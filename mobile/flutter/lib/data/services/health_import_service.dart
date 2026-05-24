import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_constants.dart';
import 'api_client.dart';
import 'health_service.dart';
import 'health_export_service.dart' show HealthExportService;

// ---------------------------------------------------------------------------
// PendingWorkoutImport - model for a workout discovered in Health Connect /
// Apple Health that has not yet been imported into Zealova. After enrichment
// it carries everything we were able to pull from the platform for the
// workout's time window (HR series, zones, splits, vitals, etc).
// ---------------------------------------------------------------------------

class PendingWorkoutImport {
  final String uuid;
  /// Legacy Zealova bucket: `cardio | strength | flexibility | hiit`.
  /// Kept for compatibility with achievements/home/schedule code that groups
  /// by `Workout.type`.
  final String activityType;

  /// Granular synced-workout kind (walking, running, cycling, yoga…).
  /// This is what the synced-workout UI renders — not the legacy bucket.
  final String activityKind;

  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;

  // --- Envelope / summary
  // basalCalories, flightsClimbed, elevationGainM removed 2026-05-07 —
  // Google Play Health Connect minimum-scope policy required dropping
  // BASAL_METABOLIC_RATE / FLOORS_CLIMBED / ELEVATION_GAINED permissions.
  final double? caloriesBurned;      // active kcal
  final double? totalCalories;       // active + basal kcal
  final double? distanceMeters;      // still populated from envelope (Strava/Apple Watch)
  final int? totalSteps;
  final String? sourceName;          // app name (e.g. "Zepp")
  final String? sourceDevice;        // device model (e.g. "Amazfit T-Rex 3")

  // --- Heart rate
  final int? avgHeartRate;
  final int? maxHeartRate;
  final int? minHeartRate;
  final List<Map<String, dynamic>> hrSamples; // [{'t': sec, 'bpm': int}]
  final Map<String, double> hrZonesPct;       // {'1': pct, …, '5': pct}
  final int? recoveryHrBpm;
  final int? recoveryDropBpm;

  // --- Pace / speed: removed 2026-05-07. Required DISTANCE / SPEED
  // permissions that no longer flow through Health Connect.

  // --- Cadence (from step deltas)
  final double? avgCadenceSpm;
  final double? maxCadenceSpm;
  final List<Map<String, dynamic>> cadenceSamples; // [{'t': sec, 'spm': double}]
  // avgStrideIn removed — depends on distance which is no longer enriched.

  // --- Vitals
  // avgSpo2, avgRespiratoryRate, peakBodyTemperatureC, avgHrvRmssd*
  // removed 2026-05-07 — Google Play Health Connect minimum-scope policy
  // required dropping OXYGEN_SATURATION / RESPIRATORY_RATE / BODY_TEMPERATURE
  // / HEART_RATE_VARIABILITY permissions.
  final int? restingHrSameDay;
  final double? bodyWeightKgNearest;

  // --- Splits + training load. splits removed (depend on distance).
  final double? trainingLoadTrimp;
  final int? effortScore; // 0-100

  const PendingWorkoutImport({
    required this.uuid,
    required this.activityType,
    required this.activityKind,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.caloriesBurned,
    this.totalCalories,
    this.distanceMeters,
    this.totalSteps,
    this.sourceName,
    this.sourceDevice,
    this.avgHeartRate,
    this.maxHeartRate,
    this.minHeartRate,
    this.hrSamples = const [],
    this.hrZonesPct = const {},
    this.recoveryHrBpm,
    this.recoveryDropBpm,
    this.avgCadenceSpm,
    this.maxCadenceSpm,
    this.cadenceSamples = const [],
    this.restingHrSameDay,
    this.bodyWeightKgNearest,
    this.trainingLoadTrimp,
    this.effortScore,
  });

  factory PendingWorkoutImport.fromHealthDataPoint(HealthDataPoint point) {
    final workout = point.value as WorkoutHealthValue;
    final duration = point.dateTo.difference(point.dateFrom).inMinutes;
    return PendingWorkoutImport(
      uuid: point.uuid,
      activityType: _mapActivityType(workout.workoutActivityType),
      activityKind: _mapActivityKind(workout.workoutActivityType),
      startTime: point.dateFrom,
      endTime: point.dateTo,
      durationMinutes: duration < 1 ? 1 : duration,
      caloriesBurned: workout.totalEnergyBurned?.toDouble(),
      distanceMeters: workout.totalDistance?.toDouble(),
      totalSteps: workout.totalSteps?.toInt(),
      sourceName: point.sourceName,
      sourceDevice: _inferDeviceModel(point),
    );
  }

