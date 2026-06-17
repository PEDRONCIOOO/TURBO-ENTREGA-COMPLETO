<?php

namespace App\Services;

use App\Models\BusinessSetting;
use Illuminate\Support\Facades\Http;

class AsaasTransferService
{
    public function createPixTransfer(float $amount, string $pixKey, string $externalReference, ?string $description = null): array
    {
        $baseUrl = (string) (BusinessSetting::where('key', 'asaas_base_url')->first()?->value ?? config('asaas.base_url', 'https://www.asaas.com/api/v3'));
        $baseUrl = rtrim($baseUrl, '/');
        $apiKey = (string) (BusinessSetting::where('key', 'asaas_api_key')->first()?->value ?? config('asaas.api_key'));
        $timeout = (int) config('asaas.timeout', 20);

        if ($apiKey === '') {
            return [
                'success' => false,
                'message' => 'Asaas API key not configured',
            ];
        }

        $payload = [
            'value' => round($amount, 2),
            'operationType' => 'PIX',
            'pixAddressKey' => $pixKey,
            'externalReference' => $externalReference,
        ];

        if (!empty($description)) {
            $payload['description'] = $description;
        }

        $response = Http::withHeaders([
            'access_token' => $apiKey,
            'Content-Type' => 'application/json',
            'Accept' => 'application/json',
        ])->timeout($timeout)->post($baseUrl . '/transfers', $payload);

        $data = $response->json();

        if ($response->successful() && is_array($data) && !empty($data['id'])) {
            return [
                'success' => true,
                'transfer_id' => $data['id'],
                'status' => $data['status'] ?? 'PENDING',
                'raw' => $data,
            ];
        }

        $errorMessage = is_array($data) ? ($data['errors'][0]['description'] ?? $data['message'] ?? 'Asaas transfer failed') : 'Asaas transfer failed';

        return [
            'success' => false,
            'message' => $errorMessage,
            'raw' => $data,
        ];
    }

    /**
     * Query the current status of an existing Asaas transfer.
     */
    public function getTransferStatus(string $transferId): array
    {
        $baseUrl = rtrim((string) (BusinessSetting::where('key', 'asaas_base_url')->first()?->value ?? 'https://www.asaas.com/api/v3'), '/');
        $apiKey  = (string) (BusinessSetting::where('key', 'asaas_api_key')->first()?->value ?? '');
        $timeout = (int) config('asaas.timeout', 20);

        if ($apiKey === '') {
            return ['success' => false, 'message' => 'Asaas API key not configured'];
        }

        $response = Http::withHeaders([
            'access_token' => $apiKey,
            'Accept'       => 'application/json',
        ])->timeout($timeout)->get($baseUrl . '/transfers/' . $transferId);

        $data = $response->json();

        if ($response->successful() && is_array($data) && !empty($data['id'])) {
            return [
                'success' => true,
                'status'  => strtoupper((string) ($data['status'] ?? '')),
                'value'   => (float) ($data['value'] ?? 0),
                'raw'     => $data,
            ];
        }

        return [
            'success' => false,
            'message' => is_array($data) ? ($data['errors'][0]['description'] ?? 'Asaas query failed') : 'Asaas query failed',
        ];
    }
}
