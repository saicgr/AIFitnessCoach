import 'dart:math' as math;

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
import 'widgets/quiz_progress_bar.dart';
import '../../widgets/glass_back_button.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../core/theme/accent_color_provider.dart';
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
  // Every colour below is one of AppColors' documented categorical hues
  // (never an ad-hoc literal) so this list stays a real semantic palette
  // instead of accumulating one-off hex values screen by screen. 'event'
  // and 'health' used to both render as near-identical reds — moved to
  // magenta vs red so adjacent rows read as distinct at a glance.
  static const List<_WhyOption> _options = [
    _WhyOption('feel_confident', 'Feel confident in my body',
        Icons.spa_rounded, AppColors.purple),  // accent-allowlist: categorical per-option palette - each 'why' option needs a distinct colour for visual scanning; recolouring collapses the distinction
    _WhyOption('keep_up', 'Keep up with my family',
        Icons.family_restroom_rounded, AppColors.info),  // accent-allowlist: informational state - same value as AppColors.info / AppColors.waterBlue
    _WhyOption('event', 'Get ready for an event',
        Icons.celebration_rounded, AppColors.magenta),  // accent-allowlist: categorical per-option palette - each 'why' option needs a distinct colour for visual scanning; recolouring collapses the distinction
    _WhyOption('health', 'A health wake-up call',
        Icons.monitor_heart_rounded, AppColors.red),  // accent-allowlist: error/destructive - same value as AppColors.error
    _WhyOption('feel_strong', 'Feel strong and capable',
        Icons.bolt_rounded, AppColors.warning),  // accent-allowlist: warning severity - same value as AppColors.warning (dark theme)
    _WhyOption('energy', 'More energy, less stress',
        Icons.wb_sunny_rounded, AppColors.cyan),  // accent-allowlist: categorical per-option palette - each 'why' option needs a distinct colour for visual scanning; recolouring collapses the distinction
  ];

  // Multi-select: people are usually driven by more than one reason. All picks
  // are saved + fed to the AI coach so it can speak to every motivation.
  final Set<String> _selected = {};

  /// This screen is step 0 of the funnel: itself, then the 11-question
  /// pre-auth quiz. Matches `QuizHeader`'s "~N min left" estimate (~15s per
  /// question) so the progress affordance doesn't reset or disappear at the
  /// boundary between this screen and the next one — the two used to show
  /// no progress bar / no estimate here, then a 10-segment bar + "~3 min
  /// left" one tap later, with no visible relationship between them.
  static const int _totalFunnelSteps = 12;
  int get _minutesLeft =>
      math.max(1, (_totalFunnelSteps * 15 / 60).ceil());

  @override
  void initState() {
    super.initState();
    // Prefill for a returning user replaying onboarding.
    _selected.addAll(ref.read(preAuthQuizProvider).primaryWhys ?? const []);
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
    setState(() {
      if (!_selected.add(id)) _selected.remove(id);
    });
  }

  Future<void> _continue() async {
    if (_selected.isEmpty) return;
    HapticFeedback.mediumImpact();
    final picks = _selected.toList();
    await ref.read(preAuthQuizProvider.notifier).setPrimaryWhys(picks);
    ref.read(posthogServiceProvider).capture(
      eventName: 'onboarding_why_answered',
      properties: {'whys': picks},
    );
    if (mounted) context.push('/pre-auth-quiz');
  }

  Future<void> _skip() async {
    HapticFeedback.lightImpact();
    // Clear any stale value so a skipped screen does not leave a why on file.
    await ref.read(preAuthQuizProvider.notifier).setPrimaryWhys(const []);
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
                  // Back affordance + section kicker on ONE line.
                  //
                  // This screen used to stack them — GlassBackButton on its own
                  // row, "FIRST, THE WHY" beneath it — which is not what the
                  // rest of onboarding does. The shared `quiz_header.dart` puts
                  // the back button and its accent label in a single `Row`
                  // (`:65-80`), so every quiz step reads as one header band
                  // while this screen read as two stacked ones. Matching the
                  // shared pattern also gives ~20pt back to the content, which
                  // matters on a screen with six options and a sticky footer.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GlassBackButton(onTap: _back),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)
                              .onboardingWhyFirstTheWhy,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6,
                            color: t.accent,
                          ),
                        ),
                      ),
                      // Time-remaining estimate, matching QuizHeader's
                      // "~N min left" exactly (same copy, same style) so the
                      // progress affordance carries across the screen
                      // boundary instead of appearing out of nowhere on the
                      // very next screen.
                      Text(
                        AppLocalizations.of(context).quizMinutesLeft(_minutesLeft),
                        style: TextStyle(
                          color: t.accent,
                          fontFamily: 'Barlow Condensed',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(),
                  const SizedBox(height: 12),
                  QuizProgressBar(
                    progress: 1 / _totalFunnelSteps,
                    segments: _totalFunnelSteps,
                    currentStep: 0,
                    padding: EdgeInsets.zero,
                  ).animate().fadeIn(),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context).onboardingWhyWhatSDrivingThis,
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
                    "We'll keep it in sight as you go. Pick all that apply.",
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
                          selected: _selected.contains(o.id),
                          onTap: () => _select(o.id),
                        )
                            .animate()
                            .fadeIn(delay: (240 + i * 70).ms)
                            .slideX(begin: 0.05, duration: 320.ms);
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Reason line for the disabled CTA — fixed-height slot so
                  // the button never shifts as picks are made/cleared.
                  // Mirrors `QuizContinueButton`'s hint row so every
                  // pre-auth screen explains a disabled Continue instead of
                  // just greying it out.
                  SizedBox(
                    height: 20,
                    child: _selected.isEmpty
                        ? Row(
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  size: 13, color: t.textMuted),
                              const SizedBox(width: 6),
                              Text(
                                'Pick at least one reason to continue',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: t.textMuted,
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 6),
                  _ContinueButton(
                    enabled: _selected.isNotEmpty,
                    onTap: _continue,
                  ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1),
                  const SizedBox(height: 4),
                  Center(
                    child: TextButton(
                      onPressed: _skip,
                      child: Text(
                        AppLocalizations.of(context).onboardingSkip,
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: option.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(option.icon, color: option.color, size: 16),
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
              // Square (rounded-corner) checkbox — this screen is
              // multi-select (people pick every reason that applies), so
              // the target shape must read as a checkbox, not the
              // single-select radio circle.
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selected ? t.checkBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: selected
                      ? null
                      : Border.all(color: t.checkBorderUnselected, width: 2),
                ),
                child: selected
                    ? Icon(Icons.check_rounded, color: t.checkIcon, size: 14)
                    : null,
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
    final t = OnboardingTheme.of(context);
    return Semantics(
      button: true,
      enabled: enabled,
      label: AppLocalizations.of(context).onboardingContinueButton,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        // A flat opacity fade over BOTH fill and text used to read as
        // "enabled but broken" — a half-transparent orange button with
        // washed-out white text — rather than a deliberate disabled state.
        // Swapping to the same solid inert tokens the quiz Continue button
        // uses (`t.cardFill` / `t.textDisabled`) makes "waiting on you"
        // unambiguous.
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: enabled
                ? LinearGradient(
                    colors: [AppColors.onboardingAccent, context.accentColor],
                  )
                : null,
            color: enabled ? null : t.cardFill,
            borderRadius: BorderRadius.circular(16),
            border: enabled ? null : Border.all(color: t.borderSubtle),
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
                  AppLocalizations.of(context).onboardingContinueButton,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: enabled ? Colors.white : t.textDisabled,
                    letterSpacing: 0.3,
                  ),
                ),
                if (enabled) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
