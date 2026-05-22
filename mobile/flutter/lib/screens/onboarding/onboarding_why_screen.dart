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

/// Onboarding conversion v6 — "What's your why" screen.
///
/// The emotional anchor, asked FIRST (right after /intro, before the
/// pre-auth quiz). It has no functional purpose for workout generation —
/// it exists purely to raise engagement and commitment, and to let later
/// copy (the reflect screen, the paywall headline) echo the user's own
/// reason back at them. Cal AI's playbook: questions that do not change
/// the product but lift conversion.
///
/// One tap selects; Continue advances; a quiet Skip link keeps it
/// low-friction (Day-0 churn risk). The answer persists to
/// `preAuthQuizProvider.primaryWhy`.
class OnboardingWhyScreen extends ConsumerStatefulWidget {
  const OnboardingWhyScreen({super.key});

  static const String routePath = '/onboarding-why';

  @override
  ConsumerState<OnboardingWhyScreen> createState() =>
      _OnboardingWhyScreenState();
}

class _WhyOption {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  const _WhyOption(this.id, this.label, this.icon, this.color);
}

class _OnboardingWhyScreenState extends ConsumerState<OnboardingWhyScreen> {
  // Engagement-only options. Order is intentional: aspirational first,
  // health-driven in the middle, energy last. IDs are stable storage keys
  // — never reorder-rename without a migration of `preAuth_primaryWhy`.
  static const List<_WhyOption> _options = [
    _WhyOption('feel_confident', 'Feel confident in my body',
        Icons.spa_rounded, Color(0xFF8B5CF6)),
    _WhyOption('keep_up', 'Keep up with my family',
        Icons.family_restroom_rounded, Color(0xFF3B82F6)),
    _WhyOption('event', 'Get ready for an event',
        Icons.celebration_rounded, Color(0xFFFF6B6B)),
    _WhyOption('health', 'A health wake-up call',
        Icons.monitor_heart_rounded, Color(0xFFEF4444)),
    _WhyOption('feel_strong', 'Feel strong and capable',
        Icons.bolt_rounded, Color(0xFFF59E0B)),
    _WhyOption('energy', 'More energy, less stress',
        Icons.wb_sunny_rounded, Color(0xFF14B8A6)),
  ];

  String? _selected;

  @override
  void initState() {
    super.initState();
    // Prefill for a returning user replaying onboarding.
    _selected = ref.read(preAuthQuizProvider).primaryWhy;
    _maybeSkip();
  }

  /// Remote kill-switch: if the `onboarding_why_screen` flag is explicitly
  /// disabled, drop straight into the quiz. Absent flag → screen stays.
  Future<void> _maybeSkip() async {
    final enabled = await OnboardingExperiments.isEnabled(
      ref.read(posthogServiceProvider),
      OnboardingExperiments.flagWhy,
    );
    if (!enabled && mounted) {
      context.go('/pre-auth-quiz');
    }
  }

  void _select(String id) {
    HapticFeedback.selectionClick();
    setState(() => _selected = id);
  }

  Future<void> _continue() async {
    if (_selected == null) return;
    HapticFeedback.mediumImpact();
    await ref.read(preAuthQuizProvider.notifier).setPrimaryWhy(_selected);
    ref.read(posthogServiceProvider).capture(
      eventName: 'onboarding_why_answered',
      properties: {'why': _selected!},
    );
    if (mounted) context.push('/pre-auth-quiz');
  }

  Future<void> _skip() async {
    HapticFeedback.lightImpact();
    // Clear any stale value so a skipped screen does not leave a why on file.
    await ref.read(preAuthQuizProvider.notifier).setPrimaryWhy(null);
    ref.read(posthogServiceProvider).capture(
          eventName: 'onboarding_why_skipped',
        );
    if (mounted) context.push('/pre-auth-quiz');
  }

  void _back() {
    HapticFeedback.lightImpact();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/intro');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = OnboardingTheme.of(context);

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
                  const SizedBox(height: 4),
                  // Back affordance — pops to /intro.
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: _back,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.arrow_back_rounded,
                          color: t.textSecondary, size: 24),
                      tooltip: 'Back',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'FIRST, THE WHY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                      color: t.accent,
                    ),
                  ).animate().fadeIn(),
                  const SizedBox(height: 8),
                  Text(
                    "What's driving this?",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: t.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(delay: 80.ms).slideY(begin: -0.1),
                  const SizedBox(height: 6),
                  Text(
                    'Your reason matters more than any workout plan. '
                    "We'll keep it in sight as you go.",
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: t.textSecondary,
                    ),
                  ).animate().fadeIn(delay: 160.ms),
                  const SizedBox(height: 18),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: 8),
                      itemCount: _options.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final o = _options[i];
                        return _WhyOptionCard(
                          option: o,
                          selected: _selected == o.id,
                          onTap: () => _select(o.id),
                        )
                            .animate()
                            .fadeIn(delay: (240 + i * 70).ms)
                            .slideX(begin: 0.05, duration: 320.ms);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ContinueButton(
                    enabled: _selected != null,
                    onTap: _continue,
                  ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1),
                  const SizedBox(height: 4),
                  Center(
                    child: TextButton(
                      onPressed: _skip,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: t.textMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One selectable "why" row — icon chip, label, trailing check.
class _WhyOptionCard extends StatelessWidget {
  final _WhyOption option;
  final bool selected;
  final VoidCallback onTap;

  const _WhyOptionCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);

    return Semantics(
      button: true,
      selected: selected,
      label: option.label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(colors: t.cardSelectedGradient)
                : null,
            color: selected ? null : t.cardFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? t.borderSelected : t.borderSubtle,
              width: selected ? 1.6 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: option.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(option.icon, color: option.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  option.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedScale(
                scale: selected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: t.checkBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_rounded,
                      color: t.checkIcon, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Primary Continue CTA — orange gradient when an option is picked,
/// dimmed and inert until then.
class _ContinueButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _ContinueButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Continue',
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: enabled ? 1.0 : 0.45,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.onboardingAccent, Color(0xFFFF6B00)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: AppColors.onboardingAccent
                            .withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
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
      ),
    );
  }
}
