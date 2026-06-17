import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/home/widgets/web/module_widget.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/parcel/controllers/parcel_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/features/home/widgets/bad_weather_widget.dart';
import 'package:sixam_mart/features/parcel/widgets/parcel_app_bar_widget.dart';
import 'package:sixam_mart/features/parcel/widgets/deliver_item_card_widget.dart';
import 'package:sixam_mart/features/parcel/widgets/why_choose_section_widget.dart';
import 'package:sixam_mart/features/parcel/widgets/download_app_section_widget.dart';
import 'package:sixam_mart/common/widgets/platform_stats_widget.dart';
import 'package:sixam_mart/common/widgets/promo_banner_widget.dart';
import 'package:sixam_mart/features/parcel/widgets/get_service_video_widget.dart';
import 'package:sixam_mart/features/parcel/widgets/sevice_info_list_widget.dart';

class ParcelCategoryScreen extends StatefulWidget {
  const ParcelCategoryScreen({super.key});

  @override
  State<ParcelCategoryScreen> createState() => _ParcelCategoryScreenState();
}

class _ParcelCategoryScreenState extends State<ParcelCategoryScreen> {

  @override
  void initState() {
    super.initState();
    if(AuthHelper.isLoggedIn() && Get.find<ProfileController>().userInfoModel == null) {
      Get.find<ProfileController>().getUserInfo();
    }
    Get.find<BannerController>().getParcelOtherBannerList(true);
    Get.find<ParcelController>().getWhyChooseDetails();
    Get.find<ParcelController>().getVideoContentDetails();
    
    // Inicializa a localizaÃ§Ã£o do usuÃ¡rio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<LocationController>().getCurrentLocation(false).then((_) {
        // Atualiza a interface apÃ³s obter a localizaÃ§Ã£o
        if (mounted) setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).scaffoldBackgroundColor
          : const Color(0xFFFAFAFA),
      appBar: ResponsiveHelper.isDesktop(context) ? null : const ParcelAppBarWidget(),
      body: GetBuilder<ParcelController>(builder: (parcelController) {
        return GetBuilder<BannerController>(builder: (bannerController) {

          bool showVideoAndServices = parcelController.videoContentDetails != null && (parcelController.videoContentDetails!.bannerVideo != null || parcelController.videoContentDetails!.bannerImageFullUrl != null);
          return Stack(clipBehavior: Clip.none, children: [

            RefreshIndicator(
              onRefresh: () async {
                await Get.find<ParcelController>().getParcelCategoryList();
                await Get.find<BannerController>().getParcelOtherBannerList(true);
                await Get.find<ParcelController>().getWhyChooseDetails();
                await Get.find<ParcelController>().getVideoContentDetails();
              },
              child: SingleChildScrollView(
                padding: ResponsiveHelper.isDesktop(context)
                    ? EdgeInsets.zero
                    : const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 100),
                child: FooterView(child: SizedBox(width: Dimensions.webMaxWidth,
                    child: Column(crossAxisAlignment: ResponsiveHelper.isDesktop(context) ? CrossAxisAlignment.center : CrossAxisAlignment.start, children: [

                      // Banner carousel with premium styling
                      bannerController.parcelOtherBannerModel != null && bannerController.parcelOtherBannerModel!.banners != null
                          ? bannerController.parcelOtherBannerModel!.banners!.isNotEmpty
                              ? Column(children: [
                                  CarouselSlider.builder(
                                    itemCount: bannerController.parcelOtherBannerModel!.banners!.length,
                                    options: CarouselOptions(
                                      autoPlay: true,
                                      height: ResponsiveHelper.isDesktop(context) ? 395 : 140,
                                      enlargeCenterPage: true,
                                      disableCenter: true,
                                      viewportFraction: 1,
                                      autoPlayInterval: const Duration(seconds: 5),
                                      onPageChanged: (index, reason) {
                                        bannerController.setCurrentIndex(index, false);
                                      },
                                    ),
                                    itemBuilder: (context, index, realIndex) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Stack(children: [
                                          CustomImage(
                                            image: '${bannerController.parcelOtherBannerModel!.banners![index].imageFullUrl}',
                                            height: ResponsiveHelper.isDesktop(context) ? 395 : 140,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                          Positioned.fill(
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Colors.transparent,
                                                    Colors.black.withValues(alpha: 0.4),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ]),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      bannerController.parcelOtherBannerModel!.banners!.length,
                                      (index) => AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        margin: const EdgeInsets.symmetric(horizontal: 2),
                                        height: 6,
                                        width: bannerController.currentIndex == index ? 20 : 6,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(3),
                                          color: bannerController.currentIndex == index
                                              ? Theme.of(context).primaryColor
                                              : Theme.of(context).primaryColor.withValues(alpha: 0.3),
                                        ),
                                      ),
                                    ),
                                  ),
                                ])
                              // Fallback: gradient hero when no banners
                              : Container(
                                  height: ResponsiveHelper.isDesktop(context) ? 395 : 140,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Color(0xFFF4870C), Color(0xFFFF6B35)],
                                    ),
                                  ),
                                  child: Stack(children: [
                                    Positioned(right: -10, top: -10, child: Container(
                                      width: 80, height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(alpha: 0.12),
                                      ),
                                    )),
                                    Positioned(right: 20, bottom: -15, child: Container(
                                      width: 50, height: 50,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(alpha: 0.08),
                                      ),
                                    )),
                                    Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text('Envie qualquer\ncoisa, agora.',
                                            style: robotoBold.copyWith(fontSize: 18, color: Colors.white, height: 1.2)),
                                          const SizedBox(height: 4),
                                          Text('Entrega rápida e segura na sua cidade',
                                            style: robotoRegular.copyWith(fontSize: 12, color: Colors.white.withValues(alpha: 0.85))),
                                        ],
                                      ),
                                    ),
                                  ]),
                                )
                          : Shimmer(
                              duration: const Duration(seconds: 2),
                              enabled: true,
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                height: ResponsiveHelper.isDesktop(context) ? 395 : 140,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                      SizedBox(height: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeDefault : Dimensions.paddingSizeSmall),

                      // Download App Section - desktop only
                      if (ResponsiveHelper.isDesktop(context))
                        const DownloadAppSectionWidget(),

                      // Platform stats - desktop only
                      if (ResponsiveHelper.isDesktop(context))
                        const PlatformStatsWidget(),

                      // Promo banner - desktop only
                      if (ResponsiveHelper.isDesktop(context))
                        const PromoBannerWidget(),

                      const BadWeatherWidget(inParcel: true),

                      Text('O que você precisa enviar?', style: robotoBold.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),

                      Text('Escolha a categoria da sua entrega', style: robotoRegular.copyWith(fontSize: 13, color: Theme.of(context).disabledColor)),
                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      parcelController.parcelCategoryList != null ? parcelController.parcelCategoryList!.isNotEmpty ? Column(
                        children: [
                          GridView.builder(
                            controller: ScrollController(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: ResponsiveHelper.isDesktop(context) ? 3 : 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              mainAxisExtent: ResponsiveHelper.isDesktop(context) ? 140 : 140,
                            ),
                            itemCount: parcelController.parcelCategoryList!.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemBuilder: (context, index) {
                              return CustomInkWell(
                                onTap: () {
                                  Get.toNamed(RouteHelper.getParcelLocationRoute(parcelController.parcelCategoryList![index]));
                                },
                                radius: Dimensions.radiusDefault,
                                child: DeliverItemCardWidget(
                                  isDeliverItem: true,
                                  image: '${parcelController.parcelCategoryList![index].imageFullUrl}',
                                  itemName: parcelController.parcelCategoryList![index].name!,
                                  description: parcelController.parcelCategoryList![index].description!,
                                ),
                              );
                            },
                          ),
                          const WhyChooseSectionWidget(),
                        ],
                      ) : Center(child: Text('no_parcel_category_found'.tr)) : ParcelShimmer(isEnabled: parcelController.parcelCategoryList == null, isDeliveryItem: true),
                    ]))),
                  ),
            ),

            ResponsiveHelper.isDesktop(context) ? const Positioned(right: 0, top: 0, bottom: 0, child: Center(child: ModuleWidget())) : const SizedBox(),

          ]);
        });
      }),
    );
  }
}


