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
  ///
  /// English. The rendering layer prefers the localised form resolved from
  /// [emptyReason]; this stays as the semantics fallback and as the only copy
  /// available for an id the catalogue no longer knows.
  final String? noDataReason;

  /// Small-tile form of [noDataReason] ("Connect Health"). A 100pt S tile
  /// ellipsises the long form into a truncated non-sentence, which is how
  /// `NO BASELINE Y…` shipped.
  final String? noDataReasonShort;

  /// *Why* the tile is dark, as a value the grid can aggregate — the piece
  /// that lets one consolidated first-run panel exist at all. Null when the
  /// tile has data, or for an id the catalogue no longer knows.
  final MetricEmptyReason? emptyReason;

  /// True when [noDataReason] names something the user can act on ("connect
  /// Health", "nothing logged yet", "finish setup") rather than a missing
  /// signal ("No Health data yet"). The capsule prefixes a circled-i in that
  /// case — the small "tap to fix" affordance, and nowhere else.
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
    this.noDataReasonShort,
    this.emptyReason,
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

/// The tile id whose empty state is a missing *signal* rather than a missing
/// source: readiness needs HRV samples specifically, and saying "no Health
/// data" there would hide which signal is actually absent.
const String _kRecoveryTileId = 'recovery';

/// Why one tile is dark. Resolved from the metric's source **and the live
/// health-connection state** — the source alone cannot tell "you never
/// connected Health" from "Health is connected and has nothing for today",
/// which is why the old copy kept saying *connect Health* to users who
/// already had.
enum MetricEmptyReason {
  /// Health-sourced, and Health is not connected. Actionable: connect it.
  healthDisconnected,

  /// Health-sourced, Health IS connected, and there are no samples. Not
  /// actionable by anything the app can offer — no CTA exists for it.
  healthNoSamples,

  /// In-app-sourced and nothing has been logged. Actionable: log something.
  nothingLogged,

  /// Computed from a plan that does not exist yet. Actionable: finish setup.
  needsSetup,
}

/// What a dark tile is asking the user to DO. Tiles that ask the same thing
/// consolidate into one group in the first-run panel; [MetricEmptyAction.none]
/// never consolidates, because there is no shared CTA to consolidate *into*.
enum MetricEmptyAction { connectHealth, logInApp, finishSetup, none }

extension MetricEmptyReasonX on MetricEmptyReason {
  MetricEmptyAction get action => switch (this) {
        MetricEmptyReason.healthDisconnected => MetricEmptyAction.connectHealth,
        MetricEmptyReason.nothingLogged => MetricEmptyAction.logInApp,
        MetricEmptyReason.needsSetup => MetricEmptyAction.finishSetup,
        MetricEmptyReason.healthNoSamples => MetricEmptyAction.none,
      };
}

/// The nine empty-state strings, as one bundle.
///
/// There is exactly ONE table mapping a reason to its copy
/// ([metricEmptyCopyFor]); this bundle is how the same table serves both
/// callers — the provider passes [kMetricEmptyCopyEn] (no BuildContext exists
/// there), the tile passes an [AppLocalizations]-backed bundle. A second
/// switch statement in the widget layer is exactly how the two halves would
/// drift.
@immutable
class MetricEmptyCopy {
  final String noSourceConnectHealth;
  final String connectHealthShort;
  final String noHealthDataYet;
  final String noDataYet;
  final String nothingLoggedYet;
  final String nothingLoggedShort;
  final String noPlanYetFinishSetup;
  final String finishSetupShort;
  final String needsHrv;

  const MetricEmptyCopy({
    required this.noSourceConnectHealth,
    required this.connectHealthShort,
    required this.noHealthDataYet,
    required this.noDataYet,
    required this.nothingLoggedYet,
    required this.nothingLoggedShort,
    required this.noPlanYetFinishSetup,
    required this.finishSetupShort,
    required this.needsHrv,
  });
}

