import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/providers/heart_rate_stream_provider.dart';

/// Apple Watch / Strava–style HR summary for the workout-complete screen.
///
/// Renders:
///  - Line chart of bpm over workout duration
///  - Peak HR marker + label
///  - Average HR dashed line
///  - Zone bands (Z1..Z5 by HRmax)
///  - Time-in-zone stacked bar
///  - Stats row (Avg / Peak / Min / Recovery)
///
/// Reads from `heartRateBufferProvider`. When the buffer is empty (no
/// strap connected or HealthKit denied) renders an empty-state CTA.
class PostWorkoutHrGraph extends ConsumerWidget {
  /// User's age — used to compute HRmax = 220 - age. Falls back to 35
  /// when null (yields HRmax 185, a reasonable default for adult lifters).
  final int? age;
  const PostWorkoutHrGraph({super.key, this.age});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final samples = ref.watch(heartRateBufferProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (samples.length < 2) {
      return _EmptyState(isDark: isDark);
    }

    final hrMax = 220 - (age ?? 35);
    final bpms = samples.map((s) => s.bpm).toList();
    final peak = bpms.reduce((a, b) => a > b ? a : b);
    final low = bpms.reduce((a, b) => a < b ? a : b);
    final avg = (bpms.reduce((a, b) => a + b) / bpms.length).round();

    final start = samples.first.t;
    final spots = <FlSpot>[];
    for (final s in samples) {
      final x = s.t.difference(start).inSeconds.toDouble();
      spots.add(FlSpot(x, s.bpm.toDouble()));
    }
    final maxX = spots.last.x;

    // Zone time accumulation (seconds in each zone)
    final zoneSeconds = List<double>.filled(5, 0);
    for (int i = 1; i < samples.length; i++) {
      final z = _zoneFor(samples[i].bpm, hrMax);
      final dt = samples[i].t.difference(samples[i - 1].t).inSeconds;
      zoneSeconds[z] += dt.toDouble();
    }
    final totalZ = zoneSeconds.fold<double>(0, (a, b) => a + b);

    // Recovery: drop in BPM in the 60s after the peak sample
    int recovery = 0;
    final peakIdx = bpms.indexOf(peak);
    if (peakIdx >= 0) {
      final peakT = samples[peakIdx].t;
      final after = samples.firstWhere(
        (s) => s.t.difference(peakT).inSeconds >= 60,
        orElse: () => samples.last,
      );
      recovery = peak - after.bpm;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_rounded, size: 18, color: Color(0xFFEF4444)),
              const SizedBox(width: 6),
              Text(
                'Heart rate',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColorsLight.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: (low - 10).toDouble().clamp(40, 220),
                maxY: (peak + 10).toDouble().clamp(60, 240),
                minX: 0,
                maxX: maxX,
                titlesData: const FlTitlesData(show: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                rangeAnnotations: RangeAnnotations(
                  horizontalRangeAnnotations: [
                    HorizontalRangeAnnotation(
                      y1: hrMax * 0.5,
                      y2: hrMax * 0.6,
                      color: const Color(0xFF94A3B8).withOpacity(0.10),
                    ),
                    HorizontalRangeAnnotation(
                      y1: hrMax * 0.6,
                      y2: hrMax * 0.7,
                      color: const Color(0xFF3B82F6).withOpacity(0.10),
                    ),
                    HorizontalRangeAnnotation(
                      y1: hrMax * 0.7,
                      y2: hrMax * 0.8,
                      color: const Color(0xFF10B981).withOpacity(0.10),
                    ),
                    HorizontalRangeAnnotation(
                      y1: hrMax * 0.8,
                      y2: hrMax * 0.9,
                      color: const Color(0xFFF59E0B).withOpacity(0.12),
                    ),
                    HorizontalRangeAnnotation(
                      y1: hrMax * 0.9,
                      y2: hrMax.toDouble(),
                      color: const Color(0xFFEF4444).withOpacity(0.14),
                    ),
                  ],
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: avg.toDouble(),
                      color: Colors.white.withOpacity(0.5),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        labelResolver: (_) => 'Avg $avg',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFFEF4444),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, _) => spot.y == peak.toDouble(),
                      getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                        radius: 4,
                        color: const Color(0xFFEF4444),
                        strokeColor: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFFEF4444).withOpacity(0.25),
                          const Color(0xFFEF4444).withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Time-in-zone stacked bar (Z1..Z5)
          if (totalZ > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    for (int z = 0; z < 5; z++)
                      Expanded(
                        flex: (zoneSeconds[z] * 1000).round().clamp(0, 1 << 30),
                        child: Container(color: _zoneColors[z]),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stat(label: 'Avg', value: '$avg'),
              _Stat(label: 'Peak', value: '$peak'),
              _Stat(label: 'Min', value: '$low'),
              _Stat(
                label: '60s rec.',
                value: recovery > 0 ? '−$recovery' : '—',
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const _zoneColors = [
    Color(0xFF94A3B8),
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
  ];

  int _zoneFor(int bpm, int hrMax) {
    final pct = bpm / hrMax;
    if (pct < 0.6) return 0;
    if (pct < 0.7) return 1;
    if (pct < 0.8) return 2;
    if (pct < 0.9) return 3;
    return 4;
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.watch_outlined, color: Color(0xFFEF4444)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'No heart-rate data captured. Wear a strap (e.g. Amazfit Helios) and grant Health permissions to see live HR + post-workout graph.',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.textSecondary
                    : AppColorsLight.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
