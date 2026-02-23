import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Standardized snackbar helpers for the app.
///
/// All snackbars are floating, rounded (borderRadius 12), and auto-dismiss.
/// Success/info dismiss after 3s, error after 5s.
///
/// ```dart
/// AppSnackBar.success(context, 'Workout saved!');
/// AppSnackBar.error(context, 'Failed to load data.');
/// AppSnackBar.info(context, 'Tap to edit.');
/// ```
class AppSnackBar {
  AppSnackBar._();

  /// Show a success snackbar (green, 3s, checkmark icon).
  static void success(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      backgroundColor: AppColors.success,
      duration: const Duration(seconds: 3),
    );
  }

  /// Show an error snackbar (red, 5s, error icon).
  static void error(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.error_rounded,
      backgroundColor: AppColors.error,
      duration: const Duration(seconds: 5),
    );
  }

  /// Show an info snackbar (blue, 3s, info icon).
  static void info(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.info_rounded,
      backgroundColor: AppColors.info,
      duration: const Duration(seconds: 3),
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Duration duration,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          duration: duration,
          dismissDirection: DismissDirection.horizontal,
        ),
      );
  }
}
