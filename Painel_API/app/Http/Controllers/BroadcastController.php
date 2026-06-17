<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\DeliveryMan;
use App\Services\FcmService;
use Illuminate\Http\Request;

class BroadcastController extends Controller
{
    public function notifyAllDeliveryMen(Request $request, FcmService $fcm)
    {
        $request->validate([
            'title' => 'required|string',
            'body'  => 'required|string',
        ]);

        // pega todos FCM dos entregadores
        $tokens = DeliveryMan::whereNotNull('fcm_token')
            ->where('fcm_token', '!=', '')
            ->pluck('fcm_token')
            ->unique()
            ->values()
            ->all();

        if (empty($tokens)) {
            return response()->json([
                'message' => 'Nenhum entregador com FCM cadastrado',
            ], 200);
        }

        $result = $fcm->sendToTokens(
            $tokens,
            $request->title,
            $request->body,
            [
                'type' => 'broadcast_entregador', // você usa no app pra saber o tipo
            ]
        );

        return response()->json([
            'message' => 'Notificação enviada',
            'result'  => $result,
            'total_tokens' => count($tokens),
        ], 200);
    }
}
