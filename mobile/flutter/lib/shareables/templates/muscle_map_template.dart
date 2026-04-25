import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/fitwiz_watermark.dart';

/// MuscleMap — anatomical front silhouette with muscle groups heat-coded
/// from `data.musclesWorked`. Sparkle accent. Spark category — synthesizes
/// raw set data into a single glanceable visual ("you trained your back
/// 4× this week, chest 2×, legs 1×").
class MuscleMapTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const MuscleMapTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final accent = data.accentColor;
    final muscles = data.musclesWorked ?? const <String, int>{};
    final maxCount = muscles.values.fold<int>(0, math.max);
    final top = muscles.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topThree = top.take(3).toList();

    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: [
        const Color(0xFF06080F),
        Color.lerp(accent, const Color(0xFF06080F), 0.85)!,
      ],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 80, 36, 56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 18 * mul, color: accent),
                const SizedBox(width: 8),
                Text(
                  'MUSCLE MAP',
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
                fontSize: 26 * mul,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              muscles.isEmpty
                  ? 'Trained the body. Volume is on the board.'
                  : '${muscles.length} groups trained · top: ${topThree.first.key}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13 * mul,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 0.42,
                  child: CustomPaint(
                    painter: _BodyPainter(
                      muscles: muscles,
                      maxCount: maxCount == 0 ? 1 : maxCount,
                      accent: accent,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (topThree.isNotEmpty)
              Row(
                children: [
                  for (var i = 0; i < topThree.length; i++) ...[
                    Expanded(
                      child: _legendChip(
                        topThree[i].key,
                        topThree[i].value,
                        accent,
                        mul,
                      ),
                    ),
                    if (i < topThree.length - 1) const SizedBox(width: 8),
                  ],
                ],
              ),
            const SizedBox(height: 18),
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

  Widget _legendChip(String name, int count, Color accent, double mul) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 10 * mul,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22 * mul,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                count == 1 ? 'set' : 'sets',
                style: TextStyle(
                  color: accent,
                  fontSize: 11 * mul,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BodyPainter extends CustomPainter {
  final Map<String, int> muscles;
  final int maxCount;
  final Color accent;

  _BodyPainter({
    required this.muscles,
    required this.maxCount,
    required this.accent,
  });

  Color _heatColor(String key) {
    final count = _matchedCount(key);
    if (count == 0) return Colors.white.withValues(alpha: 0.06);
    final t = count / maxCount;
    return Color.lerp(
      accent.withValues(alpha: 0.25),
      accent,
      t.clamp(0.0, 1.0),
    )!;
  }

  int _matchedCount(String key) {
    final lower = key.toLowerCase();
    for (final entry in muscles.entries) {
      if (entry.key.toLowerCase().contains(lower)) return entry.value;
    }
    return 0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = Colors.white.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Head.
    final headR = w * 0.13;
    final headCenter = Offset(w / 2, h * 0.08);
    canvas.drawCircle(headCenter, headR, body);
    canvas.drawCircle(headCenter, headR, outline);

    // Neck.
    final neck = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w / 2, h * 0.16), width: w * 0.10, height: h * 0.04),
      const Radius.circular(4),
    );
    canvas.drawRRect(neck, body);
    canvas.drawRRect(neck, outline);

    // Torso (shoulders → waist).
    final torso = Path()
      ..moveTo(w * 0.18, h * 0.20)
      ..quadraticBezierTo(w * 0.10, h * 0.30, w * 0.18, h * 0.55)
      ..lineTo(w * 0.32, h * 0.62)
      ..lineTo(w * 0.68, h * 0.62)
      ..lineTo(w * 0.82, h * 0.55)
      ..quadraticBezierTo(w * 0.90, h * 0.30, w * 0.82, h * 0.20)
      ..close();
    canvas.drawPath(torso, body);
    canvas.drawPath(torso, outline);

    // Chest (heat-coded).
    _drawHeatRegion(
      canvas,
      Path()
        ..moveTo(w * 0.27, h * 0.23)
        ..quadraticBezierTo(w * 0.50, h * 0.20, w * 0.73, h * 0.23)
        ..lineTo(w * 0.70, h * 0.36)
        ..lineTo(w * 0.30, h * 0.36)
        ..close(),
      _heatColor('chest'),
    );

    // Abs.
    _drawHeatRegion(
      canvas,
      Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.36, h * 0.39, w * 0.28, h * 0.18),
            const Radius.circular(8),
          ),
        ),
      _heatColor('core'),
    );

    // Shoulders (left + right).
    _drawHeatRegion(
      canvas,
      Path()..addOval(Rect.fromLTWH(w * 0.13, h * 0.20, w * 0.16, h * 0.10)),
      _heatColor('shoulder'),
    );
    _drawHeatRegion(
      canvas,
      Path()..addOval(Rect.fromLTWH(w * 0.71, h * 0.20, w * 0.16, h * 0.10)),
      _heatColor('shoulder'),
    );

    // Biceps (arms).
    _drawHeatRegion(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.06, h * 0.27, w * 0.12, h * 0.18),
          const Radius.circular(20),
        ),
      ),
      _heatColor('biceps'),
    );
    _drawHeatRegion(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.82, h * 0.27, w * 0.12, h * 0.18),
          const Radius.circular(20),
        ),
      ),
      _heatColor('biceps'),
    );

    // Forearms.
    final forearmL = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.04, h * 0.45, w * 0.10, h * 0.16),
      const Radius.circular(16),
    );
    final forearmR = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.86, h * 0.45, w * 0.10, h * 0.16),
      const Radius.circular(16),
    );
    canvas.drawRRect(forearmL, body);
    canvas.drawRRect(forearmL, outline);
    canvas.drawRRect(forearmR, body);
    canvas.drawRRect(forearmR, outline);

    // Quads.
    _drawHeatRegion(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.30, h * 0.63, w * 0.18, h * 0.22),
          const Radius.circular(20),
        ),
      ),
      _heatColor('quads'),
    );
    _drawHeatRegion(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.52, h * 0.63, w * 0.18, h * 0.22),
          const Radius.circular(20),
        ),
      ),
      _heatColor('quads'),
    );

    // Calves.
    _drawHeatRegion(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.32, h * 0.85, w * 0.14, h * 0.14),
          const Radius.circular(14),
        ),
      ),
      _heatColor('calves'),
    );
    _drawHeatRegion(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.54, h * 0.85, w * 0.14, h * 0.14),
          const Radius.circular(14),
        ),
      ),
      _heatColor('calves'),
    );

    // Outline pass on top of all heat regions.
    canvas.drawPath(torso, outline);
  }

  void _drawHeatRegion(Canvas canvas, Path path, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
    final stroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _BodyPainter old) =>
      old.muscles != muscles || old.accent != accent;
}
