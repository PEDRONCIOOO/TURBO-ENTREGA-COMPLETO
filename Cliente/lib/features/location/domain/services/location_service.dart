import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/location/domain/models/prediction_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/features/location/domain/repositories/location_repository_interface.dart';
import 'package:sixam_mart/features/location/domain/services/location_service_interface.dart';
import 'package:sixam_mart/features/location/screens/pick_map_screen.dart';
import 'package:sixam_mart/features/location/widgets/permission_dialog_widget.dart';
import 'package:sixam_mart/features/parcel/domain/models/place_details_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/location/domain/services/google_places_service.dart';

class LocationService implements LocationServiceInterface {
  final LocationRepositoryInterface locationRepoInterface;
  final GooglePlacesService _placesService;
  
  LocationService({required this.locationRepoInterface}) 
      : _placesService = GooglePlacesService(
          apiKey: 'YOUR_GOOGLE_MAPS_API_KEY',
        );


  @override
  Future<String> getAddressFromGeocode(LatLng latLng) async {
    return await locationRepoInterface.getAddressFromGeocode(latLng);
  }

  @override
  Future<LatLng?> forwardGeocode(String address) async {
    return await locationRepoInterface.forwardGeocode(address);
  }

  @override
  Future<ZoneResponseModel> getZone(String? lat, String? lng, {bool handleError = false}) async {
    return await locationRepoInterface.getZone(lat, lng, handleError: handleError);
  }

  @override
  Future<Position> getPosition(LatLng? defaultLatLng, LatLng configLatLng) async {
    Position myPosition;
    try {
      Position newLocalData = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      myPosition = newLocalData;
    }catch(e) {
      myPosition = Position(
        latitude: defaultLatLng != null ? defaultLatLng.latitude : configLatLng.latitude,
        longitude: defaultLatLng != null ? defaultLatLng.longitude : configLatLng.longitude,
        timestamp: DateTime.now(), accuracy: 1, altitude: 1, heading: 1, speed: 1, speedAccuracy: 1, altitudeAccuracy: 1, headingAccuracy: 1,
      );
    }
    return myPosition;
  }

