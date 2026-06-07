import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../data/repositories/training_load_repository.dart';

/// "Today's progress" Daily Cardio Load card (Samsung-parity).
///
/// An intraday cumulative-load area chart with the daily target band, plus a
/// "Balanced" ACWR bar (Under ↔ Injury Risk, optimal 0.8-1.5). Reads
/// [trainingLoadTodayProvider]; renders honest calibration / no-cardio states
/// instead of a fabricated curve.
class DailyCardioLoadCard extends ConsumerWidget {
  const DailyCardioLoadCard({super.key});

  static const Color _balanced = Color(0xFF22C55E);
  static const Color _loading = Color(0xFFF59E0B);
  static const Color _over = Color(0xFFEF4444);

  Color _stateColor(String state, Color muted) {
    switch (state) {
      case 'balanced':
        return _balanced;
      case 'loading':
        return _loading;
      case 'overreaching':
        return _over;
      case 'detraining':
        return const Color(0xFF38BDF8);
      default:
        return muted;
    }
  }

  String _stateLabel(String state) {
    switch (state) {
      case 'balanced':
        return 'Balanced';
      case 'loading':
        return 'Building';
      case 'overreaching':
        return 'Overreaching';
      case 'detraining':
        return 'Detraining';
      default:
        return 'Building baseline';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.surface : AppColorsLight.surface;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final async = ref.watch(trainingLoadTodayProvider);
    final data = async.valueOrNull;
    if (data == null) return const SizedBox.shrink();

    final stateColor = _stateColor(data.state, muted);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Today\'s progress',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textPrimary)),
              const Spacer(),
              Text(
                  '${data.workoutCount} workout${data.workoutCount == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 13, color: textSecondary)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 132,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0, end: 1),
              builder: (context, t, _) => CustomPaint(
                size: Size.infinite,
                painter: _IntradayPainter(
                  data: data,
                  accent: stateColor,
                  t: t,
                  axisColor: textSecondary.withValues(alpha: 0.5),
                  gridColor: textSecondary.withValues(alpha: 0.12),
                  bandColor: muted.withValues(alpha: 0.18),
                ),
              ),
            ),
          ),
          if (data.hasTarget)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Container(
                      width: 14,
                      height: 8,
                      decoration: BoxDecoration(
                          color: muted.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 6),
                  Text('Target range',
                      style: TextStyle(fontSize: 11.5, color: textSecondary)),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Divider(color: textSecondary.withValues(alpha: 0.12), height: 1),
          const SizedBox(height: 14),

          // ── Balanced ACWR bar ──
          Text(_stateLabel(data.state),
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: stateColor)),
          const SizedBox(height: 10),
          _AcwrBar(acwr: data.acwr, accent: stateColor, isDark: isDark),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('Under', style: TextStyle(fontSize: 11, color: textSecondary)),
              const Spacer(),
              Text('Optimal range (0.8 - 1.5)',
                  style: TextStyle(fontSize: 11, color: textSecondary)),
              const Spacer(),
              Text('Injury risk',
                  style: TextStyle(fontSize: 11, color: textSecondary)),
            ],
          ),
          if (data.interpretation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(data.interpretation,
                style: TextStyle(
                    fontSize: 13, height: 1.4, color: textSecondary)),
          ],
        ],
      ),
    );
  }
}

class _IntradayPainter extends CustomPainter {
  final TrainingLoadToday data;
  final Color accent;
  final double t;
  final Color axisColor;
  final Color gridColor;
  final Color bandColor;

