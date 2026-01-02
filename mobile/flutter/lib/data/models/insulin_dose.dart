import 'package:json_annotation/json_annotation.dart';

part 'insulin_dose.g.dart';

/// Type of insulin
enum InsulinType {
  @JsonValue('rapid_acting')
  rapidActing('rapid_acting', 'Rapid-Acting', 'Works in 15 min, peaks 1-2 hrs'),
  @JsonValue('short_acting')
  shortActing('short_acting', 'Short-Acting', 'Works in 30 min, peaks 2-3 hrs'),
  @JsonValue('intermediate')
  intermediate('intermediate', 'Intermediate', 'Works in 2-4 hrs, peaks 4-12 hrs'),
  @JsonValue('long_acting')
  longActing('long_acting', 'Long-Acting', 'Works in 2 hrs, lasts 24+ hrs'),
  @JsonValue('ultra_long_acting')
  ultraLongActing('ultra_long_acting', 'Ultra Long-Acting', 'Lasts 36-42 hrs'),
  @JsonValue('mixed')
  mixed('mixed', 'Mixed', 'Combination of insulin types'),
  @JsonValue('pump_bolus')
  pumpBolus('pump_bolus', 'Pump Bolus', 'Insulin pump bolus dose'),
  @JsonValue('pump_basal')
  pumpBasal('pump_basal', 'Pump Basal', 'Insulin pump basal rate');

  final String value;
  final String displayName;
  final String description;

  const InsulinType(this.value, this.displayName, this.description);

  static InsulinType fromValue(String? value) {
    if (value == null) return InsulinType.rapidActing;
    return InsulinType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => InsulinType.rapidActing,
    );
  }
}

/// Delivery method for insulin
enum DeliveryMethod {
  @JsonValue('injection')
  injection('injection', 'Injection', 'Syringe injection'),
  @JsonValue('pen')
  pen('pen', 'Pen', 'Insulin pen'),
  @JsonValue('pump')
  pump('pump', 'Pump', 'Insulin pump'),
  @JsonValue('inhaled')
  inhaled('inhaled', 'Inhaled', 'Inhaled insulin');

  final String value;
  final String displayName;
  final String description;

  const DeliveryMethod(this.value, this.displayName, this.description);

  static DeliveryMethod fromValue(String? value) {
    if (value == null) return DeliveryMethod.pen;
    return DeliveryMethod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DeliveryMethod.pen,
    );
  }
}

/// Common insulin brand names and their types
class InsulinBrand {
  final String name;
  final InsulinType type;
  final String manufacturer;

  const InsulinBrand(this.name, this.type, this.manufacturer);

  static const List<InsulinBrand> commonBrands = [
    // Rapid-acting
    InsulinBrand('Humalog (Lispro)', InsulinType.rapidActing, 'Eli Lilly'),
    InsulinBrand('NovoLog (Aspart)', InsulinType.rapidActing, 'Novo Nordisk'),
    InsulinBrand('Apidra (Glulisine)', InsulinType.rapidActing, 'Sanofi'),
    InsulinBrand('Fiasp', InsulinType.rapidActing, 'Novo Nordisk'),
    InsulinBrand('Lyumjev', InsulinType.rapidActing, 'Eli Lilly'),
    // Short-acting
    InsulinBrand('Humulin R', InsulinType.shortActing, 'Eli Lilly'),
    InsulinBrand('Novolin R', InsulinType.shortActing, 'Novo Nordisk'),
    // Intermediate
    InsulinBrand('Humulin N (NPH)', InsulinType.intermediate, 'Eli Lilly'),
    InsulinBrand('Novolin N (NPH)', InsulinType.intermediate, 'Novo Nordisk'),
    // Long-acting
    InsulinBrand('Lantus (Glargine)', InsulinType.longActing, 'Sanofi'),
    InsulinBrand('Basaglar (Glargine)', InsulinType.longActing, 'Eli Lilly'),
    InsulinBrand('Levemir (Detemir)', InsulinType.longActing, 'Novo Nordisk'),
    InsulinBrand('Semglee (Glargine)', InsulinType.longActing, 'Mylan'),
    // Ultra long-acting
    InsulinBrand('Tresiba (Degludec)', InsulinType.ultraLongActing, 'Novo Nordisk'),
    InsulinBrand('Toujeo (Glargine U-300)', InsulinType.ultraLongActing, 'Sanofi'),
    // Mixed
    InsulinBrand('Humalog Mix 75/25', InsulinType.mixed, 'Eli Lilly'),
    InsulinBrand('NovoLog Mix 70/30', InsulinType.mixed, 'Novo Nordisk'),
    InsulinBrand('Humulin 70/30', InsulinType.mixed, 'Eli Lilly'),
  ];

  /// Get display name for an insulin brand
  static String getDisplayName(String brandName) {
    final brand = commonBrands.firstWhere(
      (b) => b.name.toLowerCase().contains(brandName.toLowerCase()),
      orElse: () => InsulinBrand(brandName, InsulinType.rapidActing, 'Unknown'),
    );
    return brand.name;
  }
}