  @override
  void handleMapAnimation(GoogleMapController? mapController, Position myPosition) {
    if (mapController != null) {
      mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(myPosition.latitude, myPosition.longitude), zoom: 17),
      ));
    }
  }

  @override
  Map<String, String> prepareHeader(List<int>? zoneIds) {
    Map<String, String> header = {
      'Content-Type': 'application/json; charset=UTF-8',
      AppConstants.zoneId: zoneIds != null ? jsonEncode(zoneIds) : '',
    };
    return header;
  }

  @override
  void configureFirebaseMessaging(AddressModel address) {
    if(!GetPlatform.isWeb) {
      if(Get.find<SplashController>().configModel!.demo!) {
        FirebaseMessaging.instance.subscribeToTopic('demo_reset');
      } else {
        FirebaseMessaging.instance.unsubscribeFromTopic('demo_reset');
      }
      if (AddressHelper.getUserAddressFromSharedPref() != null) {
        if(AddressHelper.getUserAddressFromSharedPref()!.zoneIds != null) {
          for(int zoneID in AddressHelper.getUserAddressFromSharedPref()!.zoneIds!) {
            FirebaseMessaging.instance.unsubscribeFromTopic('zone_${zoneID}_customer');
          }
        }else {
          FirebaseMessaging.instance.unsubscribeFromTopic('zone_${AddressHelper.getUserAddressFromSharedPref()!.zoneId}_customer');
        }
      } else {
        FirebaseMessaging.instance.subscribeToTopic('zone_${address.zoneId}_customer');
      }
      if(address.zoneIds != null) {
        for(int zoneID in address.zoneIds!) {
          FirebaseMessaging.instance.subscribeToTopic('zone_${zoneID}_customer');
        }
      } else {
        FirebaseMessaging.instance.subscribeToTopic('zone_${address.zoneId}_customer');
      }
    }
  }

  @override
  void handleRoute(bool fromSignUp, String? route, bool canRoute) {
    if(route != null && canRoute) {
      Get.offAllNamed(route);
    }else {
      Get.offAllNamed(RouteHelper.getInitialRoute());
    }
  }

  @override
  Future<LatLng> getLatLng(String? placeId) async {
    LatLng latLng = const LatLng(0, 0);
    
    if (placeId == null || placeId.isEmpty) {
      return latLng;
    }
    
    try {
      final placeDetails = await _placesService.getPlaceDetails(placeId);
      
      if (placeDetails != null && placeDetails['geometry'] != null) {
        final location = placeDetails['geometry']['location'];
        if (location != null) {
          latLng = LatLng(
            (location['lat'] as num).toDouble(),
            (location['lng'] as num).toDouble(),
          );
        }
      }
      
      if (kDebugMode) {
        print('=== Place Details ===');
        print('Place ID: $placeId');
        print('Coordinates: ${latLng.latitude}, ${latLng.longitude}');
      }
      
      return latLng;
    } catch (e) {
      if (kDebugMode) {
        print('Error in getLatLng: $e');
      }
      // Fallback para o mÃ©todo antigo em caso de erro
      try {
        Response? response = await locationRepoInterface.get(placeId);
        if (response?.statusCode == 200) {
          PlaceDetailsModel placeDetails = PlaceDetailsModel.fromJson(response?.body);
          if (placeDetails.status == 'OK') {
            return LatLng(
              placeDetails.result!.geometry!.location!.lat!,
              placeDetails.result!.geometry!.location!.lng!,
            );
          }
        }
      } catch (e) {
        print('Fallback getLatLng also failed: $e');
      }
      return latLng;
    }
  }

  @override
  Future<List<PredictionModel>> searchLocation(String text) async {
    if (text.trim().isEmpty) {
      if (kDebugMode) {
        print('=== Search Location ===');
        print('Search text is empty or contains only whitespace');
      }
      return [];
    }
    
    final String searchText = text.trim();
    if (kDebugMode) {
      print('=== Search Location ===');
      print('Searching for: "$searchText"');
    }
    
    // Tenta primeiro com o Google Places Service
    try {
      if (kDebugMode) {
        print('Trying Google Places API...');
      }
      
      final predictions = await _placesService.searchPlaces(searchText);
      
      if (kDebugMode) {
        print('Google Places API returned ${predictions.length} results');
        if (predictions.isNotEmpty) {
          print('First result:');
          print('  Place ID: ${predictions.first.placeId}');
          print('  Description: ${predictions.first.description}');
          print('  Main Text: ${predictions.first.mainText}');
          print('  Secondary Text: ${predictions.first.secondaryText}');
        }
      }
      
      return predictions;
    } catch (e) {
      if (kDebugMode) {
        print('Error in Google Places API:');
        print('  Error: $e');
        print('  Stack trace: ${StackTrace.current}');
      }
      
      // Fallback para o mÃ©todo antigo
      try {
        if (kDebugMode) {
          print('Trying fallback search method...');
        }
        
        final response = await locationRepoInterface.searchLocation(searchText);
        
        if (kDebugMode) {
          print('Fallback method status code: ${response.statusCode}');
          print('Response body type: ${response.body.runtimeType}');
        }
        
        if (response.statusCode == 200) {
          if (response.body is List) {
            final predictions = (response.body as List)
                .whereType<Map<String, dynamic>>()
                .map((json) {
                  if (kDebugMode) {
                    print('Parsing prediction: $json');
                  }
                  return PredictionModel.fromJson(json);
                })
                .toList();
                
            if (kDebugMode) {
              print('Successfully parsed ${predictions.length} predictions from fallback');
            }
            
            return predictions;
          } else if (response.body is Map<String, dynamic>) {
            // Tenta extrair prediÃ§Ãµes de um objeto de resposta diferente
            final Map<String, dynamic> body = response.body;
            if (body.containsKey('predictions') && body['predictions'] is List) {
              final predictions = (body['predictions'] as List)
                  .whereType<Map<String, dynamic>>()
                  .map((json) => PredictionModel.fromJson(json))
                  .toList();
                  
              if (kDebugMode) {
                print('Extracted ${predictions.length} predictions from response body');
              }
              
              return predictions;
            }
          }
        }
      } catch (e) {
        print('Fallback search also failed: $e');
      }
      return [];
    }
  }

  @override
  void checkLocationPermission(Function onTap) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      showCustomSnackBar('you_have_to_allow'.tr);
    } else if (permission == LocationPermission.deniedForever) {
      Get.dialog(const PermissionDialogWidget());
    } else {
      onTap();
    }
  }

  @override
  Future<void> authorizeNavigation(String page, List<AddressModel>? addressList, GoogleMapController? mapController, {bool offNamed = false, bool offAll = false}) async {
    if(addressList != null && addressList.isEmpty) {
      if(ResponsiveHelper.isDesktop(Get.context)) {
        showGeneralDialog(context: Get.context!, pageBuilder: (_,__,___) {
          return SizedBox(
            height: 300, width: 300,
            child: PickMapScreen(fromSignUp: (page == RouteHelper.signUp), canRoute: false, fromAddAddress: false, route: null, googleMapController: mapController),
          );
        });
      } else {
        Get.toNamed(RouteHelper.getPickMapRoute(page, false));
      }
    } else {
      if(offNamed) {
        Get.offNamed(RouteHelper.getAccessLocationRoute(page));
      } else if(offAll) {
        Get.offAllNamed(RouteHelper.getAccessLocationRoute(page));
      } else {
        Get.toNamed(RouteHelper.getAccessLocationRoute(page));
      }
    }
  }

  @override
  void defaultNavigation(String page, GoogleMapController? mapController) {
    if(ResponsiveHelper.isDesktop(Get.context)) {
      showGeneralDialog(context: Get.context!, pageBuilder: (_,__,___) {
        return SizedBox(
          height: Get.context!.height * 0.75, width: 300,
          child: PickMapScreen(
            fromSignUp: (page == RouteHelper.signUp),
            canRoute: false, fromAddAddress: false, route: null,
            googleMapController: mapController,
          ),
        );
      });
    } else {
      Get.toNamed(RouteHelper.getPickMapRoute(page, false));
    }
  }

}