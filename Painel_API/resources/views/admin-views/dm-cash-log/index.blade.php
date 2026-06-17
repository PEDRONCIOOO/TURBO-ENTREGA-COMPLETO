@extends('layouts.admin.app')

@section('title', 'Logs de Dinheiro em Mãos')

@push('css_or_js')
<style>
    .badge-type-cash_assigned      { background-color: #f0ad4e; color: #fff; }
    .badge-type-adjustment_partial { background-color: #5bc0de; color: #fff; }
    .badge-type-adjustment_full    { background-color: #5cb85c; color: #fff; }
    .summary-card { border-left: 4px solid; }
    .summary-card.assigned { border-left-color: #f0ad4e; }
    .summary-card.adjusted { border-left-color: #5cb85c; }
</style>
@endpush

@section('content')
<div class="content container-fluid">

    {{-- Cabeçalho --}}
    <div class="page-header">
        <h1 class="page-header-title">
            <span class="page-header-icon">
                <i class="tio-money"></i>
            </span>
            <span>Histórico de Dinheiro em Mãos — Entregadores</span>
        </h1>
        <p class="text-muted mt-1">
            Cada pedido em dinheiro gera um registro de <strong>Dinheiro Atribuído</strong>.
            Quando o entregador faz o ajuste de carteira, um registro de <strong>Ajuste</strong> é criado.
            A comissão da plataforma é abatida do saldo digital do entregador.
        </p>
    </div>

    {{-- Resumo --}}
    <div class="row mb-3">
        <div class="col-sm-4">
            <div class="card summary-card assigned p-3">
                <div class="text-muted small">Total Atribuído (filtro atual)</div>
                <div class="h4 mb-0 font-weight-bold text-warning">
                    {{ config('cart.currency_symbol', 'R$') }} {{ number_format($totals->total_assigned ?? 0, 2, ',', '.') }}
                </div>
            </div>
        </div>
        <div class="col-sm-4">
            <div class="card summary-card adjusted p-3">
                <div class="text-muted small">Total Ajustado (filtro atual)</div>
                <div class="h4 mb-0 font-weight-bold text-success">
                    {{ config('cart.currency_symbol', 'R$') }} {{ number_format($totals->total_adjusted ?? 0, 2, ',', '.') }}
                </div>
            </div>
        </div>
        <div class="col-sm-4">
            <div class="card p-3">
                <div class="text-muted small">Registros</div>
                <div class="h4 mb-0 font-weight-bold">{{ $totals->total_records ?? 0 }}</div>
            </div>
        </div>
    </div>

    {{-- Filtros --}}
    <div class="card mb-3">
        <div class="card-body py-2">
            <form method="GET" action="{{ route('admin.dm-cash-log.index') }}" class="row g-2 align-items-end">
                <div class="col-sm-3">
                    <label class="form-label mb-1">Entregador</label>
                    <select name="dm_id" class="form-control form-control-sm">
                        <option value="">Todos</option>
                        @foreach($delivery_men as $dm)
                            <option value="{{ $dm->id }}" {{ request('dm_id') == $dm->id ? 'selected' : '' }}>
                                {{ $dm->f_name }} {{ $dm->l_name }}
                            </option>
                        @endforeach
                    </select>
                </div>
                <div class="col-sm-2">
                    <label class="form-label mb-1">Tipo</label>
                    <select name="type" class="form-control form-control-sm">
                        <option value="">Todos</option>
                        <option value="cash_assigned"      {{ request('type') === 'cash_assigned'      ? 'selected' : '' }}>Dinheiro Atribuído</option>
                        <option value="adjustment_partial" {{ request('type') === 'adjustment_partial' ? 'selected' : '' }}>Ajuste Parcial</option>
                        <option value="adjustment_full"    {{ request('type') === 'adjustment_full'    ? 'selected' : '' }}>Ajuste Completo</option>
                    </select>
                </div>
                <div class="col-sm-2">
                    <label class="form-label mb-1">De</label>
                    <input type="date" name="date_from" class="form-control form-control-sm" value="{{ request('date_from') }}">
                </div>
                <div class="col-sm-2">
                    <label class="form-label mb-1">Até</label>
                    <input type="date" name="date_to"   class="form-control form-control-sm" value="{{ request('date_to') }}">
                </div>
                <div class="col-sm-3 d-flex gap-2">
                    <button type="submit" class="btn btn-sm btn--primary">
                        <i class="tio-search mr-1"></i> Filtrar
                    </button>
                    <a href="{{ route('admin.dm-cash-log.index') }}" class="btn btn-sm btn-light">Limpar</a>
                </div>
            </form>
        </div>
    </div>

    {{-- Tabela --}}
    <div class="card">
        <div class="card-header py-2 border-0 d-flex align-items-center justify-content-between">
            <h5 class="card-title mb-0">
                <i class="tio-list-bulleted mr-1"></i>
                Registros
                <span class="badge badge-soft-secondary ml-1">{{ $logs->total() }}</span>
            </h5>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover table-borderless table-thead-bordered table-nowrap table-align-middle card-table">
                    <thead class="thead-light">
                        <tr>
                            <th>#</th>
                            <th>Data / Hora</th>
                            <th>Entregador</th>
                            <th>Pedido</th>
                            <th>Tipo</th>
                            <th class="text-right">Valor Transação</th>
                            <th class="text-right">Valor Pedido</th>
                            <th class="text-right">Cash em Mãos (após)</th>
                            <th class="text-right">Saldo Digital (após)</th>
                            <th>Observação</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($logs as $log)
                        <tr>
                            <td>{{ $log->id }}</td>
                            <td>{{ $log->created_at?->format('d/m/Y H:i') }}</td>
                            <td>
                                @if($log->delivery_man)
                                    <a href="{{ route('admin.dm-cash-log.show', $log->delivery_man_id) }}">
                                        {{ $log->delivery_man->f_name }} {{ $log->delivery_man->l_name }}
                                    </a>
                                @else
                                    <span class="text-muted">—</span>
                                @endif
                            </td>
                            <td>
                                @if($log->order_id)
                                    #{{ $log->order_id }}
                                @else
                                    <span class="text-muted">—</span>
                                @endif
                            </td>
                            <td>
                                <span class="badge badge-type-{{ $log->type }}">
                                    {{ $log->type_label }}
                                </span>
                            </td>
                            <td class="text-right font-weight-bold
                                {{ $log->type === 'cash_assigned' ? 'text-warning' : 'text-success' }}">
                                R$ {{ number_format($log->amount, 2, ',', '.') }}
                            </td>
                            <td class="text-right">
                                @if($log->order_amount > 0)
                                    R$ {{ number_format($log->order_amount, 2, ',', '.') }}
                                @else
                                    <span class="text-muted">—</span>
                                @endif
                            </td>
                            <td class="text-right">
                                <span class="{{ $log->collected_cash_after > 0 ? 'text-warning font-weight-bold' : 'text-muted' }}">
                                    R$ {{ number_format($log->collected_cash_after, 2, ',', '.') }}
                                </span>
                            </td>
                            <td class="text-right">
                                R$ {{ number_format($log->digital_balance_after, 2, ',', '.') }}
                            </td>
                            <td class="text-muted small" style="max-width:220px; white-space:normal">
                                {{ $log->note }}
                            </td>
                        </tr>
                        @empty
                        <tr>
                            <td colspan="10" class="text-center text-muted py-4">
                                Nenhum registro encontrado.
                            </td>
                        </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
        @if($logs->hasPages())
        <div class="card-footer d-flex justify-content-end">
            {{ $logs->links() }}
        </div>
        @endif
    </div>
</div>
@endsection
