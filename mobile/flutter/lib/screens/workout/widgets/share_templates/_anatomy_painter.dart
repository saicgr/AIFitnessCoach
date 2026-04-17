import 'package:flutter/material.dart';
import '_share_common.dart';

/// Hand-coded body anatomy renderer for the share gallery's signature
/// template (Anatomy Hero). Draws stylized front + back silhouettes and
/// tints individual muscle regions by [musclesWorked] set counts.
///
/// Design goals:
/// - Single CustomPainter — no SVG package dep
/// - Recognizable as a body at a thumbnail size (~160×280)
/// - Muscles that got ≥ 1 set are filled with [fillStart]→[fillEnd]
///   gradient; unused muscles are drawn in [dimColor]
/// - More sets → brighter (opacity boosted 0.6..1.0 linearly up to 10 sets)
class AnatomyPainter extends CustomPainter {
  final MuscleSetMap musclesWorked;
  final Color fillStart;
  final Color fillEnd;
  final Color dimColor;
  final Color outlineColor;

  const AnatomyPainter({
    required this.musclesWorked,
    this.fillStart = const Color(0xFF14B8A6), // teal
    this.fillEnd = const Color(0xFF06B6D4),   // cyan
    this.dimColor = const Color(0x22FFFFFF),
    this.outlineColor = const Color(0x55FFFFFF),
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Split canvas into two columns — front on left, back on right.
    final halfW = size.width / 2;
    _drawFigure(
      canvas,
      offset: Offset.zero,
      size: Size(halfW, size.height),
      isFront: true,
    );
    _drawFigure(
      canvas,
      offset: Offset(halfW, 0),
      size: Size(halfW, size.height),
      isFront: false,
    );
  }

  void _drawFigure(
    Canvas canvas, {
    required Offset offset,
    required Size size,
    required bool isFront,
  }) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    // Normalized coordinates — body occupies middle 70% of canvas.
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    // Body "unit" — one rough head-height; used to scale limb widths.
    final u = h * 0.11;

    // Body outline — stylized, symmetric silhouette.
    final outline = Path();
    // Head
    final headCenter = Offset(cx, u * 0.7);
    final headRadius = u * 0.48;
    outline.addOval(Rect.fromCircle(center: headCenter, radius: headRadius));

    // Neck → shoulders → torso → hips
    outline.moveTo(cx - u * 0.28, u * 1.15);   // neck base L
    outline.lineTo(cx - u * 1.5, u * 1.5);     // shoulder L
    outline.lineTo(cx - u * 1.4, u * 3.5);     // waist L
    outline.lineTo(cx - u * 1.1, u * 4.1);     // hip narrow L
    outline.lineTo(cx - u * 1.3, u * 5.2);     // hip wide L
    // Left leg
    outline.lineTo(cx - u * 1.05, u * 7.2);    // knee L
    outline.lineTo(cx - u * 0.9, u * 8.9);     // calf L
    outline.lineTo(cx - u * 0.55, u * 9.0);    // foot L
    outline.lineTo(cx - u * 0.1, u * 5.3);     // crotch
    // Right leg
    outline.lineTo(cx + u * 0.55, u * 9.0);    // foot R
    outline.lineTo(cx + u * 0.9, u * 8.9);     // calf R
    outline.lineTo(cx + u * 1.05, u * 7.2);    // knee R
    outline.lineTo(cx + u * 1.3, u * 5.2);     // hip wide R
    outline.lineTo(cx + u * 1.1, u * 4.1);     // hip narrow R
    outline.lineTo(cx + u * 1.4, u * 3.5);     // waist R
    outline.lineTo(cx + u * 1.5, u * 1.5);     // shoulder R
    outline.lineTo(cx + u * 0.28, u * 1.15);   // neck base R
    outline.close();

    // Arms (separate subpath so they don't fill the body shape)
    final armL = Path()
      ..moveTo(cx - u * 1.45, u * 1.55)
      ..lineTo(cx - u * 1.75, u * 3.5)
      ..lineTo(cx - u * 1.8, u * 5.0)
      ..lineTo(cx - u * 1.45, u * 5.0)
      ..lineTo(cx - u * 1.4, u * 3.5)
      ..lineTo(cx - u * 1.2, u * 1.7)
      ..close();
    final armR = Path()
      ..moveTo(cx + u * 1.45, u * 1.55)
      ..lineTo(cx + u * 1.75, u * 3.5)
      ..lineTo(cx + u * 1.8, u * 5.0)
      ..lineTo(cx + u * 1.45, u * 5.0)
      ..lineTo(cx + u * 1.4, u * 3.5)
      ..lineTo(cx + u * 1.2, u * 1.7)
      ..close();

    // Base fill for whole body (dim)
    final basePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = dimColor;
    canvas.drawPath(outline, basePaint);
    canvas.drawPath(armL, basePaint);
    canvas.drawPath(armR, basePaint);

    // Worked-muscle overlays
    if (isFront) {
      _paintFrontMuscles(canvas, cx, u);
    } else {
      _paintBackMuscles(canvas, cx, u);
    }

    // Outline stroke for silhouette definition
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = outlineColor;
    canvas.drawPath(outline, strokePaint);
    canvas.drawPath(armL, strokePaint);
    canvas.drawPath(armR, strokePaint);

    // Label
    final tp = TextPainter(
      text: TextSpan(
        text: isFront ? 'FRONT' : 'BACK',
        style: TextStyle(
          fontSize: 9,
          letterSpacing: 2,
          color: outlineColor,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, h - tp.height - 2));

    canvas.restore();
  }

  void _paintFrontMuscles(Canvas canvas, double cx, double u) {
    // Chest (left + right pec)
    _fillRegion(canvas, 'chest', [
      _pecPath(cx, u, isLeft: true),
      _pecPath(cx, u, isLeft: false),
    ]);
    // Shoulders (delts — front)
    _fillRegion(canvas, 'shoulders', [
      _deltoidPath(cx, u, isLeft: true, isFront: true),
      _deltoidPath(cx, u, isLeft: false, isFront: true),
    ]);
    // Biceps
    _fillRegion(canvas, 'biceps', [
      _bicepPath(cx, u, isLeft: true),
      _bicepPath(cx, u, isLeft: false),
    ]);
    // Forearms (front)
    _fillRegion(canvas, 'forearms', [
      _forearmPath(cx, u, isLeft: true),
      _forearmPath(cx, u, isLeft: false),
    ]);
    // Core (abs)
    _fillRegion(canvas, 'core', [_absPath(cx, u)]);
    // Hip flexors
    _fillRegion(canvas, 'hips', [_hipsPath(cx, u)]);
    // Quadriceps
    _fillRegion(canvas, 'quadriceps', [
      _quadPath(cx, u, isLeft: true),
      _quadPath(cx, u, isLeft: false),
    ]);
    // If only 'legs' provided (generic), use quads as a proxy
    if (!musclesWorked.containsKey('quadriceps') &&
        musclesWorked.containsKey('legs')) {
      _fillRegionForceKey(canvas, 'legs', [
        _quadPath(cx, u, isLeft: true),
        _quadPath(cx, u, isLeft: false),
      ]);
    }
    // Calves (front)
    _fillRegion(canvas, 'calves', [
      _calfFrontPath(cx, u, isLeft: true),
      _calfFrontPath(cx, u, isLeft: false),
    ]);
  }

  void _paintBackMuscles(Canvas canvas, double cx, double u) {
    // Trapezius + upper back
    _fillRegion(canvas, 'back', [_upperBackPath(cx, u)]);
    // Lats (part of back)
    _fillRegionForceKey(canvas, 'back', [
      _latsPath(cx, u, isLeft: true),
      _latsPath(cx, u, isLeft: false),
    ]);
    // Shoulders (rear delts)
    _fillRegion(canvas, 'shoulders', [
      _deltoidPath(cx, u, isLeft: true, isFront: false),
      _deltoidPath(cx, u, isLeft: false, isFront: false),
    ]);
    // Triceps
    _fillRegion(canvas, 'triceps', [
      _tricepPath(cx, u, isLeft: true),
      _tricepPath(cx, u, isLeft: false),
    ]);
    // Lower back
    _fillRegion(canvas, 'lower_back', [_lowerBackPath(cx, u)]);
    // Glutes
    _fillRegion(canvas, 'glutes', [
      _glutePath(cx, u, isLeft: true),
      _glutePath(cx, u, isLeft: false),
    ]);
    // Hamstrings
    _fillRegion(canvas, 'hamstrings', [
      _hamstringPath(cx, u, isLeft: true),
      _hamstringPath(cx, u, isLeft: false),
    ]);
    if (!musclesWorked.containsKey('hamstrings') &&
        musclesWorked.containsKey('legs')) {
      _fillRegionForceKey(canvas, 'legs', [
        _hamstringPath(cx, u, isLeft: true),
        _hamstringPath(cx, u, isLeft: false),
      ]);
    }
    // Calves (back)
    _fillRegion(canvas, 'calves', [
      _calfBackPath(cx, u, isLeft: true),
      _calfBackPath(cx, u, isLeft: false),
    ]);
  }

  // Fill a region only if [musclesWorked] contains the key.
  void _fillRegion(Canvas canvas, String key, List<Path> paths) {
    final sets = musclesWorked[key] ?? 0;
    if (sets <= 0) return;
    _fillRegionForceKey(canvas, key, paths);
  }

  // Fill regardless (caller already validated).
  void _fillRegionForceKey(Canvas canvas, String key, List<Path> paths) {
    final sets = musclesWorked[key] ?? 1;
    // Intensity: 0.6..1.0 linearly up to 10 sets.
    final intensity = 0.6 + (sets.clamp(1, 10) / 10) * 0.4;
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: [
          fillStart.withValues(alpha: intensity),
          fillEnd.withValues(alpha: intensity),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, 200, 400));
    for (final p in paths) {
      canvas.drawPath(p, paint);
    }
  }

