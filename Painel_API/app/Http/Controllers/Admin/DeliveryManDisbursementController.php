<?php

namespace App\Http\Controllers\Admin;

use App\CentralLogics\Helpers;
use App\Exports\DisbursementExport;
use App\Http\Controllers\Controller;
use App\Models\BusinessSetting;
use App\Models\DmCashLog;
use App\Models\DeliveryMan;
use App\Models\DeliveryManPixAccount;
use App\Models\Disbursement;
use App\Models\DisbursementDetails;
use App\Models\Order;
use App\Models\ProvideDMEarning;
use App\Services\AsaasTransferService;
use Brian2694\Toastr\Facades\Toastr;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\View;
use Maatwebsite\Excel\Facades\Excel;

class DeliveryManDisbursementController extends Controller
{
    private function isAutoAsaasEnabled(): bool
    {
        return (int) (BusinessSetting::where('key', 'dm_asaas_auto_transfer')->first()?->value ?? 0) === 1;
    }

    private function processAsaasTransfer(DisbursementDetails $disbursement): array
    {
        $pixKey = $disbursement->delivery_man?->pixAccount?->pix_key;
        if (!$pixKey) {
            $methodFields = json_decode($disbursement?->withdraw_method?->method_fields ?? '[]', true);
            $pixKey = data_get($methodFields, 'pix_key');
        }

        if (!$pixKey) {
            $disbursement->payout_provider = 'asaas';
            $disbursement->payout_status = 'failed';
            $disbursement->payout_error = 'Pix key not found for deliveryman';
            $disbursement->save();

            return ['success' => false, 'message' => 'Pix key not found for deliveryman'];
        }

        $externalReference = 'dm_disbursement_' . $disbursement->id;
        $description = 'Deliveryman withdraw #' . $disbursement->id;

        $service = app(AsaasTransferService::class);
        $result = $service->createPixTransfer(
            amount: (float) $disbursement->disbursement_amount,
            pixKey: $pixKey,
            externalReference: $externalReference,
            description: $description
        );

        $disbursement->payout_provider = 'asaas';
        $disbursement->payout_processed_at = now();

        if ($result['success']) {
            $disbursement->asaas_transfer_id = $result['transfer_id'];
            $disbursement->payout_status = strtolower((string) ($result['status'] ?? 'paid'));
            $disbursement->payout_error = null;
            $disbursement->save();

            return ['success' => true];
        }

        $disbursement->payout_status = 'failed';
        $disbursement->payout_error = $result['message'] ?? 'Asaas transfer failed';
        $disbursement->status = 'failed';
        $disbursement->save();

        // Reverse pending_withdraw so the DM's balance is not locked
        $wallet = $disbursement->delivery_man?->wallet;
        if ($wallet && $wallet->pending_withdraw >= $disbursement->disbursement_amount) {
            $wallet->decrement('pending_withdraw', $disbursement->disbursement_amount);
        }

        self::check_status($disbursement->disbursement_id);

        return ['success' => false, 'message' => $result['message'] ?? 'Asaas transfer failed'];
    }

    private function applyCompletedState(DisbursementDetails $disbursement): void
    {
        $provide_dm_earning = new ProvideDMEarning();
        $provide_dm_earning->delivery_man_id = $disbursement->delivery_man_id;
        $provide_dm_earning->method = $disbursement?->withdraw_method?->method_name;
        $provide_dm_earning->ref = $disbursement->id;
        $provide_dm_earning->amount = $disbursement['disbursement_amount'];

        if($disbursement->status== 'canceled'){
            $disbursement->delivery_man?->wallet?->increment('total_withdrawn', $disbursement['disbursement_amount']);
            } else{
                $disbursement->delivery_man?->wallet?->decrement('pending_withdraw', $disbursement['disbursement_amount']);
                $disbursement->delivery_man?->wallet?->increment('total_withdrawn', $disbursement['disbursement_amount']);
            }

        $provide_dm_earning->save();
    }

    public function list(Request $request)
    {
        $status = $request->status??'all';
        $disbursements = Disbursement::
        when($status!='all', function($q) use($status){
            return $q->where('status',$status);
        })
        ->where('created_for','delivery_man')
        ->latest()->paginate(config('default_pagination'));
        return view('admin-views.dm-disbursement.index', compact('disbursements','status'));
    }

