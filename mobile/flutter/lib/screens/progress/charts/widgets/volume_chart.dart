import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../data/models/progress_charts.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../widgets/trends/trend_chart.dart';
import '../../../../widgets/trends/trend_correlation.dart';

/// Volume Trends — weekly training volume rendered through the shared
/// [TrendChart] engine so it gets the same EWMA smoothing, scrub tooltip,
/// pinch-zoom and theming as every other trend surface (Phase G5a).
class VolumeChart extends ConsumerWidget {
  final VolumeProgressionData data;

  const VolumeChart({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = ref.colors(context);
    final sortedData = data.sortedData;

    if (sortedData.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate max value to detect the all-zero-volume case.
    final maxVolume = sortedData
        .map((e) => e.totalVolumeKg)
        .reduce((a, b) => a > b ? a : b);

    // Edge case: weeks have workout counts but every set's weight aggregated
    // to 0 (cardio/yoga sessions, bodyweight-only training, or — historically
    // — a unit-conversion bug between the lb-logged set and the kg-keyed
    // backend view). Render an explicit empty state instead of a silent
    // gray rectangle so the user knows the screen isn't broken.
    if (maxVolume <= 0) {
      return _card(
        colors,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(colors, l10n),
            const SizedBox(height: 24),
            Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                child: Column(
                  children: [
                    Icon(Icons.fitness_center,
                        size: 36,
                        color: colors.textMuted.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    Text(
                      l10n.volumeChartNoWeightedVolumeYet,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.volumeChartLogAFewWeighted,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // One TrendPoint per week with a real start date and positive volume.
    final points = <TrendPoint>[
      for (final week in sortedData)
        if (week.weekStartDate != null && week.totalVolumeKg > 0)
          TrendPoint(date: week.weekStartDate!, value: week.totalVolumeKg),
    ];

    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    return _card(
      colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(colors, l10n),
          const SizedBox(height: 16),
          RepaintBoundary(
            child: TrendChart(
              accent: colors.accent,
              primary: TrendChartSeries(
                label: l10n.volumeChartVolumeTrends,
                unit: 'kg',
                points: points,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(ThemeColors colors, AppLocalizations l10n) {
    return Row(
      children: [
        Icon(Icons.bar_chart, color: colors.accent),
        const SizedBox(width: 8),
        Text(
          l10n.volumeChartVolumeTrends,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _card(ThemeColors colors, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
      ),
      child: child,
    );
  }
}
