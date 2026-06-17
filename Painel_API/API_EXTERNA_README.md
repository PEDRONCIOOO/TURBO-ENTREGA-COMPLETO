# API de Integração Externa — Guia de Implementação

**Data:** 15 de Maio de 2026  
**Objetivo:** Permitir que sistemas terceiros enviem pedidos automaticamente usando tokens de API

---

## 📋 Resumo do que foi criado

### ✅ Arquivos criados:

#### **1. Migrações (em `database/migrations/`)**
- `2026_05_15_000001_create_user_api_tokens_table.php`
- `2026_05_15_000002_add_external_order_id_to_orders_table.php`

#### **2. Modelos (em `app/Models/`)**
- `UserApiToken.php` — modelo para gerenciar tokens de API

#### **3. Middleware (em `app/Http/Middleware/`)**
- `ExternalApiToken.php` — autentica requisições externas via Bearer token

#### **4. Controllers (em `app/Http/Controllers/`)**
- `Api/V1/ExternalOrderController.php` — 4 endpoints para pedidos externos
- `Admin/UserApiTokenController.php` — gerenciamento de tokens no painel

#### **5. Views (em `resources/views/`)**
- `admin-views/api-tokens/index.blade.php` — interface de configuração de tokens
- `api-docs.blade.php` — documentação pública da API

#### **6. Script SQL (em `database/sql/`)**
- `2026_05_15_external_api_setup.sql` — comandos SQL para criar tabelas manualmente

---

## 🚀 Como executar

### **Opção 1: Via Artisan (se tiver acesso ao servidor)**
```bash
cd C:\TURBOENTREGACOMPLETO\Painel_API

# Executar as migrações
php artisan migrate

# Ou executar migrações específicas
php artisan migrate --path=database/migrations/2026_05_15_000001_create_user_api_tokens_table.php
php artisan migrate --path=database/migrations/2026_05_15_000002_add_external_order_id_to_orders_table.php
```

### **Opção 2: Via SQL direto (sem acesso ao servidor)**
```bash
# Abra seu cliente MySQL (phpMyAdmin, MySQL Workbench, etc)
# Importe ou copie o conteúdo do arquivo:
# database/sql/2026_05_15_external_api_setup.sql

# Ou execute os comandos manualmente no terminal MySQL:
mysql -u seu_usuario -p seu_banco < database/sql/2026_05_15_external_api_setup.sql
```

---

## 🔧 Registros de Rotas (já implementados)

### **1. Middleware registrado em `app/Http/Kernel.php`**
```php
'external.api.token' => \App\Http\Middleware\ExternalApiToken::class,
```

### **2. Rotas da API em `routes/api/v1/api.php`**
```php
Route::prefix('external')->middleware('external.api.token')->group(function () {
    Route::post('orders',        [ExternalOrderController::class, 'createOrder']);
    Route::get('orders',         [ExternalOrderController::class, 'listOrders']);
    Route::get('orders/{id}',    [ExternalOrderController::class, 'orderStatus']);
    Route::delete('orders/{id}', [ExternalOrderController::class, 'cancelOrder']);
});
```

### **3. Rotas admin em `routes/admin.php`**
```php
Route::get('api-tokens',              'UserApiTokenController@index')->name('api-tokens.index');
Route::post('api-tokens',             'UserApiTokenController@store')->name('api-tokens.store');
Route::patch('api-tokens/{apiToken}', 'UserApiTokenController@toggleStatus')->name('api-tokens.toggle');
Route::delete('api-tokens/{apiToken}','UserApiTokenController@destroy')->name('api-tokens.destroy');
Route::get('api-tokens/search-users', 'UserApiTokenController@searchUsers')->name('api-tokens.search-users');
```

### **4. Rota pública em `routes/web.php`**
```php
Route::get('api-docs', function () {
    return view('api-docs');
})->name('api-docs');
```

---

## 📡 Endpoints da API

**URL Base:** `{{ url('/api/v1/external') }}`

### **1. POST /orders — Criar Pedido**
```json
{
    "recipient_name":        "João Silva",
    "recipient_phone":       "+5511999999999",
    "recipient_address":     "Rua das Flores, 100 - São Paulo",
    "recipient_lat":         -23.550520,
    "recipient_lng":         -46.633308,
    "order_amount":          28.50,
    "external_reference_id": "PED-001",
    "note":                  "Frágil"
}
```

