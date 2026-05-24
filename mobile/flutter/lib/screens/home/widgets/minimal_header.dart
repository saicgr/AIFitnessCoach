import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/serious_mode_provider.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/providers/xp_provider.dart';
import '../../../data/services/haptic_service.dart';
import 'components/components.dart';
import 'manage_gym_profiles_sheet.dart';
import '../../../core/providers/user_provider.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/app_tour/app_tour_controller.dart';
import 'streak_explainer_sheet.dart';
import 'week_calendar_strip.dart';

/// Clean, minimal header for the "Minimalist" home screen preset.
///
/// Layout:
/// ```
/// [Gym Profile Switcher - collapsed tabs]  [Lvl+Streak pill] [bell] [⋮]
/// ```
///
/// Edit-home and Settings moved into the overflow (⋮) menu — they are
/// weekly-frequency actions, not daily. The level ring + streak pill and
/// notifications bell remain visible because they are glanceable status
/// and time-sensitive respectively.
class MinimalHeader extends ConsumerWidget {
  const MinimalHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      key: AppTourKeys.topBarKey,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Expanded(child: _Greeting()),
          const _LevelStreakPill(),
          const SizedBox(width: 4),
          NotificationBellButton(isDark: isDark),
          _OverflowMenuButton(isDark: isDark),
        ],
      ),
    );
  }
}

/// Time-of-day greeting + the user's first name. Replaces the gym-profile
/// switcher in the header — switching gyms moved into the ⋮ menu.
class _Greeting extends ConsumerWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning,'
        : hour < 17
            ? 'Good afternoon,'
            : 'Good evening,';
    final name = ref.watch(currentUserProvider).valueOrNull?.name;
    final firstName = (name != null && name.trim().isNotEmpty)
        ? name.trim().split(' ').first
        : 'there';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          greeting,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          firstName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: isDark ? Colors.white : const Color(0xFF0A0A0A),
          ),
        ),
      ],
    );
  }
}

