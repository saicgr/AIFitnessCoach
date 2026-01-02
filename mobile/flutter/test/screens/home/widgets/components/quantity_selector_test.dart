import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/home/widgets/components/quantity_selector.dart';
import '../../test_helpers.dart';

void main() {
  group('QuantitySelector', () {
    testWidgets('renders current value', (tester) async {
      await tester.pumpWidget(createTestWidget(
        QuantitySelector(
          value: 2,
          onChanged: (_) {},
          accentColor: Colors.blue,
        ),
      ));

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('calls onChanged with decremented value when minus tapped', (tester) async {
      int? newValue;

      await tester.pumpWidget(createTestWidget(
        QuantitySelector(
          value: 2,
          onChanged: (v) => newValue = v,
          accentColor: Colors.blue,
          minValue: 1,
          maxValue: 3,
        ),
      ));

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();

      expect(newValue, equals(1));
    });

    testWidgets('calls onChanged with incremented value when plus tapped', (tester) async {
      int? newValue;

      await tester.pumpWidget(createTestWidget(
        QuantitySelector(
          value: 1,
          onChanged: (v) => newValue = v,
          accentColor: Colors.blue,
          minValue: 1,
          maxValue: 3,
        ),
      ));

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(newValue, equals(2));
    });

    testWidgets('does not decrement below minValue', (tester) async {
      int? newValue;

      await tester.pumpWidget(createTestWidget(
        QuantitySelector(
          value: 1,
          onChanged: (v) => newValue = v,
          accentColor: Colors.blue,
          minValue: 1,
          maxValue: 3,
        ),
      ));

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();

      expect(newValue, isNull);
    });

    testWidgets('does not increment above maxValue', (tester) async {
      int? newValue;

      await tester.pumpWidget(createTestWidget(
        QuantitySelector(
          value: 3,
          onChanged: (v) => newValue = v,
          accentColor: Colors.blue,
          minValue: 1,
          maxValue: 3,
        ),
      ));

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(newValue, isNull);
    });

    testWidgets('does not respond to taps when disabled', (tester) async {
      int? newValue;

      await tester.pumpWidget(createTestWidget(
        QuantitySelector(
          value: 2,
          onChanged: (v) => newValue = v,
          accentColor: Colors.blue,
          disabled: true,
        ),
      ));

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();

      expect(newValue, isNull);
    });

    testWidgets('uses default min/max values', (tester) async {
      // Default minValue is 1, maxValue is 2
      int? newValue;

      await tester.pumpWidget(createTestWidget(
        QuantitySelector(
          value: 2,
          onChanged: (v) => newValue = v,
          accentColor: Colors.blue,
        ),
      ));

      // Should not increment beyond default maxValue of 2
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(newValue, isNull);
    });
  });
}
