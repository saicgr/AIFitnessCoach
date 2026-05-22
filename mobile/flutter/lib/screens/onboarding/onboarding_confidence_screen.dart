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

/// Onboarding conversion v6 — confidence slider (commitment elicitation).
///
/// Shown just before the plan preview / paywall. Asking the user to rate
/// their own confidence is a commitment device — stating an intent makes
/// it more self-binding. The reassurance copy is honest and non-numeric:
/// Zealova is pre-launch, so there are NO "X% of users" stats. Every line
/// is about how the plan actually works (memory: no fabricated stats).
class OnboardingConfidenceScreen extends ConsumerStatefulWidget {
  const OnboardingConfidenceScreen({super.key});

  static const String routePath = '/onboarding-confidence';

  /// Next screen in the funnel — the personalized plan preview, flagged so
  /// it knows it is running inside onboarding.
  static const String _nextRoute = '/plan-preview?from=onboarding';

  @override
  ConsumerState<OnboardingConfidenceScreen> createState() =>
      _OnboardingConfidenceScreenState();
}

class _OnboardingConfidenceScreenState
    extends ConsumerState<OnboardingConfidenceScreen> {
  // 1-10. Starts mid-high so the slider invites a downward OR upward
  // adjustment rather than anchoring at an extreme.
  double _value = 6;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(preAuthQuizProvider).goalConfidence;
    if (existing != null) _value = existing.toDouble().clamp(1, 10);
    _maybeSkip();
  }

  Future<void> _maybeSkip() async {
    final enabled = await OnboardingExperiments.isEnabled(
      ref.read(posthogServiceProvider),
      OnboardingExperiments.flagConfidence,
    );
    if (!enabled && mounted) {
      context.go(OnboardingConfidenceScreen._nextRoute);
    }
  }

  String _firstName() {
    final raw = ref.read(preAuthQuizProvider).name?.trim() ?? '';
    if (raw.isEmpty || raw.toLowerCase() == 'user') return '';
    final first = raw.split(RegExp(r'\s+')).first;
    if (first.isEmpty) return '';
    return first[0].toUpperCase() + first.substring(1).toLowerCase();
  }

  /// Honest, non-numeric reassurance keyed to the confidence band.
  ({String title, String body}) _reassurance(int v) {
    if (v <= 3) {
      return (
        title: 'Starting unsure is honest.',
        body: 'And it is common. The plan does the deciding for you, so '
            'all you bring is showing up. Confidence gets built by doing, '
            'not before you start.',
      );
    }
    if (v <= 6) {
      return (
        title: 'A realistic place to start.',
        body: 'The plan adjusts every week to what you actually did, so '
            'it keeps pace with real life instead of a perfect version '
            'of it.',
      );
    }
    return (
      title: 'That belief will carry you.',
      body: 'The plan will keep pace and push harder the moment you are '
          'ready for more. Your job is just to keep showing up.',
    );
  }

  Color _bandColor(int v) {
    if (v <= 3) return const Color(0xFF3B82F6); // calm blue, not alarming
    if (v <= 6) return AppColors.onboardingAccent;
    return const Color(0xFF34C759);
  }

  Future<void> _continue() async {
    HapticFeedback.mediumImpact();
    final score = _value.round();
    await ref
        .read(preAuthQuizProvider.notifier)
        .setGoalConfidence(score);
    ref.read(posthogServiceProvider).capture(
      eventName: 'onboarding_confidence_answered',
      properties: {'score': score},
    );
    if (mounted) context.go(OnboardingConfidenceScreen._nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = OnboardingTheme.of(context);
    final v = _value.round();
    final band = _bandColor(v);
    final reassurance = _reassurance(v);
    final name = _firstName();

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
                  const SizedBox(height: 28),
                  Text(
                    name.isEmpty
                        ? "How confident are you you'll get there?"
                        : "$name, how confident are you you'll get there?",
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: t.textPrimary,
                      letterSpacing: -0.5,
                      height: 1.25,
                    ),
                  ).animate().fadeIn().slideY(begin: -0.1),
                  const SizedBox(height: 6),
                  Text(
                    'Be honest. There is no wrong answer here.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: t.textSecondary,
                    ),
                  ).animate().fadeIn(delay: 120.ms),
                  const Spacer(),
                  // Big live readout.
                  Center(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$v',
                            style: TextStyle(
                              fontSize: 72,
                              fontWeight: FontWeight.w900,
                              color: band,
                              letterSpacing: -2,
                            ),
                          ),
                          TextSpan(
                            text: '  / 10',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: t.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: band,
                      inactiveTrackColor: t.borderDefault,
                      thumbColor: band,
                      overlayColor: band.withValues(alpha: 0.18),
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 13),
                    ),
                    child: Slider(
                      value: _value,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '$v',
                      semanticFormatterCallback: (value) =>
                          '${value.round()} out of 10',
                      onChanged: (nv) {
                        if (nv.round() != _value.round()) {
                          HapticFeedback.selectionClick();
                        }
                        setState(() => _value = nv);
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Not sure yet',
                          style: TextStyle(
                              fontSize: 12, color: t.textMuted)),
                      Text('Fully in',
                          style: TextStyle(
                              fontSize: 12, color: t.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Reassurance card — cross-fades as the band changes.
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Container(
                      key: ValueKey(reassurance.title),
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      decoration: BoxDecoration(
                        color: band.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: band.withValues(alpha: 0.22)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reassurance.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: t.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            reassurance.body,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.45,
                              color: t.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  _ConfidenceContinueButton(onTap: _continue)
                      .animate()
                      .fadeIn(delay: 200.ms)
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

class _ConfidenceContinueButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ConfidenceContinueButton({required this.onTap});

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
