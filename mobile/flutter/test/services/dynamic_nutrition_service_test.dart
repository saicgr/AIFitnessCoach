import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/data/services/dynamic_nutrition_service.dart';
import 'package:ai_fitness_coach/data/models/nutrition_preferences.dart';
import 'package:ai_fitness_coach/data/models/fasting.dart';
import 'package:ai_fitness_coach/data/models/workout.dart';

void main() {
  group('DynamicNutritionService', () {
    late DynamicNutritionService service;
    late NutritionPreferences basePreferences;

    setUp(() {
      service = DynamicNutritionService();
      basePreferences = NutritionPreferences(
        userId: 'test-user',
        nutritionGoal: 'maintain',
        calculatedBmr: 1800,
        calculatedTdee: 2500,
        targetCalories: 2500,
        targetProteinG: 150,
        targetCarbsG: 280,
        targetFatG: 85,
        targetFiberG: 30,
        dietType: 'balanced',
        mealPattern: 'three_meals',
        nutritionOnboardingCompleted: true,
        adjustCaloriesForTraining: true,
        adjustCaloriesForRest: true,
      );
    });

    group('calculateTodaysTargets', () {
      test('should return base targets on rest day', () {
        final result = service.calculateTodaysTargets(
          preferences: basePreferences,
          todaysWorkout: null,
          gender: 'male',
        );

        // Rest day with adjustments enabled = -100 cal
        expect(result.targetCalories, 2400);
        expect(result.targetProteinG, 150);
        expect(result.isRestDay, true);
        expect(result.isFastingDay, false);
        expect(result.adjustmentReason, 'rest_day');
      });

      test('should return unadjusted base targets when rest adjustments disabled',
          () {
        final prefsNoAdjust = basePreferences.copyWith(
          adjustCaloriesForRest: false,
        );

        final result = service.calculateTodaysTargets(
          preferences: prefsNoAdjust,
          todaysWorkout: null,
          gender: 'male',
        );

        expect(result.targetCalories, 2500);
        expect(result.adjustmentReason, 'base_targets');
      });

      test('should add calories for high-intensity workout', () {
        final workout = _createMockWorkout(difficulty: 'high');

        final result = service.calculateTodaysTargets(
          preferences: basePreferences,
          todaysWorkout: workout,
          gender: 'male',
        );

        expect(result.targetCalories, greaterThan(2500)); // Should add 200 cal
        expect(result.isTrainingDay, true);
        expect(result.adjustmentReason, 'training_day');
        expect(result.adjustmentNotes.any((n) => n.contains('Training day')), true);
      });

      test('should add fewer calories for moderate workout', () {
        final workout = _createMockWorkout(difficulty: 'moderate');

        final result = service.calculateTodaysTargets(
          preferences: basePreferences,
          todaysWorkout: workout,
          gender: 'male',
        );

        expect(result.targetCalories, greaterThan(2500)); // Should add 100 cal
        expect(result.targetCalories, lessThan(2700)); // But less than high intensity
      });

      test('should add even fewer calories for low workout', () {
        final workout = _createMockWorkout(difficulty: 'low');

        final result = service.calculateTodaysTargets(
          preferences: basePreferences,
          todaysWorkout: workout,
          gender: 'male',
        );

        // Low intensity adds 50 cal
        expect(result.targetCalories, 2550);
      });

      test('should increase carbs on training days', () {
        final workout = _createMockWorkout(difficulty: 'high');

        final result = service.calculateTodaysTargets(
          preferences: basePreferences,
          todaysWorkout: workout,
          gender: 'male',
        );

        // High intensity multiplies carbs by 1.2
        expect(result.targetCarbsG, greaterThan(300));
      });

      test('should reduce calories on 5:2 fasting day', () {
        final prefsWithFasting = basePreferences;
        final fastingPrefs = FastingPreferences(
          userId: 'test-user',
          defaultProtocol: '5:2',
          fastingDays: [_getDayName(DateTime.now().weekday)], // Today is a fasting day
        );

        final result = service.calculateTodaysTargets(
          preferences: prefsWithFasting,
          todaysWorkout: null,
          fastingPreferences: fastingPrefs,
          gender: 'male',
        );

        expect(result.targetCalories, lessThan(700)); // 600 cal for men on 5:2
        expect(result.isFastingDay, true);
        expect(result.adjustmentReason, 'fasting_day');
      });

      test('should use 500 calories for female on 5:2 fasting day', () {
        final fastingPrefs = FastingPreferences(
          userId: 'test-user',
          defaultProtocol: '5:2',
          fastingDays: [_getDayName(DateTime.now().weekday)],
        );

        final result = service.calculateTodaysTargets(
          preferences: basePreferences,
          todaysWorkout: null,
          fastingPreferences: fastingPrefs,
          gender: 'female',
        );

        expect(result.targetCalories, 500);
      });

      test('should enforce minimum calories for females', () {
        final lowCalPrefs = basePreferences.copyWith(targetCalories: 1000);

        final result = service.calculateTodaysTargets(
          preferences: lowCalPrefs,
          todaysWorkout: null,
          gender: 'female',
        );

        expect(result.targetCalories, greaterThanOrEqualTo(1200));
      });

      test('should enforce minimum calories for males', () {
        final lowCalPrefs = basePreferences.copyWith(targetCalories: 1200);

        final result = service.calculateTodaysTargets(
          preferences: lowCalPrefs,
          todaysWorkout: null,
          gender: 'male',
        );

        expect(result.targetCalories, greaterThanOrEqualTo(1500));
      });
    });

    group('getPostWorkoutGuidance', () {
      test('should return high urgency for fasted training within 60 min', () {
        final workout = _createMockWorkout(difficulty: 'high');

        final guidance = service.getPostWorkoutGuidance(
          completedWorkout: workout,
          wasFastedTraining: true,
          minutesSinceCompletion: 30,
          preferences: basePreferences,
        );

        expect(guidance.urgency, 'high');
        expect(guidance.wasFastedTraining, true);
        expect(guidance.proteinTarget, greaterThan(0));
      });

      test('should return high urgency for high intensity workout within 60 min',
          () {
        final workout = _createMockWorkout(difficulty: 'high');

        final guidance = service.getPostWorkoutGuidance(
          completedWorkout: workout,
          wasFastedTraining: false,
          minutesSinceCompletion: 45,
          preferences: basePreferences,
        );

        expect(guidance.urgency, 'high');
      });

      test('should return medium urgency between 60-120 min', () {
        final workout = _createMockWorkout(difficulty: 'moderate');

        final guidance = service.getPostWorkoutGuidance(
          completedWorkout: workout,
          wasFastedTraining: false,
          minutesSinceCompletion: 90,
          preferences: basePreferences,
        );

        expect(guidance.urgency, 'medium');
      });

      test('should return low urgency after 2 hours', () {
        final workout = _createMockWorkout(difficulty: 'low');

        final guidance = service.getPostWorkoutGuidance(
          completedWorkout: workout,
          wasFastedTraining: false,
          minutesSinceCompletion: 130,
          preferences: basePreferences,
        );

        expect(guidance.urgency, 'low');
      });

      test('should include meal suggestions', () {
        final workout = _createMockWorkout();

        final guidance = service.getPostWorkoutGuidance(
          completedWorkout: workout,
          wasFastedTraining: false,
          minutesSinceCompletion: 30,
          preferences: basePreferences,
        );

        expect(guidance.suggestions, isNotEmpty);
        expect(guidance.suggestions.first.name, isNotEmpty);
      });

      test('should prioritize protein for fasted training', () {
        final workout = _createMockWorkout(difficulty: 'high');

        final guidance = service.getPostWorkoutGuidance(
          completedWorkout: workout,
          wasFastedTraining: true,
          minutesSinceCompletion: 30,
          preferences: basePreferences,
        );

        expect(guidance.proteinTarget, 35); // Higher protein for fasted
        expect(guidance.message, contains('fasted'));
      });

      test('should adjust macros for strength vs cardio workouts', () {
        final strengthWorkout = _createMockWorkout(type: 'strength');
        final cardioWorkout = _createMockWorkout(type: 'cardio');

        final strengthGuidance = service.getPostWorkoutGuidance(
          completedWorkout: strengthWorkout,
          wasFastedTraining: false,
          minutesSinceCompletion: 30,
          preferences: basePreferences,
        );

        final cardioGuidance = service.getPostWorkoutGuidance(
          completedWorkout: cardioWorkout,
          wasFastedTraining: false,
          minutesSinceCompletion: 30,
          preferences: basePreferences,
        );

        // Strength should have higher protein, cardio should have higher carbs
        expect(strengthGuidance.proteinTarget, greaterThan(cardioGuidance.proteinTarget));
        expect(cardioGuidance.carbsTarget, greaterThan(strengthGuidance.carbsTarget));
      });
    });

    group('getPreWorkoutGuidance', () {
      test('should recommend eating if not fasting and workout soon', () {
        final guidance = service.getPreWorkoutGuidance(
          upcomingWorkout: _createMockWorkout(difficulty: 'high'),
          minutesUntilWorkout: 60,
          currentlyFasting: false,
          hoursFasted: 0,
          preferences: basePreferences,
        );

        expect(guidance.shouldEat, true);
        expect(guidance.minutesUntilWorkout, 60);
      });

      test('should respect fasting state', () {
        final guidance = service.getPreWorkoutGuidance(
          upcomingWorkout: _createMockWorkout(difficulty: 'moderate'),
          minutesUntilWorkout: 60,
          currentlyFasting: true,
          hoursFasted: 14,
          preferences: basePreferences,
        );

        expect(guidance.currentlyFasting, true);
        expect(guidance.hoursFasted, 14);
      });

      test('should warn about high intensity + extended fast', () {
        final guidance = service.getPreWorkoutGuidance(
          upcomingWorkout: _createMockWorkout(difficulty: 'high'),
          minutesUntilWorkout: 60,
          currentlyFasting: true,
          hoursFasted: 16,
          preferences: basePreferences,
        );

        expect(guidance.shouldEat, true);
        expect(guidance.recommendation, contains('14+'));
      });

      test('should encourage fasted strength at 12-16h', () {
        final guidance = service.getPreWorkoutGuidance(
          upcomingWorkout: _createMockWorkout(
            type: 'strength',
            difficulty: 'moderate',
          ),
          minutesUntilWorkout: 60,
          currentlyFasting: true,
          hoursFasted: 14,
          preferences: basePreferences,
        );

        expect(guidance.shouldEat, false);
        expect(guidance.recommendation, contains('Fasted strength'));
      });

      test('should recommend not eating if too close to workout', () {
        final guidance = service.getPreWorkoutGuidance(
          upcomingWorkout: _createMockWorkout(difficulty: 'high'),
          minutesUntilWorkout: 15,
          currentlyFasting: false,
          hoursFasted: 4,
          preferences: basePreferences,
        );

        expect(guidance.shouldEat, false);
        expect(guidance.recommendation, contains('close'));
      });

      test('should include pre-workout meal suggestions', () {
        final guidance = service.getPreWorkoutGuidance(
          upcomingWorkout: _createMockWorkout(),
          minutesUntilWorkout: 90,
          currentlyFasting: false,
          hoursFasted: 0,
          preferences: basePreferences,
        );

        expect(guidance.suggestions, isNotEmpty);
      });
    });
  });

  group('DynamicTargetsResult', () {
    test('should create result with all fields', () {
      const result = DynamicTargetsResult(
        targetCalories: 2500,
        targetProteinG: 150,
        targetCarbsG: 280,
        targetFatG: 85,
        targetFiberG: 30,
        isTrainingDay: true,
        isFastingDay: false,
        isRestDay: false,
        adjustmentReason: 'training_day',
        calorieAdjustment: 200,
        adjustmentNotes: ['Training day (+200 cal)'],
      );

      expect(result.targetCalories, 2500);
      expect(result.targetProteinG, 150);
      expect(result.isTrainingDay, true);
      expect(result.adjustmentReason, 'training_day');
    });

    test('should convert to DynamicNutritionTargets', () {
      const result = DynamicTargetsResult(
        targetCalories: 2500,
        targetProteinG: 150,
        targetCarbsG: 280,
        targetFatG: 85,
        targetFiberG: 30,
        isTrainingDay: true,
        isFastingDay: false,
        isRestDay: false,
        adjustmentReason: 'training_day',
        calorieAdjustment: 200,
        adjustmentNotes: [],
      );

      final targets = result.toDynamicNutritionTargets();

      expect(targets.targetCalories, 2500);
      expect(targets.targetProteinG, 150);
      expect(targets.isTrainingDay, true);
    });
  });

  group('PostWorkoutGuidance', () {
    test('should have all required properties', () {
      const guidance = PostWorkoutGuidance(
        urgency: 'high',
        message: 'Test message',
        proteinTarget: 30,
        carbsTarget: 50,
        fatTarget: 10,
        suggestions: [],
        wasFastedTraining: true,
        minutesSinceCompletion: 30,
      );

      expect(guidance.urgency, 'high');
      expect(guidance.proteinTarget, 30);
      expect(guidance.wasFastedTraining, true);
    });
  });

  group('PreWorkoutGuidance', () {
    test('should have all required properties', () {
      const guidance = PreWorkoutGuidance(
        shouldEat: true,
        recommendation: 'Test recommendation',
        suggestions: [],
        minutesUntilWorkout: 60,
        currentlyFasting: false,
        hoursFasted: 0,
        workoutIntensity: 'moderate',
      );

      expect(guidance.shouldEat, true);
      expect(guidance.minutesUntilWorkout, 60);
      expect(guidance.workoutIntensity, 'moderate');
    });
  });

  group('WeeklyNutritionContext', () {
    test('should calculate weekly averages', () {
      const context = WeeklyNutritionContext(
        normalDayCalories: 2500,
        fastingDayCalories: 600,
        weeklyTotalCalories: 13700, // 5*2500 + 2*600
        dailyAverageCalories: 1957,
        fastingDaysPerWeek: 2,
        fastingDays: ['monday', 'thursday'],
      );

      expect(context.normalDayCalories, 2500);
      expect(context.fastingDayCalories, 600);
      expect(context.fastingDaysPerWeek, 2);
    });
  });
}

/// Helper to create mock workout for testing
Workout _createMockWorkout({
  String type = 'strength',
  String difficulty = 'moderate',
  int durationMinutes = 60,
}) {
  return Workout(
    id: 'test-workout',
    userId: 'test-user',
    name: 'Test Workout',
    type: type,
    difficulty: difficulty,
    durationMinutes: durationMinutes,
    scheduledDate: DateTime.now().toIso8601String(),
  );
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
