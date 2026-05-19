import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/achievement.dart';
import '../../core/cache/cache_first_mixin.dart';
import '../../utils/tz.dart';
import '../services/api_client.dart';

/// Achievements repository provider
final achievementsRepositoryProvider = Provider<AchievementsRepository>((ref) {
  return AchievementsRepository(ref.watch(apiClientProvider));
});

/// Achievements state
class AchievementsState {
  final bool isLoading;
  final String? error;
  final AchievementsSummary? summary;
  final List<UserAchievement> achievements;
  final List<AchievementType> allTypes;

  /// True once a load (cache OR network) has produced data at least once for
  /// this notifier instance. The Achievements screen uses this to decide
  /// whether to show a skeleton (true first-ever open) versus instant content.
  final bool hasLoaded;

  const AchievementsState({
    this.isLoading = false,
    this.error,
    this.summary,
    this.achievements = const [],
    this.allTypes = const [],
    this.hasLoaded = false,
  });

  AchievementsState copyWith({
    bool? isLoading,
    String? error,
    AchievementsSummary? summary,
    List<UserAchievement>? achievements,
    List<AchievementType>? allTypes,
    bool? hasLoaded,
  }) {
    return AchievementsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      summary: summary ?? this.summary,
      achievements: achievements ?? this.achievements,
      allTypes: allTypes ?? this.allTypes,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}

/// Achievements state provider
final achievementsProvider =
    StateNotifierProvider<AchievementsNotifier, AchievementsState>((ref) {
  return AchievementsNotifier(ref.watch(achievementsRepositoryProvider));
});

/// Achievements state notifier.
///
/// Uses [CacheFirstMixin] so the Achievements screen renders instantly on a
/// warm start: a previously-persisted summary / badge list is emitted from
/// disk before any network I/O, then silently revalidated. The screen only
/// ever shows a skeleton on a genuine first-ever open (see [AchievementsState.hasLoaded]).
class AchievementsNotifier extends StateNotifier<AchievementsState>
    with CacheFirstMixin {
  final AchievementsRepository _repository;

  AchievementsNotifier(this._repository) : super(const AchievementsState());

  /// Bump when the cached payload shape changes so stale blobs are dropped.
  static const int _schemaVersion = 1;

  /// Load achievements summary for a user (cache-first, stale-while-revalidate).
  Future<void> loadSummary(String userId) async {
    // Only surface a loading flag when there is genuinely nothing to show yet;
    // a warm start emits the cached value synchronously-fast and never flashes.
    if (state.summary == null) {
      state = state.copyWith(isLoading: true, error: null);
    }
    await loadCacheFirst<AchievementsSummary>(
      cacheKey: 'achievements_summary',
      userId: userId,
      ttl: const Duration(hours: 6),
      schemaVersion: _schemaVersion,
      fetch: () => _repository.getSummary(userId),
      decode: AchievementsSummary.fromJson,
      encode: (s) => s.toJson(),
      emit: (summary, {required bool fromCache}) {
        state = state.copyWith(
          isLoading: false,
          summary: summary,
          hasLoaded: true,
        );
      },
      onError: (e, _) {
        // Keep any cached summary on screen; only flag an error when the
        // screen has nothing to render.
        if (!mounted) return;
        state = state.copyWith(
          isLoading: false,
          error: state.summary == null ? e.toString() : null,
        );
      },
    );
  }

  /// Load all achievements for a user (cache-first, stale-while-revalidate).
  Future<void> loadAchievements(String userId) async {
    if (state.achievements.isEmpty) {
      state = state.copyWith(isLoading: true, error: null);
    }
    // The cache-first primitive is generic over a single object, so the badge
    // list is wrapped in a small `{items: [...]}` envelope for encode/decode.
    await loadCacheFirst<List<UserAchievement>>(
      cacheKey: 'achievements_list',
      userId: userId,
      ttl: const Duration(hours: 6),
      schemaVersion: _schemaVersion,
      fetch: () => _repository.getUserAchievements(userId),
      decode: (json) => (json['items'] as List? ?? const [])
          .map((e) => UserAchievement.fromJson(e as Map<String, dynamic>))
          .toList(),
      encode: (list) => {'items': list.map((e) => e.toJson()).toList()},
      emit: (achievements, {required bool fromCache}) {
        state = state.copyWith(
          isLoading: false,
          achievements: achievements,
          hasLoaded: true,
        );
      },
      onError: (e, _) {
        if (!mounted) return;
        state = state.copyWith(
          isLoading: false,
          error: state.achievements.isEmpty ? e.toString() : null,
        );
      },
    );
  }

  /// Load all achievement types
  Future<void> loadTypes() async {
    try {
      final types = await _repository.getAchievementTypes();
      state = state.copyWith(allTypes: types);
    } catch (e) {
      debugPrint('Error loading achievement types: $e');
    }
  }
}

/// Achievements repository
class AchievementsRepository {
  final ApiClient _client;

  AchievementsRepository(this._client);

  /// Get all achievement types
  Future<List<AchievementType>> getAchievementTypes() async {
    try {
      final response = await _client.get('/achievements/types');
      final data = response.data as List;
      return data.map((json) => AchievementType.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting achievement types: $e');
      rethrow;
    }
  }

  /// Get achievements summary for a user
  Future<AchievementsSummary> getSummary(String userId) async {
    try {
      final response = await _client.get('/achievements/user/$userId/summary');
      return AchievementsSummary.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting achievements summary: $e');
      rethrow;
    }
  }

  /// Get all achievements earned by a user
  Future<List<UserAchievement>> getUserAchievements(String userId) async {
    try {
      final response = await _client.get('/achievements/user/$userId');
      final data = response.data as List;
      return data.map((json) => UserAchievement.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting user achievements: $e');
      rethrow;
    }
  }

  /// Get user streaks
  Future<List<UserStreak>> getUserStreaks(String userId) async {
    try {
      final response = await _client.get('/achievements/user/$userId/streaks',
        queryParameters: {'date': Tz.localDate()},
      );
      final data = response.data as List;
      return data.map((json) => UserStreak.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting user streaks: $e');
      rethrow;
    }
  }

  /// Get personal records
  Future<List<PersonalRecord>> getPersonalRecords(String userId) async {
    try {
      final response = await _client.get('/achievements/user/$userId/prs');
      final data = response.data as List;
      return data.map((json) => PersonalRecord.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting personal records: $e');
      rethrow;
    }
  }

  /// Mark achievements as notified
  Future<void> markNotified(String userId, List<String>? achievementIds) async {
    try {
      await _client.post(
        '/achievements/user/$userId/mark-notified',
        data: achievementIds != null ? {'achievement_ids': achievementIds} : null,
      );
    } catch (e) {
      debugPrint('Error marking achievements as notified: $e');
    }
  }
}
