import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'fasting.g.dart';

/// Fasting zone representing metabolic stages during a fast
enum FastingZone {
  fed('Fed State', Color(0xFF9E9E9E), 0),
  postAbsorptive('Processing', Color(0xFF64B5F6), 4),
  earlyFasting('Early Fasting', Color(0xFF26A69A), 8),
  fatBurning('Fat Burning', Color(0xFF66BB6A), 12),
  ketosis('Ketosis', Color(0xFFFF9800), 16),
  deepKetosis('Deep Ketosis', Color(0xFFEF5350), 24),
  extended('Extended', Color(0xFF9C27B0), 48);

  final String displayName;
  final Color color;
  final int startHour;

  const FastingZone(this.displayName, this.color, this.startHour);

  /// Get zone for given elapsed hours
  static FastingZone forElapsedHours(int hours, {bool isKetoAdapted = false}) {
    final adjustment = isKetoAdapted ? 2 : 0;

    if (hours < 4) return FastingZone.fed;
    if (hours < 8 - adjustment) return FastingZone.postAbsorptive;
    if (hours < 12 - adjustment) return FastingZone.earlyFasting;
    if (hours < 16 - adjustment) return FastingZone.fatBurning;
    if (hours < 24 - adjustment) return FastingZone.ketosis;
    if (hours < 48) return FastingZone.deepKetosis;
    return FastingZone.extended;
  }

  /// Get zone for given elapsed minutes
  static FastingZone fromElapsedMinutes(int minutes, {bool isKetoAdapted = false}) {
    return forElapsedHours(minutes ~/ 60, isKetoAdapted: isKetoAdapted);
  }

  /// Get description for this zone
  String get description {
    switch (this) {
      case FastingZone.fed:
        return 'Your body is digesting food and insulin levels are elevated.';
      case FastingZone.postAbsorptive:
        return 'Blood sugar is normalizing as digestion completes.';
      case FastingZone.earlyFasting:
        return 'Glycogen stores are being depleted for energy.';
      case FastingZone.fatBurning:
        return 'Your body is switching to fat as its primary fuel source.';
      case FastingZone.ketosis:
        return 'Ketone production is increasing. Growth hormone may be elevated.';
      case FastingZone.deepKetosis:
        return 'Deep ketosis. Autophagy may be occurring.';
      case FastingZone.extended:
        return 'Extended fast. Consult a healthcare provider for fasts this long.';
    }
  }
}

/// Fasting protocol types
enum FastingProtocolType {
  tre, // Time-Restricted Eating (16:8, 18:6, etc.)
  modified, // 5:2, ADF
  extended, // 24h+
  custom,
}

/// Predefined fasting protocols
enum FastingProtocol {
  twelve12('12:12', 12, 12, FastingProtocolType.tre, 'Beginner'),
  fourteen10('14:10', 14, 10, FastingProtocolType.tre, 'Beginner'),
  sixteen8('16:8', 16, 8, FastingProtocolType.tre, 'Intermediate'),
  eighteen6('18:6', 18, 6, FastingProtocolType.tre, 'Intermediate'),
  twenty4('20:4', 20, 4, FastingProtocolType.tre, 'Advanced'),
  omad('OMAD', 23, 1, FastingProtocolType.tre, 'Advanced'),
  fiveTwo('5:2', 24, 0, FastingProtocolType.modified, 'Intermediate'),
  adf('ADF', 24, 0, FastingProtocolType.modified, 'Advanced'),
  custom('Custom', 0, 0, FastingProtocolType.custom, 'Varies');

  final String displayName;
  final int fastingHours;
  final int eatingHours;
  final FastingProtocolType type;
  final String difficulty;

  const FastingProtocol(
    this.displayName,
    this.fastingHours,
    this.eatingHours,
    this.type,
    this.difficulty,
  );

  /// Get the protocol ID (same as the enum name)
  String get id => name;

  /// Get protocol from string
  static FastingProtocol fromString(String value) {
    return FastingProtocol.values.firstWhere(
      (p) => p.displayName == value || p.name == value,
      orElse: () => FastingProtocol.sixteen8,
    );
  }
}

/// Zone entry during a fast
@JsonSerializable()
class FastingZoneEntry {
  @JsonKey(name: 'zone_name')
  final String zoneName;
  @JsonKey(name: 'entered_at')
  final DateTime enteredAt;
  @JsonKey(name: 'minutes_in_zone')
  final int? minutesInZone;