    public function view(Request $request,$id)
    {
        $key = explode(' ', $request['search']);
        $delivery_man_id = $request->query('delivery_man_id', 'all');
        $payment_method_id = $request->query('payment_method_id', 'all');
        $disbursement = Disbursement::findOrFail($id);
        $disbursements=DisbursementDetails::with('delivery_man','withdraw_method')->where(['disbursement_id'=>$id])
            ->when(isset($key) , function($q) use($key){
                $q->whereHas('delivery_man', function ($q) use($key){
                    $q->where(function ($q) use ($key) {
                        foreach ($key as $value) {
                            $q->orWhere('f_name', 'like', "%{$value}%")
                                ->orWhere('l_name', 'like', "%{$value}%")
                                ->orWhere('email', 'like', "%{$value}%")
                                ->orWhere('phone', 'like', "%{$value}%");
                        }
                    });
                });
            })
            ->when((isset($delivery_man_id) && is_numeric($delivery_man_id)), function ($query) use ($delivery_man_id){
                $query->where('delivery_man_id', $delivery_man_id);
            })
            ->when((isset($payment_method_id) && is_numeric($payment_method_id)), function ($query) use ($payment_method_id){
                $query->whereHas('withdraw_method', function ($q) use($payment_method_id){
                    return $q->where('withdrawal_method_id', $payment_method_id);
                });
            })
            ->latest();
        $dm_ids = json_encode($disbursements->pluck('delivery_man_id')->toArray());
        $disbursement_delivery_mans = $disbursements->paginate(config('default_pagination'));
        return view('admin-views.dm-disbursement.view', compact('disbursement','disbursement_delivery_mans','delivery_man_id','dm_ids','payment_method_id'));
    }
    public function export(Request $request,$id,$type='excel')
    {
        $key = explode(' ', $request['search']);
        $delivery_man_id = $request->query('delivery_man_id', 'all');
        $payment_method_id = $request->query('payment_method_id', 'all');
        $disbursement = Disbursement::findOrFail($id);
        $disbursements=DisbursementDetails::where(['disbursement_id'=>$id])
            ->when(isset($key) , function($q) use($key){
                $q->whereHas('delivery_man', function ($q) use($key){
                    $q->where(function ($q) use ($key) {
                        foreach ($key as $value) {
                            $q->orWhere('f_name', 'like', "%{$value}%")
                                ->orWhere('l_name', 'like', "%{$value}%")
                                ->orWhere('email', 'like', "%{$value}%")
                                ->orWhere('phone', 'like', "%{$value}%");
                        }
                    });
                });
            })
            ->when((isset($delivery_man_id) && is_numeric($delivery_man_id)), function ($query) use ($delivery_man_id){
                $query->where('delivery_man_id', $delivery_man_id);
            })
            ->when((isset($payment_method_id) && is_numeric($payment_method_id)), function ($query) use ($payment_method_id){
                $query->whereHas('withdraw_method', function ($q) use($payment_method_id){
                    return $q->where('withdrawal_method_id', $payment_method_id);
                });
            })
            ->latest()->get();
        $data=[
            'type'=>'dm',
            'disbursement' =>$disbursement,
            'disbursements' =>$disbursements,
        ];
        if($type == 'pdf'){
            $mpdf_view = View::make('admin-views.dm-disbursement.pdf', compact('disbursement','disbursements')
            );
            Helpers::gen_mpdf(view: $mpdf_view,file_prefix: 'Disbursement',file_postfix: $id);
        }elseif($type == 'csv'){
            return Excel::download(new DisbursementExport($data), 'Disbursement.csv');
        }
        return Excel::download(new DisbursementExport($data), 'Disbursement.xlsx');
    }

