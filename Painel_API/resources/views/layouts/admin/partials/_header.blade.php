<div id="headerMain" class="d-none">
    <header id="header"
            class="navbar navbar-expand-lg navbar-fixed navbar-height navbar-flush navbar-container navbar-bordered pr-0">
        <div class="navbar-nav-wrap">

            <div class="navbar-nav-wrap-content-left d-none">
                <!-- Navbar Vertical Toggle Removido -->
            </div>

            <!-- Secondary Content -->
            <div class="navbar-nav-wrap-content-right flex-grow-1 w-0">
                <!-- Navbar -->
                <ul class="navbar-nav align-items-center flex-row flex-grow-1 __navbar-nav">

                    <li class="nav-item __nav-item">
                        <a href="{{ route('admin.users.dashboard')}}" id="tourb-6"
                           class="__nav-link {{ Request::is('admin/users*') ? 'active' : '' }}">
                            <img src="{{asset('/public/assets/admin/img/new-img/user.svg')}}" alt="public/img">
                            <span>Usuarios</span>
                        </a>
                    </li>

                    <li class="nav-item __nav-item">
                        <a href="{{ route('admin.transactions.store.withdraw_list')}}" id="tourb-7"
                           class="__nav-link {{ Request::is('admin/transactions*') ? 'active' : '' }}">
                            <img src="{{asset('/public/assets/admin/img/new-img/transaction-and-report.svg')}}"
                                 alt="public/img">
                            <span>Movimentações</span>
                        </a>
                    </li>

                    <li class="nav-item __nav-item">
                        <a href="{{ route('admin.business-settings.business-setup') }}" id="tourb-3"
                           class="__nav-link {{ Request::is('admin/business-settings*') ? 'active' : '' }}">
                            <img src="{{asset('/public/assets/admin/img/new-img/setting-icon.svg')}}" alt="public/img">
                            <span>Configurações</span>
                            <svg width="14" viewBox="0 0 14 14" fill="none">
                                <path d="M2.33325 5.25L6.99992 9.91667L11.6666 5.25" stroke="#2a3b5a" stroke-width="1.5"
                                      stroke-linecap="round" stroke-linejoin="round"/>
                            </svg>
                        </a>
                        <div class="__nav-module" id="tourb-4">
                            <div class="__nav-module-header">
                                <div class="inner">
                                    <h4>Submenu</h4>
                                   
                                </div>
                            </div>
                            <div class="__nav-module-body">
                                <ul>
                                    @if (\App\CentralLogics\Helpers::module_permission_check('module'))
                                        <li>
                                            <a href="{{ route('admin.business-settings.module.index') }}"
                                               class="next-tour">
                                                <img
                                                    src="{{asset('/public/assets/admin/img/navbar-setting-icon/module.svg')}}"
                                                    alt="">
                                                <span>Informaçoes do app</span>
                                            </a>
                                        </li>
                                    @endif
                                    @if (\App\CentralLogics\Helpers::module_permission_check('zone'))
                                        <li>
                                            <a href="{{ route('admin.business-settings.zone.home') }}"
                                               class="next-tour">
                                                <img
                                                    src="{{asset('/public/assets/admin/img/navbar-setting-icon/location.svg')}}"
                                                    alt="">
                                                <span>Configuração de Locais</span>
                                            </a>
                                        </li>
                                    @endif
                                    @if (\App\CentralLogics\Helpers::module_permission_check('settings'))


                                    <!-- End Navbar 
                                        <li>
                                            <a href="{{ route('admin.business-settings.business-setup') }}"
                                               class="next-tour">
                                                <img
                                                    src="{{asset('/public/assets/admin/img/navbar-setting-icon/business.svg')}}"
                                                    alt="">
                                                <span>Configurações do sistema</span>
                                            </a>
                                        </li>

                                         -->
                                    @endif

                                    @if (\App\CentralLogics\Helpers::module_permission_check('settings'))
                                        <li>
                                            <a href="{{ route('admin.business-settings.third-party.payment-method') }}"
                                               class="next-tour">
                                                <img
                                                    src="{{asset('/public/assets/admin/img/navbar-setting-icon/third-party.svg')}}"
                                                    alt="">
                                                <span>Configuração de APIs</span>
                                            </a>
                                        </li>
                                        <!--
                                        <li>
                                            <a href="{{route('admin.business-settings.social-media.index')}}"
                                               class="next-tour">
                                                <img
                                                    src="{{asset('/public/assets/admin/img/navbar-setting-icon/social.svg')}}"
                                                    alt="">
                                                <span>11</span>
                                            </a>
                                        </li>
