<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;

class FcmService
{
    public function sendToTokens(array $tokens, string $title, string $body, array $data = []): array
    {
        if (empty($tokens)) {
            return ['success' => false, 'message' => 'No FCM tokens'];
        }

        $serverKey = config('services.fcm.server_key');

        $payload = [
            'registration_ids' => $tokens,   // lista de tokens
            'notification'     => [
                'title' => $title,
                'body'  => $body,
                'sound' => 'default',
            ],
            'data' => $data, // dados extras pro app abrir tela, etc
        ];

        $response = Http::withHeaders([
            'Authorization' => 'key='.$serverKey,
            'Content-Type'  => 'application/json',
        ])->post('https://fcm.googleapis.com/fcm/send', $payload);

        return [
            'success' => $response->successful(),
            'status'  => $response->status(),
            'body'    => $response->json(),
        ];
    }
}
