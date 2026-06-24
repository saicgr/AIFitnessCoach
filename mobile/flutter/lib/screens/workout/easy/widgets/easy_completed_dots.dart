// Easy tier — the set ledger (`set-ledger` from the approved easy-redesign).
//
// A row of rounded PILLS, one per set, showing the value inline:
//   • done    → "N  w×r ✓"  success-tinted border + faint success wash
//   • current → "N  w×r"     accent border (the live target you're about to log)
//   • upcoming→ "N"          faint, muted
//
// This replaces the old numbered square cells — the mockup shows previous sets
// INLINE ("1 55×12 ✓  2 60×12 ✓  3 60×12") so the user reads their ledger at a
// glance without opening History. Every pill stays tappable: a done pill jumps
// the focal card into edit mode for that set, the current pill returns to live,
// an upcoming pill skips ahead.
//
// Horizontally scrollable so any set count fits without truncation or overflow.

import 'package:flutter/material.dart';

import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../models/workout_state.dart';

class EasyCompletedDots extends StatelessWidget {
  final List<SetLog> completedSetsForCurrentExercise;
  final int currentSetIndex; // 0-indexed; equals completed.length when about to log
  final int totalSets;
  final bool useKg;

  /// Live target weight (in DISPLAY units) + reps for the current set, shown
  /// inside the current pill so it reads "3 60×12" like the mockup.
  final double currentWeightDisplay;
  final int currentReps;

  /// 0-indexed set currently being edited, or null if editing the
  /// current (upcoming) set.
  final int? editingSetIndex;

  /// Fired when the user taps a completed set pill. Passes the 0-based index.
  final ValueChanged<int>? onEditSet;

  /// Fired when the user taps the current pill while in edit mode.
  final VoidCallback? onReturnToCurrent;

  /// Fired when the user taps an upcoming pill (skip ahead).
  final ValueChanged<int>? onSkipToSet;

  /// Per the locked spec, tapping ANY ledger pill opens the History sheet.
  /// When provided, this takes precedence over onEditSet/onSkipToSet.
  final VoidCallback? onOpenHistory;

  const EasyCompletedDots({
    super.key,
    required this.completedSetsForCurrentExercise,
    required this.currentSetIndex,
    required this.totalSets,
    required this.useKg,
    this.currentWeightDisplay = 0,
    this.currentReps = 0,
    this.editingSetIndex,
    this.onEditSet,
    this.onReturnToCurrent,
    this.onSkipToSet,
    this.onOpenHistory,
  });

  String _wTok(double displayWeight) {
    if (displayWeight <= 0) return 'BW';
    return displayWeight % 1 == 0
        ? displayWeight.toStringAsFixed(0)
        : displayWeight.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    final List<Widget> pills = [];
    for (int i = 0; i < totalSets; i++) {
      final isEditingThis = editingSetIndex == i;

      // Spec: tapping any pill opens History. Keep the legacy edit/skip
      // handlers as the fallback when no History opener is wired.
      VoidCallback? tapFor(VoidCallback? legacy) {
        if (onOpenHistory != null) {
          return () {
            HapticService.instance.tap();
            onOpenHistory!();
          };
        }
        return legacy;
      }

      if (i < completedSetsForCurrentExercise.length) {
        // ── DONE pill: "N  w×r ✓" ──────────────────────────────────────────
        final s = completedSetsForCurrentExercise[i];
        final display = useKg ? s.weight : s.weight * 2.20462;
        pills.add(_LedgerPill(
          state: isEditingThis ? _PillState.current : _PillState.done,
          number: i + 1,
          valueLabel: '${_wTok(display)}×${s.reps}',
          colors: colors,
          onTap: tapFor(onEditSet == null
              ? null
              : () {
                  HapticService.instance.tap();
                  onEditSet!(i);
                }),
        ));
      } else if (i == currentSetIndex) {
        // ── CURRENT pill: "N  w×r" (the live target) ───────────────────────
        final returnable =
            editingSetIndex != null && onReturnToCurrent != null;
        pills.add(_LedgerPill(
          state: _PillState.current,
          number: i + 1,
          valueLabel: '${_wTok(currentWeightDisplay)}×$currentReps',
          colors: colors,
          onTap: tapFor(returnable
              ? () {
                  HapticService.instance.tap();
                  onReturnToCurrent!();
                }
              : null),
        ));
      } else {
        // ── UPCOMING pill: bare "N" ────────────────────────────────────────
        pills.add(_LedgerPill(
          state: _PillState.upcoming,
          number: i + 1,
          valueLabel: null,
          colors: colors,
          onTap: tapFor(onSkipToSet == null
              ? null
              : () {
                  HapticService.instance.tap();
                  onSkipToSet!(i);
                }),
        ));
      }
    }

    return SizedBox(
      height: 40,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const ClampingScrollPhysics(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (int i = 0; i < pills.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              pills[i],
            ],
          ],
        ),
      ),
    );
  }
}

enum _PillState { done, current, upcoming }

/// A single rounded ledger pill — number + inline value (+ ✓ when done).
class _LedgerPill extends StatelessWidget {
  final _PillState state;
  final int number;
  final String? valueLabel; // null → bare number (upcoming)
  final ThemeColors colors;
  final VoidCallback? onTap;

  const _LedgerPill({
    required this.state,
    required this.number,
    required this.valueLabel,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final success = colors.success;

    Color borderColor;
    Color fill;
    Color numColor;
    Color valColor;

    switch (state) {
      case _PillState.done:
        borderColor = success.withValues(alpha: 0.45);
        fill = success.withValues(alpha: 0.08);
        numColor = success;
        valColor = colors.textPrimary;
        break;
      case _PillState.current:
        borderColor = colors.accent.withValues(alpha: 0.85);
        fill = colors.accent.withValues(alpha: 0.06);
        numColor = colors.accent;
        valColor = colors.textPrimary;
        break;
      case _PillState.upcoming:
        borderColor = colors.cardBorder;
        fill = Colors.transparent;
        numColor = colors.textMuted.withValues(alpha: 0.6);
        valColor = colors.textMuted.withValues(alpha: 0.6);
        break;
    }

    final pill = Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$number',
            style: ZType.data(13, color: numColor, weight: FontWeight.w700),
          ),
          if (valueLabel != null) ...[
            const SizedBox(width: 6),
            Text(
              valueLabel!,
              style: ZType.data(13, color: valColor, weight: FontWeight.w600),
            ),
          ],
          if (state == _PillState.done) ...[
            const SizedBox(width: 5),
            Icon(Icons.check_rounded, size: 13, color: success),
          ],
        ],
      ),
    );

    if (onTap == null) return pill;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: pill,
    );
  }
}
