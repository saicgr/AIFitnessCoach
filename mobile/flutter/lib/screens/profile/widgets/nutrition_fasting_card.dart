import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/nutrition_preferences.dart';
import '../../../data/providers/nutrition_preferences_provider.dart';
import '../../../data/services/haptic_service.dart';
import '../../settings/sections/nutrition_fasting_section.dart';

/// Displays nutrition and fasting profile information from onboarding
class NutritionFastingCard extends ConsumerWidget {
  const NutritionFastingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    // Use monochrome accent
    final accentColor = isDark ? AppColors.accent : AppColorsLight.accent;

    final nutritionState = ref.watch(nutritionPreferencesProvider);
    final fastingState = ref.watch(fastingSettingsProvider);
    final prefs = nutritionState.preferences;

    // Use current targets (dynamic if available, otherwise base) for consistency with nutrition tab
    final currentCalories = nutritionState.currentCalorieTarget;
    final currentProtein = nutritionState.currentProteinTarget;
    final currentCarbs = nutritionState.currentCarbsTarget;
    final currentFat = nutritionState.currentFatTarget;

    // Show loading state
    if (nutritionState.isLoading || fastingState.isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          // Header with edit button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Text(
                  'Nutrition & Fasting',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    HapticService.selection();
                    context.push('/nutrition-settings');
                  },
                  icon: Icon(
                    Icons.edit_outlined,
                    color: accentColor,
                    size: 20,
                  ),
                  tooltip: 'Edit nutrition settings',
                ),
              ],
            ),
          ),

          // Nutrition info rows
          _buildInfoRow(
            icon: Icons.local_fire_department_outlined,
            iconColor: accentColor,
            label: 'Daily Target',
            value: '$currentCalories cal',
            isDark: isDark,
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),
          Divider(height: 1, color: cardBorder, indent: 48, endIndent: 16),

          _buildInfoRow(
            icon: Icons.restaurant_outlined,
            iconColor: accentColor,
            label: 'Diet Type',
            value: _getDietTypeDisplay(prefs?.dietType),
            isDark: isDark,
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),
          Divider(height: 1, color: cardBorder, indent: 48, endIndent: 16),

          _buildInfoRow(
            icon: Icons.flag_outlined,
            iconColor: accentColor,
            label: 'Goal',
            value: _getNutritionGoalDisplay(prefs?.nutritionGoal),
            isDark: isDark,
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),
          Divider(height: 1, color: cardBorder, indent: 48, endIndent: 16),

          // Macros row
          _buildMacrosRow(
            protein: currentProtein,
            carbs: currentCarbs,
            fat: currentFat,
            isDark: isDark,
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),

          // Fasting section if enabled
          if (fastingState.interestedInFasting) ...[
            Divider(height: 1, color: cardBorder, indent: 16, endIndent: 16),
            _buildInfoRow(
              icon: Icons.schedule,
              iconColor: accentColor,
              label: 'Fasting Protocol',
              value: _getFastingProtocolDisplay(fastingState.fastingProtocol),
              isDark: isDark,
              textPrimary: textPrimary,
              textMuted: textMuted,
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: textMuted,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacrosRow({
    required int protein,
    required int carbs,
    required int fat,
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
  }) {
    // Use monochrome accent
    final accentColor = isDark ? AppColors.accent : AppColorsLight.accent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.pie_chart_outline, color: accentColor, size: 20),
          const SizedBox(width: 12),
          Text(
            'Macros',
            style: TextStyle(
              fontSize: 14,
              color: textMuted,
            ),
          ),
          const Spacer(),
          _MacroBadge(label: 'P', value: '${protein}g', color: accentColor),
          const SizedBox(width: 6),
          _MacroBadge(label: 'C', value: '${carbs}g', color: accentColor),
          const SizedBox(width: 6),
          _MacroBadge(label: 'F', value: '${fat}g', color: accentColor),
        ],
      ),
    );
  }

  String _getDietTypeDisplay(String? dietType) {
    if (dietType == null) return 'Balanced';

    final diet = DietType.fromString(dietType);
    return diet.displayName;
  }

  String _getNutritionGoalDisplay(String? goal) {
    if (goal == null) return 'Maintain Weight';

    final nutritionGoal = NutritionGoal.fromString(goal);
    return nutritionGoal.displayName;
  }

  String _getFastingProtocolDisplay(String? protocol) {
    if (protocol == null) return '16:8';

    switch (protocol.toLowerCase()) {
      case '12:12':
      case 'twelve12':
        return '12:12';
      case '14:10':
      case 'fourteen10':
        return '14:10';
      case '16:8':
      case 'sixteen8':
        return '16:8';
      case '18:6':
      case 'eighteen6':
        return '18:6';
      case '20:4':
      case 'twenty4':
        return '20:4';
      case 'omad':
        return 'OMAD';
      case '5:2':
      case 'fivetwo':
        return '5:2';
      case 'custom':
        return 'Custom';
      default:
        return protocol;
    }
  }
}

/// Small macro badge showing label and value
class _MacroBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
