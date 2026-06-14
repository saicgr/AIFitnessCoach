// Easy tier — the set rail (`.rw-rail` from signature-v2 · EASY frame).
//
// A row of square set cells (`.rw-cell`), one per set:
//   • done    → a ✓ check, success-tinted border + faint success wash
//   • current → the set number, plain text, with a 2px ACCENT UNDERLINE
//               bar tucked under it (the `.rw-cell.cur::after` rule)
//   • upcoming→ the set number, muted/faint
//
// This is the structural rail that anchors the bottom of the poster — it
// replaces the old comma-separated "Set 1 ✓ … Set 3 now" dots line. Every
// cell stays tappable: a done cell jumps the focal card into edit mode for
// that set, the current cell returns to live, an upcoming cell skips ahead.
//
// Fixed-height regardless of set count. The cells size down (Flexible) so
// any set count fits one line — we never introduce a horizontal scroll.

import 'package:flutter/material.dart';

import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../models/workout_state.dart';

class EasyCompletedDots extends StatelessWidget {
  final List<SetLog> completedSetsForCurrentExercise;
  final int currentSetIndex; // 0-indexed; equals completed.length when about to log
  final int totalSets;
  final bool useKg;

  /// 0-indexed set currently being edited, or null if editing the
  /// current (upcoming) set. When non-null, the matching cell shows in
  /// the "editing" accent so the user sees which past set they're on.
  final int? editingSetIndex;

  /// Fired when the user taps a completed set cell. Passes the 0-based
  /// set index. Null disables tap interactions entirely (back-compat
  /// with callers that haven't wired the callback).
  final ValueChanged<int>? onEditSet;

  /// Fired when the user taps the current (upcoming) set cell while in
  /// edit mode, signaling "return to live set".
  final VoidCallback? onReturnToCurrent;

  /// Fired when the user taps an upcoming (not-yet-completed) set cell.
  /// The Easy state uses this to "skip ahead" — padding intermediate sets
  /// with placeholder zero-weight logs so the user can jump forward in
  /// the set sequence. Null = upcoming sets are not tappable.
  final ValueChanged<int>? onSkipToSet;

  const EasyCompletedDots({
    super.key,
    required this.completedSetsForCurrentExercise,
    required this.currentSetIndex,
    required this.totalSets,
    required this.useKg,
    this.editingSetIndex,
    this.onEditSet,
    this.onReturnToCurrent,
    this.onSkipToSet,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    // Build a cell descriptor (done / current / upcoming) per set.
    final List<Widget> cells = [];
    for (int i = 0; i < totalSets; i++) {
      final isEditingThis = editingSetIndex == i;

      if (i < completedSetsForCurrentExercise.length) {
        // ── DONE cell: ✓ in success colour, success-tinted border + wash.
        cells.add(_RailCell(
          state: isEditingThis ? _CellState.current : _CellState.done,
          number: i + 1,
          colors: colors,
          onTap: onEditSet == null
              ? null
              : () {
                  HapticService.instance.tap();
                  onEditSet!(i);
                },
        ));
      } else if (i == currentSetIndex) {
        // ── CURRENT cell: number + the 2px accent underline bar.
        final returnable =
            editingSetIndex != null && onReturnToCurrent != null;
        cells.add(_RailCell(
          state: _CellState.current,
          number: i + 1,
          colors: colors,
          onTap: returnable
              ? () {
                  HapticService.instance.tap();
                  onReturnToCurrent!();
                }
              : null,
        ));
      } else {
        // ── UPCOMING cell: muted number, optionally skip-to-tap.
        cells.add(_RailCell(
          state: _CellState.upcoming,
          number: i + 1,
          colors: colors,
          onTap: onSkipToSet == null
              ? null
              : () {
                  HapticService.instance.tap();
                  onSkipToSet!(i);
                },
        ));
      }
    }

    return SizedBox(
      height: 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (final c in cells) Flexible(child: Center(child: c)),
          ],
        ),
      ),
    );
  }
}

enum _CellState { done, current, upcoming }

/// A single square set cell — the `.rw-cell` primitive. 28×28 square with a
/// hairline border; the current cell carries a 2px accent underline bar.
class _RailCell extends StatelessWidget {
  final _CellState state;
  final int number;
  final ThemeColors colors;
  final VoidCallback? onTap;

  const _RailCell({
    required this.state,
    required this.number,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final success = colors.success;

    Color borderColor;
    Color fill;
    Color fg;
    Widget content;

    switch (state) {
      case _CellState.done:
        borderColor = success.withValues(alpha: 0.45);
        fill = success.withValues(alpha: 0.07);
        fg = success;
        content = Icon(Icons.check_rounded, size: 15, color: fg);
        break;
      case _CellState.current:
        borderColor = colors.cardBorder;
        fill = Colors.transparent;
        fg = colors.textPrimary;
        content = _numberText(fg);
        break;
      case _CellState.upcoming:
        borderColor = colors.cardBorder;
        fill = Colors.transparent;
        fg = colors.textMuted.withValues(alpha: 0.65);
        content = _numberText(fg);
        break;
    }

    // The square cell. The current cell adds a 2px accent underline bar
    // tucked just below it (the v2 `.rw-cell.cur::after`).
    final cell = SizedBox(
      width: 30,
      height: 34,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor),
            ),
            child: content,
          ),
          const SizedBox(height: 3),
          // Current-set accent underline — the rail's "you are here" mark.
          Container(
            width: 20,
            height: 2,
            decoration: BoxDecoration(
              color: state == _CellState.current
                  ? colors.accent
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return cell;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: cell,
    );
  }

  Widget _numberText(Color fg) => Text(
        '$number',
        style: TextStyle(
          fontFamily: 'Barlow Condensed',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: fg,
          height: 1.0,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
}