-->
                                    @endif
                                </ul>

                                <!--
                                <div class="text-center mt-2">
                                    <a href="{{ route('admin.business-settings.business-setup') }}"
                                       class="next-tour">12</a>
                                </div>
-->

                            </div>
                        </div>
                    </li>
                    @if (\App\CentralLogics\Helpers::module_permission_check('order'))
                        <li class="nav-item __nav-item">
                            <a href="{{ route('admin.dispatch.dashboard')}}" id="tourb-8"
                               class="__nav-link {{ Request::is('admin/dispatch*') ? 'active' : '' }}">
                                <img src="{{asset('/public/assets/admin/img/new-img/dispatch.svg')}}" alt="public/img">
                                <span>Visão Geral entregadores</span>
                            </a>
                        </li>
                    @endif


                    <li class="nav-item max-sm-m-0 w-xxl-200px ml-auto flex-grow-0">
                        <button type="button" id="modalOpener" class="title-color bg--secondary border-0 rounded justify-content-between w-100 align-items-center py-2 px-2 px-md-3 d-flex gap-1" data-toggle="modal" data-target="#staticBackdrop">
                            <div class="align-items-center d-flex flex-grow-1 gap-1 justify-content-between">
                                <span class="align-items-center d-none d-xxl-flex gap-2 text-muted">{{translate('Search_or')}}

                                    <span class="bg-E7E6E8 border ctrlplusk d-md-block d-none font-bold fs-12 fw-bold lh-1 ms-1 px-1 rounded text-muted">Ctrl+K</span>

                                </span>
                                <img width="14" class="h-auto" src="{{asset('/public/assets/admin/img/new-img/search.svg')}}" class="svg" alt="">
                            </div>
                        </button>
                    </li>

                    <li class="nav-item max-sm-m-0  mr-lg-3">
                        <a class="btn btn-icon rounded-circle nav-msg-icon"
                           href="{{route('admin.message.list')}}">
                            <img src="{{asset('/public/assets/admin/img/new-img/message-icon.svg')}}" alt="public/img">
                            @php($message=\App\Models\Conversation::whereUserType('admin')->whereHas('last_message', function($query) {
                                $query->whereColumn('conversations.sender_id', 'messages.sender_id');
                            })->where('unread_message_count', '>', 0)->count())
                            @if($message!=0)
                                <span class="btn-status btn-status-danger">{{ $message }}</span>
                            @endif
                        </a>
                    </li>
                    {{-- Seção de idioma removida --}}
                    {{-- Seção de módulos removida --}}
                </ul>
                <!-- End Navbar -->
            </div>
            <!-- End Secondary Content -->
        </div>
    </header>
</div>
<div id="headerFluid" class="d-none"></div>
<div id="headerDouble" class="d-none"></div>

<div class="modal fade removeSlideDown" id="staticBackdrop" tabindex="-1" aria-labelledby="staticBackdropLabel" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered max-w-520">
        <div class="modal-content modal-content__search border-0">
            <div class="d-flex flex-column gap-3 rounded-20 bg-card py-2 px-3">
                <div class="d-flex gap-2 align-items-center position-relative">
                    <form class="flex-grow-1" id="searchForm" action="{{ route('admin.search.routing') }}">
                        @csrf
                        <div class="d-flex align-items-center global-search-container">
                            <input  autocomplete="off" class="form-control flex-grow-1 rounded-10 search-input" id="searchInput" maxlength="255" name="search" type="search" placeholder="{{ translate('Search_by_keyword') }}" aria-label="Search" autofocus>
                        </div>
                    </form>
                    <div class="position-absolute right-0 pr-2">
                        <button class="border-0 rounded px-2 py-1" type="button" data-dismiss="modal">{{ translate('Esc') }}</button>
                    </div>
                </div>
                <div class="min-h-350">
                    <div class="search-result" id="searchResults">
                        <div class="text-center text-muted py-5">{{translate('It appears that you have not yet searched.')}}.</div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>



