import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/achievement.dart';
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

  const AchievementsState({
    this.isLoading = false,
    this.error,
    this.summary,
    this.achievements = const [],
    this.allTypes = const [],
  });

  AchievementsState copyWith({
    bool? isLoading,
    String? error,
    AchievementsSummary? summary,
    List<UserAchievement>? achievements,
    List<AchievementType>? allTypes,
  }) {
    return AchievementsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      summary: summary ?? this.summary,
      achievements: achievements ?? this.achievements,
      allTypes: allTypes ?? this.allTypes,
    );
  }
}

/// Achievements state provider
final achievementsProvider =
    StateNotifierProvider<AchievementsNotifier, AchievementsState>((ref) {
  return AchievementsNotifier(ref.watch(achievementsRepositoryProvider));
});

/// Achievements state notifier
class AchievementsNotifier extends StateNotifier<AchievementsState> {
  final AchievementsRepository _repository;

  AchievementsNotifier(this._repository) : super(const AchievementsState());

  /// Load achievements summary for a user
  Future<void> loadSummary(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final summary = await _repository.getSummary(userId);
      state = state.copyWith(isLoading: false, summary: summary);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load all achievements for a user
  Future<void> loadAchievements(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final achievements = await _repository.getUserAchievements(userId);
      state = state.copyWith(isLoading: false, achievements: achievements);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
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
      final response = await _client.get('/achievements/user/$userId/streaks');
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
