/// Per-metric display configuration for the home Metric Summary deck and the
/// "My Space → Metrics" editor.
///
/// This layers ON TOP of the existing [ringVisibilityProvider] (which already
/// owns *which* metrics are shown and in *what order*, persisted per-user).
/// Here we persist the *presentation* of each metric — its tile size, the
/// chart style used to draw it, an optional color override, and the trend
/// date-range — keyed by the metric's stable string id ([RingKindX.id]).
///
/// Keeping this separate from `ring_catalog.dart` means the visibility/order
/// model stays untouched (and its migration intact); a metric with no saved
/// display config simply falls back to [MetricDisplayConfig.defaultFor].
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers/auth_provider.dart';
import '../../screens/home/widgets/ring_catalog.dart';

/// Tile footprint in the deck / bento grid.
enum MetricSize { small, wide, large }

/// How a metric's value is visualised on its tile.
enum MetricChart { number, ring, bars, line, area }

/// Trend window for line/area/range-aware tiles.
enum MetricRange { d7, d30, d90, y1 }

extension MetricSizeX on MetricSize {
  String get id => switch (this) {
    MetricSize.small => 'small',
    MetricSize.wide => 'wide',
    MetricSize.large => 'large',
  };
  String get shortLabel => switch (this) {
    MetricSize.small => 'S',
    MetricSize.wide => 'W',
    MetricSize.large => 'L',
  };
  static MetricSize fromId(String? v) => MetricSize.values.firstWhere(
    (e) => e.id == v,
    orElse: () => MetricSize.small,
  );
}

extension MetricChartX on MetricChart {
  String get id => name; // number / ring / bars / line / area
  String get label => switch (this) {
    MetricChart.number => 'Number',
    MetricChart.ring => 'Ring',
    MetricChart.bars => 'Bars',
    MetricChart.line => 'Line',
    MetricChart.area => 'Area',
  };
  static MetricChart fromId(String? v) => MetricChart.values.firstWhere(
    (e) => e.name == v,
    orElse: () => MetricChart.number,
  );
}

extension MetricRangeX on MetricRange {
  String get id => name; // d7 / d30 / d90 / y1
  String get label => switch (this) {
    MetricRange.d7 => '7d',
    MetricRange.d30 => '30d',
    MetricRange.d90 => '90d',
    MetricRange.y1 => '1y',
  };
  int get days => switch (this) {
    MetricRange.d7 => 7,
    MetricRange.d30 => 30,
    MetricRange.d90 => 90,
    MetricRange.y1 => 365,
  };
  static MetricRange fromId(String? v) => MetricRange.values.firstWhere(
    (e) => e.name == v,
    orElse: () => MetricRange.d90,
  );
}

/// Immutable presentation config for one metric tile.
@immutable
class MetricDisplayConfig {
  final MetricSize size;
  final MetricChart chart;

  /// Optional color override; when null the tile uses its catalog color
  /// ([RingKindX.color]). Stored as an `#RRGGBB` string for portability.
  final int? colorOverride;

  final MetricRange range;

  const MetricDisplayConfig({
    required this.size,
    required this.chart,
    required this.range,
    this.colorOverride,
  });

  /// Sensible default presentation for a metric, picked from its kind so the
  /// deck looks right before the user customises anything.
  factory MetricDisplayConfig.defaultFor(RingKind kind) {
    switch (kind) {
      case RingKind.train:
      case RingKind.nourish:
      case RingKind.move:
      case RingKind.hydration:
      case RingKind.protein:
      case RingKind.zoneMinutes:
      case RingKind.mindfulMinutes:
        return const MetricDisplayConfig(
          size: MetricSize.small,
          chart: MetricChart.ring,
          range: MetricRange.d30,
        );
      case RingKind.sleep:
        return const MetricDisplayConfig(
          size: MetricSize.small,
          chart: MetricChart.bars,
          range: MetricRange.d30,
        );
      case RingKind.weight:
        return const MetricDisplayConfig(
          size: MetricSize.wide,
          chart: MetricChart.line,
          range: MetricRange.d90,
        );
      case RingKind.heartRate:
      case RingKind.hrv:
      case RingKind.stress:
      case RingKind.vo2max:
        return const MetricDisplayConfig(
          size: MetricSize.small,
          chart: MetricChart.line,
          range: MetricRange.d30,
        );
      case RingKind.recovery:
      case RingKind.cycle:
      case RingKind.sleepLatency:
      case RingKind.wakeConsistency:
      case RingKind.bedtimeWindow:
      case RingKind.activeEnergy:
        return const MetricDisplayConfig(
          size: MetricSize.small,
          chart: MetricChart.number,
          range: MetricRange.d30,
        );
    }
  }

