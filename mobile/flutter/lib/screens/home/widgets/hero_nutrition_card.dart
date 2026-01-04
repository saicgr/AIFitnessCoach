import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/haptic_service.dart';
import '../../nutrition/log_meal_sheet.dart';

/// Hero nutrition card - prominent action-focused nutrition display
/// Shows daily calorie/macro progress with big LOG MEAL button
class HeroNutritionCard extends ConsumerStatefulWidget {
  const HeroNutritionCard({super.key});

  @override
  ConsumerState<HeroNutritionCard> createState() => _HeroNutritionCardState();
}

class _HeroNutritionCardState extends ConsumerState<HeroNutritionCard> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = await ref.read(apiClientProvider).getUserId();
    if (userId != null && mounted) {
      await ref.read(nutritionProvider.notifier).loadTodaySummary(userId);
      await ref.read(nutritionProvider.notifier).loadTargets(userId);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final nutritionState = ref.watch(nutritionProvider);
    final summary = nutritionState.todaySummary;
    final targets = nutritionState.targets;

    final caloriesConsumed = summary?.totalCalories ?? 0;
    final calorieTarget = targets?.dailyCalorieTarget ?? 2000;
    final proteinConsumed = summary?.totalProteinG ?? 0;
    final carbsConsumed = summary?.totalCarbsG ?? 0;
    final fatConsumed = summary?.totalFatG ?? 0;

    final caloriesRemaining = calorieTarget - caloriesConsumed;
    final calorieProgress = calorieTarget > 0
        ? (caloriesConsumed / calorieTarget).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF34C759).withValues(alpha: 0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF34C759).withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Today badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34C759).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'TODAY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF34C759),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Calories remaining
                  if (_isLoading) ...[
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: const Color(0xFF34C759),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 16,
                        color: textSecondary,
                      ),
                    ),
                  ] else ...[
                    Text(
                      caloriesRemaining >= 0
                          ? '$caloriesRemaining'
                          : '+${caloriesRemaining.abs()}',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: caloriesRemaining >= 0
                            ? textPrimary
                            : AppColors.error,
                      ),
                    ),
                    Text(
                      caloriesRemaining >= 0
                          ? 'calories remaining'
                          : 'calories over',
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Progress bar
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: calorieProgress,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: calorieProgress < 1.0
                                ? const Color(0xFF34C759)
                                : AppColors.error,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Consumed / Target
                    Text(
                      '$caloriesConsumed / $calorieTarget kcal',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Macros row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _MacroChip(
                          label: 'Protein',
                          value: '${proteinConsumed.round()}g',
                          color: AppColors.purple,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 12),
                        _MacroChip(
                          label: 'Carbs',
                          value: '${carbsConsumed.round()}g',
                          color: AppColors.cyan,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 12),
                        _MacroChip(
                          label: 'Fat',
                          value: '${fatConsumed.round()}g',
                          color: AppColors.orange,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Big LOG MEAL button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticService.medium();
                        showLogMealSheet(context, ref);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF34C759),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant_outlined, size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            'LOG MEAL',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Secondary action - View Details
                  TextButton.icon(
                    onPressed: () {
                      HapticService.light();
                      context.push('/nutrition');
                    },
                    icon: Icon(
                      Icons.insights_outlined,
                      size: 18,
                      color: textSecondary,
                    ),
                    label: Text(
                      'View Details',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Macro chip showing label and value
class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
