import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';

/// VolumeBars — vertical bar chart of daily / weekly volume across the
/// share period. Reads from `data.subMetrics` when present, otherwise
/// generates a deterministic series so the chart always renders.
class VolumeBarsTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const VolumeBarsTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  static const _shortDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  List<_BarPoint> _series(Shareable d) {
    if (d.subMetrics.length >= 5) {
      return d.subMetrics.take(14).map((m) {
        final v = double.tryParse(m.value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
        return _BarPoint(
          label: m.label.isEmpty
              ? ''
              : (m.label.length > 3
                  ? m.label.substring(0, 3).toUpperCase()
                  : m.label.toUpperCase()),
          value: v,
        );
      }).toList();
    }
    final r = math.Random(d.title.hashCode);
    return List.generate(7, (i) {
      final base = (d.heroValue ?? 5000).toDouble();
      final v = base * (0.4 + r.nextDouble() * 0.7);
      return _BarPoint(label: _shortDays[i], value: v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final accent = data.accentColor;
    final series = _series(data);
    final total = series.fold<double>(0, (s, p) => s + p.value);
    final avg = series.isEmpty ? 0.0 : total / series.length;
    final peak = series.fold<double>(0, (m, p) => math.max(m, p.value));

    return ShareableCanvas(
      aspect: data.aspect,
      accentColor: accent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 80, 36, 56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart_rounded, size: 18 * mul, color: accent),
                const SizedBox(width: 8),
                Text(
                  'VOLUME',
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
            const SizedBox(height: 10),
            Row(
              children: [
                _stat('TOTAL', _fmt(total), accent, mul),
                const SizedBox(width: 24),
                _stat('AVG', _fmt(avg), accent, mul),
                const SizedBox(width: 24),
                _stat('PEAK', _fmt(peak), accent, mul),
              ],
            ),
            const SizedBox(height: 28),
            Expanded(
              child: CustomPaint(
                painter: _BarsPainter(series: series, accent: accent),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final p in series)
                  Expanded(
                    child: Center(
                      child: Text(
                        p.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 9 * mul,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
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

  Widget _stat(String label, String value, Color accent, double mul) {
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
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18 * mul,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  String _fmt(double v) {
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(v >= 10000 ? 0 : 1)}k';
    }
    return v.toStringAsFixed(v % 1 == 0 ? 0 : 1);
  }
}

class _BarPoint {
  final String label;
  final double value;
  const _BarPoint({required this.label, required this.value});
}

class _BarsPainter extends CustomPainter {
  final List<_BarPoint> series;
  final Color accent;
  _BarsPainter({required this.series, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;
    final w = size.width;
    final h = size.height;
    const gap = 10.0;
    final barW = (w - gap * (series.length - 1)) / series.length;
    final maxVal = series.fold<double>(0, (m, p) => math.max(m, p.value));
    final scale = maxVal == 0 ? 0.0 : 1.0;

    // Grid lines.
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (int i = 1; i < 5; i++) {
      final y = h * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(w, y), grid);
    }

    for (int i = 0; i < series.length; i++) {
      final x = i * (barW + gap);
      final v = series[i].value;
      final barH = scale == 0 ? 0.0 : (v / maxVal) * (h * 0.92);
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, h - barH, barW, barH),
        topLeft: const Radius.circular(8),
        topRight: const Radius.circular(8),
      );
      final isPeak = v == maxVal && v > 0;
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            accent,
            isPeak
                ? Color.lerp(accent, Colors.white, 0.5)!
                : accent.withValues(alpha: 0.55),
          ],
        ).createShader(Rect.fromLTWH(x, h - barH, barW, barH));
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter old) =>
      old.series != series || old.accent != accent;
}
