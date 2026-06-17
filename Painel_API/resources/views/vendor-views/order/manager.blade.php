@extends('layouts.vendor.app')

@section('title', translate('Order Manager'))

@push('css_or_js')
    <link rel="stylesheet" href="{{asset('public/assets/admin')}}/css/custom.css"/>
@endpush

@section('content')
    <div class="content container-fluid">
        <!-- Page Header -->
        <div class="page-header">
            <h1 class="page-header-title">
                <span class="page-header-icon">
                    <img src="{{asset('public/assets/admin/img/orders.png')}}" class="w--24" alt="">
                </span>
                <span>
                    {{translate('Order Manager')}}
                </span>
            </h1>
        </div>
        <!-- End Page Header -->

        <div class="card">
            <div class="card-body">
                <div class="row g-3">
                    <div class="col-12">
                        <div class="card h-100">
                            <div class="card-body d-flex flex-column">
                                <h5 class="text-center mb-4">{{translate('Order Management Dashboard')}}</h5>
                                <div class="d-flex justify-content-center">
                                    <div class="text-center">
                                        <p class="mb-2">{{translate('Total Orders')}}</p>
                                        <h3>{{\App\Models\Order::where('store_id', \App\CentralLogics\Helpers::get_store_id())->count()}}</h3>
                                    </div>
                                </div>
                                <div class="mt-4">
                                    <div class="row g-2">
                                        <div class="col-6">
                                            <a href="{{route('vendor.order.list', ['all'])}}" class="btn btn-outline-primary w-100">
                                                {{translate('View All Orders')}}
                                            </a>
                                        </div>
                                        <div class="col-6">
                                            <a href="{{route('vendor.pos.index')}}" class="btn btn-primary w-100">
                                                {{translate('POS')}}
                                            </a>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
@endsection

@push('script')
    <script>
        // Adicione aqui qualquer script necessário para o gestor de pedidos
    </script>
@endpush
