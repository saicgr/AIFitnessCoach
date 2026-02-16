import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../repositories/workout_repository.dart';
import '../services/api_client.dart';
import '../services/health_import_service.dart';
import '../services/health_service.dart';

// ---------------------------------------------------------------------------
// HealthImportState
// ---------------------------------------------------------------------------

class HealthImportState {
  final bool isChecking;
  final List<PendingWorkoutImport> pendingImports;
  final bool isImporting;
  final String? error;

  const HealthImportState({
    this.isChecking = false,
    this.pendingImports = const [],
    this.isImporting = false,
    this.error,
  });

  HealthImportState copyWith({
    bool? isChecking,
    List<PendingWorkoutImport>? pendingImports,
    bool? isImporting,
    String? error,
  }) {
    return HealthImportState(
      isChecking: isChecking ?? this.isChecking,
      pendingImports: pendingImports ?? this.pendingImports,
      isImporting: isImporting ?? this.isImporting,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final healthImportProvider =
    StateNotifierProvider<HealthImportNotifier, HealthImportState>((ref) {
  return HealthImportNotifier(
    ref.watch(healthServiceProvider),
    ref.watch(healthSyncProvider),
    ref.watch(apiClientProvider),
    ref.watch(workoutRepositoryProvider),
  );
});

// ---------------------------------------------------------------------------
// HealthImportNotifier
// ---------------------------------------------------------------------------

class HealthImportNotifier extends StateNotifier<HealthImportState> {
  final HealthService _healthService;
  final HealthSyncState _syncState;
  final ApiClient _apiClient;
  // ignore: unused_field
  final WorkoutRepository _workoutRepository;

  final HealthImportService _importService = HealthImportService();

  HealthImportNotifier(
    this._healthService,
    this._syncState,
    this._apiClient,
    this._workoutRepository,
  ) : super(const HealthImportState());

  /// Check Health Connect for workout sessions that haven't been imported yet.
  Future<void> checkForUnimportedWorkouts() async {
    if (!_syncState.isConnected) return;

    state = state.copyWith(isChecking: true, error: null);

    try {
      final pending =
          await _importService.getUnimportedWorkouts(_healthService);
      state = state.copyWith(isChecking: false, pendingImports: pending);
      debugPrint(
          '🏋️ [HealthImport] ${pending.length} unimported workouts found');
    } catch (e) {
      debugPrint('❌ [HealthImport] Error checking for imports: $e');
      state = state.copyWith(
        isChecking: false,
        error: e.toString(),
      );
    }
  }

  /// Enrich a specific pending import with heart-rate data.
  Future<void> enrichCurrentWorkoutHR(int index) async {
    if (index < 0 || index >= state.pendingImports.length) return;

    try {
      final pending = state.pendingImports[index];
      final enriched =
          await _importService.enrichWithHeartRate(pending, _healthService);

      final updated = List<PendingWorkoutImport>.from(state.pendingImports);
      updated[index] = enriched;
      state = state.copyWith(pendingImports: updated);
    } catch (e) {
      debugPrint('⚠️ [HealthImport] Error enriching HR at index $index: $e');
    }
  }

  /// Import a pending workout as a new workout in FitWiz and mark it complete.
  Future<void> importAsNewWorkout(
    PendingWorkoutImport pending,
    String difficulty,
  ) async {
    state = state.copyWith(isImporting: true, error: null);

    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Build a user-friendly workout name from the activity type.
      final workoutName = _buildWorkoutName(pending.activityType);

      // Build generation metadata with available health data.
      final metadata = <String, dynamic>{};
      if (pending.avgHeartRate != null) {
        metadata['avg_heart_rate'] = pending.avgHeartRate;
      }
      if (pending.maxHeartRate != null) {
        metadata['max_heart_rate'] = pending.maxHeartRate;
      }
      if (pending.minHeartRate != null) {
        metadata['min_heart_rate'] = pending.minHeartRate;
      }
      if (pending.sourceName != null) {
        metadata['source_app'] = pending.sourceName;
      }
      if (pending.caloriesBurned != null) {
        metadata['calories_burned'] = pending.caloriesBurned;
      }
      if (pending.distanceMeters != null) {
        metadata['distance_meters'] = pending.distanceMeters;
      }

      // 1. Create the workout via API.
      final createResponse = await _apiClient.post(
        ApiConstants.workouts,
        data: {
          'user_id': userId,
          'name': workoutName,
          'type': pending.activityType,
          'difficulty': difficulty,
          'scheduled_date': pending.startTime.toIso8601String(),
          'exercises_json': '[]',
          'duration_minutes': pending.durationMinutes,
          'generation_method': 'health_connect_import',
          'generation_source': 'health_connect',
          'generation_metadata': jsonEncode(metadata),
        },
      );

      final workoutId = createResponse.data['id'] as String?;
      if (workoutId == null) {
        throw Exception('Failed to create workout: no ID returned');
      }

      debugPrint('✅ [HealthImport] Created workout $workoutId');

      // 2. Mark the workout as complete.
      await _apiClient.post(
        '${ApiConstants.workouts}/$workoutId/complete',
        queryParameters: {'completion_method': 'marked_done'},
      );

      debugPrint('✅ [HealthImport] Marked workout $workoutId as complete');

      // 3. Mark UUID as tracked so it won't appear again.
      await _importService.markImported(pending.uuid);

      // 4. Remove from pending list.
      final updated = List<PendingWorkoutImport>.from(state.pendingImports)
        ..removeWhere((p) => p.uuid == pending.uuid);
      state = state.copyWith(isImporting: false, pendingImports: updated);
    } catch (e) {
      debugPrint('❌ [HealthImport] Error importing workout: $e');
      state = state.copyWith(
        isImporting: false,
        error: e.toString(),
      );
    }
  }

  /// Mark an existing FitWiz workout as complete using Health Connect data.
  /// This avoids creating a duplicate - it completes the matched workout instead.
  Future<void> markExistingWorkoutComplete(
    PendingWorkoutImport pending,
    String existingWorkoutId,
  ) async {
    state = state.copyWith(isImporting: true, error: null);

    try {
      // Mark the existing workout as complete with duration from HC.
      await _apiClient.post(
        '${ApiConstants.workouts}/$existingWorkoutId/complete',
        data: {
          'duration_minutes': pending.durationMinutes,
        },
      );

      debugPrint(
          '✅ [HealthImport] Marked existing workout $existingWorkoutId as complete');

      // Mark UUID as tracked so it won't appear again.
      await _importService.markImported(pending.uuid);

      // Remove from pending list.
      final updated = List<PendingWorkoutImport>.from(state.pendingImports)
        ..removeWhere((p) => p.uuid == pending.uuid);
      state = state.copyWith(isImporting: false, pendingImports: updated);
    } catch (e) {
      debugPrint('❌ [HealthImport] Error marking existing workout complete: $e');
      state = state.copyWith(
        isImporting: false,
        error: e.toString(),
      );
    }
  }

  /// Skip a pending workout without importing it. It will not appear again.
  Future<void> skipWorkout(PendingWorkoutImport pending) async {
    await _importService.markImported(pending.uuid);

    final updated = List<PendingWorkoutImport>.from(state.pendingImports)
      ..removeWhere((p) => p.uuid == pending.uuid);
    state = state.copyWith(pendingImports: updated);
    debugPrint('⏭️ [HealthImport] Skipped workout ${pending.uuid}');
  }

  /// Auto-import all pending Health Connect workouts in the background.
  /// Returns the count of successfully imported workouts.
  Future<int> autoImportAll() async {
    if (state.pendingImports.isEmpty) return 0;

    state = state.copyWith(isImporting: true, error: null);
    int successCount = 0;

    // Copy list to iterate safely
    final toImport = List<PendingWorkoutImport>.from(state.pendingImports);

    for (final pending in toImport) {
      try {
        final userId = await _apiClient.getUserId();
        if (userId == null) break;

        final workoutName = _buildWorkoutName(pending.activityType);
        final metadata = <String, dynamic>{};
        if (pending.avgHeartRate != null) {
          metadata['avg_heart_rate'] = pending.avgHeartRate;
        }
        if (pending.maxHeartRate != null) {
          metadata['max_heart_rate'] = pending.maxHeartRate;
        }
        if (pending.caloriesBurned != null) {
          metadata['calories_burned'] = pending.caloriesBurned;
        }
        if (pending.distanceMeters != null) {
          metadata['distance_meters'] = pending.distanceMeters;
        }
        if (pending.sourceName != null) {
          metadata['source_app'] = pending.sourceName;
        }

        // Create workout
        final createResponse = await _apiClient.post(
          ApiConstants.workouts,
          data: {
            'user_id': userId,
            'name': workoutName,
            'type': pending.activityType,
            'difficulty': 'intermediate',
            'scheduled_date': pending.startTime.toIso8601String(),
            'exercises_json': '[]',
            'duration_minutes': pending.durationMinutes,
            'generation_method': 'health_connect_import',
            'generation_source': 'health_connect',
            'generation_metadata': jsonEncode(metadata),
          },
        );

        final workoutId = createResponse.data['id'] as String?;
        if (workoutId == null) continue;

        // Mark complete
        await _apiClient.post(
          '${ApiConstants.workouts}/$workoutId/complete',
          queryParameters: {'completion_method': 'marked_done'},
        );

        // Track UUID
        await _importService.markImported(pending.uuid);
        successCount++;
      } catch (e) {
        debugPrint(
            '⚠️ [HealthImport] Auto-import failed for ${pending.uuid}: $e');
        // Continue with next workout, don't stop on individual failures
      }
    }

    // Clear all pending imports
    state = state.copyWith(
      isImporting: false,
      pendingImports: [],
    );

    debugPrint(
        '✅ [HealthImport] Auto-imported $successCount/${toImport.length} workouts');
    return successCount;
  }

  /// Build a user-friendly workout name from activity type.
  String _buildWorkoutName(String activityType) {
    switch (activityType) {
      case 'strength':
        return 'Imported Strength Workout';
      case 'cardio':
        return 'Imported Cardio Workout';
      case 'flexibility':
        return 'Imported Flexibility Workout';
      case 'hiit':
        return 'Imported HIIT Workout';
      default:
        return 'Imported Workout';
    }
  }
}
