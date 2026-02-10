import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/window_mode_provider.dart';
import 'pre_auth_quiz_screen.dart';
import 'widgets/foldable_quiz_scaffold.dart';

/// Data point for weight projection chart
class WeightDataPoint {
  final DateTime date;
  final double weight;

  WeightDataPoint(this.date, this.weight);
}

/// Calculator for weight projection
class WeightProjectionCalculator {
  /// Calculate goal date based on current weight, goal weight, and rate preference
  static DateTime calculateGoalDate({
    required double currentWeight,
    required double goalWeight,
    required int workoutDaysPerWeek,
    String? weightChangeRate,
  }) {
    final weightDiff = (currentWeight - goalWeight).abs();

    // Use rate preference if available, otherwise calculate based on workout frequency
    double weeklyRate;
    if (weightChangeRate != null) {
      // Use the selected rate
      switch (weightChangeRate) {
        case 'slow':
          weeklyRate = goalWeight < currentWeight ? 0.25 : 0.25;
          break;
        case 'moderate':
          weeklyRate = goalWeight < currentWeight ? 0.5 : 0.35;
          break;
        case 'fast':
          weeklyRate = goalWeight < currentWeight ? 0.75 : 0.5;
          break;
        case 'aggressive':
          weeklyRate = goalWeight < currentWeight ? 1.0 : 0.5;
          break;
        default:
          weeklyRate = goalWeight < currentWeight ? 0.5 : 0.35;
      }
    } else if (goalWeight < currentWeight) {
      // Weight loss: 0.5-1 kg/week based on workout frequency
      weeklyRate = 0.5 + (workoutDaysPerWeek / 14); // 0.5-1.0
    } else {
      // Weight gain: 0.25-0.5 kg/week (muscle gain is slower)
      weeklyRate = 0.25 + (workoutDaysPerWeek / 28); // 0.25-0.5
    }

    final weeksNeeded = (weightDiff / weeklyRate).ceil();
    return DateTime.now().add(Duration(days: weeksNeeded * 7));
  }

  /// Generate smooth curve with data points for chart
  static List<WeightDataPoint> generateProjectionCurve({
    required double currentWeight,
    required double goalWeight,
    required DateTime goalDate,
  }) {
    final points = <WeightDataPoint>[];
    final today = DateTime.now();
    final totalDays = goalDate.difference(today).inDays;

    // Generate 6-8 data points along the curve
    const numPoints = 7;

    for (int i = 0; i < numPoints; i++) {
      final progress = i / (numPoints - 1);
      final daysFromNow = (totalDays * progress).round();
      final date = today.add(Duration(days: daysFromNow));

      // Use ease-out curve: faster initial progress, slower as approaching goal
      // y = 1 - (1 - x)^2
      final easeOutProgress = 1 - (1 - progress) * (1 - progress);
      final weight = currentWeight +
          (goalWeight - currentWeight) * easeOutProgress;

      points.add(WeightDataPoint(date, weight));
    }

    return points;
  }
}

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
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            context.go('/personal-info');
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.glassSurface
                  : AppColorsLight.glassSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back,
              color: textPrimary,
              size: 20,
            ),
          ),
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
          headerOverlay: backButton,
          content: SingleChildScrollView(
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

                const SizedBox(height: 40),

                // Chart
                _buildChart(
                  projectionData,
                  currentWeight,
                  goalWeight,
                  useMetric,
                  isDark,
                  textPrimary,
                  textSecondary,
                  isLosingWeight,
                ),

                const SizedBox(height: 60),

                // CTA Section
                _buildCtaSection(
                  isDark,
                  textPrimary,
                  textSecondary,
                  isLosingWeight,
                ),

                const SizedBox(height: 40),
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

        return SizedBox(
          height: 280,
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

  Widget _buildCtaSection(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    bool isLosingWeight,
  ) {
    return Column(
      children: [
        // Title
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              height: 1.3,
            ),
            children: const [
              TextSpan(text: 'Let\'s make it '),
              TextSpan(
                text: 'happen',
                style: TextStyle(
                  color: AppColors.orange,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 800.ms),

        const SizedBox(height: 12),

        // Subtitle
        Text(
          isLosingWeight
              ? 'Your personalized workout plan is ready. We\'ll help you reach your goal weight safely and sustainably.'
              : 'Your personalized workout plan is designed to help you build muscle and reach your target weight.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: textSecondary,
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 900.ms),

        const SizedBox(height: 32),

        // CTA Button
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            context.go('/coach-selection');
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
        ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.2),
      ],
    );
  }

  /// Build an alternate screen for users who selected "Maintain" weight goal
  Widget _buildMaintainScreen(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color background,
    double currentWeight,
    bool useMetric,
  ) {
    final displayWeight = useMetric ? currentWeight : currentWeight * 2.20462;
    final unit = useMetric ? 'kg' : 'lbs';

    final maintainBackButton = Padding(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            context.go('/personal-info');
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.glassSurface
                  : AppColorsLight.glassSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back,
              color: textPrimary,
              size: 20,
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: FoldableQuizScaffold(
          headerTitle: "You're at Your Ideal Weight!",
          headerSubtitle: "Let's keep you there! We'll focus on maintaining your current physique while improving your fitness.",
          headerExtra: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.green.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.green,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '${displayWeight.round()} $unit',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
          headerOverlay: maintainBackButton,
          content: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Show title/celebration inline only on phone
                Consumer(builder: (context, ref, _) {
                  final windowState = ref.watch(windowModeProvider);
                  if (FoldableQuizScaffold.shouldUseFoldableLayout(windowState)) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: [
                      const SizedBox(height: 40),

                      // Celebration emoji
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.green.withValues(alpha: 0.2),
                              AppColors.orange.withValues(alpha: 0.2),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            '✨',
                            style: TextStyle(fontSize: 48),
                          ),
                        ),
                      ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.8, 0.8)),

                      const SizedBox(height: 32),

                      // Title
                      Text(
                        "You're at Your Ideal Weight!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                          height: 1.3,
                        ),
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: -0.1),

                      const SizedBox(height: 16),

                      // Current weight display
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.green.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.green,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${displayWeight.round()} $unit',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95)),

                      const SizedBox(height: 32),

                      // Subtitle
                      Text(
                        "Let's keep you there! We'll focus on maintaining your current physique while improving your overall fitness, strength, and energy levels.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: textSecondary,
                          height: 1.5,
                        ),
                      ).animate().fadeIn(delay: 500.ms),
                    ],
                  );
                }),

                const SizedBox(height: 40),

                // Benefits cards
                _buildMaintainBenefitCard(
                  isDark,
                  textPrimary,
                  textSecondary,
                  Icons.fitness_center,
                  'Build Strength',
                  'Gain muscle while maintaining weight',
                  AppColors.purple,
                  600,
                ),
                const SizedBox(height: 12),
                _buildMaintainBenefitCard(
                  isDark,
                  textPrimary,
                  textSecondary,
                  Icons.bolt,
                  'Boost Energy',
                  'Optimize nutrition for peak performance',
                  AppColors.orange,
                  700,
                ),
                const SizedBox(height: 12),
                _buildMaintainBenefitCard(
                  isDark,
                  textPrimary,
                  textSecondary,
                  Icons.favorite,
                  'Stay Healthy',
                  'Balanced lifestyle for long-term wellness',
                  AppColors.coral,
                  800,
                ),

                const SizedBox(height: 48),

                // CTA Button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.go('/coach-selection');
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
                          'Continue to Your Plan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.2),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
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
