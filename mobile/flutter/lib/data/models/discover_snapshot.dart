import 'package:flutter/foundation.dart';

/// Response from GET /leaderboard/discover (W2).
/// Single-call aggregator: percentile + Rising Stars + Near You + Top 10.
@immutable
class DiscoverSnapshot {
  final String board; // xp | volume | streaks
  final String scope; // global | country | friends
  final String weekStart; // ISO date
  final int yourRank;
  final double yourPercentile; // 0.0 - 100.0
  final String yourTier; // starter | active | rising | elite | top | legendary
  final double yourMetric;
  final int totalActive;
  final String? nextTier;
  final int unitsToNext;
  final String metricLabel; // 'XP' | 'min' | 'days'
  final List<DiscoverEntry> nearYou;
  final List<DiscoverRisingStar> risingStars;
  final List<DiscoverEntry> top10;

  // Tier-persistence hero additions (migration 1951 + 1954 + 1957 backend).
  // yourTierStreakWeeks: consecutive weeks viewer has held their tier-or-better
  // on this board. 0 when not on the board or not in a qualifying tier.
  // yourPeakTier: lifetime best tier ever achieved on this board.
  // yourNextMilestoneWeeks/Xp: "N more for M XP" nudge copy in the hero.
  final int yourTierStreakWeeks;
  final String? yourPeakTier;
  final int? yourNextMilestoneWeeks;
  final int? yourNextMilestoneXp;

  const DiscoverSnapshot({
    required this.board,
    required this.scope,
    required this.weekStart,
    required this.yourRank,
    required this.yourPercentile,
    required this.yourTier,
    required this.yourMetric,
    required this.totalActive,
    this.nextTier,
    this.unitsToNext = 0,
    this.metricLabel = '',
    this.nearYou = const [],
    this.risingStars = const [],
    this.top10 = const [],
    this.yourTierStreakWeeks = 0,
    this.yourPeakTier,
    this.yourNextMilestoneWeeks,
    this.yourNextMilestoneXp,
  });

  factory DiscoverSnapshot.fromJson(Map<String, dynamic> json) => DiscoverSnapshot(
        board: json['board'] as String? ?? 'xp',
        scope: json['scope'] as String? ?? 'global',
        weekStart: json['week_start'] as String? ?? '',
        yourRank: json['your_rank'] as int? ?? 0,
        yourPercentile: ((json['your_percentile'] as num?) ?? 0).toDouble(),
        yourTier: json['your_tier'] as String? ?? 'starter',
        yourMetric: ((json['your_metric'] as num?) ?? 0).toDouble(),
        totalActive: json['total_active'] as int? ?? 0,
        nextTier: json['next_tier'] as String?,
        unitsToNext: json['units_to_next'] as int? ?? 0,
        metricLabel: json['metric_label'] as String? ?? '',
        nearYou: (json['near_you'] as List? ?? [])
            .map((j) => DiscoverEntry.fromJson(j as Map<String, dynamic>))
            .toList(),
        risingStars: (json['rising_stars'] as List? ?? [])
            .map((j) => DiscoverRisingStar.fromJson(j as Map<String, dynamic>))
            .toList(),
        top10: (json['top_10'] as List? ?? [])
            .map((j) => DiscoverEntry.fromJson(j as Map<String, dynamic>))
            .toList(),
        yourTierStreakWeeks: json['your_tier_streak_weeks'] as int? ?? 0,
        yourPeakTier: json['your_peak_tier'] as String?,
        yourNextMilestoneWeeks: json['your_next_milestone_weeks'] as int?,
        yourNextMilestoneXp: json['your_next_milestone_xp'] as int?,
      );
}

@immutable
class DiscoverEntry {
  final String userId;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final int rank;
  final double metricValue;
  final bool isCurrentUser;
  final bool isAnonymous;            // server-driven; TRUE = user opted into anonymous mode
  final int currentLevel;

  // Row-engagement fields (migration 1956). All optional with safe defaults
  // so old cached JSON payloads still decode into valid entries.
  final int? previousRank;
  final int? rankDelta;              // +positive = climbing, -neg = falling
  final int currentStreak;
  final bool prThisWeek;
  final String? countryCode;         // ISO-2, null for anonymous users
  final DateTime? lastActiveAt;
  final String? peakTier;            // lifetime best tier (nullable)

