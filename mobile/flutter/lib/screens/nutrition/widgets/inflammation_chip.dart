import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'score_explain_sheet.dart';

/// Color grade for an inflammation score on the canonical 0-10 scale.
/// Matches the grading used in the Health Breakdown sheet's inflammation row
/// (green = anti-inflammatory, orange = neutral/mild, red = highly
/// inflammatory) so the same food reads the same color everywhere.
Color inflammationColor(num score) {
  if (score >= 7) return AppColors.error;
  if (score >= 4) return AppColors.orange;
  return AppColors.success;
}

/// Short severity label for an inflammation score (0-10).
String inflammationLabel(num score) {
  if (score >= 7) return 'Highly inflammatory';
  if (score >= 4) return 'Neutral / mild';
  return 'Anti-inflammatory';
}

/// Compact, color-graded inflammation pill for a logged-food row.
///
/// Renders "Infl N" (or "Inflammation N/10" when [compact] is false) tinted by
/// severity. Deliberately label-led with NO flame emoji — a flame reads as a
/// reward/streak in a fitness app, which made a HIGH inflammation score look
/// positive. The word "Infl"/"Inflammation" + the red→green color band make it
/// read as "lower is better" instead.
///
/// On tap opens the shared [ScoreExplainSheet] for inflammation so the user
/// gets the same explanation surfaced from Menu Analysis and the food history
/// screen. Returns nothing when the score is null (enrichment pending) — the
/// caller should guard on null too, but this keeps it safe to drop in.
class InflammationChip extends StatelessWidget {
  final int score;
  final List<String> triggers;
  final bool compact;

  const InflammationChip({
    super.key,
    required this.score,
    this.triggers = const [],
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = inflammationColor(score);
    // "Infl 7" is too cryptic for screen readers — announce the full score,
    // the severity grade the color conveys, and that details are available.
    return Semantics(
      button: true,
      label:
          'Inflammation score $score out of 10, ${inflammationLabel(score)}. Tap for details.',
      excludeSemantics: true,
      child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => ScoreExplainSheet.show(
          context,
          kind: ScoreKind.inflammation,
          value: score,
          triggers: triggers,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            // Signature: hairline-outlined chip, severity carried by the
            // label color (red→green band) not a heavy fill.
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                // Label-led so a high score never reads as a reward. Compact
                // ("INFL 7") for tight rows; full ("INFLAMMATION 7/10") on the
                // roomier daily stats card.
                (compact ? 'Infl $score' : 'Inflammation $score/10').toUpperCase(),
                style: ZType.lbl(9.5, color: color, letterSpacing: 1.2),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
