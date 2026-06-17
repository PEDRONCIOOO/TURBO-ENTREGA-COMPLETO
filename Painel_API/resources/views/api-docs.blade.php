<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Documentação API de Integração — TurboEntrega</title>
    <style>
        /* ─── Reset & Base ─────────────────────────────────────────── */
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        html { scroll-behavior: smooth; }
        body { font-family: 'Segoe UI', system-ui, sans-serif; background: #f4f6f9; color: #2d3748; line-height: 1.6; }

        /* ─── Layout ────────────────────────────────────────────────── */
        .wrapper { display: flex; min-height: 100vh; }

        /* Sidebar */
        .sidebar {
            width: 260px; min-height: 100vh; background: #1a202c; color: #a0aec0;
            position: sticky; top: 0; height: 100vh; overflow-y: auto; flex-shrink: 0;
        }
        .sidebar-brand { padding: 24px 20px 16px; border-bottom: 1px solid #2d3748; }
        .sidebar-brand h2 { color: #fff; font-size: 1.1rem; font-weight: 700; }
        .sidebar-brand small { color: #718096; font-size: .75rem; }
        .sidebar nav ul { list-style: none; padding: 12px 0; }
        .sidebar nav ul li a {
            display: flex; align-items: center; gap: 8px;
            padding: 9px 20px; color: #a0aec0; text-decoration: none; font-size: .875rem;
            transition: background .15s, color .15s;
        }
        .sidebar nav ul li a:hover, .sidebar nav ul li a.active { background: #2d3748; color: #fff; border-left: 3px solid #4299e1; }
        .sidebar-section-title { padding: 14px 20px 4px; font-size: .7rem; text-transform: uppercase; letter-spacing: .08em; color: #4a5568; }

        /* Main */
        .main { flex: 1; padding: 40px 48px; max-width: 960px; }

        /* ─── Components ────────────────────────────────────────────── */
        .section { margin-bottom: 56px; scroll-margin-top: 24px; }
        h1 { font-size: 2rem; font-weight: 800; color: #1a202c; margin-bottom: 8px; }
        h2 { font-size: 1.4rem; font-weight: 700; color: #2d3748; margin-bottom: 12px; padding-bottom: 8px; border-bottom: 2px solid #e2e8f0; }
        h3 { font-size: 1.05rem; font-weight: 600; color: #2d3748; margin: 18px 0 8px; }
        p { margin-bottom: 12px; color: #4a5568; }
        ul { padding-left: 20px; margin-bottom: 12px; color: #4a5568; }
        ul li { margin-bottom: 4px; }
        a { color: #4299e1; }

        /* Alert */
        .alert { border-left: 4px solid; border-radius: 6px; padding: 12px 16px; margin-bottom: 16px; font-size: .875rem; }
        .alert-info  { background: #ebf8ff; border-color: #63b3ed; color: #2b6cb0; }
        .alert-warn  { background: #fffbeb; border-color: #f6ad55; color: #92400e; }
        .alert-success { background: #f0fff4; border-color: #68d391; color: #276749; }

        /* Method badge */
        .method {
            display: inline-block; padding: 3px 10px; border-radius: 4px; font-size: .75rem;
            font-weight: 700; letter-spacing: .05em; margin-right: 8px; vertical-align: middle;
        }
        .method-post   { background: #c6f6d5; color: #276749; }
        .method-get    { background: #bee3f8; color: #2b6cb0; }
        .method-delete { background: #fed7d7; color: #c53030; }

        /* Endpoint card */
        .endpoint-card {
            border: 1px solid #e2e8f0; border-radius: 8px; margin-bottom: 28px; overflow: hidden;
            box-shadow: 0 1px 3px rgba(0,0,0,.06);
        }
        .endpoint-header {
            display: flex; align-items: center; gap: 10px;
            background: #f7fafc; padding: 12px 16px; border-bottom: 1px solid #e2e8f0;
        }
        .endpoint-url { font-family: 'Courier New', monospace; font-size: .9rem; color: #2d3748; font-weight: 600; }
        .endpoint-body { padding: 16px; }

        /* Code block */
        pre {
            background: #1a202c; color: #e2e8f0; border-radius: 8px;
            padding: 16px; overflow-x: auto; font-size: .8rem; line-height: 1.5;
            margin: 8px 0 16px; position: relative;
        }
        code { font-family: 'Courier New', monospace; }

        /* Table */
        table { width: 100%; border-collapse: collapse; font-size: .875rem; margin-bottom: 16px; }
        th { background: #edf2f7; padding: 8px 12px; text-align: left; font-weight: 600; color: #2d3748; }
        td { padding: 8px 12px; border-bottom: 1px solid #e2e8f0; color: #4a5568; vertical-align: top; }
        td code { background: #edf2f7; padding: 1px 5px; border-radius: 3px; font-size: .8rem; }

        /* Badge */
        .badge { display: inline-block; padding: 2px 8px; border-radius: 12px; font-size: .7rem; font-weight: 600; }
        .badge-required { background: #fed7d7; color: #c53030; }
        .badge-optional { background: #e2e8f0; color: #4a5568; }

        /* ─── Responsive ────────────────────────────────────────────── */
        @media (max-width: 768px) {
            .wrapper { flex-direction: column; }
            .sidebar { width: 100%; height: auto; position: relative; }
            .main { padding: 24px 16px; }
        }
    </style>
</head>
<body>
<div class="wrapper">

    <!-- ── SIDEBAR ─────────────────────────────────────────────────── -->
    <aside class="sidebar">
        <div class="sidebar-brand">
            <h2>🚀 TurboEntrega API</h2>
            <small>Documentação de Integração</small>
        </div>
        <nav>
            <ul>
                <li><a href="#intro">📖 Introdução</a></li>
                <li><a href="#auth">🔑 Autenticação</a></li>
                <li><a href="#base-url">🌐 URL Base</a></li>
                <div class="sidebar-section-title">Endpoints</div>
                <li><a href="#ep-me">GET Verificar Token</a></li>
                <li><a href="#ep-quote">POST Simular Frete</a></li>
                <li><a href="#ep-create">POST Criar Pedido</a></li>
                <li><a href="#ep-status">GET Status do Pedido</a></li>
                <li><a href="#ep-list">GET Listar Pedidos</a></li>
                <li><a href="#ep-cancel">DELETE Cancelar Pedido</a></li>
                <div class="sidebar-section-title">Referência</div>
                <li><a href="#statuses">📋 Status do Pedido</a></li>
                <li><a href="#errors">❌ Erros</a></li>
                <li><a href="#flow">🔄 Fluxo Completo</a></li>
            </ul>
        </nav>
    </aside>

    <!-- ── MAIN ────────────────────────────────────────────────────── -->
    <main class="main">

        <!-- Intro -->
        <section class="section" id="intro">
            <h1>Documentação da API</h1>
            <p>
                A <strong>TurboEntrega API</strong> permite que sistemas externos (e-commerce, ERPs, aplicativos)
                criem, acompanhem e cancelem pedidos de entrega de forma automática, sem intervenção manual.
            </p>
            <div class="alert alert-info">
                <strong>Como obter acesso:</strong> Entre em contato com o administrador da plataforma para
                solicitar um <em>Token de API</em> vinculado à sua conta. O token garante que as entregas
                sejam cobradas do saldo da sua wallet automaticamente.
            </div>
            <div class="alert alert-warn">
                <strong>Importante:</strong> Mantenha seu token em sigilo. Não o compartilhe publicamente.
                Caso seja comprometido, informe o administrador para revogar e gerar um novo.
            </div>
        </section>

        <!-- Auth -->
        <section class="section" id="auth">
            <h2>🔑 Autenticação</h2>
            <p>
                Todas as requisições devem incluir o token no cabeçalho HTTP
                <code>Authorization</code> no formato <strong>Bearer</strong>:
            </p>
            <pre><code>Authorization: Bearer SEU_TOKEN_AQUI
Content-Type: application/json
Accept: application/json</code></pre>
            <div class="alert alert-warn">
                Requisições sem token ou com token inválido retornarão <code>HTTP 401 Unauthorized</code>.
            </div>
        </section>

        <!-- Base URL -->
        <section class="section" id="base-url">
            <h2>🌐 URL Base</h2>
            @php
                $configuredBase = \App\Models\BusinessSetting::where('key', 'external_api_base_url')->value('value');
                $baseUrl = $configuredBase ? rtrim($configuredBase, '/') : request()->getSchemeAndHttpHost();
            @endphp
            <p>Esta documentação está publicada em:</p>
            <pre><code>{{ $baseUrl }}/api-docs</code></pre>
            <p>A URL base da integração externa neste ambiente é:</p>
            <pre><code>{{ $baseUrl }}/api/v1/external</code></pre>
            <p>Todos os endpoints descritos nesta documentação são relativos a esta URL base.</p>
        </section>

        <!-- ── ENDPOINTS ──────────────────────────────────────────── -->

        <!-- Verificar Token -->
        <section class="section" id="ep-me">
            <h2>Verificar Token</h2>
            <div class="endpoint-card">
                <div class="endpoint-header">
                    <span class="method method-get">GET</span>
                    <span class="endpoint-url">/me</span>
                </div>
                <div class="endpoint-body">
                    <p>
                        Endpoint inicial para validar integração. Retorna dados do cliente vinculado ao token
                        e saldos da wallet.
                    </p>

                    <h3>Exemplo de Requisição</h3>
                    <pre><code>GET /api/v1/external/me
Authorization: Bearer SEU_TOKEN_AQUI</code></pre>

                    <h3>Resposta <code>200 OK</code></h3>
                    <pre><code>{
    "token_valid": true,
    "customer": {
        "id": 101,
        "name": "Cliente Exemplo",
        "email": "cliente@email.com",
        "phone": "+5511999999999",
        "status": 1
    },
    "wallet": {
        "wallet_balance": 150.00,
        "reserved_balance": 20.00,
        "available_balance": 130.00
    },
    "api_token": {
        "id": 12,
        "label": "Integracao Loja X",
        "is_active": true,
        "created_at": "2026-05-15T11:20:00+00:00"
    }
}</code></pre>
                </div>
            </div>
        </section>

        <!-- Simular Frete -->
        <section class="section" id="ep-quote">
            <h2>Simular Frete</h2>
            <div class="endpoint-card">
                <div class="endpoint-header">
                    <span class="method method-post">POST</span>
                    <span class="endpoint-url">/quote</span>
                </div>
                <div class="endpoint-body">
                    <p>
                        Calcula o frete automaticamente usando:
                        <strong>origem = endereço do cliente vinculado ao token</strong> e
                        <strong>destino = endereço do destinatário enviado no payload</strong>.
                    </p>

                    <h3>Corpo da Requisição (JSON)</h3>
                    <table>
                        <thead><tr><th>Campo</th><th>Tipo</th><th>Obrigatório</th><th>Descrição</th></tr></thead>
                        <tbody>
                            <tr>
                                <td><code>recipient_address</code></td>
                                <td>string</td>
                                <td><span class="badge badge-required">Obrigatório</span></td>
                                <td>Endereço de destino</td>
                            </tr>
                            <tr>
                                <td><code>recipient_lat</code></td>
                                <td>number</td>
                                <td><span class="badge badge-optional">Opcional</span></td>
                                <td>Se não enviar, a API tenta converter do endereço</td>
                            </tr>
                            <tr>
                                <td><code>recipient_lng</code></td>
                                <td>number</td>
                                <td><span class="badge badge-optional">Opcional</span></td>
                                <td>Se não enviar, a API tenta converter do endereço</td>
                            </tr>
                        </tbody>
                    </table>

                    <h3>Exemplo de Requisição</h3>
                    <pre><code>POST /api/v1/external/quote
Authorization: Bearer SEU_TOKEN_AQUI
Content-Type: application/json

{
    "recipient_address": "Av. Paulista, 1000 - Bela Vista, São Paulo - SP"
}</code></pre>

                    <h3>Resposta <code>200 OK</code></h3>
                    <pre><code>{
    "sender": {
        "lat": -23.500000,
        "lng": -46.600000,
        "address": "Rua de origem do cliente"
    },
    "recipient": {
        "lat": -23.563611,
        "lng": -46.654389,
        "address": "Av. Paulista, 1000 - Bela Vista, São Paulo - SP"
    },
    "distance_km": 8.432,
    "per_km_charge": 2.00,
    "minimum_shipping_charge": 10.00,
    "delivery_fee": 16.86
}</code></pre>
                </div>
            </div>
        </section>

        <!-- Criar Pedido -->
        <section class="section" id="ep-create">
            <h2>Criar Pedido</h2>
            <div class="endpoint-card">
                <div class="endpoint-header">
                    <span class="method method-post">POST</span>
                    <span class="endpoint-url">/orders</span>
                </div>
                <div class="endpoint-body">
                    <p>
                        Cria um novo pedido de entrega. O saldo necessário é
                        <strong>reservado imediatamente</strong> na sua wallet — o débito
                        definitivo ocorre apenas após a entrega ser concluída.
                        O frete é calculado pelo servidor (não é enviado pelo cliente).
                    </p>

                    <h3>Corpo da Requisição (JSON)</h3>
                    <table>
                        <thead><tr><th>Campo</th><th>Tipo</th><th>Obrigatório</th><th>Descrição</th></tr></thead>
                        <tbody>
                            <tr>
                                <td><code>recipient_name</code></td>
                                <td>string</td>
                                <td><span class="badge badge-required">Obrigatório</span></td>
                                <td>Nome completo do destinatário</td>
                            </tr>
                            <tr>
                                <td><code>recipient_phone</code></td>
                                <td>string</td>
                                <td><span class="badge badge-required">Obrigatório</span></td>
                                <td>Telefone do destinatário (ex: <code>+5511999999999</code>)</td>
                            </tr>
                            <tr>
                                <td><code>recipient_address</code></td>
                                <td>string</td>
                                <td><span class="badge badge-required">Obrigatório</span></td>
                                <td>Endereço completo de entrega</td>
                            </tr>
                            <tr>
                                <td><code>recipient_lat</code></td>
                                <td>number</td>
                                <td><span class="badge badge-optional">Opcional</span></td>
                                <td>Latitude do endereço de entrega. Se não enviar, a API tenta converter pelo endereço.</td>
                            </tr>
                            <tr>
                                <td><code>recipient_lng</code></td>
                                <td>number</td>
                                <td><span class="badge badge-optional">Opcional</span></td>
                                <td>Longitude do endereço de entrega. Se não enviar, a API tenta converter pelo endereço.</td>
                            </tr>
                            <tr>
                                <td><code>external_reference_id</code></td>
                                <td>string</td>
                                <td><span class="badge badge-optional">Opcional</span></td>
                                <td>ID do pedido no seu sistema (para rastreamento). Máx. 100 caracteres.</td>
                            </tr>
                            <tr>
                                <td><code>note</code></td>
                                <td>string</td>
                                <td><span class="badge badge-optional">Opcional</span></td>
                                <td>Observações para o entregador (ex: "Frágil", "Não bater")</td>
                            </tr>
                        </tbody>
                    </table>

                    <h3>Exemplo de Requisição</h3>
                    <p>Exemplo mínimo (somente endereço do destinatário):</p>
                    <pre><code>POST /api/v1/external/orders
Authorization: Bearer SEU_TOKEN_AQUI
Content-Type: application/json

{
    "recipient_name":        "Maria da Silva",
    "recipient_phone":       "+5511987654321",
    "recipient_address":     "Av. Paulista, 1000 - Bela Vista, São Paulo - SP",
    "external_reference_id": "PED-2024-001",
    "note":                  "Portão azul, tocar campainha"
}</code></pre>

                    <h3>Resposta de Sucesso <code>201 Created</code></h3>
                    <pre><code>{
    "message":               "Pedido criado com sucesso.",
    "order_id":              12345,
    "external_reference_id": "PED-2024-001",
    "order_status":          "pending",
    "distance_km":           8.432,
    "order_amount":          28.50,
    "reserved_balance":      28.50
}</code></pre>
                    <div class="alert alert-success">
                        Guarde o <code>order_id</code> retornado para consultar o status ou cancelar o pedido.
                    </div>
                </div>
            </div>
        </section>

        <!-- Status -->
        <section class="section" id="ep-status">
            <h2>Consultar Status do Pedido</h2>
            <div class="endpoint-card">
                <div class="endpoint-header">
                    <span class="method method-get">GET</span>
                    <span class="endpoint-url">/orders/{id}</span>
                </div>
                <div class="endpoint-body">
                    <p>
                        Retorna os detalhes e o status atual de um pedido.
                        O parâmetro <code>{id}</code> pode ser o <strong>ID interno</strong> (número)
                        ou o seu <strong>external_reference_id</strong>.
                    </p>

                    <h3>Exemplo de Requisição</h3>
                    <pre><code>GET /api/v1/external/orders/12345
Authorization: Bearer SEU_TOKEN_AQUI</code></pre>
                    <p>— ou usando seu ID externo —</p>
                    <pre><code>GET /api/v1/external/orders/PED-2024-001
Authorization: Bearer SEU_TOKEN_AQUI</code></pre>

                    <h3>Resposta de Sucesso <code>200 OK</code></h3>
                    <pre><code>{
    "order_id":              12345,
    "external_reference_id": "PED-2024-001",
    "order_status":          "out_for_delivery",
    "payment_status":        "unpaid",
    "order_amount":          28.50,
    "recipient": {
        "name":    "Maria da Silva",
        "phone":   "+5511987654321",
        "address": "Av. Paulista, 1000 - Bela Vista, São Paulo - SP"
    },
    "delivery_man": {
        "name":  "Carlos Motoboy",
        "phone": "+5511911111111"
    },
    "otp":        "4821",
    "created_at": "2024-05-15T10:30:00+00:00",
    "updated_at": "2024-05-15T11:05:00+00:00"
}</code></pre>
                    <p>O campo <code>otp</code> só é retornado quando o pedido está em status <code>out_for_delivery</code>.</p>
                </div>
            </div>
        </section>

        <!-- Listar -->
        <section class="section" id="ep-list">
            <h2>Listar Pedidos</h2>
            <div class="endpoint-card">
                <div class="endpoint-header">
                    <span class="method method-get">GET</span>
                    <span class="endpoint-url">/orders</span>
                </div>
                <div class="endpoint-body">
                    <p>Retorna a lista paginada de todos os pedidos criados pelo seu token.</p>

                    <h3>Parâmetros de Query (opcionais)</h3>
                    <table>
                        <thead><tr><th>Parâmetro</th><th>Padrão</th><th>Descrição</th></tr></thead>
                        <tbody>
                            <tr><td><code>limit</code></td><td>20</td><td>Itens por página (máx. 100)</td></tr>
                            <tr><td><code>page</code></td><td>1</td><td>Número da página</td></tr>
                        </tbody>
                    </table>

                    <h3>Exemplo de Requisição</h3>
                    <pre><code>GET /api/v1/external/orders?limit=10&amp;page=1
Authorization: Bearer SEU_TOKEN_AQUI</code></pre>

                    <h3>Resposta <code>200 OK</code></h3>
                    <pre><code>{
    "total": 42,
    "limit": 10,
    "page":  1,
    "orders": [
        {
            "id":                    12345,
            "external_reference_id": "PED-2024-001",
            "order_status":          "delivered",
            "payment_status":        "paid",
            "order_amount":          28.50,
            "created_at":            "2024-05-15T10:30:00.000000Z"
        }
    ]
}</code></pre>
                </div>
            </div>
        </section>

        <!-- Cancelar -->
        <section class="section" id="ep-cancel">
            <h2>Cancelar Pedido</h2>
            <div class="endpoint-card">
                <div class="endpoint-header">
                    <span class="method method-delete">DELETE</span>
                    <span class="endpoint-url">/orders/{id}</span>
                </div>
                <div class="endpoint-body">
                    <p>
                        Cancela um pedido. O saldo reservado é <strong>devolvido imediatamente</strong>
                        caso o pedido ainda não tenha sido iniciado. Pedidos em trânsito não podem ser
                        cancelados.
                    </p>
                    <div class="alert alert-warn">
                        Só é possível cancelar pedidos com status <code>pending</code> ou <code>confirmed</code>.
                    </div>

                    <h3>Corpo da Requisição (JSON, opcional)</h3>
                    <table>
                        <thead><tr><th>Campo</th><th>Tipo</th><th>Descrição</th></tr></thead>
                        <tbody>
                            <tr>
                                <td><code>reason</code></td>
                                <td>string</td>
                                <td>Motivo do cancelamento (opcional)</td>
                            </tr>
                        </tbody>
                    </table>

                    <h3>Exemplo de Requisição</h3>
                    <pre><code>DELETE /api/v1/external/orders/12345
Authorization: Bearer SEU_TOKEN_AQUI
Content-Type: application/json

{
    "reason": "Cliente desistiu do pedido"
}</code></pre>

                    <h3>Resposta <code>200 OK</code></h3>
                    <pre><code>{
    "message":          "Pedido cancelado. Saldo devolvido.",
    "order_id":         12345,
    "order_status":     "canceled",
    "released_amount":  28.50,
    "reserved_balance": 0.00
}</code></pre>
                </div>
            </div>
        </section>

        <!-- Statuses -->
        <section class="section" id="statuses">
            <h2>📋 Status do Pedido</h2>
            <table>
                <thead><tr><th>Status</th><th>Descrição</th><th>Pode Cancelar?</th></tr></thead>
                <tbody>
                    <tr><td><code>pending</code></td><td>Aguardando aceitação por um entregador</td><td>✅ Sim</td></tr>
                    <tr><td><code>confirmed</code></td><td>Entregador confirmou o pedido</td><td>✅ Sim</td></tr>
                    <tr><td><code>processing</code></td><td>Entregador a caminho da coleta</td><td>❌ Não</td></tr>
                    <tr><td><code>picked_up</code></td><td>Entregador coletou o pacote</td><td>❌ Não</td></tr>
                    <tr><td><code>out_for_delivery</code></td><td>Em rota de entrega ao destinatário</td><td>❌ Não</td></tr>
                    <tr><td><code>delivered</code></td><td>Entrega concluída com sucesso</td><td>❌ Não</td></tr>
                    <tr><td><code>canceled</code></td><td>Pedido cancelado</td><td>—</td></tr>
                    <tr><td><code>failed</code></td><td>Falha na entrega</td><td>—</td></tr>
                </tbody>
            </table>
        </section>

        <!-- Errors -->
        <section class="section" id="errors">
            <h2>❌ Erros</h2>
            <p>Em caso de erro, a API retorna um JSON com a chave <code>errors</code>:</p>
            <pre><code>{
    "errors": [
        {
            "code":    "insufficient_balance",
            "message": "Saldo insuficiente na wallet. Disponível: R$ 10,00"
        }
    ]
}</code></pre>
            <table>
                <thead><tr><th>HTTP Status</th><th>Código</th><th>Descrição</th></tr></thead>
                <tbody>
                    <tr><td><code>401</code></td><td><code>unauthorized</code></td><td>Token ausente ou inválido</td></tr>
                    <tr><td><code>403</code></td><td><code>unauthorized</code></td><td>Usuário bloqueado</td></tr>
                    <tr><td><code>404</code></td><td><code>not_found</code></td><td>Pedido não encontrado</td></tr>
                    <tr><td><code>422</code></td><td><code>insufficient_balance</code></td><td>Saldo disponível insuficiente</td></tr>
                    <tr><td><code>422</code></td><td><code>cannot_cancel</code></td><td>Status não permite cancelamento</td></tr>
                    <tr><td><code>422</code></td><td><em>(campo)</em></td><td>Erro de validação do payload</td></tr>
                    <tr><td><code>500</code></td><td><code>server_error</code></td><td>Erro interno — tente novamente</td></tr>
                </tbody>
            </table>
        </section>

        <!-- Flow -->
        <section class="section" id="flow">
            <h2>🔄 Fluxo Completo</h2>
                <pre><code>1. Sistema externo → GET /me
    ↳ Valida token e confirma dados/saldo do cliente

2. Sistema externo → POST /quote
    ↳ Recebe o valor calculado do frete

3. Sistema externo → POST /orders
    ↳ Cria pedido usando cálculo interno e reserva o saldo

4. Polling ou webhook → GET /orders/{id}
   ↳ Acompanha: pending → confirmed → out_for_delivery → delivered

5a. Entrega concluída (delivered)
    ↳ Saldo debitado definitivamente pela plataforma

5b. Pedido cancelado (canceled)
    ↳ DELETE /orders/{id}  — saldo reservado é liberado</code></pre>

            <div class="alert alert-info">
                <strong>Dica:</strong> Use o campo <code>external_reference_id</code> ao criar o pedido
                para manter sincronia com seu sistema. Você pode consultar ou cancelar pelo seu próprio ID.
            </div>

            <div class="alert alert-warn" style="margin-top: 24px">
                <strong>Precisa de acesso?</strong>
                Entre em contato com o administrador da plataforma e informe os dados da sua empresa
                para receber um token de API vinculado à sua wallet.
            </div>
        </section>

    </main>
</div>

<script>
    // Destaca link ativo no sidebar ao fazer scroll
    const sections = document.querySelectorAll('section[id]');
    const links    = document.querySelectorAll('.sidebar nav a');
    window.addEventListener('scroll', () => {
        let current = '';
        sections.forEach(s => {
            if (window.scrollY >= s.offsetTop - 80) current = s.id;
        });
        links.forEach(a => {
            a.classList.toggle('active', a.getAttribute('href') === '#' + current);
        });
    }, { passive: true });
</script>
</body>
</html>
