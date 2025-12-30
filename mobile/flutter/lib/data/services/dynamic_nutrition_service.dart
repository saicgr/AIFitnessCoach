import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/nutrition_preferences.dart';
import '../models/fasting.dart';
import '../models/workout.dart';
import '../repositories/nutrition_preferences_repository.dart';

/// Dynamic nutrition targets service provider
final dynamicNutritionServiceProvider = Provider<DynamicNutritionService>((ref) {
  return DynamicNutritionService();
});

/// Service for calculating dynamic nutrition targets based on training status,
/// fasting protocols, and workout intensity.
///
/// This service integrates:
/// - Base nutrition preferences (from onboarding)
/// - Today's workout schedule (if any)
/// - Fasting protocol (5:2, ADF, TRE)
/// - Training day adjustments
class DynamicNutritionService {
  DynamicNutritionService();

  // ============================================
  // Constants for Adjustments
  // ============================================

  /// Calorie adjustments for different training intensities
  static const Map<String, int> _intensityCalorieAdjustments = {
    'low': 50,
    'moderate': 100,
    'high': 200,
    'very_high': 300,
  };

  /// Protein multiplier adjustments for training days
  static const Map<String, double> _intensityProteinMultipliers = {
    'low': 1.0,
    'moderate': 1.05,
    'high': 1.10,
    'very_high': 1.15,
  };

  /// Carb multiplier for training days (glycogen replenishment)
  static const Map<String, double> _intensityCarbMultipliers = {
    'low': 1.0,
    'moderate': 1.10,
    'high': 1.20,
    'very_high': 1.25,
  };

  /// Rest day calorie reduction (if enabled by user)
  static const int _restDayCalorieReduction = 100;

  /// 5:2 fasting day calorie targets
  static const int _fiveTwoFemaleCalories = 500;
  static const int _fiveTwoMaleCalories = 600;

  /// Minimum protein on fasting days (muscle preservation)
  static const int _fastingDayMinProtein = 50;

  // ============================================
  // Main Calculation Methods
  // ============================================

