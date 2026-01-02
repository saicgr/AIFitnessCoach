import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/library/library_screen.dart';

void main() {
  group('LibraryScreen', () {
    testWidgets('renders header and tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LibraryScreen(),
          ),
        ),
      );

      // Wait for initial load
      await tester.pump();

      // Verify header
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Browse exercises and programs'), findsOneWidget);

      // Verify tabs
      expect(find.text('Exercises'), findsOneWidget);
      expect(find.text('Programs'), findsOneWidget);
      expect(find.text('My Stats'), findsOneWidget);
    });

    testWidgets('can switch between tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LibraryScreen(),
          ),
        ),
      );

      await tester.pump();

      // Tap on Programs tab
      await tester.tap(find.text('Programs'));
      await tester.pumpAndSettle();

      // Tap on My Stats tab
      await tester.tap(find.text('My Stats'));
      await tester.pumpAndSettle();

      // Tap back to Exercises tab
      await tester.tap(find.text('Exercises'));
      await tester.pumpAndSettle();
    });

    testWidgets('displays correctly in dark mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const LibraryScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Exercises'), findsOneWidget);
    });

    testWidgets('displays correctly in light mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.light(),
            home: const LibraryScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Exercises'), findsOneWidget);
    });
  });
}
