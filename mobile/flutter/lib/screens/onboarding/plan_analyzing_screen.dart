import 'dart:async';
import 'dart:math' as math;

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

              // Slim progress bar tied to the step sequence, with a live
              // shimmer sweep racing across the filled portion so the bar
              // reads as actively "assembling", not just statically filling.
              _ShimmerProgressBar(
                progress: ((_currentStep) / _steps.length).clamp(0.06, 1.0),
                isDark: isDark,
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

class _StepRow extends StatefulWidget {
  final _AnalysisStep step;
  final _StepState state;
  final bool isDark;
  const _StepRow(
      {required this.step, required this.state, required this.isDark});

  @override
  State<_StepRow> createState() => _StepRowState();
}

class _StepRowState extends State<_StepRow> with TickerProviderStateMixin {
  // Drives the slow continuous spin + glow breathe while the row is active.
  late final AnimationController _activeCtrl;
  // Fires once when the row flips to done → drives the green check pop +
  // the radial spark burst.
  late final AnimationController _burstCtrl;

  @override
  void initState() {
    super.initState();
    _activeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _burstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    if (widget.state == _StepState.active) _activeCtrl.repeat();
    if (widget.state == _StepState.done) _burstCtrl.value = 1;
  }

  @override
  void didUpdateWidget(covariant _StepRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state != oldWidget.state) {
      if (widget.state == _StepState.active) {
        _activeCtrl.repeat();
      } else {
        _activeCtrl.stop();
      }
      // Trigger the spark burst on the idle/active → done transition.
      if (widget.state == _StepState.done &&
          oldWidget.state != _StepState.done) {
        _burstCtrl.forward(from: 0);
        HapticFeedback.selectionClick();
      }
    }
  }

  @override
  void dispose() {
    _activeCtrl.dispose();
    _burstCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final step = widget.step;
    final state = widget.state;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final isDone = state == _StepState.done;
    final isActive = state == _StepState.active;
    final isIdle = state == _StepState.idle;

    const doneColor = Color(0xFF2ECC71);
    final accentColor = isDone ? doneColor : AppColors.onboardingAccent;
    final iconBg = isIdle
        ? (isDark ? AppColors.elevated : AppColorsLight.elevated)
        : accentColor.withValues(alpha: 0.15);

    final row = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? AppColors.onboardingAccent.withValues(alpha: 0.55)
              : (isDone
                  ? doneColor.withValues(alpha: 0.35)
                  : (isDark
                      ? AppColors.cardBorder
                      : AppColorsLight.cardBorder)),
          width: isActive ? 1.6 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.onboardingAccent.withValues(alpha: 0.22),
                  blurRadius: 18,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Icon medallion — spins + glow-breathes while active, pops a
          // radial spark burst the instant it flips to done.
          SizedBox(
            width: 36,
            height: 36,
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: Listenable.merge([_activeCtrl, _burstCtrl]),
                builder: (_, __) {
                  final glow = isActive
                      ? 0.25 + (math.sin(_activeCtrl.value * math.pi * 2) +
                                  1) /
                              2 *
                              0.35
                      : 0.0;
                  return CustomPaint(
                    painter: _SparkBurstPainter(
                      progress: _burstCtrl.value,
                      color: doneColor,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: iconBg,
                        shape: BoxShape.circle,
                        boxShadow: glow > 0
                            ? [
                                BoxShadow(
                                  color: AppColors.onboardingAccent
                                      .withValues(alpha: glow),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: isDone
                            ? Transform.scale(
                                // Overshoot pop as the check lands.
                                scale: 0.6 +
                                    Curves.elasticOut
                                            .transform(_burstCtrl.value) *
                                        0.4,
                                child: const Icon(Icons.check_rounded,
                                    color: doneColor, size: 20),
                              )
                            : (isActive
                                ? Transform.rotate(
                                    angle: _activeCtrl.value * math.pi * 2,
                                    child: Icon(step.icon,
                                        color: AppColors.onboardingAccent,
                                        size: 18),
                                  )
                                : Icon(step.icon,
                                    color: isDark
                                        ? AppColors.textMuted
                                        : AppColorsLight.textMuted,
                                    size: 18)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _CountUpLabel(
              // v7 receipts read as terminal output — Space Mono is already
              // bundled for shareables. Embedded numbers tick up as the row
              // activates so the receipt feels computed, not pre-printed.
              label: step.label,
              animateNumbers: isActive || isDone,
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
    );

    // Dramatic reveal: idle rows sit dim + nudged down; activation slides
    // them up, scales past 1, and fades the label in.
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 350),
      opacity: isIdle ? 0.45 : 1.0,
      child: row
          .animate(target: isIdle ? 0 : 1)
          .slideX(begin: 0.04, end: 0, duration: 320.ms, curve: Curves.easeOut)
          .scaleXY(
              begin: 0.97,
              end: 1,
              duration: 320.ms,
              curve: Curves.easeOutBack),
    );
  }
}

/// Renders a label whose embedded numeric tokens (e.g. "1,700+", "178 cm",
/// "4 days") tick up from zero to their final value as the row activates.
/// Non-numeric labels render statically — never invents or mangles copy.
class _CountUpLabel extends StatefulWidget {
  final String label;
  final bool animateNumbers;
  final TextStyle style;
  const _CountUpLabel({
    required this.label,
    required this.animateNumbers,
    required this.style,
  });

  @override
  State<_CountUpLabel> createState() => _CountUpLabelState();
}

class _CountUpLabelState extends State<_CountUpLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  // Matches integers with optional thousands separators: 1,700 / 178 / 4.
  static final RegExp _numberRe = RegExp(r'\d[\d,]*');

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.animateNumbers) _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant _CountUpLabel old) {
    super.didUpdateWidget(old);
    if (widget.animateNumbers && !old.animateNumbers) _ctrl.forward(from: 0);
    if (widget.label != old.label && widget.animateNumbers) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _render(double t) {
    if (!_numberRe.hasMatch(widget.label)) return widget.label;
    return widget.label.replaceAllMapped(_numberRe, (m) {
      final raw = m.group(0)!;
      final target = int.tryParse(raw.replaceAll(',', ''));
      if (target == null) return raw;
      final current = (target * t).round();
      // Preserve the original thousands-separator formatting.
      final hadComma = raw.contains(',');
      return hadComma ? _withThousands(current) : current.toString();
    });
  }

  String _withThousands(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animateNumbers) {
      return Text(widget.label, style: widget.style);
    }
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = Curves.easeOutCubic.transform(_ctrl.value);
        return Text(_render(t), style: widget.style);
      },
    );
  }
}

