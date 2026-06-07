import 'package:flutter/material.dart';

import '../shareable_data.dart';

/// One metric line on a shared Custom Trend — its label, latest formatted
/// value, and the colour the user assigned it on the chart.
class TrendShareMetric {
  final String label;
  final String value;
  final Color color;

  const TrendShareMetric({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// Builds a [Shareable] for the Custom Trends screen.
///
/// Maps the live trend (its title, range, primary hero value, and every
/// selected metric's latest value + colour) onto the shared
/// [ShareableKind.progressCharts] template family so the trend ships through
/// the same branded gallery (story / portrait / square, watermark) as every
/// other share surface — no bespoke share pipeline.
class TrendsAdapter {
  static Shareable build({
    required String title,
    required String periodLabel,
    required Color accent,
    required List<TrendShareMetric> metrics,
    num? heroValue,
    String heroUnit = '',
    String? userDisplayName,
  }) {
    return Shareable(
      kind: ShareableKind.progressCharts,
      title: title,
      periodLabel: periodLabel,
      heroValue: heroValue,
      heroUnitSingular: heroUnit,
      highlights: [
        for (final m in metrics)
          ShareableMetric(
            label: m.label.toUpperCase(),
            value: m.value,
            accent: m.color,
          ),
      ],
      accentColor: accent,
      userDisplayName: userDisplayName,
    );
  }
}
