/// NEAT streak tracking models.
///
/// These models support:
/// - Multiple streak types (steps, active hours, NEAT score)
/// - Current and longest streak tracking
/// - Streak achievement milestones
/// - Streak recovery and maintenance
library;

import 'package:json_annotation/json_annotation.dart';

part 'neat_streak.g.dart';

/// Types of NEAT-related streaks
enum NeatStreakType {
  @JsonValue('steps')
  steps,
  @JsonValue('active_hours')
  activeHours,
  @JsonValue('neat_score')
  neatScore;

  String get displayName {
    switch (this) {
      case NeatStreakType.steps:
        return 'Step Goal Streak';
      case NeatStreakType.activeHours:
        return 'Active Hours Streak';
      case NeatStreakType.neatScore:
        return 'NEAT Score Streak';
    }
  }

  String get shortName {
    switch (this) {
      case NeatStreakType.steps:
        return 'Steps';
      case NeatStreakType.activeHours:
        return 'Active';
      case NeatStreakType.neatScore:
        return 'Score';
    }
  }

  String get icon {
    switch (this) {
      case NeatStreakType.steps:
        return 'directions_walk';
      case NeatStreakType.activeHours:
        return 'schedule';
      case NeatStreakType.neatScore:
        return 'local_fire_department';
    }
  }

  String get description {
    switch (this) {
      case NeatStreakType.steps:
        return 'Consecutive days meeting your step goal';
      case NeatStreakType.activeHours:
        return 'Consecutive days with 8+ active hours';
      case NeatStreakType.neatScore:
        return 'Consecutive days with NEAT score 70+';
    }
  }
}