  /// Calculate dynamic nutrition targets for today
  ///
  /// Takes into account:
  /// - Base nutrition preferences
  /// - Whether there's a workout today (and its intensity)
  /// - Fasting protocol and whether today is a fasting day
  /// - User preferences for training/rest day adjustments
  DynamicTargetsResult calculateTodaysTargets({
    required NutritionPreferences preferences,
    Workout? todaysWorkout,
    bool workoutCompleted = false,
    FastingPreferences? fastingPreferences,
    FastingRecord? activeFast,
    required String gender,
  }) {
    debugPrint('🎯 [DynamicNutrition] Calculating targets');

    // Start with base targets
    int baseCalories = preferences.targetCalories ?? 2000;
    int baseProtein = preferences.targetProteinG ?? 150;
    int baseCarbs = preferences.targetCarbsG ?? 200;
    int baseFat = preferences.targetFatG ?? 65;
    int baseFiber = preferences.targetFiberG;

    // Determine day type
    final bool isTrainingDay = todaysWorkout != null && !(todaysWorkout.isCompleted ?? false);
    final bool isRestDay = todaysWorkout == null;
    final bool isFastingDay = _isFastingDay(fastingPreferences);
    final String workoutIntensity = _normalizeIntensity(todaysWorkout?.difficulty);

    // Track adjustments
    int calorieAdjustment = 0;
    String adjustmentReason = 'base_targets';
    final List<String> adjustmentNotes = [];

    // Priority 1: Fasting day (5:2 or ADF) - overrides other adjustments
    if (isFastingDay && fastingPreferences != null) {
      final protocol = FastingProtocol.fromString(fastingPreferences.defaultProtocol);

      if (protocol == FastingProtocol.fiveTwo || protocol == FastingProtocol.adf) {
        // Very low calorie day
        final fastingCalories = gender.toLowerCase() == 'female'
            ? _fiveTwoFemaleCalories
            : _fiveTwoMaleCalories;

        return DynamicTargetsResult(
          targetCalories: fastingCalories,
          targetProteinG: _fastingDayMinProtein,
          targetCarbsG: 30,
          targetFatG: 25,
          targetFiberG: 15,
          isTrainingDay: isTrainingDay,
          isFastingDay: true,
          isRestDay: isRestDay,
          adjustmentReason: 'fasting_day',
          calorieAdjustment: fastingCalories - baseCalories,
          adjustmentNotes: ['Fasting day - focus on protein and vegetables'],
          weeklyContext: _calculateWeeklyContext(preferences, fastingPreferences, gender),
        );
      }
    }

    // Priority 2: Training day adjustments
    if (isTrainingDay && preferences.adjustCaloriesForTraining) {
      final calAdj = _intensityCalorieAdjustments[workoutIntensity] ?? 100;
      final proteinMult = _intensityProteinMultipliers[workoutIntensity] ?? 1.05;
      final carbMult = _intensityCarbMultipliers[workoutIntensity] ?? 1.10;

      calorieAdjustment += calAdj;
      baseCalories += calAdj;
      baseProtein = (baseProtein * proteinMult).round();
      baseCarbs = (baseCarbs * carbMult).round();

      adjustmentReason = 'training_day';
      adjustmentNotes.add('Training day (+$calAdj cal for $workoutIntensity intensity)');

      // Check if there's post-workout nutrition needed
      if (workoutCompleted) {
        adjustmentNotes.add('Prioritize protein-rich meal within 2 hours');
      }
    }

    // Priority 3: Rest day adjustments (if enabled and not training day)
    if (isRestDay && preferences.adjustCaloriesForRest) {
      calorieAdjustment -= _restDayCalorieReduction;
      baseCalories -= _restDayCalorieReduction;
      // Keep protein high, reduce carbs slightly on rest days
      baseCarbs = (baseCarbs * 0.9).round();

      adjustmentReason = 'rest_day';
      adjustmentNotes.add('Rest day (-$_restDayCalorieReduction cal)');
    }

    // Apply minimum calorie safety threshold
    final minCalories = gender.toLowerCase() == 'female'
        ? NutritionCalculator.minCaloriesFemale
        : NutritionCalculator.minCaloriesMale;

    if (baseCalories < minCalories) {
      baseCalories = minCalories;
      adjustmentNotes.add('Adjusted to safe minimum of $minCalories cal');
    }

    debugPrint('✅ [DynamicNutrition] Result: $baseCalories cal, reason: $adjustmentReason');

    return DynamicTargetsResult(
      targetCalories: baseCalories,
      targetProteinG: baseProtein,
      targetCarbsG: baseCarbs,
      targetFatG: baseFat,
      targetFiberG: baseFiber,
      isTrainingDay: isTrainingDay,
      isFastingDay: isFastingDay,
      isRestDay: isRestDay,
      adjustmentReason: adjustmentReason,
      calorieAdjustment: calorieAdjustment,
      adjustmentNotes: adjustmentNotes,
      weeklyContext: null,
    );
  }

  /// Calculate targets for a specific future date (for meal planning)
  DynamicTargetsResult calculateTargetsForDate({
    required NutritionPreferences preferences,
    required DateTime date,
    List<Workout>? weeklyWorkouts,
    FastingPreferences? fastingPreferences,
    required String gender,
  }) {
    // Find workout for this date
    Workout? workoutForDate;
    if (weeklyWorkouts != null) {
      final dateStr = date.toIso8601String().split('T').first;
      workoutForDate = weeklyWorkouts
          .where((w) => w.scheduledDate?.split('T').first == dateStr)
          .firstOrNull;
    }

    // Check if this date is a fasting day
    final isFastingDayForDate =
        _isFastingDayForDate(fastingPreferences, date);

    // Create a modified fasting preferences if needed
    FastingPreferences? modifiedFastingPrefs;
    if (isFastingDayForDate && fastingPreferences != null) {
      modifiedFastingPrefs = fastingPreferences;
    }

    return calculateTodaysTargets(
      preferences: preferences,
      todaysWorkout: workoutForDate,
      fastingPreferences: modifiedFastingPrefs,
      gender: gender,
    );
  }

  /// Check if today is a fasting day based on protocol
  bool _isFastingDay(FastingPreferences? prefs) {
    if (prefs == null) return false;

    final protocol = FastingProtocol.fromString(prefs.defaultProtocol);

    // Only 5:2 and ADF have designated fasting days
    if (protocol != FastingProtocol.fiveTwo && protocol != FastingProtocol.adf) {
      return false;
    }

    // For 5:2, check if today is in the fasting days list
    if (protocol == FastingProtocol.fiveTwo) {
      final today = DateTime.now();
      final dayName = _getDayName(today.weekday);
      return prefs.fastingDays?.contains(dayName) ?? false;
    }

    // For ADF, alternate days (check if day of year is odd/even)
    if (protocol == FastingProtocol.adf) {
      final today = DateTime.now();
      final dayOfYear = today.difference(DateTime(today.year, 1, 1)).inDays + 1;
      return dayOfYear % 2 == 1; // Odd days are fasting days
    }

    return false;
  }

