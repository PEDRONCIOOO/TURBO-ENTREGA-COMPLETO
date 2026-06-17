import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/card_design/store_card_with_distance.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';

class FeaturedStoresVerticalView extends StatelessWidget {
  const FeaturedStoresVerticalView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StoreController>(builder: (storeController) {
      return Container(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Lojas em Destaque',
                      style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Ver Todas',
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              
              storeController.featuredStoreList != null ? 
              storeController.featuredStoreList!.isNotEmpty ? 
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: storeController.featuredStoreList!.length > 10 ? 10 : storeController.featuredStoreList!.length,
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                separatorBuilder: (context, index) => const SizedBox(height: Dimensions.paddingSizeSmall),
                itemBuilder: (context, index) {
                  return StoreCardWithDistance(store: storeController.featuredStoreList![index]);
                },
              ) : const SizedBox() : const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      );
    });
  }
}
