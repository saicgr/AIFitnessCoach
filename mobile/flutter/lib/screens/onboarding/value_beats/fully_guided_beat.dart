import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/onboarding_theme.dart';
import '_value_beat_scaffold.dart';

/// Value beat: "Your workouts, fully guided."
///
/// A non-input reward screen shown between quiz questions. Pairs a simple
/// phone mockup (rendered in-code — no asset dependency) with three checkmark
/// bullets reassuring the user that every exercise comes with guidance.
///
/// Returns just a [Padding]/[Column] body — the host quiz scaffold provides the
/// [OnboardingBackground] + [Scaffold]. Brand-orange CTA via [onContinue].
class FullyGuidedBeat extends StatelessWidget {
  /// Advances the funnel to the next quiz step.
  final VoidCallback onContinue;

  const FullyGuidedBeat({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: _PhoneMockup(t: t)
                        .animate()
                        .fadeIn(delay: 150.ms)
                        .scale(begin: const Offset(0.9, 0.9)),
                  ),
                  const SizedBox(height: 28),
                  const ValueBeatHeadline(
                    headline: 'Your workouts, fully guided.',
                    supporting:
                        'No guesswork. Every set tells you exactly what to do.',
                  ),
                  const SizedBox(height: 28),
                  ...[
                    const ValueBeatCheckBullet(
                      title: 'Clear guidance for every exercise',
                    ),
                    const ValueBeatCheckBullet(
                      title: 'Step-by-step instructions + proper form',
                    ),
                    const ValueBeatCheckBullet(
                      title: 'Confidence tailored to your level',
                    ),
                  ].animateBullets(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ValueBeatContinueButton(onContinue: onContinue)
              .animate()
              .fadeIn(delay: 600.ms)
              .slideY(begin: 0.1),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// A lightweight phone mockup drawn entirely in-code so the beat carries no
/// asset dependency. Shows a stylized "active workout" card with an exercise
/// thumbnail block, a set/rep line, and a couple of guidance rows.
class _PhoneMockup extends StatelessWidget {
  final OnboardingTheme t;

  const _PhoneMockup({required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 188,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: t.isDark ? const Color(0xFF0C0C0E) : Colors.white,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: t.borderDefault, width: 6),
        boxShadow: [
          BoxShadow(
            color: t.accent.withValues(alpha: 0.18),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          color: t.cardFill,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exercise thumbnail block.
              Container(
                height: 96,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      t.accent.withValues(alpha: 0.35),
                      t.accent.withValues(alpha: 0.12),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.fitness_center_rounded,
                    size: 34,
                    color: t.accent,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _line(width: 110, height: 11, color: t.textPrimary),
              const SizedBox(height: 8),
              Row(
                children: [
                  _pill('3 × 10', t.accent),
                  const SizedBox(width: 6),
                  _pill('45 kg', t.textSecondary),
                ],
              ),
              const SizedBox(height: 12),
              _guidanceRow(t),
              const SizedBox(height: 8),
              _guidanceRow(t),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line({
    required double width,
    required double height,
    required Color color,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _guidanceRow(OnboardingTheme t) {
    return Row(
      children: [
        Icon(Icons.check_circle_rounded, size: 14, color: t.accent),
        const SizedBox(width: 8),
        _line(width: 88, height: 8, color: t.textSecondary),
      ],
    );
  }
}

/// Staggers a list of bullets with a consistent fade/slide cadence.
extension _BulletAnimation on List<Widget> {
  List<Widget> animateBullets() {
    final out = <Widget>[];
    for (var i = 0; i < length; i++) {
      out.add(
        this[i]
            .animate()
            .fadeIn(delay: (300 + i * 120).ms)
            .slideX(begin: -0.06),
      );
      if (i != length - 1) out.add(const SizedBox(height: 18));
    }
    return out;
  }
}
