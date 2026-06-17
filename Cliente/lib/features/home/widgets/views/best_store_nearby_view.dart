import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/rating_bar.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:sixam_mart/features/store/screens/store_screen.dart';

class BestStoreNearbyView extends StatelessWidget {
  const BestStoreNearbyView({super.key});

  @override
  Widget build(BuildContext context) {
    bool isPharmacy = Get.find<SplashController>().module != null && Get.find<SplashController>().module!.moduleType.toString() == AppConstants.pharmacy;
    bool isFood = Get.find<SplashController>().module != null && Get.find<SplashController>().module!.moduleType.toString() == AppConstants.food;

    return GetBuilder<StoreController>(builder: (storeController) {
      List<Store>? storeList = isPharmacy ? storeController.featuredStoreList : storeController.popularStoreList;

      return storeList != null ? storeList.isNotEmpty ? Padding(
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
        child: Column(children: [

          Padding(
            padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault, left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault),
            child: TitleWidget(
              title: isPharmacy ? 'featured_store'.tr : 'best_store_nearby'.tr,
              onTap: () => Get.toNamed(RouteHelper.getAllStoreRoute(isPharmacy ? 'featured' : 'popular', isNearbyStore: true)),
            ),
          ),

          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
              itemCount: storeList.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: Dimensions.paddingSizeDefault, top: Dimensions.paddingSizeDefault, bottom: Dimensions.paddingSizeExtraSmall),
                  child: InkWell(
                    onTap: () {
                      if(Get.find<SplashController>().moduleList != null) {
                        for(ModuleModel module in Get.find<SplashController>().moduleList!) {
                          if(module.id == storeList[index].moduleId) {
                            Get.find<SplashController>().setModule(module);
                            break;
                          }
                        }
                      }
                      Get.toNamed(
                        RouteHelper.getStoreRoute(id: storeList[index].id, page: 'store'),
                        arguments: StoreScreen(store: storeList[index], fromModule: true),
                      );
                    },
                    child: Column(
                      children: [
                        Container(
                          height: 70, 
                          width: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(35),
                            child: CustomImage(
                              image: '${storeList[index].logoFullUrl}',
                              fit: BoxFit.cover,
                              height: 70,
                              width: 70,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 80,
                          child: Text(
                            storeList[index].name ?? '',
                            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ]),
      ) : const SizedBox() : BestStoreNearbyShimmer(isPharmacy: isPharmacy, isFood: isFood);
    });
  }
}

class BestStoreNearbyShimmer extends StatelessWidget {
  final bool isPharmacy;
  final bool isFood;
  const BestStoreNearbyShimmer({super.key, required this.isPharmacy, required this.isFood});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        (isPharmacy || isFood) ? Padding(
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault, left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault),
          child: TitleWidget(
            title: isPharmacy ? 'featured_store'.tr : 'best_store_nearby'.tr,
          ),
        ) : Padding(
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault, left: Dimensions.paddingSizeLarge, right: Dimensions.paddingSizeDefault),
          child: FittedBox(
            child: Row(children: [

              Container(
                height: 2, width: context.width * 0.75,
                color: Theme.of(context).primaryColor.withOpacity(0.2),
              ),
              Container(transform: Matrix4.translationValues(-5, 0, 0),child: Icon(Icons.arrow_forward, size: 18, color: Theme.of(context).primaryColor.withOpacity(0.5))),


              Padding(
                padding: const EdgeInsets.fromLTRB(10, 5, 0, 5),
                child: Text(
                  'see_all'.tr,
                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor, decoration: TextDecoration.underline),
                ),
              ),

            ]),
          ),
        ),

        isPharmacy ? SizedBox(
          height: 130, width: Get.width,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraSmall),
            itemCount: 6,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault, top: Dimensions.paddingSizeSmall),
                child: Shimmer(
                  duration: const Duration(seconds: 2),
                  enabled: true,
                  child: Container(
                    width: 300,
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    ),
                    child: Column(children: [

                      Expanded(
                        flex: 5,
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

                          ClipRRect(
                            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                            child: Container(
                              height: 50, width: 50,
                              color: Theme.of(context).cardColor,
                            ),
                          ),
                          const SizedBox(width: Dimensions.paddingSizeSmall),

                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                              Container(
                                height: 10, width: 100,
                                color: Theme.of(context).cardColor,
                              ),
                              const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                              !isPharmacy ? const RatingBar(
                                rating: 0,
                                ratingCount: 0,
                                size: 12,
                              ) : Row(children: [

                                Icon(Icons.storefront, size: 15, color: Theme.of(context).primaryColor),
                                const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                                Expanded(
                                  child: Container(
                                    height: 10, width: 100,
                                    color: Theme.of(context).cardColor,
                                  ),
                                ),

                              ]),
                              const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                              !isPharmacy ? Row(children: [

                                Icon(Icons.storefront, size: 15, color: Theme.of(context).primaryColor),
                                const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                                Expanded(
                                  child: Container(
                                    height: 10, width: 100,
                                    color: Theme.of(context).cardColor,
                                  ),
                                ),

                              ]) : Container(
                                height: 10, width: 100,
                                color: Theme.of(context).cardColor,
                              ),

                            ]),
                          ),

                        ]),
                      ),
                      Expanded(
                        flex: 2,
                        child: Row(children: [

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 3),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                            ),
                            child: Row(children: [

                              Image.asset(Images.distanceLine, height: 15, width: 15),
                              const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                              Container(
                                height: 10, width: 50,
                                color: Theme.of(context).cardColor,
                              ),
                              const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                              Container(
                                height: 10, width: 50,
                                color: Theme.of(context).cardColor,
                              ),
                            ]),
                          ),
                          const Spacer(),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 3),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                            ),
                            child: Row(children: [

                              Image.asset(Images.clockIcon, height: 15, width: 15),
                              const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                              Container(
                                height: 10, width: 50,
                                color: Theme.of(context).cardColor,
                              ),
                            ]),
                          ),
                        ]),
                      ),
                    ]),
                  ),
                ),
              );
            },
          ),
        ) : isFood ? SizedBox(
          height: 215,
          child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault, bottom: Dimensions.paddingSizeDefault),
              itemCount: 6,
              itemBuilder: (context, index){
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                  child: Stack(children: [
                    Shimmer(
                      duration: const Duration(seconds: 2),
                      enabled: true,
                      child: Container(
                        width: 260,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        ),
                        child: Column(children: [
                          Expanded(
                            flex: 1,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(Dimensions.radiusDefault), topRight: Radius.circular(Dimensions.radiusDefault)),
                              child: Stack(clipBehavior: Clip.none, children: [
                                Container(
                                  height: double.infinity, width: double.infinity,
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                ),

                                Positioned(
                                  top: 15, right: 15,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Theme.of(context).cardColor.withOpacity(0.8),
                                    ),
                                    child: Icon(Icons.favorite_border, color: Theme.of(context).primaryColor, size: 20),
                                  ),
                                ),
                              ]),
                            ),
                          ),

                          Expanded(
                            flex: 1,
                            child: Column(children: [
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 95),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Expanded(
                                      child: Container(
                                        height: 5, width: 100,
                                        color: Theme.of(context).cardColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),

                                    Row(children: [
                                      const Icon(Icons.location_on_outlined, color: Colors.blue, size: 15),
                                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                                      Expanded(
                                        child: Container(
                                          height: 10, width: 100,
                                          color: Theme.of(context).cardColor,
                                        ),
                                      ),
                                    ]),
                                  ]),
                                ),
                              ),

                              Expanded(
                                flex: 3,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                    Container(
                                      height: 10, width: 70,
                                      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: Dimensions.paddingSizeSmall),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                                      ),
                                    ),

                                    Container(
                                      height: 20, width: 65,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                      ),
                                    ),
                                  ]),
                                ),
                              ),
                            ]),
                          ),
                        ]),
                      ),
                    ),

                    Positioned(
                      top: 60, left: 15,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            height: 65, width: 65,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),
                );
              }),
        ) : SizedBox(
          height: 160, width: Get.width,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
            itemCount: 10,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault, top: Dimensions.paddingSizeDefault),
                child: Stack(clipBehavior: Clip.none, children: [
                  Shimmer(
                    duration: const Duration(seconds: 2),
                    enabled: true,
                    child: Container(
                      height: 155, width: 250,
                      margin: const EdgeInsets.only(top: 30),
                      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                        Expanded(
                          flex: 3,
                          child: Row(children: [

                            const Expanded(flex: 3, child: SizedBox()),

                            Expanded(
                              flex: 4,
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                                  Row(children: [

                                    Container(
                                      height: 10, width: 50,
                                      color: Theme.of(context).cardColor,
                                    ),

                                  ]),
                                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                                  Row(children: [

                                    Icon(Icons.star, size: 15, color: Theme.of(context).primaryColor),
                                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                                    Container(
                                      height: 10, width: 50,
                                      color: Theme.of(context).cardColor,
                                    ),

                                  ]),
                                ]),
                                const Spacer(),

                                Icon(Icons.favorite_border, color: Theme.of(context).disabledColor, size: 20),

                              ]),
                            ),
                          ]),
                        ),

                        Expanded(
                          flex: 1,
                          child: Container(
                            height: 10, width: 100,
                            color: Theme.of(context).cardColor,
                          ),
                        ),

                      ]),
                    ),
                  ),
                  Positioned(
                    top: -5, left: 15,
                    child: Container(
                      height: 90, width: 90,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                          child: Stack(children: [

                            Container(
                              height: double.infinity, width: double.infinity,
                              color: Colors.grey[300],
                            ),

                            Positioned(
                              bottom: 0, left: 0,
                              child: Container(
                                width: 80,
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                ),
                                child: Row(children: [

                                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                                  Container(
                                    height: 10, width: 50,
                                    color: Theme.of(context).cardColor,
                                  ),
                                ]),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ]),
              );
            },
          ),
        ),
      ],
    );
  }
}
