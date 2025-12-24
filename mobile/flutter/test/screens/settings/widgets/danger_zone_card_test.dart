import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/screens/settings/widgets/danger_zone_card.dart';
import 'package:ai_fitness_coach/core/constants/app_colors.dart';

void main() {
  group('DangerItemData', () {
    test('creates with required fields', () {
      void callback() {}

      final item = DangerItemData(
        icon: Icons.delete,
        title: 'Delete',
        subtitle: 'Delete all data',
        onTap: callback,
      );

      expect(item.icon, Icons.delete);
      expect(item.title, 'Delete');
      expect(item.subtitle, 'Delete all data');
      expect(item.onTap, callback);
    });
  });

  group('DangerZoneCard', () {
    testWidgets('displays single item', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DangerZoneCard(
              items: [
                DangerItemData(
                  icon: Icons.delete,
                  title: 'Delete Account',
                  subtitle: 'Permanently delete',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Delete Account'), findsOneWidget);
      expect(find.text('Permanently delete'), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('displays multiple items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DangerZoneCard(
              items: [
                DangerItemData(
                  icon: Icons.refresh,
                  title: 'Reset',
                  subtitle: 'Reset data',
                  onTap: () {},
                ),
                DangerItemData(
                  icon: Icons.delete,
                  title: 'Delete',
                  subtitle: 'Delete account',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Reset'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('calls onTap when item is tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DangerZoneCard(
              items: [
                DangerItemData(
                  icon: Icons.delete,
                  title: 'Delete',
                  subtitle: 'Delete data',
                  onTap: () => tapped = true,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, true);
    });

    testWidgets('has error-colored border', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DangerZoneCard(
              items: [
                DangerItemData(
                  icon: Icons.delete,
                  title: 'Delete',
                  subtitle: 'Delete data',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    });

    testWidgets('shows chevron indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DangerZoneCard(
              items: [
                DangerItemData(
                  icon: Icons.delete,
                  title: 'Delete',
                  subtitle: 'Delete data',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('icon container has error color background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DangerZoneCard(
              items: [
                DangerItemData(
                  icon: Icons.delete,
                  title: 'Delete',
                  subtitle: 'Delete data',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      // Find the container that wraps the icon
      final containers = tester.widgetList<Container>(find.byType(Container));
      bool foundErrorBackground = false;
      for (final container in containers) {
        if (container.decoration is BoxDecoration) {
          final decoration = container.decoration as BoxDecoration;
          if (decoration.color == AppColors.error.withOpacity(0.1)) {
            foundErrorBackground = true;
            break;
          }
        }
      }
      expect(foundErrorBackground, true);
    });

    testWidgets('icon has error color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DangerZoneCard(
              items: [
                DangerItemData(
                  icon: Icons.delete,
                  title: 'Delete',
                  subtitle: 'Delete data',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.delete));
      expect(icon.color, AppColors.error);
    });

    testWidgets('has rounded corners', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DangerZoneCard(
              items: [
                DangerItemData(
                  icon: Icons.delete,
                  title: 'Delete',
                  subtitle: 'Delete data',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(16));
    });

    testWidgets('shows divider between items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DangerZoneCard(
              items: [
                DangerItemData(
                  icon: Icons.refresh,
                  title: 'Reset',
                  subtitle: 'Reset data',
                  onTap: () {},
                ),
                DangerItemData(
                  icon: Icons.delete,
                  title: 'Delete',
                  subtitle: 'Delete account',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Divider), findsOneWidget);
    });
  });
}
