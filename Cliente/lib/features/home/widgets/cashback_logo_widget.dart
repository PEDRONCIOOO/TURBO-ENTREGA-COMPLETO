import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_asset_image_widget.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/util/dimensions.dart';
class CashBackLogoWidget extends StatelessWidget {
  const CashBackLogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        color: Theme.of(context).primaryColor,
      ),
      child: Stack(
        children: [
          const CustomAssetImageWidget(
            Images.cashBack,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 100,
          ),
          Positioned(
            top: 15,
            left: 15,
            child: Text(
              'cash_back'.tr,
              style: robotoBold.copyWith(
                color: Colors.white,
                fontSize: Dimensions.fontSizeLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
