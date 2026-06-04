import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise_history.dart';
import '../services/api_client.dart';

/// Exercise History Repository Provider
final exerciseHistoryRepositoryProvider = Provider<ExerciseHistoryRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ExerciseHistoryRepository(apiClient);
});

/// One gym's contribution to an exercise's pooled history, surfaced by the
/// backend so the client can render the per-gym filter chips + multi-series
/// "All gyms" chart without a second round-trip.
///
/// Sourced from the `gym_breakdown` array on the `/exercise-history/*`
/// responses (built in parallel — see the backend read-path contract).
class GymBreakdownEntry {
  /// The gym profile id this slice belongs to. `null` == the legacy/
  /// "Unassigned" bucket (sets logged before per-gym attribution existed).
  final String? gymProfileId;
  final String gymName;

  /// Hex color string (e.g. `#00BCD4`) the gym owns. May be null for the
  /// unassigned bucket; callers fall back to the theme accent then.
  final String? gymColor;
  final int sessionCount;

  const GymBreakdownEntry({
    required this.gymProfileId,
    required this.gymName,
    required this.gymColor,
    required this.sessionCount,
  });

  factory GymBreakdownEntry.fromJson(Map<String, dynamic> json) {
    return GymBreakdownEntry(
      gymProfileId: json['gym_profile_id']?.toString(),
      gymName: json['gym_name']?.toString() ?? 'Gym',
      gymColor: json['gym_color']?.toString(),
      sessionCount: (json['session_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// One session enriched with the gym it was performed at. We can't add gym
/// fields to the shared [ExerciseWorkoutSession] (its model file is owned by
/// another concern), so the per-gym multi-series chart reads this side-list
/// where `session[i]` aligns with `data.sessions[i]`.
class GymTaggedSession {
  final ExerciseWorkoutSession session;
  final String? gymProfileId;
  final String? gymName;

  /// Hex color string for the owning gym, when the backend supplied it.
  final String? gymColor;

  const GymTaggedSession({
    required this.session,
    this.gymProfileId,
    this.gymName,
    this.gymColor,
  });
}

/// Wraps [ExerciseHistoryData] with the per-gym resolution metadata the
/// backend now returns. Kept as a local wrapper (rather than extending the
/// shared `exercise_history.dart` model, which another concern owns) so the
/// gym-filter UI can read `resolvedScope` / `gymBreakdown` without touching
/// the model file.
class ExerciseHistoryResult {
  final ExerciseHistoryData data;

  /// `'per_gym'` or `'combined'` — how the backend resolved the request.
  /// Drives the gym filter's default selection (per_gym → active gym,
  /// combined → "All gyms").
  final String? resolvedScope;

  /// The gym profile id the backend actually filtered by (may differ from
  /// the requested one when it resolved an equipment-aware default), or null
  /// for a combined view.
  final String? gymProfileId;

  /// Per-gym session breakdown for the chips + multi-series chart.
  final List<GymBreakdownEntry> gymBreakdown;

  /// Per-session gym attribution (parallel to `data.sessions`), used to split
  /// the "All gyms" chart into one colored series per gym.
  final List<GymTaggedSession> taggedSessions;

  const ExerciseHistoryResult({
    required this.data,
    this.resolvedScope,
    this.gymProfileId,
    this.gymBreakdown = const [],
    this.taggedSessions = const [],
  });

  bool get isPerGym => resolvedScope == 'per_gym';
}

/// Repository for fetching per-exercise workout history
class ExerciseHistoryRepository {
  final ApiClient _apiClient;

  ExerciseHistoryRepository(this._apiClient);

  /// Get paginated workout history for a specific exercise.
  ///
  /// [gymProfileId] / [scope] are OPTIONAL: when omitted the backend resolves
  /// an equipment-aware default (machine/cable → this gym only, free weights →
  /// combined). When set, history is filtered to that gym (`scope == 'current'`)
  /// or pooled across gyms (`scope == 'all'`).
  ///
  /// Returns only the [ExerciseHistoryData] body for backwards compatibility;
  /// callers that need the per-gym resolution metadata should use
  /// [getExerciseHistoryResult].
  Future<ExerciseHistoryData> getExerciseHistory({
    required String exerciseName,
    String timeRange = '12_weeks',
    int page = 1,
    int limit = 20,
    String? gymProfileId,
    String? scope,
  }) async {
    final result = await getExerciseHistoryResult(
      exerciseName: exerciseName,
      timeRange: timeRange,
      page: page,
      limit: limit,
      gymProfileId: gymProfileId,
      scope: scope,
    );
    return result.data;
  }

  /// Like [getExerciseHistory] but returns the full [ExerciseHistoryResult]
  /// including `resolved_scope` + `gym_breakdown` so the gym filter can render
  /// its default selection and (in "All gyms" mode) a per-gym colored chart.
  Future<ExerciseHistoryResult> getExerciseHistoryResult({
    required String exerciseName,
    String timeRange = '12_weeks',
    int page = 1,
    int limit = 20,
    String? gymProfileId,
    String? scope,
  }) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🔍 [ExerciseHistory] Fetching history for: $exerciseName'
          '${gymProfileId != null ? ' (gym=$gymProfileId)' : ''}'
          '${scope != null ? ' scope=$scope' : ''}');

      final encodedName = Uri.encodeComponent(exerciseName);
      final response = await _apiClient.get(
        '/exercise-history/$encodedName',
        queryParameters: {
          'user_id': userId,
          'time_range': timeRange,
          'page': page,
          'limit': limit,
          if (gymProfileId != null) 'gym_profile_id': gymProfileId,
          if (scope != null) 'scope': scope,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        // Map API response to our model. `gym_profile_id` / `gym_name` /
        // `gym_color` may ride along on each record (multi-series chart) and
        // are captured in a parallel side-list (see [GymTaggedSession]).
        final taggedSessions = (data['records'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map((r) {
          final session = ExerciseWorkoutSession(
            workoutId: r['id']?.toString() ?? '',
            workoutDate: r['workout_date'] ?? '',
            workoutName: r['workout_name'],
            sets: r['sets_completed'] ?? 0,
            reps: r['total_reps'] ?? 0,
            weightKg: (r['max_weight_kg'] as num?)?.toDouble() ?? 0,
            totalVolumeKg: (r['total_volume_kg'] as num?)?.toDouble() ?? 0,
            estimated1rmKg: (r['estimated_1rm_kg'] as num?)?.toDouble(),
            isPr: r['is_pr'] == true,
            notes: r['notes'],
          );
          return GymTaggedSession(
            session: session,
            gymProfileId: r['gym_profile_id']?.toString(),
            gymName: r['gym_name']?.toString(),
            gymColor: r['gym_color']?.toString(),
          );
        }).toList();
        final sessions = taggedSessions.map((t) => t.session).toList();

        final summary = data['summary'] as Map<String, dynamic>?;

        final breakdown = (data['gym_breakdown'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(GymBreakdownEntry.fromJson)
            .toList();

        debugPrint('✅ [ExerciseHistory] Fetched ${sessions.length} sessions'
            '${breakdown.isNotEmpty ? ' across ${breakdown.length} gym(s)' : ''}');

        final historyData = ExerciseHistoryData(
          userId: userId,
          exerciseName: exerciseName,
          timeRange: timeRange,
          totalSessions: data['total_records'] ?? sessions.length,
          sessions: sessions,
          summary: summary != null ? ExerciseProgressionSummary(
            totalSessions: summary['times_performed'] ?? 0,
            totalVolumeKg: (summary['total_volume_kg'] as num?)?.toDouble(),
            avgVolumePerSessionKg: (summary['avg_weight_kg'] as num?)?.toDouble(),
            firstSessionDate: summary['first_performed_at'],
            lastSessionDate: summary['last_performed_at'],
            currentWeightKg: (summary['max_weight_kg'] as num?)?.toDouble(),
            current1rmKg: (summary['estimated_1rm_kg'] as num?)?.toDouble(),
          ) : null,
        );

        return ExerciseHistoryResult(
          data: historyData,
          resolvedScope: data['resolved_scope']?.toString(),
          gymProfileId: data['gym_profile_id']?.toString(),
          gymBreakdown: breakdown,
          taggedSessions: taggedSessions,
        );
      }

      throw Exception('Failed to fetch exercise history');
    } catch (e) {
      debugPrint('❌ [ExerciseHistory] Error: $e');
      rethrow;
    }
  }

  /// Get chart data for exercise progression visualization.
  ///
  /// [gymProfileId] / [scope] are OPTIONAL and forwarded to the backend so the
  /// chart can be scoped to a single gym or pooled across all gyms.
  Future<List<ExerciseChartDataPoint>> getExerciseChartData({
    required String exerciseName,
    String timeRange = '12_weeks',
    String? gymProfileId,
    String? scope,
  }) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🔍 [ExerciseHistory] Fetching chart data for: $exerciseName');

      final encodedName = Uri.encodeComponent(exerciseName);
      final response = await _apiClient.get(
        '/exercise-history/$encodedName/chart',
        queryParameters: {
          'user_id': userId,
          'time_range': timeRange,
          if (gymProfileId != null) 'gym_profile_id': gymProfileId,
          if (scope != null) 'scope': scope,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final points = (data['data_points'] as List? ?? []).map((p) {
          return ExerciseChartDataPoint(
            date: p['date'] ?? '',
            value: (p['max_weight_kg'] as num?)?.toDouble() ?? 0,
            label: '${(p['max_weight_kg'] as num?)?.toStringAsFixed(1) ?? 0} kg',
            isPr: p['is_pr'] == true,
          );
        }).toList();

        debugPrint('✅ [ExerciseHistory] Fetched ${points.length} chart data points');
        return points;
      }

      throw Exception('Failed to fetch chart data');
    } catch (e) {
      debugPrint('❌ [ExerciseHistory] Chart data error: $e');
      rethrow;
    }
  }

  /// Get personal records for a specific exercise.
  ///
  /// [gymProfileId] / [scope] are OPTIONAL: when set, PRs are scoped to that
  /// gym (machine/cable PRs no longer get crushed by an incomparable record
  /// set at a different gym).
  Future<List<ExercisePersonalRecord>> getExercisePRs({
    required String exerciseName,
    String? gymProfileId,
    String? scope,
  }) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🔍 [ExerciseHistory] Fetching PRs for: $exerciseName');

      final encodedName = Uri.encodeComponent(exerciseName);
      final response = await _apiClient.get(
        '/exercise-history/$encodedName/prs',
        queryParameters: {
          'user_id': userId,
          if (gymProfileId != null) 'gym_profile_id': gymProfileId,
          if (scope != null) 'scope': scope,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final records = (data['records'] as List? ?? []).map((r) {
          return ExercisePersonalRecord(
            id: r['type'] ?? '',
            exerciseName: exerciseName,
            prType: r['type'] ?? '',
            prValue: (r['value'] as num?)?.toDouble() ?? 0,
            achievedDate: r['achieved_at'] ?? '',
            reps: r['reps'],
            weightKg: (r['weight_kg'] as num?)?.toDouble(),
          );
        }).toList();

        debugPrint('✅ [ExerciseHistory] Fetched ${records.length} PRs');
        return records;
      }

      throw Exception('Failed to fetch PRs');
    } catch (e) {
      debugPrint('❌ [ExerciseHistory] PRs error: $e');
      rethrow;
    }
  }

  /// Get most performed exercises
  Future<List<MostPerformedExercise>> getMostPerformedExercises({
    int limit = 20,
  }) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🔍 [ExerciseHistory] Fetching most performed exercises');

      final response = await _apiClient.get(
        '/exercise-history/most-performed',
        queryParameters: {
          'user_id': userId,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final exercises = (data['exercises'] as List? ?? []).map((e) {
          return MostPerformedExercise(
            exerciseName: e['exercise_name'] ?? '',
            muscleGroup: e['muscle_group'],
            timesPerformed: e['times_performed'] ?? 0,
            totalVolumeKg: (e['total_volume_kg'] as num?)?.toDouble(),
            maxWeightKg: (e['max_weight_kg'] as num?)?.toDouble(),
            lastPerformed: e['last_performed_at'],
          );
        }).toList();

        debugPrint('✅ [ExerciseHistory] Fetched ${exercises.length} exercises');
        return exercises;
      }

      throw Exception('Failed to fetch most performed exercises');
    } catch (e) {
      debugPrint('❌ [ExerciseHistory] Most performed error: $e');
      rethrow;
    }
  }

  /// Log exercise history view for analytics
  Future<void> logView({
    required String exerciseName,
    int? sessionDurationSeconds,
  }) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) return;

      await _apiClient.post(
        '/exercise-history/log-view',
        data: {
          'user_id': userId,
          'exercise_name': exerciseName,
          'session_duration_seconds': sessionDurationSeconds,
        },
      );

      debugPrint('✅ [ExerciseHistory] Logged view for: $exerciseName');
    } catch (e) {
      debugPrint('⚠️ [ExerciseHistory] Failed to log view: $e');
    }
  }

  /// Lightweight per-exercise progression history used by the live in-workout
  /// PR-detection cache. Returns the most-recent sessions as raw maps.
  ///
  /// [gymProfileId] is OPTIONAL — when supplied (machine/cable exercises) the
  /// history is scoped to that gym so a same-gym PR isn't crushed by an
  /// incomparable record at another gym; when omitted (free weights / no
  /// active gym) the history is pooled across gyms exactly as before. This
  /// param MUST stay optional: `pr_detection_service.dart` (owned by another
  /// concern) calls this with and without it.
  Future<List<Map<String, dynamic>>> getExerciseProgress({
    required String userId,
    required String exerciseName,
    int limit = 10,
    String? gymProfileId,
  }) async {
    try {
      debugPrint('🔍 [ExerciseHistory] Fetching progress for: $exerciseName'
          '${gymProfileId != null ? ' (gym=$gymProfileId)' : ''}');

      final result = await getExerciseHistoryResult(
        exerciseName: exerciseName,
        timeRange: 'all_time',
        limit: limit,
        gymProfileId: gymProfileId,
        scope: gymProfileId != null ? 'current' : null,
      );

      // Shape each session into the lightweight map the PR cache expects.
      return result.data.sessions
          .take(limit)
          .map((s) => <String, dynamic>{
                'workout_date': s.workoutDate,
                'weight_kg': s.weightKg,
                'reps': s.reps,
                'sets': s.sets,
                'total_volume_kg': s.totalVolumeKg,
                'estimated_1rm_kg': s.estimated1rmKg,
              })
          .toList();
    } catch (e) {
      debugPrint('❌ [ExerciseHistory] Error fetching progress: $e');
      return [];
    }
  }
}
