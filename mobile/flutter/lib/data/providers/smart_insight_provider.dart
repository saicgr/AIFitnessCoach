/// Smart-insight provider (Phase D1) — backs the home-screen smart-insight card.
///
/// Hits the backend `GET /insights/{uid}/smart-insights` endpoint, which runs
/// a deterministic Pearson-correlation engine over the user's own
/// `daily_activity` history and returns ranked, association-only insight
/// strings (correlation, never causation).
///
/// Render rules (folded into [SmartInsightState.shouldShow] so the card stays
/// dumb):
///   • shows ONLY when the endpoint returns at least one insight;
///   • the endpoint itself returns an empty list below 14 paired days or with
///     no wearable / no consent — so the card naturally self-hides then;
///   • hides on any API/loading error (the failure stays loud in logs);
///   • a 24h SharedPreferences cache so the home screen paints instantly and
///     we don't re-hit the weekly-recomputed endpoint on every home rebuild.
///
/// Per `feedback_no_silent_fallbacks.md` a network error is NOT swallowed into
/// a fake "no insight" — it surfaces as an AsyncError; the card treats that as
/// "hide" while the bug stays visible in logs.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';

/// SharedPreferences key owned by the smart-insight card.
const String _kSmartInsightCacheKey = 'smart_insight_cache_v1';

/// 24h cache window — the backend recomputes weekly, so a day-old client cache
/// is always fresh enough; it just avoids a network hit per home rebuild.
const Duration _smartInsightCacheTtl = Duration(hours: 24);

/// One ranked cross-metric correlation insight.
@immutable
class SmartInsight {
  /// The two correlated metric keys (e.g. `sleep`, `resting_hr`).
  final String metricA;
  final String metricB;

  /// Pearson r in [-1, 1].
  final double r;

  /// Number of paired days the correlation was computed over (>= 14).
  final int n;

  /// The human, association-only insight sentence.
  final String insight;

  const SmartInsight({
    required this.metricA,
    required this.metricB,
    required this.r,
    required this.n,
    required this.insight,
  });

  factory SmartInsight.fromJson(Map<String, dynamic> json) {
    return SmartInsight(
      metricA: json['metric_a'] as String? ?? '',
      metricB: json['metric_b'] as String? ?? '',
      r: (json['r'] as num?)?.toDouble() ?? 0.0,
      n: (json['n'] as num?)?.toInt() ?? 0,
      insight: json['insight'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'metric_a': metricA,
        'metric_b': metricB,
        'r': r,
        'n': n,
        'insight': insight,
      };
}

/// Resolved smart-insight state for the home card.
@immutable
class SmartInsightState {
  /// Ranked insights, best-first. Empty when the engine has nothing to say.
  final List<SmartInsight> insights;

  const SmartInsightState({required this.insights});

  /// Empty / "nothing to show" state.
  static const SmartInsightState none = SmartInsightState(insights: []);

  /// The card renders only when there is at least one insight with copy.
  bool get shouldShow =>
      insights.isNotEmpty && insights.first.insight.trim().isNotEmpty;

  /// The single best insight (the one the card displays). Null when empty.
  SmartInsight? get top => insights.isEmpty ? null : insights.first;
}

/// FutureProvider.autoDispose — recomputed when the home screen mounts.
///
/// Resolution order:
///   1. Read the 24h cache; if fresh, use it (instant paint).
///   2. Otherwise call the API, persist the result, and return it.
final smartInsightProvider =
    FutureProvider.autoDispose<SmartInsightState>((ref) async {
  final prefs = await SharedPreferences.getInstance();

  // 1. 24h cache — cheapest path, no network.
  final cached = _readCache(prefs);
  if (cached != null) {
    debugPrint('🔍 [SmartInsight] cache hit — ${cached.insights.length} insight(s)');
    return cached;
  }

  // 2. Network. Errors bubble — the provider surfaces AsyncError; the card
  //    treats that as "hide" but the failure stays loud in logs.
  final apiClient = ref.read(apiClientProvider);
  final userId = await apiClient.getUserId();
  if (userId == null) {
    debugPrint('🔍 [SmartInsight] no user resolved — hiding card');
    return SmartInsightState.none;
  }

  final response = await apiClient.get<Map<String, dynamic>>(
    '/insights/$userId/smart-insights',
  );
  final data = response.data ?? const {};
  final rawList = (data['insights'] as List?) ?? const [];
  final insights = rawList
      .whereType<Map>()
      .map((m) => SmartInsight.fromJson(Map<String, dynamic>.from(m)))
      .where((i) => i.insight.trim().isNotEmpty)
      .toList();

  debugPrint('🔍 [SmartInsight] API result — ${insights.length} insight(s)');
  final state = SmartInsightState(insights: insights);
  await _writeCache(prefs, state);
  return state;
});

// ─── Internals ───────────────────────────────────────────────────────────────

/// Returns the cached state when it exists and is within the 24h TTL.
SmartInsightState? _readCache(SharedPreferences prefs) {
  final raw = prefs.getString(_kSmartInsightCacheKey);
  if (raw == null) return null;
  try {
    final map = json.decode(raw) as Map<String, dynamic>;
    final savedAtIso = map['saved_at'] as String?;
    if (savedAtIso == null) return null;
    final savedAt = DateTime.tryParse(savedAtIso);
    if (savedAt == null) return null;
    if (DateTime.now().difference(savedAt) >= _smartInsightCacheTtl) return null;
    final rawList = (map['insights'] as List?) ?? const [];
    final insights = rawList
        .whereType<Map>()
        .map((m) => SmartInsight.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    return SmartInsightState(insights: insights);
  } catch (e) {
    debugPrint('⚠️ [SmartInsight] cache parse failed, ignoring: $e');
    return null;
  }
}

Future<void> _writeCache(SharedPreferences prefs, SmartInsightState state) async {
  final payload = json.encode({
    'saved_at': DateTime.now().toIso8601String(),
    'insights': state.insights.map((i) => i.toJson()).toList(),
  });
  await prefs.setString(_kSmartInsightCacheKey, payload);
}