  const FastingZoneEntry({
    required this.zoneName,
    required this.enteredAt,
    this.minutesInZone,
  });

  factory FastingZoneEntry.fromJson(Map<String, dynamic> json) =>
      _$FastingZoneEntryFromJson(json);
  Map<String, dynamic> toJson() => _$FastingZoneEntryToJson(this);
}

/// Individual fasting record
@JsonSerializable()
class FastingRecord {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'start_time')
  final DateTime startTime;
  @JsonKey(name: 'end_time')
  final DateTime? endTime;
  @JsonKey(name: 'goal_duration_minutes')
  final int goalDurationMinutes;
  @JsonKey(name: 'actual_duration_minutes')
  final int? actualDurationMinutes;
  final String protocol;
  @JsonKey(name: 'protocol_type')
  final String protocolType;
  final String status;
  @JsonKey(name: 'completed_goal')
  final bool completedGoal;
  @JsonKey(name: 'completion_percentage')
  final double? completionPercentage;
  @JsonKey(name: 'zones_reached')
  final List<FastingZoneEntry>? zonesReached;
  final String? notes;
  @JsonKey(name: 'mood_before')
  final String? moodBefore;
  @JsonKey(name: 'mood_after')
  final String? moodAfter;
  @JsonKey(name: 'energy_level_before')
  final int? energyLevelBefore;
  @JsonKey(name: 'energy_level_after')
  final int? energyLevelAfter;
  @JsonKey(name: 'ended_by')
  final String? endedBy;
  @JsonKey(name: 'breaking_meal_id')
  final String? breakingMealId;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const FastingRecord({
    required this.id,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.goalDurationMinutes,
    this.actualDurationMinutes,
    required this.protocol,
    required this.protocolType,
    this.status = 'active',
    this.completedGoal = false,
    this.completionPercentage,
    this.zonesReached,
    this.notes,
    this.moodBefore,
    this.moodAfter,
    this.energyLevelBefore,
    this.energyLevelAfter,
    this.endedBy,
    this.breakingMealId,
    required this.createdAt,
    this.updatedAt,
  });

  /// Check if fast is currently active
  bool get isActive => status == 'active' && endTime == null;

  /// Get elapsed duration in minutes
  int get elapsedMinutes {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime).inMinutes;
  }

  /// Get elapsed hours
  int get elapsedHours => elapsedMinutes ~/ 60;

  /// Get remaining minutes until goal
  int get remainingMinutes {
    final remaining = goalDurationMinutes - elapsedMinutes;
    return remaining > 0 ? remaining : 0;
  }

  /// Get progress percentage (0.0 - 1.0+)
  double get progress => elapsedMinutes / goalDurationMinutes;

  /// Get current fasting zone
  FastingZone get currentZone => FastingZone.forElapsedHours(elapsedHours);

  /// Format elapsed time as string
  String get elapsedTimeString {
    final hours = elapsedMinutes ~/ 60;
    final mins = elapsedMinutes % 60;
    return '${hours}h ${mins}m';
  }

  /// Format remaining time as string
  String get remainingTimeString {
    final hours = remainingMinutes ~/ 60;
    final mins = remainingMinutes % 60;
    return '${hours}h ${mins}m';
  }

  factory FastingRecord.fromJson(Map<String, dynamic> json) =>
      _$FastingRecordFromJson(json);
  Map<String, dynamic> toJson() => _$FastingRecordToJson(this);

  FastingRecord copyWith({
    String? id,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    int? goalDurationMinutes,
    int? actualDurationMinutes,
    String? protocol,
    String? protocolType,
    String? status,
    bool? completedGoal,
    double? completionPercentage,
    List<FastingZoneEntry>? zonesReached,
    String? notes,
    String? moodBefore,
    String? moodAfter,
    int? energyLevelBefore,
    int? energyLevelAfter,
    String? endedBy,
    String? breakingMealId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FastingRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      goalDurationMinutes: goalDurationMinutes ?? this.goalDurationMinutes,
      actualDurationMinutes:
          actualDurationMinutes ?? this.actualDurationMinutes,
      protocol: protocol ?? this.protocol,
      protocolType: protocolType ?? this.protocolType,
      status: status ?? this.status,
      completedGoal: completedGoal ?? this.completedGoal,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      zonesReached: zonesReached ?? this.zonesReached,
      notes: notes ?? this.notes,
      moodBefore: moodBefore ?? this.moodBefore,
      moodAfter: moodAfter ?? this.moodAfter,
      energyLevelBefore: energyLevelBefore ?? this.energyLevelBefore,
      energyLevelAfter: energyLevelAfter ?? this.energyLevelAfter,
      endedBy: endedBy ?? this.endedBy,
      breakingMealId: breakingMealId ?? this.breakingMealId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Fasting preferences for a user
@JsonSerializable()
class FastingPreferences {
  final String? id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'default_protocol')
  final String defaultProtocol;
  @JsonKey(name: 'custom_fasting_hours')
  final int? customFastingHours;
  @JsonKey(name: 'custom_eating_hours')
  final int? customEatingHours;
  @JsonKey(name: 'typical_fast_start_hour')
  final int typicalFastStartHour;
  @JsonKey(name: 'typical_eating_start_hour')
  final int typicalEatingStartHour;
  @JsonKey(name: 'fasting_days')
  final List<String>? fastingDays;
  @JsonKey(name: 'notifications_enabled')
  final bool notificationsEnabled;
  @JsonKey(name: 'notify_zone_transitions')
  final bool notifyZoneTransitions;
  @JsonKey(name: 'notify_goal_reached')
  final bool notifyGoalReached;
  @JsonKey(name: 'notify_eating_window_end')
  final bool notifyEatingWindowEnd;
  @JsonKey(name: 'notify_fast_start_reminder')
  final bool notifyFastStartReminder;
  @JsonKey(name: 'safety_screening_completed')
  final bool safetyScreeningCompleted;
  @JsonKey(name: 'safety_warnings_acknowledged')
  final List<String>? safetyWarningsAcknowledged;
  @JsonKey(name: 'has_medical_conditions')
  final bool hasMedicalConditions;
  @JsonKey(name: 'fasting_onboarding_completed')
  final bool fastingOnboardingCompleted;
  @JsonKey(name: 'onboarding_completed_at')
  final DateTime? onboardingCompletedAt;
  @JsonKey(name: 'experience_level')
  final String experienceLevel;

  const FastingPreferences({
    this.id,
    required this.userId,
    this.defaultProtocol = '16:8',
    this.customFastingHours,
    this.customEatingHours,
    this.typicalFastStartHour = 20,
    this.typicalEatingStartHour = 12,
    this.fastingDays,
    this.notificationsEnabled = true,
    this.notifyZoneTransitions = true,
    this.notifyGoalReached = true,
    this.notifyEatingWindowEnd = true,
    this.notifyFastStartReminder = true,
    this.safetyScreeningCompleted = false,
    this.safetyWarningsAcknowledged,
    this.hasMedicalConditions = false,
    this.fastingOnboardingCompleted = false,
    this.onboardingCompletedAt,
    this.experienceLevel = 'beginner',
  });

  /// Get the fasting hours for current protocol
  int get fastingHours {
    if (defaultProtocol == 'custom') {
      return customFastingHours ?? 16;
    }
    return FastingProtocol.fromString(defaultProtocol).fastingHours;
  }

  /// Get the eating hours for current protocol
  int get eatingHours {
    if (defaultProtocol == 'custom') {
      return customEatingHours ?? 8;
    }
    return FastingProtocol.fromString(defaultProtocol).eatingHours;
  }

  factory FastingPreferences.fromJson(Map<String, dynamic> json) =>
      _$FastingPreferencesFromJson(json);
  Map<String, dynamic> toJson() => _$FastingPreferencesToJson(this);

  FastingPreferences copyWith({
    String? id,
    String? userId,
    String? defaultProtocol,
    int? customFastingHours,
    int? customEatingHours,
    int? typicalFastStartHour,
    int? typicalEatingStartHour,
    List<String>? fastingDays,
    bool? notificationsEnabled,
    bool? notifyZoneTransitions,
    bool? notifyGoalReached,
    bool? notifyEatingWindowEnd,
    bool? notifyFastStartReminder,
    bool? safetyScreeningCompleted,
    List<String>? safetyWarningsAcknowledged,
    bool? hasMedicalConditions,
    bool? fastingOnboardingCompleted,
    DateTime? onboardingCompletedAt,
    String? experienceLevel,
  }) {
    return FastingPreferences(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      defaultProtocol: defaultProtocol ?? this.defaultProtocol,
      customFastingHours: customFastingHours ?? this.customFastingHours,
      customEatingHours: customEatingHours ?? this.customEatingHours,
      typicalFastStartHour: typicalFastStartHour ?? this.typicalFastStartHour,
      typicalEatingStartHour:
          typicalEatingStartHour ?? this.typicalEatingStartHour,
      fastingDays: fastingDays ?? this.fastingDays,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notifyZoneTransitions:
          notifyZoneTransitions ?? this.notifyZoneTransitions,
      notifyGoalReached: notifyGoalReached ?? this.notifyGoalReached,
      notifyEatingWindowEnd:
          notifyEatingWindowEnd ?? this.notifyEatingWindowEnd,
      notifyFastStartReminder:
          notifyFastStartReminder ?? this.notifyFastStartReminder,
      safetyScreeningCompleted:
          safetyScreeningCompleted ?? this.safetyScreeningCompleted,
      safetyWarningsAcknowledged:
          safetyWarningsAcknowledged ?? this.safetyWarningsAcknowledged,
      hasMedicalConditions: hasMedicalConditions ?? this.hasMedicalConditions,
      fastingOnboardingCompleted:
          fastingOnboardingCompleted ?? this.fastingOnboardingCompleted,
      onboardingCompletedAt:
          onboardingCompletedAt ?? this.onboardingCompletedAt,
      experienceLevel: experienceLevel ?? this.experienceLevel,
    );
  }
}

/// Fasting streak data
@JsonSerializable()
class FastingStreak {
  final String? id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'current_streak')
  final int currentStreak;
  @JsonKey(name: 'longest_streak')
  final int longestStreak;
  @JsonKey(name: 'total_fasts_completed')
  final int totalFastsCompleted;
  @JsonKey(name: 'total_fasting_minutes')
  final int totalFastingMinutes;
  @JsonKey(name: 'last_fast_date')
  final DateTime? lastFastDate;
  @JsonKey(name: 'streak_start_date')
  final DateTime? streakStartDate;
  @JsonKey(name: 'fasts_this_week')
  final int fastsThisWeek;
  @JsonKey(name: 'week_start_date')
  final DateTime? weekStartDate;
  @JsonKey(name: 'freezes_available')
  final int freezesAvailable;
  @JsonKey(name: 'freezes_used_this_week')
  final int freezesUsedThisWeek;
  @JsonKey(name: 'weekly_goal_enabled')
  final bool weeklyGoalEnabled;
  @JsonKey(name: 'weekly_goal_fasts')
  final int weeklyGoalFasts;

  const FastingStreak({
    this.id,
    required this.userId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalFastsCompleted = 0,
    this.totalFastingMinutes = 0,
    this.lastFastDate,
    this.streakStartDate,
    this.fastsThisWeek = 0,
    this.weekStartDate,
    this.freezesAvailable = 2,
    this.freezesUsedThisWeek = 0,
    this.weeklyGoalEnabled = false,
    this.weeklyGoalFasts = 5,
  });

  /// Get total fasting hours
  int get totalFastingHours => totalFastingMinutes ~/ 60;

  /// Check if weekly goal is met
  bool get weeklyGoalMet =>
      weeklyGoalEnabled && fastsThisWeek >= weeklyGoalFasts;

  /// Days remaining to meet weekly goal
  int get daysRemainingForGoal {
    if (!weeklyGoalEnabled) return 0;
    final remaining = weeklyGoalFasts - fastsThisWeek;
    return remaining > 0 ? remaining : 0;
  }

  factory FastingStreak.fromJson(Map<String, dynamic> json) =>
      _$FastingStreakFromJson(json);
  Map<String, dynamic> toJson() => _$FastingStreakToJson(this);
}

