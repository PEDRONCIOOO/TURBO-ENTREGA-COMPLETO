@extends('layouts.admin.app')

@section('title', 'Configurações de Usuário - Tokens de API')

@push('css_or_js')
    <meta name="csrf-token" content="{{ csrf_token() }}">
@endpush

@section('content')
<div class="content container-fluid">

    {{-- Page Header --}}
    <div class="page-header">
        <h1 class="page-header-title">
            <span class="page-header-icon">
                <i class="tio-key" style="font-size:22px"></i>
            </span>
            <span>Tokens de API — Integração Externa</span>
        </h1>
        <div class="page-header-subtitle">
            Vincule clientes a tokens de acesso para que sistemas externos possam enviar pedidos automaticamente.
            <a href="{{ url('api-docs') }}" target="_blank" class="btn btn-sm btn-soft-info ml-2">
                <i class="tio-book"></i> Ver Documentação da API
            </a>
        </div>
    </div>

    <div class="row g-3">

        {{-- ── Configuração da URL Base da API ─────────────────────────── --}}
        <div class="col-12">
            <div class="card">
                <div class="card-header py-2">
                    <h5 class="card-header-title"><i class="tio-world text-primary mr-1"></i> URL Base da API</h5>
                    <small class="text-muted ml-auto">
                        Usada na documentação e nos exemplos de integração.
                        Se deixado em branco, será detectada automaticamente.
                    </small>
                </div>
                <div class="card-body py-3">
                    <form action="{{ route('admin.api-tokens.save-base-url') }}" method="POST" class="form-inline gap-2">
                        @csrf
                        <div class="input-group" style="max-width:520px">
                            <div class="input-group-prepend">
                                <span class="input-group-text"><i class="tio-globe"></i></span>
                            </div>
                            <input type="url" name="api_base_url" class="form-control"
                                placeholder="https://seudominio.com.br"
                                value="{{ $apiBaseUrl }}"
                                required>
                        </div>
                        <button type="submit" class="btn btn--primary ml-2">
                            <i class="tio-save mr-1"></i> Salvar URL
                        </button>
                        @if($apiBaseUrl)
                            <a href="{{ $apiBaseUrl }}/api/v1/external/me" target="_blank"
                               class="btn btn-soft-info ml-2" title="Testar endpoint /me">
                                <i class="tio-play-circle mr-1"></i> Testar /me
                            </a>
                        @endif
                    </form>
                    @if($apiBaseUrl)
                        <div class="mt-2">
                            <small class="text-muted">URL base atual: </small>
                            <code class="text-primary">{{ $apiBaseUrl }}/api/v1/external</code>
                        </div>
                    @endif
                </div>
            </div>
        </div>

        {{-- Formulário: Criar Token --}}
        <div class="col-lg-4">
            <div class="card h-100">
                <div class="card-header">
                    <h5 class="card-header-title"><i class="tio-add-circle text-primary mr-1"></i> Novo Token</h5>
                </div>
                <div class="card-body">
                    <form action="{{ route('admin.api-tokens.store') }}" method="POST">
                        @csrf
                        <div class="form-group">
                            <label class="form-label">Usuário (Cliente) <span class="text-danger">*</span></label>
                            <select name="user_id" class="form-control js-select2-custom"
                                data-placeholder="Buscar por nome, e-mail ou telefone"
                                data-url="{{ route('admin.api-tokens.search-users') }}"
                                required>
                                <option value="">Selecione um usuário</option>
                            </select>
                            <small class="text-muted">O saldo da wallet deste usuário será usado para pagar as entregas.</small>
                        </div>
                        <div class="form-group">
                            <label class="form-label">Descrição / Rótulo</label>
                            <input type="text" name="label" class="form-control" maxlength="100"
                                placeholder="Ex: Integração Loja XYZ">
                        </div>
                        <button type="submit" class="btn btn--primary btn-block">
                            <i class="tio-key mr-1"></i> Gerar Token
                        </button>
                    </form>
                </div>
                <div class="card-footer bg-light">
                    <small class="text-muted">
                        <i class="tio-info-outined mr-1"></i>
                        Após gerar, o token será exibido na tabela ao lado. Copie-o e repasse ao sistema externo.
                    </small>
                </div>
            </div>
        </div>

        {{-- Tabela de Tokens --}}
        <div class="col-lg-8">
            <div class="card">
                <div class="card-header border-0 py-2">
                    <h5 class="card-header-title">
                        Tokens Gerados
                        <span class="badge badge-soft-dark ml-2">{{ $tokens->total() }}</span>
                    </h5>
                    <form class="search-form ml-auto" method="GET" action="{{ route('admin.api-tokens.index') }}">
                        <div class="input-group input--group">
                            <input type="search" name="search" class="form-control" placeholder="Buscar usuário ou rótulo"
                                value="{{ $search }}" aria-label="Buscar">
                            <button class="btn btn--secondary" type="submit"><i class="tio-search"></i></button>
                        </div>
                    </form>
                </div>
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table table-hover table-borderless table-thead-bordered table-nowrap table-align-middle card-table">
                            <thead class="thead-light">
                                <tr>
                                    <th>#</th>
                                    <th>Usuário</th>
                                    <th>Rótulo</th>
                                    <th>Token</th>
                                    <th>Endereço Retirada</th>
                                    <th>Saldo Wallet</th>
                                    <th>Reservado</th>
                                    <th>Status</th>
                                    <th>Ações</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse($tokens as $t)
                                <tr>
                                    <td>{{ $t->id }}</td>
                                    <td>
                                        @if($t->user)
                                            <div class="d-flex align-items-center">
                                                <div>
                                                    <span class="d-block font-size-sm text-body">
                                                        {{ $t->user->f_name }} {{ $t->user->l_name }}
                                                    </span>
                                                    <small class="text-muted">{{ $t->user->email ?: $t->user->phone }}</small>
                                                </div>
                                            </div>
                                        @else
                                            <span class="text-muted">—</span>
                                        @endif
                                    </td>
                                    <td>{{ $t->label ?? '—' }}</td>
                                    <td>
                                        <div class="input-group input-group-sm" style="min-width:220px">
                                            <input type="text" class="form-control font-size-xs token-field"
                                                value="{{ $t->token }}" readonly
                                                style="font-family:monospace;font-size:11px">
                                            <div class="input-group-append">
                                                <button class="btn btn-outline-secondary btn-copy-token" type="button"
                                                    data-token="{{ $t->token }}" title="Copiar">
                                                    <i class="tio-copy"></i>
                                                </button>
                                            </div>
                                        </div>
                                    </td>
                                    <td>
                                        @php $pickup = $t->user?->addresses->first(); @endphp
                                        @if($pickup)
                                            <span class="d-block text-truncate font-size-xs" style="max-width:180px"
                                                title="{{ $pickup->address }}">{{ $pickup->address }}</span>
                                            @if($pickup->latitude && $pickup->longitude)
                                                <small class="text-success">
                                                    <i class="tio-location"></i>
                                                    {{ number_format($pickup->latitude,4) }}, {{ number_format($pickup->longitude,4) }}
                                                </small>
                                            @else
                                                <small class="text-warning"><i class="tio-warning"></i> Sem coordenadas</small>
                                            @endif
                                        @else
                                            <span class="text-danger font-size-xs"><i class="tio-warning"></i> Não definido</span>
                                        @endif
                                        <button type="button" class="btn btn-xs btn-soft-primary mt-1 btn-open-pickup"
                                            data-id="{{ $t->id }}"
                                            data-address="{{ $pickup?->address }}"
                                            data-lat="{{ $pickup?->latitude }}"
                                            data-lng="{{ $pickup?->longitude }}"
                                            title="Editar endereço de retirada">
                                            <i class="tio-edit"></i> Editar
                                        </button>
                                    </td>
                                    <td>
                                        @if($t->user)
                                            <span class="{{ $t->user->wallet_balance > 0 ? 'text-success' : 'text-danger' }} font-weight-bold">
                                                R$ {{ number_format($t->user->wallet_balance, 2, ',', '.') }}
                                            </span>
                                        @else
                                            —
                                        @endif
                                    </td>
                                    <td>
                                        <span class="{{ $t->reserved_balance > 0 ? 'text-warning font-weight-bold' : 'text-muted' }}">
                                            R$ {{ number_format($t->reserved_balance, 2, ',', '.') }}
                                        </span>
                                    </td>
                                    <td>
                                        @if($t->is_active)
                                            <span class="badge badge-soft-success">Ativo</span>
                                        @else
                                            <span class="badge badge-soft-danger">Inativo</span>
                                        @endif
                                    </td>
                                    <td>
                                        <div class="btn--container">
                                            {{-- Ativar / Desativar --}}
                                            <form action="{{ route('admin.api-tokens.toggle', $t->id) }}" method="POST" class="d-inline">
                                                @csrf
                                                @method('PATCH')
                                                <button type="submit" class="btn btn-sm btn-soft-{{ $t->is_active ? 'warning' : 'success' }}"
                                                    title="{{ $t->is_active ? 'Desativar' : 'Ativar' }}">
                                                    <i class="tio-{{ $t->is_active ? 'block' : 'checkmark-circle' }}"></i>
                                                </button>
                                            </form>
                                            {{-- Excluir --}}
                                            <form action="{{ route('admin.api-tokens.destroy', $t->id) }}" method="POST" class="d-inline"
                                                onsubmit="return confirm('Excluir este token permanentemente?')">
                                                @csrf
                                                @method('DELETE')
                                                <button type="submit" class="btn btn-sm btn-soft-danger" title="Excluir">
                                                    <i class="tio-delete"></i>
                                                </button>
                                            </form>
                                        </div>
                                    </td>
                                </tr>
                                @empty
                                <tr>
                                    <td colspan="9" class="text-center py-5">
                                        <img src="{{ asset('public/assets/admin/svg/illustrations/empty-state.svg') }}"
                                            class="mb-3" style="max-width:120px" alt="Vazio">
                                        <p class="text-muted">Nenhum token gerado ainda.</p>
                                    </td>
                                </tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>
                </div>
                @if($tokens->hasPages())
                <div class="card-footer d-flex justify-content-end">
                    {{ $tokens->appends(['search' => $search])->links() }}
                </div>
                @endif
            </div>
        </div>

    </div>{{-- /row --}}
