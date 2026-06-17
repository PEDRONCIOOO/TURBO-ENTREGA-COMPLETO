# Feature: Entrega Adicional

> **Status:** Planejamento  
> **Iniciado:** 07/05/2026  
> **Responsável:** —

---

## Objetivo

Permitir que o cliente adicione **uma ou mais entregas adicionais** a um pedido principal (parcela). Exemplo: o cliente tem um pacote principal de A→B e deseja adicionar uma segunda parada B→C no mesmo pedido, pagando a diferença da taxa de entrega.

---

## Impacto por projeto

| Projeto | Impacto |
|---|---|
| `Painel_API/` | Alto — nova tabela, lógica de preço, rotas |
| `Cliente/` | Alto — nova tela/widget na tela de parcel |
| `Entregador/` | Médio — mostrar paradas adicionais no detalhe do pedido |

---

## Conceito de Negócio

- O pedido principal (`Order`) tem um endereço de coleta e um de entrega
- O cliente pode adicionar **paradas extras** antes de confirmar o pedido
- Cada parada extra tem:
  - Endereço de destino
  - Instrução de entrega (opcional)
  - Taxa adicional calculada pela distância incremental
- O entregador vê a lista de paradas em sequência

---

## Planejamento de Implementação

### Painel_API (Laravel)

#### 1. Migration — `order_additional_stops`

```php
Schema::create('order_additional_stops', function (Blueprint $table) {
    $table->id();
    $table->unsignedBigInteger('order_id');
    $table->integer('sequence');           // ordem da parada (1, 2, 3...)
    $table->json('delivery_address');      // mesmo formato de Order.delivery_address
    $table->string('delivery_instruction')->nullable();
    $table->float('extra_delivery_charge')->default(0);
    $table->string('status')->default('pending'); // pending, delivered, failed
    $table->timestamp('delivered_at')->nullable();
    $table->timestamps();

    $table->foreign('order_id')->references('id')->on('orders')->onDelete('cascade');
});
```

#### 2. Model `OrderAdditionalStop`

Arquivo: `app/Models/OrderAdditionalStop.php`

```php
class OrderAdditionalStop extends Model {
    protected $casts = [
        'delivery_address'     => 'array',
        'extra_delivery_charge'=> 'float',
        'sequence'             => 'integer',
    ];

    public function order() {
        return $this->belongsTo(Order::class);
    }
}
```

#### 3. Relacionamento em `Order`

```php
// app/Models/Order.php
public function additionalStops() {
    return $this->hasMany(OrderAdditionalStop::class)->orderBy('sequence');
}
```

#### 4. Lógica de cálculo de taxa

Criar método em `app/CentralLogics/order.php` (ou helper):

```php
function calculate_additional_stop_charge(
    float $base_lat, float $base_lng,
    float $stop_lat,  float $stop_lng,
    int $zone_id
): float {
    // Usa a mesma lógica de cálculo de distância/taxa do pedido principal
    // Retorna o valor da taxa incremental
}
```

#### 5. Endpoint — calcular taxa antes de confirmar

```
POST /api/v1/parcel/additional-stop/calculate-charge
Body: {
    "order_id": null,  ← ainda não criado, pode calcular sem pedido
    "stops": [
        {"lat": -23.55, "lng": -46.63, "delivery_instruction": "Ring bell"}
    ]
}
Response: {
    "stops": [
        {"lat": -23.55, "lng": -46.63, "extra_delivery_charge": 8.50}
    ],
    "total_extra_charge": 8.50
}
```

#### 6. Modificar endpoint de criação de pedido parcel

- `POST /api/v1/order/place` (PlaceNewOrder trait)
- Aceitar campo opcional `additional_stops: []` no body
- Após criar o `Order`, criar os `OrderAdditionalStop`
- Somar `extra_delivery_charge` de cada parada ao `delivery_charge` do pedido

#### 7. Endpoint — atualizar status de parada (Entregador)

```
POST /api/v1/deliveryman/order/{order_id}/stop/{stop_id}/delivered
```

#### 8. Incluir paradas no response do pedido

- `OrderController@track_order` — incluir `additionalStops`
- `DeliverymanController@get_order` — incluir `additionalStops`

---

### Cliente (Flutter)

#### Telas a criar/modificar

