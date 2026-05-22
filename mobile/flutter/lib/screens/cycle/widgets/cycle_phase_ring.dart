/// The headline phase ring for the Cycle "Today" tab.
///
/// A circular progress ring whose sweep is the position within the current
/// cycle, segmented by the four phases. The hub shows the current phase
/// glyph, the cycle day, and a "period in N days" / "fertile now" / "period
/// N days late" line. An "Ask coach about this" affordance seeds the chat
/// with the prediction.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../data/models/hormonal_health.dart';
import '../cycle_chat.dart';
import '../cycle_visuals.dart';

class CyclePhaseRing extends StatelessWidget {
  final CyclePrediction prediction;
  final Color accent;

  const CyclePhaseRing({
    super.key,
    required this.prediction,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);

    final phase = prediction.currentPhase;
    final day = prediction.currentCycleDay ?? 1;
    final avgLen = prediction.stats.avgCycleLength?.round() ??
        CyclePredictorDefaults.cycleLength;
    final progress = (day / avgLen).clamp(0.0, 1.0);
    final seed = day;

    final headline = _headline(seed);

    return Column(
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Phase-segmented ring.
              CustomPaint(
                size: const Size(200, 200),
                painter: _PhaseRingPainter(
                  prediction: prediction,
                  progress: progress,
                  trackColor: fg.withValues(alpha: 0.07),
                ),
              ),
              // Inner hub.
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    CyclePhaseColors.emoji(phase),
                    style: const TextStyle(fontSize: 34),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    phase?.displayName ?? 'No data',
                    style: TextStyle(
                      color: CyclePhaseColors.of(phase),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Cycle day $day',
                    style: TextStyle(
                      color: fg.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 480.ms)
            .scale(
              begin: const Offset(0.92, 0.92),
              end: const Offset(1, 1),
              duration: 480.ms,
              curve: Curves.easeOutBack,
            ),
        const SizedBox(height: 14),
        // Headline + confidence.
        Text(
          headline,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: fg,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: CycleConfidence.color(prediction.confidence),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${CycleConfidence.label(prediction.confidence)} · estimate',
              style: TextStyle(
                color: fg.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Ask coach about the prediction.
        GestureDetector(
          onTap: () => openCycleChat(
            context,
            cycleDatumSeed(
              'my current prediction — $headline, '
              '${phase?.displayName.toLowerCase() ?? 'unknown'} phase, '
              'day $day',
            ),
          ),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_rounded, size: 13, color: accent),
                const SizedBox(width: 6),
                Text(
                  'Ask coach about this',
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _headline(int seed) {
    if (prediction.isLate) {
      return CycleCopy.lateBy(prediction.periodLateBy ?? 0, seed);
    }
    if (prediction.inFertileWindow) {
      return CycleCopy.fertileNow(seed);
    }
    if (prediction.inPeriod) {
      return 'Period in progress';
    }
    final until = prediction.daysUntilNextPeriod;
    if (until != null) {
      return CycleCopy.periodIn(until, seed);
    }
    return CyclePhaseColors.tagline(prediction.currentPhase);
  }
}

/// Default constants exposed for the ring (mirrors the predictor defaults so
/// the ring never imports the whole predictor).
class CyclePredictorDefaults {
  CyclePredictorDefaults._();
  static const int cycleLength = 28;
}

/// Paints the four-phase segmented ring with a progress arc.
class _PhaseRingPainter extends CustomPainter {
  final CyclePrediction prediction;
  final double progress;
  final Color trackColor;

  _PhaseRingPainter({
    required this.prediction,
    required this.progress,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const stroke = 14.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background track.
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Phase segments — fractions of the cycle.
    final avgLen = prediction.stats.avgCycleLength?.round() ??
        CyclePredictorDefaults.cycleLength;
    final periodLen = prediction.stats.avgPeriodLength?.round() ?? 5;
    final lastStart = prediction.lastPeriodStart;
    final fStart = prediction.fertileWindowStart;
    final fEnd = prediction.fertileWindowEnd;

    int fertileStartDay = (avgLen * 0.42).round();
    int fertileEndDay = (avgLen * 0.58).round();
    if (lastStart != null && fStart != null && fEnd != null) {
      fertileStartDay =
          fStart.difference(lastStart).inDays.clamp(1, avgLen);
      fertileEndDay =
          fEnd.difference(lastStart).inDays.clamp(fertileStartDay, avgLen);
    }

    final segments = <_Seg>[
      _Seg(0, periodLen, CyclePhaseColors.menstrual),
      _Seg(periodLen, fertileStartDay, CyclePhaseColors.follicular),
      _Seg(fertileStartDay, fertileEndDay, CyclePhaseColors.ovulation),
      _Seg(fertileEndDay, avgLen, CyclePhaseColors.luteal),
    ];

    const start = -math.pi / 2; // 12 o'clock
    const gap = 0.04; // small visual gap between segments
    for (final seg in segments) {
      final a0 = start + (seg.from / avgLen) * 2 * math.pi + gap / 2;
      final a1 = start + (seg.to / avgLen) * 2 * math.pi - gap / 2;
      if (a1 <= a0) continue;
      final paint = Paint()
        ..color = seg.color.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, a0, a1 - a0, false, paint);
    }

    // Progress marker dot at the current cycle position.
    final angle = start + progress * 2 * math.pi;
    final dot = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    canvas.drawCircle(
      dot,
      stroke / 2 + 3,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      dot,
      stroke / 2,
      Paint()
        ..color = CyclePhaseColors.of(prediction.currentPhase),
    );
  }

  @override
  bool shouldRepaint(_PhaseRingPainter old) =>
      old.progress != progress ||
      old.prediction != prediction ||
      old.trackColor != trackColor;
}

class _Seg {
  final int from;
  final int to;
  final Color color;
  _Seg(this.from, this.to, this.color);
}