/// English copy — what the provider stores on [MetricTileData] for semantics
/// and for any reader without a BuildContext.
const MetricEmptyCopy kMetricEmptyCopyEn = MetricEmptyCopy(
  noSourceConnectHealth: 'No source · connect Health',
  connectHealthShort: 'Connect Health',
  noHealthDataYet: 'No Health data yet',
  noDataYet: 'No data yet',
  nothingLoggedYet: 'Nothing logged yet',
  nothingLoggedShort: 'Nothing logged',
  noPlanYetFinishSetup: 'No plan yet · finish setup',
  finishSetupShort: 'Finish setup',
  needsHrv: 'Needs HRV',
);

/// The one reason → copy table. [tileId] is threaded because readiness names
/// the signal it is missing rather than the source.
///
/// `namesSource` is the circled-i rule: it is true exactly when the line names
/// something the user can act on.
({String long, String short, bool namesSource}) metricEmptyCopyFor(
  String tileId,
  MetricEmptyReason reason,
  MetricEmptyCopy copy,
) {
  if (reason == MetricEmptyReason.healthNoSamples &&
      tileId == _kRecoveryTileId) {
    return (long: copy.needsHrv, short: copy.needsHrv, namesSource: false);
  }
  return switch (reason) {
    MetricEmptyReason.healthDisconnected => (
        long: copy.noSourceConnectHealth,
        short: copy.connectHealthShort,
        namesSource: true,
      ),
    MetricEmptyReason.healthNoSamples => (
        long: copy.noHealthDataYet,
        short: copy.noDataYet,
        namesSource: false,
      ),
    MetricEmptyReason.nothingLogged => (
        long: copy.nothingLoggedYet,
        short: copy.nothingLoggedShort,
        namesSource: true,
      ),
    MetricEmptyReason.needsSetup => (
        long: copy.noPlanYetFinishSetup,
        short: copy.finishSetupShort,
        namesSource: true,
      ),
  };
}

/// Resolves [source] against the live Health connection.
MetricEmptyReason _emptyReasonFor(MetricTileSource source,
        {required bool healthConnected}) =>
    switch (source) {
      MetricTileSource.health => healthConnected
          ? MetricEmptyReason.healthNoSamples
          : MetricEmptyReason.healthDisconnected,
      MetricTileSource.inApp => MetricEmptyReason.nothingLogged,
      MetricTileSource.computed => MetricEmptyReason.needsSetup,
    };

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

/// How many *actionable* dark tiles on one page turn a grid of empty states
/// into one consolidated panel.
///
/// 3 is the anti-pattern boundary, not a taste call: one or two dashed
/// capsules read as "these two signals are missing"; three or more of the
/// same sentence read as a broken screen, which is exactly what a fresh
/// account saw — four inline "connect Health" capsules plus a full-width
/// connect card underneath, five renderings of one instruction.
const int kMetricGridCollapseThreshold = 3;

/// How dark one page of the grid is, as one value the section can branch on.
///
/// The whole point is that emptiness stops being a per-tile decision made in
/// isolation: nothing here reads [healthSyncProvider] directly, only each
/// tile's own resolved state, which is what keeps Water and Weight (in-app
/// sourced, live at 0 oz / 82.0 lb on a Health-less phone) out of the
/// "connect Health" story they have nothing to do with.
@immutable
class MetricGridDarkness {
  /// Tiles with real data, in the user's order.
  final List<HomeMetricTile> live;

  /// Dark tiles with no CTA to consolidate into ([MetricEmptyAction.none]).
  /// They stay on the grid as tiles: each names a different missing signal,
  /// so folding them together would say less than they already do.
  final List<HomeMetricTile> inertDark;

  /// Everything that is NOT absorbed by the panel — [live] and [inertDark]
  /// merged back into the user's order. This is what the collapsed state
  /// draws under the panel.
  final List<HomeMetricTile> survivors;

  /// Absorbed tiles grouped by what they ask for, in first-seen order.
  final Map<MetricEmptyAction, List<MetricTileData>> darkByAction;

