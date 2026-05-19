import 'package:flutter/material.dart';

import '../../empty_state_tip_tour.dart';
import '../tooltip_anchors.dart';
import '../tooltip_ids.dart';

/// First-run tour for the Nutrition screen — 4 steps spotlighting the
/// log-meal entry point, the date navigator, the Fasting card, and the
/// Saved card.
///
/// Replaces the legacy `EmptyStateTipTour` in `nutrition_screen.dart`
/// that lacked `targetKey`s and was wrapped in `Positioned(bottom:90)`,
/// so it never rendered a real spotlight.
class NutritionTour {
  NutritionTour._();

  static const id = TooltipIds.nutrition;

  static List<EmptyStateTip> steps() => [
        EmptyStateTip(
          icon: Icons.add_circle_outline_rounded,
          title: 'Log a meal',
          body:
              'Tap the camera, barcode, or + button — vision OCR auto-fills calories and macros.',
          targetKey: TooltipAnchors.nutritionLogMeal,
          targetPadding: const EdgeInsets.all(10),
          targetRadius: 18,
        ),
        EmptyStateTip(
          icon: Icons.swipe_outlined,
          title: 'Swipe through dates',
          body: 'Use the date arrows or tap History to review any past day.',
          targetKey: TooltipAnchors.nutritionDateNav,
          targetPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          targetRadius: 14,
        ),
        EmptyStateTip(
          icon: Icons.timer_outlined,
          title: 'Intermittent fasting',
          body:
              'Start and track a fast right here — your live fasting window shows on this card.',
          targetKey: TooltipAnchors.nutritionFasting,
          targetPadding: const EdgeInsets.all(6),
          targetRadius: 16,
        ),
        EmptyStateTip(
          icon: Icons.bookmark_outline,
          title: 'Saved',
          body:
              'Your saved recipes, foods and scanned menus live here — one tap to log them again.',
          targetKey: TooltipAnchors.nutritionSaved,
          targetPadding: const EdgeInsets.all(6),
          targetRadius: 16,
        ),
      ];

  // Mount through the root overlay so the dim scrim sits ABOVE the main
  // nav bar — rendering it inside the screen left the nav + its fade
  // gradient painting over the scrim (the grey/white band).
  static Widget overlay() => RootOverlayTipTourHost(
        tourId: id,
        tips: steps(),
        hasMainNavBar: true,
        // Nutrition floats the Daily/Recipes/Patterns/Fuel tab pill above
        // the main nav — reserve clearance so the card clears it.
        extraBottomClearance: 72,
      );
}
