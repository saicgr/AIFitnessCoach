import 'package:flutter/material.dart';

import '../../empty_state_tip_tour.dart';
import '../tooltip_anchors.dart';
import '../tooltip_ids.dart';

/// First-run tour for the Nutrition screen — 2 steps spotlighting the
/// log-meal entry point and the date navigator.
///
/// Replaces the legacy `EmptyStateTipTour` in `nutrition_screen.dart`
/// that lacked `targetKey`s and was wrapped in `Positioned(bottom:90)`,
/// so it never rendered a real spotlight.
///
/// The old "Intermittent fasting" and "Saved" steps were removed: the
/// current Daily tab no longer carries the old Fasting + Saved split row
/// (Surface 3.2 — fasting is now a contextual slim bar, and Saved moved to
/// the Recipes tab), so the `nutritionFasting` / `nutritionSaved` anchors are
/// no longer attached to anything. Those steps spotlighted nothing on the
/// current screen, so they are gone rather than pointing at the old layout.
class NutritionTour {
  NutritionTour._();

  static const id = TooltipIds.nutrition;

  // TODO(i18n): static method — no BuildContext available.
  // Refactor to instance method accepting BuildContext to enable l10n.
  static List<EmptyStateTip> steps() => [
        EmptyStateTip(
          icon: Icons.restaurant_menu_rounded,
          title: 'Log a meal',
          body:
              'Tap Log Meal to add food by photo, barcode, or search. AI auto-fills the calories and macros for you.',
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
      ];

  // Mount through the root overlay so the dim scrim sits ABOVE the main
  // nav bar — rendering it inside the screen left the nav + its fade
  // gradient painting over the scrim (the grey/white band).
  //
  // [onDismissed] fires when the user actively closes the tour (X / final
  // Next / scrim tap) — NutritionScreen uses it to sequence the weekly
  // check-in sheet so it never lands on top of a still-visible tour card.
  static Widget overlay({VoidCallback? onDismissed}) => RootOverlayTipTourHost(
        tourId: id,
        tips: steps(),
        hasMainNavBar: true,
        // Nutrition floats the Daily/Recipes/Patterns/Fuel tab pill above
        // the main nav — reserve clearance so the card clears it.
        extraBottomClearance: 72,
        onDismissed: onDismissed,
      );
}
