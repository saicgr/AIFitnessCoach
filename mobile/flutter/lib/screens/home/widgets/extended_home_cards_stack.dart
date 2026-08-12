/// Extended home cards stack — mounts the contextual cards added in the
/// home-screen overhaul (Phases B–W). Each card self-collapses to
/// `SizedBox.shrink()` when its gating condition fails (no signal, wrong
/// time-of-day, feature disabled), so this Column is cheap to evaluate
/// even though it lists every card every build.
///
/// Mounted as a single `SliverToBoxAdapter` after the legacy tile stack
/// in `home_screen.dart`. Each card decides for itself whether it *could*
/// render; [ContextualCardSlot] + `contextual_card_rank_provider.dart` decide
/// how many of the ones that could actually *do* (R6).
///
/// Why a flat Column rather than the legacy TileType registry: adding
/// 80 TileType entries (× 4 switch statements: layout editor, tile
/// picker, preview mock, builder) is 320 case additions, each a chance
/// to break the existing My-Space reorder UX. The self-collapse model
/// matches what CalibrationBanner / SetupChecklistCard / StackedBanner
/// already do — invisible until they have a reason to render.
///
/// ## R6 — ranking and cap
///
/// Self-collapsing kept the stack cheap but left it *unbounded*: nothing
/// stopped ten gates firing on the same day, and order was source order (when
/// a card was written), not priority. Now:
///
/// * every card is wrapped in a [ContextualCardSlot] carrying its id from
///   `ContextualCardIds`; the id's rank lives in `kContextualCardManifest`,
/// * the slot reports whether its child produced content, and only the
///   top `kContextualCardDailyCap` ranked cards are shown,
/// * everything held back is counted and surfaced by
///   [ContextualCardOverflowNotice] at the foot of the stack — a bounded
///   surface that doesn't say it is bounded reads as "we showed you
///   everything".
///
/// A suppressed slot is `Offstage`, not unmounted: it is laid out (so its gate
/// keeps reporting, and a card that goes stale gives its slot back the same
/// frame) but paints nothing, occupies no space, takes no hit tests and is
/// excluded from semantics. Unmounting instead would blind the ranking to the
/// gate it just hid, and the freed slot could never be re-filled correctly.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../providers/contextual_card_rank_provider.dart';
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

/// Wraps one contextual card so the ranking can (a) learn whether the card's
/// own gate fired and (b) hold it back when it loses the day's cap.
///
/// Eligibility is *measured*, not re-derived: the gates live inside the cards
/// (24 of them, each reading its own providers), and mirroring those conditions
/// here would be a second source of truth that rots the first time one changes.
/// The slot lays the card out, reads the rendered height once per build — the
/// same technique `SelfHidingCardSection` already uses to hide orphan headers —
/// and reports "produced content" / "collapsed" to
/// [contextualCardVisibilityProvider].
///
/// Dismissal needs no special handling: a dismissed card collapses itself, the
/// slot measures zero, and the freed slot goes to the next-ranked card. Cards
/// that also want to be explicitly recorded can call
/// `ContextualCardVisibility.dismiss`.
class ContextualCardSlot extends ConsumerStatefulWidget {
  /// Stable id from `ContextualCardIds`. Must exist in
  /// `kContextualCardManifest` — an unranked id is never visible, which is the
  /// intended failure mode for a card added without arguing for its priority.
  final String id;

  final Widget child;

  const ContextualCardSlot({
    super.key,
    required this.id,
    required this.child,
  });

  @override
  ConsumerState<ContextualCardSlot> createState() => _ContextualCardSlotState();
}

class _ContextualCardSlotState extends ConsumerState<ContextualCardSlot> {
  final GlobalKey _probeKey = GlobalKey();

  /// Guards the post-frame measurement so it runs once per build rather than
  /// re-arming a layout probe every frame (the jank pattern
  /// `SelfHidingCardSection` had to fix).
  bool _measureScheduled = false;

  /// Last value handed to the notifier. `null` until the first measurement, so
  /// the very first report always goes through.
  bool? _reported;