  PendingWorkoutImport copyWith({
    String? activityType,
    String? activityKind,
    double? caloriesBurned,
    double? totalCalories,
    double? distanceMeters,
    int? totalSteps,
    String? sourceName,
    String? sourceDevice,
    int? avgHeartRate,
    int? maxHeartRate,
    int? minHeartRate,
    List<Map<String, dynamic>>? hrSamples,
    Map<String, double>? hrZonesPct,
    int? recoveryHrBpm,
    int? recoveryDropBpm,
    double? avgCadenceSpm,
    double? maxCadenceSpm,
    List<Map<String, dynamic>>? cadenceSamples,
    int? restingHrSameDay,
    double? bodyWeightKgNearest,
    double? trainingLoadTrimp,
    int? effortScore,
  }) {
    return PendingWorkoutImport(
      uuid: uuid,
      activityType: activityType ?? this.activityType,
      activityKind: activityKind ?? this.activityKind,
      startTime: startTime,
      endTime: endTime,
      durationMinutes: durationMinutes,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      totalCalories: totalCalories ?? this.totalCalories,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      totalSteps: totalSteps ?? this.totalSteps,
      sourceName: sourceName ?? this.sourceName,
      sourceDevice: sourceDevice ?? this.sourceDevice,
      avgHeartRate: avgHeartRate ?? this.avgHeartRate,
      maxHeartRate: maxHeartRate ?? this.maxHeartRate,
      minHeartRate: minHeartRate ?? this.minHeartRate,
      hrSamples: hrSamples ?? this.hrSamples,
      hrZonesPct: hrZonesPct ?? this.hrZonesPct,
      recoveryHrBpm: recoveryHrBpm ?? this.recoveryHrBpm,
      recoveryDropBpm: recoveryDropBpm ?? this.recoveryDropBpm,
      avgCadenceSpm: avgCadenceSpm ?? this.avgCadenceSpm,
      maxCadenceSpm: maxCadenceSpm ?? this.maxCadenceSpm,
      cadenceSamples: cadenceSamples ?? this.cadenceSamples,
      restingHrSameDay: restingHrSameDay ?? this.restingHrSameDay,
      bodyWeightKgNearest: bodyWeightKgNearest ?? this.bodyWeightKgNearest,
      trainingLoadTrimp: trainingLoadTrimp ?? this.trainingLoadTrimp,
      effortScore: effortScore ?? this.effortScore,
    );
  }

  /// Legacy user-override to switch the Zealova bucket (strength/cardio/…)
  /// from the import sheet. Keeps granular [activityKind] unchanged.
  PendingWorkoutImport copyWithActivityType(String newType) =>
      copyWith(activityType: newType);

