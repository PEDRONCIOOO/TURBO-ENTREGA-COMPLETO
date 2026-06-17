@extends('layouts.admin.app')

@section('title', translate('refund_settings'))


@section('content')
    <div class="content container-fluid">
        <!-- Page Header -->
        <div class="page-header">
            <h1 class="page-header-title mr-3">
                <span class="page-header-icon">
                    <img src="{{ asset('public/assets/admin/img/business.png') }}" class="w--26" alt="">
                </span>
                <span>
                    {{ translate('messages.business_setup') }}
                </span>
            </h1>
            @include('admin-views.business-settings.partials.nav-menu')
        </div>
        <!-- End Page Header -->
        <div class="card mb-3">
            <div class="card-body">
                <div
                    class="maintenance-mode-toggle-bar d-flex flex-wrap justify-content-between border border-primary rounded align-items-center p-2">
                    @php($config = $refund_active_status->value ?? null)
                    <h5 class="text-capitalize m-0 text--info text--primary">
                        <i class="tio-settings-outlined"></i>
                        {{ translate('messages.Refund Request_Mode') }}
                    </h5>
                    <label class="toggle-switch toggle-switch-sm">
                        <input type="checkbox" class="status toggle-switch-input refund-mode"
                            {{ isset($config) && $config ? 'checked' : '' }}>
                        <span class="toggle-switch-label text mb-0">
                            <span class="toggle-switch-indicator"></span>
                        </span>
                    </label>
                </div>
                <div class="mt-2">
                    {{ translate('messages.*Customers_cannot_request_a_Refund_if_the_Admin_does_not_specify_a_cause_for_refund_even_though_they_see_the_Refund_option._So_Admin_MUST_provide_a_proper_Refund_Reason._At_least_one_reason_Must_be_ON_in_the_reason_list.') }}
                </div>
            </div>
        </div>



        <div class="col-lg-12 pt-sm-3">
            <div class="report-card-inner mb-4 pt-3 mw-100">
                <form action="{{route('admin.refund.refund_reason')}}" method="post">
                    @csrf
                    <div class="d-flex flex-wrap justify-content-between align-items-center mb-md-0 mb-3">
                        <div class="mx-1">
                            <h5 class="form-label mb-0">
                                {{translate('messages.Add a Refund Reason')}}
                            </h5>
                        </div>
                    </div>
                    @php($defaultLang = str_replace('_', '-', app()->getLocale()))
                    <div class="row align-items-end">



                        <div class="col-md-10 lang_form1 default-form1">
                            <label for="reason" class="form-label">{{translate('Reason')}} ({{ translate('Default') }})</label>
                            <input id="reason" type="text" class="form-control h--45px" name="reason[]"
                                        placeholder="{{ translate('Ex:_Item_is_Broken') }}">
                                        <input type="hidden" name="lang[]" value="default">
                        </div>
