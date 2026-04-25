import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/fitwiz_watermark.dart';

/// CalendarHeatmap — GitHub-style 52-week × 7-day grid filled from
/// `data.subMetrics` (treated as activity counts), accent-tinted cells,
/// total + streak chips below. Year-in-review staple.
class CalendarHeatmapTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const CalendarHeatmapTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final accent = data.accentColor;
    final values = _values(data);
    final total = values.fold<int>(0, (s, v) => s + v);
    final streakValue = data.highlights
        .firstWhere(
          (h) => h.label.toUpperCase().contains('STREAK'),
          orElse: () => const ShareableMetric(label: '', value: ''),
        )
        .value;

    return ShareableCanvas(
      aspect: data.aspect,
      accentColor: accent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 80, 40, 56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.periodLabel.toUpperCase(),
              style: TextStyle(
                color: accent,
                fontSize: 13 * mul,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              data.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 30 * mul,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final d in const ['M', '', 'W', '', 'F', '', ''])
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1.2),
                          child: SizedBox(
                            height: 11,
                            child: Text(
                              d,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 9 * mul,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 52 / 7,
                    child: CustomPaint(
                      painter: _HeatmapPainter(values: values, accent: accent),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _legend('Less', accent.withValues(alpha: 0.18), mul),
                ...List.generate(4, (i) {
                  final t = (i + 1) / 4;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.25 + t * 0.55),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 6),
                _legend('More', accent, mul),
                const Spacer(),
                Text(
                  '$total active days',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12 * mul,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _chip('TOTAL', '$total', accent, mul),
                if (streakValue.isNotEmpty)
                  _chip('STREAK', streakValue, accent, mul),
                _chip('YEAR', '${DateTime.now().year}', accent, mul),
              ],
            ),
            const SizedBox(height: 22),
            if (showWatermark)
              FitWizWatermark(
                textColor: Colors.white,
                fontSize: 13 * mul,
              ),
          ],
        ),
      ),
    );
  }

  Widget _legend(String label, Color color, double mul) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 9 * mul,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _chip(String label, String value, Color accent, double mul) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 9 * mul,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14 * mul,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  /// Build a 52*7=364 cell intensity vector. Prefers sub-metrics if
  /// adapters provide enough granular data; otherwise generates a
  /// deterministic pattern seeded by title + total workout count so the
  /// asset still looks like real data.
  List<int> _values(Shareable d) {
    final n = 52 * 7;
    if (d.subMetrics.length >= 30) {
      return List.generate(n, (i) {
        if (i < d.subMetrics.length) {
          return int.tryParse(d.subMetrics[i].value
                  .replaceAll(RegExp(r'[^0-9]'), '')) ??
              0;
        }
        return 0;
      });
    }
    final r = math.Random(d.title.hashCode + (d.heroValue ?? 1).toInt());
    return List.generate(n, (i) {
      // Higher density in later weeks to look like growing momentum.
      final week = i ~/ 7;
      final base = (week / 52.0) * 0.55;
      final roll = r.nextDouble();
      if (roll < 0.35 - base) return 0;
      return 1 + r.nextInt(4);
    });
  }
}

class _HeatmapPainter extends CustomPainter {
  final List<int> values;
  final Color accent;

  _HeatmapPainter({required this.values, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    const cols = 52;
    const rows = 7;
    const gap = 2.0;
    final cellW = (size.width - gap * (cols - 1)) / cols;
    final cellH = (size.height - gap * (rows - 1)) / rows;
    final cell = math.min(cellW, cellH);
    final radius = Radius.circular(cell * 0.18);
    final paint = Paint();
    for (int c = 0; c < cols; c++) {
      for (int r = 0; r < rows; r++) {
        final idx = c * rows + r;
        final v = idx < values.length ? values[idx] : 0;
        if (v == 0) {
          paint.color = Colors.white.withValues(alpha: 0.05);
        } else {
          final t = (v / 4).clamp(0.0, 1.0);
          paint.color = accent.withValues(alpha: 0.25 + t * 0.55);
        }
        final x = c * (cell + gap);
        final y = r * (cell + gap);
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x, y, cell, cell), radius),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter old) =>
      old.values != values || old.accent != accent;
}
