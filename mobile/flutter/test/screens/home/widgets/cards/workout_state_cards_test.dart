import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/screens/home/widgets/cards/workout_state_cards.dart';
import '../../test_helpers.dart';

void main() {
  group('EmptyWorkoutCard', () {
    testWidgets('renders empty state message', (tester) async {
      await tester.pumpWidget(createTestWidget(
        EmptyWorkoutCard(onGenerate: () {}),
      ));

      expect(find.text('No workouts scheduled'), findsOneWidget);
      expect(find.text('Complete setup to get your personalized workout plan'),
          findsOneWidget);
    });

    testWidgets('renders generate button', (tester) async {
      await tester.pumpWidget(createTestWidget(
        EmptyWorkoutCard(onGenerate: () {}),
      ));

      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('calls onGenerate when button is tapped', (tester) async {
      bool wasCalled = false;

      await tester.pumpWidget(createTestWidget(
        EmptyWorkoutCard(onGenerate: () => wasCalled = true),
      ));

      await tester.tap(find.text('Get Started'));
      await tester.pump();

      expect(wasCalled, isTrue);
    });

    testWidgets('renders fitness icon', (tester) async {
      await tester.pumpWidget(createTestWidget(
        EmptyWorkoutCard(onGenerate: () {}),
      ));

      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
    });
  });

  group('GeneratingWorkoutsCard', () {
    testWidgets('renders default message', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const GeneratingWorkoutsCard(),
      ));

      expect(find.text('Generating your workouts...'), findsOneWidget);
    });

    testWidgets('renders custom message', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const GeneratingWorkoutsCard(
          message: 'AI is generating your workout...',
        ),
      ));

      expect(find.text('AI is generating your workout...'), findsOneWidget);
    });

    testWidgets('renders custom subtitle', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const GeneratingWorkoutsCard(
          subtitle: 'This may take a moment',
        ),
      ));

      expect(find.text('This may take a moment'), findsOneWidget);
    });

    testWidgets('renders loading indicator', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const GeneratingWorkoutsCard(),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('LoadingCard', () {
    testWidgets('renders loading skeleton', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const LoadingCard(),
      ));

      expect(find.byType(LoadingCard), findsOneWidget);
    });
  });

  group('ErrorCard', () {
    testWidgets('renders error message', (tester) async {
      await tester.pumpWidget(createTestWidget(
        ErrorCard(
          message: 'Failed to load workouts',
          onRetry: () {},
        ),
      ));

      expect(find.text('Failed to load workouts'), findsOneWidget);
    });

    testWidgets('renders retry button', (tester) async {
      await tester.pumpWidget(createTestWidget(
        ErrorCard(
          message: 'Error',
          onRetry: () {},
        ),
      ));

      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('calls onRetry when retry button is tapped', (tester) async {
      bool wasCalled = false;

      await tester.pumpWidget(createTestWidget(
        ErrorCard(
          message: 'Error',
          onRetry: () => wasCalled = true,
        ),
      ));

      await tester.tap(find.text('Try Again'));
      await tester.pump();

      expect(wasCalled, isTrue);
    });

    testWidgets('renders error icon', (tester) async {
      await tester.pumpWidget(createTestWidget(
        ErrorCard(
          message: 'Error',
          onRetry: () {},
        ),
      ));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });

  group('MoreWorkoutsLoadingBanner', () {
    testWidgets('renders loading indicator', (tester) async {
      await tester.pumpWidget(createTestWidget(
        MoreWorkoutsLoadingBanner(
          isDark: true,
          startDate: DateTime.now().toIso8601String(),
          weeks: 4,
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows week count', (tester) async {
      await tester.pumpWidget(createTestWidget(
        MoreWorkoutsLoadingBanner(
          isDark: true,
          startDate: '2024-01-15',
          weeks: 4,
        ),
      ));

      expect(find.textContaining('4 weeks'), findsOneWidget);
    });

    testWidgets('shows progress when provided', (tester) async {
      await tester.pumpWidget(createTestWidget(
        MoreWorkoutsLoadingBanner(
          isDark: true,
          startDate: '2024-01-15',
          weeks: 4,
          totalExpected: 12,
          totalGenerated: 5,
        ),
      ));

      expect(find.textContaining('5 of 12'), findsOneWidget);
    });
  });
}
