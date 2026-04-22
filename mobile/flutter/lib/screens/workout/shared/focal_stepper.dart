// Part of the Easy/Simple/Advanced workout-UI tier rework.
//
// Big thumb-first ± stepper with tappable number → numeric keyboard. Drives
// both weight and reps on the focal card. Specs come from the no-scroll plan:
//   • 64×64 pt buttons (56 on SE small screens)
//   • 34 pt digit display (30 on SE)
//   • 28 pt ± glyph
//   • Tabular-nums, weight 700
//   • Long-press ± → accelerating fast-increment (mirrors existing
//     set_row_part_weight_increments.dart pattern)
//   • Haptic: light on ±, success on keyboard confirm
//
// Helper widgets + the numeric-edit modal live in sibling files
// (focal_stepper_internals.dart, focal_stepper_numeric_sheet.dart) to keep
// this file under the 250-line cap.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/theme/accent_color_provider.dart';
import 'focal_stepper_internals.dart';
import 'focal_stepper_numeric_sheet.dart';

class FocalStepper extends StatefulWidget {
  final double value;
  final double step;
  final String unit;
  final ValueChanged<double> onChanged;

  /// Optional label rendered above the stepper ("Weight" / "Reps").
  final String? label;

  /// When true the number is displayed/edited as an integer (used for reps).
  final bool integerOnly;

  /// Minimum allowed value (clamps both button and keyboard paths).
  final double min;

  /// Maximum allowed value.
  final double max;

  /// Small-screen mode (iPhone SE / foldable folded) — compacts sizing.
  final bool compact;

  const FocalStepper({
    super.key,
    required this.value,
    required this.step,
    required this.unit,
    required this.onChanged,
    this.label,
    this.integerOnly = false,
    this.min = 0,
    this.max = 9999,
    this.compact = false,
  });

  @override
  State<FocalStepper> createState() => _FocalStepperState();
}

class _FocalStepperState extends State<FocalStepper> {
  Timer? _rampTimer;
  int _rampTicks = 0;

  @override
  void dispose() {
    _rampTimer?.cancel();
    super.dispose();
  }

  double get _effectiveStep => widget.step > 0 ? widget.step : 1.0;

  double _applyStep(int direction) {
    final delta = _effectiveStep * direction;
    final next = (widget.value + delta).clamp(widget.min, widget.max);
    return next.toDouble();
  }

  void _tap(int direction) {
    HapticService.instance.tap();
    widget.onChanged(_applyStep(direction));
  }

  void _startRamp(int direction) {
    _rampTicks = 0;
    // Mirrors set_row_part_weight_increments.dart: 150 ms first tick, then
    // each follow-up tick speeds up 20 ms down to a 40 ms floor so long
    // presses feel responsive without saturating the frame pump.
    _scheduleRamp(direction, const Duration(milliseconds: 150));
  }

  void _scheduleRamp(int direction, Duration delay) {
    _rampTimer?.cancel();
    _rampTimer = Timer(delay, () {
      if (!mounted) return;
      _rampTicks++;
      widget.onChanged(_applyStep(direction));
      HapticService.instance.tick();
      final next = (150 - _rampTicks * 20).clamp(40, 150);
      _scheduleRamp(direction, Duration(milliseconds: next));
    });
  }

  void _stopRamp() {
    _rampTimer?.cancel();
    _rampTimer = null;
    _rampTicks = 0;
  }

  Future<void> _editNumerically() async {
    final result = await showFocalStepperNumericSheet(
      context: context,
      initial: widget.value,
      unit: widget.unit,
      integerOnly: widget.integerOnly,
      min: widget.min,
      max: widget.max,
      label: widget.label ?? 'Value',
    );
    if (result != null) {
      await HapticService.instance.success();
      widget.onChanged(result.clamp(widget.min, widget.max).toDouble());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final onSurface = isDark ? Colors.white : Colors.black;

    final btnSize = widget.compact ? 56.0 : 64.0;
    final digitSize = widget.compact ? 30.0 : 34.0;
    // Bumped glyphs so the − / + are easier to thumb-hit than they look
    // in the corners of the focal card.
    final glyphSize = widget.compact ? 30.0 : 36.0;
    final unitSize = widget.compact ? 16.0 : 18.0;
    final canDec = widget.value > widget.min;
    final canInc = widget.value < widget.max;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              widget.label!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: onSurface.withValues(alpha: 0.62),
                letterSpacing: 0.2,
              ),
            ),
          ),
        // Buttons sit directly next to the digit (tight layout) instead of
        // at the edges of the column — the old `Expanded(display)` spread
        // them to the gutters and made the value read like it was
        // disconnected from the controls.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FocalStepperButton(
              icon: Icons.remove_rounded,
              size: btnSize,
              glyphSize: glyphSize,
              enabled: canDec,
              accent: accent,
              isDark: isDark,
              onTap: canDec ? () => _tap(-1) : null,
              onLongPressStart: canDec ? () => _startRamp(-1) : null,
              onLongPressEnd: _stopRamp,
            ),
            const SizedBox(width: 18),
            GestureDetector(
              onTap: _editNumerically,
              behavior: HitTestBehavior.opaque,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 96),
                child: FocalStepperDisplay(
                  value: widget.value,
                  unit: widget.unit,
                  digitSize: digitSize,
                  unitSize: unitSize,
                  integerOnly: widget.integerOnly,
                ),
              ),
            ),
            const SizedBox(width: 18),
            FocalStepperButton(
              icon: Icons.add_rounded,
              size: btnSize,
              glyphSize: glyphSize,
              enabled: canInc,
              accent: accent,
              isDark: isDark,
              onTap: canInc ? () => _tap(1) : null,
              onLongPressStart: canInc ? () => _startRamp(1) : null,
              onLongPressEnd: _stopRamp,
            ),
          ],
        ),
      ],
    );
  }
}
