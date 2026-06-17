import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sixam_mart/features/location/domain/models/prediction_model.dart';
import 'package:sixam_mart/helper/address_helper.dart';

class GooglePlacesService {
  static const String _autocompleteUrl =
      'https://producao.turboentregas.com.br/api/v1/maps/autocomplete';

  static const String _placeDetailsUrl =
      'https://producao.turboentregas.com.br/api/v1/maps/place-details';

  final String apiKey; // não usada, só pra manter compatibilidade

  GooglePlacesService({required this.apiKey});

  // =========================================================
  // AUTOCOMPLETE
  // =========================================================
  Future<List<PredictionModel>> searchPlaces(String query) async {
    print('>>> [GooglePlacesService] searchPlaces() chamado com: "$query"');

    if (query.trim().isEmpty) {
      print('>>> [GooglePlacesService] query vazia, retornando lista vazia');
      return [];
    }

    return _searchPlacesBackend(query);
  }

  Future<List<PredictionModel>> _searchPlacesBackend(String query) async {
    final String searchQuery = query.trim();

    print('>>> [GooglePlacesService] _searchPlacesBackend()');
    print('>>> Searching for: "$searchQuery"');

    try {
      final uri = Uri.parse(_autocompleteUrl).replace(
        queryParameters: _queryParametersForAutocomplete(searchQuery),
      );

      print('>>> Request URL: $uri');

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      print('>>> Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        print('>>> API Response (backend)');
        print('    Status: ${data['status']}');
        print('    Error Message: ${data['error_message'] ?? 'None'}');

        if (data['status'] == 'OK' || data['status'] == 'ZERO_RESULTS') {
          final predictions = (data['predictions'] as List?) ?? [];

          print('>>> Found ${predictions.length} predictions');

          final list = predictions
              .whereType<Map<String, dynamic>>()
              .map<PredictionModel>((prediction) {
            if (kDebugMode) {
              print('Parsing prediction: $prediction');
            }
            return PredictionModel.fromJson(prediction);
          }).toList();

          return list;
        } else {
          print('>>> Google Places API Error (via backend): ${data['status']}');
          return [];
        }
      } else {
        print('>>> HTTP Error (backend): ${response.statusCode}');
        print('>>> Response body: ${response.body}');
        return [];
      }
    } catch (e, st) {
      print('>>> Exception in _searchPlacesBackend: $e');
      print(st);
      return [];
    }
  }

  Map<String, String> _queryParametersForAutocomplete(String searchQuery) {
    final params = <String, String>{
          'input': searchQuery,
          'sessiontoken': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    final savedAddress = AddressHelper.getUserAddressFromSharedPref();
    final lat = double.tryParse(savedAddress?.latitude ?? '');
    final lng = double.tryParse(savedAddress?.longitude ?? '');

    if (lat != null && lng != null && (lat != 0 || lng != 0)) {
      params['lat'] = lat.toString();
      params['lng'] = lng.toString();
    }

    return params;
  }

  // =========================================================
  // PLACE DETAILS
  // =========================================================
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    print('>>> [GooglePlacesService] getPlaceDetails() chamado com: "$placeId"');

    if (placeId.isEmpty) {
      print('>>> placeId vazio, retornando null');
      return null;
    }

    return _getPlaceDetailsBackend(placeId);
  }

  Future<Map<String, dynamic>?> _getPlaceDetailsBackend(String placeId) async {
    final uri = Uri.parse(_placeDetailsUrl).replace(
      queryParameters: {
        'place_id': placeId,
      },
    );

    try {
      print('=== GooglePlacesService._getPlaceDetailsBackend ===');
      print('Place ID: $placeId');
      print('Request URL: $uri');

      final response =
          await http.get(uri).timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        print('Place Details Response (backend):');
        print('  Status: ${data['status']}');
        if (data['status'] != 'OK') {
          print('  Error Message: ${data['error_message'] ?? 'No error message'}');
        } else {
          print('  Place Name: ${data['result']?['name']}');
          print('  Formatted Address: ${data['result']?['formatted_address']}');
          if (data['result']?['geometry']?['location'] != null) {
            print('  Location: ${data['result']?['geometry']?['location']}');
          }
        }

        if (data['status'] == 'OK' && data['result'] != null) {
          final result = data['result'] as Map<String, dynamic>;

          if (result['geometry']?['location'] == null) {
            print('No geometry data in place details');
            return null;
          }

          return result;
        }
      } else {
        print('HTTP Error (backend): ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      return null;
    } catch (e, st) {
      print('Error in _getPlaceDetailsBackend: $e');
      print('Stack trace: $st');
      return null;
    }
  }

  /// (Opcional) Se algum dia quiser reordenar no app também
  List<PredictionModel> _prioritizeDourados(List<PredictionModel> items) {
    int score(PredictionModel p) {
      final desc = (p.description ?? '').toLowerCase();

      final hasDourados = desc.contains('dourados');
      final hasMs = desc.contains('ms') || desc.contains('mato grosso do sul');

      if (hasDourados && hasMs) return 0;
      if (hasDourados) return 1;
      return 2;
    }

    items.sort((a, b) => score(a).compareTo(score(b)));
    return items;
  }
}
