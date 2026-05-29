/// Read-only view of the user's saved custom trends so they can be surfaced
/// as home widgets (the Trends page of the metric deck + My Space).
///
/// The custom-trend builder ([CustomTrendScreen]) owns writing these to
/// SharedPreferences under [kSavedTrendsPrefsKey] as a `List<String>` of JSON
/// `{primary, overlays[], range}` (enum `.name`s). We only READ them here —
/// the builder remains the single writer — so nothing about the existing save
/// flow changes.
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'trend_series_provider.dart';

/// Must match `_kSavedTrendsPrefsKey` in `custom_trend_screen.dart`.
const String kSavedTrendsPrefsKey = 'custom_trends_saved_v2';

/// A saved custom-trend descriptor for display on home surfaces.
class SavedTrendView {
  final TrendMetric primary;
  final List<TrendMetric> overlays;
  final TrendRange range;

  const SavedTrendView({
    required this.primary,
    required this.overlays,
    required this.range,
  });

  /// "Weight × Sleep" style title (primary + first overlay), or just the
  /// primary's name when it has no overlays.
  String get title {
    if (overlays.isEmpty) return primary.displayName;
    return '${primary.displayName} × ${overlays.first.displayName}'
        '${overlays.length > 1 ? ' +${overlays.length - 1}' : ''}';
  }
}

TrendMetric? _metricByName(String? n) =>
    TrendMetric.values.where((m) => m.name == n).firstOrNull;

SavedTrendView? _parse(Map<String, dynamic> j) {
  final p = _metricByName(j['primary'] as String?);
  final r = TrendRange.values.where((x) => x.name == j['range']).firstOrNull;
  if (p == null || r == null) return null;
  final overlays = <TrendMetric>[];
  for (final raw in (j['overlays'] as List?) ?? const []) {
    final m = _metricByName(raw as String?);
    if (m != null && m != p) overlays.add(m);
  }
  return SavedTrendView(primary: p, overlays: overlays, range: r);
}

/// All saved custom trends, newest-last (write order). Empty when none saved.
final savedTrendsProvider = FutureProvider<List<SavedTrendView>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getStringList(kSavedTrendsPrefsKey) ?? const [];
  final out = <SavedTrendView>[];
  for (final s in raw) {
    try {
      final v = _parse(jsonDecode(s) as Map<String, dynamic>);
      if (v != null) out.add(v);
    } catch (_) {
      /* skip corrupt entry */
    }
  }
  return out;
});
