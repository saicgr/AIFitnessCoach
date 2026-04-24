import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A circular progress ring showing "consumed / target" for a single
/// macro, with the remaining count as the center label. Used by the
/// MenuAnalysisHeader to replace the flat number chips with a richer,
/// glanceable "how much is left" indicator that updates live as the
/// user checks/unchecks items in the menu.
///
/// Over-budget visuals: when `consumed > target`, the ring fills
/// completely in the over-budget color and the label flips to
/// "+X over" — the plan calls this out as the desired behavior so a
/// user can see at a glance which macro they've blown through.
class MacroBudgetRing extends StatelessWidget {
  final String label;
  final double consumed;
  final double target;
  final String unit;
  final Color color;
  final double size;
  final double strokeWidth;

  const MacroBudgetRing({
    super.key,
    required this.label,
    required this.consumed,
    required this.target,
    required this.color,
    this.unit = '',
    this.size = 64,
    this.strokeWidth = 5,
  });

  @override
  Widget build(BuildContext context) {
    final isOver = consumed > target && target > 0;
    final remaining = target - consumed;
    final progress = target <= 0 ? 0.0 : (consumed / target).clamp(0.0, 1.0);

    final ringColor = isOver ? Colors.redAccent : color;
    final centerText = isOver
        ? '+${remaining.abs().round()}'
        : remaining.round().toString();
    final centerSuffix = isOver ? 'over' : 'left';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(
                  progress: progress,
                  ringColor: ringColor,
                  trackColor: ringColor.withValues(alpha: 0.15),
                  strokeWidth: strokeWidth,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    centerText,
                    style: TextStyle(
                      fontSize: size * 0.28,
                      fontWeight: FontWeight.w800,
                      color: ringColor,
                      height: 1,
                    ),
                  ),
                  if (unit.isNotEmpty)
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: 8,
                        color: ringColor.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  Text(
                    centerSuffix,
                    style: TextStyle(
                      fontSize: 9,
                      color: ringColor.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: 0.7),
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color trackColor;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.ringColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    // Start at 12 o'clock and go clockwise.
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      ringPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.ringColor != ringColor ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}
