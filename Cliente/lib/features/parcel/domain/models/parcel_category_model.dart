// Se precisar usar em outro arquivo, basta importar este model.
//
// Exemplo de uso:
// final cat = ParcelCategoryModel.fromJson(json);
// final preco = cat.calculateDeliveryPrice(8.3); // distância em km

class ParcelCategoryModel {
  int? id;
  String? imageFullUrl;
  String? name;
  String? description;
  String? createdAt;
  String? updatedAt;
  double? parcelPerKmShippingCharge;
  double? parcelMinimumShippingCharge;

  // 🔹 NOVOS CAMPOS
  /// Até esse km cobra apenas o valor mínimo
  double? minimumShippingDistanceKm;

  /// Faixas de preço por km (ex: 6–10km = 1.0; 10–15km = 1.2)
  List<DistancePricingRule>? distancePricingRules;

  /// Se true, cobra km quebrado (3.3km). Se false, arredonda.
  bool? chargeFractionalKm;

  /// Quando NÃO cobra quebrado:
  /// - 'floor' → valor menor (3.3 → 3)
  /// - 'ceil'  → valor maior (3.3 → 4)
  String? fractionalRounding;

  /// Percentual da taxa principal cobrado por parada adicional (ex: 40 = 40%)
  double? extraStopPercentage;

  ParcelCategoryModel({
    this.id,
    this.imageFullUrl,
    this.name,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.parcelPerKmShippingCharge,
    this.parcelMinimumShippingCharge,
    this.minimumShippingDistanceKm,
    this.distancePricingRules,
    this.chargeFractionalKm,
    this.fractionalRounding,
    this.extraStopPercentage,
  });

  ParcelCategoryModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];

    // API pode mandar 'image_full_url' (original) ou 'image' (se você ajustar o backend),
    // então tratamos os dois.
    imageFullUrl = json['image_full_url'] ?? json['image'];

    name = json['name'];
    description = json['description'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];

    parcelPerKmShippingCharge =
        json['parcel_per_km_shipping_charge'] != null
            ? json['parcel_per_km_shipping_charge'].toDouble()
            : 0;

    parcelMinimumShippingCharge =
        json['parcel_minimum_shipping_charge'] != null
            ? json['parcel_minimum_shipping_charge'].toDouble()
            : 0;

    // 🔹 novos campos
    minimumShippingDistanceKm =
        (json['minimum_shipping_distance_km'] ?? 0).toDouble();

    if (json['distance_pricing_rules'] != null) {
      distancePricingRules = <DistancePricingRule>[];
      (json['distance_pricing_rules'] as List).forEach((v) {
        distancePricingRules!.add(DistancePricingRule.fromJson(v));
      });
    }

    chargeFractionalKm = json['charge_fractional_km'] ?? true;
    fractionalRounding = json['fractional_rounding'] ?? 'ceil';
    extraStopPercentage = (json['extra_stop_percentage'] ?? 40).toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    data['id'] = id;
    data['image_full_url'] = imageFullUrl;
    data['name'] = name;
    data['description'] = description;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['parcel_per_km_shipping_charge'] = parcelPerKmShippingCharge;
    data['parcel_minimum_shipping_charge'] = parcelMinimumShippingCharge;

    data['minimum_shipping_distance_km'] = minimumShippingDistanceKm;
    if (distancePricingRules != null) {
      data['distance_pricing_rules'] =
          distancePricingRules!.map((v) => v.toJson()).toList();
    }
    data['charge_fractional_km'] = chargeFractionalKm;
    data['fractional_rounding'] = fractionalRounding;
    data['extra_stop_percentage'] = extraStopPercentage;

    return data;
  }

  /// Calcula o valor do frete para uma distância em km,
  /// seguindo exatamente a lógica configurada no painel:
  ///
  /// - Até `minimumShippingDistanceKm` → cobra só o mínimo.
  /// - Acima disso → cobra:
  ///     mínimo + (km extra * preço por km da faixa correspondente)
  /// - Se não houver faixas, usa `parcel_per_km_shipping_charge` como fallback.
  /// - Se `chargeFractionalKm` = false → arredonda km conforme `fractionalRounding`.
  double calculateDeliveryPrice(double distanceKm) {
    if (distanceKm < 0) {
      distanceKm = 0;
    }

    // ===== 1) Tratamento de km quebrado vs arredondado =====
    double effectiveDistance = distanceKm;
    final bool useFractional = chargeFractionalKm ?? true;
    final String roundingMode = fractionalRounding ?? 'ceil';

    if (!useFractional) {
      if (roundingMode == 'floor') {
        effectiveDistance = distanceKm.floorToDouble();
      } else {
        // default = 'ceil'
        effectiveDistance = distanceKm.ceilToDouble();
      }
    }

    final double minCharge = parcelMinimumShippingCharge ?? 0;
    final double defaultPerKm = parcelPerKmShippingCharge ?? 0;
    final double threshold = minimumShippingDistanceKm ?? 0;

    // ===== 2) Até o km mínimo → só valor mínimo =====
    if (effectiveDistance <= threshold) {
      return double.parse(minCharge.toStringAsFixed(2));
    }

    // Km acima do limite onde começa a cobrar por km
    final double extraStart = threshold;
    final double extraEnd = effectiveDistance;

    double extraCharge = 0;

    // ===== 3) Aplicar faixas de km (cursor-based, igual ao PHP) =====
    if (distancePricingRules != null && distancePricingRules!.isNotEmpty) {
      final sortedRules = List<DistancePricingRule>.from(distancePricingRules!)
        ..sort((a, b) => (a.from ?? 0).compareTo(b.from ?? 0));

      double cursorKm = extraStart;

      for (final rule in sortedRules) {
        if (cursorKm >= extraEnd) break;

        final double ruleFrom = rule.from ?? 0;
        final double ruleTo = rule.to ?? extraEnd;
        final double pricePerKm = rule.pricePerKm ?? defaultPerKm;

        final double segmentStart = ruleFrom < cursorKm ? cursorKm : ruleFrom;
        if (segmentStart >= extraEnd) continue;
        final double segmentEnd = ruleTo > extraEnd ? extraEnd : ruleTo;
        if (segmentEnd <= segmentStart) continue;

        extraCharge += (segmentEnd - segmentStart) * pricePerKm;
        cursorKm = segmentEnd;
      }

      // ===== 4) Cauda não coberta pelas faixas → usa per_km padrão =====
      if (cursorKm < extraEnd && defaultPerKm > 0) {
        extraCharge += (extraEnd - cursorKm) * defaultPerKm;
      }
    } else {
      // ===== 4) Sem faixas → usa per_km padrão para toda a distância extra =====
      final double extraDistance = extraEnd > extraStart ? extraEnd - extraStart : 0;
      if (defaultPerKm > 0) {
        extraCharge = extraDistance * defaultPerKm;
      }
    }

    // ===== 5) Total = mínimo + adicional por km =====
    double total = minCharge + extraCharge;

    // Arredonda pra 2 casas decimais, igual cálculo de dinheiro
    return double.parse(total.toStringAsFixed(2));
  }
}

/// Regra de faixa de km:
///   Exemplo:
///     from: 6, to: 10, pricePerKm: 1.0  → de 6 a 10km cobra R$1,00 por km.
///     from: 10, to: 15, pricePerKm: 1.2 → de 10 a 15km cobra R$1,20 por km.
class DistancePricingRule {
  double? from;
  double? to;
  double? pricePerKm;

  DistancePricingRule({this.from, this.to, this.pricePerKm});

  DistancePricingRule.fromJson(Map<String, dynamic> json) {
    from = (json['from'] ?? 0).toDouble();
    // 'to' pode ser null (por exemplo: acima de X km)
    to = json['to'] != null ? (json['to']).toDouble() : null;
    pricePerKm = (json['price_per_km'] ?? 0).toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['from'] = from;
    data['to'] = to;
    data['price_per_km'] = pricePerKm;
    return data;
  }
}
