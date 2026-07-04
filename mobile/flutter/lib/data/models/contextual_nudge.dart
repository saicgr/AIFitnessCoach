/// `ContextualNudge` — a time-of-day + state-driven "do this now" hint that
/// renders as a stacked row inside the Coach hero card. Replaces the
/// `_HydrationResetRow` + `_BreakfastSlotRow` widgets that used to live inside
/// `HomeNutritionCard`.
///
/// Three layers compose a nudge:
///   * Identity — [NudgeId], used as the local-explainer dictionary key and
///     as the snooze key in SharedPreferences.
///   * Copy — [title], [body], [ctaLabel].
///   * Action — [ContextualNudgeAction], a discriminated descriptor consumed
///     by `CoachContextualNudgeRow` so the model stays free of `BuildContext`
///     and `WidgetRef`. The row dispatches by [ContextualNudgeActionKind].
///
/// Priority ordering is owned by `contextualNudgeProvider` (not encoded as a
/// field on the model — that would invite drift between two sources of truth).
library;

import 'package:flutter/foundation.dart';

/// Identity of a nudge — drives the local-explainer dictionary lookup and
/// the per-nudge snooze key. Names map 1:1 to keys in
/// `kNudgeExplainerStrings` in `coach_nudge_explainer_sheet.dart`.
enum NudgeId {
  // Core meal + hydration set.
  hydration,
  hydrationMidday,
  hydrationLateDay,
  breakfast,
  lunch,
  dinner,
  workout,
  windDown,
  // Pre-workout band.
  preWorkoutFuel,
  preWorkoutHydrate,
  preWorkoutWarmup,
  // Post-workout band.
  postWorkoutRefuel,
  // Mood / mental.
  moodCheckin,
  breathwork,
  gratitudePrompt,
  sleepStory,
  // Movement.
  hourlyStand,
  walkBreak,
  // Sleep.
  bedtimeWindow,
  blueLightCutoff,
  // Schedule / planning.
  tomorrowPreview,
  missedMealCatchup,
  // Fasting band.
  fastingApproachingEnd,
  fastingRefeed,
  fastingPreCountdown,
  fastingExtend,
  // Nutrition gaps.
  proteinGapMeal,
  fiberGapMeal,
  sodiumWatch,
  hiddenSugar,
  caffeineCutoff,
  lateSnackAlternative,
  // Gap 7 — opt-in tracker over-limit nudges (added sugar / caffeine / alcohol).
  sugarOverLimit,
  caffeineOverLimit,
  alcoholOverLimit,
  // Recovery / wearable advanced.
  readinessAlert,
  hrvDrop,
  rhrAnomaly,
  sleepEfficiencyDrop,
  // Cycle / hormonal.
  pmsPrep,
  ovulationPeak,
  periodPredict,
  periodSymptom,
  // Habit / gamification.
  habitStack,
  achievementNearUnlock,
  // Streak.
  streakAtRisk,
  // Goal / milestone.
  goalHalfway,
  goalSlipping,
  raceCountdown,
  // Travel.
  jetLag,
  hotelGym,
  // Social.
  friendActivity,
  partnerCheckin,
  // Subscription.
  usageBasedUpsell,
  // Educational.
  dailyLesson,
  weeklyDigest,
  discoveryInsight,
  // Wearable status.
  wearableBatteryLow,
  scaleSyncPrompt,
  // Cooking / pantry.
  leftoverCountdown,
  groceryGeofence,
  // Calendar.
  meetingHeavyLighter,
  freeWindowHold,
  // Misc.
  weighInReminder,
  birthday,
  appAnniversary,
  firstOfMonth,
  // Phase U/V/W — fasting, pre-workout, post-workout extensions.
  fastingPostFastGuidance,    // F3.91
  fastedTrainingWarning,      // F3.94
  fastDayProteinShift,        // F3.97
  fastBrokeEarlyAck,          // F3.98
  preWorkoutVariantSwap,      // F3.103
  preWorkoutMoodCheckin,      // F3.104
  preWorkoutCaffeineTiming,   // F3.105
  preWorkoutHydration,        // F3.106
  preWorkoutDurationPreview,  // F3.107
  preWorkoutFuelMacro,        // F3.109
  postWorkoutProteinGrams,    // F3.113
  postWorkoutPrChip,          // F3.115
  postWorkoutKudosLoop,       // F3.117
  // Phase B/C/D/E — recovery + circadian + nutrition + movement extensions.
  respRateAnomaly,            // F3.8
  remDeepLow,                 // F3.11
  skinTempShift,              // F3.13
  adaptiveCalorieAdjust,      // F3.15
  postWorkoutProtein,         // F3.17
  refeedDay,                  // F3.19
  activeCalorieRingClose,     // F3.25
  longSitWalk,                // F3.26
  chronotypeMorning,          // F3.31a
  chronotypeEvening,          // F3.31b
  // Phase F/G/H/I/J pack additions.
  ovulationStrengthWindow,    // F3.35
  pregnancyModeGuard,         // F3.37
  perimenopauseCue,           // F3.38
  hydrationHeat,              // F3.45
  electrolyteTile,            // F3.46
  kudosBadge,                 // F3.53
  // Gap 10 — ACWR spike: training load is overreaching (acute >> chronic).
  // Escalated when an active injury overlaps the loaded area.
  loadSpike,
  // Program encouragement — gentle, celebrate-first nudges tied to an active
  // program assignment (start-day welcome, halfway cheer, lapsed comeback).
  programFirstDay,
  programMidpoint,
  programComeback,
}