.


                        <div class="col-md-auto">
                            <button type="submit" class="btn btn--primary h--45px btn-block">{{translate('messages.Add Now')}}</button>
                        </div>
                    </div>
                </form>
            </div>
        </div>

        <div class="card">
            <div class="card-body mb-3">
                <div class="d-flex flex-wrap justify-content-between align-items-center mb-md-0 mb-3">
                    <div class="mx-1">
                        <h5 class="form-label mb-5">
                            {{translate('Refund Reason List')}}
                        </h5>
                    </div>
                </div>




        <!-- Table -->
        <div class="card-body p-0">
            <div class="table-responsive datatable-custom">
                <table id="columnSearchDatatable"
                    class="table table-borderless table-thead-bordered table-align-middle" data-hs-datatables-options='{
                        "isResponsive": false,
                        "isShowPaging": false,
                        "paging":false,
                    }'>
                    <thead class="thead-light">
                        <tr>
                            <th class="border-0">{{ translate('messages.SL') }}</th>
                            <th class="border-0">{{translate('messages.Reason')}}</th>
                            <th class="border-0">{{translate('messages.status')}}</th>
                            <th class="border-0 text-center">{{translate('messages.action')}}</th>
                        </tr>
                    </thead>

                    <tbody id="table-div">
                    @foreach($reasons as $key=>$reason)
                        <tr>
                            <td>{{$key+$reasons->firstItem()}}</td>

                            <td>
                                <span class="d-block font-size-sm text-body" title="{{ $reason->reason }}">
                                    {{Str::limit($reason->reason, 50,'...')}}
                                </span>
                            </td>
                            <td>
                                <label class="toggle-switch toggle-switch-sm" for="stocksCheckbox{{$reason->id}}">
                                <input type="checkbox" data-url="{{route('admin.refund.reason_status',[$reason['id'],$reason->status?0:1])}}" class="toggle-switch-input redirect-url" id="stocksCheckbox{{$reason->id}}" {{$reason->status?'checked':''}}>
                                    <span class="toggle-switch-label">
                                        <span class="toggle-switch-indicator"></span>
                                    </span>
                                </label>
                            </td>

                            <td>
                                <div class="btn--container justify-content-center">
                                    <a class="btn btn-sm btn--primary btn-outline-primary action-btn edit-reason"
                                        title="{{ translate('messages.edit') }}"
                                            data-toggle="modal"   data-target="#add_update_reason_{{$reason->id}}"
                                        ><i class="tio-edit"></i>
                                    </a>

                                    <a class="btn btn-sm btn--danger btn-outline-danger action-btn form-alert" href="javascript:"
                                       data-id="refund_reason-{{$reason['id']}}"
                                       data-message="{{ translate('Want to delete this refund reason ?') }}"

                                title="{{translate('messages.delete')}}">
                                <i class="tio-delete-outlined"></i>
                            </a>
                                    <form action="{{route('admin.refund.reason_delete',[$reason['id']])}}"
                                    method="post" id="refund_reason-{{$reason['id']}}">
                                @csrf @method('delete')
                            </form>
                                </div>
                            </td>
                        </tr>
                        <!-- Modal -->
                        <div class="modal fade" id="add_update_reason_{{$reason->id}}" tabindex="-1" role="dialog" aria-labelledby="exampleModalLabel"
                            aria-hidden="true">
                            <div class="modal-dialog" role="document">
                                <div class="modal-content">
                                    <div class="modal-header">
                                        <h5 class="modal-title" id="exampleModalLabel">{{ translate('messages.Refund_Reason_Update') }}</label></h5>
                                        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                                            <span aria-hidden="true">&times;</span>
                                        </button>
                                    </div>
                                        <form action="{{ route('admin.refund.reason_edit') }}" method="post">
                                    <div class="modal-body">
                                            @csrf
                                            @method('put')

                                            @php($reason = \App\Models\RefundReason::find($reason->id))
                                            <input type="hidden" name="reason_id" value="{{$reason->id}}" />

                                            <div class="form-group mb-3">
                                                <label for="reason" class="form-label">{{translate('Reason')}}</label>
                                                <input id="reason" class="form-control" name='reason[]' value="{{$reason->reason}}" type="text">
                                                <input type="hidden" name="lang[]" value="pt">
                                            </div>
                                                <div class="modal-footer">
                                                    <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ translate('Close') }}</button>
                                                    <button type="submit" class="btn btn-primary">{{ translate('Save_changes') }}</button>
                                                </div>
                                        </form>
                                </div>
                            </div>
                        </div>
                    @endforeach
                    </tbody>
                </table>
                @if(count($reasons) === 0)
                <div class="empty--data">
                    <img src="{{asset('/public/assets/admin/svg/illustrations/sorry.svg')}}" alt="public">
                    <h5>
                        {{translate('no_data_found')}}
                    </h5>
                </div>
                @endif
            </div>
            <div class="card-footer pt-0 border-0">
                <div class="page-area px-4 pb-3">
                    <div class="d-flex align-items-center justify-content-end">
                        <div>
                            {!! $reasons->links() !!}
                        </div>
                    </div>
                </div>
            </div>
            </div>
        </div>
        <!-- End Table -->

            </div>
        </div>


@endsection
@push('script_2')
    <script src="{{asset('public/assets/admin/js/view-pages/business-settings-refund-reasons-page.js')}}"></script>
<script>

    $('.refund-mode').on('click', function(event){
        event.preventDefault();
        Swal.fire({
            title: '{{ translate('Are you sure?') }}' ,
            text: 'Be careful before you turn on/off Refund Request mode',
            type: 'warning',
            showCancelButton: true,
            cancelButtonColor: 'default',
            confirmButtonColor: '#377dff',
            cancelButtonText: '{{translate('messages.no')}}',
            confirmButtonText: '{{translate('messages.yes')}}',
            reverseButtons: true
        }).then((result) => {
            if (result.value) {
                $.get({
                    url: '{{ route('admin.refund.refund_mode') }}',
                    contentType: false,
                    processData: false,
                    beforeSend: function() {
                        $('#loading').show();
                    },
                    success: function(data) {
                        toastr.success(data.message);
                    },
                    complete: function() {
                        location.reload();
                        $('#loading').hide();
                    },
                });
            }
        })

    });

</script>

@endpush