    public function status(Request $request)
    {
        $disbursements=DisbursementDetails::where(['disbursement_id'=>$request->disbursement_id])->whereIn('delivery_man_id',$request->delivery_man_ids)->get();

        foreach ($disbursements as $disbursement){

            if ( (string)  $disbursement->delivery_man?->wallet?->total_earning <  (string) ($disbursement->delivery_man?->wallet?->total_withdrawn + $disbursement->delivery_man?->wallet?->pending_withdraw) ) {
                return response()->json([
                    'status' => 'error',
                    'message'=> translate('messages.Balance_mismatched_total_earning_is_too_low_for').' '.$disbursement->delivery_man?->name,
                ]);
            }


            if($request->status == 'completed') {
                if ($disbursement->status != 'completed') {
                    if ($this->isAutoAsaasEnabled() && ($disbursement->payout_provider === 'asaas' || $disbursement->payout_provider === null)) {
                        $transfer = $this->processAsaasTransfer($disbursement);
                        if (!$transfer['success']) {
                            return response()->json([
                                'status' => 'error',
                                'message' => $transfer['message'] ?? 'Asaas transfer failed',
                            ]);
                        }
                    }

                    $this->applyCompletedState($disbursement);

                }
            }elseif ($request->status == 'canceled'){
                if($disbursement->status == 'completed'){
                    return response()->json([
                        'status' => 'error',
                        'message'=> translate('messages.can_not_cancel_completed_disbursement_,_uncheck_completed_disbursements')
                    ]);
                }


                $disbursement->delivery_man?->wallet?->decrement('pending_withdraw', $disbursement['disbursement_amount']);
                // if((string)  $disbursement->delivery_man?->wallet?->pending_withdraw  >=  (string)  $disbursement['disbursement_amount']){
                //   $disbursement->delivery_man?->wallet?->decrement('pending_withdraw', $disbursement['disbursement_amount']);
                //     } else{
                //         return response()->json([
                //             'status' => 'error',
                //             'message'=> translate('messages.Balance_mismatched_for').' '.$disbursement->delivery_man?->f_name,
                //         ]);
                //     }
            }
            $disbursement->status = $request->status;
            $disbursement->save();
        }

        self::check_status($request->disbursement_id);

        return response()->json([
            'status' => 'success',
            'message'=> translate('messages.status_updated')
        ]);
    }

    public function statusById($id,$status)
    {

        $disbursement=DisbursementDetails::find($id);

            if ((string) $disbursement->delivery_man?->wallet?->total_earning <  (string)($disbursement->delivery_man?->wallet?->total_withdrawn + $disbursement->delivery_man?->wallet?->pending_withdraw) ) {
                Toastr::error(translate('messages.Balance_mismatched_total_earning_is_too_low_for').' '.$disbursement->delivery_man?->f_name);
                return back();
            }


        if($status == 'completed'){
            // Idempotency guard: não reprocessar se já concluído
            if ($disbursement->status === 'completed') {
                Toastr::warning('Este saque já está concluído.');
                return back();
            }
            if ($this->isAutoAsaasEnabled() && ($disbursement->payout_provider === 'asaas' || $disbursement->payout_provider === null)) {
                $transfer = $this->processAsaasTransfer($disbursement);
                if (!$transfer['success']) {
                    Toastr::error($transfer['message'] ?? 'Asaas transfer failed');
                    return back();
                }
            }

            $this->applyCompletedState($disbursement);

        }elseif ($status == 'canceled'){
            if($disbursement->status == 'completed'){
                Toastr::error(translate('messages.can_not_cancel_completed_disbursement_,_uncheck_completed_disbursements'));
                return back();
            }

            $disbursement->delivery_man?->wallet?->decrement('pending_withdraw', $disbursement['disbursement_amount']);
            // if((string) $disbursement->delivery_man?->wallet?->pending_withdraw  >=   (string) $disbursement['disbursement_amount']){

            //     $disbursement->delivery_man?->wallet?->decrement('pending_withdraw', $disbursement['disbursement_amount']);
            //     } else{
            //         Toastr::error(translate('messages.Balance_mismatched_for').' '.$disbursement->delivery_man?->f_name);
            //         return back();
            //     }



        }elseif ($status == 'pending'){
            // Bloquear estorno se o pagamento já foi confirmado via Asaas
            if (
                $disbursement->payout_provider === 'asaas' &&
                in_array($disbursement->payout_status, ['paid', 'transferred'])
            ) {
                Toastr::error('Não é possível estornar: pagamento já confirmado via Asaas (status: ' . $disbursement->payout_status . '). Entre em contato com o suporte Asaas para cancelar a transferência.');
                return back();
            }
            if($disbursement->status == 'completed'){
                $withdraw = ProvideDMEarning::where('ref',$id)->where('delivery_man_id', $disbursement->delivery_man_id)->first();
                if ($withdraw){
                    $withdraw->delete();
                }
            }
            $disbursement->delivery_man?->wallet?->decrement('total_withdrawn', $disbursement['disbursement_amount']);
            $disbursement->delivery_man?->wallet?->increment('pending_withdraw', $disbursement['disbursement_amount']);
        }

        $disbursement->status = $status;
        $disbursement->save();

        self::check_status($disbursement->disbursement_id);

        Toastr::success(translate('messages.status_updated'));
        return back();
    }

