import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Compact `● value unit` chip used on synced-workout cards and list tiles.
///
/// The colored dot carries the metric's semantic color (e.g. cyan for
/// distance, orange for calories). Value and unit are rendered in the
/// contextual text color (primary in dark, primary in light).
class MetricChip extends StatelessWidget {
  final Color dotColor;
  final String value;
  final String? unit;
  final double fontSize;

  const MetricChip({
    super.key,
    required this.dotColor,
    required this.value,
    this.unit,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? Colors.white.withValues(alpha: 0.92) : AppColorsLight.textPrimary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              if (unit != null && unit!.isNotEmpty)
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    fontSize: fontSize - 1,
                    fontWeight: FontWeight.w500,
                    color: textColor.withValues(alpha: 0.65),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Semantic colors used by metric chips — keeps chip callers from hunting for
/// the right shade for each metric type.
class MetricColors {
  MetricColors._();
  static const Color distance = Color(0xFF06B6D4);   // cyan
  static const Color calories = Color(0xFFF97316);   // orange
  static const Color steps = Color(0xFF22C55E);      // green
  static const Color heartRate = Color(0xFFEF4444);  // red
  static const Color cadence = Color(0xFFA855F7);    // purple
  static const Color elevation = Color(0xFF84CC16);  // lime
  static const Color pace = Color(0xFF14B8A6);       // teal
  static const Color duration = Color(0xFF8B5CF6);   // violet
  static const Color spo2 = Color(0xFF3B82F6);       // blue
  static const Color temperature = Color(0xFFF59E0B);// amber
  static const Color respRate = Color(0xFF10B981);   // emerald
  static const Color hrv = Color(0xFFEC4899);        // pink
}
