/// R6 — explicit ranking + a hard per-day cap for Home's contextual card stack.
///
/// ## Why this exists
///
/// `ExtendedHomeCardsStack` mounts every contextual card unconditionally and
/// lets each one self-collapse to `SizedBox.shrink()` when its gate fails. That
/// makes the stack cheap to *evaluate*, but nothing bounded how many gates fire
/// on the same day — so on a busy day Home simply grew, and nobody decided that
/// it should. Order was source order, which is not a ranking: it encodes when a
/// card was written, not how much it matters today.
///
/// Both competitors were punished for exactly this. Samsung Health's loudest
/// complaint was unhideable content dominating the screen; Google Health's was
/// oversized tiles and dead space. This file is the decision layer that keeps
/// Zealova out of that failure mode: every card declares a **priority** and a
/// **category**, the day's eligible set is ranked by an explicit total order,
/// and only [kContextualCardDailyCap] of them may render.
///
/// ## Contract
///
/// * **Explicit + inspectable** — [kContextualCardManifest] is the single list
///   of every contextual card Home may show, with its priority and category.
///   Nothing ranks by source order any more.
/// * **Deterministic** — [planContextualCards] is a pure function with a total
///   ordering (priority desc, then manifest index asc). The same eligible set
///   always yields the same visible set in the same order, on every rebuild.
/// * **Never silently truncated** — the plan carries [ContextualCardPlan
///   .overflowCount] so the stack can render an "N more" affordance. A bounded
///   surface that doesn't say it is bounded reads as "we showed you
///   everything", which is a lie.
/// * **Dismiss-aware** — a dismissed card is not eligible, so it does not
///   consume a cap slot; the next-ranked card takes it.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The group a contextual card belongs to. Mirrors the section headers in
/// `extended_home_cards_stack.dart` so the cap's fairness rule
/// ([kContextualCardMaxPerCategory]) matches what the user actually sees.
enum ContextualCardCategory {
  activity,
  nutritionBody,
  plan,
  patterns,
  social,
  milestone,
  fasting,
}

/// Priority tiers. Higher wins. A card's priority is `tier + delta`, where the
/// small delta orders cards *within* a tier — so the tier stays readable at a
/// glance and re-ranking inside a tier can never leapfrog a tier boundary.
///
/// The tiers answer one question: **what does the user lose by not seeing this
/// card today?**
abstract final class ContextualCardTier {
  /// Not seeing it risks injury or re-injury. Never loses a slot.
  static const int safety = 900;

  /// Only true today — a live fast, a jet-lag day, a birthday, a plan change
  /// that applies to this session. Tomorrow it is stale or gone.
  static const int timeSensitive = 700;

  /// Asks for one specific action the user could take today.
  static const int actionable = 500;

  /// Explains something the user did not know. Keeps just as well tomorrow.
  static const int insight = 300;

  /// Reports a number trending. Purely informational.
  static const int progress = 200;

  /// Feels good, changes nothing.
  static const int celebration = 100;
}

/// Stable ids for every contextual card. These are the join key between the
/// manifest and the widget slots — never derive an id from a runtime type name
/// (obfuscated release builds rename types).
abstract final class ContextualCardIds {
  static const String standReminder = 'stand_reminder';
  static const String stepStreak = 'step_streak';
  static const String zoneMinutes = 'zone_minutes';
  static const String smoothedWeightTrend = 'smoothed_weight_trend';
  static const String weeklyPlanStrip = 'weekly_plan_strip';
  static const String staleScoreNudge = 'stale_score_nudge';
  static const String planAdjustments = 'plan_adjustments';
  static const String returnToExercise = 'return_to_exercise';
  static const String injuryWorkaround = 'injury_workaround';
  static const String jetLagAdjust = 'jet_lag_adjust';
  static const String busyWeekCompressed = 'busy_week_compressed';
  static const String workoutSleepCorrelation = 'workout_sleep_correlation';
  static const String macroPatternCallout = 'macro_pattern_callout';
  static const String friendActivity = 'friend_activity';
  static const String groupChallengeProgress = 'group_challenge_progress';
  static const String accountabilityPartnerNudge = 'accountability_partner_nudge';
  static const String appAnniversary = 'app_anniversary';
  static const String workoutMilestone = 'workout_milestone';
  static const String bodyCompMilestone = 'body_comp_milestone';
  static const String birthday = 'birthday';
  static const String firstOfMonth = 'first_of_month';
  static const String weighInDay = 'weigh_in_day';
  static const String fastZoneStrip = 'fast_zone_strip';
  static const String fastStreak = 'fast_streak';
}

/// One contextual card's ranking declaration.
@immutable
class ContextualCardSpec {
  /// Stable id from [ContextualCardIds].
  final String id;