/// User's streak for a specific NEAT metric
@JsonSerializable()
class NeatStreak {
  final String? id;

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'streak_type')
  final NeatStreakType streakType;

  @JsonKey(name: 'current_streak')
  final int currentStreak;

  @JsonKey(name: 'longest_streak')
  final int longestStreak;

  @JsonKey(name: 'last_achievement_date')
  final String? lastAchievementDate;

  @JsonKey(name: 'streak_start_date')
  final String? streakStartDate;

  @JsonKey(name: 'is_active')
  final bool isActive;

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const NeatStreak({
    this.id,
    required this.userId,
    required this.streakType,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastAchievementDate,
    this.streakStartDate,
    this.isActive = false,
    this.createdAt,
    this.updatedAt,
  });

  factory NeatStreak.fromJson(Map<String, dynamic> json) =>
      _$NeatStreakFromJson(json);

  Map<String, dynamic> toJson() => _$NeatStreakToJson(this);

  /// Last achievement date as DateTime
  DateTime? get lastAchievementDateTime =>
      lastAchievementDate != null ? DateTime.tryParse(lastAchievementDate!) : null;

  /// Streak start date as DateTime
  DateTime? get streakStartDateTime =>
      streakStartDate != null ? DateTime.tryParse(streakStartDate!) : null;

  /// Whether this is the user's personal best streak
  bool get isPersonalBest => currentStreak > 0 && currentStreak >= longestStreak;

  /// Progress toward next streak milestone
  int get nextMilestone {
    if (currentStreak < 7) return 7;
    if (currentStreak < 14) return 14;
    if (currentStreak < 30) return 30;
    if (currentStreak < 60) return 60;
    if (currentStreak < 90) return 90;
    if (currentStreak < 180) return 180;
    return 365;
  }

  /// Progress toward next milestone (0.0 to 1.0)
  double get milestoneProgress {
    final previousMilestone = _previousMilestone;
    final range = nextMilestone - previousMilestone;
    if (range <= 0) return 1.0;
    return ((currentStreak - previousMilestone) / range).clamp(0.0, 1.0);
  }

  int get _previousMilestone {
    if (currentStreak < 7) return 0;
    if (currentStreak < 14) return 7;
    if (currentStreak < 30) return 14;
    if (currentStreak < 60) return 30;
    if (currentStreak < 90) return 60;
    if (currentStreak < 180) return 90;
    return 180;
  }

  /// Days until streak is at risk (not achieved yesterday)
  bool get isAtRisk {
    if (lastAchievementDateTime == null) return false;
    final now = DateTime.now();
    final daysSinceLast = now.difference(lastAchievementDateTime!).inDays;
    return daysSinceLast >= 1;
  }

  /// Get a motivational message based on streak status
  String get motivationalMessage {
    if (currentStreak == 0) {
      return 'Start your ${streakType.shortName.toLowerCase()} streak today!';
    } else if (currentStreak == 1) {
      return 'Day 1 - Great start! Keep it going!';
    } else if (currentStreak < 7) {
      return '$currentStreak days strong! Push for a week!';
    } else if (currentStreak == 7) {
      return 'One week streak achieved!';
    } else if (currentStreak < 14) {
      return '$currentStreak days! Two weeks is in sight!';
    } else if (currentStreak < 30) {
      return '$currentStreak day streak! Aim for a month!';
    } else if (currentStreak == 30) {
      return 'One month streak - incredible!';
    } else {
      return '$currentStreak days - you\'re unstoppable!';
    }
  }

  /// Create a copy with updated values
  NeatStreak copyWith({
    String? id,
    String? userId,
    NeatStreakType? streakType,
    int? currentStreak,
    int? longestStreak,
    String? lastAchievementDate,
    String? streakStartDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NeatStreak(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      streakType: streakType ?? this.streakType,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastAchievementDate: lastAchievementDate ?? this.lastAchievementDate,
      streakStartDate: streakStartDate ?? this.streakStartDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Collection of all streak types for a user
@JsonSerializable()
class NeatStreakSummary {
  @JsonKey(name: 'user_id')
  final String userId;

  final List<NeatStreak> streaks;

  @JsonKey(name: 'best_active_streak')
  final NeatStreak? bestActiveStreak;

  @JsonKey(name: 'total_streak_days')
  final int totalStreakDays;

  const NeatStreakSummary({
    required this.userId,
    this.streaks = const [],
    this.bestActiveStreak,
    this.totalStreakDays = 0,
  });

  factory NeatStreakSummary.fromJson(Map<String, dynamic> json) =>
      _$NeatStreakSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$NeatStreakSummaryToJson(this);

  /// Get streak by type
  NeatStreak? getStreak(NeatStreakType type) {
    try {
      return streaks.firstWhere((s) => s.streakType == type);
    } catch (_) {
      return null;
    }
  }

  /// Get step goal streak
  NeatStreak? get stepStreak => getStreak(NeatStreakType.steps);

  /// Get active hours streak
  NeatStreak? get activeHoursStreak => getStreak(NeatStreakType.activeHours);

  /// Get NEAT score streak
  NeatStreak? get neatScoreStreak => getStreak(NeatStreakType.neatScore);

  /// Any active streaks
  bool get hasActiveStreak => streaks.any((s) => s.currentStreak > 0);

  /// All active streaks
  List<NeatStreak> get activeStreaks =>
      streaks.where((s) => s.currentStreak > 0).toList();

  /// Longest current streak across all types
  NeatStreak? get longestCurrentStreak {
    final active = activeStreaks;
    if (active.isEmpty) return null;
    return active.reduce((a, b) => a.currentStreak >= b.currentStreak ? a : b);
  }
}

/// Streak milestone achievement
@JsonSerializable()
class NeatStreakMilestone {
  final int days;

  @JsonKey(name: 'streak_type')
  final NeatStreakType streakType;

  final String name;

  final String? icon;

  @JsonKey(name: 'achieved_at')
  final DateTime? achievedAt;

  const NeatStreakMilestone({
    required this.days,
    required this.streakType,
    required this.name,
    this.icon,
    this.achievedAt,
  });

  factory NeatStreakMilestone.fromJson(Map<String, dynamic> json) =>
      _$NeatStreakMilestoneFromJson(json);

  Map<String, dynamic> toJson() => _$NeatStreakMilestoneToJson(this);

  /// Whether this milestone has been achieved
  bool get isAchieved => achievedAt != null;
}