  /// Serialize the enriched payload into the shape stored on
  /// `workouts.generation_metadata`.
  Map<String, dynamic> toMetadata() {
    final m = <String, dynamic>{
      'hc_activity_kind': activityKind,
      'start_time_iso': startTime.toUtc().toIso8601String(),
      'end_time_iso': endTime.toUtc().toIso8601String(),
    };
    if (sourceName != null) m['source_app'] = sourceName;
    if (sourceDevice != null) m['source_device'] = sourceDevice;
    if (caloriesBurned != null) m['calories_active'] = caloriesBurned;
    if (totalCalories != null) m['calories_total'] = totalCalories;
    if (distanceMeters != null) m['distance_m'] = distanceMeters;
    if (totalSteps != null) m['steps'] = totalSteps;
    if (avgHeartRate != null) m['avg_heart_rate'] = avgHeartRate;
    if (maxHeartRate != null) m['max_heart_rate'] = maxHeartRate;
    if (minHeartRate != null) m['min_heart_rate'] = minHeartRate;
    if (hrSamples.isNotEmpty) m['hr_samples'] = hrSamples;
    if (hrZonesPct.isNotEmpty) m['hr_zones_pct'] = hrZonesPct;
    if (recoveryHrBpm != null) m['recovery_hr_bpm'] = recoveryHrBpm;
    if (recoveryDropBpm != null) m['recovery_drop_bpm'] = recoveryDropBpm;
    if (avgCadenceSpm != null) m['avg_cadence_spm'] = avgCadenceSpm;
    if (maxCadenceSpm != null) m['max_cadence_spm'] = maxCadenceSpm;
    if (cadenceSamples.isNotEmpty) m['cadence_samples'] = cadenceSamples;
    if (restingHrSameDay != null) m['resting_hr_same_day'] = restingHrSameDay;
    if (bodyWeightKgNearest != null) {
      m['body_weight_kg_nearest'] = bodyWeightKgNearest;
    }
    if (trainingLoadTrimp != null) m['training_load_trimp'] = trainingLoadTrimp;
    if (effortScore != null) m['effort_score'] = effortScore;
    // basal_calories, flights_climbed, elevation_gain_m, avg_speed_mps,
    // max_speed_mps, pace_sec_per_km, pace_samples, avg_stride_in, avg_spo2,
    // avg_respiratory_rate, peak_body_temperature_c, avg_hrv_rmssd_pre/post,
    // splits — all dropped 2026-05-07 (Google Play Health Connect minimum
    // scope). The synced workout detail UI null-checks each metadata key,
    // so missing keys simply hide the corresponding tile.
    return m;
  }

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'activityType': activityType,
        'activityKind': activityKind,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'durationMinutes': durationMinutes,
        ...toMetadata(),
      };

  /// Legacy Zealova bucket mapper — unchanged in taxonomy. Do NOT widen
  /// beyond `strength | cardio | flexibility | hiit`; the achievements,
  /// home hero, and schedule-week code group on these four values.
  static String _mapActivityType(HealthWorkoutActivityType type) {
    switch (type) {
      case HealthWorkoutActivityType.WEIGHTLIFTING:
      case HealthWorkoutActivityType.STRENGTH_TRAINING:
      case HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING:
      case HealthWorkoutActivityType.FUNCTIONAL_STRENGTH_TRAINING:
      case HealthWorkoutActivityType.CORE_TRAINING:
      case HealthWorkoutActivityType.CALISTHENICS:
        return 'strength';
      case HealthWorkoutActivityType.YOGA:
      case HealthWorkoutActivityType.PILATES:
      case HealthWorkoutActivityType.FLEXIBILITY:
      case HealthWorkoutActivityType.MIND_AND_BODY:
      case HealthWorkoutActivityType.TAI_CHI:
      case HealthWorkoutActivityType.GUIDED_BREATHING:
        return 'flexibility';
      case HealthWorkoutActivityType.HIGH_INTENSITY_INTERVAL_TRAINING:
        return 'hiit';
      default:
        return 'cardio';
    }
  }

  /// Granular kind mapper — drives the synced-workout UI's per-kind color,
  /// icon, and default metric priority. Extend freely; unknown inputs fall
  /// through to `other` (slate palette, generic workout title).
  static String _mapActivityKind(HealthWorkoutActivityType type) {
    switch (type) {
      case HealthWorkoutActivityType.WALKING:
      case HealthWorkoutActivityType.WALKING_TREADMILL:
      case HealthWorkoutActivityType.WHEELCHAIR_WALK_PACE:
        return 'walking';
      case HealthWorkoutActivityType.RUNNING:
      case HealthWorkoutActivityType.RUNNING_TREADMILL:
      case HealthWorkoutActivityType.WHEELCHAIR_RUN_PACE:
        return 'running';
      case HealthWorkoutActivityType.BIKING:
      case HealthWorkoutActivityType.BIKING_STATIONARY:
      case HealthWorkoutActivityType.HAND_CYCLING:
        return 'cycling';
      case HealthWorkoutActivityType.SWIMMING:
      case HealthWorkoutActivityType.SWIMMING_OPEN_WATER:
      case HealthWorkoutActivityType.SWIMMING_POOL:
      case HealthWorkoutActivityType.WATER_FITNESS:
      case HealthWorkoutActivityType.WATER_POLO:
      case HealthWorkoutActivityType.WATER_SPORTS:
        return 'swimming';
      case HealthWorkoutActivityType.ROWING:
      case HealthWorkoutActivityType.ROWING_MACHINE:
        return 'rowing';
      case HealthWorkoutActivityType.HIKING:
      case HealthWorkoutActivityType.CLIMBING:
      case HealthWorkoutActivityType.ROCK_CLIMBING:
        return 'hiking';
      case HealthWorkoutActivityType.ELLIPTICAL:
        return 'elliptical';
      case HealthWorkoutActivityType.STAIRS:
      case HealthWorkoutActivityType.STAIR_CLIMBING:
      case HealthWorkoutActivityType.STAIR_CLIMBING_MACHINE:
      case HealthWorkoutActivityType.STEP_TRAINING:
        return 'stairs';
      case HealthWorkoutActivityType.SKATING:
      case HealthWorkoutActivityType.ICE_SKATING:
        return 'skating';
      case HealthWorkoutActivityType.DANCING:
      case HealthWorkoutActivityType.SOCIAL_DANCE:
      case HealthWorkoutActivityType.CARDIO_DANCE:
      case HealthWorkoutActivityType.BARRE:
        return 'dance';
      case HealthWorkoutActivityType.YOGA:
      case HealthWorkoutActivityType.MIND_AND_BODY:
      case HealthWorkoutActivityType.FLEXIBILITY:
      case HealthWorkoutActivityType.TAI_CHI:
      case HealthWorkoutActivityType.GUIDED_BREATHING:
        return 'yoga';
      case HealthWorkoutActivityType.PILATES:
        return 'pilates';
      case HealthWorkoutActivityType.HIGH_INTENSITY_INTERVAL_TRAINING:
        return 'hiit';
      case HealthWorkoutActivityType.TENNIS:
      case HealthWorkoutActivityType.TABLE_TENNIS:
      case HealthWorkoutActivityType.BADMINTON:
      case HealthWorkoutActivityType.PICKLEBALL:
      case HealthWorkoutActivityType.RACQUETBALL:
      case HealthWorkoutActivityType.SQUASH:
        return 'tennis';
      case HealthWorkoutActivityType.BASKETBALL:
        return 'basketball';
      case HealthWorkoutActivityType.AMERICAN_FOOTBALL:
      case HealthWorkoutActivityType.AUSTRALIAN_FOOTBALL:
      case HealthWorkoutActivityType.RUGBY:
        return 'football';
      case HealthWorkoutActivityType.SOCCER:
        return 'soccer';
      case HealthWorkoutActivityType.WEIGHTLIFTING:
      case HealthWorkoutActivityType.STRENGTH_TRAINING:
      case HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING:
      case HealthWorkoutActivityType.FUNCTIONAL_STRENGTH_TRAINING:
      case HealthWorkoutActivityType.CORE_TRAINING:
      case HealthWorkoutActivityType.CALISTHENICS:
        return 'strength';
      default:
        return 'other';
    }
  }

  /// Heuristic — the health plugin exposes `sourceName` (app) but not the
  /// actual hardware. Zepp + Amazfit users see strings like "Amazfit …" or
  /// "Mi Fitness" in `sourceId`/`deviceId` on some versions. Until the
  /// plugin exposes a stable device field we fall back to `sourceName`.
  static String? _inferDeviceModel(HealthDataPoint point) {
    // health 11.x exposes `sourcePlatform`, `sourceId`, `sourceName`. The
    // device model is not guaranteed. Best-effort only.
    return null;
  }
}

