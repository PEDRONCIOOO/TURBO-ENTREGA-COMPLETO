import 'package:flutter/foundation.dart';

class PredictionModel {
  final String? description;
  final String? id;
  final int? distanceMeters;
  final String? placeId;
  final String? reference;
  final Map<String, dynamic>? placePrediction;
  final String? mainText;
  final String? secondaryText;

  PredictionModel({
    this.description,
    this.id,
    this.distanceMeters,
    this.placeId,
    this.reference,
    this.placePrediction,
    this.mainText,
    this.secondaryText,
  });

  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      print('=== PredictionModel.fromJson ===');
      print('Input JSON: $json');
    }

    // Extrai structured_formatting se existir
    final structuredFormatting = json['structured_formatting'] as Map<String, dynamic>?;
    
    final model = PredictionModel(
      description: json['description'] ?? json['place'],
      id: json['id'],
      distanceMeters: json['distance_meters'],
      placeId: json['placeId'] ?? json['place_id'],
      reference: json['reference'],
      mainText: structuredFormatting?['main_text'] as String?,
      secondaryText: structuredFormatting?['secondary_text'] as String?,
      placePrediction: json,
    );

    if (kDebugMode) {
      print('Created PredictionModel:');
      print('  description: ${model.description}');
      print('  placeId: ${model.placeId}');
      print('  mainText: ${model.mainText}');
      print('  secondaryText: ${model.secondaryText}');
      print('==============================');
    }

    return model;
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'id': id,
      'distance_meters': distanceMeters,
      'place_id': placeId,
      'reference': reference,
      'structured_formatting': {
        'main_text': mainText,
        'secondary_text': secondaryText,
      },
      if (placePrediction != null) 'placePrediction': placePrediction,
    };
  }

  @override
  String toString() {
    return 'PredictionModel(description: $description, placeId: $placeId, mainText: $mainText, secondaryText: $secondaryText)';
  }
}
