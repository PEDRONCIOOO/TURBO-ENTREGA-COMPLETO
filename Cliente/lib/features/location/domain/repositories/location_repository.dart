import 'package:flutter/foundation.dart';
import 'package:get/get_connect/http/src/response/response.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/location/domain/models/zone_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/features/location/domain/repositories/location_repository_interface.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';

class LocationRepository implements LocationRepositoryInterface {
  final ApiClient apiClient;

  LocationRepository({required this.apiClient});

  @override
  Future<String> getAddressFromGeocode(LatLng latLng) async {
    Response response = await apiClient.getData('${AppConstants.geocodeUri}?lat=${latLng.latitude}&lng=${latLng.longitude}', handleError: false);
    String address = 'Unknown Location Found';
    if(response.statusCode == 200 && response.body['status'] == 'OK') {
      address = response.body['results'][0]['formatted_address'].toString();
    }else {
      showCustomSnackBar(response.body['error_message'] ?? response.bodyString);
    }
    return address;
  }

  @override
  Future<LatLng?> forwardGeocode(String address) async {
    final encoded = Uri.encodeQueryComponent(address);
    Response response = await apiClient.getData(
      '${AppConstants.forwardGeocodeUri}?address=$encoded',
      handleError: false,
    );
    if (response.statusCode == 200 && response.body['status'] == 'OK') {
      final results = response.body['results'] as List?;
      if (results != null && results.isNotEmpty) {
        final location = results[0]['geometry']?['location'];
        if (location != null) {
          return LatLng(
            (location['lat'] as num).toDouble(),
            (location['lng'] as num).toDouble(),
          );
        }
      }
    }
    return null;
  }

  @override
  Future<ZoneResponseModel> getZone(String? lat, String? lng, {bool handleError = false}) async {
    Response response = await apiClient.getData('${AppConstants.zoneUri}?lat=$lat&lng=$lng', handleError: handleError);
    if(response.statusCode == 200) {
      ZoneResponseModel responseModel;
      List<int>? zoneIds = ZoneModel.fromJson(response.body).zoneIds;
      List<ZoneData>? zoneData = ZoneModel.fromJson(response.body).zoneData;
      responseModel = ZoneResponseModel(true, '' , zoneIds ?? [], zoneData??[], [], response.statusCode);
      return responseModel;
    } else {
      return ZoneResponseModel(false, response.statusText, [], [], [], response.statusCode);
    }
  }

  @override
  Future<Response> searchLocation(String url) async {
    try {
      if (kDebugMode) {
        print('Search Location URL: $url');
      }
      
      final Response response = await apiClient.getData(url);
      
      if (kDebugMode) {
        print('=== Search Location Response ===');
        print('Status Code: ${response.statusCode}');
        print('Response Body Type: ${response.body.runtimeType}');
        if (response.statusCode == 200) {
          print('Response Body: ${response.body}');
        } else {
          print('Error Response: ${response.statusText}');
        }
      }
      
      // Garantir que a resposta sempre tenha um formato consistente
      if (response.statusCode == 200) {
        dynamic body = response.body;
        
        // Se o corpo for um mapa e tiver 'predictions', jÃ¡ estÃ¡ no formato correto
        if (body is Map && body['predictions'] != null) {
          return response;
        }
        
        // Se o corpo for um mapa e tiver 'items', criar uma nova resposta com 'predictions'
        if (body is Map && body['items'] != null) {
          return Response(
            body: {'predictions': body['items']},
            statusCode: response.statusCode,
            statusText: response.statusText,
            bodyString: response.bodyString,
            headers: response.headers,
            request: response.request,
          );
        }
        
        // Se o corpo for uma lista, criar uma nova resposta com 'predictions'
        if (body is List) {
          return Response(
            body: {'predictions': body},
            statusCode: response.statusCode,
            statusText: response.statusText,
            bodyString: response.bodyString,
            headers: response.headers,
            request: response.request,
          );
        }
      }
      
      // Se chegou atÃ© aqui, a resposta nÃ£o estÃ¡ no formato esperado
      if (kDebugMode) {
        print('Formato de resposta inesperado: ${response.body}');
      }
      return response;
      
    } catch (e) {
      if (kDebugMode) {
        print('Error in searchLocation: $e');
      }
      rethrow;
    }
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
  Future<Response> get(String? id) async {
    Response response = await apiClient.getData('${AppConstants.placeDetailsUri}?placeid=$id');
    return response;
  }

  @override
  Future getList({int? offset}) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }

}