  MetricDisplayConfig copyWith({
    MetricSize? size,
    MetricChart? chart,
    Object? colorOverride = _sentinel,
    MetricRange? range,
  }) => MetricDisplayConfig(
    size: size ?? this.size,
    chart: chart ?? this.chart,
    range: range ?? this.range,
    colorOverride: identical(colorOverride, _sentinel)
        ? this.colorOverride
        : colorOverride as int?,
  );

  Map<String, dynamic> toJson() => {
    'size': size.id,
    'chart': chart.id,
    'range': range.id,
    if (colorOverride != null) 'color': colorOverride,
  };

  factory MetricDisplayConfig.fromJson(Map<String, dynamic> j) =>
      MetricDisplayConfig(
        size: MetricSizeX.fromId(j['size'] as String?),
        chart: MetricChartX.fromId(j['chart'] as String?),
        range: MetricRangeX.fromId(j['range'] as String?),
        colorOverride: (j['color'] as num?)?.toInt(),
      );
}

const Object _sentinel = Object();

String _layoutKey(String? userId) => (userId == null || userId.isEmpty)
    ? 'home_metric_layout_anon'
    : 'home_metric_layout_$userId';

/// Persists per-metric [MetricDisplayConfig] keyed by [RingKindX.id].
class MetricLayoutNotifier
    extends StateNotifier<Map<String, MetricDisplayConfig>> {
  final Ref _ref;
  MetricLayoutNotifier(this._ref) : super(const {}) {
    _load();
  }

  String? get _userId => _ref.read(currentUserIdProvider);

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_layoutKey(_userId));
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final next = <String, MetricDisplayConfig>{};
      decoded.forEach((k, v) {
        if (k is String && v is Map) {
          try {
            next[k] = MetricDisplayConfig.fromJson(
              Map<String, dynamic>.from(v),
            );
          } catch (_) {
            /* skip corrupt entry */
          }
        }
      });
      if (next.isNotEmpty) state = next;
    } catch (_) {
      // Best-effort; defaults apply per-metric when a key is missing.
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(state.map((k, v) => MapEntry(k, v.toJson())));
      await prefs.setString(_layoutKey(_userId), encoded);
    } catch (_) {
      /* best-effort */
    }
  }

  /// The resolved config for a metric — its saved config, else the default.
  MetricDisplayConfig configFor(RingKind kind) =>
      state[kind.id] ?? MetricDisplayConfig.defaultFor(kind);

  void _update(
    RingKind kind,
    MetricDisplayConfig Function(MetricDisplayConfig) f,
  ) {
    final current = configFor(kind);
    state = {...state, kind.id: f(current)};
    _persist();
  }

  void setSize(RingKind kind, MetricSize size) =>
      _update(kind, (c) => c.copyWith(size: size));

  void setChart(RingKind kind, MetricChart chart) =>
      _update(kind, (c) => c.copyWith(chart: chart));

  void setRange(RingKind kind, MetricRange range) =>
      _update(kind, (c) => c.copyWith(range: range));

  /// [colorOverride] of null clears the override (back to catalog color).
  void setColor(RingKind kind, int? colorOverride) =>
      _update(kind, (c) => c.copyWith(colorOverride: colorOverride));

  void reset(RingKind kind) {
    if (!state.containsKey(kind.id)) return;
    final next = {...state}..remove(kind.id);
    state = next;
    _persist();
  }
}

/// Per-metric presentation config (size / chart / color / range), persisted
/// per-user. Read [MetricLayoutNotifier.configFor] for a resolved-with-default
/// config; watch the provider to rebuild on changes.
final metricLayoutProvider =
    StateNotifierProvider<
      MetricLayoutNotifier,
      Map<String, MetricDisplayConfig>
    >((ref) {
      ref.watch(currentUserIdProvider); // rebuild notifier per account
      return MetricLayoutNotifier(ref);
    });
