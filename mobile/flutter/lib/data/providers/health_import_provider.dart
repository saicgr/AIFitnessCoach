import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart' show HealthDataType, NumericHealthValue;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_constants.dart';
import '../../utils/tz.dart';
import '../repositories/workout_repository.dart';
import '../services/api_client.dart';
import '../services/background_sync_service.dart'
    show kAutoImportExternalWorkoutsKey;
import '../services/health_import_service.dart';
import '../services/health_service.dart';

// ---------------------------------------------------------------------------
// HeartRateSample + HeartRateBackfill (Surface 6c — Gravl "From Apple Health")
//
// When a workout finishes with NO live BLE/Watch HR samples (widget.heart-
// RateReadings empty), the completed-workout / summary screens fall back to
// pulling HR for the workout window straight from Apple Health (iOS) /
// Health Connect (Android). This mirrors Gravl's "From Apple Health" HR card.
//
// Permission-guarded: returns an EMPTY result when Health isn't connected,
// READ isn't granted, or the window has no samples — callers render nothing
// (no error UI) in that case.
// ---------------------------------------------------------------------------

/// One heart-rate sample pulled from the platform health store for a workout
/// window. Hand-written (no codegen) — intentionally tiny so it can cross the
/// provider→screen boundary without dragging in the full `health` package.
class HeartRateSample {
  final int bpm;
  final DateTime timestamp;

  const HeartRateSample({required this.bpm, required this.timestamp});
}

/// Aggregated HR backfill result: the ordered series plus avg/min/max.
/// `series` is empty when nothing was read (permission denied / no data) —
/// callers should treat `hasData == false` as "render nothing".
class HeartRateBackfillResult {
  final List<HeartRateSample> series;
  final int? avgBpm;
  final int? minBpm;
  final int? maxBpm;

  /// Platform-appropriate provenance label for the HR card
  /// ("From Apple Health" on iOS, "From Health Connect" on Android).
  final String sourceLabel;

  const HeartRateBackfillResult({
    required this.series,
    this.avgBpm,
    this.minBpm,
    this.maxBpm,
    required this.sourceLabel,
  });

  bool get hasData => series.isNotEmpty;

  /// Empty result for the "no data / not permitted" path.
  factory HeartRateBackfillResult.empty() => HeartRateBackfillResult(
        series: const [],
        sourceLabel: HeartRateBackfillResult.platformSourceLabel(),
      );

  static String platformSourceLabel() =>
      Platform.isIOS ? 'From Apple Health' : 'From Health Connect';
}

// ---------------------------------------------------------------------------
// WatchSessionHandoff (B12)
//
// When the user opens the app on their phone we proactively ask the paired
// Apple Watch to begin (or resume) a workout session so the watch starts
// recording HR/calories without the user fumbling for the watch app first.
//
// This is the Dart half of a phone→watch handoff. It calls a native iOS
// MethodChannel that must be wired in the iOS Runner via WatchConnectivity
// (WCSession) — see the INTEGRATION snippet in the agent report. The channel
// is a no-op on Android (no first-party watch session API parity) and degrades
// silently if the native side isn't present (MissingPluginException caught).
// ---------------------------------------------------------------------------

class WatchSessionHandoff {
  WatchSessionHandoff._();

  static const MethodChannel _channel =
      MethodChannel('com.zealova.app/watch_session');

