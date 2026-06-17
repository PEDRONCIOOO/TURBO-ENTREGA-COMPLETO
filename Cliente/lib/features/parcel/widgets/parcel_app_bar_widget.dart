import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/notification/controllers/notification_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class ParcelAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final bool? backButton;
  const ParcelAppBarWidget({super.key, this.backButton = true});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).cardColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leadingWidth: 0,
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      title: GetBuilder<SplashController>(
        builder: (splashController) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
              (splashController.module != null && splashController.configModel!.module == null && splashController.moduleList != null && splashController.moduleList!.length != 1) ? GestureDetector(
                onTap: () => splashController.removeModule(),
                child: Container(
                  height: 38, width: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(Images.moduleIcon, height: 20, width: 20, color: Theme.of(context).textTheme.bodyLarge!.color),
                ),
              ) : const SizedBox(),
              SizedBox(width: (splashController.module != null && splashController.configModel!.module
                  == null && splashController.moduleList != null && splashController.moduleList!.length != 1) ? 8 : 0),
              Expanded(child: GestureDetector(
                onTap: () => Get.find<LocationController>().navigateToLocationScreen('home'),
                child: GetBuilder<LocationController>(builder: (locationController) {
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
                              AddressHelper.getUserAddressFromSharedPref()!.addressType!.tr,
                              style: robotoMedium.copyWith(
                                color: Theme.of(context).textTheme.bodyLarge!.color,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              AddressHelper.getUserAddressFromSharedPref()!.address ?? '',
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
          );
        }
      ),
    );
  }

  @override
  Size get preferredSize => Size(Dimensions.webMaxWidth, GetPlatform.isDesktop ? 70 : 56);
}