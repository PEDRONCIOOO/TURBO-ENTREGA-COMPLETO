import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/api/local_client.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/parcel/domain/models/parcel_category_model.dart';
import 'package:sixam_mart/features/parcel/domain/models/parcel_instruction_model.dart';
import 'package:sixam_mart/features/parcel/domain/models/video_content_model.dart';
import 'package:sixam_mart/features/parcel/domain/models/why_choose_model.dart';
import 'package:sixam_mart/features/parcel/domain/repositories/parcel_repository_interface.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';

class ParcelRepository implements ParcelRepositoryInterface {
  final ApiClient apiClient;
  ParcelRepository({required this.apiClient});



Future<double> getDeliveryFeeFromServer({
  required int categoryId,
  required double distanceKm,
  required int zoneId,
  double extraCharge = 0,
  bool isReturn = false,
}) async {
  Response response = await apiClient.postData(
    AppConstants.parcelCalculateFeeUri,
    {
      'category_id': categoryId,
      'distance_km': distanceKm,
      'zone_id': zoneId,
      'extra_charge': extraCharge,

      // ✅ NOVO CAMPO (manda 1/0 para facilitar no backend Laravel)
      'is_return': isReturn ? 1 : 0,
    },
  );

  if (response.statusCode == 200 && response.body != null) {
    final data = response.body;
    return (data['delivery_fee'] as num).toDouble();
  } else {
    return -1;
  }
}
  
  @override
  Future<Response> getPlaceDetails(String? placeID) async {
    return await apiClient.getData('${AppConstants.placeDetailsUri}?placeid=$placeID');
  }

  /// Calcula a distância em km entre dois pontos usando o backend (Distance Matrix API).
  /// Fallback: Geolocator.distanceBetween (cálculo euclidiano – sempre positivo).
  Future<double> getRouteDistanceKm(LatLng origin, LatLng destination) async {
    try {
      final response = await apiClient.getData(
        '${AppConstants.distanceMatrixUri}'
        '?origin_lat=${origin.latitude}'
        '&origin_lng=${origin.longitude}'
        '&destination_lat=${destination.latitude}'
        '&destination_lng=${destination.longitude}'
        '&mode=DRIVE',
        handleError: false,
      );

      if (response.statusCode == 200 && response.body != null) {
        final body = response.body as Map<String, dynamic>;

        // 1) Routes API v2: campo direto distanceMeters (int)
        final rawMeters = body['distanceMeters'];
        if (rawMeters != null) {
          final meters = (rawMeters as num).toDouble();
          if (meters > 0) return meters / 1000.0;
        }

        // 2) Routes API v2: localizedValues.distance.text  ex: "5,2 km" ou "800 m"
        final String? distText =
            body['localizedValues']?['distance']?['text'] as String?;
        if (distText != null && distText.isNotEmpty) {
          final km = _parseDistanceText(distText);
          if (km != null && km > 0) return km;
        }

        // 3) Legacy Distance Matrix: rows[0].elements[0].distance.value (meters)
        if (body['status'] == 'OK') {
          final rows = body['rows'] as List?;
          final val = rows?[0]?['elements']?[0]?['distance']?['value'];
          if (val != null) {
            final meters = (val as num).toDouble();
            if (meters > 0) return meters / 1000.0;
          }
        }
      }
    } catch (_) {}

    // Fallback: straight-line (Haversine) distance
    return Geolocator.distanceBetween(
          origin.latitude, origin.longitude,
          destination.latitude, destination.longitude,
        ) /
        1000.0;
  }

  /// Converte texto de distância retornado pela API para km.
  /// Exemplos: "5,2 km" → 5.2 · "800 m" → 0.8 · "1 m" → 0.001
  double? _parseDistanceText(String text) {
    try {
      final lower = text.toLowerCase().trim();
      final isKm = lower.contains('km');
      // remove tudo exceto dígitos, vírgula e ponto
      final numStr = lower
          .replaceAll(RegExp(r'[^\d,.]'), '')
          .replaceAll(',', '.');
      final value = double.tryParse(numStr);
      if (value == null) return null;
      return isKm ? value : value / 1000.0;
    } catch (_) {
      return null;
    }
  }

