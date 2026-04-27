import 'package:flutter/material.dart';

import '../../empty_state_tip_tour.dart';
import '../tooltip_anchors.dart';
import '../tooltip_ids.dart';

/// First-run tour for the Menu Analysis sheet — already worked before
/// this refactor; lifted into its own class for consistency.
class MenuAnalysisTour {
  MenuAnalysisTour._();

  static const id = TooltipIds.menuAnalysis;

  static List<EmptyStateTip> steps() => [
        EmptyStateTip(
          icon: Icons.swap_vert_rounded,
          title: 'Sort the whole menu',
          body:
              'Tap Protein, Carbs, Fat, or Inflammation to re-rank every dish at once. More… opens advanced sort.',
          targetKey: TooltipAnchors.menuAnalysisSortRow,
          targetPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          targetRadius: 14,
        ),
        EmptyStateTip(
          icon: Icons.tune_rounded,
          title: 'Filter by diet & allergens',
          body:
              'Hide dishes that don\'t fit your diet or contain your allergens — your preferences carry over from Settings.',
          targetKey: TooltipAnchors.menuAnalysisFilter,
          targetPadding: const EdgeInsets.all(6),
          targetRadius: 14,
        ),
        EmptyStateTip(
          icon: Icons.auto_awesome_rounded,
          title: 'Recommended for you',
          body:
              'AI picks the best three dishes against your remaining macros, allergens, and inflammation tolerance.',
          targetKey: TooltipAnchors.menuAnalysisRecommended,
          targetPadding: const EdgeInsets.all(6),
          targetRadius: 16,
        ),
        EmptyStateTip(
          icon: Icons.add_circle_outline_rounded,
          title: 'Select dishes to log',
          body:
              'Tick the dishes you actually ordered, then hit Log to send them to your daily totals.',
          targetKey: TooltipAnchors.menuAnalysisSelectFooter,
          targetPadding: const EdgeInsets.all(6),
          targetRadius: 14,
        ),
      ];

  static Widget overlay() => Positioned.fill(
        child: EmptyStateTipTour(tourId: id, tips: steps()),
      );
}
