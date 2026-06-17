<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\PaymentRequest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use MercadoPago\Client\Payment\PaymentClient;
use MercadoPago\Exceptions\MPApiException;
use MercadoPago\MercadoPagoConfig;
use App\Traits\Processor;


class MercadoPagoWebhookController extends Controller
{
    private $config;
    use Processor;
    public function __construct()
    {
        // Carrega a mesma config usada no MercadoPagoController
        $config = $this->payment_config('mercadopago', 'payment_config'); // helper do teu projeto
        if (!is_null($config) && $config->mode == 'live') {
            $this->config = json_decode($config->live_values);
        } elseif (!is_null($config) && $config->mode == 'test') {
            $this->config = json_decode($config->test_values);
        }

        if (isset($this->config->access_token)) {
            MercadoPagoConfig::setAccessToken($this->config->access_token);
        }
    }

    public function handle(Request $request)
    {
        Log::info('MercadoPago Webhook recebido', [
            'query'   => $request->query(),
            'payload' => $request->all(),
        ]);

        // ID do pagamento vem em data.id ou em data_id
        $paymentId = data_get($request->all(), 'data.id')
            ?? $request->query('data_id');

        if (!$paymentId) {
            Log::warning('Webhook sem paymentId válido', [
                'query'   => $request->query(),
                'payload' => $request->all(),
            ]);
            return response()->json(['message' => 'no payment id'], 200);
        }

        $client = new PaymentClient();

        try {
            $payment = $client->get((int)$paymentId);
        } catch (MPApiException $e) {
            Log::error('Erro ao buscar pagamento no webhook', [
                'payment_id' => $paymentId,
                'error'      => $e->getMessage(),
                'response'   => $e->getApiResponse()->getContent(),
            ]);
            return response()->json(['message' => 'mp error'], 200);
        } catch (\Exception $e) {
            Log::error('Erro genérico ao buscar pagamento no webhook', [
                'payment_id' => $paymentId,
                'error'      => $e->getMessage(),
            ]);
            return response()->json(['message' => 'generic error'], 200);
        }

        $status            = $payment->status ?? null;
        $externalReference = $payment->external_reference ?? null;

        Log::info('Pagamento MercadoPago (webhook)', [
            'payment_id'         => $paymentId,
            'status'             => $status,
            'external_reference' => $externalReference,
        ]);

        if (!$externalReference) {
            Log::warning('Webhook: pagamento sem external_reference', [
                'payment_id' => $paymentId,
            ]);
            return response()->json(['message' => 'no external reference'], 200);
        }

        $paymentRequest = PaymentRequest::find($externalReference);

        if (!$paymentRequest) {
            Log::warning('PaymentRequest não encontrado para external_reference', [
                'external_reference' => $externalReference,
            ]);
            return response()->json(['message' => 'payment request not found'], 200);
        }

        if ($status === 'approved') {
            $paymentRequest->is_paid        = 1;
            $paymentRequest->payment_method = $paymentRequest->payment_method ?? 'mercadopago';
            $paymentRequest->transaction_id = $payment->id;
            $paymentRequest->save();
        } elseif (in_array($status, ['rejected', 'cancelled', 'refunded', 'charged_back'])) {
            $paymentRequest->is_paid = 0;
            $paymentRequest->save();
        }

        return response()->json(['status' => 'ok'], 200);
    }
}
