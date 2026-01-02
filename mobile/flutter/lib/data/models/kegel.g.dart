// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kegel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KegelPreferences _$KegelPreferencesFromJson(Map<String, dynamic> json) =>
    KegelPreferences(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      kegelsEnabled: json['kegels_enabled'] as bool? ?? false,
      includeInWarmup: json['include_in_warmup'] as bool? ?? false,
      includeInCooldown: json['include_in_cooldown'] as bool? ?? false,
      includeAsStandalone: json['include_as_standalone'] as bool? ?? false,
      includeInDailyRoutine: json['include_in_daily_routine'] as bool? ?? false,
      dailyReminderEnabled: json['daily_reminder_enabled'] as bool? ?? false,
      dailyReminderTime: json['daily_reminder_time'] as String?,
      reminderFrequency:
          $enumDecodeNullable(
            _$ReminderFrequencyEnumMap,
            json['reminder_frequency'],
          ) ??
          ReminderFrequency.twice,
      targetSessionsPerDay:
          (json['target_sessions_per_day'] as num?)?.toInt() ?? 3,
      targetDurationSeconds:
          (json['target_duration_seconds'] as num?)?.toInt() ?? 300,
      currentLevel:
          $enumDecodeNullable(_$KegelLevelEnumMap, json['current_level']) ??
          KegelLevel.beginner,
      focusArea:
          $enumDecodeNullable(_$KegelFocusAreaEnumMap, json['focus_area']) ??
          KegelFocusArea.general,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$KegelPreferencesToJson(
  KegelPreferences instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'kegels_enabled': instance.kegelsEnabled,
  'include_in_warmup': instance.includeInWarmup,
  'include_in_cooldown': instance.includeInCooldown,
  'include_as_standalone': instance.includeAsStandalone,
  'include_in_daily_routine': instance.includeInDailyRoutine,
  'daily_reminder_enabled': instance.dailyReminderEnabled,
  'daily_reminder_time': instance.dailyReminderTime,
  'reminder_frequency': _$ReminderFrequencyEnumMap[instance.reminderFrequency]!,
  'target_sessions_per_day': instance.targetSessionsPerDay,
  'target_duration_seconds': instance.targetDurationSeconds,
  'current_level': _$KegelLevelEnumMap[instance.currentLevel]!,
  'focus_area': _$KegelFocusAreaEnumMap[instance.focusArea]!,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

const _$ReminderFrequencyEnumMap = {
  ReminderFrequency.once: 'once',
  ReminderFrequency.twice: 'twice',
  ReminderFrequency.threeTimes: 'three_times',
  ReminderFrequency.hourly: 'hourly',
};

const _$KegelLevelEnumMap = {
  KegelLevel.beginner: 'beginner',
  KegelLevel.intermediate: 'intermediate',
  KegelLevel.advanced: 'advanced',
};

const _$KegelFocusAreaEnumMap = {
  KegelFocusArea.general: 'general',
  KegelFocusArea.maleSpecific: 'male_specific',
  KegelFocusArea.femaleSpecific: 'female_specific',
  KegelFocusArea.postpartum: 'postpartum',
  KegelFocusArea.prostateHealth: 'prostate_health',
};

KegelSession _$KegelSessionFromJson(Map<String, dynamic> json) => KegelSession(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  sessionDate: DateTime.parse(json['session_date'] as String),
  sessionTime: json['session_time'] as String?,
  durationSeconds: (json['duration_seconds'] as num).toInt(),
  repsCompleted: (json['reps_completed'] as num?)?.toInt(),
  holdDurationSeconds: (json['hold_duration_seconds'] as num?)?.toInt(),
  sessionType:
      $enumDecodeNullable(_$KegelSessionTypeEnumMap, json['session_type']) ??
      KegelSessionType.standard,
  exerciseName: json['exercise_name'] as String?,
  performedDuring: $enumDecodeNullable(
    _$KegelPerformedDuringEnumMap,
    json['performed_during'],
  ),
  workoutId: json['workout_id'] as String?,
  difficultyRating: (json['difficulty_rating'] as num?)?.toInt(),
  notes: json['notes'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$KegelSessionToJson(
  KegelSession instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'session_date': instance.sessionDate.toIso8601String(),
  'session_time': instance.sessionTime,
  'duration_seconds': instance.durationSeconds,
  'reps_completed': instance.repsCompleted,
  'hold_duration_seconds': instance.holdDurationSeconds,
  'session_type': _$KegelSessionTypeEnumMap[instance.sessionType]!,
  'exercise_name': instance.exerciseName,
  'performed_during': _$KegelPerformedDuringEnumMap[instance.performedDuring],
  'workout_id': instance.workoutId,
  'difficulty_rating': instance.difficultyRating,
  'notes': instance.notes,
  'created_at': instance.createdAt.toIso8601String(),
};

const _$KegelSessionTypeEnumMap = {
  KegelSessionType.quick: 'quick',
  KegelSessionType.standard: 'standard',
  KegelSessionType.advanced: 'advanced',
  KegelSessionType.custom: 'custom',
};

const _$KegelPerformedDuringEnumMap = {
  KegelPerformedDuring.warmup: 'warmup',
  KegelPerformedDuring.cooldown: 'cooldown',
  KegelPerformedDuring.standalone: 'standalone',
  KegelPerformedDuring.dailyRoutine: 'daily_routine',
  KegelPerformedDuring.other: 'other',
};

KegelStats _$KegelStatsFromJson(Map<String, dynamic> json) => KegelStats(
  userId: json['user_id'] as String,
  kegelsEnabled: json['kegels_enabled'] as bool? ?? false,
  targetSessionsPerDay: (json['target_sessions_per_day'] as num?)?.toInt() ?? 3,
  totalDaysPracticed: (json['total_days_practiced'] as num?)?.toInt() ?? 0,
  totalSessions: (json['total_sessions'] as num?)?.toInt() ?? 0,
  totalDurationSeconds: (json['total_duration_seconds'] as num?)?.toInt() ?? 0,
  avgSessionDuration: (json['avg_session_duration'] as num?)?.toInt() ?? 0,
  sessionsToday: (json['sessions_today'] as num?)?.toInt() ?? 0,
  sessionsLast7Days: (json['sessions_last_7_days'] as num?)?.toInt() ?? 0,
  currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
  longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
  dailyGoalMetToday: json['daily_goal_met_today'] as bool? ?? false,
);

Map<String, dynamic> _$KegelStatsToJson(KegelStats instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'kegels_enabled': instance.kegelsEnabled,
      'target_sessions_per_day': instance.targetSessionsPerDay,
      'total_days_practiced': instance.totalDaysPracticed,
      'total_sessions': instance.totalSessions,
      'total_duration_seconds': instance.totalDurationSeconds,
      'avg_session_duration': instance.avgSessionDuration,
      'sessions_today': instance.sessionsToday,
      'sessions_last_7_days': instance.sessionsLast7Days,
      'current_streak': instance.currentStreak,
      'longest_streak': instance.longestStreak,
      'daily_goal_met_today': instance.dailyGoalMetToday,
    };

KegelExercise _$KegelExerciseFromJson(Map<String, dynamic> json) =>
    KegelExercise(
      id: json['id'] as String,
      name: json['name'] as String,
      displayName: json['display_name'] as String,
      description: json['description'] as String,
      instructions:
          (json['instructions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      targetAudience: json['target_audience'] as String? ?? 'all',
      focusMuscles:
          (json['focus_muscles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      difficulty: json['difficulty'] as String? ?? 'beginner',
      defaultDurationSeconds:
          (json['default_duration_seconds'] as num?)?.toInt() ?? 30,
      defaultReps: (json['default_reps'] as num?)?.toInt() ?? 10,
      defaultHoldSeconds: (json['default_hold_seconds'] as num?)?.toInt() ?? 5,
      restBetweenRepsSeconds:
          (json['rest_between_reps_seconds'] as num?)?.toInt() ?? 5,
      benefits:
          (json['benefits'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      videoUrl: json['video_url'] as String?,
      animationType: json['animation_type'] as String?,
    );

Map<String, dynamic> _$KegelExerciseToJson(KegelExercise instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'display_name': instance.displayName,
      'description': instance.description,
      'instructions': instance.instructions,
      'target_audience': instance.targetAudience,
      'focus_muscles': instance.focusMuscles,
      'difficulty': instance.difficulty,
      'default_duration_seconds': instance.defaultDurationSeconds,
      'default_reps': instance.defaultReps,
      'default_hold_seconds': instance.defaultHoldSeconds,
      'rest_between_reps_seconds': instance.restBetweenRepsSeconds,
      'benefits': instance.benefits,
      'video_url': instance.videoUrl,
      'animation_type': instance.animationType,
    };

KegelDailyGoal _$KegelDailyGoalFromJson(Map<String, dynamic> json) =>
    KegelDailyGoal(
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      goalMet: json['goal_met'] as bool? ?? false,
      sessionsCompleted: (json['sessions_completed'] as num?)?.toInt() ?? 0,
      targetSessions: (json['target_sessions'] as num?)?.toInt() ?? 3,
      remaining: (json['remaining'] as num?)?.toInt() ?? 3,
    );

Map<String, dynamic> _$KegelDailyGoalToJson(KegelDailyGoal instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'date': instance.date.toIso8601String(),
      'goal_met': instance.goalMet,
      'sessions_completed': instance.sessionsCompleted,
      'target_sessions': instance.targetSessions,
      'remaining': instance.remaining,
    };