    /**
     * Query Asaas for the current transfer status and sync it locally.
     */
    public function syncAsaasStatus($id)
    {
        $disbursement = DisbursementDetails::with(['delivery_man.wallet'])->findOrFail($id);

        if (!$disbursement->asaas_transfer_id) {
            Toastr::warning('Este saque não possui ID de transferência Asaas.');
            return back();
        }

        $service = app(\App\Services\AsaasTransferService::class);
        $result  = $service->getTransferStatus($disbursement->asaas_transfer_id);

        if (!$result['success']) {
            Toastr::error($result['message'] ?? 'Não foi possível consultar o Asaas.');
            return back();
        }

        $asaasStatus = $result['status']; // e.g. DONE, CONFIRMED, CANCELLED, FAILED, PENDING

        if (in_array($asaasStatus, ['DONE', 'CONFIRMED', 'TRANSFERRED'], true)) {
            if ($disbursement->status !== 'completed') {
                // Atualiza o valor real efetivamente transferido pelo Asaas
                $realValue = (float) ($result['value'] ?? 0);
                if ($realValue > 0 && abs($realValue - $disbursement->disbursement_amount) > 0.001) {
                    // Ajusta pending_withdraw para o valor correto antes de processar
                    $oldAmount = $disbursement->disbursement_amount;
                    $wallet = $disbursement->delivery_man?->wallet;
                    if ($wallet) {
                        $wallet->decrement('pending_withdraw', $oldAmount);
                        $wallet->increment('pending_withdraw', $realValue);
                    }
                    $disbursement->disbursement_amount = $realValue;
                    $disbursement->save();
                }
                $disbursement->payout_status = 'paid';
                $disbursement->payout_error  = null;
                $disbursement->save();
                $this->applyCompletedState($disbursement);
                $disbursement->status = 'completed';
                $disbursement->save();
                self::check_status($disbursement->disbursement_id);
                Toastr::success('Transferência confirmada no Asaas. Saque marcado como concluído.');
            } else {
                // Just sync payout_status
                $disbursement->payout_status = 'paid';
                $disbursement->payout_error  = null;
                $disbursement->save();
                Toastr::success('Status do Asaas atualizado para: pago.');
            }
        } elseif (in_array($asaasStatus, ['CANCELLED', 'FAILED', 'BLOCKED'], true)) {
            if ($disbursement->status !== 'completed') {
                $disbursement->payout_status = 'failed';
                $disbursement->payout_error  = 'Asaas status: ' . $asaasStatus;
                $disbursement->status = 'failed';
                $disbursement->save();
                $wallet = $disbursement->delivery_man?->wallet;
                if ($wallet && $wallet->pending_withdraw >= $disbursement->disbursement_amount) {
                    $wallet->decrement('pending_withdraw', $disbursement->disbursement_amount);
                }
                self::check_status($disbursement->disbursement_id);
                Toastr::warning('Transferência cancelada/falhou no Asaas. Saque marcado como falhou.');
            } else {
                Toastr::info('Saque já está concluído — nenhuma alteração necessária.');
            }
        } else {
            // PENDING, PROCESSING etc — just update payout_status text
            $disbursement->payout_status = strtolower($asaasStatus);
            $disbursement->save();
            Toastr::info('Status atual no Asaas: ' . $asaasStatus . '. Aguardando confirmação.');
        }

        return back();
    }

