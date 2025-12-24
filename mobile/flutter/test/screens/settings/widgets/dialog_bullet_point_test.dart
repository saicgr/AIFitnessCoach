import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/screens/settings/widgets/dialog_bullet_point.dart';
import 'package:ai_fitness_coach/core/constants/app_colors.dart';

void main() {
  group('DialogBulletPoint', () {
    testWidgets('displays text content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DialogBulletPoint(
              text: 'Test bullet point',
              color: Colors.red,
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.text('Test bullet point'), findsOneWidget);
    });

    testWidgets('displays colored bullet', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DialogBulletPoint(
              text: 'Test',
              color: Colors.green,
              isDark: true,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.green);
      expect(decoration.shape, BoxShape.circle);
    });

    testWidgets('applies bottom padding', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DialogBulletPoint(
              text: 'Test',
              color: Colors.red,
              isDark: true,
            ),
          ),
        ),
      );

      final padding = tester.widget<Padding>(find.byType(Padding).first);
      expect(padding.padding, const EdgeInsets.only(bottom: 8));
    });

    testWidgets('uses dark mode text color when isDark is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DialogBulletPoint(
              text: 'Test',
              color: Colors.red,
              isDark: true,
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Test'));
      expect(text.style?.color, AppColors.textSecondary);
    });

    testWidgets('uses light mode text color when isDark is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DialogBulletPoint(
              text: 'Test',
              color: Colors.red,
              isDark: false,
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Test'));
      expect(text.style?.color, AppColorsLight.textSecondary);
    });

    testWidgets('has correct bullet size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DialogBulletPoint(
              text: 'Test',
              color: Colors.blue,
              isDark: true,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.maxWidth, 6);
      expect(container.constraints?.maxHeight, 6);
    });

    testWidgets('uses Row with crossAxisAlignment.start', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DialogBulletPoint(
              text: 'Test',
              color: Colors.blue,
              isDark: true,
            ),
          ),
        ),
      );

      final row = tester.widget<Row>(find.byType(Row));
      expect(row.crossAxisAlignment, CrossAxisAlignment.start);
    });
  });
}
