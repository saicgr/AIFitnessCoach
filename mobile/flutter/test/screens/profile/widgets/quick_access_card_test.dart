import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/profile/widgets/quick_access_card.dart';
import 'package:fitwiz/core/constants/app_colors.dart';

void main() {
  group('QuickAccessCard', () {
    testWidgets('displays icon correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickAccessCard(
              icon: Icons.emoji_events,
              title: 'Achievements',
              color: AppColors.orange,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    });

    testWidgets('displays title correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickAccessCard(
              icon: Icons.emoji_events,
              title: 'Achievements',
              color: AppColors.orange,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Achievements'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickAccessCard(
              icon: Icons.water_drop,
              title: 'Hydration',
              color: AppColors.electricBlue,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(QuickAccessCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('renders with correct color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickAccessCard(
              icon: Icons.restaurant,
              title: 'Nutrition',
              color: AppColors.success,
              onTap: () {},
            ),
          ),
        ),
      );

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.restaurant));
      expect(iconWidget.color, equals(AppColors.success));
    });

    testWidgets('renders in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: QuickAccessCard(
              icon: Icons.summarize,
              title: 'Weekly Summary',
              color: AppColors.purple,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Weekly Summary'), findsOneWidget);
    });

    testWidgets('renders in light mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: QuickAccessCard(
              icon: Icons.straighten,
              title: 'Measurements',
              color: AppColors.cyan,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Measurements'), findsOneWidget);
    });
  });
}
