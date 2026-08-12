/// Everything one Home metric tile renders, resolved from live providers.
///
/// The tile grid never talks to a source provider directly: it watches
/// `metricTileDataProvider(tileId)` and gets back a headline, a normalised
/// chart series, and — the piece that did not exist before this build — the
/// metric's distance from its **30-day baseline**.
///
/// The baseline rules, in one place because every tile claims to obey them:
///
///  * The baseline is the mean of the **prior** days in the 30-day window —
///    today is excluded, otherwise today's value drags its own reference.
///  * Fewer than [kMinBaselineHistory] prior days → **no deviation is claimed
///    at all**. No sentence, and no dashed reference line on the chart. An
///    honest quiet sub-line (the metric's own goal/trend text) takes its place.
///  * Colour comes from [SemanticState.resolve] via [MetricValence] — valence,
///    never the sign. Steps below baseline strains; resting HR below baseline
///    supports; weight declares itself neutral and stays grey either way.
///  * No data → no chart. A flat line drawn through one point is a fabricated
///    shape, so [MetricTileData.series] comes back empty and the tile renders
///    its labelled empty state instead.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/stats/state_valence.dart';
import '../../services/score_history_service.dart';
import '../models/metric_value.dart';
import '../services/health_service.dart' show healthSyncProvider;
import 'home_metric_tiles_provider.dart';
import 'metric_value_provider.dart';
import 'today_score_provider.dart';
import 'trend_series_provider.dart';

/// Prior days required before a tile may claim a deviation. Below this the
/// "baseline" would be a rumour.
const int kMinBaselineHistory = 7;

/// Points drawn in a tile's mini-chart (the mockup's 14-day curve).
const int kTileChartPoints = 14;

/// Resolved baseline comparison for one metric.
@immutable
class MetricDeviation {
  /// Mean of the prior days in the window.
  final double baseline;

  /// Today's value, in the same unit as [baseline].
  final double current;

  /// Signed distance in the style's unit (percent / points / absolute).
  final double amount;

  /// Noise floor in [amount]'s unit — inside it the tile reads "on baseline".
  final double epsilon;

  const MetricDeviation({
    required this.baseline,
    required this.current,
    required this.amount,
    required this.epsilon,
  });
}

/// Computes the deviation of [values].last from the mean of the days before
/// it. [values] must be chronological daily values ending with today.
///
/// Returns null when there is not enough history, or when a percentage would
/// divide by a zero baseline.
MetricDeviation? computeMetricDeviation(
  List<double> values, {
  required MetricDeviationStyle style,
  int minHistory = kMinBaselineHistory,
  int window = 30,
}) {
  if (values.length < minHistory + 1) return null;
  final current = values.last;
  final prior = values.sublist(
    values.length - 1 - window < 0 ? 0 : values.length - 1 - window,
    values.length - 1,
  );
  if (prior.length < minHistory) return null;
  final baseline = prior.reduce((a, b) => a + b) / prior.length;

  switch (style) {
    case MetricDeviationStyle.percent:
      if (baseline.abs() < 1e-9) return null;
      return MetricDeviation(
        baseline: baseline,
        current: current,
        amount: (current - baseline) / baseline * 100,
        epsilon: 2, // ±2% is rounding dust, not a trend
      );
    case MetricDeviationStyle.points:
      return MetricDeviation(
        baseline: baseline,
        current: current,
        amount: current - baseline,
        epsilon: 2, // ±2 points on a 0–100 score
      );
    case MetricDeviationStyle.absolute:
      return MetricDeviation(
        baseline: baseline,
        current: current,
        amount: current - baseline,
        // Half a percent of the baseline: 0.9 lb on a 183 lb body weight.
        epsilon: baseline.abs() * 0.005,
      );
  }
}

/// Display-ready state of one tile.
@immutable
class MetricTileData {
  final String id;

  /// Tracked uppercase kicker.
  final String label;

  /// Big value, already formatted ("6,412", "7h 12m", "183.4"). "—" when the
  /// tile has no data.
  final String value;

  /// Small suffix after [value] ("%", "L", "bpm"). Empty when the unit is a
  /// word the numeral already implies ("steps", "days").
  final String unit;

  final bool hasData;

  /// Why the tile is empty — rendered in a dashed capsule. Null when it isn't.
  final String? noDataReason;

  /// True when [noDataReason] names a *source* the user can connect or log to
  /// ("No source · connect Health", "Nothing logged yet") rather than a missing
  /// signal. The capsule prefixes a circled-i in that case — the small
  /// "tap to fix" affordance the mockup gives those two forms and no other.
  final bool noDataNamesSource;

  /// Chart points normalised to 0..1 (1 = top of the plot band). Empty means
  /// draw no chart at all.
  final List<double> series;

  /// The 30-day baseline in the same normalised space, or null when no
  /// deviation is claimed (then no dashed reference line is drawn either).
  final double? baselineY;

  /// True when the tile is making a baseline claim.
  final bool claimsDeviation;

