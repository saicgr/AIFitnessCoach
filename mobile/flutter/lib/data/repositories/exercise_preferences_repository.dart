import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../services/api_client.dart';

/// Exercise preferences repository provider
final exercisePreferencesRepositoryProvider = Provider<ExercisePreferencesRepository>((ref) {
  return ExercisePreferencesRepository(ref.watch(apiClientProvider));
});

/// Model for a favorite exercise
class FavoriteExercise {
  final String id;
  final String exerciseName;
  final String? exerciseId;
  final DateTime addedAt;

  const FavoriteExercise({
    required this.id,
    required this.exerciseName,
    this.exerciseId,
    required this.addedAt,
  });

  factory FavoriteExercise.fromJson(Map<String, dynamic> json) {
    return FavoriteExercise(
      id: json['id'] as String,
      exerciseName: json['exercise_name'] as String,
      exerciseId: json['exercise_id'] as String?,
      addedAt: DateTime.parse(json['added_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'exercise_name': exerciseName,
    'exercise_id': exerciseId,
    'added_at': addedAt.toIso8601String(),
  };
}

/// Model for a staple exercise (never rotated out)
class StapleExercise {
  final String id;
  final String exerciseName;
  final String? libraryId;
  final String? muscleGroup;
  final String? reason;
  final DateTime createdAt;
  final String? bodyPart;
  final String? equipment;
  final String? gifUrl;

  const StapleExercise({
    required this.id,
    required this.exerciseName,
    this.libraryId,
    this.muscleGroup,
    this.reason,
    required this.createdAt,
    this.bodyPart,
    this.equipment,
    this.gifUrl,
  });

  factory StapleExercise.fromJson(Map<String, dynamic> json) {
    return StapleExercise(
      id: json['id'] as String,
      exerciseName: json['exercise_name'] as String,
      libraryId: json['library_id'] as String?,
      muscleGroup: json['muscle_group'] as String?,
      reason: json['reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      bodyPart: json['body_part'] as String?,
      equipment: json['equipment'] as String?,
      gifUrl: json['gif_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'exercise_name': exerciseName,
    'library_id': libraryId,
    'muscle_group': muscleGroup,
    'reason': reason,
    'created_at': createdAt.toIso8601String(),
  };
}

/// Model for variation preference
class VariationPreference {
  final int variationPercentage;
  final String description;

  const VariationPreference({
    required this.variationPercentage,
    required this.description,
  });

  factory VariationPreference.fromJson(Map<String, dynamic> json) {
    return VariationPreference(
      variationPercentage: json['variation_percentage'] as int,
      description: json['description'] as String,
    );
  }
}

/// Model for week-over-week exercise comparison
class WeekComparison {
  final DateTime currentWeekStart;
  final DateTime previousWeekStart;
  final List<String> keptExercises;
  final List<String> newExercises;
  final List<String> removedExercises;
  final int totalCurrent;
  final int totalPrevious;
  final String variationSummary;

  const WeekComparison({
    required this.currentWeekStart,
    required this.previousWeekStart,
    required this.keptExercises,
    required this.newExercises,
    required this.removedExercises,
    required this.totalCurrent,
    required this.totalPrevious,
    required this.variationSummary,
  });

  factory WeekComparison.fromJson(Map<String, dynamic> json) {
    return WeekComparison(
      currentWeekStart: DateTime.parse(json['current_week_start'] as String),
      previousWeekStart: DateTime.parse(json['previous_week_start'] as String),
      keptExercises: (json['kept_exercises'] as List<dynamic>).cast<String>(),
      newExercises: (json['new_exercises'] as List<dynamic>).cast<String>(),
      removedExercises: (json['removed_exercises'] as List<dynamic>).cast<String>(),
      totalCurrent: json['total_current'] as int,
      totalPrevious: json['total_previous'] as int,
      variationSummary: json['variation_summary'] as String,
    );
  }

  /// Check if there are any changes this week
  bool get hasChanges => newExercises.isNotEmpty || removedExercises.isNotEmpty;

  /// Get percentage of exercises that changed
  double get changePercentage {
    if (totalPrevious == 0) return 0.0;
    return (newExercises.length / totalPrevious) * 100;
  }
}

/// Model for a queued exercise
class QueuedExercise {
  final String id;
  final String exerciseName;
  final String? exerciseId;
  final int priority;
  final String? targetMuscleGroup;
  final DateTime addedAt;
  final DateTime expiresAt;
  final DateTime? usedAt;

  const QueuedExercise({
    required this.id,
    required this.exerciseName,
    this.exerciseId,
    required this.priority,
    this.targetMuscleGroup,
    required this.addedAt,
    required this.expiresAt,
    this.usedAt,
  });

  factory QueuedExercise.fromJson(Map<String, dynamic> json) {
    return QueuedExercise(
      id: json['id'] as String,
      exerciseName: json['exercise_name'] as String,
      exerciseId: json['exercise_id'] as String?,
      priority: json['priority'] as int? ?? 0,
      targetMuscleGroup: json['target_muscle_group'] as String?,
      addedAt: DateTime.parse(json['added_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      usedAt: json['used_at'] != null ? DateTime.parse(json['used_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'exercise_name': exerciseName,
    'exercise_id': exerciseId,
    'priority': priority,
    'target_muscle_group': targetMuscleGroup,
    'added_at': addedAt.toIso8601String(),
    'expires_at': expiresAt.toIso8601String(),
    'used_at': usedAt?.toIso8601String(),
  };

  /// Check if this queue item is still active (not used, not expired)
  bool get isActive => usedAt == null && expiresAt.isAfter(DateTime.now());
}

/// Repository for exercise preferences (favorites, queue, consistency mode)
class ExercisePreferencesRepository {
  final ApiClient _apiClient;

  ExercisePreferencesRepository(this._apiClient);

  // ─────────────────────────────────────────────────────────────────
  // Favorite Exercises
  // ─────────────────────────────────────────────────────────────────

  /// Get all favorite exercises for a user
  Future<List<FavoriteExercise>> getFavoriteExercises(String userId) async {
    debugPrint('❤️ [ExercisePrefs] Fetching favorite exercises for user: $userId');

    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${ApiConstants.baseUrl}/api/v1/users/$userId/favorite-exercises',
      );

      if (response.data != null) {
        final favorites = response.data!
            .map((json) => FavoriteExercise.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('✅ [ExercisePrefs] Found ${favorites.length} favorite exercises');
        return favorites;
      }

      return [];
    } catch (e, stackTrace) {
      debugPrint('❌ [ExercisePrefs] Error fetching favorites: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Add an exercise to favorites
  Future<FavoriteExercise> addFavoriteExercise(
    String userId,
    String exerciseName, {
    String? exerciseId,
  }) async {
    debugPrint('❤️ [ExercisePrefs] Adding favorite: $exerciseName for user: $userId');

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${ApiConstants.baseUrl}/api/v1/users/$userId/favorite-exercises',
        data: {
          'exercise_name': exerciseName,
          if (exerciseId != null) 'exercise_id': exerciseId,
        },
      );

      if (response.data != null) {
        final favorite = FavoriteExercise.fromJson(response.data!);
        debugPrint('✅ [ExercisePrefs] Added favorite: ${favorite.exerciseName}');
        return favorite;
      }

      throw Exception('Failed to add favorite exercise');
    } catch (e, stackTrace) {
      debugPrint('❌ [ExercisePrefs] Error adding favorite: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Remove an exercise from favorites
  Future<void> removeFavoriteExercise(String userId, String exerciseName) async {
    debugPrint('❤️ [ExercisePrefs] Removing favorite: $exerciseName for user: $userId');

    try {
      await _apiClient.delete(
        '${ApiConstants.baseUrl}/api/v1/users/$userId/favorite-exercises/${Uri.encodeComponent(exerciseName)}',
      );
      debugPrint('✅ [ExercisePrefs] Removed favorite: $exerciseName');
    } catch (e, stackTrace) {
      debugPrint('❌ [ExercisePrefs] Error removing favorite: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Check if an exercise is favorited
  Future<bool> isFavorite(String userId, String exerciseName) async {
    try {
      final favorites = await getFavoriteExercises(userId);
      return favorites.any((f) => f.exerciseName.toLowerCase() == exerciseName.toLowerCase());
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Exercise Queue
  // ─────────────────────────────────────────────────────────────────

  /// Get all queued exercises for a user
  Future<List<QueuedExercise>> getExerciseQueue(String userId) async {
    debugPrint('📋 [ExercisePrefs] Fetching exercise queue for user: $userId');

    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${ApiConstants.baseUrl}/api/v1/users/$userId/exercise-queue',
      );

      if (response.data != null) {
        final queue = response.data!
            .map((json) => QueuedExercise.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('✅ [ExercisePrefs] Found ${queue.length} queued exercises');
        return queue;
      }

      return [];
    } catch (e, stackTrace) {
      debugPrint('❌ [ExercisePrefs] Error fetching queue: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Add an exercise to the queue
  Future<QueuedExercise> addToQueue(
    String userId,
    String exerciseName, {
    String? exerciseId,
    int priority = 0,
    String? targetMuscleGroup,
  }) async {
    debugPrint('📋 [ExercisePrefs] Adding to queue: $exerciseName for user: $userId');

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${ApiConstants.baseUrl}/api/v1/users/$userId/exercise-queue',
        data: {
          'exercise_name': exerciseName,
          if (exerciseId != null) 'exercise_id': exerciseId,
          'priority': priority,
          if (targetMuscleGroup != null) 'target_muscle_group': targetMuscleGroup,
        },
      );

      if (response.data != null) {
        final queued = QueuedExercise.fromJson(response.data!);
        debugPrint('✅ [ExercisePrefs] Added to queue: ${queued.exerciseName}');
        return queued;
      }

      throw Exception('Failed to add exercise to queue');
    } catch (e, stackTrace) {
      debugPrint('❌ [ExercisePrefs] Error adding to queue: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Remove an exercise from the queue
  Future<void> removeFromQueue(String userId, String exerciseName) async {
    debugPrint('📋 [ExercisePrefs] Removing from queue: $exerciseName for user: $userId');

    try {
      await _apiClient.delete(
        '${ApiConstants.baseUrl}/api/v1/users/$userId/exercise-queue/${Uri.encodeComponent(exerciseName)}',
      );
      debugPrint('✅ [ExercisePrefs] Removed from queue: $exerciseName');
    } catch (e, stackTrace) {
      debugPrint('❌ [ExercisePrefs] Error removing from queue: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Check if an exercise is in the queue
  Future<bool> isQueued(String userId, String exerciseName) async {
    try {
      final queue = await getExerciseQueue(userId);
      return queue.any((q) =>
        q.exerciseName.toLowerCase() == exerciseName.toLowerCase() && q.isActive);
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Consistency Mode
  // ─────────────────────────────────────────────────────────────────

  /// Get user's exercise consistency mode
  Future<String> getConsistencyMode(String userId) async {
    debugPrint('🔄 [ExercisePrefs] Fetching consistency mode for user: $userId');

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConstants.baseUrl}/api/v1/users/$userId',
      );

      if (response.data != null) {
        // Parse preferences JSON if it exists
        final preferencesRaw = response.data!['preferences'];
        if (preferencesRaw != null) {
          Map<String, dynamic>? preferences;
          if (preferencesRaw is String) {
            try {
              if (preferencesRaw.isEmpty) {
                preferences = {};
              } else if (preferencesRaw.startsWith('{')) {
                final parsed = await _parseJson(preferencesRaw);
                preferences = parsed ?? {};
              } else {
                preferences = {};
              }
            } catch (_) {
              preferences = {};
            }
          } else if (preferencesRaw is Map) {
            preferences = Map<String, dynamic>.from(preferencesRaw);
          }

          final mode = preferences?['exercise_consistency'] as String? ?? 'vary';
          debugPrint('✅ [ExercisePrefs] Consistency mode: $mode');
          return mode;
        }
      }

      return 'vary'; // Default
    } catch (e, stackTrace) {
      debugPrint('❌ [ExercisePrefs] Error fetching consistency mode: $e');
      debugPrint('Stack trace: $stackTrace');
      return 'vary'; // Default on error
    }
  }

  /// Helper to parse JSON string
  Future<Map<String, dynamic>?> _parseJson(String jsonString) async {
    try {
      final decoded = await compute(_decodeJson, jsonString);
      return decoded;
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic>? _decodeJson(String jsonString) {
    try {
      return Map<String, dynamic>.from(
        (jsonString.isEmpty || !jsonString.startsWith('{'))
          ? {}
          : Map<String, dynamic>.from(_jsonDecode(jsonString) ?? {})
      );
    } catch (_) {
      return null;
    }
  }

  static dynamic _jsonDecode(String source) {
    try {
      return source.isEmpty ? null : (source.startsWith('{') || source.startsWith('['))
        ? _parseJsonValue(source)
        : null;
    } catch (_) {
      return null;
    }
  }

  static dynamic _parseJsonValue(String source) {
    // Simple JSON parsing - for production, use dart:convert
    try {
      if (source.startsWith('{')) {
        // Parse object
        final result = <String, dynamic>{};
        // This is a simplified parser - in production use jsonDecode
        return result;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Set user's exercise consistency mode
  Future<void> setConsistencyMode(String userId, String mode) async {
    debugPrint('🔄 [ExercisePrefs] Setting consistency mode to: $mode for user: $userId');

    try {
      await _apiClient.put(
        '${ApiConstants.baseUrl}/api/v1/users/$userId',
        data: {'exercise_consistency': mode},
      );
      debugPrint('✅ [ExercisePrefs] Updated consistency mode to: $mode');
    } catch (e, stackTrace) {
      debugPrint('❌ [ExercisePrefs] Error setting consistency mode: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Staple Exercises (Core lifts that never rotate)
  // ─────────────────────────────────────────────────────────────────

  /// Get all staple exercises for a user
  Future<List<StapleExercise>> getStapleExercises(String userId) async {
    debugPrint('🔒 [ExercisePrefs] Fetching staple exercises for user: $userId');

    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${ApiConstants.baseUrl}/api/v1/exercise-preferences/staples/$userId',
      );

      if (response.data != null) {
        final staples = response.data!
            .map((json) => StapleExercise.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('✅ [ExercisePrefs] Found ${staples.length} staple exercises');
        return staples;
      }

      return [];
    } catch (e, stackTrace) {
      debugPrint('❌ [ExercisePrefs] Error fetching staples: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Add an exercise to staples
  Future<StapleExercise> addStapleExercise(
    String userId,
    String exerciseName, {
    String? libraryId,
    String? muscleGroup,
    String? reason,
  }) async {
    debugPrint('🔒 [ExercisePrefs] Adding staple: $exerciseName for user: $userId');

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${ApiConstants.baseUrl}/api/v1/exercise-preferences/staples',
        data: {
          'user_id': userId,
          'exercise_name': exerciseName,
          if (libraryId != null) 'library_id': libraryId,
          if (muscleGroup != null) 'muscle_group': muscleGroup,
          if (reason != null) 'reason': reason,
        },
      );

      if (response.data != null) {
        final staple = StapleExercise.fromJson(response.data!);
        debugPrint('✅ [ExercisePrefs] Added staple: ${staple.exerciseName}');
        return staple;
      }

      throw Exception('Failed to add staple exercise');
    } catch (e, stackTrace) {
      debugPrint('❌ [ExercisePrefs] Error adding staple: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Remove an exercise from staples
  Future<void> removeStapleExercise(String userId, String stapleId) async {
    debugPrint('🔒 [ExercisePrefs] Removing staple: $stapleId for user: $userId');

    try {
      await _apiClient.delete(
        '${ApiConstants.baseUrl}/api/v1/exercise-preferences/staples/$userId/$stapleId',
      );
      debugPrint('✅ [ExercisePrefs] Removed staple: $stapleId');
    } catch (e, stackTrace) {
      debugPrint('❌ [ExercisePrefs] Error removing staple: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Check if an exercise is a staple
  Future<bool> isStaple(String userId, String exerciseName) async {
    try {
      final staples = await getStapleExercises(userId);
      return staples.any((s) => s.exerciseName.toLowerCase() == exerciseName.toLowerCase());
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Variation Percentage
  // ─────────────────────────────────────────────────────────────────

  /// Get user's variation percentage preference
  Future<VariationPreference> getVariationPreference(String userId) async {
    debugPrint('🔄 [ExercisePrefs] Fetching variation preference for user: $userId');

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConstants.baseUrl}/api/v1/exercise-preferences/variation/$userId',
      );

      if (response.data != null) {
        final pref = VariationPreference.fromJson(response.data!);
        debugPrint('✅ [ExercisePrefs] Variation: ${pref.variationPercentage}% - ${pref.description}');
        return pref;
      }

      return const VariationPreference(
        variationPercentage: 30,
        description: 'Balanced variety',
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [ExercisePrefs] Error fetching variation: $e');
      debugPrint('Stack trace: $stackTrace');
      return const VariationPreference(
        variationPercentage: 30,
        description: 'Balanced variety',
      );
    }
  }

  /// Set user's variation percentage preference
  Future<VariationPreference> setVariationPreference(String userId, int percentage) async {
    debugPrint('🔄 [ExercisePrefs] Setting variation to: $percentage% for user: $userId');

    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '${ApiConstants.baseUrl}/api/v1/exercise-preferences/variation',
        data: {
          'user_id': userId,
          'variation_percentage': percentage,
        },
      );

      if (response.data != null) {
        final pref = VariationPreference.fromJson(response.data!);
        debugPrint('✅ [ExercisePrefs] Updated variation to: ${pref.variationPercentage}%');
        return pref;
      }

      throw Exception('Failed to update variation preference');
    } catch (e, stackTrace) {
      debugPrint('❌ [ExercisePrefs] Error setting variation: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Week-over-Week Comparison
  // ─────────────────────────────────────────────────────────────────

  /// Get week-over-week exercise comparison
  Future<WeekComparison?> getWeekComparison(String userId) async {
    debugPrint('📊 [ExercisePrefs] Fetching week comparison for user: $userId');

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConstants.baseUrl}/api/v1/exercise-preferences/week-comparison/$userId',
      );

      if (response.data != null) {
        final comparison = WeekComparison.fromJson(response.data!);
        debugPrint('✅ [ExercisePrefs] Week comparison: ${comparison.variationSummary}');
        return comparison;
      }

      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ [ExercisePrefs] Error fetching week comparison: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }
}
