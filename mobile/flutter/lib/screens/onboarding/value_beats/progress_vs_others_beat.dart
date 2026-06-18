import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/onboarding_theme.dart';
import '_value_beat_scaffold.dart';

/// Value beat: a qualitative "you vs typical" progress chart.
///
/// Hand-painted with a [CustomPainter] (no chart package). Two curves — "You
/// with Zealova" in brand orange rising above "Typical" in grey — over a
/// 2 / 4 / 8 week x-axis. The framing is intentionally HONEST and qualitative:
/// the curves carry no numeric y-axis and the copy says members "more
/// consistently" add strength — no fabricated precise numbers.
///
/// Returns just a [Padding]/[Column] body — the host quiz scaffold provides the
/// [OnboardingBackground] + [Scaffold].
class ProgressVsOthersBeat extends StatelessWidget {
  /// Advances the funnel to the next quiz step.
  final VoidCallback onContinue;

  /// Optional experience label (e.g. "Beginner") used to personalize the
  /// "members at your level" line. When null, a neutral phrasing is used.
  final String? experienceLabel;

  const ProgressVsOthersBeat({
    super.key,
    required this.onContinue,
    this.experienceLabel,
  });

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);

    final levelPhrase = (experienceLabel != null &&
            experienceLabel!.trim().isNotEmpty)
        ? 'Members at the ${experienceLabel!.trim().toLowerCase()} level'
        : 'Members at your level';

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
                  const ValueBeatHeadline(
                    headline: 'A plan that compounds.',
                    supporting:
                        'Consistency beats intensity. Here is the shape of it.',
                  ),
                  const SizedBox(height: 28),
                  _ChartCard(t: t)
                      .animate()
                      .fadeIn(delay: 250.ms)
                      .scale(begin: const Offset(0.97, 0.97)),
                  const SizedBox(height: 22),
                  Text(
                    '$levelPhrase add strength more consistently when every '
                    'session is planned for them.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: t.textSecondary,
                    ),
                  ).animate().fadeIn(delay: 500.ms),
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

class _ChartCard extends StatelessWidget {
  final OnboardingTheme t;

  const _ChartCard({required this.t});

  @override
  Widget build(BuildContext context) {
    final greyCurve = t.textMuted;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      decoration: BoxDecoration(
        color: t.cardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.borderDefault, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend.
          Row(
            children: [
              _legendDot(t.accent),
              const SizedBox(width: 6),
              Text(
                'You with Zealova',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: t.textPrimary,
                ),
              ),
              const SizedBox(width: 16),
              _legendDot(greyCurve),
              const SizedBox(width: 6),
              Text(
                'Typical',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: t.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // The painted curves.
          SizedBox(
            height: 150,
            width: double.infinity,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, progress, _) {
                return CustomPaint(
                  painter: _ProgressCurvesPainter(
                    youColor: t.accent,
                    typicalColor: greyCurve,
                    progress: progress,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // X-axis labels.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _axisLabel('2 wks'),
                _axisLabel('4 wks'),
                _axisLabel('8 wks'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _axisLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: t.textMuted,
      ),
    );
  }
}

/// Paints two qualitative growth curves. The "you" curve accelerates upward;
/// the "typical" curve flattens. No numeric y-axis — this is a shape, not a
/// claim about specific magnitudes.
class _ProgressCurvesPainter extends CustomPainter {
  final Color youColor;
  final Color typicalColor;

  /// 0..1 reveal progress, used to draw-on the curves left-to-right.
  final double progress;

  _ProgressCurvesPainter({
    required this.youColor,
    required this.typicalColor,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Baseline grid line.
    final gridPaint = Paint()
      ..color = typicalColor.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, h - 1), Offset(w, h - 1), gridPaint);

    // Control points as fractions of the canvas (y inverted: 0 = top).
    Offset pt(double fx, double fy) => Offset(fx * w, (1 - fy) * h);

    // "Typical" — slow, flattening.
    final typicalPath = Path()
      ..moveTo(pt(0.0, 0.12).dx, pt(0.0, 0.12).dy)
      ..cubicTo(
        pt(0.33, 0.20).dx, pt(0.33, 0.20).dy,
        pt(0.66, 0.28).dx, pt(0.66, 0.28).dy,
        pt(1.0, 0.34).dx, pt(1.0, 0.34).dy,
      );

    // "You with Zealova" — accelerating upward.
    final youPath = Path()
      ..moveTo(pt(0.0, 0.14).dx, pt(0.0, 0.14).dy)
      ..cubicTo(
        pt(0.30, 0.30).dx, pt(0.30, 0.30).dy,
        pt(0.62, 0.55).dx, pt(0.62, 0.55).dy,
        pt(1.0, 0.92).dx, pt(1.0, 0.92).dy,
      );

    _drawAnimatedPath(canvas, typicalPath, typicalColor, 2.5, dashed: true);
    _drawAnimatedPath(canvas, youPath, youColor, 3.5);

    // Endpoint marker on the "you" curve once mostly revealed.
    if (progress > 0.92) {
      final metrics = youPath.computeMetrics().first;
      final end = metrics.getTangentForOffset(metrics.length)?.position;
      if (end != null) {
        canvas.drawCircle(
          end,
          5,
          Paint()..color = youColor,
        );
        canvas.drawCircle(
          end,
          9,
          Paint()
            ..color = youColor.withValues(alpha: 0.22)
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  void _drawAnimatedPath(
    Canvas canvas,
    Path path,
    Color color,
    double width, {
    bool dashed = false,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final metric in path.computeMetrics()) {
      final len = metric.length * progress.clamp(0.0, 1.0);
      if (dashed) {
        const dash = 6.0;
        const gap = 5.0;
        double dist = 0;
        while (dist < len) {
          final next = (dist + dash).clamp(0.0, len);
          canvas.drawPath(metric.extractPath(dist, next), paint);
          dist += dash + gap;
        }
      } else {
        canvas.drawPath(metric.extractPath(0, len), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ProgressCurvesPainter old) =>
      old.progress != progress ||
      old.youColor != youColor ||
      old.typicalColor != typicalColor;
}
