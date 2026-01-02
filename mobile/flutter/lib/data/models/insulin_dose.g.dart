// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'insulin_dose.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InsulinDose _$InsulinDoseFromJson(Map<String, dynamic> json) => InsulinDose(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  insulinName: json['insulin_name'] as String,
  insulinType: json['insulin_type'] as String,
  units: (json['units'] as num).toDouble(),
  deliveryMethod: json['delivery_method'] as String? ?? 'pen',
  injectionSite: json['injection_site'] as String?,
  administeredAt: DateTime.parse(json['administered_at'] as String),
  notes: json['notes'] as String?,
  glucoseReadingId: json['glucose_reading_id'] as String?,
  foodLogId: json['food_log_id'] as String?,
  carbsCovered: (json['carbs_covered'] as num?)?.toInt(),
  correctionUnits: (json['correction_units'] as num?)?.toDouble(),
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$InsulinDoseToJson(InsulinDose instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'insulin_name': instance.insulinName,
      'insulin_type': instance.insulinType,
      'units': instance.units,
      'delivery_method': instance.deliveryMethod,
      'injection_site': instance.injectionSite,
      'administered_at': instance.administeredAt.toIso8601String(),
      'notes': instance.notes,
      'glucose_reading_id': instance.glucoseReadingId,
      'food_log_id': instance.foodLogId,
      'carbs_covered': instance.carbsCovered,
      'correction_units': instance.correctionUnits,
      'created_at': instance.createdAt.toIso8601String(),
    };

InsulinDoseRequest _$InsulinDoseRequestFromJson(Map<String, dynamic> json) =>
    InsulinDoseRequest(
      insulinName: json['insulin_name'] as String,
      insulinType: json['insulin_type'] as String,
      units: (json['units'] as num).toDouble(),
      deliveryMethod: json['delivery_method'] as String?,
      injectionSite: json['injection_site'] as String?,
      administeredAt: json['administered_at'] == null
          ? null
          : DateTime.parse(json['administered_at'] as String),
      notes: json['notes'] as String?,
      glucoseReadingId: json['glucose_reading_id'] as String?,
      carbsCovered: (json['carbs_covered'] as num?)?.toInt(),
      correctionUnits: (json['correction_units'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$InsulinDoseRequestToJson(InsulinDoseRequest instance) =>
    <String, dynamic>{
      'insulin_name': instance.insulinName,
      'insulin_type': instance.insulinType,
      'units': instance.units,
      'delivery_method': instance.deliveryMethod,
      'injection_site': instance.injectionSite,
      'administered_at': instance.administeredAt?.toIso8601String(),
      'notes': instance.notes,
      'glucose_reading_id': instance.glucoseReadingId,
      'carbs_covered': instance.carbsCovered,
      'correction_units': instance.correctionUnits,
    };

DailyInsulinSummary _$DailyInsulinSummaryFromJson(Map<String, dynamic> json) =>
    DailyInsulinSummary(
      date: json['date'] as String,
      totalUnits: (json['total_units'] as num?)?.toDouble() ?? 0,
      basalUnits: (json['basal_units'] as num?)?.toDouble() ?? 0,
      bolusUnits: (json['bolus_units'] as num?)?.toDouble() ?? 0,
      correctionUnits: (json['correction_units'] as num?)?.toDouble() ?? 0,
      doseCount: (json['dose_count'] as num?)?.toInt() ?? 0,
      doses:
          (json['doses'] as List<dynamic>?)
              ?.map((e) => InsulinDose.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$DailyInsulinSummaryToJson(
  DailyInsulinSummary instance,
) => <String, dynamic>{
  'date': instance.date,
  'total_units': instance.totalUnits,
  'basal_units': instance.basalUnits,
  'bolus_units': instance.bolusUnits,
  'correction_units': instance.correctionUnits,
  'dose_count': instance.doseCount,
  'doses': instance.doses,
};
