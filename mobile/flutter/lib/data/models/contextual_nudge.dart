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
  hydration,
  breakfast,
  lunch,
  dinner,
  workout,
  windDown,
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

  const ContextualNudge({
    required this.id,
    required this.icon,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.action,
    this.explainerOverride,
  });

  ContextualNudge copyWith({
    String? icon,
    String? title,
    String? body,
    String? ctaLabel,
    ContextualNudgeAction? action,
    String? explainerOverride,
  }) {
    return ContextualNudge(
      id: id,
      icon: icon ?? this.icon,
      title: title ?? this.title,
      body: body ?? this.body,
      ctaLabel: ctaLabel ?? this.ctaLabel,
      action: action ?? this.action,
      explainerOverride: explainerOverride ?? this.explainerOverride,
    );
  }
}