/// Fasting statistics summary
@JsonSerializable()
class FastingStats {
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'completed_fasts')
  final int completedFasts;
  @JsonKey(name: 'total_fasts')
  final int totalFasts;
  @JsonKey(name: 'avg_duration_minutes')
  final double avgDurationMinutes;
  @JsonKey(name: 'longest_fast_minutes')
  final int longestFastMinutes;
  @JsonKey(name: 'total_fasting_minutes')
  final int totalFastingMinutes;

  const FastingStats({
    required this.userId,
    this.completedFasts = 0,
    this.totalFasts = 0,
    this.avgDurationMinutes = 0,
    this.longestFastMinutes = 0,
    this.totalFastingMinutes = 0,
  });

  /// Completion rate as percentage
  double get completionRate =>
      totalFasts > 0 ? (completedFasts / totalFasts) * 100 : 0;

  /// Average duration in hours
  double get avgDurationHours => avgDurationMinutes / 60;

  /// Longest fast in hours
  double get longestFastHours => longestFastMinutes / 60;

  /// Total fasting time in hours
  int get totalFastingHours => totalFastingMinutes ~/ 60;

  factory FastingStats.fromJson(Map<String, dynamic> json) =>
      _$FastingStatsFromJson(json);
  Map<String, dynamic> toJson() => _$FastingStatsToJson(this);
}

