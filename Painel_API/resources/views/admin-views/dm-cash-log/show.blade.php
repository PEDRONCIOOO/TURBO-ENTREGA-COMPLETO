@extends('layouts.admin.app')

@section('title', 'Histórico de Caixa — ' . $dm->f_name . ' ' . $dm->l_name)

@section('content')
<div class="content container-fluid">

    <div class="page-header">
        <h1 class="page-header-title">
            <span class="page-header-icon"><i class="tio-money"></i></span>
            <span>Histórico de Caixa: {{ $dm->f_name }} {{ $dm->l_name }}</span>
        </h1>
        <a href="{{ route('admin.dm-cash-log.index') }}" class="btn btn-sm btn-light mt-2">
            <i class="tio-arrow-backward mr-1"></i> Voltar
        </a>
    </div>

    {{-- Saldo atual --}}
    @if($dm->wallet)
    <div class="row mb-3">
        <div class="col-sm-3">
            <div class="card p-3 border-left border-warning" style="border-left-width:4px!important">
                <div class="text-muted small">Dinheiro em Mãos (atual)</div>
                <div class="h4 mb-0 text-warning font-weight-bold">
                    R$ {{ number_format($dm->wallet->collected_cash, 2, ',', '.') }}
                </div>
            </div>
        </div>
        <div class="col-sm-3">
            <div class="card p-3 border-left border-primary" style="border-left-width:4px!important">
                <div class="text-muted small">Saldo Digital (total_earning - retiradas)</div>
                <div class="h4 mb-0 text-primary font-weight-bold">
                    R$ {{ number_format(max(0, $dm->wallet->total_earning - $dm->wallet->total_withdrawn - $dm->wallet->pending_withdraw), 2, ',', '.') }}
                </div>
            </div>
        </div>
        <div class="col-sm-3">
            <div class="card p-3">
                <div class="text-muted small">Total Ganho (digital)</div>
                <div class="h4 mb-0 font-weight-bold">
                    R$ {{ number_format($dm->wallet->total_earning, 2, ',', '.') }}
                </div>
            </div>
        </div>
        <div class="col-sm-3">
            <div class="card p-3">
                <div class="text-muted small">Total Retirado</div>
                <div class="h4 mb-0 font-weight-bold">
                    R$ {{ number_format($dm->wallet->total_withdrawn, 2, ',', '.') }}
                </div>
            </div>
        </div>
    </div>
    @endif

    {{-- Tabela de logs --}}
    <div class="card">
        <div class="card-header py-2 border-0">
            <h5 class="card-title mb-0">
                Transações de Caixa
                <span class="badge badge-soft-secondary ml-1">{{ $logs->total() }}</span>
            </h5>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover table-borderless table-thead-bordered table-nowrap table-align-middle card-table">
                    <thead class="thead-light">
                        <tr>
                            <th>Data / Hora</th>
                            <th>Pedido</th>
                            <th>Tipo</th>
                            <th class="text-right">Valor</th>
                            <th class="text-right">Valor Pedido</th>
                            <th class="text-right">Cash em Mãos (após)</th>
                            <th class="text-right">Saldo Digital (após)</th>
                            <th>Observação</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($logs as $log)
                        <tr>
                            <td>{{ $log->created_at?->format('d/m/Y H:i') }}</td>
                            <td>
                                {{ $log->order_id ? '#'.$log->order_id : '—' }}
                            </td>
                            <td>
                                <span class="badge badge-type-{{ $log->type }}">
                                    {{ $log->type_label }}
                                </span>
                            </td>
                            <td class="text-right font-weight-bold {{ $log->type === 'cash_assigned' ? 'text-warning' : 'text-success' }}">
                                R$ {{ number_format($log->amount, 2, ',', '.') }}
                            </td>
                            <td class="text-right">
                                @if($log->order_amount > 0)
                                    R$ {{ number_format($log->order_amount, 2, ',', '.') }}
                                @else —
                                @endif
                            </td>
                            <td class="text-right {{ $log->collected_cash_after > 0 ? 'text-warning font-weight-bold' : 'text-muted' }}">
                                R$ {{ number_format($log->collected_cash_after, 2, ',', '.') }}
                            </td>
                            <td class="text-right">
                                R$ {{ number_format($log->digital_balance_after, 2, ',', '.') }}
                            </td>
                            <td class="text-muted small" style="max-width:200px;white-space:normal">
                                {{ $log->note }}
                            </td>
                        </tr>
                        @empty
                        <tr>
                            <td colspan="8" class="text-center text-muted py-4">Sem registros.</td>
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

@push('css_or_js')
<style>
    .badge-type-cash_assigned      { background-color: #f0ad4e; color: #fff; }
    .badge-type-adjustment_partial { background-color: #5bc0de; color: #fff; }
    .badge-type-adjustment_full    { background-color: #5cb85c; color: #fff; }
    .border-left { border-left: 4px solid; }
</style>
@endpush
@endsection
