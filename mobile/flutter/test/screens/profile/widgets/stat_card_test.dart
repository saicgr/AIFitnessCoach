import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/profile/widgets/stat_card.dart';
import 'package:fitwiz/core/constants/app_colors.dart';

void main() {
  group('StatCard', () {
    testWidgets('displays icon correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              icon: Icons.fitness_center,
              value: '10',
              label: 'Workouts',
              color: AppColors.cyan,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
    });

    testWidgets('displays value correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              icon: Icons.fitness_center,
              value: '10',
              label: 'Workouts',
              color: AppColors.cyan,
            ),
          ),
        ),
      );

      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('displays label correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              icon: Icons.fitness_center,
              value: '10',
              label: 'Workouts',
              color: AppColors.cyan,
            ),
          ),
        ),
      );

      expect(find.text('Workouts'), findsOneWidget);
    });

    testWidgets('shows tooltip when isEstimate is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              icon: Icons.local_fire_department,
              value: '~500',
              label: 'Est. Cal',
              color: AppColors.orange,
              isEstimate: true,
            ),
          ),
        ),
      );

      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgets('does not show tooltip when isEstimate is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              icon: Icons.fitness_center,
              value: '10',
              label: 'Workouts',
              color: AppColors.cyan,
              isEstimate: false,
            ),
          ),
        ),
      );

      expect(find.byType(Tooltip), findsNothing);
    });

    testWidgets('renders in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: StatCard(
              icon: Icons.fitness_center,
              value: '10',
              label: 'Workouts',
              color: AppColors.cyan,
            ),
          ),
        ),
      );

      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('renders in light mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: StatCard(
              icon: Icons.fitness_center,
              value: '10',
              label: 'Workouts',
              color: AppColors.cyan,
            ),
          ),
        ),
      );

      expect(find.text('10'), findsOneWidget);
    });
  });
}
