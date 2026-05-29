/// F3.40 — Mindful minutes ring showing today's meditation/breathwork
/// minutes vs a soft daily target. Reads the real aggregate from
/// [mindfulnessTodayProvider] (in-app logs + iOS HealthKit "Mindful Minutes",
/// merged); taps open the guided session player which logs on completion.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/mindfulness_provider.dart';
import '../../../../data/services/haptic_service.dart';

class MindfulMinutesRing extends ConsumerWidget {
  const MindfulMinutesRing({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);

    final today = ref.watch(mindfulnessTodayProvider).asData?.value;
    final hasData = today != null;
    final minutes = today?.minutes ?? 0;
    final target = today?.targetMinutes ?? 10;
    final progress = today?.progress ?? 0.0;
    final goalMet = today?.goalMet ?? false;

    // Subtitle is honest about state: a real total when we have data, a CTA
    // otherwise — never a fabricated "0 / 10".
    final subtitle = !hasData
        ? 'Start a 5-min session'
        : goalMet
            ? '$minutes min today · goal met'
            : '$minutes / $target min today';

    return GestureDetector(
      onTap: () {
        HapticService.light();
        // Breathwork preset; the player logs the real elapsed time.
        context.push('/mindfulness/session?source=breathwork&duration=5');
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.cardBorder),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CustomPaint(
                painter: _RingPainter(
                  progress: progress,
                  bg: c.cardBorder,
                  fg: c.accent,
                ),
                child: Center(
                  child: Text(
                    hasData ? '$minutes' : '–',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Mindful minutes',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: c.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color bg;
  final Color fg;
  _RingPainter({required this.progress, required this.bg, required this.fg});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 4.5;
    final r = (math.min(size.width, size.height) - stroke) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final bgP = Paint()
      ..color = bg
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final fgP = Paint()
      ..color = fg
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, r, bgP);
    final sweep = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -math.pi / 2,
      sweep,
      false,
      fgP,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.bg != bg || old.fg != fg;
}
