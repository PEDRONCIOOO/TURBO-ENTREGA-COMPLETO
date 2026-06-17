<?php

namespace App\Http\Controllers\Api\V1;

use App\CentralLogics\Helpers;
use App\Http\Controllers\Controller;
use App\Models\ParcelCategory;
use Illuminate\Http\Request;

class ParcelCategoryController extends Controller
{
    public function index(Request $request)
    {
        try {
            $parcel_categories = ParcelCategory::
                when(config('module.current_module_data'), function ($query) {
                    $query->module(config('module.current_module_data')['id']);
                })
                ->active()
                ->get();

            // Mantém o formato padrão (nome, imagem, etc.)
            Helpers::parcel_category_data_formatting($parcel_categories, true);

            // Garante que os novos campos vão para o app Flutter
            $data = $parcel_categories->map(function ($category) {
                // distance_pricing_rules pode vir como array (cast) ou JSON; normaliza
                $rulesRaw = $category->distance_pricing_rules;
                if (!is_array($rulesRaw)) {
                    $rules = json_decode($rulesRaw ?? '[]', true) ?? [];
                } else {
                    $rules = $rulesRaw;
                }

                return [
                    'id'   => $category->id,
                    'name' => $category->name,
                    'description' => $category->description,

                    // imagem já formatada pelo helper / accessor
                    'image' => $category->image_full_url ?? $category->image,

                    // campos antigos de frete
                    'parcel_per_km_shipping_charge'  => (float) $category->parcel_per_km_shipping_charge,
                    'parcel_minimum_shipping_charge' => (float) $category->parcel_minimum_shipping_charge,

                    // NOVOS CAMPOS
                    'minimum_shipping_distance_km' => (float) ($category->minimum_shipping_distance_km ?? 0),
                    'distance_pricing_rules'       => $rules,
                    'charge_fractional_km'         => (bool) $category->charge_fractional_km,
                    'fractional_rounding'          => $category->fractional_rounding ?? 'ceil',
                    'extra_stop_percentage'        => (float) ($category->extra_stop_percentage ?? 40),
                    'extra_stop_fee_basis'         => $category->extra_stop_fee_basis ?? 'main_fee',
                ];
            })->values();

            return response()->json($data, 200);
        } catch (\Exception $e) {
            info($e->getMessage());
            return response()->json([], 200);
        }
    }

