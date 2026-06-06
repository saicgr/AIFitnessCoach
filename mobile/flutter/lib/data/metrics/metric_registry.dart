import 'package:flutter/material.dart';

import '../../screens/home/widgets/ring_catalog.dart';
import '../../widgets/trends/premium_metric_chart.dart';
import '../providers/nutrition_preferences_provider.dart';
import '../providers/trend_series_provider.dart';
import 'metric_descriptor.dart';

/// Maps a home [RingKind] to its universal metric id (route param). Defaults to
/// the ring's own id so even un-described rings resolve to a (chartless) screen.
String metricIdForRing(RingKind kind) => kind.id;

/// The composite "Today Score" id (the home deck's central ring).
const String kTodayMetricId = 'today';

/// id → descriptor for the universal metric detail screen. Metrics without a
/// `series` render the big number + an honest note + the deep link.
final Map<String, MetricDescriptor> metricRegistry = {
  kTodayMetricId: MetricDescriptor(
    id: kTodayMetricId,
    title: 'Today Score',
    icon: Icons.bolt_rounded,
    color: const Color(0xFF7AD228),
    unit: '',
    agg: MetricAgg.latest,
    defaultChart: PremiumChartType.area,
    series: null, // composite handled specially by the screen
    fullScreenRoute: '/stats',
  ),
  'train': MetricDescriptor(
    id: 'train',
    title: 'Train',
    icon: Icons.fitness_center_rounded,
    color: RingKind.train.color,
    unit: '%',
    agg: MetricAgg.avgPerDay,
    defaultChart: PremiumChartType.line,
    series: TrendMetric.pillarTrain,
    ringName: 'train',
    fullScreenRoute: '/stats',
  ),
  'nourish': MetricDescriptor(
    id: 'nourish',
    title: 'Nourish',
    icon: Icons.restaurant_rounded,
    color: RingKind.nourish.color,
    unit: 'kcal',
    agg: MetricAgg.sumPerDay,
    defaultChart: PremiumChartType.bar,
    series: TrendMetric.calories,
    goalOf: (ref) =>
        ref.watch(nutritionPreferencesProvider).currentCalorieTarget.toDouble(),
    subViews: [
      MetricSubView(
        label: 'Calories',
        series: TrendMetric.calories,
        unit: 'kcal',
        goalOf: (ref) => ref
            .watch(nutritionPreferencesProvider)
            .currentCalorieTarget
            .toDouble(),
      ),
      MetricSubView(
        label: 'Protein',
        series: TrendMetric.protein,
        unit: 'g',
        goalOf: (ref) => ref
            .watch(nutritionPreferencesProvider)
            .currentProteinTarget
            .toDouble(),
      ),
      const MetricSubView(label: 'Carbs', series: TrendMetric.carbs, unit: 'g'),
      const MetricSubView(label: 'Fat', series: TrendMetric.fat, unit: 'g'),
      const MetricSubView(label: 'Fiber', series: TrendMetric.fiber, unit: 'g'),
    ],
    ringName: 'nourish',
    fullScreenRoute: '/nutrition',
  ),
  'move': MetricDescriptor(
    id: 'move',
    title: 'Move',
    icon: Icons.directions_walk_rounded,
    color: RingKind.move.color,
    unit: 'steps',
    agg: MetricAgg.sumPerDay,
    defaultChart: PremiumChartType.bar,
    series: TrendMetric.steps,
    goalOf: (ref) => 10000,
    ringName: 'move',
    fullScreenRoute: '/neat',
  ),
  'sleep': MetricDescriptor(
    id: 'sleep',
    title: 'Sleep',
    icon: Icons.bedtime_rounded,
    color: RingKind.sleep.color,
    unit: 'h',
    agg: MetricAgg.avgPerDay,
    defaultChart: PremiumChartType.line,
    series: TrendMetric.sleepHours,
    goalOf: (ref) => 8,
    ringName: 'sleep',
    fullScreenRoute: '/health/sleep',
  ),
  'active_energy': MetricDescriptor(
    id: 'active_energy',
    title: 'Active Energy',
    icon: Icons.local_fire_department_rounded,
    color: RingKind.activeEnergy.color,
    unit: 'kcal',
    agg: MetricAgg.sumPerDay,
    defaultChart: PremiumChartType.bar,
    series: TrendMetric.activeCalories,
    ringName: 'active_energy',
    fullScreenRoute: '/neat',
  ),
  'recovery': MetricDescriptor(
    id: 'recovery',
    title: 'Recovery',
    icon: Icons.favorite_rounded,
    color: RingKind.recovery.color,
    unit: '/100',
    agg: MetricAgg.avgPerDay,
    defaultChart: PremiumChartType.line,
    series: TrendMetric.readinessScore,
    ringName: 'recovery',
    fullScreenRoute: '/health/combined',
  ),
  'hydration': MetricDescriptor(
    id: 'hydration',
    title: 'Hydration',
    icon: Icons.water_drop_rounded,
    color: RingKind.hydration.color,
    unit: 'oz',
    agg: MetricAgg.sumPerDay,
    defaultChart: PremiumChartType.bar,
    series: TrendMetric.water,
    ringName: 'hydration',
    fullScreenRoute: '/nutrition?tab=2',
  ),
  'weight': MetricDescriptor(
    id: 'weight',
    title: 'Weight',
    icon: Icons.monitor_weight_rounded,
    color: RingKind.weight.color,
    unit: 'lb',
    agg: MetricAgg.latest,
    defaultChart: PremiumChartType.line,
    series: TrendMetric.weight,
    goalDirectionUp: false,
    ringName: 'weight',
    fullScreenRoute: '/measurements/weight',
  ),
  'heart_rate': MetricDescriptor(
    id: 'heart_rate',
    title: 'Heart Rate',
    icon: Icons.monitor_heart_rounded,
    color: RingKind.heartRate.color,
    unit: 'bpm',
    agg: MetricAgg.avgPerDay,
    defaultChart: PremiumChartType.line,
    series: TrendMetric.restingHeartRate,
    goalDirectionUp: false,
    ringName: 'heart_rate',
    fullScreenRoute: '/health/combined',
  ),
  'protein': MetricDescriptor(
    id: 'protein',
    title: 'Protein',
    icon: Icons.egg_alt_rounded,
    color: RingKind.protein.color,
    unit: 'g',
    agg: MetricAgg.sumPerDay,
    defaultChart: PremiumChartType.bar,
    series: TrendMetric.protein,
    goalOf: (ref) =>
        ref.watch(nutritionPreferencesProvider).currentProteinTarget.toDouble(),
    ringName: 'protein',
    fullScreenRoute: '/nutrition',
  ),
};

/// Resolves a descriptor for [id]. For an unknown ring id, falls back to a
/// chartless descriptor (big number + note) coloured from the ring catalog.
MetricDescriptor? metricDescriptorFor(String id) {
  final found = metricRegistry[id];
  if (found != null) return found;
  // Unknown id that still maps to a ring → chartless descriptor.
  final ring = RingKind.values.where((k) => k.id == id).firstOrNull;
  if (ring == null) return null;
  return MetricDescriptor(
    id: id,
    title: ring.label,
    icon: Icons.insights_rounded,
    color: ring.color,
    unit: '',
    ringName: id,
  );
}
