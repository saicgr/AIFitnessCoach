import 'package:json_annotation/json_annotation.dart';

part 'kegel.g.dart';

// ============================================================================
// ENUMS
// ============================================================================

enum KegelFocusArea {
  @JsonValue('general')
  general,
  @JsonValue('male_specific')
  maleSpecific,
  @JsonValue('female_specific')
  femaleSpecific,
  @JsonValue('postpartum')
  postpartum,
  @JsonValue('prostate_health')
  prostateHealth,
}

extension KegelFocusAreaExtension on KegelFocusArea {
  String get displayName {
    switch (this) {
      case KegelFocusArea.general:
        return 'General';
      case KegelFocusArea.maleSpecific:
        return 'Male-Specific';
      case KegelFocusArea.femaleSpecific:
        return 'Female-Specific';
      case KegelFocusArea.postpartum:
        return 'Postpartum';
      case KegelFocusArea.prostateHealth:
        return 'Prostate Health';
    }
  }
}

enum KegelLevel {
  @JsonValue('beginner')
  beginner,
  @JsonValue('intermediate')
  intermediate,
  @JsonValue('advanced')
  advanced,
}

extension KegelLevelExtension on KegelLevel {
  String get displayName {
    switch (this) {
      case KegelLevel.beginner:
        return 'Beginner';
      case KegelLevel.intermediate:
        return 'Intermediate';
      case KegelLevel.advanced:
        return 'Advanced';
    }
  }
}

enum ReminderFrequency {
  @JsonValue('once')
  once,
  @JsonValue('twice')
  twice,
  @JsonValue('three_times')
  threeTimes,
  @JsonValue('hourly')
  hourly,
}

enum KegelSessionType {
  @JsonValue('quick')
  quick,
  @JsonValue('standard')
  standard,
  @JsonValue('advanced')
  advanced,
  @JsonValue('custom')
  custom,
}

enum KegelPerformedDuring {
  @JsonValue('warmup')
  warmup,
  @JsonValue('cooldown')
  cooldown,
  @JsonValue('standalone')
  standalone,
  @JsonValue('daily_routine')
  dailyRoutine,
  @JsonValue('other')
  other,
}

// ============================================================================
// KEGEL PREFERENCES MODEL
// ============================================================================

