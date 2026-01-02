import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/nutrition_preferences.dart';
import '../services/api_client.dart';

/// Nutrition preferences repository provider
final nutritionPreferencesRepositoryProvider =
    Provider<NutritionPreferencesRepository>((ref) {
  return NutritionPreferencesRepository(ref.watch(apiClientProvider));
});

/// Nutrition preferences repository for all nutrition preferences and weight tracking
class NutritionPreferencesRepository {
  final ApiClient _client;

  NutritionPreferencesRepository(this._client);

  // ============================================
  // Nutrition Preferences
  // ============================================

  /// Get user's nutrition preferences
  Future<NutritionPreferences?> getPreferences(String userId) async {
    try {
      debugPrint('🔍 [NutritionPrefs] Getting preferences for $userId');
      final response =
          await _client.get('/nutrition/preferences/$userId');
      if (response.data == null ||
          (response.data is Map && response.data.isEmpty)) {
        return null;
      }
      return NutritionPreferences.fromJson(response.data);
    } catch (e) {
      if (e.toString().contains('404')) {
        debugPrint('ℹ️ [NutritionPrefs] No preferences found (404)');
        return null;
      }
      debugPrint('❌ [NutritionPrefs] Error getting preferences: $e');
      rethrow;
    }
  }

  /// Save/update nutrition preferences
  Future<NutritionPreferences> savePreferences({
    required String userId,
    required NutritionPreferences preferences,
  }) async {
    try {
      debugPrint('💾 [NutritionPrefs] Saving preferences for $userId');
      final response = await _client.put(
        '/nutrition/preferences/$userId',
        data: preferences.toJson(),
      );
      debugPrint('✅ [NutritionPrefs] Preferences saved');
      return NutritionPreferences.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [NutritionPrefs] Error saving preferences: $e');
      rethrow;
    }
  }

  /// Complete nutrition onboarding (supports multi-select goals)
  Future<NutritionPreferences> completeOnboarding({
    required String userId,
    required List<NutritionGoal> goals, // Multi-select goals
    required RateOfChange? rateOfChange,
    required DietType dietType,
    required List<FoodAllergen> allergies,
    required List<DietaryRestriction> restrictions,
    required MealPattern mealPattern,
    required int? fastingStartHour,
    required int? fastingEndHour,
    required CookingSkill cookingSkill,
    required int cookingTimeMinutes,
    required BudgetLevel budgetLevel,
    int? customCarbPercent,
    int? customProteinPercent,
    int? customFatPercent,
    // Pre-calculated values from frontend to ensure consistency
    int? calculatedBmr,
    int? calculatedTdee,
    int? targetCalories,
    int? targetProteinG,
    int? targetCarbsG,
    int? targetFatG,
  }) async {
    try {
      debugPrint('🎓 [NutritionPrefs] Completing onboarding for $userId with ${goals.length} goals');
      if (targetCalories != null) {
        debugPrint('🎓 [NutritionPrefs] Sending frontend-calculated values: $targetCalories cal');
      }

      // Send both nutrition_goals (array) and nutrition_goal (legacy, primary goal)
      final primaryGoal = goals.isNotEmpty ? goals.first : NutritionGoal.maintain;

      final response = await _client.post(
        '/nutrition/onboarding/complete',
        data: {
          'user_id': userId,
          'nutrition_goals': goals.map((g) => g.value).toList(), // New multi-select
          'nutrition_goal': primaryGoal.value, // Legacy field for backward compatibility
          if (rateOfChange != null) 'rate_of_change': rateOfChange.value,
          'diet_type': dietType.value,
          'allergies': allergies.map((a) => a.value).toList(),
          'dietary_restrictions': restrictions.map((r) => r.value).toList(),
          'meal_pattern': mealPattern.value,
          if (fastingStartHour != null) 'fasting_start_hour': fastingStartHour,
          if (fastingEndHour != null) 'fasting_end_hour': fastingEndHour,
          'cooking_skill': cookingSkill.value,
          'cooking_time_minutes': cookingTimeMinutes,
          'budget_level': budgetLevel.value,
          if (customCarbPercent != null)
            'custom_carb_percent': customCarbPercent,
          if (customProteinPercent != null)
            'custom_protein_percent': customProteinPercent,
          if (customFatPercent != null) 'custom_fat_percent': customFatPercent,
          // Send pre-calculated values to ensure consistency with what user saw
          if (calculatedBmr != null) 'calculated_bmr': calculatedBmr,
          if (calculatedTdee != null) 'calculated_tdee': calculatedTdee,
          if (targetCalories != null) 'target_calories': targetCalories,
          if (targetProteinG != null) 'target_protein_g': targetProteinG,
          if (targetCarbsG != null) 'target_carbs_g': targetCarbsG,
          if (targetFatG != null) 'target_fat_g': targetFatG,
        },
      );

      debugPrint('✅ [NutritionPrefs] Onboarding completed');
      return NutritionPreferences.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [NutritionPrefs] Error completing onboarding: $e');
      rethrow;
    }
  }

