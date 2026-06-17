<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <title>Pagamento | Turbo Entregas</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">

    {{-- Bootstrap 4 CSS --}}
    <link rel="stylesheet" type="text/css"
          href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css">

    <link rel="stylesheet" type="text/css" href="{{ asset('public/assets/admin/css/mercado.css') }}">

    {{-- jQuery + Popper + Bootstrap JS (necessário para as abas funcionarem) --}}
    <script src="https://code.jquery.com/jquery-3.4.1.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.12.9/umd/popper.min.js"></script>
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/js/bootstrap.min.js"></script>

    {{-- Mercado Pago --}}
    <script src="https://sdk.mercadopago.com/js/v2"></script>

    <style>
        .payment-tabs {
            border-bottom: none;
        }
        .payment-tabs .nav-link {
            border-radius: 50px;
            margin: 0 5px;
            padding: 8px 16px;
            border: 1px solid #007bff;
            color: #007bff;
        }
        .payment-tabs .nav-link.active {
            background-color: #007bff;
            color: #fff;
        }
    </style>
</head>
<body>
<main>

    <input type="hidden" id="mercado-pago-public-key" value="{{ $config->public_key }}">
    <input type="hidden" id="payment-id" value="{{ $data->id }}">

    <!-- Payment -->
    <section class="payment-form dark">
        <div class="container__payment">
            <div class="block-heading">
                <h2>Pagamento</h2>
                <p>Escolha a forma de pagamento abaixo</p>

                <div class="mt-3 d-flex justify-content-center">
                    <ul class="nav nav-tabs payment-tabs" id="paymentTabs" role="tablist">
                        <li class="nav-item flex-fill text-center">
                            <a class="nav-link active" id="card-tab" data-toggle="tab"
                               href="#card-pane" role="tab" aria-controls="card-pane"
                               aria-selected="true">
                                Cartão de crédito
                            </a>
                        </li>
                        <li class="nav-item flex-fill text-center">
                            <a class="nav-link" id="pix-tab" data-toggle="tab"
                               href="#pix-pane" role="tab" aria-controls="pix-pane"
                               aria-selected="false">
                                Pix
                            </a>
                        </li>
                    </ul>
                </div>
            </div>

            <div class="form-payment">
                <div class="products">
                    <p class="alert alert-danger" role="alert" id="error_alert" style="display:none;"></p>
                    <div class="total">
                        Valor a pagar {{ $data->currency_code }}
                        <span class="price">{{ $data->payment_amount }}</span>
                    </div>
                </div>

                <div class="tab-content" id="paymentTabsContent">

                    {{-- CARTÃO --}}
                    <div class="tab-pane fade show active" id="card-pane" role="tabpanel" aria-labelledby="card-tab">
                        <div class="payment-details mt-4">
                            <form id="form-checkout">
                                <h3 class="title">Dados do comprador</h3>
                                <div class="row">
                                    <div class="form-group col">
                                        <input id="form-checkout__cardholderEmail" name="cardholderEmail" type="email"
                                               class="form-control"
                                               placeholder="E-mail do comprador"/>
                                    </div>
                                </div>
                                <div class="row">
                                    <div class="form-group col-sm-5">
                                        <select id="form-checkout__identificationType" name="identificationType"
                                                class="form-control"></select>
                                    </div>
                                    <div class="form-group col-sm-7">
                                        <input id="form-checkout__identificationNumber" name="docNumber" type="text"
                                               class="form-control"
                                               placeholder="Documento (CPF/CNPJ)"/>
                                    </div>
                                </div>
                                <br>
                                <h3 class="title">Dados do cartão</h3>
                                <div class="row">
                                    <div class="form-group col-sm-8">
                                        <input id="form-checkout__cardholderName" name="cardholderName" type="text"
                                               class="form-control"
                                               placeholder="Nome impresso no cartão"/>
                                    </div>
                                    <div class="form-group col-sm-4">
                                        <div class="input-group expiration-date">
                                            <input id="form-checkout__cardExpirationMonth" name="cardExpirationMonth"
                                                   type="text" class="form-control" placeholder="MM"/>
                                            <span class="date-separator">/</span>
                                            <input id="form-checkout__cardExpirationYear" name="cardExpirationYear"
                                                   type="text" class="form-control" placeholder="AA"/>
                                        </div>
                                    </div>
                                    <div class="form-group col-sm-8">
                                        <input id="form-checkout__cardNumber" name="cardNumber" type="text"
                                               class="form-control"
                                               placeholder="Número do cartão"/>
                                    </div>
                                    <div class="form-group col-sm-4">
                                        <input id="form-checkout__securityCode" name="securityCode" type="text"
                                               class="form-control"
                                               placeholder="CVV"/>
                                    </div>
                                    <div id="issuerInput" class="form-group col-sm-12 hidden">
                                        <select id="form-checkout__issuer" name="issuer" class="form-control"></select>
                                    </div>
                                    <div class="form-group col-sm-12">
                                        <select id="form-checkout__installments" name="installments" type="text"
                                                class="form-control"></select>
                                    </div>
                                    <div class="form-group col-sm-12">
                                        <br>
                                        <button id="form-checkout__submit" type="submit"
                                                class="btn btn--primary btn-block checkout-submit">
                                            Pagar com cartão
                                        </button>
                                        <br>
                                        <p id="loading-message" style="display:none;">
                                            Processando pagamento, por favor aguarde...
                                        </p>
                                        <br>
                                    </div>
                                </div>
                            </form>
                        </div>
                    </div>

                    {{-- PIX --}}
                    <div class="tab-pane fade" id="pix-pane" role="tabpanel" aria-labelledby="pix-tab">
                        <div class="payment-details mt-4">
                            <form id="form-pix">
                                <h3 class="title">Pagamento via Pix</h3>
                                <div class="row">
                                    <div class="form-group col-sm-8">
                                        <input id="pix_email" type="email"
                                               class="form-control"
                                               placeholder="E-mail do pagador" required/>
                                    </div>
                                    <div class="form-group col-sm-4">
                                        <input id="pix_cpf" type="text"
                                               class="form-control"
                                               placeholder="CPF do pagador" required/>
                                    </div>
                                </div>

                                <div class="form-group">
                                    <button id="pix_submit" type="submit"
                                            class="btn btn--primary btn-block checkout-submit">
                                        Gerar Pix
                                    </button>
                                </div>

                                <p id="pix-loading-message" style="display:none;">
                                    Gerando Pix, por favor aguarde...
                                </p>

                                <div id="pix-result" class="mt-3" style="display:none;">
                                    <h5>Escaneie o QR Code abaixo ou copie o código Pix</h5>
                                    <div class="text-center my-3">
                                        <img id="pix-qrcode" alt="QR Code Pix" style="max-width:250px;">
                                    </div>
                                    <div class="form-group">
                                        <label for="pix-code">Código Pix (copiar e colar)</label>
                                        <textarea id="pix-code" class="form-control" rows="3" readonly></textarea>
                                    </div>
                                    <div id="pix-ticket-link" class="mt-2"></div>
                                    <p id="pix-confirmed" class="alert alert-success" style="display:none;">
                                        Pagamento confirmado! Você será redirecionado em instantes...
                                    </p>
                                </div>
                            </form>
                        </div>
                    </div>

                </div> {{-- tab-content --}}
            </div>
        </div>
    </section>