// ---------------------------------------------------------------------------
// ImportedWorkoutTracker - SharedPreferences-backed UUID dedup tracker.
// Stores {uuid: timestamp_ms} with a 30-day TTL.
// ---------------------------------------------------------------------------

class ImportedWorkoutTracker {
  static const _prefsKey = 'health_import_uuids';
  static const _ttlDays = 30;

  Map<String, int>? _cache;

  Future<Map<String, int>> _load() async {
    if (_cache != null) return _cache!;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      _cache = {};
      return _cache!;
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _cache = decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (e) {
      debugPrint('⚠️ [ImportTracker] Corrupt data, resetting: $e');
      _cache = {};
    }
    return _cache!;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_cache ?? {}));
  }

  Future<void> pruneOldEntries() async {
    final map = await _load();
    final cutoff = DateTime.now()
        .subtract(const Duration(days: _ttlDays))
        .millisecondsSinceEpoch;
    final before = map.length;
    map.removeWhere((_, ts) => ts < cutoff);
    if (map.length != before) {
      await _save();
      debugPrint(
          '🧹 [ImportTracker] Pruned ${before - map.length} old entries');
    }
  }

  Future<bool> isTracked(String uuid) async {
    await pruneOldEntries();
    final map = await _load();
    return map.containsKey(uuid);
  }

  Future<void> markTracked(String uuid) async {
    final map = await _load();
    map[uuid] = DateTime.now().millisecondsSinceEpoch;
    await _save();
  }

  /// Remove a UUID from the tracker so it surfaces again on the next sync.
  /// Used when the user deletes an imported workout — we want it to re-appear.
  Future<void> unmark(String uuid) async {
    final map = await _load();
    if (map.remove(uuid) != null) {
      await _save();
      debugPrint('↩️  [ImportTracker] Unmarked $uuid');
    }
  }
}

// ---------------------------------------------------------------------------
// HealthImportService - orchestrates discovery and enrichment of workouts
// from Health Connect / HealthKit that haven't been imported yet.
// ---------------------------------------------------------------------------

class HealthImportService {
  final ImportedWorkoutTracker _tracker = ImportedWorkoutTracker();

  /// Fetch workout sessions from Health Connect that have not been imported.
  Future<List<PendingWorkoutImport>> getUnimportedWorkouts(
    HealthService healthService, {
    int days = 7,
  }) async {
    try {
      final sessions = await healthService.getWorkoutSessions(days: days);
      final results = <PendingWorkoutImport>[];

      for (final point in sessions) {
        if (point.value is! WorkoutHealthValue) continue;
        final duration = point.dateTo.difference(point.dateFrom).inSeconds;
        if (duration < 60) continue; // skip sub-1m noise
        // SLICE_HEALTH_EXPORT loopback guard — workouts we previously
        // wrote back to Apple Health / Health Connect are stamped with
        // the Zealova source tag in the workout title. Skip those so
        // they don't re-enter the import pipeline (loop prevention).
        // Tag lookup is a cheap string match; see
        // `HealthExportService.isZealovaTaggedTitle`.
        final workoutValue = point.value as WorkoutHealthValue;
        final title = workoutValue.totalEnergyBurnedUnit.toString() == ''
            ? null
            : null; // health 12.x WorkoutHealthValue has no `name`/`title`
        // Some platforms expose the title via metadata; fall back to a
        // sourceName check (Zealova-written records also carry our app
        // source name).
        final src = point.sourceName ?? '';
        if (HealthExportService.isZealovaTaggedTitle(title ?? src) ||
            src.toLowerCase().contains('zealova')) {
          continue;
        }
        final import_ = PendingWorkoutImport.fromHealthDataPoint(point);
        final alreadyTracked = await _tracker.isTracked(import_.uuid);
        if (!alreadyTracked) {
          results.add(import_);
        }
      }

      debugPrint(
          '🏋️ [HealthImport] Found ${results.length} unimported workouts '
          'out of ${sessions.length} total');
      return results;
    } catch (e) {
      debugPrint('❌ [HealthImport] Error getting unimported workouts: $e');
      return [];
    }
  }