  const DiscoverEntry({
    required this.userId,
    this.username,
    this.displayName,
    this.avatarUrl,
    required this.rank,
    required this.metricValue,
    this.isCurrentUser = false,
    this.isAnonymous = false,
    this.currentLevel = 1,
    this.previousRank,
    this.rankDelta,
    this.currentStreak = 0,
    this.prThisWeek = false,
    this.countryCode,
    this.lastActiveAt,
    this.peakTier,
  });

  factory DiscoverEntry.fromJson(Map<String, dynamic> json) => DiscoverEntry(
        userId: json['user_id'] as String? ?? '',
        username: json['username'] as String?,
        displayName: json['display_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        rank: json['rank'] as int? ?? 0,
        metricValue: ((json['metric_value'] as num?) ?? 0).toDouble(),
        isCurrentUser: json['is_current_user'] as bool? ?? false,
        isAnonymous: json['is_anonymous'] as bool? ?? false,
        currentLevel: (json['current_level'] as int?) ?? 1,
        previousRank: json['previous_rank'] as int?,
        rankDelta: json['rank_delta'] as int?,
        currentStreak: (json['current_streak'] as int?) ?? 0,
        prThisWeek: (json['hit_pr_this_week'] as bool?) ?? false,
        countryCode: json['country_code'] as String?,
        lastActiveAt: _parseIsoDate(json['last_active_at']),
        peakTier: json['peak_tier'] as String?,
      );

  String get bestName {
    final n = displayName ?? username;
    return (n == null || n.isEmpty) ? 'Athlete' : n;
  }

  /// Whether this user has been active within the last 24 hours. Powers the
  /// green activity pulse dot. Null `lastActiveAt` (anonymous users or no
  /// activity yet) renders as inactive.
  bool get isActiveNow {
    final t = lastActiveAt;
    if (t == null) return false;
    return DateTime.now().difference(t) < const Duration(hours: 24);
  }
}

@immutable
class DiscoverRisingStar {
  final String userId;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final int currentRank;
  final int previousRank;
  final int rankDelta;
  final double metricValue;
  final bool isAnonymous;
  final int currentLevel;

  // Row-engagement parity with DiscoverEntry
  final int currentStreak;
  final bool prThisWeek;
  final String? countryCode;
  final DateTime? lastActiveAt;
  final String? peakTier;

  const DiscoverRisingStar({
    required this.userId,
    this.username,
    this.displayName,
    this.avatarUrl,
    required this.currentRank,
    required this.previousRank,
    required this.rankDelta,
    required this.metricValue,
    this.isAnonymous = false,
    this.currentLevel = 1,
    this.currentStreak = 0,
    this.prThisWeek = false,
    this.countryCode,
    this.lastActiveAt,
    this.peakTier,
  });

  factory DiscoverRisingStar.fromJson(Map<String, dynamic> json) => DiscoverRisingStar(
        userId: json['user_id'] as String? ?? '',
        username: json['username'] as String?,
        displayName: json['display_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        currentRank: json['current_rank'] as int? ?? 0,
        previousRank: json['previous_rank'] as int? ?? 0,
        rankDelta: json['rank_delta'] as int? ?? 0,
        metricValue: ((json['metric_value'] as num?) ?? 0).toDouble(),
        isAnonymous: json['is_anonymous'] as bool? ?? false,
        currentLevel: (json['current_level'] as int?) ?? 1,
        currentStreak: (json['current_streak'] as int?) ?? 0,
        prThisWeek: (json['hit_pr_this_week'] as bool?) ?? false,
        countryCode: json['country_code'] as String?,
        lastActiveAt: _parseIsoDate(json['last_active_at']),
        peakTier: json['peak_tier'] as String?,
      );

  String get bestName {
    final n = displayName ?? username;
    return (n == null || n.isEmpty) ? 'Athlete' : n;
  }

  bool get isActiveNow {
    final t = lastActiveAt;
    if (t == null) return false;
    return DateTime.now().difference(t) < const Duration(hours: 24);
  }
}

/// Shared ISO date parser — accepts strings like "2026-04-14T12:00:00Z" or
/// "2026-04-14". Returns null for null/empty/malformed inputs so the UI
/// degrades gracefully to "unknown activity time".
DateTime? _parseIsoDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  if (raw is String && raw.isNotEmpty) {
    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }
  return null;
}
