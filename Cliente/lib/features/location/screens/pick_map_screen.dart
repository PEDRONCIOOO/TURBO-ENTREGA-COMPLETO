import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'dart:async';

import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/location/widgets/serach_location_widget.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class PickMapScreen extends StatefulWidget {
  final bool fromSignUp;
  final bool fromAddAddress;
  final bool canRoute;
  final String? route;
  final GoogleMapController? googleMapController;
  final Function(AddressModel address)? onPicked;
  final bool fromLandingPage;

  const PickMapScreen({
    super.key,
    required this.fromSignUp,
    required this.fromAddAddress,
    required this.canRoute,
    required this.route,
    this.googleMapController,
    this.onPicked,
    this.fromLandingPage = false,
  });

  @override
  State<PickMapScreen> createState() => _PickMapScreenState();
}

class _PickMapScreenState extends State<PickMapScreen> {
  final TextEditingController _numberController = TextEditingController();
  bool _geocoding = false;
  bool _numberError = false;
  Timer? _zoneValidationDebounce;
  String? _lastZoneValidationAddress;

  /// Endereço original vindo do LocationController (sem mexer)
  String? _baseAddress;

  /// Último endereço vindo do controller (pra detectar troca de endereço)
  String? _lastControllerAddress;

  /// Endereço exibido (rua + número + resto)
  String? _displayAddress;

