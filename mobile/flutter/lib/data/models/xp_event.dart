import 'package:json_annotation/json_annotation.dart';

part 'xp_event.g.dart';

/// Active XP multiplier event (Double XP Weekend, etc.)
@JsonSerializable()
class XPEvent {
  final String id;
  @JsonKey(name: 'event_name')
  final String eventName;
  @JsonKey(name: 'event_type')
  final String eventType;
  final String? description;
  @JsonKey(name: 'xp_multiplier')
  final double xpMultiplier;
  @JsonKey(name: 'start_at')
  final DateTime startAt;
  @JsonKey(name: 'end_at')
  final DateTime endAt;
  @JsonKey(name: 'icon_name')
  final String? iconName;
  @JsonKey(name: 'banner_color')
  final String? bannerColor;

  const XPEvent({
    required this.id,
    required this.eventName,
    required this.eventType,
    this.description,
    required this.xpMultiplier,
    required this.startAt,
    required this.endAt,
    this.iconName,
    this.bannerColor,
  });

  factory XPEvent.fromJson(Map<String, dynamic> json) => _$XPEventFromJson(json);
  Map<String, dynamic> toJson() => _$XPEventToJson(this);

  /// Whether this is a Double XP event (2x or more)
  bool get isDoubleXP => xpMultiplier >= 2.0;

  /// Time remaining until event ends
  Duration get timeRemaining => endAt.difference(DateTime.now());

  /// Whether the event is currently active
  bool get isActive => DateTime.now().isBefore(endAt) && DateTime.now().isAfter(startAt);

