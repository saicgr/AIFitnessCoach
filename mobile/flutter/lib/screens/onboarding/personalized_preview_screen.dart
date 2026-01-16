import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import 'pre_auth_quiz_screen.dart';
import 'widgets/calorie_macro_estimator.dart';

/// Personalized preview screen that shows value before requiring sign-in
/// This demonstrates what the user will get based on their quiz answers
class PersonalizedPreviewScreen extends ConsumerStatefulWidget {
  const PersonalizedPreviewScreen({super.key});

  @override
  ConsumerState<PersonalizedPreviewScreen> createState() => _PersonalizedPreviewScreenState();
}

class _PersonalizedPreviewScreenState extends ConsumerState<PersonalizedPreviewScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Show loading animation then reveal content
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _showContent = true);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quizData = ref.watch(preAuthQuizProvider);
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0A1628), AppColors.pureBlack],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE3F2FD), Color(0xFFF5F5F5), Colors.white],
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(isDark, textSecondary),

              // Content
              Expanded(
                child: _showContent
                    ? _buildPreviewContent(isDark, quizData, textPrimary, textSecondary)
                    : _buildLoadingState(isDark, textPrimary),
              ),

              // CTA Button
              if (_showContent) _buildCTAButton(isDark),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/weight-projection'),
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: textSecondary,
              size: 20,
            ),
          ),
          const Spacer(),
          // Progress indicator - 90% complete (quiz done, projection viewed)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accent.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: AppColors.accent, size: 16),
                const SizedBox(width: 6),
                Text(
                  '90% Complete',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildLoadingState(bool isDark, Color textPrimary) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated AI icon
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_pulseController.value * 0.1),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.3 + _pulseController.value * 0.2),
                      blurRadius: 20 + _pulseController.value * 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        Text(
          'Creating your personalized plan...',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Analyzing your goals and preferences',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewContent(
    bool isDark,
    PreAuthQuizData quizData,
    Color textPrimary,
    Color textSecondary,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // "Your Plan is Ready" header
          _buildPlanReadyHeader(isDark, textPrimary)
              .animate()
              .fadeIn(delay: 100.ms)
              .slideY(begin: 0.1),

          const SizedBox(height: 24),

          // Summary Card
          _buildSummaryCard(isDark, quizData, textPrimary, textSecondary)
              .animate()
              .fadeIn(delay: 200.ms)
              .slideY(begin: 0.1),

          const SizedBox(height: 20),

          // Sample Week Preview
          _buildWeekPreview(isDark, quizData, textPrimary, textSecondary)
              .animate()
              .fadeIn(delay: 300.ms)
              .slideY(begin: 0.1),

          const SizedBox(height: 20),

          // Nutrition & Fasting Card
          if (quizData.nutritionGoals?.isNotEmpty == true ||
              quizData.fastingProtocol != null)
            _buildNutritionFastingCard(isDark, quizData, textPrimary, textSecondary)
                .animate()
                .fadeIn(delay: 350.ms)
                .slideY(begin: 0.1),

          if (quizData.nutritionGoals?.isNotEmpty == true ||
              quizData.fastingProtocol != null)
            const SizedBox(height: 20),

          // Features List
          _buildFeaturesList(isDark, textPrimary, textSecondary)
              .animate()
              .fadeIn(delay: 400.ms)
              .slideY(begin: 0.1),

          const SizedBox(height: 100), // Space for CTA button
        ],
      ),
    );
  }

  Widget _buildPlanReadyHeader(bool isDark, Color textPrimary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Success icon
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.3),
                blurRadius: 16,
                spreadRadius: 0,
              ),
            ],
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'Your Plan is Ready!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        Text(
          'Based on your answers, we\'ve designed a personalized fitness and nutrition journey just for you',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    bool isDark,
    PreAuthQuizData quizData,
    Color textPrimary,
    Color textSecondary,
  ) {
    final cardColor = isDark ? AppColors.elevated : Colors.white;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // Format goal name
    String goalDisplay = _formatGoal(quizData.goal ?? 'build_muscle');
    String levelDisplay = _formatLevel(quizData.fitnessLevel ?? 'intermediate');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Goal badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flag_outlined, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  goalDisplay,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                isDark,
                textPrimary,
                textSecondary,
                '${quizData.daysPerWeek ?? 3}',
                'days/week',
                Icons.calendar_today_outlined,
              ),
              Container(
                width: 1,
                height: 40,
                color: borderColor,
              ),
              _buildStatItem(
                isDark,
                textPrimary,
                textSecondary,
                levelDisplay,
                'level',
                Icons.trending_up,
              ),
              Container(
                width: 1,
                height: 40,
                color: borderColor,
              ),
              _buildStatItem(
                isDark,
                textPrimary,
                textSecondary,
                '${quizData.equipment?.length ?? 1}',
                'equipment',
                Icons.fitness_center,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    String value,
    String label,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: AppColors.accent, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildWeekPreview(
    bool isDark,
    PreAuthQuizData quizData,
    Color textPrimary,
    Color textSecondary,
  ) {
    final cardColor = isDark ? AppColors.elevated : Colors.white;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final daysPerWeek = quizData.daysPerWeek ?? 3;

    // Get the actual selected workout days (0=Mon, 1=Tue, ..., 6=Sun)
    final selectedDays = quizData.workoutDays ?? [];

    // Sample workout types based on goal
    final workoutTypes = _getSampleWorkouts(quizData.goal ?? 'build_muscle', daysPerWeek);

    // Create a map of day index to workout type for selected days
    final dayWorkoutMap = <int, Map<String, dynamic>>{};
    int workoutIndex = 0;
    for (final dayIndex in selectedDays) {
      if (workoutIndex < workoutTypes.length) {
        dayWorkoutMap[dayIndex] = workoutTypes[workoutIndex];
        workoutIndex++;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Your Week Preview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Week days
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
              // Check if this day is in the user's selected workout days
              final isWorkoutDay = dayWorkoutMap.containsKey(index);
              final workout = isWorkoutDay ? dayWorkoutMap[index] : null;

              return Column(
                children: [
                  Text(
                    dayNames[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isWorkoutDay
                          ? (workout?['color'] as Color).withOpacity(0.15)
                          : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                      borderRadius: BorderRadius.circular(10),
                      border: isWorkoutDay
                          ? Border.all(color: workout?['color'] as Color, width: 1.5)
                          : null,
                    ),
                    child: Icon(
                      isWorkoutDay
                          ? (workout?['icon'] as IconData)
                          : Icons.remove,
                      color: isWorkoutDay
                          ? (workout?['color'] as Color)
                          : textSecondary.withOpacity(0.3),
                      size: 18,
                    ),
                  ),
                ],
              );
            }),
          ),

          const SizedBox(height: 16),

          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: workoutTypes.toSet().map((workout) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: workout['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    workout['name'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      color: textSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getSampleWorkouts(String goal, int daysPerWeek) {
    final workouts = <Map<String, dynamic>>[];

    switch (goal) {
      case 'build_muscle':
      case 'increase_strength':
        final types = [
          {'name': 'Push', 'icon': Icons.fitness_center, 'color': AppColors.accent},
          {'name': 'Pull', 'icon': Icons.fitness_center, 'color': AppColors.electricBlue},
          {'name': 'Legs', 'icon': Icons.directions_walk, 'color': AppColors.teal},
          {'name': 'Upper', 'icon': Icons.fitness_center, 'color': AppColors.accent},
          {'name': 'Lower', 'icon': Icons.directions_walk, 'color': AppColors.teal},
          {'name': 'Full Body', 'icon': Icons.accessibility_new, 'color': AppColors.accent},
          {'name': 'Arms', 'icon': Icons.fitness_center, 'color': AppColors.accent},
        ];
        for (int i = 0; i < daysPerWeek && i < types.length; i++) {
          workouts.add(types[i]);
        }
        break;

      case 'lose_weight':
        final types = [
          {'name': 'HIIT', 'icon': Icons.flash_on, 'color': AppColors.accent},
          {'name': 'Cardio', 'icon': Icons.directions_run, 'color': AppColors.accent},
          {'name': 'Strength', 'icon': Icons.fitness_center, 'color': AppColors.accent},
          {'name': 'HIIT', 'icon': Icons.flash_on, 'color': AppColors.accent},
          {'name': 'Active Recovery', 'icon': Icons.self_improvement, 'color': AppColors.teal},
          {'name': 'Full Body', 'icon': Icons.accessibility_new, 'color': AppColors.accent},
          {'name': 'Cardio', 'icon': Icons.directions_run, 'color': AppColors.accent},
        ];
        for (int i = 0; i < daysPerWeek && i < types.length; i++) {
          workouts.add(types[i]);
        }
        break;

      case 'improve_endurance':
        final types = [
          {'name': 'Cardio', 'icon': Icons.directions_run, 'color': AppColors.accent},
          {'name': 'Intervals', 'icon': Icons.timer, 'color': AppColors.accent},
          {'name': 'Endurance', 'icon': Icons.directions_bike, 'color': AppColors.teal},
          {'name': 'Tempo', 'icon': Icons.speed, 'color': AppColors.electricBlue},
          {'name': 'Long Run', 'icon': Icons.directions_run, 'color': AppColors.accent},
          {'name': 'Recovery', 'icon': Icons.self_improvement, 'color': AppColors.success},
          {'name': 'Cross Train', 'icon': Icons.pool, 'color': AppColors.accent},
        ];
        for (int i = 0; i < daysPerWeek && i < types.length; i++) {
          workouts.add(types[i]);
        }
        break;

      default:
        final types = [
          {'name': 'Full Body', 'icon': Icons.accessibility_new, 'color': AppColors.accent},
          {'name': 'Cardio', 'icon': Icons.directions_run, 'color': AppColors.accent},
          {'name': 'Strength', 'icon': Icons.fitness_center, 'color': AppColors.electricBlue},
          {'name': 'Flexibility', 'icon': Icons.self_improvement, 'color': AppColors.teal},
          {'name': 'HIIT', 'icon': Icons.flash_on, 'color': AppColors.accent},
          {'name': 'Active', 'icon': Icons.directions_walk, 'color': AppColors.success},
          {'name': 'Core', 'icon': Icons.circle_outlined, 'color': AppColors.accent},
        ];
        for (int i = 0; i < daysPerWeek && i < types.length; i++) {
          workouts.add(types[i]);
        }
    }

    return workouts;
  }

  Widget _buildNutritionFastingCard(
    bool isDark,
    PreAuthQuizData quizData,
    Color textPrimary,
    Color textSecondary,
  ) {
    final cardColor = isDark ? AppColors.elevated : Colors.white;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final hasNutrition = quizData.nutritionGoals?.isNotEmpty == true;
    final hasFasting = quizData.fastingProtocol != null &&
                       quizData.fastingProtocol != 'none' &&
                       quizData.fastingProtocol!.isNotEmpty;

    // Calculate nutrition metrics if we have sufficient data
    final canCalculateMetrics = quizData.age != null &&
        quizData.gender != null &&
        quizData.heightCm != null &&
        quizData.weightKg != null;

    NutritionEstimate? estimate;
    if (canCalculateMetrics) {
      estimate = CalorieMacroEstimator.calculateAll(
        weightKg: quizData.weightKg!,
        heightCm: quizData.heightCm!,
        age: quizData.age!,
        gender: quizData.gender!,
        activityLevel: quizData.activityLevel,
        weightDirection: quizData.weightDirection,
        weightChangeRate: quizData.weightChangeRate,
        goalWeightKg: quizData.goalWeightKg,
        nutritionGoals: quizData.nutritionGoals,
        workoutDaysPerWeek: quizData.daysPerWeek,
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_menu, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Nutrition & Fasting',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),

          // Daily Targets (show if we can calculate)
          if (estimate != null) ...[
            const SizedBox(height: 16),
            _buildDailyTargetsSection(estimate, isDark, textPrimary, textSecondary),
          ],

          // Nutrition Goals
          if (hasNutrition) ...[
            const SizedBox(height: 16),
            _buildNutritionGoalsRow(quizData.nutritionGoals!, isDark, textPrimary, textSecondary),
          ],

          // Fasting Protocol
          if (hasFasting) ...[
            const SizedBox(height: 16),
            _buildFastingRow(quizData, isDark, textPrimary, textSecondary),
          ],
        ],
      ),
    );
  }

  Widget _buildDailyTargetsSection(
    NutritionEstimate estimate,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Targets',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 12),

        // Main macros row
        Row(
          children: [
            _buildMacroTargetItem(
              icon: Icons.local_fire_department,
              value: '${estimate.calories}',
              label: 'kcal',
              color: AppColors.accent,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            _buildMacroTargetItem(
              icon: Icons.fitness_center,
              value: '${estimate.protein}g',
              label: 'protein',
              color: AppColors.accent,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            _buildMacroTargetItem(
              icon: Icons.grain,
              value: '${estimate.carbs}g',
              label: 'carbs',
              color: AppColors.accent,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            _buildMacroTargetItem(
              icon: Icons.water_drop,
              value: '${estimate.fat}g',
              label: 'fat',
              color: AppColors.teal,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Additional insights in a more compact format
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildInsightPill(
              icon: Icons.water,
              text: '${estimate.waterLiters}L water',
              color: AppColors.electricBlue,
            ),
            _buildInsightPill(
              icon: Icons.psychology,
              text: 'Target: body of a ${estimate.metabolicAge}-year-old',
              color: AppColors.accent,
            ),
            if (estimate.weeksToGoal != null)
              _buildInsightPill(
                icon: Icons.flag_outlined,
                text: 'Goal in ~${estimate.weeksToGoal} weeks',
                color: AppColors.success,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMacroTargetItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightPill({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionGoalsRow(
    List<String> goals,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Nutrition Focus',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: goals.map((goal) {
            final goalInfo = _getNutritionGoalInfo(goal);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (goalInfo['color'] as Color).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (goalInfo['color'] as Color).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    goalInfo['icon'] as IconData,
                    size: 14,
                    color: goalInfo['color'] as Color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    goalInfo['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: goalInfo['color'] as Color,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFastingRow(
    PreAuthQuizData quizData,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final protocol = quizData.fastingProtocol!;
    final protocolInfo = _getFastingProtocolInfo(protocol);

    // Calculate eating window if we have wake/sleep times
    String? eatingWindow;
    if (quizData.wakeTime != null && quizData.sleepTime != null) {
      eatingWindow = _calculateEatingWindow(protocol, quizData.wakeTime!, quizData.sleepTime!);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.teal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.teal.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.schedule,
              color: AppColors.teal,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  protocolInfo['label'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  eatingWindow ?? (protocolInfo['description'] as String),
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.teal,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              protocol,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getNutritionGoalInfo(String goal) {
    switch (goal) {
      case 'lose_fat':
        return {
          'label': 'Lose Fat',
          'icon': Icons.local_fire_department,
          'color': AppColors.accent,
        };
      case 'build_muscle':
        return {
          'label': 'Build Muscle',
          'icon': Icons.fitness_center,
          'color': AppColors.accent,
        };
      case 'maintain':
        return {
          'label': 'Maintain Weight',
          'icon': Icons.balance,
          'color': AppColors.electricBlue,
        };
      case 'improve_energy':
        return {
          'label': 'More Energy',
          'icon': Icons.bolt,
          'color': AppColors.accent,
        };
      case 'eat_healthier':
        return {
          'label': 'Eat Healthier',
          'icon': Icons.eco,
          'color': AppColors.success,
        };
      default:
        return {
          'label': goal.replaceAll('_', ' ').split(' ').map((w) =>
            w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w
          ).join(' '),
          'icon': Icons.restaurant,
          'color': AppColors.teal,
        };
    }
  }

  Map<String, dynamic> _getFastingProtocolInfo(String protocol) {
    switch (protocol) {
      case '16:8':
        return {
          'label': 'Intermittent Fasting',
          'description': '16 hours fasting, 8 hour eating window',
        };
      case '18:6':
        return {
          'label': 'Extended Fasting',
          'description': '18 hours fasting, 6 hour eating window',
        };
      case '14:10':
        return {
          'label': 'Gentle Fasting',
          'description': '14 hours fasting, 10 hour eating window',
        };
      case '20:4':
        return {
          'label': 'Warrior Diet',
          'description': '20 hours fasting, 4 hour eating window',
        };
      default:
        return {
          'label': 'Intermittent Fasting',
          'description': 'Custom fasting schedule',
        };
    }
  }

  String? _calculateEatingWindow(String protocol, String wakeTime, String sleepTime) {
    try {
      // Parse times
      final wakeParts = wakeTime.split(':');
      final wakeHour = int.parse(wakeParts[0]);
      final wakeMinute = int.parse(wakeParts[1]);

      // Get eating window hours from protocol (e.g., "16:8" -> 8 hours)
      final protocolParts = protocol.split(':');
      if (protocolParts.length != 2) return null;
      final eatingHours = int.parse(protocolParts[1]);

      // Start eating 1 hour after waking
      final startHour = (wakeHour + 1) % 24;
      final endHour = (startHour + eatingHours) % 24;

      // Format times
      String formatTime(int hour, int minute) {
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
      }

      return 'Eat ${formatTime(startHour, wakeMinute)} - ${formatTime(endHour, wakeMinute)}';
    } catch (e) {
      return null;
    }
  }

  Widget _buildFeaturesList(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final features = [
      {
        'icon': Icons.auto_awesome,
        'title': 'AI-Powered Coaching',
        'description': 'Personalized workouts that adapt to your progress',
        'color': AppColors.accent,
      },
      {
        'icon': Icons.play_circle_outline,
        'title': '1,700+ Exercise Videos',
        'description': 'HD demos for perfect form every time',
        'color': AppColors.accent,
      },
      {
        'icon': Icons.trending_up,
        'title': 'Smart Progression',
        'description': 'Automatic adjustments as you get stronger',
        'color': AppColors.success,
      },
      {
        'icon': Icons.restaurant_menu,
        'title': 'Nutrition Guidance',
        'description': 'Meal suggestions aligned with your goals',
        'color': AppColors.accent,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "What's Included",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),

        const SizedBox(height: 12),

        ...features.asMap().entries.map((entry) {
          final index = entry.key;
          final feature = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (feature['color'] as Color).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    color: feature['color'] as Color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature['title'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        feature['description'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 20,
                ),
              ],
            ),
          ).animate(delay: (index * 80).ms).fadeIn().slideX(begin: 0.05);
        }),
      ],
    );
  }

  Widget _buildCTAButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Main CTA
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                context.go('/sign-in');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: AppColors.accent.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Save My Plan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Subtext with FREE badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'FREE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'No credit card required',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1);
  }

  String _formatGoal(String goal) {
    switch (goal) {
      case 'build_muscle':
        return 'Build Muscle';
      case 'lose_weight':
        return 'Lose Weight';
      case 'increase_strength':
        return 'Get Stronger';
      case 'improve_endurance':
        return 'Build Endurance';
      case 'stay_active':
        return 'Stay Active';
      case 'athletic_performance':
        return 'Athletic Performance';
      default:
        return 'Fitness Journey';
    }
  }

  String _formatLevel(String level) {
    switch (level) {
      case 'beginner':
        return 'Beginner';
      case 'intermediate':
        return 'Intermediate';
      case 'advanced':
        return 'Advanced';
      default:
        return 'Intermediate';
    }
  }
}
