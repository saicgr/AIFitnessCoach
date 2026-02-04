/// Exercise Options Info Sheet
///
/// A bottom sheet that explains what each exercise option means.
/// Displayed when user taps "What do these mean?" in the exercise menu.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';

/// Show the exercise options info sheet
Future<void> showExerciseOptionsInfoSheet({
  required BuildContext context,
}) {
  HapticFeedback.lightImpact();

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.2),
    builder: (ctx) => const ExerciseOptionsInfoSheet(),
  );
}

/// Exercise options info sheet widget
class ExerciseOptionsInfoSheet extends StatelessWidget {
  const ExerciseOptionsInfoSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final screenHeight = MediaQuery.of(context).size.height;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.85,
          ),
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.electricBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.help_outline_rounded,
                          color: AppColors.electricBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Exercise Options Explained',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Info items
                _buildInfoItem(
                  context: context,
                  icon: Icons.favorite,
                  iconColor: AppColors.error,
                  title: 'Favorite',
                  description: 'Save exercises you love for quick access. Favorites appear in your Exercise Library filtered view and are prioritized in AI recommendations.',
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),

                _buildInfoItem(
                  context: context,
                  icon: Icons.playlist_add,
                  iconColor: AppColors.cyan,
                  title: 'Repeat Next Time',
                  description: 'Queue this exercise to appear in your next workout. Great for exercises you want to focus on. Queued exercises expire after 7 days if not used.',
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),

                _buildInfoItem(
                  context: context,
                  icon: Icons.push_pin,
                  iconColor: AppColors.purple,
                  title: 'Staple Exercise',
                  description: 'Mark as a core lift that will never be rotated out. AI will always include staple exercises in your workouts - perfect for compound movements you want consistent progressive overload on.',
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),

                _buildDivider(isDark),

                _buildInfoItem(
                  context: context,
                  icon: Icons.history_rounded,
                  iconColor: AppColors.electricBlue,
                  title: 'View History',
                  description: 'See your performance history and progression charts for this exercise over time.',
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),

                _buildInfoItem(
                  context: context,
                  icon: Icons.swap_horiz,
                  iconColor: AppColors.electricBlue,
                  title: 'Swap Exercise',
                  description: 'Replace with a similar exercise targeting the same muscles. Choose from AI suggestions, recent swaps, or browse the full library.',
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),

                _buildInfoItem(
                  context: context,
                  icon: Icons.link,
                  iconColor: AppColors.electricBlue,
                  title: 'Link as Superset',
                  description: 'Pair with another exercise to perform back-to-back with minimal rest. Great for time efficiency and muscle pump.',
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),

                _buildDivider(isDark),

                _buildInfoItem(
                  context: context,
                  icon: Icons.delete_outline,
                  iconColor: AppColors.error,
                  title: 'Remove from Workout',
                  description: 'Remove this exercise from the current workout only. The exercise may appear again in future workouts.',
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),

                _buildInfoItem(
                  context: context,
                  icon: Icons.block_rounded,
                  iconColor: AppColors.error,
                  title: 'Never Recommend',
                  description: 'Permanently block this exercise from future AI recommendations. Use this for exercises you dislike or cannot perform due to injury.',
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),

                // Bottom padding for safe area
                SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon container
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),

          const SizedBox(width: 14),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Divider(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.06),
      ),
    );
  }
}