  public function calculateDeliveryFee(Request $request)
{
    $request->validate([
        'category_id'   => 'required|integer|exists:parcel_categories,id',
        'distance_km'   => 'required|numeric|min:0',
        'zone_id'       => 'nullable|integer',
        'extra_charge'  => 'nullable|numeric|min:0', // continua ignorado no cálculo
        'is_return'     => 'nullable|in:0,1',        // ✅ novo
    ]);

    try {
        $categoryId = (int) $request->input('category_id');
        $distanceKm = (float) $request->input('distance_km');
        $zoneId     = $request->input('zone_id');
        $isReturn   = (int) ($request->input('is_return', 0)) === 1; // ✅ novo

        /** @var \App\Models\ParcelCategory $category */
        $category = ParcelCategory::findOrFail($categoryId);

        // ----------------- CONFIG DO PAINEL -----------------
        $minKm     = (float) ($category->minimum_shipping_distance_km ?? 0);     // ex.: 1
        $minCharge = (float) ($category->parcel_minimum_shipping_charge ?? 0);   // ex.: 6

        // Default por km (se precisar)
        $perKmDefault = (float) ($category->parcel_per_km_shipping_charge ?? 0);

        // ✅ default do retorno (se não vier na faixa, usa default)
        // Se você criar uma coluna default de retorno, troque aqui.
        $perKmReturnDefault = (float) ($category->parcel_return_per_km_shipping_charge ?? 0);

        // Regras em JSON (distance_pricing_rules)
        $rulesRaw = $category->distance_pricing_rules;
        if (!is_array($rulesRaw)) {
            $rules = json_decode($rulesRaw ?? '[]', true) ?? [];
        } else {
            $rules = $rulesRaw;
        }

        // Ordena regras por "from"
        usort($rules, function ($a, $b) {
            $fromA = isset($a['from']) ? (float)$a['from'] : 0;
            $fromB = isset($b['from']) ? (float)$b['from'] : 0;
            return $fromA <=> $fromB;
        });

        // ----------------- RESULTADOS -----------------
        $distanceUsedKm   = $distanceKm;
        $lastPricePerKm   = null;
        $lastReturnPerKm  = null;

        $outboundCharge   = 0.0; // ida (somente parte variável por km acima do min)
        $returnCharge     = 0.0; // volta (somente parte variável por km acima do min)
        $baseCharge       = 0.0; // min + ida (+ volta se marcado)

        // ----------------- CASO 1: DISTÂNCIA <= MÍNIMO -----------------
        if ($distanceKm <= $minKm) {
            // Você já cobra apenas o mínimo
            $baseCharge     = $minCharge;
            $distanceUsedKm = $distanceKm;

            // Se quiser cobrar retorno mesmo dentro do mínimo, você pode decidir:
            // - manter só minCharge
            // - ou somar outro minCharge
            // Aqui vou manter sua regra atual: só mínimo.
            // Se quiser dobrar mínimo quando is_return=1, me diga.
        } else {
            // ----------------- CASO 2: PASSOU DO MÍNIMO -----------------
            // Respeita charge_fractional_km: usa km exato ou arredondado conforme configuração
            $distanceUsedKm = self::resolveEffectiveDistance($category, $distanceKm);
            $distanceIntKm  = $distanceUsedKm; // alias float — mantém restante do código sem mudança

            // Começa com o valor mínimo (cobre de 0 até minKm)
            $baseCharge     = $minCharge;
            $cursorKm       = $minKm;

            if (!empty($rules)) {
                foreach ($rules as $rule) {
                    if ($cursorKm >= $distanceIntKm) {
                        break;
                    }

                    $ruleFrom = isset($rule['from']) ? (float)$rule['from'] : 0.0;
                    $ruleTo   = array_key_exists('to', $rule) && $rule['to'] !== null
                        ? (float)$rule['to']
                        : null;

                    $pricePerKm = isset($rule['price_per_km'])
                        ? (float)$rule['price_per_km']
                        : $perKmDefault;

                    // ✅ retorno por km (novo)
                    $returnPricePerKm = isset($rule['return_price_per_km'])
                        ? (float)$rule['return_price_per_km']
                        : $perKmReturnDefault;

                    $segmentStart = max($cursorKm, $ruleFrom);
                    if ($segmentStart >= $distanceIntKm) {
                        continue;
                    }

                    $segmentEnd = $ruleTo !== null
                        ? min($distanceIntKm, $ruleTo)
                        : $distanceIntKm;

                    if ($segmentEnd <= $segmentStart) {
                        continue;
                    }

                    $segmentLengthKm = $segmentEnd - $segmentStart;

                    // ---- Ida ----
                    $outboundCharge  += $segmentLengthKm * $pricePerKm;
                    $lastPricePerKm   = $pricePerKm;

                    // ---- Volta (se marcado) ----
                    if ($isReturn) {
                        // se não tiver return_price_per_km e default=0, o retorno fica 0
                        $returnCharge      += $segmentLengthKm * $returnPricePerKm;
                        $lastReturnPerKm    = $returnPricePerKm;
                    }

                    $cursorKm = $segmentEnd;
                }

                // Sobrou distância sem faixa explícita -> usa defaults
                if ($cursorKm < $distanceIntKm) {
                    $remainingKm = $distanceIntKm - $cursorKm;

                    if ($perKmDefault > 0) {
                        $outboundCharge  += $remainingKm * $perKmDefault;
                        $lastPricePerKm   = $perKmDefault;
                    }

                    if ($isReturn && $perKmReturnDefault > 0) {
                        $returnCharge     += $remainingKm * $perKmReturnDefault;
                        $lastReturnPerKm   = $perKmReturnDefault;
                    }
                }

            } else {
                // Sem regras: cobra tudo que passou do mínimo com defaults
                $extraKm = max(0, $distanceIntKm - $minKm);

                $outboundCharge  += $extraKm * $perKmDefault;
                $lastPricePerKm   = $perKmDefault;

                if ($isReturn) {
                    $returnCharge    += $extraKm * $perKmReturnDefault;
                    $lastReturnPerKm  = $perKmReturnDefault;
                }
            }

            // Soma mínimo + ida (+ volta)
            $baseCharge += $outboundCharge + ($isReturn ? $returnCharge : 0);
        }

        // ----------------- ZONA (OPCIONAL) -----------------
        $zoneIncreasePercent = 0;

        if (!empty($zoneId)) {
            $zone = \App\Models\Zone::find($zoneId);
            if ($zone && $zone->increase_delivery_fee_status == 1) {
                $zoneIncreasePercent = (float) $zone->increase_delivery_fee;
                $baseCharge += $baseCharge * ($zoneIncreasePercent / 100);
            }
        }

        // ----------------- VALOR FINAL -----------------
        $finalCharge = round($baseCharge, 2);

        return response()->json([
            'category_id'           => $category->id,
            'distance_km'           => $distanceKm,
            'distance_used'         => $distanceUsedKm,
            'minimum_distance_km'   => $minKm,
            'minimum_charge'        => $minCharge,

            // ✅ breakdown
            'is_return'             => $isReturn ? 1 : 0,
            'outbound_charge'       => round($outboundCharge, 2),
            'return_charge'         => round($returnCharge, 2),

            'price_per_km_applied'  => $lastPricePerKm,
            'return_price_applied'  => $lastReturnPerKm,

            'extra_charge'          => 0,
            'zone_id'               => $zoneId,
            'zone_increase_percent' => $zoneIncreasePercent,
            'delivery_fee'          => $finalCharge,
        ], 200);

    } catch (\Exception $e) {
        info('calculateDeliveryFee error: '.$e->getMessage());

        return response()->json([
            'message' => 'Could not calculate delivery fee',
        ], 500);
    }
}

/**
 * POST /api/v1/parcel/additional-stop/calculate-fee
 *
 * Calcula a taxa extra para uma ou mais paradas adicionais de um pedido parcel.
 *
 * Body:
 * {
 *   "category_id": 1,
 *   "zone_id": 2,          // opcional
 *   "stops": [
 *     { "distance_km": 3.5 },
 *     { "distance_km": 2.0 }
 *   ]
 * }
 */
public function calculateAdditionalStopFee(Request $request)
{
    $request->validate([
        'category_id'         => 'required|integer|exists:parcel_categories,id',
        'stops'               => 'required|array|min:1|max:5',
        'stops.*.distance_km' => 'required|numeric|min:0',
        'zone_id'             => 'nullable|integer',
        'main_distance_km'    => 'nullable|numeric|min:0',
    ]);

    try {
        $category    = ParcelCategory::findOrFail($request->category_id);
        $zoneId      = $request->input('zone_id');
        $stopPercent = (float) ($category->extra_stop_percentage ?? 40);

        $zoneIncreasePercent = 0.0;
        if (!empty($zoneId)) {
            $zone = \App\Models\Zone::find($zoneId);
            if ($zone && $zone->increase_delivery_fee_status == 1) {
                $zoneIncreasePercent = (float) $zone->increase_delivery_fee;
            }
        }

        $stopsResult    = [];
        $totalExtraFee  = 0.0;
        $mainDistanceKm = (float) ($request->input('main_distance_km') ?? 0);

        $feeBasis = $category->extra_stop_fee_basis ?? 'main_fee';

        foreach ($request->stops as $index => $stop) {
            $distanceKm = (float) $stop['distance_km'];

            // Valida que a parada extra não é mais distante que a entrega principal
            if ($mainDistanceKm > 0 && $distanceKm > $mainDistanceKm) {
                return response()->json([
                    'message'           => 'A distância da parada extra (' . round($distanceKm, 2) . ' km) não pode ser maior que a da entrega principal (' . round($mainDistanceKm, 2) . ' km).',
                    'extra_distance_km' => $distanceKm,
                    'main_distance_km'  => $mainDistanceKm,
                ], 422);
            }

            // Calcula a taxa base conforme a configuração da categoria:
            // 'main_fee'       → taxa calculada para a distância PRINCIPAL × %
            // 'extra_distance' → taxa calculada para a distância DA PARADA EXTRA × %
            if ($feeBasis === 'main_fee' && $mainDistanceKm > 0) {
                $fullFee = self::computeParcelFeeForDistance($category, $mainDistanceKm, $zoneIncreasePercent);
            } else {
                $fullFee = self::computeParcelFeeForDistance($category, $distanceKm, $zoneIncreasePercent);
            }
            $charge = round($fullFee * ($stopPercent / 100), 2);

            $stopsResult[] = [
                'sequence'              => $index + 1,
                'distance_km'           => $distanceKm,
                'full_fee'              => round($fullFee, 2),
                'extra_delivery_charge' => $charge,
            ];
            $totalExtraFee += $charge;
        }

        return response()->json([
            'category_id'           => $category->id,
            'zone_id'               => $zoneId,
            'extra_stop_percentage' => $stopPercent,
            'stops'                 => $stopsResult,
            'total_extra_charge'    => round($totalExtraFee, 2),
        ], 200);

    } catch (\Exception $e) {
        info('calculateAdditionalStopFee error: ' . $e->getMessage());
        return response()->json(['message' => 'Could not calculate fee'], 500);
    }
}

/**
 * Calcula o valor do frete parcel para uma distância, dada a configuração da categoria.
/**
 * Calcula o frete parcel para uma distância.
 * Suporta ida simples ou ida+volta (is_return).
 * Reutilizado internamente (PlaceNewOrder, calculateAdditionalStopFee).
 */
public static function computeParcelFeeForDistance(
    ParcelCategory $category,
    float $distanceKm,
    float $zoneIncreasePercent = 0.0,
    bool $isReturn = false
): float {
    $minKm              = (float) ($category->minimum_shipping_distance_km ?? 0);
    $minCharge          = (float) ($category->parcel_minimum_shipping_charge ?? 0);
    $perKmDefault       = (float) ($category->parcel_per_km_shipping_charge ?? 0);
    $perKmReturnDefault = (float) ($category->parcel_return_per_km_shipping_charge ?? 0);

    $rulesRaw = $category->distance_pricing_rules;
    $rules    = is_array($rulesRaw) ? $rulesRaw : (json_decode($rulesRaw ?? '[]', true) ?? []);

    usort($rules, function ($a, $b) {
        return ((float)($a['from'] ?? 0)) <=> ((float)($b['from'] ?? 0));
    });

    $baseCharge   = $minCharge;
    $returnCharge = 0.0;

    if ($distanceKm > $minKm) {
        $distanceIntKm = self::resolveEffectiveDistance($category, $distanceKm);
        $cursorKm      = $minKm;

        if (!empty($rules)) {
            foreach ($rules as $rule) {
                if ($cursorKm >= $distanceIntKm) {
                    break;
                }
                $ruleFrom         = (float) ($rule['from'] ?? 0);
                $ruleTo           = array_key_exists('to', $rule) && $rule['to'] !== null ? (float) $rule['to'] : null;
                $pricePerKm       = (float) ($rule['price_per_km'] ?? $perKmDefault);
                $returnPricePerKm = (float) ($rule['return_price_per_km'] ?? $perKmReturnDefault);

                $segmentStart = max($cursorKm, $ruleFrom);
                if ($segmentStart >= $distanceIntKm) {
                    continue;
                }
                $segmentEnd = $ruleTo !== null ? min($distanceIntKm, $ruleTo) : $distanceIntKm;
                if ($segmentEnd <= $segmentStart) {
                    continue;
                }
                $segLen      = $segmentEnd - $segmentStart;
                $baseCharge += $segLen * $pricePerKm;
                if ($isReturn) {
                    $returnCharge += $segLen * $returnPricePerKm;
                }
                $cursorKm = $segmentEnd;
            }

            if ($cursorKm < $distanceIntKm) {
                $remaining = $distanceIntKm - $cursorKm;
                if ($perKmDefault > 0) {
                    $baseCharge += $remaining * $perKmDefault;
                }
                if ($isReturn && $perKmReturnDefault > 0) {
                    $returnCharge += $remaining * $perKmReturnDefault;
                }
            }
        } else {
            $extraKm     = max(0, $distanceIntKm - $minKm);
            $baseCharge += $extraKm * $perKmDefault;
            if ($isReturn) {
                $returnCharge += $extraKm * $perKmReturnDefault;
            }
        }
    }

    $total = $baseCharge + $returnCharge;

    if ($zoneIncreasePercent > 0) {
        $total += $total * ($zoneIncreasePercent / 100);
    }

    return $total;
}

/**
 * Determina a distância efetiva a ser usada no cálculo conforme configuração da categoria.
 *
 * charge_fractional_km = true  → usa o valor decimal exato (ex.: 2.7 km)
 * charge_fractional_km = false → arredonda conforme fractional_rounding:
 *   'ceil'  (padrão) → teto  (2.7 → 3)
 *   'floor'          → piso  (2.7 → 2)
 *   'round'          → round (2.7 → 3, 2.3 → 2)
 */
private static function resolveEffectiveDistance(ParcelCategory $category, float $distanceKm): float
{
    if ($category->charge_fractional_km) {
        return $distanceKm; // km exato — sem arredondamento
    }

    $rounding = $category->fractional_rounding ?? 'ceil';
    switch ($rounding) {
        case 'floor': return (float) floor($distanceKm);
        case 'round': return (float) round($distanceKm);
        default:      return (float) ceil($distanceKm); // 'ceil' é o padrão
    }
}

}