  /// `ContextualCardTier.x + delta`. Higher wins.
  final int priority;

  final ContextualCardCategory category;

  const ContextualCardSpec({
    required this.id,
    required this.priority,
    required this.category,
  });
}

/// Every contextual card Home may render, with its rank. **This list is the
/// ranking** — the order cards appear in the widget tree is layout, not
/// priority.
///
/// Adding a card to `ExtendedHomeCardsStack` without adding it here means it is
/// never eligible (its slot has no rank), which is the intended failure mode:
/// a new card must argue for its priority, not slip in by being appended.
const List<ContextualCardSpec> kContextualCardManifest = <ContextualCardSpec>[
  // ── Activity ────────────────────────────────────────────────────────────
  ContextualCardSpec(
    id: ContextualCardIds.standReminder,
    // Actionable and it expires within the hour, but the ask is trivial.
    priority: ContextualCardTier.actionable + 10,
    category: ContextualCardCategory.activity,
  ),
  ContextualCardSpec(
    id: ContextualCardIds.stepStreak,
    priority: ContextualCardTier.progress + 20,
    category: ContextualCardCategory.activity,
  ),
  ContextualCardSpec(
    id: ContextualCardIds.zoneMinutes,
    priority: ContextualCardTier.progress + 10,
    category: ContextualCardCategory.activity,
  ),

  // ── Nutrition & body ────────────────────────────────────────────────────
  ContextualCardSpec(
    id: ContextualCardIds.smoothedWeightTrend,
    priority: ContextualCardTier.progress + 30,
    category: ContextualCardCategory.nutritionBody,
  ),

  // ── Plan & adjustments ──────────────────────────────────────────────────
  ContextualCardSpec(
    id: ContextualCardIds.weeklyPlanStrip,
    priority: ContextualCardTier.actionable + 20,
    category: ContextualCardCategory.plan,
  ),
  ContextualCardSpec(
    id: ContextualCardIds.staleScoreNudge,
    priority: ContextualCardTier.actionable + 40,
    category: ContextualCardCategory.plan,
  ),
  ContextualCardSpec(
    id: ContextualCardIds.planAdjustments,
    // Changes what today's session is. Highest non-safety rank.
    priority: ContextualCardTier.timeSensitive + 40,
    category: ContextualCardCategory.plan,
  ),
  ContextualCardSpec(
    id: ContextualCardIds.returnToExercise,
    priority: ContextualCardTier.timeSensitive + 30,
    category: ContextualCardCategory.plan,
  ),
  ContextualCardSpec(
    id: ContextualCardIds.injuryWorkaround,
    // The only safety-tier card: training around an injury outranks everything.
    priority: ContextualCardTier.safety,
    category: ContextualCardCategory.plan,
  ),
  ContextualCardSpec(
    id: ContextualCardIds.jetLagAdjust,
    priority: ContextualCardTier.timeSensitive + 20,
    category: ContextualCardCategory.plan,
  ),
  ContextualCardSpec(
    id: ContextualCardIds.busyWeekCompressed,
    priority: ContextualCardTier.timeSensitive + 10,
    category: ContextualCardCategory.plan,
  ),

  // ── Patterns & insights ─────────────────────────────────────────────────
  ContextualCardSpec(
    id: ContextualCardIds.workoutSleepCorrelation,
    priority: ContextualCardTier.insight + 20,
    category: ContextualCardCategory.patterns,
  ),
  ContextualCardSpec(
    id: ContextualCardIds.macroPatternCallout,
    priority: ContextualCardTier.insight + 10,
    category: ContextualCardCategory.patterns,
  ),

  // ── Social ──────────────────────────────────────────────────────────────
  ContextualCardSpec(
    id: ContextualCardIds.accountabilityPartnerNudge,
    // A human is waiting on a reply — that is an ask, not a feed item.
    priority: ContextualCardTier.actionable + 15,
    category: ContextualCardCategory.social,
  ),
  ContextualCardSpec(
    id: ContextualCardIds.groupChallengeProgress,
    priority: ContextualCardTier.actionable + 5,
    category: ContextualCardCategory.social,
  ),
  ContextualCardSpec(
    id: ContextualCardIds.friendActivity,
    priority: ContextualCardTier.celebration + 5,
    category: ContextualCardCategory.social,
  ),

  // ── Milestones ──────────────────────────────────────────────────────────
  ContextualCardSpec(
    id: ContextualCardIds.birthday,
    // Fires on exactly one day a year. Suppressed today == suppressed forever,
    // so it sits at the bottom of the time-sensitive tier rather than in
    // celebration, where a step streak could outrank it.
    priority: ContextualCardTier.timeSensitive + 1,
    category: ContextualCardCategory.milestone,
  ),
  ContextualCardSpec(
    id: ContextualCardIds.weighInDay,
    priority: ContextualCardTier.actionable + 30,
    category: ContextualCardCategory.milestone,
  ),
  ContextualCardSpec(
    id: ContextualCardIds.workoutMilestone,
    priority: ContextualCardTier.celebration + 40,
    category: ContextualCardCategory.milestone,
  ),
  ContextualCardSpec(
    id: ContextualCardIds.bodyCompMilestone,
    priority: ContextualCardTier.celebration + 30,
    category: ContextualCardCategory.milestone,
  ),
  ContextualCardSpec(
    id: ContextualCardIds.appAnniversary,
    priority: ContextualCardTier.celebration + 20,
    category: ContextualCardCategory.milestone,
  ),
  ContextualCardSpec(
    id: ContextualCardIds.firstOfMonth,
    priority: ContextualCardTier.celebration + 10,
    category: ContextualCardCategory.milestone,
  ),

  // ── Fasting ─────────────────────────────────────────────────────────────
  ContextualCardSpec(
    id: ContextualCardIds.fastZoneStrip,
    // Only meaningful while a fast is actually running.
    priority: ContextualCardTier.timeSensitive + 5,
    category: ContextualCardCategory.fasting,
  ),
  ContextualCardSpec(
    id: ContextualCardIds.fastStreak,
    priority: ContextualCardTier.progress + 15,
    category: ContextualCardCategory.fasting,
  ),
];

