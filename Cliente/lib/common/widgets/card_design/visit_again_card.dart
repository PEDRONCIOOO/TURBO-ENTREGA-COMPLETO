import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/common/widgets/hover/text_hover.dart';
import 'package:sixam_mart/common/widgets/not_available_widget.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/store/screens/store_screen.dart';

class VisitAgainCard extends StatelessWidget {
  final Store store;
  final bool fromFood;
  const VisitAgainCard({super.key, required this.store, required this.fromFood});

  @override
  Widget build(BuildContext context) {
    bool isAvailable = store.open == 1 && store.active!;

    return TextHover(
      builder: (hovered) {
        return CustomInkWell(
          onTap: () {
            Get.toNamed(
              RouteHelper.getStoreRoute(id: store.id, page: 'store'),
              arguments: StoreScreen(store: store, fromModule: false),
            );
          },
          radius: 100,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 70, 
                  width: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Stack(
                      children: [
                        CustomImage(
                          isHovered: hovered,
                          image: '${store.logoFullUrl}',
                          fit: BoxFit.cover,
                          height: 70,
                          width: 70,
                        ),
                        isAvailable ? const SizedBox() : NotAvailableWidget(
                          isStore: true, 
                          store: store, 
                          fontSize: 8, 
                          isAllSideRound: true
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}
