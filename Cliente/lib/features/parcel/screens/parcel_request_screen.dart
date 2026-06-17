import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:sixam_mart/features/checkout/widgets/guest_create_account.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/parcel/controllers/parcel_controller.dart';
import 'package:sixam_mart/features/parcel/domain/models/parcel_category_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/common/widgets/not_logged_in_screen.dart';
import 'package:sixam_mart/features/checkout/widgets/condition_check_box.dart';
import 'package:sixam_mart/features/payment/widgets/offline_payment_button.dart';
import 'package:sixam_mart/features/checkout/widgets/payment_button.dart';
import 'package:sixam_mart/features/checkout/widgets/tips_widget.dart';
import 'package:sixam_mart/features/parcel/widgets/card_widget.dart';
import 'package:sixam_mart/features/parcel/widgets/delivery_instruction_bottom_sheet_widget.dart';
import 'package:sixam_mart/features/parcel/widgets/details_widget.dart';
import 'package:sixam_mart/features/parcel/widgets/extra_delivery_dialog_widget.dart';

class ParcelRequestScreen extends StatefulWidget {
  final ParcelCategoryModel parcelCategory;
  final AddressModel pickedUpAddress;
  final AddressModel destinationAddress;

  const ParcelRequestScreen({
    super.key,
    required this.parcelCategory,
    required this.pickedUpAddress,
    required this.destinationAddress,
  });

  @override
  State<ParcelRequestScreen> createState() => _ParcelRequestScreenState();
}

class _ParcelRequestScreenState extends State<ParcelRequestScreen> {
  final TextEditingController _tipController = TextEditingController();
  final TextEditingController _guestPasswordController = TextEditingController();
  final TextEditingController _guestConfirmPasswordController = TextEditingController();
  final FocusNode _guestPasswordNode = FocusNode();
  final FocusNode _guestConfirmPasswordNode = FocusNode();
  bool _isLoggedIn = AuthHelper.isLoggedIn();
  bool? _isCashOnDeliveryActive = false;
  bool? _isDigitalPaymentActive = false;
  bool _isOfflinePaymentActive = false;
  bool canCheckSmall = false;
  final JustTheController tooltipController = JustTheController();

  /// Para não chamar o endpoint de frete repetidamente
  bool _requestedFeeOnce = false;

  /// NOVO: checkbox retorno
  bool _isReturnTrip = false;

  @override
  void initState() {
    super.initState();
    initCall();
  }

  void initCall() {
    final parcelController = Get.find<ParcelController>();

    parcelController.getOfflineMethodList();
    parcelController.getDmTipMostTapped();
    parcelController.setPaymentIndex(-1, false);
    parcelController.getDistance(widget.pickedUpAddress, widget.destinationAddress);
    parcelController.setPayerIndex(0, false);
    parcelController.startLoader(false, canUpdate: false);

    // RECOMENDADO: permite recalcular ao entrar de novo na tela
    _requestedFeeOnce = false;

    for (ZoneData zData in widget.pickedUpAddress.zoneData!) {
      if (zData.id == AddressHelper.getUserAddressFromSharedPref()!.zoneId) {
        _isCashOnDeliveryActive =
            zData.cashOnDelivery! && Get.find<SplashController>().configModel!.cashOnDelivery!;
        _isDigitalPaymentActive =
            zData.digitalPayment! && Get.find<SplashController>().configModel!.digitalPayment!;
        _isOfflinePaymentActive =
            zData.offlinePayment! && Get.find<SplashController>().configModel!.offlinePaymentStatus!;
        break;
      }
    }

    if (Get.find<ProfileController>().userInfoModel == null && _isLoggedIn) {
      Get.find<ProfileController>().getUserInfo();
    }

    parcelController.updateTips(
      Get.find<AuthController>().getDmTipIndex().isNotEmpty
          ? int.parse(Get.find<AuthController>().getDmTipIndex())
          : 0,
      notify: false,
    );

    if (Get.find<CheckoutController>().isCreateAccount) {
      Get.find<CheckoutController>().toggleCreateAccount(willUpdate: false);
    }

    parcelController.setInstructionselectedIndex(-1, notify: false);
    parcelController.setCustomNoteController('', notify: false);
    parcelController.setSelectedIndex(-1);
    parcelController.setCustomNote('');
  }

  String _parcelPrice(double value) {
    return PriceConverter.convertPrice(
      value,
      formatedStringPrice: value.toStringAsFixed(2),
    );
  }

