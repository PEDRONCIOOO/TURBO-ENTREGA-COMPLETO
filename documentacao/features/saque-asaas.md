# Feature: Saque via ASAAS

> **Status:** Planejamento  
> **Iniciado:** 07/05/2026  
> **Responsável:** —

---

## Objetivo

Permitir que entregadores solicitem saque de seus ganhos e o valor seja transferido automaticamente via **ASAAS** (gateway de pagamento brasileiro), sem intervenção manual do admin.

---

## O que é ASAAS?

[ASAAS](https://www.asaas.com) é um gateway de pagamento brasileiro que suporta:
- Transferências PIX instantâneas
- TED/DOC
- Gerenciamento de subcontas (split de pagamento)
- API REST documentada em https://docs.asaas.com

---

## Impacto por projeto

| Projeto | Impacto |
|---|---|
| `Painel_API/` | Alto — novo serviço, migration, rotas, controller |
| `Entregador/` | Médio — nova tela/fluxo de saque ASAAS |
| `Cliente/` | Nenhum |

---

## Planejamento de Implementação

### Painel_API (Laravel)

#### 1. Configuração ASAAS

- Adicionar `ASAAS_API_KEY` e `ASAAS_ENV` (sandbox/production) no `.env`
- Criar `config/asaas.php`

```php
// config/asaas.php
return [
    'api_key'  => env('ASAAS_API_KEY'),
    'base_url' => env('ASAAS_ENV', 'sandbox') === 'production'
        ? 'https://api.asaas.com/v3'
        : 'https://sandbox.asaas.com/api/v3',
];
```

#### 2. Service `AsaasService`

Arquivo: `app/Services/AsaasService.php`

Responsabilidades:
- `createTransfer(array $data): array` — POST `/transfers`
- `getTransfer(string $id): array` — GET `/transfers/{id}`
- `createPixTransfer(array $pixData): array` — wrapper para PIX
- Tratar erros HTTP e retornar exceções tipadas

```php
// Exemplo de payload para transferência PIX
[
    'value'           => 50.00,
    'pixAddressKey'   => '000.000.000-00',
    'pixAddressKeyType' => 'CPF',
    'description'     => 'Saque entregador #123',
    'scheduleDate'    => now()->toDateString(),
]
```

#### 3. Migration — `delivery_man_asaas_accounts`

```php
Schema::create('delivery_man_asaas_accounts', function (Blueprint $table) {
    $table->id();
    $table->unsignedBigInteger('delivery_man_id')->unique();
    $table->string('asaas_customer_id')->nullable(); // ID do cliente no ASAAS
    $table->string('pix_key');
    $table->string('pix_key_type'); // CPF, CNPJ, EMAIL, PHONE, EVP
    $table->string('holder_name');
    $table->string('holder_document')->nullable();
    $table->boolean('is_active')->default(true);
    $table->timestamps();

    $table->foreign('delivery_man_id')->references('id')->on('delivery_men')->onDelete('cascade');
});
```

#### 4. Model `DeliveryManAsaasAccount`

Arquivo: `app/Models/DeliveryManAsaasAccount.php`

#### 5. Migration — adicionar coluna em `disbursements`

```php
$table->string('asaas_transfer_id')->nullable();
$table->string('asaas_transfer_status')->nullable(); // PENDING, DONE, CANCELLED
```

#### 6. Controller `AsaasDisbursementController`

Arquivo: `app/Http/Controllers/Api/V1/AsaasDisbursementController.php`

Endpoints:
- `POST /api/v1/deliveryman/asaas/setup-account` — cadastrar conta ASAAS
- `GET /api/v1/deliveryman/asaas/account` — obter conta cadastrada
- `POST /api/v1/deliveryman/asaas/request-withdrawal` — solicitar saque via ASAAS
- `GET /api/v1/deliveryman/asaas/withdrawal-status/{id}` — consultar status

#### 7. Webhook ASAAS

Arquivo: `app/Http/Controllers/AsaasWebhookController.php`  
Rota: `POST /webhook/asaas`

- Recebe eventos `TRANSFER_COMPLETED`, `TRANSFER_FAILED`
- Atualiza `disbursements.asaas_transfer_status`
- Se `COMPLETED`: confirma saque em `DeliveryManWallet` (já atualizado no request-withdrawal)
- Se `FAILED`: estorna `pending_withdraw` → devolve ao saldo disponível + notifica entregador

#### 8. Rotas

```php
// routes/api/v1/api.php — dentro do grupo autenticado do deliveryman
Route::group(['prefix' => 'asaas'], function () {
    Route::post('setup-account',        'AsaasDisbursementController@setupAccount');
    Route::get('account',               'AsaasDisbursementController@getAccount');
    Route::post('request-withdrawal',   'AsaasDisbursementController@requestWithdrawal');
    Route::get('withdrawal-status/{id}','AsaasDisbursementController@withdrawalStatus');
});

// Webhook público
Route::post('webhook/asaas', 'AsaasWebhookController@handle');
```

---

### Entregador (Flutter)

#### Telas a criar/modificar

| Arquivo | Ação |
|---|---|
| `features/disbursement/screens/asaas_setup_screen.dart` | Nova — cadastrar conta ASAAS |
| `features/disbursement/screens/asaas_withdrawal_screen.dart` | Nova — solicitar saque ASAAS |
| `features/disbursement/screens/disbursement_screen.dart` | Modificar — adicionar botão "Saque ASAAS" |
| `features/disbursement/controllers/disbursement_controller.dart` | Modificar — novos métodos de API |
| `features/disbursement/domain/models/asaas_account_model.dart` | Novo model |

#### Fluxo da UI

```
DisbursementScreen
    └── Botão "Saque via ASAAS"
            │
            ├── [sem conta] → AsaasSetupScreen
            │       └── Formulário: chave PIX, tipo, nome, documento
            │               └── Salva → volta para DisbursementScreen
            │
            └── [com conta] → AsaasWithdrawalScreen
                    └── Mostra saldo disponível
                        Insere valor
                        Confirma → API → feedback de sucesso/erro
```

---

## Fluxo de Saque ASAAS (resumo)

```
Entregador solicita saque
        │
        ▼
API valida saldo disponível
        │
        ▼
API cria registro em disbursements (status: pending)
API deduz pending_withdraw em DeliveryManWallet
        │
        ▼
AsaasService::createPixTransfer()
        │
        ├── Sucesso → salva asaas_transfer_id, status: processing
        │
        └── Erro → desfaz pending_withdraw → retorna erro ao entregador
        │
        ▼
Webhook ASAAS recebe resultado
        │
        ├── TRANSFER_COMPLETED
        │   └── Atualiza disbursement status → confirma total_withdrawn
        │
        └── TRANSFER_FAILED
            └── Estorna pending_withdraw → notifica entregador via FCM
```

---

## Arquivos a criar/modificar

### Painel_API
- [ ] `.env` — adicionar `ASAAS_API_KEY`, `ASAAS_ENV`
- [ ] `config/asaas.php`
- [ ] `app/Services/AsaasService.php`
- [ ] `app/Models/DeliveryManAsaasAccount.php`
- [ ] `database/migrations/xxxx_create_delivery_man_asaas_accounts_table.php`
- [ ] `database/migrations/xxxx_add_asaas_columns_to_disbursements_table.php`
- [ ] `app/Http/Controllers/Api/V1/AsaasDisbursementController.php`
- [ ] `app/Http/Controllers/AsaasWebhookController.php`
- [ ] `routes/api/v1/api.php` — adicionar rotas ASAAS
- [ ] `routes/web.php` — adicionar rota webhook

### Entregador
- [ ] `lib/features/disbursement/domain/models/asaas_account_model.dart`
- [ ] `lib/features/disbursement/screens/asaas_setup_screen.dart`
- [ ] `lib/features/disbursement/screens/asaas_withdrawal_screen.dart`
- [ ] `lib/features/disbursement/controllers/disbursement_controller.dart` — modificar
- [ ] `lib/features/disbursement/screens/disbursement_screen.dart` — modificar

---

## Considerações de Segurança

- A `ASAAS_API_KEY` nunca deve ser exposta no client (só fica no `.env` do servidor)
- Webhook deve validar assinatura ASAAS (`asaas-access-token` header)
- Saque só pode ser solicitado para o entregador autenticado (validar `auth_token`)
- Valor mínimo de saque deve ser configurável via `BusinessSetting`
