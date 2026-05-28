/// F3.28 — Wake-time consistency tile.
///
/// Surfaces 7-day standard deviation of wake times. A tight stddev (<30 min)
/// is associated with better circadian alignment. Collapses when no data.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/sleep_detail_provider.dart';

/// (stddev, mean) computed directly from the real `sleepHistoryProvider`
/// (Health Connect / HealthKit nightly history). We take the most recent 7
/// nights that have a known wake time and compute the circular standard
/// deviation of wake minutes-from-midnight (so a 23:55 / 00:05 pair stays
/// tight rather than appearing 23h45m apart).
///
/// Returns (null, null) when fewer than 3 wake times are available — the
/// chip then collapses honestly rather than showing a misleading "0 min".
final wakeConsistencySignalProvider =
    Provider.autoDispose<({double? stddevMinutes, String? meanWake})>((ref) {
  final async = ref.watch(sleepHistoryProvider);
  return async.maybeWhen(
    data: (h) {
      final wakeMinutes = <int>[];
      for (final n in h.nights) {
        if (wakeMinutes.length >= 7) break;
        final wake = n.mainSleep.wakeTime;
        if (wake == null) continue;
        wakeMinutes.add(wake.hour * 60 + wake.minute);
      }
      if (wakeMinutes.length < 3) {
        return (stddevMinutes: null, meanWake: null);
      }
      // Circular mean on the 24h clock.
      var sumSin = 0.0;
      var sumCos = 0.0;
      for (final m in wakeMinutes) {
        final theta = (m / 1440) * 2 * math.pi;
        sumSin += math.sin(theta);
        sumCos += math.cos(theta);
      }
      var meanTheta =
          math.atan2(sumSin / wakeMinutes.length, sumCos / wakeMinutes.length);
      if (meanTheta < 0) meanTheta += 2 * math.pi;
      final meanMin = ((meanTheta / (2 * math.pi)) * 1440).round() % 1440;

      // Stddev folded across the midnight wrap.
      var variance = 0.0;
      for (final m in wakeMinutes) {
        var d = m - meanMin;
        if (d > 720) d -= 1440;
        if (d < -720) d += 1440;
        variance += d * d;
      }
      final sd = math.sqrt(variance / wakeMinutes.length);
      final hh = (meanMin ~/ 60).toString().padLeft(2, '0');
      final mm = (meanMin % 60).toString().padLeft(2, '0');
      return (stddevMinutes: sd, meanWake: '$hh:$mm');
    },
    orElse: () => (stddevMinutes: null, meanWake: null),
  );
});

class WakeConsistencyTile extends ConsumerWidget {
  /// 7-day stddev of wake times (minutes). Null → collapsed.
  final double? stddevMinutes;

  /// Mean wake time "HH:mm". Optional secondary label.
  final String? meanWake;

  const WakeConsistencyTile({
    super.key,
    this.stddevMinutes,
    this.meanWake,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signal = ref.watch(wakeConsistencySignalProvider);
    final sd = stddevMinutes ?? signal.stddevMinutes;
    if (sd == null) return const SizedBox.shrink();
    final c = ThemeColors.of(context);
    final mean = meanWake ?? signal.meanWake;

    final label = sd <= 20
        ? 'Locked in'
        : sd <= 45
            ? 'Steady'
            : sd <= 75
                ? 'Drifting'
                : 'Erratic';
    final labelColor = sd <= 45 ? c.success : (sd <= 75 ? c.warning : c.error);

    return Container(
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
              Icon(Icons.alarm, size: 16, color: c.accent),
              const SizedBox(width: 6),
              Text(
                'Wake consistency',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '±${sd.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'min',
                style: TextStyle(fontSize: 12, color: c.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            mean != null ? '$label · avg $mean' : label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}