  /// Ask the paired Apple Watch to auto-start a workout session. Best-effort:
  /// returns false on Android, when no watch is reachable, or when the native
  /// handler isn't installed yet. Never throws.
  static Future<bool> autoStartWatchSession({String? activityKind}) async {
    if (!Platform.isIOS) return false;
    try {
      final ok = await _channel.invokeMethod<bool>(
        'autoStartWatchSession',
        <String, dynamic>{
          if (activityKind != null) 'activityKind': activityKind,
        },
      );
      debugPrint('⌚ [WatchHandoff] autoStartWatchSession → $ok');
      return ok ?? false;
    } on MissingPluginException {
      // Native side not wired yet — expected until the iOS Runner snippet ships.
      debugPrint('⌚ [WatchHandoff] native channel not installed (no-op)');
      return false;
    } on PlatformException catch (e) {
      debugPrint('⌚ [WatchHandoff] native error: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('⌚ [WatchHandoff] unexpected error: $e');
      return false;
    }
  }
}

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

/// Read-only accessor for the list of external workouts discovered in Health
/// Connect / Apple Health that the user hasn't imported yet. Drives the
/// "N external workouts to import" entry point (workouts screen) and the
/// manual review/import sheet. Empty when nothing is pending — callers render
/// nothing (no fabricated data).
///
/// NOTE: this only reflects what the notifier has already discovered; it does
/// NOT trigger a Health Connect scan. Call
/// `ref.read(healthImportProvider.notifier).checkForUnimportedWorkouts()` on a
/// surface that wants fresh data (the workouts screen does this on resume).
final pendingExternalWorkoutsProvider =
    Provider<List<PendingWorkoutImport>>((ref) {
  return ref.watch(
    healthImportProvider.select((s) => s.pendingImports),
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

  /// Import a pending workout as a new workout in Zealova and mark it complete.
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
      if (pending.hrSamples.isEmpty) {
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
          // B13(a): file the import on the LOCAL calendar day the user actually
          // trained. The backend buckets scheduled_date by the leading
          // YYYY-MM-DD (str(scheduled_date)[:10] in today.py + workout_db.py),
          // so sending startTime.toUtc() shifted every evening workout west of
          // UTC forward a day. Tz.localDate() sends the user's real training
          // day as a date string Pydantic accepts.
          'scheduled_date': Tz.localDate(pending.startTime),
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

  /// Mark an existing Zealova workout as complete using Health Connect data.
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
        if (pending.hrSamples.isEmpty) {
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
            // B13(a): local calendar day the workout actually happened on —
            // backend buckets scheduled_date by YYYY-MM-DD (see importAsNewWorkout).
            'scheduled_date': Tz.localDate(enriched.startTime),
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

  /// Foreground external-workout sync (B12): discover + auto-import workouts
  /// recorded outside the app (Apple Watch / Apple Health / Health Connect),
  /// honoring the user's "auto-import external workouts" toggle. Dedupes by
  /// the platform UUID (shared tracker with the background isolate), so a
  /// workout imported here won't re-surface in the background task.
  ///
  /// Returns the count imported. No-op (returns 0) when the toggle is off,
  /// Health isn't connected, or there's nothing new. Use this on app
  /// foreground; the periodic background task covers the app-closed case.
  Future<int> syncExternalWorkouts() async {
    // Respect the user opt-out (default ON to match historical behavior).
    bool enabled = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      enabled = prefs.getBool(kAutoImportExternalWorkoutsKey) ?? true;
    } catch (_) {}
    if (!enabled) {
      debugPrint('ℹ️ [HealthImport] External auto-import disabled — skipping');
      return 0;
    }

    if (!_syncState.isConnected) return 0;

    await checkForUnimportedWorkouts();
    if (state.pendingImports.isEmpty) return 0;

    return autoImportAll();
  }

  /// Phone→watch handoff (B12): when the app is opened on the phone, ask the
  /// paired Apple Watch to auto-start a workout session. Best-effort, never
  /// throws. iOS-only; no-ops on Android and when the native channel is absent.
  Future<bool> maybeAutoStartWatchSession({String? activityKind}) {
    return WatchSessionHandoff.autoStartWatchSession(
      activityKind: activityKind,
    );
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

  /// Surface 6c — Apple Health / Health Connect HR backfill.
  ///
  /// Reads heart-rate samples for the `[start, end]` workout window straight
  /// from the platform health store, then computes avg/min/max + the ordered
  /// series. Used by the completed-workout / summary screens when the live
  /// BLE/Watch capture produced no samples, so the HR card still renders
  /// "From Apple Health" / "From Health Connect" data (Gravl Image #1 parity).
  ///
  /// Permission-guarded and never throws: returns
  /// [HeartRateBackfillResult.empty] (hasData == false) when Health isn't
  /// connected, READ isn't granted for HEART_RATE, or the window has no
  /// samples. Callers should render nothing in that case (no error UI).
  Future<HeartRateBackfillResult> readHeartRateForRange(
    DateTime start,
    DateTime end,
  ) async {
    // Guard 1: Health must be connected (mirrors every other read path here).
    if (!_syncState.isConnected) {
      if (kDebugMode) {
        debugPrint('❤️ [HR backfill] skipped — Health not connected');
      }
      return HeartRateBackfillResult.empty();
    }

    // Guard against an inverted / empty window.
    if (!end.isAfter(start)) {
      if (kDebugMode) {
        debugPrint('❤️ [HR backfill] skipped — non-positive window '
            '($start → $end)');
      }
      return HeartRateBackfillResult.empty();
    }

    try {
      // Guard 2: only attempt the read when HEART_RATE READ isn't explicitly
      // denied. On iOS this returns true (null→true) so the read proceeds;
      // on Android it skips the read when Play-policy hasn't granted the scope
      // (avoids the plugin's internal SecurityException log spam).
      final canRead =
          await _healthService.hasReadAccess([HealthDataType.HEART_RATE]);
      if (!canRead) {
        if (kDebugMode) {
          debugPrint('❤️ [HR backfill] skipped — HEART_RATE read not granted');
        }
        return HeartRateBackfillResult.empty();
      }

      final points = await _healthService.getHeartRateForTimeRange(start, end);
      if (points.isEmpty) {
        if (kDebugMode) {
          debugPrint('❤️ [HR backfill] no HR samples in window '
              '($start → $end)');
        }
        return HeartRateBackfillResult.empty();
      }

      final samples = <HeartRateSample>[];
      for (final p in points) {
        final value = p.value;
        if (value is! NumericHealthValue) continue;
        final bpm = value.numericValue.toInt();
        if (bpm <= 0) continue;
        samples.add(HeartRateSample(bpm: bpm, timestamp: p.dateFrom));
      }

      if (samples.isEmpty) {
        if (kDebugMode) {
          debugPrint('❤️ [HR backfill] all HR samples were non-numeric/zero');
        }
        return HeartRateBackfillResult.empty();
      }

      // Order chronologically so the chart plots left→right correctly.
      samples.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      final bpms = samples.map((s) => s.bpm).toList();
      final minBpm = bpms.reduce((a, b) => a < b ? a : b);
      final maxBpm = bpms.reduce((a, b) => a > b ? a : b);
      final avgBpm =
          (bpms.reduce((a, b) => a + b) / bpms.length).round();

      if (kDebugMode) {
        debugPrint('❤️ [HR backfill] ${samples.length} samples '
            '(avg $avgBpm, min $minBpm, max $maxBpm) for $start → $end');
      }

      return HeartRateBackfillResult(
        series: samples,
        avgBpm: avgBpm,
        minBpm: minBpm,
        maxBpm: maxBpm,
        sourceLabel: HeartRateBackfillResult.platformSourceLabel(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❤️ [HR backfill] error reading HR for range: $e');
      }
      return HeartRateBackfillResult.empty();
    }
  }
}
