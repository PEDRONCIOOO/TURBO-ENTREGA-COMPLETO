# Visão Geral da Arquitetura — Turbo Entregas

> Atualizado: 07/05/2026

---

## 1. Diagrama de Componentes

```
┌─────────────────────────────────────────────────────────┐
│                      CLIENTES FINAIS                     │
│                                                         │
│   ┌───────────────┐          ┌─────────────────────┐    │
│   │  App Cliente  │          │   App Entregador    │    │
│   │  (Flutter)    │          │   (Flutter)         │    │
│   │  sixam_mart   │          │ sixam_mart_delivery │    │
│   └───────┬───────┘          └──────────┬──────────┘    │
│           │  HTTP/REST                  │ HTTP/REST      │
│           └────────────┬────────────────┘               │
│                        ▼                                 │
│             ┌────────────────────┐                       │
│             │    Painel_API      │                       │
│             │  (Laravel 10)      │                       │
│             │  PHP 8.2           │                       │
│             │  routes/api/v1     │                       │
│             └─────────┬──────────┘                       │
│                       │                                  │
│              ┌────────┴────────┐                         │
│              │   MySQL / DB    │                         │
│              └─────────────────┘                         │
└─────────────────────────────────────────────────────────┘
```

---

## 2. App Cliente (`Cliente/`)

**Pacote Flutter:** `sixam_mart`  
**Versão:** 1.0.0+1  
**SDK:** Dart ≥ 3.2.0

### Estrutura de diretórios relevantes

```
lib/
├── main.dart
├── api/             ← clientes HTTP (Dio/http)
├── common/          ← widgets compartilhados
├── features/        ← cada feature em subpasta própria
│   ├── parcel/      ← pedidos de entrega/parcela
│   │   ├── controllers/
│   │   ├── domain/models/
│   │   └── screens/
│   │       ├── parcel_category_screen.dart
│   │       ├── parcel_location_screen.dart
│   │       └── parcel_request_screen.dart
│   ├── order/       ← acompanhamento de pedidos
│   ├── checkout/    ← finalização do pedido + pagamento
│   ├── wallet/      ← carteira do cliente
│   └── payment/     ← integrações de pagamento
├── helper/
├── util/
└── theme/
```

### Dependências-chave

| Pacote | Uso |
|---|---|
| `get` ^4.6.6 | State management (GetX) |
| `http` ^1.2.2 | Requisições HTTP |
| `google_maps_flutter` | Mapa de endereços |
| `geolocator` | GPS |
| `firebase_*` | Push notifications + crash reporting |
| `drift` | Banco de dados local |

---

## 3. App Entregador (`Entregador/`)

**Pacote Flutter:** `sixam_mart_delivery`  
**Versão:** 1.0.0+2  
**SDK:** Dart ≥ 3.2.0

### Estrutura de diretórios relevantes

```
lib/
├── main.dart
├── features/
│   ├── auth/
│   ├── order/       ← aceitar/gerenciar pedidos
│   ├── disbursement/ ← saque de ganhos
│   │   ├── controllers/
│   │   ├── domain/
│   │   └── screens/
│   │       ├── disbursement_screen.dart        ← relatório de saques
│   │       ├── withdraw_method_screen.dart     ← listar métodos
│   │       └── add_withdraw_method_screen.dart ← cadastrar método
│   ├── cash_in_hand/ ← dinheiro em mãos
│   └── home/
```

### Dependências-chave

| Pacote | Uso |
|---|---|
| `get` ^4.6.6 | State management (GetX) |
| `flutter_foreground_task` | Rastreamento em background |
| `flutter_dotenv` | Configuração por ambiente |
| `web_socket_channel` | WebSocket para notificações em tempo real |

---

## 4. Painel & API (`Painel_API/`)

**Framework:** Laravel 10  
**PHP:** 8.2  
**Banco:** MySQL (spatial via `matanyadaev/laravel-eloquent-spatial`)

### Estrutura da API REST

```
routes/
├── api/v1/api.php          ← rotas principais (customer + deliveryman)
├── vendor.php              ← painel do lojista
├── admin.php               ← painel admin
└── rest_api/v1/
    ├── customer/routes.php
    └── rider/routes.php

app/Http/Controllers/Api/V1/
├── OrderController.php
├── DeliverymanController.php  ← disbursement, PIX, saques
├── WalletController.php
├── ParcelCategoryController.php
└── ...
```

### Models principais

| Model | Tabela | Descrição |
|---|---|---|
| `Order` | `orders` | Pedido (food/parcel) |
| `OrderDetail` | `order_details` | Itens do pedido |
| `DeliveryMan` | `delivery_men` | Entregador |
| `DeliveryManWallet` | `delivery_man_wallets` | Carteira do entregador |
| `DeliveryManPixAccount` | `delivery_man_pix_accounts` | Chave PIX do entregador |
| `WithdrawRequest` | `withdraw_requests` | Solicitação de saque |
| `Disbursement` | `disbursements` | Disbursement batch |
| `DisbursementWithdrawalMethod` | `disbursement_withdrawal_methods` | Métodos de saque |
| `ParcelCategory` | `parcel_categories` | Categorias de parcela |

### Gateways de pagamento atualmente integrados

- Stripe
- PayPal
- Razorpay
- Mercado Pago
- Paystack
- Flutterwave
- Bkash, Paytm, etc.
- PIX (integração local via `DeliveryManPixAccount`)

---

## 5. Módulos LaravelModules

```
Painel_API/Modules/
└── TaxModule/   ← cálculo de impostos por pedido
```

---

## 6. Configurações de ambiente

| Projeto | Arquivo |
|---|---|
| Cliente | `lib/util/app_constants.dart` (URLs base) |
| Entregador | `flutter.env` + `flutter_dotenv` |
| API | `.env` (Laravel padrão) |
