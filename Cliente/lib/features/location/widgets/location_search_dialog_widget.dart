import 'package:flutter/foundation.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/location/domain/models/prediction_model.dart';
import 'package:sixam_mart/features/parcel/controllers/parcel_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationSearchDialogWidget extends StatelessWidget {
  final GoogleMapController? mapController;
  final bool? isPickedUp;
  final bool isFrom;
  const LocationSearchDialogWidget({super.key, required this.mapController, this.isPickedUp, this.isFrom = false});

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    final Color primaryColor = Theme.of(context).primaryColor;

    return Container(
      width: 500,
      margin: EdgeInsets.only(
        top: ResponsiveHelper.isDesktop(context) ? 180 : 60,
        left: 16,
        right: 16,
      ),
      alignment: Alignment.topCenter,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: ResponsiveHelper.isDesktop(context) ? 600 : Dimensions.webMaxWidth,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: TypeAheadField(
              textFieldConfiguration: TextFieldConfiguration(
                controller: controller,
                textInputAction: TextInputAction.search,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                keyboardType: TextInputType.streetAddress,
                style: robotoRegular.copyWith(
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar endereço...',
                  hintStyle: robotoRegular.copyWith(
                    fontSize: 15,
                    color: Colors.grey.shade400,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.search_rounded, size: 18, color: primaryColor),
                    ),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(Icons.close_rounded, size: 20, color: Colors.grey.shade400),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  filled: false,
                ),
              ),
              suggestionsBoxDecoration: SuggestionsBoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                elevation: 0,
                constraints: const BoxConstraints(maxHeight: 300),
              ),
              suggestionsCallback: (pattern) async {
                return await Get.find<LocationController>().searchLocation(context, pattern);
              },
              noItemsFoundBuilder: (context) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.location_off_rounded, size: 18, color: Colors.grey.shade400),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Nenhum endereço encontrado',
                        style: robotoRegular.copyWith(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              },
              itemBuilder: (context, PredictionModel suggestion) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade100, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.location_on_rounded, size: 18, color: primaryColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              suggestion.mainText ?? suggestion.description ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: robotoMedium.copyWith(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodyLarge!.color,
                              ),
                            ),
                            if (suggestion.secondaryText?.isNotEmpty == true) ...[
                              const SizedBox(height: 2),
                              Text(
                                suggestion.secondaryText!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: robotoRegular.copyWith(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.north_west_rounded, size: 14, color: Colors.grey.shade300),
                    ],
                  ),
                );
              },
              onSuggestionSelected: (PredictionModel suggestion) async {
                if (kDebugMode) {
                  print('=== Local selecionado ===');
                  print('Place ID: ${suggestion.placeId}');
                  print('Main Text: ${suggestion.mainText}');
                }

                try {
                  if (Get.isDialogOpen == true) {
                    Navigator.of(Get.overlayContext!).pop();
                    await Future.delayed(const Duration(milliseconds: 200));
                  }

                  if (isPickedUp == null) {
                    final locationController = Get.find<LocationController>();

                    Get.dialog(
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const CircularProgressIndicator(),
                        ),
                      ),
                    );

                    try {
                      await locationController.setLocation(
                        suggestion.placeId,
                        suggestion.description ?? suggestion.mainText ?? 'Local desconhecido',
                        mapController,
                      );

                      if (Get.isDialogOpen == true) {
                        Navigator.of(Get.overlayContext!).pop();
                      }

                      if (mapController != null) {
                        final newPosition = LatLng(
                          locationController.pickPosition.latitude,
                          locationController.pickPosition.longitude,
                        );
                        await mapController!.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(target: newPosition, zoom: 17),
                          ),
                        );
                      }
                    } catch (e) {
                      if (Get.isDialogOpen == true) {
                        Navigator.of(Get.overlayContext!).pop();
                      }
                      if (kDebugMode) print('Erro ao atualizar localizacao: $e');
                    }
                  } else {
                    Get.find<ParcelController>().setLocationFromPlace(
                      suggestion.placeId,
                      suggestion.description ?? suggestion.mainText ?? 'Local desconhecido',
                      isPickedUp,
                    );
                  }
                } catch (e) {
                  if (kDebugMode) print('Erro ao selecionar localizacao: $e');
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
