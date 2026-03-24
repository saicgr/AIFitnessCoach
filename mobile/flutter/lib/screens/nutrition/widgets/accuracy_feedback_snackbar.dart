import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/haptic_service.dart';

/// Shows a brief accuracy feedback snackbar after food logging.
/// Displays the food name, calorie count, and thumbs up/down buttons.
///
/// - Thumbs up: dismisses with light haptic feedback
/// - Thumbs down: dismisses with medium haptic feedback, calls [onThumbsDown]
void showAccuracyFeedbackSnackbar(
  BuildContext context, {
  required String foodName,
  required int calories,
  required VoidCallback onThumbsDown,
}) {
  final messenger = ScaffoldMessenger.of(context);
  final bottomPadding = MediaQuery.of(context).padding.bottom;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final bgColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
  final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
  final mutedColor = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

  // Truncate long food names
  final displayName =
      foodName.length > 28 ? '${foodName.substring(0, 25)}...' : foodName;

  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$displayName — $calories cal',
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Accurate?',
            style: TextStyle(color: mutedColor, fontSize: 12),
          ),
          const SizedBox(width: 4),
          _FeedbackButton(
            icon: Icons.thumb_up_outlined,
            color: AppColors.green,
            onTap: () {
              HapticService.light();
              messenger.hideCurrentSnackBar();
            },
          ),
          const SizedBox(width: 2),
          _FeedbackButton(
            icon: Icons.thumb_down_outlined,
            color: AppColors.red,
            onTap: () {
              HapticService.medium();
              messenger.hideCurrentSnackBar();
              onThumbsDown();
            },
          ),
        ],
      ),
      backgroundColor: bgColor,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      margin: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: bottomPadding + 100,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
  );
}

class _FeedbackButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeedbackButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}
