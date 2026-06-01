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
import 'cards/daily_strain_target_tile.dart';
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
import 'cards/one_rm_recompute_banner.dart';
import 'cards/plan_adjustments_card.dart';
import 'cards/planned_vs_actual_card.dart';
import 'cards/postworkout_mood_strip.dart';
import 'cards/postworkout_progress_photo_prompt.dart';
import 'cards/postworkout_tomorrow_adjust_card.dart';
import 'cards/recovery_countdown_tile.dart';
import 'cards/referral_gift_tile.dart';
import 'cards/return_to_exercise_card.dart';
import 'cards/rhr_delta_card.dart';
import 'cards/smoothed_weight_trend_chip.dart';
import 'cards/stand_reminder_chip.dart';
import 'cards/step_streak_tile.dart';
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
        _HomeCardSection(
          title: 'Plan & adjustments',
          children: const [
            WeeklyPlanStrip(),
            PlanAdjustmentsCard(),
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
        // usage-cap upsell + premium-preview were dropped from home. It now
        // sits under a lightweight self-hiding section header (issue 6) so it
        // isn't an orphaned, header-less card floating between groups. The
        // header only paints when the tile itself renders (the tile self-hides
        // when there's no referral offer), so a hidden tile leaves no orphan
        // header.
        _HomeCardSection(
          title: 'Refer & earn',
          children: const [
            ReferralGiftTile(),
          ],
        ),
        // #14 — the standalone "Connect Health Connect / Apple Health" preflight
        // (MissingDataChip) was removed from home; the user prefers reaching
        // these via the timeline + workout card. The MissingDataChip widget
        // file stays in place, unused.
        _HomeCardSection(
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
        _HomeCardSection(
          title: 'Around your workout',
          children: const [
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
        ),
      ],
      ),
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
  // Guards the post-frame measurement so it runs ONCE per build, not on every
  // frame. The old code re-armed addPostFrameCallback on every build, turning
  // each section into a per-frame layout probe (findRenderObject) — a major
  // source of home-scroll jank with ~11 sections live.
  bool _measureScheduled = false;

  void _measure() {
    _measureScheduled = false;
    if (!mounted) return;
    final ctx = _bodyKey.currentContext;
    if (ctx == null) return;
    final ro = ctx.findRenderObject();
    final h = (ro is RenderBox && ro.hasSize) ? ro.size.height : 0.0;
    final has = h > 1.0;
    if (has != _hasContent) setState(() => _hasContent = has);
  }

  void _scheduleMeasure() {
    if (_measureScheduled) return;
    _measureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  Widget build(BuildContext context) {
    // Measure once per build (de-duped via _measureScheduled) instead of
    // re-arming a post-frame layout probe on every frame. The child cards
    // self-collapse via their own providers; when one flips it rebuilds the
    // affected card subtree, the parent SliverList relayouts, and this build
    // runs again — re-arming exactly one measurement. setState only fires on an
    // actual content flip, so there's no rebuild loop.
    _scheduleMeasure();
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
