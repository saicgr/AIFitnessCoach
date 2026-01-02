// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diabetes_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiabetesProfile _$DiabetesProfileFromJson(Map<String, dynamic> json) =>
    DiabetesProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      diabetesType: json['diabetes_type'] as String,
      diagnosisDate: json['diagnosis_date'] == null
          ? null
          : DateTime.parse(json['diagnosis_date'] as String),
      treatmentApproach:
          json['treatment_approach'] as String? ?? 'diet_exercise',
      monitoringMethod: json['monitoring_method'] as String? ?? 'finger_prick',
      targetFastingMin: (json['target_fasting_min'] as num?)?.toInt() ?? 70,
      targetFastingMax: (json['target_fasting_max'] as num?)?.toInt() ?? 100,
      targetA1c: (json['target_a1c'] as num?)?.toDouble(),
      hypoThreshold: (json['hypo_threshold'] as num?)?.toInt() ?? 70,
      hyperThreshold: (json['hyper_threshold'] as num?)?.toInt() ?? 180,
      glucoseUnit: json['glucose_unit'] as String? ?? 'mg/dL',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$DiabetesProfileToJson(DiabetesProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'diabetes_type': instance.diabetesType,
      'diagnosis_date': instance.diagnosisDate?.toIso8601String(),
      'treatment_approach': instance.treatmentApproach,
      'monitoring_method': instance.monitoringMethod,
      'target_fasting_min': instance.targetFastingMin,
      'target_fasting_max': instance.targetFastingMax,
      'target_a1c': instance.targetA1c,
      'hypo_threshold': instance.hypoThreshold,
      'hyper_threshold': instance.hyperThreshold,
      'glucose_unit': instance.glucoseUnit,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
