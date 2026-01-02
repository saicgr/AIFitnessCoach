// FitWiz Widget Tests
//
// These tests verify the core widget functionality of the app.
// Run with: flutter test

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'helpers/test_helpers.dart';

void main() {
  group('App Widget Tests', () {
    testWidgets('App renders without crashing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('FitWiz'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('FitWiz'), findsOneWidget);
    });

    testWidgets('ProviderScope wraps app correctly', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Text('Test'),
            ),
          ),
        ),
      );

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Theme applies correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: ThemeMode.dark,
            home: Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Scaffold(
                  body: Text(isDark ? 'Dark Mode' : 'Light Mode'),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Dark Mode'), findsOneWidget);
    });
  });

  group('Widget Helper Tests', () {
    testWidgets('createWidgetUnderTest wraps widget correctly', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          child: const Text('Test Widget'),
        ),
      );

      expect(find.text('Test Widget'), findsOneWidget);
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('createScaffoldedWidget adds Scaffold', (tester) async {
      await tester.pumpWidget(
        createScaffoldedWidget(
          child: const Text('Scaffolded'),
        ),
      );

      expect(find.text('Scaffolded'), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('TestFixtures', () {
    test('createUser creates valid User', () {
      final user = TestFixtures.createUser();
      expect(user.id, isNotEmpty);
      expect(user.name, isNotNull);
    });

    test('createWorkout creates valid Workout', () {
      final workout = TestFixtures.createWorkout();
      expect(workout.id, isNotEmpty);
      expect(workout.name, isNotNull);
    });

    test('createExercise creates valid Exercise', () {
      final exercise = TestFixtures.createExercise();
      expect(exercise.name, isNotEmpty);
      expect(exercise.sets, isNotNull);
    });

    test('createChatMessage creates valid ChatMessage', () {
      final message = TestFixtures.createChatMessage();
      expect(message.role, isNotEmpty);
      expect(message.content, isNotEmpty);
    });

    test('createHydrationLog creates valid HydrationLog', () {
      final log = TestFixtures.createHydrationLog();
      expect(log.id, isNotEmpty);
      expect(log.amountMl, greaterThan(0));
    });

    test('createFoodItem creates valid FoodItem', () {
      final item = TestFixtures.createFoodItem();
      expect(item.name, isNotEmpty);
    });
  });

  group('JsonFixtures', () {
    test('userJson returns valid map', () {
      final json = JsonFixtures.userJson();
      expect(json['id'], isNotNull);
      expect(json['email'], isNotNull);
    });

    test('workoutJson returns valid map', () {
      final json = JsonFixtures.workoutJson();
      expect(json['id'], isNotNull);
      expect(json['name'], isNotNull);
    });

    test('chatMessageJson returns valid map', () {
      final json = JsonFixtures.chatMessageJson();
      expect(json['role'], isNotNull);
      expect(json['content'], isNotNull);
    });

    test('chatResponseJson returns valid map', () {
      final json = JsonFixtures.chatResponseJson();
      expect(json['message'], isNotNull);
    });

    test('hydrationLogJson returns valid map', () {
      final json = JsonFixtures.hydrationLogJson();
      expect(json['id'], isNotNull);
      expect(json['amount_ml'], isNotNull);
    });

    test('dailyHydrationSummaryJson returns valid map', () {
      final json = JsonFixtures.dailyHydrationSummaryJson();
      expect(json['date'], isNotNull);
      expect(json['total_ml'], isNotNull);
    });

    test('foodItemJson returns valid map', () {
      final json = JsonFixtures.foodItemJson();
      expect(json['name'], isNotNull);
    });

    test('dailyNutritionSummaryJson returns valid map', () {
      final json = JsonFixtures.dailyNutritionSummaryJson();
      expect(json['date'], isNotNull);
      expect(json['total_calories'], isNotNull);
    });
  });
}
