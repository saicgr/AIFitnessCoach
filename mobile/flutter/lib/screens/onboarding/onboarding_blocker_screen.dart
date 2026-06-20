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

import '../../l10n/generated/app_localizations.dart';
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
  // 3 concrete "how the plan carries this" points (icon + short line) shown
  // under the acknowledgment so the lower half reads as substance, not space.
  final List<(IconData, String)> supports;
  const _BlockerOption(
      this.id, this.label, this.icon, this.acknowledgment, this.supports);
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
      [
        (Icons.event_available_rounded, 'Locked to the days & length you chose'),
        (Icons.autorenew_rounded, 'Miss one? The week reshapes — no pileup'),
        (Icons.bolt_rounded, 'Sessions trimmed to fit, never padded'),
      ],
    ),
    _BlockerOption(
      'lost_motivation',
      'I lost motivation',
      Icons.battery_2_bar_rounded,
      'Motivation comes and goes for everyone. That is why the plan runs '
          'on a set schedule and small weekly wins, so showing up does not '
          'depend on feeling motivated that day.',
      [
        (Icons.event_repeat_rounded, 'Set schedule — no daily willpower call'),
        (Icons.emoji_events_rounded, 'Small weekly wins you can actually see'),
        (Icons.local_fire_department_rounded,
            'Streaks keep momentum on the low days'),
      ],
    ),
    _BlockerOption(
      'no_results',
      "I wasn't seeing results",
      Icons.trending_flat_rounded,
      'No results usually means the plan stopped progressing. Yours adds '
          'a little every week with progressive overload, and the coach '
          'changes course when something stalls.',
      [
        (Icons.trending_up_rounded, 'Progressive overload adds a little weekly'),
        (Icons.alt_route_rounded, 'Coach changes course the moment you stall'),
        (Icons.insights_rounded, 'Every lift tracked — progress in numbers'),
      ],
    ),
    _BlockerOption(
      'unsure',
      "I didn't know what to do",
      Icons.help_outline_rounded,
      'Not knowing what to do is a real wall. Every session here is laid '
          'out for you, with form guidance on each move, so there is no '
          'guesswork before you start.',
      [
        (Icons.checklist_rounded, 'Every set & rep laid out before you start'),
        (Icons.play_circle_outline_rounded, 'Form cues on each move'),
        (Icons.chat_bubble_outline_rounded, 'Ask the coach anything, anytime'),
      ],
    ),
    _BlockerOption(
      'injury',
      'I got injured or burned out',
      Icons.healing_rounded,
      'Injury and burnout are setbacks, not the end. Your plan works '
          'around the limitations you told us about and builds intensity '
          'gradually instead of all at once.',
      [
        (Icons.shield_outlined, 'Works around the areas you flagged'),
        (Icons.trending_up_rounded, 'Builds intensity gradually, not all at once'),
        (Icons.swap_horiz_rounded, 'Swaps any move that aggravates it'),
      ],
    ),
    _BlockerOption(
      'first_time',
      'This is my first real attempt',
      Icons.flag_rounded,
      'A first real attempt is a strong place to begin. The plan meets '
          'you where you are today and builds up slowly, so nothing about '
          'week one is overwhelming.',
      [
        (Icons.spa_rounded, 'Starts exactly where you are today'),
        (Icons.stairs_rounded, 'Builds up slowly — week one is easy'),
        (Icons.flag_rounded, 'One clear next step, every day'),
      ],
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
          AppLocalizations.of(context).onboardingBlockerWhatSHeldYou,
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: t.textPrimary,
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn().slideY(begin: -0.1),
        const SizedBox(height: 6),
        Text(
          AppLocalizations.of(context).onboardingBlockerNoJudgmentKnowingThe,
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
          label: AppLocalizations.of(context).onboardingContinueButton,
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
        // Focal animated emblem — the per-blocker icon inside a living orbit
        // of pulsing rings + a slow sweep, signalling "your plan handles this".
        Center(
          child: RepaintBoundary(
            child: _AcknowledgmentEmblem(
              icon: option.icon,
              accent: AppColors.onboardingAccent,
            ),
          ),
        ).animate().fadeIn(duration: 420.ms).scaleXY(
              begin: 0.7,
              curve: Curves.easeOutBack,
              duration: 480.ms,
            ),
        const SizedBox(height: 22),
        Text(
          AppLocalizations.of(context).onboardingBlockerThatMakesSense,
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: t.textPrimary,
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn(delay: 160.ms).slideY(begin: -0.1),
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
              ).animate().fadeIn(delay: 280.ms).slideY(begin: 0.06),
              const SizedBox(height: 14),
              // Reassurance strip — a quiet "the plan carries this for you"
              // line with a softly breathing shield so the lower half is alive.
              _PlanHandlesStrip(accent: AppColors.onboardingAccent)
                  .animate()
                  .fadeIn(delay: 440.ms)
                  .slideY(begin: 0.06),
              const SizedBox(height: 24),
              // 3 concrete "how your plan carries this" points — fills the
              // lower half with substance instead of empty space.
              Text(
                'HOW YOUR PLAN CARRIES THIS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: t.textSecondary,
                ),
              ).animate().fadeIn(delay: 520.ms),
              const SizedBox(height: 12),
              for (int i = 0; i < option.supports.length; i++) ...[
                _SupportRow(
                  icon: option.supports[i].$1,
                  text: option.supports[i].$2,
                  accent: AppColors.onboardingAccent,
                ).animate().fadeIn(delay: (580 + i * 90).ms).slideX(begin: 0.05),
                if (i != option.supports.length - 1)
                  const SizedBox(height: 10),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _PrimaryButton(
          label: AppLocalizations.of(context).onboardingBlockerLetSDoIt,
          enabled: true,
          onTap: _finish,
        ).animate().fadeIn(delay: 560.ms).slideY(begin: 0.1),
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

/// Focal animated emblem for the acknowledgment stage. The chosen blocker
/// icon sits in a soft orange tile, ringed by two slow-pulsing halos and a
/// single dot that orbits once per ~6s — a calm "the plan has this handled"
/// motif. One controller drives everything; isolated by a RepaintBoundary.
class _AcknowledgmentEmblem extends StatefulWidget {
  final IconData icon;
  final Color accent;
  const _AcknowledgmentEmblem({required this.icon, required this.accent});

  @override
  State<_AcknowledgmentEmblem> createState() => _AcknowledgmentEmblemState();
}

class _AcknowledgmentEmblemState extends State<_AcknowledgmentEmblem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = 116.0;
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _EmblemPainter(
              t: _controller.value,
              accent: widget.accent,
            ),
            child: child,
          );
        },
        // The icon tile is static (child not rebuilt each tick).
        child: Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.accent.withValues(alpha: 0.22),
                  widget.accent.withValues(alpha: 0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: widget.accent.withValues(alpha: 0.35)),
            ),
            child: Icon(widget.icon, color: widget.accent, size: 28),
          ),
        ),
      ),
    );
  }
}

