// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeeklySummary _$WeeklySummaryFromJson(Map<String, dynamic> json) =>
    WeeklySummary(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      weekStart: json['week_start'] as String,
      weekEnd: json['week_end'] as String,
      workoutsCompleted: (json['workouts_completed'] as num?)?.toInt() ?? 0,
      workoutsScheduled: (json['workouts_scheduled'] as num?)?.toInt() ?? 0,
      totalExercises: (json['total_exercises'] as num?)?.toInt() ?? 0,
      totalSets: (json['total_sets'] as num?)?.toInt() ?? 0,
      totalTimeMinutes: (json['total_time_minutes'] as num?)?.toInt() ?? 0,
      caloriesBurnedEstimate:
          (json['calories_burned_estimate'] as num?)?.toInt() ?? 0,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      streakStatus: json['streak_status'] as String?,
      prsAchieved: (json['prs_achieved'] as num?)?.toInt() ?? 0,
      prDetails: (json['pr_details'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      aiSummary: json['ai_summary'] as String?,
      aiHighlights: (json['ai_highlights'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      aiEncouragement: json['ai_encouragement'] as String?,
      aiNextWeekTips: (json['ai_next_week_tips'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      aiGeneratedAt: json['ai_generated_at'] == null
          ? null
          : DateTime.parse(json['ai_generated_at'] as String),
      emailSent: json['email_sent'] as bool? ?? false,
      pushSent: json['push_sent'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$WeeklySummaryToJson(WeeklySummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'week_start': instance.weekStart,
      'week_end': instance.weekEnd,
      'workouts_completed': instance.workoutsCompleted,
      'workouts_scheduled': instance.workoutsScheduled,
      'total_exercises': instance.totalExercises,
      'total_sets': instance.totalSets,
      'total_time_minutes': instance.totalTimeMinutes,
      'calories_burned_estimate': instance.caloriesBurnedEstimate,
      'current_streak': instance.currentStreak,
      'streak_status': instance.streakStatus,
      'prs_achieved': instance.prsAchieved,
      'pr_details': instance.prDetails,
      'ai_summary': instance.aiSummary,
      'ai_highlights': instance.aiHighlights,
      'ai_encouragement': instance.aiEncouragement,
      'ai_next_week_tips': instance.aiNextWeekTips,
      'ai_generated_at': instance.aiGeneratedAt?.toIso8601String(),
      'email_sent': instance.emailSent,
      'push_sent': instance.pushSent,
      'created_at': instance.createdAt.toIso8601String(),
    };