  /// Check if a specific date is a fasting day
  bool _isFastingDayForDate(FastingPreferences? prefs, DateTime date) {
    if (prefs == null) return false;

    final protocol = FastingProtocol.fromString(prefs.defaultProtocol);

    if (protocol == FastingProtocol.fiveTwo) {
      final dayName = _getDayName(date.weekday);
      return prefs.fastingDays?.contains(dayName) ?? false;
    }

    if (protocol == FastingProtocol.adf) {
      final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
      return dayOfYear % 2 == 1;
    }

    return false;
  }

  /// Get day name from weekday number
  String _getDayName(int weekday) {
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    return days[weekday - 1];
  }

  /// Normalize workout intensity string
  String _normalizeIntensity(String? intensity) {
    if (intensity == null) return 'moderate';
    final lower = intensity.toLowerCase();
    if (lower.contains('easy') || lower.contains('low') || lower.contains('light')) {
      return 'low';
    }
    if (lower.contains('hard') || lower.contains('high') || lower.contains('intense')) {
      return 'high';
    }
    if (lower.contains('extreme') || lower.contains('very')) {
      return 'very_high';
    }
    return 'moderate';
  }

  /// Calculate weekly context for 5:2 and ADF protocols
  WeeklyNutritionContext? _calculateWeeklyContext(
    NutritionPreferences preferences,
    FastingPreferences? fastingPrefs,
    String gender,
  ) {
    if (fastingPrefs == null) return null;

    final protocol = FastingProtocol.fromString(fastingPrefs.defaultProtocol);

    if (protocol == FastingProtocol.fiveTwo) {
      final normalDayCalories = preferences.targetCalories ?? 2000;
      final fastingDayCalories = gender.toLowerCase() == 'female'
          ? _fiveTwoFemaleCalories
          : _fiveTwoMaleCalories;

      final weeklyTotal = (5 * normalDayCalories) + (2 * fastingDayCalories);
      final dailyAverage = weeklyTotal ~/ 7;

      return WeeklyNutritionContext(
        normalDayCalories: normalDayCalories,
        fastingDayCalories: fastingDayCalories,
        weeklyTotalCalories: weeklyTotal,
        dailyAverageCalories: dailyAverage,
        fastingDaysPerWeek: 2,
        fastingDays: fastingPrefs.fastingDays ?? [],
      );
    }

    if (protocol == FastingProtocol.adf) {
      final normalDayCalories = preferences.targetCalories ?? 2000;
      final fastingDayCalories = (normalDayCalories * 0.25).round();

      // 3.5 normal days, 3.5 fasting days per week
      final weeklyTotal =
          ((3.5 * normalDayCalories) + (3.5 * fastingDayCalories)).round();
      final dailyAverage = weeklyTotal ~/ 7;

      return WeeklyNutritionContext(
        normalDayCalories: normalDayCalories,
        fastingDayCalories: fastingDayCalories,
        weeklyTotalCalories: weeklyTotal,
        dailyAverageCalories: dailyAverage,
        fastingDaysPerWeek: 4, // Approximately
        fastingDays: ['alternate'],
      );
    }

    return null;
  }

  // ============================================
  // Post-Workout Nutrition Guidance
  // ============================================

