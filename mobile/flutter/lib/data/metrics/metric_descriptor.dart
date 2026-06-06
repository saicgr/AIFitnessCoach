import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/trend_series_provider.dart';
import '../../widgets/trends/premium_metric_chart.dart';

/// How a metric's window is summarised in the big-number header.
enum MetricAgg {
  /// Latest reading (weight, body fat, resting HR).
  latest,

  /// Average of the per-day values (sleep duration, HR).
  avgPerDay,

  /// Daily values are totals; header shows the per-day average of them
  /// (steps, calories, active energy).
  sumPerDay,
}

/// A switchable sub-view of a metric (e.g. Nutrition → Calories / Protein /
/// Carbs / Fat / Fiber). Selecting a chip re-scopes the chart + list + header
/// to this series. Only sub-views backed by a real [series] are ever shown.
@immutable
class MetricSubView {
  final String label;
  final TrendMetric series;
  final String unit;
  final PremiumChartType chart;
  final double? Function(WidgetRef ref)? goalOf;

  const MetricSubView({
    required this.label,
    required this.series,
    required this.unit,
    this.chart = PremiumChartType.bar,
    this.goalOf,
  });
}

/// A single source of truth describing one metric for the universal detail
/// screen. The registry ([metricRegistry]) maps an id → descriptor, and every
/// entry point (home carousel, Stats & Scores rows) resolves to one of these.
@immutable
class MetricDescriptor {
  /// url-safe id (route param), e.g. 'steps', 'weight', 'train', 'today'.
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final String unit;
  final MetricAgg agg;

  /// Default chart style; the user can override via the in-screen selector.
  final PremiumChartType defaultChart;

  /// Primary time-series source. Null → the screen shows the big number + an
  /// honest note + the deep link, never a fabricated chart.
  final TrendMetric? series;

  /// True when higher is better (steps, sleep). False when lower is better
  /// (resting HR, body fat, weight toward a target). Drives goal-met colouring.
  final bool goalDirectionUp;

  /// Resolves the goal value (nullable) from live providers, or null.
  final double? Function(WidgetRef ref)? goalOf;

  /// Switchable sub-views (chip row). Empty → no chips.
  final List<MetricSubView> subViews;

  /// The home ring this metric maps to (for the today big-number + colour).
  final String? ringName;

  /// "View full X" deep link to a richer specialised screen, when one exists.
  final String? fullScreenRoute;

  const MetricDescriptor({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.unit,
    this.agg = MetricAgg.avgPerDay,
    this.defaultChart = PremiumChartType.line,
    this.series,
    this.goalDirectionUp = true,
    this.goalOf,
    this.subViews = const [],
    this.ringName,
    this.fullScreenRoute,
  });
}
