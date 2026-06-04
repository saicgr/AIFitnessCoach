/// Extended home cards stack — auto-mounts all 80 contextual cards added
/// in the home-screen overhaul (Phases B–W). Each card self-collapses to
/// `SizedBox.shrink()` when its gating condition fails (no signal, wrong
/// time-of-day, feature disabled), so this Column is cheap to evaluate
/// even though it lists every card every build.
///
/// Mounted as a single `SliverToBoxAdapter` after the legacy tile stack
/// in `home_screen.dart`. Each card decides for itself whether to render.
///
/// Why a flat Column rather than the legacy TileType registry: adding
/// 80 TileType entries (× 4 switch statements: layout editor, tile
/// picker, preview mock, builder) is 320 case additions, each a chance
/// to break the existing My-Space reorder UX. The self-collapse model
/// matches what CalibrationBanner / SetupChecklistCard / StackedBanner
/// already do — invisible until they have a reason to render.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'self_hiding_card_section.dart';
import 'cards/accountability_partner_nudge.dart';
import 'cards/app_anniversary_card.dart';
import 'cards/birthday_card.dart';
import 'cards/body_comp_milestone_card.dart';
import 'cards/busy_week_compressed_card.dart';
import 'cards/fast_streak_tile.dart';
import 'cards/fast_zone_strip.dart';
import 'cards/first_of_month_card.dart';
import 'cards/friend_activity_snippet.dart';
import 'cards/group_challenge_progress.dart';
import 'cards/injury_workaround_banner.dart';
import 'cards/jet_lag_adjust_card.dart';
import 'cards/macro_pattern_callout.dart';
import 'cards/plan_adjustments_card.dart';
import 'cards/referral_gift_tile.dart';
import 'cards/return_to_exercise_card.dart';
import 'cards/smoothed_weight_trend_chip.dart';
import 'cards/stale_score_nudge_card.dart';
import 'cards/stand_reminder_chip.dart';
import 'cards/step_streak_tile.dart';
import 'cards/weekly_plan_strip.dart';
import 'cards/weigh_in_day_chip.dart';
import 'cards/workout_milestone_card.dart';
import 'cards/workout_sleep_correlation_card.dart';
import 'cards/zone_minutes_bar.dart';

class ExtendedHomeCardsStack extends ConsumerWidget {
  const ExtendedHomeCardsStack({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Each card still self-collapses to SizedBox.shrink when its gate fails.
    // They're now grouped under labeled, SELF-HIDING section headers (issue 7):
    // a header only paints when ≥1 card in its group actually renders, so an
    // empty group shows nothing (no orphan header). The Timeline is NOT here —
    // home_screen appends it as the very last card after this whole stack.
    //
    // Wrapped in a RepaintBoundary so this large self-collapsing card stack
    // paints into its own layer — sibling slivers (and the deck above) don't
    // force it to repaint, and its own repaints don't dirty them.
    return RepaintBoundary(
      child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Readiness, HRV, Stress, VO₂max, Bedtime, Wake consistency and Sleep
        // latency moved OUT of standalone home cards and INTO the metric deck
        // as selectable metric tiles (user feedback) — readiness == the
        // existing Recovery ring. The evening sleep-story tile was removed from
        // home (user feedback); the widget still exists, just unmounted here.
        SelfHidingCardSection(
          title: 'Activity',
          children: const [
            StandReminderChip(),
            StepStreakTile(),
            ZoneMinutesBar(),
          ],
        ),
        SelfHidingCardSection(
          title: 'Nutrition & body',
          children: const [
            // MicronutrientGapChip removed from Home — micronutrients live in
            // the Nutrition tab (micros_detail_screen / nutrient_explorer).
            SmoothedWeightTrendChip(),
          ],
        ),
        // #12 — the four cycle tiles (CyclePhaseChip / PeriodPredictionTile /
        // PmsPrepCard / PeriodSymptomLogTile) are consolidated into ONE
        // expandable "Your Cycle" card (CycleSummaryCard). It renders in the
        // dedicated HomeSection.cycle slot (home_screen.dart) — NOT here too —
        // so cycle shows exactly once. The separate tiles are gone from home.
        // #13 — DeloadRecommendationCard, SmartRescheduleBanner,
        // DayOfWeekSkipCard and StrainRecoveryMismatchCard are consolidated
        // into the single PlanAdjustmentsCard, which lists only the currently
        // active adjustments (each a row with its own CTA). The four cards are
        // no longer rendered separately on home.
        SelfHidingCardSection(
          title: 'Plan & adjustments',
          children: const [
            WeeklyPlanStrip(),
            StaleScoreNudgeCard(),
            PlanAdjustmentsCard(),
            ReturnToExerciseCard(),
            InjuryWorkaroundBanner(),
            JetLagAdjustCard(),
            BusyWeekCompressedCard(),
          ],
        ),
        SelfHidingCardSection(
          title: 'Patterns & insights',
          children: const [
            WorkoutSleepCorrelationCard(),
            MacroPatternCallout(),
          ],
        ),
        SelfHidingCardSection(
          title: 'Social',
          children: const [
            FriendActivitySnippet(),
            GroupChallengeProgress(),
            AccountabilityPartnerNudge(),
          ],
        ),
        SelfHidingCardSection(
          title: 'Milestones',
          children: const [
            AppAnniversaryCard(),
            WorkoutMilestoneCard(),
            BodyCompMilestoneCard(),
            BirthdayCard(),
            FirstOfMonthCard(),
            WeighInDayChip(),
          ],
        ),
        // Membership slimmed to just the referral tile (user feedback) — the
        // usage-cap upsell + premium-preview were dropped from home. It now
        // sits under a lightweight self-hiding section header (issue 6) so it
        // isn't an orphaned, header-less card floating between groups. The
        // header only paints when the tile itself renders (the tile self-hides
        // when there's no referral offer), so a hidden tile leaves no orphan
        // header.
        SelfHidingCardSection(
          title: 'Refer & earn',
          children: const [
            ReferralGiftTile(),
          ],
        ),
        // #14 — the standalone "Connect Health Connect / Apple Health" preflight
        // (MissingDataChip) was removed from home; the user prefers reaching
        // these via the timeline + workout card. The MissingDataChip widget
        // file stays in place, unused.
        SelfHidingCardSection(
          title: 'Fasting',
          children: const [
            FastZoneStrip(),
            FastStreakTile(),
          ],
        ),
        // #14 — the pre-workout prep cards (PreWorkoutT30Card,
        // PreWorkoutWarmupCard, PreWorkoutRpeChip, EquipmentPreflightBanner)
        // are no longer rendered on home; the timeline + workout card cover
        // pre-workout prep. The widget files stay in place, unused.
        //
        // #15 — the "Around your workout" post-workout card group (Training
        // effect, Planned vs actual, mood/journal prompts, Tomorrow tweak, …)
        // moved OFF Home and INTO the Workouts tab (user feedback). It now
        // mounts beneath today's workout via `AroundYourWorkoutSection` in
        // `workouts_screen.dart`. The 11 card widgets stay in
        // `home/widgets/cards/`; only the mount point moved.
      ],
      ),
    );
  }
}

// The self-hiding section wrapper formerly defined here as `_HomeCardSection`
// now lives in `self_hiding_card_section.dart` as the public
// `SelfHidingCardSection`, shared with the Workouts tab's
// `AroundYourWorkoutSection`.
