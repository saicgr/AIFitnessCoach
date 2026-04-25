import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/fitwiz_watermark.dart';

/// ActivityRings — three concentric rings (Workouts / Volume / Streak) with
/// Apple-Watch typography on a dark canvas. Sweep gradients per ring.
class ActivityRingsTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const ActivityRingsTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final ringData = _resolveRings(data);

    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: const [Color(0xFF000000), Color(0xFF050810)],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 80, 40, 56),
        child: Column(
          children: [
            Text(
              'ACTIVITY',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 13 * mul,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data.periodLabel,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 14 * mul,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 320,
              height: 320,
              child: CustomPaint(
                painter: _RingsPainter(rings: ringData),
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(3, (i) {
                final r = ringData[i];
                return _legendChip(r, mul);
              }),
            ),
            const SizedBox(height: 28),
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

  List<_Ring> _resolveRings(Shareable d) {
    final hl = d.highlights.where((h) => h.isPopulated).toList();
    final accent = d.accentColor;
    String value(int i, String fallback) =>
        i < hl.length ? hl[i].value : fallback;
    String label(int i, String fallback) =>
        i < hl.length ? hl[i].label : fallback;
    return [
      _Ring(
        label: label(0, 'WORKOUTS'),
        value: value(0, '${d.heroValue?.round() ?? 0}'),
        progress: _progressFromValue(value(0, '0'), max: 30),
        colors: [const Color(0xFFFF375F), const Color(0xFFFF6B82)],
      ),
      _Ring(
        label: label(1, 'VOLUME'),
        value: value(1, '—'),
        progress: _progressFromValue(value(1, '0'), max: 5000),
        colors: [accent, Color.lerp(accent, Colors.white, 0.3)!],
      ),
      _Ring(
        label: label(2, 'STREAK'),
        value: value(2, '0'),
        progress: _progressFromValue(value(2, '0'), max: 30),
        colors: [const Color(0xFFFFB35B), const Color(0xFFFF6B35)],
      ),
    ];
  }

  double _progressFromValue(String raw, {required double max}) {
    final m = RegExp(r'\d+(\.\d+)?').firstMatch(raw);
    if (m == null) return 0.6;
    final v = double.tryParse(m.group(0)!) ?? 0;
    return (v / max).clamp(0.05, 1.0);
  }

  Widget _legendChip(_Ring r, double mul) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: r.colors),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          r.value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 17 * mul,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          r.label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 10 * mul,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

class _Ring {
  final String label;
  final String value;
  final double progress;
  final List<Color> colors;
  _Ring({
    required this.label,
    required this.value,
    required this.progress,
    required this.colors,
  });
}

class _RingsPainter extends CustomPainter {
  final List<_Ring> rings;
  _RingsPainter({required this.rings});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const stroke = 26.0;
    const gap = 8.0;
    var radius = math.min(size.width, size.height) / 2 - stroke / 2;
    for (final ring in rings) {
      // Track.
      final track = Paint()
        ..color = ring.colors.first.withValues(alpha: 0.15)
        ..strokeWidth = stroke
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, radius, track);

      // Sweep.
      final sweep = ring.progress * 2 * math.pi;
      final paint = Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: -math.pi / 2 + sweep,
          colors: ring.colors,
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..strokeWidth = stroke
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweep,
        false,
        paint,
      );
      radius -= stroke + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) => false;
}
