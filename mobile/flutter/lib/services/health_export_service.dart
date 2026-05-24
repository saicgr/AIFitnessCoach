import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/cardio_log.dart';
import '../data/models/workout.dart';
import '../data/repositories/cardio_log_repository.dart';
import '../data/repositories/workout_repository.dart';

/// SLICE_HEALTH_EXPORT — Apple Health / Health Connect write-back.
///
/// Pushes manual cardio + strength workouts the user logs in Zealova back to
/// HKWorkout (iOS) / Health Connect (Android) so other apps (Strava, MyFitnessPal,
/// Apple Fitness, etc.) can see them.
///
/// **Dedup-loop note (read me before editing):** Apple Health does not expose
/// a writable arbitrary-metadata field via the `health: ^12.2.1` package
/// (HKWorkoutMetadataKey* setters are not bound). To prevent the
/// import service from re-importing workouts that originated in Zealova,
/// we stamp a recognizable suffix into the workout's `title`:
///
///   `<original title> [Zealova:<external_id>]`
///
/// **The import service (`health_import_service.dart`, owned by SLICE_GPS)
/// must skip any HealthWorkout whose title contains the `[Zealova:` marker.**
/// Coordinate with SLICE_GPS or the composer to add that skip filter — if it's
/// missing the user will see duplicates: Zealova log + re-imported HK copy.
/// See `kZealovaSourceTag` / [isZealovaTaggedTitle] / [buildTaggedTitle] below
/// for the exact format the importer should match.
class HealthExportService {
  /// SharedPreferences key for the user-facing toggle.
  static const String kEnabledPrefKey = 'health_writeback_enabled';

  /// SharedPreferences key for the last successful write timestamp (epoch ms).
  static const String kLastSyncPrefKey = 'health_writeback_last_sync_ms';

  /// Marker prefix the import service must look for in HKWorkout titles to
  /// recognize records that originated in Zealova. Used to break the
  /// export → import → re-export loop.
  static const String kZealovaSourceTag = '[Zealova:';

  final Health _health;
  final CardioLogRepository _cardioRepo;
  final WorkoutRepository _workoutRepo;

  HealthExportService({
    Health? health,
    required CardioLogRepository cardioRepo,
    required WorkoutRepository workoutRepo,
  })  : _health = health ?? Health(),
        _cardioRepo = cardioRepo,
        _workoutRepo = workoutRepo;

  bool _configured = false;

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  // ───────────────────────── Toggle persistence ─────────────────────────

