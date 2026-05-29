/// Today Score — Zealova's home-screen execution score.
///
/// The score answers "how much of today's plan have you done?" — it is an
/// EXECUTION score (built from the coach's plan + your food log + your steps),
/// not a biometric recovery score. It is computed entirely client-side and
/// deterministically (see [computeTodayScore] in
/// `lib/services/today_score_service.dart`).
///
/// Pure model layer — no Flutter, no codegen, no app dependencies — so it is
/// trivially unit-testable in isolation.
library;

/// The three things the score is built from.
///
/// Weights are *relative priorities*. On any given day only the contributors
/// that actually apply are counted, and their weights renormalize to 100% —
/// see [TodayScore.contributors] / [computeTodayScore].
enum ContributorKind {
  /// Did you do today's prescribed training. Base weight 40%.
  train,

  /// Are you on target for calories + protein. Base weight 30%.
  /// Internal name kept as `fuel` to avoid wide refactor; user-facing label
  /// is "Nourish" (see [ContributorKindMeta.label]).
  fuel,

  /// Steps vs your daily goal (from Health Connect / Apple Health). Base 15%.
  move,

  /// Sleep score from the health-service sleep aggregation. Base 15%.
  /// Applicable only when Health Connect / HealthKit is linked and provides
  /// a sleep summary; not counted as a zero otherwise.
  sleep,
}

/// Base (full-training-day) weight for each contributor. They sum to 1.0.
///
/// Adding Sleep as a 4th contributor (2026-05-22) split off weight from Train
/// (50→40) and Fuel/Nourish (35→30) while keeping Train as the heaviest pillar
/// — Zealova is workout-first, so 40% on Train preserves that asymmetry vs
/// Oura/Whoop's recovery-heavy weighting.
const Map<ContributorKind, double> kBaseContributorWeights = {
  ContributorKind.train: 0.40,
  ContributorKind.fuel: 0.30,
  ContributorKind.move: 0.15,
  ContributorKind.sleep: 0.15,
};

extension ContributorKindMeta on ContributorKind {
  /// Short human label shown in the score card legend.
  String get label {
    switch (this) {
      case ContributorKind.train:
        return 'Train';
      case ContributorKind.fuel:
        return 'Nourish';
      case ContributorKind.move:
        return 'Move';
      case ContributorKind.sleep:
        return 'Sleep';
    }
  }

  double get baseWeight => kBaseContributorWeights[this]!;
}

/// One slice of the Today Score.
///
/// A contributor is only [applicable] if it has real data today:
///  * [ContributorKind.train] — a workout is scheduled today (rest day / no
///    plan ⇒ not applicable, and *not* counted as a zero).
///  * [ContributorKind.fuel] — the user has nutrition targets set.
///  * [ContributorKind.move] — Health Connect is linked and giving steps.
///
/// [completion] is a 0.0–1.0 fraction and is only meaningful when [applicable].
/// [effectiveWeight] is the renormalized weight actually used in the score
/// (0.0 when the contributor is not applicable today).
class ScoreContributor {
  final ContributorKind kind;
  final bool applicable;
  final double completion;
  final double effectiveWeight;

  /// Plain-language status shown under the contributor's name, e.g.
  /// "89g protein to go", "Leg day · not started", "Rest day".
  final String statusText;

  const ScoreContributor({
    required this.kind,
    required this.applicable,
    required this.completion,
    required this.effectiveWeight,
    required this.statusText,
  });

  /// Base (un-renormalized) weight — useful for the "worth 50 points" copy.
  double get baseWeight => kind.baseWeight;

  /// This contributor's contribution to the final 0–100 score.
  double get points => applicable ? effectiveWeight * completion * 100.0 : 0.0;

  ScoreContributor copyWith({
    bool? applicable,
    double? completion,
    double? effectiveWeight,
    String? statusText,
  }) {
    return ScoreContributor(
      kind: kind,
      applicable: applicable ?? this.applicable,
      completion: completion ?? this.completion,
      effectiveWeight: effectiveWeight ?? this.effectiveWeight,
      statusText: statusText ?? this.statusText,
    );
  }
}

/// The computed Today Score.
class TodayScore {
  /// The composite score, 0–100.
  final int score;

  /// Always four entries, in Train / Nourish (internal `fuel`) / Move / Sleep
  /// order. Inapplicable ones are still present (so the UI can show "Rest day"
  /// etc.) but contribute 0.
  final List<ScoreContributor> contributors;

  /// True when nothing applies today (brand-new user: no plan, no targets,
  /// no Health Connect). The home shows a setup prompt rather than "0".
  final bool isSetupState;

  /// When this score was computed.
  final DateTime generatedAt;

  const TodayScore({
    required this.score,
    required this.contributors,
    required this.isSetupState,
    required this.generatedAt,
  });

  /// Look up a single contributor. Total (never throws): a [TodayScore] built
  /// from a partial/deserialized contributors list returns an inapplicable
  /// zero-weight stand-in instead of a `StateError` — defensive against a
  /// future server-sourced or cached score that omits a kind.
  ScoreContributor contributor(ContributorKind kind) =>
      contributors.firstWhere(
        (c) => c.kind == kind,
        orElse: () => ScoreContributor(
          kind: kind,
          applicable: false,
          completion: 0,
          effectiveWeight: 0,
          statusText: '',
        ),
      );

  /// The contributors actually counted in today's score.
  List<ScoreContributor> get applicableContributors =>
      contributors.where((c) => c.applicable).toList();

  /// A short state word for under the big number, derived from the score.
  String get stateLabel {
    if (isSetupState) return 'Finish setup';
    if (score >= 90) return 'Crushing it';
    if (score >= 70) return 'On track';
    if (score >= 40) return 'Keep going';
    return 'Just getting started';
  }
}