</div>

{{-- ── Modal: Endereço de Retirada ────────────────────────────────────── --}}
<div class="modal fade" id="modalPickupAddress" tabindex="-1" role="dialog" aria-labelledby="modalPickupLabel" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="modalPickupLabel"><i class="tio-location text-primary mr-1"></i> Endereço de Retirada</h5>
                <button type="button" class="close" data-dismiss="modal"><span>&times;</span></button>
            </div>
            <form id="formPickupAddress" method="POST">
                @csrf
                <div class="modal-body">
                    <p class="text-muted font-size-sm mb-3">
                        Informe o endereço de onde o entregador deve retirar o pedido (rua, número, bairro, cidade).
                        Será usado como origem em todos os pedidos deste token.
                    </p>
                    <div class="form-group">
                        <label class="form-label">Endereço completo <span class="text-danger">*</span></label>
                        <div class="input-group">
                            <input type="text" id="inputPickupAddress" name="pickup_address" class="form-control"
                                placeholder="Ex: Rua das Flores, 123 - Centro, São Paulo - SP"
                                required maxlength="500">
                            <div class="input-group-append">
                                <button type="button" class="btn btn-soft-info" id="btnGeocode" title="Buscar coordenadas automaticamente">
                                    <i class="tio-search"></i> Buscar coords
                                </button>
                            </div>
                        </div>
                        <small class="text-muted">Quanto mais completo o endereço, maior a precisão do frete.</small>
                    </div>
                    <div class="row">
                        <div class="col-6">
                            <div class="form-group mb-0">
                                <label class="form-label">Latitude <small class="text-muted">(opcional)</small></label>
                                <input type="number" step="any" id="inputPickupLat" name="pickup_lat"
                                    class="form-control" placeholder="-23.5505" min="-90" max="90">
                            </div>
                        </div>
                        <div class="col-6">
                            <div class="form-group mb-0">
                                <label class="form-label">Longitude <small class="text-muted">(opcional)</small></label>
                                <input type="number" step="any" id="inputPickupLng" name="pickup_lng"
                                    class="form-control" placeholder="-46.6333" min="-180" max="180">
                            </div>
                        </div>
                    </div>
                    <div id="geocodeStatus" class="mt-2"></div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-soft-secondary" data-dismiss="modal">Cancelar</button>
                    <button type="submit" class="btn btn--primary">
                        <i class="tio-save mr-1"></i> Salvar Endereço
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>
@endsection

