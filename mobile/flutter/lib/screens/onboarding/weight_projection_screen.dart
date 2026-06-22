import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/config/science_citations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/window_mode_provider.dart';
import '../../core/services/posthog_service.dart';
import '../../widgets/citation_link.dart';
import '../../widgets/glass_back_button.dart';
import 'goal_speed_calculator.dart';
import 'pre_auth_quiz_screen.dart';
import 'widgets/calorie_macro_estimator.dart';
import 'widgets/foldable_quiz_scaffold.dart';
import 'widgets/quiz_weight_rate.dart';
import 'value_beats/plan_ready_beat.dart';

import '../../l10n/generated/app_localizations.dart';
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

  /// True while the user is actively touching a chart point (tooltip showing).
  /// The 🎯 goal-date chip fades out while this is true so it never sits on top
  /// of a tooltip popped over a point near the top-right endpoint.
  bool _chartTouched = false;

  /// Tracks the last rate the curves were drawn for, so changing the pace
  /// replays the draw (smooth recompute) rather than hard-cutting.
  String? _lastDrawnRate;

  /// Drives the "more below" scroll cue. The conversion content — the "N×
  /// faster than going solo" proof, the evidence citations and the
  /// Current/Goal/To-lose/Per-week stat cards — sits under the fold on small
  /// phones. We pulse a labeled chevron until the user scrolls into it so the
  /// sell never goes unseen.
  final ScrollController _scrollController = ScrollController();
  bool _showScrollHint = false;

  // Below this much hidden content the cue stays OFF. The screen is tuned to
  // fit on common phones, so a trivial residual overflow (a few px absorbed by
  // the bounce) must NOT nag — only show the cue when a meaningful chunk (≈ a
  // whole element, e.g. the stats strip) is genuinely below the fold.
  static const double _scrollHintThreshold = 64.0;

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final more = pos.maxScrollExtent - pos.pixels > _scrollHintThreshold;
    if (more != _showScrollHint && mounted) {
      setState(() => _showScrollHint = more);
    }
  }

  /// Replays the line-draw animation and gives a tactile tick — called when
  /// the user drags to a new pace so the curve, goal date and multiplier all
  /// re-animate together (Cal-AI-grade live recompute).
  void _replayForRate(String rate) {
    if (_lastDrawnRate == rate) return;
    _lastDrawnRate = rate;
    HapticFeedback.selectionClick();
    _animationController.forward(from: 0);
  }

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

    // Seed + drive the "more below" scroll cue once the body has laid out.
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

    final divider = Container(
      width: 1,
      height: 26,
      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.07),
    );

    Widget cell(IconData icon, Color color, String label, String value) {
      return Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label + tiny icon on one line, value below — compact 2-row cell.
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 11, color: color),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    // Single compact summary strip — replaces the old 2×2 stat cards + the
    // duplicate green safe-rate banner (the "Safe rate: NHS" citation right
    // above already states it). Keeps all four data points in ~⅓ the height so
    // the whole screen fits without scrolling, dashboard-style.
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          cell(
            Icons.monitor_weight_outlined,
            textSecondary,
            AppLocalizations.of(context).workoutPlanDrawerCurrent,
            '${displayCurrent.round()} $unit',
          ),
          divider,
          cell(
            Icons.flag_outlined,
            AppColors.green,
            AppLocalizations.of(context).challengeCreateFieldGoal,
            '${displayGoal.round()} $unit',
          ),
          divider,
          cell(
            isLosingWeight ? Icons.trending_down : Icons.trending_up,
            AppColors.orange,
            isLosingWeight
                ? AppLocalizations.of(context).weightProjectionToLose
                : AppLocalizations.of(context).weightProjectionToGain,
            '${diff.round()} $unit',
          ),
          divider,
          cell(
            Icons.speed_rounded,
            isDark ? AppColors.cyan : AppColorsLight.cyan,
            AppLocalizations.of(context).weightProjectionPerWeek,
            displayWeeklyRate != null
                ? '${displayWeeklyRate.toStringAsFixed(1)} $unit'
                : '$workoutDays days/wk',
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

    // Plan-vs-solo projection — feeds the grey "On your own" comparison curve
    // and the substantiated "⚡ N× faster" chip. Sampled at the same number of
    // points as the plan curve so both lines share the x-axis indices.
    final speed = GoalSpeedCalculator.compute(
      currentWeightKg: currentWeight,
      goalWeightKg: goalWeight,
      weightChangeRate: weightChangeRate,
      numPoints: projectionData.length,
    );

    final formattedGoalDate = DateFormat('MMM, yyyy').format(goalDate);
    final isLosingWeight = goalWeight < currentWeight;

    // Chart is given a fixed (responsive) height so it can live inside a
    // SingleChildScrollView — a `Flexible` chart here was eating all the height
    // and pushing the Continue button off-screen (the 142px overflow blocker).
    final screenH = MediaQuery.of(context).size.height;
    final chartHeight = (screenH * 0.175).clamp(130.0, 150.0);

    // Pinned CTA — lives in the scaffold's `button` slot (rendered OUTSIDE the
    // scrollable body) so it is always reachable regardless of content height.
    final continueButton = GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        ref.read(posthogServiceProvider).capture(
          eventName: 'onboarding_weight_goal_set',
          properties: {
            'goal_weight_kg': goalWeight,
            'current_weight_kg': currentWeight,
            'direction': isLosingWeight ? 'lose' : 'gain',
          },
        );
        // v5 flow: weight-projection → demo-tasks (workout
        // + nutrition apptaste) → sign-in.
        context.go('/demo-tasks');
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.rocket_launch, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context).onboardingContinueButton,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2);

    final backButton = Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GlassBackButton(
          onTap: () {
            HapticFeedback.lightImpact();
            // Back goes one step in the v5 flow: ← plan-analyzing
            // (not all the way to /intro — losing all quiz answers
            // mid-projection is a footgun).
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/plan-analyzing');
            }
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
          button: continueButton,
          content: Stack(
            children: [
              SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plan-ready celebration (Gravl-gap): seal + "N days/week = M
                // planned workouts/month" stat. Upgrades the plain "plan is
                // ready" line that already lives in this reveal — NOT a new
                // screen (a duplicate preview step was deliberately removed).
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 6),
                    child: PlanReadyFlair(
                      daysPerWeek: workoutDays,
                      compact: true,
                      showHeadline: false,
                      // Drop the big celebration seal here — it ate ~110px of
                      // the fold and pushed the "N× faster" proof off-screen.
                      // A small ✓ in the pill keeps the celebratory beat.
                      showSeal: false,
                    ),
                  ),
                ),
                // Show title inline only on phone
                Consumer(builder: (context, ref, _) {
                  final windowState = ref.watch(windowModeProvider);
                  if (FoldableQuizScaffold.shouldUseFoldableLayout(windowState)) {
                    return const SizedBox.shrink();
                  }
                  return RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                        height: 1.18,
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

                const SizedBox(height: 8),

                // Rate selection chips
                Text(
                  isLosingWeight
                      ? AppLocalizations.of(context).weightProjectionHowFastDoYou
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
                    // Live recompute: replay the curve draw + multiplier with a
                    // tactile tick instead of a hard cut.
                    _replayForRate(rate);
                  },
                ),

                const SizedBox(height: 8),

                // Chart — fixed responsive height (scrollable body, see chartHeight).
                SizedBox(
                  height: chartHeight,
                  child: _buildChart(
                    projectionData,
                    currentWeight,
                    goalWeight,
                    useMetric,
                    isDark,
                    textPrimary,
                    textSecondary,
                    isLosingWeight,
                    goalDate,
                    speed,
                  ),
                ),

                const SizedBox(height: 8),

                // Legend + "⚡ N× faster than going solo" chip + safe-rate
                // citation. The multiplier is the user's own plan-vs-solo
                // projection, anchored to a tappable source.
                _buildSpeedRow(speed, isDark, textPrimary, textSecondary)
                    .animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 8),

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

                // CTA moved to the scaffold's pinned `button:` slot so it can
                // never be pushed off-screen. Small trailing gap keeps the strip
                // clear of the pinned button (scaffold adds its own padding too).
                const SizedBox(height: 3),
              ],
            ),
              ),
              // "More below" cue — the proof ("N× faster"), the evidence
              // citations and the stat cards that actually sell the plan sit
              // under the fold on small phones; pulse a labeled chevron so the
              // user scrolls into them instead of bouncing on the chart. Fades
              // out the moment the proof section reaches the screen.
              Positioned(
                left: 0,
                right: 0,
                bottom: 6,
                child: IgnorePointer(
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _showScrollHint ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 220),
                      child: const _ScrollMoreCue(),
                    ),
                  ),
                ),
              ),
            ],
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
    DateTime goalDate,
    GoalSpeedProjection? speed,
  ) {
    final minWeight = isLosingWeight ? goalWeight : currentWeight;
    final maxWeight = isLosingWeight ? currentWeight : goalWeight;
    final weightRange = maxWeight - minWeight;
    final padding = weightRange * 0.15;
    // The solo curve can sit "behind" the goal (heavier on a loss), so widen
    // the axis a touch to keep it on-canvas.
    final chartMinY = minWeight - padding;
    final chartMaxY = maxWeight + padding;

    // Confidence-band half-widths, fanning out toward the goal (more
    // uncertainty later) — communicates "estimate", not "guarantee".
    final bandMax = weightRange * 0.10;
    final n = data.length;
    double bandHalfAt(int i) => n <= 1 ? 0 : bandMax * (i / (n - 1));

    // Convert weight for display if using imperial
    double displayWeight(double kg) => useMetric ? kg : kg * 2.20462;
    String weightUnit = useMetric ? 'kg' : 'lbs';

    // Calculate sensible Y-axis interval (3-5 labels)
    final displayRange = displayWeight(chartMaxY) - displayWeight(chartMinY);
    final rawInterval = displayRange / 4;
    // Round to nice numbers (5, 10, 20, 25, 50, etc.)
    final niceInterval = rawInterval <= 5
        ? 5.0
        : rawInterval <= 10
            ? 10.0
            : rawInterval <= 25
                ? 25.0
                : 50.0;
    // Convert nice interval back to kg for the chart
    final yInterval = useMetric ? niceInterval : niceInterval / 2.20462;

    return AnimatedBuilder(
      animation: _lineAnimation,
      builder: (context, child) {
        // Calculate how many points to show based on animation progress
        final visiblePointCount =
            (_lineAnimation.value * data.length).ceil().clamp(1, data.length);
        final visibleData = data.sublist(0, visiblePointCount);

        // Solo curve draws with a deliberate LAG (value^1.8) so the speed gap
        // is *felt* during the reveal, both lines settling together at the end.
        final soloT = math.pow(_lineAnimation.value, 1.8).toDouble();
        final soloVisibleCount =
            (soloT * data.length).ceil().clamp(1, data.length);
        final soloSpots = (speed == null)
            ? const <FlSpot>[]
            : [
                for (int i = 0; i < soloVisibleCount; i++)
                  FlSpot(i.toDouble(), speed.soloCurve[i].weightKg),
              ];

        // Confidence band: upper/lower invisible lines around the plan curve,
        // shaded between. Tracks the same visible-point count as the plan.
        final bandUpper = [
          for (int i = 0; i < visiblePointCount; i++)
            FlSpot(i.toDouble(), visibleData[i].weight + bandHalfAt(i)),
        ];
        final bandLower = [
          for (int i = 0; i < visiblePointCount; i++)
            FlSpot(i.toDouble(), visibleData[i].weight - bandHalfAt(i)),
        ];

        // v7: the 🎯 goal-date chip pops in over the line's endpoint as the
        // draw completes (last 15% of the animation).
        final chipT = Curves.easeOutBack.transform(
            ((_lineAnimation.value - 0.85) / 0.15).clamp(0.0, 1.0));

        return Stack(
          children: [
            Container(
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
          child: Padding(
            padding: const EdgeInsets.only(top: 12, right: 8, bottom: 4),
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  // Fade the goal-date chip out of the way while a point is
                  // touched, so its tooltip is never obscured near the endpoint.
                  touchCallback: (event, response) {
                    final touched = event.isInterestedForInteractions &&
                        (response?.lineBarSpots?.isNotEmpty ?? false);
                    if (touched != _chartTouched) {
                      setState(() => _chartTouched = touched);
                    }
                  },
                  // Generous hit-area so taps land easily anywhere near a point.
                  touchSpotThreshold: 26,
                  // Touch indicator: a soft guide line + an enlarged dot on the
                  // plan and solo lines (never the invisible band edges).
                  getTouchedSpotIndicator: (barData, spotIndexes) {
                    return spotIndexes.map((_) {
                      final isBand = barData.barWidth == 0;
                      if (isBand) {
                        return const TouchedSpotIndicatorData(
                          FlLine(color: Colors.transparent),
                          FlDotData(show: false),
                        );
                      }
                      final isSolo = barData.dashArray != null;
                      final dotColor = isSolo
                          ? (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.45)
                          : AppColors.orange;
                      return TouchedSpotIndicatorData(
                        FlLine(
                          color: AppColors.orange.withValues(alpha: 0.35),
                          strokeWidth: 2,
                          dashArray: const [4, 3],
                        ),
                        FlDotData(
                          show: true,
                          getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                            radius: isSolo ? 4.5 : 6,
                            color: dotColor,
                            strokeWidth: 2.5,
                            strokeColor: Colors.white,
                          ),
                        ),
                      );
                    }).toList();
                  },
                  touchTooltipData: LineTouchTooltipData(
                    tooltipRoundedRadius: 12,
                    getTooltipColor: (_) =>
                        (isDark ? AppColors.elevated : AppColorsLight.elevated)
                            .withValues(alpha: 0.96),
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    tooltipMargin: 12,
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (touchedSpots) {
                      // Render ONE combined tooltip on the plan spot showing
                      // both "Your plan" and "On your own" at the tapped date;
                      // suppress the band edges + the duplicate solo box.
                      final planBarIndex = soloSpots.isNotEmpty ? 3 : 2;
                      return touchedSpots.map((spot) {
                        if (spot.barIndex != planBarIndex) return null;
                        final pointIndex = spot.spotIndex.clamp(0, data.length - 1);
                        final date = data[pointIndex].date;
                        final planW = displayWeight(spot.y);
                        final isStart = pointIndex == 0;
                        final isEnd = pointIndex == data.length - 1;
                        final label = isStart
                            ? 'Today'
                            : isEnd
                                ? 'Goal'
                                : DateFormat('MMM yyyy').format(date);
                        final children = <TextSpan>[
                          TextSpan(
                            text: '\nYour plan  ',
                            style: TextStyle(
                              color: AppColors.orange,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          TextSpan(
                            text: '${planW.toStringAsFixed(1)} $weightUnit',
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ];
                        if (speed != null) {
                          final soloW =
                              displayWeight(speed.soloCurve[pointIndex].weightKg);
                          children.add(TextSpan(
                            text: '\nOn your own  ',
                            style: TextStyle(
                              color: textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ));
                          children.add(TextSpan(
                            text: '${soloW.toStringAsFixed(1)} $weightUnit',
                            style: TextStyle(
                              color: textSecondary,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ));
                        }
                        return LineTooltipItem(
                          label,
                          TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            height: 1.5,
                          ),
                          children: children,
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yInterval,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                    strokeWidth: 1,
                    dashArray: [6, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      interval: yInterval,
                      getTitlesWidget: (value, meta) {
                        // Hide labels at the very edges to avoid clipping
                        if (value <= chartMinY || value >= chartMaxY) {
                          return const SizedBox.shrink();
                        }
                        final display = displayWeight(value).round();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '$display',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: textSecondary.withValues(alpha: 0.7),
                            ),
                            textAlign: TextAlign.right,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= data.length) {
                          return const SizedBox.shrink();
                        }
                        // Show first, last, and middle labels
                        final isFirst = index == 0;
                        final isLast = index == data.length - 1;
                        final isMid = index == (data.length ~/ 2);
                        if (!isFirst && !isLast && !isMid) {
                          return const SizedBox.shrink();
                        }
                        final date = data[index].date;
                        final label = isFirst
                            ? 'Today'
                            : DateFormat('MMM yy').format(date);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isFirst || isLast
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isFirst || isLast
                                  ? textSecondary
                                  : textSecondary.withValues(alpha: 0.6),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (data.length - 1).toDouble(),
                minY: chartMinY,
                maxY: chartMaxY,
                // Confidence band fans between the two invisible band lines
                // (indices 0 & 1) — reads as an estimate range, not a promise.
                betweenBarsData: [
                  BetweenBarsData(
                    fromIndex: 0,
                    toIndex: 1,
                    color: AppColors.orange.withValues(alpha: 0.12),
                  ),
                ],
                lineBarsData: [
                  // 0 — lower band edge (invisible)
                  LineChartBarData(
                    spots: bandLower,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    barWidth: 0,
                    color: Colors.transparent,
                    dotData: const FlDotData(show: false),
                  ),
                  // 1 — upper band edge (invisible)
                  LineChartBarData(
                    spots: bandUpper,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    barWidth: 0,
                    color: Colors.transparent,
                    dotData: const FlDotData(show: false),
                  ),
                  // 2 — "On your own" comparison curve (grey, dashed, lags)
                  if (soloSpots.isNotEmpty)
                    LineChartBarData(
                      spots: soloSpots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.32),
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dashArray: const [6, 5],
                      dotData: const FlDotData(show: false),
                    ),
                  // 3 — the plan curve (orange), drawn on top
                  LineChartBarData(
                    spots: visibleData.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value.weight,
                      );
                    }).toList(),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    gradient: const LinearGradient(
                      colors: [AppColors.orange, Color(0xFFEA580C)],
                    ),
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    shadow: Shadow(
                      color: AppColors.orange.withValues(alpha: 0.45),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
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
                  ),
                ],
              ),
            ),
          ),
            ),
            // 🎯 goal-date chip — lands where the line ends. Never intercepts
            // touches (IgnorePointer), and fades out while a point is touched so
            // it doesn't sit on top of that point's tooltip.
            if (chipT > 0)
              PositionedDirectional(
                top: 6,
                end: 6,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _chartTouched ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Transform.scale(
                  scale: 0.6 + 0.4 * chipT,
                  alignment: AlignmentDirectional.topEnd,
                  child: Opacity(
                    opacity: chipT.clamp(0.0, 1.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.orange.withValues(alpha: 0.45),
                            blurRadius: 16,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Text(
                        '🎯 ${DateFormat('MMM d').format(goalDate)}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF160B03),
                        ),
                      ),
                    ),
                  ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Legend dot/dash swatch for the chart lines.
  Widget _legendSwatch(Color color, {required bool dashed}) {
    if (!dashed) {
      return Container(
        width: 14,
        height: 4,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        2,
        (_) => Container(
          width: 6,
          height: 3,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  /// Legend + the substantiated "⚡ N× faster than going solo" chip + the
  /// estimate/safe-rate caption with a tappable citation. The multiplier is
  /// the user's own plan-vs-solo projection — never a fabricated number.
  Widget _buildSpeedRow(
    GoalSpeedProjection? speed,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final greyLegend =
        (isDark ? Colors.white : Colors.black).withValues(alpha: 0.32);

    Widget legendLabel(Color color, String label, {required bool dashed}) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _legendSwatch(color, dashed: dashed),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            legendLabel(AppColors.orange, 'Your plan', dashed: false),
            const SizedBox(width: 16),
            legendLabel(greyLegend, 'On your own', dashed: true),
          ],
        ),
        if (speed != null) ...[
          const SizedBox(height: 10),
          // ⚡ N× faster chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.orange.withValues(alpha: 0.18),
                  AppColors.orange.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.orange.withValues(alpha: 0.30)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⚡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 14, color: textPrimary),
                    children: [
                      TextSpan(
                        text: speed.multiplierLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.orange,
                          fontSize: 16,
                        ),
                      ),
                      const TextSpan(
                        text: ' faster',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(
                        text: '  than going solo',
                        style: TextStyle(color: textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          CitationLink(
            citation: speed.citation,
            accent: AppColors.orange,
            fontSize: 11,
            leading: 'Why this works — ',
          ),
        ],
        const SizedBox(height: 8),
        // One compact disclaimer line: the estimate caveat is folded into the
        // tappable safe-rate citation (the shaded band is self-evident), saving
        // a whole row so the summary strip clears the fold.
        Row(
          children: [
            Icon(Icons.info_outline_rounded,
                size: 13, color: textSecondary.withValues(alpha: 0.7)),
            const SizedBox(width: 6),
            Flexible(
              child: CitationLink(
                citation: ScienceCitations.safeRate,
                accent: textSecondary,
                fontSize: 11,
                leading: 'Estimated range · Safe rate: ',
              ),
            ),
          ],
        ),
      ],
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

/// Floating "more below" cue for the projection screen. The plan's proof —
/// the "N× faster than going solo" chip, the cited evidence and the stat cards
/// — lives under the fold on small phones; this labeled, gently-bobbing chevron
/// tells the user there's something worth scrolling to (not just "scroll").
/// Rendered inside an [IgnorePointer] + [AnimatedOpacity] by the host, so it
/// never blocks taps and fades the instant the proof reaches the screen.
class _ScrollMoreCue extends StatelessWidget {
  const _ScrollMoreCue();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            'See why it works',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.orange,
            ),
          ),
          SizedBox(width: 4),
          _BobbingChevron(),
        ],
      ),
    );
  }
}

class _BobbingChevron extends StatelessWidget {
  const _BobbingChevron();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.keyboard_arrow_down_rounded,
      color: AppColors.orange,
      size: 18,
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: -2, end: 3, duration: 650.ms, curve: Curves.easeInOut);
  }
}