  const MetricGridDarkness({
    required this.live,
    required this.inertDark,
    required this.survivors,
    required this.darkByAction,
  });

  /// Dark tiles the panel can actually offer an action for.
  int get actionableDarkCount {
    var n = 0;
    for (final group in darkByAction.values) {
      n += group.length;
    }
    return n;
  }

  bool get collapse => actionableDarkCount >= kMetricGridCollapseThreshold;

  /// The group that earns the filled button. Largest wins; a tie resolves
  /// connect → log → setup, because that is the order of how much the grid
  /// gets back per tap.
  MetricEmptyAction get primaryAction {
    var best = MetricEmptyAction.none;
    var bestCount = 0;
    for (final a in const [
      MetricEmptyAction.connectHealth,
      MetricEmptyAction.logInApp,
      MetricEmptyAction.finishSetup,
    ]) {
      final n = darkByAction[a]?.length ?? 0;
      if (n > bestCount) {
        best = a;
        bestCount = n;
      }
    }
    return best;
  }
}

/// [MetricGridDarkness] for one page of the grid.
final metricGridDarknessProvider =
    Provider.family<MetricGridDarkness, int>((ref, page) {
  final tiles = tilesOnPage(ref.watch(homeMetricTilesProvider), page);
  final live = <HomeMetricTile>[];
  final inertDark = <HomeMetricTile>[];
  final survivors = <HomeMetricTile>[];
  final darkByAction = <MetricEmptyAction, List<MetricTileData>>{};

  for (final t in tiles) {
    final data = ref.watch(metricTileDataProvider(t.id));
    if (data.hasData) {
      live.add(t);
      survivors.add(t);
      continue;
    }
    final action = data.emptyReason?.action ?? MetricEmptyAction.none;
    if (action == MetricEmptyAction.none) {
      inertDark.add(t);
      survivors.add(t);
      continue;
    }
    (darkByAction[action] ??= <MetricTileData>[]).add(data);
  }

  return MetricGridDarkness(
    live: List.unmodifiable(live),
    inertDark: List.unmodifiable(inertDark),
    survivors: List.unmodifiable(survivors),
    darkByAction: Map.unmodifiable(darkByAction),
  );
});

/// A dark tile, with its reason and both copy forms resolved through the one
/// table. Every empty return in [metricTileDataProvider] comes through here.
MetricTileData _emptyTile(
  MetricTileSpec spec,
  GoodDirection valence,
  MetricEmptyReason reason,
) {
  final copy = metricEmptyCopyFor(spec.id, reason, kMetricEmptyCopyEn);
  return MetricTileData(
    id: spec.id,
    label: spec.tileLabel,
    value: '—',
    unit: '',
    hasData: false,
    emptyReason: reason,
    noDataReason: copy.long,
    noDataReasonShort: copy.short,
    noDataNamesSource: copy.namesSource,
    series: const [],
    valence: valence,
    deviationLabel: '',
    deviationLabelShort: '',
    route: spec.route,
  );
}

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
      return _emptyTile(
        spec,
        valence,
        _emptyReasonFor(
          spec.source,
          // Short-circuits for the computed source, so the score tile does not
          // subscribe to the health plugin just to say "finish setup".
          healthConnected: spec.source == MetricTileSource.health &&
              ref.watch(healthSyncProvider.select((s) => s.isConnected)),
        ),
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
    return _emptyTile(
      spec,
      valence,
      _emptyReasonFor(
        spec.source,
        healthConnected:
            ref.watch(healthSyncProvider.select((s) => s.isConnected)),
      ),
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
    // 'No baseline yet' ellipsises to `NO BASELINE Y…` inside a 100pt S tile —
    // the short form has to actually be short.
    deviationLabelShort: copy?.short ?? mv.deltaLabel ?? 'No baseline',
    usesBars: _barMetrics.contains(spec.id),
    route: spec.route,
  );
});
