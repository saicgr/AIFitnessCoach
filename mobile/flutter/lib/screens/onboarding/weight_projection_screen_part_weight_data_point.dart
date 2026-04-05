part of 'weight_projection_screen.dart';


/// Data point for weight projection chart
class WeightDataPoint {
  final DateTime date;
  final double weight;

  WeightDataPoint(this.date, this.weight);
}


/// Calculator for weight projection
class WeightProjectionCalculator {
  /// Calculate weekly rate in kg based on user's rate preference and workout frequency
  static double calculateWeeklyRate({
    required double currentWeight,
    required double goalWeight,
    required int workoutDaysPerWeek,
    String? weightChangeRate,
  }) {
    if (weightChangeRate != null) {
      switch (weightChangeRate) {
        case 'slow':
          return goalWeight < currentWeight ? 0.25 : 0.25;
        case 'moderate':
          return goalWeight < currentWeight ? 0.5 : 0.35;
        case 'fast':
          return goalWeight < currentWeight ? 0.75 : 0.5;
        case 'aggressive':
          return goalWeight < currentWeight ? 1.0 : 0.5;
        default:
          return goalWeight < currentWeight ? 0.5 : 0.35;
      }
    } else if (goalWeight < currentWeight) {
      return 0.5 + (workoutDaysPerWeek / 14);
    } else {
      return 0.25 + (workoutDaysPerWeek / 28);
    }
  }

  /// Calculate goal date based on current weight, goal weight, and rate preference
  static DateTime calculateGoalDate({
    required double currentWeight,
    required double goalWeight,
    required int workoutDaysPerWeek,
    String? weightChangeRate,
  }) {
    final weightDiff = (currentWeight - goalWeight).abs();
    final weeklyRate = calculateWeeklyRate(
      currentWeight: currentWeight,
      goalWeight: goalWeight,
      workoutDaysPerWeek: workoutDaysPerWeek,
      weightChangeRate: weightChangeRate,
    );

    final weeksNeeded = (weightDiff / weeklyRate).ceil();
    return DateTime.now().add(Duration(days: weeksNeeded * 7));
  }

  /// Generate smooth curve with data points for chart
  static List<WeightDataPoint> generateProjectionCurve({
    required double currentWeight,
    required double goalWeight,
    required DateTime goalDate,
  }) {
    final points = <WeightDataPoint>[];
    final today = DateTime.now();
    final totalDays = goalDate.difference(today).inDays;

    // Generate 6-8 data points along the curve
    const numPoints = 7;

    for (int i = 0; i < numPoints; i++) {
      final progress = i / (numPoints - 1);
      final daysFromNow = (totalDays * progress).round();
      final date = today.add(Duration(days: daysFromNow));

      // Use ease-out curve: faster initial progress, slower as approaching goal
      // y = 1 - (1 - x)^2
      final easeOutProgress = 1 - (1 - progress) * (1 - progress);
      final weight = currentWeight +
          (goalWeight - currentWeight) * easeOutProgress;

      points.add(WeightDataPoint(date, weight));
    }

    return points;
  }
}

