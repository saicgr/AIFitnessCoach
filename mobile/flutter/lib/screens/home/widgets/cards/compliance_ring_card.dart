import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../data/models/home_layout.dart';
import '../../../../data/services/haptic_service.dart';

/// Workout Compliance Ring Card for the home screen.
///
/// Displays a circular progress ring showing how many workouts
/// have been completed out of a target, color-coded by compliance:
///   - Green  >= 75%
///   - Yellow >= 50%
///   - Red    <  50%
///
/// Tapping navigates to the consistency screen.
class ComplianceRingCard extends ConsumerWidget {
  final int completed;
  final int target;
  final String weekLabel;
  final TileSize size;
  final bool isDark;

  const ComplianceRingCard({
    super.key,
    required this.completed,
    required this.target,
    this.weekLabel = 'This Week',
    this.size = TileSize.half,
    this.isDark = true,
  });

  double get _progress => target > 0 ? (completed / target).clamp(0.0, 1.0) : 0.0;

  Color _complianceColor(Color accent) {
    final pct = _progress;
    if (pct >= 0.75) return const Color(0xFF4CAF50); // green
    if (pct >= 0.50) return const Color(0xFFFFC107); // yellow/amber
    return const Color(0xFFEF5350); // red
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = ref.colors(context).accent;
    final ringColor = _complianceColor(accentColor);

    if (size == TileSize.compact) {
      return _buildCompactLayout(
        context,
        elevatedColor: elevatedColor,
        textColor: textColor,
        cardBorder: cardBorder,
        ringColor: ringColor,
      );
    }

    return InkWell(
      onTap: () {
        HapticService.light();
        context.push('/consistency');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: size == TileSize.full
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
            : null,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: target == 0
            ? _buildEmptyState(textMuted, accentColor)
            : _buildContentState(
                textColor: textColor,
                textMuted: textMuted,
                ringColor: ringColor,
                accentColor: accentColor,
              ),
      ),
    );
  }

  Widget _buildCompactLayout(
    BuildContext context, {
    required Color elevatedColor,
    required Color textColor,
    required Color cardBorder,
    required Color ringColor,
  }) {
    return InkWell(
      onTap: () {
        HapticService.light();
        context.push('/consistency');
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CustomPaint(
                painter: _ComplianceRingPainter(
                  progress: _progress,
                  ringColor: ringColor,
                  trackColor: ringColor.withOpacity(0.15),
                  strokeWidth: 2.5,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$completed/$target',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textMuted, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.track_changes, color: accentColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Workout Compliance',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'No workouts scheduled this week',
          style: TextStyle(
            fontSize: 14,
            color: textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildContentState({
    required Color textColor,
    required Color textMuted,
    required Color ringColor,
    required Color accentColor,
  }) {
    final pctText = '${(_progress * 100).round()}%';

    return Row(
      children: [
        // Circular ring
        SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(64, 64),
                painter: _ComplianceRingPainter(
                  progress: _progress,
                  ringColor: ringColor,
                  trackColor: ringColor.withOpacity(0.15),
                  strokeWidth: 5,
                ),
              ),
              Text(
                pctText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Text info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      weekLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textMuted,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: textMuted,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$completed of $target workouts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _complianceMessage(),
                style: TextStyle(
                  fontSize: 12,
                  color: ringColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _complianceMessage() {
    final remaining = target - completed;
    if (_progress >= 1.0) return 'All workouts completed!';
    if (_progress >= 0.75) return 'Great pace! $remaining left';
    if (_progress >= 0.50) return 'On track — $remaining to go';
    if (completed == 0) return 'Get started today!';
    return '$remaining workouts remaining';
  }
}

/// Custom painter that draws a compliance ring arc.
class _ComplianceRingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color trackColor;
  final double strokeWidth;

  _ComplianceRingPainter({
    required this.progress,
    required this.ringColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track (background ring)
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = ringColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final startAngle = -pi / 2; // 12 o'clock
      final sweepAngle = 2 * pi * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ComplianceRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
