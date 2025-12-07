// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hydration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HydrationLog _$HydrationLogFromJson(Map<String, dynamic> json) => HydrationLog(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  drinkType: json['drink_type'] as String,
  amountMl: (json['amount_ml'] as num).toInt(),
  workoutId: json['workout_id'] as String?,
  notes: json['notes'] as String?,
  loggedAt: json['logged_at'] == null
      ? null
      : DateTime.parse(json['logged_at'] as String),
);

Map<String, dynamic> _$HydrationLogToJson(HydrationLog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'drink_type': instance.drinkType,
      'amount_ml': instance.amountMl,
      'workout_id': instance.workoutId,
      'notes': instance.notes,
      'logged_at': instance.loggedAt?.toIso8601String(),
    };

DailyHydrationSummary _$DailyHydrationSummaryFromJson(
  Map<String, dynamic> json,
) => DailyHydrationSummary(
  date: json['date'] as String,
  totalMl: (json['total_ml'] as num?)?.toInt() ?? 0,
  waterMl: (json['water_ml'] as num?)?.toInt() ?? 0,
  proteinShakeMl: (json['protein_shake_ml'] as num?)?.toInt() ?? 0,
  sportsDrinkMl: (json['sports_drink_ml'] as num?)?.toInt() ?? 0,
  otherMl: (json['other_ml'] as num?)?.toInt() ?? 0,
  goalMl: (json['goal_ml'] as num?)?.toInt() ?? 2500,
  goalPercentage: (json['goal_percentage'] as num?)?.toDouble() ?? 0,
  entries:
      (json['entries'] as List<dynamic>?)
          ?.map((e) => HydrationLog.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$DailyHydrationSummaryToJson(
  DailyHydrationSummary instance,
) => <String, dynamic>{
  'date': instance.date,
  'total_ml': instance.totalMl,
  'water_ml': instance.waterMl,
  'protein_shake_ml': instance.proteinShakeMl,
  'sports_drink_ml': instance.sportsDrinkMl,
  'other_ml': instance.otherMl,
  'goal_ml': instance.goalMl,
  'goal_percentage': instance.goalPercentage,
  'entries': instance.entries,
};
