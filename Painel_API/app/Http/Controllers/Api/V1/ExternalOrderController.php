<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Api\V1\ParcelCategoryController;
use App\Http\Controllers\Controller;
use App\Models\BusinessSetting;
use App\Models\CustomerAddress;
use App\Models\Module;
use App\Models\Order;
use App\Models\ParcelCategory;
use App\Models\UserApiToken;
use App\Models\Zone;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Validator;
use MatanYadaev\EloquentSpatial\Objects\Point;

/**
 * Controller para pedidos enviados por sistemas externos (terceiros).
 * Autenticação via Bearer token vinculado a um usuário (remetente).
 *
 * Todos os endpoints exigem o middleware `external.api.token`.
 */
class ExternalOrderController extends Controller
{
    /**
     * POST /api/v1/external/orders
     *
     * Cria um pedido de entrega enviado por sistema externo.
     * O saldo da wallet do remetente é reservado imediatamente.
     *
     * Payload:
     * {
     *   "recipient_name":    "João Silva",
     *   "recipient_phone":   "+5511999999999",
     *   "recipient_address": "Rua das Flores, 100 - São Paulo",
    *   "recipient_lat":     -23.550520, // opcional
    *   "recipient_lng":     -46.633308, // opcional
     *   "external_reference_id": "EXT-001", // (opcional) ID do pedido no sistema de origem
     *   "note": "Frágil"                    // (opcional)
     * }
     */
    public function createOrder(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'recipient_name'       => 'required|string|max:100',
            'recipient_phone'      => 'required|string|max:20',
            'recipient_address'    => 'required|string|max:500',
            'recipient_lat'        => 'nullable|numeric|between:-90,90',
            'recipient_lng'        => 'nullable|numeric|between:-180,180',
            'external_reference_id'=> 'nullable|string|max:100',
            'note'                 => 'nullable|string|max:500',
            'category_id'          => 'nullable|integer|exists:parcel_categories,id',
            'is_return'            => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'errors' => collect($validator->errors()->toArray())
                    ->map(fn($msgs, $field) => ['code' => $field, 'message' => $msgs[0]])
                    ->values(),
            ], 422);
        }

        /** @var \App\Models\UserApiToken $apiToken */
        $apiToken = $request->get('_api_token');
        $sender   = $apiToken->user;

        // Se lat/lng não forem enviados, tenta converter a partir do endereço.
        $recipientLat = $request->filled('recipient_lat') ? (float) $request->recipient_lat : null;
        $recipientLng = $request->filled('recipient_lng') ? (float) $request->recipient_lng : null;

        if ($recipientLat === null || $recipientLng === null) {
            $resolvedCoordinates = $this->resolveCoordinatesFromAddress((string) $request->recipient_address);

            if (!$resolvedCoordinates) {
                return response()->json([
                    'errors' => [[
                        'code' => 'recipient_address',
                        'message' => 'Não foi possível localizar o endereço do destinatário. Envie recipient_lat e recipient_lng ou um endereço mais completo.',
                    ]],
                ], 422);
            }

            $recipientLat = $resolvedCoordinates['lat'];
            $recipientLng = $resolvedCoordinates['lng'];
        }

        $senderCoordinates = $this->resolveSenderCoordinates($sender->id);

        if (!$senderCoordinates) {
            return response()->json([
                'errors' => [[
                    'code' => 'sender_address',
                    'message' => 'O cliente vinculado ao token não possui endereço de retirada cadastrado. Configure o endereço na página de Tokens de API.',
                ]],
            ], 422);
        }

        $feeData = $this->calculateDeliveryFee(
            (float) $senderCoordinates['lat'],
            (float) $senderCoordinates['lng'],
            (float) $recipientLat,
            (float) $recipientLng,
            $request->filled('category_id') ? (int) $request->category_id : null,
            filter_var($request->input('is_return', false), FILTER_VALIDATE_BOOLEAN)
        );

        $orderAmount = (float) $feeData['delivery_fee'];

        // Verifica saldo disponível (wallet_balance - reserved_balance)
        $availableBalance = $sender->wallet_balance - $apiToken->reserved_balance;

        if ($availableBalance < $orderAmount) {
            return response()->json([
                'errors' => [[
                    'code'    => 'insufficient_balance',
                    'message' => 'Saldo insuficiente na wallet. Disponível: ' . number_format($availableBalance, 2, ',', '.'),
                ]],
            ], 422);
        }

        // Determina a zona pelo endereço de destino
        $zone = Zone::whereContains('coordinates', new Point(
            $recipientLat,
            $recipientLng,
            config('app.point_srid', 4326)
        ))->first();

        // Tenta encontrar o módulo parcel ativo
        $parcelModule = Module::where('module_type', 'parcel')->first();

        DB::beginTransaction();
        try {
            // Reserva o saldo no token (bloqueia sem debitar ainda)
            $apiToken->increment('reserved_balance', $orderAmount);

            $deliveryAddress = json_encode([
                'contact_person_name'   => $request->recipient_name,
                'contact_person_number' => $request->recipient_phone,
                'address'               => $request->recipient_address,
                'address_type'          => 'Delivery',
                'latitude'              => (string) $recipientLat,
                'longitude'             => (string) $recipientLng,
                'house'                 => '',
                'road'                  => '',
                'floor'                 => '',
            ]);

            $lastId = Order::max('id') ?? 99999;

            $order = new Order();
            $order->id                    = $lastId + 1;
            $order->user_id               = $sender->id;
            $order->order_amount          = $orderAmount;
            $order->payment_status        = 'unpaid'; // será debitado ao confirmar entrega
            $order->order_status          = 'pending';
            $order->payment_method        = 'wallet';
            $order->order_note            = $request->note;
            $order->order_type            = 'parcel';
            $order->delivery_charge       = $orderAmount;
            $order->original_delivery_charge = $orderAmount;
            $order->delivery_address      = $deliveryAddress;
            $order->is_guest              = 0;
            $order->otp                   = rand(1000, 9999);
            $order->zone_id               = $zone?->id;
            $order->module_id             = $parcelModule?->id;
            $order->external_reference_id = $request->external_reference_id;
            $order->api_token_id          = $apiToken->id;
            $order->pending               = now();
            $order->created_at            = now();
            $order->updated_at            = now();
            $order->save();

            DB::commit();

            return response()->json([
                'message'              => 'Pedido criado com sucesso.',
                'order_id'             => $order->id,
                'external_reference_id'=> $order->external_reference_id,
                'order_status'         => $order->order_status,
                'order_amount'         => $order->order_amount,
                'distance_km'          => $feeData['distance_km'],
                'distance_source'      => $feeData['distance_source'],
                'category_id'          => $feeData['category_id'],
                'is_return'            => $feeData['is_return'],
                'outbound_charge'      => $feeData['outbound_charge'],
                'return_charge'        => $feeData['return_charge'],
                'zone_increase_percent'=> $feeData['zone_increase_percent'],
                'reserved_balance'     => (float) $apiToken->fresh()->reserved_balance,
            ], 201);

        } catch (\Throwable $e) {
            DB::rollBack();
            report($e);
            return response()->json([
                'errors' => [['code' => 'server_error', 'message' => 'Erro ao criar o pedido. Tente novamente.']],
            ], 500);
        }
    }

    /**
     * DELETE /api/v1/external/orders/{id}
     *
     * Cancela um pedido externo. O saldo reservado é devolvido à wallet se o
     * pedido ainda estiver em status que permita cancelamento.
     *
     * O {id} pode ser o ID interno do pedido (numérico) ou o external_reference_id.
     */
    public function cancelOrder(Request $request, string $id): JsonResponse
    {
        /** @var \App\Models\UserApiToken $apiToken */
        $apiToken = $request->get('_api_token');
        $sender   = $apiToken->user;

        // Busca o pedido pelo ID interno ou pelo external_reference_id
        $order = Order::where('api_token_id', $apiToken->id)
            ->where(function ($q) use ($id) {
                $q->where('id', is_numeric($id) ? $id : 0)
                  ->orWhere('external_reference_id', $id);
            })
            ->first();

        if (!$order) {
            return response()->json([
                'errors' => [['code' => 'not_found', 'message' => 'Pedido não encontrado ou não pertence a este token.']],
            ], 404);
        }

        $cancellableStatuses = ['pending', 'confirmed'];

        if (!in_array($order->order_status, $cancellableStatuses)) {
            return response()->json([
                'errors' => [[
                    'code'    => 'cannot_cancel',
                    'message' => 'O pedido não pode ser cancelado no status atual: ' . $order->order_status,
                ]],
            ], 422);
        }

        DB::beginTransaction();
        try {
            $amountToRelease = (float) $order->order_amount;

            $order->order_status   = 'canceled';
            $order->canceled       = now();
            $order->canceled_by    = 'customer';
            $order->cancellation_reason = $request->input('reason', 'Cancelado via API externa');
            $order->save();

            // Libera o saldo reservado no token
            $newReserved = max(0, $apiToken->reserved_balance - $amountToRelease);
            $apiToken->reserved_balance = $newReserved;
            $apiToken->save();

            DB::commit();

            return response()->json([
                'message'          => 'Pedido cancelado. Saldo devolvido.',
                'order_id'         => $order->id,
                'order_status'     => $order->order_status,
                'released_amount'  => $amountToRelease,
                'reserved_balance' => (float) $apiToken->fresh()->reserved_balance,
            ], 200);

        } catch (\Throwable $e) {
            DB::rollBack();
            report($e);
            return response()->json([
                'errors' => [['code' => 'server_error', 'message' => 'Erro ao cancelar o pedido.']],
            ], 500);
        }
    }

    /**
     * GET /api/v1/external/orders/{id}
     *
     * Consulta o status e os detalhes de um pedido externo.
     * O {id} pode ser o ID interno (numérico) ou external_reference_id.
     */
    public function orderStatus(Request $request, string $id): JsonResponse
    {
        /** @var \App\Models\UserApiToken $apiToken */
        $apiToken = $request->get('_api_token');

        $order = Order::with(['delivery_man:id,f_name,l_name,phone'])
            ->where('api_token_id', $apiToken->id)
            ->where(function ($q) use ($id) {
                $q->where('id', is_numeric($id) ? $id : 0)
                  ->orWhere('external_reference_id', $id);
            })
            ->first();

        if (!$order) {
            return response()->json([
                'errors' => [['code' => 'not_found', 'message' => 'Pedido não encontrado.']],
            ], 404);
        }

        $deliveryAddress = $order->delivery_address ? json_decode($order->delivery_address) : null;

        return response()->json([
            'order_id'              => $order->id,
            'external_reference_id' => $order->external_reference_id,
            'order_status'          => $order->order_status,
            'payment_status'        => $order->payment_status,
            'order_amount'          => (float) $order->order_amount,
            'recipient'             => [
                'name'    => $deliveryAddress?->contact_person_name ?? '',
                'phone'   => $deliveryAddress?->contact_person_number ?? '',
                'address' => $deliveryAddress?->address ?? '',
            ],
            'delivery_man'          => $order->delivery_man ? [
                'name'  => $order->delivery_man->f_name . ' ' . $order->delivery_man->l_name,
                'phone' => $order->delivery_man->phone,
            ] : null,
            'otp'                   => ($order->order_status === 'out_for_delivery') ? $order->otp : null,
            'created_at'            => $order->created_at?->toIso8601String(),
            'updated_at'            => $order->updated_at?->toIso8601String(),
        ], 200);
    }

    /**
     * GET /api/v1/external/orders
     *
     * Lista os pedidos criados pelo token autenticado (paginado).
     */
    public function listOrders(Request $request): JsonResponse
    {
        /** @var \App\Models\UserApiToken $apiToken */
        $apiToken = $request->get('_api_token');

        $limit  = min((int) $request->input('limit', 20), 100);
        $orders = Order::where('api_token_id', $apiToken->id)
            ->select(['id', 'external_reference_id', 'order_status', 'payment_status', 'order_amount', 'created_at'])
            ->latest()
            ->paginate($limit);

        return response()->json([
            'total'   => $orders->total(),
            'limit'   => $limit,
            'page'    => $orders->currentPage(),
            'orders'  => $orders->items(),
        ], 200);
    }

    /**
     * GET /api/v1/external/me
     *
     * Verifica se o token está válido e retorna dados do cliente vinculado,
     * incluindo o endereço de origem (com lat/lng, geocodificando se necessário).
     */
    public function me(Request $request): JsonResponse
    {
        /** @var \App\Models\UserApiToken $apiToken */
        $apiToken = $request->get('_api_token');
        $user = $apiToken->user;

        $senderCoordinates = $this->resolveSenderCoordinates($user->id);

        return response()->json([
            'token_valid' => true,
            'customer' => [
                'id'     => $user->id,
                'name'   => trim(($user->f_name ?? '') . ' ' . ($user->l_name ?? '')),
                'email'  => $user->email,
                'phone'  => $user->phone,
                'status' => (int) $user->status,
            ],
            'sender_address' => $senderCoordinates ? [
                'address' => $senderCoordinates['address'],
                'lat'     => $senderCoordinates['lat'],
                'lng'     => $senderCoordinates['lng'],
            ] : null,
            'wallet' => [
                'wallet_balance'    => (float) $user->wallet_balance,
                'reserved_balance'  => (float) $apiToken->reserved_balance,
                'available_balance' => (float) ($user->wallet_balance - $apiToken->reserved_balance),
            ],
            'api_token' => [
                'id'         => $apiToken->id,
                'label'      => $apiToken->label,
                'is_active'  => (bool) $apiToken->is_active,
                'created_at' => $apiToken->created_at?->toIso8601String(),
            ],
        ], 200);
    }

    /**
     * POST /api/v1/external/quote
     *
     * Calcula o valor do frete usando o endereço do cliente do token como origem
     * e o endereço do destinatário como destino. Aplica exatamente as mesmas
     * regras do app Cliente (faixas por km, mínimo, fracional, ida e volta e
     * acréscimo de zona).
     *
     * Body:
     * {
     *   "recipient_address": "Rua das Flores, 100",
     *   "recipient_lat":     -23.55,   // opcional
     *   "recipient_lng":     -46.63,   // opcional
     *   "category_id":       1,        // opcional (default: primeira categoria ativa)
     *   "is_return":         true      // opcional (ida + volta)
     * }
     */
    public function quote(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'recipient_address' => 'required|string|max:500',
            'recipient_lat'     => 'nullable|numeric|between:-90,90',
            'recipient_lng'     => 'nullable|numeric|between:-180,180',
            'category_id'       => 'nullable|integer|exists:parcel_categories,id',
            'is_return'         => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'errors' => collect($validator->errors()->toArray())
                    ->map(fn($msgs, $field) => ['code' => $field, 'message' => $msgs[0]])
                    ->values(),
            ], 422);
        }

        /** @var \App\Models\UserApiToken $apiToken */
        $apiToken = $request->get('_api_token');

        $recipientLat = $request->filled('recipient_lat') ? (float) $request->recipient_lat : null;
        $recipientLng = $request->filled('recipient_lng') ? (float) $request->recipient_lng : null;

        if ($recipientLat === null || $recipientLng === null) {
            $resolvedCoordinates = $this->resolveCoordinatesFromAddress((string) $request->recipient_address);

            if (!$resolvedCoordinates) {
                return response()->json([
                    'errors' => [[
                        'code' => 'recipient_address',
                        'message' => 'Não foi possível localizar o endereço do destinatário.',
                    ]],
                ], 422);
            }

            $recipientLat = (float) $resolvedCoordinates['lat'];
            $recipientLng = (float) $resolvedCoordinates['lng'];
        }

        $senderCoordinates = $this->resolveSenderCoordinates($apiToken->user_id);
        if (!$senderCoordinates) {
            return response()->json([
                'errors' => [[
                    'code' => 'sender_address',
                    'message' => 'O cliente vinculado ao token não possui endereço de retirada cadastrado. Configure o endereço na página de Tokens de API.',
                ]],
            ], 422);
        }

        $categoryId = $request->filled('category_id') ? (int) $request->category_id : null;
        $isReturn   = filter_var($request->input('is_return', false), FILTER_VALIDATE_BOOLEAN);

        $feeData = $this->calculateDeliveryFee(
            (float) $senderCoordinates['lat'],
            (float) $senderCoordinates['lng'],
            $recipientLat,
            $recipientLng,
            $categoryId,
            $isReturn
        );

        return response()->json([
            'sender' => [
                'lat'     => (float) $senderCoordinates['lat'],
                'lng'     => (float) $senderCoordinates['lng'],
                'address' => $senderCoordinates['address'],
            ],
            'recipient' => [
                'lat'     => (float) $recipientLat,
                'lng'     => (float) $recipientLng,
                'address' => (string) $request->recipient_address,
            ],
            'distance_km'             => $feeData['distance_km'],
            'distance_source'         => $feeData['distance_source'],
            'category_id'             => $feeData['category_id'],
            'is_return'               => $feeData['is_return'],
            'per_km_charge'           => $feeData['per_km_charge'],
            'minimum_shipping_charge' => $feeData['minimum_shipping_charge'],
            'outbound_charge'         => $feeData['outbound_charge'],
            'return_charge'           => $feeData['return_charge'],
            'zone_id'                 => $feeData['zone_id'] ?? null,
            'zone_increase_percent'   => $feeData['zone_increase_percent'],
            'delivery_fee'            => $feeData['delivery_fee'],
        ], 200);
    }

    /**
     * Converte endereço em latitude/longitude usando Google Geocoding API.
     */
    private function resolveCoordinatesFromAddress(string $address): ?array
    {
        $mapApiKeyServer = BusinessSetting::where(['key' => 'map_api_key_server'])->value('value');

        if (!$mapApiKeyServer) {
            return null;
        }

        $response = Http::timeout(10)->get('https://maps.googleapis.com/maps/api/geocode/json', [
            'address' => $address,
            'key' => $mapApiKeyServer,
            'region' => 'br',
            'language' => 'pt-BR',
        ]);

        if ($response->failed()) {
            return null;
        }

        $json = $response->json();
        $firstResult = data_get($json, 'results.0.geometry.location');

        if (!$firstResult || !isset($firstResult['lat'], $firstResult['lng'])) {
            return null;
        }

        return [
            'lat' => (float) $firstResult['lat'],
            'lng' => (float) $firstResult['lng'],
        ];
    }

    /**
     * Busca a coordenada de origem do cliente vinculado ao token.
     * Prioriza o último endereço com lat/lng preenchidos; se não encontrar,
     * tenta geocodificar o endereço textual existente via Google Geocoding API.
     */
    private function resolveSenderCoordinates(int $userId): ?array
    {
        // 0. Prioridade: endereço explícito de retirada (address_type = 'pickup')
        $pickup = CustomerAddress::where('user_id', $userId)
            ->where('address_type', 'pickup')
            ->whereNotNull('latitude')
            ->whereNotNull('longitude')
            ->latest()
            ->first();

        if ($pickup) {
            return [
                'lat'     => (float) $pickup->latitude,
                'lng'     => (float) $pickup->longitude,
                'address' => (string) ($pickup->address ?? ''),
            ];
        }

        // Se tem address_type = 'pickup' mas sem coordenadas ainda, geocodifica
        $pickupNoCoords = CustomerAddress::where('user_id', $userId)
            ->where('address_type', 'pickup')
            ->whereNotNull('address')
            ->where('address', '!=', '')
            ->latest()
            ->first();

        if ($pickupNoCoords) {
            $resolved = $this->resolveCoordinatesFromAddress((string) $pickupNoCoords->address);
            if ($resolved) {
                $pickupNoCoords->latitude  = $resolved['lat'];
                $pickupNoCoords->longitude = $resolved['lng'];
                $pickupNoCoords->save();
                return [
                    'lat'     => (float) $resolved['lat'],
                    'lng'     => (float) $resolved['lng'],
                    'address' => (string) $pickupNoCoords->address,
                ];
            }
        }

        // 1. Fallback: qualquer endereço do usuário com coordenadas
        $senderAddress = CustomerAddress::where('user_id', $userId)
            ->whereNotNull('latitude')
            ->whereNotNull('longitude')
            ->latest()
            ->first();

        if ($senderAddress) {
            return [
                'lat'     => (float) $senderAddress->latitude,
                'lng'     => (float) $senderAddress->longitude,
                'address' => (string) ($senderAddress->address ?? ''),
            ];
        }

        // 2. Último recurso: qualquer endereço e geocodifica
        $anyAddress = CustomerAddress::where('user_id', $userId)
            ->whereNotNull('address')
            ->where('address', '!=', '')
            ->latest()
            ->first();

        if (!$anyAddress) {
            return null;
        }

        $resolved = $this->resolveCoordinatesFromAddress((string) $anyAddress->address);

        if (!$resolved) {
            return null;
        }

        $anyAddress->latitude  = $resolved['lat'];
        $anyAddress->longitude = $resolved['lng'];
        $anyAddress->save();

        return [
            'lat'     => (float) $resolved['lat'],
            'lng'     => (float) $resolved['lng'],
            'address' => (string) $anyAddress->address,
        ];
    }

    /**
     * Calcula o frete usando exatamente a mesma lógica do app Cliente:
     *  - Distância pela Google Routes API v2 (mesma rota do `/config/distance-api`),
     *    com fallback para haversine quando indisponível.
     *  - Faixas (`distance_pricing_rules`), mínimo, fracional, ida e volta da
     *    `ParcelCategory` selecionada (ou primeira ativa como padrão).
     *  - Acréscimo percentual da zona do destinatário (`increased_delivery_fee`).
     */
    private function calculateDeliveryFee(
        float $originLat,
        float $originLng,
        float $destinationLat,
        float $destinationLng,
        ?int $categoryId = null,
        bool $isReturn = false
    ): array {
        $category = $categoryId
            ? ParcelCategory::find($categoryId)
            : null;

        if (!$category) {
            $category = ParcelCategory::query()
                ->when(method_exists(ParcelCategory::class, 'scopeActive'), fn ($q) => $q->active())
                ->orderBy('id')
                ->first();
        }

        // Distância via Google Routes API (rota real). Fallback p/ haversine.
        $distanceKm = $this->resolveRoadDistanceKm($originLat, $originLng, $destinationLat, $destinationLng);
        $distanceSource = 'google_routes';
        if ($distanceKm === null) {
            $distanceKm = $this->haversineKm($originLat, $originLng, $destinationLat, $destinationLng);
            $distanceSource = 'haversine';
        }

        // Zona do destinatário → acréscimo percentual (mesma regra do PlaceNewOrder).
        $zone = Zone::whereContains('coordinates', new Point(
            $destinationLat,
            $destinationLng,
            config('app.point_srid', 4326)
        ))->first();

        $zoneIncreasePercent = 0.0;
        if ($zone && (int) ($zone->increased_delivery_fee_status ?? 0) === 1) {
            $zoneIncreasePercent = (float) ($zone->increased_delivery_fee ?? 0);
        }

        if (!$category) {
            // Sem categoria cadastrada: usa o legado por BusinessSetting.
            $perKmCharge = (float) (BusinessSetting::where('key', 'parcel_per_km_shipping_charge')->value('value') ?? 0);
            $minimumCharge = (float) (BusinessSetting::where('key', 'parcel_minimum_shipping_charge')->value('value') ?? 0);

            $outbound = max(0.0, $distanceKm) * $perKmCharge;
            $base = max($minimumCharge, $outbound);
            $returnCharge = $isReturn ? $outbound : 0.0;
            $total = $base + $returnCharge;
            if ($zoneIncreasePercent > 0) {
                $total += $total * ($zoneIncreasePercent / 100);
            }

            return [
                'distance_km'             => round($distanceKm, 3),
                'distance_source'         => $distanceSource,
                'category_id'             => null,
                'is_return'               => $isReturn,
                'per_km_charge'           => round($perKmCharge, 2),
                'minimum_shipping_charge' => round($minimumCharge, 2),
                'outbound_charge'         => round($outbound, 2),
                'return_charge'           => round($returnCharge, 2),
                'zone_increase_percent'   => $zoneIncreasePercent,
                'delivery_fee'            => round($total, 2),
            ];
        }

        // Ida (sem volta)
        $outboundTotal = ParcelCategoryController::computeParcelFeeForDistance(
            $category,
            $distanceKm,
            0.0,
            false
        );

        // Ida + Volta (quando solicitado)
        $withReturnTotal = $isReturn
            ? ParcelCategoryController::computeParcelFeeForDistance($category, $distanceKm, 0.0, true)
            : $outboundTotal;

        $returnCharge = max(0.0, $withReturnTotal - $outboundTotal);

        $finalTotal = $withReturnTotal;
        if ($zoneIncreasePercent > 0) {
            $finalTotal += $finalTotal * ($zoneIncreasePercent / 100);
        }

        return [
            'distance_km'             => round($distanceKm, 3),
            'distance_source'         => $distanceSource,
            'category_id'             => (int) $category->id,
            'is_return'               => $isReturn,
            'per_km_charge'           => (float) ($category->parcel_per_km_shipping_charge ?? 0),
            'minimum_shipping_charge' => (float) ($category->parcel_minimum_shipping_charge ?? 0),
            'outbound_charge'         => round($outboundTotal, 2),
            'return_charge'           => round($returnCharge, 2),
            'zone_increase_percent'   => $zoneIncreasePercent,
            'zone_id'                 => $zone?->id,
            'delivery_fee'            => round($finalTotal, 2),
        ];
    }

    /**
     * Distância de rota (km) via Google Routes API v2 — mesma chamada do `/config/distance-api`.
     * Retorna `null` em caso de falha para o chamador aplicar fallback.
     */
    private function resolveRoadDistanceKm(float $originLat, float $originLng, float $destinationLat, float $destinationLng): ?float
    {
        $apiKey = BusinessSetting::where('key', 'map_api_key_server')->value('value');
        if (!$apiKey) {
            return null;
        }

        try {
            $response = Http::timeout(10)
                ->withHeaders([
                    'Content-Type'      => 'application/json',
                    'X-Goog-Api-Key'    => $apiKey,
                    'X-Goog-FieldMask'  => 'duration,distanceMeters',
                ])
                ->post('https://routes.googleapis.com/distanceMatrix/v2:computeRouteMatrix', [
                    'origins' => [[
                        'waypoint' => ['location' => ['latLng' => [
                            'latitude'  => $originLat,
                            'longitude' => $originLng,
                        ]]],
                    ]],
                    'destinations' => [[
                        'waypoint' => ['location' => ['latLng' => [
                            'latitude'  => $destinationLat,
                            'longitude' => $destinationLng,
                        ]]],
                    ]],
                    'travelMode' => 'DRIVE',
                ]);

            if ($response->failed()) {
                return null;
            }

            $element = $response->json('0');
            if (!is_array($element) || !isset($element['distanceMeters'])) {
                return null;
            }

            return ((int) $element['distanceMeters']) / 1000.0;
        } catch (\Throwable $e) {
            report($e);
            return null;
        }
    }

    private function haversineKm(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $earthRadiusKm = 6371.0;
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);

        $a = sin($dLat / 2) ** 2
            + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLng / 2) ** 2;

        return 2 * $earthRadiusKm * asin(min(1, sqrt($a)));
    }
}
