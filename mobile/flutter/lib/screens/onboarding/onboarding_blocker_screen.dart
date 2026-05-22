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

/// Onboarding conversion v6 — "What's held you back" + acknowledgment.
///
/// Two-stage screen. Stage 1 asks the obstacle question (engagement-only,
/// does not feed workout generation). Stage 2 morphs into an honest
/// acknowledgment of that obstacle and how the plan addresses it — the
/// contrast-and-reassurance lever. No fabricated stats: every line is
/// about how the product actually works.
class OnboardingBlockerScreen extends ConsumerStatefulWidget {
  const OnboardingBlockerScreen({super.key});

  static const String routePath = '/onboarding-blocker';
  static const String _nextRoute = '/trust-and-expectations';

  @override
  ConsumerState<OnboardingBlockerScreen> createState() =>
      _OnboardingBlockerScreenState();
}

class _BlockerOption {
  final String id;
  final String label;
  final IconData icon;
  final String acknowledgment;
  const _BlockerOption(this.id, this.label, this.icon, this.acknowledgment);
}

class _OnboardingBlockerScreenState
    extends ConsumerState<OnboardingBlockerScreen> {
  // IDs are stable storage keys for `preAuth_pastBlocker` — do not rename.
  static const List<_BlockerOption> _options = [
    _BlockerOption(
      'no_time',
      "I couldn't find the time",
      Icons.schedule_rounded,
      'Time is the one nobody beats with willpower. Your plan is built '
          'around the exact days and session length you picked, and if you '
          'miss one the coach reshapes the week instead of piling on guilt.',
    ),
    _BlockerOption(
      'lost_motivation',
      'I lost motivation',
      Icons.battery_2_bar_rounded,
      'Motivation comes and goes for everyone. That is why the plan runs '
          'on a set schedule and small weekly wins, so showing up does not '
          'depend on feeling motivated that day.',
    ),
    _BlockerOption(
      'no_results',
      "I wasn't seeing results",
      Icons.trending_flat_rounded,
      'No results usually means the plan stopped progressing. Yours adds '
          'a little every week with progressive overload, and the coach '
          'changes course when something stalls.',
    ),
    _BlockerOption(
      'unsure',
      "I didn't know what to do",
      Icons.help_outline_rounded,
      'Not knowing what to do is a real wall. Every session here is laid '
          'out for you, with form guidance on each move, so there is no '
          'guesswork before you start.',
    ),
    _BlockerOption(
      'injury',
      'I got injured or burned out',
      Icons.healing_rounded,
      'Injury and burnout are setbacks, not the end. Your plan works '
          'around the limitations you told us about and builds intensity '
          'gradually instead of all at once.',
    ),
    _BlockerOption(
      'first_time',
      'This is my first real attempt',
      Icons.flag_rounded,
      'A first real attempt is a strong place to begin. The plan meets '
          'you where you are today and builds up slowly, so nothing about '
          'week one is overwhelming.',
    ),
  ];

  /// 0 = question, 1 = acknowledgment.
  int _stage = 0;
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = ref.read(preAuthQuizProvider).pastBlocker;
    _maybeSkip();
  }

  Future<void> _maybeSkip() async {
    final enabled = await OnboardingExperiments.isEnabled(
      ref.read(posthogServiceProvider),
      OnboardingExperiments.flagBlocker,
    );
    if (!enabled && mounted) {
      context.go(OnboardingBlockerScreen._nextRoute);
    }
  }

  _BlockerOption? get _selectedOption {
    if (_selected == null) return null;
    for (final o in _options) {
      if (o.id == _selected) return o;
    }
    return null;
  }

  void _select(String id) {
    HapticFeedback.selectionClick();
    setState(() => _selected = id);
  }

  Future<void> _toAcknowledgment() async {
    if (_selected == null) return;
    HapticFeedback.mediumImpact();
    await ref.read(preAuthQuizProvider.notifier).setPastBlocker(_selected!);
    ref.read(posthogServiceProvider).capture(
      eventName: 'onboarding_blocker_answered',
      properties: {'blocker': _selected!},
    );
    if (mounted) setState(() => _stage = 1);
  }

  void _finish() {
    HapticFeedback.mediumImpact();
    context.go(OnboardingBlockerScreen._nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: OnboardingBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.08, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                        parent: animation, curve: Curves.easeOutCubic)),
                    child: child,
                  ),
                ),
                child: _stage == 0
                    ? _buildQuestion(key: const ValueKey('q'))
                    : _buildAcknowledgment(key: const ValueKey('a')),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion({required Key key}) {
    final t = OnboardingTheme.of(context);
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        Text(
          "What's held you back before?",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: t.textPrimary,
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn().slideY(begin: -0.1),
        const SizedBox(height: 6),
        Text(
          "No judgment. Knowing the wall is how we plan around it.",
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: t.textSecondary,
          ),
        ).animate().fadeIn(delay: 120.ms),
        const SizedBox(height: 18),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: _options.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final o = _options[i];
              return _BlockerOptionCard(
                option: o,
                selected: _selected == o.id,
                onTap: () => _select(o.id),
              )
                  .animate()
                  .fadeIn(delay: (200 + i * 65).ms)
                  .slideX(begin: 0.05, duration: 300.ms);
            },
          ),
        ),
        const SizedBox(height: 8),
        _PrimaryButton(
          label: 'Continue',
          enabled: _selected != null,
          onTap: _toAcknowledgment,
        ).animate().fadeIn(delay: 640.ms).slideY(begin: 0.1),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildAcknowledgment({required Key key}) {
    final t = OnboardingTheme.of(context);
    final option = _selectedOption ?? _options.first;

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.onboardingAccent.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(option.icon,
              color: AppColors.onboardingAccent, size: 28),
        ).animate().scale(duration: 360.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 18),
        Text(
          'That makes sense.',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: t.textPrimary,
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn(delay: 120.ms).slideY(begin: -0.1),
        const SizedBox(height: 18),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                decoration: BoxDecoration(
                  color: t.cardFill,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: t.borderDefault),
                ),
                child: Text(
                  option.acknowledgment,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: t.textPrimary,
                    letterSpacing: -0.1,
                  ),
                ),
              ).animate().fadeIn(delay: 240.ms).slideY(begin: 0.06),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _PrimaryButton(
          label: "Let's do it",
          enabled: true,
          onTap: _finish,
        ).animate().fadeIn(delay: 360.ms).slideY(begin: 0.1),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// One selectable blocker row.
class _BlockerOptionCard extends StatelessWidget {
  final _BlockerOption option;
  final bool selected;
  final VoidCallback onTap;

  const _BlockerOptionCard({
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
              Icon(option.icon, size: 22, color: t.textSecondary),
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
                  child:
                      Icon(Icons.check_rounded, color: t.checkIcon, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared orange-gradient primary button (dims when disabled).
class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
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
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded,
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