  /// Comprehensive enrichment: pull every Health Connect metric we can find
  /// inside the workout window (+ a small buffer for recovery HR + pre-window
  /// HRV/resting-HR). Computes zones, splits, pace/cadence series, TRIMP.
  ///
  /// [userAge] is used to compute the HR max (220 − age). When null, the
  /// observed max HR during the workout is used.
  Future<PendingWorkoutImport> enrichWithFullMetrics(
    PendingWorkoutImport pending,
    HealthService healthService, {
    int? userAge,
  }) async {
    final start = pending.startTime;
    final end = pending.endTime;
    final durationSec = end.difference(start).inSeconds;
    if (durationSec < 60) return pending;

    // Window data: everything during [start, end + 2min recovery buffer].
    final windowEnd = end.add(const Duration(minutes: 2));
    // Distance / FlightsClimbed / BasalEnergy / BloodOxygen / BodyTemperature
    // / RespiratoryRate / HRV (RMSSD + SDNN) were removed 2026-05-07 to
    // comply with Google Play's Health Connect minimum-scope policy. Workout
    // enrichment now only pulls heart rate, steps, and active/total energy.
    final windowPoints = await healthService.getDataInRange(
      start: start,
      end: windowEnd,
      types: const [
        HealthDataType.HEART_RATE,
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.TOTAL_CALORIES_BURNED,
      ],
    );

    // Pre-window data: resting HR captured in the 4h before workout.
    final preStart = start.subtract(const Duration(hours: 4));
    final prePoints = await healthService.getDataInRange(
      start: preStart,
      end: start,
      types: const [
        HealthDataType.RESTING_HEART_RATE,
      ],
    );

    // Nearest-body-weight lookup (within 14 days).
    final weightPoints = await healthService.getDataInRange(
      start: start.subtract(const Duration(days: 14)),
      end: end,
      types: const [HealthDataType.WEIGHT],
    );

    // Partition windowPoints by type. Distance / FlightsClimbed / Basal /
    // SpO2 / BodyTemperature / RespiratoryRate were removed from the
    // request set on 2026-05-07 (Google Play minimum scope), so the
    // matching buckets are gone.
    final hrRaw = <HealthDataPoint>[];
    final stepsRaw = <HealthDataPoint>[];
    final activeEnergy = <HealthDataPoint>[];
    final totalEnergy = <HealthDataPoint>[];

    for (final p in windowPoints) {
      switch (p.type) {
        case HealthDataType.HEART_RATE:
          hrRaw.add(p);
          break;
        case HealthDataType.STEPS:
          stepsRaw.add(p);
          break;
        case HealthDataType.ACTIVE_ENERGY_BURNED:
          activeEnergy.add(p);
          break;
        case HealthDataType.TOTAL_CALORIES_BURNED:
          totalEnergy.add(p);
          break;
        default:
          break;
      }
    }

    // --- Heart rate (in-window only, no recovery tail yet)
    final hrInWindow =
        hrRaw.where((p) => !p.dateTo.isAfter(end)).toList();
    final hrValues = hrInWindow
        .map((p) => (p.value as NumericHealthValue).numericValue.toInt())
        .toList();
    int? avgHr, maxHr, minHr;
    if (hrValues.isNotEmpty) {
      avgHr = hrValues.reduce((a, b) => a + b) ~/ hrValues.length;
      maxHr = hrValues.reduce((a, b) => a > b ? a : b);
      minHr = hrValues.reduce((a, b) => a < b ? a : b);
    }

    // HR time series downsampled to ≤120 pts. Require 3+ min for series.
    final hrSeries = <({double t, int bpm})>[];
    if (durationSec >= 180 && hrInWindow.length >= 4) {
      final bucketSec = math.max(10.0, durationSec / 120);
      final bucketSums = <int, int>{};
      final bucketCounts = <int, int>{};
      for (final p in hrInWindow) {
        final t = p.dateTo.difference(start).inSeconds.toDouble();
        if (t < 0) continue;
        final b = (t / bucketSec).floor();
        final v = (p.value as NumericHealthValue).numericValue.toInt();
        bucketSums[b] = (bucketSums[b] ?? 0) + v;
        bucketCounts[b] = (bucketCounts[b] ?? 0) + 1;
      }
      final bucketKeys = bucketSums.keys.toList()..sort();
      for (final k in bucketKeys) {
        hrSeries.add((
          t: k * bucketSec,
          bpm: (bucketSums[k]! / bucketCounts[k]!).round(),
        ));
      }
    }

    // HR zones — from series (or raw if no series)
    Map<String, double> zonesPct = {};
    int? zonesMaxBase = userAge != null ? 220 - userAge : null;
    zonesMaxBase ??= maxHr;
    if (zonesMaxBase != null &&
        zonesMaxBase > 0 &&
        hrInWindow.isNotEmpty) {
      int z1 = 0, z2 = 0, z3 = 0, z4 = 0, z5 = 0;
      for (final v in hrValues) {
        final pct = v / zonesMaxBase;
        if (pct < 0.60) {
          z1++;
        } else if (pct < 0.70) {
          z2++;
        } else if (pct < 0.80) {
          z3++;
        } else if (pct < 0.90) {
          z4++;
        } else {
          z5++;
        }
      }
      final total = z1 + z2 + z3 + z4 + z5;
      if (total > 0) {
        zonesPct = {
          '1': (z1 / total * 100).roundToDouble(),
          '2': (z2 / total * 100).roundToDouble(),
          '3': (z3 / total * 100).roundToDouble(),
          '4': (z4 / total * 100).roundToDouble(),
          '5': (z5 / total * 100).roundToDouble(),
        };
      }
    }

    // Recovery HR — average of HR samples in the 2min AFTER endTime
    final hrRecovery = hrRaw
        .where((p) => p.dateTo.isAfter(end))
        .map((p) => (p.value as NumericHealthValue).numericValue.toInt())
        .toList();
    int? recoveryHr, recoveryDrop;
    if (hrRecovery.isNotEmpty && maxHr != null) {
      recoveryHr =
          hrRecovery.reduce((a, b) => a + b) ~/ hrRecovery.length;
      recoveryDrop = maxHr - recoveryHr;
    }

    // --- Energy. Basal removed 2026-05-07 — minimum scope.
    double? activeKcal = _sum(activeEnergy);
    if (activeKcal == null && pending.caloriesBurned != null) {
      activeKcal = pending.caloriesBurned;
    }
    final totalKcal = _sum(totalEnergy);

    // Distance is no longer pulled from Health Connect / HealthKit. If the
    // pending envelope (e.g. Apple Watch workout summary) already carried a
    // distance, keep it; otherwise null. Distance-derived series (pace,
    // speed, splits, stride) are no longer computed.
    final totalDistance = pending.distanceMeters;

    // --- Steps (prefer envelope if present)
    int? totalSteps = pending.totalSteps;
    if (totalSteps == null) {
      final sum = _sum(stepsRaw);
      if (sum != null) totalSteps = sum.round();
    }

    // FlightsClimbed, ElevationGained, pace/speed series removed 2026-05-07
    // (minimum scope) — locals deleted along with the matching copyWith
    // arguments below.

    // --- Cadence series (bucketed 30s step-deltas → spm)
    final cadenceSeries = <Map<String, dynamic>>[];
    double? avgCadenceSpm, maxCadenceSpm;
    if (stepsRaw.isNotEmpty) {
      final bucketSec = math.max(30.0, durationSec / 60);
      final bucketSteps = <int, double>{};
      for (final p in stepsRaw) {
        final t = p.dateTo.difference(start).inSeconds.toDouble();
        if (t < 0 || t > durationSec) continue;
        final b = (t / bucketSec).floor();
        final v = (p.value as NumericHealthValue).numericValue.toDouble();
        bucketSteps[b] = (bucketSteps[b] ?? 0) + v;
      }
      final keys = bucketSteps.keys.toList()..sort();
      final cads = <double>[];
      for (final k in keys) {
        final spm = (bucketSteps[k]! / bucketSec) * 60;
        cadenceSeries.add({'t': k * bucketSec, 'spm': spm});
        cads.add(spm);
      }
      if (cads.isNotEmpty) {
        avgCadenceSpm = cads.reduce((a, b) => a + b) / cads.length;
        maxCadenceSpm = cads.reduce((a, b) => a > b ? a : b);
      }
    }

    // Stride length, SpO2, respiratory rate, body temperature, and HRV
    // were all removed 2026-05-07 (Google Play Health Connect minimum
    // scope) — the matching PendingWorkoutImport fields and copyWith
    // arguments are gone.

    // Resting HR same-day
    final rhrPoints = prePoints
        .where((p) => p.type == HealthDataType.RESTING_HEART_RATE)
        .toList();
    int? restingHr;
    if (rhrPoints.isNotEmpty) {
      restingHr = ((rhrPoints.last.value as NumericHealthValue)
              .numericValue
              .toDouble())
          .round();
    }

    // Body weight nearest
    double? bodyKg;
    if (weightPoints.isNotEmpty) {
      bodyKg = (weightPoints.last.value as NumericHealthValue)
          .numericValue
          .toDouble();
    }

    // Distance-based splits removed (no distance series source).

    // --- TRIMP (Banister, Edwards-simplified)
    double? trimp;
    if (avgHr != null && restingHr != null && zonesMaxBase != null) {
      final hrReserveRatio =
          ((avgHr - restingHr) / (zonesMaxBase - restingHr)).clamp(0.0, 1.0);
      final sexFactor = 0.64; // men; sex unknown at this layer
      trimp = (durationSec / 60) *
          hrReserveRatio *
          sexFactor *
          math.exp(1.92 * hrReserveRatio);
    }
    int? effortScore;
    if (trimp != null) {
      // Map roughly: 0..15 easy, 15..50 moderate, 50..120 hard, 120+ savage
      effortScore = (trimp / 150 * 100).clamp(0.0, 100.0).round();
    }

    return pending.copyWith(
      caloriesBurned: activeKcal,
      totalCalories: totalKcal,
      distanceMeters: totalDistance,
      totalSteps: totalSteps,
      avgHeartRate: avgHr,
      maxHeartRate: maxHr,
      minHeartRate: minHr,
      hrSamples: hrSeries
          .map((s) => <String, dynamic>{'t': s.t.round(), 'bpm': s.bpm})
          .toList(),
      hrZonesPct: zonesPct,
      recoveryHrBpm: recoveryHr,
      recoveryDropBpm: recoveryDrop,
      avgCadenceSpm: avgCadenceSpm,
      maxCadenceSpm: maxCadenceSpm,
      cadenceSamples: cadenceSeries,
      restingHrSameDay: restingHr,
      bodyWeightKgNearest: bodyKg,
      trainingLoadTrimp: trimp,
      effortScore: effortScore,
    );
  }

