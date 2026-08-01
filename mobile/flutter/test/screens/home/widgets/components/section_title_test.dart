import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/home/widgets/components/section_title.dart';
import '../../test_helpers.dart';

void main() {
  group('SectionTitle', () {
    testWidgets('renders icon and title', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const SectionTitle(
          icon: Icons.fitness_center,
          title: 'Equipment',
        ),
      ));

      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
      expect(find.text('Equipment'), findsOneWidget);
    });

    testWidgets('renders badge when provided', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const SectionTitle(
          icon: Icons.fitness_center,
          title: 'Equipment',
          badge: '3 selected',
        ),
      ));

      expect(find.text('3 selected'), findsOneWidget);
    });

    testWidgets('does not render badge when not provided', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const SectionTitle(
          icon: Icons.fitness_center,
          title: 'Equipment',
        ),
      ));

      expect(find.text('3 selected'), findsNothing);
    });

    testWidgets('uses custom icon color when provided', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const SectionTitle(
          icon: Icons.fitness_center,
          title: 'Equipment',
          iconColor: Colors.red,
        ),
      ));

      final icon = tester.widget<Icon>(find.byIcon(Icons.fitness_center));
      expect(icon.color, equals(Colors.red));
    });
  });

  group('SectionHeader', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const SectionHeader(title: 'TODAY'),
      ));

      expect(find.text('TODAY'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const SectionHeader(
          title: 'UPCOMING',
          subtitle: '5 workouts',
        ),
      ));

      expect(find.text('UPCOMING'), findsOneWidget);
      expect(find.text('5 workouts'), findsOneWidget);
    });

    testWidgets('renders action text when provided', (tester) async {
      await tester.pumpWidget(createTestWidget(
        SectionHeader(
          title: 'UPCOMING',
          actionText: 'View All',
          onAction: () {},
        ),
      ));

      // The signature header renders the action as an uppercase label
      // (`ZType.lbl`), matching the uppercase section title beside it.
      expect(find.text('VIEW ALL'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
    });

    testWidgets('calls onAction when action is tapped', (tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(createTestWidget(
        SectionHeader(
          title: 'UPCOMING',
          actionText: 'View All',
          onAction: () => wasTapped = true,
        ),
      ));

      await tester.tap(find.text('VIEW ALL'));
      await tester.pump();

      expect(wasTapped, isTrue);
    });

    testWidgets('does not render action when actionText is null', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const SectionHeader(title: 'TODAY'),
      ));

      expect(find.text('VIEW ALL'), findsNothing);
      expect(find.byIcon(Icons.arrow_forward_ios), findsNothing);
    });

    testWidgets('does not render action when onAction is null', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const SectionHeader(
          title: 'TODAY',
          actionText: 'View All',
        ),
      ));

      expect(find.text('VIEW ALL'), findsNothing);
    });
  });
}
