<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class GooglePlacesController extends Controller
{
    protected string $placesAutocompleteUrl = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
    protected string $placesDetailsUrl      = 'https://maps.googleapis.com/maps/api/place/details/json';

    protected function getApiKey(): string
    {
        // pode configurar também em config/services.php se quiser
        return env('GOOGLE_MAPS_API_KEY', 'YOUR_GOOGLE_MAPS_API_KEY');
    }

public function autocomplete(Request $request)
{
    $request->validate([
        'input' => 'required|string',
    ]);

    try {
        $rawInput = $request->query('input'); // o que veio do app
        $normalized = mb_strtolower($rawInput ?? '', 'UTF-8');

        $forcedInput = $rawInput;

        // Se o usuário NÃO escreveu nada sobre Dourados/MS,
        // a gente "completa" pra focar a cidade:
        if (
            !str_contains($normalized, 'dourados') &&
            !str_contains($normalized, 'ms') &&
            !str_contains($normalized, 'mato grosso do sul')
        ) {
            $forcedInput = $rawInput . ', Dourados - MS';
        }

        $params = [
            'input'        => $forcedInput,
            'key'          => $this->getApiKey(),
            'components'   => 'country:br',
            'types'        => 'address',
            'language'     => 'pt-BR',
            'sessiontoken' => $request->query('sessiontoken') ?? now()->timestamp,

            // opcional: ainda mais “peso” em Dourados (raio ~25km do centro)
            // 'location' => '-22.2231,-54.8120',
            // 'radius'   => 25000,
        ];

        $response = Http::timeout(10)->get($this->placesAutocompleteUrl, $params);

        if ($response->failed()) {
            Log::warning('Google Places Autocomplete error', [
                'status' => $response->status(),
                'body'   => $response->body(),
            ]);
        }

        $json = $response->json();

        // NÃO mexemos nas predictions aqui.
        // O retorno fica idêntico ao do Google, só que já focado em Dourados-MS.
        return response()->json($json, $response->status());

    } catch (\Throwable $e) {
        Log::error('Google Places Autocomplete exception', [
            'message' => $e->getMessage(),
            'trace'   => $e->getTraceAsString(),
        ]);

        return response()->json([
            'status'        => 'ERROR',
            'error_message' => 'Internal server error',
        ], 500);
    }
}


    public function placeDetails(Request $request)
    {
        $request->validate([
            'place_id' => 'required|string',
        ]);

        try {
            $params = [
                'place_id' => $request->query('place_id'),
                'fields'   => 'geometry,name,formatted_address,address_components',
                'key'      => $this->getApiKey(),
                'language' => 'pt-BR',
            ];

            $response = Http::timeout(10)->get($this->placesDetailsUrl, $params);

            if ($response->failed()) {
                Log::warning('Google Places Details error', [
                    'status' => $response->status(),
                    'body'   => $response->body(),
                ]);
            }

            return response()->json($response->json(), $response->status());
        } catch (\Throwable $e) {
            Log::error('Google Places Details exception', [
                'message' => $e->getMessage(),
                'trace'   => $e->getTraceAsString(),
            ]);

            return response()->json([
                'status'        => 'ERROR',
                'error_message' => 'Internal server error',
            ], 500);
        }
    }
}