/// Result of ending a fast
class FastEndResult {
  final FastingRecord record;
  final bool streakMaintained;
  final String message;
  final bool usedFreeze;

  const FastEndResult({
    required this.record,
    required this.streakMaintained,
    required this.message,
    this.usedFreeze = false,
  });

  factory FastEndResult.fromJson(Map<String, dynamic> json) {
    return FastEndResult(
      record: FastingRecord.fromJson(json['record'] as Map<String, dynamic>),
      streakMaintained: json['streak_maintained'] as bool? ?? true,
      message: json['message'] as String? ?? '',
      usedFreeze: json['used_freeze'] as bool? ?? false,
    );
  }

  /// Get encouraging message based on completion
  String get encouragingMessage {
    final percent = record.completionPercentage ?? record.progress * 100;

    if (percent >= 100) {
      return "Excellent! You completed your ${record.goalDurationMinutes ~/ 60}h fast!";
    } else if (percent >= 80) {
      return "Great job! You completed ${percent.round()}% of your goal. Your streak is maintained!";
    } else if (percent >= 50) {
      return "Good effort! You fasted for ${record.elapsedTimeString}. Every fast counts!";
    } else {
      return "No problem! You fasted for ${record.elapsedTimeString}. Tomorrow is a new opportunity!";
    }
  }
}