/// 3-dot overflow menu holding secondary header actions (Edit home, Settings).
class _OverflowMenuButton extends ConsumerWidget {
  final bool isDark;
  const _OverflowMenuButton({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconColor = isDark ? Colors.white70 : Colors.black54;
    final weekCollapsed = ref.watch(weekCalendarCollapsedProvider);
    final weekHidden = ref.watch(weekCalendarHiddenProvider);
    return PopupMenuButton<String>(
      tooltip: 'More',
      icon: Icon(Icons.more_vert, size: 22, color: iconColor),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      onOpened: HapticService.light,
      onSelected: (value) {
        HapticService.light();
        switch (value) {
          case 'change_gym':
            showGlassSheet(
              context: context,
              builder: (_) => const ManageGymProfilesSheet(),
            );
            break;
          case 'toggle_week':
            ref.read(weekCalendarCollapsedProvider.notifier).toggle();
            break;
          case 'toggle_week_hidden':
            ref.read(weekCalendarHiddenProvider.notifier).toggle();
            break;
          case 'my_space':
            context.push('/settings/homescreen');
            break;
          case 'settings':
            context.push('/settings');
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'change_gym',
          child: Row(
            children: [
              Icon(Icons.storefront_outlined, size: 20, color: iconColor),
              const SizedBox(width: 12),
              const Text('Change gym profile'),
            ],
          ),
        ),
        // Collapse: show single-line summary pill instead of the 7-day strip.
        // Only meaningful when the strip is visible at all.
        if (!weekHidden)
          PopupMenuItem<String>(
            value: 'toggle_week',
            child: Row(
              children: [
                Icon(
                  weekCollapsed ? Icons.expand_more : Icons.expand_less,
                  size: 20,
                  color: iconColor,
                ),
                const SizedBox(width: 12),
                Text(weekCollapsed
                    ? 'Expand week strip'
                    : 'Collapse week strip'),
              ],
            ),
          ),
        // Hide: remove the strip entirely (no collapsed pill either).
        PopupMenuItem<String>(
          value: 'toggle_week_hidden',
          child: Row(
            children: [
              Icon(
                weekHidden
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: iconColor,
              ),
              const SizedBox(width: 12),
              Text(weekHidden ? 'Show day strip' : 'Hide day strip'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'my_space',
          child: Row(
            children: [
              Icon(Icons.dashboard_customize_outlined,
                  size: 20, color: iconColor),
              const SizedBox(width: 12),
              const Text('My Space'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 20, color: iconColor),
              const SizedBox(width: 12),
              const Text('Settings'),
            ],
          ),
        ),
      ],
    );
  }
}

/// Paired level ring + active-streak pill.
///
/// Taps jump to the You → Overview tab (single source of truth for both
/// level trajectory and streaks). Streak number is fetched lazily on
/// mount; if the fetch fails or returns 0, only the level ring renders.
class _LevelStreakPill extends ConsumerStatefulWidget {
  const _LevelStreakPill();

  @override
  ConsumerState<_LevelStreakPill> createState() => _LevelStreakPillState();
}

// Imported above; declared down here so the diff stays local. The streak
// explainer sheet lives in widgets/streak_explainer_sheet.dart.

class _LevelStreakPillState extends ConsumerState<_LevelStreakPill> {
  // Source of truth for streak = the XP login streak (same as the XP Goals
  // screen's "Login Streak" banner), read directly from xpProvider. Prior
  // revision fetched the workout streak from /achievements/streaks which
  // disagreed with the XP Goals number (home said 9, XP Goals said 12).

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final xpState = ref.watch(xpProvider);
    final accent = ref.watch(accentColorProvider).getColor(isDark);
    final progress = xpState.progressFraction.clamp(0.0, 1.0);
    final serious = ref.watch(seriousModeProvider);

    // Streak segment = XP login streak. Matches the XP Goals screen's
    // banner exactly. Hidden in Serious Mode (less game-y chrome).
    final streakDays = ref.watch(xpCurrentStreakProvider);
    final showStreak = !serious && streakDays > 0;

    final levelRing = SizedBox(
      width: 36,
      height: 36,
      child: CustomPaint(
        painter: _LevelRingPainter(
          progress: progress,
          accentColor: accent,
          trackColor: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08),
        ),
        child: Center(
          child: Text(
            '${xpState.currentLevel}',
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              height: 1,
            ),
          ),
        ),
      ),
    );

    // Two distinct chips with explicit tap-targets — the previous unified
    // pill rendered `3 · 5🔥` which users couldn't decode (was 3 the level?
    // the streak? the score?). Now: level ring tappable to /xp-goals;
    // streak chip labeled "5d 🔥" tappable to a new explainer sheet that
    // shows the streak rule + remaining freezes.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Level chip — the existing CustomPaint ring tappable on its own.
        GestureDetector(
          onTap: () {
            HapticService.light();
            context.push('/xp-goals');
          },
          behavior: HitTestBehavior.opaque,
          child: levelRing,
        ),
        if (showStreak) ...[
          const SizedBox(width: 6),
          // Streak chip — labeled "Nd 🔥" so the number reads as days.
          GestureDetector(
            onTap: () {
              HapticService.light();
              showStreakExplainerSheet(context);
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: const Color(0xFFEC8B2C).withValues(alpha: 0.32),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${streakDays}d',
                    style: TextStyle(
                      color:
                          isDark ? Colors.white : const Color(0xFF0A0A0A),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('🔥', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Paints a circular progress ring around the level number.
class _LevelRingPainter extends CustomPainter {
  final double progress;
  final Color accentColor;
  final Color trackColor;

  _LevelRingPainter({
    required this.progress,
    required this.accentColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 2;
    const strokeWidth = 3.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_LevelRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accentColor != accentColor ||
      oldDelegate.trackColor != trackColor;
}
