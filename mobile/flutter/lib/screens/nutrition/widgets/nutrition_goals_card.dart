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
      child: Row(
        children: [
          // Green accent bar
          Container(width: 4, color: green),
          // Card content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: title + training badge + water + edit/refresh
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

          const SizedBox(height: 10),

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
            const SizedBox(height: 8),
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
            const SizedBox(height: 8),
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

/// Stateful sheet that shows the full calculation breakdown with expandable BMR details
class _CalculationInfoSheet extends ConsumerStatefulWidget {
  final NutritionPreferences prefs;
  final bool isDark;
  final VoidCallback? onEdit;
  final VoidCallback? onRecalculate;
  final String Function(int) formatNumber;
  final String Function(double) getActivityLabel;

  const _CalculationInfoSheet({
    required this.prefs,
    required this.isDark,
    this.onEdit,
    this.onRecalculate,
    required this.formatNumber,
    required this.getActivityLabel,
  });

  @override
  ConsumerState<_CalculationInfoSheet> createState() => _CalculationInfoSheetState();
}

class _CalculationInfoSheetState extends ConsumerState<_CalculationInfoSheet> {
  bool _bmrExpanded = false;

  @override
  Widget build(BuildContext context) {
    final prefs = widget.prefs;
    final isDark = widget.isDark;
    final fmt = widget.formatNumber;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final bmr = prefs.calculatedBmr ?? 0;
    final tdee = prefs.calculatedTdee ?? 0;
    // Use dynamic target (same source as the Daily Goals card) for consistency
    final prefsState = ref.watch(nutritionPreferencesProvider);
    final targetCal = prefsState.currentCalorieTarget;
    final goalAdjustment = targetCal - tdee;
    final goal = prefs.primaryGoalEnum;
    final dietType = prefs.dietTypeEnum;
    final rate = prefs.rateOfChange;

    final activityMultiplier = bmr > 0 ? (tdee / bmr) : 1.2;
    final activityLabel = widget.getActivityLabel(activityMultiplier);

    final carbPct = dietType.carbPercent;
    final proteinPct = dietType.proteinPercent;
    final fatPct = dietType.fatPercent;

    // Get user profile for BMR breakdown
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How your targets are calculated',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // BMR — tappable to expand formula breakdown
          GestureDetector(
            onTap: () => setState(() => _bmrExpanded = !_bmrExpanded),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'BMR (Basal Metabolic Rate)',
                    style: TextStyle(
                      fontSize: 13,
                      color: textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${fmt(bmr)} cal',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _bmrExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.chevron_right, size: 18, color: teal),
                ),
              ],
            ),
          ),

          // Expandable BMR calculation breakdown
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.only(left: 12, top: 4, bottom: 12),
              child: Text(
                'Mifflin-St Jeor formula · tap to see details',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
            ),
            secondChild: _buildBmrBreakdown(user, bmr, isDark, textPrimary, textMuted, teal, cardBorder),
            crossFadeState: _bmrExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),

          // Activity multiplier
          _CalcRow(
            label: 'Activity Multiplier (×${activityMultiplier.toStringAsFixed(2)})',
            value: activityLabel,
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          // TDEE
          _CalcRow(
            label: 'TDEE (Daily Energy Needs)',
            value: '${fmt(tdee)} cal',
            isDark: isDark,
            isBold: true,
          ),
          const SizedBox(height: 12),

          Divider(color: cardBorder, height: 1),
          const SizedBox(height: 12),

          // Goal adjustment
          _CalcRow(
            label: 'Goal Adjustment',
            value: '${goalAdjustment >= 0 ? '+' : ''}${fmt(goalAdjustment)} cal',
            isDark: isDark,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 12),
            child: Text(
              '${goal.displayName}${rate != null ? ' (${RateOfChange.fromString(rate).displayName.toLowerCase()})' : ''}',
              style: TextStyle(fontSize: 11, color: textMuted),
            ),
          ),

          // Final target
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: teal.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Calorie Target',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                Text(
                  '${fmt(targetCal)} cal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: teal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Macro split
          Divider(color: cardBorder, height: 1),
          const SizedBox(height: 12),
          Text(
            'Macro Split (${dietType.displayName}: $carbPct/$proteinPct/$fatPct)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _MacroChip(
                label: 'Protein',
                grams: prefs.targetProteinG ?? 0,
                pct: proteinPct,
                color: isDark ? AppColors.purple : AppColorsLight.purple,
              ),
              const SizedBox(width: 8),
              _MacroChip(
                label: 'Carbs',
                grams: prefs.targetCarbsG ?? 0,
                pct: carbPct,
                color: isDark ? AppColors.cyan : AppColorsLight.cyan,
              ),
              const SizedBox(width: 8),
              _MacroChip(
                label: 'Fat',
                grams: prefs.targetFatG ?? 0,
                pct: fatPct,
                color: isDark ? AppColors.orange : AppColorsLight.orange,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Edit + Recalculate buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: widget.onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit Targets'),
                  style: FilledButton.styleFrom(
                    backgroundColor: teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onRecalculate,
                  icon: Icon(Icons.refresh, size: 18, color: teal),
                  label: Text('Recalculate', style: TextStyle(inherit: false, color: teal, fontSize: 14, fontWeight: FontWeight.w500)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: teal.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBmrBreakdown(
    dynamic user,
    int bmr,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color teal,
    Color cardBorder,
  ) {
    final weight = user?.weightKg;
    final height = user?.heightCm;
    final age = user?.age;
    final gender = user?.gender?.toString().toLowerCase() ?? 'male';
    final isMale = gender == 'male';

    if (weight == null || height == null || age == null) {
      return Padding(
        padding: const EdgeInsets.only(left: 12, top: 4, bottom: 12),
        child: Text(
          'Mifflin-St Jeor formula (profile data unavailable for breakdown)',
          style: TextStyle(fontSize: 11, color: textMuted),
        ),
      );
    }

    // Mifflin-St Jeor: (10 × weight) + (6.25 × height) - (5 × age) + offset
    final weightTerm = 10.0 * weight;
    final heightTerm = 6.25 * height;
    final ageTerm = (5 * age).toDouble();
    final offset = isMale ? 5 : -161;

    return Container(
      margin: const EdgeInsets.only(left: 8, top: 6, bottom: 12, right: 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: teal.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mifflin-St Jeor Equation${isMale ? ' (Male)' : ' (Female)'}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: teal,
            ),
          ),
          const SizedBox(height: 8),
          _BmrFormulaRow(label: '10 × ${weight.toStringAsFixed(1)} kg', value: weightTerm, isDark: isDark, hint: 'more mass = more energy at rest'),
          _BmrFormulaRow(label: '6.25 × ${height.toStringAsFixed(1)} cm', value: heightTerm, isDark: isDark, prefix: '+', hint: 'taller = larger surface area'),
          _BmrFormulaRow(label: '5 × $age yrs', value: ageTerm.toDouble(), isDark: isDark, prefix: '−', hint: 'metabolism slows with age'),
          _BmrFormulaRow(label: isMale ? 'Male constant' : 'Female constant', value: offset.toDouble(), isDark: isDark, prefix: offset >= 0 ? '+' : '−', showAbs: true, hint: isMale ? 'males have more lean mass' : 'females have different body composition'),
          const SizedBox(height: 4),
          Divider(color: cardBorder, height: 1),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BMR',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
              ),
              Text(
                '= $bmr cal',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: teal),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A single row in the BMR formula breakdown
class _BmrFormulaRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isDark;
  final String prefix;
  final bool showAbs;
  final String? hint;

  const _BmrFormulaRow({
    required this.label,
    required this.value,
    required this.isDark,
    this.prefix = '',
    this.showAbs = false,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final displayValue = showAbs ? value.abs() : value;
    return Padding(
      padding: EdgeInsets.only(top: 2, bottom: hint != null ? 6 : 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 16,
                child: prefix.isNotEmpty
                    ? Text(prefix, style: TextStyle(fontSize: 11, color: textMuted))
                    : null,
              ),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11, color: textMuted),
                ),
              ),
              Text(
                '= ${displayValue.toStringAsFixed(1)}',
                style: TextStyle(fontSize: 11, color: textPrimary),
              ),
            ],
          ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 1),
              child: Text(
                hint!,
                style: TextStyle(fontSize: 9.5, color: textMuted.withValues(alpha: 0.6), fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
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

    return Column(
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Background ring - tinted with macro color
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 5,
                  backgroundColor: color.withValues(alpha: 0.25),
                  color: color.withValues(alpha: 0.25),
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
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  if (showKcal)
                    Text(
                      'kcal',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
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
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        Text(
          '/${target.toInt()}$unit',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: textPrimary.withValues(alpha: 0.5),
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }
}

/// Small pill chip for displaying goal metadata (weight, date, rate)
class _GoalChip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color;

  const _GoalChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final muted = color.withValues(alpha: 0.55);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 11, color: muted),
          const SizedBox(width: 3),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w400,
            color: muted,
          ),
        ),
      ],
    );
  }
}

/// Row in the calculation info bottom sheet
class _CalcRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool isBold;

  const _CalcRow({
    required this.label,
    required this.value,
    required this.isDark,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                color: isBold ? textPrimary : textMuted,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Macro chip in the calculation info bottom sheet
class _MacroChip extends StatelessWidget {
  final String label;
  final int grams;
  final int pct;
  final Color color;

  const _MacroChip({
    required this.label,
    required this.grams,
    required this.pct,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              '${grams}g',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              '$pct%',
              style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
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
