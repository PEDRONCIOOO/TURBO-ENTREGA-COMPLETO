import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/brands/controllers/brands_controller.dart';
import 'package:sixam_mart/features/home/controllers/advertisement_controller.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/home/widgets/all_store_filter_widget.dart';
import 'package:sixam_mart/features/home/widgets/cashback_logo_widget.dart';
import 'package:sixam_mart/features/home/widgets/cashback_dialog_widget.dart';
import 'package:sixam_mart/features/home/widgets/refer_bottom_sheet_widget.dart';
import 'package:sixam_mart/features/item/controllers/campaign_controller.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/coupon/controllers/coupon_controller.dart';
import 'package:sixam_mart/features/flash_sale/controllers/flash_sale_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/notification/controllers/notification_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/address/controllers/address_controller.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/home/screens/modules/food_home_screen.dart';
import 'package:sixam_mart/features/home/screens/modules/grocery_home_screen.dart';
import 'package:sixam_mart/features/home/screens/modules/pharmacy_home_screen.dart';
import 'package:sixam_mart/features/home/screens/modules/shop_home_screen.dart';
import 'package:sixam_mart/features/parcel/controllers/parcel_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/item_view.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/common/widgets/paginated_list_view.dart';
import 'package:sixam_mart/common/widgets/web_menu_bar.dart';
import 'package:sixam_mart/features/home/screens/web_new_home_screen.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/home/widgets/module_view.dart';
import 'package:sixam_mart/features/parcel/screens/parcel_category_screen.dart';
import 'package:sixam_mart/features/home/widgets/login_popup_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static Future<void> loadData(bool reload, {bool fromModule = false}) async {
    Get.find<LocationController>().syncZoneData();
    Get.find<FlashSaleController>().setEmptyFlashSale(fromModule: fromModule);

    final splashController = Get.find<SplashController>();
    final module = splashController.module;
    final moduleConfig = splashController.configModel?.moduleConfig?.module;
    final bool isLoggedIn = AuthHelper.isLoggedIn();
    final bool hasModule = module != null;
    final bool isStandardModule = hasModule && !(moduleConfig?.isParcel ?? false);
    final String moduleType = module?.moduleType?.toString() ?? '';

    // --- Chamadas criticas (acima da dobra) ---
    if (isStandardModule) {
      Get.find<BannerController>().getBannerList(reload);
      Get.find<CategoryController>().getCategoryList(reload);
      Get.find<StoreController>().getPopularStoreList(reload, 'all', false);
    }

    if (!hasModule && splashController.configModel!.module == null) {
      Get.find<BannerController>().getFeaturedBanner();
      Get.find<StoreController>().getFeaturedStoreList();
    }

    if (isLoggedIn) {
      Get.find<ProfileController>().getUserInfo();
    }

    splashController.getModules();

    // --- Chamadas deferidas (abaixo da dobra, ~300ms delay) ---
    Future.delayed(const Duration(milliseconds: 300), () {
      if (isStandardModule) {
        Get.find<StoreController>().getRecommendedStoreList();
        Get.find<BannerController>().getPromotionalBannerList(reload);
        Get.find<ItemController>().getDiscountedItemList(reload, false, 'all');
        Get.find<CampaignController>().getBasicCampaignList(reload);
        Get.find<CampaignController>().getItemCampaignList(reload);
        Get.find<ItemController>().getPopularItemList(reload, 'all', false);
        Get.find<StoreController>().getLatestStoreList(reload, 'all', false);
        Get.find<StoreController>().getTopOfferStoreList(reload, false);
        Get.find<ItemController>().getReviewedItemList(reload, 'all', false);
        Get.find<ItemController>().getRecommendedItemList(reload, 'all', false);
        Get.find<StoreController>().getStoreList(1, reload);
        Get.find<AdvertisementController>().getAdvertisementList();

        if (moduleType == AppConstants.grocery) {
          Get.find<FlashSaleController>().getFlashSale(reload, false);
        }
        if (moduleType == AppConstants.ecommerce) {
          Get.find<ItemController>().getFeaturedCategoriesItemList(false, false);
          Get.find<FlashSaleController>().getFlashSale(reload, false);
          Get.find<BrandsController>().getBrandList();
        }
      }

      if (isLoggedIn) {
        Get.find<StoreController>().getVisitAgainStoreList(fromModule: fromModule);
        Get.find<NotificationController>().getNotificationList(reload);
        Get.find<CouponController>().getCouponList();
        if (hasModule) {
          Get.find<FavouriteController>().getFavouriteList();
          Get.find<HomeController>().getCashBackOfferList();
        }
      }

      if (isLoggedIn && !hasModule) {
        Get.find<AddressController>().getAddressList();
      }

      if (hasModule && (moduleConfig?.isParcel ?? false)) {
        Get.find<ParcelController>().getParcelCategoryList();
      }

      if (moduleType == AppConstants.pharmacy) {
        Get.find<ItemController>().getBasicMedicine(reload, false);
        Get.find<StoreController>().getFeaturedStoreList();
        Get.find<ItemController>().getCommonConditions(false).then((_) {
          if (Get.find<ItemController>().commonConditions != null &&
              Get.find<ItemController>().commonConditions!.isNotEmpty) {
            Get.find<ItemController>().getConditionsWiseItem(
                Get.find<ItemController>().commonConditions![0].id!, false);
          }
        });
      }
    });
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool searchBgShow = false;
  final GlobalKey _headerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    HomeScreen.loadData(false).then((value) {
      Get.find<SplashController>().getReferBottomSheetStatus();

      if ((Get.find<ProfileController>().userInfoModel?.isValidForDiscount ??
              false) &&
          Get.find<SplashController>().showReferBottomSheet) {
        _showReferBottomSheet();
      }
    });

    if (!ResponsiveHelper.isWeb()) {
      Get.find<LocationController>().getZone(
          AddressHelper.getUserAddressFromSharedPref()!.latitude,
          AddressHelper.getUserAddressFromSharedPref()!.longitude,
          false,
          updateInAddress: true);
    }

    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (Get.find<HomeController>().showFavButton) {
          Get.find<HomeController>().changeFavVisibility();
          Future.delayed(const Duration(milliseconds: 800),
              () => Get.find<HomeController>().changeFavVisibility());
        }
      } else {
        if (Get.find<HomeController>().showFavButton) {
          Get.find<HomeController>().changeFavVisibility();
          Future.delayed(const Duration(milliseconds: 800),
              () => Get.find<HomeController>().changeFavVisibility());
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  void _showReferBottomSheet() {
    ResponsiveHelper.isDesktop(context)
        ? Get.dialog(
            Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(Dimensions.radiusExtraLarge)),
              insetPadding: const EdgeInsets.all(22),
              clipBehavior: Clip.antiAliasWithSaveLayer,
              child: const ReferBottomSheetWidget(),
            ),
            useSafeArea: false,
          ).then((value) =>
            Get.find<SplashController>().saveReferBottomSheetStatus(false))
        : showModalBottomSheet(
            isScrollControlled: true,
            useRootNavigator: true,
            context: Get.context!,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(Dimensions.radiusExtraLarge),
                  topRight: Radius.circular(Dimensions.radiusExtraLarge)),
            ),
            builder: (context) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8),
                child: const ReferBottomSheetWidget(),
              );
            },
          ).then((value) =>
            Get.find<SplashController>().saveReferBottomSheetStatus(false));
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(builder: (splashController) {
      if (splashController.moduleList != null &&
          splashController.moduleList!.length == 1) {
        splashController.switchModule(0, true);
      }
      bool showMobileModule = !ResponsiveHelper.isDesktop(context) &&
          splashController.module == null &&
          splashController.configModel!.module == null;
      bool isParcel = splashController.module != null &&
          splashController.module!.moduleType.toString() == AppConstants.parcel;
      bool isPharmacy = splashController.module != null &&
          splashController.module!.moduleType.toString() ==
              AppConstants.pharmacy;
      bool isFood = splashController.module != null &&
          splashController.module!.moduleType.toString() == AppConstants.food;
      bool isShop = splashController.module != null &&
          splashController.module!.moduleType.toString() ==
              AppConstants.ecommerce;
      bool isGrocery = splashController.module != null &&
          splashController.module!.moduleType.toString() ==
              AppConstants.grocery;
      return GetBuilder<HomeController>(builder: (homeController) {
        return Scaffold(
          appBar:
              ResponsiveHelper.isDesktop(context) ? const WebMenuBar() : null,
          endDrawer: const MenuDrawer(),
          endDrawerEnableOpenDragGesture: false,
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: Stack(
            children: [
              isParcel
                  ? const ParcelCategoryScreen()
                  : SafeArea(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          splashController.setRefreshing(true);
                          if (Get.find<SplashController>().module != null) {
                            await Get.find<LocationController>().syncZoneData();
                            await Get.find<BannerController>()
                                .getBannerList(true);
                            if (isGrocery) {
                              await Get.find<FlashSaleController>()
                                  .getFlashSale(true, true);
                            }
                            await Get.find<BannerController>()
                                .getPromotionalBannerList(true);
                            await Get.find<ItemController>()
                                .getDiscountedItemList(true, false, 'all');
                            await Get.find<CategoryController>()
                                .getCategoryList(true);
                            await Get.find<StoreController>()
                                .getPopularStoreList(true, 'all', false);
                            await Get.find<CampaignController>()
                                .getItemCampaignList(true);
                            Get.find<CampaignController>()
                                .getBasicCampaignList(true);
                            await Get.find<ItemController>()
                                .getPopularItemList(true, 'all', false);
                            await Get.find<StoreController>()
                                .getLatestStoreList(true, 'all', false);
                            await Get.find<StoreController>()
                                .getTopOfferStoreList(true, false);
                            await Get.find<ItemController>()
                                .getReviewedItemList(true, 'all', false);
                            await Get.find<StoreController>()
                                .getStoreList(1, true);
                            Get.find<AdvertisementController>()
                                .getAdvertisementList();
                            if (AuthHelper.isLoggedIn()) {
                              await Get.find<ProfileController>().getUserInfo();
                              await Get.find<NotificationController>()
                                  .getNotificationList(true);
                              Get.find<CouponController>().getCouponList();
                            }
                            if (isPharmacy) {
                              Get.find<ItemController>()
                                  .getBasicMedicine(true, true);
                              Get.find<ItemController>()
                                  .getCommonConditions(true);
                            }
                            if (isShop) {
                              await Get.find<FlashSaleController>()
                                  .getFlashSale(true, true);
                              Get.find<ItemController>()
                                  .getFeaturedCategoriesItemList(true, true);
                              Get.find<BrandsController>().getBrandList();
                            }
                          } else {
                            await Get.find<BannerController>()
                                .getFeaturedBanner();
                            await Get.find<SplashController>().getModules();
                            if (AuthHelper.isLoggedIn()) {
                              await Get.find<AddressController>()
                                  .getAddressList();
                            }
                            await Get.find<StoreController>()
                                .getFeaturedStoreList();
                          }
                          splashController.setRefreshing(false);
                        },
                        child: ResponsiveHelper.isDesktop(context)
                            ? WebNewHomeScreen(
                                scrollController: _scrollController,
                              )
                            : CustomScrollView(
                                controller: _scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                slivers: [
                                  /// App Bar
                                  SliverAppBar(
                                    floating: true,
                                    elevation: 0,
                                    automaticallyImplyLeading: false,
                                    surfaceTintColor: Colors.transparent,
                                    backgroundColor: Theme.of(context).colorScheme.surface,
                                    toolbarHeight: 56,
                                    titleSpacing: 0,
                                    title: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                        Expanded(child: GestureDetector(
                                          onTap: () => Get.find<LocationController>().navigateToLocationScreen('home'),
                                          child: GetBuilder<LocationController>(builder: (locationController) {
                                            final address = AddressHelper.getUserAddressFromSharedPref();
                                            return Container(
                                              height: 38,
                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).primaryColor.withValues(alpha: 0.06),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(children: [
                                                Icon(Icons.location_on_rounded, size: 16, color: Theme.of(context).primaryColor),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text(
                                                        address?.addressType?.tr ?? 'location'.tr,
                                                        style: robotoMedium.copyWith(
                                                          color: Theme.of(context).textTheme.bodyLarge!.color,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w700,
                                                          height: 1.1,
                                                        ),
                                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                                      ),
                                                      Text(
                                                        address?.address ?? 'select_location'.tr,
                                                        style: robotoRegular.copyWith(
                                                          color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black).withValues(alpha: 0.5),
                                                          fontSize: 10,
                                                          height: 1.2,
                                                        ),
                                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Icon(Icons.keyboard_arrow_down_rounded, color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black).withValues(alpha: 0.4), size: 18),
                                              ]),
                                            );
                                          }),
                                        )),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () => Get.toNamed(RouteHelper.getNotificationRoute()),
                                          child: GetBuilder<NotificationController>(builder: (notificationController) {
                                            return Container(
                                              height: 38, width: 38,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Stack(clipBehavior: Clip.none, children: [
                                                Icon(CupertinoIcons.bell_fill, size: 18, color: Theme.of(context).textTheme.bodyLarge!.color),
                                                if (notificationController.hasNotification) Positioned(
                                                  top: -2, right: -2,
                                                  child: Container(
                                                    height: 8, width: 8,
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFFF3B30),
                                                      shape: BoxShape.circle,
                                                      border: Border.all(width: 1.5, color: Theme.of(context).cardColor),
                                                    ),
                                                  ),
                                                ),
                                              ]),
                                            );
                                          }),
                                        ),
                                      ]),
                                    ),
                                    actions: const [SizedBox()],
                                  ),

                                  /// Search Button
                                  const SliverToBoxAdapter(),

                                  SliverToBoxAdapter(
                                    child: Center(
                                        child: SizedBox(
                                      width: Dimensions.webMaxWidth,
                                      child: !showMobileModule
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                  isGrocery
                                                      ? const GroceryHomeScreen()
                                                      : isPharmacy
                                                          ? const PharmacyHomeScreen()
                                                          : isFood
                                                              ? const FoodHomeScreen()
                                                              : isShop
                                                                  ? const ShopHomeScreen()
                                                                  : const SizedBox(),
                                                ])
                                          : ModuleView(
                                              splashController:
                                                  splashController),
                                    )),
                                  ),

                                  !showMobileModule
                                      ? SliverPersistentHeader(
                                          key: _headerKey,
                                          pinned: true,
                                          delegate: SliverDelegate(
                                            height: 85,
                                            callback: (val) {
                                              searchBgShow = val;
                                            },
                                            child: const AllStoreFilterWidget(),
                                          ),
                                        )
                                      : const SliverToBoxAdapter(),

                                  SliverToBoxAdapter(
                                      child: !showMobileModule
                                          ? Center(
                                              child:
                                                  GetBuilder<StoreController>(
                                                      builder:
                                                          (storeController) {
                                                return Padding(
                                                  padding: EdgeInsets.only(
                                                      bottom: ResponsiveHelper
                                                              .isDesktop(
                                                                  context)
                                                          ? 0
                                                          : 100),
                                                  child: PaginatedListView(
                                                    scrollController:
                                                        _scrollController,
                                                    totalSize: storeController
                                                        .storeModel?.totalSize,
                                                    offset: storeController
                                                        .storeModel?.offset,
                                                    onPaginate: (int?
                                                            offset) async =>
                                                        await storeController
                                                            .getStoreList(
                                                                offset!, false),
                                                    itemView: ItemsView(
                                                      isStore: true,
                                                      items: null,
                                                      isFoodOrGrocery:
                                                          (isFood || isGrocery),
                                                      stores: storeController
                                                          .storeModel?.stores,
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                        horizontal: ResponsiveHelper
                                                                .isDesktop(
                                                                    context)
                                                            ? Dimensions
                                                                .paddingSizeExtraSmall
                                                            : Dimensions
                                                                .paddingSizeSmall,
                                                        vertical: ResponsiveHelper
                                                                .isDesktop(
                                                                    context)
                                                            ? Dimensions
                                                                .paddingSizeExtraSmall
                                                            : Dimensions
                                                                .paddingSizeDefault,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }),
                                            )
                                          : const SizedBox()),
                                ],
                              ),
                      ),
                    ),
              Positioned(
                bottom: kBottomNavigationBarHeight +
                    20, // Posicionar mais para cima
                left: 0,
                right: 0,
                child: Builder(builder: (context) {
                  bool shouldShow = !kIsWeb && 
                      (!AuthHelper.isLoggedIn() || AuthHelper.isGuestLoggedIn());
                  print(
                      'Debug - Login Popup: isLoggedIn: ${!AuthHelper.isLoggedIn()}, isGuestLoggedIn: ${AuthHelper.isGuestLoggedIn()}, shouldShow: $shouldShow');
                  return Visibility(
                    visible: shouldShow,
                    child: const LoginPopupWidget(),
                  );
                }),
              ),
            ],
          ),
          floatingActionButton: AuthHelper.isLoggedIn() &&
                  homeController.cashBackOfferList != null &&
                  homeController.cashBackOfferList!.isNotEmpty
              ? homeController.showFavButton
                  ? Padding(
                      padding: EdgeInsets.only(
                          bottom: 50.0,
                          right: ResponsiveHelper.isDesktop(context) ? 50 : 0),
                      child: InkWell(
                        onTap: () => Get.dialog(const CashBackDialogWidget()),
                        child: const CashBackLogoWidget(),
                      ),
                    )
                  : null
              : null,
        );
      });
    });
  }
}

class SliverDelegate extends SliverPersistentHeaderDelegate {
  Widget child;
  double height;
  Function(bool isPinned)? callback;
  bool isPinned = false;

  SliverDelegate({required this.child, this.height = 50, this.callback});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    isPinned = shrinkOffset == maxExtent /*|| shrinkOffset < maxExtent*/;
    callback!(isPinned);
    return child;
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(SliverDelegate oldDelegate) {
    return oldDelegate.maxExtent != height ||
        oldDelegate.minExtent != height ||
        child != oldDelegate.child;
  }
}
