import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixam_mart_delivery/common/models/response_model.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart_delivery/features/order/domain/models/order_model.dart';
import 'package:sixam_mart_delivery/features/order/domain/models/update_status_body_model.dart';
import 'package:sixam_mart_delivery/features/order/domain/services/order_service_interface.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/styles.dart';
import 'package:sixam_mart_delivery/features/order/domain/models/order_cancellation_body.dart';
// import 'package:sixam_mart_delivery/util/app_constants.dart'; // Removido pois nÃ£o Ã© mais necessÃ¡rio
import 'package:sixam_mart_delivery/util/app_constants.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_snackbar_widget.dart';
// Adicionar as importaÃ§Ãµes que faltam
import 'package:sixam_mart_delivery/features/order/domain/models/order_details_model.dart';
import 'package:sixam_mart_delivery/features/order/domain/models/ignore_model.dart';
import 'package:sixam_mart_delivery/api/api_client.dart';
import 'package:sixam_mart_delivery/helper/notification_helper.dart';
import 'package:sixam_mart_delivery/main.dart'; // para usar flutterLocalNotificationsPlugin
class OrderController extends GetxController implements GetxService {
  final OrderServiceInterface orderServiceInterface;
  OrderController({required this.orderServiceInterface});

  List<OrderModel>? _currentOrderList;
  List<OrderModel>? get currentOrderList => _currentOrderList;
  
  List<OrderModel>? _completedOrderList;
  List<OrderModel>? get completedOrderList => _completedOrderList;
  
  List<OrderModel>? _latestOrderList;
  List<OrderModel>? get latestOrderList => _latestOrderList;
  
  List<OrderDetailsModel>? _orderDetailsModel;
  List<OrderDetailsModel>? get orderDetailsModel => _orderDetailsModel;
  
  List<IgnoreModel> _ignoredRequests = [];
  List<IgnoreModel> get ignoredRequests => _ignoredRequests;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String _otp = '';
  String get otp => _otp;
  
  bool _paginate = false;
  bool get paginate => _paginate;
  
  int? _pageSize;
  int? get pageSize => _pageSize;
  
  List<int> _offsetList = [];
  List<int> get offsetList => _offsetList;
  
  int _offset = 1;
  int get offset => _offset;
  
  OrderModel? _orderModel;
  OrderModel? get orderModel => _orderModel;
  
  String? _cancelReason = '';
  String? get cancelReason => _cancelReason;
  
  List<CancellationData>? _orderCancelReasons;
  List<CancellationData>? get orderCancelReasons => _orderCancelReasons;
  
  bool _showDeliveryImageField = false;
  bool get showDeliveryImageField => _showDeliveryImageField;
  
  List<XFile> _pickedPrescriptions = [];
  List<XFile> get pickedPrescriptions => _pickedPrescriptions;

  void changeDeliveryImageStatus({bool isUpdate = true}){
    _showDeliveryImageField = !_showDeliveryImageField;
    if(isUpdate) {
      update();
    }
  }

  void pickPrescriptionImage({required bool isRemove, required bool isCamera}) async {
    if(isRemove) {
      _pickedPrescriptions = [];
    }else {
      XFile? xFile = await ImagePicker().pickImage(source: isCamera ? ImageSource.camera : ImageSource.gallery, imageQuality: 50);
      if(xFile != null) {
        _pickedPrescriptions.add(xFile);
        if(Get.isDialogOpen!){
          Get.back();
        }
      }
      update();
    }
  }

  void initLoading(){
    _isLoading = false;
    update();
  }

  void setOrderCancelReason(String? reason){
    _cancelReason = reason;
    update();
  }

  Future<void> getOrderCancelReasons() async {
    List<CancellationData>? orderCancelReasons = await orderServiceInterface.getCancelReasons();
    if (orderCancelReasons != null) {
      _orderCancelReasons = [];
      _orderCancelReasons!.addAll(orderCancelReasons);
    }
    update();
  }

  Future<void> getOrderWithId(int? orderId) async {
    _orderModel = null;
    Response response = await orderServiceInterface.getOrderWithId(orderId);
    if(response.statusCode == 200) {
      _orderModel = OrderModel.fromJson(response.body);
    }else {
      Navigator.pop(Get.context!);
      await Get.find<OrderController>().getCurrentOrders();
    }
    update();
  }

  Future<void> getCompletedOrders(int offset, {bool willUpdate = true}) async {
    if(offset == 1) {
      _offsetList = [];
      _offset = 1;
      _completedOrderList = null;
      if(willUpdate) {
        update();
      }
    }
    if (!_offsetList.contains(offset)) {
      _offsetList.add(offset);
      PaginatedOrderModel? paginatedOrderModel = await orderServiceInterface.getCompletedOrderList(offset);
      if (paginatedOrderModel != null) {
        if (offset == 1) {
          _completedOrderList = [];
        }
        _completedOrderList!.addAll(paginatedOrderModel.orders!);
        _pageSize = paginatedOrderModel.totalSize;
        _paginate = false;
        update();
      }
    } else {
      if(_paginate) {
        _paginate = false;
        update();
      }
    }
  }

  void showBottomLoader() {
    _paginate = true;
    update();
  }

  void setOffset(int offset) {
    _offset = offset;
  }

  Future<void> getCurrentOrders() async {
    List<OrderModel>? currentOrderList = await orderServiceInterface.getCurrentOrders();
    if(currentOrderList != null) {
      _currentOrderList = [];
      _currentOrderList!.addAll(currentOrderList);
    }
    update();
  }

