import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/chrome_constants.dart';
import 'seeded_scheme.dart';

/// App theme configuration - Dark OLED optimized
class AppTheme {
  AppTheme._();

  static ThemeData buildDarkTheme(Color primary) {
    final onPrimary = primary.computeLuminance() > 0.4 ? Colors.black : Colors.white;
    // Every colour ROLE is seeded from the single accent (register row 15).
    //
    // This used to be `ColorScheme.dark(primary: primary, secondary:
    // AppColors.purple, …)`, which left two independent accents live at once:
    // `colorScheme.primary` followed the user's accent while
    // `colorScheme.secondary` was always purple and every unspecified role
    // (`secondaryContainer`, `tertiary`, `primaryContainer`, …) fell back to
    // Material's baseline purple. 173 widgets read those roles, so a single
    // screen could legitimately paint three unrelated "accents".
    //
    // Seeding derives them all from `primary`, so choosing an accent moves the
    // whole scheme together. The app's own surface/error tokens are re-applied
    // on top because those are brand decisions, not tonal ones.
    //
    // Memoised (see seeded_scheme.dart): `ColorScheme.fromSeed` costs ~287 µs
    // versus ~0.4 µs for the const scheme it replaced, and `app.dart` builds
    // BOTH themes on every root rebuild.
    final seeded = seededScheme(primary, Brightness.dark);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color Scheme
      colorScheme: seeded.copyWith(
        primary: primary,
        onPrimary: onPrimary,
        onSecondary: AppColors.textPrimary,
        surface: AppColors.nearBlack,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: AppColors.textPrimary,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.pureBlack,

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.pureBlack,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.pureBlack,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.nearBlack,
        selectedItemColor: primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Navigation Bar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.nearBlack,
        indicatorColor: primary.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primary,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primary, size: 24);
          }
          return const IconThemeData(color: AppColors.textMuted, size: 24);
        }),
        height: 80,
      ),

      // Cards
      cardTheme: CardThemeData(
        color: AppColors.elevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.cardBorder.withOpacity(0.5),
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
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
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(color: AppColors.textMuted.withOpacity(0.3)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // FAB
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.purple,
        foregroundColor: AppColors.textPrimary,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.cardBorder.withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),

      // Text Theme
      // Signature: Anton activated on the DISPLAY styles (mastheads / hero
      // numerals). Labels/titles/body opt into Barlow Condensed / Fraunces /
      // Space Mono surgically via ZType (core/theme/app_typography.dart) as
      // each screen is restyled — avoids breaking non-uppercase label/button text.
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Anton',
          fontSize: 32,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          height: 0.98,
          color: AppColors.textPrimary,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Anton',
          fontSize: 28,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          height: 0.98,
          color: AppColors.textPrimary,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Anton',
          fontSize: 24,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          height: 1.0,
          color: AppColors.textPrimary,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
          letterSpacing: 1.5,
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: AppColors.cardBorder.withOpacity(0.3),
        thickness: 1,
        space: 1,
      ),

      // Progress Indicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: AppColors.glassSurface,
        circularTrackColor: AppColors.glassSurface,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.elevated,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        // Clear the floating nav bar AND the quick-log FAB that floats above
        // it. This was the literal `80`, which put the toast band straight
        // across the FAB — see [kSnackBarBottomInset] for why that made UNDO
        // both unreadable and untappable (E2E row 125).
        insetPadding: const EdgeInsets.only(left: 16, right: 16, bottom: kSnackBarBottomInset, top: 8), // rtl-keep: SnackBarThemeData.insetPadding requires EdgeInsets
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.elevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),

      // Date / Time pickers
      //
      // Without these the Material pickers are the ONLY app surfaces that
      // paint themselves from the seeded tonal palette instead of the brand
      // tokens: `DatePickerThemeData.backgroundColor` defaults to
      // `colorScheme.surfaceContainerHigh`, and `colorScheme.surface` (the
      // only surface role this theme overrides) is not consulted. With an
      // orange seed that tonal role resolves to a brown/tan panel — an
      // obviously off-brand dialog dropped into a black-and-accent app.
      //
      // Fixing it here rather than at the call sites is the point: 35 call
      // sites across the app open `showDatePicker`/`showTimePicker`, only 8 of
      // which hand-rolled their own `builder: (ctx, child) => Theme(...)`
      // wrapper. A theme entry covers all of them, including every future one.
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.elevated,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: AppColors.elevated,
        headerForegroundColor: AppColors.textSecondary,
        dividerColor: AppColors.cardBorder,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.elevated,
        dialBackgroundColor: AppColors.glassSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.elevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        dragHandleColor: AppColors.textMuted,
        dragHandleSize: Size(40, 4),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.glassSurface,
        labelStyle: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary.withOpacity(0.5);
          return null;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }
}