/// How many contextual cards may render on Home on one day.
///
/// **Five.** The reasoning, so the next person can argue with the number rather
/// than guess at it:
///
/// * The contextual stack is the *tail* of Home. Above it already sit the
///   header, the hero workout deck, the metric deck, the section tiles and the
///   timeline. Everything here is a bonus, not the product.
/// * Five cards at ~72–110pt each is roughly one extra screen of scroll on a
///   6.1" device. Six or more and the tail becomes longer than the content it
///   is appended to — the exact shape of the Samsung Health complaint
///   ("Insights cannot be hidden and is the biggest thing on screen").
/// * Five is also about the limit of what someone actually reads before
///   thumb-flicking past. Cards beyond it are not "shown"; they are scrolled
///   over, which costs attention and returns nothing.
///
/// This is a cap on what *renders*, not on what is evaluated: gates stay cheap
/// and keep running, so the day's full eligible set is always known and the
/// overflow can be surfaced honestly.
const int kContextualCardDailyCap = 5;

/// At most this many of the [kContextualCardDailyCap] slots may come from one
/// [ContextualCardCategory].
///
/// Two. Without it, one chatty category (six milestone cards can all fire on a
/// birthday that is also the first of the month) takes the entire day's budget
/// and Home reads as a single-topic feed. With it, a capped day always shows at
/// least three different kinds of thing. Applied *before* the global cap, so it
/// is part of the same deterministic pass.
const int kContextualCardMaxPerCategory = 2;

/// The outcome of ranking one day's eligible cards.
@immutable
class ContextualCardPlan {
  /// Ids that may render, in ranked order (highest priority first).
  final List<String> visible;

  /// Eligible ids that lost to the cap, in ranked order. Empty when
  /// [showingAll] is true — see [overflowCount] for the honest number.
  final List<String> suppressed;

  /// How many eligible cards the cap holds back, regardless of [showingAll].
  /// This is what the "N more" affordance reports; it stays stable when the
  /// user expands, so the affordance can flip to "show less" without lying.
  final int overflowCount;

  /// True when the user asked to see past the cap this session.
  final bool showingAll;

  final Set<String> _visibleSet;

  ContextualCardPlan({
    required this.visible,
    required this.suppressed,
    required this.overflowCount,
    required this.showingAll,
  }) : _visibleSet = visible.toSet();

  bool isVisible(String id) => _visibleSet.contains(id);

  /// True when at least one eligible card is being held back right now.
  bool get hasSuppressedCards => overflowCount > 0;
}

