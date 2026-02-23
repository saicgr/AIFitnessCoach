import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/providers/xp_provider.dart';
import '../../../data/services/haptic_service.dart';
import 'components/components.dart';
import 'gym_profile_switcher.dart';

/// Clean, minimal header for the "Minimalist" home screen preset.
///
/// Layout:
/// ```
/// [Gym Profile Switcher - collapsed tabs]
/// Hey, {name}         [XP badge (level)] [bell icon]
/// ```
class MinimalHeader extends ConsumerWidget {
  const MinimalHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final xpState = ref.watch(xpProvider);
    final accentColor = ref.watch(accentColorProvider);
    final accent = accentColor.getColor(isDark);
    final progress = xpState.progressFraction.clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Gym Profile Switcher - takes remaining space
          const Expanded(
            child: GymProfileSwitcher(collapsed: true),
          ),

          // Layout Edit Button
          IconButton(
            onPressed: () {
              HapticService.light();
              context.push('/settings/homescreen');
            },
            icon: Icon(
              Icons.dashboard_customize_outlined,
              size: 22,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            tooltip: 'Edit Layout',
          ),

          // XP Level Badge with progress ring
          GestureDetector(
            onTap: () {
              HapticService.light();
              context.push('/xp-goals');
            },
            child: SizedBox(
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
            ),
          ),

          const SizedBox(width: 4),

          // Notification Bell
          NotificationBellButton(isDark: isDark),
        ],
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

    // Track (background ring)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start from top
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
