import 'package:flutter/foundation.dart';

/// Backend response for `GET /api/v1/leaderboard/weekly-recap`.
///
/// Rendered once per ISO week in a full-screen dialog on first Monday-6am
/// app foreground. All fields are optional/defaultable so an uncompleted
/// recap (user wasn't ranked last week) decodes into a mostly-empty object
/// that the dialog recognizes and skips.
@immutable
class WeeklyRecap {
  final String weekStart; // ISO yyyy-MM-dd
  final String boardType; // 'xp' | 'volume' | 'streaks'
  final int? rankCurrent;
  final int? rankPrevious;
  final int? rankDelta;
  final String? tierCurrent;
  final String? tierPrevious;
  final int xpEarnedThisWeek;
  final int shieldsUsed;
  final List<RecapReward> awardsUnlocked;
  final List<RecapPeer> passes;
  final List<RecapPeer> overtakenBy;
  final int consecutiveWeeksInTier;
  final int? nextMilestoneWeeks;
  final int? nextMilestoneXp;
  final String? coachPersonaMessage;

  const WeeklyRecap({
    required this.weekStart,
    required this.boardType,
    this.rankCurrent,
    this.rankPrevious,
    this.rankDelta,
    this.tierCurrent,
    this.tierPrevious,
    this.xpEarnedThisWeek = 0,
    this.shieldsUsed = 0,
    this.awardsUnlocked = const [],
    this.passes = const [],
    this.overtakenBy = const [],
    this.consecutiveWeeksInTier = 0,
    this.nextMilestoneWeeks,
    this.nextMilestoneXp,
    this.coachPersonaMessage,
  });

  /// `true` when we have enough data to render a meaningful modal. The
  /// dialog-gate provider uses this to suppress "empty recap" dialogs for
  /// users who weren't on the board last week — no point waking them up
  /// with "nothing happened last week".
  bool get hasMeaningfulContent {
    if (rankCurrent != null) return true;
    if (xpEarnedThisWeek > 0) return true;
    if (awardsUnlocked.isNotEmpty) return true;
    return false;
  }

  factory WeeklyRecap.fromJson(Map<String, dynamic> json) => WeeklyRecap(
        weekStart: json['week_start'] as String? ?? '',
        boardType: json['board_type'] as String? ?? 'xp',
        rankCurrent: json['rank_current'] as int?,
        rankPrevious: json['rank_previous'] as int?,
        rankDelta: json['rank_delta'] as int?,
        tierCurrent: json['tier_current'] as String?,
        tierPrevious: json['tier_previous'] as String?,
        xpEarnedThisWeek: json['xp_earned_this_week'] as int? ?? 0,
        shieldsUsed: json['shields_used'] as int? ?? 0,
        awardsUnlocked: (json['awards_unlocked'] as List? ?? [])
            .map((j) => RecapReward.fromJson(j as Map<String, dynamic>))
            .toList(),
        passes: (json['passes'] as List? ?? [])
            .map((j) => RecapPeer.fromJson(j as Map<String, dynamic>))
            .toList(),
        overtakenBy: (json['overtaken_by'] as List? ?? [])
            .map((j) => RecapPeer.fromJson(j as Map<String, dynamic>))
            .toList(),
        consecutiveWeeksInTier: json['consecutive_weeks_in_tier'] as int? ?? 0,
        nextMilestoneWeeks: json['next_milestone_weeks'] as int?,
        nextMilestoneXp: json['next_milestone_xp'] as int?,
        coachPersonaMessage: json['coach_persona_message'] as String?,
      );
}

@immutable
class RecapReward {
  final String kind;              // tier_persistence | first_time_tier | cumulative_weeks | peak_rank | rising_star | phoenix_rising | shield_save
  final String? badgeId;
  final String? badgeName;
  final String? badgeIcon;
  final String? rarity;
  final int xp;
  final String? tier;
  final int? consecutiveWeeks;

  const RecapReward({
    required this.kind,
    this.badgeId,
    this.badgeName,
    this.badgeIcon,
    this.rarity,
    this.xp = 0,
    this.tier,
    this.consecutiveWeeks,
  });

  factory RecapReward.fromJson(Map<String, dynamic> json) => RecapReward(
        kind: json['kind'] as String? ?? '',
        badgeId: json['badge_id'] as String?,
        badgeName: json['badge_name'] as String?,
        badgeIcon: json['badge_icon'] as String?,
        rarity: json['rarity'] as String?,
        xp: json['xp'] as int? ?? 0,
        tier: json['tier'] as String?,
        consecutiveWeeks: json['consecutive_weeks'] as int?,
      );
}

@immutable
class RecapPeer {
  final String userId;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final int? previousRank;
  final int? currentRank;

  const RecapPeer({
    required this.userId,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.previousRank,
    this.currentRank,
  });

  factory RecapPeer.fromJson(Map<String, dynamic> json) => RecapPeer(
        userId: json['user_id'] as String? ?? '',
        username: json['username'] as String?,
        displayName: json['display_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        previousRank: json['previous_rank'] as int?,
        currentRank: json['current_rank'] as int?,
      );

  String get bestName {
    final n = displayName ?? username;
    return (n == null || n.isEmpty) ? 'Athlete' : n;
  }
}
