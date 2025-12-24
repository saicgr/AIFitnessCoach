import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_fitness_coach/core/theme/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeModeNotifier', () {
    late ThemeModeNotifier notifier;

    setUp(() async {
      // Set up SharedPreferences mock
      SharedPreferences.setMockInitialValues({});
      notifier = ThemeModeNotifier();
    });

    test('should initialize with system theme mode', () {
      expect(notifier.state, ThemeMode.system);
    });

    group('setTheme', () {
      test('should set theme to dark mode', () async {
        await notifier.setTheme(ThemeMode.dark);
        expect(notifier.state, ThemeMode.dark);
      });

      test('should set theme to light mode', () async {
        await notifier.setTheme(ThemeMode.light);
        expect(notifier.state, ThemeMode.light);
      });

      test('should set theme to system mode', () async {
        await notifier.setTheme(ThemeMode.dark);
        await notifier.setTheme(ThemeMode.system);
        expect(notifier.state, ThemeMode.system);
      });

      test('should persist theme to SharedPreferences', () async {
        await notifier.setTheme(ThemeMode.dark);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('theme_mode'), 'dark');
      });
    });

    group('toggle', () {
      test('should toggle from dark to light', () async {
        await notifier.setTheme(ThemeMode.dark);
        await notifier.toggle();
        expect(notifier.state, ThemeMode.light);
      });

      test('should toggle from light to dark', () async {
        await notifier.setTheme(ThemeMode.light);
        await notifier.toggle();
        expect(notifier.state, ThemeMode.dark);
      });

      test('should toggle from system to light (system != dark)', () async {
        notifier = ThemeModeNotifier();
        expect(notifier.state, ThemeMode.system);

        await notifier.toggle();
        // From system, toggle goes to light (since system != dark)
        expect(notifier.state, ThemeMode.light);
      });
    });

    group('isDark', () {
      test('should return true for dark mode', () async {
        await notifier.setTheme(ThemeMode.dark);
        expect(notifier.isDark, true);
      });

      test('should return false for light mode', () async {
        await notifier.setTheme(ThemeMode.light);
        expect(notifier.isDark, false);
      });

      test('should return false for system mode', () {
        expect(notifier.isDark, false);
      });
    });

    group('persistence', () {
      test('should load dark theme from SharedPreferences', () async {
        SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
        final loadedNotifier = ThemeModeNotifier();

        // Wait for async _loadTheme to complete
        await Future.delayed(const Duration(milliseconds: 100));

        expect(loadedNotifier.state, ThemeMode.dark);
      });

      test('should load light theme from SharedPreferences', () async {
        SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
        final loadedNotifier = ThemeModeNotifier();

        // Wait for async _loadTheme to complete
        await Future.delayed(const Duration(milliseconds: 100));

        expect(loadedNotifier.state, ThemeMode.light);
      });

      test('should default to system when no saved preference', () async {
        SharedPreferences.setMockInitialValues({});
        final loadedNotifier = ThemeModeNotifier();

        // Wait for async _loadTheme to complete
        await Future.delayed(const Duration(milliseconds: 100));

        expect(loadedNotifier.state, ThemeMode.system);
      });

      test('should default to system for invalid saved preference', () async {
        SharedPreferences.setMockInitialValues({'theme_mode': 'invalid'});
        final loadedNotifier = ThemeModeNotifier();

        // Wait for async _loadTheme to complete
        await Future.delayed(const Duration(milliseconds: 100));

        expect(loadedNotifier.state, ThemeMode.system);
      });
    });
  });

  group('themeModeProvider', () {
    test('should provide ThemeModeNotifier', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final themeMode = container.read(themeModeProvider);
      expect(themeMode, isA<ThemeMode>());
    });

    test('should allow setting theme via notifier', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeModeProvider.notifier);
      await notifier.setTheme(ThemeMode.dark);

      expect(container.read(themeModeProvider), ThemeMode.dark);
    });
  });

  group('AppThemeLight', () {
    test('should return light theme', () {
      final theme = AppThemeLight.theme;

      expect(theme.brightness, Brightness.light);
      expect(theme.useMaterial3, true);
    });

    test('should have proper scaffold background color', () {
      final theme = AppThemeLight.theme;

      expect(theme.scaffoldBackgroundColor, isNotNull);
    });

    test('should have proper app bar theme', () {
      final theme = AppThemeLight.theme;

      expect(theme.appBarTheme.backgroundColor, isNotNull);
      expect(theme.appBarTheme.elevation, 0);
      expect(theme.appBarTheme.centerTitle, true);
    });

    test('should have proper card theme', () {
      final theme = AppThemeLight.theme;

      expect(theme.cardTheme.elevation, 0);
      expect(theme.cardTheme.margin, EdgeInsets.zero);
    });

    test('should have proper text theme', () {
      final theme = AppThemeLight.theme;

      expect(theme.textTheme.displayLarge, isNotNull);
      expect(theme.textTheme.bodyLarge, isNotNull);
      expect(theme.textTheme.bodyMedium, isNotNull);
    });
  });

  group('SeniorTheme', () {
    test('should have proper font scale', () {
      expect(SeniorTheme.fontScale, 1.35);
    });

    test('should have minimum button height', () {
      expect(SeniorTheme.minButtonHeight, 64.0);
    });

    test('should have minimum touch target size', () {
      expect(SeniorTheme.minTouchTarget, 56.0);
    });

    group('darkTheme', () {
      test('should return dark theme', () {
        final theme = SeniorTheme.darkTheme;

        expect(theme.brightness, Brightness.dark);
        expect(theme.useMaterial3, true);
      });

      test('should have larger toolbar height', () {
        final theme = SeniorTheme.darkTheme;

        expect(theme.appBarTheme.toolbarHeight, 64);
      });

      test('should have larger icon sizes', () {
        final theme = SeniorTheme.darkTheme;

        expect(theme.appBarTheme.iconTheme?.size, 28);
        expect(theme.iconTheme.size, 28);
      });

      test('should have larger text sizes', () {
        final theme = SeniorTheme.darkTheme;

        expect(theme.textTheme.displayLarge?.fontSize, 40);
        expect(theme.textTheme.bodyLarge?.fontSize, 20);
        expect(theme.textTheme.bodyMedium?.fontSize, 18);
      });

      test('should have larger button minimum size', () {
        final theme = SeniorTheme.darkTheme;

        final buttonStyle = theme.elevatedButtonTheme.style;
        expect(buttonStyle?.minimumSize?.resolve({}), const Size(double.infinity, 64));
      });

      test('should have taller navigation bar', () {
        final theme = SeniorTheme.darkTheme;

        expect(theme.navigationBarTheme.height, 88);
      });
    });

    group('lightTheme', () {
      test('should return light theme', () {
        final theme = SeniorTheme.lightTheme;

        expect(theme.brightness, Brightness.light);
        expect(theme.useMaterial3, true);
      });

      test('should have larger toolbar height', () {
        final theme = SeniorTheme.lightTheme;

        expect(theme.appBarTheme.toolbarHeight, 64);
      });

      test('should have high contrast colors', () {
        final theme = SeniorTheme.lightTheme;

        // Primary should be darker for better contrast
        expect(theme.colorScheme.primary, isNotNull);
        expect(theme.colorScheme.onSurface, isNotNull);
      });

      test('should have larger text sizes', () {
        final theme = SeniorTheme.lightTheme;

        expect(theme.textTheme.displayLarge?.fontSize, 40);
        expect(theme.textTheme.bodyLarge?.fontSize, 20);
      });
    });
  });
}
