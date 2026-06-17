@extends('layouts.admin.app')

@section('title', 'Asaas — Pagamentos PIX')

@push('css_or_js')
<style>
    .asaas-tab-nav .nav-link { font-weight: 500; }
    .pix-badge { font-size: 0.75rem; padding: 3px 8px; border-radius: 20px; }
    .pix-badge-cpf    { background:#e3f0ff; color:#0d6efd; }
    .pix-badge-email  { background:#fff3cd; color:#856404; }
    .pix-badge-phone  { background:#d1e7dd; color:#0f5132; }
    .pix-badge-cnpj   { background:#f8d7da; color:#842029; }
    .pix-badge-evp    { background:#f0e6ff; color:#6f42c1; }
</style>
@endpush

@section('content')
<div class="content container-fluid">

    {{-- Page Header --}}
    <div class="page-header mb-0">
        <h1 class="page-header-title">
            <span class="page-header-icon">
                <img src="{{ asset('/public/assets/admin/img/business.png') }}" class="w--26" alt="">
            </span>
            <span>Asaas — Pagamentos PIX</span>
        </h1>
    </div>

    {{-- Tab Nav --}}
    <ul class="nav nav-tabs asaas-tab-nav border-bottom mt-3 mb-4" id="asaasTabs" role="tablist">
        <li class="nav-item">
            <a class="nav-link {{ $tab === 'settings' ? 'active' : '' }}"
               href="{{ route('admin.transactions.asaas.index', ['tab' => 'settings']) }}">
                <i class="tio-settings-outlined mr-1"></i> Configurações
            </a>
        </li>
        <li class="nav-item">
            <a class="nav-link {{ $tab === 'saques' ? 'active' : '' }}"
               href="{{ route('admin.transactions.asaas.index', ['tab' => 'saques']) }}">
                <i class="tio-money mr-1"></i> Saques dos Entregadores
            </a>
        </li>
        <li class="nav-item">
            <a class="nav-link {{ $tab === 'pix' ? 'active' : '' }}"
               href="{{ route('admin.transactions.asaas.index', ['tab' => 'pix']) }}">
                <i class="tio-key mr-1"></i> Chaves PIX
            </a>
        </li>
        <li class="nav-item">
            <a class="nav-link {{ $tab === 'entregadores' ? 'active' : '' }}"
               href="{{ route('admin.transactions.asaas.index', ['tab' => 'entregadores']) }}">
                <i class="tio-user mr-1"></i> Entregadores
            </a>
        </li>
    </ul>

    {{-- ══════════════════════════════════════════════════════════ --}}
    {{-- TAB 1 — CONFIGURAÇÕES                                      --}}
    {{-- ══════════════════════════════════════════════════════════ --}}
    @if($tab === 'settings')
    <form action="{{ route('admin.transactions.asaas.save-settings') }}" method="POST">
        @csrf
        <div class="row g-3">
            <div class="col-12">
                <div class="card">
                    <div class="card-header">
                        <h5 class="card-title mb-0">Integração Asaas</h5>
                        <p class="text-muted mb-0 mt-1" style="font-size:.875rem;">
                            Configure a API do Asaas para processar transferências PIX automáticas para os entregadores.
                        </p>
                    </div>
                    <div class="card-body">
                        <div class="row g-3">

                            {{-- Auto-transferência --}}
                            <div class="col-12">
                                <div class="border rounded p-3 d-flex align-items-center gap-3">
                                    <label class="toggle-switch mb-0" for="dm_asaas_auto_transfer">
                                        <input type="checkbox" class="toggle-switch-input"
                                               name="dm_asaas_auto_transfer" id="dm_asaas_auto_transfer"
                                               value="1" {{ (int)($settings['dm_asaas_auto_transfer'] ?? 0) === 1 ? 'checked' : '' }}>
                                        <span class="toggle-switch-label">
                                            <span class="toggle-switch-indicator"></span>
                                        </span>
                                    </label>
                                    <div>
                                        <strong>Auto-transferência via Asaas</strong>
                                        <p class="text-muted mb-0" style="font-size:.8rem;">
                                            Quando ativado, ao aprovar um saque o sistema envia automaticamente a transferência PIX pelo Asaas.
                                        </p>
                                    </div>
                                </div>
                            </div>

                            {{-- Base URL --}}
                            <div class="col-md-6">
                                <label for="asaas_base_url" class="form-label fw-semibold">
                                    Asaas Base URL
                                    <small class="text-muted">(ambiente)</small>
                                </label>
                                <input id="asaas_base_url" type="text" name="asaas_base_url"
                                       class="form-control"
                                       value="{{ $settings['asaas_base_url'] }}"
                                       placeholder="https://www.asaas.com/api/v3">
                                <div class="mt-1" style="font-size:.78rem;">
                                    <span class="text-muted">Produção:</span>
                                    <code>https://www.asaas.com/api/v3</code>
                                    &nbsp;|&nbsp;
                                    <span class="text-muted">Sandbox:</span>
                                    <code>https://sandbox.asaas.com/api/v3</code>
                                </div>
                            </div>

                            {{-- API Key --}}
                            <div class="col-md-6">
                                <label for="asaas_api_key" class="form-label fw-semibold">Asaas API Key</label>
                                <div class="input-group">
                                    <input id="asaas_api_key" type="password" name="asaas_api_key"
                                           class="form-control"
                                           value="{{ $settings['asaas_api_key'] }}"
                                           placeholder="$aact_...">
                                    <button class="btn btn-outline-secondary" type="button"
                                            onclick="toggleApiKey(this)">
                                        <i class="tio-visible-outlined"></i>
                                    </button>
                                </div>
                                <small class="text-muted">Encontre em: Asaas → Configurações → Integração → Chave de API</small>
                            </div>

                            {{-- Webhook Token --}}
                            <div class="col-md-6">
                                <label for="asaas_webhook_token" class="form-label fw-semibold">
                                    Token de Validação do Webhook
                                    <small class="text-muted">(opcional)</small>
                                </label>
                                <div class="input-group">
                                    <input id="asaas_webhook_token" type="password" name="asaas_webhook_token"
                                           class="form-control"
                                           value="{{ $settings['asaas_webhook_token'] }}"
                                           placeholder="Token secreto...">
                                    <button class="btn btn-outline-secondary" type="button"
                                            onclick="this.previousElementSibling.type = this.previousElementSibling.type === 'password' ? 'text' : 'password'">
                                        <i class="tio-visible-outlined"></i>
                                    </button>
                                </div>
                                <small class="text-muted">
                                    Será enviado pelo Asaas no header <code>asaas-access-token</code> a cada validação.
                                    Configure o mesmo token no painel Asaas → Integrações → Mecanismos de segurança.
                                </small>
                            </div>

                            {{-- Webhook URL --}}
                            <div class="col-12">
                                <div class="border rounded p-3 bg-light">
                                    <label class="form-label fw-semibold mb-1">
                                        <i class="tio-link mr-1"></i> URL do Webhook de Validação de Saque
                                    </label>
                                    <div class="input-group">
                                        <input type="text" class="form-control font-monospace"
                                               id="webhookUrlField" readonly
                                               value="{{ url('/api/v1/asaas/webhook') }}">
                                        <button class="btn btn-outline-secondary" type="button"
                                                onclick="copyWebhookUrl()">
                                            <i class="tio-copy"></i> Copiar
                                        </button>
                                    </div>
                                    <small class="text-muted">
                                        Configure esta URL no painel do Asaas em:
                                        <strong>Menu do usuário → Integrações → Mecanismos de segurança → URL do Webhook</strong>.
                                        O Asaas chamará esta URL 5 segundos após cada transferência para validação.
                                    </small>
                                </div>
                            </div>

                        </div>

                        <div class="d-flex justify-content-end mt-4">
                            <button type="submit" class="btn btn--primary px-4">
                                <i class="tio-save mr-1"></i> Salvar configurações
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </form>
    @endif

    {{-- ══════════════════════════════════════════════════════════ --}}
    {{-- TAB 2 — SAQUES                                             --}}
    {{-- ══════════════════════════════════════════════════════════ --}}
    @if($tab === 'saques')
    <div class="card">
        <div class="card-header d-flex flex-wrap align-items-center justify-content-between gap-2">
            <h5 class="card-title mb-0">Saques dos Entregadores</h5>
            <div class="d-flex gap-2 flex-wrap">
                @foreach(['all' => 'Todos', 'pending' => 'Pendente', 'processing' => 'Processando', 'completed' => 'Concluído', 'failed' => 'Erro', 'canceled' => 'Cancelado'] as $s => $label)
                    <a href="{{ route('admin.transactions.asaas.index', ['tab' => 'saques', 'status' => $s]) }}"
                       class="btn btn-sm {{ $status === $s ? ($s === 'failed' ? 'btn-danger' : 'btn--primary') : ($s === 'failed' ? 'btn-outline-danger' : 'btn-outline-secondary') }}">
                        {{ $label }}
                    </a>
                @endforeach
            </div>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0">
                    <thead class="thead-light">
                        <tr>
                            <th>#</th>
                            <th>Entregador</th>
                            <th>Valor</th>
                            <th>Status</th>
                            <th>Asaas Status</th>
                            <th>ID Transferência</th>
                            <th>Processado em</th>
                            <th>Ações</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($disbursements as $d)
                        <tr class="{{ $d->status === 'failed' ? 'table-danger' : '' }}">
                            <td>{{ $d->id }}</td>
                            <td>
                                <div>{{ $d->delivery_man?->f_name }} {{ $d->delivery_man?->l_name }}</div>
                                <small class="text-muted">{{ $d->delivery_man?->phone }}</small>
                            </td>
                            <td><strong>{{ \App\CentralLogics\Helpers::format_currency($d->disbursement_amount) }}</strong></td>
                            <td>
                                @php $sc = match($d->status) { 'completed' => 'success', 'pending' => 'warning', 'failed' => 'danger', 'canceled' => 'secondary', default => 'info' }; @endphp
                                @php $statusLabel = match($d->status) { 'completed' => 'Concluído', 'pending' => 'Pendente', 'failed' => 'Erro', 'canceled' => 'Cancelado', default => ucfirst($d->status) }; @endphp
                                <span class="badge badge-soft-{{ $sc }}">{{ $statusLabel }}</span>
                            </td>
                            <td>
                                @if($d->payout_provider === 'asaas')
                                    @php $ac = match($d->payout_status ?? '') { 'paid','transferred' => 'success', 'failed','error' => 'danger', default => 'warning' }; @endphp
                                    <span class="badge badge-soft-{{ $ac }}">{{ $d->payout_status ?? 'pendente' }}</span>
                                    @if($d->payout_error)
                                        <br><small class="text-danger" title="{{ $d->payout_error }}">
                                            <i class="tio-warning-outlined"></i> Erro
                                        </small>
                                    @endif
                                @else
                                    <span class="text-muted">—</span>
                                @endif
                            </td>
                            <td>
                                @if($d->asaas_transfer_id)
                                    <code style="font-size:.75rem;">{{ $d->asaas_transfer_id }}</code>
                                @else
                                    <span class="text-muted">—</span>
                                @endif
                            </td>
                            <td>
                                {{ $d->payout_processed_at ? \Carbon\Carbon::parse($d->payout_processed_at)->format('d/m/Y H:i') : '—' }}
                            </td>
                            <td>
                                <div class="d-flex gap-1 flex-wrap">
                                    <a href="{{ route('admin.transactions.dm-disbursement.view', $d->disbursement_id) }}"
                                       class="btn btn-sm btn-outline-primary" title="Ver detalhes">
                                        <i class="tio-visible-outlined"></i>
                                    </a>
                                    @if($d->asaas_transfer_id)
                                    <a href="{{ route('admin.transactions.dm-disbursement.sync-asaas', $d->id) }}"
                                       class="btn btn-sm btn-outline-info"
                                       title="Consultar status atual no Asaas e sincronizar"
                                       onclick="return confirm('Consultar status desta transferência no Asaas e sincronizar?')">
                                        <i class="tio-refresh"></i>
                                    </a>
                                    @endif
                                    @if(!in_array($d->status, ['completed', 'failed', 'canceled']))
                                    <a href="{{ route('admin.transactions.dm-disbursement.process-asaas', $d->id) }}"
                                       class="btn btn-sm btn-outline-success"
                                       title="Retentar transferência via Asaas"
                                       onclick="return confirm('Processar transferência Asaas para este saque?')">
                                        <i class="tio-send"></i>
                                    </a>
                                    @endif
                                </div>
                            </td>
                        </tr>
                        @empty
                        <tr>
                            <td colspan="8" class="text-center py-5">
                                <img src="{{ asset('/public/assets/admin/svg/illustrations/sorry.svg') }}" height="80" alt="">
                                <p class="mt-2 text-muted">Nenhum saque encontrado</p>
                            </td>
                        </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
        @if($disbursements->hasPages())
        <div class="card-footer d-flex justify-content-end">
            {{ $disbursements->links() }}
        </div>
        @endif
    </div>
    @endif

    {{-- ══════════════════════════════════════════════════════════ --}}
    {{-- TAB 3 — CHAVES PIX                                         --}}
    {{-- ══════════════════════════════════════════════════════════ --}}
    @if($tab === 'pix')
    <div class="card">
        <div class="card-header d-flex align-items-center justify-content-between">
            <h5 class="card-title mb-0">Chaves PIX dos Entregadores</h5>
            <small class="text-muted">Total: {{ $pixAccounts->total() }}</small>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0">
                    <thead class="thead-light">
                        <tr>
                            <th>Entregador</th>
                            <th>Chave PIX</th>
                            <th>Tipo</th>
                            <th>Titular</th>
                            <th>Documento</th>
                            <th>Verificado</th>
                            <th>Cadastrado em</th>
                            <th>Ações</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($pixAccounts as $pix)
                        <tr>
                            <td>
                                <div class="fw-semibold">{{ $pix->deliveryMan?->f_name }} {{ $pix->deliveryMan?->l_name }}</div>
                                <small class="text-muted">{{ $pix->deliveryMan?->phone }}</small>
                            </td>
                            <td><code>{{ $pix->pix_key }}</code></td>
                            <td>
                                @php $typeClass = 'pix-badge-' . strtolower($pix->pix_key_type ?? 'evp'); @endphp
                                <span class="pix-badge {{ $typeClass }}">{{ $pix->pix_key_type ?? '—' }}</span>
                            </td>
                            <td>{{ $pix->holder_name ?: '—' }}</td>
                            <td>{{ $pix->holder_document ?: '—' }}</td>
                            <td>
                                @if($pix->is_verified)
                                    <span class="badge badge-soft-success">Verificado</span>
                                @else
                                    <span class="badge badge-soft-secondary">Não verificado</span>
                                @endif
                            </td>
                            <td>{{ \Carbon\Carbon::parse($pix->created_at)->format('d/m/Y H:i') }}</td>
                            <td>
                                <a href="{{ route('admin.transactions.dm-disbursement.reset-pix', $pix->delivery_man_id) }}"
                                   class="btn btn-sm btn-outline-danger"
                                   title="Redefinir chave PIX"
                                   onclick="return confirm('Tem certeza? O entregador precisará cadastrar uma nova chave PIX.')">
                                    <i class="tio-refresh"></i> Redefinir
                                </a>
                            </td>
                        </tr>
                        @empty
                        <tr>
                            <td colspan="8" class="text-center py-5">
                                <img src="{{ asset('/public/assets/admin/svg/illustrations/sorry.svg') }}" height="80" alt="">
                                <p class="mt-2 text-muted">Nenhuma chave PIX cadastrada</p>
                            </td>
                        </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
        @if($pixAccounts->hasPages())
        <div class="card-footer d-flex justify-content-end">
            {{ $pixAccounts->links() }}
        </div>
        @endif
    </div>
    @endif

    {{-- ══════════════════════════════════════════════════════════ --}}
    {{-- TAB 4 — ENTREGADORES E SALDOS                              --}}
    {{-- ══════════════════════════════════════════════════════════ --}}
    @if($tab === 'entregadores')
    @php
        $formatMoney = function ($value) {
            $currencySymbol = \App\CentralLogics\Helpers::currency_symbol();
            $formattedValue = number_format((float) $value, 2, ',', '.');

            return config('currency_symbol_position') === 'right'
                ? $formattedValue . ' ' . $currencySymbol
                : $currencySymbol . ' ' . $formattedValue;
        };
    @endphp
    <div class="card mb-4">
        <div class="card-header d-flex flex-wrap justify-content-between align-items-center gap-2">
            <h5 class="card-title mb-0">Saldos dos Entregadores</h5>
            <form method="GET" action="{{ route('admin.transactions.asaas.index') }}" class="d-flex gap-2">
                <input type="hidden" name="tab" value="entregadores">
                @if($selectedDmId)
                    <input type="hidden" name="dm_id" value="{{ $selectedDmId }}">
                @endif
                <input type="text" name="search" class="form-control" placeholder="Buscar por nome/telefone" value="{{ $search }}">
                <button class="btn btn--primary" type="submit"><i class="tio-search"></i></button>
            </form>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0">
                    <thead class="thead-light">
                        <tr>
                            <th>#</th>
                            <th>Entregador</th>
                            <th>Saldo Plataforma</th>
                            <th>Saldo Digital</th>
                            <th>Dinheiro em Mãos</th>
                            <th>Pend. Saque</th>
                            <th>Cancelados (DM)</th>
                            <th>Não aceitos/Falhos</th>
                            <th>Ações</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($deliveryMen ?? [] as $dm)
                            @php
                                $totalEarning = (float) ($dm->wallet?->total_earning ?? 0);
                                $totalWithdrawn = (float) ($dm->wallet?->total_withdrawn ?? 0);
                                $pendingWithdraw = (float) ($dm->wallet?->pending_withdraw ?? 0);
                                $collectedCash = (float) ($dm->wallet?->collected_cash ?? 0);
                                $digitalBalance = $totalEarning - ($totalWithdrawn + $pendingWithdraw);
                                $platformNetBalance = $totalEarning - ($totalWithdrawn + $pendingWithdraw + $collectedCash);
                            @endphp
                            <tr>
                                <td>{{ $dm->id }}</td>
                                <td>
                                    <div class="font-weight-semibold">{{ $dm->f_name }} {{ $dm->l_name }}</div>
                                    <small class="text-muted">{{ $dm->phone }}</small>
                                </td>
                                <td>
                                    <strong class="{{ $platformNetBalance > 0 ? 'text-success' : ($platformNetBalance < 0 ? 'text-danger' : 'text-muted') }}">
                                        {{ $formatMoney($platformNetBalance) }}
                                    </strong>
                                </td>
                                <td>{{ $formatMoney($digitalBalance) }}</td>
                                <td>{{ $formatMoney($collectedCash) }}</td>
                                <td>{{ $formatMoney($pendingWithdraw) }}</td>
                                <td><span class="badge badge-soft-warning">{{ $dm->canceled_by_dm_orders_count ?? 0 }}</span></td>
                                <td>
                                    <span class="badge badge-soft-danger" title="Proxy de pedidos não aceitos no fluxo atual">{{ $dm->failed_orders_count ?? 0 }}</span>
                                </td>
                                <td>
                                    <a class="btn btn-sm btn-outline-primary"
                                       href="{{ route('admin.transactions.asaas.index', ['tab' => 'entregadores', 'dm_id' => $dm->id, 'search' => $search]) }}#dm-history">
                                        <i class="tio-visible"></i> Ver histórico
                                    </a>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="9" class="text-center py-5">
                                    <img src="{{ asset('/public/assets/admin/svg/illustrations/sorry.svg') }}" height="80" alt="">
                                    <p class="mt-2 text-muted">Nenhum entregador encontrado</p>
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
        @if(($deliveryMen ?? null) && $deliveryMen->hasPages())
            <div class="card-footer d-flex justify-content-end">
                {{ $deliveryMen->links() }}
            </div>
        @endif
    </div>

    @if($selectedDeliveryMan)
    <div class="card mb-4" id="dm-history" style="scroll-margin-top: 90px;">
        <div class="card-header d-flex flex-wrap justify-content-between align-items-center gap-2">
            <h5 class="card-title mb-0">Histórico do Entregador: {{ $selectedDeliveryMan->f_name }} {{ $selectedDeliveryMan->l_name }}</h5>
            <small class="text-muted">Telefone: {{ $selectedDeliveryMan->phone }}</small>
        </div>
        <div class="card-body">
            <div class="row g-3 mb-4">
                <div class="col-md-3">
                    <div class="border rounded p-3 h-100">
                        <small class="text-muted d-block">Saldo Plataforma</small>
                        <strong class="{{ ($selectedWalletSummary['status'] ?? 'neutral') === 'positive' ? 'text-success' : (($selectedWalletSummary['status'] ?? 'neutral') === 'negative' ? 'text-danger' : 'text-muted') }}">
                            {{ $formatMoney($selectedWalletSummary['platform_net_balance'] ?? 0) }}
                        </strong>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="border rounded p-3 h-100">
                        <small class="text-muted d-block">Saldo Digital</small>
                        <strong>{{ $formatMoney($selectedWalletSummary['digital_balance'] ?? 0) }}</strong>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="border rounded p-3 h-100">
                        <small class="text-muted d-block">Dinheiro em Mãos</small>
                        <strong>{{ $formatMoney($selectedWalletSummary['collected_cash'] ?? 0) }}</strong>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="border rounded p-3 h-100">
                        <small class="text-muted d-block">Pendente de Saque</small>
                        <strong>{{ $formatMoney($selectedWalletSummary['pending_withdraw'] ?? 0) }}</strong>
                    </div>
                </div>
            </div>

            <div class="row g-3">
                <div class="col-lg-6">
                    <h6 class="mb-2">Histórico de Dinheiro em Mãos</h6>
                    <div class="table-responsive border rounded">
                        <table class="table table-sm table-hover mb-0">
                            <thead class="thead-light">
                                <tr>
                                    <th>Data</th>
                                    <th>Tipo</th>
                                    <th>Valor</th>
                                    <th>Pedido</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse($selectedDmCashLogs as $log)
                                    <tr>
                                        <td>{{ \Carbon\Carbon::parse($log->created_at)->format('d/m/Y H:i') }}</td>
                                        <td><span class="badge badge-soft-{{ $log->type_badge }}">{{ $log->type_label }}</span></td>
                                        <td>{{ $formatMoney($log->amount) }}</td>
                                        <td>{{ $log->order_id ? '#'.$log->order_id : '—' }}</td>
                                    </tr>
                                @empty
                                    <tr><td colspan="4" class="text-center text-muted py-3">Sem histórico</td></tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>
                </div>

                <div class="col-lg-6">
                    <h6 class="mb-2">Histórico de Saques</h6>
                    <div class="table-responsive border rounded">
                        <table class="table table-sm table-hover mb-0">
                            <thead class="thead-light">
                                <tr>
                                    <th>Data</th>
                                    <th>Valor</th>
                                    <th>Status</th>
                                    <th>Asaas</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse($selectedDmDisbursements as $withdraw)
                                    <tr>
                                        <td>{{ \Carbon\Carbon::parse($withdraw->created_at)->format('d/m/Y H:i') }}</td>
                                        <td>{{ $formatMoney($withdraw->disbursement_amount) }}</td>
                                        <td><span class="badge badge-soft-secondary">{{ $withdraw->status }}</span></td>
                                        <td>{{ $withdraw->payout_status ?? '—' }}</td>
                                    </tr>
                                @empty
                                    <tr><td colspan="4" class="text-center text-muted py-3">Sem saques</td></tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

            <div class="mt-4">
                <h6 class="mb-2">Pedidos (cancelados / não aceitos-falhos / concluídos)</h6>
                <div class="table-responsive border rounded">
                    <table class="table table-sm table-hover mb-0">
                        <thead class="thead-light">
                            <tr>
                                <th>Pedido</th>
                                <th>Status</th>
                                <th>Cancelado por</th>
                                <th>Motivo</th>
                                <th>Valor</th>
                                <th>Criado em</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($selectedDmOrders as $order)
                                <tr>
                                    <td>#{{ $order->id }}</td>
                                    <td>
                                        @php
                                            $badge = match($order->order_status) {
                                                'delivered' => 'success',
                                                'canceled' => 'warning',
                                                'failed' => 'danger',
                                                default => 'secondary'
                                            };
                                        @endphp
                                        <span class="badge badge-soft-{{ $badge }}">{{ $order->order_status }}</span>
                                    </td>
                                    <td>{{ $order->canceled_by ?: '—' }}</td>
                                    <td>{{ $order->cancellation_reason ?: '—' }}</td>
                                    <td>{{ $formatMoney($order->order_amount) }}</td>
                                    <td>{{ \Carbon\Carbon::parse($order->created_at)->format('d/m/Y H:i') }}</td>
                                </tr>
                            @empty
                                <tr><td colspan="6" class="text-center text-muted py-3">Sem pedidos para exibir</td></tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
    @endif
    @endif

</div>
@endsection

@push('script_2')
<script>
"use strict";
function toggleApiKey(btn) {
    const input = document.getElementById('asaas_api_key');
    const isPassword = input.type === 'password';
    input.type = isPassword ? 'text' : 'password';
    btn.querySelector('i').className = isPassword ? 'tio-hidden-outlined' : 'tio-visible-outlined';
}

function copyWebhookUrl() {
    const field = document.getElementById('webhookUrlField');
    field.select();
    field.setSelectionRange(0, 99999);
    navigator.clipboard.writeText(field.value).then(function() {
        toastr.success('URL copiada!');
    }).catch(function() {
        document.execCommand('copy');
        toastr.success('URL copiada!');
    });
}
</script>
@endpush
