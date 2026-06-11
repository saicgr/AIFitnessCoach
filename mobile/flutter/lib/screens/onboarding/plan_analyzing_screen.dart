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
import '../../l10n/generated/app_localizations.dart';
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
  // Labels are deferred to build() so AppLocalizations.of(context) can be used.
  List<_AnalysisStep> _steps = const [];

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
      // ApiConstants.baseUrl is the bare host (e.g. https://aifitnesscoach-zqi3.onrender.com).
      // The router mounts onboarding under /api/v1, so we need apiBaseUrl
      // (which appends /api/v1). Hitting baseUrl alone returned 404 → JSON
      // parse failure on the FastAPI 404 body → silent goal-date fallback +
      // misleading Sentry error in the next screen.
      final dio = Dio(BaseOptions(baseUrl: ApiConstants.apiBaseUrl));
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

  /// Goal id → noun phrase (mirrors sign_in_screen's `_formatGoal`).
  String _formatGoal(String goal) {
    switch (goal) {
      case 'build_muscle':
        return 'Muscle Building';
      case 'lose_weight':
        return 'Weight Loss';
      case 'increase_strength':
        return 'Strength';
      case 'improve_endurance':
        return 'Endurance';
      case 'stay_active':
        return 'Active Lifestyle';
      case 'athletic_performance':
        return 'Performance';
      default:
        return 'Fitness';
    }
  }

  /// "5'10" · 168 lb" or "178 cm · 76 kg" depending on the user's units.
  String? _formatBody(PreAuthQuizData quiz) {
    final h = quiz.heightCm;
    final w = quiz.weightKg;
    if (h == null || w == null) return null;
    if (quiz.useMetricUnits) {
      return '${h.round()} cm · ${w.round()} kg';
    }
    final totalIn = h / 2.54;
    final ft = totalIn ~/ 12;
    final inch = (totalIn % 12).round();
    final lb = (w * 2.20462).round();
    return "$ft'$inch\" · $lb lb";
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    // v7 "receipts": each step echoes the user's OWN quiz answers back —
    // proof the AI listened, not a generic checklist. Missing data falls
    // back to the original generic label (never invented values).
    if (_steps.isEmpty) {
      final quiz = ref.read(preAuthQuizProvider);
      final goal = quiz.goal;
      final body = _formatBody(quiz);
      final days = quiz.daysPerWeek;
      _steps = [
        _AnalysisStep(
          icon: Icons.flag_rounded,
          label: goal != null
              ? l10n.planAnalyzingReceiptGoals(_formatGoal(goal))
              : l10n.planAnalyzingReviewingYourGoals,
        ),
        _AnalysisStep(
          icon: Icons.accessibility_new_rounded,
          label: body != null
              ? l10n.planAnalyzingReceiptBody(body)
              : l10n.planAnalyzingMatchingYourBodyType,
        ),
        _AnalysisStep(
          icon: Icons.calendar_today_rounded,
          label: days != null
              ? l10n.planAnalyzingReceiptSchedule(days)
              : l10n.planAnalyzingCalibratingYourSchedule,
        ),
        _AnalysisStep(
            icon: Icons.fitness_center_rounded,
            label: l10n.planAnalyzingPullingFrom1700),
        _AnalysisStep(
            icon: Icons.trending_up_rounded,
            label: l10n.planAnalyzingCalculatingYourGoalDate),
      ];
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Animated AI icon
              _PulsingAiOrb(),
              const SizedBox(height: 26),
              Text(
                l10n.planAnalyzingBuildingYourPlan.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Anton',
                  fontSize: 30,
                  color: textPrimary,
                  height: 1.05,
                ),
              ).animate().fadeIn(),
              const SizedBox(height: 8),
              Text(
                l10n.planAnalyzingSubtitleV7,
                style: TextStyle(fontSize: 13.5, color: textSecondary),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 26),

              // Slim progress bar tied to the step sequence.
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Container(
                  height: 5,
                  color: isDark
                      ? const Color(0xFF1A1A1D)
                      : AppColorsLight.elevated,
                  child: AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor:
                        ((_currentStep) / _steps.length).clamp(0.06, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [
                          Color(0xFFFFB366),
                          AppColors.orange,
                        ]),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.orange.withValues(alpha: 0.5),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 26),

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
              // v7 receipts read as terminal output — Space Mono is already
              // bundled for shareables.
              style: TextStyle(
                fontFamily: 'Space Mono',
                fontSize: 13,
                fontWeight: isIdle ? FontWeight.w400 : FontWeight.w700,
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
