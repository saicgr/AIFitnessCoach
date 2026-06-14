/// Surface 4 — Streak Freeze.
///
/// A dedicated home for OUR passive auto-protect freeze model (NOT Gravl's
/// manual equip-slots — there is no expiry and nothing to tap). The screen
/// maps the Gravl "Freezes protect your streak" surface onto our mechanics:
///
///   1. "Banked Freezes  X / 5" — banked freezes rendered as armed snowflake
///      tiles in a row (filled, ice-blue glow), with dashed-outline empty tiles
///      for the remaining capacity up to the cap (5).
///   2. "Earn next freeze  N / 10" — a progress bar toward the next auto-earned
///      freeze. The API reports `streak_until_next_freeze` in DAYS; we convert
///      to streak-WEEKS (70 days = 10 weeks per freeze) for human-readable copy.
///   3. "Recent activity" — the freeze ledger, each row rendered from its own
///      `.label` getter (earned / auto-protected / used) with an ice icon and a
///      relative date.
///
/// Data source: [streakFreezeStatusProvider] → [StreakFreezeStatus].
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../data/providers/streak_freeze_provider.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/design_system/zealova.dart';

class StreakFreezeScreen extends ConsumerWidget {
  const StreakFreezeScreen({super.key});

  /// The single hardcoded color allowed by the house rules: the existing ice
  /// blue used everywhere freezes appear (freeze rail, day grid, freeze chip).
  static const Color _ice = Color(0xFF4FC3F7);

  /// Freeze capacity cap (passive bank never exceeds this).
  static const int _cap = 5;

  /// Streak-weeks earned per free freeze. The API's `streakPerFreeze` is in
  /// DAYS (70); 70 days / 7 = 10 streak-weeks.
  static const int _weeksPerFreeze = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);
    final statusAsync = ref.watch(streakFreezeStatusProvider);

    return Scaffold(
      backgroundColor: c.background,
      appBar: const ZealovaAppBar(
        title: 'Streak Freeze',
        kicker: 'Protection',
      ),
      body: SafeArea(
        child: statusAsync.when(
          loading: () => const _LoadingState(),
          // The provider already swallows errors and returns an empty status,
          // so this error branch is defensive — show the same body for an empty
          // status either way.
          error: (_, __) => const _LoadingState(),
          data: (status) => RefreshIndicator(
            color: _ice,
            onRefresh: () async {
              HapticService.light();
              ref.invalidate(streakFreezeStatusProvider);
              await ref.read(streakFreezeStatusProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              children: [
                _BankedFreezesCard(status: status),
                const SizedBox(height: AppSpacing.md),
                _EarnNextFreezeCard(status: status),
                const SizedBox(height: AppSpacing.lg),
                _RecentActivitySection(status: status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Card 1 — Banked Freezes  X / 5  (armed snowflake tiles)
// ───────────────────────────────────────────────────────────────────────────

class _BankedFreezesCard extends StatelessWidget {
  final StreakFreezeStatus status;

  const _BankedFreezesCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    // Clamp to the cap so a server overflow can never render more than 5 tiles.
    final banked = status.freezesAvailable.clamp(0, StreakFreezeScreen._cap);

    return _FreezeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: 'Banked Freezes',
            trailing: '$banked / ${StreakFreezeScreen._cap}',
          ),
          const SizedBox(height: AppSpacing.md),
          // One tile per capacity slot: filled (armed) for each banked freeze,
          // dashed-outline (empty) for the remaining capacity.
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = AppSpacing.sm;
              const count = StreakFreezeScreen._cap;
              // Size tiles to fill the row evenly; never overflow on SE.
              final tileSize =
                  ((constraints.maxWidth - gap * (count - 1)) / count)
                      .clamp(40.0, 64.0);
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(count, (i) {
                  final armed = i < banked;
                  return _FreezeTile(size: tileSize, armed: armed);
                }),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Banked freezes automatically protect your streak if you miss a '
            'week — no tapping needed.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single capacity slot. Armed → filled ice tile with a glow + solid
/// snowflake. Empty → dashed-outline tile with a muted snowflake.
class _FreezeTile extends StatelessWidget {
  final double size;
  final bool armed;

  const _FreezeTile({required this.size, required this.armed});

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    const ice = StreakFreezeScreen._ice;
    final iconSize = size * 0.5;

    if (armed) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: ice.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: ice.withValues(alpha: 0.55), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: ice.withValues(alpha: 0.35),
              blurRadius: 14,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Icon(Icons.ac_unit_rounded, size: iconSize, color: ice),
        ),
      );
    }

    // Empty slot — dashed outline + muted snowflake.
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: c.textSecondary.withValues(alpha: 0.35),
        radius: AppRadius.md,
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Icon(
            Icons.ac_unit_rounded,
            size: iconSize,
            color: c.textSecondary.withValues(alpha: 0.28),
          ),
        ),
      ),
    );
  }
}

/// Paints a rounded-rect dashed border for the empty freeze slots.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  static const double _dashWidth = 4;
  static const double _dashGap = 3;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + _dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, math.min(next, metric.length)),
          paint,
        );
        distance = next + _dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

// ───────────────────────────────────────────────────────────────────────────
// Card 2 — Earn next freeze  N / 10  (progress)
// ───────────────────────────────────────────────────────────────────────────

class _EarnNextFreezeCard extends StatelessWidget {
  final StreakFreezeStatus status;

  const _EarnNextFreezeCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    const ice = StreakFreezeScreen._ice;

