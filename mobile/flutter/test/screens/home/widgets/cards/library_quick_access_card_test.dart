import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/home/widgets/cards/library_quick_access_card.dart';
import '../../test_helpers.dart';

void main() {
  group('LibraryQuickAccessCard', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const LibraryQuickAccessCard(isDark: true),
      ));

      expect(find.text('Exercise Library'), findsOneWidget);
    });

    testWidgets('renders subtitle', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const LibraryQuickAccessCard(isDark: true),
      ));

      expect(
        find.text('Browse exercises, programs & workout history'),
        findsOneWidget,
      );
    });

    testWidgets('renders fitness icon', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const LibraryQuickAccessCard(isDark: true),
      ));

      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
    });

    testWidgets('renders forward arrow icon', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const LibraryQuickAccessCard(isDark: true),
      ));

      expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
    });

    testWidgets('renders correctly in dark theme', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const LibraryQuickAccessCard(isDark: true),
        isDark: true,
      ));

      expect(find.text('Exercise Library'), findsOneWidget);
    });

    testWidgets('renders correctly in light theme', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const LibraryQuickAccessCard(isDark: false),
        isDark: false,
      ));

      expect(find.text('Exercise Library'), findsOneWidget);
    });

    testWidgets('is tappable', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const LibraryQuickAccessCard(isDark: true),
      ));

      // The card should contain InkWell for tap handling
      expect(find.byType(InkWell), findsOneWidget);
    });
  });
}
