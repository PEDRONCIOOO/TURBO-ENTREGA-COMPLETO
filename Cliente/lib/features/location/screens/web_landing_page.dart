import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_loader.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/platform_stats_widget.dart';
import 'package:sixam_mart/common/widgets/promo_banner_widget.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/location/domain/models/prediction_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/features/location/screens/pick_map_screen.dart';
import 'package:sixam_mart/features/location/widgets/registration_card_widget.dart';
import 'package:sixam_mart/features/location/widgets/web_landing_page_shimmer_widget.dart';
import 'package:sixam_mart/features/parcel/widgets/download_app_section_widget.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class WebLandingPage extends StatefulWidget {
  final bool fromSignUp;
  final bool fromHome;
  final String? route;
  const WebLandingPage({super.key, required this.fromSignUp, required this.fromHome, required this.route});

  @override
  State<WebLandingPage> createState() => _WebLandingPageState();
}

class _WebLandingPageState extends State<WebLandingPage> {
  final TextEditingController _controller = TextEditingController();
  final PageController _pageController = PageController();
  AddressModel? _address;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (Get.find<SplashController>().moduleList == null) {
      if (kDebugMode) print('-------call from web landing page------------');
      Get.find<SplashController>().getModules(headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        AppConstants.localizationKey: Get.find<LocalizationController>().locale.languageCode,
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: FooterView(
        child: SizedBox(
          width: Dimensions.webMaxWidth,
          child: GetBuilder<SplashController>(builder: (splashController) {
            if (splashController.landingModel == null) {
              return const WebLandingPageShimmerWidget();
            }
            return Column(children: [

              const SizedBox(height: Dimensions.paddingSizeLarge),

              // === HERO SECTION ===
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF4870C), Color(0xFFFF6B35)],
                  ),
                ),
                child: Stack(children: [
                  // Decorative circles
                  Positioned(right: -20, top: -20, child: Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)),
                  )),
                  Positioned(left: 60, bottom: -30, child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)),
                  )),
                  Positioned(right: 200, bottom: 10, child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1)),
                  )),
                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                    child: Row(children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            splashController.landingModel?.fixedHeaderTitle ?? 'Turbo Entregas',
                            style: robotoBold.copyWith(fontSize: 38, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            splashController.landingModel?.fixedHeaderSubTitle ?? '',
                            style: robotoRegular.copyWith(fontSize: 15, color: Colors.white.withValues(alpha: 0.9), height: 1.5),
                          ),
                        ],
                      )),
                      const SizedBox(width: 32),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CustomImage(
                          image: '${splashController.landingModel?.fixedHeaderImageFullUrl ?? ''}',
                          height: 220, width: 320, fit: BoxFit.cover,
                        ),
                      ),
                    ]),
                  ),
                ]),
              ),

              const SizedBox(height: 16),

              // === PROMO BANNER ===
              const PromoBannerWidget(),

              const SizedBox(height: 16),

              // === PLATFORM STATS ===
              const PlatformStatsWidget(),

              const SizedBox(height: 24),

              // === LOCATION SEARCH BAR ===
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isDark ? Theme.of(context).cardColor : Colors.white,
                  border: Border.all(
                    color: isDark
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.12),
                  ),
                  boxShadow: isDark ? null : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16, offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(children: [
                  // Location icon
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4870C).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.location_on_rounded, color: Color(0xFFF4870C), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    splashController.landingModel?.fixedLocationTitle ?? 'Escolha sua localização',
                    style: robotoBold.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 24),
                  // Search field
                  Expanded(child: TypeAheadField(
                    textFieldConfiguration: TextFieldConfiguration(
                      controller: _controller,
                      textInputAction: TextInputAction.search,
                      textCapitalization: TextCapitalization.words,
                      keyboardType: TextInputType.streetAddress,
                      decoration: InputDecoration(
                        hintText: 'search_location'.tr,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.15)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        hintStyle: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: 14),
                        filled: true,
                        fillColor: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF8F8F8),
                        suffixIcon: IconButton(
                          onPressed: () async {
                            Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);
                            _address = await Get.find<LocationController>().getCurrentLocation(true);
                            _controller.text = _address!.address ?? '';
                            Get.back();
                          },
                          icon: Icon(Icons.my_location, color: Theme.of(context).primaryColor),
                        ),
                      ),
                      style: robotoRegular.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge!.color,
                        fontSize: 14,
                      ),
                    ),
                    suggestionsCallback: (pattern) async {
                      return await Get.find<LocationController>().searchLocation(context, pattern);
                    },
                    itemBuilder: (context, PredictionModel suggestion) {
                      return Padding(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                        child: Row(children: [
                          Icon(Icons.location_on, color: Theme.of(context).primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(
                            suggestion.description ?? '',
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: robotoRegular.copyWith(fontSize: 14),
                          )),
                        ]),
                      );
                    },
                    onSuggestionSelected: (PredictionModel suggestion) async {
                      _controller.text = suggestion.description ?? '';
                      _address = await Get.find<LocationController>().setLocation(suggestion.placeId, suggestion.description, null);
                    },
                  )),
                  const SizedBox(width: 12),
                  // Set Location button
                  _ActionButton(
                    label: 'set_location'.tr,
                    isPrimary: true,
                    onTap: () => _handleSetLocation(),
                  ),
                  const SizedBox(width: 8),
                  // Pick from map button
                  _ActionButton(
                    label: 'pick_from_map'.tr,
                    isPrimary: false,
                    onTap: () => _handlePickFromMap(),
                  ),
                ]),
              ),

              const SizedBox(height: 48),

              // === MODULE SECTION ===
              if (splashController.landingModel?.fixedModuleTitle != null) ...[
                Text(
                  splashController.landingModel!.fixedModuleTitle!,
                  style: robotoBold.copyWith(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  splashController.landingModel?.fixedModuleSubTitle ?? '',
                  style: robotoRegular.copyWith(fontSize: 14, color: Theme.of(context).disabledColor),
                ),
                const SizedBox(height: 28),
              ],

              // Module carousel
              GetBuilder<SplashController>(builder: (sc) {
                if (sc.moduleList != null && _timer == null) {
                  _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
                    int index = sc.moduleIndex >= sc.moduleList!.length - 1 ? 0 : sc.moduleIndex + 1;
                    sc.setModuleIndex(index);
                    _pageController.animateToPage(index, duration: const Duration(seconds: 2), curve: Curves.easeInOut);
                  });
                }
                if (sc.moduleList == null) return const SizedBox();
                return Column(children: [
                  // Module tabs
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(sc.moduleList!.length, (index) {
                      bool isActive = sc.moduleIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: InkWell(
                          onTap: () {
                            sc.setModuleIndex(index);
                            _pageController.animateToPage(index, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: isActive
                                  ? const Color(0xFFF4870C).withValues(alpha: 0.12)
                                  : isDark ? Theme.of(context).cardColor : const Color(0xFFF5F5F5),
                              border: Border.all(
                                color: isActive ? const Color(0xFFF4870C).withValues(alpha: 0.3) : Colors.transparent,
                              ),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              CustomImage(
                                image: '${sc.moduleList![index].iconFullUrl}',
                                height: 28, width: 28,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                sc.moduleList![index].moduleName ?? '',
                                style: robotoBold.copyWith(
                                  fontSize: 13,
                                  color: isActive ? const Color(0xFFF4870C) : Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                              ),
                            ]),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  // Module content
                  SizedBox(
                    height: 380,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: sc.moduleList!.length,
                      onPageChanged: (index) => sc.setModuleIndex(index >= sc.moduleList!.length ? 0 : index),
                      itemBuilder: (context, index) {
                        index = sc.moduleIndex >= sc.moduleList!.length ? 0 : sc.moduleIndex;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: isDark ? Theme.of(context).cardColor : Colors.white,
                            border: Border.all(
                              color: isDark
                                  ? Theme.of(context).primaryColor.withValues(alpha: 0.08)
                                  : Colors.grey.withValues(alpha: 0.1),
                            ),
                            boxShadow: isDark ? null : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 20, offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(children: [
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF4870C).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    sc.moduleList![index].moduleName ?? '',
                                    style: robotoBold.copyWith(fontSize: 12, color: const Color(0xFFF4870C)),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  sc.moduleList![index].moduleName ?? '',
                                  style: robotoBold.copyWith(fontSize: 22, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 12),
                                Expanded(child: SingleChildScrollView(
                                  child: Text(
                                    sc.moduleList![index].description?.replaceAll(RegExp(r'<[^>]*>'), '') ?? '',
                                    style: robotoRegular.copyWith(
                                      fontSize: 14, height: 1.6,
                                      color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.6),
                                    ),
                                  ),
                                )),
                              ],
                            )),
                            const SizedBox(width: 32),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CustomImage(
                                image: '${sc.moduleList![index].thumbnailFullUrl}',
                                height: 300, width: 350, fit: BoxFit.contain,
                              ),
                            ),
                          ]),
                        );
                      },
                    ),
                  ),
                ]);
              }),

              const SizedBox(height: 48),

              // === BENEFIT CARDS ===
              if (splashController.landingModel!.specialCriterias != null &&
                  splashController.landingModel!.specialCriterias!.isNotEmpty) ...[
                Row(
                  children: List.generate(
                    splashController.landingModel!.specialCriterias!.length > 4
                        ? 4
                        : splashController.landingModel!.specialCriterias!.length,
                    (index) {
                      final criteria = splashController.landingModel!.specialCriterias![index];
                      return Expanded(child: Padding(
                        padding: EdgeInsets.only(
                          right: index < splashController.landingModel!.specialCriterias!.length - 1 ? 16 : 0,
                        ),
                        child: Container(
                          height: 160,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: isDark ? Theme.of(context).cardColor : Colors.white,
                            border: Border.all(
                              color: isDark
                                  ? Theme.of(context).primaryColor.withValues(alpha: 0.08)
                                  : Colors.grey.withValues(alpha: 0.1),
                            ),
                            boxShadow: isDark ? null : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 12, offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Container(
                              width: 52, height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4870C).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: CustomImage(
                                  image: '${criteria.imageFullUrl}',
                                  height: 32, width: 32,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              criteria.title ?? '',
                              style: robotoBold.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center,
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                            ),
                          ]),
                        ),
                      ));
                    },
                  ),
                ),
                const SizedBox(height: 48),
              ],

              // === AVAILABLE ZONES ===
              if (splashController.landingModel?.availableZoneStatus == 1 &&
                  splashController.landingModel!.availableZoneList!.isNotEmpty) ...[
                Row(children: [
                  Expanded(flex: 2, child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CustomImage(
                      height: 320,
                      image: '${splashController.landingModel?.availableZoneImageFullUrl}',
                    ),
                  )),
                  const SizedBox(width: 48),
                  Expanded(flex: 3, child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        splashController.landingModel?.availableZoneTitle?.replaceAll(RegExp(r'<[^>]*>'), '') ?? '',
                        style: robotoBold.copyWith(fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        splashController.landingModel?.availableZoneShortDescription ?? '',
                        style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: List.generate(
                          splashController.landingModel?.availableZoneList?.length ?? 0,
                          (index) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: isDark ? Theme.of(context).cardColor : const Color(0xFFF8F8F8),
                              border: Border.all(
                                color: isDark
                                    ? Theme.of(context).primaryColor.withValues(alpha: 0.08)
                                    : Colors.grey.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Text(
                              splashController.landingModel?.availableZoneList?[index].displayName ?? '',
                              style: robotoBold.copyWith(fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )),
                ]),
                const SizedBox(height: 48),
              ],

              // === STORE REGISTRATION ===
              if (splashController.landingModel?.joinSellerStatus == 1)
                RegistrationCardWidget(isStore: true, splashController: splashController),
              if (splashController.landingModel?.joinSellerStatus == 1)
                const SizedBox(height: 32),

              // === DOWNLOAD APP SECTION (Reusing our custom widget) ===
              const DownloadAppSectionWidget(),
              const SizedBox(height: 32),

              // === DELIVERYMAN REGISTRATION ===
              if (splashController.landingModel?.joinDeliveryManStatus == 1)
                RegistrationCardWidget(isStore: false, splashController: splashController),
              if (splashController.landingModel?.joinDeliveryManStatus == 1)
                const SizedBox(height: 40),

            ]);
          }),
        ),
      ),
    );
  }

  void _handleSetLocation() async {
    if (_address != null && _controller.text.trim().isNotEmpty) {
      Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);
      ZoneResponseModel response = await Get.find<LocationController>().getZone(
        _address!.latitude, _address!.longitude, false,
      );
      if (response.isSuccess) {
        if (!AuthHelper.isGuestLoggedIn() && !AuthHelper.isLoggedIn()) {
          Get.find<AuthController>().guestLogin().then((response) {
            if (response.isSuccess) {
              Get.find<ProfileController>().setForceFullyUserEmpty();
              Get.find<LocationController>().saveAddressAndNavigate(
                _address, widget.fromSignUp, widget.route, widget.route != null, ResponsiveHelper.isDesktop(Get.context),
              );
            }
          });
        } else {
          Get.find<LocationController>().saveAddressAndNavigate(
            _address, widget.fromSignUp, widget.route, widget.route != null, ResponsiveHelper.isDesktop(Get.context),
          );
        }
      } else {
        Get.back();
        showCustomSnackBar('service_not_available_in_current_location'.tr);
      }
    } else {
      showCustomSnackBar('pick_an_address'.tr);
    }
  }

  void _handlePickFromMap() {
    if (ResponsiveHelper.isDesktop(Get.context)) {
      showGeneralDialog(context: context, pageBuilder: (_, __, ___) {
        return SizedBox(
          height: 300, width: 300,
          child: PickMapScreen(
            fromSignUp: widget.fromSignUp, canRoute: widget.route != null,
            fromAddAddress: false,
            route: widget.route ?? (widget.fromSignUp ? RouteHelper.signUp : RouteHelper.accessLocation),
            fromLandingPage: true,
          ),
        );
      });
    } else {
      Get.toNamed(RouteHelper.getPickMapRoute(
        widget.route ?? (widget.fromSignUp ? RouteHelper.signUp : RouteHelper.accessLocation),
        widget.route != null,
      ));
    }
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.isPrimary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isPrimary ? const Color(0xFFF4870C) : Colors.transparent,
          border: isPrimary ? null : Border.all(
            color: const Color(0xFFF4870C).withValues(alpha: 0.4),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: robotoBold.copyWith(
              fontSize: 13,
              color: isPrimary ? Colors.white : const Color(0xFFF4870C),
            ),
          ),
        ),
      ),
    );
  }
}
