import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Standardized dialog helpers for the app.
///
/// Use these instead of raw `showDialog` calls to ensure
/// consistent styling across all dialogs.
///
/// Usage:
/// ```dart
/// final confirmed = await AppDialog.confirm(
///   context,
///   title: 'Delete Workout?',
///   message: 'This action cannot be undone.',
///   confirmText: 'Delete',
///   confirmColor: AppColors.error,
///   icon: Icons.delete_rounded,
/// );
/// ```
class AppDialog {
  AppDialog._();

  static const double _borderRadius = 20.0;
  static const double _iconContainerSize = 48.0;
  static const double _iconSize = 24.0;

  /// Show a confirmation dialog with confirm/cancel buttons.
  /// Returns true if confirmed, false if cancelled.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
    IconData? icon,
  }) async {
    final result = await _show<bool>(
      context,
      title: title,
      message: message,
      icon: icon,
      actions: (isDark, accent, dialogContext) => [
        _DialogButton(
          text: cancelText,
          onTap: () => Navigator.of(dialogContext).pop(false),
          isPrimary: false,
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _DialogButton(
          text: confirmText,
          onTap: () => Navigator.of(dialogContext).pop(true),
          isPrimary: true,
          isDark: isDark,
          color: confirmColor,
        ),
      ],
    );
    return result ?? false;
  }

  /// Show an info dialog with OK button.
  static Future<void> info(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'OK',
    IconData? icon,
  }) async {
    await _show<void>(
      context,
      title: title,
      message: message,
      icon: icon,
      actions: (isDark, accent, dialogContext) => [
        _DialogButton(
          text: buttonText,
          onTap: () => Navigator.of(dialogContext).pop(),
          isPrimary: true,
          isDark: isDark,
        ),
      ],
    );
  }

  /// Show a destructive confirmation (red confirm button).
  static Future<bool> destructive(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Delete',
    String cancelText = 'Cancel',
    IconData? icon,
  }) async {
    final result = await _show<bool>(
      context,
      title: title,
      message: message,
      icon: icon ?? Icons.warning_amber_rounded,
      iconColor: AppColors.error,
      actions: (isDark, accent, dialogContext) => [
        _DialogButton(
          text: cancelText,
          onTap: () => Navigator.of(dialogContext).pop(false),
          isPrimary: false,
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _DialogButton(
          text: confirmText,
          onTap: () => Navigator.of(dialogContext).pop(true),
          isPrimary: true,
          isDark: isDark,
          color: AppColors.error,
        ),
      ],
    );
    return result ?? false;
  }

  /// Internal method that builds and shows the dialog.
  static Future<T?> _show<T>(
    BuildContext context, {
    required String title,
    required String message,
    IconData? icon,
    Color? iconColor,
    required List<Widget> Function(bool isDark, Color accent, BuildContext dialogContext) actions,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final accent = isDark ? AppColors.accent : AppColorsLight.accent;
    final resolvedIconColor = iconColor ?? accent;

    return showDialog<T>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Dialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                if (icon != null) ...[
                  Container(
                    width: _iconContainerSize,
                    height: _iconContainerSize,
                    decoration: BoxDecoration(
                      color: resolvedIconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color: resolvedIconColor,
                      size: _iconSize,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Action buttons — pass dialog context (ctx) so pop()
                // targets the root Navigator that owns the dialog overlay,
                // not a nested ShellRoute Navigator.
                Row(
                  children: actions(isDark, accent, ctx),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Internal dialog button widget.
class _DialogButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isDark;
  final Color? color;

  const _DialogButton({
    required this.text,
    required this.onTap,
    required this.isPrimary,
    required this.isDark,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.accent : AppColorsLight.accent;
    final accentContrast =
        isDark ? AppColors.accentContrast : AppColorsLight.accentContrast;
    final resolvedColor = color ?? accent;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    if (isPrimary) {
      return Expanded(
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: resolvedColor,
              foregroundColor:
                  color != null ? Colors.white : accentContrast,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: SizedBox(
        height: 48,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor:
                isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
            side: BorderSide(
              color: textMuted.withValues(alpha: 0.3),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