  /// Get post-workout nutrition guidance
  PostWorkoutGuidance getPostWorkoutGuidance({
    required Workout completedWorkout,
    required bool wasFastedTraining,
    required int minutesSinceCompletion,
    required NutritionPreferences preferences,
  }) {
    final intensity = _normalizeIntensity(completedWorkout.difficulty);
    final workoutType = completedWorkout.type?.toLowerCase() ?? 'general';
    final isHighIntensity = intensity == 'high' || intensity == 'very_high';

    // Urgency based on fasted training, intensity, and time elapsed
    String urgency;
    if (wasFastedTraining && minutesSinceCompletion < 60) {
      urgency = 'high';
    } else if (isHighIntensity && minutesSinceCompletion < 60) {
      urgency = 'high';
    } else if (minutesSinceCompletion < 120) {
      urgency = 'medium';
    } else {
      urgency = 'low';
    }

    // Calculate macro targets for post-workout meal
    int proteinTarget;
    int carbsTarget;
    int fatTarget;

    if (wasFastedTraining) {
      // Higher protein priority after fasted training
      proteinTarget = 35;
      carbsTarget = 45;
      fatTarget = 10;
    } else if (workoutType.contains('strength') || workoutType.contains('resistance')) {
      proteinTarget = 30;
      carbsTarget = 40;
      fatTarget = 15;
    } else if (workoutType.contains('cardio') || workoutType.contains('endurance')) {
      proteinTarget = 20;
      carbsTarget = 60;
      fatTarget = 10;
    } else {
      proteinTarget = 25;
      carbsTarget = 50;
      fatTarget = 15;
    }

    // Generate suggestions
    List<MealSuggestion> suggestions;
    if (wasFastedTraining) {
      suggestions = [
        const MealSuggestion(
          name: 'Protein shake',
          description: '25-40g protein',
          quickOption: true,
        ),
        const MealSuggestion(
          name: 'Greek yogurt + fruit',
          description: '20g protein + carbs',
          quickOption: true,
        ),
        const MealSuggestion(
          name: 'Eggs + toast',
          description: '18g protein + carbs',
          quickOption: false,
        ),
      ];
    } else {
      suggestions = [
        const MealSuggestion(
          name: 'Chicken + rice',
          description: 'Complete recovery meal',
          quickOption: false,
        ),
        const MealSuggestion(
          name: 'Protein smoothie',
          description: 'Quick & effective',
          quickOption: true,
        ),
        const MealSuggestion(
          name: 'Tuna sandwich',
          description: 'Portable option',
          quickOption: true,
        ),
      ];
    }

    // Message based on urgency
    String message;
    if (urgency == 'high') {
      message = 'You trained fasted - prioritize protein now!';
    } else if (urgency == 'medium') {
      message = 'Fuel your recovery with protein and carbs';
    } else {
      message = 'When convenient, have a balanced meal';
    }

    return PostWorkoutGuidance(
      urgency: urgency,
      message: message,
      proteinTarget: proteinTarget,
      carbsTarget: carbsTarget,
      fatTarget: fatTarget,
      suggestions: suggestions,
      wasFastedTraining: wasFastedTraining,
      minutesSinceCompletion: minutesSinceCompletion,
    );
  }

  // ============================================
  // Pre-Workout Nutrition Guidance
  // ============================================

  /// Get pre-workout nutrition guidance
  PreWorkoutGuidance getPreWorkoutGuidance({
    required Workout upcomingWorkout,
    required int minutesUntilWorkout,
    required bool currentlyFasting,
    required int hoursFasted,
    required NutritionPreferences preferences,
  }) {
    final intensity = _normalizeIntensity(upcomingWorkout.difficulty);
    final workoutType = upcomingWorkout.type?.toLowerCase() ?? 'general';

    // Determine if eating before workout is recommended
    bool shouldEat;
    String recommendation;
    List<MealSuggestion> suggestions;

    if (intensity == 'high' || intensity == 'very_high') {
      // High intensity needs fuel
      if (hoursFasted > 14) {
        shouldEat = true;
        recommendation = 'High-intensity workouts aren\'t recommended after 14+ hours fasted. '
            'Consider a small pre-workout snack or moving to lighter exercise.';
        suggestions = [
          const MealSuggestion(
            name: 'Banana',
            description: 'Quick energy, 30 min before',
            quickOption: true,
          ),
          const MealSuggestion(
            name: 'Rice cake + honey',
            description: 'Fast carbs, 30 min before',
            quickOption: true,
          ),
        ];
      } else if (minutesUntilWorkout < 30) {
        shouldEat = false;
        recommendation = 'Too close to workout for a full meal. '
            'Have a small carb snack if needed.';
        suggestions = [];
      } else {
        shouldEat = minutesUntilWorkout >= 60;
        recommendation = 'Have a carb-focused snack 1-2 hours before for optimal performance.';
        suggestions = [
          const MealSuggestion(
            name: 'Greek yogurt + banana',
            description: '1-2 hours before',
            quickOption: false,
          ),
          const MealSuggestion(
            name: 'Oatmeal',
            description: '2-3 hours before',
            quickOption: false,
          ),
        ];
      }
    } else if (workoutType.contains('strength') && hoursFasted >= 12 && hoursFasted <= 16) {
      // Fasted strength training in this window can be beneficial
      shouldEat = false;
      recommendation = 'Good timing! Fasted strength training at 12-16h may boost growth hormone. '
          'Plan a protein-rich meal within 1-2 hours after.';
      suggestions = [];
    } else if (workoutType.contains('cardio') && intensity == 'low') {
      // Light cardio is fine fasted
      shouldEat = false;
      recommendation = 'Light cardio is perfect for fasted training. Great for fat burning!';
      suggestions = [];
    } else {
      // Default - moderate recommendation
      shouldEat = minutesUntilWorkout >= 90;
      recommendation = 'A light snack 1-2 hours before can help performance.';
      suggestions = [
        const MealSuggestion(
          name: 'Toast with peanut butter',
          description: '1-2 hours before',
          quickOption: true,
        ),
      ];
    }

    return PreWorkoutGuidance(
      shouldEat: shouldEat,
      recommendation: recommendation,
      suggestions: suggestions,
      minutesUntilWorkout: minutesUntilWorkout,
      currentlyFasting: currentlyFasting,
      hoursFasted: hoursFasted,
      workoutIntensity: intensity,
    );
  }
}