class ParcelShimmer extends StatelessWidget {
  final bool isEnabled;
  final bool isDeliveryItem;
  const ParcelShimmer({super.key, required this.isEnabled, required this.isDeliveryItem});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: isDeliveryItem ? SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveHelper.isDesktop(context) ? 3 : 2,
        crossAxisSpacing: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeLarge : Dimensions.paddingSizeSmall,
        mainAxisSpacing: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeLarge : Dimensions.paddingSizeSmall,
        mainAxisExtent: ResponsiveHelper.isDesktop(context) ? 100 : 75,
      ) : SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveHelper.isDesktop(context) ? 3 : ResponsiveHelper.isTab(context) ? 2 : 1,
        crossAxisSpacing: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeLarge : Dimensions.paddingSizeSmall,
        mainAxisSpacing: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeLarge : Dimensions.paddingSizeSmall,
        mainAxisExtent: ResponsiveHelper.isDesktop(context) ? 100 : 80,
      ),
      itemCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          ),
          child: Shimmer(
            duration: const Duration(seconds: 2),
            enabled: isEnabled,
            child: Row(children: [

              Container(
                height: 50, width: 50, alignment: Alignment.center,
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),

              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(height: 15, width: 200, color: Colors.grey[300]),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Container(height: 15, width: 100, color: Colors.grey[300]),
              ])),
              const SizedBox(width: Dimensions.paddingSizeSmall),
            ]),
          ),
        );
      },
    );
  }
}

