import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/screens/settings/widgets/section_header.dart';
import 'package:ai_fitness_coach/core/constants/app_colors.dart';

void main() {
  group('SectionHeader', () {
    testWidgets('displays title in uppercase', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(title: 'test header'),
          ),
        ),
      );

      expect(find.text('TEST HEADER'), findsOneWidget);
    });

    testWidgets('displays already uppercase title correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(title: 'PREFERENCES'),
          ),
        ),
      );

      expect(find.text('PREFERENCES'), findsOneWidget);
    });

    testWidgets('aligns text to the left', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(title: 'Test'),
          ),
        ),
      );

      final align = tester.widget<Align>(find.byType(Align));
      expect(align.alignment, Alignment.centerLeft);
    });

    testWidgets('uses correct text style in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: SectionHeader(title: 'Test'),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('TEST'));
      final textStyle = textWidget.style!;

      expect(textStyle.fontSize, 12);
      expect(textStyle.fontWeight, FontWeight.w600);
      expect(textStyle.letterSpacing, 1.5);
      expect(textStyle.color, AppColors.textMuted);
    });

    testWidgets('uses correct text style in light mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: SectionHeader(title: 'Test'),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('TEST'));
      final textStyle = textWidget.style!;

      expect(textStyle.fontSize, 12);
      expect(textStyle.fontWeight, FontWeight.w600);
      expect(textStyle.color, AppColorsLight.textMuted);
    });
  });
}