  /// Recalculate targets based on current user data
  Future<NutritionPreferences> recalculateTargets(String userId) async {
    try {
      debugPrint('🔄 [NutritionPrefs] Recalculating targets for $userId');
      final response = await _client.post(
        '/nutrition/preferences/$userId/recalculate',
      );
      debugPrint('✅ [NutritionPrefs] Targets recalculated');
      return NutritionPreferences.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [NutritionPrefs] Error recalculating targets: $e');
      rethrow;
    }
  }

  // ============================================
  // Weight Tracking
  // ============================================

  /// Log a weight entry
  Future<WeightLog> logWeight({
    required String userId,
    required double weightKg,
    DateTime? loggedAt,
    String source = 'manual',
    String? notes,
  }) async {
    try {
      debugPrint('⚖️ [NutritionPrefs] Logging weight for $userId: $weightKg kg');
      final response = await _client.post(
        '/nutrition/weight-logs',
        data: {
          'user_id': userId,
          'weight_kg': weightKg,
          'logged_at': (loggedAt ?? DateTime.now()).toIso8601String(),
          'source': source,
          if (notes != null) 'notes': notes,
        },
      );
      debugPrint('✅ [NutritionPrefs] Weight logged');
      return WeightLog.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [NutritionPrefs] Error logging weight: $e');
      rethrow;
    }
  }

