import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../models/custom_exercise.dart';
import '../services/api_client.dart';

/// Custom exercise repository provider
final customExerciseRepositoryProvider = Provider<CustomExerciseRepository>((ref) {
  return CustomExerciseRepository(ref.watch(apiClientProvider));
});

/// Repository for custom exercise operations including composites
class CustomExerciseRepository {
  final ApiClient _apiClient;

  CustomExerciseRepository(this._apiClient);

  // ============================================================================
  // Fetch Operations
  // ============================================================================

  /// Get all custom exercises for a user (including composites) with usage stats
  Future<List<CustomExercise>> getAllCustomExercises(String userId) async {
    debugPrint('🏋️ [CustomExerciseRepo] Fetching all custom exercises for user: $userId');

    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${ApiConstants.baseUrl}/api/v1/exercises/custom/$userId/all',
      );

      if (response.data != null) {
        final exercises = response.data!
            .cast<Map<String, dynamic>>()
            .map((json) => CustomExercise.fromJson(json))
            .toList();
        debugPrint('✅ [CustomExerciseRepo] Found ${exercises.length} custom exercises');
        return exercises;
      }

      debugPrint('⚠️ [CustomExerciseRepo] No custom exercises found (null response)');
      return [];
    } catch (e, stackTrace) {
      debugPrint('❌ [CustomExerciseRepo] Error fetching custom exercises: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get custom exercise statistics
  Future<CustomExerciseStats> getStats(String userId) async {
    debugPrint('🏋️ [CustomExerciseRepo] Fetching stats for user: $userId');

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConstants.baseUrl}/api/v1/exercises/custom/$userId/stats',
      );

      if (response.data != null) {
        final stats = CustomExerciseStats.fromJson(response.data!);
        debugPrint('✅ [CustomExerciseRepo] Stats: ${stats.totalCustomExercises} exercises, ${stats.totalUses} uses');
        return stats;
      }

      return const CustomExerciseStats(
        totalCustomExercises: 0,
        simpleExercises: 0,
        compositeExercises: 0,
        totalUses: 0,
        mostUsed: [],
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [CustomExerciseRepo] Error fetching stats: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ============================================================================
  // Create Operations
  // ============================================================================

  /// Create a simple (non-composite) custom exercise
  Future<CustomExercise> createSimpleExercise({
    required String userId,
    required CreateCustomExerciseRequest request,
  }) async {
    debugPrint('🏋️ [CustomExerciseRepo] Creating simple exercise: ${request.name}');

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${ApiConstants.baseUrl}/api/v1/exercises/custom/$userId',
        data: request.toJson(),
      );

      if (response.data != null) {
        // The response from the simple create endpoint has fewer fields
        // We need to map it to a full CustomExercise
        final data = response.data!;
        final exercise = CustomExercise(
          id: data['id'] as String,
          name: data['name'] as String,
          primaryMuscle: data['primary_muscle'] as String,
          equipment: data['equipment'] as String,
          instructions: data['instructions'] as String?,
          defaultSets: data['default_sets'] as int? ?? 3,
          defaultReps: data['default_reps'] as int?,
          isCompound: data['is_compound'] as bool? ?? false,
          isComposite: false,
          tags: ['custom'],
          usageCount: 0,
          createdAt: data['created_at'] as String,
        );
        debugPrint('✅ [CustomExerciseRepo] Created exercise: ${exercise.name} (ID: ${exercise.id})');
        return exercise;
      }

      throw Exception('Failed to create exercise: No data returned');
    } catch (e, stackTrace) {
      debugPrint('❌ [CustomExerciseRepo] Error creating exercise: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Create a composite (combo) exercise
  Future<CustomExercise> createCompositeExercise({
    required String userId,
    required CreateCompositeExerciseRequest request,
  }) async {
    debugPrint('🏋️ [CustomExerciseRepo] Creating composite exercise: ${request.name}');
    debugPrint('🏋️ [CustomExerciseRepo] Components: ${request.componentExercises.map((c) => c.name).join(', ')}');

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${ApiConstants.baseUrl}/api/v1/exercises/custom/$userId/composite',
        data: request.toJson(),
      );

      if (response.data != null) {
        final data = response.data!;

        // Parse component exercises
        List<ComponentExercise> components = [];
        final componentData = data['component_exercises'];
        if (componentData is List) {
          components = componentData
              .cast<Map<String, dynamic>>()
              .map((c) => ComponentExercise.fromJson(c))
              .toList();
        }

        // Parse tags
        List<String> tags = [];
        final tagsData = data['tags'];
        if (tagsData is List) {
          tags = tagsData.cast<String>();
        }

        // Parse secondary muscles
        List<String> secondaryMuscles = [];
        final secondaryData = data['secondary_muscles'];
        if (secondaryData is List) {
          secondaryMuscles = secondaryData.cast<String>();
        }

        final exercise = CustomExercise(
          id: data['id'] as String,
          name: data['name'] as String,
          primaryMuscle: data['primary_muscle'] as String,
          secondaryMuscles: secondaryMuscles,
          equipment: data['equipment'] as String,
          instructions: data['instructions'] as String?,
          defaultSets: data['default_sets'] as int? ?? 3,
          defaultRestSeconds: data['default_rest_seconds'] as int?,
          isCompound: true,
          isComposite: true,
          comboType: data['combo_type'] as String?,
          componentExercises: components,
          customNotes: data['custom_notes'] as String?,
          tags: tags,
          usageCount: data['usage_count'] as int? ?? 0,
          createdAt: data['created_at'] as String,
        );
        debugPrint('✅ [CustomExerciseRepo] Created composite: ${exercise.name} (ID: ${exercise.id})');
        return exercise;
      }

      throw Exception('Failed to create composite exercise: No data returned');
    } catch (e, stackTrace) {
      debugPrint('❌ [CustomExerciseRepo] Error creating composite: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ============================================================================
  // Update Operations
  // ============================================================================

  /// Update a custom exercise
  Future<CustomExercise> updateExercise({
    required String userId,
    required String exerciseId,
    required Map<String, dynamic> updates,
  }) async {
    debugPrint('🏋️ [CustomExerciseRepo] Updating exercise: $exerciseId');

    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '${ApiConstants.baseUrl}/api/v1/exercises/custom/$userId/$exerciseId',
        data: updates,
      );

      if (response.data != null) {
        final exercise = _parseFullExercise(response.data!);
        debugPrint('✅ [CustomExerciseRepo] Updated exercise: ${exercise.name}');
        return exercise;
      }

      throw Exception('Failed to update exercise: No data returned');
    } catch (e, stackTrace) {
      debugPrint('❌ [CustomExerciseRepo] Error updating exercise: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ============================================================================
  // Delete Operations
  // ============================================================================

  /// Delete a custom exercise
  Future<void> deleteExercise({
    required String userId,
    required String exerciseId,
  }) async {
    debugPrint('🏋️ [CustomExerciseRepo] Deleting exercise: $exerciseId');

    try {
      await _apiClient.delete(
        '${ApiConstants.baseUrl}/api/v1/exercises/custom/$userId/$exerciseId',
      );
      debugPrint('✅ [CustomExerciseRepo] Deleted exercise: $exerciseId');
    } catch (e, stackTrace) {
      debugPrint('❌ [CustomExerciseRepo] Error deleting exercise: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ============================================================================
  // Usage Tracking
  // ============================================================================

  /// Log usage of a custom exercise
  Future<void> logUsage({
    required String userId,
    required String exerciseId,
    String? workoutId,
    int? rating,
    String? notes,
  }) async {
    debugPrint('🏋️ [CustomExerciseRepo] Logging usage of exercise: $exerciseId');

    try {
      final queryParams = <String, String>{};
      if (workoutId != null) queryParams['workout_id'] = workoutId;
      if (rating != null) queryParams['rating'] = rating.toString();
      if (notes != null) queryParams['notes'] = notes;

      await _apiClient.post(
        '${ApiConstants.baseUrl}/api/v1/exercises/custom/$userId/$exerciseId/log-usage',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      debugPrint('✅ [CustomExerciseRepo] Logged usage');
    } catch (e, stackTrace) {
      debugPrint('❌ [CustomExerciseRepo] Error logging usage: $e');
      debugPrint('Stack trace: $stackTrace');
      // Don't rethrow - usage logging is not critical
    }
  }

  // ============================================================================
  // Search
  // ============================================================================

  /// Search the exercise library (for finding exercises to combine)
  Future<List<ExerciseSearchResult>> searchLibrary({
    required String query,
    int limit = 20,
  }) async {
    debugPrint('🔍 [CustomExerciseRepo] Searching library for: $query');

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConstants.baseUrl}/api/v1/exercises/library/search',
        queryParameters: {
          'query': query,
          'limit': limit.toString(),
        },
      );

      if (response.data != null) {
        final results = response.data!['results'] as List?;
        if (results != null) {
          final exercises = results
              .cast<Map<String, dynamic>>()
              .map((json) => ExerciseSearchResult.fromJson(json))
              .toList();
          debugPrint('✅ [CustomExerciseRepo] Found ${exercises.length} exercises');
          return exercises;
        }
      }

      return [];
    } catch (e, stackTrace) {
      debugPrint('❌ [CustomExerciseRepo] Error searching library: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ============================================================================
  // Helpers
  // ============================================================================

  /// Parse a full exercise response
  CustomExercise _parseFullExercise(Map<String, dynamic> data) {
    // Parse component exercises
    List<ComponentExercise>? components;
    final componentData = data['component_exercises'];
    if (componentData is List && componentData.isNotEmpty) {
      components = componentData
          .cast<Map<String, dynamic>>()
          .map((c) => ComponentExercise.fromJson(c))
          .toList();
    }

    // Parse tags
    List<String> tags = [];
    final tagsData = data['tags'];
    if (tagsData is List) {
      tags = tagsData.cast<String>();
    }

    // Parse secondary muscles
    List<String>? secondaryMuscles;
    final secondaryData = data['secondary_muscles'];
    if (secondaryData is List && secondaryData.isNotEmpty) {
      secondaryMuscles = secondaryData.cast<String>();
    }

    return CustomExercise(
      id: data['id'] as String,
      name: data['name'] as String,
      primaryMuscle: data['primary_muscle'] as String? ?? '',
      secondaryMuscles: secondaryMuscles,
      equipment: data['equipment'] as String? ?? 'bodyweight',
      instructions: data['instructions'] as String?,
      defaultSets: data['default_sets'] as int? ?? 3,
      defaultReps: data['default_reps'] as int?,
      defaultRestSeconds: data['default_rest_seconds'] as int?,
      isCompound: data['is_compound'] as bool? ?? false,
      isComposite: data['is_composite'] as bool? ?? false,
      comboType: data['combo_type'] as String?,
      componentExercises: components,
      customNotes: data['custom_notes'] as String?,
      customVideoUrl: data['custom_video_url'] as String?,
      tags: tags,
      usageCount: data['usage_count'] as int? ?? 0,
      lastUsed: data['last_used'] as String?,
      createdAt: data['created_at'] as String,
    );
  }
}
