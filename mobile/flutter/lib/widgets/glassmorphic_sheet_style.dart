/// Glassmorphic Bottom Sheet Style Reference
///
/// This file documents the standard styling for bottom sheets in the app,
/// based on the weekly check-in sheet design.
///
/// USAGE: Copy the patterns below when creating new bottom sheets.

import 'dart:ui';
import 'package:flutter/material.dart';

/// Standard values for glassmorphic bottom sheets
class GlassmorphicSheetStyle {
  GlassmorphicSheetStyle._();

  // ═══════════════════════════════════════════════════════════════════════════
  // BARRIER (scrim behind sheet)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Light scrim so content shows through
  static Color get barrierColor => Colors.black.withValues(alpha: 0.2);

  // ═══════════════════════════════════════════════════════════════════════════
  // BORDER RADIUS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Standard border radius for sheet top corners
  static const double borderRadius = 28.0;
  static BorderRadius get sheetBorderRadius =>
      const BorderRadius.vertical(top: Radius.circular(borderRadius));

  // ═══════════════════════════════════════════════════════════════════════════
  // BLUR
  // ═══════════════════════════════════════════════════════════════════════════

  /// Standard blur amount for glassmorphic effect
  static const double blurSigma = 8.0;
  static ImageFilter get blurFilter =>
      ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma);

  // ═══════════════════════════════════════════════════════════════════════════
  // BACKGROUND COLOR
  // ═══════════════════════════════════════════════════════════════════════════

  /// Semi-transparent background - dark mode
  static Color get backgroundDark => Colors.black.withValues(alpha: 0.4);

  /// Semi-transparent background - light mode
  static Color get backgroundLight => Colors.white.withValues(alpha: 0.6);

  /// Get background color based on theme
  static Color backgroundColor(bool isDark) =>
      isDark ? backgroundDark : backgroundLight;

  // ═══════════════════════════════════════════════════════════════════════════
  // TOP BORDER
  // ═══════════════════════════════════════════════════════════════════════════

  /// Subtle top border width
  static const double borderWidth = 0.5;

  /// Top border color - dark mode
  static Color get borderColorDark => Colors.white.withValues(alpha: 0.2);

  /// Top border color - light mode
  static Color get borderColorLight => Colors.black.withValues(alpha: 0.1);

  /// Get border based on theme
  static Border topBorder(bool isDark) => Border(
    top: BorderSide(
      color: isDark ? borderColorDark : borderColorLight,
      width: borderWidth,
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // HANDLE BAR
  // ═══════════════════════════════════════════════════════════════════════════

  /// Handle bar dimensions
  static const double handleWidth = 40.0;
  static const double handleHeight = 4.0;
  static const double handleBorderRadius = 2.0;

  /// Build standard handle bar widget
  static Widget handleBar(Color textMuted) => Container(
    width: handleWidth,
    height: handleHeight,
    decoration: BoxDecoration(
      color: textMuted,
      borderRadius: BorderRadius.circular(handleBorderRadius),
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // DECORATION HELPER
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get complete BoxDecoration for sheet container
  static BoxDecoration sheetDecoration(bool isDark) => BoxDecoration(
    color: backgroundColor(isDark),
    borderRadius: sheetBorderRadius,
    border: topBorder(isDark),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// EXAMPLE USAGE - Copy this pattern for new bottom sheets
// ═══════════════════════════════════════════════════════════════════════════════

/*
/// Shows a glassmorphic bottom sheet
Future<void> showMySheet(BuildContext context, WidgetRef ref) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  // Hide nav bar while sheet is open
  ref.read(floatingNavBarVisibleProvider.notifier).state = false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.2), // Light scrim
    builder: (context) => MySheet(isDark: isDark),
  );

  // Show nav bar when sheet is closed
  ref.read(floatingNavBarVisibleProvider.notifier).state = true;
}

/// The sheet content widget
class MySheet extends StatelessWidget {
  final bool isDark;
  const MySheet({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.9, // or mainAxisSize: min
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.6),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Sheet content goes here...
            ],
          ),
        ),
      ),
    );
  }
}
*/
