import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import 'onboarding_experiments.dart';
import 'pre_auth_quiz_data.dart';
import 'weight_projection_screen.dart' show WeightProjectionCalculator;
import 'widgets/onboarding_theme.dart';

import '../../l10n/generated/app_localizations.dart';
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
    // Echo the user's primary (first-picked) "why".
    final whyId = (quiz.primaryWhys != null && quiz.primaryWhys!.isNotEmpty)
        ? quiz.primaryWhys!.first
        : null;
    final why = whyId != null ? _whyPhrases[whyId] : null;
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
                    AppLocalizations.of(context).onboardingReflectHereSWhatWe,
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
                        const SizedBox(height: 18),
                        // "We're building it for you" — an animated trajectory
                        // preview (current → goal) plus a staggered chip cluster
                        // of the inputs the plan is shaped around. Reinforces the
                        // reciprocity beat without adding more prose.
                        _PlanPreview(quiz: quiz)
                            .animate()
                            .fadeIn(delay: 560.ms)
                            .slideY(begin: 0.06),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ReflectContinueButton(onTap: _continue)
                      .animate()
                      .fadeIn(delay: 720.ms)
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
      label: AppLocalizations.of(context).onboardingContinueButton,
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
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context).onboardingContinueButton,
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

/// The "your plan is being built for you" visual under the echo cards.
///
/// When the quiz carries a real weight delta it shows an animated
/// current → goal trajectory curve; otherwise it falls back to the chip
/// cluster alone (no fabricated curve). Either way it ends in a staggered
/// row of chips echoing the inputs the plan is shaped around.
class _PlanPreview extends StatelessWidget {
  final PreAuthQuizData quiz;
  const _PlanPreview({required this.quiz});

  /// Build the trajectory points (0..1 normalized) from the same calculator
  /// the projection screen uses, so the preview matches the real curve.
  List<double>? _normalizedCurve() {
    final cur = quiz.weightKg;
    final goal = quiz.goalWeightKg;
    if (cur == null || goal == null || cur <= 0 || goal <= 0) return null;
    if ((cur - goal).abs() < 0.5) return null; // maintain → no curve

    final goalDate = WeightProjectionCalculator.calculateGoalDate(
      currentWeight: cur,
      goalWeight: goal,
      workoutDaysPerWeek: quiz.daysPerWeek ?? 4,
      weightChangeRate: quiz.weightChangeRate,
    );
    final pts = WeightProjectionCalculator.generateProjectionCurve(
      currentWeight: cur,
      goalWeight: goal,
      goalDate: goalDate,
    );
    if (pts.length < 2) return null;

    // Normalize weights to 0..1 of the (current, goal) span so the painter
    // is unit-agnostic. y=0 sits at the start weight, y=1 at the goal.
    final span = goal - cur;
    if (span.abs() < 1e-6) return null;
    return [for (final p in pts) ((p.weight - cur) / span).clamp(0.0, 1.0)];
  }

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);
    final accent = AppColors.onboardingAccent;
    final curve = _normalizedCurve();
    final losing =
        (quiz.goalWeightKg ?? 0) < (quiz.weightKg ?? 0) && curve != null;

    final chips = _planChips(quiz);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: t.isDark ? 0.10 : 0.07),
            accent.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 16, color: accent),
              const SizedBox(width: 8),
              Text(
                "We're building it around you",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: t.textPrimary,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
          if (curve != null) ...[
            const SizedBox(height: 14),
            RepaintBoundary(
              child: _TrajectorySparkline(
                normalized: curve,
                losing: losing,
                accent: accent,
                trackColor: t.textSecondary.withValues(alpha: 0.18),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < chips.length; i++)
                _GoalChip(icon: chips[i].$1, label: chips[i].$2, accent: accent)
                    .animate()
                    .fadeIn(delay: (700 + i * 90).ms, duration: 320.ms)
                    .scaleXY(begin: 0.85, curve: Curves.easeOutBack),
            ],
          ),
        ],
      ),
    );
  }

  /// (icon, label) pairs for the chip cluster — only chips we actually have
  /// data for. No placeholders.
  List<(IconData, String)> _planChips(PreAuthQuizData quiz) {
    final out = <(IconData, String)>[];
    final goalPhrase =
        _OnboardingReflectScreenState._goalPhrases[quiz.goal];
    if (goalPhrase != null) {
      // Capitalize the verb phrase for chip form ("Build muscle").
      final cap = goalPhrase[0].toUpperCase() + goalPhrase.substring(1);
      out.add((Icons.flag_rounded, cap));
    }
    final days = quiz.daysPerWeek;
    if (days != null && days > 0) {
      out.add((Icons.event_available_rounded,
          '$days ${days == 1 ? 'day' : 'days'}/week'));
    }
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
          final dir = goal < cur ? '−' : '+';
          out.add((Icons.monitor_weight_rounded, '$dir$amt $unit goal'));
        }
      }
    }
    return out;
  }
}

