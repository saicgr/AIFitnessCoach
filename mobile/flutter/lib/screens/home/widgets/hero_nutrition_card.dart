import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../data/repositories/auth_repository.dart';
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
    final apiClient = ref.read(apiClientProvider);
    final userId = await apiClient.getUserId();
    if (userId != null && mounted) {
      await ref.read(nutritionProvider.notifier).loadTodaySummary(userId);
      await ref.read(nutritionProvider.notifier).loadTargets(userId);

      // Check if targets are null - if so, try to calculate them from user profile
      final nutritionState = ref.read(nutritionProvider);
      if (nutritionState.targets?.dailyCalorieTarget == null) {
        await _calculateTargetsFromProfile(userId, apiClient);
        // Reload targets after calculation
        await ref.read(nutritionProvider.notifier).loadTargets(userId);
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Calculate nutrition targets from user profile if not already set
  Future<void> _calculateTargetsFromProfile(String userId, ApiClient apiClient) async {
    try {
      final authState = ref.read(authStateProvider);
      final user = authState.user;
      if (user == null) return;

      // Only calculate if we have the required data
      if (user.weightKg == null || user.heightCm == null ||
          user.age == null || user.gender == null) {
        debugPrint('⚠️ [HeroNutritionCard] Missing user profile data for nutrition calculation');
        return;
      }

      // Determine weight direction based on target vs current weight
      String weightDirection = 'maintain';
      if (user.targetWeightKg != null && user.weightKg != null) {
        final diff = user.targetWeightKg! - user.weightKg!;
        if (diff < -2) {
          weightDirection = 'lose';
        } else if (diff > 2) {
          weightDirection = 'gain';
        }
      }

      // Map fitness goals to nutrition goals
      final nutritionGoals = user.goalsList.map((goal) {
        switch (goal) {
          case 'lose_weight':
          case 'lose_fat':
            return 'lose_fat';
          case 'build_muscle':
          case 'gain_muscle':
            return 'build_muscle';
          default:
            return 'maintain';
        }
      }).toList();

      debugPrint('🔄 [HeroNutritionCard] Calculating nutrition targets for existing user...');
      await apiClient.post(
        '${ApiConstants.users}/$userId/calculate-nutrition-targets',
        data: {
          'weight_kg': user.weightKg,
          'height_cm': user.heightCm,
          'age': user.age,
          'gender': user.gender,
          'activity_level': user.activityLevel ?? 'lightly_active',
          'weight_direction': weightDirection,
          'weight_change_rate': 'moderate',
          'goal_weight_kg': user.targetWeightKg,
          'nutrition_goals': nutritionGoals.isNotEmpty ? nutritionGoals : ['maintain'],
          'workout_days_per_week': user.workoutsPerWeek ?? 3,
        },
      );
      debugPrint('✅ [HeroNutritionCard] Nutrition targets calculated and saved');
    } catch (e) {
      debugPrint('❌ [HeroNutritionCard] Failed to calculate nutrition targets: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;

    // Debug logging
    debugPrint('🥗 [HeroNutritionCard] build() - isDark: $isDark, isLoading: $_isLoading');
    debugPrint('🥗 [HeroNutritionCard] textPrimary: $textPrimary, textSecondary: $textSecondary');
    debugPrint('🥗 [HeroNutritionCard] cardBg: $cardBg');

    final nutritionState = ref.watch(nutritionProvider);
    final summary = nutritionState.todaySummary;
    final targets = nutritionState.targets;

    debugPrint('🥗 [HeroNutritionCard] summary: $summary, targets: $targets');

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
            color: AppColors.textPrimary.withValues(alpha: 0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Today badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'TODAY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Calories remaining
                  if (_isLoading) ...[
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textPrimary,
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
                        fontSize: 42,
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
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Progress bar
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: calorieProgress,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: calorieProgress < 1.0
                                ? AppColors.textPrimary
                                : AppColors.error,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Consumed / Target
                    Text(
                      '$caloriesConsumed / $calorieTarget kcal',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),

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
                  const SizedBox(height: 16),

                  // Big LOG MEAL button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticService.medium();
                        showLogMealSheet(context, ref);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant_outlined, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'LOG MEAL',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Secondary action - View Details
                  TextButton.icon(
                    onPressed: () {
                      HapticService.light();
                      context.push('/nutrition');
                    },
                    icon: Icon(
                      Icons.insights_outlined,
                      size: 16,
                      color: textSecondary,
                    ),
                    label: Text(
                      'View Details',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
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