@JsonSerializable()
class KegelPreferences {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'kegels_enabled')
  final bool kegelsEnabled;
  @JsonKey(name: 'include_in_warmup')
  final bool includeInWarmup;
  @JsonKey(name: 'include_in_cooldown')
  final bool includeInCooldown;
  @JsonKey(name: 'include_as_standalone')
  final bool includeAsStandalone;
  @JsonKey(name: 'include_in_daily_routine')
  final bool includeInDailyRoutine;
  @JsonKey(name: 'daily_reminder_enabled')
  final bool dailyReminderEnabled;
  @JsonKey(name: 'daily_reminder_time')
  final String? dailyReminderTime;
  @JsonKey(name: 'reminder_frequency')
  final ReminderFrequency reminderFrequency;
  @JsonKey(name: 'target_sessions_per_day')
  final int targetSessionsPerDay;
  @JsonKey(name: 'target_duration_seconds')
  final int targetDurationSeconds;
  @JsonKey(name: 'current_level')
  final KegelLevel currentLevel;
  @JsonKey(name: 'focus_area')
  final KegelFocusArea focusArea;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  KegelPreferences({
    required this.id,
    required this.userId,
    this.kegelsEnabled = false,
    this.includeInWarmup = false,
    this.includeInCooldown = false,
    this.includeAsStandalone = false,
    this.includeInDailyRoutine = false,
    this.dailyReminderEnabled = false,
    this.dailyReminderTime,
    this.reminderFrequency = ReminderFrequency.twice,
    this.targetSessionsPerDay = 3,
    this.targetDurationSeconds = 300,
    this.currentLevel = KegelLevel.beginner,
    this.focusArea = KegelFocusArea.general,
    required this.createdAt,
    required this.updatedAt,
  });

  factory KegelPreferences.fromJson(Map<String, dynamic> json) =>
      _$KegelPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$KegelPreferencesToJson(this);

  KegelPreferences copyWith({
    String? id,
    String? userId,
    bool? kegelsEnabled,
    bool? includeInWarmup,
    bool? includeInCooldown,
    bool? includeAsStandalone,
    bool? includeInDailyRoutine,
    bool? dailyReminderEnabled,
    String? dailyReminderTime,
    ReminderFrequency? reminderFrequency,
    int? targetSessionsPerDay,
    int? targetDurationSeconds,
    KegelLevel? currentLevel,
    KegelFocusArea? focusArea,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KegelPreferences(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      kegelsEnabled: kegelsEnabled ?? this.kegelsEnabled,
      includeInWarmup: includeInWarmup ?? this.includeInWarmup,
      includeInCooldown: includeInCooldown ?? this.includeInCooldown,
      includeAsStandalone: includeAsStandalone ?? this.includeAsStandalone,
      includeInDailyRoutine:
          includeInDailyRoutine ?? this.includeInDailyRoutine,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderTime: dailyReminderTime ?? this.dailyReminderTime,
      reminderFrequency: reminderFrequency ?? this.reminderFrequency,
      targetSessionsPerDay: targetSessionsPerDay ?? this.targetSessionsPerDay,
      targetDurationSeconds:
          targetDurationSeconds ?? this.targetDurationSeconds,
      currentLevel: currentLevel ?? this.currentLevel,
      focusArea: focusArea ?? this.focusArea,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ============================================================================
// KEGEL SESSION MODEL
// ============================================================================

@JsonSerializable()
class KegelSession {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'session_date')
  final DateTime sessionDate;
  @JsonKey(name: 'session_time')
  final String? sessionTime;
  @JsonKey(name: 'duration_seconds')
  final int durationSeconds;
  @JsonKey(name: 'reps_completed')
  final int? repsCompleted;
  @JsonKey(name: 'hold_duration_seconds')
  final int? holdDurationSeconds;
  @JsonKey(name: 'session_type')
  final KegelSessionType sessionType;
  @JsonKey(name: 'exercise_name')
  final String? exerciseName;
  @JsonKey(name: 'performed_during')
  final KegelPerformedDuring? performedDuring;
  @JsonKey(name: 'workout_id')
  final String? workoutId;
  @JsonKey(name: 'difficulty_rating')
  final int? difficultyRating;
  final String? notes;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  KegelSession({
    required this.id,
    required this.userId,
    required this.sessionDate,
    this.sessionTime,
    required this.durationSeconds,
    this.repsCompleted,
    this.holdDurationSeconds,
    this.sessionType = KegelSessionType.standard,
    this.exerciseName,
    this.performedDuring,
    this.workoutId,
    this.difficultyRating,
    this.notes,
    required this.createdAt,
  });

  factory KegelSession.fromJson(Map<String, dynamic> json) =>
      _$KegelSessionFromJson(json);

  Map<String, dynamic> toJson() => _$KegelSessionToJson(this);
}

// ============================================================================
// KEGEL STATS MODEL
// ============================================================================

@JsonSerializable()
class KegelStats {
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'kegels_enabled')
  final bool kegelsEnabled;
  @JsonKey(name: 'target_sessions_per_day')
  final int targetSessionsPerDay;
  @JsonKey(name: 'total_days_practiced')
  final int totalDaysPracticed;
  @JsonKey(name: 'total_sessions')
  final int totalSessions;
  @JsonKey(name: 'total_duration_seconds')
  final int totalDurationSeconds;
  @JsonKey(name: 'avg_session_duration')
  final int avgSessionDuration;
  @JsonKey(name: 'sessions_today')
  final int sessionsToday;
  @JsonKey(name: 'sessions_last_7_days')
  final int sessionsLast7Days;
  @JsonKey(name: 'current_streak')
  final int currentStreak;
  @JsonKey(name: 'longest_streak')
  final int longestStreak;
  @JsonKey(name: 'daily_goal_met_today')
  final bool dailyGoalMetToday;

  KegelStats({
    required this.userId,
    this.kegelsEnabled = false,
    this.targetSessionsPerDay = 3,
    this.totalDaysPracticed = 0,
    this.totalSessions = 0,
    this.totalDurationSeconds = 0,
    this.avgSessionDuration = 0,
    this.sessionsToday = 0,
    this.sessionsLast7Days = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.dailyGoalMetToday = false,
  });

  factory KegelStats.fromJson(Map<String, dynamic> json) =>
      _$KegelStatsFromJson(json);

  Map<String, dynamic> toJson() => _$KegelStatsToJson(this);

  String get totalDurationFormatted {
    final hours = totalDurationSeconds ~/ 3600;
    final minutes = (totalDurationSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

// ============================================================================
// KEGEL EXERCISE MODEL
// ============================================================================

@JsonSerializable()
class KegelExercise {
  final String id;
  final String name;
  @JsonKey(name: 'display_name')
  final String displayName;
  final String description;
  final List<String> instructions;
  @JsonKey(name: 'target_audience')
  final String targetAudience;
  @JsonKey(name: 'focus_muscles')
  final List<String> focusMuscles;
  final String difficulty;
  @JsonKey(name: 'default_duration_seconds')
  final int defaultDurationSeconds;
  @JsonKey(name: 'default_reps')
  final int defaultReps;
  @JsonKey(name: 'default_hold_seconds')
  final int defaultHoldSeconds;
  @JsonKey(name: 'rest_between_reps_seconds')
  final int restBetweenRepsSeconds;
  final List<String> benefits;
  @JsonKey(name: 'video_url')
  final String? videoUrl;
  @JsonKey(name: 'animation_type')
  final String? animationType;

  KegelExercise({
    required this.id,
    required this.name,
    required this.displayName,
    required this.description,
    this.instructions = const [],
    this.targetAudience = 'all',
    this.focusMuscles = const [],
    this.difficulty = 'beginner',
    this.defaultDurationSeconds = 30,
    this.defaultReps = 10,
    this.defaultHoldSeconds = 5,
    this.restBetweenRepsSeconds = 5,
    this.benefits = const [],
    this.videoUrl,
    this.animationType,
  });

  factory KegelExercise.fromJson(Map<String, dynamic> json) =>
      _$KegelExerciseFromJson(json);

  Map<String, dynamic> toJson() => _$KegelExerciseToJson(this);

  bool get isForMen => targetAudience == 'all' || targetAudience == 'male';
  bool get isForWomen => targetAudience == 'all' || targetAudience == 'female';
}

// ============================================================================
// KEGEL DAILY GOAL MODEL
// ============================================================================

@JsonSerializable()
class KegelDailyGoal {
  @JsonKey(name: 'user_id')
  final String userId;
  final DateTime date;
  @JsonKey(name: 'goal_met')
  final bool goalMet;
  @JsonKey(name: 'sessions_completed')
  final int sessionsCompleted;
  @JsonKey(name: 'target_sessions')
  final int targetSessions;
  final int remaining;

  KegelDailyGoal({
    required this.userId,
    required this.date,
    this.goalMet = false,
    this.sessionsCompleted = 0,
    this.targetSessions = 3,
    this.remaining = 3,
  });

  factory KegelDailyGoal.fromJson(Map<String, dynamic> json) =>
      _$KegelDailyGoalFromJson(json);

  Map<String, dynamic> toJson() => _$KegelDailyGoalToJson(this);

  double get progressPercent =>
      targetSessions > 0 ? (sessionsCompleted / targetSessions).clamp(0.0, 1.0) : 0.0;
}
