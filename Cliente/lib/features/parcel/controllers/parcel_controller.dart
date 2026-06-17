import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/parcel/domain/models/parcel_category_model.dart';
import 'package:sixam_mart/features/parcel/domain/models/place_details_model.dart';
import 'package:sixam_mart/features/parcel/domain/models/video_content_model.dart';
import 'package:sixam_mart/features/parcel/domain/models/why_choose_model.dart';
import 'package:sixam_mart/features/parcel/domain/services/parcel_service_interface.dart';
import 'package:sixam_mart/features/payment/domain/models/offline_method_model.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/parcel/domain/repositories/parcel_repository.dart'; // ajuste o path se for diferente

import '../domain/models/parcel_instruction_model.dart';
import 'package:universal_html/html.dart' as html;

/// Dados de uma entrega extra (parada adicional).
class ExtraDeliveryEntry {
  final AddressModel address;
  final double distanceKm;
  final double fee;
  final String houseNumber;
  final String contactPersonName;

  const ExtraDeliveryEntry({
    required this.address,
    required this.distanceKm,
    required this.fee,
    this.houseNumber = '',
    this.contactPersonName = '',
  });
}

class ParcelController extends GetxController implements GetxService {
  final ParcelServiceInterface parcelServiceInterface;
  final ParcelRepository parcelRepository;

  ParcelController({
    required this.parcelServiceInterface,
    required this.parcelRepository,
  });

  List<ParcelCategoryModel>? _parcelCategoryList;
  List<ParcelCategoryModel>? get parcelCategoryList => _parcelCategoryList;

  AddressModel? _pickupAddress;
  AddressModel? get pickupAddress => _pickupAddress;

  AddressModel? _destinationAddress;
  AddressModel? get destinationAddress => _destinationAddress;

  bool? _isPickedUp = true;
  bool? get isPickedUp => _isPickedUp;

  bool _isSender = true;
  bool get isSender => _isSender;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  double? _distance = -1;
  double? get distance => _distance;

  final List<String> _payerTypes = ['sender', 'receiver'];
  List<String> get payerTypes => _payerTypes;

  int _payerIndex = 0;
  int get payerIndex => _payerIndex;

  int _paymentIndex = -1;
  int get paymentIndex => _paymentIndex;

  bool _acceptTerms = true;
  bool get acceptTerms => _acceptTerms;

  double? _extraCharge;
  double? get extraCharge => _extraCharge;

  String? _digitalPaymentName;
  String? get digitalPaymentName => _digitalPaymentName;

  WhyChooseModel? _whyChooseDetails;
  WhyChooseModel? get whyChooseDetails => _whyChooseDetails;

  VideoContentModel? _videoContentDetails;
  VideoContentModel? get videoContentDetails => _videoContentDetails;

  int _selectedOfflineBankIndex = 0;
  int get selectedOfflineBankIndex => _selectedOfflineBankIndex;

  List<Data>? _parcelInstructionList;
  List<Data>? get parcelInstructionList => _parcelInstructionList;

  int _instructionselectedIndex = -1;
  int get instructionselectedIndex => _instructionselectedIndex;

  final TextEditingController _customNoteController = TextEditingController();
  TextEditingController get customNoteController => _customNoteController;

  String _customNote = '';
  String? get customNote => _customNote;

  int _selectedIndexNote = -1;
  int? get selectedIndexNote => _selectedIndexNote;

  int? _senderAddressIndex = 0;
  int? get senderAddressIndex => _senderAddressIndex;

  int? _receiverAddressIndex = 0;
  int? get receiverAddressIndex => _receiverAddressIndex;

  String? _senderCountryCode;
  String? get senderCountryCode => _senderCountryCode;

  String? _receiverCountryCode;
  String? get receiverCountryCode => _receiverCountryCode;

  List<OfflineMethodModel>? _offlineMethodList;
  List<OfflineMethodModel>? get offlineMethodList => _offlineMethodList;

  int? _mostDmTipAmount;
  int? get mostDmTipAmount => _mostDmTipAmount;

  double _tips = 0.0;
  double get tips => _tips;

  int _selectedTips = 0;
  int get selectedTips => _selectedTips;