  void _measure() {
    _measureScheduled = false;
    if (!mounted) return;
    final ctx = _probeKey.currentContext;
    if (ctx == null) return;
    final ro = ctx.findRenderObject();
    final height = (ro is RenderBox && ro.hasSize) ? ro.size.height : 0.0;
    // >1 rather than >0: a collapsed card is SizedBox.shrink (0), and hairline
    // dividers inside an otherwise-empty card must not read as content.
    final produced = height > 1.0;
    if (produced == _reported) return;
    _reported = produced;
    ref
        .read(contextualCardVisibilityProvider.notifier)
        .reportEligible(widget.id, produced);
  }

  void _scheduleMeasure() {
    if (_measureScheduled) return;
    _measureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  Widget build(BuildContext context) {
    _scheduleMeasure();
    final visible = ref.watch(
      contextualCardPlanProvider.select((p) => p.isVisible(widget.id)),
    );

    // Offstage lays the child out (so the gate keeps being observed) while
    // painting nothing, taking zero height in the parent Column, failing hit
    // tests and dropping out of the semantics tree. The probe key sits INSIDE
    // the Offstage, on the child's own box — the Offstage itself reports zero
    // height to its parent, which is exactly what keeps a fully-suppressed
    // SelfHidingCardSection from painting an orphan header.
    return Offstage(
      offstage: !visible,
      child: Column(
        key: _probeKey,
        mainAxisSize: MainAxisSize.min,
        children: [widget.child],
      ),
    );
  }
}

/// "N more" affordance for cards the cap held back.
///
/// Renders nothing when nothing was suppressed. When something was, it says how
/// many and lets the user open them — truncating silently would read as "that
/// is everything we have for you today", which is false.
class ContextualCardOverflowNotice extends ConsumerWidget {
  const ContextualCardOverflowNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(contextualCardPlanProvider);
    if (!plan.hasSuppressedCards) return const SizedBox.shrink();

