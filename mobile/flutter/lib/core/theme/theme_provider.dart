import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';

/// Theme mode provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

/// Theme mode notifier
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const _themeKey = 'theme_mode';

  ThemeModeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  /// Load saved theme preference
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeString = prefs.getString(_themeKey) ?? 'light';
      state = _themeFromString(themeString);
      _updateSystemUI();
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  /// Toggle between light and dark mode
  Future<void> toggle() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setTheme(newMode);
  }

  /// Set specific theme mode
  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    _updateSystemUI();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, _themeToString(mode));
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  /// Update system UI overlay style
  void _updateSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      state == ThemeMode.dark
          ? const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              systemNavigationBarColor: AppColors.pureBlack,
              systemNavigationBarIconBrightness: Brightness.light,
            )
          : const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              systemNavigationBarColor: Colors.white,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
    );
  }

  bool get isDark => state == ThemeMode.dark;

  String _themeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  ThemeMode _themeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.light;
    }
  }
}

/// Light theme colors (OLED-friendly but light)
class AppColorsLight {
  AppColorsLight._();

  // Brand Colors (same as dark)
  static const Color cyan = Color(0xFF0891B2);
  static const Color cyanDark = Color(0xFF0E7490);
  static const Color electricBlue = Color(0xFF2563EB);
  static const Color teal = Color(0xFF0D9488);

  // Light Theme Colors
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color nearWhite = Color(0xFFFAFAFA);
  static const Color elevated = Color(0xFFF4F4F5);
  static const Color glassSurface = Color(0xFFF8F8FA);  // Lighter for better contrast on white
  static const Color cardBorder = Color(0xFFE4E4E7);
  static const Color surface = Color(0xFFF9FAFB);

  // Text Colors
  static const Color textPrimary = Color(0xFF18181B);
  static const Color textSecondary = Color(0xFF52525B);
  static const Color textMuted = Color(0xFF71717A);

  // Workout Type Colors (same as dark)
  static const Color strength = Color(0xFF6366F1);
  static const Color cardio = Color(0xFFEF4444);
  static const Color flexibility = Color(0xFF14B8A6);
  static const Color hiit = Color(0xFFEC4899);

  // Accent Colors (same as dark)
  static const Color orange = Color(0xFFF97316);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color coral = Color(0xFFF43F5E);
  static const Color magenta = Color(0xFFEC4899);

  // Semantic Colors
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);
}

/// Light theme configuration
class AppThemeLight {
  AppThemeLight._();

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: AppColorsLight.cyan,
        onPrimary: AppColorsLight.pureWhite,
        secondary: AppColorsLight.purple,
        onSecondary: AppColorsLight.pureWhite,
        surface: AppColorsLight.nearWhite,
        onSurface: AppColorsLight.textPrimary,
        error: AppColorsLight.error,
        onError: AppColorsLight.pureWhite,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColorsLight.pureWhite,

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColorsLight.pureWhite,
        foregroundColor: AppColorsLight.textPrimary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: AppColorsLight.pureWhite,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          color: AppColorsLight.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColorsLight.nearWhite,
        selectedItemColor: AppColorsLight.cyan,
        unselectedItemColor: AppColorsLight.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Navigation Bar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColorsLight.nearWhite,
        indicatorColor: AppColorsLight.cyan.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColorsLight.cyan,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColorsLight.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColorsLight.cyan, size: 24);
          }
          return const IconThemeData(color: AppColorsLight.textMuted, size: 24);
        }),
        height: 80,
      ),

      // Cards
      cardTheme: CardThemeData(
        color: AppColorsLight.elevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColorsLight.cardBorder.withOpacity(0.5),
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsLight.cyan,
          foregroundColor: AppColorsLight.pureWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorsLight.textPrimary,
          side: BorderSide(color: AppColorsLight.textMuted.withOpacity(0.3)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsLight.glassSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColorsLight.cardBorder.withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorsLight.cyan),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: AppColorsLight.textMuted),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColorsLight.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColorsLight.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColorsLight.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColorsLight.textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColorsLight.textMuted,
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColorsLight.elevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColorsLight.elevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        dragHandleColor: AppColorsLight.textMuted,
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColorsLight.cyan,
        linearTrackColor: AppColorsLight.glassSurface,
      ),
    );
  }
}
