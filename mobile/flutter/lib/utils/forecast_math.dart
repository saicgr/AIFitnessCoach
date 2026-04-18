import 'dart:math' as math;

/// Simple linear extrapolation for the First Workout Forecast sheet (W1).
/// The pace here is the user's declared workouts-per-week; no fancy regression
/// because we only have 1 data point at this moment. The goal is to produce
/// a compelling but honest projection that frames "if you keep this pace..."
class ForecastMath {
  /// Weeks in a typical 30-day window (30 / 7).
  static const double weeksInMonth = 30.0 / 7.0;

  /// Projected 30-day volume (same unit as input). Safe for zero inputs.
  static int projectVolumePerMonth({
    required double volumeThisWorkout,
    required int sessionsPerWeek,
  }) {
    if (volumeThisWorkout <= 0 || sessionsPerWeek <= 0) return 0;
    return (volumeThisWorkout * sessionsPerWeek * weeksInMonth).round();
  }

  /// Projected 30-day calories burned.
  static int projectCaloriesPerMonth({
    required int caloriesThisWorkout,
    required int sessionsPerWeek,
  }) {
    if (caloriesThisWorkout <= 0 || sessionsPerWeek <= 0) return 0;
    return (caloriesThisWorkout * sessionsPerWeek * weeksInMonth).round();
  }

  /// Projected 30-day total minutes trained.
  static int projectMinutesPerMonth({
    required int durationMinutesThisWorkout,
    required int sessionsPerWeek,
  }) {
    if (durationMinutesThisWorkout <= 0 || sessionsPerWeek <= 0) return 0;
    return (durationMinutesThisWorkout * sessionsPerWeek * weeksInMonth).round();
  }

  /// Very rough strength-gain percent forecast.
  /// Backed by the research-backed heuristic that novices see ~1-3% weekly
  /// gains on main lifts for their first ~12 weeks before tapering.
  ///
  /// - If the user just set a PR with `firstWorkoutPrImprovementPercent > 0`,
  ///   extrapolate (weekly rate × 4.3) capped at 25%.
  /// - Otherwise, use a conservative default: 2% per session (capped at 15%).
  static int projectStrengthGainPercent({
    required double firstWorkoutPrImprovementPercent,
    required int sessionsPerWeek,
  }) {
    if (sessionsPerWeek <= 0) return 0;
    final double weeklyRate = firstWorkoutPrImprovementPercent > 0
        ? firstWorkoutPrImprovementPercent
        : 2.0 * sessionsPerWeek.toDouble();
    final projected = weeklyRate * weeksInMonth;
    final capped = math.min(projected, 25.0);
    return capped.round();
  }

  /// Lbs → "about N small cars" comparison for the share/celebration card.
  /// Uses 3,000 lbs = 1 mid-size car.
  static String poundsToCars(int lbs) {
    if (lbs < 1500) return '';
    final n = (lbs / 3000).round();
    if (n == 0) return '';
    if (n == 1) return 'about 1 mid-size car';
    return 'about $n mid-size cars';
  }

  /// Calories → "~N lbs of body fat" comparison (3,500 cal/lb).
  static String caloriesToBodyFat(int cal) {
    if (cal < 1750) return '';
    final lbs = (cal / 3500).toStringAsFixed(1);
    return '~$lbs lbs of body fat';
  }

  /// Formats large numbers as "15K" or "1.2M".
  static String formatCompact(int n) {
    if (n.abs() >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(1)}M';
    }
    if (n.abs() >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K';
    }
    return n.toString();
  }
}