    final c = ThemeColors.of(context);
    final l10n = AppLocalizations.of(context);
    final label = plan.showingAll
        ? l10n.foodAnalysisResultShowLess
        // NOT `homeScreenUi1MoreTiles` ("+N more tiles") — this notice renders
        // directly under the metric TILE grid, where "more tiles" reads as
        // more metrics rather than more coaching cards.
        : l10n.contextualCardsMoreSuggestions(plan.overflowCount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => ref
              .read(contextualCardVisibilityProvider.notifier)
              .toggleShowAll(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: c.textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  plan.showingAll ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: c.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ExtendedHomeCardsStack extends ConsumerWidget {
  const ExtendedHomeCardsStack({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Each card still self-collapses to SizedBox.shrink when its gate fails,
    // and is additionally ranked + capped by its ContextualCardSlot (R6).
    // They're grouped under labeled, SELF-HIDING section headers (issue 7):
    // a header only paints when ≥1 card in its group actually renders, so an
    // empty group — or a group whose cards all lost the cap — shows nothing
    // (no orphan header). The Timeline is NOT here — home_screen appends it as
    // the very last card after this whole stack.
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
            ContextualCardSlot(
              id: ContextualCardIds.standReminder,
              child: StandReminderChip(),
            ),
            ContextualCardSlot(
              id: ContextualCardIds.stepStreak,
              child: StepStreakTile(),
            ),
            ContextualCardSlot(
              id: ContextualCardIds.zoneMinutes,
              child: ZoneMinutesBar(),
            ),
          ],
        ),
        SelfHidingCardSection(
          title: 'Nutrition & body',
          children: const [
            // MicronutrientGapChip removed from Home — micronutrients live in
            // the Nutrition tab (micros_detail_screen / nutrient_explorer).
            ContextualCardSlot(
              id: ContextualCardIds.smoothedWeightTrend,
              child: SmoothedWeightTrendChip(),
            ),
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
            ContextualCardSlot(
              id: ContextualCardIds.weeklyPlanStrip,
              child: WeeklyPlanStrip(),
            ),
            ContextualCardSlot(
              id: ContextualCardIds.staleScoreNudge,
              child: StaleScoreNudgeCard(),
            ),
            ContextualCardSlot(
              id: ContextualCardIds.planAdjustments,
              child: PlanAdjustmentsCard(),
            ),
            ContextualCardSlot(
              id: ContextualCardIds.returnToExercise,
              child: ReturnToExerciseCard(),
            ),
            ContextualCardSlot(
              id: ContextualCardIds.injuryWorkaround,
              child: InjuryWorkaroundBanner(),
            ),
            ContextualCardSlot(
              id: ContextualCardIds.jetLagAdjust,
              child: JetLagAdjustCard(),
            ),
            ContextualCardSlot(
              id: ContextualCardIds.busyWeekCompressed,
              child: BusyWeekCompressedCard(),
            ),
          ],
        ),
        SelfHidingCardSection(
          title: 'Patterns & insights',
          children: const [
            ContextualCardSlot(
              id: ContextualCardIds.workoutSleepCorrelation,
              child: WorkoutSleepCorrelationCard(),
            ),
            ContextualCardSlot(
              id: ContextualCardIds.macroPatternCallout,
              child: MacroPatternCallout(),
            ),
          ],
        ),
        SelfHidingCardSection(
          title: 'Social',
          children: const [
            ContextualCardSlot(
              id: ContextualCardIds.friendActivity,
              child: FriendActivitySnippet(),
            ),
            ContextualCardSlot(
              id: ContextualCardIds.groupChallengeProgress,
              child: GroupChallengeProgress(),
            ),
            ContextualCardSlot(
              id: ContextualCardIds.accountabilityPartnerNudge,
              child: AccountabilityPartnerNudge(),
            ),
          ],
        ),
        SelfHidingCardSection(
          title: 'Milestones',
          children: const [
            ContextualCardSlot(
              id: ContextualCardIds.appAnniversary,
              child: AppAnniversaryCard(),
            ),
            ContextualCardSlot(
              id: ContextualCardIds.workoutMilestone,
              child: WorkoutMilestoneCard(),
            ),
            ContextualCardSlot(
              id: ContextualCardIds.bodyCompMilestone,
              child: BodyCompMilestoneCard(),
            ),
            ContextualCardSlot(
              id: ContextualCardIds.birthday,
              child: BirthdayCard(),
            ),
            ContextualCardSlot(
              id: ContextualCardIds.firstOfMonth,
              child: FirstOfMonthCard(),
            ),
            ContextualCardSlot(
              id: ContextualCardIds.weighInDay,
              child: WeighInDayChip(),
            ),
          ],
        ),
        // Membership slimmed to just the referral tile (user feedback) — the
        // usage-cap upsell + premium-preview were dropped from home. It now
        // sits under a lightweight self-hiding section header (issue 6) so it
        // isn't an orphaned, header-less card floating between groups. The
        // header only paints when the tile itself renders (the tile self-hides
        // when there's no referral offer), so a hidden tile leaves no orphan
        // header.
        // Refer & earn RELOCATED off Home (→ You / Settings) per the Signature
        // v2 lean-home decision — it's promotional, not glanceable home content.
        // The ReferralGiftTile widget stays in place for its new home.
        // #14 — the standalone "Connect Health Connect / Apple Health" preflight
        // (MissingDataChip) was removed from home; the user prefers reaching
        // these via the timeline + workout card. The MissingDataChip widget
        // file stays in place, unused.
        SelfHidingCardSection(
          title: 'Fasting',
          children: const [
            ContextualCardSlot(
              id: ContextualCardIds.fastZoneStrip,
              child: FastZoneStrip(),
            ),
            ContextualCardSlot(
              id: ContextualCardIds.fastStreak,
              child: FastStreakTile(),
            ),
          ],
        ),
        // Says how many contextual cards the cap is holding back today, and
        // opens them on tap. Renders nothing when nothing was suppressed.
        const ContextualCardOverflowNotice(),
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