/// Priority tier for the SubCardRanker pyramid (F4).
///   1 — Health alerts (anomalies, illness)
///   2 — Time-sensitive (refuel window, bedtime, pre-workout)
///   3 — Streak-at-risk (loss aversion)
///   4 — Habit nudges (water, meals, stand)
///   5 — Educational (passive learning)
///   6 — Social (lowest perishability)
enum NudgePriorityTier {
  healthAlert,
  timeSensitive,
  streakRisk,
  habit,
  educational,
  social,
}

/// Coarse category used to apply user-override re-weighting from AI Settings.
/// Maps roughly 1:1 onto the priority tiers but stays a separate enum so we
/// can re-rank without redefining priority entirely.
enum NudgeCategory {
  healthAlert,
  timeSensitive,
  streak,
  habit,
  educational,
  social,
}

/// Action verbs the row knows how to dispatch. Keep this list small — every
/// new kind requires a switch arm in `CoachContextualNudgeRow`.
enum ContextualNudgeActionKind {
  /// Quick-log hydration. `args['amountMl']` (int) is required.
  logHydration,

  /// Open the meal-log sheet pre-filled to a meal slot.
  /// `args['mealType']` is one of `breakfast | lunch | dinner | snack`.
  quickLogMeal,

  /// Start today's scheduled workout — navigates to /workout/active.
  startWorkout,

  /// Open the evening journal flow (sleep wind-down). Currently routes to
  /// `/journal` — placeholder until the journal feature ships; until then
  /// it falls back to `/chat`.
  openJournal,

  /// Open the mood-checkin sheet.
  logMood,

  /// Start an in-app breathwork session (4-7-8 / box-breathing).
  startBreathwork,

  /// Tomorrow's workout preview overlay.
  openTomorrowPreview,

  /// Open the daily-lesson reader.
  openDailyLesson,

  /// Open AI Settings (used by usage-based-upsell, AI Coach 3-dot menu).
  openAiSettings,

  /// Generic deep-link CTA. `args['route']` required.
  navigateRoute,

  /// No-op CTA — just dismisses the card. Used for informational cards
  /// where the only action is dismissal.
  acknowledge,
}

/// Discriminated CTA descriptor. Kept as a sealed-style data class instead of
/// a sealed class so it survives the codebase's `build_runner` ban
/// (`feedback`: project_codegen_gotcha — no `.g.dart` regeneration allowed).
@immutable
class ContextualNudgeAction {
  final ContextualNudgeActionKind kind;
  final Map<String, dynamic> args;

  const ContextualNudgeAction({
    required this.kind,
    this.args = const {},
  });

  /// Hydration quick-log. Mirrors the call shape used by the original
  /// `_HydrationResetRow.onLog16oz` (~473 ml rounded to 500 ml so the
  /// 250-ml-per-cup ledger lands on whole cups).
  static const ContextualNudgeAction logHydration16oz = ContextualNudgeAction(
    kind: ContextualNudgeActionKind.logHydration,
    args: {'amountMl': 500},
  );