    public function processAsaasById($id)
    {
        $disbursement = DisbursementDetails::findOrFail($id);
        $transfer = $this->processAsaasTransfer($disbursement);

        if (!$transfer['success']) {
            Toastr::error($transfer['message'] ?? 'Asaas transfer failed');
            return back();
        }

        // Bloqueia reprocessamento para status terminais
        if (in_array($disbursement->status, ['completed', 'canceled', 'failed'])) {
            Toastr::warning('Este saque já está ' . $disbursement->status . ' e não pode ser reprocessado.');
            return back();
        }

        if ($disbursement->status !== 'completed') {
            $this->applyCompletedState($disbursement);
            $disbursement->status = 'completed';
            $disbursement->save();
            self::check_status($disbursement->disbursement_id);
        }

        Toastr::success('Asaas transfer processed successfully');
        return back();
    }
    public function generate_disbursement()
    {
        $delivery_mans = DeliveryMan::where('type' ,'zone_wise')->where('earning',1)->get();
        $disbursement_details = [];
        $total_amount = 0;

        $disbursement = new Disbursement();
        $disbursement->id = 1000 + Disbursement::count() + 1;
        if (Disbursement::find($disbursement->id)) {
            $disbursement->id = Disbursement::orderBy('id', 'desc')->first()->id + 1;
        }
        $disbursement->title = 'Disbursement # '.$disbursement->id;
        $minimum_amount = BusinessSetting::where(['key' => 'dm_disbursement_min_amount'])->first()?->value;
        foreach ($delivery_mans as $delivery_man){
            if(isset($delivery_man->wallet)){

                $total_earning = $delivery_man->wallet?$delivery_man->wallet->total_earning:0;
                $total_withdraw = ($delivery_man->wallet?$delivery_man->wallet->total_withdrawn:0) + ($delivery_man->wallet?$delivery_man->wallet->pending_withdraw:0);
                $total_cash_in_hand = $delivery_man->wallet?$delivery_man->wallet->collected_cash:0;
                $disbursement_amount = ( (string) $total_earning >  (string)  ($total_withdraw+$total_cash_in_hand))?  ($total_earning - ($total_withdraw+$total_cash_in_hand)):0;

                if ($disbursement_amount>$minimum_amount && $delivery_man->disbursement_method){
                    $res_d = [
                        'disbursement_id' => $disbursement->id,
                        'delivery_man_id' => $delivery_man->id,
                        'disbursement_amount' => $disbursement_amount,
                        'payment_method' => $delivery_man->disbursement_method->id,
                        'created_at' => now(),
                        'updated_at' => now()
                    ];
                    $disbursement_details[] = $res_d;
                    $total_amount += $res_d['disbursement_amount'];
                    $delivery_man->wallet->pending_withdraw = $delivery_man->wallet->pending_withdraw + $disbursement_amount;
                    $delivery_man->wallet->save();
                }
            }

        }

        if ($total_amount > 0){
            $disbursement->total_amount = $total_amount;
            $disbursement->created_for = 'delivery_man';
            $disbursement->save();

            DisbursementDetails::insert($disbursement_details);
        }

        info("DM-----Disbursement");
        return true;

    }

    public function check_status($id) {
        $disbursements = DisbursementDetails::where(['disbursement_id' => $id])->get();
        $statusCounts = $disbursements->countBy('status');

        $disbursement = Disbursement::find($id);

        if (isset($statusCounts['pending']) && ($statusCounts['pending'] == count($disbursements))) {
            $disbursement->status = 'pending';
        } elseif (isset($statusCounts['canceled']) && ($statusCounts['canceled'] == count($disbursements))) {
            $disbursement->status = 'canceled';
        } elseif (isset($statusCounts['failed']) && ($statusCounts['failed'] == count($disbursements))) {
            $disbursement->status = 'failed';
        } elseif (isset($statusCounts['completed']) && ($statusCounts['completed'] == count($disbursements))) {
            $disbursement->status = 'completed';
        } else {
            $disbursement->status = 'partially_completed';
        }

        return $disbursement->save();
    }

    public function resetPixAccount($delivery_man_id)
    {
        $deleted = \App\Models\DeliveryManPixAccount::where('delivery_man_id', $delivery_man_id)->delete();

        if ($deleted) {
            Toastr::success('Chave PIX redefinida com sucesso. O entregador pode cadastrar uma nova chave.');
        } else {
            Toastr::warning('Nenhuma chave PIX encontrada para este entregador.');
        }

        return back();
    }