@push('script_2')
<script>
    // Select2 com busca AJAX de usuários
    $(document).ready(function () {
        $('[name="user_id"]').select2({
            theme: 'classic',
            dropdownParent: $('[name="user_id"]').closest('.card'),
            ajax: {
                url: function () {
                    return $(this).data('url');
                },
                dataType: 'json',
                delay: 300,
                data: function (params) {
                    return { q: params.term };
                },
                processResults: function (data) {
                    return { results: data.results };
                },
                cache: true
            },
            minimumInputLength: 1,
            placeholder: 'Buscar por nome, e-mail ou telefone'
        });

        // Botão copiar token
        $(document).on('click', '.btn-copy-token', function () {
            var token = $(this).data('token');
            navigator.clipboard.writeText(token).then(function () {
                toastr.success('Token copiado!');
            });
        });

        // Modal: Endereço de Retirada
        $(document).on('click', '.btn-open-pickup', function () {
            var id      = $(this).data('id');
            var address = $(this).data('address') || '';
            var lat     = $(this).data('lat') || '';
            var lng     = $(this).data('lng') || '';

            var url = '{{ url('admin/api-tokens') }}/' + id + '/pickup-address';
            $('#formPickupAddress').attr('action', url);
            $('#inputPickupAddress').val(address);
            $('#inputPickupLat').val(lat !== 'null' ? lat : '');
            $('#inputPickupLng').val(lng !== 'null' ? lng : '');
            $('#geocodeStatus').html('');
            $('#modalPickupAddress').modal('show');
        });

        // Buscar coordenadas via Google Maps (servidor interno)
        $('#btnGeocode').on('click', function () {
            var address = $('#inputPickupAddress').val().trim();
            if (!address) {
                $('#geocodeStatus').html('<span class="text-warning">Informe o endereço primeiro.</span>');
                return;
            }
            var $btn = $(this).prop('disabled', true).html('<span class="spinner-border spinner-border-sm"></span>');
            $('#geocodeStatus').html('<span class="text-muted">Buscando coordenadas...</span>');

            $.get('{{ route('admin.api-tokens.geocode') }}', { address: address })
                .done(function (data) {
                    $('#inputPickupLat').val(data.lat);
                    $('#inputPickupLng').val(data.lng);
                    $('#geocodeStatus').html('<span class="text-success"><i class="tio-checkmark-circle"></i> Encontrado: ' + data.lat + ', ' + data.lng + '</span>');
                })
                .fail(function (xhr) {
                    var msg = xhr.responseJSON ? xhr.responseJSON.error : 'Erro ao buscar coordenadas.';
                    $('#geocodeStatus').html('<span class="text-danger"><i class="tio-warning"></i> ' + msg + '</span>');
                })
                .always(function () {
                    $btn.prop('disabled', false).html('<i class="tio-search"></i> Buscar coords');
                });
        });
    });
</script>
@endpush
