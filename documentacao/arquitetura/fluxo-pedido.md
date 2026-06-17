# Fluxo de Pedido (Parcel/Entrega)

> Atualizado: 07/05/2026

---

## Ciclo de Status de um Pedido

```
Cliente cria pedido
        │
        ▼
   [pending]  ←── entregador recebe notificação
        │
        │ entregador aceita (accept_order)
        ▼
  [handover]  ←── entregador a caminho de coleta
        │
        │ entregador coleta
        ▼
  [picked_up]
        │
        │ entregador entrega
        ▼
  [delivered]  ←── transação financeira criada
        │
  [canceled] ou [refund_requested] → [refunded]
```

---

## Endpoints relevantes (API V1)

| Método | Rota | Controller | Descrição |
|---|---|---|---|
| GET | `/api/v1/order/track` | `OrderController@track_order` | Rastrear pedido |
| POST | `/api/v1/deliveryman/accept-order` | `DeliverymanController@accept_order` | Entregador aceita |
| POST | `/api/v1/deliveryman/update-order-status` | `DeliverymanController@update_order_status` | Atualizar status |
| GET | `/api/v1/deliveryman/get-order/{id}` | `DeliverymanController@get_order` | Detalhe do pedido |

---

## Fluxo de Parcela (Parcel)

1. Cliente acessa `ParcelCategoryScreen` → escolhe categoria
2. `ParcelLocationScreen` → define endereço de coleta e destino
3. `ParcelRequestScreen` → confirma detalhes, instruções, pagamento
4. API cria `Order` com `order_type = 'parcel'`
5. Entregador recebe notificação via FCM topic `delivery_man_{zone_id}_{vehicle_id}`
6. Entregador aceita → status vai direto para `handover` (parcel pula `confirmed`)
7. Entregador entrega → `OrderLogic::create_transaction()` registra ganho na carteira
