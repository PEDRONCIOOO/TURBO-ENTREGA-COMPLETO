<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Traits\Processor;
use Illuminate\Http\Request;
use App\Models\PaymentRequest;
use Exception;
use Illuminate\Support\Facades\Validator;
use MercadoPago\Client\Payment\PaymentClient;
use MercadoPago\Exceptions\MPApiException;
use MercadoPago\MercadoPagoConfig;
use MercadoPago\Client\Common\RequestOptions;

class MercadoPagoController extends Controller
{
    use Processor;

    private PaymentRequest $paymentRequest;
    private $config;
    private $user;

    public function __construct(PaymentRequest $paymentRequest, User $user)
    {
        $config = $this->payment_config('mercadopago', 'payment_config');
        if (!is_null($config) && $config->mode == 'live') {
            $this->config = json_decode($config->live_values);
        } elseif (!is_null($config) && $config->mode == 'test') {
            $this->config = json_decode($config->test_values);
        }
        $this->paymentRequest = $paymentRequest;
        $this->user = $user;

        if (isset($this->config->access_token)) {
            MercadoPagoConfig::setAccessToken($this->config->access_token);
        }
    }

    /**
     * Abre a tela de pagamento (Cartão / Pix).
     */
    public function index(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'payment_id' => 'required|uuid'
        ]);

        if ($validator->fails()) {
            return response()->json(
                $this->response_formatter(GATEWAYS_DEFAULT_400, null, $this->error_processor($validator)),
                400
            );
        }

        $data = $this->paymentRequest::where([
            'id'      => $request['payment_id'],
            'is_paid' => 0
        ])->first();

        if (!isset($data)) {
            return response()->json($this->response_formatter(GATEWAYS_DEFAULT_204), 200);
        }

        $config = $this->config;

        return view('payment-views.payment-view-marcedo-pogo', compact('config', 'data'));
    }

    /**
     * Pagamento com CARTÃO (fluxo antigo).
     */
    public function make_payment(Request $request)
    {
        $paymentRequest = $this->paymentRequest::where(['id' => $request['payment_id']])->first();
        if (!$paymentRequest) {
            return response()->json(['error' => 'Payment request not found'], 404);
        }

        $client = new PaymentClient();
        $data = [];
        $data['transaction_amount'] = (float)$request['transactionAmount'];
        $data['token']              = $request['token'];
        $data['description']        = $request['description'] ?? ('Pagamento ' . $paymentRequest->id);
        $data['installments']       = (int)$request['installments'];
        $data['payment_method_id']  = $request['paymentMethodId'];
        $data['payer']['email']     = $request['payer']['email'];

        // para conseguir ligar o pagamento ao payment_id no webhook
        $data['external_reference'] = $request['payment_id'];
        $data['notification_url']   = route('mercadopago.webhook');

        $request_options = new RequestOptions();
        $unigueId = uniqid();
        $request_options->setCustomHeaders([
            "X-Idempotency-Key: {$unigueId}"
        ]);

        try {
            $payment  = $client->create($data, $request_options);
            $response = [
                'status'        => $payment->status,
                'status_detail' => $payment->status_detail,
                'id'            => $payment->id,
            ];
        } catch (MPApiException $e) {
            $response['error'] = $e->getApiResponse()->getContent();
        } catch (Exception $e) {
            $response['error'] = $e->getMessage();
        }

        if (data_get($response, 'error.message', null)) {
            $response['error'] = data_get($response, 'error.message', null);
            return response()->json($response);
        }

        // Se aprovado na hora, salva transaction_id
        if (isset($payment) && $payment->status == 'approved') {
            $paymentInfo = $this->paymentRequest::where(['id' => $request['payment_id']])->first();
            if ($paymentInfo) {
                $paymentInfo->transaction_id = $payment->id;
                $paymentInfo->payment_method = 'mercadopago_card';
                $paymentInfo->save();
            }
        }

        return response()->json($response);
    }

    /**
     * Pagamento via PIX: gera QR Code e código copia-e-cola.
     */
    public function pix_payment(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'payment_id'        => 'required|uuid',
            'transactionAmount' => 'required|numeric|min:0.01',
            'payer.email'       => 'required|email',
            'payer.identification.number' => 'required',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'error' => 'Dados inválidos para Pix',
                'details' => $validator->errors(),
            ], 422);
        }

        $paymentRequest = $this->paymentRequest::where(['id' => $request['payment_id']])->first();
        if (!$paymentRequest) {
            return response()->json(['error' => 'Payment request not found'], 404);
        }

        $client = new PaymentClient();

        $data = [
            'transaction_amount' => (float)$request['transactionAmount'],
            'description'        => 'Pagamento via Pix ' . $paymentRequest->id,
            'payment_method_id'  => 'pix',
            'payer'              => $request->input('payer'),
            'external_reference' => $request['payment_id'],
            'notification_url'   => route('mercadopago.webhook'),
        ];

        $request_options = new RequestOptions();
        $unigueId = uniqid();
        $request_options->setCustomHeaders([
            "X-Idempotency-Key: {$unigueId}"
        ]);

        try {
            $payment = $client->create($data, $request_options);

            $transactionData = $payment->point_of_interaction->transaction_data ?? null;

            // salva transaction_id mas NÃO marca como pago ainda (espera webhook)
            $paymentRequest->transaction_id = $payment->id;
            $paymentRequest->payment_method = 'mercadopago_pix';
            $paymentRequest->save();

            return response()->json([
                'status'         => $payment->status,
                'id'             => $payment->id,
                'qr_code'        => $transactionData->qr_code ?? null,
                'qr_code_base64' => $transactionData->qr_code_base64 ?? null,
                'ticket_url'     => $transactionData->ticket_url ?? null,
            ]);
        } catch (MPApiException $e) {
            return response()->json([
                'error' => $e->getApiResponse()->getContent()
            ], 422);
        } catch (Exception $e) {
            return response()->json([
                'error' => $e->getMessage()
            ], 422);
        }
    }

    /**
     * Endpoint para o front saber se o Pix já foi pago.
     * Ele apenas lê o registro de PaymentRequest.
     */
    public function pix_status(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'payment_id' => 'required|uuid'
        ]);

        if ($validator->fails()) {
            return response()->json(['status' => 'error', 'details' => $validator->errors()], 422);
        }

        $paymentRequest = $this->paymentRequest::where(['id' => $request['payment_id']])->first();

        if (!$paymentRequest) {
            return response()->json(['status' => 'not_found'], 404);
        }

        // se o webhook já marcou como pago
        if ($paymentRequest->is_paid) {
            return response()->json(['status' => 'paid']);
        }

        return response()->json(['status' => 'pending']);
    }

    /**
     * Sucesso – mesma lógica antiga, só usa payment_id da query.
     */
    public function success(Request $request)
    {
        $paymentData = $this->paymentRequest::where(['id' => $request['payment_id']])->first();

        if ($paymentData && $paymentData->transaction_id != null) {

            // marca como pago aqui (igual versão antiga)
            $this->paymentRequest::where(['id' => $request['payment_id']])->update([
                'payment_method' => $paymentData->payment_method ?? 'mercadopago',
                'is_paid'        => 1,
            ]);

            $data = $this->paymentRequest::where(['id' => $request['payment_id']])->first();

            if (isset($data) && function_exists($data->success_hook)) {
                call_user_func($data->success_hook, $data);
            }

            return $this->payment_response($data, 'success');

        } else {

            if ($paymentData && function_exists($paymentData->failure_hook)) {
                call_user_func($paymentData->failure_hook, $paymentData);
            }

            return $this->payment_response($paymentData, 'fail');
        }
    }

    public function failed(Request $request)
    {
        $paymentData = $this->paymentRequest::where(['id' => $request['payment_id']])->first();

        if (isset($paymentData) && function_exists($paymentData->failure_hook)) {
            call_user_func($paymentData->failure_hook, $paymentData);
        }

        return $this->payment_response($paymentData, 'fail');
    }
}
