import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:url_launcher/url_launcher_string.dart';

class StoreBannerWidget extends StatefulWidget {
  final StoreController storeController;
  const StoreBannerWidget({super.key, required this.storeController});

  @override
  State<StoreBannerWidget> createState() => _StoreBannerWidgetState();
}

class _StoreBannerWidgetState extends State<StoreBannerWidget> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return (widget.storeController.storeBanners != null && widget.storeController.storeBanners!.isNotEmpty) ? Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
      child: Column(
        children: [
          CarouselSlider.builder(
            options: CarouselOptions(
              autoPlay: true,
              enlargeCenterPage: true,
              disableCenter: true,
              viewportFraction: 1,
              autoPlayInterval: const Duration(seconds: 4),
              onPageChanged: (index, reason) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
            itemCount: widget.storeController.storeBanners!.length,
            itemBuilder: (context, index, _) {
              return InkWell(
                onTap: () async {
                  String url = widget.storeController.storeBanners![index].defaultLink!;
                  if (await canLaunchUrlString(url)) {
                    await launchUrlString(url, mode: LaunchMode.externalApplication);
                  } else {
                    showCustomSnackBar('unable_to_found_url'.tr);
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  child: CustomImage(
                    image: '${widget.storeController.storeBanners![index].imageFullUrl}',
                    height: context.width * 0.3,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: Dimensions.paddingSizeSmall),
          
          // Indicadores de pontos
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.storeController.storeBanners!.map((banner) {
              int index = widget.storeController.storeBanners!.indexOf(banner);
              return Container(
                width: index == _currentIndex ? 8 : 6,
                height: index == _currentIndex ? 8 : 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _currentIndex 
                    ? Theme.of(context).primaryColor 
                    : Theme.of(context).primaryColor.withOpacity(0.5),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ) : const SizedBox();
  }
}
