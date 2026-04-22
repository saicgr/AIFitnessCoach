// Easy tier — completed dots strip (NOT the Simple/Advanced set rail).
//
// Compact one-line visual of set progress:
//   Set 1 ✓ 30×10 · Set 2 ✓ 30×10 · Set 3 now · Set 4 ◌
//
// Beginners need to see "what did I just do" without the cognitive
// overhead of Simple's tappable rail. Tapping a completed dot now jumps
// the focal card into "edit" mode for that set — tap again or tap the
// current-set dot to return.
//
// Fixed 36 pt tall regardless of set count. If the row would overflow
// horizontally, the dots Flex-scale down; we never introduce a
// horizontal scroll container.

import 'package:flutter/material.dart';

import '../../../../core/services/haptic_service.dart';
import '../../models/workout_state.dart';

class EasyCompletedDots extends StatelessWidget {
  final List<SetLog> completedSetsForCurrentExercise;
  final int currentSetIndex; // 0-indexed; equals completed.length when about to log
  final int totalSets;
  final bool useKg;

  /// 0-indexed set currently being edited, or null if editing the
  /// current (upcoming) set. When non-null, the matching dot shows in
  /// the "editing" accent so the user sees which past set they're on.
  final int? editingSetIndex;

  /// Fired when the user taps a completed set dot. Passes the 0-based
  /// set index. Null disables tap interactions entirely (back-compat
  /// with callers that haven't wired the callback).
  final ValueChanged<int>? onEditSet;

  /// Fired when the user taps the current (upcoming) set dot while in
  /// edit mode, signaling "return to live set".
  final VoidCallback? onReturnToCurrent;

  /// Fired when the user taps an upcoming (not-yet-completed) set dot.
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

  String _fmtWeight(double w) {
    if (w <= 0) return '';
    return w % 1 == 0 ? w.toStringAsFixed(0) : w.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.white : Colors.black;
    final doneColor = base.withValues(alpha: 0.78);
    final currentColor = base;
    final upcomingColor = base.withValues(alpha: 0.32);
    final editingColor = Theme.of(context).colorScheme.primary;

    // Build a list of dot descriptors (done / current / upcoming).
    final List<Widget> dots = [];
    for (int i = 0; i < totalSets; i++) {
      final isEditingThis = editingSetIndex == i;
      if (i < completedSetsForCurrentExercise.length) {
        final set = completedSetsForCurrentExercise[i];
        final weightDisplay = useKg
            ? set.weight
            : set.weight * 2.20462; // simple display-only convert
        dots.add(_Dot(
          label: 'Set ${i + 1}',
          detail: '${_fmtWeight(weightDisplay)}×${set.reps}',
          color: isEditingThis ? editingColor : doneColor,
          bold: isEditingThis,
          trailingCheck: !isEditingThis,
          onTap: onEditSet == null
              ? null
              : () {
                  HapticService.instance.tap();
                  onEditSet!(i);
                },
        ));
      } else if (i == currentSetIndex) {
        final returnable = editingSetIndex != null && onReturnToCurrent != null;
        dots.add(_Dot(
          label: 'Set ${i + 1}',
          detail: returnable ? 'return' : 'now',
          color: returnable ? editingColor : currentColor,
          bold: true,
          trailingCheck: false,
          onTap: returnable
              ? () {
                  HapticService.instance.tap();
                  onReturnToCurrent!();
                }
              : null,
        ));
      } else {
        // Upcoming set — tappable when `onSkipToSet` is wired. Lets the
        // user jump ahead by padding skipped sets with placeholder logs.
        dots.add(_Dot(
          label: 'Set ${i + 1}',
          detail: null,
          color: upcomingColor,
          bold: false,
          trailingCheck: false,
          onTap: onSkipToSet == null
              ? null
              : () {
                  HapticService.instance.tap();
                  onSkipToSet!(i);
                },
        ));
      }
    }

    // Interleave with dividers. Use Flex weights so any set count fits.
    final children = <Widget>[];
    for (int i = 0; i < dots.length; i++) {
      children.add(Flexible(child: dots[i]));
      if (i < dots.length - 1) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('·',
              style: TextStyle(
                fontSize: 14,
                color: base.withValues(alpha: 0.38),
                fontWeight: FontWeight.w600,
              )),
        ));
      }
    }

    return SizedBox(
      height: 36,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final String label;
  final String? detail;
  final Color color;
  final bool bold;
  final bool trailingCheck;
  final VoidCallback? onTap;

  const _Dot({
    required this.label,
    required this.detail,
    required this.color,
    required this.bold,
    required this.trailingCheck,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          overflow: TextOverflow.ellipsis,
        ),
        if (trailingCheck) ...[
          const SizedBox(width: 3),
          Icon(Icons.check_rounded, size: 12, color: color),
        ],
        if (detail != null && detail!.isNotEmpty) ...[
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              detail!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: color.withValues(alpha: bold ? 1.0 : 0.82),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );

    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: row,
      ),
    );
  }
}
