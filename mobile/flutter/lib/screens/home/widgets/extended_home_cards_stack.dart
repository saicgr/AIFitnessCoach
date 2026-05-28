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

import 'cards/accountability_partner_nudge.dart';
import 'cards/app_anniversary_card.dart';
import 'cards/bedtime_window_tile.dart';
import 'cards/birthday_card.dart';
import 'cards/body_battery_tile.dart';
import 'cards/body_comp_milestone_card.dart';
import 'cards/busy_week_compressed_card.dart';
import 'cards/coach_persona_pickup_tile.dart';
import 'cards/cycle_phase_chip.dart';
import 'cards/daily_lesson_tile.dart';
import 'cards/daily_meditation_tile.dart';
import 'cards/daily_quest_deck.dart';
import 'cards/daily_strain_target_tile.dart';
import 'cards/day14_goal_recalibration_card.dart';
import 'cards/day_n_tutorial_card.dart';
import 'cards/day_of_week_skip_card.dart';
import 'cards/discovery_insight_tile.dart';
import 'cards/equipment_preflight_banner.dart';
import 'cards/evening_sleep_story_tile.dart';
import 'cards/fast_streak_tile.dart';
import 'cards/fast_zone_strip.dart';
import 'cards/first_of_month_card.dart';
import 'cards/friend_activity_snippet.dart';
import 'cards/group_challenge_progress.dart';
import 'cards/hr_zone_breakdown_card.dart';
import 'cards/hrv_trend_strip.dart';
import 'cards/injury_workaround_banner.dart';
import 'cards/jet_lag_adjust_card.dart';
import 'cards/knowledge_cards_carousel.dart';
import 'cards/league_rank_tile.dart';
import 'cards/macro_pattern_callout.dart';
import 'cards/micronutrient_gap_chip.dart';
import 'cards/mindful_minutes_ring.dart';
import 'cards/missing_data_chip.dart';
import 'cards/monthly_quest_tile.dart';
import 'cards/mood_checkin_strip.dart';
import 'cards/one_rm_recompute_banner.dart';
import 'cards/period_prediction_tile.dart';
import 'cards/period_symptom_log_tile.dart';
import 'cards/planned_vs_actual_card.dart';
import 'cards/pms_prep_card.dart';
import 'cards/postworkout_mood_strip.dart';
import 'cards/postworkout_progress_photo_prompt.dart';
import 'cards/postworkout_tomorrow_adjust_card.dart';
import 'cards/pre_workout_fuel_card.dart';
import 'cards/premium_preview_tile.dart';
import 'cards/preworkout_rpe_chip.dart';
import 'cards/preworkout_t30_card.dart';
import 'cards/preworkout_warmup_card.dart';
import 'cards/readiness_score_card.dart';
import 'cards/recovery_countdown_tile.dart';
import 'cards/referral_gift_tile.dart';
import 'cards/return_to_exercise_card.dart';
import 'cards/rhr_delta_card.dart';
import 'cards/scale_sync_prompt.dart';
import 'cards/sleep_latency_tile.dart';
import 'cards/smart_reschedule_banner.dart';
import 'cards/smoothed_weight_trend_chip.dart';
import 'cards/stand_reminder_chip.dart';
import 'cards/step_streak_tile.dart';
import 'cards/sticky_wearable_tile.dart';
import 'cards/strain_recovery_mismatch_card.dart';
import 'cards/streak_freeze_chip.dart';
import 'cards/stress_score_tile.dart';
import 'cards/tomorrow_preview_tile.dart';
import 'cards/training_effect_card.dart';
import 'cards/usage_upsell_banner.dart';
import 'cards/vo2max_trend_chip.dart';
import 'cards/wake_consistency_tile.dart';
import 'cards/wearable_battery_chip.dart';
import 'cards/weekly_digest_tile.dart';
import 'cards/weekly_plan_strip.dart';
import 'cards/weigh_in_day_chip.dart';
import 'cards/workout_felt_journal_prompt.dart';
import 'cards/workout_milestone_card.dart';
import 'cards/workout_sleep_correlation_card.dart';
import 'cards/zone_minutes_bar.dart';