  /// Back-compat alias — the old `enrichWithHeartRate` shape returned an
  /// object with only HR fields populated. Callers that don't yet pass
  /// user age can still use this.
  Future<PendingWorkoutImport> enrichWithHeartRate(
    PendingWorkoutImport pending,
    HealthService healthService,
  ) =>
      enrichWithFullMetrics(pending, healthService);

  Future<void> markImported(String uuid) => _tracker.markTracked(uuid);

  /// Remove a UUID from the dedup tracker. Call when the user deletes an
  /// imported workout so it can be re-surfaced on the next Health Connect sync.
  Future<void> unmark(String uuid) => _tracker.unmark(uuid);

  // ----- helpers -----

  static double? _sum(List<HealthDataPoint> points) {
    if (points.isEmpty) return null;
    double s = 0;
    for (final p in points) {
      s += (p.value as NumericHealthValue).numericValue.toDouble();
    }
    return s;
  }

  // _average / _peak / _buildSplits removed 2026-05-07 along with the
  // distance / vitals enrichment they fed (Google Play minimum scope).

  // -------------------------------------------------------------------------
  // iOS GPS re-add (SLICE_GPS, 2026-05-24)
  //
  // iOS-only: re-adds HKWorkoutRoute polyline capture + HKQuantityTypeIdentifier
  // VO2Max import. Both are deliberately gated behind `Platform.isIOS` —
  // Google Play scope declaration for ACTIVITY_RECOGNITION + foreground GPS
  // is still pending, so on Android we hard no-op rather than ship a broken
  // permission prompt.
  //
  // Version gate (health package 12.2.1):
  //   The `health` plugin enum does NOT expose `WORKOUT_ROUTE` or `VO2MAX`
  //   members. Verified via:
  //     grep -E "WORKOUT_ROUTE|VO2MAX" \
  //       ~/.pub-cache/hosted/pub.dev/health-12.2.1/lib/src/heath_data_types.dart
  //     → no matches
  //   So we cannot ask the plugin to pull these series directly. The
  //   helpers below scaffold the upload + DB write paths so that when:
  //     (a) we bump health to a version that exposes the enum, OR
  //     (b) we add a native HKHealthStore channel for routes,
  //   the rest of the slice (UI widget, S3 endpoint, cardio_metrics
  //   schema) is already wired and only the fetch needs swapping in.
  //   Until then `_fetchRoutePolylineIos` returns [] and `importVo2MaxFromIos`
  //   returns 0 — callers degrade gracefully (RouteMap renders the indoor
  //   empty state; VO2max trend remains backed by the existing in-app
  //   estimator).
  // -------------------------------------------------------------------------

