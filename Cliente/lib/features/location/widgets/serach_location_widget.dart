import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart/features/location/widgets/location_search_dialog_widget.dart';
import 'package:sixam_mart/features/parcel/controllers/parcel_controller.dart';
import 'package:sixam_mart/util/styles.dart';

class SearchLocationWidget extends StatelessWidget {
  final GoogleMapController? mapController;
  final String? pickedAddress;
  final bool? isEnabled;
  final bool? isPickedUp;
  final bool? fromDialog;
  final String? hint;
  const SearchLocationWidget({super.key, required this.mapController, required this.pickedAddress, required this.isEnabled, this.isPickedUp, this.hint, this.fromDialog = false});

  @override
  Widget build(BuildContext context) {
    final bool hasAddress = pickedAddress != null && pickedAddress!.isNotEmpty;
    final bool isActive = isEnabled == null || isEnabled!;
    final Color primaryColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: () {
        Get.dialog(LocationSearchDialogWidget(mapController: mapController, isPickedUp: isPickedUp));
        if(isEnabled != null) {
          Get.find<ParcelController>().setIsPickedUp(isPickedUp, true);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: hasAddress
              ? primaryColor.withValues(alpha: 0.05)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEnabled != null && !fromDialog!
                ? (isActive ? primaryColor : Theme.of(context).disabledColor)
                : (hasAddress ? primaryColor.withValues(alpha: 0.2) : Colors.grey.shade300),
            width: isActive && isEnabled != null && !fromDialog! ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive
                  ? primaryColor.withValues(alpha: 0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              hasAddress ? Icons.location_on_rounded : Icons.search_rounded,
              size: 20,
              color: isActive ? primaryColor : Theme.of(context).disabledColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasAddress ? 'Endereço' : (hint ?? 'search_location'.tr),
                  style: robotoMedium.copyWith(
                    fontSize: 11,
                    color: isActive ? primaryColor : Theme.of(context).disabledColor,
                    letterSpacing: 0.3,
                  ),
                ),
                if (hasAddress) ...[
                  const SizedBox(height: 2),
                  Text(
                    pickedAddress!,
                    style: robotoRegular.copyWith(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.keyboard_arrow_right_rounded,
            size: 22,
            color: Colors.grey.shade400,
          ),
        ]),
      ),
    );
  }
}