  @override
  Widget build(BuildContext context) {
    _isLoggedIn = AuthHelper.isLoggedIn();
    bool isGuestLoggedIn = AuthHelper.isGuestLoggedIn();
    bool guestCheckoutPermission =
        AuthHelper.isGuestLoggedIn() && Get.find<SplashController>().configModel!.guestCheckoutStatus!;

    return Scaffold(
      appBar: CustomAppBar(title: 'parcel_request'.tr),
      endDrawer: const MenuDrawer(),
      endDrawerEnableOpenDragGesture: false,
      body: SafeArea(
        child: guestCheckoutPermission || _isLoggedIn
            ? GetBuilder<ParcelController>(builder: (parcelController) {
                // Usa addPostFrameCallback para nunca chamar update() durante o build
                if (!_requestedFeeOnce &&
                    parcelController.distance != null &&
                    parcelController.distance != -1) {
                  _requestedFeeOnce = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    parcelController.updateDeliveryFee(
                      categoryId: widget.parcelCategory.id!,
                      zoneId: widget.pickedUpAddress.zoneId!,
                      isReturn: _isReturnTrip,
                    );
                  });
                }

                // Se o cálculo terminou mas retornou erro (deliveryFee == null, não calculando),
                // reseta para tentar de novo no próximo rebuild
                if (_requestedFeeOnce &&
                    !parcelController.isCalculatingFee &&
                    parcelController.deliveryFee == null &&
                    parcelController.distance != null &&
                    parcelController.distance != -1) {
                  _requestedFeeOnce = false;
                }

                double charge = -1; // será o delivery_fee (do backend)
                double total = 0; // delivery_fee + gorjeta + taxa extra
                double dmTips = 0;
                double additionalCharge = Get.find<SplashController>().configModel!.additionalChargeStatus!
                    ? Get.find<SplashController>().configModel!.additionCharge!
                    : 0;

                if (parcelController.distance != -1 &&
                    parcelController.deliveryFee != null &&
                    parcelController.deliveryFee! >= 0) {
                  charge = parcelController.deliveryFee!;
                  dmTips = parcelController.tips;
                  total = charge +
                      dmTips +
                      additionalCharge +
                      parcelController.extraDeliveriesTotalFee;
                }

                return Column(children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: ResponsiveHelper.isDesktop(context)
                          ? null
                          : const EdgeInsets.all(Dimensions.paddingSizeSmall),
                      child: FooterView(
                        child: SizedBox(
                          width: Dimensions.webMaxWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ResponsiveHelper.isDesktop(context)
                                  ? const SizedBox(height: Dimensions.paddingSizeSmall)
                                  : const SizedBox(),

                              // 🔹 Card com categoria
                              DottedBorder(
                                color: Theme.of(context).disabledColor,
                                strokeWidth: 1.5,
                                dashPattern: const [5, 5],
                                borderType: BorderType.RRect,
                                radius: const Radius.circular(Dimensions.radiusDefault),
                                child: Container(
                                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                  ),
                                  child: Row(children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(200),
                                      child: CustomImage(
                                        image: '${widget.parcelCategory.imageFullUrl}',
                                        height: 60,
                                        width: 60,
                                      ),
                                    ),
                                    const SizedBox(width: Dimensions.paddingSizeSmall),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.parcelCategory.name!,
                                            style: robotoBold.copyWith(
                                              color: Theme.of(context).primaryColor,
                                            ),
                                          ),
                                          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                                          Text(
                                            widget.parcelCategory.description!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: robotoRegular.copyWith(
                                              color: Theme.of(context).disabledColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ]),
                                ),
                              ),
                              const SizedBox(height: Dimensions.paddingSizeSmall),

                              // 🔹 Detalhes remetente/destinatário
                              CardWidget(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    DetailsWidget(
                                      title: 'sender_details'.tr,
                                      address: widget.pickedUpAddress,
                                    ),
                                    const SizedBox(height: Dimensions.paddingSizeLarge),
                                    DetailsWidget(
                                      title: 'receiver_details'.tr,
                                      address: widget.destinationAddress,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: Dimensions.paddingSizeSmall),

                              // Botão "Adicionar entrega extra" (máx 2)
                              if (parcelController.extraDeliveries.length < 2 &&
                                  parcelController.distance != null &&
                                  parcelController.distance != -1)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: Dimensions.paddingSizeSmall),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(
                                        Dimensions.radiusDefault),
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) =>
                                            ExtraDeliveryDialogWidget(
                                          mainDistanceKm:
                                              parcelController.distance!,
                                          categoryId:
                                              widget.parcelCategory.id!,
                                          zoneId:
                                              widget.pickedUpAddress.zoneId!,
                                          pickupAddress:
                                              widget.pickedUpAddress,
                                        ),
                                      );
                                    },
                                    child: DottedBorder(
                                      color: Theme.of(context).primaryColor,
                                      strokeWidth: 1.5,
                                      dashPattern: const [6, 4],
                                      borderType: BorderType.RRect,
                                      radius: const Radius.circular(
                                          Dimensions.radiusDefault),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: Dimensions.paddingSizeSmall,
                                          horizontal:
                                              Dimensions.paddingSizeDefault,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                              Dimensions.radiusDefault),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_location_alt_outlined,
                                                color: Theme.of(context)
                                                    .primaryColor),
                                            const SizedBox(
                                                width: Dimensions
                                                    .paddingSizeExtraSmall),
                                            Text(
                                              'Adicionar entrega extra'
                                              '${parcelController.extraDeliveries.isEmpty ? '' : ' (${parcelController.extraDeliveries.length}/2)'}',
                                              style: robotoMedium.copyWith(
                                                color: Theme.of(context)
                                                    .primaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              // ── Lista de entregas extras adicionadas ───────
                              if (parcelController.extraDeliveries.isNotEmpty)
                                ...parcelController.extraDeliveries
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final i = entry.key;
                                  final extra = entry.value;
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: Dimensions.paddingSizeSmall),
                                    child: CardWidget(
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            color:
                                                Theme.of(context).primaryColor,
                                            size: 20,
                                          ),
                                          const SizedBox(
                                              width: Dimensions
                                                  .paddingSizeSmall),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Parada ${i + 1}: ${extra.address.address ?? ''}',
                                                  style: robotoMedium.copyWith(
                                                    fontSize: Dimensions
                                                        .fontSizeSmall,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                if (extra.houseNumber
                                                    .isNotEmpty)
                                                  Text(
                                                    'Nº ${extra.houseNumber}',
                                                    style: robotoRegular
                                                        .copyWith(
                                                      fontSize: Dimensions
                                                          .fontSizeExtraSmall,
                                                      color: Theme.of(context)
                                                          .hintColor,
                                                    ),
                                                  ),
                                                Text(
                                                  '${extra.distanceKm.toStringAsFixed(2)} km  •  ${_parcelPrice(extra.fee)}',
                                                  style: robotoRegular.copyWith(
                                                    fontSize: Dimensions
                                                        .fontSizeExtraSmall,
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline,
                                                color: Colors.red, size: 20),
                                            visualDensity:
                                                VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            constraints:
                                                const BoxConstraints(),
                                            onPressed: () => parcelController
                                                .removeExtraDelivery(i),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              // ──────────────────────────────────────────────
                              CardWidget(
                                child: CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  value: _isReturnTrip,
                                  activeColor: Theme.of(context).primaryColor,
                                  title: Text('Retorno (ida + volta)', style: robotoMedium),
                                  subtitle: Text(
                                    'Marque se o entregador precisa voltar ao ponto de origem.',
                                    style: robotoRegular.copyWith(color: Theme.of(context).hintColor),
                                  ),
                                  onChanged: (bool? v) {
                                    final newValue = v ?? false;

                                    setState(() {
                                      _isReturnTrip = newValue;
                                    });

                                    // Recalcula imediatamente
                                    parcelController.updateDeliveryFee(
                                      categoryId: widget.parcelCategory.id!,
                                      zoneId: widget.pickedUpAddress.zoneId!,
                                      isReturn: _isReturnTrip,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: Dimensions.paddingSizeSmall),

                              // 🔹 Distância + frete
                              CardWidget(
                                child: Row(children: [
                                  Expanded(
                                    child: Row(children: [
                                      Image.asset(Images.distance, height: 30, width: 30),
                                      const SizedBox(width: Dimensions.paddingSizeSmall),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('distance'.tr, style: robotoRegular),
                                          Text(
                                            parcelController.distance == -1
                                                ? 'calculating'.tr
                                                : '${parcelController.distance!.toStringAsFixed(2)} ${'km'.tr}',
                                            style: robotoBold.copyWith(
                                              color: Theme.of(context).primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ]),
                                  ),
                                  Expanded(
                                    child: Row(children: [
                                      Image.asset(Images.delivery, height: 30, width: 30),
                                      const SizedBox(width: Dimensions.paddingSizeSmall),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('delivery_fee'.tr, style: robotoRegular),
                                          if (parcelController.distance == -1 || parcelController.isCalculatingFee)
                                            Text('calculating'.tr, style: robotoBold.copyWith(color: Theme.of(context).primaryColor))
                                          else if (parcelController.deliveryFee == null)
                                            GestureDetector(
                                              onTap: () {
                                                setState(() { _requestedFeeOnce = false; });
                                                parcelController.updateDeliveryFee(
                                                  categoryId: widget.parcelCategory.id!,
                                                  zoneId: widget.pickedUpAddress.zoneId!,
                                                  isReturn: _isReturnTrip,
                                                );
                                              },
                                              child: Text('Tentar novamente', style: robotoBold.copyWith(color: Colors.red, fontSize: Dimensions.fontSizeSmall)),
                                            )
                                          else
                                            Text(
                                              _parcelPrice(charge + parcelController.extraDeliveriesTotalFee),
                                              style: robotoBold.copyWith(color: Theme.of(context).primaryColor),
                                              textDirection: TextDirection.ltr,
                                            ),
                                        ],
                                      ),
                                    ]),
                                  ),
                                ]),
                              ),
                              const SizedBox(height: Dimensions.paddingSizeDefault),

                              // 🔹 Instruções de entrega
                              CardWidget(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                                  child: Column(children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "add_more_delivery_instruction".tr,
                                          style: robotoMedium,
                                        ),
                                        InkWell(
                                          onTap: () {
                                            !ResponsiveHelper.isDesktop(context)
                                                ? Get.bottomSheet(
                                                    const DeliveryInstructionBottomSheetWidget(),
                                                    backgroundColor: Colors.transparent,
                                                    isScrollControlled: true,
                                                  )
                                                : showDialog(
                                                    context: context,
                                                    builder: (context) {
                                                      return const Dialog(
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.all(
                                                            Radius.circular(Dimensions.radiusDefault),
                                                          ),
                                                        ),
                                                        child: DeliveryInstructionBottomSheetWidget(),
                                                      );
                                                    },
                                                  );
                                          },
                                          child: const Padding(
                                            padding: EdgeInsets.only(left: Dimensions.paddingSizeDefault),
                                            child: Icon(CupertinoIcons.add, size: 20),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: parcelController.selectedIndexNote != -1 ||
                                              parcelController.customNote!.isNotEmpty
                                          ? Dimensions.paddingSizeSmall
                                          : 0,
                                    ),
                                    (parcelController.selectedIndexNote != -1 ||
                                            parcelController.customNote!.isNotEmpty)
                                        ? Row(children: [
                                            Image.asset(
                                              Images.parcelInstructionIcon,
                                              height: 30,
                                              width: 30,
                                            ),
                                            const SizedBox(width: Dimensions.paddingSizeSmall),
                                            Flexible(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  parcelController.selectedIndexNote != -1
                                                      ? Row(
                                                          children: [
                                                            Flexible(
                                                              child: Text(
                                                                parcelController
                                                                        .parcelInstructionList![parcelController.selectedIndexNote!]
                                                                        .instruction ??
                                                                    '',
                                                                style: robotoMedium.copyWith(
                                                                  color: Theme.of(context).primaryColor,
                                                                ),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                            const SizedBox(width: Dimensions.paddingSizeSmall),
                                                            InkWell(
                                                              onTap: () {
                                                                parcelController.setInstructionselectedIndex(-1, notify: false);
                                                                parcelController.setCustomNoteController('');
                                                                Get.find<ParcelController>().setSelectedIndex(-1);
                                                                Get.find<ParcelController>().setCustomNote('');
                                                              },
                                                              child: Icon(
                                                                Icons.clear,
                                                                color: Theme.of(context).disabledColor,
                                                                size: 20,
                                                              ),
                                                            ),
                                                          ],
                                                        )
                                                      : const SizedBox(),
                                                  parcelController.customNote!.isNotEmpty
                                                      ? Text(
                                                          parcelController.customNote ?? '',
                                                          style: robotoMedium.copyWith(
                                                            color: Theme.of(context).disabledColor,
                                                          ),
                                                        )
                                                      : const SizedBox(),
                                                ],
                                              ),
                                            ),
                                          ])
                                        : const SizedBox(),
                                  ]),
                                ),
                              ),
                              const SizedBox(height: Dimensions.paddingSizeDefault),

                              // 🔹 Guest create account
                              isGuestLoggedIn
                                  ? GuestCreateAccount(
                                      guestPasswordController: _guestPasswordController,
                                      guestConfirmPasswordController: _guestConfirmPasswordController,
                                      guestPasswordNode: _guestPasswordNode,
                                      guestConfirmPasswordNode: _guestConfirmPasswordNode,
                                      fromParcel: true,
                                    )
                                  : const SizedBox(),

                              const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                              // 🔹 Gorjeta (tips)
                              (Get.find<SplashController>().configModel!.dmTipsStatus == 1)
                                  ? Container(
                                      color: Theme.of(context).cardColor,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: Dimensions.paddingSizeLarge,
                                        horizontal: Dimensions.paddingSizeSmall,
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('delivery_man_tips'.tr, style: robotoMedium),
                                          const SizedBox(height: Dimensions.paddingSizeSmall),
                                          SizedBox(
                                            height: (parcelController.selectedTips == AppConstants.tips.length - 1) &&
                                                    parcelController.canShowTipsField
                                                ? 0
                                                : 60,
                                            child: (parcelController.selectedTips == AppConstants.tips.length - 1) &&
                                                    parcelController.canShowTipsField
                                                ? const SizedBox()
                                                : ListView.builder(
                                                    scrollDirection: Axis.horizontal,
                                                    shrinkWrap: true,
                                                    physics: const BouncingScrollPhysics(),
                                                    itemCount: AppConstants.tips.length,
                                                    itemBuilder: (context, index) {
                                                      return TipsWidget(
                                                        title: AppConstants.tips[index] == '0'
                                                            ? 'not_now'.tr
                                                            : (index != AppConstants.tips.length - 1)
                                                                ? PriceConverter.convertPrice(
                                                                    double.parse(AppConstants.tips[index]),
                                                                    forDM: true,
                                                                  )
                                                                : AppConstants.tips[index].tr,
                                                        isSelected: parcelController.selectedTips == index,
                                                        isSuggested: index != 0 &&
                                                            AppConstants.tips[index] ==
                                                                parcelController.mostDmTipAmount.toString(),
                                                        onTap: () {
                                                          parcelController.updateTips(index);
                                                          if (parcelController.selectedTips != 0 &&
                                                              parcelController.selectedTips != AppConstants.tips.length - 1) {
                                                            parcelController.addTips(double.parse(AppConstants.tips[index]));
                                                          }
                                                          if (parcelController.selectedTips == AppConstants.tips.length - 1) {
                                                            parcelController.showTipsField();
                                                          }
                                                          _tipController.text = parcelController.tips.toString();
                                                        },
                                                      );
                                                    },
                                                  ),
                                          ),
                                          SizedBox(
                                            height: (parcelController.selectedTips == AppConstants.tips.length - 1) &&
                                                    parcelController.canShowTipsField
                                                ? Dimensions.paddingSizeExtraSmall
                                                : 0,
                                          ),
                                          parcelController.selectedTips == AppConstants.tips.length - 1
                                              ? const SizedBox()
                                              : ListTile(
                                                  onTap: () => parcelController.toggleDmTipSave(),
                                                  leading: Checkbox(
                                                    visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                                    activeColor: Theme.of(context).primaryColor,
                                                    value: parcelController.isDmTipSave,
                                                    onChanged: (bool? isChecked) =>
                                                        parcelController.toggleDmTipSave(),
                                                  ),
                                                  title: Text(
                                                    'save_for_later'.tr,
                                                    style: robotoMedium.copyWith(
                                                      color: Theme.of(context).primaryColor,
                                                    ),
                                                  ),
                                                  contentPadding: EdgeInsets.zero,
                                                  visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
                                                  dense: true,
                                                  horizontalTitleGap: 0,
                                                ),
                                          SizedBox(
                                            height: parcelController.selectedTips == AppConstants.tips.length - 1
                                                ? Dimensions.paddingSizeDefault
                                                : 0,
                                          ),
                                          parcelController.selectedTips == AppConstants.tips.length - 1
                                              ? Row(children: [
                                                  Expanded(
                                                    child: CustomTextField(
                                                      titleText: 'enter_amount'.tr,
                                                      controller: _tipController,
                                                      inputAction: TextInputAction.done,
                                                      inputType: TextInputType.number,
                                                      onSubmit: (value) {
                                                        if (value.isNotEmpty) {
                                                          if (double.parse(value) >= 0) {
                                                            parcelController.addTips(double.parse(value));
                                                          } else {
                                                            showCustomSnackBar('tips_can_not_be_negative'.tr);
                                                          }
                                                        } else {
                                                          parcelController.addTips(0.0);
                                                        }
                                                      },
                                                      onChanged: (String value) {
                                                        if (value.isNotEmpty) {
                                                          if (double.parse(value) >= 0) {
                                                            parcelController.addTips(double.parse(value));
                                                          } else {
                                                            showCustomSnackBar('tips_can_not_be_negative'.tr);
                                                          }
                                                        } else {
                                                          parcelController.addTips(0.0);
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: Dimensions.paddingSizeSmall),
                                                  InkWell(
                                                    onTap: () {
                                                      parcelController.updateTips(0);
                                                      parcelController.showTipsField();
                                                    },
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: Theme.of(context).primaryColor.withOpacity(0.5),
                                                      ),
                                                      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                                                      child: const Icon(Icons.clear),
                                                    ),
                                                  ),
                                                ])
                                              : const SizedBox(),
                                        ],
                                      ),
                                    )
                                  : const SizedBox.shrink(),

                              SizedBox(
                                height: (Get.find<SplashController>().configModel!.dmTipsStatus == 1)
                                    ? Dimensions.paddingSizeExtraSmall
                                    : 0,
                              ),

                              // 🔹 Quem paga
                              Text('charge_pay_by'.tr, style: robotoMedium),
                              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                              Row(children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => parcelController.setPayerIndex(0, true),
                                    child: Row(children: [
                                      Radio<String>(
                                        value: parcelController.payerTypes[0],
                                        groupValue: parcelController.payerTypes[parcelController.payerIndex],
                                        activeColor: Theme.of(context).primaryColor,
                                        onChanged: (String? payerType) => parcelController.setPayerIndex(0, true),
                                      ),
                                      Text(parcelController.payerTypes[0].tr, style: robotoRegular),
                                    ]),
                                  ),
                                ),
                                _isCashOnDeliveryActive!
                                    // Receptor só pode pagar em dinheiro; bloqueia se houver paradas extras
                                    && parcelController.extraDeliveries.isEmpty
                                    ? Expanded(
                                        child: InkWell(
                                          onTap: () => parcelController.setPayerIndex(1, true),
                                          child: Row(children: [
                                            Radio<String>(
                                              value: parcelController.payerTypes[1],
                                              groupValue: parcelController.payerTypes[parcelController.payerIndex],
                                              activeColor: Theme.of(context).primaryColor,
                                              onChanged: (String? payerType) => parcelController.setPayerIndex(1, true),
                                            ),
                                            Text(parcelController.payerTypes[1].tr, style: robotoRegular),
                                          ]),
                                        ),
                                      )
                                    : const SizedBox(),
                              ]),
                              const SizedBox(height: Dimensions.paddingSizeLarge),

                              // 🔹 Botões de pagamento (dinheiro / carteira)
                              // Dinheiro bloqueado quando há paradas adicionais
                              Row(children: [
                                _isCashOnDeliveryActive! && parcelController.extraDeliveries.isEmpty
                                    ? Expanded(
                                        child: PaymentButton(
                                          icon: Images.cashOnDelivery,
                                          title: 'cash_on_delivery'.tr,
                                          subtitle: 'pay_your_payment_after_getting_item'.tr,
                                          isSelected: parcelController.paymentIndex == 0,
                                          onTap: () => parcelController.setPaymentIndex(0, true),
                                        ),
                                      )
                                    : const SizedBox(),
                                SizedBox(
                                  width: (Get.find<SplashController>().configModel!.customerWalletStatus == 1 &&
                                          parcelController.payerIndex == 0 &&
                                          !isGuestLoggedIn)
                                      ? Dimensions.paddingSizeLarge
                                      : 0,
                                ),
                                (Get.find<SplashController>().configModel!.customerWalletStatus == 1 &&
                                        parcelController.payerIndex == 0 &&
                                        !isGuestLoggedIn)
                                    ? Expanded(
                                        child: PaymentButton(
                                          icon: Images.wallet,
                                          title: 'wallet_payment'.tr,
                                          subtitle: 'pay_from_your_existing_balance'.tr,
                                          isSelected: parcelController.paymentIndex == 1,
                                          onTap: () => parcelController.setPaymentIndex(1, true),
                                        ),
                                      )
                                    : const SizedBox(),
                              ]),
                              const SizedBox(height: Dimensions.paddingSizeSmall),

                              // 🔹 Pagamento online (gateway)
                              (_isDigitalPaymentActive! && parcelController.payerIndex == 0)
                                  ? Column(children: [
                                      Row(children: [
                                        Text(
                                          'pay_via_online'.tr,
                                          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                                        ),
                                        Text(
                                          'faster_and_secure_way_to_pay_bill'.tr,
                                          style: robotoRegular.copyWith(
                                            fontSize: Dimensions.fontSizeSmall,
                                            color: Theme.of(context).hintColor,
                                          ),
                                        ),
                                      ]),
                                      const SizedBox(height: Dimensions.paddingSizeLarge),
                                      ListView.builder(
                                        itemCount: Get.find<SplashController>()
                                            .configModel!
                                            .activePaymentMethodList!
                                            .length,
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemBuilder: (context, index) {
                                          bool isSelected = parcelController.paymentIndex == 2 &&
                                              Get.find<SplashController>()
                                                      .configModel!
                                                      .activePaymentMethodList![index]
                                                      .getWay! ==
                                                  parcelController.digitalPaymentName;
                                          return InkWell(
                                            onTap: () {
                                              parcelController.setPaymentIndex(2, true);
                                              parcelController.changeDigitalPaymentName(
                                                Get.find<SplashController>()
                                                    .configModel!
                                                    .activePaymentMethodList![index]
                                                    .getWay!,
                                              );
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: isSelected ? Colors.blue.withOpacity(0.05) : Colors.transparent,
                                                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: Dimensions.paddingSizeSmall,
                                                vertical: Dimensions.paddingSizeLarge,
                                              ),
                                              child: Row(children: [
                                                Container(
                                                  height: 20,
                                                  width: 20,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
                                                    border: Border.all(color: Theme.of(context).disabledColor),
                                                  ),
                                                  child: Icon(
                                                    Icons.check,
                                                    color: Theme.of(context).cardColor,
                                                    size: 16,
                                                  ),
                                                ),
                                                const SizedBox(width: Dimensions.paddingSizeDefault),
                                                CustomImage(
                                                  height: 20,
                                                  fit: BoxFit.contain,
                                                  image: Get.find<SplashController>()
                                                      .configModel!
                                                      .activePaymentMethodList![index]
                                                      .getWayImageFullUrl!,
                                                ),
                                                const SizedBox(width: Dimensions.paddingSizeSmall),
                                                Text(
                                                  Get.find<SplashController>()
                                                      .configModel!
                                                      .activePaymentMethodList![index]
                                                      .getWayTitle!,
                                                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                                                ),
                                              ]),
                                            ),
                                          );
                                        },
                                      ),
                                    ])
                                  : const SizedBox(),

                              // 🔹 Pagamento offline
                              parcelController.offlineMethodList != null && parcelController.payerIndex == 0
                                  ? OfflinePaymentButton(
                                      isSelected: parcelController.paymentIndex == 3,
                                      offlineMethodList: parcelController.offlineMethodList!,
                                      isOfflinePaymentActive: _isOfflinePaymentActive,
                                      onTap: () {
                                        parcelController.setPaymentIndex(3, true);
                                      },
                                      parcelController: parcelController,
                                      forParcel: true,
                                      checkoutController: Get.find<CheckoutController>(),
                                      tooltipController: tooltipController,
                                    )
                                  : const SizedBox(),

                              const SizedBox(height: Dimensions.paddingSizeSmall),

                              // 🔹 Resumo do pedido
                              Text('order_summary'.tr, style: robotoMedium),
                              const SizedBox(height: Dimensions.paddingSizeSmall),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('delivery_fee'.tr, style: robotoRegular),
                                  Text(
                                    (parcelController.distance == -1 || parcelController.deliveryFee == null)
                                        ? 'calculating'.tr
                                        : _parcelPrice(charge),
                                    style: robotoRegular.copyWith(
                                      color: parcelController.distance == -1
                                          ? Colors.red
                                          : Theme.of(context).textTheme.bodyMedium!.color,
                                    ),
                                  ),
                                ],
                              ),
                              // Linhas de entregas extras
                              ...List.generate(
                                parcelController.extraDeliveries.length,
                                (i) => Padding(
                                  padding: const EdgeInsets.only(
                                      top: Dimensions.paddingSizeExtraSmall),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Entrega extra ${i + 1}',
                                          style: robotoRegular),
                                      Text(
                                        '(+) ${_parcelPrice(parcelController.extraDeliveries[i].fee)}',
                                        style: robotoRegular,
                                        textDirection: TextDirection.ltr,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: Get.find<SplashController>().configModel!.dmTipsStatus == 1
                                    ? Dimensions.paddingSizeSmall
                                    : 0.0,
                              ),
                              (Get.find<SplashController>().configModel!.dmTipsStatus == 1)
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('delivery_man_tips'.tr, style: robotoRegular),
                                        Text(
                                          '(+) ${_parcelPrice(dmTips)}',
                                          style: robotoRegular,
                                          textDirection: TextDirection.ltr,
                                        ),
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                              SizedBox(
                                height: Get.find<SplashController>().configModel!.additionalChargeStatus!
                                    ? Dimensions.paddingSizeSmall
                                    : 0,
                              ),
                              Get.find<SplashController>().configModel!.additionalChargeStatus!
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          Get.find<SplashController>().configModel!.additionalChargeName!,
                                          style: robotoRegular,
                                        ),
                                        Text(
                                          '(+) ${_parcelPrice(Get.find<SplashController>().configModel!.additionCharge!)}',
                                          style: robotoRegular,
                                          textDirection: TextDirection.ltr,
                                        ),
                                      ],
                                    )
                                  : const SizedBox(),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                                child: Divider(
                                  thickness: 1,
                                  color: Theme.of(context).hintColor.withOpacity(0.5),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('total_amount'.tr, style: robotoMedium),
                                  Text(
                                    _parcelPrice(total),
                                    style: robotoMedium,
                                    textDirection: TextDirection.ltr,
                                  ),
                                ],
                              ),

                              const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                              const CheckoutCondition(isParcel: true),

                              SizedBox(
                                height: ResponsiveHelper.isDesktop(context)
                                    ? Dimensions.paddingSizeLarge
                                    : 0,
                              ),
                              ResponsiveHelper.isDesktop(context)
                                  ? _bottomButton(
                                      parcelController,
                                      deliveryFee: charge,
                                      dmTips: dmTips,
                                      additionalCharge: additionalCharge,
                                      isGuestLoggedIn: isGuestLoggedIn,
                                    )
                                  : const SizedBox(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 🔹 Botão inferior (mobile)
                  ResponsiveHelper.isDesktop(context)
                      ? const SizedBox()
                      : _bottomButton(
                          parcelController,
                          deliveryFee: charge,
                          dmTips: dmTips,
                          additionalCharge: additionalCharge,
                          isGuestLoggedIn: isGuestLoggedIn,
                        ),
                ]);
              })
            : NotLoggedInScreen(callBack: (value) {
                initCall();
                setState(() {});
              }),
      ),
    );
  }

  Widget _bottomButton(
    ParcelController parcelController, {
    required double deliveryFee,
    required double dmTips,
    required double additionalCharge,
    bool isGuestLoggedIn = false,
  }) {
    // baseAmount = valor do serviço (frete + entregas extras + taxa extra)
    final double baseAmount = (deliveryFee > 0 ? deliveryFee : 0) +
        (additionalCharge > 0 ? additionalCharge : 0) +
        parcelController.extraDeliveriesTotalFee;

    // totalAmount = valor final para pagamento (base + gorjeta)
    final double totalAmount = baseAmount + (dmTips > 0 ? dmTips : 0);

    bool isInstructionSelected = parcelController.selectedIndexNote != -1;
    bool isCustomNote = parcelController.customNote!.isNotEmpty;

    return CustomButton(
      buttonText: 'confirm_parcel_request'.tr,
      isLoading: parcelController.isLoading,
      margin: ResponsiveHelper.isDesktop(context)
          ? null
          : const EdgeInsets.all(Dimensions.paddingSizeSmall),
      onPressed: parcelController.acceptTerms
          ? () {
              if (parcelController.distance == -1 ||
                  parcelController.deliveryFee == null) {
                showCustomSnackBar('delivery_fee_not_set_yet'.tr);
              } else if (parcelController.tips < 0) {
                showCustomSnackBar('tips_can_not_be_negative'.tr);
              } else if (parcelController.paymentIndex == 0 &&
                  parcelController.extraDeliveries.isNotEmpty) {
                // Segurança extra: bloqueia cash se houver paradas adicionais
                showCustomSnackBar('cash_not_allowed_for_parcel_with_stops'.tr);
              } else if (parcelController.paymentIndex == -1) {
                showCustomSnackBar('please_select_payment_method_first'.tr);
              } else if (isGuestLoggedIn &&
                  Get.find<CheckoutController>().isCreateAccount &&
                  _guestPasswordController.text.isEmpty) {
                showCustomSnackBar('enter_password'.tr);
              } else if (isGuestLoggedIn &&
                  Get.find<CheckoutController>().isCreateAccount &&
                  _guestConfirmPasswordController.text.isEmpty) {
                showCustomSnackBar('enter_confirm_password'.tr);
              } else if (isGuestLoggedIn &&
                  Get.find<CheckoutController>().isCreateAccount &&
                  (_guestPasswordController.text !=
                      _guestConfirmPasswordController.text)) {
                showCustomSnackBar('confirm_password_does_not_matched'.tr);
              } else {
                // monta o body com valores CONSISTENTES
                PlaceOrderBodyModel placeOrderBody = PlaceOrderBodyModel(
                  cart: [],
                  couponDiscountAmount: null,
                  distance: parcelController.distance,
                  scheduleAt: null,

                  // 👇 valor base (frete + taxa extra) que vai para o backend
                  orderAmount: baseAmount,

                  orderNote: '',
                  orderType: 'parcel',
                  receiverDetails: widget.destinationAddress,
                  paymentMethod: parcelController.paymentIndex == 0
                      ? 'cash_on_delivery'
                      : parcelController.paymentIndex == 1
                          ? 'wallet'
                          : parcelController.paymentIndex == 2
                              ? 'digital_payment'
                              : 'offline_payment',
                  couponCode: null,
                  storeId: null,
                  address: widget.pickedUpAddress.address,
                  latitude: widget.pickedUpAddress.latitude,
                  longitude: widget.pickedUpAddress.longitude,
                  senderZoneId: widget.pickedUpAddress.zoneId,
                  addressType: widget.pickedUpAddress.addressType,
                  contactPersonName:
                      widget.pickedUpAddress.contactPersonName ?? '',
                  contactPersonNumber:
                      widget.pickedUpAddress.contactPersonNumber ?? '',
                  streetNumber: widget.pickedUpAddress.streetNumber ?? '',
                  house: widget.pickedUpAddress.house ?? '',
                  floor: widget.pickedUpAddress.floor ?? '',
                  discountAmount: 0,
                  taxAmount: 0,
                  parcelCategoryId: widget.parcelCategory.id.toString(),
                  chargePayer:
                      parcelController.payerTypes[parcelController.payerIndex],

                  // 👇 gorjeta enviada em campo próprio
                  dmTips: dmTips.toString(),

                  cutlery: 0,
                  unavailableItemNote: '',
                  deliveryInstruction: (isInstructionSelected
                          ? '${parcelController.parcelInstructionList![parcelController.selectedIndexNote!].instruction}'
                          : '') +
                      (isInstructionSelected
                          ? (isCustomNote
                              ? " (${parcelController.customNote})"
                              : '')
                          : (isCustomNote
                              ? parcelController.customNote ?? ''
                              : '')),
                  partialPayment: 0,
                  guestId: AuthHelper.isGuestLoggedIn()
                      ? int.parse(AuthHelper.getGuestId())
                      : 0,
                  isBuyNow: 0,
                  guestEmail: widget.pickedUpAddress.email ?? '',
                  extraPackagingAmount: null,
                  createNewUser:
                      Get.find<CheckoutController>().isCreateAccount ? 1 : 0,
                  password: _guestPasswordController.text,
                  additionalStops: parcelController.extraDeliveries.map((e) => {
                    'address':               e.address.address ?? '',
                    'latitude':              e.address.latitude ?? '',
                    'longitude':             e.address.longitude ?? '',
                    'distance_km':           e.distanceKm,
                    'extra_delivery_charge': e.fee,
                    'contact_person_name':   e.contactPersonName,
                    'contact_person_number': e.address.contactPersonNumber ?? '',
                    'house':                 e.houseNumber,
                    'delivery_instruction':  null,
                  }).toList(),
                  isReturn: _isReturnTrip,
                );

                if (parcelController.paymentIndex == 3) {
                  // Pagamento offline: passa o TOTAL (base + gorjeta)
                  Get.toNamed(
                    RouteHelper.getOfflinePaymentScreen(
                      placeOrderBody: placeOrderBody,
                      zoneId: widget.pickedUpAddress.zoneId,
                      total: totalAmount,
                      maxCodOrderAmount: 0,
                      fromCart: false,
                      isCodActive: false,
                      forParcel: true,
                    ),
                  );
                } else {
                  parcelController.startLoader(true);
                  parcelController.placeOrder(
                    placeOrderBody,
                    widget.pickedUpAddress.zoneId,
                    0,
                    0,
                    false,
                    false,
                    forParcel: true,
                  );
                }
              }
            }
          : null,
    );
  }
}
