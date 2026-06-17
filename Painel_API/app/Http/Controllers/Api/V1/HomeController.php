<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\DataSetting;
use Illuminate\Http\Request;
use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\DB;

class HomeController extends Controller
{

    // public function terms_and_conditions(Request $request)
    // {
    //     $current_language = $request->header('X-localization') ?? 'en';
    //     $data = self::get_settings_localization('terms_and_conditions',$current_language);
    //     return response()->json($data);
    // }

// public function terms_and_conditions(Request $request)
// {
//     try {
//         // 🔹 Teste simbólico para confirmar se o endpoint está sendo acessado
//         return response()->json([
//             'key' => 'terms_and_conditions',
//             'lang' => $request->header('X-localization') ?? 'en',
//             'data' => '<h1>Termos de Uso - Turbo Entregas</h1><p>Este é um retorno simbólico de teste para verificar se o Flutter está recebendo corretamente.</p>',
//         ]);
//     } catch (\Exception $e) {
//         // 🔹 Em caso de erro, retorna detalhes
//         return response()->json([
//             'error' => true,
//             'message' => $e->getMessage(),
//             'trace' => $e->getTraceAsString(),
//         ], 500);
//     }
// }

    public function terms_and_conditions(Request $request)
{
    try {
        // Pega idioma atual (do header ou padrão "en")
        $lang = $request->header('X-localization') ?? 'en';

        // Busca registro direto na tabela (ajuste o nome da coluna se for diferente)
        $raw = DB::table('business_settings')
            ->where('key', 'terms_and_conditions')
            ->value('value');

        // Caso não encontre o registro
        if (empty($raw)) {
            return response()->json([
                'status'  => 'error',
                'message' => 'Nenhum registro encontrado para a chave terms_and_conditions.',
            ], 404);
        }

        // Verifica se o conteúdo é JSON
        $decoded = json_decode($raw, true);
        $isJson  = json_last_error() === JSON_ERROR_NONE;

        // Retorna em formato estruturado
        return response()->json([
            'status'  => 'success',
            'key'     => 'terms_and_conditions',
            'lang'    => $lang,
            'format'  => $isJson ? 'json' : 'html',
            'data'    => $isJson ? $decoded : $raw,
        ]);

    } catch (Exception $e) {
        // Loga o erro detalhado
        Log::error('Erro ao carregar terms_and_conditions: ' . $e->getMessage(), [
            'trace' => $e->getTraceAsString(),
        ]);

        // Retorna resposta de erro padronizada
        return response()->json([
            'status'  => 'error',
            'message' => 'Erro interno ao tentar carregar os Termos e Condições.',
            'error'   => $e->getMessage(),
        ], 500);
    }
}

    public function about_us(Request $request)
    {
        $current_language = $request->header('X-localization') ?? 'en';
        $data = self::get_settings_localization('about_us',$current_language);
        return response()->json($data);
    }

    // public function privacy_policy(Request $request)
    // {
    //     $current_language = $request->header('X-localization') ?? 'en';
    //     $data = self::get_settings_localization('privacy_policy',$current_language);
    //     return response()->json($data);
    // }

    public function privacy_policy(Request $request)
    {
        try {
            // Busca direta no banco
            $raw = DB::table('business_settings')
                ->where('key', 'privacy_policy')
                ->value('value');

            // Verifica se achou algo
            if (empty($raw)) {
                return response()->json([
                    'status'  => 'error',
                    'message' => 'Nenhum registro encontrado para a chave privacy_policy.',
                ], 404);
            }

            // Tenta decodificar JSON (caso o valor seja um JSON válido)
            $decoded = json_decode($raw, true);
            $isJson  = json_last_error() === JSON_ERROR_NONE;

            // Retorna resposta formatada
            return response()->json([
                'status'  => 'success',
                'key'     => 'privacy_policy',
                'format'  => $isJson ? 'json' : 'html',
                'data'    => $isJson ? $decoded : $raw,
            ]);

        } catch (Exception $e) {
            // Registra erro no log para depuração
            Log::error('Erro ao carregar privacy_policy: ' . $e->getMessage(), [
                'trace' => $e->getTraceAsString(),
            ]);

            // Retorna resposta de erro detalhada
            return response()->json([
                'status'  => 'error',
                'message' => 'Erro interno ao tentar carregar a política de privacidade.',
                'error'   => $e->getMessage(),
            ], 500);
        }
    }
    public function refund_policy(Request $request)
    {
        $current_language = $request->header('X-localization') ?? 'en';
        $data = self::get_settings_localization('refund_policy',$current_language);
        return response()->json($data);
    }

    public function shipping_policy(Request $request)
    {
        $current_language = $request->header('X-localization') ?? 'en';
        $data = self::get_settings_localization('shipping_policy',$current_language);
        return response()->json($data);
    }

    public function cancelation(Request $request)
    {
        $current_language = $request->header('X-localization') ?? 'en';
        $data = self::get_settings_localization('cancellation_policy',$current_language);
        return response()->json($data);
    }

    public static function get_settings_localization($name,$lang)
    {
        $data = DataSetting::withoutGlobalScope('translate')->with(['translations' => function ($query) use ($lang) {
            return $query->where('locale', $lang);
        }])->where(['key' => $name])->first();
        if($data && count($data->translations)>0){
            $data = $data->translations[0]['value'];
        }else{
            $data = $data ? $data->value: '';
        }
        return $data;
    }
}
