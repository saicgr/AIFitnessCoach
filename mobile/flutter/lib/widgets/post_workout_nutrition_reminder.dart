import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../data/providers/unified_state_provider.dart';
import '../data/providers/nutrition_preferences_provider.dart';
import '../data/services/dynamic_nutrition_service.dart';

/// A widget that displays post-workout nutrition reminders
/// Shows when user is in post-workout window and needs to refuel
class PostWorkoutNutritionReminder extends ConsumerWidget {
  /// Whether to show in a compact mode
  final bool compact;

  /// Callback when user wants to log a meal
  final VoidCallback? onLogMeal;

  const PostWorkoutNutritionReminder({
    super.key,
    this.compact = false,
    this.onLogMeal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unifiedState = ref.watch(unifiedStateProvider);
    final nutritionPrefsState = ref.watch(nutritionPreferencesProvider);

    // Only show in post-workout state
    if (unifiedState.currentState != AppState.postWorkout) {
      return const SizedBox.shrink();
    }

    // Need a completed workout to show guidance
    final completedWorkout = unifiedState.todaysWorkout;
    if (completedWorkout == null) {
      return const SizedBox.shrink();
    }

    // Get nutrition preferences
    final nutritionPrefs = nutritionPrefsState.preferences;
    if (nutritionPrefs == null) {
      return const SizedBox.shrink();
    }

    // Get the dynamic nutrition service for guidance
    final nutritionService = ref.watch(dynamicNutritionServiceProvider);
    final wasFastedTraining = unifiedState.isFasting;
    final minutesSinceWorkout = unifiedState.minutesSinceWorkout;

    // Get post-workout guidance
    final guidance = nutritionService.getPostWorkoutGuidance(
      completedWorkout: completedWorkout,
      wasFastedTraining: wasFastedTraining,
      minutesSinceCompletion: minutesSinceWorkout,
      preferences: nutritionPrefs,
    );

    // Determine urgency level
    final urgency = _getUrgencyLevel(guidance.urgency);

    if (urgency == _UrgencyLevel.none) {
      return const SizedBox.shrink();
    }

    return _buildReminderBanner(
      context,
      guidance: guidance,
      urgency: urgency,
      minutesSinceWorkout: minutesSinceWorkout,
      wasFasted: wasFastedTraining,
    );
  }

  _UrgencyLevel _getUrgencyLevel(String urgencyString) {
    switch (urgencyString) {
      case 'high':
        return _UrgencyLevel.high;
      case 'medium':
        return _UrgencyLevel.medium;
      case 'low':
        return _UrgencyLevel.low;
      default:
        return _UrgencyLevel.none;
    }
  }

  Widget _buildReminderBanner(
    BuildContext context, {
    required PostWorkoutGuidance guidance,
    required _UrgencyLevel urgency,
    required int minutesSinceWorkout,
    required bool wasFasted,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get colors based on urgency
    final Color backgroundColor;
    final Color borderColor;
    final Color iconColor;
    final IconData icon;
    final String title;

    switch (urgency) {
      case _UrgencyLevel.high:
        backgroundColor = isDark
            ? AppColors.orange.withValues(alpha: 0.1)
            : AppColors.orange.withValues(alpha: 0.08);
        borderColor = AppColors.orange.withValues(alpha: 0.3);
        iconColor = AppColors.orange;
        icon = Icons.restaurant_menu;
        title = 'Time to Refuel!';
      case _UrgencyLevel.medium:
        backgroundColor = isDark
            ? AppColors.green.withValues(alpha: 0.1)
            : AppColors.green.withValues(alpha: 0.08);
        borderColor = AppColors.green.withValues(alpha: 0.3);
        iconColor = AppColors.green;
        icon = Icons.restaurant;
        title = 'Post-Workout Nutrition';
      case _UrgencyLevel.low:
        backgroundColor = isDark
            ? AppColors.cyan.withValues(alpha: 0.1)
            : AppColors.cyan.withValues(alpha: 0.08);
        borderColor = AppColors.cyan.withValues(alpha: 0.3);
        iconColor = AppColors.cyan;
        icon = Icons.local_dining;
        title = 'Recovery Nutrition';
      case _UrgencyLevel.none:
        return const SizedBox.shrink();
    }

    if (compact) {
      return _buildCompactBanner(
        context,
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        iconColor: iconColor,
        icon: icon,
        title: title,
        minutesSinceWorkout: minutesSinceWorkout,
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatMinutes(minutesSinceWorkout)} since workout',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (wasFasted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Fasted',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.orange,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            guidance.message,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
              height: 1.4,
            ),
          ),
          // Macro targets
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                _MacroChip(
                  label: 'Protein',
                  value: '${guidance.proteinTarget}g',
                  color: AppColors.cyan,
                ),
                const SizedBox(width: 8),
                _MacroChip(
                  label: 'Carbs',
                  value: '${guidance.carbsTarget}g',
                  color: AppColors.purple,
                ),
                const SizedBox(width: 8),
                _MacroChip(
                  label: 'Fat',
                  value: '${guidance.fatTarget}g',
                  color: AppColors.orange,
                ),
              ],
            ),
          ),
          // Meal suggestions
          if (guidance.suggestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick options:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: guidance.suggestions.take(3).map((suggestion) =>
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.elevated
                              : AppColorsLight.elevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: iconColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          suggestion.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                          ),
                        ),
                      ),
                    ).toList(),
                  ),
                ],
              ),
            ),
          // Log meal button
          if (onLogMeal != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: onLogMeal,
                  style: TextButton.styleFrom(
                    backgroundColor: iconColor.withValues(alpha: 0.1),
                    foregroundColor: iconColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    'Log Post-Workout Meal',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactBanner(
    BuildContext context, {
    required Color backgroundColor,
    required Color borderColor,
    required Color iconColor,
    required IconData icon,
    required String title,
    required int minutesSinceWorkout,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: iconColor,
              ),
            ),
          ),
          Text(
            _formatMinutes(minutesSinceWorkout),
            style: TextStyle(
              fontSize: 12,
              color: iconColor.withValues(alpha: 0.7),
            ),
          ),
          if (onLogMeal != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onLogMeal,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Log',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '${hours}h';
    }
    return '${hours}h ${mins}m';
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

enum _UrgencyLevel {
  none,
  low,
  medium,
  high,
}
