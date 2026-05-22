/// `todayScoreProvider` — assembles the live [TodayScore] from the app's
/// workout / nutrition / health providers.
///
/// This is the only place the score touches app state; the engine itself
/// ([computeTodayScore]) stays a pure function. Async sources are read via
/// `valueOrNull` so the score is always available — it simply refines as
/// each source finishes loading.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/today_score.dart';
import '../../services/today_score_service.dart';
import 'today_workout_provider.dart';
import 'nutrition_preferences_provider.dart';
import '../repositories/nutrition_repository.dart';
import '../services/health_service.dart';
import '../services/health_goals_service.dart';

/// The live Today Score, recomputed whenever any input changes.
final todayScoreProvider = Provider<TodayScore>((ref) {
  // ---- Workout (Train) ---------------------------------------------------
  final workout = ref.watch(todayWorkoutProvider).valueOrNull;
  final isRestDay = workout?.restDayMessage != null;
  final hasWorkoutScheduledToday =
      (workout?.hasWorkoutToday ?? false) && !isRestDay;
  // "Has a plan" = the user has any scheduled training context at all
  // (a workout today, an upcoming one, or a declared rest day). A brand-new
  // user with nothing scheduled has no plan.
  final hasPlan = workout != null &&
      (workout.hasWorkoutToday ||
          workout.nextWorkout != null ||
          isRestDay);
  final workoutComplete = workout?.completedToday ?? false;
  final exercisesTotal = workout?.todayWorkout?.exerciseCount ?? 0;
  // Per-exercise progress for a mid-session workout is not exposed here;
  // until it is, Train is binary (0 until complete, 1 when complete).
  final exercisesDone = workoutComplete ? exercisesTotal : 0;
  final workoutLabel = workout?.todayWorkout?.name;

  // ---- Nutrition (Fuel) --------------------------------------------------
  final summary = ref.watch(nutritionProvider).todaySummary;
  final prefs = ref.watch(nutritionPreferencesProvider);
  final calorieTarget = prefs.currentCalorieTarget;
  final proteinTargetG = prefs.currentProteinTarget.round();
  final hasNutritionTargets = calorieTarget > 0 && proteinTargetG > 0;

  // ---- Activity (Move) ---------------------------------------------------
  final steps = ref.watch(dailyActivityProvider).today?.steps ?? 0;
  final stepGoal =
      ref.watch(healthGoalsProvider).valueOrNull?.stepGoal ?? 10000;
  final healthConnected = ref.watch(healthSyncProvider).isConnected;

  return computeTodayScore(TodayScoreInputs(
    hasPlan: hasPlan,
    hasWorkoutScheduledToday: hasWorkoutScheduledToday,
    isRestDay: isRestDay,
    workoutComplete: workoutComplete,
    exercisesDone: exercisesDone,
    exercisesTotal: exercisesTotal,
    workoutLabel: workoutLabel,
    hasNutritionTargets: hasNutritionTargets,
    calorieTarget: calorieTarget,
    caloriesLogged: summary?.totalCalories ?? 0,
    proteinTargetG: proteinTargetG,
    proteinLoggedG: (summary?.totalProteinG ?? 0).round(),
    healthConnected: healthConnected,
    steps: steps,
    stepGoal: stepGoal,
  ));
});
