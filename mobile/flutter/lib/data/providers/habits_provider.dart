import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout.dart';
import '../repositories/workout_repository.dart';
import '../repositories/nutrition_repository.dart';
import '../repositories/hydration_repository.dart';
import '../../screens/home/widgets/habit_card.dart';

/// Provider that aggregates habit data from workouts, nutrition, and hydration
/// Returns a list of HabitData for the last 30 days
final habitsProvider = Provider<List<HabitData>>((ref) {
  final workoutsAsync = ref.watch(workoutsProvider);
  final nutritionState = ref.watch(nutritionProvider);
  final hydrationState = ref.watch(hydrationProvider);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Generate last 30 days of workout data
  final workoutDays = _getWorkoutDays(workoutsAsync, today);
  final workoutStreak = _calculateStreak(workoutDays);

  // Generate last 30 days of food logging data
  final foodLogDays = _getFoodLogDays(nutritionState, today);
  final foodStreak = _calculateStreak(foodLogDays);

  // Generate last 30 days of hydration data
  final waterDays = _getHydrationDays(hydrationState, today);
  final waterStreak = _calculateStreak(waterDays);

  return [
    HabitData(
      name: 'Workouts',
      icon: Icons.fitness_center,
      last30Days: workoutDays,
      currentStreak: workoutStreak,
      route: '/workouts',
    ),
    HabitData(
      name: 'Food Log',
      icon: Icons.restaurant_menu,
      last30Days: foodLogDays,
      currentStreak: foodStreak,
      route: '/nutrition',
    ),
    HabitData(
      name: 'Water',
      icon: Icons.water_drop,
      last30Days: waterDays,
      currentStreak: waterStreak,
      route: '/hydration',
    ),
  ];
});

/// Get workout completion status for last 30 days
List<bool> _getWorkoutDays(AsyncValue<List<Workout>> workoutsAsync, DateTime today) {
  final List<bool> days = List.filled(30, false);

  workoutsAsync.whenData((workouts) {
    for (final workout in workouts) {
      if (workout.isCompleted != true) continue;
      if (workout.scheduledDate == null) continue;

      try {
        final workoutDate = workout.scheduledLocalDate;
        if (workoutDate == null) continue;
        final daysDiff = today.difference(workoutDate).inDays;

        // Index 0 = 29 days ago, Index 29 = today
        if (daysDiff >= 0 && daysDiff < 30) {
          days[29 - daysDiff] = true;
        }
      } catch (_) {
        // Invalid date format, skip
      }
    }
  });

  return days;
}

/// Get food logging status for last 30 days
/// Currently checks if today has any logs, historical data would need API support
List<bool> _getFoodLogDays(NutritionState nutritionState, DateTime today) {
  final List<bool> days = List.filled(30, false);

  // Debug: Log nutrition state
  debugPrint('🍎 _getFoodLogDays: todaySummary=${nutritionState.todaySummary != null}, recentLogs=${nutritionState.recentLogs.length}');

  // Check if today has any food logged (calories > 0)
  if (nutritionState.todaySummary != null) {
    final hasFood = nutritionState.todaySummary!.totalCalories > 0;
    days[29] = hasFood; // Today is the last index
    debugPrint('🍎 Today food: $hasFood (calories: ${nutritionState.todaySummary!.totalCalories})');
  }

  // Check recent logs for historical data
  for (final log in nutritionState.recentLogs) {
    try {
      final logDate = log.loggedAt;
      final daysDiff = today.difference(DateTime(logDate.year, logDate.month, logDate.day)).inDays;

      if (daysDiff >= 0 && daysDiff < 30) {
        days[29 - daysDiff] = true;
        debugPrint('🍎 Found food log at daysDiff=$daysDiff');
      }
    } catch (_) {
      // Invalid date, skip
    }
  }

  final completedDays = days.where((d) => d).length;
  debugPrint('🍎 Food log days: $completedDays/30');

  return days;
}

/// Get hydration status for last 30 days
/// Currently checks if today has water logged, historical data would need API support
List<bool> _getHydrationDays(HydrationState hydrationState, DateTime today) {
  final List<bool> days = List.filled(30, false);

  // Check if today has any water logged
  if (hydrationState.todaySummary != null) {
    final hasWater = hydrationState.todaySummary!.totalMl > 0;
    days[29] = hasWater; // Today is the last index
  }

  // Check recent logs for historical data
  for (final log in hydrationState.recentLogs) {
    final logDate = log.loggedAt;
    if (logDate == null) continue;

    try {
      final daysDiff = today.difference(DateTime(logDate.year, logDate.month, logDate.day)).inDays;

      if (daysDiff >= 0 && daysDiff < 30) {
        days[29 - daysDiff] = true;
      }
    } catch (_) {
      // Invalid date, skip
    }
  }

  return days;
}

/// Calculate current streak (consecutive days ending at today)
int _calculateStreak(List<bool> days) {
  int streak = 0;

  // Start from the end (today) and count backwards
  for (int i = days.length - 1; i >= 0; i--) {
    if (days[i]) {
      streak++;
    } else {
      break;
    }
  }

  return streak;
}
