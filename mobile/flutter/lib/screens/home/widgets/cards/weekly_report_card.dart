import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/providers/consistency_provider.dart';
import '../../../../data/repositories/workout_repository.dart';
import '../../../../data/services/haptic_service.dart';

/// Home-screen entry point into Reports & Insights.
///
/// Shows a compact this-week progress ring + current streak + PR count and
/// navigates to `/summaries` (the Reports & Insights screen) on tap. Meant
/// to solve the discoverability complaint that users couldn't find the
/// reports screen — it's now a first-class card on Home.
class WeeklyReportCard extends ConsumerWidget {
  final bool isDark;

  const WeeklyReportCard({super.key, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsNotifier = ref.watch(workoutsProvider.notifier);
    final weeklyProgress = workoutsNotifier.weeklyProgress;
    final completed = weeklyProgress.$1;
    final scheduled = weeklyProgress.$2;

    final consistencyState = ref.watch(consistencyProvider);
    final streak = consistencyState.currentStreak;

    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final border = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final progress =
        scheduled > 0 ? (completed / scheduled).clamp(0.0, 1.0) : 0.0;
    final pct = (progress * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticService.selection();
            // Open the reports hub — users pick the specific report from
            // there. /summaries is still one card inside the hub.
            context.push('/reports');
          },
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  purple.withValues(alpha: isDark ? 0.18 : 0.10),
                  cyan.withValues(alpha: isDark ? 0.12 : 0.06),
                  elevated,
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Progress ring visualizing workouts-completed / scheduled
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: CustomPaint(
                      painter: _ProgressRingPainter(
                        progress: progress,
                        color: purple,
                        trackColor: purple.withValues(alpha: 0.15),
                      ),
                      child: Center(
                        child: Text(
                          '$pct%',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.insights_rounded,
                                color: cyan, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Reports & Insights',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          scheduled > 0
                              ? '$completed of $scheduled workouts this week'
                              : 'Open your weekly report',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (streak > 0) ...[
                              _Chip(
                                icon: Icons.local_fire_department_rounded,
                                label: '$streak day streak',
                                color: const Color(0xFFF97316),
                              ),
                              const SizedBox(width: 6),
                            ],
                            _Chip(
                              icon: Icons.arrow_forward_rounded,
                              label: 'View report',
                              color: cyan,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: textMuted, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 3;

    final track = Paint()
      ..color = trackColor
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    final fg = Paint()
      ..color = color
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) =>
      old.progress != progress || old.color != color;
}
