<?php

namespace App\Http\Middleware;

use App\Models\UserApiToken;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class ExternalApiToken
{
    /**
     * Autentica requisições externas via Bearer token vinculado a um usuário.
     * O token é passado no cabeçalho Authorization: Bearer {token}
     */
    public function handle(Request $request, Closure $next): Response
    {
        $bearerToken = $request->bearerToken();

        if (!$bearerToken) {
            return response()->json([
                'errors' => [['code' => 'unauthorized', 'message' => 'Token de API não informado. Passe o token no cabeçalho Authorization: Bearer {token}']],
            ], 401);
        }

        $apiToken = UserApiToken::with('user')
            ->where('token', $bearerToken)
            ->where('is_active', true)
            ->first();

        if (!$apiToken || !$apiToken->user) {
            return response()->json([
                'errors' => [['code' => 'unauthorized', 'message' => 'Token de API inválido ou inativo.']],
            ], 401);
        }

        if ($apiToken->user->status == 0) {
            return response()->json([
                'errors' => [['code' => 'unauthorized', 'message' => 'Usuário vinculado ao token está bloqueado.']],
            ], 403);
        }

        // Injeta o token e o usuário no request para uso nos controllers
        $request->merge(['_api_token' => $apiToken]);
        $request->setUserResolver(fn() => $apiToken->user);

        return $next($request);
    }
}
