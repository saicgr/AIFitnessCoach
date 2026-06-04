/// "Around your workout" — the post-workout card group that used to live on
/// Home. Moved to the Workouts tab (user feedback: these don't belong on Home)
/// where it mounts directly beneath today's workout in `WorkoutsScreen`.
///
/// Behavior is unchanged from its Home incarnation: every card is
/// today-anchored (reads `todayWorkoutProvider` / today-only providers) and
/// self-collapses to `SizedBox.shrink()` until today's workout is completed.
/// The `SelfHidingCardSection` wrapper hides the header (and adds zero height)
/// while every card is collapsed, so on non-workout days this renders nothing.
library;

import 'package:flutter/material.dart';

import '../../home/widgets/self_hiding_card_section.dart';
import '../../home/widgets/cards/daily_strain_target_tile.dart';
import '../../home/widgets/cards/hr_zone_breakdown_card.dart';
import '../../home/widgets/cards/one_rm_recompute_banner.dart';
import '../../home/widgets/cards/planned_vs_actual_card.dart';
import '../../home/widgets/cards/postworkout_mood_strip.dart';
import '../../home/widgets/cards/postworkout_progress_photo_prompt.dart';
import '../../home/widgets/cards/postworkout_tomorrow_adjust_card.dart';
import '../../home/widgets/cards/recovery_countdown_tile.dart';
import '../../home/widgets/cards/rhr_delta_card.dart';
import '../../home/widgets/cards/training_effect_card.dart';
import '../../home/widgets/cards/workout_felt_journal_prompt.dart';

class AroundYourWorkoutSection extends StatelessWidget {
  const AroundYourWorkoutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const SelfHidingCardSection(
      title: 'Around your workout',
      collapsible: true,
      initiallyCollapsed: true,
      collapsedSubtitle: 'Training effect, recovery, mood, journal and more',
      children: [
        DailyStrainTargetTile(),
        TrainingEffectCard(),
        RecoveryCountdownTile(),
        PlannedVsActualCard(),
        PostWorkoutTomorrowAdjustCard(),
        HrZoneBreakdownCard(),
        PostWorkoutMoodStrip(),
        RhrDeltaCard(),
        OneRmRecomputeBanner(),
        PostWorkoutProgressPhotoPrompt(),
        WorkoutFeltJournalPrompt(),
      ],
    );
  }
}