  // ─── Region path builders (front) ─────────────────────────

  Path _pecPath(double cx, double u, {required bool isLeft}) {
    final sign = isLeft ? -1.0 : 1.0;
    return Path()
      ..moveTo(cx + sign * 0.15 * u, 1.4 * u)
      ..lineTo(cx + sign * 1.25 * u, 1.55 * u)
      ..lineTo(cx + sign * 1.2 * u, 2.35 * u)
      ..lineTo(cx + sign * 0.2 * u, 2.3 * u)
      ..close();
  }

  Path _deltoidPath(double cx, double u, {required bool isLeft, required bool isFront}) {
    final sign = isLeft ? -1.0 : 1.0;
    return Path()
      ..moveTo(cx + sign * 1.15 * u, 1.35 * u)
      ..lineTo(cx + sign * 1.5 * u, 1.5 * u)
      ..lineTo(cx + sign * 1.55 * u, 2.15 * u)
      ..lineTo(cx + sign * 1.2 * u, 2.0 * u)
      ..close();
  }

  Path _bicepPath(double cx, double u, {required bool isLeft}) {
    final sign = isLeft ? -1.0 : 1.0;
    return Path()
      ..moveTo(cx + sign * 1.48 * u, 2.1 * u)
      ..lineTo(cx + sign * 1.75 * u, 2.1 * u)
      ..lineTo(cx + sign * 1.78 * u, 3.3 * u)
      ..lineTo(cx + sign * 1.48 * u, 3.3 * u)
      ..close();
  }

