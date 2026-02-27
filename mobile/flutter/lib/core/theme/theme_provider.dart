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

  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  /// Load saved theme preference
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeString = prefs.getString(_themeKey);
      debugPrint('🎨 [Theme] Loaded theme string from prefs: "$themeString"');
      state = _themeFromString(themeString ?? 'system');
      debugPrint('🎨 [Theme] Set theme mode to: $state');
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
    debugPrint('🎨 [Theme] setTheme called with: $mode (current: $state)');
    state = mode;
    _updateSystemUI();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, _themeToString(mode));
      debugPrint('🎨 [Theme] Saved theme to prefs: ${_themeToString(mode)}');
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  /// Update system UI overlay style
  void _updateSystemUI() {
    // For system mode, let Flutter handle it automatically
    if (state == ThemeMode.system) {
      // Don't override system UI when following system theme
      return;
    }

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
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.system; // Default to system theme
    }
  }
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

      // Snackbar - floating above nav bar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColorsLight.textPrimary,
        contentTextStyle: const TextStyle(color: AppColorsLight.pureWhite),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        // Clear the floating nav bar (52px + bottom safe area + gap)
        insetPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 80, top: 8),
      ),
    );
  }
}

/// Senior Mode Theme - High contrast, large fonts for elderly users
class SeniorTheme {
  SeniorTheme._();

  /// Font scale multiplier for senior mode
  static const double fontScale = 1.35;

  /// Minimum button height for easy touch targets
  static const double minButtonHeight = 64.0;

  /// Minimum touch target size
  static const double minTouchTarget = 56.0;

  /// Dark theme for senior mode
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color Scheme - Higher contrast
      colorScheme: const ColorScheme.dark(
        primary: AppColors.cyan,
        onPrimary: AppColors.pureBlack,
        secondary: AppColors.purple,
        onSecondary: Colors.white,
        surface: Color(0xFF1A1A1A), // Slightly lighter for contrast
        onSurface: Colors.white,
        error: Color(0xFFFF6B6B), // Brighter error color
        onError: Colors.white,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.pureBlack,

      // AppBar - Larger text
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.pureBlack,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 64,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.pureBlack,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 24, // Larger title
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(
          size: 28, // Larger icons
          color: Colors.white,
        ),
      ),

      // Bottom Navigation - Larger icons and text
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1A1A1A),
        selectedItemColor: AppColors.cyan,
        unselectedItemColor: Color(0xFF888888),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 14, // Larger labels
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        selectedIconTheme: IconThemeData(size: 32), // Larger icons
        unselectedIconTheme: IconThemeData(size: 28),
      ),

      // Navigation Bar (Material 3) - Larger
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1A1A1A),
        indicatorColor: AppColors.cyan.withOpacity(0.3),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.cyan,
            );
          }
          return const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF888888),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.cyan, size: 32);
          }
          return const IconThemeData(color: Color(0xFF888888), size: 28);
        }),
        height: 88, // Taller nav bar
      ),

      // Cards - Larger padding and higher contrast border
      cardTheme: CardThemeData(
        color: const Color(0xFF1A1A1A),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: Color(0xFF444444),
            width: 2,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // Buttons - Much larger for easy tapping
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cyan,
          foregroundColor: AppColors.pureBlack,
          elevation: 0,
          minimumSize: const Size(double.infinity, 64), // Tall buttons
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          textStyle: const TextStyle(
            fontSize: 20, // Larger button text
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFF666666), width: 2),
          minimumSize: const Size(double.infinity, 64),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.cyan,
          minimumSize: const Size(48, 56),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration - Larger
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF444444), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF444444), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.cyan, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF888888),
          fontSize: 18,
        ),
        labelStyle: const TextStyle(
          color: Color(0xFFAAAAAA),
          fontSize: 18,
        ),
      ),

      // Text Theme - All sizes scaled up
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 40, // 32 * 1.25
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displayMedium: TextStyle(
          fontSize: 35, // 28 * 1.25
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displaySmall: TextStyle(
          fontSize: 30, // 24 * 1.25
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineLarge: TextStyle(
          fontSize: 28, // 22 * 1.27
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 25, // 20 * 1.25
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        headlineSmall: TextStyle(
          fontSize: 23, // 18 * 1.27
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontSize: 20, // 16 * 1.25
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        titleSmall: TextStyle(
          fontSize: 18, // 14 * 1.29
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 20, // 16 * 1.25
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: 18, // 14 * 1.29
          fontWeight: FontWeight.w400,
          color: Color(0xFFCCCCCC),
        ),
        bodySmall: TextStyle(
          fontSize: 16, // 12 * 1.33
          fontWeight: FontWeight.w400,
          color: Color(0xFFAAAAAA),
        ),
        labelLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        labelMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFFCCCCCC),
        ),
        labelSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFFAAAAAA),
          letterSpacing: 1.2,
        ),
      ),

      // Icon Theme - Larger icons throughout
      iconTheme: const IconThemeData(
        size: 28,
        color: Colors.white,
      ),

      // Divider - More visible
      dividerTheme: const DividerThemeData(
        color: Color(0xFF444444),
        thickness: 2,
        space: 2,
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.cyan,
        linearTrackColor: Color(0xFF333333),
        circularTrackColor: Color(0xFF333333),
      ),

      // Snackbar - Larger text
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2A2A2A),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        behavior: SnackBarBehavior.floating,
        // Clear the floating nav bar (52px + bottom safe area + gap)
        insetPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 80, top: 8),
      ),

      // Dialog - Larger
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 18,
          color: Color(0xFFCCCCCC),
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        dragHandleColor: Color(0xFF666666),
        dragHandleSize: Size(48, 6),
      ),

      // Chip - Larger
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2A2A2A),
        labelStyle: const TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
        side: const BorderSide(color: Color(0xFF444444), width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // Switch - Larger
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.cyan;
          }
          return const Color(0xFF666666);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.cyan.withOpacity(0.5);
          }
          return const Color(0xFF333333);
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // Slider - Larger thumb
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.cyan,
        inactiveTrackColor: const Color(0xFF444444),
        thumbColor: AppColors.cyan,
        overlayColor: AppColors.cyan.withOpacity(0.2),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
        trackHeight: 8,
      ),
    );
  }

  /// Light theme for senior mode
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme - High contrast
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0088AA), // Darker cyan for contrast
        onPrimary: Colors.white,
        secondary: Color(0xFF6633CC), // Darker purple
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: Color(0xFF1A1A1A),
        error: Color(0xFFCC0000), // Darker red for contrast
        onError: Colors.white,
      ),

      // Scaffold
      scaffoldBackgroundColor: Colors.white,

      // AppBar - Larger text
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1A1A1A),
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 64,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(
          size: 28,
          color: Color(0xFF1A1A1A),
        ),
      ),

      // Buttons - Large for easy tapping
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0088AA),
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 64),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // Text Theme - Scaled up with high contrast
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A1A),
        ),
        headlineMedium: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
        ),
        bodyLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w400,
          color: Color(0xFF1A1A1A),
        ),
        bodyMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: Color(0xFF333333),
        ),
        bodySmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFF555555),
        ),
      ),

      // Icon Theme - Larger
      iconTheme: const IconThemeData(
        size: 28,
        color: Color(0xFF1A1A1A),
      ),
    );
  }
}