class _EmblemPainter extends CustomPainter {
  /// 0..1 loop position.
  final double t;
  final Color accent;

  _EmblemPainter({required this.t, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.width / 2;

    // Two breathing halos, phase-offset so one is always expanding while the
    // other fades — a continuous gentle pulse with no hard reset.
    for (var i = 0; i < 2; i++) {
      final phase = (t + i * 0.5) % 1.0;
      final r = 30 + maxR * 0.7 * phase;
      final alpha = (1 - phase) * 0.28;
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = accent.withValues(alpha: alpha),
      );
    }

    // Static guide ring the orbit dot rides on.
    final orbitR = maxR * 0.74;
    canvas.drawCircle(
      center,
      orbitR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = accent.withValues(alpha: 0.14),
    );

    // Single orbiting dot (with a soft glow) sweeping the guide ring.
    final angle = t * 2 * math.pi - math.pi / 2;
    final dot = Offset(
      center.dx + orbitR * math.cos(angle),
      center.dy + orbitR * math.sin(angle),
    );
    canvas.drawCircle(
      dot,
      6,
      Paint()
        ..color = accent.withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(dot, 3, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(_EmblemPainter old) =>
      old.t != t || old.accent != accent;
}

/// One "how your plan carries this" point — accent icon puck + concise line.
class _SupportRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color accent;
  const _SupportRow(
      {required this.icon, required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.3,
              fontWeight: FontWeight.w600,
              color: t.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// A quiet reassurance strip with a softly breathing shield icon. Reinforces
/// "your plan carries this" without adding more body copy to the card.
class _PlanHandlesStrip extends StatelessWidget {
  final Color accent;
  const _PlanHandlesStrip({required this.accent});

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: t.isDark ? 0.08 : 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user_rounded, size: 20, color: accent)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(
                begin: 1.0,
                end: 1.14,
                duration: 1600.ms,
                curve: Curves.easeInOut,
              ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your plan already accounts for this — no extra willpower required.',
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: t.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