  /// Get weight logs for a user
  Future<List<WeightLog>> getWeightLogs({
    required String userId,
    int limit = 30,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      debugPrint('🔍 [NutritionPrefs] Getting weight logs for $userId');
      final queryParams = <String, dynamic>{'limit': limit};
      if (fromDate != null) queryParams['from_date'] = fromDate;
      if (toDate != null) queryParams['to_date'] = toDate;

      final response = await _client.get(
        '/nutrition/weight-logs/$userId',
        queryParameters: queryParams,
      );
      final data = response.data as List;
      debugPrint('✅ [NutritionPrefs] Retrieved ${data.length} weight logs');
      return data.map((json) => WeightLog.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ [NutritionPrefs] Error getting weight logs: $e');
      rethrow;
    }
  }

  /// Get the latest weight log
  Future<WeightLog?> getLatestWeight(String userId) async {
    try {
      final logs = await getWeightLogs(userId: userId, limit: 1);
      return logs.isNotEmpty ? logs.first : null;
    } catch (e) {
      debugPrint('❌ [NutritionPrefs] Error getting latest weight: $e');
      return null;
    }
  }

  /// Calculate weight trend (smoothed average)
  Future<WeightTrend> getWeightTrend({
    required String userId,
    int days = 14,
  }) async {
    try {
      debugPrint('📈 [NutritionPrefs] Getting weight trend for $userId');
      final response = await _client.get(
        '/nutrition/weight-logs/$userId/trend',
        queryParameters: {'days': days},
      );
      return WeightTrend.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [NutritionPrefs] Error getting weight trend: $e');
      rethrow;
    }
  }

  /// Delete a weight log
  Future<void> deleteWeightLog({
    required String userId,
    required String logId,
  }) async {
    try {
      debugPrint('🗑️ [NutritionPrefs] Deleting weight log $logId');
      await _client.delete(
        '/nutrition/weight-logs/$logId',
        queryParameters: {'user_id': userId},
      );
      debugPrint('✅ [NutritionPrefs] Weight log deleted');
    } catch (e) {
      debugPrint('❌ [NutritionPrefs] Error deleting weight log: $e');
      rethrow;
    }
  }

  // ============================================
  // Nutrition Streaks
  // ============================================

  /// Get user's nutrition streak
  Future<NutritionStreak> getStreak(String userId) async {
    try {
      debugPrint('🔥 [NutritionPrefs] Getting streak for $userId');
      final response = await _client.get('/nutrition/streak/$userId');
      return NutritionStreak.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [NutritionPrefs] Error getting streak: $e');
      rethrow;
    }
  }

  /// Use a streak freeze
  Future<NutritionStreak> useStreakFreeze(String userId) async {
    try {
      debugPrint('🧊 [NutritionPrefs] Using streak freeze for $userId');
      final response = await _client.post(
        '/nutrition/streak/$userId/freeze',
      );
      debugPrint('✅ [NutritionPrefs] Streak freeze used');
      return NutritionStreak.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [NutritionPrefs] Error using streak freeze: $e');
      rethrow;
    }
  }

  // ============================================
  // Dynamic Targets (Training Day Adjustments)
  // ============================================

  /// Get dynamic nutrition targets for a specific date
  /// Takes into account workout schedule and fasting protocol
  Future<DynamicNutritionTargets> getDynamicTargets({
    required String userId,
    DateTime? date,
  }) async {
    try {
      debugPrint('🎯 [NutritionPrefs] Getting dynamic targets for $userId');
      final queryParams = <String, dynamic>{};
      if (date != null) queryParams['date'] = date.toIso8601String().split('T').first;

      final response = await _client.get(
        '/nutrition/dynamic-targets/$userId',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return DynamicNutritionTargets.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [NutritionPrefs] Error getting dynamic targets: $e');
      rethrow;
    }
  }

  // ============================================
  // Adaptive Algorithm
  // ============================================

  /// Get latest adaptive nutrition calculation
  Future<AdaptiveCalculation?> getAdaptiveCalculation(String userId) async {
    try {
      debugPrint('🧮 [NutritionPrefs] Getting adaptive calculation for $userId');
      final response = await _client.get(
        '/nutrition/adaptive/$userId',
      );
      if (response.data == null ||
          (response.data is Map && response.data.isEmpty)) {
        return null;
      }
      return AdaptiveCalculation.fromJson(response.data);
    } catch (e) {
      if (e.toString().contains('404')) {
        return null;
      }
      debugPrint('❌ [NutritionPrefs] Error getting adaptive calculation: $e');
      rethrow;
    }
  }

  /// Trigger adaptive calculation
  Future<AdaptiveCalculation> calculateAdaptive(String userId) async {
    try {
      debugPrint('🧮 [NutritionPrefs] Triggering adaptive calculation for $userId');
      final response = await _client.post(
        '/nutrition/adaptive/$userId/calculate',
      );
      debugPrint('✅ [NutritionPrefs] Adaptive calculation complete');
      return AdaptiveCalculation.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [NutritionPrefs] Error calculating adaptive: $e');
      rethrow;
    }
  }

  /// Accept or decline weekly nutrition recommendation
  Future<void> respondToRecommendation({
    required String userId,
    required String recommendationId,
    required bool accepted,
  }) async {
    try {
      debugPrint('📝 [NutritionPrefs] Responding to recommendation $recommendationId');
      await _client.post(
        '/nutrition/recommendations/$recommendationId/respond',
        data: {
          'user_id': userId,
          'accepted': accepted,
        },
      );
      debugPrint('✅ [NutritionPrefs] Response saved');
    } catch (e) {
      debugPrint('❌ [NutritionPrefs] Error responding to recommendation: $e');
      rethrow;
    }
  }

  // ============================================
  // Nutrition UI Preferences
  // ============================================

  /// Get user's nutrition UI preferences
  Future<NutritionUIPreferences> getUIPreferences(String userId) async {
    try {
      debugPrint('🔍 [NutritionPrefs] Getting UI preferences for $userId');
      final response = await _client.get('/nutrition/ui-preferences/$userId');
      if (response.data == null || (response.data is Map && response.data.isEmpty)) {
        return NutritionUIPreferences.defaultPreferences(userId);
      }
      return NutritionUIPreferences.fromJson(response.data);
    } catch (e) {
      if (e.toString().contains('404')) {
        debugPrint('ℹ️ [NutritionPrefs] No UI preferences found, returning defaults');
        return NutritionUIPreferences.defaultPreferences(userId);
      }
      debugPrint('❌ [NutritionPrefs] Error getting UI preferences: $e');
      rethrow;
    }
  }

  /// Update nutrition UI preferences
  Future<NutritionUIPreferences> updateUIPreferences(NutritionUIPreferences prefs) async {
    try {
      debugPrint('💾 [NutritionPrefs] Updating UI preferences for ${prefs.userId}');
      final response = await _client.put(
        '/nutrition/ui-preferences/${prefs.userId}',
        data: prefs.toJson(),
      );
      debugPrint('✅ [NutritionPrefs] UI preferences updated');
      return NutritionUIPreferences.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [NutritionPrefs] Error updating UI preferences: $e');
      rethrow;
    }
  }

  /// Reset UI preferences to defaults
  Future<NutritionUIPreferences> resetUIPreferences(String userId) async {
    try {
      debugPrint('🔄 [NutritionPrefs] Resetting UI preferences for $userId');
      final response = await _client.post('/nutrition/ui-preferences/$userId/reset');
      debugPrint('✅ [NutritionPrefs] UI preferences reset');
      return NutritionUIPreferences.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [NutritionPrefs] Error resetting UI preferences: $e');
      rethrow;
    }
  }

  // ============================================
  // Meal Templates
  // ============================================

  /// Get meal templates (optionally filter by meal_type)
  Future<List<MealTemplate>> getTemplates({String? mealType}) async {
    try {
      debugPrint('🔍 [NutritionPrefs] Getting meal templates${mealType != null ? ' for $mealType' : ''}');
      final queryParams = <String, dynamic>{};
      if (mealType != null) queryParams['meal_type'] = mealType;

      final response = await _client.get(
        '/nutrition/templates',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final data = response.data as List;
      debugPrint('✅ [NutritionPrefs] Retrieved ${data.length} templates');
      return data.map((json) => MealTemplate.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ [NutritionPrefs] Error getting templates: $e');
      rethrow;
    }
  }

  /// Create a new meal template
  Future<MealTemplate> createTemplate(MealTemplate template) async {
    try {
      debugPrint('➕ [NutritionPrefs] Creating template: ${template.name}');
      final response = await _client.post(
        '/nutrition/templates',
        data: template.toJson(),
      );
      debugPrint('✅ [NutritionPrefs] Template created');
      return MealTemplate.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [NutritionPrefs] Error creating template: $e');
      rethrow;
    }
  }

  /// Update an existing meal template
  Future<MealTemplate> updateTemplate(MealTemplate template) async {
    try {
      if (template.id == null) {
        throw ArgumentError('Template ID is required for update');
      }
      debugPrint('✏️ [NutritionPrefs] Updating template: ${template.id}');
      final response = await _client.put(
        '/nutrition/templates/${template.id}',
        data: template.toJson(),
      );
      debugPrint('✅ [NutritionPrefs] Template updated');
      return MealTemplate.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [NutritionPrefs] Error updating template: $e');
      rethrow;
    }
  }

  /// Delete a meal template
  Future<void> deleteTemplate(String templateId) async {
    try {
      debugPrint('🗑️ [NutritionPrefs] Deleting template: $templateId');
      await _client.delete('/nutrition/templates/$templateId');
      debugPrint('✅ [NutritionPrefs] Template deleted');
    } catch (e) {
      debugPrint('❌ [NutritionPrefs] Error deleting template: $e');
      rethrow;
    }
  }

  /// Log a template as a meal
  Future<void> logTemplate(
    String templateId, {
    String? mealType,
    double servings = 1.0,
  }) async {
    try {
      debugPrint('📝 [NutritionPrefs] Logging template: $templateId');
      await _client.post(
        '/nutrition/templates/$templateId/log',
        data: {
          if (mealType != null) 'meal_type': mealType,
          'servings': servings,
        },
      );
      debugPrint('✅ [NutritionPrefs] Template logged');
    } catch (e) {
      debugPrint('❌ [NutritionPrefs] Error logging template: $e');
      rethrow;
    }
  }

  // ============================================
  // Quick Logging
  // ============================================

  /// Quick log a saved food (bypasses AI)
  Future<void> quickLog(
    String savedFoodId,
    String mealType, {
    double servings = 1.0,
  }) async {
    try {
      debugPrint('⚡ [NutritionPrefs] Quick logging food: $savedFoodId');
      await _client.post(
        '/nutrition/saved-foods/$savedFoodId/quick-log',
        data: {
          'meal_type': mealType,
          'servings': servings,
        },
      );
      debugPrint('✅ [NutritionPrefs] Quick log complete');
    } catch (e) {
      debugPrint('❌ [NutritionPrefs] Error quick logging: $e');
      rethrow;
    }
  }

  /// Get quick suggestions based on time/history
  Future<List<QuickSuggestion>> getQuickSuggestions({String? mealType}) async {
    try {
      debugPrint('🔍 [NutritionPrefs] Getting quick suggestions${mealType != null ? ' for $mealType' : ''}');
      final queryParams = <String, dynamic>{};
      if (mealType != null) queryParams['meal_type'] = mealType;

      final response = await _client.get(
        '/nutrition/quick-suggestions',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final data = response.data as List;
      debugPrint('✅ [NutritionPrefs] Retrieved ${data.length} suggestions');
      return data.map((json) => QuickSuggestion.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ [NutritionPrefs] Error getting suggestions: $e');
      rethrow;
    }
  }

  // ============================================
  // Food Search
  // ============================================

  /// Search foods with caching
  Future<List<FoodSearchResult>> searchFoods(String query, {int limit = 20}) async {
    try {
      debugPrint('🔍 [NutritionPrefs] Searching foods: "$query"');
      final response = await _client.get(
        '/nutrition/foods/search',
        queryParameters: {
          'query': query,
          'limit': limit,
        },
      );
      final data = response.data as List;
      debugPrint('✅ [NutritionPrefs] Found ${data.length} foods');
      return data.map((json) => FoodSearchResult.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ [NutritionPrefs] Error searching foods: $e');
      rethrow;
    }
  }
}

/// Weight trend data
class WeightTrend {
  final double? startWeight;
  final double? endWeight;
  final double? changeKg;
  final double? weeklyRateKg;
  final String direction; // 'losing', 'maintaining', 'gaining'
  final int daysAnalyzed;
  final double confidence;

  WeightTrend({
    this.startWeight,
    this.endWeight,
    this.changeKg,
    this.weeklyRateKg,
    required this.direction,
    required this.daysAnalyzed,
    required this.confidence,
  });

  factory WeightTrend.fromJson(Map<String, dynamic> json) {
    return WeightTrend(
      startWeight: (json['start_weight'] as num?)?.toDouble(),
      endWeight: (json['end_weight'] as num?)?.toDouble(),
      changeKg: (json['change_kg'] as num?)?.toDouble(),
      weeklyRateKg: (json['weekly_rate_kg'] as num?)?.toDouble(),
      direction: json['direction'] as String? ?? 'maintaining',
      daysAnalyzed: json['days_analyzed'] as int? ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'start_weight': startWeight,
        'end_weight': endWeight,
        'change_kg': changeKg,
        'weekly_rate_kg': weeklyRateKg,
        'direction': direction,
        'days_analyzed': daysAnalyzed,
        'confidence': confidence,
      };
}

/// Dynamic nutrition targets for a specific day
class DynamicNutritionTargets {
  final int targetCalories;
  final int targetProteinG;
  final int targetCarbsG;
  final int targetFatG;
  final int targetFiberG;
  final bool isTrainingDay;
  final bool isFastingDay;
  final bool isRestDay;
  final String adjustmentReason;
  final int calorieAdjustment;

  const DynamicNutritionTargets({
    this.targetCalories = 2000,
    this.targetProteinG = 150,
    this.targetCarbsG = 200,
    this.targetFatG = 65,
    this.targetFiberG = 25,
    this.isTrainingDay = false,
    this.isFastingDay = false,
    this.isRestDay = true,
    this.adjustmentReason = 'base_targets',
    this.calorieAdjustment = 0,
  });

  factory DynamicNutritionTargets.fromJson(Map<String, dynamic> json) {
    return DynamicNutritionTargets(
      targetCalories: json['target_calories'] as int? ?? 2000,
      targetProteinG: json['target_protein_g'] as int? ?? 150,
      targetCarbsG: json['target_carbs_g'] as int? ?? 200,
      targetFatG: json['target_fat_g'] as int? ?? 65,
      targetFiberG: json['target_fiber_g'] as int? ?? 25,
      isTrainingDay: json['is_training_day'] as bool? ?? false,
      isFastingDay: json['is_fasting_day'] as bool? ?? false,
      isRestDay: json['is_rest_day'] as bool? ?? true,
      adjustmentReason: json['adjustment_reason'] as String? ?? 'base_targets',
      calorieAdjustment: json['calorie_adjustment'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'target_calories': targetCalories,
        'target_protein_g': targetProteinG,
        'target_carbs_g': targetCarbsG,
        'target_fat_g': targetFatG,
        'target_fiber_g': targetFiberG,
        'is_training_day': isTrainingDay,
        'is_fasting_day': isFastingDay,
        'is_rest_day': isRestDay,
        'adjustment_reason': adjustmentReason,
        'calorie_adjustment': calorieAdjustment,
      };
}

// AdaptiveCalculation class is imported from '../models/nutrition_preferences.dart'