  Future<double> getAdditionalStopFee({
    required int categoryId,
    required int zoneId,
    required double distanceKm,
    required double mainDistanceKm,
  }) async {
    final Response response = await apiClient.postData(
      AppConstants.parcelAdditionalStopFeeUri,
      {
        'category_id':     categoryId,
        'zone_id':         zoneId,
        'main_distance_km': mainDistanceKm,
        'stops': [
          {'distance_km': distanceKm},
        ],
      },
    );
    if (response.statusCode == 200 && response.body != null) {
      final stops = response.body['stops'] as List?;
      if (stops != null && stops.isNotEmpty) {
        return (stops[0]['extra_delivery_charge'] as num).toDouble();
      }
    }
    return -1;
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future get(String? id, {bool isVideoDetails = true, DataSourceEnum source = DataSourceEnum.client}) async {
    if(isVideoDetails) {
      return await _getVideoContentDetails(source: source);
    } else {
      return await _getWhyChooseDetails(source: source);
    }
  }

  Future<VideoContentModel?> _getVideoContentDetails({required DataSourceEnum source}) async {
    VideoContentModel? videoContentDetails;
    String cacheId = '${AppConstants.videoContentUri}-${Get.find<SplashController>().module!.id!}';

    switch(source) {
      case DataSourceEnum.client:
        Response response = await apiClient.getData(AppConstants.videoContentUri);
        if(response.statusCode == 200) {
          videoContentDetails = VideoContentModel.fromJson(response.body);
          LocalClient.organize(source, cacheId, jsonEncode(response.body), apiClient.getHeader());
        }

      case DataSourceEnum.local:
        String? cacheResponseData = await LocalClient.organize(source, cacheId, null, null);
        if(cacheResponseData != null) {
          videoContentDetails = VideoContentModel.fromJson(jsonDecode(cacheResponseData));
        }
    }
    return videoContentDetails;
  }

  Future<WhyChooseModel?> _getWhyChooseDetails({required DataSourceEnum source}) async {
    WhyChooseModel? whyChooseDetails;
    String cacheId = '${AppConstants.whyChooseUri}-${Get.find<SplashController>().module!.id!}';

    switch(source) {
      case DataSourceEnum.client:
        Response response = await apiClient.getData(AppConstants.whyChooseUri);
        if(response.statusCode == 200) {
          whyChooseDetails = WhyChooseModel.fromJson(response.body);
          LocalClient.organize(source, cacheId, jsonEncode(response.body), apiClient.getHeader());
        }

      case DataSourceEnum.local:
        String? cacheResponseData = await LocalClient.organize(source, cacheId, null, null);
        if(cacheResponseData != null) {
          whyChooseDetails = WhyChooseModel.fromJson(jsonDecode(cacheResponseData));
        }
    }
    return whyChooseDetails;
  }

  @override
  Future getList({int? offset, bool parcelCategory = true}) async {
    if(parcelCategory) {
     return await _getParcelCategory();
    } else {
      return await _getParcelInstruction(offset!);
    }
  }

  Future<List<ParcelCategoryModel>?> _getParcelCategory() async {
    List<ParcelCategoryModel>? parcelCategoryList;
    Response response = await apiClient.getData(AppConstants.parcelCategoryUri);
    if(response.statusCode == 200) {
      parcelCategoryList = [];
      response.body.forEach((parcel) => parcelCategoryList!.add(ParcelCategoryModel.fromJson(parcel)));
    }
    return parcelCategoryList;
  }

  Future<List<Data>?> _getParcelInstruction(int offset) async {
    List<Data>? parcelInstructionList;
    Response response = await apiClient.getData('${AppConstants.parcelInstructionUri}?limit=10&offset=$offset');
    if(response.statusCode == 200) {
      parcelInstructionList = [];
      parcelInstructionList.addAll(ParcelInstructionModel.fromJson(response.body).data!);
    }
    return parcelInstructionList;
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }

}