  bool _canShowTipsField = false;
  bool get canShowTipsField => _canShowTipsField;

  bool _isDmTipSave = false;
  bool get isDmTipSave => _isDmTipSave;


  double? deliveryFee;       // <<< NOVO
  bool isCalculatingFee = false; // <<< NOVO

  // ── Entregas extras ──────────────────────────────────────────────────────
  final List<ExtraDeliveryEntry> _extraDeliveries = [];
  List<ExtraDeliveryEntry> get extraDeliveries => List.unmodifiable(_extraDeliveries);

  double get extraDeliveriesTotalFee =>
      _extraDeliveries.fold(0.0, (sum, e) => sum + e.fee);

  void addExtraDelivery(ExtraDeliveryEntry entry) {
    if (_extraDeliveries.length < 2) {
      _extraDeliveries.add(entry);
      update();
    }
  }

  void removeExtraDelivery(int index) {
    if (index >= 0 && index < _extraDeliveries.length) {
      _extraDeliveries.removeAt(index);
      update();
    }
  }

  void clearExtraDeliveries() {
    _extraDeliveries.clear();
  }

  /// Resolve o placeId → calcula distância → devolve um
  /// [ExtraDeliveryEntry] pronto ou [null] em caso de erro.
  /// O valor cobrado usa computeParcelFeeForDistance × % configurado na categoria.
  /// [errorOut] recebe a mensagem de erro quando retorna null.
  Future<ExtraDeliveryEntry?> resolveExtraDelivery({
    required String placeId,
    required String description,
    required double mainDistanceKm,
    required int categoryId,
    required int zoneId,
    required AddressModel pickupAddress,
    String houseNumber = '',
    String contactPersonName = '',
    String contactPersonNumber = '',
    StringBuffer? errorOut,
  }) async {
    try {
      // Guard: pickup address must have valid coordinates
      final double? originLat = double.tryParse(pickupAddress.latitude ?? '');
      final double? originLng = double.tryParse(pickupAddress.longitude ?? '');
      if (originLat == null || originLng == null) {
        errorOut?.write('Endereço de origem inválido. Refaça a seleção.');
        return null;
      }

      // 1. Detalhes do lugar (lat/lng do endereço extra)
      final Response response = await parcelRepository.getPlaceDetails(placeId);
      if (response.statusCode != 200) {
        errorOut?.write('Erro ao carregar endereço.');
        return null;
      }

      final PlaceDetailsModel placeDetails =
          PlaceDetailsModel.fromJson(response.body);
      if (placeDetails.status != 'OK' ||
          placeDetails.result?.geometry?.location == null) {
        errorOut?.write('Endereço inválido. Tente selecionar outro.');
        return null;
      }

      final double destLat = placeDetails.result!.geometry!.location!.lat!;
      final double destLng = placeDetails.result!.geometry!.location!.lng!;

      // 2. Distância via Distance Matrix (com fallback Geolocator)
      final double extraDistanceKm = await parcelRepository.getRouteDistanceKm(
        LatLng(originLat, originLng),
        LatLng(destLat, destLng),
      );

      if (extraDistanceKm <= 0) {
        errorOut?.write('Não foi possível calcular a distância do endereço.');
        return null;
      }

      // 3. Validação: parada extra não pode ser mais distante que a principal
      if (extraDistanceKm > mainDistanceKm) {
        errorOut?.write(
            'A distância da parada extra (${extraDistanceKm.toStringAsFixed(2)} km) '
            'não pode ser maior que a da entrega principal '
            '(${mainDistanceKm.toStringAsFixed(2)} km).');
        return null;
      }

      // 4. Taxa calculada pela API (computeParcelFeeForDistance × % configurado na categoria)
      final double extraFee = await parcelRepository.getAdditionalStopFee(
        categoryId:     categoryId,
        zoneId:         zoneId,
        distanceKm:     extraDistanceKm,
        mainDistanceKm: mainDistanceKm,
      );
      if (extraFee < 0) {
        errorOut?.write('Não foi possível calcular a taxa da parada extra.');
        return null;
      }

      // Endereço completo = descrição + número (para exibição e armazenamento)
      final String fullAddress = houseNumber.isNotEmpty
          ? '$description, $houseNumber'
          : description;

      final AddressModel extraAddress = AddressModel(
        address: fullAddress,
        addressType: 'others',
        latitude: destLat.toString(),
        longitude: destLng.toString(),
        contactPersonName: contactPersonName,
        contactPersonNumber: contactPersonNumber,
        house: houseNumber.isEmpty ? null : houseNumber,
      );

      return ExtraDeliveryEntry(
        address: extraAddress,
        distanceKm: extraDistanceKm,
        fee: extraFee,
        houseNumber: houseNumber,
        contactPersonName: contactPersonName,
      );
    } catch (e) {
      errorOut?.write('Erro inesperado: $e');
      return null;
    }
  }
  // ─────────────────────────────────────────────────────────────────────────


Future<void> updateDeliveryFee({
  required int categoryId,
  required int zoneId,
  bool isReturn = false, // ✅ novo
}) async {
  if (distance == null || distance == -1) return;

  isCalculatingFee = true;
  update();

  final double fee = await parcelRepository.getDeliveryFeeFromServer(
    categoryId: categoryId,
    distanceKm: distance!,
    zoneId: zoneId,
    extraCharge: extraCharge ?? 0,
    isReturn: isReturn, // ✅ novo
  );

  // fee == -1 indica erro de rede / backend. Mantém null para poder tentar de novo.
  deliveryFee = fee >= 0 ? fee : null;
  isCalculatingFee = false;
  update();
}




