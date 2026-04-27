import 'package:flutter/material.dart';

import '../../empty_state_tip_tour.dart';
import '../tooltip_anchors.dart';
import '../tooltip_ids.dart';

/// First-run tour for the Workouts tab — already worked before this
/// refactor; lifted out of the screen so every tour lives in the same
/// modular shape.
class WorkoutsTour {
  WorkoutsTour._();

  static const id = TooltipIds.workouts;

  static List<EmptyStateTip> steps() => [
        EmptyStateTip(
          icon: Icons.play_circle_outline_rounded,
          title: 'Start a workout',
          body:
              'Hit Start on Today\'s Workout to log sets, reps, and weight with the in-flow rest timer.',
          targetKey: TooltipAnchors.workoutsToday,
          targetPadding: const EdgeInsets.all(10),
          targetRadius: 22,
        ),
        EmptyStateTip(
          icon: Icons.tune_rounded,
          title: 'Make it yours',
          body:
              'Use Custom, Browse, or Favorites to build, swap, or repeat a workout.',
          targetKey: TooltipAnchors.workoutsQuickActions,
          targetPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          targetRadius: 16,
        ),
        EmptyStateTip(
          icon: Icons.favorite_outline_rounded,
          title: 'Set your preferences',
          body:
              'Pin favorites, hide exercises you avoid, or queue moves you want next.',
          targetKey: TooltipAnchors.workoutsExercisePrefs,
          targetPadding: const EdgeInsets.all(8),
          targetRadius: 18,
        ),
      ];

  static Widget overlay() => Positioned.fill(
        child: SafeArea(
          top: false,
          child: EmptyStateTipTour(tourId: id, tips: steps()),
        ),
      );
}
