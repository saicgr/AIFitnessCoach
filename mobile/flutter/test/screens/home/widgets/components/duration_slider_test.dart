import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/screens/home/widgets/components/duration_slider.dart';
import '../../test_helpers.dart';

void main() {
  group('DurationSlider', () {
    testWidgets('renders duration label', (tester) async {
      await tester.pumpWidget(createTestWidget(
        DurationSlider(
          duration: 45,
          onChanged: (_) {},
        ),
      ));

      expect(find.text('Duration'), findsOneWidget);
      expect(find.text('45 min'), findsOneWidget);
    });

    testWidgets('renders slider widget', (tester) async {
      await tester.pumpWidget(createTestWidget(
        DurationSlider(
          duration: 45,
          onChanged: (_) {},
        ),
      ));

      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('renders min and max labels', (tester) async {
      await tester.pumpWidget(createTestWidget(
        DurationSlider(
          duration: 45,
          onChanged: (_) {},
          minDuration: 15,
          maxDuration: 90,
        ),
      ));

      expect(find.text('15 min'), findsOneWidget);
      expect(find.text('90 min'), findsOneWidget);
    });

    testWidgets('calls onChanged when slider value changes', (tester) async {
      double? newDuration;

      await tester.pumpWidget(createTestWidget(
        DurationSlider(
          duration: 45,
          onChanged: (d) => newDuration = d,
        ),
      ));

      // Drag the slider
      final slider = find.byType(Slider);
      await tester.drag(slider, const Offset(100, 0));
      await tester.pump();

      expect(newDuration, isNotNull);
    });

    testWidgets('uses custom min and max values', (tester) async {
      await tester.pumpWidget(createTestWidget(
        DurationSlider(
          duration: 30,
          onChanged: (_) {},
          minDuration: 10,
          maxDuration: 60,
        ),
      ));

      expect(find.text('10 min'), findsOneWidget);
      expect(find.text('60 min'), findsOneWidget);
    });

    testWidgets('uses custom accent color', (tester) async {
      await tester.pumpWidget(createTestWidget(
        DurationSlider(
          duration: 45,
          onChanged: (_) {},
          accentColor: Colors.purple,
        ),
      ));

      // Widget should render without error
      expect(find.byType(DurationSlider), findsOneWidget);
    });

    testWidgets('slider is disabled when disabled is true', (tester) async {
      await tester.pumpWidget(createTestWidget(
        DurationSlider(
          duration: 45,
          onChanged: (_) {},
          disabled: true,
        ),
      ));

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.onChanged, isNull);
    });
  });
}
