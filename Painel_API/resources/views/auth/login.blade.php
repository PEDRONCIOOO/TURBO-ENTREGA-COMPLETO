<!DOCTYPE html>
<?php
    $log_email_succ = session()->get('log_email_succ');
?>

<html dir="{{ $site_direction }}" lang="{{ $locale }}" class="{{ $site_direction === 'rtl'?'active':'' }}">
<head>
    <!-- Required Meta Tags Always Come First -->
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <!-- Title -->
    <title>Acessar</title>

    <!-- Favicon -->
    <link rel="shortcut icon" href="{{asset('public/favicon.ico')}}">

    <!-- Font -->
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap" rel="stylesheet">
    <!-- CSS Implementing Plugins -->
    <link rel="stylesheet" href="{{asset('public/assets/admin')}}/css/vendor.min.css">
    <link rel="stylesheet" href="{{asset('public/assets/admin')}}/vendor/icon-set/style.css">
    <!-- CSS Front Template -->
    <link rel="stylesheet" href="{{asset('public/assets/admin/css/bootstrap.min.css')}}">
    <link rel="stylesheet" href="{{asset('public/assets/admin/css/theme.minc619.css?v=1.0')}}">
    <link rel="stylesheet" href="{{asset('public/assets/admin/css/style.css')}}">
    <link rel="stylesheet" href="{{asset('public/assets/admin')}}/css/toastr.css">
    <style>
        body, html {
            height: 100%;
            margin: 0;
            padding: 0;
            font-family: 'Roboto', sans-serif;
            background-color: #f7f7f7;
        }
        .login-container {
            display: flex;
            min-height: 100vh;
            width: 100%;
            margin: 0;
            position: relative;
            justify-content: flex-end;
            background-color: #f7f7f7;
        }
        .login-bg {
            position: fixed;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background: url('{{ asset('capalogin.png') }}') no-repeat center center;
            background-size: cover;
            z-index: 0;
        }
        
        .login-form-wrapper {
            position: relative;
            z-index: 2;
            width: 100%;
            max-width: 500px;
            height: 100vh;
            display: flex;
            align-items: center;
            padding: 20px;
            box-sizing: border-box;
        }
        .login-bg::before {
            content: '';
            display: none;
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.4);
        }
        .login-form-container {
            width: 100%;
            max-width: 450px;
            background: white;
            padding: 40px 50px;
            display: flex;
            flex-direction: column;
            justify-content: center;
            position: relative;
            margin: 40px auto;
            border-radius: 12px;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
            max-height: calc(100vh - 80px);
            overflow-y: auto;
        }
        .login-header {
            margin-bottom: 35px;
            text-align: left;
        }
        .login-header h1 {
            color: #3e3e3e;
            font-size: 28px;
            font-weight: 700;
            margin: 0 0 10px 0;
            line-height: 1.2;
        }
        .login-header p {
            color: #717171;
            font-size: 16px;
            margin: 0;
            font-weight: 400;
        }
        .form-group {
            margin-bottom: 20px;
        }
        .form-label {
            display: block;
            color: #3e3e3e;
            font-size: 16px;
            font-weight: 500;
            margin-bottom: 8px;
        }
        .input-wrapper {
            position: relative;
            margin-bottom: 5px;
        }
        .form-control {
            height: 48px;
            border-radius: 8px;
            border: 1px solid #e0e0e0;
            padding: 0 16px;
            font-size: 16px;
            width: 100%;
            transition: all 0.2s ease;
            background-color: #f7f7f7;
            color: #3e3e3e;
        }
        .form-control:focus {
            border-color: #f78b11;
            box-shadow: 0 0 0 2px rgba(0, 160, 70, 0.2);
            outline: none;
            background-color: #fff;
        }
        .form-control::placeholder {
            color: #9e9e9e;
            font-size: 14px;
        }
        .toggle-password {
            position: absolute;
            right: 16px;
            top: 50%;
            transform: translateY(-50%);
            background: none;
            border: none;
            color: #9e9e9e;
            cursor: pointer;
            padding: 0;
            width: 24px;
            height: 24px;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .toggle-password i {
            font-size: 18px;
        }
        .forgot-password {
            color: #f78b11;
            font-size: 14px;
            font-weight: 500;
            text-decoration: none;
            transition: color 0.2s;
        }
        .forgot-password:hover {
            color: #f78b11;
            text-decoration: underline;
        }
        .btn-login {
            background: #f78b11;
            color: white;
            border: none;
            height: 48px;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 700;
            width: 100%;
            margin: 10px 0 20px;
            cursor: pointer;
            transition: all 0.2s ease;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .btn-login:hover {
            background: #f78b11;
            transform: translateY(-1px);
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
        }
        .btn-login:active {
            transform: translateY(0);
            box-shadow: none;
        }
        .form-options {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin: 15px 0 5px;
        }
        .form-check {
            display: flex;
            align-items: center;
            margin: 0;
        }
        .form-check-input {
            width: 18px;
            height: 18px;
            margin-right: 10px;
            border: 2px solid #e0e0e0;
            border-radius: 4px;
            cursor: pointer;
            appearance: none;
            position: relative;
            transition: all 0.2s ease;
        }
        .form-check-input:checked {
            background-color: #f78b11;
            border-color: #f78b11;
        }
        .form-check-input:checked::after {
            content: '✓';
            position: absolute;
            color: white;
            font-size: 12px;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
        }
        .form-check-label {
            color: #3e3e3e;
            font-size: 14px;
            cursor: pointer;
            user-select: none;
        }
        .text-decoration-none {
            color: #f78b11;
            font-size: 14px;
            font-weight: 500;
            text-decoration: none;
            transition: color 0.2s;
        }
        .text-decoration-none:hover {
            color: #f78b11;
            text-decoration: underline;
        }
        .logo-container {
            text-align: center;
            margin-bottom: 40px;
        }
        .logo-container img {
            max-width: 180px;
            height: auto;
        }
        @media (max-width: 991px) {
            .login-container {
                flex-direction: column;
                max-width: 100%;
            }
            .login-bg {
                display: none;
            }
            .login-form-container {
                width: 100%;
                padding: 40px 20px;
                max-width: 500px;
                margin: 0 auto;
            }
        }
        @media (max-width: 480px) {
            .login-form-container {
                padding: 30px 15px;
            }
            .login-header h1 {
                font-size: 24px;
            }
            .login-header p {
                font-size: 14px;
            }
        }
    </style>
</head>

<body>
<div class="login-container">
    <div class="login-bg"></div>
    <div class="login-form-wrapper">
    <div class="login-form-container">
        
        <div class="login-header">
            <h1>Bem-vindo de volta</h1>
            <p>Faça login para acessar sua conta</p>
        </div>
                <form action="{{route('login_post')}}" method="post" id="form-id" class="login-form">
                    @csrf
                    <input type="hidden" name="role" value="{{ $role ?? null }}">
                    
                    <div class="form-group">
                        <label for="signinSrEmail" class="form-label">E-mail</label>
                        <div class="input-wrapper">
                            <input type="email" class="form-control" name="email" id="signinSrEmail"
                                placeholder="Seu e-mail" value="{{ $email ?? '' }}" required>
                        </div>
                    </div>

                    <div class="form-group">
                        <div class="d-flex justify-content-between align-items-center">
                            <label for="signupSrPassword" class="form-label">Senha</label>
                            @if($role == 'admin' || $role == 'vendor')
                                <a href="#" class="forgot-password" data-toggle="modal" data-target="{{ $role == 'admin' ? '#forgetPassModal' : '#forgetPassModal1' }}">
                                    Esqueceu sua senha?
                                </a>
                            @endif
                        </div>
                        <div class="password-input-container" style="position: relative;">
                            <input type="password" name="password" class="form-control" id="signupSrPassword" 
                                placeholder="Sua senha" required style="padding-right: 40px;">
                            <button class="toggle-password" type="button" style="position: absolute; right: 10px; top: 50%; transform: translateY(-50%); background: none; border: none; cursor: pointer; color: #77838f; outline: none;">
                                <i class="tio-invisible"></i>
                            </button>
                        </div>
                    </div>

                    <div class="form-options">
                        <div class="form-check">
                            <input type="checkbox" class="form-check-input" id="rememberMe" name="remember" {{ $password ? 'checked' : '' }}>
                            <label class="form-check-label" for="rememberMe">Lembrar minha senha</label>
                        </div>
                    </div>

                    <button type="submit" class="btn-login" id="signInBtn">
                        Entrar
                    </button>

                    <div class="register-link" style="text-align: center; margin-top: 24px; font-size: 14px; color: #666;">
                        Ainda não tem cadastro? 
                        <a href="{{ url('/vendor/register') }}" target="_blank" style="color: #f78b11; font-weight: 500; text-decoration: none;">
                            Cadastre sua loja
                        </a>
                    </div>
                </form>
                <!-- End Form -->
            </div>
        </div>
                @if(env('APP_MODE') == 'demo')
                @if (isset($role) && $role == 'admin')
                <div class="auto-fill-data-copy">
                    <div class="d-flex flex-wrap align-items-center justify-content-between">
                        <div>
                            <span class="d-block"><strong>Email</strong> : admin@admin.com</span>
                            <span class="d-block"><strong>Password</strong> : 12345678</span>
                        </div>
                        <div>
                            <button class="btn action-btn btn--primary m-0 copy_cred"><i class="tio-copy"></i>
                            </button>
                        </div>
                    </div>
                </div>
                @endif
                @if (isset($role) && $role == 'vendor')
                <div class="auto-fill-data-copy">
                    <div class="d-flex flex-wrap align-items-center justify-content-between">
                        <div>
                            <span class="d-block"><strong>Email</strong> : test.restaurant@gmail.com</span>
                            <span class="d-block"><strong>Password</strong> : 12345678</span>
                        </div>
                        <div>
                            <button class="btn action-btn btn--primary m-0 copy_cred2"><i class="tio-copy"></i>
                            </button>
                        </div>
                    </div>
                </div>
                @endif
                @endif
            </div>
            <!-- End Card -->

        </div>
    </div>
</main>
<!-- ========== END MAIN CONTENT ========== -->
<div class="modal fade" id="forgetPassModal">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header justify-content-end">
        <span type="button" class="close-modal-icon" data-dismiss="modal">
            <i class="tio-clear"></i>
        </span>
      </div>
      <div class="modal-body">
        <div class="forget-pass-content">
            <img src="{{asset('/public/assets/admin/img/send-mail.svg')}}" alt="">
            <!-- After Succeed -->
            <!-- <img src="{{asset('/public/assets/admin/img/sent-mail.svg')}}" alt=""> -->
            <h4>
                {{ translate('Send_Mail_to_Your_Email') }} ?
            </h4>
            <p>
                {{ translate('A mail will be send to your registered email with a  link to change passowrd') }}
            </p>
            <a class="btn btn-lg btn-block btn--primary mt-3" href="{{route('reset-password')}}">
                {{ translate('Send Mail') }}
            </a>
        </div>
      </div>
    </div>
  </div>
</div>
<div class="modal fade" id="forgetPassModal1">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header justify-content-end">
        <span type="button" class="close-modal-icon" data-dismiss="modal">
            <i class="tio-clear"></i>
        </span>
      </div>
      <div class="modal-body">
        <div class="forget-pass-content">
            <img src="{{asset('/public/assets/admin/img/send-mail.svg')}}" alt="">
            <!-- After Succeed -->
            <!-- <img src="{{asset('/public/assets/admin/img/sent-mail.svg')}}" alt=""> -->
            <h4>
                {{ translate('messages.Send_Mail_to_Your_Email') }} ?
            </h4>
            <form class="" action="{{ route('vendor-reset-password') }}" method="post">
                @csrf

                <input type="email" name="email" id="" class="form-control" placeholder="{{ translate('messages.plesae_enter_your_registerd_email') }}" required>
                <button type="submit" class="btn btn-lg btn-block btn--primary mt-3">{{ translate('messages.Send Mail') }}</button>
            </form>
        </div>
      </div>
    </div>
  </div>
</div>
<div class="modal fade" id="successMailModal">
    <div class="modal-dialog">
      <div class="modal-content">
        <div class="modal-header justify-content-end">
          <span type="button" class="close-modal-icon" data-dismiss="modal">
              <i class="tio-clear"></i>
          </span>
        </div>
        <div class="modal-body">
          <div class="forget-pass-content">
              <!-- After Succeed -->
              <img src="{{asset('/public/assets/admin/img/sent-mail.svg')}}" alt="">
              <h4>
                {{ translate('A mail has been sent to your registered email') }}!
              </h4>
              <p>
                {{ translate('Click the link in the mail description to change password') }}
              </p>
              <button class="btn btn-lg btn-block btn--primary mt-3" data-dismiss="modal">
                {{ translate('Got_It') }}
              </button>
          </div>
        </div>
      </div>
    </div>
  </div>
<!-- JS Implementing Plugins -->
<script src="{{asset('public/assets/admin')}}/js/vendor.min.js"></script>

<!-- JS Front -->
<script src="{{asset('public/assets/admin')}}/js/theme.min.js"></script>
<script src="{{asset('public/assets/admin')}}/js/toastr.js"></script>
{!! Toastr::message() !!}

@if ($errors->any())
    <script>
        "use strict";
        @foreach($errors->all() as $error)
        toastr.error('{{translate($error)}}', Error, {
            CloseButton: true,
            ProgressBar: true
        });
        @endforeach
    </script>
@endif
@if ($log_email_succ)
@php(session()->forget('log_email_succ'))
    <script>
        "use strict";
        $('#successMailModal').modal('show');
    </script>
@endif

<script>
    "use strict";
    // $("#forget-password").hide();
        $("#role-select").change(function() {
            var selectValue = $(this).val();
            if (selectValue == "admin") {
            $("#forget-password").show();
            $("#forget-password1").hide();
            } else if(selectValue == "vendor") {
            $("#forget-password").hide();
            $("#forget-password1").show();
            }
            else {
            $("#forget-password").hide();
            $("#forget-password1").hide();
            }
        });

    $(document).on('ready', function () {
        // INITIALIZATION OF SHOW PASSWORD
        // =======================================================
        $('.js-toggle-password').each(function () {
            new HSTogglePassword(this).init()
        });

        // INITIALIZATION OF FORM VALIDATION
        // =======================================================
        $('.js-validate').each(function () {
            $.HSCore.components.HSValidation.init($(this));
        });
    });


$(document).on('click','.reloadCaptcha', function(){
    $.ajax({
        url: "{{ route('reload-captcha') }}",
        type: "GET",
        dataType: 'json',
        beforeSend: function () {
            $('#loading').show()
            $('.capcha-spin').addClass('active')
        },
        success: function(data) {
            $('#reload-captcha').html(data.view);
        },
        complete: function () {
            $('#loading').hide()
            $('.capcha-spin').removeClass('active')
        }
    });
});


    $(document).ready(function() {
        $('.onerror-image').on('error', function() {
            let img = $(this).data('onerror-image')
            $(this).attr('src', img);
        });
    });
</script>
@if(isset($recaptcha) && $recaptcha['status'] == 1)
    <script src="https://www.google.com/recaptcha/api.js?render={{$recaptcha['site_key']}}"></script>
@endif
@if(isset($recaptcha) && $recaptcha['status'] == 1)
    <script>
        $(document).ready(function() {
            $('#signInBtn').click(function (e) {
                if( $('#set_default_captcha_value').val() == 1){
                    $('#form-id').submit();
                    return true;
                }
                e.preventDefault();
                if (typeof grecaptcha === 'undefined') {
                    toastr.error('Invalid recaptcha key provided. Please check the recaptcha configuration.');
                    $('#reload-captcha').removeClass('d-none');
                    $('#set_default_captcha_value').val('1');

                    return;
                }
                grecaptcha.ready(function () {
                    grecaptcha.execute('{{$recaptcha['site_key']}}', {action: 'submit'}).then(function (token) {
                        $('#g-recaptcha-response').value = token;
                        $('#form-id').submit();
                    });
                });
                window.onerror = function (message) {
                    var errorMessage = 'An unexpected error occurred. Please check the recaptcha configuration';
                    if (message.includes('Invalid site key')) {
                        errorMessage = 'Invalid site key provided. Please check the recaptcha configuration.';
                    } else if (message.includes('not loaded in api.js')) {
                        errorMessage = 'reCAPTCHA API could not be loaded. Please check the recaptcha API configuration.';
                    }
                    $('#reload-captcha').removeClass('d-none');
                    $('#set_default_captcha_value').val('1');
                    toastr.error(errorMessage)
                    return true;
                };
            });
        });
    </script>
@endif
{{-- recaptcha scripts end --}}



@if(env('APP_MODE')=='demo')
    <script>
        "use strict";
        $('.copy_cred').on('click', function () {
            $('#signinSrEmail').val('admin@admin.com');
            $('#signupSrPassword').val('12345678');
            toastr.success('Copied successfully!', 'Success!', {
                CloseButton: true,
                ProgressBar: true
            });
        })
        $('.copy_cred2').on('click', function () {
            $('#signinSrEmail').val('test.restaurant@gmail.com');
            $('#signupSrPassword').val('12345678');
            toastr.success('Copied successfully!', 'Success!', {
                CloseButton: true,
                ProgressBar: true
            });
        })
    </script>
@endif

<!-- Password Toggle Script -->
<script>
    document.addEventListener('DOMContentLoaded', function() {
        const togglePassword = document.querySelector('.toggle-password');
        const password = document.querySelector('#signupSrPassword');
        const icon = togglePassword.querySelector('i');

        togglePassword.addEventListener('click', function() {
            const type = password.getAttribute('type') === 'password' ? 'text' : 'password';
            password.setAttribute('type', type);
            
            // Alterna entre os ícones de olho aberto e fechado
            if (type === 'password') {
                icon.classList.remove('tio-visible-outlined');
                icon.classList.add('tio-invisible');
            } else {
                icon.classList.remove('tio-invisible');
                icon.classList.add('tio-visible-outlined');
            }
        });
    });
</script>

<!-- IE Support -->
<script>
    if (/MSIE \d|Trident.*rv:/.test(navigator.userAgent)) document.write('<script src="{{asset('public//assets/admin')}}/vendor/babel-polyfill/polyfill.min.js"><\/script>');
</script>
</body>
</html>