  /// Signed deviation, in the metric's style unit. 0 when nothing is claimed.
  final double deviation;

  /// Noise floor passed to the valence ramp.
  final double deviationEpsilon;

  /// Which way is good for THIS metric — the ramp needs it, and there is no
  /// default.
  final GoodDirection valence;

  /// Full sentence: "12% below your 30-day baseline".
  final String deviationLabel;

  /// Small-tile form: "Below baseline".
  final String deviationLabelShort;

  /// Bars instead of a line — daily totals that reset (water, protein).
  final bool usesBars;

  final String route;

  const MetricTileData({
    required this.id,
    required this.label,
    required this.value,
    required this.unit,
    required this.hasData,
    required this.series,
    required this.valence,
    required this.deviationLabel,
    required this.deviationLabelShort,
    required this.route,
    this.noDataReason,
    this.noDataNamesSource = false,
    this.baselineY,
    this.claimsDeviation = false,
    this.deviation = 0,
    this.deviationEpsilon = 0,
    this.usesBars = false,
  });
}

/// Units that are already implied by the numeral — rendering them as a suffix
/// is noise ("6,412 STEPS" under a kicker that already says STEPS).
const Set<String> _impliedUnits = {'steps', 'days', 'day', ''};

const Set<String> _barMetrics = {
  'hydration',
  'nourish',
  'protein',
  'active_energy',
  'zone_minutes',
  'mindful_minutes',
};

String _emptyReasonFor(MetricTileSource source) {
  switch (source) {
    case MetricTileSource.health:
      return 'No source · connect Health';
    case MetricTileSource.inApp:
      return 'Nothing logged yet';
    case MetricTileSource.computed:
      return 'No plan yet · finish setup';
  }
}

/// Whether the empty-state capsule earns its circled-i: health and in-app
/// reasons name a source the user can act on, a computed one does not.
bool _reasonNamesSource(MetricTileSource source) =>
    source == MetricTileSource.health || source == MetricTileSource.inApp;

String _directionWord(double amount) => amount > 0 ? 'above' : 'below';

({String long, String short}) _deviationCopy(
  MetricDeviation dev,
  MetricDeviationStyle style,
  String unit,
) {
  if (dev.amount.abs() <= dev.epsilon) {
    return (long: 'On your 30-day baseline', short: 'On baseline');
  }
  final word = _directionWord(dev.amount);
  final magnitude = switch (style) {
    MetricDeviationStyle.percent => '${dev.amount.abs().round()}%',
    MetricDeviationStyle.points => '${dev.amount.abs().round()} pts',
    MetricDeviationStyle.absolute =>
      '${dev.amount.abs().toStringAsFixed(1)}${unit.isEmpty ? '' : ' $unit'}',
  };
  return (
    long: '$magnitude $word your 30-day baseline',
    short: '${word[0].toUpperCase()}${word.substring(1)} baseline',
  );
}

/// Headroom added to each end of the min→max range before normalising.
///
/// Without it every series — a 200-step spread on a 9,000-step week included —
/// is stretched edge to edge and reads as a dramatic zigzag. Padding the range
/// by a quarter keeps the shape honest AND lets a quiet week look quiet, which
/// is the whole argument for putting a chart on a tile at all.
const double kTileSeriesHeadroom = 0.125;

/// Normalises [values] (and the baseline, when present) into 0..1, with
/// [kTileSeriesHeadroom] of padding at each end. Public so the "a quiet week
/// looks quiet" property is testable rather than a claim in a comment.
({List<double> series, double? baselineY}) normaliseTileSeries(
  List<double> values,
  double? baseline,
) {
  if (values.length < 2) return (series: const <double>[], baselineY: null);
  var lo = values.reduce((a, b) => a < b ? a : b);
  var hi = values.reduce((a, b) => a > b ? a : b);
  if (baseline != null) {
    if (baseline < lo) lo = baseline;
    if (baseline > hi) hi = baseline;
  }
  final headroom = (hi - lo) * kTileSeriesHeadroom;
  lo -= headroom;
  hi += headroom;
  final span = hi - lo;
  if (span.abs() < 1e-9) {
    return (
      series: List<double>.filled(values.length, 0.5),
      baselineY: baseline == null ? null : 0.5,
    );
  }
  return (
    series: [for (final v in values) (v - lo) / span],
    baselineY: baseline == null ? null : (baseline - lo) / span,
  );
}

List<double> _tailValues(List<double> values) => values.length <= kTileChartPoints
    ? values
    : values.sublist(values.length - kTileChartPoints);

/// Whether the grid should offer the Connect-Health recovery card underneath
/// itself: Health is dark AND at least one placed tile actually reads from it.
///
/// The second half is what keeps it honest — a user whose grid holds only
/// in-app metrics (water, weight, protein) is missing nothing, so pitching them
/// a connect card would be an ad, not a fix.
final metricTilesNeedHealthConnectProvider = Provider<bool>((ref) {
  if (ref.watch(healthSyncProvider.select((s) => s.isConnected))) return false;
  return ref.watch(homeMetricTilesProvider).any(
        (t) => t.spec?.source == MetricTileSource.health,
      );
});

