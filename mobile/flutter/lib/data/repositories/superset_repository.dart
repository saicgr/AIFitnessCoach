import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../models/superset_preferences.dart';
import '../services/api_client.dart';

/// Superset repository provider
final supersetRepositoryProvider = Provider<SupersetRepository>((ref) {
  return SupersetRepository(ref.watch(apiClientProvider));
});

/// Repository for managing superset preferences, suggestions, and favorites
class SupersetRepository {
  final ApiClient _apiClient;

  SupersetRepository(this._apiClient);

  // ─────────────────────────────────────────────────────────────────
  // Superset Preferences
  // ─────────────────────────────────────────────────────────────────

  /// Get superset preferences for a user
  Future<SupersetPreferences> getPreferences(String userId) async {
    debugPrint('🔗 [SupersetRepo] Fetching preferences for user: $userId');

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConstants.baseUrl}${ApiConstants.supersets}/preferences/$userId',
      );

      if (response.data != null) {
        final preferences = SupersetPreferences.fromJson(response.data!);
        debugPrint('✅ [SupersetRepo] Fetched preferences: enabled=${preferences.supersetsEnabled}');
        return preferences;
      }

      // Return defaults if no preferences found
      return const SupersetPreferences();
    } catch (e, stackTrace) {
      debugPrint('❌ [SupersetRepo] Error fetching preferences: $e');
      debugPrint('Stack trace: $stackTrace');
      // Return defaults on error
      return const SupersetPreferences();
    }
  }

  /// Update superset preferences for a user
  Future<SupersetPreferences> updatePreferences(
    String userId,
    SupersetPreferences preferences,
  ) async {
    debugPrint('🔗 [SupersetRepo] Updating preferences for user: $userId');

    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '${ApiConstants.baseUrl}${ApiConstants.supersets}/preferences/$userId',
        data: {
          'supersets_enabled': preferences.supersetsEnabled,
          'prefer_antagonist_pairs': preferences.preferAntagonistPairs,
          'prefer_compound_sets': preferences.preferCompoundSets,
          'max_superset_pairs': preferences.maxSupersetPairs,
          'superset_rest_seconds': preferences.supersetRestSeconds,
          'post_superset_rest_seconds': preferences.postSupersetRestSeconds,
        },
      );

      if (response.data != null) {
        final updated = SupersetPreferences.fromJson(response.data!);
        debugPrint('✅ [SupersetRepo] Updated preferences: enabled=${updated.supersetsEnabled}');
        return updated;
      }

      throw Exception('Failed to update superset preferences');
    } catch (e, stackTrace) {
      debugPrint('❌ [SupersetRepo] Error updating preferences: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Superset Pair Management
  // ─────────────────────────────────────────────────────────────────

  /// Create a superset pair within a workout
  Future<ActiveSupersetPair> createSupersetPair(
    String workoutId,
    int exerciseIndex1,
    int exerciseIndex2, {
    int? restBetweenSeconds,
    int? restAfterSeconds,
  }) async {
    debugPrint('🔗 [SupersetRepo] Creating superset pair in workout: $workoutId');
    debugPrint('   Exercises: $exerciseIndex1 <-> $exerciseIndex2');

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${ApiConstants.baseUrl}${ApiConstants.supersets}/pairs',
        data: {
          'workout_id': workoutId,
          'exercise1_index': exerciseIndex1,
          'exercise2_index': exerciseIndex2,
          if (restBetweenSeconds != null) 'rest_between_seconds': restBetweenSeconds,
          if (restAfterSeconds != null) 'rest_after_seconds': restAfterSeconds,
        },
      );

      if (response.data != null) {
        final pair = ActiveSupersetPair.fromJson(response.data!);
        debugPrint('✅ [SupersetRepo] Created superset pair: group=${pair.supersetGroup}');
        return pair;
      }

      throw Exception('Failed to create superset pair');
    } catch (e, stackTrace) {
      debugPrint('❌ [SupersetRepo] Error creating superset pair: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Remove a superset pair from a workout
  Future<void> removeSupersetPair(String workoutId, int supersetGroup) async {
    debugPrint('🔗 [SupersetRepo] Removing superset group $supersetGroup from workout: $workoutId');

    try {
      await _apiClient.delete(
        '${ApiConstants.baseUrl}${ApiConstants.supersets}/pairs/$workoutId/$supersetGroup',
      );
      debugPrint('✅ [SupersetRepo] Removed superset group: $supersetGroup');
    } catch (e, stackTrace) {
      debugPrint('❌ [SupersetRepo] Error removing superset pair: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get all superset pairs for a workout
  Future<List<ActiveSupersetPair>> getWorkoutSupersets(String workoutId) async {
    debugPrint('🔗 [SupersetRepo] Fetching supersets for workout: $workoutId');

    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${ApiConstants.baseUrl}${ApiConstants.supersets}/pairs/$workoutId',
      );

      if (response.data != null) {
        final pairs = response.data!
            .map((json) => ActiveSupersetPair.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('✅ [SupersetRepo] Found ${pairs.length} superset pairs');
        return pairs;
      }

      return [];
    } catch (e, stackTrace) {
      debugPrint('❌ [SupersetRepo] Error fetching workout supersets: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Superset Suggestions
  // ─────────────────────────────────────────────────────────────────

  /// Get AI-suggested superset pairs for a workout
  Future<List<SupersetSuggestion>> getSuggestions(String userId, String workoutId) async {
    debugPrint('🔗 [SupersetRepo] Fetching suggestions for workout: $workoutId');

    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${ApiConstants.baseUrl}${ApiConstants.supersets}/suggestions/$userId/$workoutId',
      );

      if (response.data != null) {
        final suggestions = response.data!
            .map((json) => SupersetSuggestion.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('✅ [SupersetRepo] Found ${suggestions.length} suggestions');
        return suggestions;
      }

      return [];
    } catch (e, stackTrace) {
      debugPrint('❌ [SupersetRepo] Error fetching suggestions: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Accept a superset suggestion (creates the pair)
  Future<ActiveSupersetPair> acceptSuggestion(String suggestionId) async {
    debugPrint('🔗 [SupersetRepo] Accepting suggestion: $suggestionId');

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${ApiConstants.baseUrl}${ApiConstants.supersets}/suggestions/$suggestionId/accept',
      );

      if (response.data != null) {
        final pair = ActiveSupersetPair.fromJson(response.data!);
        debugPrint('✅ [SupersetRepo] Accepted suggestion, created pair: ${pair.supersetGroup}');
        return pair;
      }

      throw Exception('Failed to accept suggestion');
    } catch (e, stackTrace) {
      debugPrint('❌ [SupersetRepo] Error accepting suggestion: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Dismiss a superset suggestion
  Future<void> dismissSuggestion(String suggestionId) async {
    debugPrint('🔗 [SupersetRepo] Dismissing suggestion: $suggestionId');

    try {
      await _apiClient.delete(
        '${ApiConstants.baseUrl}${ApiConstants.supersets}/suggestions/$suggestionId',
      );
      debugPrint('✅ [SupersetRepo] Dismissed suggestion');
    } catch (e, stackTrace) {
      debugPrint('❌ [SupersetRepo] Error dismissing suggestion: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Favorite Superset Pairs
  // ─────────────────────────────────────────────────────────────────

  /// Get all favorite superset pairs for a user
  Future<List<FavoriteSupersetPair>> getFavorites(String userId) async {
    debugPrint('❤️ [SupersetRepo] Fetching favorite pairs for user: $userId');

    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${ApiConstants.baseUrl}${ApiConstants.supersets}/favorites/$userId',
      );

      if (response.data != null) {
        final favorites = response.data!
            .map((json) => FavoriteSupersetPair.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('✅ [SupersetRepo] Found ${favorites.length} favorite pairs');
        return favorites;
      }

      return [];
    } catch (e, stackTrace) {
      debugPrint('❌ [SupersetRepo] Error fetching favorites: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Add a superset pair to favorites
  Future<FavoriteSupersetPair> addFavorite(
    String userId,
    String exercise1Name,
    String exercise2Name, {
    String? exercise1Id,
    String? exercise2Id,
    SupersetPairingType pairingType = SupersetPairingType.antagonist,
    String? notes,
  }) async {
    debugPrint('❤️ [SupersetRepo] Adding favorite pair: $exercise1Name + $exercise2Name');

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${ApiConstants.baseUrl}${ApiConstants.supersets}/favorites',
        data: {
          'user_id': userId,
          'exercise1_name': exercise1Name,
          'exercise2_name': exercise2Name,
          if (exercise1Id != null) 'exercise1_id': exercise1Id,
          if (exercise2Id != null) 'exercise2_id': exercise2Id,
          'pairing_type': pairingType.value,
          if (notes != null) 'notes': notes,
        },
      );

      if (response.data != null) {
        final favorite = FavoriteSupersetPair.fromJson(response.data!);
        debugPrint('✅ [SupersetRepo] Added favorite pair: ${favorite.displayName}');
        return favorite;
      }

      throw Exception('Failed to add favorite pair');
    } catch (e, stackTrace) {
      debugPrint('❌ [SupersetRepo] Error adding favorite: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Remove a superset pair from favorites
  Future<void> removeFavorite(String userId, String pairId) async {
    debugPrint('❤️ [SupersetRepo] Removing favorite pair: $pairId');

    try {
      await _apiClient.delete(
        '${ApiConstants.baseUrl}${ApiConstants.supersets}/favorites/$userId/$pairId',
      );
      debugPrint('✅ [SupersetRepo] Removed favorite pair');
    } catch (e, stackTrace) {
      debugPrint('❌ [SupersetRepo] Error removing favorite: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Check if a pair is favorited
  Future<bool> isPairFavorited(String userId, String exercise1Name, String exercise2Name) async {
    try {
      final favorites = await getFavorites(userId);
      return favorites.any((f) =>
          (f.exercise1Name.toLowerCase() == exercise1Name.toLowerCase() &&
              f.exercise2Name.toLowerCase() == exercise2Name.toLowerCase()) ||
          (f.exercise1Name.toLowerCase() == exercise2Name.toLowerCase() &&
              f.exercise2Name.toLowerCase() == exercise1Name.toLowerCase()));
    } catch (e) {
      return false;
    }
  }

  /// Use a favorite pair (increments usage count)
  Future<void> useFavoritePair(String userId, String pairId) async {
    debugPrint('❤️ [SupersetRepo] Recording usage of favorite pair: $pairId');

    try {
      await _apiClient.post<void>(
        '${ApiConstants.baseUrl}${ApiConstants.supersets}/favorites/$userId/$pairId/use',
      );
      debugPrint('✅ [SupersetRepo] Recorded pair usage');
    } catch (e, stackTrace) {
      debugPrint('❌ [SupersetRepo] Error recording usage: $e');
      debugPrint('Stack trace: $stackTrace');
      // Non-critical, don't rethrow
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Superset History
  // ─────────────────────────────────────────────────────────────────

  /// Get superset history for a user
  Future<List<SupersetHistoryEntry>> getHistory(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    debugPrint('📜 [SupersetRepo] Fetching superset history for user: $userId');

    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${ApiConstants.baseUrl}${ApiConstants.supersets}/history/$userId',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.data != null) {
        final history = response.data!
            .map((json) => SupersetHistoryEntry.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('✅ [SupersetRepo] Found ${history.length} history entries');
        return history;
      }

      return [];
    } catch (e, stackTrace) {
      debugPrint('❌ [SupersetRepo] Error fetching history: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Record a superset completion
  Future<SupersetHistoryEntry> recordSupersetCompletion({
    required String userId,
    required String workoutId,
    required String exercise1Name,
    required String exercise2Name,
    required SupersetPairingType pairingType,
    bool wasCompleted = true,
    int? userRating,
  }) async {
    debugPrint('📜 [SupersetRepo] Recording superset completion');

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${ApiConstants.baseUrl}${ApiConstants.supersets}/history',
        data: {
          'user_id': userId,
          'workout_id': workoutId,
          'exercise1_name': exercise1Name,
          'exercise2_name': exercise2Name,
          'pairing_type': pairingType.value,
          'was_completed': wasCompleted,
          if (userRating != null) 'user_rating': userRating,
        },
      );

      if (response.data != null) {
        final entry = SupersetHistoryEntry.fromJson(response.data!);
        debugPrint('✅ [SupersetRepo] Recorded superset completion');
        return entry;
      }

      throw Exception('Failed to record superset completion');
    } catch (e, stackTrace) {
      debugPrint('❌ [SupersetRepo] Error recording completion: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Rate a superset pairing from history
  Future<void> rateSupersetPairing(String historyEntryId, int rating) async {
    debugPrint('⭐ [SupersetRepo] Rating superset pairing: $rating');

    try {
      await _apiClient.put<void>(
        '${ApiConstants.baseUrl}${ApiConstants.supersets}/history/$historyEntryId/rating',
        data: {'rating': rating},
      );
      debugPrint('✅ [SupersetRepo] Rated pairing');
    } catch (e, stackTrace) {
      debugPrint('❌ [SupersetRepo] Error rating pairing: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Utility Methods
  // ─────────────────────────────────────────────────────────────────

  /// Get recommended pairing types for two muscle groups
  Future<List<SupersetPairingType>> getRecommendedPairingTypes(
    String muscleGroup1,
    String muscleGroup2,
  ) async {
    debugPrint('🔍 [SupersetRepo] Getting recommended pairing types');

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConstants.baseUrl}${ApiConstants.supersets}/pairing-types',
        queryParameters: {
          'muscle1': muscleGroup1,
          'muscle2': muscleGroup2,
        },
      );

      if (response.data != null && response.data!['pairing_types'] != null) {
        final types = (response.data!['pairing_types'] as List<dynamic>)
            .map((t) => SupersetPairingType.values.firstWhere(
                  (pt) => pt.value == t,
                  orElse: () => SupersetPairingType.custom,
                ))
            .toList();
        debugPrint('✅ [SupersetRepo] Found ${types.length} recommended types');
        return types;
      }

      return [SupersetPairingType.custom];
    } catch (e, stackTrace) {
      debugPrint('❌ [SupersetRepo] Error getting pairing types: $e');
      debugPrint('Stack trace: $stackTrace');
      return [SupersetPairingType.custom];
    }
  }

  /// Get superset statistics for a user
  Future<Map<String, dynamic>> getSupersetStats(String userId) async {
    debugPrint('📊 [SupersetRepo] Fetching superset stats for user: $userId');

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConstants.baseUrl}${ApiConstants.supersets}/stats/$userId',
      );

      if (response.data != null) {
        debugPrint('✅ [SupersetRepo] Fetched superset stats');
        return response.data!;
      }

      return {
        'total_supersets_completed': 0,
        'favorite_pairs_count': 0,
        'most_used_pairing_type': null,
        'average_time_saved_minutes': 0,
      };
    } catch (e, stackTrace) {
      debugPrint('❌ [SupersetRepo] Error fetching stats: $e');
      debugPrint('Stack trace: $stackTrace');
      return {
        'total_supersets_completed': 0,
        'favorite_pairs_count': 0,
        'most_used_pairing_type': null,
        'average_time_saved_minutes': 0,
      };
    }
  }
}
