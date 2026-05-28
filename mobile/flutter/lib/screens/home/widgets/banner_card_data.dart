import 'package:flutter/material.dart';

/// All supported banner types in priority order (lowest index = highest priority)
enum BannerType {
  renewal,
  missedWorkout,
  rankPercentile,   // e.g. "Top 1% this week" — tap → Discover
  dailyCrate,
  doubleXP,
  week1Tip,
  contextual,
  wrapped,
  healthCoaching,  // Phase C3: proactive readiness briefing / anomaly / activity nudge
  streakAtRisk,    // F3.2 streak-at-risk pre-warning / last-chance
}

/// Unified data model for all home screen banner cards.
///
/// Each banner type maps its provider data into this single model so the
/// [StackedBannerPanel] can render them uniformly at a fixed 84px height.
class BannerCardData {
  final BannerType type;
  final String id;
  final IconData? icon;
  final String? emoji;
  final String title;
  final String subtitle;
  final Color accentColor;
  final String? actionLabel;
  final VoidCallback? onTap;
  final VoidCallback? onAction;

  /// Optional: extra data needed by specific banner actions (e.g. MissedWorkout object)
  final dynamic payload;

  /// Optional shared deterministic notification id, e.g. `<type>_<localdate>`.
  ///
  /// When set, [BannerNotificationMapper.toNotification] uses this verbatim as
  /// the bell-entry id instead of the `banner_<id>` default — so a push and
  /// the same-day banner that share this id dedupe to ONE notification-bell
  /// entry (Phase C3). Banners without a server-side push counterpart leave
  /// this null and keep the default `banner_<id>` scheme.
  final String? notifId;

  const BannerCardData({
    required this.type,
    required this.id,
    this.icon,
    this.emoji,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    this.actionLabel,
    this.onTap,
    this.onAction,
    this.payload,
    this.notifId,
  });
}