/// Live tile state for [tileId]. Unknown ids resolve to an empty tile rather
/// than throwing — a stale persisted layout must never crash Home.
final metricTileDataProvider =
    Provider.family<MetricTileData, String>((ref, tileId) {
  final spec = kHomeMetricTileCatalog[tileId];
  if (spec == null) {
    return MetricTileData(
      id: tileId,
      label: tileId,
      value: '—',
      unit: '',
      hasData: false,
      noDataReason: 'Unknown metric',
      series: const [],
      valence: GoodDirection.neutral,
      deviationLabel: '',
      deviationLabelShort: '',
      route: '/health/combined',
    );
  }

  final valence = MetricValence.forKey(spec.id);

  // ── The Today Score hero: computed from in-app workouts + logs, so it is
  // alive on a fresh install where every sensor tile is dark. Its history is
  // the local daily snapshot list, not a trend series.
  if (spec.ring == null) {
    final score = ref.watch(todayScoreProvider);
    final history = ref.watch(scoreHistoryProvider).days;
    if (score.isSetupState) {
      return MetricTileData(
        id: spec.id,
        label: spec.tileLabel,
        value: '—',
        unit: '',
        hasData: false,
        noDataReason: _emptyReasonFor(spec.source),
        noDataNamesSource: _reasonNamesSource(spec.source),
        series: const [],
        valence: valence,
        deviationLabel: '',
        deviationLabelShort: '',
        route: spec.route,
      );
    }
    final values = <double>[
      for (final d in history) d.score.toDouble(),
    ];
    // The live score supersedes today's stored snapshot (it is recomputed
    // faster than the snapshot is written).
    if (values.isNotEmpty) {
      values[values.length - 1] = score.score.toDouble();
    } else {
      values.add(score.score.toDouble());
    }
    final dev = computeMetricDeviation(values, style: spec.deviationStyle);
    final norm = normaliseTileSeries(_tailValues(values), dev?.baseline);
    final copy = dev == null
        ? null
        : _deviationCopy(dev, spec.deviationStyle, '');
    return MetricTileData(
      id: spec.id,
      label: spec.tileLabel,
      value: '${score.score}',
      unit: '',
      hasData: true,
      series: norm.series,
      baselineY: norm.baselineY,
      claimsDeviation: dev != null,
      deviation: dev?.amount ?? 0,
      deviationEpsilon: dev?.epsilon ?? 0,
      valence: valence,
      deviationLabel: copy?.long ?? 'From workouts & logs',
      deviationLabelShort: copy?.short ?? 'From your logs',
      route: spec.route,
    );
  }

  // ── Ring-backed metrics. `metricValueProvider` owns the headline; the trend
  // series owns the shape and the baseline.
  final kind = spec.ring!;
  final MetricValue mv = ref.watch(metricValueProvider(kind));
  final unit = _impliedUnits.contains(mv.unit) ? '' : mv.unit;

  if (mv.isEmpty) {
    return MetricTileData(
      id: spec.id,
      label: spec.tileLabel,
      value: '—',
      unit: '',
      hasData: false,
      noDataReason: _emptyReasonFor(spec.source),
      noDataNamesSource: _reasonNamesSource(spec.source),
      series: const [],
      valence: valence,
      deviationLabel: '',
      deviationLabelShort: '',
      route: spec.route,
    );
  }

  List<double> values = const [];
  final tm = trendMetricForRing(kind);
  if (tm != null) {
    final series = ref
        .watch(trendSeriesProvider(TrendSeriesKey(tm, TrendRange.d30)))
        .valueOrNull;
    if (series != null) {
      values = [for (final p in series.points) p.value];
    }
  }

  final dev = values.isEmpty
      ? null
      : computeMetricDeviation(values, style: spec.deviationStyle);
  final norm = normaliseTileSeries(_tailValues(values), dev?.baseline);
  final copy =
      dev == null ? null : _deviationCopy(dev, spec.deviationStyle, mv.unit);

  return MetricTileData(
    id: spec.id,
    label: spec.tileLabel,
    value: mv.headline,
    unit: unit,
    hasData: true,
    series: norm.series,
    baselineY: norm.baselineY,
    claimsDeviation: dev != null,
    deviation: dev?.amount ?? 0,
    deviationEpsilon: dev?.epsilon ?? 0,
    valence: valence,
    // With no baseline the tile falls back to the metric's own honest line
    // ("Goal 2.5 L", "of 10k") and claims nothing about a trend.
    deviationLabel: copy?.long ?? mv.deltaLabel ?? 'Not enough history yet',
    deviationLabelShort: copy?.short ?? mv.deltaLabel ?? 'No baseline yet',
    usesBars: _barMetrics.contains(spec.id),
    route: spec.route,
  );
});
