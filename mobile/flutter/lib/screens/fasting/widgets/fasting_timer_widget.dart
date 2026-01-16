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
  final VoidCallback? onStartFast;
  final bool isDark;

  const FastingTimerWidget({
    super.key,
    this.activeFast,
    this.onEndFast,
    this.onStartFast,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    // Use monochrome accent instead of purple
    final accentColor = isDark ? AppColors.accent : AppColorsLight.accent;
    final accentContrast = isDark ? AppColors.accentContrast : AppColorsLight.accentContrast;

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
      padding: const EdgeInsets.all(16),
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
          // Circular progress with timer - responsive size
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final timerSize = screenWidth < 380 ? 150.0 : 180.0;
              return SizedBox(
                width: timerSize,
                height: timerSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background circle
                    SizedBox(
                      width: timerSize,
                      height: timerSize,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: screenWidth < 380 ? 8 : 10,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    // Multi-zone colored progress
                    SizedBox(
                      width: timerSize,
                      height: timerSize,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, value, child) {
                          return CustomPaint(
                            painter: _ZoneProgressPainter(
                              progress: value,
                              currentZone: currentZone,
                              strokeWidth: screenWidth < 380 ? 8 : 10,
                              goalDurationMinutes: activeFast?.goalDurationMinutes ?? 960, // Default 16h
                              isDark: isDark,
                            ),
                          );
                        },
                      ),
                    ),
                    // Center content
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (activeFast != null) ...[
                          // Time elapsed
                          Text(
                            _formatTime(elapsedSeconds),
                            style: TextStyle(
                              fontSize: screenWidth < 380 ? 24 : 30,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Label
                          Text(
                            'elapsed',
                            style: TextStyle(
                              fontSize: 12,
                              color: textMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Remaining time (in seconds for live countdown)
                          Text(
                            _formatRemainingTime(
                                (activeFast!.goalDurationMinutes * 60) - elapsedSeconds),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: accentColor,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          Text(
                            'remaining',
                            style: TextStyle(
                              fontSize: 11,
                              color: textMuted,
                            ),
                          ),
                        ] else ...[
                          // Play button only - text moved to main button below
                          GestureDetector(
                            onTap: onStartFast,
                            child: Container(
                              width: screenWidth < 380 ? 64 : 72,
                              height: screenWidth < 380 ? 64 : 72,
                              decoration: BoxDecoration(
                                color: accentColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: accentContrast,
                                size: screenWidth < 380 ? 36 : 40,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

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

            // End fast button - using monochrome accent
            TextButton.icon(
              onPressed: onEndFast,
              icon: Icon(
                Icons.stop_rounded,
                color: accentColor,
                size: 20,
              ),
              label: Text(
                'End Fast',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                backgroundColor: accentColor.withValues(alpha: 0.1),
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

  String _formatRemainingTime(int remainingSeconds) {
    if (remainingSeconds <= 0) return 'Goal reached!';
    final hours = remainingSeconds ~/ 3600;
    final minutes = (remainingSeconds % 3600) ~/ 60;
    final seconds = remainingSeconds % 60;
    // Show HH:MM:SS format for consistency with elapsed time
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Custom painter for multi-zone colored circular progress
/// Shows all zones as colored segments around the ring
class _ZoneProgressPainter extends CustomPainter {
  final double progress;
  final FastingZone currentZone;
  final double strokeWidth;
  final int goalDurationMinutes;
  final bool isDark;

  _ZoneProgressPainter({
    required this.progress,
    required this.currentZone,
    required this.strokeWidth,
    required this.goalDurationMinutes,
    required this.isDark,
  });

  // Zone boundaries in hours
  static const List<_ZoneSegment> _zoneSegments = [
    _ZoneSegment(FastingZone.fed, 0, 4),
    _ZoneSegment(FastingZone.postAbsorptive, 4, 8),
    _ZoneSegment(FastingZone.earlyFasting, 8, 12),
    _ZoneSegment(FastingZone.fatBurning, 12, 16),
    _ZoneSegment(FastingZone.ketosis, 16, 24),
    _ZoneSegment(FastingZone.deepKetosis, 24, 48),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final goalHours = goalDurationMinutes / 60;

    // Draw zone segments as background (faded)
    for (final segment in _zoneSegments) {
      if (segment.startHour >= goalHours) continue;

      final startAngle = _hoursToAngle(segment.startHour.toDouble(), goalHours);
      final endHour = math.min(segment.endHour.toDouble(), goalHours);
      final sweepAngle = _hoursToAngle(endHour, goalHours) - startAngle;

      if (sweepAngle <= 0) continue;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt
        ..color = segment.zone.color.withValues(alpha: 0.2);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }

    // Draw filled progress through zones
    if (progress > 0) {
      final progressHours = progress * goalHours;

      for (final segment in _zoneSegments) {
        if (segment.startHour >= progressHours) break;
        if (segment.startHour >= goalHours) break;

        final segmentStart = segment.startHour.toDouble();
        final segmentEnd = math.min(
          segment.endHour.toDouble(),
          math.min(progressHours, goalHours),
        );

        if (segmentEnd <= segmentStart) continue;

        final startAngle = _hoursToAngle(segmentStart, goalHours);
        final sweepAngle = _hoursToAngle(segmentEnd, goalHours) - startAngle;

        final isCurrentZone = segment.zone == currentZone;

        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt
          ..color = segment.zone.color;

        // Add glow effect for current zone
        if (isCurrentZone) {
          final glowPaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth + 4
            ..strokeCap = StrokeCap.butt
            ..color = segment.zone.color.withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

          canvas.drawArc(
            Rect.fromCircle(center: center, radius: radius),
            startAngle,
            sweepAngle,
            false,
            glowPaint,
          );
        }

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          false,
          paint,
        );
      }

      // Draw progress indicator dot at current position
      final progressAngle = -math.pi / 2 + (2 * math.pi * progress);
      final dotX = center.dx + radius * math.cos(progressAngle);
      final dotY = center.dy + radius * math.sin(progressAngle);

      // Outer glow
      canvas.drawCircle(
        Offset(dotX, dotY),
        strokeWidth * 0.8,
        Paint()
          ..color = currentZone.color.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Inner dot
      canvas.drawCircle(
        Offset(dotX, dotY),
        strokeWidth * 0.5,
        Paint()..color = currentZone.color,
      );

      // White center
      canvas.drawCircle(
        Offset(dotX, dotY),
        strokeWidth * 0.25,
        Paint()..color = Colors.white,
      );
    }
  }

  double _hoursToAngle(double hours, double goalHours) {
    // Map hours to angle, starting from top (-π/2)
    return -math.pi / 2 + (hours / goalHours) * 2 * math.pi;
  }

  @override
  bool shouldRepaint(covariant _ZoneProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.currentZone != currentZone ||
        oldDelegate.goalDurationMinutes != goalDurationMinutes;
  }
}

/// Helper class for zone segments
class _ZoneSegment {
  final FastingZone zone;
  final int startHour;
  final int endHour;

  const _ZoneSegment(this.zone, this.startHour, this.endHour);
}
