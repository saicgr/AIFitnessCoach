import 'package:flutter/material.dart';

import '../../empty_state_tip_tour.dart';
import '../tooltip_anchors.dart';
import '../tooltip_ids.dart';

/// First-run tour for the Nutrition screen — 3 steps spotlighting the
/// log-meal entry point, the date navigator, and My Foods.
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
          icon: Icons.bookmark_outline,
          title: 'My Foods',
          body:
              'Save meals and recipes you eat often — one tap to log them again.',
          targetKey: TooltipAnchors.nutritionMyFoods,
          targetPadding: const EdgeInsets.all(6),
          targetRadius: 14,
        ),
      ];

  static Widget overlay() => Positioned.fill(
        child: SafeArea(
          top: false,
          child: EmptyStateTipTour(tourId: id, tips: steps()),
        ),
      );
}