  @override
  void dispose() {
    _zoneValidationDebounce?.cancel();
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ResponsiveHelper.isDesktop(context)
          ? Colors.transparent
          : Theme.of(context).cardColor,
      endDrawer: const MenuDrawer(),
      endDrawerEnableOpenDragGesture: false,
      body: SafeArea(
        child: Center(
          child: Container(
            height: ResponsiveHelper.isDesktop(context)
                ? Get.context!.height * 0.6
                : null,
            width: ResponsiveHelper.isDesktop(context)
                ? 700
                : Dimensions.webMaxWidth,
            decoration: context.width > 700
                ? BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius:
                        BorderRadius.circular(Dimensions.radiusSmall),
                  )
                : null,
            child: GetBuilder<LocationController>(
              builder: (locationController) {
                final String controllerAddress =
                    locationController.pickAddress ?? '';

                // 1) Detecta quando o usuário escolhe um NOVO endereço
                if (controllerAddress.isNotEmpty &&
                    controllerAddress != _lastControllerAddress) {
                  _lastControllerAddress = controllerAddress;
                  final extracted = _extractNumberFromAddress(controllerAddress);
                  _baseAddress = extracted['address'];
                  _displayAddress = null;
                  _numberController.text = extracted['number'] ?? '';
                  _numberError = false;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    _scheduleAddressZoneValidation(
                      locationController,
                      _baseAddress ?? controllerAddress,
                    );
                  });
                }

                // 2) Garante base preenchida pelo menos uma vez
                if ((_baseAddress == null || _baseAddress!.isEmpty) &&
                    controllerAddress.isNotEmpty) {
                  _baseAddress = controllerAddress;
                }

                // Exibe o endereço SEM número no campo de cima
                // (número fica no campo dedicado abaixo)
                final String currentAddress = _baseAddress ?? controllerAddress;
                final bool canPickAddress = locationController.inZone &&
                    !locationController.buttonDisabled &&
                    !locationController.loading &&
                    !locationController.isLoading &&
                    !_geocoding;

                return Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.location_on_rounded, size: 20, color: Theme.of(context).primaryColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Onde você está?',
                                  style: robotoBold.copyWith(fontSize: 18),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Busque seu endereço para entregas',
                                  style: robotoRegular.copyWith(
                                    fontSize: 12,
                                    color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black).withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Get.back(),
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Campo de endereço
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SearchLocationWidget(
                        mapController: null,
                        pickedAddress: currentAddress,
                        isEnabled: null,
                        fromDialog: true,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Campo de número
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: _numberController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        style: robotoRegular.copyWith(fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Número',
                          labelStyle: robotoMedium.copyWith(
                            fontSize: 12,
                            color: _numberError ? Colors.red : Theme.of(context).primaryColor,
                          ),
                          hintText: 'Ex: 1234',
                          hintStyle: robotoRegular.copyWith(fontSize: 13, color: Colors.grey.shade400),
                          errorText: _numberError ? 'Informe o número do endereço' : null,
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(10),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _numberError
                                  ? Colors.red.withValues(alpha: 0.1)
                                  : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.tag_rounded,
                              size: 18,
                              color: _numberError ? Colors.red : Theme.of(context).primaryColor,
                            ),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: _numberError ? Colors.red : Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: _numberError ? Colors.red : Theme.of(context).primaryColor, width: 1.5),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Colors.red, width: 1.5),
                          ),
                        ),
                        onChanged: (value) {
                          if (_numberError && value.trim().isNotEmpty) {
                            setState(() => _numberError = false);
                          }
                          _onNumberChanged(value, _baseAddress ?? controllerAddress);
                          _scheduleAddressZoneValidation(locationController, _baseAddress ?? controllerAddress);
                        },
                      ),
                    ),

                    // Status indicator
                    if (!locationController.inZone && currentAddress.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(children: [
                            Icon(Icons.info_outline_rounded, size: 18, color: Colors.red.shade400),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'service_not_available_in_this_area'.tr,
                                style: robotoRegular.copyWith(fontSize: 12, color: Colors.red.shade700),
                              ),
                            ),
                          ]),
                        ),
                      ),

                    const Spacer(),

                    // Botão
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: CustomButton(
                        isBold: true,
                        radius: 16,
                        buttonText: locationController.inZone
                            ? widget.fromAddAddress
                                ? 'pick_address'.tr
                                : 'pick_location'.tr
                            : 'service_not_available_in_this_area'.tr,
                        isLoading: locationController.isLoading || _geocoding,
                        onPressed: canPickAddress
                            ? () => _onPickAddressButtonPressed(locationController)
                            : null,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Atualiza o texto do endereço em cima conforme o número digitado.
  void _onNumberChanged(String number, String baseAddress) {
    if (baseAddress.isEmpty) return;

    setState(() {
      _baseAddress = baseAddress;

      final numTrim = number.trim();
      if (numTrim.isEmpty) {
        _displayAddress = _baseAddress;
      } else {
        _displayAddress = _composeAddressWithNumber(_baseAddress!, numTrim);
      }
    });
  }

  void _scheduleAddressZoneValidation(
    LocationController locationController,
    String baseAddress,
  ) {
    final String address = baseAddress.trim();
    if (address.isEmpty) return;

    final String number = _numberController.text.trim();
    final String addressToValidate = number.isEmpty
        ? address
        : _composeAddressWithNumber(address, number);

    _zoneValidationDebounce?.cancel();
    _zoneValidationDebounce = Timer(const Duration(milliseconds: 600), () {
      _validateAddressZone(locationController, addressToValidate);
    });
  }

  Future<void> _validateAddressZone(
    LocationController locationController,
    String addressToValidate,
  ) async {
    _lastZoneValidationAddress = addressToValidate;
    if (mounted) setState(() => _geocoding = true);

    try {
      final LatLng? precise =
          await locationController.forwardGeocode(addressToValidate);
      if (!mounted || _lastZoneValidationAddress != addressToValidate) return;

      if (precise != null &&
          !(precise.latitude == 0.0 && precise.longitude == 0.0)) {
        locationController.updatePickPosition(precise);
        await locationController.getZone(
          precise.latitude.toString(),
          precise.longitude.toString(),
          false,
        );
      } else if (locationController.pickPosition.latitude != 0.0 ||
          locationController.pickPosition.longitude != 0.0) {
        await locationController.getZone(
          locationController.pickPosition.latitude.toString(),
          locationController.pickPosition.longitude.toString(),
          false,
        );
      }
    } finally {
      if (mounted && _lastZoneValidationAddress == addressToValidate) {
        setState(() => _geocoding = false);
      }
    }
  }

  /// Monta "Rua X, 123, Cidade - UF, País" a partir de um endereço base.
  /// Regras:
  /// - Sempre usa o primeiro pedaço como "rua".
  /// - Se o segundo pedaço for numérico **e** o terceiro tiver padrão de cidade
  ///   (contém "-"), considera o segundo como número antigo e substitui.
  /// - Caso contrário, o segundo pedaço vai pro "resto" (CEP, bairro, etc).
  String _composeAddressWithNumber(String original, String number) {
    final parts = original.split(',');

    if (parts.isEmpty) return original;

    final street = parts[0].trim();
    List<String> restParts;

    final hasSecond =
        parts.length >= 2 && parts[1].trim().isNotEmpty;
    final hasThird =
        parts.length >= 3 && parts[2].trim().isNotEmpty;

    final bool secondIsNumeric = hasSecond &&
        RegExp(r'^\d+$').hasMatch(parts[1].trim());

    // Ex.: "BR-163, 116, Nova Alvorada do Sul - MS, 79140-000, Brasil"
    // -> parts[2] contém "-", então 116 é número da casa
    final bool thirdLooksLikeCity =
        hasThird && parts[2].contains('-');

    if (secondIsNumeric && thirdLooksLikeCity) {
      // já tinha número no meio -> removemos ele e mantemos o resto
      restParts = parts.sublist(2);
    } else {
      // segundo pedaço NÃO é claramente número de casa -> vai pro resto
      restParts = parts.sublist(1);
    }

    final buffer = StringBuffer();
    buffer.write(street);
    buffer.write(', ');
    buffer.write(number);

    if (restParts.isNotEmpty) {
      buffer.write(', ');
      buffer.write(restParts.join(',').trim());
    }

    return buffer.toString();
  }

  /// Tenta extrair o número do imóvel de um endereço formatado.
  /// Ex: "R. X, 150, Bairro Y, Cidade" → {address: "R. X, Bairro Y, Cidade", number: "150"}
  Map<String, String?> _extractNumberFromAddress(String original) {
    final parts = original.split(',');
    if (parts.length < 3) return {'address': original, 'number': null};

    final secondTrimmed = parts[1].trim();
    final bool secondIsNumeric = RegExp(r'^\d+$').hasMatch(secondTrimmed);

    if (secondIsNumeric) {
      final withoutNumber = ([parts[0].trim()] +
              parts.sublist(2).map((p) => p.trim()).toList())
          .join(', ');
      return {'address': withoutNumber, 'number': secondTrimmed};
    }

    return {'address': original, 'number': null};
  }

  // ==================== BOTÃO "ESCOLHER LOCAL" ====================

  Future<void> _onPickAddressButtonPressed(LocationController locationController) async {
    final String baseAddr = _baseAddress ?? locationController.pickAddress ?? '';
    final String houseNumber = _numberController.text.trim();

    if (baseAddr.isEmpty) {
      showCustomSnackBar('pick_an_address'.tr);
      return;
    }

    // Número é obrigatório
    if (houseNumber.isEmpty) {
      setState(() => _numberError = true);
      showCustomSnackBar('Informe o número do endereço');
      return;
    }
    setState(() => _numberError = false);

    // Endereço final composto: rua + número + resto
    final String finalAddress = _composeAddressWithNumber(baseAddr, houseNumber);

    // Sempre faz forward-geocode para obter coordenadas precisas do imóvel
    setState(() => _geocoding = true);
    try {
      final LatLng? precise = await locationController.forwardGeocode(finalAddress);
      if (precise != null &&
          !(precise.latitude == 0.0 && precise.longitude == 0.0)) {
        locationController.updatePickPosition(precise);
      }
    } finally {
      if (mounted) setState(() => _geocoding = false);
    }

    final zoneResponse = await locationController.getZone(
      locationController.pickPosition.latitude.toString(),
      locationController.pickPosition.longitude.toString(),
      false,
    );
    if (!zoneResponse.isSuccess) {
      showCustomSnackBar('service_not_available_in_this_area'.tr);
      return;
    }

    if (widget.onPicked != null) {
      // usado em fluxos que precisam só do AddressModel pronto
      AddressModel address = AddressModel(
        latitude: locationController.pickPosition.latitude.toString(),
        longitude: locationController.pickPosition.longitude.toString(),
        addressType: 'others',
        address: finalAddress,
        contactPersonName:
            AddressHelper.getUserAddressFromSharedPref()!
                .contactPersonName,
        contactPersonNumber:
            AddressHelper.getUserAddressFromSharedPref()!
                .contactPersonNumber,
        streetNumber: houseNumber,
      );
      widget.onPicked!(address);
      Get.back();
    } else if (widget.fromAddAddress) {
      // fluxo do "Adicionar novo endereço" com mapa por trás
      if (widget.googleMapController != null) {
        widget.googleMapController!.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(
                locationController.pickPosition.latitude,
                locationController.pickPosition.longitude,
              ),
              zoom: 16,
            ),
          ),
        );
        Get.find<LocationController>().setAddAddressData();
      }
      Get.back();
    } else {
      // fluxo normal de salvar e navegar
      AddressModel address = AddressModel(
        latitude: locationController.pickPosition.latitude.toString(),
        longitude: locationController.pickPosition.longitude.toString(),
        addressType: 'others',
        address: finalAddress,
        streetNumber: houseNumber,
      );

      if (widget.fromLandingPage) {
        if (!AuthHelper.isGuestLoggedIn() && !AuthHelper.isLoggedIn()) {
          Get.find<AuthController>().guestLogin().then((response) {
            if (response.isSuccess) {
              Get.find<ProfileController>().setForceFullyUserEmpty();
              Get.back();
              locationController.saveAddressAndNavigate(
                address,
                widget.fromSignUp,
                widget.route,
                widget.canRoute,
                ResponsiveHelper.isDesktop(Get.context),
              );
            }
          });
        } else {
          Get.back();
          locationController.saveAddressAndNavigate(
            address,
            widget.fromSignUp,
            widget.route,
            widget.canRoute,
            ResponsiveHelper.isDesktop(context),
          );
        }
      } else {
        locationController.saveAddressAndNavigate(
          address,
          widget.fromSignUp,
          widget.route,
          widget.canRoute,
          ResponsiveHelper.isDesktop(context),
        );
      }
    }
  }
}
