// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'glucose_reading.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GlucoseReading _$GlucoseReadingFromJson(Map<String, dynamic> json) =>
    GlucoseReading(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      glucoseValue: (json['glucose_value'] as num).toInt(),
      mealContext: json['meal_context'] as String,
      readingType: json['reading_type'] as String? ?? 'manual',
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      notes: json['notes'] as String?,
      foodLogId: json['food_log_id'] as String?,
      workoutId: json['workout_id'] as String?,
      insulinDoseId: json['insulin_dose_id'] as String?,
      carbsConsumed: (json['carbs_consumed'] as num?)?.toInt(),
      isFlagged: json['is_flagged'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$GlucoseReadingToJson(GlucoseReading instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'glucose_value': instance.glucoseValue,
      'meal_context': instance.mealContext,
      'reading_type': instance.readingType,
      'recorded_at': instance.recordedAt.toIso8601String(),
      'notes': instance.notes,
      'food_log_id': instance.foodLogId,
      'workout_id': instance.workoutId,
      'insulin_dose_id': instance.insulinDoseId,
      'carbs_consumed': instance.carbsConsumed,
      'is_flagged': instance.isFlagged,
      'created_at': instance.createdAt.toIso8601String(),
    };

GlucoseReadingRequest _$GlucoseReadingRequestFromJson(
  Map<String, dynamic> json,
) => GlucoseReadingRequest(
  glucoseValue: (json['glucose_value'] as num).toInt(),
  mealContext: json['meal_context'] as String,
  readingType: json['reading_type'] as String?,
  recordedAt: json['recorded_at'] == null
      ? null
      : DateTime.parse(json['recorded_at'] as String),
  notes: json['notes'] as String?,
  foodLogId: json['food_log_id'] as String?,
  carbsConsumed: (json['carbs_consumed'] as num?)?.toInt(),
);

Map<String, dynamic> _$GlucoseReadingRequestToJson(
  GlucoseReadingRequest instance,
) => <String, dynamic>{
  'glucose_value': instance.glucoseValue,
  'meal_context': instance.mealContext,
  'reading_type': instance.readingType,
  'recorded_at': instance.recordedAt?.toIso8601String(),
  'notes': instance.notes,
  'food_log_id': instance.foodLogId,
  'carbs_consumed': instance.carbsConsumed,
};

DailyGlucoseSummary _$DailyGlucoseSummaryFromJson(Map<String, dynamic> json) =>
    DailyGlucoseSummary(
      date: json['date'] as String,
      readingCount: (json['reading_count'] as num?)?.toInt() ?? 0,
      avgGlucose: (json['avg_glucose'] as num?)?.toDouble() ?? 0,
      minGlucose: (json['min_glucose'] as num?)?.toInt() ?? 0,
      maxGlucose: (json['max_glucose'] as num?)?.toInt() ?? 0,
      timeInRangePercent:
          (json['time_in_range_percent'] as num?)?.toDouble() ?? 0,
      lowCount: (json['low_count'] as num?)?.toInt() ?? 0,
      highCount: (json['high_count'] as num?)?.toInt() ?? 0,
      readings:
          (json['readings'] as List<dynamic>?)
              ?.map((e) => GlucoseReading.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$DailyGlucoseSummaryToJson(
  DailyGlucoseSummary instance,
) => <String, dynamic>{
  'date': instance.date,
  'reading_count': instance.readingCount,
  'avg_glucose': instance.avgGlucose,
  'min_glucose': instance.minGlucose,
  'max_glucose': instance.maxGlucose,
  'time_in_range_percent': instance.timeInRangePercent,
  'low_count': instance.lowCount,
  'high_count': instance.highCount,
  'readings': instance.readings,
};
