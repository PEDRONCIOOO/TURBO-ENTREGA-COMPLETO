# Fluxo Financeiro e Pagamentos

> Atualizado: 07/05/2026

---

## Carteira do Entregador (`DeliveryManWallet`)

| Campo | Descrição |
|---|---|
| `total_earning` | Total ganho pelo entregador |
| `total_withdrawn` | Total já sacado/transferido |
| `pending_withdraw` | Saques em análise |
| `collected_cash` | Dinheiro em mãos (COD não repassado ainda) |

**Saldo disponível para saque:**  
`total_earning - (total_withdrawn + pending_withdraw)`

---

## Métodos de Saque do Entregador

### Modelo atual

O entregador cadastra seus métodos via `DisbursementWithdrawalMethod`:
- `method_name` — nome livre (ex: "PIX Pessoal")
- `method_fields` — JSON com dados do método (ex: `{"pix_key": "...", "pix_key_type": "CPF"}`)
- `is_default` — método padrão

### PIX (integração nativa)

Tabela separada `delivery_man_pix_accounts` via model `DeliveryManPixAccount`:
- `pix_key`, `pix_key_type` (CPF/CNPJ/EMAIL/PHONE/EVP)
- `holder_name`, `holder_document`
- `is_verified`

### Disbursement Flow

1. Entregador solicita saque → `POST /api/v1/deliveryman/request-disbursement`
2. Admin aprova → registra em `Disbursement` + `DisbursementDetails`
3. Saldo atualizado em `DeliveryManWallet`

---

## Gateways de Pagamento (Cliente)

Integrados via `PaymentController` usando abstração `Payment::generate_link()`:

| Gateway | Arquivo |
|---|---|
| Stripe | `StripePaymentController.php` |
| PayPal | `PaypalPaymentController.php` |
| Razorpay | `RazorPayController.php` |
| Mercado Pago | `MercadoPagoController.php` |
| Paystack | `PaystackController.php` |
| Flutterwave | `FlutterwaveV3Controller.php` |
| Bkash | `BkashPaymentController.php` |
| SSL Commerz | `SslCommerzPaymentController.php` |

---

## Próximas integrações planejadas

- **ASAAS** — saque automático para entregadores (ver [features/saque-asaas.md](../features/saque-asaas.md))