  Future<void> getLatestOrders() async {
    List<OrderModel>? latestOrderList = await orderServiceInterface.getLatestOrders();
    if(latestOrderList != null) {
      _latestOrderList = [];
      List<int?> ignoredIdList = orderServiceInterface.prepareIgnoreIdList(_ignoredRequests);
      _latestOrderList!.addAll(orderServiceInterface.processLatestOrders(latestOrderList, ignoredIdList));
    }
    update();
  }

  Future<bool> updateOrderStatus(
  OrderModel currentOrder,
  String status, {
  bool back = false,
  String? reason,
  bool? parcel = false,
  bool gotoDashboard = false,
}) async {
  _isLoading = true;
  update();

  List<MultipartBody> multiParts =
      orderServiceInterface.prepareOrderProofImages(_pickedPrescriptions);

  String? otpToSend;
  if (_otp.isNotEmpty) {
    otpToSend = _otp;
    print('Enviando OTP: $otpToSend para o pedido ${currentOrder.id}');
  } else {
    print('OTP não fornecido para o pedido ${currentOrder.id}');
  }

  UpdateStatusBodyModel updateStatusBody = UpdateStatusBodyModel(
    orderId: currentOrder.id,
    status: status,
    reason: reason,
    otp: otpToSend,
  );

  print('Atualizando status do pedido ${currentOrder.id} para $status');

  ResponseModel responseModel =
      await orderServiceInterface.updateOrderStatus(updateStatusBody, multiParts);

  Get.back(result: responseModel.isSuccess);

  if (responseModel.isSuccess) {

    // ✅ LIMPA NOTIFICAÇÃO FIXA "EM CORRIDA" QUANDO FINALIZA
    if (status == 'delivered' ||
        status == 'failed' ||
        status == 'canceled' ||
        status == 'refunded') {
      try {
        await NotificationHelper.clearRunningOrderOngoing(flutterLocalNotificationsPlugin);
      } catch (_) {}
    }

    if (back) {
      Get.back();
    }
    if (gotoDashboard) {
      Get.offAllNamed(RouteHelper.getInitialRoute(fromOrderDetails: true));
    }

    Get.find<ProfileController>().getProfile();
    getCurrentOrders();
    currentOrder.orderStatus = status;
    showCustomSnackBar(responseModel.message, isError: false);

  } else {
    showCustomSnackBar(responseModel.message, isError: true);
  }

  _isLoading = false;
  update();
  return responseModel.isSuccess;
}


  Future<bool> markStopDelivered(int stopId) async {
    _isLoading = true;
    update();
    final result = await orderServiceInterface.markStopDelivered(stopId);
    _isLoading = false;
    update();
    if (result.isSuccess) {
      return true;
    } else {
      debugPrint('markStopDelivered error: ${result.message}');
      showCustomSnackBar('Erro ao concluir parada: ${result.message}', isError: true);
      return false;
    }
  }

  Future<void> getOrderDetails(int? orderID, bool parcel) async {
    if(parcel) {
      _orderDetailsModel = [];
    }else {
      _orderDetailsModel = null;
      List<OrderDetailsModel>? orderDetailsModel = await orderServiceInterface.getOrderDetails(orderID);
      if(orderDetailsModel != null) {
        _orderDetailsModel = [];
        _orderDetailsModel!.addAll(orderDetailsModel);
      }
      update();
    }
  }

  Future<bool> acceptOrder(int? orderID, int index, OrderModel orderModel) async {
    _isLoading = true;
    update();
    ResponseModel responseModel = await orderServiceInterface.acceptOrder(orderID);
    Get.back();
    if(responseModel.isSuccess) {
      _latestOrderList!.removeAt(index);
      _currentOrderList!.add(orderModel);
    }else {
      showCustomSnackBar(responseModel.message, isError: true);
    }
    _isLoading = false;
    update();
    return responseModel.isSuccess;
  }


  Future<bool> acceptOrderById(int orderId) async {
    _isLoading = true;
    update();

    final ResponseModel responseModel = await orderServiceInterface.acceptOrder(orderId);

    if (responseModel.isSuccess) {
      // Recarrega listas para refletir o aceite
      await getLatestOrders();
      await getCurrentOrders();

    } else {
      showCustomSnackBar(responseModel.message, isError: true);
    }

    _isLoading = false;
    update();
    return responseModel.isSuccess;
  }

  Future<bool> ignoreOrderById(int orderId) async {
    _isLoading = true;
    update();

    // IMPORTANTÍSSIMO:
    // Você precisa ter um endpoint/serviço para "ignorar/recusar".
    // Se já existir no seu orderServiceInterface, use ele aqui.
    // Exemplo: orderServiceInterface.ignoreOrder(orderId)
    //final ResponseModel responseModel = await orderServiceInterface.ignoreOrder(orderId);

    // if (responseModel.isSuccess) {
    //   await getLatestOrders();
    // } else {
    //   showCustomSnackBar(responseModel.message, isError: true);
    // }

    _isLoading = false;
    update();
    return true;
  }


  void getIgnoreList() {
    _ignoredRequests = [];
    _ignoredRequests.addAll(orderServiceInterface.getIgnoreList());
  }

  void ignoreOrder(int index) {
    _ignoredRequests.add(IgnoreModel(id: _latestOrderList![index].id, time: DateTime.now()));
    _latestOrderList!.removeAt(index);
    orderServiceInterface.setIgnoreList(_ignoredRequests);
    update();
  }

  void removeFromIgnoreList() {
    List<IgnoreModel> tempList = orderServiceInterface.tempList(Get.find<SplashController>().currentTime, _ignoredRequests);
    _ignoredRequests = [];
    _ignoredRequests.addAll(tempList);
    orderServiceInterface.setIgnoreList(_ignoredRequests);
  }

  void setOtp(String otp) {
    _otp = otp;
    if(otp != '') {
      update();
    }
  }
  
}