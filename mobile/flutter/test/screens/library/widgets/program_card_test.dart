import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/library/widgets/program_card.dart';
import 'package:fitwiz/data/models/program.dart';

void main() {
  group('ProgramCard', () {
    LibraryProgram createProgram({
      String name = 'Strength Training',
      String category = 'Goal-Based',
      String? difficultyLevel,
      int? durationWeeks,
      int? sessionsPerWeek,
      String? celebrityName,
    }) {
      return LibraryProgram(
        id: 'test-id',
        name: name,
        category: category,
        difficultyLevel: difficultyLevel,
        durationWeeks: durationWeeks,
        sessionsPerWeek: sessionsPerWeek,
        celebrityName: celebrityName,
      );
    }

    testWidgets('renders program name', (WidgetTester tester) async {
      final program = createProgram(name: 'HIIT Cardio');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgramCard(program: program),
          ),
        ),
      );

      expect(find.text('HIIT Cardio'), findsOneWidget);
    });

    testWidgets('renders category badge', (WidgetTester tester) async {
      final program = createProgram(
        name: 'Muscle Building',
        category: 'Goal-Based',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgramCard(program: program),
          ),
        ),
      );

      expect(find.text('Goal-Based'), findsOneWidget);
    });

    testWidgets('renders difficulty level when provided',
        (WidgetTester tester) async {
      final program = createProgram(
        name: 'Advanced Strength',
        difficultyLevel: 'Advanced',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgramCard(program: program),
          ),
        ),
      );

      expect(find.text('Advanced'), findsOneWidget);
    });

    testWidgets('renders duration display', (WidgetTester tester) async {
      final program = createProgram(
        name: '12 Week Transformation',
        durationWeeks: 12,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgramCard(program: program),
          ),
        ),
      );

      expect(find.text('12 weeks'), findsOneWidget);
    });

    testWidgets('renders sessions per week display',
        (WidgetTester tester) async {
      final program = createProgram(
        name: 'PPL Split',
        sessionsPerWeek: 6,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgramCard(program: program),
          ),
        ),
      );

      expect(find.text('6 days/week'), findsOneWidget);
    });

    testWidgets('shows calendar and repeat icons',
        (WidgetTester tester) async {
      final program = createProgram(
        durationWeeks: 8,
        sessionsPerWeek: 4,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgramCard(program: program),
          ),
        ),
      );

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.byIcon(Icons.repeat), findsOneWidget);
    });

    testWidgets('shows chevron right icon', (WidgetTester tester) async {
      final program = createProgram();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgramCard(program: program),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('is tappable', (WidgetTester tester) async {
      final program = createProgram();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgramCard(program: program),
          ),
        ),
      );

      await tester.tap(find.byType(ProgramCard));
      await tester.pump();
    });

    testWidgets('renders celebrity workout category correctly',
        (WidgetTester tester) async {
      final program = createProgram(
        name: 'Chris Hemsworth Workout',
        category: 'Celebrity Workout',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgramCard(program: program),
          ),
        ),
      );

      expect(find.text('Celebrity Workout'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsAtLeastNWidgets(1));
    });

    testWidgets('renders sport training category correctly',
        (WidgetTester tester) async {
      final program = createProgram(
        name: 'Football Conditioning',
        category: 'Sport Training',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgramCard(program: program),
          ),
        ),
      );

      expect(find.text('Sport Training'), findsOneWidget);
      expect(find.byIcon(Icons.sports), findsAtLeastNWidgets(1));
    });

    testWidgets('renders correctly in dark mode',
        (WidgetTester tester) async {
      final program = createProgram(
        name: 'Night Workout',
        category: 'Goal-Based',
        difficultyLevel: 'Intermediate',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: ProgramCard(program: program),
          ),
        ),
      );

      expect(find.text('Night Workout'), findsOneWidget);
    });

    testWidgets('renders correctly in light mode',
        (WidgetTester tester) async {
      final program = createProgram(
        name: 'Morning Routine',
        category: 'Goal-Based',
        difficultyLevel: 'Beginner',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: ProgramCard(program: program),
          ),
        ),
      );

      expect(find.text('Morning Routine'), findsOneWidget);
    });
  });
}