| Arquivo | Ação |
|---|---|
| `features/parcel/screens/parcel_request_screen.dart` | Modificar — adicionar seção "Paradas Adicionais" |
| `features/parcel/widgets/additional_stop_widget.dart` | Novo — card de parada com endereço + remover |
| `features/parcel/widgets/add_stop_bottom_sheet.dart` | Novo — bottom sheet para buscar endereço da parada |
| `features/parcel/controllers/parcel_controller.dart` | Modificar — lista de paradas, cálculo |
| `features/parcel/domain/models/additional_stop_model.dart` | Novo model |
| `features/checkout/domain/models/place_order_body_model.dart` | Modificar — adicionar campo `additional_stops` |

#### Fluxo da UI

```
ParcelRequestScreen
    │
    ├── [Seção: Endereço de entrega] ← já existe
    │
    ├── [Seção: Paradas Adicionais] ← NOVO
    │   ├── Lista de paradas adicionadas (card removível)
    │   │   └── AddressCard + taxa calculada + botão remover
    │   │
    │   └── Botão "+ Adicionar parada"
    │           └── AddStopBottomSheet
    │                   └── Campo de busca de endereço (GooglePlaces)
    │                           └── Confirma → calcula taxa via API
    │                                   → adiciona à lista
    │
    └── [Total] ← inclui soma das taxas adicionais
```

#### Model `AdditionalStopModel`

```dart
class AdditionalStopModel {
  final AddressModel address;
  final String? deliveryInstruction;
  final double extraDeliveryCharge;

  const AdditionalStopModel({
    required this.address,
    this.deliveryInstruction,
    required this.extraDeliveryCharge,
  });
}
```

#### Modificação em `PlaceOrderBodyModel`

Adicionar:
```dart
final List<AdditionalStopModel>? additionalStops;
```

E no `toJson()`:
```dart
if (additionalStops != null && additionalStops!.isNotEmpty)
  'additional_stops': additionalStops!.map((s) => s.toJson()).toList(),
```

---

### Entregador (Flutter)

#### Modificações

| Arquivo | Ação |
|---|---|
| `features/order/screens/order_details_screen.dart` | Mostrar lista de paradas com status |
| `features/order/controllers/order_controller.dart` | Ler `additional_stops` do response |

---

## Fluxo Completo

```
Cliente na ParcelRequestScreen
        │
        ▼
Adiciona paradas → API calcula taxa incremental por parada
        │
        ▼
Confirma pedido → PlaceOrder com additional_stops[]
        │
        ▼
API cria Order + OrderAdditionalStop(s)
delivery_charge = charge_principal + soma(extra_delivery_charge)
        │
        ▼
Entregador aceita pedido
        │
        ▼
Entregador vê lista de paradas em sequência no app
        │
        ├── Entrega parada 1 → POST .../stop/1/delivered
        ├── Entrega parada 2 → POST .../stop/2/delivered
        └── Entrega parada final → status = delivered
```

---

## Arquivos a criar/modificar

### Painel_API
- [ ] `database/migrations/xxxx_create_order_additional_stops_table.php`
- [ ] `app/Models/OrderAdditionalStop.php`
- [ ] `app/Models/Order.php` — relacionamento `additionalStops()`
- [ ] `app/CentralLogics/order.php` — função de cálculo de taxa incremental
- [ ] `app/Http/Controllers/Api/V1/OrderController.php` — incluir paradas nos responses
- [ ] `app/Http/Controllers/Api/V1/DeliverymanController.php` — endpoint de parada entregue
- [ ] `app/Traits/PlaceNewOrder.php` — salvar paradas ao criar pedido
- [ ] `routes/api/v1/api.php` — novas rotas

### Cliente
- [ ] `lib/features/parcel/domain/models/additional_stop_model.dart`
- [ ] `lib/features/parcel/widgets/additional_stop_widget.dart`
- [ ] `lib/features/parcel/widgets/add_stop_bottom_sheet.dart`
- [ ] `lib/features/parcel/controllers/parcel_controller.dart` — modificar
- [ ] `lib/features/parcel/screens/parcel_request_screen.dart` — modificar
- [ ] `lib/features/checkout/domain/models/place_order_body_model.dart` — modificar

### Entregador
- [ ] `lib/features/order/screens/order_details_screen.dart` — modificar
- [ ] `lib/features/order/controllers/order_controller.dart` — modificar

---

## Considerações de UX

- Máximo de paradas adicionais: configurável (sugestão: 3)
- Mostrar claramente o valor de cada taxa adicional antes de confirmar
- Entregador deve ver a rota otimizada com todas as paradas
- Não permitir adicionar paradas após o pedido ser aceito pelo entregador
