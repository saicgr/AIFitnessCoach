import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../services/api_client.dart';

/// Exercise repository provider
final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepository(ref.watch(apiClientProvider));
});

/// Repository for exercise-related API operations
class ExerciseRepository {
  final ApiClient _apiClient;

  ExerciseRepository(this._apiClient);

  /// Get all custom exercises for a user
  Future<List<Map<String, dynamic>>> getCustomExercises(String userId) async {
    debugPrint('🏋️ [ExerciseRepository] Fetching custom exercises for user: $userId');

    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${ApiConstants.baseUrl}/api/v1/exercises/custom/$userId',
      );

      if (response.data != null) {
        final exercises = response.data!.cast<Map<String, dynamic>>();
        debugPrint('✅ [ExerciseRepository] Found ${exercises.length} custom exercises');
        return exercises;
      }

      debugPrint('⚠️ [ExerciseRepository] No custom exercises found (null response)');
      return [];
    } catch (e, stackTrace) {
      debugPrint('❌ [ExerciseRepository] Error fetching custom exercises: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Create a new custom exercise
  Future<Map<String, dynamic>> createCustomExercise(
    String userId,
    Map<String, dynamic> exerciseData,
  ) async {
    debugPrint('🏋️ [ExerciseRepository] Creating custom exercise for user: $userId');
    debugPrint('🏋️ [ExerciseRepository] Exercise data: ${exerciseData['name']} - ${exerciseData['primary_muscle']}');

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${ApiConstants.baseUrl}/api/v1/exercises/custom/$userId',
        data: exerciseData,
      );

      if (response.data != null) {
        debugPrint('✅ [ExerciseRepository] Created custom exercise: ${response.data!['name']} (ID: ${response.data!['id']})');
        return response.data!;
      }

      debugPrint('⚠️ [ExerciseRepository] Exercise created but no data returned');
      return {};
    } catch (e, stackTrace) {
      debugPrint('❌ [ExerciseRepository] Error creating custom exercise: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Delete a custom exercise
  Future<void> deleteCustomExercise(String userId, String exerciseId) async {
    debugPrint('🏋️ [ExerciseRepository] Deleting custom exercise: $exerciseId for user: $userId');

    try {
      await _apiClient.delete(
        '${ApiConstants.baseUrl}/api/v1/exercises/custom/$userId/$exerciseId',
      );
      debugPrint('✅ [ExerciseRepository] Successfully deleted custom exercise: $exerciseId');
    } catch (e, stackTrace) {
      debugPrint('❌ [ExerciseRepository] Error deleting custom exercise: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
