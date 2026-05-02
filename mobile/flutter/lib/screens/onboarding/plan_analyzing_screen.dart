import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/posthog_service.dart';
import 'pre_auth_quiz_data.dart';

/// Plan Analyzing Screen — Onboarding v5 / Cal AI pattern
///
/// Performative AI generation. Cal AI's plan generation feels long because
/// it sells the personalization. We do the same: 5 sequential checkmarks,
/// each ~700ms apart, with a real backend call in the middle to compute
/// the user's projected goal date (which the next screen displays).
///
/// Total visible time: ~5 seconds.
/// While the animation plays, we hit POST /onboarding/computed-goal-date
/// (no auth required — pre-signup endpoint) and stash the result in
/// PreAuthQuizData.goalTargetDate.
class PlanAnalyzingScreen extends ConsumerStatefulWidget {
  const PlanAnalyzingScreen({super.key});

  @override
  ConsumerState<PlanAnalyzingScreen> createState() =>
      _PlanAnalyzingScreenState();
}

class _PlanAnalyzingScreenState extends ConsumerState<PlanAnalyzingScreen>
    with TickerProviderStateMixin {
  // Each step shows in order: idle → checking → done.
  final List<_AnalysisStep> _steps = const [
    _AnalysisStep(icon: Icons.flag_rounded, label: 'Reviewing your goals'),
    _AnalysisStep(
        icon: Icons.accessibility_new_rounded,
        label: 'Matching your body type'),
    _AnalysisStep(
        icon: Icons.calendar_today_rounded, label: 'Calibrating your schedule'),
    _AnalysisStep(
        icon: Icons.fitness_center_rounded, label: 'Pulling from 1,700+ exercises'),
    _AnalysisStep(
        icon: Icons.trending_up_rounded,
        label: 'Calculating your goal date'),
  ];

  int _currentStep = 0;
  Timer? _stepTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _startSequence();
    _fetchGoalDate();
  }

  void _startSequence() {
    _stepTimer = Timer.periodic(const Duration(milliseconds: 850), (timer) {
      if (!mounted) return;
      setState(() {
        if (_currentStep < _steps.length) {
          _currentStep++;
        } else {
          _stepTimer?.cancel();
          _maybeNavigate();
        }
      });
    });
  }

  Future<void> _fetchGoalDate() async {
    final quiz = ref.read(preAuthQuizProvider);

    // Skip if no body data yet — projection needs weight + target.
    if (quiz.weightKg == null || quiz.goalWeightKg == null) {
      return;
    }

    try {
      final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
      final response = await dio.post(
        '/onboarding/computed-goal-date',
        data: {
          'weight_kg': quiz.weightKg,
          'target_weight_kg': quiz.goalWeightKg,
          'weight_change_rate': quiz.weightChangeRate ?? 'moderate',
          'activity_level': quiz.activityLevel ?? 'moderately_active',
          'days_per_week': quiz.daysPerWeek ?? 4,
        },
      );
      final data = response.data as Map<String, dynamic>?;
      final goalDate = data?['goal_date'] as String?;
      if (goalDate != null) {
        await ref
            .read(preAuthQuizProvider.notifier)
            .setGoalTargetDate(goalDate);
      }
    } catch (e) {
      // Non-fatal — weight-projection screen falls back to client-side math.
      debugPrint('plan-analyzing: goal date fetch failed: $e');
    }
  }

  void _maybeNavigate() {
    if (_navigated) return;
    _navigated = true;
    HapticFeedback.mediumImpact();
    ref.read(posthogServiceProvider).capture(
          eventName: 'onboarding_plan_analyzing_completed',
        );
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) context.go('/weight-projection');
    });
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Animated AI icon
              _PulsingAiOrb(),
              const SizedBox(height: 28),
              Text(
                'Building your plan',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(),
              const SizedBox(height: 6),
              Text(
                'This will take a few seconds…',
                style: TextStyle(fontSize: 14, color: textSecondary),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 36),

              // Steps
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _steps.length,
                  itemBuilder: (ctx, i) {
                    final step = _steps[i];
                    final state = i < _currentStep
                        ? _StepState.done
                        : (i == _currentStep
                            ? _StepState.active
                            : _StepState.idle);
                    return _StepRow(
                      step: step,
                      state: state,
                      isDark: isDark,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _StepState { idle, active, done }

class _AnalysisStep {
  final IconData icon;
  final String label;
  const _AnalysisStep({required this.icon, required this.label});
}

class _StepRow extends StatelessWidget {
  final _AnalysisStep step;
  final _StepState state;
  final bool isDark;
  const _StepRow({required this.step, required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final isDone = state == _StepState.done;
    final isActive = state == _StepState.active;
    final isIdle = state == _StepState.idle;

    final accentColor =
        isDone ? const Color(0xFF2ECC71) : AppColors.onboardingAccent;
    final iconBg = isIdle
        ? (isDark ? AppColors.elevated : AppColorsLight.elevated)
        : accentColor.withValues(alpha: 0.15);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? AppColors.onboardingAccent.withValues(alpha: 0.4)
              : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check_rounded,
                      color: Color(0xFF2ECC71), size: 20)
                  : (isActive
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onboardingAccent,
                          ),
                        )
                      : Icon(step.icon,
                          color: isDark
                              ? AppColors.textMuted
                              : AppColorsLight.textMuted,
                          size: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              step.label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isIdle ? FontWeight.w500 : FontWeight.w600,
                color: isIdle ? textSecondary : textPrimary,
              ),
            ),
          ),
        ],
      ),
    ).animate(target: isDone ? 1 : 0).fadeIn();
  }
}

class _PulsingAiOrb extends StatefulWidget {
  @override
  State<_PulsingAiOrb> createState() => _PulsingAiOrbState();
}

class _PulsingAiOrbState extends State<_PulsingAiOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        // Zealova brand mark — the asset already has its own rounded
        // squircle, so wrapping it in another white circle produced a
        // visible "icon-inside-a-container" stack. Render the icon
        // directly with just the brand-orange glow pulsing behind it.
        return Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.onboardingAccent
                    .withValues(alpha: 0.35 + (_ctrl.value * 0.2)),
                blurRadius: 28 + (_ctrl.value * 12),
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              'assets/images/app_icon.png',
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}
