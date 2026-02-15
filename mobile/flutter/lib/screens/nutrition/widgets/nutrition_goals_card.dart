import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/nutrition.dart';
import '../../../data/models/nutrition_preferences.dart';
import '../../../data/providers/nutrition_preferences_provider.dart';
import '../../../data/repositories/hydration_repository.dart';
import '../../../data/repositories/nutrition_preferences_repository.dart';
import '../../../data/services/health_service.dart';

/// Dedicated card showing nutrition goals with edit/recalculate options
class NutritionGoalsCard extends ConsumerWidget {
  final NutritionTargets? targets;
  final DailyNutritionSummary? summary;
  final bool isDark;
  final VoidCallback? onEdit;
  final VoidCallback? onRecalculate;
  final VoidCallback? onHydrationTap;

  const NutritionGoalsCard({
    super.key,
    this.targets,
    this.summary,
    required this.isDark,
    this.onEdit,
    this.onRecalculate,
    this.onHydrationTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('🎯 NutritionGoalsCard build called, isDark: $isDark');
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;
    final coral = isDark ? AppColors.coral : AppColorsLight.coral;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final electricBlue = isDark ? AppColors.electricBlue : AppColorsLight.electricBlue;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final hydrationState = ref.watch(hydrationProvider);
    final currentMl = hydrationState.todaySummary?.totalMl ?? 0;
    final goalMl = hydrationState.dailyGoalMl;
    final hydrationPct = goalMl > 0 ? (currentMl / goalMl).clamp(0.0, 1.0) : 0.0;

    final prefsState = ref.watch(nutritionPreferencesProvider);
    final dynamicTargets = prefsState.dynamicTargets;
    final isTrainingDay = dynamicTargets?.isTrainingDay ?? false;
    final nutritionGoal = prefsState.preferences?.nutritionGoalEnum;

    // Use dynamic targets if available, otherwise fall back to base targets
    final effectiveCalories = (dynamicTargets?.targetCalories ?? targets?.dailyCalorieTarget ?? 2000).toDouble();
    final effectiveProtein = (dynamicTargets?.targetProteinG ?? targets?.dailyProteinTargetG ?? 150).toDouble();
    final effectiveCarbs = (dynamicTargets?.targetCarbsG ?? targets?.dailyCarbsTargetG ?? 250).toDouble();
    final effectiveFat = (dynamicTargets?.targetFatG ?? targets?.dailyFatTargetG ?? 65).toDouble();

    // Current consumed values
    final consumedCalories = (summary?.totalCalories ?? 0).toDouble();
    final consumedProtein = (summary?.totalProteinG ?? 0).toDouble();
    final consumedCarbs = (summary?.totalCarbsG ?? 0).toDouble();
    final consumedFat = (summary?.totalFatG ?? 0).toDouble();

    // Calories burned from Health Connect / Watch
    final activityState = ref.watch(dailyActivityProvider);
    final caloriesBurned = activityState.today?.caloriesBurned ?? 0;
    final isFromWatch = activityState.today?.isFromWatch ?? false;

    final green = isDark ? AppColors.green : AppColorsLight.green;

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: teal.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: green, width: 4),
            ),
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with title, training indicator, and actions
          Row(
            children: [
              Icon(Icons.track_changes, color: teal, size: 18),
              const SizedBox(width: 6),
              Text(
                'Daily Goals',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              if (isTrainingDay) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: teal.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fitness_center, size: 10, color: teal),
                      const SizedBox(width: 3),
                      Text(
                        'Training',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: teal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Flexible(
                child: GestureDetector(
                  onTap: onHydrationTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.water_drop,
                        size: 14,
                        color: hydrationPct >= 0.75
                            ? electricBlue
                            : hydrationPct >= 0.25
                                ? electricBlue.withValues(alpha: 0.6)
                                : textMuted,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          '$currentMl/${goalMl}ml',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Edit button
              IconButton(
                onPressed: onEdit,
                icon: Icon(Icons.edit_outlined, size: 18, color: textMuted),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Edit Goals',
              ),
              const SizedBox(width: 6),
              // Recalculate button
              IconButton(
                onPressed: onRecalculate,
                icon: Icon(Icons.refresh, size: 18, color: textMuted),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Recalculate',
              ),
            ],
          ),

          // Goal type badge
          if (nutritionGoal != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getGoalDisplayName(nutritionGoal),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: teal,
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Macro progress rings in a row
          Row(
            children: [
              Expanded(
                child: _MacroProgressRing(
                  label: 'Calories',
                  current: consumedCalories.toDouble(),
                  target: effectiveCalories.toDouble(),
                  color: teal,
                  unit: '',
                  isDark: isDark,
                  showKcal: true,
                ),
              ),
              Expanded(
                child: _MacroProgressRing(
                  label: 'Protein',
                  current: consumedProtein,
                  target: effectiveProtein,
                  color: purple,
                  unit: 'g',
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _MacroProgressRing(
                  label: 'Carbs',
                  current: consumedCarbs,
                  target: effectiveCarbs,
                  color: orange,
                  unit: 'g',
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _MacroProgressRing(
                  label: 'Fat',
                  current: consumedFat,
                  target: effectiveFat,
                  color: coral,
                  unit: 'g',
                  isDark: isDark,
                ),
              ),
            ],
          ),

          // Calories burned from Health Connect / Watch
          if (caloriesBurned > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_fire_department, size: 16, color: green),
                      const SizedBox(width: 6),
                      Text(
                        'Burned',
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                      const Spacer(),
                      Text(
                        '+${caloriesBurned.toInt()}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: green,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isFromWatch ? 'from Watch' : 'from Health Connect',
                        style: TextStyle(fontSize: 10, color: textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.balance, size: 16, color: teal),
                      const SizedBox(width: 6),
                      Text(
                        'Net',
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                      const Spacer(),
                      Text(
                        '${(consumedCalories - caloriesBurned).toInt()}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: teal,
                        ),
                      ),
                      Text(
                        ' / ${effectiveCalories.toInt()} kcal',
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Adjustment reason - only show if it's NOT the default "base_targets"
          // (i.e., only show when there's an actual adjustment like "training_day" or "rest_day")
          if (dynamicTargets?.adjustmentReason != null &&
              dynamicTargets!.adjustmentReason != 'base_targets') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getAdjustmentReasonDisplay(dynamicTargets!.adjustmentReason),
                      style: TextStyle(
                        fontSize: 12,
                        color: teal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
        ),
      ),
    );
  }

  String _getGoalDisplayName(NutritionGoal goal) {
    switch (goal) {
      case NutritionGoal.loseFat:
        return '🔥 Lose Fat';
      case NutritionGoal.buildMuscle:
        return '💪 Build Muscle';
      case NutritionGoal.maintain:
        return '⚖️ Maintain Weight';
      case NutritionGoal.improveEnergy:
        return '⚡ Improve Energy';
      case NutritionGoal.eatHealthier:
        return '🥗 Eat Healthier';
      case NutritionGoal.recomposition:
        return '🎯 Body Recomposition';
    }
  }

  String _getAdjustmentReasonDisplay(String reason) {
    switch (reason) {
      case 'training_day':
        return 'Targets adjusted for your workout today';
      case 'rest_day':
        return 'Rest day - lower calorie target';
      case 'fasting_day':
        return 'Fasting day - targets adjusted';
      default:
        return reason;
    }
  }
}

/// Circular progress ring for individual macros
class _MacroProgressRing extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final Color color;
  final String unit;
  final bool isDark;
  final bool showKcal;

  const _MacroProgressRing({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.unit,
    required this.isDark,
    this.showKcal = false,
  });

  double get percentage => target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    return Column(
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background ring
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 5,
                  backgroundColor: glassSurface,
                  color: glassSurface,
                ),
              ),
              // Progress ring
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  value: percentage,
                  strokeWidth: 5,
                  backgroundColor: Colors.transparent,
                  color: color,
                  strokeCap: StrokeCap.round,
                ),
              ),
              // Center text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${current.toInt()}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  if (showKcal)
                    Text(
                      'kcal',
                      style: TextStyle(
                        fontSize: 8,
                        color: textMuted,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: textMuted,
          ),
        ),
        Text(
          '/${target.toInt()}$unit',
          style: TextStyle(
            fontSize: 10,
            color: textMuted.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

/// Compact inline macro display for header area
/// Shows: P: 45/150g | C: 120/200g | F: 30/65g
class CompactMacroTargets extends StatelessWidget {
  final DailyNutritionSummary? summary;
  final NutritionTargets? targets;
  final DynamicNutritionTargets? dynamicTargets;
  final bool isDark;
  final VoidCallback? onTap;

  const CompactMacroTargets({
    super.key,
    this.summary,
    this.targets,
    this.dynamicTargets,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;
    final coral = isDark ? AppColors.coral : AppColorsLight.coral;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    // Use dynamic targets if available
    final effectiveProtein = (dynamicTargets?.targetProteinG ?? targets?.dailyProteinTargetG ?? 150).toDouble();
    final effectiveCarbs = (dynamicTargets?.targetCarbsG ?? targets?.dailyCarbsTargetG ?? 250).toDouble();
    final effectiveFat = (dynamicTargets?.targetFatG ?? targets?.dailyFatTargetG ?? 65).toDouble();

    final consumedProtein = (summary?.totalProteinG ?? 0).toDouble();
    final consumedCarbs = (summary?.totalCarbsG ?? 0).toDouble();
    final consumedFat = (summary?.totalFatG ?? 0).toDouble();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: glassSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _CompactMacroItem(
              label: 'P',
              current: consumedProtein,
              target: effectiveProtein,
              color: purple,
              isDark: isDark,
            ),
            Container(
              width: 1,
              height: 24,
              color: textMuted.withValues(alpha: 0.2),
            ),
            _CompactMacroItem(
              label: 'C',
              current: consumedCarbs,
              target: effectiveCarbs,
              color: orange,
              isDark: isDark,
            ),
            Container(
              width: 1,
              height: 24,
              color: textMuted.withValues(alpha: 0.2),
            ),
            _CompactMacroItem(
              label: 'F',
              current: consumedFat,
              target: effectiveFat,
              color: coral,
              isDark: isDark,
            ),
            // Edit indicator
            Icon(
              Icons.chevron_right,
              size: 16,
              color: textMuted.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactMacroItem extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final Color color;
  final bool isDark;

  const _CompactMacroItem({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textMuted,
          ),
        ),
        Text(
          '${current.toInt()}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        Text(
          '/${target.toInt()}g',
          style: TextStyle(
            fontSize: 11,
            color: textMuted,
          ),
        ),
      ],
    );
  }
}
