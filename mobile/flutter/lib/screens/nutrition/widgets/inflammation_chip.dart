import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
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
/// Renders "🔥 N" (or "🔥 N/10" when [compact] is false) tinted by severity,
/// and on tap opens the shared [ScoreExplainSheet] for inflammation so the user
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
    return Material(
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
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 10)),
              const SizedBox(width: 4),
              Text(
                compact ? '$score' : '$score/10',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