  /// Start today's scheduled workout.
  static const ContextualNudgeAction startWorkout = ContextualNudgeAction(
    kind: ContextualNudgeActionKind.startWorkout,
  );

  /// Open the evening journal flow.
  static const ContextualNudgeAction openJournal = ContextualNudgeAction(
    kind: ContextualNudgeActionKind.openJournal,
  );

  /// Meal-slot quick-log. Factory (not const) — the meal-type arg has to
  /// flow through at runtime; a const constructor can't capture a parameter
  /// into its `args` map.
  factory ContextualNudgeAction.mealSlot(String mealType) {
    return ContextualNudgeAction(
      kind: ContextualNudgeActionKind.quickLogMeal,
      args: {'mealType': mealType},
    );
  }
}

/// The nudge itself. Fields are presentation-ready strings — the provider has
/// already resolved server overrides + locale before constructing this.
@immutable
class ContextualNudge {
  final NudgeId id;

  /// Emoji used as the leading glyph. Keeping this as a string preserves
  /// parity with the existing rows (`🍳`, `💧`) and avoids loading a new
  /// icon font for six tiny glyphs.
  final String icon;

  /// One short line — the bold first row.
  final String title;

  /// Single-line subtext. Caller is responsible for keeping it short; the
  /// row clamps with `softWrap: false` + ellipsis.
  final String body;

  /// CTA pill label, e.g. "Log 16oz", "Quick log", "Start".
  final String ctaLabel;

  /// What happens when the user taps the CTA pill.
  final ContextualNudgeAction action;

  /// Optional 2–3 sentence explainer the server returned for this nudge.
  /// When null, the row falls back to the local string keyed by [id].
  final String? explainerOverride;

  /// Optional concrete "why this fired" reason specific to THIS user's data
  /// (e.g. "You flagged right-knee pain — 2 exercises were swapped today").
  /// When set, the explainer modal shows this instead of the generic local
  /// trigger string, so the card never presents a real, data-driven nudge with
  /// boilerplate copy.
  final String? whyOverride;

  /// Priority tier — drives ordering inside the F4 SubCardRanker pyramid.
  /// Default `habit` if a nudge omits it (back-compat with older call sites).
  final NudgePriorityTier priorityTier;

  /// Coarse category used by AI Settings user-override re-weighting.
  final NudgeCategory category;

  /// When this nudge stops being relevant. Used by the ranker to break
  /// ties within a priority tier (sooner-perishing first). For non-
  /// perishable nudges (educational, social, etc.) use `DateTime` of end-of-
  /// day or far-future.
  final DateTime? perishesAt;

  /// Per-day de-duplication key. Defaults to `id.name`. Set this explicitly
  /// when the same nudge id can fire with multiple distinct dedup contexts
  /// (e.g. `protein_gap_meal_breakfast` vs `protein_gap_meal_lunch`).
  final String? dedupKey;

  const ContextualNudge({
    required this.id,
    required this.icon,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.action,
    this.explainerOverride,
    this.whyOverride,
    this.priorityTier = NudgePriorityTier.habit,
    this.category = NudgeCategory.habit,
    this.perishesAt,
    this.dedupKey,
  });

  String get effectiveDedupKey => dedupKey ?? id.name;

  ContextualNudge copyWith({
    String? icon,
    String? title,
    String? body,
    String? ctaLabel,
    ContextualNudgeAction? action,
    String? explainerOverride,
    String? whyOverride,
    NudgePriorityTier? priorityTier,
    NudgeCategory? category,
    DateTime? perishesAt,
    String? dedupKey,
  }) {
    return ContextualNudge(
      id: id,
      icon: icon ?? this.icon,
      title: title ?? this.title,
      body: body ?? this.body,
      ctaLabel: ctaLabel ?? this.ctaLabel,
      action: action ?? this.action,
      explainerOverride: explainerOverride ?? this.explainerOverride,
      whyOverride: whyOverride ?? this.whyOverride,
      priorityTier: priorityTier ?? this.priorityTier,
      category: category ?? this.category,
      perishesAt: perishesAt ?? this.perishesAt,
      dedupKey: dedupKey ?? this.dedupKey,
    );
  }
}
