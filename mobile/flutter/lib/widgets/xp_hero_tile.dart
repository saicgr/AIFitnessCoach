import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/accent_color_provider.dart';
import '../data/models/weekly_xp_summary.dart';
import '../data/providers/weekly_xp_summary_provider.dart';
import '../data/providers/xp_provider.dart';

/// Three-row XP hero tile used on the You hub (Overview + Stats & Rewards).
///
/// Row 1 — Weekly XP (hero metric per market research), delta chip, 7-day
///         mini-sparkline.
/// Row 2 — Level chip + progress bar to next level + reward-preview chip.
/// Row 3 — Streak flame + optional "log X for +N XP" nudge.
///
/// Reads from three providers:
///   • `userXpProvider`           → level + xp_in_current_level/xp_to_next
///   • `weeklyXpSummaryProvider`  → hero row (this_week / last_week / sparkline / nudge)
///   • `nextLevelPreviewProvider` → reward chip (kind + label + icon + tier)
///   • `xpCurrentStreakProvider`  → streak flame count
///
/// Empty / loading states degrade gracefully — any row can render its own
/// shimmer or skeleton without breaking the rest. Keeps the card alive
/// while the weekly-summary call is still in flight.
class XpHeroTile extends ConsumerWidget {
  final bool muted;

  const XpHeroTile({super.key, this.muted = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final accent = AccentColorScope.of(context).getColor(isDark);

    final userXp = ref.watch(userXpProvider);
    final weeklyAsync = ref.watch(weeklyXpSummaryProvider);
    final nextLevelAsync = ref.watch(nextLevelPreviewProvider);
    final streak = ref.watch(xpCurrentStreakProvider);

    final level = userXp?.currentLevel ?? 1;
    final progress = userXp?.progressFraction ?? 0.0;
    final xpInLevel = userXp?.xpInCurrentLevel ?? 0;
    final xpToNext = userXp?.xpToNextLevel ?? 150;

    final bgAlpha = muted ? 0.04 : 0.12;
    final borderAlpha = muted ? 0.15 : 0.35;
    final iconColor = muted ? fg.withValues(alpha: 0.4) : accent;

    final weekly = weeklyAsync.maybeWhen(
      data: (s) => s,
      orElse: () => WeeklyXpSummary.empty,
    );
    final nextLevel = nextLevelAsync.maybeWhen(
      data: (v) => v,
      orElse: () => null,
    );

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.push('/xp-goals');
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: muted
              ? fg.withValues(alpha: bgAlpha)
              : accent.withValues(alpha: bgAlpha),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: muted
                ? fg.withValues(alpha: borderAlpha)
                : accent.withValues(alpha: borderAlpha),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WeeklyHeroRow(
              weekly: weekly,
              fg: fg,
              accent: iconColor,
              loading: weeklyAsync.isLoading,
            ),
            const SizedBox(height: 14),
            _LevelRow(
              level: level,
              xpInLevel: xpInLevel,
              xpToNext: xpToNext,
              progress: progress,
              reward: nextLevel?.reward,
              fg: fg,
              accent: iconColor,
              muted: muted,
            ),
            if (streak > 0 || weekly.nextNudge.isNotEmpty) ...[
              const SizedBox(height: 12),
              _MicroStatsRow(
                streak: streak,
                nudgeKey: weekly.nextNudge,
                fg: fg,
                accent: iconColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}


// ========================================================================
// Row 1 — Weekly XP hero
// ========================================================================

class _WeeklyHeroRow extends StatelessWidget {
  final WeeklyXpSummary weekly;
  final Color fg;
  final Color accent;
  final bool loading;

  const _WeeklyHeroRow({
    required this.weekly,
    required this.fg,
    required this.accent,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final delta = weekly.delta;
    final deltaColor = delta > 0
        ? const Color(0xFF22C55E)
        : (delta < 0 ? const Color(0xFFEF4444) : fg.withValues(alpha: 0.5));
    final deltaIcon = delta > 0
        ? Icons.arrow_upward_rounded
        : (delta < 0 ? Icons.arrow_downward_rounded : Icons.remove_rounded);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'THIS WEEK',
                style: TextStyle(
                  color: fg.withValues(alpha: 0.55),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    loading && weekly.thisWeekXp == 0
                        ? '—'
                        : '+${weekly.thisWeekXp}',
                    style: TextStyle(
                      color: fg,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'XP',
                      style: TextStyle(
                        color: fg.withValues(alpha: 0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (weekly.lastWeekXp > 0 || delta != 0) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(deltaIcon, color: deltaColor, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      _formatDelta(delta, weekly.deltaPercent),
                      style: TextStyle(
                        color: deltaColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'vs last week',
                      style: TextStyle(
                        color: fg.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        _Sparkline(
          values: weekly.sparkline7day,
          accent: accent,
          baseColor: fg.withValues(alpha: 0.15),
        ),
      ],
    );
  }

  String _formatDelta(int delta, double? pct) {
    final sign = delta > 0 ? '+' : (delta < 0 ? '' : '');
    if (pct == null) return '$sign$delta XP';
    return '$sign${pct.abs().toStringAsFixed(0)}%';
  }
}


/// Tiny bar-style sparkline. 7 bars fixed-width so the layout is stable
/// across users. Empty weeks render as flat bars, never blank space.
class _Sparkline extends StatelessWidget {
  final List<int> values;
  final Color accent;
  final Color baseColor;

  const _Sparkline({
    required this.values,
    required this.accent,
    required this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    final max = values.fold<int>(0, (a, b) => b > a ? b : a);
    return SizedBox(
      width: 88,
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < values.length; i++) ...[
            Container(
              width: 8,
              height: max == 0 ? 4 : 4 + (values[i] / max * 32),
              decoration: BoxDecoration(
                color: values[i] == 0 ? baseColor : accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (i < values.length - 1) const SizedBox(width: 3),
          ],
        ],
      ),
    );
  }
}


// ========================================================================
// Row 2 — Level + progress bar + reward chip
// ========================================================================

class _LevelRow extends StatelessWidget {
  final int level;
  final int xpInLevel;
  final int xpToNext;
  final double progress;
  final NextLevelReward? reward;
  final Color fg;
  final Color accent;
  final bool muted;

  const _LevelRow({
    required this.level,
    required this.xpInLevel,
    required this.xpToNext,
    required this.progress,
    required this.reward,
    required this.fg,
    required this.accent,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (xpToNext - xpInLevel).clamp(0, xpToNext);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _LevelChip(level: level, fg: fg, accent: accent, muted: muted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$xpInLevel / $xpToNext XP',
                style: TextStyle(
                  color: fg.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$remaining to Lv ${level + 1}',
              style: TextStyle(
                color: fg.withValues(alpha: 0.55),
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: fg.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
        if (reward != null) ...[
          const SizedBox(height: 10),
          _RewardPreviewChip(
            nextLevel: level + 1,
            reward: reward!,
            fg: fg,
            accent: accent,
          ),
        ],
      ],
    );
  }
}


class _LevelChip extends StatelessWidget {
  final int level;
  final Color fg;
  final Color accent;
  final bool muted;

  const _LevelChip({
    required this.level,
    required this.fg,
    required this.accent,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: muted ? 0.12 : 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Text(
        'Lv $level',
        style: TextStyle(
          color: fg,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}


class _RewardPreviewChip extends StatelessWidget {
  final int nextLevel;
  final NextLevelReward reward;
  final Color fg;
  final Color accent;

  const _RewardPreviewChip({
    required this.nextLevel,
    required this.reward,
    required this.fg,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fg.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _iconFor(reward.icon),
            color: _tierColor(reward.tier, accent),
            size: 14,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Lv $nextLevel → ${reward.label}',
              style: TextStyle(
                color: fg.withValues(alpha: 0.85),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Map server-provided icon keys to Material `IconData`. Keeping this
  /// centralised means the backend can evolve the reward catalogue without
  /// forcing a client release — unknown keys fall back to a safe default.
  IconData _iconFor(String key) {
    switch (key) {
      case 'shield_rounded':
        return Icons.shield_rounded;
      case 'workspace_premium':
        return Icons.workspace_premium;
      case 'palette_outlined':
        return Icons.palette_outlined;
      case 'switch_account_outlined':
        return Icons.switch_account_outlined;
      case 'apps_outlined':
        return Icons.apps_outlined;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'insights_rounded':
        return Icons.insights_rounded;
      case 'event_repeat_rounded':
        return Icons.event_repeat_rounded;
      case 'local_shipping_outlined':
        return Icons.local_shipping_outlined;
      case 'sell_outlined':
        return Icons.sell_outlined;
      case 'checkroom_outlined':
        return Icons.checkroom_outlined;
      case 'auto_awesome_outlined':
      default:
        return Icons.auto_awesome_outlined;
    }
  }

  Color _tierColor(String tier, Color accent) {
    switch (tier) {
      case 'platinum':
        return const Color(0xFFE5E7EB);
      case 'gold':
        return const Color(0xFFFBBF24);
      case 'silver':
      default:
        return accent;
    }
  }
}


// ========================================================================
// Row 3 — Streak + nudge
// ========================================================================

class _MicroStatsRow extends StatelessWidget {
  final int streak;
  final String nudgeKey;
  final Color fg;
  final Color accent;

  const _MicroStatsRow({
    required this.streak,
    required this.nudgeKey,
    required this.fg,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (streak > 0) ...[
          Icon(
            Icons.local_fire_department,
            color: const Color(0xFFFB923C),
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            '$streak-day streak',
            style: TextStyle(
              color: fg.withValues(alpha: 0.75),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (streak > 0 && nudgeKey.isNotEmpty) ...[
          const SizedBox(width: 10),
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: fg.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
        ],
        if (nudgeKey.isNotEmpty)
          Flexible(
            child: Text(
              _nudgeCopyFor(nudgeKey),
              style: TextStyle(
                color: accent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  /// Nudge copy maps — variant-pool compliant (4+ options where
  /// meaningful) per the dynamic-copy feedback file. For now the server
  /// returns a single key per nudge type; the UI picks from variants on a
  /// stable day-hash so copy doesn't flicker mid-session.
  String _nudgeCopyFor(String key) {
    final day = DateTime.now().day;
    const pool = {
      'log_breakfast': [
        'Log breakfast for +20 XP',
        'Breakfast logged = +20 XP',
        'Tap to log breakfast · +20',
        'Start the day: log breakfast · +20',
      ],
      'log_workout': [
        'Log a workout for +50 XP',
        'Today\'s workout = +50 XP',
        'Tap to log a workout · +50',
        'Finish strong: log workout · +50',
      ],
    };
    final variants = pool[key];
    if (variants == null || variants.isEmpty) return '';
    return variants[day % variants.length];
  }
}
