// Easy tier — in-workout Strength-Score TARGET pill (B6, vs Gravl).
//
// Shows the deterministic weight×reps target that would raise the current
// exercise's primary-muscle strength score into its next level band:
//
//   ⚡  Hit 80 lb × 8 to level up Chest  ·  10 pts to Intermediate
//
// Collapses to `SizedBox.shrink()` when there's no target (already elite,
// excluded muscle, or the fetch failed). Tapping is a no-op — it's a goal
// nudge, not a control. Adds a subtle "stale" hint when the muscle's score
// data has gone stale (training it now also refreshes the score).

import 'package:flutter/material.dart';

import '../score_target_service.dart';

class EasyScoreTargetPill extends StatelessWidget {
  /// The fetched target for the current exercise's primary muscle, or null.
  final ScoreTarget? target;

  /// Display unit toggle (true = kg, false = lb).
  final bool useKg;

  /// Accent color (AccentColorScope) — frames the "level up" call to action.
  final Color accent;

  const EasyScoreTargetPill({
    super.key,
    required this.target,
    required this.useKg,
    required this.accent,
  });

  String _titleCase(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  @override
  Widget build(BuildContext context) {
    final t = target;
    if (t == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = accent.withValues(alpha: isDark ? 0.14 : 0.10);
    final border = accent.withValues(alpha: 0.35);
    final strong = isDark ? Colors.white : Colors.black.withValues(alpha: 0.82);

    final muscle = _titleCase(t.muscleGroup);
    final level = _titleCase(t.nextLevel);
    final label = t.displayLabel(useKg: useKg);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              t.isStale ? Icons.refresh_rounded : Icons.bolt_rounded,
              size: 15,
              color: accent,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: RichText(
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: strong,
                  ),
                  children: [
                    const TextSpan(text: 'Hit '),
                    TextSpan(
                      text: label,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                    TextSpan(
                      text: t.isStale
                          ? ' to refresh + level up $muscle'
                          : ' to level up $muscle',
                    ),
                    if (t.pointsToNextLevel > 0)
                      TextSpan(
                        text: '  ·  ${t.pointsToNextLevel} pts to $level',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: strong.withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