/// Individual insulin dose record
@JsonSerializable()
class InsulinDose {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'insulin_name')
  final String insulinName;
  @JsonKey(name: 'insulin_type')
  final String insulinType;
  @JsonKey(name: 'units')
  final double units;
  @JsonKey(name: 'delivery_method')
  final String deliveryMethod;
  @JsonKey(name: 'injection_site')
  final String? injectionSite;
  @JsonKey(name: 'administered_at')
  final DateTime administeredAt;
  final String? notes;
  @JsonKey(name: 'glucose_reading_id')
  final String? glucoseReadingId;
  @JsonKey(name: 'food_log_id')
  final String? foodLogId;
  @JsonKey(name: 'carbs_covered')
  final int? carbsCovered;
  @JsonKey(name: 'correction_units')
  final double? correctionUnits;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const InsulinDose({
    required this.id,
    required this.userId,
    required this.insulinName,
    required this.insulinType,
    required this.units,
    this.deliveryMethod = 'pen',
    this.injectionSite,
    required this.administeredAt,
    this.notes,
    this.glucoseReadingId,
    this.foodLogId,
    this.carbsCovered,
    this.correctionUnits,
    required this.createdAt,
  });

  factory InsulinDose.fromJson(Map<String, dynamic> json) =>
      _$InsulinDoseFromJson(json);
  Map<String, dynamic> toJson() => _$InsulinDoseToJson(this);

  InsulinType get insulinTypeEnum => InsulinType.fromValue(insulinType);
  DeliveryMethod get deliveryMethodEnum => DeliveryMethod.fromValue(deliveryMethod);

  /// Get formatted units display
  String get unitsDisplay => '${units.toStringAsFixed(units.truncateToDouble() == units ? 0 : 1)} U';

  /// Check if this is a basal dose
  bool get isBasal =>
      insulinTypeEnum == InsulinType.longActing ||
      insulinTypeEnum == InsulinType.ultraLongActing ||
      insulinTypeEnum == InsulinType.intermediate ||
      insulinTypeEnum == InsulinType.pumpBasal;

  /// Check if this is a bolus dose
  bool get isBolus =>
      insulinTypeEnum == InsulinType.rapidActing ||
      insulinTypeEnum == InsulinType.shortActing ||
      insulinTypeEnum == InsulinType.pumpBolus;

  /// Get the insulin display name
  String get insulinDisplayName => InsulinBrand.getDisplayName(insulinName);
}

/// Request to log insulin dose
@JsonSerializable()
class InsulinDoseRequest {
  @JsonKey(name: 'insulin_name')
  final String insulinName;
  @JsonKey(name: 'insulin_type')
  final String insulinType;
  @JsonKey(name: 'units')
  final double units;
  @JsonKey(name: 'delivery_method')
  final String? deliveryMethod;
  @JsonKey(name: 'injection_site')
  final String? injectionSite;
  @JsonKey(name: 'administered_at')
  final DateTime? administeredAt;
  final String? notes;
  @JsonKey(name: 'glucose_reading_id')
  final String? glucoseReadingId;
  @JsonKey(name: 'carbs_covered')
  final int? carbsCovered;
  @JsonKey(name: 'correction_units')
  final double? correctionUnits;

  const InsulinDoseRequest({
    required this.insulinName,
    required this.insulinType,
    required this.units,
    this.deliveryMethod,
    this.injectionSite,
    this.administeredAt,
    this.notes,
    this.glucoseReadingId,
    this.carbsCovered,
    this.correctionUnits,
  });

  factory InsulinDoseRequest.fromJson(Map<String, dynamic> json) =>
      _$InsulinDoseRequestFromJson(json);
  Map<String, dynamic> toJson() => _$InsulinDoseRequestToJson(this);
}

/// Daily insulin summary
@JsonSerializable()
class DailyInsulinSummary {
  final String date;
  @JsonKey(name: 'total_units')
  final double totalUnits;
  @JsonKey(name: 'basal_units')
  final double basalUnits;
  @JsonKey(name: 'bolus_units')
  final double bolusUnits;
  @JsonKey(name: 'correction_units')
  final double correctionUnits;
  @JsonKey(name: 'dose_count')
  final int doseCount;
  final List<InsulinDose> doses;

  const DailyInsulinSummary({
    required this.date,
    this.totalUnits = 0,
    this.basalUnits = 0,
    this.bolusUnits = 0,
    this.correctionUnits = 0,
    this.doseCount = 0,
    this.doses = const [],
  });

  factory DailyInsulinSummary.fromJson(Map<String, dynamic> json) =>
      _$DailyInsulinSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$DailyInsulinSummaryToJson(this);

  /// Get basal to bolus ratio
  String get basalBolusRatio {
    if (totalUnits == 0) return 'N/A';
    final basalPercent = (basalUnits / totalUnits * 100).round();
    final bolusPercent = 100 - basalPercent;
    return '$basalPercent/$bolusPercent';
  }
}
