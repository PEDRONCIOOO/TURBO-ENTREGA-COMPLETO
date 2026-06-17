import 'package:sixam_mart/common/widgets/card_design/store_card_with_distance.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/home/widgets/web/web_new_on_view_widget.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/common/widgets/card_design/store_card.dart';
import 'package:sixam_mart/common/widgets/rating_bar.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/features/store/screens/store_screen.dart';

class NewOnMartView extends StatelessWidget {
  final bool isPharmacy;
  final bool isShop;
  final bool isNewStore;
  const NewOnMartView({super.key, required this.isPharmacy, required this.isShop, this.isNewStore = false});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StoreController>(builder: (storeController) {
      List<Store>? storeList = storeController.latestStoreList;

      return storeList != null ? storeList.isNotEmpty ? Padding(
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
        child: Column(children: [

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: TitleWidget(
              title: '${'new_on'.tr} ${AppConstants.appName}',
              onTap: () => Get.toNamed(RouteHelper.getAllStoreRoute('latest')),
            ),
          ),

          SizedBox(
            height: 120,
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
              itemCount: storeList.length,
              itemBuilder: (context, index){
                return Padding(
                  padding: const EdgeInsets.only(right: Dimensions.paddingSizeDefault, top: Dimensions.paddingSizeDefault, bottom: Dimensions.paddingSizeExtraSmall),
                  child: InkWell(
                    onTap: () {
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
      ) : const SizedBox.shrink() : const WebNewOnShimmerView();
    });
  }
}

class PopularStoreShimmer extends StatelessWidget {
  final StoreController storeController;
  const PopularStoreShimmer({super.key, required this.storeController});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
        itemCount: 10,
        itemBuilder: (context, index){
          return Container(
            height: 150, width: 200,
            margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall, bottom: 5),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                boxShadow: [BoxShadow(color: Colors.grey[300]!, blurRadius: 10, spreadRadius: 1)],
            ),
            child: Shimmer(
              duration: const Duration(seconds: 2),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                Container(
                  height: 90, width: 200,
                  decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusSmall)),
                      color: Colors.grey[300],
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [

                      Container(height: 10, width: 100, color: Colors.grey[300]),
                      const SizedBox(height: 5),

                      Container(height: 10, width: 130, color: Colors.grey[300]),
                      const SizedBox(height: 5),

                      const RatingBar(rating: 0.0, size: 12, ratingCount: 0),
                    ]),
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}
