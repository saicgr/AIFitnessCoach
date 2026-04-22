// Part of the Easy/Simple/Advanced workout-UI tier rework.
//
// Fixed-height done/upcoming rail that sits above the focal card. 36 pt single
// row; at ≥8 sets flips to 2 rows (64 pt); at ≥12 sets clips to 2 rows + a
// `+N` overflow chip that opens `set_rail_overflow_sheet.dart`. The rail NEVER
// introduces a scroll container — fits via Flexible weights, collapses to
// icon-only at <56 pt chip width.
//
// Tap a pill → `onEditSet(setIndex)`. Tap the overflow chip → `onOverflowTap()`.
//
// Pill/chip rendering lives in `set_rail_internals.dart` to keep this file
// under the 250-line project cap.

import 'package:flutter/material.dart';

import '../../../core/services/haptic_service.dart';
import 'set_rail_internals.dart';

enum RailSetStatus { done, current, upcoming, warmup }

/// Minimal info the rail needs to render a pill. Not tied to Drift/Supabase —
/// callers map their domain models into this.
class RailSetSummary {
  /// Display index — user-facing set number. Warmups are conventionally
  /// rendered with a "W" badge; use `RailSetStatus.warmup` and any index ≥ 1.
  final int displayIndex;
  final RailSetStatus status;

  /// Weight value for done pills; null for upcoming/current.
  /// Units are the caller's responsibility — the rail just renders it.
  final double? weight;
  final int? reps;

  /// Formatted weight label ("30 kg" / "65 lb") — when non-null this overrides
  /// `weight` for rendering. Callers compute this once with the current
  /// workout-weight-unit preference to avoid re-doing it on every build.
  final String? weightLabel;

  const RailSetSummary({
    required this.displayIndex,
    required this.status,
    this.weight,
    this.reps,
    this.weightLabel,
  });
}

class SetRail extends StatelessWidget {
  final List<RailSetSummary> sets;

  /// Logical "current" index (matches the `currentIndex` in `sets`). The pill
  /// at this index is accent-outlined and sits as the visual anchor.
  final int currentIndex;

  final void Function(int setIndex) onEditSet;
  final VoidCallback onOverflowTap;

  /// Maximum visible pills before triggering the overflow chip (≥12).
  static const int _overflowThreshold = 12;

  /// Threshold for 2-row layout (≥8).
  static const int _twoRowThreshold = 8;

  const SetRail({
    super.key,
    required this.sets,
    required this.currentIndex,
    required this.onEditSet,
    required this.onOverflowTap,
  });

  @override
  Widget build(BuildContext context) {
    if (sets.isEmpty) return const SizedBox(height: 36);

    final count = sets.length;
    final useTwoRows = count >= _twoRowThreshold;
    final needsOverflow = count >= _overflowThreshold;
    final height = useTwoRows ? 64.0 : 36.0;

    // When overflowing, show the first 11 pills + a "+N" overflow tile. The
    // overflow sheet is the canonical editor for anything that doesn't fit
    // inside the rail — per plan, the main workout surface never scrolls.
    final visibleCount = needsOverflow ? _overflowThreshold - 1 : count;
    final visible = sets.take(visibleCount).toList(growable: false);
    final overflowCount = count - visibleCount;

    return SizedBox(
      height: height,
      child: useTwoRows
          ? _TwoRowLayout(
              visible: visible,
              currentIndex: currentIndex,
              overflowCount: needsOverflow ? overflowCount : 0,
              onEditSet: onEditSet,
              onOverflowTap: onOverflowTap,
            )
          : _OneRowLayout(
              visible: visible,
              currentIndex: currentIndex,
              overflowCount: needsOverflow ? overflowCount : 0,
              onEditSet: onEditSet,
              onOverflowTap: onOverflowTap,
            ),
    );
  }
}

class _OneRowLayout extends StatelessWidget {
  final List<RailSetSummary> visible;
  final int currentIndex;
  final int overflowCount;
  final void Function(int) onEditSet;
  final VoidCallback onOverflowTap;

  const _OneRowLayout({
    required this.visible,
    required this.currentIndex,
    required this.overflowCount,
    required this.onEditSet,
    required this.onOverflowTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < visible.length; i++) ...[
          Flexible(
            child: RailPill(
              summary: visible[i],
              isCurrent: i == currentIndex,
              onTap: () {
                HapticService.instance.tick();
                onEditSet(i);
              },
            ),
          ),
          if (i < visible.length - 1) const SizedBox(width: 6),
        ],
        if (overflowCount > 0) ...[
          const SizedBox(width: 6),
          RailOverflowChip(count: overflowCount, onTap: onOverflowTap),
        ],
      ],
    );
  }
}

class _TwoRowLayout extends StatelessWidget {
  final List<RailSetSummary> visible;
  final int currentIndex;
  final int overflowCount;
  final void Function(int) onEditSet;
  final VoidCallback onOverflowTap;

  const _TwoRowLayout({
    required this.visible,
    required this.currentIndex,
    required this.overflowCount,
    required this.onEditSet,
    required this.onOverflowTap,
  });

  @override
  Widget build(BuildContext context) {
    final half = (visible.length / 2).ceil();
    final topRow = visible.sublist(0, half);
    final bottomRow = visible.sublist(half);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RowLine(
          summaries: topRow,
          baseIndex: 0,
          currentIndex: currentIndex,
          overflowCount: 0,
          onEditSet: onEditSet,
          onOverflowTap: onOverflowTap,
        ),
        const SizedBox(height: 4),
        _RowLine(
          summaries: bottomRow,
          baseIndex: half,
          currentIndex: currentIndex,
          overflowCount: overflowCount,
          onEditSet: onEditSet,
          onOverflowTap: onOverflowTap,
        ),
      ],
    );
  }
}

class _RowLine extends StatelessWidget {
  final List<RailSetSummary> summaries;
  final int baseIndex;
  final int currentIndex;
  final int overflowCount;
  final void Function(int) onEditSet;
  final VoidCallback onOverflowTap;

  const _RowLine({
    required this.summaries,
    required this.baseIndex,
    required this.currentIndex,
    required this.overflowCount,
    required this.onEditSet,
    required this.onOverflowTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          for (int i = 0; i < summaries.length; i++) ...[
            Flexible(
              child: RailPill(
                summary: summaries[i],
                isCurrent: (baseIndex + i) == currentIndex,
                onTap: () {
                  HapticService.instance.tick();
                  onEditSet(baseIndex + i);
                },
              ),
            ),
            if (i < summaries.length - 1) const SizedBox(width: 6),
          ],
          if (overflowCount > 0) ...[
            const SizedBox(width: 6),
            RailOverflowChip(count: overflowCount, onTap: onOverflowTap),
          ],
        ],
      ),
    );
  }
}
