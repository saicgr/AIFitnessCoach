import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';

/// StrengthRadar — six-axis radar / spider chart showing strength balance
/// across body regions (Push, Pull, Legs, Core, Conditioning, Mobility).
/// Uses `data.musclesWorked` and `data.highlights` to source values when
/// available; otherwise falls back to a deterministic shape seeded by
/// the title hash.
class StrengthRadarTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const StrengthRadarTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  static const _axes = [
    'PUSH',
    'PULL',
    'LEGS',
    'CORE',
    'CONDITION',
    'MOBILITY',
  ];

  List<double> _values(Shareable d) {
    // Map muscle counts to axes when present.
    final mw = d.musclesWorked ?? const <String, int>{};
    if (mw.isNotEmpty) {
      // Use max(maxV, 1) to avoid div-by-zero; do NOT clamp to a fake floor —
      // axes that weren't trained should render as 0, not as 15% of full
      // (the old `.clamp(0.15, 1.0)` faked a polygon for empty users).
      final maxV = math.max(
        mw.values.fold<int>(0, math.max),
        1,
      ).toDouble();
      double scoreFor(List<String> keywords) {
        var total = 0;
        for (final entry in mw.entries) {
          final lower = entry.key.toLowerCase();
          if (keywords.any((k) => lower.contains(k))) total += entry.value;
        }
        return (total / maxV).clamp(0.0, 1.0);
      }

      return [
        scoreFor(const ['chest', 'shoulder', 'tricep']),
        scoreFor(const ['back', 'lat', 'bicep']),
        scoreFor(const ['leg', 'quad', 'glute', 'hamstring', 'calf']),
        scoreFor(const ['core', 'ab', 'oblique']),
        scoreFor(const ['cardio', 'condition', 'hiit']),
        scoreFor(const ['mobility', 'stretch', 'yoga']),
      ];
    }
    // No muscle data — render an empty (centered) shape so the user sees a
    // truthful "no activity yet" radar instead of a randomized fake polygon.
    return List.filled(6, 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final accent = data.accentColor;
    final values = _values(data);
    final balance = (values.reduce((a, b) => a + b) / values.length * 100).round();

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
                Icon(Icons.radar_rounded, size: 18 * mul, color: accent),
                const SizedBox(width: 8),
                Text(
                  'STRENGTH RADAR',
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
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accent),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.balance_rounded,
                          size: 14 * mul, color: accent),
                      const SizedBox(width: 4),
                      Text(
                        'BALANCE $balance',
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
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CustomPaint(
                    painter: _RadarPainter(
                      values: values,
                      labels: _axes,
                      accent: accent,
                      mul: mul,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
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
}

class _RadarPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final Color accent;
  final double mul;

  _RadarPainter({
    required this.values,
    required this.labels,
    required this.accent,
    required this.mul,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 28;
    final n = values.length;

    // Concentric grid (4 rings).
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (int i = 1; i <= 4; i++) {
      final r = radius * (i / 4);
      final path = Path();
      for (int j = 0; j < n; j++) {
        final angle = -math.pi / 2 + (j / n) * 2 * math.pi;
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, ringPaint);
    }

    // Spokes + labels.
    final spokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 1;
    for (int i = 0; i < n; i++) {
      final angle = -math.pi / 2 + (i / n) * 2 * math.pi;
      final outer = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, outer, spokePaint);

      final labelOffset = Offset(
        center.dx + (radius + 18) * math.cos(angle),
        center.dy + (radius + 18) * math.sin(angle),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 10 * mul,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        labelOffset - Offset(tp.width / 2, tp.height / 2),
      );
    }

    // Filled value polygon.
    final fillPath = Path();
    final dotPoints = <Offset>[];
    for (int i = 0; i < n; i++) {
      final angle = -math.pi / 2 + (i / n) * 2 * math.pi;
      final r = radius * values[i].clamp(0.0, 1.0);
      final p = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      dotPoints.add(p);
      if (i == 0) {
        fillPath.moveTo(p.dx, p.dy);
      } else {
        fillPath.lineTo(p.dx, p.dy);
      }
    }
    fillPath.close();

    final fillPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          accent.withValues(alpha: 0.55),
          accent.withValues(alpha: 0.22),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = accent
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    canvas.drawPath(fillPath, strokePaint);

    final dotPaint = Paint()..color = Colors.white;
    final dotRing = Paint()..color = accent;
    for (final p in dotPoints) {
      canvas.drawCircle(p, 5, dotRing);
      canvas.drawCircle(p, 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.values != values || old.accent != accent;
}
