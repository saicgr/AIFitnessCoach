/// A resolved, display-ready snapshot of one metric for the home Metric
/// Summary deck and the "My Space → Metrics" rows.
///
/// This is a *pure* data class — it holds already-computed values and an
/// optional sparkline series. The composition from live providers
/// (activity / sleep / nutrition / hydration / weight / readiness / trends)
/// lives in `metric_value_provider.dart`; presentation widgets only ever
/// consume this object so they stay testable and provider-agnostic.
library;

import 'package:flutter/painting.dart';

/// A single (x, y) sample for a sparkline / mini-chart. [x] is a 0..1
/// normalised position along the time axis; [y] is a 0..1 normalised value.
class MetricSpark {
  final double x;
  final double y;
  const MetricSpark(this.x, this.y);
}

class MetricValue {
  /// Stable metric id (matches `RingKindX.id`, e.g. `train`, `move`).
  final String id;

  /// Human label, e.g. "Steps", "Resting HR".
  final String label;

  /// The headline numeric value, already in display units. Null = no data.
  final double? value;

  /// Pre-formatted headline string when a raw double doesn't fit
  /// (e.g. "7h 36m" for sleep, "184.2" for weight). When null the renderer
  /// formats [value] itself.
  final String? displayValue;

  /// Unit suffix, e.g. "kcal", "bpm", "oz", "%". May be empty.
  final String unit;

  /// Goal/target in the same units, when the metric has one.
  final double? goal;

  /// Completion fraction 0..1 for ring/gauge tiles, when applicable.
  final double? pct;

  /// Accent color (resolved: override or catalog color).
  final Color color;

  /// Optional short delta/trend label, e.g. "↓ 0.8 this week".
  final String? deltaLabel;

  /// Optional normalised series for line/area/sparkline tiles.
  final List<MetricSpark>? series;

  /// True when the metric has no data today (renders an empty / connect state).
  final bool isEmpty;

  const MetricValue({
    required this.id,
    required this.label,
    required this.unit,
    required this.color,
    this.value,
    this.displayValue,
    this.goal,
    this.pct,
    this.deltaLabel,
    this.series,
    this.isEmpty = false,
  });

  /// Empty/"no data" placeholder for a metric.
  factory MetricValue.empty({
    required String id,
    required String label,
    required Color color,
    String unit = '',
  }) => MetricValue(
    id: id,
    label: label,
    unit: unit,
    color: color,
    isEmpty: true,
  );

  /// The string the tile shows as its big number.
  String get headline {
    if (isEmpty) return '—';
    if (displayValue != null) return displayValue!;
    final v = value;
    if (v == null) return '—';
    if (v >= 1000) {
      // 6,540 style grouping for large counts.
      final s = v.round().toString();
      final buf = StringBuffer();
      for (var i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
        buf.write(s[i]);
      }
      return buf.toString();
    }
    return v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
  }
}
