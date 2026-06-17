import 'dart:async';
import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:sixam_mart_delivery/features/language/controllers/language_controller.dart';
import 'package:sixam_mart_delivery/features/notification/controllers/notification_controller.dart';
import 'package:sixam_mart_delivery/features/order/controllers/order_controller.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart_delivery/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart_delivery/features/chat/domain/models/conversation_model.dart';
import 'package:sixam_mart_delivery/features/order/domain/models/order_details_model.dart';
import 'package:sixam_mart_delivery/features/order/domain/models/order_model.dart';
import 'package:sixam_mart_delivery/helper/price_converter_helper.dart';
import 'package:sixam_mart_delivery/helper/responsive_helper.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/util/app_constants.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/images.dart';
import 'package:sixam_mart_delivery/util/styles.dart';
import 'package:sixam_mart_delivery/common/widgets/confirmation_dialog_widget.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_app_bar_widget.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_button_widget.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_image_widget.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_snackbar_widget.dart';
import 'package:sixam_mart_delivery/features/order/widgets/camera_button_sheet_widget.dart';
import 'package:sixam_mart_delivery/features/order/widgets/cancellation_dialogue_widget.dart';
import 'package:sixam_mart_delivery/features/order/widgets/collect_money_delivery_sheet_widget.dart';
import 'package:sixam_mart_delivery/features/order/widgets/order_item_widget.dart';
import 'package:sixam_mart_delivery/features/order/widgets/verify_delivery_sheet_widget.dart';
import 'package:sixam_mart_delivery/features/chat/screens/chat_screen.dart';
import 'package:sixam_mart_delivery/features/order/widgets/info_card_widget.dart';
import 'package:sixam_mart_delivery/features/order/widgets/slider_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailsScreen extends StatefulWidget {
  final int? orderId;
  final bool? isRunningOrder;
  final int? orderIndex;
  final bool fromNotification;
  final bool fromLocationScreen;
  const OrderDetailsScreen({super.key, required this.orderId, required this.isRunningOrder, required this.orderIndex,
    this.fromNotification = false, this.fromLocationScreen = false});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> with WidgetsBindingObserver {
  Timer? _timer;
  final Set<int> _completedStopIds = {};
  final PageController _stopsPageController = PageController();

  void _startApiCalling(){
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      Get.find<OrderController>().getOrderWithId(widget.orderId!);
    });
  }

  Future<void> _loadData() async {
    Get.find<OrderController>().pickPrescriptionImage(isRemove: true, isCamera: false);
    await Get.find<OrderController>().getOrderWithId(widget.orderId);
    Get.find<OrderController>().getOrderDetails(widget.orderId, Get.find<OrderController>().orderModel!.orderType == 'parcel');
    await Get.find<OrderController>().getLatestOrders();
    if(Get.find<OrderController>().showDeliveryImageField){
      Get.find<OrderController>().changeDeliveryImageStatus(isUpdate: false);
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _loadData();
    _startApiCalling();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if(state == AppLifecycleState.paused) {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopsPageController.dispose();
    super.dispose();
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {

    bool? cancelPermission = Get.find<SplashController>().configModel!.canceledByDeliveryman;
    bool selfDelivery = Get.find<ProfileController>().profileModel!.type != 'zone_wise';

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async{
        if((widget.fromNotification || widget.fromLocationScreen)) {
          Future.delayed(const Duration(milliseconds: 0), () async {
            await Get.offAllNamed(RouteHelper.getInitialRoute());
          });
        } else {
          return;
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).cardColor,
        appBar: CustomAppBarWidget(title: 'order_details'.tr, onBackPressed: (){
        if(widget.fromNotification || widget.fromLocationScreen) {
            Get.offAllNamed(RouteHelper.getInitialRoute());
          } else {
            Get.back();
          }
        }),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: GetBuilder<OrderController>(builder: (orderController) {

              OrderModel? controllerOrderModel = orderController.orderModel;

              bool restConfModel = Get.find<SplashController>().configModel!.orderConfirmationModel != 'deliveryman';

              bool? parcel, processing, accepted, confirmed, handover, pickedUp, cod, wallet, partialPay, offlinePay;
              
              bool orderVerificationActive = Get.find<SplashController>().configModel?.orderDeliveryVerification ?? false;

              late bool showBottomView;
              late bool showSlider;
              bool showDeliveryConfirmImage = false;

              double? deliveryCharge = 0;
              double itemsPrice = 0;
              double? discount = 0;
              double? couponDiscount = 0;
              double? tax = 0;
              double addOns = 0;
              double? dmTips = 0;
              double additionalCharge = 0;
              double extraPackagingAmount = 0;
              double referrerBonusAmount = 0;
              bool? isPrescriptionOrder = false;
              bool? taxIncluded = false;
              bool showChatPermission = true;
              OrderModel? order = controllerOrderModel;
              if(order != null && orderController.orderDetailsModel != null) {
                deliveryCharge = order.deliveryCharge;
                dmTips = order.dmTips;
                isPrescriptionOrder = order.prescriptionOrder;
                discount = order.storeDiscountAmount! + order.flashAdminDiscountAmount! + order.flashStoreDiscountAmount!;
                tax = order.totalTaxAmount;
                taxIncluded = order.taxStatus;
                additionalCharge = order.additionalCharge!;
                extraPackagingAmount = order.extraPackagingAmount!;
                referrerBonusAmount = order.referrerBonusAmount!;
                couponDiscount = order.couponDiscountAmount;
                if(isPrescriptionOrder!){
                  double orderAmount = order.orderAmount ?? 0;
                  itemsPrice = (orderAmount + discount) - ((taxIncluded! ? 0 : tax!) + deliveryCharge! + additionalCharge) - dmTips!;
                }else {
                  for (OrderDetailsModel orderDetails in orderController.orderDetailsModel!) {
                    for (AddOn addOn in orderDetails.addOns!) {
                      addOns = addOns + (addOn.price! * addOn.quantity!);
                    }
                    itemsPrice = itemsPrice + (orderDetails.price! * orderDetails.quantity!);
                  }
                }

                if (order.storeBusinessModel == 'commission') {
                  showChatPermission = true;
                } else if (order.storeBusinessModel == 'subscription') {
                  showChatPermission = order.storeChatPermission == 1;
                } else {
                  showChatPermission = true;
                }
              }
              double subTotal = itemsPrice + addOns;
              double total = itemsPrice + addOns - discount+ (taxIncluded! ? 0 : tax!) + deliveryCharge! - couponDiscount! + dmTips! + additionalCharge + extraPackagingAmount - referrerBonusAmount;

              if(controllerOrderModel != null){
                parcel = controllerOrderModel.orderType == 'parcel';
                processing = controllerOrderModel.orderStatus == AppConstants.processing;
                accepted = controllerOrderModel.orderStatus == AppConstants.accepted;
                confirmed = controllerOrderModel.orderStatus == AppConstants.confirmed;
                handover = controllerOrderModel.orderStatus == AppConstants.handover;
                pickedUp = controllerOrderModel.orderStatus == AppConstants.pickedUp;
                cod = controllerOrderModel.paymentMethod == 'cash_on_delivery';
                wallet = controllerOrderModel.paymentMethod == 'wallet';
                partialPay = controllerOrderModel.paymentMethod == 'partial_payment';
                offlinePay = controllerOrderModel.paymentMethod == 'offline_payment';

                showDeliveryConfirmImage = pickedUp && Get.find<SplashController>().configModel!.dmPictureUploadStatus!;
                bool restConfModel = Get.find<SplashController>().configModel!.orderConfirmationModel != 'deliveryman';
                showBottomView = (parcel && accepted) || accepted || confirmed || processing || handover
                    || pickedUp || (widget.isRunningOrder ?? true);
                showSlider = (cod && accepted && !restConfModel && !selfDelivery) || handover || pickedUp
                    || (parcel && accepted);
              }

              return (orderController.orderDetailsModel != null && controllerOrderModel != null) ? Column(children: [

                Expanded(child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(children: [

                    Row(children: [
                      Text('${parcel! ? 'delivery_id'.tr : 'order_id'.tr}:', style: robotoRegular),
                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                      Text(controllerOrderModel.id.toString(), style: robotoMedium),
                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                      const Expanded(child: SizedBox()),
                      Container(height: 7, width: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green)),
                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                      Text(
                        controllerOrderModel.orderStatus!.tr,
                        style: robotoRegular,
                      ),
                    ]),
                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    Row(children: [
                      Text('${parcel ? 'charge_payer'.tr : 'item'.tr}:', style: robotoRegular),
                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                      Text(
                        parcel ? controllerOrderModel.chargePayer!.tr : orderController.orderDetailsModel!.length.toString(),
                        style: robotoMedium.copyWith(color: Theme.of(context).primaryColor),
                      ),
                      const Expanded(child: SizedBox()),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
                        decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                        child: Text(
                          cod! ? 'cod'.tr : wallet! ? 'wallet'.tr : partialPay! ? 'partially_pay'.tr : offlinePay! ? 'offline_payment'.tr : 'digitally_paid'.tr,
                          style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).primaryColor),
                        ),
                      ),
                    ]),

                    orderController.orderDetailsModel!.isNotEmpty && orderController.orderDetailsModel![0].itemDetails != null && orderController.orderDetailsModel![0].itemDetails!.moduleType == 'food'
                    ? Column(children: [
                      const Divider(height: Dimensions.paddingSizeLarge),

                      Row(children: [
                        Text('${'cutlery'.tr}: ', style: robotoRegular),
                        const Expanded(child: SizedBox()),

                        Text(
                          controllerOrderModel.cutlery! ? 'yes'.tr : 'no'.tr,
                          style: robotoRegular,
                        ),
                      ]),
                    ]) : const SizedBox(),

                    controllerOrderModel.unavailableItemNote != null ? Column(
                      children: [
                        const Divider(height: Dimensions.paddingSizeLarge),

                        Row(children: [
                          Text('${'unavailable_item_note'.tr}: ', style: robotoMedium),

                          Text(
                            controllerOrderModel.unavailableItemNote!,
                            style: robotoRegular,
                          ),
                        ]),
                      ],
                    ) : const SizedBox(),

                    controllerOrderModel.deliveryInstruction != null ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Divider(height: Dimensions.paddingSizeLarge),
                      RichText(
                        textAlign: TextAlign.start,
                        text: TextSpan(
                            text: '${'delivery_instruction'.tr}: ',
                            style: robotoMedium.copyWith(color: Theme.of(context).textTheme.bodyMedium!.color),
                            children: <TextSpan>[
                              TextSpan(text: controllerOrderModel.deliveryInstruction!,
                                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)
                              )
                            ]
                        ),
                      ),
                    ]) : const SizedBox(),
                    SizedBox(height: controllerOrderModel.deliveryInstruction != null ? Dimensions.paddingSizeSmall : 0),

                    const Divider(height: Dimensions.paddingSizeLarge),
                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    InfoCardWidget(
                      title: 'Detalhes do remetente ',
                      boldSuffix: '(Loja)',
                      address: parcel ? controllerOrderModel.deliveryAddress : DeliveryAddress(address: controllerOrderModel.storeAddress),
                      image: parcel ? '' : '${controllerOrderModel.storeLogoFullUrl}',
                      name: parcel ? controllerOrderModel.deliveryAddress!.contactPersonName : controllerOrderModel.storeName,
                      phone: parcel ? controllerOrderModel.deliveryAddress!.contactPersonNumber : controllerOrderModel.storePhone,
                      latitude: parcel ? controllerOrderModel.deliveryAddress!.latitude : controllerOrderModel.storeLat,
                      longitude: parcel ? controllerOrderModel.deliveryAddress!.longitude : controllerOrderModel.storeLng,
                      showButton: (controllerOrderModel.orderStatus != 'delivered' && controllerOrderModel.orderStatus != 'failed'
                          && controllerOrderModel.orderStatus != 'canceled' && controllerOrderModel.orderStatus != 'refunded'),
                      isStore: true, isChatAllow: true,
                      messageOnTap: () {
                        final int? orderIdForChat = widget.orderId ?? controllerOrderModel.id;
                        Get.to(() => ChatScreen(
                          notificationBody: NotificationBodyModel(
                            notificationType: NotificationType.message,
                            type: AppConstants.vendor,
                            orderId: orderIdForChat,
                          ),
                          user: User(
                            fName: controllerOrderModel.storeName,
                            imageFullUrl: controllerOrderModel.storeLogoFullUrl,
                          ),
                        ));
                      },
                      order: order!,
                    ),
                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    InfoCardWidget(
                      title: parcel ? 'receiver_details'.tr : 'Detalhes do destinatário ',
                      boldSuffix: parcel ? null : '(cliente)',
                      address: parcel ? controllerOrderModel.receiverDetails : controllerOrderModel.deliveryAddress,
                      image: parcel ? '' : controllerOrderModel.customer != null ? '${controllerOrderModel.customer!.imageFullUrl}' : '',
                      name: parcel ? controllerOrderModel.receiverDetails!.contactPersonName : controllerOrderModel.deliveryAddress!.contactPersonName,
                      phone: parcel ? controllerOrderModel.receiverDetails!.contactPersonNumber : controllerOrderModel.deliveryAddress!.contactPersonNumber,
                      latitude: parcel ? controllerOrderModel.receiverDetails!.latitude : controllerOrderModel.deliveryAddress!.latitude,
                      longitude: parcel ? controllerOrderModel.receiverDetails!.longitude : controllerOrderModel.deliveryAddress!.longitude,
                      showButton: controllerOrderModel.orderStatus != 'delivered' && controllerOrderModel.orderStatus != 'failed'
                          && controllerOrderModel.orderStatus != 'canceled' && controllerOrderModel.orderStatus != 'refunded',
                      isStore: parcel ? false : true, isChatAllow: showChatPermission,
                      messageOnTap: () => Get.toNamed(RouteHelper.getChatRoute(
                        notificationBody: NotificationBodyModel(
                          orderId: controllerOrderModel.id, customerId: controllerOrderModel.customer!.id,
                        ),
                        user: User(
                          id: controllerOrderModel.customer!.id, fName: controllerOrderModel.customer!.fName,
                          lName: controllerOrderModel.customer!.lName, imageFullUrl: controllerOrderModel.customer!.imageFullUrl,
                        ),
                      )),
                      order: order,
                    ),
                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    // ── Paradas adicionais (parcel) ───────────────────────
                    if (parcel! && controllerOrderModel.hasAdditionalStops) ...[
                      Container(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                          border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Icon(Icons.add_location_alt, size: 16, color: Theme.of(context).primaryColor),
                              const SizedBox(width: 6),
                              Text('Paradas adicionais', style: robotoMedium.copyWith(color: Theme.of(context).primaryColor)),
                            ]),
                            const SizedBox(height: Dimensions.paddingSizeSmall),
                            ...controllerOrderModel.additionalStops!.map((stop) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Container(
                                    width: 24, height: 24,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: stop.status == 'delivered'
                                          ? Colors.green
                                          : Theme.of(context).primaryColor,
                                    ),
                                    child: stop.status == 'delivered'
                                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                                        : Text('${stop.sequence}', style: robotoMedium.copyWith(fontSize: 11, color: Colors.white)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    if (stop.addressText.isNotEmpty)
                                      Text(
                                        stop.addressText,
                                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                                        maxLines: 2, overflow: TextOverflow.ellipsis,
                                      ),
                                    if (stop.houseText.isNotEmpty)
                                      Text(
                                        'Casa/Nº: ${stop.houseText}',
                                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor),
                                      ),
                                    if (stop.contactName != null && stop.contactName!.isNotEmpty)
                                      Text(
                                        stop.contactName!,
                                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor),
                                      ),
                                    const SizedBox(height: 2),
                                    Row(children: [
                                      Icon(Icons.straighten, size: 12, color: Theme.of(context).disabledColor),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${stop.distanceKm?.toStringAsFixed(2) ?? '—'} km',
                                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor),
                                      ),
                                      if ((stop.extraDeliveryCharge ?? 0) > 0) ...[
                                        const SizedBox(width: 10),
                                        Icon(Icons.attach_money, size: 12, color: Colors.orange[700]),
                                        Text(
                                          'Taxa: ${PriceConverterHelper.convertPrice(stop.extraDeliveryCharge)}',
                                          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Colors.orange[700]),
                                        ),
                                      ],
                                      const Spacer(),
                                      if (stop.status == 'delivered')
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text('Entregue', style: robotoRegular.copyWith(fontSize: 10, color: Colors.green)),
                                        ),
                                    ]),
                                    if (stop.status != 'delivered') Row(children: [
                                      if (stop.contactPhone != null && stop.contactPhone!.isNotEmpty)
                                        TextButton.icon(
                                          onPressed: () async {
                                            final uri = Uri.parse('tel:${stop.contactPhone}');
                                            if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                                          },
                                          icon: Icon(Icons.call, color: Theme.of(context).primaryColor, size: 16),
                                          label: Text('Ligar', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).primaryColor)),
                                          style: TextButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                        ),
                                      if (stop.latitude != null && stop.longitude != null)
                                        TextButton.icon(
                                          onPressed: () async {
                                            final url = 'https://www.google.com/maps/dir/?api=1&destination=${stop.latitude},${stop.longitude}&mode=d';
                                            final uri = Uri.parse(url);
                                            if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                                          },
                                          icon: Icon(Icons.directions, color: Theme.of(context).disabledColor, size: 16),
                                          label: Text('Direção', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor)),
                                          style: TextButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                        ),
                                    ]),
                                  ])),
                                ]),
                                if (stop != controllerOrderModel.additionalStops!.last)
                                  Divider(height: 8, color: Theme.of(context).dividerColor),
                              ]),
                            )),
                          ],
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeLarge),
                    ],

                    parcel ? Container(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                        boxShadow: Get.isDarkMode ? null : [BoxShadow(color: Colors.grey[200]!, spreadRadius: 1, blurRadius: 5)],
                      ),
                      child: controllerOrderModel.parcelCategory != null ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('parcel_category'.tr, style: robotoRegular),
                        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                        Row(children: [
                          ClipOval(child: CustomImageWidget(
                            image: '${controllerOrderModel.parcelCategory!.imageFullUrl}',
                            height: 35, width: 35, fit: BoxFit.cover,
                          )),
                          const SizedBox(width: Dimensions.paddingSizeSmall),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(
                              controllerOrderModel.parcelCategory!.name!, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                            ),
                            Text(
                              controllerOrderModel.parcelCategory!.description!, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                            ),
                          ])),
                        ]),
                      ]) : SizedBox(
                        width: context.width,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('parcel_category'.tr, style: robotoRegular),
                          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                          Text('no_parcel_category_data_found'.tr, style: robotoMedium),
                        ]),
                      ),
                    ) : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: orderController.orderDetailsModel!.length,
                      itemBuilder: (context, index) {
                        return OrderItemWidget(order: controllerOrderModel, orderDetails: orderController.orderDetailsModel![index]);
                      },
                    ),

                    (controllerOrderModel.orderNote != null && controllerOrderModel.orderNote!.isNotEmpty) ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('additional_note'.tr, style: robotoRegular),
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      Container(
                        width: 1170,
                        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(width: 1, color: Theme.of(context).disabledColor),
                        ),
                        child: Text(
                          controllerOrderModel.orderNote!,
                          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                        ),
                      ),
                    ]) : const SizedBox(),
                    SizedBox(height: (controllerOrderModel.orderNote != null && controllerOrderModel.orderNote!.isNotEmpty) ? Dimensions.paddingSizeLarge : 0),

                    (Get.find<SplashController>().getModule(controllerOrderModel.moduleType).orderAttachment!
                        && controllerOrderModel.orderAttachmentFullUrl != null && controllerOrderModel.orderAttachmentFullUrl!.isNotEmpty)
                        ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('prescription'.tr, style: robotoRegular),
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          childAspectRatio: 1.5,
                          crossAxisCount: ResponsiveHelper.isTab(context) ? 5 : 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 5,
                        ),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controllerOrderModel.orderAttachmentFullUrl!.length,
                        itemBuilder: (BuildContext context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () => openDialog(context, controllerOrderModel.orderAttachmentFullUrl![index]),
                              child: Center(child: ClipRRect(
                                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                child: CustomImageWidget(
                                  image: controllerOrderModel.orderAttachmentFullUrl![index],
                                  width: 100, height: 100,
                                ),
                              )),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: Dimensions.paddingSizeLarge),
                    ]) : const SizedBox(),

                    (controllerOrderModel.orderStatus == 'delivered' && controllerOrderModel.orderProofFullUrl != null
                    && controllerOrderModel.orderProofFullUrl!.isNotEmpty) ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      Text('order_proof'.tr, style: robotoRegular),
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            childAspectRatio: 1.5,
                            crossAxisCount: ResponsiveHelper.isTab(context) ? 5 : 3,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 5,
                          ),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controllerOrderModel.orderProofFullUrl!.length,
                          itemBuilder: (BuildContext context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                onTap: () => openDialog(context, controllerOrderModel.orderProofFullUrl![index]),
                                child: Center(child: ClipRRect(
                                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                  child: CustomImageWidget(
                                    image: controllerOrderModel.orderProofFullUrl![index],
                                    width: 100, height: 100,
                                  ),
                                )),
                              ),
                            );
                          }),

                      const SizedBox(height: Dimensions.paddingSizeLarge),
                    ]) : const SizedBox(),
                    const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                    !parcel ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('item_price'.tr, style: robotoRegular),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(PriceConverterHelper.convertPrice(itemsPrice), style: robotoRegular),
                      ]),
                    ]) : const SizedBox(),
                    SizedBox(height: !parcel ? 10 : 0),

                    Get.find<SplashController>().getModuleConfig(order.moduleType).addOn! ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('addons'.tr, style: robotoRegular),
                        Text('(+) ${PriceConverterHelper.convertPrice(addOns)}', style: robotoRegular),
                      ],
                    ) : const SizedBox(),

                    Get.find<SplashController>().getModuleConfig(order.moduleType).addOn! ? Divider(
                      thickness: 1, color: Theme.of(context).hintColor.withOpacity(0.5),
                    ) : const SizedBox(),

                    Get.find<SplashController>().getModuleConfig(order.moduleType).addOn! ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('subtotal'.tr, style: robotoMedium),
                        Text(PriceConverterHelper.convertPrice(subTotal), style: robotoMedium),
                      ],
                    ) : const SizedBox(),
                    SizedBox(height: Get.find<SplashController>().getModuleConfig(order.moduleType).addOn! ? 10 : 0),

                    !parcel ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('discount'.tr, style: robotoRegular),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('(-) ${PriceConverterHelper.convertPrice(discount)}', style: robotoRegular),
                      ]),
                    ]) : const SizedBox(),
                    SizedBox(height: !parcel ? 10 : 0),

                    couponDiscount > 0 ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('coupon_discount'.tr, style: robotoRegular),
                      Text(
                        '(-) ${PriceConverterHelper.convertPrice(couponDiscount)}',
                        style: robotoRegular,
                      ),
                    ]) : const SizedBox(),
                    SizedBox(height: couponDiscount > 0 ? 10 : 0),

                    (referrerBonusAmount > 0) ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('referral_discount'.tr, style: robotoRegular),
                        Text('(-) ${PriceConverterHelper.convertPrice(referrerBonusAmount)}', style: robotoRegular),
                      ],
                    ) : const SizedBox(),
                    SizedBox(height: referrerBonusAmount > 0 ? 10 : 0),

                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('delivery_fee'.tr, style: robotoRegular),
                      Text('(+) ${PriceConverterHelper.convertPrice(deliveryCharge)}', style: robotoRegular),
                    ]),
                    // Breakdown paradas adicionais
                    if (parcel && controllerOrderModel.hasAdditionalStops) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Column(children: [
                          () {
                            final stops = controllerOrderModel.additionalStops!;
                            final totalStopCharge = stops.fold<double>(0, (s, e) => s + (e.extraDeliveryCharge ?? 0));
                            final baseCharge = (deliveryCharge ?? 0) - totalStopCharge;
                            return Column(children: [
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Text('  • Entrega principal', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor)),
                                Text(PriceConverterHelper.convertPrice(baseCharge), style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor)),
                              ]),
                              ...stops.map((s) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Text('  • Parada ${s.sequence}', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor)),
                                Text(PriceConverterHelper.convertPrice(s.extraDeliveryCharge ?? 0), style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor)),
                              ])),
                            ]);
                          }(),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('delivery_man_tips'.tr, style: robotoRegular),
                        Text('(+) ${PriceConverterHelper.convertPrice(dmTips)}', style: robotoRegular),
                      ],
                    ),
                    const SizedBox(height: 10),

                    (extraPackagingAmount > 0) ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('extra_packaging'.tr, style: robotoRegular),
                        Text('(+) ${PriceConverterHelper.convertPrice(extraPackagingAmount)}', style: robotoRegular),
                      ],
                    ) : const SizedBox(),
                    SizedBox(height: extraPackagingAmount > 0 ? 10 : 0),

                    (order.additionalCharge != null && order.additionalCharge! > 0) ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(Get.find<SplashController>().configModel!.additionalChargeName!, style: robotoRegular),
                      Text('(+) ${PriceConverterHelper.convertPrice(order.additionalCharge)}', style: robotoRegular, textDirection: TextDirection.ltr),
                    ]) : const SizedBox(),
                    (order.additionalCharge != null && order.additionalCharge! > 0) ? const SizedBox(height: 10) : const SizedBox(),

                    (tax! == 0) || taxIncluded ? const SizedBox() : Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('vat_tax'.tr, style: robotoRegular),
                      Text('(+) ${PriceConverterHelper.convertPrice(tax)}', style: robotoRegular),
                    ]),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                      child: Divider(thickness: 1, color: Theme.of(context).hintColor.withOpacity(0.5)),
                    ),

                    partialPay! ? DottedBorder(
                      color: Theme.of(context).primaryColor,
                      strokeWidth: 1,
                      strokeCap: StrokeCap.butt,
                      dashPattern: const [8, 5],
                      padding: const EdgeInsets.all(0),
                      borderType: BorderType.RRect,
                      radius: const Radius.circular(Dimensions.radiusDefault),
                      child: Ink(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                        color: !restConfModel ? Theme.of(context).primaryColor.withOpacity(0.05) : Colors.transparent,
                        child: Column(children: [

                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text('total_amount'.tr, style: robotoMedium.copyWith(
                              fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor,
                            )),
                            Text(
                              PriceConverterHelper.convertPrice(total),
                              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor),
                            ),
                          ]),
                          const SizedBox(height: 10),

                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text('paid_by_wallet'.tr, style: !restConfModel ? robotoMedium : robotoRegular),
                            Text(
                              PriceConverterHelper.convertPrice(order.payments![0].amount),
                              style: !restConfModel ? robotoMedium : robotoRegular,
                            ),
                          ]),
                          const SizedBox(height: 10),

                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text('${order.payments?[1].paymentStatus == 'paid' ? 'paid_by'.tr : 'due_amount'.tr} (${order.payments![1].paymentMethod?.tr})', style: !restConfModel ? robotoMedium : robotoRegular),
                            Text(
                              PriceConverterHelper.convertPrice(order.payments![1].amount),
                              style: !restConfModel ? robotoMedium : robotoRegular,
                            ),
                          ]),
                        ]),
                      ),
                    ) : const SizedBox(),
                    SizedBox(height: partialPay ? 20 : 0),

                    !partialPay ? Row(children: [
                      Text('total_amount'.tr, style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor,
                      )),

                      taxIncluded ? Text(' ${'vat_tax_inc'.tr}', style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).primaryColor,
                      )) : const SizedBox(),

                      const Expanded(child: SizedBox()),

                      Text(
                        PriceConverterHelper.convertPrice(total),
                        style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor),
                      ),
                    ]) : const SizedBox(),

                  ]),
                )),

                showDeliveryConfirmImage && controllerOrderModel.orderStatus != 'delivered' ? Container(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.05),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusDefault)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('completed_after_delivery_picture'.tr, style: robotoRegular),
                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    Container(
                      height: 80,
                      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: orderController.pickedPrescriptions.length+1,
                        itemBuilder: (context, index) {
                          XFile? file = index == orderController.pickedPrescriptions.length ? null : orderController.pickedPrescriptions[index];
                          if(index < 5 && index == orderController.pickedPrescriptions.length) {
                            return InkWell(
                              onTap: () {
                                if(GetPlatform.isIOS) {
                                  Get.find<OrderController>().pickPrescriptionImage(isRemove: false, isCamera: false);
                                }else {
                                  Get.bottomSheet(const CameraButtonSheetWidget());
                                }
                              },
                              child: Container(
                                height: 60, width: 60, alignment: Alignment.center, decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                              ),
                                child:  Icon(Icons.camera_alt_sharp, color: Theme.of(context).primaryColor, size: 32),
                              ),
                            );
                          }
                          return file != null ? Container(
                            margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                            ),
                            child: Stack(children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                child: GetPlatform.isWeb ? Image.network(
                                  file.path, width: 60, height: 60, fit: BoxFit.cover,
                                ) : Image.file(
                                  File(file.path), width: 60, height: 60, fit: BoxFit.cover,
                                ),
                              ),
                            ]),
                          ) : const SizedBox();
                        },
                      ),
                    ),
                  ]),
                ) : const SizedBox(),

                showDeliveryConfirmImage && controllerOrderModel.orderStatus != 'delivered' && !parcel ? CustomButtonWidget(
                  buttonText: 'complete_delivery'.tr,
                  onPressed: () {
                    if(orderVerificationActive){
                      Get.find<NotificationController>().sendDeliveredNotification(controllerOrderModel.id);

                      Get.bottomSheet(VerifyDeliverySheetWidget(
                        currentOrderModel: controllerOrderModel, verify: orderVerificationActive,
                        orderAmount: partialPay! ? controllerOrderModel.payments![1].amount!.toDouble() : controllerOrderModel.orderAmount,
                        cod: cod! || (partialPay && controllerOrderModel.payments![1].paymentMethod == 'cash_on_delivery'),
                      ), isScrollControlled: true).then((isSuccess) {

                        if(isSuccess && (cod! || (partialPay! && controllerOrderModel.payments![1].paymentMethod == 'cash_on_delivery'))){
                          Get.bottomSheet(CollectMoneyDeliverySheetWidget(
                            currentOrderModel: controllerOrderModel, verify: orderVerificationActive,
                            orderAmount: partialPay! ? controllerOrderModel.payments![1].amount!.toDouble() : controllerOrderModel.orderAmount,
                            cod: cod || (partialPay && controllerOrderModel.payments![1].paymentMethod == 'cash_on_delivery'),
                          ), isScrollControlled: true, isDismissible: false);
                        }
                      });
                    } else{
                      Get.bottomSheet(CollectMoneyDeliverySheetWidget(
                        currentOrderModel: controllerOrderModel, verify: orderVerificationActive,
                        orderAmount: partialPay! ? controllerOrderModel.payments![1].amount!.toDouble() : controllerOrderModel.orderAmount,
                        cod: cod! || (partialPay && controllerOrderModel.payments![1].paymentMethod == 'cash_on_delivery'),
                      ), isScrollControlled: true);
                    }

                  },
                ) : showBottomView ? ((accepted! && !parcel && (!cod || restConfModel || selfDelivery))
                 || processing! || confirmed!) ? Container(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    border: Border.all(width: 1, color: Get.isDarkMode ? Colors.grey[700]! : Colors.grey[200]!),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    processing! ? 'order_is_preparing'.tr : 'order_waiting_for_process'.tr,
                    style: robotoMedium,
                  ),
                ) : showSlider ? ((cod && accepted && !restConfModel && cancelPermission! && !selfDelivery)
                || (parcel && accepted && cancelPermission!)) ? Row(children: [

                  Expanded(child: TextButton(
                    onPressed: () {
                      orderController.setOrderCancelReason('');
                      Get.dialog(CancellationDialogueWidget(orderId: widget.orderId));
                    },
                    style: TextButton.styleFrom(
                      minimumSize: const Size(1170, 40), padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                        side: BorderSide(width: 1, color: Theme.of(context).textTheme.bodyLarge!.color!),
                      ),
                    ),
                    child: Text('cancel'.tr, textAlign: TextAlign.center, style: robotoRegular.copyWith(
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                      fontSize: Dimensions.fontSizeLarge,
                    )),
                  )),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Expanded(child: CustomButtonWidget(
                    buttonText: 'confirm'.tr, height: 40,
                    onPressed: () {
                      Get.dialog(ConfirmationDialogWidget(
                        icon: Images.warning, title: 'are_you_sure_to_confirm'.tr,
                        description: parcel! ? 'you_want_to_confirm_this_delivery'.tr : 'you_want_to_confirm_this_order'.tr,
                        onYesPressed: () {
                          if((orderVerificationActive || cod!) && !parcel!) {
                            orderController.updateOrderStatus(
                              controllerOrderModel, parcel ? AppConstants.handover : AppConstants.confirmed, back: widget.fromLocationScreen? false: true,
                              gotoDashboard: widget.fromLocationScreen? true: false,
                            );
                          }
                          else if(parcel! && cod! && controllerOrderModel.chargePayer != 'sender') {
                            orderController.updateOrderStatus(controllerOrderModel, AppConstants.handover);
                          }
                          else if(parcel && controllerOrderModel.chargePayer == 'sender' && cod!) {
                            orderController.updateOrderStatus(controllerOrderModel, AppConstants.handover);
                          }
                        },
                      ), barrierDismissible: false);
                    },
                  )),

                ]) : ((){
                  // Paradas adicionais pendentes (quando pickedUp em pedido parcel)
                  final pendingStops = (parcel == true && pickedUp == true && controllerOrderModel.hasAdditionalStops)
                      ? (controllerOrderModel.additionalStops!
                          .where((s) => !_completedStopIds.contains(s.id) && s.status != 'delivered')
                          .toList()
                          ..sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0)))
                      : <OrderAdditionalStop>[];

                  if (pendingStops.isNotEmpty) {
                    return Column(children: [
                      Container(
                        height: 8,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(pendingStops.length, (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).primaryColor.withOpacity(0.4),
                            ),
                          )),
                        ),
                      ),
                      SizedBox(
                        height: 170,
                        child: PageView.builder(
                          controller: _stopsPageController,
                          itemCount: pendingStops.length,
                          itemBuilder: (ctx, index) {
                            final stop = pendingStops[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                border: Border.all(color: Theme.of(context).primaryColor, width: 1.5),
                              ),
                              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Container(
                                    width: 28, height: 28,
                                    decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).primaryColor),
                                    child: Center(child: Text('${stop.sequence ?? index + 1}', style: robotoMedium.copyWith(color: Colors.white, fontSize: 12))),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(
                                    stop.addressText,
                                    style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                                    maxLines: 2, overflow: TextOverflow.ellipsis,
                                  )),
                                ]),
                                if (stop.houseText.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text('Complemento: ${stop.houseText}', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall)),
                                ],
                                if (stop.contactName != null) ...[
                                  const SizedBox(height: 4),
                                  Text('${stop.contactName}${stop.contactPhone != null ? ' • ${stop.contactPhone}' : ''}',
                                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall)),
                                ],
                                if (stop.distanceKm != null) ...[
                                  const SizedBox(height: 4),
                                  Text('${stop.distanceKm!.toStringAsFixed(1)} km',
                                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).primaryColor)),
                                ],
                                // Botões ligar/direção no carousel
                                Row(children: [
                                  if (stop.contactPhone != null && stop.contactPhone!.isNotEmpty)
                                    TextButton.icon(
                                      onPressed: () async {
                                        final uri = Uri.parse('tel:${stop.contactPhone}');
                                        if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                                      },
                                      icon: Icon(Icons.call, size: 14, color: Theme.of(context).primaryColor),
                                      label: Text('Ligar', style: robotoRegular.copyWith(fontSize: 11, color: Theme.of(context).primaryColor)),
                                      style: TextButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                    ),
                                  if (stop.latitude != null && stop.longitude != null)
                                    TextButton.icon(
                                      onPressed: () async {
                                        final url = 'https://www.google.com/maps/dir/?api=1&destination=${stop.latitude},${stop.longitude}&mode=d';
                                        final uri = Uri.parse(url);
                                        if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                                      },
                                      icon: Icon(Icons.directions, size: 14, color: Theme.of(context).disabledColor),
                                      label: Text('Direção', style: robotoRegular.copyWith(fontSize: 11, color: Theme.of(context).disabledColor)),
                                      style: TextButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                    ),
                                ]),
                                const Spacer(),
                                SizedBox(
                                  width: double.infinity,
                                  height: 36,
                                  child: ElevatedButton.icon(
                                    onPressed: orderController.isLoading ? null : () async {
                                      final ok = await Get.find<OrderController>().markStopDelivered(stop.id!);
                                      if (ok) {
                                        setState(() { _completedStopIds.add(stop.id!); });
                                      }
                                    },
                                    icon: const Icon(Icons.check_circle_outline, size: 16),
                                    label: Text('Concluir esta parada', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
                                    ),
                                  ),
                                ),
                              ]),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Deslize para ver as paradas (${pendingStops.length} restante${pendingStops.length != 1 ? 's' : ''})',
                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ]);
                  }

                  return SliderButton(
                  action: () {

                    if((cod! && accepted! && !restConfModel && !selfDelivery) || (parcel! && accepted!)) {

                      if(orderController.isLoading) {
                        orderController.initLoading();
                      }
                      Get.dialog(ConfirmationDialogWidget(
                        icon: Images.warning, title: 'are_you_sure_to_confirm'.tr,
                        description: parcel! ? 'you_want_to_confirm_this_delivery'.tr : 'you_want_to_confirm_this_order'.tr,
                        onYesPressed: () {
                          orderController.updateOrderStatus(
                            controllerOrderModel, parcel! ? AppConstants.handover : AppConstants.confirmed, back: widget.fromLocationScreen? false: true,
                            gotoDashboard: widget.fromLocationScreen? true: false
                          );
                        },
                      ), barrierDismissible: false);
                    } else if(handover!){
                      if(parcel && controllerOrderModel.chargePayer == 'sender' && cod){
                        Get.bottomSheet(VerifyDeliverySheetWidget(
                          currentOrderModel: controllerOrderModel, verify: false, isSetOtp: false,
                          orderAmount: controllerOrderModel.orderAmount, cod: cod, isSenderPay: true, isParcel: parcel,
                        ), isScrollControlled: true);
                      }else {
                        if(Get.find<ProfileController>().profileModel!.active == 1) {
                          Get.find<OrderController>().updateOrderStatus(controllerOrderModel, AppConstants.pickedUp, back: widget.fromLocationScreen? false: true,
                          gotoDashboard: widget.fromLocationScreen? true: false);
                        }else {
                          showCustomSnackBar('make_yourself_online_first'.tr);
                        }
                      }
                    } else if(parcel && pickedUp!){
                      if(orderVerificationActive && controllerOrderModel.chargePayer != 'sender' && cod) {
                        Get.bottomSheet(VerifyDeliverySheetWidget(
                          currentOrderModel: controllerOrderModel, verify: orderVerificationActive,
                          orderAmount: controllerOrderModel.orderAmount, cod: cod, isParcel: parcel, isSenderPay: false,
                        ), isScrollControlled: true).then((value) {
                          if(value == 'show_price_view') {
                            Get.bottomSheet(VerifyDeliverySheetWidget(
                              currentOrderModel: controllerOrderModel, verify: false, isSetOtp: false,
                              orderAmount: controllerOrderModel.orderAmount, cod: cod, isSenderPay: false, isParcel: parcel,
                            ), isScrollControlled: true);
                          }
                        });
                      } else if(orderVerificationActive && controllerOrderModel.chargePayer == 'sender' && cod){
                        Get.bottomSheet(VerifyDeliverySheetWidget(
                          currentOrderModel: controllerOrderModel, verify: orderVerificationActive,
                          orderAmount: controllerOrderModel.orderAmount, cod: cod, isSenderPay: true, isParcel: parcel,
                        ), isScrollControlled: true).then((value) {
                          if(value == 'show_price_view') {
                            Get.bottomSheet(VerifyDeliverySheetWidget(
                              currentOrderModel: controllerOrderModel, verify: false, isSetOtp: false,
                              orderAmount: controllerOrderModel.orderAmount, cod: cod, isSenderPay: true, isParcel: parcel,
                            ), isScrollControlled: true);
                          }
                        });
                      }else if(orderVerificationActive){
                        Get.bottomSheet(VerifyDeliverySheetWidget(
                          currentOrderModel: controllerOrderModel, verify: orderVerificationActive,
                          orderAmount: controllerOrderModel.orderAmount, cod: cod,
                        ), isScrollControlled: true);
                      } else {
                        Get.find<OrderController>().updateOrderStatus(controllerOrderModel, AppConstants.delivered, back: widget.fromLocationScreen? false: true,
                        gotoDashboard: widget.fromLocationScreen? true: false);
                      }
                    }else if(!parcel && pickedUp!){
                      if(orderVerificationActive || cod){
                        Get.bottomSheet(VerifyDeliverySheetWidget(
                          currentOrderModel: controllerOrderModel, verify: orderVerificationActive,
                          orderAmount: controllerOrderModel.orderAmount, cod: cod,
                        ), isScrollControlled: true);
                      }
                      else {
                        Get.find<OrderController>().updateOrderStatus(controllerOrderModel, AppConstants.delivered, back: widget.fromLocationScreen? false: true,
                        gotoDashboard: widget.fromLocationScreen? true: false);
                      }
                    }

                    /*else if(pickedUp!) {
                      if(parcel && controllerOrderModel.chargePayer != 'sender') {
                        Get.bottomSheet(VerifyDeliverySheetWidget(
                          currentOrderModel: controllerOrderModel, verify: orderVerificationActive,
                          orderAmount: controllerOrderModel.orderAmount, cod: true, isParcel: parcel,
                        ), isScrollControlled: true).then((value) {
                          if(value == 'show_price_view') {
                            Get.bottomSheet(VerifyDeliverySheetWidget(
                              currentOrderModel: controllerOrderModel, verify: false, isSetOtp: false,
                              orderAmount: controllerOrderModel.orderAmount, cod: true, isSenderPay: false, isParcel: parcel,
                            ), isScrollControlled: true);
                          }
                        });
                      }
                      else if((orderVerificationActive || cod) && !parcel){
                        Get.bottomSheet(VerifyDeliverySheetWidget(
                          currentOrderModel: controllerOrderModel, verify: orderVerificationActive,
                          orderAmount: controllerOrderModel.orderAmount, cod: cod,
                        ), isScrollControlled: true);
                      }
                      else if(!cod && parcel && controllerOrderModel.chargePayer == 'sender'){
                        Get.bottomSheet(VerifyDeliverySheetWidget(
                          currentOrderModel: controllerOrderModel, verify: orderVerificationActive,
                          orderAmount: controllerOrderModel.orderAmount, cod: cod,
                        ), isScrollControlled: true);
                      }
                      else {
                        Get.find<OrderController>().updateOrderStatus(controllerOrderModel, AppConstants.delivered, back: widget.fromLocationScreen? false: true,
                          gotoDashboard: widget.fromLocationScreen? true: false);
                      }
                    }

                    else if(parcel && controllerOrderModel.chargePayer == 'sender' && cod){
                      Get.bottomSheet(VerifyDeliverySheetWidget(
                        currentOrderModel: controllerOrderModel, verify: orderVerificationActive,
                        orderAmount: controllerOrderModel.orderAmount, cod: cod, isSenderPay: true, isParcel: parcel,
                      ), isScrollControlled: true).then((value) {
                        if(value == 'show_price_view') {
                          Get.bottomSheet(VerifyDeliverySheetWidget(
                            currentOrderModel: controllerOrderModel, verify: false, isSetOtp: false,
                            orderAmount: controllerOrderModel.orderAmount, cod: cod, isSenderPay: true, isParcel: parcel,
                          ), isScrollControlled: true);
                        }
                      });
                    }

                    else if(handover!) {
                      if(Get.find<ProfileController>().profileModel!.active == 1) {
                        Get.find<OrderController>().updateOrderStatus(controllerOrderModel, AppConstants.pickedUp, back: widget.fromLocationScreen? false: true,
                          gotoDashboard: widget.fromLocationScreen? true: false);
                      }else {
                        showCustomSnackBar('make_yourself_online_first'.tr);
                      }
                    }*/

                  },
                  label: Text(
                    (parcel! && accepted!) ? 'swipe_to_confirm_delivery'.tr
                        : (cod! && accepted! && !restConfModel && !selfDelivery) ? 'swipe_to_confirm_order'.tr
                        : pickedUp! ? parcel! ? 'swipe_to_deliver_parcel'.tr
                        : 'swipe_to_deliver_order'.tr : handover! ? parcel! ? 'swipe_to_pick_up_parcel'.tr
                        : 'swipe_to_pick_up_order'.tr : '',
                    style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor),
                  ),
                  dismissThresholds: 0.5, dismissible: false, shimmer: true,
                  width: 1170, height: 60, buttonSize: 50, radius: 10,
                  icon: Center(child: Icon(
                    Get.find<LocalizationController>().isLtr ? Icons.double_arrow_sharp : Icons.keyboard_arrow_left,
                    color: Colors.white, size: 20.0,
                  )),
                  isLtr: Get.find<LocalizationController>().isLtr,
                  boxShadow: const BoxShadow(blurRadius: 0),
                  buttonColor: Theme.of(context).primaryColor,
                  backgroundColor: const Color(0xffF4F7FC),
                  baseColor: Theme.of(context).primaryColor,
                );
                })() : const SizedBox() : const SizedBox(),

              ]) : const Center(child: CircularProgressIndicator());
            }),
          ),
        ),
      ),
    );
  }

  void openDialog(BuildContext context, String imageUrl) => showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
        child: Stack(children: [

          ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            child: PhotoView(
              tightMode: true,
              imageProvider: NetworkImage(imageUrl),
              heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
            ),
          ),

          Positioned(top: 0, right: 0, child: IconButton(
            splashRadius: 5,
            onPressed: () => Get.back(),
            icon: const Icon(Icons.cancel, color: Colors.red),
          )),

        ]),
      );
    },
  );
}