  /// Fetch the recorded GPS polyline for an Apple Health workout and POST it
  /// to the backend so it can be persisted to S3 + linked on cardio_logs.
  ///
  /// Returns the S3 key on success, or null on Android / unsupported plugin
  /// version / empty route / network failure. Never throws — failure is a
  /// degraded view, not a blocking error.
  ///
  /// [cardioLogId] is the already-created `cardio_logs.id` row that this
  /// route belongs to. The polyline endpoint links the upload to that row.
  Future<String?> fetchAndUploadRouteIfIos({
    required ApiClient apiClient,
    required String cardioLogId,
    required PendingWorkoutImport workout,
  }) async {
    if (!Platform.isIOS) {
      // Android intentionally skipped — see header comment.
      return null;
    }

    final polyline = await _fetchRoutePolylineIos(workout);
    if (polyline.length < 2) {
      // No route or single point — nothing to upload.
      return null;
    }

    try {
      final response = await apiClient.post<Map<String, dynamic>>(
        '${ApiConstants.apiBaseUrl}/cardio-logs/$cardioLogId/route',
        data: <String, dynamic>{
          'polyline': polyline
              .map((p) => <double>[p.$1, p.$2])
              .toList(growable: false),
          'source': 'apple_health',
        },
      );
      final key = response.data?['route_polyline_s3_key'] as String?;
      debugPrint(
          '🗺️  [HealthImport] route uploaded for log=$cardioLogId key=$key '
          'points=${polyline.length}');
      return key;
    } catch (e) {
      debugPrint('❌ [HealthImport] route upload failed for $cardioLogId: $e');
      return null;
    }
  }

