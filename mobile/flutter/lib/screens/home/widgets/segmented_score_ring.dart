import 'dart:math' as math;
import 'package:flutter/material.dart';

/// One weighted arc of the [SegmentedScoreRing].
class ScoreRingSegment {
  /// Fraction of the ring this segment occupies (0–1). The segments of a
  /// ring sum to ~1.0 — they are the renormalized contributor weights.
  final double weight;

  /// How much of this segment is filled, 0–1.
  final double completion;

  /// The filled (done) colour.
  final Color color;

  /// The unfilled "tinted track" colour — a pale tint of [color], so each
  /// segment reads as its own zone even before anything is done.
  final Color trackColor;

  const ScoreRingSegment({
    required this.weight,
    required this.completion,
    required this.color,
    required this.trackColor,
  });
}

/// A single ring split into weighted segments — the Today Score ring.
///
/// Each segment draws a pale tinted track (the goal) plus a solid arc (done),
/// with a small gap between segments and round caps. The segment count adapts
/// to whatever applies today (3 on a training day, 2 on a rest day, etc.).
class SegmentedScoreRing extends StatelessWidget {
  final List<ScoreRingSegment> segments;
  final double size;
  final double strokeWidth;
  final Widget? center;

  const SegmentedScoreRing({
    super.key,
    required this.segments,
    this.size = 132,
    this.strokeWidth = 16,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _SegmentedRingPainter(
              segments: segments,
              strokeWidth: strokeWidth,
            ),
          ),
          if (center != null) center!,
        ],
      ),
    );
  }
}

class _SegmentedRingPainter extends CustomPainter {
  final List<ScoreRingSegment> segments;
  final double strokeWidth;

  _SegmentedRingPainter({required this.segments, required this.strokeWidth});

  /// Gap between adjacent segments, in degrees.
  static const double _gapDeg = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final usableDeg = 360.0 - _gapDeg * segments.length;
    double startDeg = -90.0; // 12 o'clock

    for (final seg in segments) {
      final sweepDeg = seg.weight.clamp(0.0, 1.0) * usableDeg;

      // Tinted track — the full segment extent.
      final trackPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = seg.trackColor;
      canvas.drawArc(rect, _rad(startDeg), _rad(sweepDeg), false, trackPaint);

      // Done arc.
      final done = seg.completion.clamp(0.0, 1.0);
      if (done > 0) {
        final donePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = seg.color;
        canvas.drawArc(
          rect,
          _rad(startDeg),
          _rad(sweepDeg * done),
          false,
          donePaint,
        );
      }

      startDeg += sweepDeg + _gapDeg;
    }
  }

  double _rad(double deg) => deg * math.pi / 180.0;

  @override
  bool shouldRepaint(_SegmentedRingPainter old) =>
      old.strokeWidth != strokeWidth ||
      !_sameSegments(old.segments, segments);

  bool _sameSegments(List<ScoreRingSegment> a, List<ScoreRingSegment> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].weight != b[i].weight ||
          a[i].completion != b[i].completion ||
          a[i].color != b[i].color ||
          a[i].trackColor != b[i].trackColor) {
        return false;
      }
    }
    return true;
  }
}
