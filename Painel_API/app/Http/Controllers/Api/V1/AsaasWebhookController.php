<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Controllers\Admin\DeliveryManDisbursementController;
use App\Models\BusinessSetting;
use App\Models\DeliveryManPixAccount;
use App\Models\DisbursementDetails;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class AsaasWebhookController extends Controller
{
    /**
     * Handle Asaas webhooks.
     *
     * Two types arrive at this endpoint:
     *
     * 1. Transfer VALIDATION webhook (type=TRANSFER):
     *    Asaas sends 5s after a transfer is created.
     *    We must respond with {"status":"APPROVED"} or {"status":"REFUSED","refuseReason":"..."}.
     *    After 3 consecutive failures Asaas cancels the transfer automatically.
     *
     * 2. Transfer STATUS events (event=TRANSFER_CONFIRMED / TRANSFER_CANCELLED / etc.):
     *    Asaas notifies us when the transfer lifecycle changes.
     *    We use this to auto-update the DisbursementDetails status.
     *
     * Docs: https://docs.asaas.com/docs/mecanismo-para-validacao-de-saque-via-webhooks
     */
    public function handle(Request $request): JsonResponse
    {
        Log::info('[AsaasWebhook] Received', [
            'ip'      => $request->ip(),
            'payload' => $request->all(),
        ]);

        // ── 1. Validate optional access token ───────────────────────────────
        $configuredToken = (string) (BusinessSetting::where('key', 'asaas_webhook_token')->first()?->value ?? '');

        if ($configuredToken !== '') {
            $incomingToken = (string) $request->header('asaas-access-token', '');

            if (!hash_equals($configuredToken, $incomingToken)) {
                Log::warning('[AsaasWebhook] Invalid asaas-access-token');
                // For validation webhooks, refuse. For event webhooks, 200 is fine.
                if ($request->input('type') === 'TRANSFER') {
                    return $this->refuse('Token de acesso inválido');
                }
                return response()->json(['received' => false], 401);
            }
        }

        // ── 2. Route by event type ────────────────────────────────────────────
        $event = $request->input('event');
        $type  = $request->input('type');

        // Transfer validation webhook
        if ($type === 'TRANSFER') {
            return $this->handleValidationWebhook($request);
        }

        // Transfer status event webhook
        if ($event && str_starts_with($event, 'TRANSFER_')) {
            return $this->handleTransferEvent($request, $event);
        }

        // Other types — acknowledge and ignore
        Log::info("[AsaasWebhook] Ignoring unhandled payload (type={$type}, event={$event})");
        return response()->json(['received' => true], 200);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Validation webhook (type = TRANSFER)
    // ─────────────────────────────────────────────────────────────────────────

    private function handleValidationWebhook(Request $request): JsonResponse
    {
        $transfer          = $request->input('transfer', []);
        $asaasTransferId   = $transfer['id'] ?? null;
        $externalReference = $transfer['externalReference'] ?? null;

        if (!$asaasTransferId) {
            Log::warning('[AsaasWebhook] Validation: missing transfer.id');
            return $this->refuse('ID da transferência ausente no payload');
        }

        $disbursement = $this->findDisbursement($asaasTransferId, $externalReference);

        if (!$disbursement) {
            Log::warning('[AsaasWebhook] Validation: disbursement not found', [
                'asaas_transfer_id'  => $asaasTransferId,
                'external_reference' => $externalReference,
            ]);
            return $this->refuse('Transferência não encontrada no sistema');
        }

        if (in_array(strtolower((string) $disbursement->status), ['canceled', 'cancelled'], true)) {
            Log::warning('[AsaasWebhook] Validation: disbursement is cancelled', ['id' => $disbursement->id]);
            return $this->refuse('Saque cancelado — transferência não autorizada');
        }

        // Verify the delivery man has a registered PIX key
        $hasPixKey = DeliveryManPixAccount::where('delivery_man_id', $disbursement->delivery_man_id)->exists();
        if (!$hasPixKey) {
            Log::warning('[AsaasWebhook] Validation: no PIX key', ['delivery_man_id' => $disbursement->delivery_man_id]);
            return $this->refuse('Chave PIX não cadastrada para este entregador');
        }

        // Verify the DM has sufficient balance
        $wallet = $disbursement->delivery_man?->wallet;
        if ($wallet) {
            $availableBalance = (float) max(
                0,
                $wallet->total_earning - ($wallet->total_withdrawn + $wallet->pending_withdraw + $wallet->collected_cash)
            );
            if ((float) $disbursement->disbursement_amount > round($availableBalance + (float) $disbursement->disbursement_amount, 8)) {
                Log::warning('[AsaasWebhook] Validation: insufficient balance', ['id' => $disbursement->id]);
                return $this->refuse('Saldo insuficiente para este saque');
            }
        }

        Log::info('[AsaasWebhook] Validation APPROVED', ['disbursement_id' => $disbursement->id, 'asaas_transfer_id' => $asaasTransferId]);
        return $this->approve();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Transfer status event (event = TRANSFER_CONFIRMED / TRANSFER_CANCELLED …)
    // ─────────────────────────────────────────────────────────────────────────

    private function handleTransferEvent(Request $request, string $event): JsonResponse
    {
        $transfer          = $request->input('transfer', []);
        $asaasTransferId   = $transfer['id'] ?? null;
        $externalReference = $transfer['externalReference'] ?? null;
        $asaasStatus       = strtoupper((string) ($transfer['status'] ?? ''));

        if (!$asaasTransferId) {
            Log::warning('[AsaasWebhook] Event: missing transfer.id', ['event' => $event]);
            return response()->json(['received' => true], 200);
        }

        $disbursement = $this->findDisbursement($asaasTransferId, $externalReference);

        if (!$disbursement) {
            Log::warning('[AsaasWebhook] Event: disbursement not found', ['asaas_transfer_id' => $asaasTransferId, 'event' => $event]);
            return response()->json(['received' => true], 200);
        }

        // Already in a final state — skip
        if (in_array($disbursement->status, ['completed', 'canceled'], true)) {
            Log::info('[AsaasWebhook] Event: disbursement already in final state — skip', ['id' => $disbursement->id, 'status' => $disbursement->status]);
            return response()->json(['received' => true], 200);
        }

        DB::beginTransaction();
        try {
            // ── CONFIRMED / DONE → mark completed ────────────────────────────
            if (in_array($event, ['TRANSFER_CONFIRMED', 'TRANSFER_DONE'], true)
                || in_array($asaasStatus, ['DONE', 'CONFIRMED'], true)) {

                // Atualiza o valor real efetivamente transferido pelo Asaas
                $realValue = (float) ($transfer['value'] ?? $transfer['netValue'] ?? 0);
                if ($realValue > 0 && abs($realValue - $disbursement->disbursement_amount) > 0.001) {
                    $oldAmount = $disbursement->disbursement_amount;
                    $wallet    = $disbursement->delivery_man?->wallet;
                    if ($wallet) {
                        $wallet->decrement('pending_withdraw', $oldAmount);
                        $wallet->increment('pending_withdraw', $realValue);
                    }
                    $disbursement->disbursement_amount = $realValue;
                }

                $disbursement->payout_status = 'paid';
                if ($asaasTransferId) {
                    $disbursement->asaas_transfer_id = $asaasTransferId;
                }
                $disbursement->save();

                // Deduct from pending_withdraw, add to total_withdrawn
                $disbursement->delivery_man?->wallet?->decrement('pending_withdraw', $disbursement->disbursement_amount);
                $disbursement->delivery_man?->wallet?->increment('total_withdrawn', $disbursement->disbursement_amount);

                $disbursement->status = 'completed';
                $disbursement->save();

                // ProvideDMEarning record
                \App\Models\ProvideDMEarning::create([
                    'delivery_man_id' => $disbursement->delivery_man_id,
                    'method'          => 'asaas_pix',
                    'ref'             => 'asaas_transfer_' . $disbursement->id,
                    'amount'          => $disbursement->disbursement_amount,
                ]);

                // Sync parent disbursement status
                $this->syncParentStatus($disbursement->disbursement_id);

                Log::info('[AsaasWebhook] Transfer COMPLETED', ['disbursement_id' => $disbursement->id]);

            // ── CANCELLED / FAILED → mark canceled, reverse pending_withdraw ─
            } elseif (in_array($event, ['TRANSFER_CANCELLED', 'TRANSFER_FAILED'], true)
                      || in_array($asaasStatus, ['CANCELLED', 'FAILED', 'BLOCKED'], true)) {

                $disbursement->payout_status = 'failed';
                $disbursement->payout_error  = 'Asaas event: ' . $event . ' status: ' . $asaasStatus;
                $disbursement->save();

                // Reverse pending_withdraw so the DM can request again
                $wallet = $disbursement->delivery_man?->wallet;
                if ($wallet && $wallet->pending_withdraw >= $disbursement->disbursement_amount) {
                    $wallet->decrement('pending_withdraw', $disbursement->disbursement_amount);
                }

                $disbursement->status = 'canceled';
                $disbursement->save();

                $this->syncParentStatus($disbursement->disbursement_id);

                Log::info('[AsaasWebhook] Transfer CANCELLED/FAILED', ['disbursement_id' => $disbursement->id]);

            } else {
                // Other events (TRANSFER_PENDING, TRANSFER_PROCESSING, etc.) — just log
                Log::info('[AsaasWebhook] Event: no action needed', ['event' => $event, 'asaas_status' => $asaasStatus]);
            }

            DB::commit();
        } catch (\Throwable $e) {
            DB::rollBack();
            Log::error('[AsaasWebhook] Error processing event', ['event' => $event, 'error' => $e->getMessage()]);
        }

        return response()->json(['received' => true], 200);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────────────────────────────

    private function findDisbursement(string $asaasTransferId, ?string $externalReference): ?DisbursementDetails
    {
        $disbursement = DisbursementDetails::with(['delivery_man.wallet', 'delivery_man.pixAccount'])
            ->where('asaas_transfer_id', $asaasTransferId)
            ->first();

        if (!$disbursement && $externalReference && str_starts_with($externalReference, 'dm_disbursement_')) {
            $id = (int) substr($externalReference, strlen('dm_disbursement_'));
            if ($id > 0) {
                $disbursement = DisbursementDetails::with(['delivery_man.wallet', 'delivery_man.pixAccount'])
                    ->find($id);
            }
        }

        return $disbursement;
    }

    private function syncParentStatus(int $disbursementId): void
    {
        $all    = DisbursementDetails::where('disbursement_id', $disbursementId)->get();
        $counts = $all->countBy('status');
        $total  = $all->count();

        $parent = \App\Models\Disbursement::find($disbursementId);
        if (!$parent) {
            return;
        }

        if (($counts['completed'] ?? 0) === $total) {
            $parent->status = 'completed';
        } elseif (($counts['canceled'] ?? 0) === $total) {
            $parent->status = 'canceled';
        } elseif (($counts['pending'] ?? 0) === $total) {
            $parent->status = 'pending';
        } else {
            $parent->status = 'partially_completed';
        }

        $parent->save();
    }

    private function approve(): JsonResponse
    {
        return response()->json(['status' => 'APPROVED'], 200);
    }

    private function refuse(string $reason): JsonResponse
    {
        return response()->json([
            'status'       => 'REFUSED',
            'refuseReason' => $reason,
        ], 200);
    }
}
