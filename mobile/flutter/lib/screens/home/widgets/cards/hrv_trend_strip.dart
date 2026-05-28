/// F3.6 — HRV (Heart Rate Variability) 7-day trend strip.
///
/// Compact horizontal sparkline of last-N nightly HRV values. Self-collapses
/// when no series is available. Tapping opens the recovery detail screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';

// TODO(backend): GET /api/v1/health/hrv-series?days=7 — HRV (HEART_RATE_VARIABILITY_RMSSD)
// was dropped from Health Connect scope 2026-05-07 (Google Play minimum-scope policy)
// and the iOS path was dropped in parallel. No Riverpod provider currently holds
// a multi-day HRV series; recovery score derives from RHR + sleep only. Re-enable
// once a backend-side HRV ingestion returns a nightly series.
final hrvTrendSignalProvider = Provider.autoDispose<List<double>?>((ref) => null);

class HrvTrendStrip extends ConsumerWidget {
  /// Nightly HRV (ms RMSSD) — oldest → newest. Empty/null → collapsed.
  final List<double>? series;

  const HrvTrendStrip({super.key, this.series});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = series ?? ref.watch(hrvTrendSignalProvider);
    if (s == null || s.isEmpty) return const SizedBox.shrink();
    final c = ThemeColors.of(context);
    final latest = s.last;
    final prev = s.length > 1 ? s[s.length - 2] : latest;
    final delta = latest - prev;

    return GestureDetector(
      onTap: () => context.go('/recovery'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, size: 16, color: c.accent),
                const SizedBox(width: 6),
                Text(
                  'HRV trend',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${latest.toStringAsFixed(0)} ms',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: CustomPaint(
                size: const Size(double.infinity, 36),
                painter: _SparklinePainter(s, c.accent),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(0)} ms vs last night',
              style: TextStyle(
                fontSize: 11.5,
                color: c.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _SparklinePainter(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 0.001 ? 1.0 : (maxV - minV);

    final dx = size.width / (values.length - 1);
    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = dx * i;
      final y = size.height - ((values[i] - minV) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.values != values || old.color != color;
}
