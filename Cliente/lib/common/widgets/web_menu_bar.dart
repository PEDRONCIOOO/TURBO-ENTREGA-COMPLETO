import 'package:flutter/cupertino.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/hover/text_hover.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/auth/widgets/auth_dialog_widget.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/common/controllers/theme_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_dropdown.dart';

class WebMenuBar extends StatelessWidget implements PreferredSizeWidget {
  const WebMenuBar({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: isDark ? Border(bottom: BorderSide(color: primaryColor.withValues(alpha: 0.1))) : null,
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: Dimensions.webMaxWidth,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [

              // Logo
              InkWell(
                onTap: () => Get.toNamed(RouteHelper.getInitialRoute()),
                child: Image.asset(Images.logo, width: 100, height: 42),
              ),
              const SizedBox(width: 16),

              // Location chip
              GetBuilder<LocationController>(builder: (locationController) {
                final address = AddressHelper.getUserAddressFromSharedPref();
                return InkWell(
                  onTap: () => Get.find<LocationController>().navigateToLocationScreen('home'),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 280),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          address != null && AuthHelper.isLoggedIn()
                              ? (address.addressType == 'home'
                                  ? Icons.home_filled
                                  : address.addressType == 'office'
                                      ? Icons.work
                                      : Icons.location_on)
                              : Icons.location_on,
                          size: 14,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                address != null && AuthHelper.isLoggedIn()
                                    ? address.addressType!.tr
                                    : 'your_location'.tr,
                                style: robotoMedium.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).textTheme.bodyLarge!.color,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                address?.address ?? 'set_your_delivery_location'.tr,
                                style: robotoRegular.copyWith(
                                  fontSize: 9,
                                  color: Theme.of(context).disabledColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down, size: 14, color: Theme.of(context).disabledColor),
                      ],
                    ),
                  ),
                );
              }),

              const Spacer(),

              // Nav items as pills - active based on current route
              Builder(builder: (context) {
                final currentRoute = Get.currentRoute;
                return Row(children: [
                  _NavPill(title: 'home'.tr, isActive: currentRoute == '/' || currentRoute.startsWith('/home'), onTap: () {
                    if (AddressHelper.getUserAddressFromSharedPref() != null) {
                      Get.toNamed(RouteHelper.getInitialRoute());
                    } else {
                      showCustomSnackBar('please_select_address_first'.tr);
                    }
                  }),
                  const SizedBox(width: 4),
                  _NavPill(title: 'categories'.tr, isActive: currentRoute.startsWith('/category'), onTap: () {
                    if (AddressHelper.getUserAddressFromSharedPref() != null) {
                      Get.toNamed(RouteHelper.getCategoryRoute());
                    } else {
                      showCustomSnackBar('please_select_address_first'.tr);
                    }
                  }),
                  const SizedBox(width: 4),
                  _NavPill(title: 'Favoritos'.tr, isActive: currentRoute.startsWith('/favourite'), onTap: () {
                    if (AddressHelper.getUserAddressFromSharedPref() != null) {
                      Get.toNamed(RouteHelper.getFavouriteRoute());
                    } else {
                      showCustomSnackBar('please_select_address_first'.tr);
                    }
                  }),
                  const SizedBox(width: 4),
                  _NavPill(title: 'stores'.tr, isActive: currentRoute.startsWith('/stores'), onTap: () {
                    if (AddressHelper.getUserAddressFromSharedPref() != null) {
                      Get.toNamed(RouteHelper.getAllStoreRoute('popular'));
                    } else {
                      showCustomSnackBar('please_select_address_first'.tr);
                    }
                  }),
                ]);
              }),

              const SizedBox(width: 12),
              Container(width: 1, height: 24, color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
              const SizedBox(width: 12),

              // Icon buttons in rounded containers
              _HeaderIconButton(
                icon: CupertinoIcons.search,
                onTap: () {
                  if (AddressHelper.getUserAddressFromSharedPref() != null) {
                    Get.toNamed(RouteHelper.getSearchRoute());
                  } else {
                    showCustomSnackBar('please_select_address_first'.tr);
                  }
                },
              ),
              const SizedBox(width: 8),
              _HeaderIconButton(
                icon: CupertinoIcons.bell_fill,
                onTap: () {
                  if (AddressHelper.getUserAddressFromSharedPref() != null) {
                    Get.toNamed(RouteHelper.getNotificationRoute());
                  } else {
                    showCustomSnackBar('please_select_address_first'.tr);
                  }
                },
              ),
              const SizedBox(width: 8),
              _HeaderIconButton(
                icon: Icons.shopping_cart_outlined,
                isCart: true,
                onTap: () {
                  if (AddressHelper.getUserAddressFromSharedPref() != null) {
                    Get.toNamed(RouteHelper.getCartRoute());
                  } else {
                    showCustomSnackBar('please_select_address_first'.tr);
                  }
                },
              ),
              const SizedBox(width: 8),

              // Theme toggle
              GetBuilder<ThemeController>(builder: (themeController) {
                return _HeaderIconButton(
                  icon: themeController.darkTheme
                      ? CupertinoIcons.moon_stars_fill
                      : CupertinoIcons.sun_min_fill,
                  onTap: () => themeController.toggleTheme(),
                );
              }),

              const SizedBox(width: 12),

              // Profile/Sign in button
              GetBuilder<AuthController>(builder: (authController) {
                return InkWell(
                  onTap: () {
                    if (authController.isLoggedIn()) {
                      Get.toNamed(RouteHelper.getProfileRoute());
                    } else {
                      Get.dialog(
                        const Center(child: AuthDialogWidget(exitFromApp: false, backFromThis: false)),
                        barrierDismissible: false,
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          authController.isLoggedIn()
                              ? Icons.person_rounded
                              : Icons.login_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          authController.isLoggedIn() ? 'profile'.tr : 'sign_in'.tr,
                          style: robotoMedium.copyWith(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(width: 8),

              // Menu drawer
              _HeaderIconButton(
                icon: Icons.menu_rounded,
                onTap: () => Scaffold.of(context).openEndDrawer(),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size(Dimensions.webMaxWidth, 60);
}

class _NavPill extends StatelessWidget {
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const _NavPill({required this.title, this.isActive = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextHover(builder: (hovered) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).primaryColor
                : hovered
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.08)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            title,
            style: robotoMedium.copyWith(
              fontSize: 12,
              color: isActive
                  ? Colors.white
                  : hovered
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).textTheme.bodyLarge!.color,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      );
    });
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isCart;

  const _HeaderIconButton({required this.icon, required this.onTap, this.isCart = false});

  @override
  Widget build(BuildContext context) {
    return TextHover(builder: (hovered) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: hovered
                ? Theme.of(context).primaryColor.withValues(alpha: 0.12)
                : Theme.of(context).primaryColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: isCart
              ? GetBuilder<CartController>(builder: (cartController) {
                  return Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Icon(icon, size: 16, color: Theme.of(context).primaryColor),
                      if (cartController.cartList.isNotEmpty)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            height: 14,
                            width: 14,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red.shade500,
                            ),
                            child: Text(
                              cartController.cartList.length.toString(),
                              style: robotoRegular.copyWith(fontSize: 8, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  );
                })
              : Icon(icon, size: 16, color: Theme.of(context).primaryColor),
        ),
      );
    });
  }
}
