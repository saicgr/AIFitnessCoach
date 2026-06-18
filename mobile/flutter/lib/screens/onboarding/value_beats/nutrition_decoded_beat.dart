import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/onboarding_theme.dart';
import '_value_beat_scaffold.dart';

/// Value beat: "Your nutrition, decoded."
///
/// The nutrition-half value beat — Zealova onboards nutrition too (unlike
/// Gravl), so this beat carries the food side of the value story. A compact
/// macro-ring visual + three checkmark bullets covering snap-a-meal logging,
/// adaptive macro targets, and the coach connecting food to training.
///
/// Returns just a [Padding]/[Column] body — the host quiz scaffold provides the
/// [OnboardingBackground] + [Scaffold].
class NutritionDecodedBeat extends StatelessWidget {
  /// Advances the funnel to the next quiz step.
  final VoidCallback onContinue;

  const NutritionDecodedBeat({super.key, required this.onContinue});

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
                    child: _MacroRings(t: t)
                        .animate()
                        .fadeIn(delay: 150.ms)
                        .scale(begin: const Offset(0.85, 0.85)),
                  ),
                  const SizedBox(height: 28),
                  const ValueBeatHeadline(
                    headline: 'Your nutrition, decoded.',
                    supporting:
                        'Fuel that matches the training — without spreadsheets.',
                  ),
                  const SizedBox(height: 28),
                  ...[
                    const ValueBeatCheckBullet(
                      icon: Icons.camera_alt_rounded,
                      title: 'Snap a meal to log it',
                      subtitle: 'A photo is enough — we handle the macros.',
                    ),
                    const ValueBeatCheckBullet(
                      icon: Icons.track_changes_rounded,
                      title: 'Macro targets that adapt',
                      subtitle: 'Shift with your goal, weight, and training load.',
                    ),
                    const ValueBeatCheckBullet(
                      icon: Icons.insights_rounded,
                      title: 'A coach that connects food to training',
                      subtitle: 'See how today\'s plate sets up tomorrow\'s lift.',
                    ),
                  ].animateStaggered(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ValueBeatContinueButton(onContinue: onContinue)
              .animate()
              .fadeIn(delay: 650.ms)
              .slideY(begin: 0.1),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Three concentric macro rings (protein / carbs / fat) drawn in-code. Purely
/// decorative — the arc fills are illustrative, not a claim about real targets.
class _MacroRings extends StatelessWidget {
  final OnboardingTheme t;

  const _MacroRings({required this.t});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 132,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeOutCubic,
        builder: (context, progress, _) {
          return CustomPaint(
            painter: _MacroRingsPainter(
              progress: progress,
              track: t.borderDefault,
              // Macro-specific colors: P (orange-brand), C (amber), F (teal).
              protein: t.accent,
              carbs: const Color(0xFFFBBF24),
              fat: const Color(0xFF2DD4BF),
            ),
            child: Center(
              child: Icon(
                Icons.restaurant_rounded,
                size: 30,
                color: t.accent,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MacroRingsPainter extends CustomPainter {
  final double progress;
  final Color track;
  final Color protein;
  final Color carbs;
  final Color fat;

  _MacroRingsPainter({
    required this.progress,
    required this.track,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const stroke = 9.0;
    // (radius, fillFraction, color) per ring, outer -> inner.
    final rings = <(double, double, Color)>[
      (size.width / 2 - stroke, 0.78, protein),
      (size.width / 2 - stroke * 2.4, 0.62, carbs),
      (size.width / 2 - stroke * 3.8, 0.46, fat),
    ];

    const startAngle = -1.5708; // top (-90deg)
    for (final (radius, fill, color) in rings) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      // Track.
      canvas.drawArc(
        rect,
        0,
        6.2832,
        false,
        Paint()
          ..color = track.withValues(alpha: 0.5)
          ..strokeWidth = stroke
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      // Fill (animated).
      canvas.drawArc(
        rect,
        startAngle,
        6.2832 * fill * progress,
        false,
        Paint()
          ..color = color
          ..strokeWidth = stroke
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_MacroRingsPainter old) =>
      old.progress != progress ||
      old.protein != protein ||
      old.carbs != carbs ||
      old.fat != fat ||
      old.track != track;
}

extension _StaggerBullets on List<Widget> {
  List<Widget> animateStaggered() {
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
