import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/onboarding_theme.dart';
import '_value_beat_scaffold.dart';

/// Value beat: "Your plan is ready" — a celebration moment shown right before
/// the plan reveal.
///
/// Big headline + a sub-stat line computed from [daysPerWeek] (e.g. "3
/// days/week = 12 planned workouts/month") and a subtle scale-in flourish with
/// a few painted confetti shards. No emoji — Material vibe only.
///
/// Returns just a [Padding]/[Column] body — the host quiz scaffold provides the
/// [OnboardingBackground] + [Scaffold].
class PlanReadyBeat extends StatelessWidget {
  /// Advances the funnel into the plan reveal.
  final VoidCallback onContinue;

  /// Training days per week the user picked — drives the sub-stat line.
  final int daysPerWeek;

  const PlanReadyBeat({
    super.key,
    required this.onContinue,
    required this.daysPerWeek,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: PlanReadyFlair(daysPerWeek: daysPerWeek),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ValueBeatContinueButton(
            onContinue: onContinue,
            label: 'See my plan',
          ).animate().fadeIn(delay: 650.ms).slideY(begin: 0.1),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// The celebration visual — seal + confetti + "Your plan is ready" + the
/// "N days/week = M workouts/month" stat pill — without any scaffold or button.
///
/// Reusable so the weight-projection reveal can drop in the same celebration
/// inline (upgrading its plain "plan is ready" line) WITHOUT a duplicate screen.
/// [compact] shrinks the seal and drops the confetti for embedding alongside
/// other content; [showHeadline] hides the big headline when the host screen
/// already carries one.
class PlanReadyFlair extends StatelessWidget {
  final int daysPerWeek;
  final bool compact;
  final bool showHeadline;

  const PlanReadyFlair({
    super.key,
    required this.daysPerWeek,
    this.compact = false,
    this.showHeadline = true,
  });

  /// "N days/week = M planned workouts/month" using a 4-week month. Guards a
  /// sane 1..7 range so the copy never reads oddly.
  String get _subStat {
    final days = daysPerWeek.clamp(1, 7);
    final perMonth = days * 4;
    final dayWord = days == 1 ? 'day' : 'days';
    return '$days $dayWord/week = $perMonth planned workouts/month';
  }

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);
    final sealBox = compact ? 64.0 : 132.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: sealBox,
          width: sealBox,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (!compact)
                _Confetti(t: t)
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 150.ms),
              _Seal(t: t, size: compact ? 52 : 88)
                  .animate()
                  .scale(
                    begin: const Offset(0.4, 0.4),
                    end: const Offset(1, 1),
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 250.ms),
            ],
          ),
        ),
        if (showHeadline) ...[
          const SizedBox(height: 28),
          Text(
            'Your plan is ready',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              height: 1.15,
              color: t.textPrimary,
            ),
          ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
        ],
        SizedBox(height: compact ? 14 : 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: t.badgeBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: t.accent.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Text(
            _subStat,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: t.accent,
            ),
          ),
        ).animate().fadeIn(delay: 500.ms).scale(begin: const Offset(0.9, 0.9)),
      ],
    );
  }
}

/// The orange "check seal" at the center of the celebration.
class _Seal extends StatelessWidget {
  final OnboardingTheme t;
  final double size;

  const _Seal({required this.t, this.size = 88});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: t.buttonGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: t.accent.withValues(alpha: 0.45),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(Icons.check_rounded, size: size * 0.55, color: t.buttonText),
    );
  }
}

/// A few painted confetti shards radiating from the seal. Deterministic layout
/// (no randomness at build time) so it reads the same on every rebuild.
class _Confetti extends StatelessWidget {
  final OnboardingTheme t;

  const _Confetti({required this.t});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(132, 132),
      painter: _ConfettiPainter(
        primary: t.accent,
        secondary: t.textMuted,
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final Color primary;
  final Color secondary;

  _ConfettiPainter({required this.primary, required this.secondary});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const count = 12;
    const innerR = 48.0;
    const outerR = 64.0;

    for (var i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi;
      final color = i.isEven ? primary : secondary;
      final start = center +
          Offset(math.cos(angle) * innerR, math.sin(angle) * innerR);
      final end = center +
          Offset(math.cos(angle) * outerR, math.sin(angle) * outerR);

      final paint = Paint()
        ..color = color.withValues(alpha: i.isEven ? 0.9 : 0.5)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) =>
      old.primary != primary || old.secondary != secondary;
}