  /// iOS-only: fetch the HKWorkoutRoute polyline for the workout window.
  ///
  /// Returns a list of (lat, lng) records. Empty list = no route recorded
  /// (indoor activity) OR plugin version doesn't expose WORKOUT_ROUTE yet
  /// (current state — see version-gate comment above).
  Future<List<(double, double)>> _fetchRoutePolylineIos(
    PendingWorkoutImport workout,
  ) async {
    // health 12.2.1 does NOT expose HealthDataType.WORKOUT_ROUTE. When we
    // bump the plugin (or add a native channel), swap the body for a real
    // HKWorkoutRoute → CLLocation series fetch over [workout.startTime,
    // workout.endTime]. Until then return empty so RouteMap shows the
    // indoor empty state instead of a broken render.
    return const [];
  }

  /// iOS-only: import VO2max samples from Apple Health into the existing
  /// `cardio_metrics` table (NOT a new table — migration 082 schema).
  ///
  /// Posts each sample with `source = 'health_kit'` (the value enforced by
  /// the `cardio_metrics_source_check` CHECK constraint — `'apple_health'`
  /// is NOT in the allowed set) and `measured_at = sample.startTime`.
  ///
  /// Returns the number of samples imported, or 0 on Android / unsupported
  /// plugin version / no new samples. Never throws.
  Future<int> importVo2MaxFromIos({
    required ApiClient apiClient,
    int days = 30,
  }) async {
    if (!Platform.isIOS) return 0;

    final samples = await _fetchVo2MaxSamplesIos(days: days);
    if (samples.isEmpty) return 0;

    int written = 0;
    for (final sample in samples) {
      try {
        await apiClient.post<Map<String, dynamic>>(
          '${ApiConstants.apiBaseUrl}/cardio/metrics',
          data: <String, dynamic>{
            'vo2_max_estimate': sample.vo2Max,
            'measured_at': sample.measuredAt.toUtc().toIso8601String(),
            // 'health_kit' is the value the cardio_metrics CHECK constraint
            // allows for HealthKit-sourced rows. Migration 082, line 23.
            'source': 'health_kit',
          },
        );
        written++;
      } catch (e) {
        debugPrint('⚠️  [HealthImport] vo2max sample failed: $e');
      }
    }
    debugPrint(
        '🫁 [HealthImport] imported $written / ${samples.length} VO2max samples');
    return written;
  }

  /// iOS-only: fetch VO2max samples from Apple Health.
  ///
  /// Returns the per-sample (value, timestamp) pairs. Empty when no samples
  /// exist OR when the plugin version doesn't expose VO2MAX yet (current
  /// state — see version-gate comment above).
  Future<List<_Vo2MaxSample>> _fetchVo2MaxSamplesIos({int days = 30}) async {
    // health 12.2.1 does NOT expose HealthDataType.VO2MAX. When we bump
    // the plugin (or add a native channel via HKQuantityTypeIdentifier
    // .vo2Max), swap the body for a real fetch. Until then return empty
    // so the VO2max trend chart stays backed by the in-app estimator.
    return const [];
  }
}

/// Lightweight record-style holder for a single VO2max sample read off
/// Apple Health. Kept private to this file — callers only see the
/// aggregated "samples written" count returned by [importVo2MaxFromIos].
class _Vo2MaxSample {
  final double vo2Max;
  final DateTime measuredAt;
  const _Vo2MaxSample(this.vo2Max, this.measuredAt);
}