    public function asaasIndex(Request $request)
    {
        $settings = [
            'dm_asaas_auto_transfer' => BusinessSetting::where('key', 'dm_asaas_auto_transfer')->first()?->value ?? 0,
            'asaas_base_url'         => BusinessSetting::where('key', 'asaas_base_url')->first()?->value ?? 'https://www.asaas.com/api/v3',
            'asaas_api_key'          => BusinessSetting::where('key', 'asaas_api_key')->first()?->value ?? '',
            'asaas_webhook_token'    => BusinessSetting::where('key', 'asaas_webhook_token')->first()?->value ?? '',
        ];

        $tab = $request->get('tab', 'settings');
        $status = $request->get('status', 'all');
        $search = $request->get('search');
        $selectedDmId = (int) $request->get('dm_id', 0);

        $disbursements = DisbursementDetails::with(['delivery_man', 'withdraw_method'])
            ->when($status !== 'all', fn($q) => $q->where('status', $status))
            ->latest()
            ->paginate(20)
            ->appends($request->query());

        $pixAccounts = DeliveryManPixAccount::with('deliveryMan')
            ->latest()
            ->paginate(20)
            ->appends($request->query());

        $deliveryMen = null;
        $selectedDeliveryMan = null;
        $selectedWalletSummary = null;
        $selectedDmCashLogs = collect();
        $selectedDmDisbursements = collect();
        $selectedDmOrders = collect();

        if ($tab === 'entregadores') {
            $deliveryMen = DeliveryMan::with('wallet')
                ->withCount([
                    'orders as delivered_orders_count' => function ($query) {
                        $query->where('order_status', 'delivered');
                    },
                    'orders as canceled_by_dm_orders_count' => function ($query) {
                        $query->where('order_status', 'canceled')->where('canceled_by', 'deliveryman');
                    },
                    'orders as failed_orders_count' => function ($query) {
                        $query->where('order_status', 'failed');
                    },
                ])
                ->when($search, function ($query) use ($search) {
                    $query->where(function ($q) use ($search) {
                        $q->where('f_name', 'like', "%{$search}%")
                            ->orWhere('l_name', 'like', "%{$search}%")
                            ->orWhere('phone', 'like', "%{$search}%");
                    });
                })
                ->latest()
                ->paginate(20)
                ->appends($request->query());

            if ($selectedDmId > 0) {
                $selectedDeliveryMan = DeliveryMan::with(['wallet', 'pixAccount'])->find($selectedDmId);

                if ($selectedDeliveryMan) {
                    $wallet = $selectedDeliveryMan->wallet;

                    $totalEarning = (float) ($wallet?->total_earning ?? 0);
                    $totalWithdrawn = (float) ($wallet?->total_withdrawn ?? 0);
                    $pendingWithdraw = (float) ($wallet?->pending_withdraw ?? 0);
                    $collectedCash = (float) ($wallet?->collected_cash ?? 0);

                    $digitalBalance = (float) ($totalEarning - ($totalWithdrawn + $pendingWithdraw));
                    $platformNetBalance = (float) ($totalEarning - ($totalWithdrawn + $pendingWithdraw + $collectedCash));

                    $selectedWalletSummary = [
                        'total_earning' => $totalEarning,
                        'total_withdrawn' => $totalWithdrawn,
                        'pending_withdraw' => $pendingWithdraw,
                        'collected_cash' => $collectedCash,
                        'digital_balance' => $digitalBalance,
                        'platform_net_balance' => $platformNetBalance,
                        'status' => $platformNetBalance > 0 ? 'positive' : ($platformNetBalance < 0 ? 'negative' : 'neutral'),
                    ];

                    $selectedDmCashLogs = DmCashLog::with('order')
                        ->where('delivery_man_id', $selectedDmId)
                        ->latest()
                        ->limit(50)
                        ->get();

                    $selectedDmDisbursements = DisbursementDetails::with('withdraw_method')
                        ->where('delivery_man_id', $selectedDmId)
                        ->latest()
                        ->limit(50)
                        ->get();

                    $selectedDmOrders = Order::where('delivery_man_id', $selectedDmId)
                        ->whereIn('order_status', ['canceled', 'failed', 'delivered', 'pending', 'confirmed', 'picked_up'])
                        ->latest()
                        ->limit(50)
                        ->get([
                            'id',
                            'order_status',
                            'canceled_by',
                            'cancellation_reason',
                            'order_amount',
                            'payment_status',
                            'created_at',
                            'updated_at',
                        ]);
                }
            }
        }

        return view('admin-views.asaas.index', compact(
            'settings',
            'tab',
            'status',
            'search',
            'disbursements',
            'pixAccounts',
            'deliveryMen',
            'selectedDmId',
            'selectedDeliveryMan',
            'selectedWalletSummary',
            'selectedDmCashLogs',
            'selectedDmDisbursements',
            'selectedDmOrders'
        ));
    }

    public function saveAsaasSettings(Request $request)
    {
        Helpers::businessUpdateOrInsert(['key' => 'dm_asaas_auto_transfer'], [
            'value' => $request->has('dm_asaas_auto_transfer') ? 1 : 0,
        ]);
        Helpers::businessUpdateOrInsert(['key' => 'asaas_base_url'], [
            'value' => $request->input('asaas_base_url', 'https://www.asaas.com/api/v3'),
        ]);
        Helpers::businessUpdateOrInsert(['key' => 'asaas_api_key'], [
            'value' => $request->input('asaas_api_key', ''),
        ]);
        Helpers::businessUpdateOrInsert(['key' => 'asaas_webhook_token'], [
            'value' => $request->input('asaas_webhook_token', ''),
        ]);

        Toastr::success('Configurações do Asaas salvas com sucesso.');
        return redirect()->route('admin.transactions.asaas.index', ['tab' => 'settings']);
    }
}