/// A small rounded "input" chip in the plan-preview cluster.
class _GoalChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  const _GoalChip(
      {required this.icon, required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: t.cardFill,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: t.textPrimary,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lightweight animated current → goal trajectory line. Drives a single
/// self-contained controller (isolated from the screen) and draws the curve
/// progressively with a glowing leading dot and a soft gradient fill.
class _TrajectorySparkline extends StatefulWidget {
  /// Normalized weights (0 = start, 1 = goal), already direction-correct.
  final List<double> normalized;
  final bool losing;
  final Color accent;
  final Color trackColor;

  const _TrajectorySparkline({
    required this.normalized,
    required this.losing,
    required this.accent,
    required this.trackColor,
  });

  @override
  State<_TrajectorySparkline> createState() => _TrajectorySparklineState();
}

class _TrajectorySparklineState extends State<_TrajectorySparkline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _draw;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _draw = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    // Start after the card itself has slid in.
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _draw,
        builder: (context, _) => CustomPaint(
          painter: _TrajectoryPainter(
            normalized: widget.normalized,
            progress: _draw.value,
            accent: widget.accent,
            trackColor: widget.trackColor,
          ),
        ),
      ),
    );
  }
}

class _TrajectoryPainter extends CustomPainter {
  final List<double> normalized;
  final double progress;
  final Color accent;
  final Color trackColor;

  _TrajectoryPainter({
    required this.normalized,
    required this.progress,
    required this.accent,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (normalized.length < 2) return;

    const padX = 10.0;
    const padTop = 12.0;
    const padBottom = 12.0;
    final w = size.width - padX * 2;
    final h = size.height - padTop - padBottom;

    // Map normalized progress (0=start weight, 1=goal weight) to a y where the
    // START sits visually high-ish and the GOAL lands at the opposite end, so
    // the line always *descends toward* the goal for a loss and *rises toward*
    // it for a gain — reads as forward motion either way.
    Offset pointAt(int i) {
      final x = padX + w * (i / (normalized.length - 1));
      final n = normalized[i]; // 0..1 toward goal
      // For losing: start high (y small), goal low isn't ideal visually; we
      // want a calm downward slope. yFrac: 0 → top region, 1 → bottom region.
      final yFrac = 0.15 + 0.7 * n;
      final y = padTop + h * yFrac;
      return Offset(x, y);
    }

    // Build a smooth path through all points (Catmull-Rom-ish via quadratic).
    final fullPath = Path();
    final pts = [for (var i = 0; i < normalized.length; i++) pointAt(i)];
    fullPath.moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = pts[i];
      final p1 = pts[i + 1];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      fullPath.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
    fullPath.lineTo(pts.last.dx, pts.last.dy);

    // Faint full-length track (the "destination" the line is filling in).
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawPath(fullPath, trackPaint);

    // Progressive reveal via PathMetric.
    final metrics = fullPath.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final drawLen = metric.length * progress.clamp(0.0, 1.0);
    final drawnPath = metric.extractPath(0, drawLen);

    // Gradient fill under the drawn portion.
    final tangent = metric.getTangentForOffset(drawLen);
    final headPoint = tangent?.position ?? pts.first;
    final fillPath = Path.from(drawnPath)
      ..lineTo(headPoint.dx, size.height - padBottom)
      ..lineTo(pts.first.dx, size.height - padBottom)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accent.withValues(alpha: 0.22),
          accent.withValues(alpha: 0.0),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(fillPath, fillPaint);

    // The accent line itself.
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        colors: [accent, const Color(0xFFEA580C)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(drawnPath, linePaint);

    // Start anchor dot.
    canvas.drawCircle(
      pts.first,
      3.5,
      Paint()..color = trackColor.withValues(alpha: 0.9),
    );

    // Glowing leading head dot.
    canvas.drawCircle(
      headPoint,
      8,
      Paint()
        ..color = accent.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(headPoint, 4.5, Paint()..color = accent);
    canvas.drawCircle(
      headPoint,
      4.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );

    // Goal flag marker once the line is essentially complete.
    if (progress > 0.92) {
      final goalAlpha = ((progress - 0.92) / 0.08).clamp(0.0, 1.0);
      final goalPt = pts.last;
      canvas.drawCircle(
        goalPt,
        9 + 3 * (1 - goalAlpha),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = accent.withValues(alpha: 0.6 * goalAlpha),
      );
    }
  }

  @override
  bool shouldRepaint(_TrajectoryPainter old) =>
      old.progress != progress ||
      old.normalized != normalized ||
      old.accent != accent;
}