/// Ranks [eligible] and applies the caps. Pure and total-ordered: identical
/// inputs always produce an identical plan, so Home's constant rebuilds can
/// never reshuffle the stack.
///
/// [eligible] is the set of ids whose gate fired *and* that are not dismissed;
/// [dismissed] is subtracted as well, so a card dismissed while still eligible
/// frees its slot for the next-ranked card instead of holding it empty.
ContextualCardPlan planContextualCards({
  required Set<String> eligible,
  Set<String> dismissed = const <String>{},
  List<ContextualCardSpec> manifest = kContextualCardManifest,
  int cap = kContextualCardDailyCap,
  int maxPerCategory = kContextualCardMaxPerCategory,
  bool showAll = false,
}) {
  // Index-carrying candidates: the manifest index is the tiebreak, which makes
  // the comparator a *total* order (no reliance on sort stability).
  final candidates = <({int index, ContextualCardSpec spec})>[];
  for (var i = 0; i < manifest.length; i++) {
    final spec = manifest[i];
    if (!eligible.contains(spec.id)) continue;
    if (dismissed.contains(spec.id)) continue;
    candidates.add((index: i, spec: spec));
  }

  candidates.sort((a, b) {
    final byPriority = b.spec.priority.compareTo(a.spec.priority);
    if (byPriority != 0) return byPriority;
    return a.index.compareTo(b.index);
  });

  final capped = <String>[];
  final overflow = <String>[];
  final perCategory = <ContextualCardCategory, int>{};
  for (final c in candidates) {
    final used = perCategory[c.spec.category] ?? 0;
    final fits = capped.length < cap && used < maxPerCategory;
    if (fits) {
      capped.add(c.spec.id);
      perCategory[c.spec.category] = used + 1;
    } else {
      overflow.add(c.spec.id);
    }
  }

  return ContextualCardPlan(
    visible: showAll
        ? List<String>.unmodifiable(candidates.map((c) => c.spec.id))
        : List<String>.unmodifiable(capped),
    suppressed: showAll
        ? const <String>[]
        : List<String>.unmodifiable(overflow),
    overflowCount: overflow.length,
    showingAll: showAll,
  );
}

/// What the stack knows about today's cards: which gates fired, which the user
/// dismissed, and whether they asked to see past the cap.
@immutable
class ContextualCardVisibilityState {
  /// Ids whose card actually produced content this frame. Reported by the card
  /// slots themselves — the gates live inside the cards, and duplicating 24
  /// gating conditions here would rot the moment one of them changed.
  final Set<String> eligible;

  /// Ids the user explicitly dismissed this session.
  final Set<String> dismissed;

  /// Set when the user taps the "N more" affordance.
  final bool showAll;

  const ContextualCardVisibilityState({
    this.eligible = const <String>{},
    this.dismissed = const <String>{},
    this.showAll = false,
  });

  ContextualCardVisibilityState copyWith({
    Set<String>? eligible,
    Set<String>? dismissed,
    bool? showAll,
  }) {
    return ContextualCardVisibilityState(
      eligible: eligible ?? this.eligible,
      dismissed: dismissed ?? this.dismissed,
      showAll: showAll ?? this.showAll,
    );
  }
}

class ContextualCardVisibility extends Notifier<ContextualCardVisibilityState> {
  @override
  ContextualCardVisibilityState build() => const ContextualCardVisibilityState();

  /// Called by a card slot when its child starts or stops producing content.
  /// No-ops when nothing changed, so the measure → report → rebuild → measure
  /// path settles after one pass instead of looping.
  void reportEligible(String id, bool isEligible) {
    final has = state.eligible.contains(id);
    if (has == isEligible) return;
    final next = Set<String>.of(state.eligible);
    if (isEligible) {
      next.add(id);
    } else {
      next.remove(id);
    }
    state = state.copyWith(eligible: next);
  }

  /// Records an explicit dismissal. Cards that hide themselves on dismiss also
  /// stop reporting eligible, so this is belt-and-braces for cards that keep
  /// rendering something after being dismissed.
  void dismiss(String id) {
    if (state.dismissed.contains(id)) return;
    state = state.copyWith(dismissed: {...state.dismissed, id});
  }

  /// Toggles the "N more" expansion. Session-scoped on purpose: expanding is a
  /// one-off "show me the rest", not a preference that quietly unbounds Home
  /// forever.
  void toggleShowAll() => state = state.copyWith(showAll: !state.showAll);
}

final contextualCardVisibilityProvider =
    NotifierProvider<ContextualCardVisibility, ContextualCardVisibilityState>(
  ContextualCardVisibility.new,
);

/// Today's ranked, capped plan. Recomputes only when the visibility state
/// actually changes — not per frame — so the debug log below fires on real
/// transitions.
final contextualCardPlanProvider = Provider<ContextualCardPlan>((ref) {
  final s = ref.watch(contextualCardVisibilityProvider);
  final plan = planContextualCards(
    eligible: s.eligible,
    dismissed: s.dismissed,
    showAll: s.showAll,
  );
  if (kDebugMode && s.eligible.isNotEmpty) {
    debugPrint(
      '🔍 [ContextualCards] eligible=${s.eligible.length} '
      'visible=${plan.visible} suppressed=${plan.suppressed} '
      '(cap=$kContextualCardDailyCap, perCategory=$kContextualCardMaxPerCategory)',
    );
  }
  return plan;
});
