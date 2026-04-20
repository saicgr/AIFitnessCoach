/// Exercise History Batch Service
///
/// Fetches per-set workout history for multiple exercises in one call.
/// Feeds the [PreSetInsightEngine] on the active-workout screen.
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/services/pre_set_insight_engine.dart';
import 'api_client.dart';

class ExerciseHistoryBatchService {
  final ApiClient _apiClient;

  ExerciseHistoryBatchService(this._apiClient);

  /// Returns a map of exercise_name → newest-first list of [SessionSummary].
  /// Throws on network / auth errors — callers should catch and surface
  /// the error (no silent degraded banner).
  Future<Map<String, List<SessionSummary>>> fetchBatch({
    required String userId,
    required List<String> exerciseNames,
    int limitPerExercise = 6,
    int daysBack = 84,
  }) async {
    if (exerciseNames.isEmpty) return {};

    try {
      final response = await _apiClient.dio.post(
        '/exercise-history/batch',
        data: {
          'user_id': userId,
          'exercise_names': exerciseNames,
          'limit_per_exercise': limitPerExercise,
          'days_back': daysBack,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );

      if (response.statusCode != 200 || response.data == null) {
        throw StateError(
          'Batch history returned ${response.statusCode}',
        );
      }

      final raw = response.data['histories'] as Map<String, dynamic>? ?? {};
      final out = <String, List<SessionSummary>>{};

      for (final entry in raw.entries) {
        final exerciseName = entry.key;
        final sessions = (entry.value as List<dynamic>? ?? []).map((s) {
          final map = s as Map<String, dynamic>;
          final setsRaw = (map['working_sets'] as List<dynamic>? ?? []);
          final sets = setsRaw.map((x) {
            final m = x as Map<String, dynamic>;
            return SetSummary(
              weightKg: (m['weight_kg'] as num?)?.toDouble() ?? 0.0,
              reps: (m['reps'] as num?)?.toInt() ?? 0,
              rpe: (m['rpe'] as num?)?.toInt(),
              rir: (m['rir'] as num?)?.toInt(),
            );
          }).toList();
          return SessionSummary(
            dateIso: (map['date'] as String?) ?? '',
            workingSets: sets,
          );
        }).toList();
        out[exerciseName] = sessions;
      }

      return out;
    } catch (e, stack) {
      debugPrint('❌ [ExerciseHistoryBatch] $e');
      debugPrint('   $stack');
      rethrow;
    }
  }
}
