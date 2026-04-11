import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../workout/widgets/share_templates/app_watermark.dart';

/// Daily nutrition summary template - Calories, macros, meal count
class NutritionDailySummaryTemplate extends StatelessWidget {
  final int totalCalories;
  final int calorieTarget;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? proteinTarget;
  final double? carbsTarget;
  final double? fatTarget;
  final int mealCount;
  final String dateLabel;
  final bool showWatermark;

  const NutritionDailySummaryTemplate({
    super.key,
    required this.totalCalories,
    required this.calorieTarget,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.proteinTarget,
    this.carbsTarget,
    this.fatTarget,
    required this.mealCount,
    required this.dateLabel,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final caloriePercent = calorieTarget > 0
        ? (totalCalories / calorieTarget).clamp(0.0, 1.5)
        : 0.0;

    return Container(
      width: 320,
      height: 440,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A1628), Color(0xFF132238), Color(0xFF0A1628)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.teal.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.orange.withValues(alpha: 0.08),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'DAILY NUTRITION',
                  style: TextStyle(
                    color: AppColors.teal,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 24),

                // Calorie ring
                Center(
                  child: SizedBox(
                    width: 140,
                    height: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 140,
                          height: 140,
                          child: CircularProgressIndicator(
                            value: caloriePercent.toDouble(),
                            strokeWidth: 10,
                            backgroundColor: Colors.white.withValues(alpha: 0.08),
                            valueColor: AlwaysStoppedAnimation(
                              caloriePercent > 1.0 ? AppColors.error : AppColors.teal,
                            ),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$totalCalories',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                            Text(
                              'of $calorieTarget kcal',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Macro bars
                _MacroBar(label: 'Protein', value: proteinG, target: proteinTarget, color: AppColors.macroProtein, unit: 'g'),
                const SizedBox(height: 10),
                _MacroBar(label: 'Carbs', value: carbsG, target: carbsTarget, color: AppColors.macroCarbs, unit: 'g'),
                const SizedBox(height: 10),
                _MacroBar(label: 'Fat', value: fatG, target: fatTarget, color: AppColors.macroFat, unit: 'g'),

                const Spacer(),

                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$mealCount meals logged',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                    if (showWatermark) const AppWatermark(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final double value;
  final double? target;
  final Color color;
  final String unit;

  const _MacroBar({
    required this.label,
    required this.value,
    this.target,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (target != null && target! > 0)
        ? (value / target!).clamp(0.0, 1.0)
        : 0.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              target != null
                  ? '${value.round()}$unit / ${target!.round()}$unit'
                  : '${value.round()}$unit',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