  Path _forearmPath(double cx, double u, {required bool isLeft}) {
    final sign = isLeft ? -1.0 : 1.0;
    return Path()
      ..moveTo(cx + sign * 1.48 * u, 3.5 * u)
      ..lineTo(cx + sign * 1.78 * u, 3.5 * u)
      ..lineTo(cx + sign * 1.76 * u, 4.8 * u)
      ..lineTo(cx + sign * 1.5 * u, 4.8 * u)
      ..close();
  }

  Path _absPath(double cx, double u) {
    return Path()
      ..moveTo(cx - 0.55 * u, 2.45 * u)
      ..lineTo(cx + 0.55 * u, 2.45 * u)
      ..lineTo(cx + 0.5 * u, 3.9 * u)
      ..lineTo(cx - 0.5 * u, 3.9 * u)
      ..close();
  }

  Path _hipsPath(double cx, double u) {
    return Path()
      ..moveTo(cx - 1.05 * u, 4.15 * u)
      ..lineTo(cx + 1.05 * u, 4.15 * u)
      ..lineTo(cx + 1.15 * u, 4.8 * u)
      ..lineTo(cx - 1.15 * u, 4.8 * u)
      ..close();
  }

  Path _quadPath(double cx, double u, {required bool isLeft}) {
    final sign = isLeft ? -1.0 : 1.0;
    return Path()
      ..moveTo(cx + sign * 0.15 * u, 5.3 * u)
      ..lineTo(cx + sign * 1.2 * u, 5.3 * u)
      ..lineTo(cx + sign * 1.05 * u, 7.1 * u)
      ..lineTo(cx + sign * 0.25 * u, 7.1 * u)
      ..close();
  }

