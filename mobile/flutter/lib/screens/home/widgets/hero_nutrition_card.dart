import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/haptic_service.dart';
import '../../../data/providers/nutrition_preferences_provider.dart';
import '../../../data/repositories/nutrition_preferences_repository.dart';
import '../../../data/repositories/hydration_repository.dart';
import '../../nutrition/log_meal_sheet.dart';

/// Hero nutrition card with Apple Watch-style concentric macro rings.
/// Outer = Protein, Middle = Carbs, Inner = Fat.
/// Center shows calorie remaining count.
class HeroNutritionCard extends ConsumerStatefulWidget {
  const HeroNutritionCard({super.key});

  @override
  ConsumerState<HeroNutritionCard> createState() => _HeroNutritionCardState();
}

class _HeroNutritionCardState extends ConsumerState<HeroNutritionCard>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late AnimationController _animController;
  late Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _ringAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final apiClient = ref.read(apiClientProvider);
    final userId = await apiClient.getUserId();
    if (userId != null && mounted) {
      await ref.read(nutritionProvider.notifier).loadTodaySummary(userId);
      await ref.read(nutritionProvider.notifier).loadTargets(userId);

      // Load hydration data
      ref.read(hydrationProvider.notifier).loadTodaySummary(userId);

      // Load dynamic targets (training/rest day adjustments)
      ref.read(nutritionPreferencesProvider.notifier).initialize(userId);

      // Check if targets are null - if so, try to calculate them from user profile
      final nutritionState = ref.read(nutritionProvider);
      if (nutritionState.targets?.dailyCalorieTarget == null) {
        await _calculateTargetsFromProfile(userId, apiClient);
        await ref.read(nutritionProvider.notifier).loadTargets(userId);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        _animController.forward();
      }
    }
  }

  String _adjustmentLabel(DynamicNutritionTargets dt) {
    switch (dt.adjustmentReason) {
      case 'training_day':
        return 'Training day (+${dt.calorieAdjustment} kcal)';
      case 'rest_day':
        return 'Rest day (${dt.calorieAdjustment} kcal)';
      case 'fasting_day':
        return 'Fasting day';
      default:
        return '';
    }
  }

  Future<void> _calculateTargetsFromProfile(String userId, ApiClient apiClient) async {
    try {
      final authState = ref.read(authStateProvider);
      final user = authState.user;
      if (user == null) return;

      if (user.weightKg == null || user.heightCm == null ||
          user.age == null || user.gender == null) {
        return;
      }

      String weightDirection = 'maintain';
      if (user.targetWeightKg != null && user.weightKg != null) {
        final diff = user.targetWeightKg! - user.weightKg!;
        if (diff < -2) {
          weightDirection = 'lose';
        } else if (diff > 2) {
          weightDirection = 'gain';
        }
      }

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

    final nutritionState = ref.watch(nutritionProvider);
    final summary = nutritionState.todaySummary;
    final targets = nutritionState.targets;
    final prefsState = ref.watch(nutritionPreferencesProvider);
    final dynamicTargets = prefsState.dynamicTargets;
    final hydrationState = ref.watch(hydrationProvider);
    final waterConsumedMl = hydrationState.todaySummary?.totalMl ?? 0;
    final waterGoalMl = hydrationState.todaySummary?.goalMl ?? hydrationState.dailyGoalMl;

    final caloriesConsumed = summary?.totalCalories ?? 0;
    final calorieTarget = dynamicTargets?.targetCalories ?? targets?.dailyCalorieTarget ?? 2000;
    final proteinConsumed = (summary?.totalProteinG ?? 0).round();
    final carbsConsumed = (summary?.totalCarbsG ?? 0).round();
    final fatConsumed = (summary?.totalFatG ?? 0).round();

    final proteinTarget = prefsState.currentProteinTarget;
    final carbsTarget = prefsState.currentCarbsTarget;
    final fatTarget = prefsState.currentFatTarget;

    final caloriesRemaining = calorieTarget - caloriesConsumed;

    // Centralized macro colors
    final proteinColor = isDark ? AppColors.macroProtein : AppColorsLight.macroProtein;
    final carbsRingColor = isDark ? AppColors.macroCarbs : AppColorsLight.macroCarbs;
    final fatColor = isDark ? AppColors.macroFat : AppColorsLight.macroFat;
    final buttonBg = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final buttonFg = isDark ? Colors.black : Colors.white;

    // Progress values (clamped to 0..1 for ring drawing, but allow >1 for overshoot glow)
    final proteinProgress = proteinTarget > 0
        ? (proteinConsumed / proteinTarget).clamp(0.0, 1.5)
        : 0.0;
    final carbsProgress = carbsTarget > 0
        ? (carbsConsumed / carbsTarget).clamp(0.0, 1.5)
        : 0.0;
    final fatProgress = fatTarget > 0
        ? (fatConsumed / fatTarget).clamp(0.0, 1.5)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : Colors.black).withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Column(
            children: [
              // Compact calorie header row
              if (!_isLoading) ...[
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      size: 16,
                      color: fatColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$caloriesConsumed / $calorieTarget kcal',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (caloriesConsumed > calorieTarget
                                ? AppColors.error
                                : (isDark ? AppColors.teal : AppColorsLight.teal))
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${calorieTarget > 0 ? ((caloriesConsumed / calorieTarget) * 100).round() : 0}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: caloriesConsumed > calorieTarget
                              ? AppColors.error
                              : (isDark ? AppColors.teal : AppColorsLight.teal),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Water consumed / goal row
                Row(
                  children: [
                    Icon(
                      Icons.water_drop_outlined,
                      size: 16,
                      color: const Color(0xFF38BDF8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${(waterConsumedMl / 1000).toStringAsFixed(1)} / ${(waterGoalMl / 1000).toStringAsFixed(1)} L',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${waterGoalMl > 0 ? ((waterConsumedMl / waterGoalMl) * 100).round() : 0}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF38BDF8),
                        ),
                      ),
                    ),
                  ],
                ),
                // Training/rest day adjustment badge
                if (dynamicTargets != null &&
                    dynamicTargets.adjustmentReason != 'base_targets') ...[
                  const SizedBox(height: 4),
                  Builder(builder: (context) {
                    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: teal.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline, size: 11, color: teal),
                            const SizedBox(width: 4),
                            Text(
                              _adjustmentLabel(dynamicTargets),
                              style: TextStyle(fontSize: 10, color: teal, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],

              // Centered rings (hero element)
              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _ringAnimation,
                      builder: (context, _) {
                        return SizedBox(
                          height: 175,
                          width: 175,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(175, 175),
                                painter: _MacroRingsPainter(
                                  proteinProgress: proteinProgress * _ringAnimation.value,
                                  carbsProgress: carbsProgress * _ringAnimation.value,
                                  fatProgress: fatProgress * _ringAnimation.value,
                                  proteinColor: proteinColor,
                                  carbsColor: carbsRingColor,
                                  fatColor: fatColor,
                                  trackColor: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.black.withValues(alpha: 0.08),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    caloriesRemaining >= 0
                                        ? '$caloriesRemaining'
                                        : '+${caloriesRemaining.abs()}',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: caloriesRemaining >= 0
                                          ? textPrimary
                                          : AppColors.error,
                                      height: 1.1,
                                    ),
                                  ),
                                  Text(
                                    caloriesRemaining >= 0 ? 'cal left' : 'cal over',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // Horizontal macro progress bars
              if (!_isLoading) ...[
                _MacroProgressBar(
                  label: 'Protein',
                  consumed: proteinConsumed,
                  target: proteinTarget,
                  color: proteinColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 4),
                _MacroProgressBar(
                  label: 'Carbs',
                  consumed: carbsConsumed,
                  target: carbsTarget,
                  color: carbsRingColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 4),
                _MacroProgressBar(
                  label: 'Fat',
                  consumed: fatConsumed,
                  target: fatTarget,
                  color: fatColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
              ],

              // LOG MEAL button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    HapticService.medium();
                    showLogMealSheet(context, ref);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonBg,
                    foregroundColor: buttonFg,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_outlined, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Log Meal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // View Details
              GestureDetector(
                onTap: () {
                  HapticService.light();
                  context.go('/nutrition');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.insights_outlined, size: 13, color: textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'View Details',
                        style: TextStyle(color: textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal macro progress bar: dot + label + fill bar + consumed/target
class _MacroProgressBar extends StatelessWidget {
  final String label;
  final int consumed;
  final int target;
  final Color color;
  final bool isDark;

  const _MacroProgressBar({
    required this.label,
    required this.consumed,
    required this.target,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;

    return SizedBox(
      height: 24,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${consumed}g / ${target}g',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for Apple Watch-style concentric macro rings.
/// Draws three rings (outer→inner): Protein, Carbs, Fat.
/// Each ring has a muted track behind it and a colored arc for progress.
/// Arcs have rounded StrokeCap and start from 12 o'clock (-π/2).
class _MacroRingsPainter extends CustomPainter {
  final double proteinProgress;
  final double carbsProgress;
  final double fatProgress;
  final Color proteinColor;
  final Color carbsColor;
  final Color fatColor;
  final Color trackColor;

  _MacroRingsPainter({
    required this.proteinProgress,
    required this.carbsProgress,
    required this.fatProgress,
    required this.proteinColor,
    required this.carbsColor,
    required this.fatColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 18.0;
    const ringGap = 2.0;
    const startAngle = -math.pi / 2; // 12 o'clock

    // Outer ring (Protein): largest radius
    final outerRadius = (size.width / 2) - strokeWidth / 2;
    _drawRing(canvas, center, outerRadius, strokeWidth,
        proteinProgress, proteinColor, startAngle);

    // Middle ring (Carbs)
    final middleRadius = outerRadius - strokeWidth - ringGap;
    _drawRing(canvas, center, middleRadius, strokeWidth,
        carbsProgress, carbsColor, startAngle);

    // Inner ring (Fat)
    final innerRadius = middleRadius - strokeWidth - ringGap;
    _drawRing(canvas, center, innerRadius, strokeWidth,
        fatProgress, fatColor, startAngle);
  }

  void _drawRing(Canvas canvas, Offset center, double radius,
      double strokeWidth, double progress, Color color, double startAngle) {
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track (background ring)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Always show at least a small arc so rings are never invisible
    final effectiveProgress = progress <= 0 ? 0.02 : progress;

    // Clamp to full circle for the main arc
    final clampedProgress = effectiveProgress.clamp(0.0, 1.0);
    final sweepAngle = 2 * math.pi * clampedProgress;

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);

    // If over 100%, draw the overshoot portion with a brighter/lighter color
    // wrapping around again from the start
    if (progress > 1.0) {
      final overshoot = (progress - 1.0).clamp(0.0, 0.5);
      final overshootSweep = 2 * math.pi * overshoot;
      final overshootPaint = Paint()
        ..color = Color.lerp(color, Colors.white, 0.35)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, overshootSweep, false, overshootPaint);
    }
  }

  @override
  bool shouldRepaint(_MacroRingsPainter oldDelegate) {
    return proteinProgress != oldDelegate.proteinProgress ||
        carbsProgress != oldDelegate.carbsProgress ||
        fatProgress != oldDelegate.fatProgress;
  }
}