    // The API reports days; convert to streak-WEEKS (ceil so a partial week
    // still reads as "1 more streak-week" rather than rounding to 0).
    final weeksRemaining = (status.streakUntilNextFreeze / 7).ceil();
    // "Ready" = progress complete or no days left to wait.
    final isReady =
        status.progressToNextFreeze >= 1.0 || status.streakUntilNextFreeze <= 0;
    // Weeks completed within the current 10-week cadence (for the "N / 10"
    // header), derived from the same fraction the progress bar uses.
    final weeksEarned = isReady
        ? StreakFreezeScreen._weeksPerFreeze
        : (StreakFreezeScreen._weeksPerFreeze - weeksRemaining)
            .clamp(0, StreakFreezeScreen._weeksPerFreeze);

    final String caption;
    if (isReady) {
      caption = 'Your next free freeze is ready.';
    } else {
      final wk = weeksRemaining == 1 ? 'streak-week' : 'streak-weeks';
      caption = 'Earn one freeze every 10 streak-weeks. '
          '$weeksRemaining more $wk until your next freeze.';
    }

    return _FreezeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: 'Earn next freeze',
            trailing: '$weeksEarned / ${StreakFreezeScreen._weeksPerFreeze}',
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0,
                end: status.progressToNextFreeze.clamp(0.0, 1.0),
              ),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: c.textSecondary.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(ice),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Text(
            caption,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Section 3 — Recent activity (ledger)
// ───────────────────────────────────────────────────────────────────────────

class _RecentActivitySection extends StatelessWidget {
  final StreakFreezeStatus status;

  const _RecentActivitySection({required this.status});

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final ledger = status.recentLedger;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.sm),
          child: Text(
            'RECENT ACTIVITY',
            style: ZType.disp(20, color: c.textPrimary),
          ),
        ),
        if (ledger.isEmpty)
          _FreezeCard(
            child: Row(
              children: [
                Icon(
                  Icons.ac_unit_rounded,
                  size: 20,
                  color: c.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                Expanded(
                  child: Text(
                    'No freeze activity yet. Keep your streak going and you\'ll '
                    'bank your first freeze automatically.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          _FreezeCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Column(
              children: [
                for (var i = 0; i < ledger.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      color: c.cardBorder,
                    ),
                  _LedgerRow(entry: ledger[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _LedgerRow extends StatelessWidget {
  final StreakFreezeLedgerEntry entry;

  const _LedgerRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    const ice = StreakFreezeScreen._ice;
    final when = _relativeDate(entry.eventDate ?? entry.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: ice.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Center(
              child: Icon(Icons.ac_unit_rounded, size: 18, color: ice),
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Text(
              entry.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
          ),
          if (when != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(
              when,
              style: TextStyle(
                fontSize: 12,
                color: c.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Turns an ISO date/timestamp string into a short relative label
  /// ("Today", "Yesterday", "3d ago", or a calendar date for older entries).
  static String? _relativeDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(parsed.year, parsed.month, parsed.day);
    final days = today.difference(that).inDays;

    if (days <= 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (days < 7) return '${days}d ago';
    if (days < 14) return 'Last week';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final m = months[that.month - 1];
    // Include the year only when it differs from the current year.
    return that.year == now.year
        ? '$m ${that.day}'
        : '$m ${that.day}, ${that.year}';
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Shared chrome
// ───────────────────────────────────────────────────────────────────────────

/// An ice-tinted card shell, matching the existing freeze-rail visual style
/// (`_buildFreezeRail` in streak_timeframe_sheet.dart): faint ice fill + ice
/// border so every freeze surface reads as "cold" without a hard recolor.
class _FreezeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _FreezeCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  @override
  Widget build(BuildContext context) {
    const ice = StreakFreezeScreen._ice;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: ice.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: ice.withValues(alpha: 0.22)),
      ),
      child: child,
    );
  }
}

/// Title row with a small ice snowflake + a trailing "X / Y" count pill.
class _CardHeader extends StatelessWidget {
  final String title;
  final String trailing;

  const _CardHeader({required this.title, required this.trailing});

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    const ice = StreakFreezeScreen._ice;
    return Row(
      children: [
        const Icon(Icons.ac_unit_rounded, size: 18, color: ice),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: ZType.lbl(13, color: c.textPrimary, letterSpacing: 1.5),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 2,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: ice.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Text(
            trailing,
            style: ZType.data(13, color: ice),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Loading skeleton — mirrors the real layout so the swap doesn't reflow.
// ───────────────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        // Banked freezes card placeholder.
        _FreezeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonBox(width: 160, height: 18),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  StreakFreezeScreen._cap,
                  (_) => const SkeletonBox(width: 48, height: 48, radius: 12),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const SkeletonText(lines: 2, lastLineFraction: 0.7),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Earn-next card placeholder.
        _FreezeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SkeletonBox(width: 140, height: 18),
              SizedBox(height: AppSpacing.md),
              SkeletonBox(height: 10, radius: 6),
              SizedBox(height: AppSpacing.sm + 2),
              SkeletonText(lines: 2, lastLineFraction: 0.6),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Padding(
          padding: EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.sm),
          child: SkeletonBox(width: 120, height: 16),
        ),
        _FreezeCard(
          child: Column(
            children: List.generate(
              3,
              (i) => Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : AppSpacing.md),
                child: Row(
                  children: const [
                    SkeletonBox(width: 34, height: 34, radius: 8),
                    SizedBox(width: AppSpacing.sm + 4),
                    Expanded(child: SkeletonBox(height: 14)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
