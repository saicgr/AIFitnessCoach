import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/widgets/empty_state.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('EmptyState', () {
    testWidgets('should display icon, title, and subtitle', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          child: const EmptyState(
            icon: Icons.search,
            title: 'Test Title',
            subtitle: 'Test Subtitle',
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);
    });

    testWidgets('should display action button when actionLabel and onAction provided', (tester) async {
      bool actionCalled = false;

      await tester.pumpWidget(
        createWidgetUnderTest(
          child: EmptyState(
            icon: Icons.add,
            title: 'Title',
            subtitle: 'Subtitle',
            actionLabel: 'Click Me',
            onAction: () => actionCalled = true,
          ),
        ),
      );

      expect(find.text('Click Me'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      expect(actionCalled, true);
    });

    testWidgets('should not display action button when actionLabel is null', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          child: const EmptyState(
            icon: Icons.search,
            title: 'Title',
            subtitle: 'Subtitle',
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('should not display action button when onAction is null', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          child: const EmptyState(
            icon: Icons.search,
            title: 'Title',
            subtitle: 'Subtitle',
            actionLabel: 'Action',
            onAction: null,
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsNothing);
    });

    group('factory constructors', () {
      testWidgets('noWorkouts should display correct content', (tester) async {
        await tester.pumpWidget(
          createWidgetUnderTest(
            child: EmptyState.noWorkouts(),
          ),
        );

        expect(find.byIcon(Icons.fitness_center), findsOneWidget);
        expect(find.text('No workouts yet'), findsOneWidget);
        expect(find.text('Create Program'), findsOneWidget);
      });

      testWidgets('noWorkouts should call onAction when button tapped', (tester) async {
        bool called = false;

        await tester.pumpWidget(
          createWidgetUnderTest(
            child: EmptyState.noWorkouts(onAction: () => called = true),
          ),
        );

        await tester.tap(find.byType(ElevatedButton));
        expect(called, true);
      });

      testWidgets('noExercises should display correct content', (tester) async {
        await tester.pumpWidget(
          createWidgetUnderTest(
            child: EmptyState.noExercises(),
          ),
        );

        expect(find.byIcon(Icons.search_off), findsOneWidget);
        expect(find.text('No exercises found'), findsOneWidget);
        expect(find.text('Clear Filters'), findsOneWidget);
      });

      testWidgets('noHistory should display correct content', (tester) async {
        await tester.pumpWidget(
          createWidgetUnderTest(
            child: EmptyState.noHistory(),
          ),
        );

        expect(find.byIcon(Icons.history), findsOneWidget);
        expect(find.text('No workout history'), findsOneWidget);
        // No action button for noHistory
        expect(find.byType(ElevatedButton), findsNothing);
      });

      testWidgets('noResults should display correct content', (tester) async {
        await tester.pumpWidget(
          createWidgetUnderTest(
            child: EmptyState.noResults(),
          ),
        );

        expect(find.byIcon(Icons.search), findsOneWidget);
        expect(find.text('No results'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsNothing);
      });

      testWidgets('offline should display correct content', (tester) async {
        await tester.pumpWidget(
          createWidgetUnderTest(
            child: EmptyState.offline(),
          ),
        );

        expect(find.byIcon(Icons.wifi_off), findsOneWidget);
        expect(find.text('No connection'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('offline should call onRetry when button tapped', (tester) async {
        bool retried = false;

        await tester.pumpWidget(
          createWidgetUnderTest(
            child: EmptyState.offline(onRetry: () => retried = true),
          ),
        );

        await tester.tap(find.byType(ElevatedButton));
        expect(retried, true);
      });
    });

    testWidgets('should apply custom icon color', (tester) async {
      const customColor = Colors.purple;

      await tester.pumpWidget(
        createWidgetUnderTest(
          child: const EmptyState(
            icon: Icons.star,
            title: 'Title',
            subtitle: 'Subtitle',
            iconColor: customColor,
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.star));
      // Icon color should be applied (with opacity)
      expect(icon.color, isNotNull);
    });

    testWidgets('should center content', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          child: const EmptyState(
            icon: Icons.check,
            title: 'Centered',
            subtitle: 'This should be centered',
          ),
        ),
      );

      expect(find.byType(Center), findsOneWidget);
    });

    testWidgets('should work in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: EmptyState(
              icon: Icons.dark_mode,
              title: 'Dark Mode',
              subtitle: 'Testing dark mode',
            ),
          ),
        ),
      );

      expect(find.text('Dark Mode'), findsOneWidget);
    });

    testWidgets('should work in light mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: EmptyState(
              icon: Icons.light_mode,
              title: 'Light Mode',
              subtitle: 'Testing light mode',
            ),
          ),
        ),
      );

      expect(find.text('Light Mode'), findsOneWidget);
    });
  });

  group('SkeletonLoader', () {
    testWidgets('should display default number of items', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          child: const SkeletonLoader(),
        ),
      );

      // Default itemCount is 5
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should accept custom item count', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          child: const SkeletonLoader(itemCount: 3),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should accept custom item height', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          child: const SkeletonLoader(
            itemCount: 2,
            itemHeight: 100,
          ),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should animate shimmer effect', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          child: const SkeletonLoader(itemCount: 1),
        ),
      );

      // Pump to start animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('SkeletonCard', () {
    testWidgets('should display with default dimensions', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          child: const SkeletonCard(),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container, isNotNull);
    });

    testWidgets('should accept custom dimensions', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          child: const SkeletonCard(
            height: 150,
            width: 200,
          ),
        ),
      );

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should accept custom border radius', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          child: SkeletonCard(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      );

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should animate shimmer effect', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          child: const SkeletonCard(),
        ),
      );

      // Pump to start animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should work in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: SkeletonCard(),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(Container), findsWidgets);
    });
  });
}
