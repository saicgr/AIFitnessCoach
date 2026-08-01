import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/settings/widgets/setting_switch_tile.dart';
import 'package:fitwiz/core/theme/accent_color_provider.dart';

void _noop(bool _) {}

void main() {
  group('SettingSwitchTile', () {
    testWidgets('displays icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingSwitchTile(
              icon: Icons.notifications,
              title: 'Notifications',
              value: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.notifications), findsOneWidget);
    });

    testWidgets('displays title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingSwitchTile(
              icon: Icons.notifications,
              title: 'Test Title',
              value: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
    });

    testWidgets('displays subtitle when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingSwitchTile(
              icon: Icons.notifications,
              title: 'Title',
              subtitle: 'Test Subtitle',
              value: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Test Subtitle'), findsOneWidget);
    });

    testWidgets('switch reflects value true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingSwitchTile(
              icon: Icons.notifications,
              title: 'Test',
              value: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, true);
    });

    testWidgets('switch reflects value false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingSwitchTile(
              icon: Icons.notifications,
              title: 'Test',
              value: false,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, false);
    });

    testWidgets('calls onChanged when switch is toggled', (tester) async {
      bool? newValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingSwitchTile(
              icon: Icons.notifications,
              title: 'Test',
              value: false,
              onChanged: (value) => newValue = value,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Switch));
      expect(newValue, true);
    });

    testWidgets('switch is disabled when enabled is false', (tester) async {
      bool called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingSwitchTile(
              icon: Icons.notifications,
              title: 'Test',
              value: false,
              onChanged: (_) => called = true,
              enabled: false,
            ),
          ),
        ),
      );

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.onChanged, isNull);

      await tester.tap(find.byType(Switch));
      expect(called, false);
    });

    testWidgets('uses custom icon color when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingSwitchTile(
              icon: Icons.notifications,
              title: 'Test',
              value: true,
              onChanged: (_) {},
              iconColor: Colors.red,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.notifications));
      expect(icon.color, Colors.red);
    });

    testWidgets('uses the ambient accent as the switch active color',
        (tester) async {
      // The tile used to hardcode cyan on the theme's default purple track,
      // which read as a two-tone pill. It now honours the user's accent via
      // [AccentColorScope] for BOTH thumb and track.
      await tester.pumpWidget(
        MaterialApp(
          home: const AccentColorScope(
            accent: AccentColor.cyan,
            child: Scaffold(
              body: SettingSwitchTile(
                icon: Icons.notifications,
                title: 'Test',
                value: true,
                onChanged: _noop,
              ),
            ),
          ),
        ),
      );

      final expected = AccentColor.cyan.getColor(false);
      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.activeThumbColor, expected);
      expect(switchWidget.activeTrackColor, expected.withValues(alpha: 0.5));
    });

    testWidgets('falls back to the default accent with no AccentColorScope',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingSwitchTile(
              icon: Icons.notifications,
              title: 'Test',
              value: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.activeThumbColor, AccentColor.orange.getColor(false));
    });
  });
}
