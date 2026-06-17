import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/card_design/visit_again_card.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class VisitAgainView extends StatefulWidget {
  final bool? fromFood;
  const VisitAgainView({super.key, this.fromFood = false});

  @override
  State<VisitAgainView> createState() => _VisitAgainViewState();
}

class _VisitAgainViewState extends State<VisitAgainView> {

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StoreController>(builder: (storeController) {
        List<Store>? stores = storeController.visitAgainStoreList;

      return stores != null ? stores.isNotEmpty ? Padding(
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
              child: Text(
                widget.fromFood! ? "wanna_try_again".tr : "visit_again".tr, 
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: stores.length,
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return VisitAgainCard(store: stores[index], fromFood: widget.fromFood!);
                },
              ),
            ),
          ],
        ),
      ) : const SizedBox() : const VisitAgainShimmerView();
    });
  }
}

class VisitAgainShimmerView extends StatelessWidget {
  const VisitAgainShimmerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
            child: Shimmer(
              child: Container(
                height: 20, 
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                ),
              ),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                  child: Shimmer(
                    child: Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[300],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
