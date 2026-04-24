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

  /// Enrich a specific pending import with the full set of Health Connect /
  /// HealthKit metrics captured during the workout window — HR series +
  /// zones, pace/speed/cadence samples, vitals, splits, TRIMP/effort.
  Future<void> enrichCurrentWorkoutHR(int index) async {
    if (index < 0 || index >= state.pendingImports.length) return;

    try {
      final pending = state.pendingImports[index];
      final enriched = await _importService.enrichWithFullMetrics(
          pending, _healthService);

      final updated = List<PendingWorkoutImport>.from(state.pendingImports);
      updated[index] = enriched;
      state = state.copyWith(pendingImports: updated);
    } catch (e) {
      debugPrint('⚠️ [HealthImport] Error enriching at index $index: $e');
    }
  }

  /// Import a pending workout as a new workout in FitWiz and mark it complete.
  /// [customName] overrides the auto-generated name if provided.
  Future<void> importAsNewWorkout(
    PendingWorkoutImport pending,
    String difficulty, {
    String? customName,
  }) async {
    state = state.copyWith(isImporting: true, error: null);

    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Enrich if we haven't already (covers auto-import flows that skipped
      // the explicit enrichCurrentWorkoutHR call).
      var enriched = pending;
      if (pending.hrSamples.isEmpty && pending.paceSamples.isEmpty) {
        try {
          enriched = await _importService.enrichWithFullMetrics(
              pending, _healthService);
        } catch (e) {
          debugPrint('⚠️ [HealthImport] Enrichment failed, importing raw: $e');
        }
      }

      // Kind-based name ("Walking", "Cycling"); preserve caller override.
      final workoutName = (customName != null && customName.trim().isNotEmpty)
          ? customName.trim()
          : _buildWorkoutName(enriched.activityKind);

      // Exhaustive metadata (HR series, zones, pace, cadence, splits,
      // vitals, training load) — serialized by PendingWorkoutImport.
      final metadata = enriched.toMetadata();
      // Back-compat keys read by pre-rewrite UI.
      if (enriched.caloriesBurned != null) {
        metadata['calories_burned'] = enriched.caloriesBurned;
      }
      if (enriched.distanceMeters != null) {
        metadata['distance_meters'] = enriched.distanceMeters;
      }
      if (enriched.totalSteps != null) {
        metadata['total_steps'] = enriched.totalSteps;
      }

      // 1. Create the workout via API.
      final createResponse = await _apiClient.post(
        '${ApiConstants.workouts}/',
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

  /// Remove a UUID from the dedup tracker so the workout re-appears on
  /// the next Health Connect sync. Called when the user deletes a synced
  /// workout from the detail screen.
  Future<void> unmarkImported(String uuid) async {
    await _importService.unmark(uuid);
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

        // Enrich if needed (HR series, zones, pace, cadence, splits, vitals).
        var enriched = pending;
        if (pending.hrSamples.isEmpty && pending.paceSamples.isEmpty) {
          try {
            enriched = await _importService.enrichWithFullMetrics(
                pending, _healthService);
          } catch (e) {
            debugPrint('⚠️ [HealthImport] Enrichment failed mid-batch: $e');
          }
        }

        final workoutName = _buildWorkoutName(enriched.activityKind);
        final metadata = enriched.toMetadata();
        if (enriched.caloriesBurned != null) {
          metadata['calories_burned'] = enriched.caloriesBurned;
        }
        if (enriched.distanceMeters != null) {
          metadata['distance_meters'] = enriched.distanceMeters;
        }
        if (enriched.totalSteps != null) {
          metadata['total_steps'] = enriched.totalSteps;
        }

        // Create workout
        final createResponse = await _apiClient.post(
          '${ApiConstants.workouts}/',
          data: {
            'user_id': userId,
            'name': workoutName,
            'type': enriched.activityType,
            'difficulty': 'intermediate',
            'scheduled_date': enriched.startTime.toIso8601String(),
            'exercises_json': '[]',
            'duration_minutes': enriched.durationMinutes,
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

  /// Build a user-friendly workout name from the granular kind.
  ///
  /// Uses the kind (e.g. `walking`) rather than the legacy bucket
  /// (`cardio`) so cards read "Walking" / "Running" / "Cycling", not
  /// the generic "Imported Cardio Workout".
  String _buildWorkoutName(String kind) {
    switch (kind) {
      case 'walking':
        return 'Walking';
      case 'running':
        return 'Running';
      case 'cycling':
        return 'Cycling';
      case 'swimming':
        return 'Swimming';
      case 'rowing':
        return 'Rowing';
      case 'hiking':
        return 'Hiking';
      case 'elliptical':
        return 'Elliptical';
      case 'stairs':
        return 'Stair Climb';
      case 'skating':
        return 'Skating';
      case 'dance':
        return 'Dance';
      case 'yoga':
        return 'Yoga';
      case 'pilates':
        return 'Pilates';
      case 'hiit':
        return 'HIIT';
      case 'tennis':
        return 'Tennis';
      case 'basketball':
        return 'Basketball';
      case 'football':
        return 'Football';
      case 'soccer':
        return 'Soccer';
      case 'strength':
        return 'Strength Session';
      default:
        return 'Workout';
    }
  }

  /// Re-enrich an already-imported workout (by id) from Health Connect —
  /// fetches metrics for the stored window and merges into the workout's
  /// `generation_metadata`. No-op if the workout is not a Health Connect
  /// import or the window is outside the platform's retention.
  Future<bool> reEnrichImportedWorkout(
    String workoutId,
    DateTime startTime,
    DateTime endTime, {
    String? sourceName,
    String? activityKind,
  }) async {
    try {
      // Reconstruct a PendingWorkoutImport stub — we only need the window +
      // kind to run enrichment; uuid is irrelevant at this path.
      final stub = PendingWorkoutImport(
        uuid: 'reenrich-$workoutId',
        activityType: 'cardio',
        activityKind: activityKind ?? 'other',
        startTime: startTime,
        endTime: endTime,
        durationMinutes: endTime.difference(startTime).inMinutes,
        sourceName: sourceName,
      );
      final enriched = await _importService.enrichWithFullMetrics(
          stub, _healthService);
      final merged = enriched.toMetadata();
      if (enriched.caloriesBurned != null) {
        merged['calories_burned'] = enriched.caloriesBurned;
      }
      if (enriched.distanceMeters != null) {
        merged['distance_meters'] = enriched.distanceMeters;
      }
      if (enriched.totalSteps != null) {
        merged['total_steps'] = enriched.totalSteps;
      }

      // Fetch the current metadata via GET so we can merge, then PATCH.
      final current = await _apiClient.get(
        '${ApiConstants.workouts}/$workoutId',
      );
      final raw = current.data['generation_metadata'];
      Map<String, dynamic> existing = {};
      if (raw is String && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) existing = decoded;
        } catch (_) {}
      } else if (raw is Map<String, dynamic>) {
        existing = raw;
      }
      final finalMetadata = {...existing, ...merged};

      await _apiClient.put(
        '${ApiConstants.workouts}/$workoutId',
        data: {'generation_metadata': jsonEncode(finalMetadata)},
      );
      debugPrint('✅ [HealthImport] Re-enriched workout $workoutId');
      return true;
    } catch (e) {
      debugPrint('❌ [HealthImport] Re-enrich failed for $workoutId: $e');
      return false;
    }
  }
}
