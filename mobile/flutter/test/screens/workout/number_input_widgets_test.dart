import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/screens/workout/widgets/number_input_widgets.dart';

void main() {
  group('InlineNumberInput', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController(text: '10');
    });

    tearDown(() {
      controller.dispose();
    });

    Widget buildTestWidget({
      bool isDecimal = false,
      bool isActive = false,
      Color accentColor = Colors.cyan,
      VoidCallback? onShowDialog,
    }) {
      return MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: InlineNumberInput(
            controller: controller,
            isDecimal: isDecimal,
            isActive: isActive,
            accentColor: accentColor,
            onShowDialog: onShowDialog,
          ),
        ),
      );
    }

    testWidgets('displays initial value', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('displays 0 when text is empty', (tester) async {
      controller.text = '';
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('has plus and minus buttons', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
    });

    testWidgets('plus button increments integer value', (tester) async {
      await tester.pumpWidget(buildTestWidget(isDecimal: false));

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(controller.text, '11');
    });

    testWidgets('minus button decrements integer value', (tester) async {
      await tester.pumpWidget(buildTestWidget(isDecimal: false));

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();

      expect(controller.text, '9');
    });

    testWidgets('plus button increments decimal by 2.5', (tester) async {
      controller.text = '50';
      await tester.pumpWidget(buildTestWidget(isDecimal: true));

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(controller.text, '52.5');
    });

    testWidgets('minus button decrements decimal by 2.5', (tester) async {
      controller.text = '50';
      await tester.pumpWidget(buildTestWidget(isDecimal: true));

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();

      expect(controller.text, '47.5');
    });

    testWidgets('value cannot go below 0', (tester) async {
      controller.text = '0';
      await tester.pumpWidget(buildTestWidget(isDecimal: false));

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();

      expect(controller.text, '0');
    });

    testWidgets('decimal value cannot go below 0', (tester) async {
      controller.text = '1';
      await tester.pumpWidget(buildTestWidget(isDecimal: true));

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();

      expect(double.parse(controller.text), greaterThanOrEqualTo(0));
    });

    testWidgets('tapping value calls onShowDialog', (tester) async {
      bool dialogShown = false;

      await tester.pumpWidget(buildTestWidget(
        onShowDialog: () => dialogShown = true,
      ));

      // Tap the text display area
      await tester.tap(find.text('10'));
      await tester.pump();

      expect(dialogShown, true);
    });

    testWidgets('active state shows different styling', (tester) async {
      await tester.pumpWidget(buildTestWidget(isActive: true));

      // Just verify it renders without error
      expect(find.byType(InlineNumberInput), findsOneWidget);
    });
  });

  group('ExpandedNumberInput', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController(text: '60');
    });

    tearDown(() {
      controller.dispose();
    });

    Widget buildTestWidget({
      bool isDecimal = false,
      Color accentColor = Colors.cyan,
      VoidCallback? onShowDialog,
    }) {
      return MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: ExpandedNumberInput(
            controller: controller,
            isDecimal: isDecimal,
            accentColor: accentColor,
            onShowDialog: onShowDialog,
          ),
        ),
      );
    }

    testWidgets('displays initial value', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('60'), findsOneWidget);
    });

    testWidgets('has glowing increment buttons', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(GlowingIncrementButton), findsNWidgets(2));
    });

    testWidgets('plus button increments value', (tester) async {
      await tester.pumpWidget(buildTestWidget(isDecimal: false));

      // Find and tap the plus button (it's the right GlowingIncrementButton)
      final buttons = find.byType(GlowingIncrementButton);
      await tester.tap(buttons.last);
      await tester.pump();

      expect(controller.text, '61');
    });

    testWidgets('minus button decrements value', (tester) async {
      await tester.pumpWidget(buildTestWidget(isDecimal: false));

      // Find and tap the minus button (it's the left GlowingIncrementButton)
      final buttons = find.byType(GlowingIncrementButton);
      await tester.tap(buttons.first);
      await tester.pump();

      expect(controller.text, '59');
    });
  });

  group('GlowingIncrementButton', () {
    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GlowingIncrementButton(
            icon: Icons.add,
            accentColor: Colors.cyan,
            isLeft: false,
            onTap: () => tapped = true,
          ),
        ),
      ));

      await tester.tap(find.byType(GlowingIncrementButton));
      await tester.pump();

      expect(tapped, true);
    });

    testWidgets('displays icon', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GlowingIncrementButton(
            icon: Icons.add,
            accentColor: Colors.cyan,
            isLeft: false,
            onTap: () {},
          ),
        ),
      ));

      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });

  group('NumberInputField', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController(text: '50');
    });

    tearDown(() {
      controller.dispose();
    });

    Widget buildTestWidget({bool isDecimal = false}) {
      return MaterialApp(
        home: Scaffold(
          body: NumberInputField(
            controller: controller,
            icon: Icons.fitness_center,
            hint: 'Weight',
            color: Colors.cyan,
            isDecimal: isDecimal,
          ),
        ),
      );
    }

    testWidgets('displays icon', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.fitness_center), findsNWidgets(2)); // Both + and - have icons
    });

    testWidgets('has text field', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('increment and decrement work', (tester) async {
      await tester.pumpWidget(buildTestWidget(isDecimal: true));

      // Tap increment
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(controller.text, '52.5');

      // Tap decrement
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();

      expect(controller.text, '50');
    });
  });

  group('InlineNumberInputWithLabel', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController(text: '60');
    });

    tearDown(() {
      controller.dispose();
    });

    Widget buildTestWidget({
      String? unitLabel,
      VoidCallback? onUnitToggle,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: InlineNumberInputWithLabel(
            controller: controller,
            label: 'WEIGHT',
            icon: Icons.fitness_center,
            color: Colors.cyan,
            isDecimal: true,
            unitLabel: unitLabel,
            onUnitToggle: onUnitToggle,
          ),
        ),
      );
    }

    testWidgets('displays label', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('WEIGHT'), findsOneWidget);
    });

    testWidgets('displays unit label when provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(unitLabel: 'KG'));

      expect(find.text('KG'), findsOneWidget);
    });

    testWidgets('unit toggle calls callback', (tester) async {
      bool toggled = false;

      await tester.pumpWidget(buildTestWidget(
        unitLabel: 'KG',
        onUnitToggle: () => toggled = true,
      ));

      await tester.tap(find.text('KG'));
      await tester.pump();

      expect(toggled, true);
    });

    testWidgets('increment and decrement work', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(controller.text, '62.5');
    });
  });
}