  /// Returns the user's current opt-in state. Defaults to **false** — write-back
  /// is OFF by default per privacy-first principle (user must explicitly grant).
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kEnabledPrefKey) ?? false;
  }

  /// Persists the toggle. Does NOT request permissions — caller (the settings
  /// tile widget) requests permissions BEFORE flipping the toggle to true.
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kEnabledPrefKey, enabled);
    debugPrint('🏥 [HealthExport] toggle set to $enabled');
  }

  /// Last successful write timestamp (null = never synced).
  Future<DateTime?> getLastSyncAt() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(kLastSyncPrefKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> _stampLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(kLastSyncPrefKey, DateTime.now().millisecondsSinceEpoch);
  }

  // ───────────────────────── Permissions ─────────────────────────

  /// Requests WRITE authorization for WORKOUT + ACTIVE_ENERGY_BURNED + DISTANCE.
  /// Returns true on grant.
  Future<bool> requestWritePermissions() async {
    try {
      await _ensureConfigured();
      final types = <HealthDataType>[
        HealthDataType.WORKOUT,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.DISTANCE_DELTA,
      ];
      final perms = types.map((_) => HealthDataAccess.WRITE).toList();
      final granted = await _health.requestAuthorization(types, permissions: perms);
      debugPrint('🏥 [HealthExport] write perms granted=$granted');
      return granted;
    } catch (e, st) {
      debugPrint('❌ [HealthExport] requestWritePermissions error: $e\n$st');
      return false;
    }
  }

  // ───────────────────────── Tag helpers ─────────────────────────

  /// Builds a title that embeds our source tag + external_id so the import
  /// service can recognize-and-skip Zealova-originated records.
  ///
  /// Examples:
  ///   buildTaggedTitle('Push Day A', 'wkt_abc123')
  ///     → 'Push Day A [Zealova:wkt_abc123]'
  ///   buildTaggedTitle(null, 'card_xyz')
  ///     → '[Zealova:card_xyz]'
  static String buildTaggedTitle(String? baseTitle, String externalId) {
    final tag = '$kZealovaSourceTag$externalId]';
    final base = (baseTitle == null || baseTitle.trim().isEmpty)
        ? ''
        : '${baseTitle.trim()} ';
    return '$base$tag';
  }

  /// True if [title] was produced by [buildTaggedTitle]. Importers should call
  /// this on every HealthWorkout title and skip when true.
  static bool isZealovaTaggedTitle(String? title) {
    if (title == null) return false;
    return title.contains(kZealovaSourceTag);
  }

  // ───────────────────────── Core write ─────────────────────────

  /// Generic write entry-point. Short-circuits (returns false) if the toggle
  /// is OFF or we are on an unsupported platform.
  Future<bool> writeWorkout({
    required String workoutType,
    required DateTime start,
    required DateTime end,
    double? distanceM,
    double? caloriesKcal,
    String? externalId,
    String? title,
  }) async {
    // Edge: respect user toggle. No silent override.
    if (!await isEnabled()) {
      debugPrint('🏥 [HealthExport] skipped — toggle OFF');
      return false;
    }

    // Edge: only iOS + Android supported (HKWorkout / Health Connect).
    if (!Platform.isIOS && !Platform.isAndroid) {
      debugPrint('🏥 [HealthExport] skipped — unsupported platform');
      return false;
    }

    // Edge: zero/negative-duration sessions are invalid and HK rejects them.
    if (!end.isAfter(start)) {
      debugPrint('⚠️ [HealthExport] skipped — end<=start ($start → $end)');
      return false;
    }

    try {
      await _ensureConfigured();
      final activity = _mapActivityType(workoutType);
      final taggedTitle = (externalId != null && externalId.isNotEmpty)
          ? buildTaggedTitle(title, externalId)
          : title;

      final ok = await _health.writeWorkoutData(
        activityType: activity,
        start: start,
        end: end,
        totalEnergyBurned: caloriesKcal?.round(),
        totalDistance: distanceM?.round(),
        title: taggedTitle,
        // iOS requires manual or automatic; user-logged data is manual.
        recordingMethod: RecordingMethod.manual,
      );

      // Best-effort: write a separate ACTIVE_ENERGY sample so daily totals
      // pick it up. Failure here must NOT fail the workout write.
      if (ok && caloriesKcal != null && caloriesKcal > 0) {
        try {
          await _health.writeHealthData(
            value: caloriesKcal,
            type: HealthDataType.ACTIVE_ENERGY_BURNED,
            startTime: start,
            endTime: end,
            recordingMethod: RecordingMethod.manual,
          );
        } catch (e) {
          debugPrint('⚠️ [HealthExport] non-fatal: active-energy write failed: $e');
        }
      }

      if (ok) {
        await _stampLastSync();
        debugPrint('✅ [HealthExport] wrote $activity (${start.toIso8601String()})');
      } else {
        debugPrint('❌ [HealthExport] writeWorkoutData returned false');
      }
      return ok;
    } catch (e, st) {
      debugPrint('❌ [HealthExport] writeWorkout error: $e\n$st');
      return false;
    }
  }

  // ───────────────────── Convenience wrappers ─────────────────────

  /// Look up a cardio log by id and write it. Returns false if not found.
  ///
  /// Note: `CardioLogRepository` has no `getById` — we list recent entries for
  /// the user and find by id. Caller should pass [userId] for efficiency; if
  /// omitted we ask the workout repo for the current user.
  Future<bool> writeCardioLog(String cardioLogId, {String? userId}) async {
    if (!await isEnabled()) return false;
    try {
      final uid = userId ?? await _workoutRepo.getCurrentUserId();
      if (uid == null) {
        debugPrint('⚠️ [HealthExport] writeCardioLog: no userId');
        return false;
      }
      // Pull a reasonable window — manual log was just inserted, will be at head.
      final logs = await _cardioRepo.getUserCardioLogs(userId: uid, limit: 100);
      final match = logs.cast<CardioLog?>().firstWhere(
            (l) => l?.id == cardioLogId,
            orElse: () => null,
          );
      if (match == null) {
        debugPrint('⚠️ [HealthExport] cardio log $cardioLogId not found');
        return false;
      }
      final start = DateTime.parse(match.performedAt);
      final end = start.add(Duration(seconds: match.durationSeconds));
      return writeWorkout(
        workoutType: match.activityType,
        start: start,
        end: end,
        distanceM: match.distanceM,
        caloriesKcal: match.calories?.toDouble(),
        externalId: match.id,
        title: _prettyActivityTitle(match.activityType),
      );
    } catch (e, st) {
      debugPrint('❌ [HealthExport] writeCardioLog error: $e\n$st');
      return false;
    }
  }

  /// Look up a strength workout by id and write it.
  Future<bool> writeStrengthWorkout(String workoutId) async {
    if (!await isEnabled()) return false;
    try {
      final Workout? w = await _workoutRepo.getWorkout(workoutId);
      if (w == null) {
        debugPrint('⚠️ [HealthExport] workout $workoutId not found');
        return false;
      }

      // Edge: pick the most reliable timestamps available.
      // completedAt is set when the user finishes. scheduledDate is fallback.
      final endStr = w.completedAt ?? w.updatedAt ?? w.scheduledDate;
      if (endStr == null) {
        debugPrint('⚠️ [HealthExport] no timestamp on workout $workoutId');
        return false;
      }
      final end = DateTime.parse(endStr).toLocal();
      final durMin = w.durationMinutes ??
          w.estimatedDurationMinutes ??
          w.durationMinutesMax ??
          30; // safe default if nothing recorded
      final start = end.subtract(Duration(minutes: durMin));

      return writeWorkout(
        workoutType: w.type ?? 'strength',
        start: start,
        end: end,
        caloriesKcal: w.estimatedCaloriesStored?.toDouble(),
        externalId: w.id,
        title: w.name,
      );
    } catch (e, st) {
      debugPrint('❌ [HealthExport] writeStrengthWorkout error: $e\n$st');
      return false;
    }
  }

  // ───────────────────── Helpers ─────────────────────

  /// Map a Zealova activity string to the closest HK/HealthConnect type.
  /// Keep this list intentionally small — the existing
  /// `HealthService._mapWorkoutType` is the source-of-truth richer mapping;
  /// we mirror its most common cases here to keep the slice self-contained.
  static HealthWorkoutActivityType _mapActivityType(String t) {
    switch (t.toLowerCase().trim()) {
      case 'strength':
      case 'weights':
      case 'resistance':
        return Platform.isIOS
            ? HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING
            : HealthWorkoutActivityType.STRENGTH_TRAINING;
      case 'hiit':
        return HealthWorkoutActivityType.HIGH_INTENSITY_INTERVAL_TRAINING;
      case 'cardio':
      case 'run':
      case 'running':
        return HealthWorkoutActivityType.RUNNING;
      case 'walk':
      case 'walking':
        return HealthWorkoutActivityType.WALKING;
      case 'bike':
      case 'biking':
      case 'cycling':
        return HealthWorkoutActivityType.BIKING;
      case 'swim':
      case 'swimming':
        return HealthWorkoutActivityType.SWIMMING;
      case 'yoga':
        return HealthWorkoutActivityType.YOGA;
      case 'pilates':
        return HealthWorkoutActivityType.PILATES;
      case 'stretching':
      case 'flexibility':
      case 'mobility':
        return Platform.isIOS
            ? HealthWorkoutActivityType.FLEXIBILITY
            : HealthWorkoutActivityType.YOGA;
      case 'calisthenics':
      case 'bodyweight':
        return Platform.isIOS
            ? HealthWorkoutActivityType.FUNCTIONAL_STRENGTH_TRAINING
            : HealthWorkoutActivityType.CALISTHENICS;
      default:
        return HealthWorkoutActivityType.OTHER;
    }
  }

  static String _prettyActivityTitle(String activityType) {
    if (activityType.isEmpty) return 'Workout';
    return activityType[0].toUpperCase() + activityType.substring(1).toLowerCase();
  }
}