  Path _calfFrontPath(double cx, double u, {required bool isLeft}) {
    final sign = isLeft ? -1.0 : 1.0;
    return Path()
      ..moveTo(cx + sign * 0.35 * u, 7.35 * u)
      ..lineTo(cx + sign * 1.0 * u, 7.35 * u)
      ..lineTo(cx + sign * 0.9 * u, 8.8 * u)
      ..lineTo(cx + sign * 0.45 * u, 8.8 * u)
      ..close();
  }

  // ─── Region path builders (back) ──────────────────────────

  Path _upperBackPath(double cx, double u) {
    return Path()
      ..moveTo(cx - 1.2 * u, 1.5 * u)
      ..lineTo(cx + 1.2 * u, 1.5 * u)
      ..lineTo(cx + 1.0 * u, 2.6 * u)
      ..lineTo(cx - 1.0 * u, 2.6 * u)
      ..close();
  }

  Path _latsPath(double cx, double u, {required bool isLeft}) {
    final sign = isLeft ? -1.0 : 1.0;
    return Path()
      ..moveTo(cx + sign * 0.35 * u, 2.7 * u)
      ..lineTo(cx + sign * 1.3 * u, 2.6 * u)
      ..lineTo(cx + sign * 1.25 * u, 3.8 * u)
      ..lineTo(cx + sign * 0.4 * u, 3.8 * u)
      ..close();
  }

  Path _tricepPath(double cx, double u, {required bool isLeft}) {
    final sign = isLeft ? -1.0 : 1.0;
    return Path()
      ..moveTo(cx + sign * 1.48 * u, 2.1 * u)
      ..lineTo(cx + sign * 1.78 * u, 2.1 * u)
      ..lineTo(cx + sign * 1.76 * u, 3.3 * u)
      ..lineTo(cx + sign * 1.48 * u, 3.3 * u)
      ..close();
  }

  Path _lowerBackPath(double cx, double u) {
    return Path()
      ..moveTo(cx - 0.9 * u, 3.9 * u)
      ..lineTo(cx + 0.9 * u, 3.9 * u)
      ..lineTo(cx + 0.85 * u, 4.6 * u)
      ..lineTo(cx - 0.85 * u, 4.6 * u)
      ..close();
  }

  Path _glutePath(double cx, double u, {required bool isLeft}) {
    final sign = isLeft ? -1.0 : 1.0;
    return Path()
      ..moveTo(cx + sign * 0.1 * u, 4.65 * u)
      ..lineTo(cx + sign * 1.2 * u, 4.65 * u)
      ..lineTo(cx + sign * 1.1 * u, 5.4 * u)
      ..lineTo(cx + sign * 0.15 * u, 5.4 * u)
      ..close();
  }

  Path _hamstringPath(double cx, double u, {required bool isLeft}) {
    final sign = isLeft ? -1.0 : 1.0;
    return Path()
      ..moveTo(cx + sign * 0.2 * u, 5.5 * u)
      ..lineTo(cx + sign * 1.15 * u, 5.5 * u)
      ..lineTo(cx + sign * 1.0 * u, 7.0 * u)
      ..lineTo(cx + sign * 0.3 * u, 7.0 * u)
      ..close();
  }

  Path _calfBackPath(double cx, double u, {required bool isLeft}) {
    final sign = isLeft ? -1.0 : 1.0;
    return Path()
      ..moveTo(cx + sign * 0.4 * u, 7.35 * u)
      ..lineTo(cx + sign * 0.95 * u, 7.35 * u)
      ..lineTo(cx + sign * 0.85 * u, 8.5 * u)
      ..lineTo(cx + sign * 0.5 * u, 8.5 * u)
      ..close();
  }

  @override
  bool shouldRepaint(AnatomyPainter oldDelegate) {
    return oldDelegate.musclesWorked != musclesWorked ||
        oldDelegate.fillStart != fillStart ||
        oldDelegate.fillEnd != fillEnd;
  }
}
