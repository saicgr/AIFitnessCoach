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

import '../../../core/theme/theme_colors.dart';
import 'cards/accountability_partner_nudge.dart';
import 'cards/app_anniversary_card.dart';
import 'cards/birthday_card.dart';
import 'cards/body_comp_milestone_card.dart';
import 'cards/busy_week_compressed_card.dart';
import 'cards/cycle_phase_chip.dart';
import 'cards/daily_strain_target_tile.dart';
import 'cards/day_of_week_skip_card.dart';
import 'cards/equipment_preflight_banner.dart';
import 'cards/evening_sleep_story_tile.dart';
import 'cards/fast_streak_tile.dart';
import 'cards/fast_zone_strip.dart';
import 'cards/first_of_month_card.dart';
import 'cards/friend_activity_snippet.dart';
import 'cards/group_challenge_progress.dart';
import 'cards/hr_zone_breakdown_card.dart';
import 'cards/injury_workaround_banner.dart';
import 'cards/jet_lag_adjust_card.dart';
import 'cards/macro_pattern_callout.dart';
import 'cards/micronutrient_gap_chip.dart';
import 'cards/missing_data_chip.dart';
import 'cards/one_rm_recompute_banner.dart';
import 'cards/period_prediction_tile.dart';
import 'cards/period_symptom_log_tile.dart';
import 'cards/planned_vs_actual_card.dart';
import 'cards/pms_prep_card.dart';
import 'cards/postworkout_mood_strip.dart';
import 'cards/postworkout_progress_photo_prompt.dart';
import 'cards/postworkout_tomorrow_adjust_card.dart';
import 'cards/preworkout_rpe_chip.dart';
import 'cards/preworkout_t30_card.dart';
import 'cards/preworkout_warmup_card.dart';
import 'cards/recovery_countdown_tile.dart';
import 'cards/referral_gift_tile.dart';
import 'cards/return_to_exercise_card.dart';
import 'cards/rhr_delta_card.dart';
import 'cards/smart_reschedule_banner.dart';
import 'cards/smoothed_weight_trend_chip.dart';
import 'cards/stand_reminder_chip.dart';
import 'cards/step_streak_tile.dart';
import 'cards/strain_recovery_mismatch_card.dart';
import 'cards/training_effect_card.dart';
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
    // Each card still self-collapses to SizedBox.shrink when its gate fails.
    // They're now grouped under labeled, SELF-HIDING section headers (issue 7):
    // a header only paints when ≥1 card in its group actually renders, so an
    // empty group shows nothing (no orphan header). The Timeline is NOT here —
    // home_screen appends it as the very last card after this whole stack.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Readiness, HRV, Stress, VO₂max, Bedtime, Wake consistency and Sleep
        // latency moved OUT of standalone home cards and INTO the metric deck
        // as selectable metric tiles (user feedback) — readiness == the
        // existing Recovery ring. Only the evening sleep-story narrative (no
        // metric equivalent) remains here.
        _HomeCardSection(
          title: 'Sleep',
          children: const [
            EveningSleepStoryTile(),
          ],
        ),
        _HomeCardSection(
          title: 'Activity',
          children: const [
            StandReminderChip(),
            StepStreakTile(),
            ZoneMinutesBar(),
          ],
        ),
        _HomeCardSection(
          title: 'Nutrition & body',
          children: const [
            MicronutrientGapChip(),
            SmoothedWeightTrendChip(),
          ],
        ),
        _HomeCardSection(
          title: 'Your cycle',
          children: const [
            CyclePhaseChip(),
            PeriodPredictionTile(),
            PmsPrepCard(),
            PeriodSymptomLogTile(),
          ],
        ),
        _HomeCardSection(
          title: 'Plan & adjustments',
          children: const [
            WeeklyPlanStrip(),
            SmartRescheduleBanner(),
            DayOfWeekSkipCard(),
            ReturnToExerciseCard(),
            InjuryWorkaroundBanner(),
            JetLagAdjustCard(),
            BusyWeekCompressedCard(),
          ],
        ),
        _HomeCardSection(
          title: 'Patterns & insights',
          children: const [
            WorkoutSleepCorrelationCard(),
            MacroPatternCallout(),
            StrainRecoveryMismatchCard(),
          ],
        ),
        _HomeCardSection(
          title: 'Social',
          children: const [
            FriendActivitySnippet(),
            GroupChallengeProgress(),
            AccountabilityPartnerNudge(),
          ],
        ),
        _HomeCardSection(
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
        // usage-cap upsell + premium-preview were dropped from home. Rendered
        // directly (no section header) since it's a lone self-hiding card.
        const ReferralGiftTile(),
        // Devices & setup minimized to ONLY the "Connect Health Connect /
        // Apple Health" prompt (MissingDataChip → activity gap), which unlocks
        // the empty steps/activity tiles. The wearable-battery / scale-sync /
        // tutorial / recalibration cards were dropped from home (user
        // feedback). Lone self-hiding card → no section header.
        const MissingDataChip(),
        _HomeCardSection(
          title: 'Fasting',
          children: const [
            FastZoneStrip(),
            FastStreakTile(),
          ],
        ),
        _HomeCardSection(
          title: 'Around your workout',
          children: const [
            PreWorkoutT30Card(),
            PreWorkoutWarmupCard(),
            PreWorkoutRpeChip(),
            DailyStrainTargetTile(),
            EquipmentPreflightBanner(),
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
        ),
      ],
    );
  }
}

/// A labeled group of contextual home cards whose header **only appears when
/// at least one child actually renders content** (issue 7).
///
/// The child cards each self-collapse to `SizedBox.shrink()` when their gate
/// fails, so a group can be entirely empty on any given day. Rather than
/// duplicate every card's gating logic, this wrapper measures the rendered
/// height of the card column after layout and shows/hides the header
/// accordingly — no orphan "RECOVERY" header floating over nothing.
class _HomeCardSection extends StatefulWidget {
  final String title;
  final List<Widget> children;
  const _HomeCardSection({required this.title, required this.children});

  @override
  State<_HomeCardSection> createState() => _HomeCardSectionState();
}

class _HomeCardSectionState extends State<_HomeCardSection> {
  final GlobalKey _bodyKey = GlobalKey();
  bool _hasContent = false;

  void _measure() {
    if (!mounted) return;
    final ctx = _bodyKey.currentContext;
    if (ctx == null) return;
    final ro = ctx.findRenderObject();
    final h = (ro is RenderBox && ro.hasSize) ? ro.size.height : 0.0;
    final has = h > 1.0;
    if (has != _hasContent) setState(() => _hasContent = has);
  }

  @override
  Widget build(BuildContext context) {
    // Re-measure after every layout so the header tracks the cards even when a
    // card self-collapses/expands from a provider change that doesn't rebuild
    // THIS widget. setState only fires on an actual flip, so there's no loop.
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    final c = ThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: _hasContent
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 16, 6),
                  child: Text(
                    widget.title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: c.textMuted,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Column(
          key: _bodyKey,
          mainAxisSize: MainAxisSize.min,
          children: widget.children,
        ),
      ],
    );
  }
}