/// Radial spark burst painted behind the icon medallion the instant a step
/// flips to done. Fades + expands outward over [progress] 0→1.
class _SparkBurstPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _SparkBurstPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final center = size.center(Offset.zero);
    final maxR = size.width * 0.95;
    const sparks = 8;
    final eased = Curves.easeOut.transform(progress);
    final opacity = (1 - progress).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < sparks; i++) {
      final angle = (i / sparks) * math.pi * 2;
      final inner = size.width * 0.4 + eased * maxR * 0.3;
      final outer = inner + (8 + eased * 10);
      final dir = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(center + dir * inner, center + dir * outer, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkBurstPainter old) =>
      old.progress != progress || old.color != color;
}

/// Slim progress bar with a continuous shimmer highlight sweeping across the
/// filled portion — reads as active assembly rather than a static fill.
class _ShimmerProgressBar extends StatefulWidget {
  final double progress;
  final bool isDark;
  const _ShimmerProgressBar({required this.progress, required this.isDark});

  @override
  State<_ShimmerProgressBar> createState() => _ShimmerProgressBarState();
}

class _ShimmerProgressBarState extends State<_ShimmerProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Container(
          height: 5,
          color: widget.isDark
              ? const Color(0xFF1A1A1D)
              : AppColorsLight.elevated,
          child: AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            alignment: AlignmentDirectional.centerStart,
            widthFactor: widget.progress,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, child) {
                return ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (rect) {
                    // A bright band travelling left→right across the fill.
                    final t = _ctrl.value;
                    return LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: const [
                        Colors.transparent,
                        Colors.white,
                        Colors.transparent,
                      ],
                      stops: [
                        (t - 0.18).clamp(0.0, 1.0),
                        t.clamp(0.0, 1.0),
                        (t + 0.18).clamp(0.0, 1.0),
                      ],
                    ).createShader(rect);
                  },
                  child: child,
                );
              },
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
      ),
    );
  }
}

class _PulsingAiOrb extends StatefulWidget {
  @override
  State<_PulsingAiOrb> createState() => _PulsingAiOrbState();
}

class _PulsingAiOrbState extends State<_PulsingAiOrb>
    with TickerProviderStateMixin {
  // Slow breathe for the glow + brand-mark scale.
  late final AnimationController _breathe;
  // Continuous rotation for the orbiting accent ring + travelling spark.
  late final AnimationController _orbit;

  @override
  void initState() {
    super.initState();
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
  }

  @override
  void dispose() {
    _breathe.dispose();
    _orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: 140,
        height: 140,
        child: AnimatedBuilder(
          animation: Listenable.merge([_breathe, _orbit]),
          builder: (_, __) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Orbiting accent ring + a single spark travelling around it,
                // giving the hero a sense of the AI "working" around the mark.
                CustomPaint(
                  size: const Size(140, 140),
                  painter: _OrbitRingPainter(
                    angle: _orbit.value * math.pi * 2,
                    breathe: _breathe.value,
                  ),
                ),
                // Zealova brand mark — the asset already has its own rounded
                // squircle, so wrapping it in another white circle produced a
                // visible "icon-inside-a-container" stack. Render the icon
                // directly with just the brand-orange glow breathing behind it.
                Transform.scale(
                  scale: 0.97 + (_breathe.value * 0.06),
                  child: Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.onboardingAccent
                              .withValues(alpha: 0.35 + (_breathe.value * 0.25)),
                          blurRadius: 28 + (_breathe.value * 16),
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
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Rotating dashed accent ring with one bright travelling spark, drawn around
/// the hero brand mark to signal active AI work.
class _OrbitRingPainter extends CustomPainter {
  final double angle;
  final double breathe;
  const _OrbitRingPainter({required this.angle, required this.breathe});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.46;

    // Faint full ring.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = AppColors.onboardingAccent.withValues(alpha: 0.18),
    );

    // A glowing arc that sweeps around with the rotation.
    final sweepPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: angle,
        endAngle: angle + math.pi,
        colors: [
          AppColors.onboardingAccent.withValues(alpha: 0.0),
          AppColors.onboardingAccent.withValues(alpha: 0.85),
        ],
        transform: GradientRotation(angle),
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      angle,
      math.pi * 0.55,
      false,
      sweepPaint,
    );

    // Bright travelling spark dot at the leading edge of the arc.
    final sparkAngle = angle + math.pi * 0.55;
    final spark =
        center + Offset(math.cos(sparkAngle), math.sin(sparkAngle)) * radius;
    canvas.drawCircle(
      spark,
      3 + breathe * 1.2,
      Paint()
        ..color = AppColors.orange
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawCircle(
      spark,
      2.2,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitRingPainter old) =>
      old.angle != angle || old.breathe != breathe;
}