  void showTipsField(){
    _canShowTipsField = !_canShowTipsField;
    update();
  }

  Future<void> addTips(double tips) async {
    _tips = tips;
    update();
  }

  void toggleDmTipSave() {
    _isDmTipSave = !_isDmTipSave;
    update();
  }

  void setCountryCode(String code, bool isSender) {
    if(isSender) {
      _senderCountryCode = code;
    } else {
      _receiverCountryCode = code;
    }
  }

  void setSenderAddressIndex(int? index, {bool canUpdate = true}) {
    _senderAddressIndex = index;
    if(canUpdate) {
      update();
    }
  }

  void setReceiverAddressIndex(int? index, {bool canUpdate = true}) {
    _receiverAddressIndex = index;
    if(canUpdate) {
      update();
    }
  }

  void selectOfflineBank(int index){
    _selectedOfflineBankIndex = index;
    update();
  }

  void changeDigitalPaymentName(String name){
    _digitalPaymentName = name;
    update();
  }

  void toggleTerms() {
    _acceptTerms = !_acceptTerms;
    update();
  }

  Future<void> getParcelCategoryList() async {
    List<ParcelCategoryModel>? categoryModelList = await parcelServiceInterface.getParcelCategory();
    if(categoryModelList != null) {
      _parcelCategoryList = [];
      _parcelCategoryList!.addAll(categoryModelList);
    }
    update();
  }

  void setPickupAddress(AddressModel? addressModel, bool notify) {
    _pickupAddress = addressModel;
    if(notify) {
      update();
    }
  }

  void setDestinationAddress(AddressModel? addressModel, {bool notify = true}) {
    _destinationAddress = addressModel;
    if(notify) {
      update();
    }
  }

  void setLocationFromPlace(String? placeID, String? address, bool? isPickedUp) async {
    Response response = await parcelServiceInterface.getPlaceDetails(placeID);
    if(response.statusCode == 200) {
      PlaceDetailsModel placeDetails = PlaceDetailsModel.fromJson(response.body);
      await _processAddressAndAction(placeDetails, address);
    }
  }

