import 'package:flutter/material.dart';

/// Returns the brand color for a leaderboard tier.
///
/// Backend tier strings come from `_tier_from_rank` (migration 1954):
///   top1 | top5 | top10 | top25 | active | starter
///
/// Legacy callers may also pass `legendary | top | elite | rising` from the
/// `compute_user_percentile` RPC (same semantics, older labels). Both are
/// accepted here so we don't have to normalize at every call site.
///
/// `isDark` toggles between dark-mode-optimized and light-mode-optimized
/// palettes. Colors are tuned to remain legible against AppColors.elevated
/// and AppColorsLight.elevated respectively.
Color tierColor(String? tier, bool isDark) {
  switch (tier) {
    case 'top1':
    case 'legendary':
      // Gold — richest prestige color. Slightly warmer in dark mode so it
      // pops against near-black surfaces.
      return isDark ? const Color(0xFFFFD369) : const Color(0xFFD99A00);
    case 'top5':
    case 'top':
      // Purple — distinct from XP-Goals accent but sits in the same family.
      return isDark ? const Color(0xFFC28DFF) : const Color(0xFF7B2CBF);
    case 'top10':
    case 'elite':
      // Cyan-blue — reads as "elevated" without overpowering gold/purple.
      return isDark ? const Color(0xFF66D9EF) : const Color(0xFF0A7EA4);
    case 'top25':
    case 'rising':
      // Green — associates with growth / "on the rise".
      return isDark ? const Color(0xFF7ED88A) : const Color(0xFF1F8A3C);
    case 'active':
      // Neutral blue-gray — signals "still on the board" without ranking.
      return isDark ? const Color(0xFF93A1B1) : const Color(0xFF586069);
    case 'starter':
    default:
      return isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
  }
}

/// Thin border color for avatar ring. Slightly desaturated tier color so it
/// reads as a ring rather than a solid halo.
Color tierRing(String? tier, bool isDark) {
  final base = tierColor(tier, isDark);
  return base.withValues(alpha: isDark ? 0.85 : 0.9);
}

/// Human-readable label used in the tier-streak hero line + weekly recap.
String tierDisplayName(String? tier) {
  switch (tier) {
    case 'top1':
    case 'legendary':
      return 'Top 1%';
    case 'top5':
    case 'top':
      return 'Top 5%';
    case 'top10':
    case 'elite':
      return 'Top 10%';
    case 'top25':
    case 'rising':
      return 'Top 25%';
    case 'active':
      return 'Active';
    default:
      return '';
  }
}
