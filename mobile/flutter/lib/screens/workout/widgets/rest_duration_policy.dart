/// Smart rest-timer duration policy.
///
/// Deterministic, <1ms helper that picks the rest countdown duration to
/// auto-start when a working set is marked complete. The intent (per the
/// "Beat Gravl" leapfrog plan, Workstream 5 item 5) is that the rest the app
/// starts should ADAPT to how hard the just-finished set was — a near-failure
/// set warrants a longer rest than a set with reps left in reserve.
///
/// Resolution order (first non-null wins):
///   1. The exercise's prescribed rest (`exercise.restSeconds`), when present.
///      A coach/plan-authored rest target always overrides effort scaling.
///   2. RIR-scaled rest:  RIR 0 → 180s · RIR 1–2 → 120s · RIR 3+ → 90s.
///   3. RPE-scaled rest (when only RPE was logged):
///      RPE ≥ 9.5 → 180s · RPE ≥ 8 → 120s · else → 90s.
///      RPE maps to RIR via the industry convention RIR ≈ 10 − RPE, so the two
///      ladders agree (RPE 10 ⇒ RIR 0 ⇒ 180s, RPE 8 ⇒ RIR 2 ⇒ 120s).
///   4. Fallback base: 90s between sets, 120s between exercises.
///
/// No weight-unit concerns here — this is purely a time computation.
class RestDurationPolicy {
  /// Hard rep-near-failure rest (RIR 0 / RPE 10).
  static const int hardRestSeconds = 180;

  /// Moderate rest (RIR 1–2 / RPE 8–9).
  static const int moderateRestSeconds = 120;

  /// Light rest (RIR 3+ / RPE < 8), and the default between-set base.
  static const int lightRestSeconds = 90;

  /// Default rest between exercises when nothing else applies.
  static const int betweenExercisesSeconds = 120;

  /// Resolve the rest duration (seconds) to auto-start.
  ///
  /// [prescribedRestSeconds] — the exercise's authored rest, if any. A value
  ///   > 0 short-circuits effort scaling.
  /// [rir] — reps-in-reserve logged for the just-finished set (0–5+).
  /// [rpe] — rate-of-perceived-exertion (1–10) for the set, used only when
  ///   [rir] is null.
  /// [betweenExercises] — true when this is rest BEFORE the next exercise (no
  ///   effort scaling — we don't yet know the next movement's demand).
  static int resolveSeconds({
    int? prescribedRestSeconds,
    int? rir,
    int? rpe,
    bool betweenExercises = false,
  }) {
    // 1. Authored rest always wins.
    if (prescribedRestSeconds != null && prescribedRestSeconds > 0) {
      return prescribedRestSeconds;
    }

    // Between-exercise rest doesn't scale on the prior set's effort.
    if (betweenExercises) {
      return betweenExercisesSeconds;
    }

    // 2. RIR-scaled rest (preferred — it's what the set logger captures).
    if (rir != null) {
      if (rir <= 0) return hardRestSeconds;
      if (rir <= 2) return moderateRestSeconds;
      return lightRestSeconds;
    }

    // 3. RPE-scaled rest (only RPE was logged). RIR ≈ 10 − RPE.
    if (rpe != null) {
      if (rpe >= 10) return hardRestSeconds; // RIR ~0
      if (rpe >= 8) return moderateRestSeconds; // RIR ~1–2
      return lightRestSeconds; // RIR 3+
    }

    // 4. Nothing logged — light base rest.
    return lightRestSeconds;
  }

  /// Human-readable one-line reason for the chosen duration, used as a subtle
  /// caption on the auto-started timer so the adaptation is legible rather than
  /// magic. Returns null when the rest came straight from the plan (no scaling
  /// story to tell).
  static String? reasonFor({
    int? prescribedRestSeconds,
    int? rir,
    int? rpe,
  }) {
    if (prescribedRestSeconds != null && prescribedRestSeconds > 0) {
      return null; // Plan-authored — no effort-scaling explanation.
    }
    if (rir != null) {
      if (rir <= 0) return 'Near failure — longer rest';
      if (rir <= 2) return 'Hard set — moderate rest';
      return 'Reps in reserve — shorter rest';
    }
    if (rpe != null) {
      if (rpe >= 10) return 'Near failure — longer rest';
      if (rpe >= 8) return 'Hard set — moderate rest';
      return 'Reps in reserve — shorter rest';
    }
    return null;
  }
}
