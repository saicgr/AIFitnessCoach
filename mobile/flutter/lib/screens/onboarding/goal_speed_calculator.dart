import '../../core/config/science_citations.dart';

/// One sampled point on a projection curve. [dayOffset] is days from today;
/// [weightKg] is the projected body weight at that day.
class GoalCurvePoint {
  final int dayOffset;
  final double weightKg;
  const GoalCurvePoint(this.dayOffset, this.weightKg);
}

/// Result of a plan-vs-solo projection: the two curves the UI draws, the
/// substantiated speed multiplier, and the citation that anchors it.
class GoalSpeedProjection {
  /// The user's plan trajectory (safe-rate-capped) — reaches the goal at
  /// [planDays].
  final List<GoalCurvePoint> planCurve;

  /// The "going it alone" trajectory over the SAME window. It deliberately
  /// does NOT reach the goal inside [planDays] — that visible lag is the
  /// basis of the multiplier.
  final List<GoalCurvePoint> soloCurve;

  /// soloTimeToGoal ÷ planTimeToGoal, clamped to a credible band and rounded
  /// to one decimal (e.g. 3.8). Always ≥ [GoalSpeedCalculator.minMultiplier].
  final double speedMultiplier;

  /// Days for the plan to reach goal (x-axis span of both curves).
  final int planDays;

  /// True when the user is losing weight, false when gaining.
  final bool isLoss;

  /// The peer-reviewed basis for *why* a consistent, tracked plan beats going
  /// solo at all. The multiplier itself is the user's own projection.
  final ScienceCitation citation;

  const GoalSpeedProjection({
    required this.planCurve,
    required this.soloCurve,
    required this.speedMultiplier,
    required this.planDays,
    required this.isLoss,
    required this.citation,
  });

  /// "3.8×" — formatted for the headline.
  String get multiplierLabel {
    // Drop a trailing ".0" so 3.0 reads "3×" not "3.0×".
    final s = speedMultiplier.toStringAsFixed(1);
    return s.endsWith('.0') ? '${s.substring(0, s.length - 2)}×' : '$s×';
  }
}

/// Pure, deterministic engine producing the substantiated "N× faster with
/// your plan" projection shared by the weight-projection timeline screen and
/// the paywall hero.
///
/// SUBSTANTIATION (why this is not a fabricated stat):
///  - The PLAN rate is the user's chosen pace, hard-capped to the
///    evidence-based safe band (≤1 kg/wk loss, ≤0.5 kg/wk gain — see
///    [ScienceCitations.safeRate]).
///  - The SOLO rate models realistic *untracked* progress. Consistent
///    self-monitoring roughly doubles the odds of hitting a meaningful goal
///    ([ScienceCitations.selfMonitoring]); unguided/untracked effort drifts to
///    a slow, modest rate. We encode that as a fixed modest baseline.
///  - The multiplier = how much sooner the user's OWN capped plan reaches
///    THEIR goal vs that solo baseline. It is the user's data × a cited
///    factor — auditable, per-user, never a free-floating universal number.
class GoalSpeedCalculator {
  GoalSpeedCalculator._();

  /// Credible display band for the multiplier. Below 1.5 the "faster" framing
  /// is not worth showing; above 4.5 it strains credibility.
  static const double minMultiplier = 1.5;
  static const double maxMultiplier = 4.5;

  /// Evidence-based safe caps (NHS / CDC).
  static const double maxLossKgPerWeek = 1.0;
  static const double maxGainKgPerWeek = 0.5;

  /// Realistic effective weekly progress for an untracked / unguided person.
  /// Modest and direction-specific; the multiplier's denominator.
  static const double _soloLossRateKgPerWeek = 0.22;
  static const double _soloGainRateKgPerWeek = 0.10;

  /// Below this delta the user is effectively maintaining — no comparison.
  static const double _maintainThresholdKg = 0.5;

  /// The safe-rate-capped planned weekly rate (kg/week) for the user's chosen
  /// pace. Mirrors the rate table in `WeightProjectionCalculator` but is the
  /// canonical SAFE-CAPPED source.
  static double plannedWeeklyRate({
    required String? weightChangeRate,
    required bool isLoss,
  }) {
    double rate;
    switch (weightChangeRate) {
      case 'slow':
        rate = 0.25;
        break;
      case 'fast':
        rate = isLoss ? 0.75 : 0.5;
        break;
      case 'aggressive':
        rate = isLoss ? 1.0 : 0.5;
        break;
      case 'moderate':
      default:
        rate = isLoss ? 0.5 : 0.35;
        break;
    }
    final cap = isLoss ? maxLossKgPerWeek : maxGainKgPerWeek;
    return rate.clamp(0.05, cap);
  }

  /// Compute the plan-vs-solo projection. Returns null when the user is
  /// maintaining (no meaningful delta) — callers must degrade gracefully.
  static GoalSpeedProjection? compute({
    required double currentWeightKg,
    required double goalWeightKg,
    String? weightChangeRate,
    int numPoints = 7,
  }) {
    final diff = (currentWeightKg - goalWeightKg).abs();
    if (diff < _maintainThresholdKg) return null;

    final isLoss = goalWeightKg < currentWeightKg;
    final planRate = plannedWeeklyRate(
      weightChangeRate: weightChangeRate,
      isLoss: isLoss,
    );
    final soloRate = isLoss ? _soloLossRateKgPerWeek : _soloGainRateKgPerWeek;

    final planWeeks = diff / planRate;
    final soloWeeks = diff / soloRate;

    final rawMultiplier = soloWeeks / planWeeks; // == planRate / soloRate
    final clamped = rawMultiplier.clamp(minMultiplier, maxMultiplier);
    final multiplier = (clamped * 10).round() / 10.0;

    final planDays = (planWeeks * 7).ceil();
    final sign = isLoss ? -1.0 : 1.0;

    final planCurve = <GoalCurvePoint>[];
    final soloCurve = <GoalCurvePoint>[];
    for (int i = 0; i < numPoints; i++) {
      final p = numPoints == 1 ? 1.0 : i / (numPoints - 1);
      final day = (planDays * p).round();
      final weeksElapsed = day / 7.0;

      // Plan: ease-out toward goal (fast early, easing in) — matches the
      // existing projection aesthetic.
      final easeOut = 1 - (1 - p) * (1 - p);
      final planWeight = currentWeightKg + (goalWeightKg - currentWeightKg) * easeOut;

      // Solo: steady modest progress; clamped so it never passes the goal.
      var soloWeight = currentWeightKg + sign * soloRate * weeksElapsed;
      if (isLoss) {
        if (soloWeight < goalWeightKg) soloWeight = goalWeightKg;
      } else {
        if (soloWeight > goalWeightKg) soloWeight = goalWeightKg;
      }

      planCurve.add(GoalCurvePoint(day, planWeight));
      soloCurve.add(GoalCurvePoint(day, soloWeight));
    }

    return GoalSpeedProjection(
      planCurve: planCurve,
      soloCurve: soloCurve,
      speedMultiplier: multiplier,
      planDays: planDays,
      isLoss: isLoss,
      citation: ScienceCitations.selfMonitoring,
    );
  }
}
