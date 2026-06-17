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
        'category_id' => 'required|integer|exists:parcel_categories,id',
        'distance_km' => 'required|numeric|min:0',
        'zone_id'     => 'nullable|integer',
        // extra_charge vem no payload mas não será usado no cálculo
        'extra_charge'=> 'nullable|numeric|min:0',
    ]);

    try {
        $categoryId = (int) $request->input('category_id');
        $distanceKm = (float) $request->input('distance_km');
        $zoneId     = $request->input('zone_id');

        /** @var \App\Models\ParcelCategory $category */
        $category = ParcelCategory::findOrFail($categoryId);

        // ----------------- CONFIG DO PAINEL -----------------
        $minKm     = (float) ($category->minimum_shipping_distance_km ?? 0);   // ex.: 1
        $minCharge = (float) ($category->parcel_minimum_shipping_charge ?? 0); // ex.: 6

        // Default por km se precisar (opcional)
        $perKmDefault = (float) ($category->parcel_per_km_shipping_charge ?? 0);

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

        // ----------------- CASO 1: DISTÂNCIA <= MÍNIMO -----------------
        if ($distanceKm <= $minKm) {
            $baseCharge       = $minCharge;
            $distanceUsedKm   = $distanceKm;
            $lastPricePerKm   = null;
        } else {
            // ----------------- CASO 2: PASSOU DO MÍNIMO -----------------
            // Arredonda pra cima: 1.1 -> 2, 1.9 -> 2, 15.2 -> 16
            $distanceIntKm  = (int) ceil($distanceKm);
            $distanceUsedKm = (float) $distanceIntKm;

            // Começa com o valor mínimo (cobre de 0 até minKm)
            $baseCharge     = $minCharge;
            $cursorKm       = $minKm; // a partir daqui vamos cobrar por km
            $lastPricePerKm = null;

            // Cobra km extras por faixa
            if (!empty($rules)) {
                foreach ($rules as $rule) {
                    if ($cursorKm >= $distanceIntKm) {
                        break; // já cobrimos tudo
                    }

                    $ruleFrom = isset($rule['from']) ? (float)$rule['from'] : 0.0;
                    $ruleTo   = array_key_exists('to', $rule) && $rule['to'] !== null
                        ? (float)$rule['to']
                        : null;

                    $pricePerKm = isset($rule['price_per_km'])
                        ? (float)$rule['price_per_km']
                        : $perKmDefault;

                    // Início do trecho dentro desta faixa
                    $segmentStart = max($cursorKm, $ruleFrom);
                    if ($segmentStart >= $distanceIntKm) {
                        continue;
                    }

                    // Fim da faixa (exclusivo)
                    $segmentEnd = $ruleTo !== null
                        ? min($distanceIntKm, $ruleTo)
                        : $distanceIntKm;

                    if ($segmentEnd <= $segmentStart) {
                        continue;
                    }

                    $segmentLengthKm = $segmentEnd - $segmentStart;

                    // Soma valor deste trecho
                    $baseCharge     += $segmentLengthKm * $pricePerKm;
                    $lastPricePerKm  = $pricePerKm;
                    $cursorKm        = $segmentEnd;
                }

                // Se ainda sobrou distância sem faixa explícita,
                // usa o perKmDefault (se > 0)
                if ($cursorKm < $distanceIntKm && $perKmDefault > 0) {
                    $remainingKm    = $distanceIntKm - $cursorKm;
                    $baseCharge    += $remainingKm * $perKmDefault;
                    $lastPricePerKm = $perKmDefault;
                }
            } else {
                // Sem regras: cobra tudo que passou do mínimo com perKmDefault
                $extraKm        = max(0, $distanceIntKm - $minKm);
                $baseCharge    += $extraKm * $perKmDefault;
                $lastPricePerKm = $perKmDefault;
            }
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
            'distance_km'           => $distanceKm,       // distância real enviada
            'distance_used'         => $distanceUsedKm,   // distância usada no cálculo (ceil)
            'minimum_distance_km'   => $minKm,
            'minimum_charge'        => $minCharge,
            'price_per_km_applied'  => $lastPricePerKm,   // última faixa aplicada
            'extra_charge'          => 0,                 // não usamos mais extra_charge do request
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



}
