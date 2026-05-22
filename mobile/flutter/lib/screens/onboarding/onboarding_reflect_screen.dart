import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import 'onboarding_experiments.dart';
import 'pre_auth_quiz_data.dart';
import 'widgets/onboarding_theme.dart';

/// Onboarding conversion v6 — acknowledgment interstitial.
///
/// Shown right after the quiz, before /onboarding-blocker. No input: it
/// exists purely to give value back (Noom's reciprocity principle — every
/// step should return something, not just extract). It echoes the user's
/// own goal + why + schedule in one warm sentence and anchors an honest,
/// locally-computed outcome. Never reads Gemini output.
class OnboardingReflectScreen extends ConsumerStatefulWidget {
  const OnboardingReflectScreen({super.key});

  static const String routePath = '/onboarding-reflect';
  static const String _nextRoute = '/onboarding-blocker';

  @override
  ConsumerState<OnboardingReflectScreen> createState() =>
      _OnboardingReflectScreenState();
}

class _OnboardingReflectScreenState
    extends ConsumerState<OnboardingReflectScreen> {
  // Goal id → verb phrase. IDs come from the quiz goal question
  // (_buildGoalQuestion) plus a few legacy ids for safety.
  static const Map<String, String> _goalPhrases = {
    'build_muscle': 'build muscle',
    'lose_weight': 'lose weight',
    'increase_strength': 'get stronger',
    'gain_strength': 'get stronger',
    'improve_endurance': 'build your endurance',
    'improve_fitness': 'get fitter',
    'stay_active': 'stay active',
    'athletic_performance': 'boost your performance',
    'body_recomp': 'recomp your body',
  };

  // Why id → phrase, matching the options in onboarding_why_screen.dart.
  static const Map<String, String> _whyPhrases = {
    'feel_confident': 'feel confident in your body',
    'keep_up': 'keep up with your family',
    'event': 'be ready for your event',
    'health': 'take charge of your health',
    'feel_strong': 'feel strong and capable',
    'energy': 'have more energy and less stress',
  };

  @override
  void initState() {
    super.initState();
    _maybeSkip();
  }

  Future<void> _maybeSkip() async {
    final enabled = await OnboardingExperiments.isEnabled(
      ref.read(posthogServiceProvider),
      OnboardingExperiments.flagReflect,
    );
    if (!enabled && mounted) {
      context.go(OnboardingReflectScreen._nextRoute);
    }
  }

  void _continue() {
    HapticFeedback.mediumImpact();
    ref.read(posthogServiceProvider).capture(
          eventName: 'onboarding_reflect_completed',
        );
    context.go(OnboardingReflectScreen._nextRoute);
  }

  /// Honest outcome line. With a real weight delta from the quiz it
  /// restates the user's OWN target (their input, not a fabricated
  /// projection) and never attaches a fake weekly rate. Otherwise it
  /// falls back to the same honest framing the trust screen uses.
  String _outcomeLine(PreAuthQuizData quiz) {
    final cur = quiz.weightKg;
    final goal = quiz.goalWeightKg;
    if (cur != null && goal != null && cur > 0 && goal > 0) {
      final delta = (goal - cur).abs();
      if (delta >= 0.5) {
        final unit = quiz.useMetricUnits ? 'kg' : 'lb';
        final amt = quiz.useMetricUnits
            ? delta.round()
            : (delta * 2.20462).round();
        if (amt > 0) {
          final dir = goal < cur ? 'lose' : 'gain';
          return 'Your target is to $dir $amt $unit. The plan adds a '
              'little every week and adjusts to keep that realistic.';
        }
      }
    }
    return 'The plan starts where you are today and progresses every '
        'week. Most people see real change by week three.';
  }

  /// The woven echo sentence — the user's goal, their why, and schedule.
  /// Bold spans highlight the values they actually gave us.
  List<TextSpan> _echoSpans(PreAuthQuizData quiz, TextStyle base) {
    final bold = base.copyWith(fontWeight: FontWeight.w800);
    final goalPhrase = _goalPhrases[quiz.goal] ?? 'reach your goal';
    final why = quiz.primaryWhy != null ? _whyPhrases[quiz.primaryWhy] : null;
    final days = quiz.daysPerWeek;

    final spans = <TextSpan>[
      TextSpan(text: "You're here to ", style: base),
      TextSpan(text: goalPhrase, style: bold),
    ];
    if (why != null) {
      spans
        ..add(TextSpan(text: ', so you can ', style: base))
        ..add(TextSpan(text: why, style: bold));
    }
    if (days != null && days > 0) {
      spans
        ..add(TextSpan(text: ', training ', style: base))
        ..add(TextSpan(
            text: '$days ${days == 1 ? 'day' : 'days'} a week', style: bold));
    }
    spans.add(TextSpan(text: '.', style: base));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = OnboardingTheme.of(context);
    final quiz = ref.watch(preAuthQuizProvider);

    final echoBase = TextStyle(
      fontSize: 19,
      height: 1.45,
      fontWeight: FontWeight.w500,
      color: t.textPrimary,
      letterSpacing: -0.2,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: OnboardingBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: t.selectionAccent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(Icons.check_rounded,
                        color: t.selectionAccent, size: 30),
                  ).animate().scale(
                        duration: 360.ms,
                        curve: Curves.easeOutBack,
                      ),
                  const SizedBox(height: 18),
                  Text(
                    "Here's what we heard.",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: t.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(delay: 120.ms).slideY(begin: -0.1),
                  const SizedBox(height: 22),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        // The woven echo card.
                        Container(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                          decoration: BoxDecoration(
                            color: t.cardFill,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: t.borderDefault),
                          ),
                          child: Text.rich(
                            TextSpan(children: _echoSpans(quiz, echoBase)),
                          ),
                        ).animate().fadeIn(delay: 260.ms).slideY(begin: 0.06),
                        const SizedBox(height: 14),
                        // Honest outcome anchor.
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          decoration: BoxDecoration(
                            color: AppColors.onboardingAccent
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.onboardingAccent
                                  .withValues(alpha: 0.20),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.trending_up_rounded,
                                  size: 20,
                                  color: AppColors.onboardingAccent),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _outcomeLine(quiz),
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.4,
                                    fontWeight: FontWeight.w600,
                                    color: t.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 420.ms).slideY(begin: 0.06),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ReflectContinueButton(onTap: _continue)
                      .animate()
                      .fadeIn(delay: 560.ms)
                      .slideY(begin: 0.1),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReflectContinueButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ReflectContinueButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Continue',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.onboardingAccent, Color(0xFFFF6B00)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.onboardingAccent.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