class ExtendedHomeCardsStack extends ConsumerWidget {
  const ExtendedHomeCardsStack({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ordering loosely follows the user's day: health snapshot → schedule
    // → meals/hydration → habits/social → educational → milestones →
    // pre-workout → post-workout → onboarding leftovers. Within a group
    // the SubCardRanker handles sub-card prioritisation; this stack is
    // for the FULL cards that sit outside the Coach hero card.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        // -- Recovery & physiological --------------------------------
        ReadinessScoreCard(),
        HrvTrendStrip(),
        BodyBatteryTile(),
        StressScoreTile(),
        Vo2maxTrendChip(),

        // -- Sleep / circadian ---------------------------------------
        BedtimeWindowTile(),
        WakeConsistencyTile(),
        SleepLatencyTile(),
        EveningSleepStoryTile(),

        // -- Schedule / planning -------------------------------------
        WeeklyPlanStrip(),
        TomorrowPreviewTile(),
        SmartRescheduleBanner(),
        PreWorkoutFuelCard(),

        // -- Movement non-workout ------------------------------------
        StandReminderChip(),
        StepStreakTile(),
        ZoneMinutesBar(),

        // -- Hydration / nutrition micro -----------------------------
        MicronutrientGapChip(),
        SmoothedWeightTrendChip(),

        // -- Cycle ---------------------------------------------------
        CyclePhaseChip(),
        PeriodPredictionTile(),
        PmsPrepCard(),
        PeriodSymptomLogTile(),

        // -- Mental health -------------------------------------------
        MoodCheckinStrip(),
        MindfulMinutesRing(),
        DailyMeditationTile(),

        // -- Habit / gamification ------------------------------------
        StreakFreezeChip(),
        DailyQuestDeck(),
        MonthlyQuestTile(),
        LeagueRankTile(),

        // -- Social --------------------------------------------------
        FriendActivitySnippet(),
        GroupChallengeProgress(),
        AccountabilityPartnerNudge(),

        // -- Subscription --------------------------------------------
        UsageUpsellBanner(),
        ReferralGiftTile(),
        PremiumPreviewTile(),

        // -- Educational ---------------------------------------------
        KnowledgeCardsCarousel(),
        DailyLessonTile(),
        WeeklyDigestTile(),
        DiscoveryInsightTile(),

        // -- Milestones ----------------------------------------------
        AppAnniversaryCard(),
        WorkoutMilestoneCard(),
        BodyCompMilestoneCard(),
        BirthdayCard(),
        FirstOfMonthCard(),
        WeighInDayChip(),

        // -- Wearable status -----------------------------------------
        WearableBatteryChip(),
        ScaleSyncPrompt(),
        MissingDataChip(),

        // -- AI pattern detection ------------------------------------
        DayOfWeekSkipCard(),
        WorkoutSleepCorrelationCard(),
        MacroPatternCallout(),
        StrainRecoveryMismatchCard(),

        // -- Injury / travel -----------------------------------------
        ReturnToExerciseCard(),
        InjuryWorkaroundBanner(),
        JetLagAdjustCard(),
        BusyWeekCompressedCard(),

        // -- Onboarding leftovers ------------------------------------
        StickyWearableTile(),
        DayNTutorialCard(),
        Day14GoalRecalibrationCard(),
        CoachPersonaPickupTile(),

        // -- Fasting -------------------------------------------------
        FastZoneStrip(),
        FastStreakTile(),

        // -- Pre-workout ---------------------------------------------
        PreWorkoutT30Card(),
        PreWorkoutWarmupCard(),
        PreWorkoutRpeChip(),
        DailyStrainTargetTile(),
        EquipmentPreflightBanner(),

        // -- Post-workout --------------------------------------------
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
