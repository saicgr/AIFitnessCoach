import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:ai_fitness_coach/data/services/api_client.dart';
import 'package:ai_fitness_coach/data/models/user.dart';
import 'package:ai_fitness_coach/data/models/workout.dart';
import 'package:ai_fitness_coach/data/models/exercise.dart';
import 'package:ai_fitness_coach/data/models/chat_message.dart';
import 'package:ai_fitness_coach/data/models/achievement.dart';
import 'package:ai_fitness_coach/data/models/hydration.dart';
import 'package:ai_fitness_coach/data/models/nutrition.dart';

// Mock classes
class MockDio extends Mock implements Dio {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockApiClient extends Mock implements ApiClient {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

// Fake classes for registerFallbackValue
class FakeUri extends Fake implements Uri {}

class FakeRequestOptions extends Fake implements RequestOptions {}

class FakeResponse extends Fake implements Response {}

// Test fixtures
class TestFixtures {
  // Sample user for testing
  static User createUser({
    String id = 'test-user-id',
    String? username = 'testuser',
    String? name = 'Test User',
    String? email = 'test@example.com',
    String? fitnessLevel = 'intermediate',
    String? goals,
    String? equipment,
    String? preferences,
    String? activeInjuries,
    double? heightCm = 175.0,
    double? weightKg = 70.0,
    int? age = 30,
    String? gender = 'male',
    bool? onboardingCompleted = true,
  }) {
    return User(
      id: id,
      username: username,
      name: name,
      email: email,
      fitnessLevel: fitnessLevel,
      goals: goals ?? '["Build muscle", "Lose weight"]',
      equipment: equipment ?? '["Dumbbells", "Barbell"]',
      preferences: preferences ?? '{"workout_days": [0, 2, 4], "workout_environment": "commercial_gym"}',
      activeInjuries: activeInjuries,
      heightCm: heightCm,
      weightKg: weightKg,
      age: age,
      gender: gender,
      onboardingCompleted: onboardingCompleted,
    );
  }

  // Sample workout for testing
  static Workout createWorkout({
    String? id = 'test-workout-id',
    String? userId = 'test-user-id',
    String? name = 'Test Workout',
    String? type = 'strength',
    String? difficulty = 'intermediate',
    String? scheduledDate,
    bool? isCompleted = false,
    dynamic exercisesJson,
    int? durationMinutes = 45,
  }) {
    return Workout(
      id: id,
      userId: userId,
      name: name,
      type: type,
      difficulty: difficulty,
      scheduledDate: scheduledDate ?? DateTime.now().toIso8601String().split('T')[0],
      isCompleted: isCompleted,
      exercisesJson: exercisesJson ?? [
        {
          'name': 'Bench Press',
          'sets': 3,
          'reps': 10,
          'rest_seconds': 60,
          'muscle_group': 'chest',
          'equipment': 'Barbell',
        },
        {
          'name': 'Squats',
          'sets': 4,
          'reps': 8,
          'rest_seconds': 90,
          'muscle_group': 'legs',
          'equipment': 'Barbell',
        },
      ],
      durationMinutes: durationMinutes,
    );
  }

  // Sample exercise for testing
  static WorkoutExercise createExercise({
    String? id = 'test-exercise-id',
    String? nameValue = 'Bench Press',
    int? sets = 3,
    int? reps = 10,
    int? restSeconds = 60,
    double? weight = 60.0,
    String? muscleGroup = 'chest',
    String? equipment = 'Barbell',
    String? instructions = 'Lower the bar to your chest, then push up.',
  }) {
    return WorkoutExercise(
      id: id,
      nameValue: nameValue,
      sets: sets,
      reps: reps,
      restSeconds: restSeconds,
      weight: weight,
      muscleGroup: muscleGroup,
      equipment: equipment,
      instructions: instructions,
    );
  }

  // Sample chat message for testing
  static ChatMessage createChatMessage({
    String? id = 'test-message-id',
    String? userId = 'test-user-id',
    String role = 'user',
    String content = 'Hello, coach!',
    String? intent,
    AgentType? agentType,
    String? createdAt,
  }) {
    return ChatMessage(
      id: id,
      userId: userId,
      role: role,
      content: content,
      intent: intent,
      agentType: agentType,
      createdAt: createdAt ?? DateTime.now().toIso8601String(),
    );
  }

  // Sample achievement type for testing
  static AchievementType createAchievementType({
    String id = 'test-achievement-type-id',
    String name = 'First Workout',
    String description = 'Complete your first workout',
    String category = 'workout',
    String icon = 'trophy',
    String tier = 'bronze',
    int points = 10,
  }) {
    return AchievementType(
      id: id,
      name: name,
      description: description,
      category: category,
      icon: icon,
      tier: tier,
      points: points,
    );
  }

  // Sample hydration log for testing
  static HydrationLog createHydrationLog({
    String id = 'test-hydration-id',
    String userId = 'test-user-id',
    String drinkType = 'water',
    int amountMl = 250,
    DateTime? loggedAt,
  }) {
    return HydrationLog(
      id: id,
      userId: userId,
      drinkType: drinkType,
      amountMl: amountMl,
      loggedAt: loggedAt ?? DateTime.now(),
    );
  }

