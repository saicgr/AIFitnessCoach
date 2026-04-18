import 'package:flutter/foundation.dart';

/// Per-user leaderboard privacy toggles.
/// Backed by `users.{show_on_leaderboard, leaderboard_anonymous, profile_stats_visible}`.
@immutable
class PrivacySettings {
  /// Master switch. When false, user is excluded from Discover leaderboards.
  final bool showOnLeaderboard;

  /// When true, user shows as "Anonymous athlete" (masked name + avatar).
  final bool leaderboardAnonymous;

  /// When true, tapping my leaderboard entry reveals my bio + radar shape.
  final bool profileStatsVisible;

  const PrivacySettings({
    required this.showOnLeaderboard,
    required this.leaderboardAnonymous,
    required this.profileStatsVisible,
  });

  /// Safe defaults — everything visible (matches migration 1941 defaults).
  static const defaults = PrivacySettings(
    showOnLeaderboard: true,
    leaderboardAnonymous: false,
    profileStatsVisible: true,
  );

  factory PrivacySettings.fromJson(Map<String, dynamic> json) => PrivacySettings(
        showOnLeaderboard: json['show_on_leaderboard'] as bool? ?? true,
        leaderboardAnonymous: json['leaderboard_anonymous'] as bool? ?? false,
        profileStatsVisible: json['profile_stats_visible'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'show_on_leaderboard': showOnLeaderboard,
        'leaderboard_anonymous': leaderboardAnonymous,
        'profile_stats_visible': profileStatsVisible,
      };

  PrivacySettings copyWith({
    bool? showOnLeaderboard,
    bool? leaderboardAnonymous,
    bool? profileStatsVisible,
  }) =>
      PrivacySettings(
        showOnLeaderboard: showOnLeaderboard ?? this.showOnLeaderboard,
        leaderboardAnonymous: leaderboardAnonymous ?? this.leaderboardAnonymous,
        profileStatsVisible: profileStatsVisible ?? this.profileStatsVisible,
      );
}
