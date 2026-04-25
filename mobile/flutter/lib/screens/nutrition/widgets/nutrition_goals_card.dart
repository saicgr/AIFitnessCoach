import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/user_provider.dart';
import '../../../data/models/nutrition.dart';
import '../../../data/models/nutrition_preferences.dart';
import '../../../data/providers/nutrition_preferences_provider.dart';
import '../../../data/repositories/hydration_repository.dart';
import '../../../data/repositories/nutrition_preferences_repository.dart';
import '../../../data/services/health_service.dart';
import '../../../widgets/glass_sheet.dart';
import 'calories_burned_sheet.dart';

part 'nutrition_goals_card_part_calculation_info_sheet.dart';

/// Public launcher for the calculation breakdown sheet. Wraps the existing
/// `_CalculationInfoSheet` (BMR formula, TDEE, goal adjustment, macro split)
/// in `GlassSheet` so it inherits the app-wide glassmorphism + drag handle
/// + root-navigator placement (so the bottom nav bar isn't drawn over it).
///
/// Pass [onEdit] / [onRecalculate] only from surfaces where those actions
/// make sense. From the Edit Daily Targets sheet (which is itself the editor)
/// they should be null — the launcher hides the action row when both are
/// null so we don't render dead buttons.
void showNutritionCalculationSheet(
  BuildContext context, {
  required NutritionPreferences prefs,
  required bool isDark,
  VoidCallback? onEdit,
  VoidCallback? onRecalculate,
}) {
  String fmt(int n) {
    final abs = n.abs();
    if (abs >= 1000) {
      final prefix = n < 0 ? '-' : '';
      return '$prefix${abs ~/ 1000},${(abs % 1000).toString().padLeft(3, '0')}';
    }
    return n.toString();
  }

  String activityLabel(double m) {
    if (m <= 1.25) return 'Sedentary';
    if (m <= 1.45) return 'Lightly Active';
    if (m <= 1.65) return 'Moderately Active';
    if (m <= 1.8) return 'Very Active';
    return 'Extra Active';
  }

  showGlassSheet(
    context: context,
    builder: (ctx) => GlassSheet(
      child: _CalculationInfoSheet(
        prefs: prefs,
        isDark: isDark,
        onEdit: onEdit == null
            ? null
            : () {
                Navigator.pop(ctx);
                onEdit();
              },
        onRecalculate: onRecalculate == null
            ? null
            : () {
                Navigator.pop(ctx);
                onRecalculate();
              },
        formatNumber: fmt,
        getActivityLabel: activityLabel,
      ),
    ),
  );
}


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
    // Macro colors matching home screen hero_nutrition_card
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;
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
    final prefs = prefsState.preferences;

    // Use provider's unified targets (dynamic > prefs > defaults) — same source as profile
    final effectiveCalories = prefsState.currentCalorieTarget.toDouble();
    final effectiveProtein = prefsState.currentProteinTarget.toDouble();
    final effectiveCarbs = prefsState.currentCarbsTarget.toDouble();
    final effectiveFat = prefsState.currentFatTarget.toDouble();

    // Current consumed values
    final consumedCalories = (summary?.totalCalories ?? 0).toDouble();
    final consumedProtein = (summary?.totalProteinG ?? 0).toDouble();
    final consumedCarbs = (summary?.totalCarbsG ?? 0).toDouble();
    final consumedFat = (summary?.totalFatG ?? 0).toDouble();

    // Calories burned from Health Connect / Watch
    final activityState = ref.watch(dailyActivityProvider);
    final caloriesBurned = activityState.today?.caloriesBurned ?? 0;
    final green = isDark ? AppColors.green : AppColorsLight.green;

    final hasCaloriesBurned = caloriesBurned > 0;
    final hasGoal = nutritionGoal != null;

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: teal.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Green accent bar
          Container(width: 3, color: green),
          // Card content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: title + training badge + water + edit/refresh
          Row(
            children: [
              Icon(Icons.track_changes, color: teal, size: 16),
              const SizedBox(width: 5),
              Text(
                'Daily Goals',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              if (isTrainingDay) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: teal.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.fitness_center, size: 10, color: teal),
                ),
              ],
              // Info button — shows how targets were calculated
              if (prefs != null && prefs.calculatedBmr != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _showCalculationInfo(context, prefs, isDark),
                  child: Icon(Icons.info_outline_rounded, size: 16, color: textMuted),
                ),
              ],
              const Spacer(),
              // Water progress chip
              GestureDetector(
                onTap: onHydrationTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (hydrationPct >= 0.75 ? electricBlue : textMuted).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.water_drop, size: 12,
                        color: hydrationPct >= 0.75 ? electricBlue
                             : hydrationPct >= 0.25 ? electricBlue.withValues(alpha: 0.7)
                             : textMuted),
                      const SizedBox(width: 3),
                      Text(
                        _formatWaterAmount(currentMl, goalMl),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: hydrationPct >= 0.75 ? electricBlue : textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onEdit,
                child: Icon(Icons.edit_outlined, size: 18, color: textMuted),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRecalculate,
                child: Icon(Icons.refresh, size: 18, color: textMuted),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Macro progress rings in a row (colors match home screen tile)
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
                  color: cyan,
                  unit: 'g',
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _MacroProgressRing(
                  label: 'Fat',
                  current: consumedFat,
                  target: effectiveFat,
                  color: orange,
                  unit: 'g',
                  isDark: isDark,
                ),
              ),
            ],
          ),

          // Goal weight / target date / weekly rate / goal badge (loss/gain goals only)
          if (prefs != null && (prefs.goalWeightKg != null || prefs.goalDate != null ||
              hasGoal ||
              (prefs.rateOfChange != null &&
               (prefs.primaryGoalEnum == NutritionGoal.loseFat ||
                prefs.primaryGoalEnum == NutritionGoal.buildMuscle)))) ...[
            const SizedBox(height: 6),
            Builder(builder: (_) {
              final chips = <Widget>[
                if (hasGoal)
                  _GoalChip(
                    icon: null,
                    label: _getGoalDisplayName(nutritionGoal),
                    color: teal,
                  ),
                if (prefs!.goalWeightKg != null)
                  _GoalChip(
                    icon: Icons.my_location_outlined,
                    label: '${_formatWeight(prefs.goalWeightKg!)}kg',
                    color: teal,
                  ),
                if (prefs.goalDate != null)
                  Flexible(
                    child: _GoalChip(
                      icon: Icons.calendar_today_outlined,
                      label: _formatGoalDate(prefs.goalDate!, prefs.weeksToGoal),
                      color: teal,
                    ),
                  ),
                if (prefs.rateOfChange != null &&
                    (prefs.primaryGoalEnum == NutritionGoal.loseFat ||
                     prefs.primaryGoalEnum == NutritionGoal.buildMuscle))
                  _GoalChip(
                    icon: Icons.trending_down_outlined,
                    label: _formatWeeklyRate(prefs.rateOfChange!),
                    color: teal,
                  ),
              ];
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: chips,
              );
            }),
          ],

          // Bottom info line: calories burned
          if (hasCaloriesBurned) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => showCaloriesBurnedSheet(context, caloriesBurned),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_fire_department, size: 14, color: green),
                  const SizedBox(width: 2),
                  Text(
                    '${caloriesBurned.toInt()} burned',
                    style: TextStyle(fontSize: 11, color: green, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right, size: 14, color: green),
                ],
              ),
            ),
          ],
        ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _monthNames = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatGoalDate(DateTime date, int? weeksToGoal) {
    final monthName = _monthNames[date.month];
    final base = "$monthName '${date.year % 100}";
    if (weeksToGoal != null && weeksToGoal > 0) return '$base · ${weeksToGoal}wk';
    return base;
  }

  String _formatWeight(double weight) {
    return weight == weight.roundToDouble() && weight % 1 == 0
        ? weight.toInt().toString()
        : weight.toStringAsFixed(1);
  }

  String _formatWeeklyRate(String rateOfChange) {
    switch (rateOfChange) {
      case 'slow':
        return '0.25kg/wk';
      case 'moderate':
        return '0.5kg/wk';
      case 'fast':
        return '0.75kg/wk';
      case 'aggressive':
        return '1kg/wk';
      default:
        return rateOfChange;
    }
  }

  void _showCalculationInfo(BuildContext context, NutritionPreferences prefs, bool isDark) {
    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        child: _CalculationInfoSheet(
          prefs: prefs,
          isDark: isDark,
          onEdit: () {
            Navigator.pop(ctx);
            onEdit?.call();
          },
          onRecalculate: () {
            Navigator.pop(ctx);
            onRecalculate?.call();
          },
          formatNumber: _formatNumber,
          getActivityLabel: _getActivityLabel,
        ),
      ),
    );
  }

  String _getActivityLabel(double multiplier) {
    if (multiplier <= 1.25) return 'Sedentary';
    if (multiplier <= 1.45) return 'Lightly Active';
    if (multiplier <= 1.65) return 'Moderately Active';
    if (multiplier <= 1.8) return 'Very Active';
    return 'Extra Active';
  }

  String _formatNumber(int n) {
    final abs = n.abs();
    if (abs >= 1000) {
      final prefix = n < 0 ? '-' : '';
      return '$prefix${abs ~/ 1000},${(abs % 1000).toString().padLeft(3, '0')}';
    }
    return n.toString();
  }

  /// Format water amount — abbreviate to liters when ≥ 1000ml
  String _formatWaterAmount(int currentMl, int goalMl) {
    String fmt(int ml) {
      if (ml >= 1000) {
        final liters = ml / 1000;
        // Show one decimal if not whole, otherwise no decimal
        return liters == liters.roundToDouble()
            ? '${liters.toInt()}L'
            : '${liters.toStringAsFixed(1)}L';
      }
      return '${ml}ml';
    }
    return '${fmt(currentMl)}/${fmt(goalMl)}';
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

}

/// Compact inline macro display for header area
/// Shows: P: 45/150g | C: 120/200g | F: 30/65g
class CompactMacroTargets extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    // Use provider's unified targets (dynamic > prefs > defaults) — single source of truth
    final prefsState = ref.watch(nutritionPreferencesProvider);
    final effectiveProtein = prefsState.currentProteinTarget.toDouble();
    final effectiveCarbs = prefsState.currentCarbsTarget.toDouble();
    final effectiveFat = prefsState.currentFatTarget.toDouble();

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
              color: cyan,
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
              color: orange,
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