  Future<void> _processAddressAndAction(PlaceDetailsModel placeDetails, String? address) async {
    if(placeDetails.status == 'OK') {
      AddressModel address0 = AddressModel(
        address: address, addressType: 'others', latitude: placeDetails.result!.geometry!.location!.lat.toString(),
        longitude: placeDetails.result!.geometry!.location!.lng.toString(),
        contactPersonName: AddressHelper.getUserAddressFromSharedPref()!.contactPersonName,
        contactPersonNumber: AddressHelper.getUserAddressFromSharedPref()!.contactPersonNumber,
      );
      ZoneResponseModel response0 = await Get.find<LocationController>().getZone(address0.latitude, address0.longitude, false);
      if (response0.isSuccess) {
        bool inZone = false;
        for(int zoneId in AddressHelper.getUserAddressFromSharedPref()!.zoneIds!) {
          if(response0.zoneIds.contains(zoneId)) {
            inZone = true;
            break;
          }
        }
        if(inZone) {
          address0.zoneId =  response0.zoneIds[0];
          address0.zoneIds = [];
          address0.zoneIds!.addAll(response0.zoneIds);
          address0.zoneData = [];
          address0.zoneData!.addAll(response0.zoneData);
          if(isPickedUp!) {
            setPickupAddress(address0, true);
          }else {
            setDestinationAddress(address0);
          }
        }else {
          showCustomSnackBar('your_selected_location_is_from_different_zone_store'.tr);
        }
      } else {
        showCustomSnackBar(response0.message);
      }
    }
  }

  Future<void> getWhyChooseDetails({DataSourceEnum source = DataSourceEnum.local}) async {
    if(source == DataSourceEnum.local) {
      _whyChooseDetails = await parcelServiceInterface.getWhyChooseDetails(source: source);
      update();
      getWhyChooseDetails(source: DataSourceEnum.client);
    } else {
      _whyChooseDetails = await parcelServiceInterface.getWhyChooseDetails(source: source);
      update();
    }
  }

  Future<void> getVideoContentDetails({DataSourceEnum source = DataSourceEnum.local}) async {
    if(source == DataSourceEnum.local) {
      _videoContentDetails = await parcelServiceInterface.getVideoContentDetails(source: source);
      update();
      getVideoContentDetails(source: DataSourceEnum.client);
    } else {
      _videoContentDetails = await parcelServiceInterface.getVideoContentDetails(source: source);
      update();
    }
  }

  void setIsPickedUp(bool? isPickedUp, bool notify) {
    _isPickedUp = isPickedUp;
    if(notify) {
      update();
    }
  }

  void setIsSender(bool sender, bool notify) {
    _isSender = sender;
    if(notify) {
      update();
    }
  }

  void getDistance(AddressModel pickedUpAddress, AddressModel destinationAddress) async {
    _distance = -1;
    _distance = await Get.find<CheckoutController>().getDistanceInKM(
      LatLng(double.parse(pickedUpAddress.latitude!), double.parse(pickedUpAddress.longitude!)),
      LatLng(double.parse(destinationAddress.latitude!), double.parse(destinationAddress.longitude!)),
    );

    _extraCharge = Get.find<CheckoutController>().extraCharge;

    update();
  }

  void setPayerIndex(int index, bool notify) {
    _payerIndex = index;
    if(_payerIndex == 1) {
      _paymentIndex = 0;
    }
    if(notify) {
      update();
    }
  }

  void setPaymentIndex(int index, bool notify) {
    _paymentIndex = index;
    if(notify) {
      update();
    }
  }

  void startLoader(bool isEnable, {bool canUpdate = true}) {
    _isLoading = isEnable;
    if(canUpdate) {
      update();
    }
  }

  Future<void> getParcelInstruction() async {
    _parcelInstructionList = null;
    _parcelInstructionList = await parcelServiceInterface.getParcelInstruction(1);
    update();
  }

  void setInstructionselectedIndex(int index, {bool notify = true}) {
    _instructionselectedIndex = index;
    if(notify) {
      update();
    }
  }

  void setCustomNoteController(String customNote, {bool notify = true}) {
    _customNoteController.text = customNote;
    if(notify) {
      update();
    }
  }

  void setCustomNote(String? customNoteText) {
    if (customNoteText != null && customNoteText.isNotEmpty) {
      _customNote = customNoteText;
      update();
    }else {
      _customNote = _customNoteController.text;
    }
    if(customNoteText == null) {
      update();
    }
  }

  void setSelectedIndex(int? index) {
    if(index != null) {
      _selectedIndexNote = index;
    }else{
      _selectedIndexNote = _instructionselectedIndex;
    }
    if(index == null) {
      update();
    }
  }

