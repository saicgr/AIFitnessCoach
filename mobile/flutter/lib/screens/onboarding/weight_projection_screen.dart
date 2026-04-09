import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/window_mode_provider.dart';
import '../../core/services/posthog_service.dart';
import '../../widgets/glass_back_button.dart';
import 'pre_auth_quiz_screen.dart';
import 'widgets/calorie_macro_estimator.dart';
import 'widgets/foldable_quiz_scaffold.dart';
import 'widgets/quiz_weight_rate.dart';

part 'weight_projection_screen_part_weight_data_point.dart';

part 'weight_projection_screen_ui.dart';


/// Weight projection screen showing when user will reach their goal
class WeightProjectionScreen extends ConsumerStatefulWidget {
  const WeightProjectionScreen({super.key});

  @override
  ConsumerState<WeightProjectionScreen> createState() =>
      _WeightProjectionScreenState();
}

class _WeightProjectionScreenState
    extends ConsumerState<WeightProjectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _lineAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _lineAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // Start animation after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildWeightSummary(
    bool isDark, Color textPrimary, Color textSecondary, {
    required double currentWeight,
    required double goalWeight,
    required bool useMetric,
    required bool isLosingWeight,
    required int workoutDays,
    double? weeklyRateKg,
  }) {
    final unit = useMetric ? 'kg' : 'lbs';
    final displayCurrent = useMetric ? currentWeight : currentWeight * 2.205;
    final displayGoal = useMetric ? goalWeight : goalWeight * 2.205;
    final diff = (displayCurrent - displayGoal).abs();
    final displayWeeklyRate = weeklyRateKg != null
        ? (useMetric ? weeklyRateKg : weeklyRateKg * 2.205)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Weight stats row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                label: 'Current',
                value: '${displayCurrent.round()} $unit',
                icon: Icons.monitor_weight_outlined,
                color: textSecondary,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                label: 'Goal',
                value: '${displayGoal.round()} $unit',
                icon: Icons.flag_outlined,
                color: AppColors.green,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                label: isLosingWeight ? 'To lose' : 'To gain',
                value: '${diff.round()} $unit',
                icon: isLosingWeight ? Icons.trending_down : Icons.trending_up,
                color: AppColors.orange,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                label: 'Per week',
                value: displayWeeklyRate != null
                    ? '${displayWeeklyRate.toStringAsFixed(1)} $unit'
                    : '$workoutDays days/wk',
                icon: Icons.speed_rounded,
                color: isDark ? AppColors.cyan : AppColorsLight.cyan,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Tip
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.green.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.eco_rounded, size: 16, color: AppColors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isLosingWeight
                      ? 'Safe rate: 0.5–1 kg/week. Your plan follows evidence-based guidelines.'
                      : 'Lean gain: 0.25–0.5 kg/week. Slow and steady builds quality muscle.',
                  style: TextStyle(
                    fontSize: 11,
                    color: textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final background = isDark ? AppColors.background : AppColorsLight.background;

    final quizData = ref.watch(preAuthQuizProvider);

    // Default values if not set
    final currentWeight = quizData.weightKg ?? 80.0;
    final goalWeight = quizData.goalWeightKg ?? 70.0;
    final workoutDays = quizData.daysPerWeek ?? 4;
    final useMetric = quizData.useMetricUnits;
    final weightDirection = quizData.weightDirection;
    final weightChangeRate = quizData.weightChangeRate;

    // Check if user selected "maintain" - show alternate view
    final isMaintaining = weightDirection == 'maintain' ||
        (currentWeight - goalWeight).abs() < 0.5;  // Also handle near-zero difference

    if (isMaintaining) {
      return _buildMaintainScreen(
        isDark,
        textPrimary,
        textSecondary,
        background,
        currentWeight,
        useMetric,
      );
    }

    // Calculate TDEE for calorie labels on rate chips
    final userAge = quizData.age ?? 25;
    final userGender = quizData.gender ?? 'male';
    final bmr = CalorieMacroEstimator.calculateBMR(
      weightKg: currentWeight,
      heightCm: quizData.heightCm ?? 170,
      age: userAge,
      gender: userGender,
    );
    final tdee = CalorieMacroEstimator.calculateTDEE(bmr, quizData.activityLevel);

    final weeklyRate = WeightProjectionCalculator.calculateWeeklyRate(
      currentWeight: currentWeight,
      goalWeight: goalWeight,
      workoutDaysPerWeek: workoutDays,
      weightChangeRate: weightChangeRate,
    );

    final goalDate = WeightProjectionCalculator.calculateGoalDate(
      currentWeight: currentWeight,
      goalWeight: goalWeight,
      workoutDaysPerWeek: workoutDays,
      weightChangeRate: weightChangeRate,
    );

    final projectionData = WeightProjectionCalculator.generateProjectionCurve(
      currentWeight: currentWeight,
      goalWeight: goalWeight,
      goalDate: goalDate,
    );

    final formattedGoalDate = DateFormat('MMM, yyyy').format(goalDate);
    final isLosingWeight = goalWeight < currentWeight;

    final backButton = Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GlassBackButton(
          onTap: () {
            HapticFeedback.lightImpact();
            context.go('/personal-info');
          },
        ),
      ),
    );

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: FoldableQuizScaffold(
          headerTitle: "At this rate you'll reach your goal by $formattedGoalDate",
          headerSubtitle: isLosingWeight
              ? 'Your personalized plan is ready to help you reach your goal weight safely.'
              : 'Your personalized plan is designed to help you build muscle.',
          headerExtra: _buildWeightSummary(
            isDark, textPrimary, textSecondary,
            currentWeight: currentWeight,
            goalWeight: goalWeight,
            useMetric: useMetric,
            isLosingWeight: isLosingWeight,
            workoutDays: workoutDays,
            weeklyRateKg: weeklyRate,
          ),
          headerOverlay: backButton,
          content: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show title inline only on phone
                Consumer(builder: (context, ref, _) {
                  final windowState = ref.watch(windowModeProvider);
                  if (FoldableQuizScaffold.shouldUseFoldableLayout(windowState)) {
                    return const SizedBox.shrink();
                  }
                  return RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                        height: 1.3,
                      ),
                      children: [
                        const TextSpan(text: "At this rate you'll reach your goal by "),
                        TextSpan(
                          text: formattedGoalDate,
                          style: const TextStyle(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.1);
                }),

                const SizedBox(height: 16),

                // Rate selection chips
                Text(
                  isLosingWeight
                      ? 'How fast do you want to lose it?'
                      : 'How fast do you want to gain?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ).animate().fadeIn(delay: 250.ms),
                const SizedBox(height: 8),
                QuizWeightRateChips(
                  selectedRate: weightChangeRate ?? 'moderate',
                  rates: getWeightRateOptions(isLosing: isLosingWeight, useMetric: useMetric, tdee: tdee, gender: userGender),
                  onRateChanged: (rate) {
                    final notifier = ref.read(preAuthQuizProvider.notifier);
                    notifier.setBodyMetrics(
                      heightCm: quizData.heightCm ?? 170,
                      weightKg: currentWeight,
                      goalWeightKg: goalWeight,
                      useMetric: useMetric,
                      weightDirection: weightDirection,
                      weightChangeRate: rate,
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Chart — flexible to fill available space
                Flexible(
                  child: _buildChart(
                    projectionData,
                    currentWeight,
                    goalWeight,
                    useMetric,
                    isDark,
                    textPrimary,
                    textSecondary,
                    isLosingWeight,
                  ),
                ),

                const SizedBox(height: 16),

                // Weight summary stats (phone only — foldable shows in header)
                Consumer(builder: (context, ref, _) {
                  final windowState = ref.watch(windowModeProvider);
                  if (FoldableQuizScaffold.shouldUseFoldableLayout(windowState)) {
                    return const SizedBox.shrink();
                  }
                  return _buildWeightSummary(
                    isDark, textPrimary, textSecondary,
                    currentWeight: currentWeight,
                    goalWeight: goalWeight,
                    useMetric: useMetric,
                    isLosingWeight: isLosingWeight,
                    workoutDays: workoutDays,
                    weeklyRateKg: weeklyRate,
                  ).animate().fadeIn(delay: 600.ms);
                }),

                const SizedBox(height: 20),

                // CTA Button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();

                    // Track weight goal set
                    ref.read(posthogServiceProvider).capture(
                      eventName: 'onboarding_weight_goal_set',
                      properties: {
                        'goal_weight_kg': goalWeight,
                        'current_weight_kg': currentWeight,
                        'direction': isLosingWeight ? 'lose' : 'gain',
                      },
                    );

                    context.go('/training-split');
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.orange, Color(0xFFEA580C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orange.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rocket_launch, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChart(
    List<WeightDataPoint> data,
    double currentWeight,
    double goalWeight,
    bool useMetric,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    bool isLosingWeight,
  ) {
    final minWeight = isLosingWeight ? goalWeight : currentWeight;
    final maxWeight = isLosingWeight ? currentWeight : goalWeight;
    final padding = (maxWeight - minWeight) * 0.15;

    // Convert weight for display if using imperial
    double displayWeight(double kg) => useMetric ? kg : kg * 2.20462;
    String weightUnit = useMetric ? 'kg' : 'lbs';

    return AnimatedBuilder(
      animation: _lineAnimation,
      builder: (context, child) {
        // Calculate how many points to show based on animation progress
        final visiblePointCount =
            (_lineAnimation.value * data.length).ceil().clamp(1, data.length);
        final visibleData = data.sublist(0, visiblePointCount);

        return SizedBox.expand(
          child: Stack(
            children: [
              // Gradient background
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.orange.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              // Chart
              LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) =>
                          (isDark ? AppColors.elevated : AppColorsLight.elevated)
                              .withValues(alpha: 0.95),
                      tooltipPadding: const EdgeInsets.all(8),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final date = data[spot.spotIndex].date;
                          final weight = displayWeight(spot.y);
                          return LineTooltipItem(
                            '${DateFormat('MMM d').format(date)}\n${weight.toStringAsFixed(1)} $weightUnit',
                            TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxWeight - minWeight + padding * 2) / 4,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: const FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (data.length - 1).toDouble(),
                  minY: minWeight - padding,
                  maxY: maxWeight + padding,
                  lineBarsData: [
                    LineChartBarData(
                      spots: visibleData.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value.weight,
                        );
                      }).toList(),
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: AppColors.orange,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          // Larger dots for first and last points
                          final isEndpoint =
                              index == 0 || index == visibleData.length - 1;
                          return FlDotCirclePainter(
                            radius: isEndpoint ? 6 : 4,
                            color: AppColors.orange,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.orange.withValues(alpha: 0.3),
                            AppColors.orange.withValues(alpha: 0.05),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // "Today" label at start
              Positioned(
                left: 8,
                top: isLosingWeight ? 40 : 200,
                child: _buildPointLabel(
                  'Today',
                  textSecondary,
                  isDark,
                ).animate().fadeIn(delay: 500.ms),
              ),

              // Goal Weight label at end (only show when animation is complete)
              if (_lineAnimation.value > 0.9)
                Positioned(
                  right: 8,
                  top: isLosingWeight ? 180 : 40,
                  child: _buildGoalLabel(
                    'Goal Weight',
                    isDark,
                    textPrimary,
                  ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPointLabel(String label, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildGoalLabel(String label, bool isDark, Color textPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.orange, Color(0xFFEA580C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '🏆',
            style: TextStyle(fontSize: 14),
          ),
          SizedBox(width: 6),
          Text(
            'Goal Weight',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintainBenefitCard(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    int delayMs,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: delayMs.ms).fadeIn().slideX(begin: 0.1);
  }
}
