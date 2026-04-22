import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/serious_mode_provider.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/providers/xp_provider.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/haptic_service.dart';
import 'components/components.dart';
import 'gym_profile_switcher.dart';
import '../../../widgets/app_tour/app_tour_controller.dart';

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
          const Expanded(
            child: GymProfileSwitcher(collapsed: true),
          ),
          const _LevelStreakPill(),
          const SizedBox(width: 4),
          NotificationBellButton(isDark: isDark),
          _OverflowMenuButton(isDark: isDark),
        ],
      ),
    );
  }
}

/// 3-dot overflow menu holding secondary header actions (Edit home, Settings).
class _OverflowMenuButton extends StatelessWidget {
  final bool isDark;
  const _OverflowMenuButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final iconColor = isDark ? Colors.white70 : Colors.black54;
    return PopupMenuButton<String>(
      tooltip: 'More',
      icon: Icon(Icons.more_vert, size: 22, color: iconColor),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      onOpened: HapticService.light,
      onSelected: (value) {
        HapticService.light();
        switch (value) {
          case 'edit_home':
            context.push('/settings/homescreen');
            break;
          case 'settings':
            context.push('/settings');
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'edit_home',
          child: Row(
            children: [
              Icon(Icons.dashboard_customize_outlined,
                  size: 20, color: iconColor),
              const SizedBox(width: 12),
              const Text('Edit home screen'),
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

class _LevelStreakPillState extends ConsumerState<_LevelStreakPill> {
  int? _streakDays;
  bool _streakLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStreak());
  }

  Future<void> _loadStreak() async {
    try {
      final api = ref.read(apiClientProvider);
      final userId = await api.getUserId();
      if (userId == null) {
        if (mounted) setState(() => _streakLoaded = true);
        return;
      }
      final res = await api.dio.get(
        '/achievements/user/$userId/streaks',
        options: Options(
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 6),
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      List? list;
      final data = res.data;
      if (data is List) list = data;
      if (data is Map && data['streaks'] is List) list = data['streaks'] as List;

      int? pick;
      if (list != null && list.isNotEmpty) {
        Map<String, dynamic>? workout;
        Map<String, dynamic>? fallback;
        for (final raw in list) {
          if (raw is! Map) continue;
          final m = raw.cast<String, dynamic>();
          final count = (m['current_streak'] as num?)?.toInt() ?? 0;
          if (count <= 0) continue;
          final type = m['streak_type'] as String? ?? '';
          if (type == 'workout' || type == 'workouts') {
            workout = m;
          } else {
            fallback ??= m;
          }
        }
        final best = workout ?? fallback;
        if (best != null) {
          pick = (best['current_streak'] as num?)?.toInt();
        }
      }

      if (mounted) {
        setState(() {
          _streakDays = pick;
          _streakLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _streakLoaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final xpState = ref.watch(xpProvider);
    final accent = ref.watch(accentColorProvider).getColor(isDark);
    final progress = xpState.progressFraction.clamp(0.0, 1.0);
    final serious = ref.watch(seriousModeProvider);

    // Streak segment hidden in Serious Mode (less game-y chrome).
    final showStreak =
        !serious && _streakLoaded && (_streakDays ?? 0) > 0;

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

    return GestureDetector(
      onTap: () {
        HapticService.light();
        // Route to the consolidated You hub (Overview tab) — level + streak
        // share the same destination now that they're paired in the UI.
        context.go('/profile?tab=overview');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: showStreak
            ? const EdgeInsets.only(right: 10)
            : EdgeInsets.zero,
        decoration: showStreak
            ? BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: accent.withValues(alpha: 0.25),
                  width: 1,
                ),
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            levelRing,
            if (showStreak) ...[
              const SizedBox(width: 6),
              Text(
                '•',
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.35)
                      : Colors.black.withValues(alpha: 0.3),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              const Text('🔥', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 2),
              Text(
                '$_streakDays',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0A0A0A),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  height: 1,
                ),
              ),
            ],
          ],
        ),
      ),
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
