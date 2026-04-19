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
  });
}
