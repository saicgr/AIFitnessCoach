// Part of the Easy/Simple/Advanced workout-UI tier rework.
//
// Inline tap-to-edit pill used inside set rows (overflow sheet, completed-set
// card, etc.). 40 pt collapsed; taps expand to a ~64 pt mini editor with
// compact ± weight · number · ± reps · ✓ save. AnimatedSize + AnimatedSwitcher
// handle the 200 ms morph. Honors feedback_inline_editing.md — no modal sheet,
// the value editor lives in-place.
//
// The expanded editor body is in `inline_edit_pill_editor.dart` to keep this
// file under the 250-line project cap.

import 'package:flutter/material.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/theme/accent_color_provider.dart';
import 'inline_edit_pill_editor.dart';

class InlineEditPill extends StatefulWidget {
  final double weight;
  final int reps;
  final String unit;

  /// Step for weight ± (from weightIncrementsProvider on the caller side).
  final double weightStep;

  /// Called on every ± tap so the caller can live-reflect the dirty state
  /// (e.g. rail pill text updates instantly).
  final ValueChanged<(double weight, int reps)> onChanged;

  /// Called when user taps ✓ to commit. The pill collapses itself on save.
  final VoidCallback onSave;

  /// Optional label rendered inside the collapsed pill ("Set 1 ✓" etc.).
  final String? collapsedLabel;

  const InlineEditPill({
    super.key,
    required this.weight,
    required this.reps,
    required this.unit,
    required this.onChanged,
    required this.onSave,
    this.weightStep = 2.5,
    this.collapsedLabel,
  });

  @override
  State<InlineEditPill> createState() => _InlineEditPillState();
}

class _InlineEditPillState extends State<InlineEditPill> {
  bool _expanded = false;

  void _toggle() {
    HapticService.instance.tap();
    setState(() => _expanded = !_expanded);
  }

  void _bumpWeight(int direction) {
    HapticService.instance.tick();
    final step = widget.weightStep > 0 ? widget.weightStep : 1.0;
    final next =
        (widget.weight + step * direction).clamp(0.0, 9999.0).toDouble();
    widget.onChanged((next, widget.reps));
  }

  void _bumpReps(int direction) {
    HapticService.instance.tick();
    final next = (widget.reps + direction).clamp(0, 999);
    widget.onChanged((widget.weight, next));
  }

  void _save() {
    HapticService.instance.success();
    setState(() => _expanded = false);
    widget.onSave();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _expanded
            ? InlineEditPillExpanded(
                key: const ValueKey('expanded'),
                weight: widget.weight,
                reps: widget.reps,
                unit: widget.unit,
                accent: accent,
                isDark: isDark,
                onBumpWeight: _bumpWeight,
                onBumpReps: _bumpReps,
                onSave: _save,
              )
            : _CollapsedPill(
                key: const ValueKey('collapsed'),
                weight: widget.weight,
                reps: widget.reps,
                unit: widget.unit,
                accent: accent,
                isDark: isDark,
                label: widget.collapsedLabel,
                onTap: _toggle,
              ),
      ),
    );
  }
}

class _CollapsedPill extends StatelessWidget {
  final double weight;
  final int reps;
  final String unit;
  final Color accent;
  final bool isDark;
  final String? label;
  final VoidCallback onTap;

  const _CollapsedPill({
    super.key,
    required this.weight,
    required this.reps,
    required this.unit,
    required this.accent,
    required this.isDark,
    required this.label,
    required this.onTap,
  });

  String get _weightText {
    if (weight == weight.roundToDouble()) return weight.toStringAsFixed(0);
    return weight.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = isDark ? Colors.white : Colors.black;

    return Semantics(
      button: true,
      label: label ?? 'Edit set, $_weightText $unit by $reps reps',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: isDark ? 0.14 : 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (label != null) ...[
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                '$_weightText $unit × $reps',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.edit_rounded,
                size: 14,
                color: onSurface.withValues(alpha: 0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
