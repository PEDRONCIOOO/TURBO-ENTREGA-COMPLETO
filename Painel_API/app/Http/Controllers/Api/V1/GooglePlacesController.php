<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class GooglePlacesController extends Controller
{
    // Places API (New)
    protected string $placesAutocompleteUrl = 'https://places.googleapis.com/v1/places:autocomplete';
    protected string $placesDetailsBaseUrl  = 'https://places.googleapis.com/v1/places/';

    protected function getApiKey(): string
    {
        return env('GOOGLE_MAPS_API_KEY', 'YOUR_GOOGLE_MAPS_API_KEY');
    }

    public function autocomplete(Request $request)
    {
        $request->validate([
            'input' => 'required|string',
            'lat' => 'nullable|numeric',
            'lng' => 'nullable|numeric',
        ]);

        try {
            $rawInput = trim((string) $request->query('input'));

            // Session token (o app deveria manter o mesmo durante a sessão)
            $sessionToken = (string) ($request->query('sessiontoken') ?? now()->timestamp);

            $payload = [
                'input'        => $rawInput,
                'languageCode' => 'pt-BR',
                'regionCode'   => 'BR',
                'sessionToken' => $sessionToken,

                // tente aproximar do legacy `types=address`
                'includedPrimaryTypes' => [
                    'street_address',
                    'route',
                    'premise',
                    'subpremise',
                ],

            ];

            if ($request->filled(['lat', 'lng'])) {
                $payload['locationBias'] = [
                    'circle' => [
                        'center' => [
                            'latitude' => (float) $request->query('lat'),
                            'longitude' => (float) $request->query('lng'),
                        ],
                        'radius' => 30000.0,
                    ],
                ];
            }

            $response = Http::timeout(10)
                ->withHeaders([
                    'Content-Type'     => 'application/json',
                    'X-Goog-Api-Key'   => $this->getApiKey(),
                    'X-Goog-FieldMask' => implode(',', [
                        'suggestions.placePrediction.placeId',
                        'suggestions.placePrediction.text',
                        'suggestions.placePrediction.structuredFormat',
                        'suggestions.placePrediction.types',
                    ]),
                ])
                ->post($this->placesAutocompleteUrl, $payload);

            $json = $response->json();

            if ($response->failed()) {
                Log::warning('Places(New) autocomplete error', [
                    'status' => $response->status(),
                    'body'   => $response->body(),
                ]);

                // devolve erro no formato legacy
                return response()->json([
                    'status' => 'REQUEST_DENIED',
                    'error_message' => $json['error']['message'] ?? 'Places autocomplete failed',
                    'predictions' => [],
                ], $response->status());
            }

            // ====== CONVERSÃO: NEW -> LEGACY ======
            $predictionsLegacy = [];
            $suggestions = $json['suggestions'] ?? [];

            foreach ($suggestions as $s) {
                $pp = $s['placePrediction'] ?? null;
                if (!$pp) continue;

                $mainText = $pp['structuredFormat']['mainText']['text'] ?? '';
                $secondaryText = $pp['structuredFormat']['secondaryText']['text'] ?? '';
                $description = trim($mainText . ($secondaryText ? ', ' . $secondaryText : ''));

                $predictionsLegacy[] = [
                    'description' => $description,
                    'place_id'    => $pp['placeId'] ?? null,

                    // legacy costumava mandar isso
                    'structured_formatting' => [
                        'main_text' => $mainText,
                        'secondary_text' => $secondaryText,
                    ],

                    // legacy tem "types"
                    'types' => $pp['types'] ?? [],
                ];
            }

            // Resposta no formato antigo
            return response()->json([
                'status' => 'OK',
                'predictions' => $predictionsLegacy,
                'sessiontoken' => $sessionToken,
            ], 200);

        } catch (\Throwable $e) {
            Log::error('Places(New) autocomplete exception', [
                'message' => $e->getMessage(),
                'trace'   => $e->getTraceAsString(),
            ]);

            return response()->json([
                'status'        => 'ERROR',
                'error_message' => 'Internal server error',
                'predictions'   => [],
            ], 500);
        }
    }

    public function placeDetails(Request $request)
    {
        $request->validate([
            'place_id' => 'required|string',
        ]);

        try {
            $placeId = (string) $request->query('place_id');

            $url = $this->placesDetailsBaseUrl . urlencode($placeId);

            $response = Http::timeout(10)
                ->withHeaders([
                    'X-Goog-Api-Key' => $this->getApiKey(),

                    // precisamos de campos para montar o "result" legacy
                    'X-Goog-FieldMask' => implode(',', [
                        'id',
                        'displayName',
                        'formattedAddress',
                        'addressComponents',
                        'location',
                    ]),
                ])
                ->get($url, [
                    'languageCode' => 'pt-BR',
                    'regionCode'   => 'BR',
                ]);

            $json = $response->json();

            if ($response->failed()) {
                Log::warning('Places(New) details error', [
                    'status' => $response->status(),
                    'body'   => $response->body(),
                ]);

                // legacy também devolvia esses campos
                return response()->json([
                    'status' => 'REQUEST_DENIED',
                    'error_message' => $json['error']['message'] ?? 'Place details failed',
                    'result' => null,
                ], $response->status());
            }

            // ====== CONVERSÃO: NEW -> LEGACY ======
            $lat = $json['location']['latitude'] ?? null;
            $lng = $json['location']['longitude'] ?? null;

            // address_components legacy
            $addressComponentsLegacy = [];
            foreach (($json['addressComponents'] ?? []) as $ac) {
                $addressComponentsLegacy[] = [
                    'long_name'  => $ac['longText'] ?? '',
                    'short_name' => $ac['shortText'] ?? '',
                    'types'      => $ac['types'] ?? [],
                ];
            }

            $resultLegacy = [
                'name' => $json['displayName']['text'] ?? null,
                'formatted_address' => $json['formattedAddress'] ?? null,
                'address_components' => $addressComponentsLegacy,
                'geometry' => [
                    'location' => [
                        'lat' => $lat,
                        'lng' => $lng,
                    ],
                ],
            ];

            // Resposta no formato antigo
            return response()->json([
                'status' => 'OK',
                'result' => $resultLegacy,
            ], 200);

        } catch (\Throwable $e) {
            Log::error('Places(New) details exception', [
                'message' => $e->getMessage(),
                'trace'   => $e->getTraceAsString(),
            ]);

            return response()->json([
                'status'        => 'ERROR',
                'error_message' => 'Internal server error',
                'result'        => null,
            ], 500);
        }
    }
}
