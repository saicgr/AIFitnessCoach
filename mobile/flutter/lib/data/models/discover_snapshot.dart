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

  const DiscoverEntry({
    required this.userId,
    this.username,
    this.displayName,
    this.avatarUrl,
    required this.rank,
    required this.metricValue,
    this.isCurrentUser = false,
  });

  factory DiscoverEntry.fromJson(Map<String, dynamic> json) => DiscoverEntry(
        userId: json['user_id'] as String? ?? '',
        username: json['username'] as String?,
        displayName: json['display_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        rank: json['rank'] as int? ?? 0,
        metricValue: ((json['metric_value'] as num?) ?? 0).toDouble(),
        isCurrentUser: json['is_current_user'] as bool? ?? false,
      );

  String get bestName {
    final n = displayName ?? username;
    return (n == null || n.isEmpty) ? 'Athlete' : n;
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

  const DiscoverRisingStar({
    required this.userId,
    this.username,
    this.displayName,
    this.avatarUrl,
    required this.currentRank,
    required this.previousRank,
    required this.rankDelta,
    required this.metricValue,
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
      );

  String get bestName {
    final n = displayName ?? username;
    return (n == null || n.isEmpty) ? 'Athlete' : n;
  }
}
