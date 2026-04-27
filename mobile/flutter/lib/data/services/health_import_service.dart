import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'health_service.dart';

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
  final double? caloriesBurned;      // active kcal
  final double? totalCalories;       // active + basal kcal
  final double? basalCalories;
  final double? distanceMeters;
  final int? totalSteps;
  final int? flightsClimbed;
  final double? elevationGainM;
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

  // --- Pace / speed (from distance deltas)
  final double? avgSpeedMps;
  final double? maxSpeedMps;
  final double? paceSecPerKm;
  final List<Map<String, dynamic>> paceSamples; // [{'t': sec, 'mps': double}]

  // --- Cadence (from step deltas)
  final double? avgCadenceSpm;
  final double? maxCadenceSpm;
  final List<Map<String, dynamic>> cadenceSamples; // [{'t': sec, 'spm': double}]
  final double? avgStrideIn;

  // --- Vitals
  final double? avgSpo2;
  final double? avgRespiratoryRate;
  final double? peakBodyTemperatureC;
  final double? avgHrvRmssdPre;
  final double? avgHrvRmssdPost;
  final int? restingHrSameDay;
  final double? bodyWeightKgNearest;

  // --- Splits + training load
  final List<Map<String, dynamic>> splits;
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
    this.basalCalories,
    this.distanceMeters,
    this.totalSteps,
    this.flightsClimbed,
    this.elevationGainM,
    this.sourceName,
    this.sourceDevice,
    this.avgHeartRate,
    this.maxHeartRate,
    this.minHeartRate,
    this.hrSamples = const [],
    this.hrZonesPct = const {},
    this.recoveryHrBpm,
    this.recoveryDropBpm,
    this.avgSpeedMps,
    this.maxSpeedMps,
    this.paceSecPerKm,
    this.paceSamples = const [],
    this.avgCadenceSpm,
    this.maxCadenceSpm,
    this.cadenceSamples = const [],
    this.avgStrideIn,
    this.avgSpo2,
    this.avgRespiratoryRate,
    this.peakBodyTemperatureC,
    this.avgHrvRmssdPre,
    this.avgHrvRmssdPost,
    this.restingHrSameDay,
    this.bodyWeightKgNearest,
    this.splits = const [],
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
    double? basalCalories,
    double? distanceMeters,
    int? totalSteps,
    int? flightsClimbed,
    double? elevationGainM,
    String? sourceName,
    String? sourceDevice,
    int? avgHeartRate,
    int? maxHeartRate,
    int? minHeartRate,
    List<Map<String, dynamic>>? hrSamples,
    Map<String, double>? hrZonesPct,
    int? recoveryHrBpm,
    int? recoveryDropBpm,
    double? avgSpeedMps,
    double? maxSpeedMps,
    double? paceSecPerKm,
    List<Map<String, dynamic>>? paceSamples,
    double? avgCadenceSpm,
    double? maxCadenceSpm,
    List<Map<String, dynamic>>? cadenceSamples,
    double? avgStrideIn,
    double? avgSpo2,
    double? avgRespiratoryRate,
    double? peakBodyTemperatureC,
    double? avgHrvRmssdPre,
    double? avgHrvRmssdPost,
    int? restingHrSameDay,
    double? bodyWeightKgNearest,
    List<Map<String, dynamic>>? splits,
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
      basalCalories: basalCalories ?? this.basalCalories,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      totalSteps: totalSteps ?? this.totalSteps,
      flightsClimbed: flightsClimbed ?? this.flightsClimbed,
      elevationGainM: elevationGainM ?? this.elevationGainM,
      sourceName: sourceName ?? this.sourceName,
      sourceDevice: sourceDevice ?? this.sourceDevice,
      avgHeartRate: avgHeartRate ?? this.avgHeartRate,
      maxHeartRate: maxHeartRate ?? this.maxHeartRate,
      minHeartRate: minHeartRate ?? this.minHeartRate,
      hrSamples: hrSamples ?? this.hrSamples,
      hrZonesPct: hrZonesPct ?? this.hrZonesPct,
      recoveryHrBpm: recoveryHrBpm ?? this.recoveryHrBpm,
      recoveryDropBpm: recoveryDropBpm ?? this.recoveryDropBpm,
      avgSpeedMps: avgSpeedMps ?? this.avgSpeedMps,
      maxSpeedMps: maxSpeedMps ?? this.maxSpeedMps,
      paceSecPerKm: paceSecPerKm ?? this.paceSecPerKm,
      paceSamples: paceSamples ?? this.paceSamples,
      avgCadenceSpm: avgCadenceSpm ?? this.avgCadenceSpm,
      maxCadenceSpm: maxCadenceSpm ?? this.maxCadenceSpm,
      cadenceSamples: cadenceSamples ?? this.cadenceSamples,
      avgStrideIn: avgStrideIn ?? this.avgStrideIn,
      avgSpo2: avgSpo2 ?? this.avgSpo2,
      avgRespiratoryRate: avgRespiratoryRate ?? this.avgRespiratoryRate,
      peakBodyTemperatureC:
          peakBodyTemperatureC ?? this.peakBodyTemperatureC,
      avgHrvRmssdPre: avgHrvRmssdPre ?? this.avgHrvRmssdPre,
      avgHrvRmssdPost: avgHrvRmssdPost ?? this.avgHrvRmssdPost,
      restingHrSameDay: restingHrSameDay ?? this.restingHrSameDay,
      bodyWeightKgNearest: bodyWeightKgNearest ?? this.bodyWeightKgNearest,
      splits: splits ?? this.splits,
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
    if (basalCalories != null) m['calories_basal'] = basalCalories;
    if (distanceMeters != null) m['distance_m'] = distanceMeters;
    if (totalSteps != null) m['steps'] = totalSteps;
    if (flightsClimbed != null) m['flights_climbed'] = flightsClimbed;
    if (elevationGainM != null) m['elevation_gain_m'] = elevationGainM;
    if (avgHeartRate != null) m['avg_heart_rate'] = avgHeartRate;
    if (maxHeartRate != null) m['max_heart_rate'] = maxHeartRate;
    if (minHeartRate != null) m['min_heart_rate'] = minHeartRate;
    if (hrSamples.isNotEmpty) m['hr_samples'] = hrSamples;
    if (hrZonesPct.isNotEmpty) m['hr_zones_pct'] = hrZonesPct;
    if (recoveryHrBpm != null) m['recovery_hr_bpm'] = recoveryHrBpm;
    if (recoveryDropBpm != null) m['recovery_drop_bpm'] = recoveryDropBpm;
    if (avgSpeedMps != null) m['avg_speed_mps'] = avgSpeedMps;
    if (maxSpeedMps != null) m['max_speed_mps'] = maxSpeedMps;
    if (paceSecPerKm != null) m['pace_sec_per_km'] = paceSecPerKm;
    if (paceSamples.isNotEmpty) m['pace_samples'] = paceSamples;
    if (avgCadenceSpm != null) m['avg_cadence_spm'] = avgCadenceSpm;
    if (maxCadenceSpm != null) m['max_cadence_spm'] = maxCadenceSpm;
    if (cadenceSamples.isNotEmpty) m['cadence_samples'] = cadenceSamples;
    if (avgStrideIn != null) m['avg_stride_in'] = avgStrideIn;
    if (avgSpo2 != null) m['avg_spo2'] = avgSpo2;
    if (avgRespiratoryRate != null) {
      m['avg_respiratory_rate'] = avgRespiratoryRate;
    }
    if (peakBodyTemperatureC != null) {
      m['peak_body_temperature_c'] = peakBodyTemperatureC;
    }
    if (avgHrvRmssdPre != null) m['avg_hrv_rmssd_pre'] = avgHrvRmssdPre;
    if (avgHrvRmssdPost != null) m['avg_hrv_rmssd_post'] = avgHrvRmssdPost;
    if (restingHrSameDay != null) m['resting_hr_same_day'] = restingHrSameDay;
    if (bodyWeightKgNearest != null) {
      m['body_weight_kg_nearest'] = bodyWeightKgNearest;
    }
    if (splits.isNotEmpty) m['splits'] = splits;
    if (trainingLoadTrimp != null) m['training_load_trimp'] = trainingLoadTrimp;
    if (effortScore != null) m['effort_score'] = effortScore;
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
    final windowPoints = await healthService.getDataInRange(
      start: start,
      end: windowEnd,
      types: const [
        HealthDataType.HEART_RATE,
        HealthDataType.STEPS,
        HealthDataType.DISTANCE_DELTA,
        HealthDataType.DISTANCE_WALKING_RUNNING,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.TOTAL_CALORIES_BURNED,
        HealthDataType.BASAL_ENERGY_BURNED,
        HealthDataType.FLIGHTS_CLIMBED,
        HealthDataType.BLOOD_OXYGEN,
        HealthDataType.BODY_TEMPERATURE,
        HealthDataType.RESPIRATORY_RATE,
      ],
    );

    // Pre-window data: HRV / resting HR captured in the 4h before workout.
    final preStart = start.subtract(const Duration(hours: 4));
    final prePoints = await healthService.getDataInRange(
      start: preStart,
      end: start,
      types: const [
        HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
        HealthDataType.HEART_RATE_VARIABILITY_SDNN,
        HealthDataType.RESTING_HEART_RATE,
      ],
    );

    // Nearest-body-weight lookup (within 14 days).
    final weightPoints = await healthService.getDataInRange(
      start: start.subtract(const Duration(days: 14)),
      end: end,
      types: const [HealthDataType.WEIGHT],
    );

    // Partition windowPoints by type.
    final hrRaw = <HealthDataPoint>[];
    final stepsRaw = <HealthDataPoint>[];
    final distRaw = <HealthDataPoint>[];
    final activeEnergy = <HealthDataPoint>[];
    final totalEnergy = <HealthDataPoint>[];
    final basalEnergy = <HealthDataPoint>[];
    final flights = <HealthDataPoint>[];
    final spo2 = <HealthDataPoint>[];
    final bodyTemp = <HealthDataPoint>[];
    final respRate = <HealthDataPoint>[];

    for (final p in windowPoints) {
      switch (p.type) {
        case HealthDataType.HEART_RATE:
          hrRaw.add(p);
          break;
        case HealthDataType.STEPS:
          stepsRaw.add(p);
          break;
        case HealthDataType.DISTANCE_DELTA:
        case HealthDataType.DISTANCE_WALKING_RUNNING:
          distRaw.add(p);
          break;
        case HealthDataType.ACTIVE_ENERGY_BURNED:
          activeEnergy.add(p);
          break;
        case HealthDataType.TOTAL_CALORIES_BURNED:
          totalEnergy.add(p);
          break;
        case HealthDataType.BASAL_ENERGY_BURNED:
          basalEnergy.add(p);
          break;
        case HealthDataType.FLIGHTS_CLIMBED:
          flights.add(p);
          break;
        case HealthDataType.BLOOD_OXYGEN:
          spo2.add(p);
          break;
        case HealthDataType.BODY_TEMPERATURE:
          bodyTemp.add(p);
          break;
        case HealthDataType.RESPIRATORY_RATE:
          respRate.add(p);
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

    // --- Energy
    double? activeKcal = _sum(activeEnergy);
    if (activeKcal == null && pending.caloriesBurned != null) {
      activeKcal = pending.caloriesBurned;
    }
    final totalKcal = _sum(totalEnergy);
    final basalKcal = _sum(basalEnergy);

    // --- Distance (prefer envelope if present)
    double? totalDistance = pending.distanceMeters ?? _sum(distRaw);

    // --- Steps (prefer envelope if present)
    int? totalSteps = pending.totalSteps;
    if (totalSteps == null) {
      final sum = _sum(stepsRaw);
      if (sum != null) totalSteps = sum.round();
    }

    // --- Flights + elevation
    int? flightsClimbed;
    final flightsSum = _sum(flights);
    if (flightsSum != null) flightsClimbed = flightsSum.round();
    double? elevationGainM =
        flightsClimbed != null ? flightsClimbed * 3.0 : null;

    // --- Speed / pace series (bucketed 30s deltas from distance)
    final paceSeries = <Map<String, dynamic>>[];
    double? avgSpeedMps, maxSpeedMps, paceSecPerKm;
    if (distRaw.isNotEmpty && totalDistance != null && totalDistance > 0) {
      final bucketSec = math.max(30.0, durationSec / 60);
      final bucketMeters = <int, double>{};
      for (final p in distRaw) {
        final t = p.dateTo.difference(start).inSeconds.toDouble();
        if (t < 0 || t > durationSec) continue;
        final b = (t / bucketSec).floor();
        final v = (p.value as NumericHealthValue).numericValue.toDouble();
        bucketMeters[b] = (bucketMeters[b] ?? 0) + v;
      }
      final keys = bucketMeters.keys.toList()..sort();
      final speeds = <double>[];
      for (final k in keys) {
        final mps = bucketMeters[k]! / bucketSec;
        paceSeries.add({'t': k * bucketSec, 'mps': mps});
        speeds.add(mps);
      }
      if (speeds.isNotEmpty) {
        avgSpeedMps = totalDistance / durationSec;
        maxSpeedMps = speeds.reduce((a, b) => a > b ? a : b);
        paceSecPerKm = 1000 / avgSpeedMps;
      }
    }

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

    // --- Stride length — inches
    double? avgStrideIn;
    if (totalSteps != null &&
        totalSteps > 0 &&
        totalDistance != null &&
        totalDistance > 0) {
      final meters = totalDistance / totalSteps;
      avgStrideIn = meters * 39.3701;
    }

    // --- Vitals
    final avgSpo2 = _average(spo2);
    final avgResp = _average(respRate);
    final peakTemp = _peak(bodyTemp);

    // --- HRV (post) from recovery window
    final hrvPoints = prePoints
        .where((p) =>
            p.type == HealthDataType.HEART_RATE_VARIABILITY_RMSSD ||
            p.type == HealthDataType.HEART_RATE_VARIABILITY_SDNN)
        .toList();
    final avgHrvPre = _average(hrvPoints);

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

    // --- Splits (distance-based, only if we have distance series)
    final splits = (totalDistance != null && totalDistance > 1000)
        ? _buildSplits(
            distancePoints: distRaw,
            hrSeries: hrSeries,
            workoutStart: start,
            splitMeters: 1609.344, // miles (US default); later: user pref
            unitLabel: 'mi',
          )
        : <Map<String, dynamic>>[];

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
      basalCalories: basalKcal,
      distanceMeters: totalDistance,
      totalSteps: totalSteps,
      flightsClimbed: flightsClimbed,
      elevationGainM: elevationGainM,
      avgHeartRate: avgHr,
      maxHeartRate: maxHr,
      minHeartRate: minHr,
      hrSamples: hrSeries
          .map((s) => <String, dynamic>{'t': s.t.round(), 'bpm': s.bpm})
          .toList(),
      hrZonesPct: zonesPct,
      recoveryHrBpm: recoveryHr,
      recoveryDropBpm: recoveryDrop,
      avgSpeedMps: avgSpeedMps,
      maxSpeedMps: maxSpeedMps,
      paceSecPerKm: paceSecPerKm,
      paceSamples: paceSeries,
      avgCadenceSpm: avgCadenceSpm,
      maxCadenceSpm: maxCadenceSpm,
      cadenceSamples: cadenceSeries,
      avgStrideIn: avgStrideIn,
      avgSpo2: avgSpo2,
      avgRespiratoryRate: avgResp,
      peakBodyTemperatureC: peakTemp,
      avgHrvRmssdPre: avgHrvPre,
      restingHrSameDay: restingHr,
      bodyWeightKgNearest: bodyKg,
      splits: splits,
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

  static double? _average(List<HealthDataPoint> points) {
    if (points.isEmpty) return null;
    double s = 0;
    for (final p in points) {
      s += (p.value as NumericHealthValue).numericValue.toDouble();
    }
    return s / points.length;
  }

  static double? _peak(List<HealthDataPoint> points) {
    if (points.isEmpty) return null;
    double m = double.negativeInfinity;
    for (final p in points) {
      final v = (p.value as NumericHealthValue).numericValue.toDouble();
      if (v > m) m = v;
    }
    return m == double.negativeInfinity ? null : m;
  }

  /// Build per-split summaries by integrating the distance time-series.
  /// `hrSeries` is the already-downsampled HR data used for avg-HR per split.
  static List<Map<String, dynamic>> _buildSplits({
    required List<HealthDataPoint> distancePoints,
    required List<({double t, int bpm})> hrSeries,
    required DateTime workoutStart,
    required double splitMeters,
    required String unitLabel,
  }) {
    if (distancePoints.isEmpty) return [];
    // Sort chronologically.
    final sorted = [...distancePoints]
      ..sort((a, b) => a.dateTo.compareTo(b.dateTo));
    double cum = 0;
    final boundaries = <double>[]; // seconds-from-start at each split
    for (final p in sorted) {
      cum += (p.value as NumericHealthValue).numericValue.toDouble();
      while (cum >= (boundaries.length + 1) * splitMeters) {
        final tSec = p.dateTo.difference(workoutStart).inSeconds.toDouble();
        boundaries.add(tSec);
      }
    }
    final splits = <Map<String, dynamic>>[];
    double prev = 0;
    for (int i = 0; i < boundaries.length; i++) {
      final t = boundaries[i];
      final duration = (t - prev).round();
      if (duration <= 0) {
        prev = t;
        continue;
      }
      final within =
          hrSeries.where((s) => s.t >= prev && s.t <= t).toList();
      int? avgHr;
      if (within.isNotEmpty) {
        avgHr =
            within.map((s) => s.bpm).reduce((a, b) => a + b) ~/ within.length;
      }
      splits.add({
        'i': i,
        'unit': unitLabel,
        'duration_sec': duration,
        if (avgHr != null) 'avg_hr': avgHr,
        'avg_speed_mps': splitMeters / duration,
      });
      prev = t;
    }
    return splits;
  }
}
