import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/weekly_plan.dart';
import '../services/api_client.dart';

/// Weekly plan repository provider
final weeklyPlanRepositoryProvider = Provider<WeeklyPlanRepository>((ref) {
  return WeeklyPlanRepository(ref.watch(apiClientProvider));
});

/// Weekly plan repository for all holistic plan API calls
class WeeklyPlanRepository {
  final ApiClient _client;

  WeeklyPlanRepository(this._client);

  // ============================================
  // Weekly Plans
  // ============================================

  /// Generate a new weekly plan
  Future<WeeklyPlan> generateWeeklyPlan({
    required String userId,
    required List<int> workoutDays,
    String? fastingProtocol,
    required String nutritionStrategy,
    String? preferredWorkoutTime,
    List<String>? goals,
  }) async {
    try {
      debugPrint('📅 [WeeklyPlan] Generating plan for $userId');
      final response = await _client.post(
        '/weekly-plans/generate',
        data: {
          'user_id': userId,
          'workout_days': workoutDays,
          if (fastingProtocol != null) 'fasting_protocol': fastingProtocol,
          'nutrition_strategy': nutritionStrategy,
          if (preferredWorkoutTime != null)
            'preferred_workout_time': preferredWorkoutTime,
          if (goals != null) 'goals': goals,
        },
      );
      debugPrint('✅ [WeeklyPlan] Plan generated successfully');
      return WeeklyPlan.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [WeeklyPlan] Error generating plan: $e');
      rethrow;
    }
  }

  /// Get the current week's plan
  Future<WeeklyPlan?> getCurrentWeekPlan(String userId) async {
    try {
      debugPrint('🔍 [WeeklyPlan] Fetching current week plan for $userId');
      final response = await _client.get(
        '/weekly-plans/current',
        queryParameters: {'user_id': userId},
      );

      if (response.data == null ||
          (response.data is Map && response.data.isEmpty)) {
        debugPrint('📭 [WeeklyPlan] No current plan found');
        return null;
      }

      debugPrint('✅ [WeeklyPlan] Current plan fetched');
      return WeeklyPlan.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [WeeklyPlan] Error fetching current plan: $e');
      rethrow;
    }
  }

  /// Get a specific week's plan by start date
  Future<WeeklyPlan?> getWeekPlan(String userId, DateTime weekStart) async {
    try {
      final weekStartStr =
          '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
      debugPrint('🔍 [WeeklyPlan] Fetching plan for week $weekStartStr');

      final response = await _client.get(
        '/weekly-plans/$weekStartStr',
        queryParameters: {'user_id': userId},
      );

      if (response.data == null ||
          (response.data is Map && response.data.isEmpty)) {
        debugPrint('📭 [WeeklyPlan] No plan found for $weekStartStr');
        return null;
      }

      debugPrint('✅ [WeeklyPlan] Plan fetched for $weekStartStr');
      return WeeklyPlan.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [WeeklyPlan] Error fetching week plan: $e');
      rethrow;
    }
  }

  /// Update a weekly plan
  Future<WeeklyPlan> updateWeeklyPlan({
    required String planId,
    required String userId,
    List<int>? workoutDays,
    String? fastingProtocol,
    String? nutritionStrategy,
    String? status,
  }) async {
    try {
      debugPrint('📝 [WeeklyPlan] Updating plan $planId');
      final response = await _client.put(
        '/weekly-plans/$planId',
        data: {
          'user_id': userId,
          if (workoutDays != null) 'workout_days': workoutDays,
          if (fastingProtocol != null) 'fasting_protocol': fastingProtocol,
          if (nutritionStrategy != null) 'nutrition_strategy': nutritionStrategy,
          if (status != null) 'status': status,
        },
      );
      debugPrint('✅ [WeeklyPlan] Plan updated');
      return WeeklyPlan.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [WeeklyPlan] Error updating plan: $e');
      rethrow;
    }
  }

  /// Archive (delete) a weekly plan
  Future<void> archiveWeeklyPlan({
    required String planId,
    required String userId,
  }) async {
    try {
      debugPrint('🗑️ [WeeklyPlan] Archiving plan $planId');
      await _client.delete(
        '/weekly-plans/$planId',
        queryParameters: {'user_id': userId},
      );
      debugPrint('✅ [WeeklyPlan] Plan archived');
    } catch (e) {
      debugPrint('❌ [WeeklyPlan] Error archiving plan: $e');
      rethrow;
    }
  }

