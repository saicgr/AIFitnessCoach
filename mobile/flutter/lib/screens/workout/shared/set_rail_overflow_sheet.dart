// Part of the Easy/Simple/Advanced workout-UI tier rework.
//
// Bottom-sheet editor for sets that don't fit in the 12-pill rail. Lists each
// set as a row (set#, prev, weight × reps, edit affordance). Tap a row →
// dismiss the sheet and return the index so the focal card can re-bind.
//
// The sheet itself is the only scroll container — the main workout surface
// remains scroll-free, honoring the no-scroll hard constraint.
//
// Row rendering lives in `set_rail_overflow_row.dart` so this file stays
// under the 250-line project cap.

import 'package:flutter/material.dart';

import '../../../core/services/haptic_service.dart';
import 'set_rail.dart';
import 'set_rail_overflow_row.dart';

/// Convenience launcher used by consumers. Returns the picked index when the
/// user tapped a row, or null on dismiss.
Future<int?> showSetRailOverflowSheet({
  required BuildContext context,
  required List<RailSetSummary> sets,
  required int currentIndex,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SetRailOverflowSheet(
      sets: sets,
      currentIndex: currentIndex,
    ),
  );
}

/// Exposed publicly so callers can compose it inside an existing sheet if
/// needed (e.g. Simple tier's plan sheet).
class SetRailOverflowSheet extends StatelessWidget {
  final List<RailSetSummary> sets;
  final int currentIndex;

  const SetRailOverflowSheet({
    super.key,
    required this.sets,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final onSurface = isDark ? Colors.white : Colors.black;
    final mediaHeight = MediaQuery.of(context).size.height;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: mediaHeight * 0.68),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: onSurface.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'All sets',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: onSurface,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${sets.length} total',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: onSurface.withValues(alpha: 0.6),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: sets.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: onSurface.withValues(alpha: 0.06),
                ),
                itemBuilder: (context, i) => OverflowRow(
                  summary: sets[i],
                  isCurrent: i == currentIndex,
                  onTap: () {
                    HapticService.instance.tick();
                    Navigator.of(context).pop(i);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