  /// Formatted time remaining (e.g., "1d 5h 30m")
  String get formattedTimeRemaining {
    final remaining = timeRemaining;
    if (remaining.isNegative) return 'Ended';

    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;

    if (days > 0) {
      return '${days}d ${hours}h';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Multiplier display (e.g., "2x XP")
  String get multiplierDisplay => '${xpMultiplier.toStringAsFixed(xpMultiplier == xpMultiplier.roundToDouble() ? 0 : 1)}x XP';
}

/// User's login streak information
@JsonSerializable()
class LoginStreakInfo {
  @JsonKey(name: 'current_streak')
  final int currentStreak;
  @JsonKey(name: 'longest_streak')
  final int longestStreak;
  @JsonKey(name: 'total_logins')
  final int totalLogins;
  @JsonKey(name: 'last_login_date')
  final String? lastLoginDate;
  @JsonKey(name: 'first_login_at')
  final DateTime? firstLoginAt;
  @JsonKey(name: 'streak_start_date')
  final String? streakStartDate;
  @JsonKey(name: 'has_logged_in_today')
  final bool hasLoggedInToday;

  const LoginStreakInfo({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalLogins,
    this.lastLoginDate,
    this.firstLoginAt,
    this.streakStartDate,
    required this.hasLoggedInToday,
  });

  factory LoginStreakInfo.fromJson(Map<String, dynamic> json) => _$LoginStreakInfoFromJson(json);
  Map<String, dynamic> toJson() => _$LoginStreakInfoToJson(this);

  factory LoginStreakInfo.empty() => const LoginStreakInfo(
    currentStreak: 0,
    longestStreak: 0,
    totalLogins: 0,
    hasLoggedInToday: false,
  );

  /// Days until next milestone (7, 30, 100, 365)
  int? get daysToNextMilestone {
    final milestones = [7, 30, 100, 365];
    for (final m in milestones) {
      if (currentStreak < m) return m - currentStreak;
    }
    return null; // Already past all milestones
  }

  /// Next milestone number
  int? get nextMilestone {
    final milestones = [7, 30, 100, 365];
    for (final m in milestones) {
      if (currentStreak < m) return m;
    }
    return null;
  }
}

/// Result from processing daily login
@JsonSerializable()
class DailyLoginResult {
  @JsonKey(name: 'is_first_login')
  final bool isFirstLogin;
  @JsonKey(name: 'streak_broken')
  final bool streakBroken;
  @JsonKey(name: 'current_streak')
  final int currentStreak;
  @JsonKey(name: 'longest_streak')
  final int longestStreak;
  @JsonKey(name: 'total_logins')
  final int totalLogins;
  @JsonKey(name: 'daily_xp')
  final int dailyXp;
  @JsonKey(name: 'first_login_xp')
  final int firstLoginXp;
  @JsonKey(name: 'streak_milestone_xp')
  final int streakMilestoneXp;
  @JsonKey(name: 'total_xp_awarded')
  final int totalXpAwarded;
  @JsonKey(name: 'active_events')
  final List<XPEvent>? activeEvents;
  final double multiplier;
  final String message;
  @JsonKey(name: 'already_claimed')
  final bool alreadyClaimed;

  const DailyLoginResult({
    required this.isFirstLogin,
    required this.streakBroken,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalLogins,
    required this.dailyXp,
    required this.firstLoginXp,
    required this.streakMilestoneXp,
    required this.totalXpAwarded,
    this.activeEvents,
    required this.multiplier,
    required this.message,
    this.alreadyClaimed = false,
  });

  factory DailyLoginResult.fromJson(Map<String, dynamic> json) {
    // Handle active_events which might be a list of maps
    List<XPEvent>? events;
    if (json['active_events'] != null) {
      final eventsList = json['active_events'] as List;
      events = eventsList.map((e) => XPEvent.fromJson(e as Map<String, dynamic>)).toList();
    }

    return DailyLoginResult(
      isFirstLogin: json['is_first_login'] as bool? ?? false,
      streakBroken: json['streak_broken'] as bool? ?? false,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      totalLogins: json['total_logins'] as int? ?? 0,
      dailyXp: json['daily_xp'] as int? ?? 0,
      firstLoginXp: json['first_login_xp'] as int? ?? 0,
      streakMilestoneXp: json['streak_milestone_xp'] as int? ?? 0,
      totalXpAwarded: json['total_xp_awarded'] as int? ?? 0,
      activeEvents: events,
      multiplier: (json['multiplier'] as num?)?.toDouble() ?? 1.0,
      message: json['message'] as String? ?? '',
      alreadyClaimed: json['already_claimed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'is_first_login': isFirstLogin,
    'streak_broken': streakBroken,
    'current_streak': currentStreak,
    'longest_streak': longestStreak,
    'total_logins': totalLogins,
    'daily_xp': dailyXp,
    'first_login_xp': firstLoginXp,
    'streak_milestone_xp': streakMilestoneXp,
    'total_xp_awarded': totalXpAwarded,
    'active_events': activeEvents?.map((e) => e.toJson()).toList(),
    'multiplier': multiplier,
    'message': message,
    'already_claimed': alreadyClaimed,
  };

  /// Whether this was a significant event (first login, milestone, etc.)
  bool get isSignificant => isFirstLogin || streakMilestoneXp > 0 || totalXpAwarded > 100;

  /// Whether Double XP is active
  bool get hasDoubleXP => multiplier >= 2.0;
}

/// XP bonus template definition
@JsonSerializable()
class XPBonusTemplate {
  final String id;
  @JsonKey(name: 'bonus_type')
  final String bonusType;
  @JsonKey(name: 'base_xp')
  final int baseXp;
  final String? description;
  @JsonKey(name: 'streak_multiplier')
  final bool streakMultiplier;
  @JsonKey(name: 'max_streak_multiplier')
  final int maxStreakMultiplier;
  @JsonKey(name: 'is_active')
  final bool isActive;

  const XPBonusTemplate({
    required this.id,
    required this.bonusType,
    required this.baseXp,
    this.description,
    required this.streakMultiplier,
    required this.maxStreakMultiplier,
    required this.isActive,
  });

  factory XPBonusTemplate.fromJson(Map<String, dynamic> json) => _$XPBonusTemplateFromJson(json);
  Map<String, dynamic> toJson() => _$XPBonusTemplateToJson(this);

  /// Display name for the bonus type
  String get displayName {
    switch (bonusType) {
      case 'first_login':
        return 'Welcome Bonus';
      case 'daily_login':
        return 'Daily Check-in';
      case 'streak_milestone_7':
        return '7-Day Streak';
      case 'streak_milestone_30':
        return '30-Day Streak';
      case 'streak_milestone_100':
        return '100-Day Streak';
      case 'streak_milestone_365':
        return '365-Day Streak';
      case 'weekly_workouts':
        return 'Weekly Workouts';
      case 'weekly_perfect':
        return 'Perfect Week';
      case 'monthly_dedication':
        return 'Monthly Dedication';
      case 'monthly_goal_met':
        return 'Monthly Goal';
      default:
        return bonusType.replaceAll('_', ' ');
    }
  }

  /// Category for grouping (login, weekly, monthly)
  String get category {
    if (bonusType.startsWith('weekly_')) return 'weekly';
    if (bonusType.startsWith('monthly_')) return 'monthly';
    if (bonusType.contains('streak') || bonusType.contains('login')) return 'login';
    return 'other';
  }
}

/// Checkpoint progress for weekly/monthly goals
@JsonSerializable()
class CheckpointProgress {
  @JsonKey(name: 'checkpoint_type')
  final String checkpointType;
  @JsonKey(name: 'period_start')
  final String periodStart;
  @JsonKey(name: 'period_end')
  final String periodEnd;
  @JsonKey(name: 'checkpoints_earned')
  final List<String> checkpointsEarned;
  @JsonKey(name: 'total_xp_earned')
  final int totalXpEarned;

  const CheckpointProgress({
    required this.checkpointType,
    required this.periodStart,
    required this.periodEnd,
    required this.checkpointsEarned,
    required this.totalXpEarned,
  });

  factory CheckpointProgress.fromJson(Map<String, dynamic> json) => _$CheckpointProgressFromJson(json);
  Map<String, dynamic> toJson() => _$CheckpointProgressToJson(this);

  factory CheckpointProgress.empty(String type) => CheckpointProgress(
    checkpointType: type,
    periodStart: DateTime.now().toIso8601String(),
    periodEnd: DateTime.now().toIso8601String(),
    checkpointsEarned: [],
    totalXpEarned: 0,
  );

  /// Number of checkpoints earned
  int get earnedCount => checkpointsEarned.length;

  /// Total possible checkpoints for this period type
  int get totalCheckpoints => checkpointType == 'weekly' ? 8 : 8;

  /// Progress percentage
  double get progressPercentage => earnedCount / totalCheckpoints;
}