  // Sample food item for testing
  static FoodItem createFoodItem({
    String name = 'Chicken Breast',
    String? amount = '200g',
    int? calories = 330,
    double? proteinG = 62.0,
    double? carbsG = 0.0,
    double? fatG = 7.0,
  }) {
    return FoodItem(
      name: name,
      amount: amount,
      calories: calories,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
    );
  }
}

// Widget test helpers
Widget createWidgetUnderTest({
  required Widget child,
  List<Override>? overrides,
  List<NavigatorObserver>? navigatorObservers,
}) {
  return ProviderScope(
    overrides: overrides ?? [],
    child: MaterialApp(
      home: child,
      navigatorObservers: navigatorObservers ?? [],
    ),
  );
}

Widget createScaffoldedWidget({
  required Widget child,
  List<Override>? overrides,
}) {
  return ProviderScope(
    overrides: overrides ?? [],
    child: MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

// Extension for common test patterns
extension WidgetTesterX on WidgetTester {
  Future<void> pumpApp(Widget widget, {List<Override>? overrides}) async {
    await pumpWidget(createWidgetUnderTest(
      child: widget,
      overrides: overrides,
    ));
  }

  Future<void> pumpAndSettleApp(Widget widget, {List<Override>? overrides}) async {
    await pumpWidget(createWidgetUnderTest(
      child: widget,
      overrides: overrides,
    ));
    await pumpAndSettle();
  }
}

// Setup for mocks
void setUpMocks() {
  registerFallbackValue(FakeUri());
  registerFallbackValue(FakeRequestOptions());
  registerFallbackValue(FakeResponse());
}

// JSON fixtures for API response testing
class JsonFixtures {
  static Map<String, dynamic> userJson() => {
    'id': 'test-user-id',
    'username': 'testuser',
    'name': 'Test User',
    'email': 'test@example.com',
    'fitness_level': 'intermediate',
    'goals': '["Build muscle", "Lose weight"]',
    'equipment': '["Dumbbells", "Barbell"]',
    'preferences': '{"workout_days": [0, 2, 4]}',
    'height_cm': 175.0,
    'weight_kg': 70.0,
    'age': 30,
    'gender': 'male',
    'onboarding_completed': true,
  };

  static Map<String, dynamic> workoutJson() => {
    'id': 'test-workout-id',
    'user_id': 'test-user-id',
    'name': 'Test Workout',
    'type': 'strength',
    'difficulty': 'intermediate',
    'scheduled_date': DateTime.now().toIso8601String().split('T')[0],
    'is_completed': false,
    'duration_minutes': 45,
    'exercises_json': [
      {
        'name': 'Bench Press',
        'sets': 3,
        'reps': 10,
        'rest_seconds': 60,
      }
    ],
  };

  static Map<String, dynamic> chatMessageJson() => {
    'id': 'test-message-id',
    'user_id': 'test-user-id',
    'role': 'assistant',
    'content': 'Hello! I am your AI fitness coach.',
    'intent': 'greeting',
    'agent_type': 'coach',
    'created_at': DateTime.now().toIso8601String(),
  };

  static Map<String, dynamic> chatResponseJson() => {
    'message': 'Hello! How can I help you today?',
    'intent': 'greeting',
    'agent_type': 'coach',
    'action_data': null,
  };

  static Map<String, dynamic> achievementTypeJson() => {
    'id': 'test-achievement-type-id',
    'name': 'First Workout',
    'description': 'Complete your first workout',
    'category': 'workout',
    'icon': 'trophy',
    'tier': 'bronze',
    'points': 10,
    'is_repeatable': false,
  };

  static Map<String, dynamic> hydrationLogJson() => {
    'id': 'test-hydration-id',
    'user_id': 'test-user-id',
    'drink_type': 'water',
    'amount_ml': 250,
    'logged_at': DateTime.now().toIso8601String(),
  };

  static Map<String, dynamic> dailyHydrationSummaryJson() => {
    'date': DateTime.now().toIso8601String().split('T')[0],
    'total_ml': 2000,
    'water_ml': 1500,
    'protein_shake_ml': 300,
    'sports_drink_ml': 200,
    'other_ml': 0,
    'goal_ml': 2500,
    'goal_percentage': 0.8,
    'entries': [],
  };

  static Map<String, dynamic> foodItemJson() => {
    'name': 'Chicken Breast',
    'amount': '200g',
    'calories': 330,
    'protein_g': 62.0,
    'carbs_g': 0.0,
    'fat_g': 7.0,
  };

  static Map<String, dynamic> dailyNutritionSummaryJson() => {
    'date': DateTime.now().toIso8601String().split('T')[0],
    'total_calories': 2000,
    'total_protein_g': 150.0,
    'total_carbs_g': 200.0,
    'total_fat_g': 67.0,
    'total_fiber_g': 25.0,
    'meal_count': 3,
    'avg_health_score': 75.0,
    'meals': [],
  };
}
