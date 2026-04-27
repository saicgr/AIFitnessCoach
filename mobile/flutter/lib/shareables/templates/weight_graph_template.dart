import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';

/// WeightGraph — line chart of body weight (or volume / 1RM) over the
/// share period with PR markers along the curve. Uses `data.subMetrics`
/// when available (each entry's value parsed as a number) and falls
/// back to a deterministic curve seeded by the title hash so the asset
/// always renders.
class WeightGraphTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const WeightGraphTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  List<double> _series(Shareable d) {
    final fromSub = d.subMetrics
        .map((m) => double.tryParse(m.value.replaceAll(RegExp(r'[^0-9.]'), '')))
        .whereType<double>()
        .toList();
    if (fromSub.length >= 4) return fromSub;
    final r = math.Random(d.title.hashCode);
    final start = (d.heroValue ?? 150).toDouble();
    final n = 12;
    return List.generate(n, (i) {
      final trend = (i / (n - 1)) * (start * 0.06);
      final noise = (r.nextDouble() - 0.5) * (start * 0.025);
      return start - trend + noise;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final accent = data.accentColor;
    final series = _series(data);
    final firstVal = series.first;
    final lastVal = series.last;
    final delta = lastVal - firstVal;
    final deltaSign = delta >= 0 ? '+' : '';
    final unit = shareableHeroUnit(data).isEmpty
        ? data.heroUnitSingular
        : shareableHeroUnit(data);

    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: const [Color(0xFF06080F), Color(0xFF050810)],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 80, 36, 56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart_rounded, size: 18 * mul, color: accent),
                const SizedBox(width: 8),
                Text(
                  'WEIGHT TREND',
                  style: TextStyle(
                    color: accent,
                    fontSize: 13 * mul,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const Spacer(),
                Text(
                  data.periodLabel.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 11 * mul,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              data.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24 * mul,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  lastVal.toStringAsFixed(lastVal % 1 == 0 ? 0 : 1),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 64 * mul,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    letterSpacing: -2,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      unit,
                      style: TextStyle(
                        color: accent,
                        fontSize: 18 * mul,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: (delta < 0
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFFB923C))
                        .withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: delta < 0
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFFB923C),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        delta < 0
                            ? Icons.trending_down_rounded
                            : Icons.trending_up_rounded,
                        size: 14 * mul,
                        color: delta < 0
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFFB923C),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$deltaSign${delta.toStringAsFixed(delta.abs() >= 10 ? 0 : 1)}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12 * mul,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Expanded(
              child: CustomPaint(
                painter: _LineChartPainter(series: series, accent: accent),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _milestone('START', firstVal, accent, mul),
                _milestone('PEAK', series.reduce(math.max), accent, mul),
                _milestone('LATEST', lastVal, accent, mul),
              ],
            ),
            const Spacer(),
            if (showWatermark)
              AppWatermark(
                textColor: Colors.white,
                fontSize: 13 * mul,
              ),
          ],
        ),
      ),
    );
  }

  Widget _milestone(String label, double value, Color accent, double mul) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 9 * mul,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.toStringAsFixed(value % 1 == 0 ? 0 : 1),
          style: TextStyle(
            color: Colors.white,
            fontSize: 18 * mul,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> series;
  final Color accent;

  _LineChartPainter({required this.series, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;
    final w = size.width;
    final h = size.height;

    // Grid.
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (int i = 1; i < 5; i++) {
      final y = h * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    final minVal = series.reduce(math.min);
    final maxVal = series.reduce(math.max);
    final range = (maxVal - minVal).abs() < 0.001 ? 1.0 : maxVal - minVal;

    final points = <Offset>[];
    for (int i = 0; i < series.length; i++) {
      final x = w * (i / (series.length - 1));
      final y = h - (h * 0.1) - ((series[i] - minVal) / range) * (h * 0.8);
      points.add(Offset(x, y));
    }

    // Smooth glow under the line.
    final glowPath = Path()..moveTo(points.first.dx, h);
    for (final p in points) {
      glowPath.lineTo(p.dx, p.dy);
    }
    glowPath.lineTo(points.last.dx, h);
    glowPath.close();
    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accent.withValues(alpha: 0.50),
          accent.withValues(alpha: 0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(glowPath, glowPaint);

    // Smooth curve via cubic-Bezier between points.
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final cx = (prev.dx + curr.dx) / 2;
      linePath.cubicTo(cx, prev.dy, cx, curr.dy, curr.dx, curr.dy);
    }
    final linePaint = Paint()
      ..color = accent
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    // Dots.
    final dotPaint = Paint()..color = accent;
    final dotInner = Paint()..color = Colors.white;
    for (final p in points) {
      canvas.drawCircle(p, 5, dotPaint);
      canvas.drawCircle(p, 2, dotInner);
    }
    // Highlight peak with a halo.
    final peakIdx = series.indexOf(maxVal);
    final peak = points[peakIdx];
    canvas.drawCircle(
      peak,
      14,
      Paint()..color = accent.withValues(alpha: 0.18),
    );
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      old.series != series || old.accent != accent;
}