  const _IntradayPainter({
    required this.data,
    required this.accent,
    required this.t,
    required this.axisColor,
    required this.gridColor,
    required this.bandColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 4.0;
    const bottomPad = 18.0;
    final chartW = size.width - leftPad;
    final chartH = size.height - bottomPad;

    // Y scale: max of cumulative load and the target band top, with headroom.
    double maxY = 10;
    for (final p in data.points) {
      if (p.cumulative > maxY) maxY = p.cumulative;
    }
    if (data.targetMax != null && data.targetMax! > maxY) maxY = data.targetMax!;
    maxY *= 1.15;

    double xFor(int minute) => leftPad + (minute / 1440.0) * chartW;
    double yFor(double v) => chartH - (v / maxY) * chartH;

    // Target band.
    if (data.targetMin != null && data.targetMax != null) {
      final bandRect = Rect.fromLTRB(
          leftPad, yFor(data.targetMax!), size.width, yFor(data.targetMin!));
      canvas.drawRect(bandRect, Paint()..color = bandColor);
    }

    // Hour gridlines + labels (every 6h).
    final tickPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final h in [0, 6, 12, 18, 24]) {
      final x = xFor(h * 60);
      canvas.drawLine(Offset(x, 0), Offset(x, chartH), tickPaint);
      final tp = TextPainter(
        text: TextSpan(
            text: h == 0
                ? '12AM'
                : (h == 24 ? '' : (h == 12 ? '12PM' : '${h % 12}${h < 12 ? 'AM' : 'PM'}')),
            style: TextStyle(color: axisColor, fontSize: 9.5)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + 2, chartH + 4));
    }

    // Cumulative step-area (animated up to the current cumulative).
    if (data.points.length >= 2) {
      final pts = <Offset>[];
      double lastCum = 0;
      for (final p in data.points) {
        final c = p.cumulative * t;
        pts.add(Offset(xFor(p.minute), yFor(lastCum))); // step
        pts.add(Offset(xFor(p.minute), yFor(c)));
        lastCum = c;
      }
      // Extend the final level to "now" edge isn't known server-side; hold to
      // the last point's x (honest — the curve plateaus after the last session).
      final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final o in pts.skip(1)) {
        linePath.lineTo(o.dx, o.dy);
      }
      // Fill under the curve.
      final fill = Path.from(linePath)
        ..lineTo(pts.last.dx, chartH)
        ..lineTo(pts.first.dx, chartH)
        ..close();
      canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [accent.withValues(alpha: 0.34), accent.withValues(alpha: 0.04)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, chartH)),
      );
      canvas.drawPath(
        linePath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = accent,
      );
      // Workout markers (runner ticks) at each step-up.
      for (final p in data.points.skip(1)) {
        final x = xFor(p.minute);
        canvas.drawCircle(Offset(x, yFor(p.cumulative * t)), 3.5,
            Paint()..color = accent);
      }
    } else {
      // No cardio today — flat baseline.
      canvas.drawLine(
        Offset(leftPad, chartH),
        Offset(size.width, chartH),
        Paint()
          ..color = accent.withValues(alpha: 0.4)
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _IntradayPainter old) =>
      old.t != t || old.data != data || old.accent != accent;
}

/// The Under ↔ Injury-Risk ACWR bar with the optimal 0.8-1.5 band + a thumb.
class _AcwrBar extends StatelessWidget {
  final double? acwr;
  final Color accent;
  final bool isDark;
  const _AcwrBar({required this.acwr, required this.accent, required this.isDark});

  static const double _scaleMax = 2.5;

  @override
  Widget build(BuildContext context) {
    final track = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);
    final band = const Color(0xFF22C55E).withValues(alpha: 0.22);
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      double pos(double v) => (v / _scaleMax).clamp(0.0, 1.0) * w;
      return SizedBox(
        height: 18,
        child: Stack(
          children: [
            // Track.
            Positioned(
              top: 6,
              left: 0,
              right: 0,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                    color: track, borderRadius: BorderRadius.circular(3)),
              ),
            ),
            // Optimal band 0.8-1.5.
            Positioned(
              top: 6,
              left: pos(0.8),
              width: pos(1.5) - pos(0.8),
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                    color: band, borderRadius: BorderRadius.circular(3)),
              ),
            ),
            // Thumb at current ACWR (only when known).
            if (acwr != null)
              Positioned(
                top: 0,
                left: (pos(acwr!) - 9).clamp(0.0, w - 18),
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
