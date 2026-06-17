# Integracao de Saques via Asaas (Entregador)

## Objetivo
Implementar saque de entregador via Pix usando Asaas, mantendo o fluxo legado separado e sem quebrar os saques existentes de vendedor.

## Configuracao Admin
Tela: Admin > Business Settings > Disbursement

Campos novos:
- `dm_asaas_auto_transfer` (boolean)
- `asaas_base_url` (string)
- `asaas_api_key` (string)

Comportamento:
- Quando `dm_asaas_auto_transfer=1`, ao completar disbursement de entregador o sistema tenta enviar automaticamente para Asaas.
- Quando `dm_asaas_auto_transfer=0`, o admin pode processar manualmente no detalhe do disbursement.

## Endpoints Deliveryman API
Base: `api/v1/delivery-man`

### 1) Consultar Pix cadastrado
- Metodo: `GET`
- URL: `/pix-account`
- Auth: token do entregador (`dm.api`)
- Resposta 200:
```json
{
  "has_account": true,
  "data": {
    "id": 1,
    "delivery_man_id": 12,
    "pix_key": "email@dominio.com",
    "pix_key_type": "EMAIL",
    "holder_name": "Fulano",
    "holder_document": "12345678900",
    "is_verified": false
  }
}
```

### 2) Cadastrar/Editar Pix
- Metodo: `POST`
- URL: `/pix-account`
- Auth: token do entregador (`dm.api`)
- Body:
```json
{
  "pix_key": "email@dominio.com",
  "pix_key_type": "EMAIL",
  "holder_name": "Fulano",
  "holder_document": "12345678900"
}
```
- Regras:
  - `pix_key` obrigatorio
  - `pix_key_type` em `CPF|CNPJ|EMAIL|PHONE|EVP`

### 3) Solicitar saque manual (gera disbursement)
- Metodo: `POST`
- URL: `/request-disbursement`
- Auth: token do entregador (`dm.api`)
- Body:
```json
{
  "amount": 120.50
}
```
- Validacoes:
  - Valor > 0
  - Entregador precisa ter Pix cadastrado
  - Entregador precisa ter metodo de saque padrao
  - Saldo disponivel: `total_earning - (total_withdrawn + pending_withdraw + collected_cash)`

## Endpoint Admin para processamento Asaas
Base: `admin/transactions/dm-disbursement`

### Processar saque no Asaas (manual)
- Metodo: `GET`
- URL: `/process-asaas/{id}`
- Auth: painel admin
- Efeito:
  - Cria transferencia no Asaas (`/v3/transfers`, operacao `PIX`)
  - Atualiza colunas de rastreio em `disbursement_details`
  - Se sucesso, finaliza saque (`completed`) e faz ajuste da carteira

## Integracao Asaas
Servico interno: `App\Services\AsaasTransferService`

Request enviado:
- Metodo: `POST`
- URL: `{asaas_base_url}/transfers`
- Header: `access_token: {asaas_api_key}`
- Payload:
```json
{
  "value": 120.50,
  "operationType": "PIX",
  "pixAddressKey": "email@dominio.com",
  "externalReference": "dm_disbursement_123",
  "description": "Deliveryman withdraw #123"
}
```

## Tabelas novas/alteradas

### Nova tabela: `delivery_man_pix_accounts`
- `delivery_man_id` (unico)
- `pix_key`
- `pix_key_type`
- `holder_name`
- `holder_document`
- `is_verified`

### Alteracao: `disbursement_details`
- `payout_provider`
- `payout_status`
- `asaas_transfer_id`
- `payout_error`
- `payout_processed_at`

## Observacoes de segregacao (nao misturar legado)
- O fluxo legado de saque de vendedor (`withdraw_requests`) nao foi alterado.
- A integracao Asaas foi aplicada no fluxo de disbursement de entregador.
- O cadastro Pix do entregador foi separado em tabela dedicada.