</main>

<script>
    'use strict';

    const publicKey   = document.getElementById("mercado-pago-public-key").value;
    const mercadopago = new MercadoPago(publicKey);
    const productCost = '{{ $data->payment_amount }}';
    const paymentId   = document.getElementById('payment-id').value;

    const errorAlert = document.getElementById("error_alert");

    function formatError(err) {
        if (!err) return 'Ocorreu um erro ao processar o pagamento.';
        if (typeof err === 'string') return err;
        if (typeof err === 'object') {
            if (err.message) return err.message;
            if (err.error)   return formatError(err.error);
            try {
                return JSON.stringify(err);
            } catch (e) {
                return 'Ocorreu um erro ao processar o pagamento.';
            }
        }
        return String(err);
    }

    function showError(message) {
        errorAlert.innerText = formatError(message);
        errorAlert.style.display = "block";
    }

    // ---------- CARTÃO ----------
    loadCardForm();

    function loadCardForm() {
        const cardForm = mercadopago.cardForm({
            amount: productCost,
            autoMount: true,
            form: {
                id: "form-checkout",
                cardholderName:       { id: "form-checkout__cardholderName" },
                cardholderEmail:      { id: "form-checkout__cardholderEmail" },
                cardNumber:           { id: "form-checkout__cardNumber" },
                cardExpirationMonth:  { id: "form-checkout__cardExpirationMonth" },
                cardExpirationYear:   { id: "form-checkout__cardExpirationYear" },
                securityCode:         { id: "form-checkout__securityCode" },
                installments:         { id: "form-checkout__installments" },
                identificationType:   { id: "form-checkout__identificationType" },
                identificationNumber: { id: "form-checkout__identificationNumber" },
                issuer:               { id: "form-checkout__issuer" },
            },
            callbacks: {
                onFormMounted: error => {
                    if (error) return console.warn("Erro ao montar o formulário de cartão: ", error);
                },
                onSubmit: event => {
                    event.preventDefault();
                    document.getElementById("loading-message").style.display = "block";
                    errorAlert.style.display = "none";

                    const {
                        paymentMethodId,
                        issuerId,
                        cardholderEmail: email,
                        amount,
                        token,
                        installments,
                        identificationNumber,
                        identificationType,
                    } = cardForm.getCardFormData();

                    fetch("{{ route('mercadopago.make_payment', ['payment_id' => $data->id]) }}", {
                        method: "POST",
                        headers: {
                            "Content-Type": "application/json",
                            "X-CSRF-TOKEN": "{{ csrf_token() }}"
                        },
                        body: JSON.stringify({
                            payment_id: "{{ $data->id }}",
                            token,
                            issuerId,
                            paymentMethodId,
                            transactionAmount: Number(amount),
                            installments: Number(installments),
                            payer: {
                                email,
                                identification: {
                                    type: identificationType,
                                    number: identificationNumber,
                                },
                            },
                        }),
                    })
                        .then(response => response.json())
                        .then(result => {
                            document.getElementById("loading-message").style.display = "none";

                            if (result.error) {
                                showError(result.error);
                                return;
                            }

                            // cartão aprovado -> segue fluxo normal que já estava funcionando
                            window.location.href = "{{ route('mercadopago.success', ['payment_id' => $data->id]) }}";
                        })
                        .catch(error => {
                            document.getElementById("loading-message").style.display = "none";
                            showError(error);
                        });
                },
                onFetching: (resource) => {
                    const payButton = document.getElementById("form-checkout__submit");
                    payButton.setAttribute('disabled', true);
                    return () => {
                        payButton.removeAttribute("disabled");
                    };
                },
            },
        });
    }

    // ---------- PIX ----------
    const pixForm = document.getElementById('form-pix');

    pixForm.addEventListener('submit', function (e) {
        e.preventDefault();

        const email = document.getElementById('pix_email').value;
        const cpf   = document.getElementById('pix_cpf').value;

        document.getElementById('pix-loading-message').style.display = 'block';
        document.getElementById('pix-result').style.display = 'none';
        document.getElementById('pix-confirmed').style.display = 'none';
        errorAlert.style.display = "none";

        fetch("{{ route('mercadopago.pix_payment', ['payment_id' => $data->id]) }}", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-CSRF-TOKEN": "{{ csrf_token() }}"
            },
            body: JSON.stringify({
                payment_id: "{{ $data->id }}",
                transactionAmount: Number(productCost),
                payer: {
                    email: email,
                    identification: {
                        type: "CPF",
                        number: cpf
                    }
                }
            }),
        })
            .then(response => response.json())
            .then(result => {
                document.getElementById('pix-loading-message').style.display = 'none';

                if (result.error) {
                    showError(result.error);
                    return;
                }

                if (result.qr_code_base64) {
                    document.getElementById('pix-qrcode').src =
                        "data:image/png;base64," + result.qr_code_base64;
                }
                if (result.qr_code) {
                    document.getElementById('pix-code').value = result.qr_code;
                }

                const ticketDiv = document.getElementById('pix-ticket-link');
                ticketDiv.innerHTML = '';
                if (result.ticket_url) {
                    ticketDiv.innerHTML =
                        '<a href="' + result.ticket_url + '" target="_blank">Abrir link do pagamento</a>';
                }

                document.getElementById('pix-result').style.display = 'block';

                // começa a checar status até o webhook confirmar
                startPixStatusPooling();
            })
            .catch(error => {
                document.getElementById('pix-loading-message').style.display = 'none';
                showError(error);
            });
    });

    function startPixStatusPooling() {
        const confirmedEl = document.getElementById('pix-confirmed');
        const interval = setInterval(() => {
            fetch("{{ route('mercadopago.pix_status') }}?payment_id={{ $data->id }}")
                .then(r => r.json())
                .then(result => {
                    if (result.status === 'paid') {
                        clearInterval(interval);
                        confirmedEl.style.display = 'block';
                        setTimeout(() => {
                            window.location.href = "{{ route('mercadopago.success', ['payment_id' => $data->id]) }}";
                        }, 3000);
                    }
                })
                .catch(e => console.error('Erro ao checar status do Pix', e));
        }, 8000);
    }
</script>
</body>
</html>
