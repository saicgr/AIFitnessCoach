import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/fasting.dart';
import '../../../data/providers/fasting_provider.dart';

/// Circular timer widget showing fasting progress and current zone
class FastingTimerWidget extends ConsumerWidget {
  final FastingRecord? activeFast;
  final VoidCallback? onEndFast;
  final bool isDark;

  const FastingTimerWidget({
    super.key,
    this.activeFast,
    this.onEndFast,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

    // Watch the timer for live updates
    final timerValue = ref.watch(fastingTimerProvider);
    final elapsedSeconds = timerValue.value ?? 0;
    final elapsedMinutes = elapsedSeconds ~/ 60;

    // Calculate current zone based on live elapsed time
    final currentZone = activeFast != null
        ? FastingZone.fromElapsedMinutes(elapsedMinutes)
        : FastingZone.fed;

    // Calculate progress
    final progress = activeFast != null
        ? (elapsedMinutes / activeFast!.goalDurationMinutes).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: currentZone.color.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Circular progress with timer
          SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 12,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                ),
                // Zone-colored progress
                SizedBox(
                  width: 220,
                  height: 220,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, value, child) {
                      return CustomPaint(
                        painter: _ZoneProgressPainter(
                          progress: value,
                          currentZone: currentZone,
                          strokeWidth: 12,
                        ),
                      );
                    },
                  ),
                ),
                // Center content
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Time elapsed
                    Text(
                      _formatTime(elapsedSeconds),
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Label
                    Text(
                      activeFast != null ? 'elapsed' : 'not fasting',
                      style: TextStyle(
                        fontSize: 14,
                        color: textMuted,
                      ),
                    ),
                    if (activeFast != null) ...[
                      const SizedBox(height: 12),
                      // Remaining time
                      Text(
                        _formatRemainingTime(
                            activeFast!.goalDurationMinutes - elapsedMinutes),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: purple,
                        ),
                      ),
                      Text(
                        'remaining',
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Current zone indicator
          if (activeFast != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: currentZone.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: currentZone.color.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: currentZone.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    currentZone.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: currentZone.color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currentZone.description,
              style: TextStyle(
                fontSize: 13,
                color: textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // End fast button
            TextButton.icon(
              onPressed: onEndFast,
              icon: Icon(
                Icons.stop_rounded,
                color: AppColors.coral,
                size: 20,
              ),
              label: Text(
                'End Fast',
                style: TextStyle(
                  color: AppColors.coral,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                backgroundColor: AppColors.coral.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatRemainingTime(int remainingMinutes) {
    if (remainingMinutes <= 0) return 'Goal reached!';
    final hours = remainingMinutes ~/ 60;
    final minutes = remainingMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

/// Custom painter for zone-colored circular progress
class _ZoneProgressPainter extends CustomPainter {
  final double progress;
  final FastingZone currentZone;
  final double strokeWidth;

  _ZoneProgressPainter({
    required this.progress,
    required this.currentZone,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = currentZone.color;

    // Draw arc from top (-90 degrees)
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ZoneProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.currentZone != currentZone;
  }
}
