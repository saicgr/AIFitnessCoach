/// Providers for the generic per-exercise metric-tracking system.
///
/// Two pieces of user state back the dynamic "+ Add column" feature:
///   • [customMetricDefsProvider] — metric definitions the user created
///     (merged on top of the built-in [kMetricCatalog]).
///   • [exerciseMetricPrefsProvider] — the ordered metric-key columns the user
///     chose for a specific exercise (persisted per user + per exercise).
///
/// Backed by the backend `/metrics/exercise-custom` + `/metrics/exercise-prefs`
/// endpoints (see backend/api/v1/metrics_db.py).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/exercise_tracking_metric.dart';
import '../services/api_client.dart';
import 'habit_provider.dart' show currentUserIdProvider;

/// User-defined custom metrics, as [MetricDef]s keyed by their `key`.
final customMetricDefsProvider =
    FutureProvider<Map<String, MetricDef>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const {};
  try {
    final api = ref.read(apiClientProvider);
    // NB: /metrics/custom is owned by the HEALTH custom-metric feature; the
    // exercise custom-metric registry lives at /metrics/exercise-custom.
    final res = await api.get('/metrics/exercise-custom',
        queryParameters: {'user_id': userId});
    final data = res.data;
    final list = (data is Map && data['custom_metrics'] is List)
        ? data['custom_metrics'] as List
        : const [];
    final out = <String, MetricDef>{};
    for (final e in list) {
      if (e is! Map) continue;
      final key = e['key']?.toString();
      if (key == null || key.isEmpty) return out;
      out[key] = MetricDef(
        key,
        key, // custom metrics store under metrics[<key>]
        (e['label'] ?? key).toString(),
        (e['label'] ?? key).toString().toUpperCase(),
        (e['canonical_unit'] ?? '').toString(),
        (e['input_type'] ?? 'number').toString(),
        false,
      );
    }
    return out;
  } catch (e) {
    debugPrint('⚠️ [Metrics] custom defs fetch failed: $e');
    return const {};
  }
});

/// The full metric registry available to the user = built-ins + their customs.
/// Returns a lookup `MetricDef? Function(String key)`.
final metricDefLookupProvider = Provider<MetricDef? Function(String)>((ref) {
  final custom = ref.watch(customMetricDefsProvider).valueOrNull ?? const {};
  return (key) => kMetricCatalog[key] ?? custom[key];
});

/// The user's chosen metric-key columns for [exerciseId] (empty when none set).
/// These are the EXTRA columns layered on top of the exercise's classifier
/// defaults — the UI unions them with `exercise.trackingProfile.metricKeys`.
final exerciseMetricPrefsProvider =
    FutureProvider.family<List<String>, String>((ref, exerciseId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null || exerciseId.isEmpty) return const [];
  try {
    final api = ref.read(apiClientProvider);
    final res = await api.get('/metrics/exercise-prefs',
        queryParameters: {'user_id': userId, 'exercise_id': exerciseId});
    final data = res.data;
    final keys = (data is Map && data['metric_keys'] is List)
        ? (data['metric_keys'] as List).map((e) => e.toString()).toList()
        : <String>[];
    return keys;
  } catch (e) {
    debugPrint('⚠️ [Metrics] exercise-prefs fetch failed: $e');
    return const [];
  }
});

/// Mutations for the metric system. Kept as a thin service rather than a
/// notifier so callers (the picker sheet, the custom-exercise builder) can fire
/// and invalidate the relevant providers.
class ExerciseMetricsService {
  ExerciseMetricsService(this._ref);
  final Ref _ref;

  String? get _userId => _ref.read(currentUserIdProvider);

  /// Persist the full ordered metric-key list the user wants for [exerciseId].
  Future<void> saveExerciseMetricKeys(
      String exerciseId, List<String> keys) async {
    final userId = _userId;
    if (userId == null || exerciseId.isEmpty) return;
    final api = _ref.read(apiClientProvider);
    await api.put('/metrics/exercise-prefs', data: {
      'user_id': userId,
      'exercise_id': exerciseId,
      'metric_keys': keys,
    });
    _ref.invalidate(exerciseMetricPrefsProvider(exerciseId));
  }

  /// Create a user-defined custom metric.
  Future<void> createCustomMetric({
    required String key,
    required String label,
    String? unit,
    required String canonicalUnit,
    String inputType = 'number',
  }) async {
    final userId = _userId;
    if (userId == null) return;
    final api = _ref.read(apiClientProvider);
    await api.post('/metrics/exercise-custom', data: {
      'user_id': userId,
      'key': key,
      'label': label,
      'unit': unit,
      'canonical_unit': canonicalUnit,
      'input_type': inputType,
    });
    _ref.invalidate(customMetricDefsProvider);
  }
}

final exerciseMetricsServiceProvider =
    Provider<ExerciseMetricsService>((ref) => ExerciseMetricsService(ref));

/// Draft EXTRA-metric values (bagKey → raw text) for the currently-active set
/// in the Advanced table. The extra-metric input cells write here; `completeSet`
/// reads + clears it when the set is logged. Standard weight/reps/distance/time
/// ride their own controllers — this is only the long-tail metrics (box height,
/// calories, custom…).
final activeSetExtraMetricsProvider =
    StateProvider<Map<String, String>>((ref) => {});

/// The EFFECTIVE ordered column keys for an exercise = its classifier defaults
/// unioned with the user's saved per-exercise additions (order preserved,
/// defaults first). Use this to drive the set-row columns.
List<String> effectiveMetricKeys(List<String> defaults, List<String> prefs) {
  final out = <String>[...defaults];
  for (final k in prefs) {
    if (!out.contains(k)) out.add(k);
  }
  return out;
}