  Future<void> getOfflineMethodList()async {
    _offlineMethodList = null;
    _offlineMethodList = await parcelServiceInterface.getOfflineMethodList();
    update();
  }

  Future<void> getDmTipMostTapped()async {
    _mostDmTipAmount = await parcelServiceInterface.getDmTipMostTapped();
    update();
  }

  void updateTips(int index, {bool notify = true}) {
    _selectedTips = index;
    if(_selectedTips == 0 || _selectedTips == 5) {
      _tips = 0;
    }else {
      _tips = double.parse(AppConstants.tips[index]);
    }
    if(notify) {
      update();
    }
  }

  Future<String> placeOrder(PlaceOrderBodyModel placeOrderBody, int? zoneID, double amount, double? maximumCodOrderAmount, bool fromCart, bool isCashOnDeliveryActive, {bool forParcel = false, bool isOfflinePay = false}) async {
    _isLoading = true;
    update();
    String orderID = '';
    Response response = await parcelServiceInterface.placeOrder(placeOrderBody);
    _isLoading = false;
    if (response.statusCode == 200) {
      String? message = response.body['message'];
      orderID = response.body['order_id'].toString();
      int createUserId = response.body['user_id'];

      clearExtraDeliveries();

      if(!isOfflinePay) {
        parcelCallback(true, message, orderID, zoneID, amount, maximumCodOrderAmount, isCashOnDeliveryActive, placeOrderBody.contactPersonNumber, createUserId: createUserId);
      }
      if (kDebugMode) {
        print('-------- Order placed successfully $orderID ----------');
      }
    } else {
      if (kDebugMode) {
        print('-------- placeOrder ERRO [${response.statusCode}] ----------');
        print('statusText: ${response.statusText}');
        print('body: ${response.body}');
      }
      if(!isOfflinePay) {
        parcelCallback(false, response.statusText, '-1', zoneID, amount, maximumCodOrderAmount, isCashOnDeliveryActive, placeOrderBody.contactPersonNumber);
      } else {
        showCustomSnackBar(response.statusText);
      }
    }
    update();

    return orderID;
  }

  Future<void> parcelCallback(bool isSuccess, String? message, String orderID, int? zoneID, double orderAmount, double? maxCodAmount, bool isCashOnDeliveryActive, String? contactNumber, {int? createUserId}) async {
    Get.find<ParcelController>().startLoader(false);
    if(isSuccess) {
      if(isDmTipSave){
        Get.find<AuthController>().saveDmTipIndex(selectedTips.toString());
      }
      Get.find<CheckoutController>().setGuestAddress(null);
      if(Get.find<ParcelController>().paymentIndex == 2) {
        if(GetPlatform.isWeb) {
          // Get.back();
          await Get.find<AuthController>().saveGuestNumber(contactNumber ?? '');
          String? hostname = html.window.location.hostname;
          String protocol = html.window.location.protocol;
          String selectedUrl = '${AppConstants.baseUrl}/payment-mobile?order_id=$orderID&&customer_id=${Get.find<ProfileController>().userInfoModel?.id ?? (Get.find<CheckoutController>().isCreateAccount ? createUserId : AuthHelper.getGuestId())}'
              '&payment_method=${Get.find<ParcelController>().digitalPaymentName}&payment_platform=web&&callback=$protocol//$hostname${RouteHelper.orderSuccess}?id=$orderID&status=';
          html.window.open(selectedUrl,"_self");
        } else{
          Get.offNamed(RouteHelper.getPaymentRoute(
            orderID, Get.find<ProfileController>().userInfoModel?.id ?? 0, 'parcel', orderAmount, isCashOnDeliveryActive,
            Get.find<ParcelController>().digitalPaymentName, guestId: AuthHelper.getGuestId(),
            contactNumber: contactNumber, createAccount: Get.find<CheckoutController>().isCreateAccount, createUserId: createUserId,
          ));
        }
      }else {
        Get.offNamed(RouteHelper.getOrderSuccessRoute(orderID, contactNumber, createAccount: Get.find<CheckoutController>().isCreateAccount));
      }
      updateTips(0, notify: false);
    }else {
      showCustomSnackBar(message);
    }
  }

}