// ============================================
// Result Classes
// ============================================

/// Result of dynamic nutrition targets calculation
class DynamicTargetsResult {
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
  final List<String> adjustmentNotes;
  final WeeklyNutritionContext? weeklyContext;

  const DynamicTargetsResult({
    required this.targetCalories,
    required this.targetProteinG,
    required this.targetCarbsG,
    required this.targetFatG,
    required this.targetFiberG,
    required this.isTrainingDay,
    required this.isFastingDay,
    required this.isRestDay,
    required this.adjustmentReason,
    required this.calorieAdjustment,
    required this.adjustmentNotes,
    this.weeklyContext,
  });

  /// Convert to DynamicNutritionTargets (for API compatibility)
  DynamicNutritionTargets toDynamicNutritionTargets() {
    return DynamicNutritionTargets(
      targetCalories: targetCalories,
      targetProteinG: targetProteinG,
      targetCarbsG: targetCarbsG,
      targetFatG: targetFatG,
      targetFiberG: targetFiberG,
      isTrainingDay: isTrainingDay,
      isFastingDay: isFastingDay,
      isRestDay: isRestDay,
      adjustmentReason: adjustmentReason,
      calorieAdjustment: calorieAdjustment,
    );
  }
}

/// Weekly nutrition context for modified fasting protocols
class WeeklyNutritionContext {
  final int normalDayCalories;
  final int fastingDayCalories;
  final int weeklyTotalCalories;
  final int dailyAverageCalories;
  final int fastingDaysPerWeek;
  final List<String> fastingDays;

  const WeeklyNutritionContext({
    required this.normalDayCalories,
    required this.fastingDayCalories,
    required this.weeklyTotalCalories,
    required this.dailyAverageCalories,
    required this.fastingDaysPerWeek,
    required this.fastingDays,
  });
}

/// Post-workout nutrition guidance
class PostWorkoutGuidance {
  final String urgency; // 'high', 'medium', 'low'
  final String message;
  final int proteinTarget;
  final int carbsTarget;
  final int fatTarget;
  final List<MealSuggestion> suggestions;
  final bool wasFastedTraining;
  final int minutesSinceCompletion;

  const PostWorkoutGuidance({
    required this.urgency,
    required this.message,
    required this.proteinTarget,
    required this.carbsTarget,
    required this.fatTarget,
    required this.suggestions,
    required this.wasFastedTraining,
    required this.minutesSinceCompletion,
  });
}

/// Pre-workout nutrition guidance
class PreWorkoutGuidance {
  final bool shouldEat;
  final String recommendation;
  final List<MealSuggestion> suggestions;
  final int minutesUntilWorkout;
  final bool currentlyFasting;
  final int hoursFasted;
  final String workoutIntensity;

  const PreWorkoutGuidance({
    required this.shouldEat,
    required this.recommendation,
    required this.suggestions,
    required this.minutesUntilWorkout,
    required this.currentlyFasting,
    required this.hoursFasted,
    required this.workoutIntensity,
  });
}

/// Meal suggestion for pre/post workout
class MealSuggestion {
  final String name;
  final String description;
  final bool quickOption;

  const MealSuggestion({
    required this.name,
    required this.description,
    this.quickOption = false,
  });
}
