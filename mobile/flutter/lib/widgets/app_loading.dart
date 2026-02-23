import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'empty_state.dart';

/// Standardized loading indicators for the app.
///
/// Provides consistent loading states across all screens:
/// - [circular] - Standard spinner with theme colors
/// - [skeleton] - Skeleton loading list (wraps [SkeletonLoader])
/// - [inline] - Small 16px spinner for buttons/cells
/// - [fullScreen] - Centered loading with optional message
class AppLoading {
  AppLoading._();

  /// Standard circular loading indicator with theme colors.
  ///
  /// ```dart
  /// AppLoading.circular()
  /// AppLoading.circular(size: 24, color: Colors.white)
  /// ```
  static Widget circular({double size = 36, Color? color}) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: size < 24 ? 2 : 3,
        valueColor: color != null ? AlwaysStoppedAnimation(color) : null,
      ),
    );
  }

  /// Skeleton loading list (wraps existing [SkeletonLoader]).
  ///
  /// ```dart
  /// AppLoading.skeleton()
  /// AppLoading.skeleton(count: 5, height: 80)
  /// ```
  static Widget skeleton({int count = 3, double height = 72}) {
    return SkeletonLoader(
      itemCount: count,
      itemHeight: height,
    );
  }

  /// Small inline loader for buttons/cells (16px).
  ///
  /// ```dart
  /// isLoading ? AppLoading.inline() : Text('Save')
  /// ```
  static Widget inline({Color? color}) {
    return SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: color != null ? AlwaysStoppedAnimation(color) : null,
      ),
    );
  }

  /// Full-screen centered loading with optional message.
  ///
  /// ```dart
  /// AppLoading.fullScreen()
  /// AppLoading.fullScreen(message: 'Loading workouts...')
  /// ```
  static Widget fullScreen({String? message}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          circular(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final isDark =
                    Theme.of(context).brightness == Brightness.dark;
                return Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColorsLight.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
