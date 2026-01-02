import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/settings/widgets/setting_tile.dart';

void main() {
  group('SettingItemData', () {
    test('creates with required fields', () {
      const item = SettingItemData(
        icon: Icons.settings,
        title: 'Test Setting',
      );

      expect(item.icon, Icons.settings);
      expect(item.title, 'Test Setting');
      expect(item.subtitle, isNull);
      expect(item.onTap, isNull);
      expect(item.trailing, isNull);
      expect(item.isThemeToggle, false);
      expect(item.isFollowSystemToggle, false);
    });

    test('creates with all fields', () {
      void callback() {}
      const trailing = Icon(Icons.check);

      final item = SettingItemData(
        icon: Icons.settings,
        title: 'Test Setting',
        subtitle: 'Test subtitle',
        onTap: callback,
        trailing: trailing,
        isThemeToggle: true,
        isFollowSystemToggle: true,
      );

      expect(item.icon, Icons.settings);
      expect(item.title, 'Test Setting');
      expect(item.subtitle, 'Test subtitle');
      expect(item.onTap, callback);
      expect(item.trailing, trailing);
      expect(item.isThemeToggle, true);
      expect(item.isFollowSystemToggle, true);
    });
  });

  group('SettingTile', () {
    testWidgets('displays icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SettingTile(
              icon: Icons.settings,
              title: 'Test',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('displays title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SettingTile(
              icon: Icons.settings,
              title: 'Test Title',
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
    });

    testWidgets('displays subtitle when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SettingTile(
              icon: Icons.settings,
              title: 'Test Title',
              subtitle: 'Test Subtitle',
            ),
          ),
        ),
      );

      expect(find.text('Test Subtitle'), findsOneWidget);
    });

    testWidgets('does not display subtitle when not provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SettingTile(
              icon: Icons.settings,
              title: 'Test Title',
            ),
          ),
        ),
      );

      // Only title should be found, no subtitle
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('shows chevron when onTap provided and showChevron is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingTile(
              icon: Icons.settings,
              title: 'Test',
              onTap: () {},
              showChevron: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('hides chevron when showChevron is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingTile(
              icon: Icons.settings,
              title: 'Test',
              onTap: () {},
              showChevron: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('displays custom trailing widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SettingTile(
              icon: Icons.settings,
              title: 'Test',
              trailing: Icon(Icons.check, key: Key('custom_trailing')),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('custom_trailing')), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingTile(
              icon: Icons.settings,
              title: 'Test',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, true);
    });

    testWidgets('uses custom icon color when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SettingTile(
              icon: Icons.settings,
              title: 'Test',
              iconColor: Colors.red,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.settings));
      expect(icon.color, Colors.red);
    });

    testWidgets('applies correct padding', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SettingTile(
              icon: Icons.settings,
              title: 'Test',
            ),
          ),
        ),
      );

      final padding = tester.widget<Padding>(find.byType(Padding).first);
      expect(padding.padding, const EdgeInsets.all(16));
    });
  });
}
