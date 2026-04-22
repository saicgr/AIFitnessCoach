// Part of the Easy/Simple/Advanced workout-UI tier rework.
//
// Internal widgets for `focal_stepper.dart`. Split from the main file purely
// so that focal_stepper.dart stays ≤ 250 lines per the project convention.

import 'package:flutter/material.dart';

/// Big ± button used on either side of the focal stepper number.
class FocalStepperButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final double glyphSize;
  final bool enabled;
  final Color accent;
  final bool isDark;
  final VoidCallback? onTap;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;

  const FocalStepperButton({
    super.key,
    required this.icon,
    required this.size,
    required this.glyphSize,
    required this.enabled,
    required this.accent,
    required this.isDark,
    required this.onTap,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = isDark ? Colors.white : Colors.black;
    final bg = enabled
        ? accent.withValues(alpha: isDark ? 0.18 : 0.12)
        : onSurface.withValues(alpha: 0.04);
    final fg = enabled ? accent : onSurface.withValues(alpha: 0.28);
    final border =
        enabled ? accent.withValues(alpha: 0.45) : onSurface.withValues(alpha: 0.10);

    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTap: onTap,
        onLongPressStart: (_) => onLongPressStart?.call(),
        onLongPressEnd: (_) => onLongPressEnd?.call(),
        onLongPressCancel: () => onLongPressEnd?.call(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(size / 3.4),
            border: Border.all(color: border, width: 1),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: glyphSize, color: fg),
        ),
      ),
    );
  }
}

/// Tabular-nums digit display at the center of the focal stepper.
class FocalStepperDisplay extends StatelessWidget {
  final double value;
  final String unit;
  final double digitSize;
  final double unitSize;
  final bool integerOnly;

  const FocalStepperDisplay({
    super.key,
    required this.value,
    required this.unit,
    required this.digitSize,
    required this.unitSize,
    required this.integerOnly,
  });

  String get _display {
    if (integerOnly) return value.round().toString();
    // Weight: show 0.25 precision but trim trailing zeros so 30 renders as
    // "30" (not "30.00") and 30.5 as "30.5" (not "30.50").
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    final rounded = (value * 4).round() / 4.0;
    final s = rounded.toStringAsFixed(2);
    return s.endsWith('0') ? s.substring(0, s.length - 1) : s;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? Colors.white : Colors.black;

    return Semantics(
      button: true,
      label: 'Edit $unit value, currently $_display',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _display,
            style: TextStyle(
              fontSize: digitSize,
              fontWeight: FontWeight.w700,
              color: onSurface,
              height: 1.05,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: TextStyle(
              fontSize: unitSize,
              fontWeight: FontWeight.w500,
              color: onSurface.withValues(alpha: 0.55),
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