class VideoContentDetailsShimmer extends StatelessWidget {
  const VideoContentDetailsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveHelper.isDesktop(context) ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [

      Expanded(
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: 350,
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
        ),
      ),
      const SizedBox(width: 125),

      Expanded(
        child: ListView.builder(
          physics: const ScrollPhysics(),
          shrinkWrap: true,
          itemCount: 6,
          itemBuilder: (context, index) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              Row(children: [
                Container(
                  height: 14, width: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeDefault),

                Container(height: 15, width: 200, color: Colors.grey[300]),
              ]),

              Container(
                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: 22.5),
                margin: const EdgeInsets.only(left: 7),
                decoration: BoxDecoration(
                    border: index == 6 - 1 ? null : Border(left: BorderSide(width: 1, color: Theme.of(context).disabledColor))),
                child: Container(height: 15, width: 100, color: Colors.grey[300]),
              ),
            ]);
          },
        ),
      ),
    ]) : Column(children: [

      Container(
        width: MediaQuery.of(context).size.width,
        height: 185,
        padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
      ),
      const SizedBox(height: Dimensions.paddingSizeLarge),

      ListView.builder(
        physics: const ScrollPhysics(),
        shrinkWrap: true,
        itemCount: 6,
        itemBuilder: (context, index) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            Row(children: [
              Container(
                height: 14, width: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeDefault),

              Container(height: 15, width: 200, color: Colors.grey[300]),
            ]),

            Container(
              padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: 22.5),
              margin: const EdgeInsets.only(left: 7),
              decoration: BoxDecoration(
                  border: index == 6 - 1 ? null : Border(left: BorderSide(width: 1, color: Theme.of(context).disabledColor))),
              child: Container(height: 15, width: 100, color: Colors.grey[300]),
            ),
          ]);
        },
      ),
    ]);
  }
}