/// Safety screening question for fasting
class FastingSafetyQuestion {
  final String id;
  final String question;
  final bool blocksIfTrue;
  final String blockMessage;
  final String? warnMessage;

  const FastingSafetyQuestion({
    required this.id,
    required this.question,
    required this.blocksIfTrue,
    required this.blockMessage,
    this.warnMessage,
  });
}

/// Default safety screening questions
final List<FastingSafetyQuestion> fastingSafetyQuestions = [
  const FastingSafetyQuestion(
    id: 'pregnant_breastfeeding',
    question: "Are you pregnant or breastfeeding?",
    blocksIfTrue: true,
    blockMessage: "Fasting is not recommended during pregnancy or breastfeeding.",
  ),
  const FastingSafetyQuestion(
    id: 'eating_disorder',
    question: "Do you have a history of eating disorders?",
    blocksIfTrue: true,
    blockMessage:
        "For your safety, we don't recommend fasting for those with a history of eating disorders.",
  ),
  const FastingSafetyQuestion(
    id: 'type1_diabetes',
    question: "Do you have Type 1 diabetes?",
    blocksIfTrue: true,
    blockMessage:
        "Type 1 diabetics should not fast without strict medical supervision.",
  ),
  const FastingSafetyQuestion(
    id: 'under_18',
    question: "Are you under 18 years old?",
    blocksIfTrue: true,
    blockMessage: "Fasting is not recommended for those under 18.",
  ),
  const FastingSafetyQuestion(
    id: 'medication_with_food',
    question: "Do you take medications that must be taken with food?",
    blocksIfTrue: false,
    blockMessage: "",
    warnMessage:
        "Please consult your doctor about adjusting medication timing before starting a fasting protocol.",
  ),
  const FastingSafetyQuestion(
    id: 'type2_diabetes_bp',
    question: "Do you have Type 2 diabetes or take blood pressure medications?",
    blocksIfTrue: false,
    blockMessage: "",
    warnMessage:
        "We recommend consulting your doctor before starting intermittent fasting. You may need to adjust your medication.",
  ),
];
