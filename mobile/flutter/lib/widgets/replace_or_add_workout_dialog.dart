import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../screens/home/widgets/components/sheet_theme_colors.dart';

/// Reusable Replace / Add prompt used by both the Regenerate Workout flow
/// and the Mood Workout flow.
///
/// Returns:
///   * `true`  — user chose Replace
///   * `false` — user chose Add (keep existing too)
///   * `null`  — user dismissed the dialog / tapped outside
Future<bool?> showReplaceOrAddWorkoutDialog(
  BuildContext context, {
  String message = 'You already have a workout scheduled for today.',
  String addLabel = 'Add Workout',
  String replaceLabel = 'Replace',
  String title = 'What would you like to do?',
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final colors = context.sheetColors;

  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Text(
        message,
        style: TextStyle(
          color:
              isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(addLabel, style: TextStyle(color: colors.cyan)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.purple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(replaceLabel),
        ),
      ],
    ),
  );
}
