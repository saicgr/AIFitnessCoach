/// Heart-rate-aware rest recovery policy.
///
/// Deterministic, dependency-free helper that decides — once a rest countdown
/// has elapsed — whether the lifter's heart rate has settled enough to start
/// the next set, and what BPM target counts as "recovered". It is the bridge
/// the "HR-aware rest" feature wires between the live in-workout heart-rate
/// stream and the rest timer (the two have always existed separately).
///
/// The training rationale: heart-rate recovery is a legitimate readiness signal
/// between sets — if HR is still elevated, a few more seconds of rest preserves
/// performance on the next set. Polar's "Work-Rest Guide" and Garmin's
/// recovery-HR features prove the model on hardware; this brings it in-app, fed
/// by BLE / Health Connect / HealthKit.
///
/// Sibling in spirit to [RestDurationPolicy] (rest_duration_policy.dart): a pure
/// <1ms computation, no I/O, no fakery. The *method* degrades gracefully by how
/// much data is available — it never invents a heart rate it doesn't have
/// (feedback_no_silent_fallbacks). When nothing is computable it returns null,
/// and the caller simply leaves the timer behaving exactly as it does today.
///
/// Target resolution (first computable wins):
///   1. **Heart-Rate Reserve (Karvonen)** — `restingHr + 0.60·(maxHr − restingHr)`.
///      Most personalized; needs age (→ maxHr) and a known resting HR.
///   2. **Zone-based** — `0.70 · maxHr` (top of the "fat burn" zone). Needs age.
///   3. **Relative drop** — recover toward the lull seen this rest / well below
///      the set's peak: `max(minHrThisRest + 15, peakHr − 35)`. Works with only
///      live HR, no profile data.
library;

/// Which method produced the recovery target — surfaced so the UI can be honest
/// ("personalized" vs "estimated") and for analytics.
enum HrRecoveryMethod { reserve, zone, relative }

/// Result of a recovery-target computation. Null target ⇒ not computable ⇒ the
/// caller should treat rest as un-gated (normal timer behavior).
class HrRecoveryTarget {
  /// BPM at or below which the lifter is considered recovered for the next set.
  final int targetBpm;

  /// How [targetBpm] was derived.
  final HrRecoveryMethod method;

  const HrRecoveryTarget({required this.targetBpm, required this.method});
}

class HrRecoveryPolicy {
  /// Fraction of heart-rate reserve to recover to (Karvonen). 0.60 ≈ the
  /// boundary between "still working" and "settled enough to lift again".
  static const double reserveFraction = 0.60;

  /// Fraction of max HR for the zone-based target (top of the fat-burn zone).
  static const double zoneFraction = 0.70;

  /// How far below the set's peak the relative-drop target sits.
  static const int relativePeakDrop = 35;

  /// How far above the rest's lull the relative-drop target sits.
  static const int relativeLullRise = 15;

  /// Absolute sanity clamps so a target can never be absurdly low/high.
  static const int minTargetBpm = 80;
  static const int maxTargetBpm = 175;

  /// Max HR from age via the Tanaka formula (208 − 0.7·age), matching
  /// `calculateMaxHR` in heart_rate_provider.dart. Kept inline so this stays a
  /// pure, dependency-free file.
  static int maxHrForAge(int age) => (208 - (0.7 * age)).round();

  /// Compute the recovery target, or null when no method has enough data.
  ///
  /// [age] — for max HR (methods 1 & 2). [restingHr] — for Karvonen (method 1).
  /// [peakHr] — the set's peak BPM (method 3). [minHrThisRest] — the lowest BPM
  /// seen so far during this rest (method 3).
  static HrRecoveryTarget? recoveryTarget({
    int? age,
    int? restingHr,
    int? peakHr,
    int? minHrThisRest,
  }) {
    final maxHr = (age != null && age > 0) ? maxHrForAge(age) : null;

    // 1. Karvonen heart-rate reserve.
    if (maxHr != null &&
        restingHr != null &&
        restingHr > 0 &&
        restingHr < maxHr) {
      final raw = restingHr + reserveFraction * (maxHr - restingHr);
      return HrRecoveryTarget(
        targetBpm: _clamp(raw.round(), restingHr),
        method: HrRecoveryMethod.reserve,
      );
    }

    // 2. Zone-based (% of max HR).
    if (maxHr != null) {
      return HrRecoveryTarget(
        targetBpm: _clamp((zoneFraction * maxHr).round(), restingHr),
        method: HrRecoveryMethod.zone,
      );
    }

    // 3. Relative drop — needs only live HR (peak, and optionally the lull).
    if (peakHr != null && peakHr > 0) {
      final fromPeak = peakHr - relativePeakDrop;
      final fromLull =
          (minHrThisRest != null && minHrThisRest > 0) ? minHrThisRest + relativeLullRise : fromPeak;
      final raw = fromPeak > fromLull ? fromPeak : fromLull;
      return HrRecoveryTarget(
        targetBpm: _clamp(raw, restingHr),
        method: HrRecoveryMethod.relative,
      );
    }

    return null;
  }

  /// True when [currentBpm] has settled to (or below) [targetBpm].
  static bool isRecovered(int currentBpm, int targetBpm) =>
      currentBpm <= targetBpm;

  /// Short, honest label for how the target was derived.
  static String methodLabel(HrRecoveryMethod method) {
    switch (method) {
      case HrRecoveryMethod.reserve:
        return 'personalized';
      case HrRecoveryMethod.zone:
        return 'zone-based';
      case HrRecoveryMethod.relative:
        return 'estimated';
    }
  }

  static int _clamp(int value, int? restingHr) {
    // Never let the target dip below a hair above resting (unreachable) or the
    // absolute floor, nor above the ceiling.
    final floor = restingHr != null && restingHr > 0
        ? (restingHr + 15 > minTargetBpm ? restingHr + 15 : minTargetBpm)
        : minTargetBpm;
    if (value < floor) return floor;
    if (value > maxTargetBpm) return maxTargetBpm;
    return value;
  }
}