  // ============================================
  // Daily Plan Entries
  // ============================================

  /// Get a specific day's plan
  Future<DailyPlanEntry?> getDailyPlan({
    required String planId,
    required String userId,
    required DateTime date,
  }) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      debugPrint('🔍 [WeeklyPlan] Fetching daily plan for $dateStr');

      final response = await _client.get(
        '/weekly-plans/$planId/daily/$dateStr',
        queryParameters: {'user_id': userId},
      );

      if (response.data == null ||
          (response.data is Map && response.data.isEmpty)) {
        debugPrint('📭 [WeeklyPlan] No daily plan for $dateStr');
        return null;
      }

      debugPrint('✅ [WeeklyPlan] Daily plan fetched for $dateStr');
      return DailyPlanEntry.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [WeeklyPlan] Error fetching daily plan: $e');
      rethrow;
    }
  }

  /// Update a daily plan entry
  Future<DailyPlanEntry> updateDailyPlan({
    required String planId,
    required String userId,
    required DateTime date,
    bool? nutritionLogged,
    bool? workoutCompleted,
    bool? fastingCompleted,
    List<MealSuggestion>? mealSuggestions,
  }) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      debugPrint('📝 [WeeklyPlan] Updating daily plan for $dateStr');

      final response = await _client.put(
        '/weekly-plans/$planId/daily/$dateStr',
        data: {
          'user_id': userId,
          if (nutritionLogged != null) 'nutrition_logged': nutritionLogged,
          if (workoutCompleted != null) 'workout_completed': workoutCompleted,
          if (fastingCompleted != null) 'fasting_completed': fastingCompleted,
          if (mealSuggestions != null)
            'meal_suggestions': mealSuggestions.map((m) => m.toJson()).toList(),
        },
      );

      debugPrint('✅ [WeeklyPlan] Daily plan updated');
      return DailyPlanEntry.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [WeeklyPlan] Error updating daily plan: $e');
      rethrow;
    }
  }

  // ============================================
  // Meal Suggestions
  // ============================================

  /// Generate meal suggestions for a specific day
  Future<List<MealSuggestion>> generateMealSuggestions({
    required String userId,
    required DateTime planDate,
    required String dayType,
    required int calorieTarget,
    required double proteinTargetG,
    String? eatingWindowStart,
    String? eatingWindowEnd,
    String? workoutTime,
  }) async {
    try {
      final dateStr =
          '${planDate.year}-${planDate.month.toString().padLeft(2, '0')}-${planDate.day.toString().padLeft(2, '0')}';
      debugPrint('🍽️ [WeeklyPlan] Generating meal suggestions for $dateStr');

      final response = await _client.post(
        '/weekly-plans/meal-suggestions',
        data: {
          'user_id': userId,
          'plan_date': dateStr,
          'day_type': dayType,
          'calorie_target': calorieTarget,
          'protein_target_g': proteinTargetG,
          if (eatingWindowStart != null) 'eating_window_start': eatingWindowStart,
          if (eatingWindowEnd != null) 'eating_window_end': eatingWindowEnd,
          if (workoutTime != null) 'workout_time': workoutTime,
        },
      );

      debugPrint('✅ [WeeklyPlan] Meal suggestions generated');
      return (response.data as List)
          .map((json) => MealSuggestion.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ [WeeklyPlan] Error generating meal suggestions: $e');
      rethrow;
    }
  }

  /// Regenerate a specific meal
  Future<MealSuggestion> regenerateMeal({
    required String userId,
    required String mealType,
    required int remainingCalories,
    required double remainingProteinG,
    String? eatingWindowEnd,
    String? reason,
  }) async {
    try {
      debugPrint('🔄 [WeeklyPlan] Regenerating $mealType meal');

      final response = await _client.post(
        '/weekly-plans/regenerate-meal',
        data: {
          'user_id': userId,
          'meal_type': mealType,
          'remaining_calories': remainingCalories,
          'remaining_protein_g': remainingProteinG,
          if (eatingWindowEnd != null) 'eating_window_end': eatingWindowEnd,
          if (reason != null) 'reason': reason,
        },
      );

      debugPrint('✅ [WeeklyPlan] Meal regenerated');
      return MealSuggestion.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [WeeklyPlan] Error regenerating meal: $e');
      rethrow;
    }
  }
}
