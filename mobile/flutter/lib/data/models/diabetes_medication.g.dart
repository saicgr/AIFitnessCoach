// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diabetes_medication.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiabetesMedication _$DiabetesMedicationFromJson(Map<String, dynamic> json) =>
    DiabetesMedication(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      medicationName: json['medication_name'] as String,
      genericName: json['generic_name'] as String?,
      medicationType: json['medication_type'] as String,
      dosageMg: (json['dosage_mg'] as num).toDouble(),
      dosageUnit: json['dosage_unit'] as String? ?? 'mg',
      frequency: json['frequency'] as String,
      timeOfDay:
          (json['time_of_day'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      withFood: json['with_food'] as bool? ?? false,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] == null
          ? null
          : DateTime.parse(json['end_date'] as String),
      isActive: json['is_active'] as bool? ?? true,
      prescribingDoctor: json['prescribing_doctor'] as String?,
      notes: json['notes'] as String?,
      refillDate: json['refill_date'] == null
          ? null
          : DateTime.parse(json['refill_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$DiabetesMedicationToJson(DiabetesMedication instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'medication_name': instance.medicationName,
      'generic_name': instance.genericName,
      'medication_type': instance.medicationType,
      'dosage_mg': instance.dosageMg,
      'dosage_unit': instance.dosageUnit,
      'frequency': instance.frequency,
      'time_of_day': instance.timeOfDay,
      'with_food': instance.withFood,
      'start_date': instance.startDate.toIso8601String(),
      'end_date': instance.endDate?.toIso8601String(),
      'is_active': instance.isActive,
      'prescribing_doctor': instance.prescribingDoctor,
      'notes': instance.notes,
      'refill_date': instance.refillDate?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

DiabetesMedicationRequest _$DiabetesMedicationRequestFromJson(
  Map<String, dynamic> json,
) => DiabetesMedicationRequest(
  medicationName: json['medication_name'] as String,
  genericName: json['generic_name'] as String?,
  medicationType: json['medication_type'] as String,
  dosageMg: (json['dosage_mg'] as num).toDouble(),
  dosageUnit: json['dosage_unit'] as String?,
  frequency: json['frequency'] as String,
  timeOfDay: (json['time_of_day'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  withFood: json['with_food'] as bool?,
  startDate: json['start_date'] == null
      ? null
      : DateTime.parse(json['start_date'] as String),
  prescribingDoctor: json['prescribing_doctor'] as String?,
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$DiabetesMedicationRequestToJson(
  DiabetesMedicationRequest instance,
) => <String, dynamic>{
  'medication_name': instance.medicationName,
  'generic_name': instance.genericName,
  'medication_type': instance.medicationType,
  'dosage_mg': instance.dosageMg,
  'dosage_unit': instance.dosageUnit,
  'frequency': instance.frequency,
  'time_of_day': instance.timeOfDay,
  'with_food': instance.withFood,
  'start_date': instance.startDate?.toIso8601String(),
  'prescribing_doctor': instance.prescribingDoctor,
  'notes': instance.notes,
};

MedicationDoseLog _$MedicationDoseLogFromJson(Map<String, dynamic> json) =>
    MedicationDoseLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      medicationId: json['medication_id'] as String,
      takenAt: DateTime.parse(json['taken_at'] as String),
      wasTaken: json['was_taken'] as bool? ?? true,
      skipReason: json['skip_reason'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$MedicationDoseLogToJson(MedicationDoseLog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'medication_id': instance.medicationId,
      'taken_at': instance.takenAt.toIso8601String(),
      'was_taken': instance.wasTaken,
      'skip_reason': instance.skipReason,
      'notes': instance.notes,
      'created_at': instance.createdAt.toIso8601String(),
    };
