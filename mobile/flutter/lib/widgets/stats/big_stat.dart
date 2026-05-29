import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'stat_delta_chip.dart';

/// A glanceable "big number" stat block — the building block for the scalar
/// strips on the Workout and Nutrition tabs.
///
/// The value is deliberately large (default 34pt, weight 800) per the design
/// brief that numbers must be easy to read at arm's length, and is wrapped in
/// a [FittedBox] so a long value (e.g. "12,480") scales down instead of
/// overflowing on a small device.
class BigStat extends StatelessWidget {
  /// Pre-formatted primary value, e.g. "142", "3h 40m", "18,420".
  final String value;

  /// Short caption under the value, e.g. "workouts", "day streak".
  final String label;

  /// Optional unit rendered small, trailing the value (e.g. "lbs", "g").
  final String? unit;

  final IconData? icon;

  /// Tint for the icon + accents. Defaults to the muted text colour.
  final Color? accent;

  /// Optional delta chip shown beneath the value.
  final StatDeltaChip? delta;

  /// Optional trend visual (e.g. a [MiniSparkline]) shown at the bottom.
  final Widget? trend;

  final bool isDark;
  final double valueFontSize;

  const BigStat({
    super.key,
    required this.value,
    required this.label,
    required this.isDark,
    this.unit,
    this.icon,
    this.accent,
    this.delta,
    this.trend,
    this.valueFontSize = 34,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final tint = accent ?? textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: tint),
          const SizedBox(height: 6),
        ],
        // Big number + small unit, scaled to fit.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  height: 1.0,
                  letterSpacing: -0.5,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    unit!,
                    style: TextStyle(
                      fontSize: valueFontSize * 0.4,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textMuted,
          ),
        ),
        if (delta != null) ...[
          const SizedBox(height: 6),
          delta!,
        ],
        if (trend != null) ...[
          const SizedBox(height: 8),
          trend!,
        ],
      ],
    );
  }
}