### **2. GET /orders/{id} — Status do Pedido**
Parâmetro `{id}` pode ser o ID interno ou `external_reference_id`.

### **3. GET /orders — Listar Pedidos**
Query params: `?limit=20&page=1`

### **4. DELETE /orders/{id} — Cancelar Pedido**
Devolve o saldo bloqueado se o pedido ainda estiver pendente.

---

## 🔑 Autenticação

Todas as requisições à API externa devem incluir:
```
Authorization: Bearer SEU_TOKEN_AQUI
Content-Type: application/json
```

---

## 💳 Fluxo de Reserva de Saldo

1. **Cliente cria pedido** → Saldo é **reservado** (bloqueado) na wallet
2. **Entregador busca o pedido** → Status muda para `confirmed`
3. **Entrega em trânsito** → Status: `out_for_delivery`
4. **Entrega concluída** → Saldo é **debitado definitivamente**
5. **Pedido cancelado** → Saldo reservado é **devolvido**

```sql
-- A tabela user_api_tokens tem a coluna:
reserved_balance DECIMAL(20, 2) -- saldo bloqueado por pedidos pendentes
```

---

## 🖥️ Painel de Configuração

**Acesso:** `/admin/api-tokens`

- Gerar novo token para um usuário
- Listar todos os tokens com saldo reservado
- Ativar/desativar tokens
- Excluir tokens (apenas se não houver saldo reservado)
- Busca AJAX de usuários por nome, e-mail ou telefone

---

## 📚 Documentação Pública

**Acesso:** `/api-docs`

Página pública com:
- Guia de autenticação
- Exemplos de requisições e respostas
- Lista de status de pedidos
- Códigos de erro
- Fluxo completo de integração

---

## 🔒 Segurança

- Token armazenado em hash (64 caracteres aleatórios)
- Validação de token em cada requisição
- Verificação de usuário bloqueado
- Saldo disponível verificado antes de criar pedido
- Transações de banco de dados (rollback em erro)

---

## 📊 Estrutura de Dados

### **Tabela: user_api_tokens**
```sql
id (PK)
user_id (FK) → users
token (UNIQUE, 64 chars)
label (descrição do token)
is_active (boolean)
reserved_balance (decimal)
created_at, updated_at
```

### **Alterações na tabela: orders**
```sql
external_reference_id (string, 100 chars)
api_token_id (FK) → user_api_tokens
```

---

## ✨ Próximos passos (opcional)

1. **Webhook**: Implementar notificações quando status do pedido muda
2. **Rate limiting**: Limitar requisições por IP/token (middleware)
3. **Audit log**: Registrar todas as requisições externas
4. **Dashboard**: Gráficos de pedidos criados via API
5. **Teste de carga**: Validar performance com múltiplas requisições

---

## ❓ Dúvidas Frequentes

**P: Onde copio o token para repassar ao cliente?**  
R: No painel `/admin/api-tokens`, há um botão de copiar ao lado de cada token.

**P: O que acontece se o cliente não tiver saldo?**  
R: A API retorna erro `422` com mensagem indicando saldo insuficiente.

**P: Como o entregador recebe o OTP?**  
R: É gerado automaticamente (4 dígitos) e retornado no status quando `out_for_delivery`.

**P: Posso reutilizar o token para múltiplos clientes?**  
R: Cada token está vinculado a um único usuário (remetente).

---

## 📝 Anotações Importantes

- Os migrations já estão prontos e podem ser executados com `php artisan migrate`
- Se preferir SQL puro, use o arquivo `database/sql/2026_05_15_external_api_setup.sql`
- Não esqueça de executar migrations ANTES de usar a API
- O middleware `external.api.token` valida o token automaticamente
- A resposta sempre retorna JSON com formato: `{ "errors": [...] }` ou dados da resposta

---

## 🎯 Checklist de Implementação

- [x] Criar migrações
- [x] Criar modelos
- [x] Criar middleware de autenticação
- [x] Implementar 4 endpoints da API
- [x] Criar controller admin para tokens
- [x] Criar view para gerenciar tokens
- [x] Criar documentação pública
- [x] Registrar todas as rotas
- [x] Registrar middleware no Kernel
- [ ] **Executar migrations (seu turno)**
- [ ] Testar endpoints com Postman/curl
- [ ] Gerar tokens para clientes
- [ ] Comunicar aos clientes a URL da documentação

---

**Status:** ✅ Pronto para uso após executar as migrations!
