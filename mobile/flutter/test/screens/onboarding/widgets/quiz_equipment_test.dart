import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/screens/onboarding/widgets/quiz_equipment.dart';

void main() {
  group('QuizEquipment', () {
    testWidgets('displays question text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizEquipment(
              selectedEquipment: const {},
              dumbbellCount: 2,
              kettlebellCount: 1,
              onEquipmentToggled: (_) {},
              onDumbbellCountChanged: (_) {},
              onKettlebellCountChanged: (_) {},
              onInfoTap: (_, __, ___) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('What equipment do you have access to?'), findsOneWidget);
    });

    testWidgets('displays equipment options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizEquipment(
              selectedEquipment: const {},
              dumbbellCount: 2,
              kettlebellCount: 1,
              onEquipmentToggled: (_) {},
              onDumbbellCountChanged: (_) {},
              onKettlebellCountChanged: (_) {},
              onInfoTap: (_, __, ___) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Bodyweight Only'), findsOneWidget);
      expect(find.text('Dumbbells'), findsOneWidget);
      expect(find.text('Barbell'), findsOneWidget);
    });

    testWidgets('calls onEquipmentToggled when option is tapped', (tester) async {
      String? toggledId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizEquipment(
              selectedEquipment: const {},
              dumbbellCount: 2,
              kettlebellCount: 1,
              onEquipmentToggled: (id) {
                toggledId = id;
              },
              onDumbbellCountChanged: (_) {},
              onKettlebellCountChanged: (_) {},
              onInfoTap: (_, __, ___) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Dumbbells'));
      await tester.pump();

      expect(toggledId, equals('dumbbells'));
    });

    testWidgets('shows check mark for selected equipment', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizEquipment(
              selectedEquipment: const {'bodyweight', 'dumbbells'},
              dumbbellCount: 2,
              kettlebellCount: 1,
              onEquipmentToggled: (_) {},
              onDumbbellCountChanged: (_) {},
              onKettlebellCountChanged: (_) {},
              onInfoTap: (_, __, ___) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check), findsNWidgets(2));
    });

    testWidgets('displays full gym option', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizEquipment(
              selectedEquipment: const {},
              dumbbellCount: 2,
              kettlebellCount: 1,
              onEquipmentToggled: (_) {},
              onDumbbellCountChanged: (_) {},
              onKettlebellCountChanged: (_) {},
              onInfoTap: (_, __, ___) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Full Gym Access'), findsOneWidget);
    });

    testWidgets('renders in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: QuizEquipment(
              selectedEquipment: const {},
              dumbbellCount: 2,
              kettlebellCount: 1,
              onEquipmentToggled: (_) {},
              onDumbbellCountChanged: (_) {},
              onKettlebellCountChanged: (_) {},
              onInfoTap: (_, __, ___) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('What equipment do you have access to?'), findsOneWidget);
    });

    testWidgets('renders in light mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: QuizEquipment(
              selectedEquipment: const {},
              dumbbellCount: 2,
              kettlebellCount: 1,
              onEquipmentToggled: (_) {},
              onDumbbellCountChanged: (_) {},
              onKettlebellCountChanged: (_) {},
              onInfoTap: (_, __, ___) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('What equipment do you have access to?'), findsOneWidget);
    });
  });
}
