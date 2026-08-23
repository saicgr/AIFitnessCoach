import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/cache_first_mixin.dart';
import '../repositories/auth_repository.dart';
import '../services/api_client.dart';

/// Repository for the Heart Health Score endpoint.
///
/// Backed by `backend/api/v1/health_metrics_endpoints.py` → GET
/// /health/heart-health. The CHRONIC cardiovascular habit score (0-100),
/// distinct from the acute recoveryProvider. No fallback data.
class HeartHealthRepository {
  final ApiClient _apiClient;

  HeartHealthRepository(this._apiClient);

  Future<HeartHealthData> fetch() async {
    debugPrint('❤️ [HeartHealth] fetch');
    final response = await _apiClient.get('/health/heart-health');
    if (response.statusCode != 200) {
      throw Exception('Failed to load heart health (${response.statusCode})');
    }
    return HeartHealthData.fromJson(
        Map<String, dynamic>.from(response.data as Map));
  }
}

final heartHealthRepositoryProvider = Provider<HeartHealthRepository>((ref) {
  return HeartHealthRepository(ref.watch(apiClientProvider));
});

/// Instant-load standard (Part 2) for the Heart Health detail screen.
///
/// Used to block on a bare centered `CircularProgressIndicator` on every cold
/// launch because the score lived only in the `FutureProvider.autoDispose`'s
/// memory and was lost on app restart. This notifier adds a disk cache (via
/// [CacheFirstMixin]) so a restart paints the last-seen score instantly while
/// a fresh copy is fetched silently behind it.
class HeartHealthNotifier extends StateNotifier<AsyncValue<HeartHealthData>>
    with CacheFirstMixin {
  HeartHealthNotifier({
    required HeartHealthRepository repository,
    required String userId,
  })  : _repository = repository,
        _userId = userId,
        super(const AsyncValue.loading()) {
    load();
  }

  final HeartHealthRepository _repository;
  final String _userId;

  static const int _schemaVersion = 1;

  Future<void> load() async {
    await loadCacheFirst<HeartHealthData>(
      cacheKey: 'heart_health',
      userId: _userId,
      // Day-bucketed score; a day old is still a reasonable instant-paint
      // placeholder while the fresh value loads behind it.
      ttl: const Duration(hours: 12),
      schemaVersion: _schemaVersion,
      localDateScoped: true,
      fetch: _repository.fetch,
      decode: HeartHealthData.fromJson,
      encode: _encodeHeartHealth,
      emit: (data, {required bool fromCache}) {
        if (!mounted) return;
        state = AsyncValue.data(data);
      },
      onError: (e, st) {
        if (!mounted) return;
        try {
          if (state.valueOrNull == null) {
            state = AsyncValue.error(e, st);
          }
        } catch (_) {
          // Notifier disposed between the mounted check and the state read.
        }
      },
    );
  }
}

final heartHealthProvider =
    StateNotifierProvider<HeartHealthNotifier, AsyncValue<HeartHealthData>>(
        (ref) {
  final userId = ref.watch(authStateProvider).user?.id ?? '';
  return HeartHealthNotifier(
    repository: ref.watch(heartHealthRepositoryProvider),
    userId: userId,
  );
});

/// Mirrors [HeartHealthData.fromJson] so the disk write-through round-trips
/// losslessly.
Map<String, dynamic> _encodeHeartHealth(HeartHealthData d) => {
      'local_date': d.localDate,
      'score': d.score,
      'delta': d.delta,
      'label': d.label,
      'components': d.components
          .map((c) => {
                'key': c.key,
                'label': c.label,
                'score': c.score,
                'display': c.display,
                'band': c.band,
              })
          .toList(),
      'headline': d.headline,
      'body': d.body,
      'delivery': d.delivery,
    };

// ---------------------------------------------------------------------------
// Models — mirror services/heart_health_service.py
// ---------------------------------------------------------------------------

@immutable
class HeartComponent {
  final String key;
  final String label;
  final int? score; // 0-100, null when no data
  final String display; // human value for the tile, e.g. "6h 41m"
  final String band; // Good | Fair | Poor | No data

  const HeartComponent({
    required this.key,
    required this.label,
    required this.score,
    required this.display,
    required this.band,
  });

  bool get hasData => score != null;

  factory HeartComponent.fromJson(Map<String, dynamic> json) {
    return HeartComponent(
      key: json['key'] as String,
      label: json['label'] as String? ?? '',
      score: json['score'] as int?,
      display: json['display'] as String? ?? '',
      band: json['band'] as String? ?? 'No data',
    );
  }
}

@immutable
class HeartHealthData {
  final String localDate;
  final int score; // 0-100
  final int? delta; // vs previous snapshot
  final String label; // Excellent | Good | Fair | Poor
  final List<HeartComponent> components;
  final String headline;
  final String body;
  final String delivery;

  const HeartHealthData({
    required this.localDate,
    required this.score,
    required this.delta,
    required this.label,
    required this.components,
    required this.headline,
    required this.body,
    required this.delivery,
  });

  factory HeartHealthData.fromJson(Map<String, dynamic> json) {
    return HeartHealthData(
      localDate: json['local_date'] as String? ?? '',
      score: json['score'] as int? ?? 0,
      delta: json['delta'] as int?,
      label: json['label'] as String? ?? '',
      components: ((json['components'] as List<dynamic>?) ?? [])
          .map((e) =>
              HeartComponent.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      headline: json['headline'] as String? ?? '',
      body: json['body'] as String? ?? '',
      delivery: json['delivery'] as String? ?? 'deterministic_fallback',
    );
  }
}
