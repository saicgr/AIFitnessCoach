import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'health_service.dart';

// ---------------------------------------------------------------------------
// PendingWorkoutImport - model for a workout discovered in Health Connect
// that has not yet been imported into FitWiz.
// ---------------------------------------------------------------------------

class PendingWorkoutImport {
  final String uuid;
  final String activityType; // strength, cardio, flexibility, hiit
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final double? caloriesBurned;
  final double? distanceMeters;
  final int? totalSteps;
  final String? sourceName;
  final int? avgHeartRate;
  final int? maxHeartRate;
  final int? minHeartRate;

  const PendingWorkoutImport({
    required this.uuid,
    required this.activityType,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.caloriesBurned,
    this.distanceMeters,
    this.totalSteps,
    this.sourceName,
    this.avgHeartRate,
    this.maxHeartRate,
    this.minHeartRate,
  });

  /// Create from a HealthDataPoint whose value is a WorkoutHealthValue.
  factory PendingWorkoutImport.fromHealthDataPoint(HealthDataPoint point) {
    final workout = point.value as WorkoutHealthValue;
    final duration = point.dateTo.difference(point.dateFrom).inMinutes;

    return PendingWorkoutImport(
      uuid: point.uuid,
      activityType: _mapActivityType(workout.workoutActivityType),
      startTime: point.dateFrom,
      endTime: point.dateTo,
      durationMinutes: duration < 1 ? 1 : duration,
      caloriesBurned: workout.totalEnergyBurned != null
          ? workout.totalEnergyBurned!.toDouble()
          : null,
      distanceMeters: workout.totalDistance != null
          ? workout.totalDistance!.toDouble()
          : null,
      totalSteps: workout.totalSteps?.toInt(),
      sourceName: point.sourceName,
    );
  }

  /// Return a copy with heart-rate fields populated.
  PendingWorkoutImport copyWithHeartRate({
    int? avgHeartRate,
    int? maxHeartRate,
    int? minHeartRate,
  }) {
    return PendingWorkoutImport(
      uuid: uuid,
      activityType: activityType,
      startTime: startTime,
      endTime: endTime,
      durationMinutes: durationMinutes,
      caloriesBurned: caloriesBurned,
      distanceMeters: distanceMeters,
      totalSteps: totalSteps,
      sourceName: sourceName,
      avgHeartRate: avgHeartRate ?? this.avgHeartRate,
      maxHeartRate: maxHeartRate ?? this.maxHeartRate,
      minHeartRate: minHeartRate ?? this.minHeartRate,
    );
  }

  /// Map Health Connect activity type to FitWiz category.
  static String _mapActivityType(HealthWorkoutActivityType type) {
    switch (type) {
      case HealthWorkoutActivityType.WEIGHTLIFTING:
        return 'strength';
      case HealthWorkoutActivityType.RUNNING:
      case HealthWorkoutActivityType.BIKING:
      case HealthWorkoutActivityType.WALKING:
      case HealthWorkoutActivityType.SWIMMING:
      case HealthWorkoutActivityType.ROWING:
        return 'cardio';
      case HealthWorkoutActivityType.YOGA:
      case HealthWorkoutActivityType.PILATES:
        return 'flexibility';
      case HealthWorkoutActivityType.HIGH_INTENSITY_INTERVAL_TRAINING:
        return 'hiit';
      default:
        return 'cardio';
    }
  }

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'activityType': activityType,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'durationMinutes': durationMinutes,
        'caloriesBurned': caloriesBurned,
        'distanceMeters': distanceMeters,
        'totalSteps': totalSteps,
        'sourceName': sourceName,
        'avgHeartRate': avgHeartRate,
        'maxHeartRate': maxHeartRate,
        'minHeartRate': minHeartRate,
      };
}

// ---------------------------------------------------------------------------
// ImportedWorkoutTracker - SharedPreferences-backed UUID dedup tracker.
// Stores {uuid: timestamp_ms} with a 30-day TTL.
// ---------------------------------------------------------------------------

class ImportedWorkoutTracker {
  static const _prefsKey = 'health_import_uuids';
  static const _ttlDays = 30;

  Map<String, int>? _cache;

  /// Load the tracked UUIDs from SharedPreferences.
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

  /// Persist the current map back to SharedPreferences.
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_cache ?? {}));
  }

  /// Remove entries older than 30 days.
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

  /// Check if a UUID has already been imported.
  Future<bool> isTracked(String uuid) async {
    await pruneOldEntries();
    final map = await _load();
    return map.containsKey(uuid);
  }

  /// Mark a UUID as imported.
  Future<void> markTracked(String uuid) async {
    final map = await _load();
    map[uuid] = DateTime.now().millisecondsSinceEpoch;
    await _save();
  }
}

// ---------------------------------------------------------------------------
// HealthImportService - orchestrates discovery and enrichment of workouts
// from Health Connect / HealthKit that haven't been imported yet.
// ---------------------------------------------------------------------------

class HealthImportService {
  final ImportedWorkoutTracker _tracker = ImportedWorkoutTracker();

  /// Fetch workout sessions from Health Connect that have not been imported.
  ///
  /// [healthService] is the existing HealthService that wraps the health plugin.
  /// [days] controls the lookback window (default 7).
  Future<List<PendingWorkoutImport>> getUnimportedWorkouts(
    HealthService healthService, {
    int days = 7,
  }) async {
    try {
      final sessions = await _fetchWorkoutSessions(healthService, days: days);
      final results = <PendingWorkoutImport>[];

      for (final point in sessions) {
        if (point.value is! WorkoutHealthValue) continue;
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

  /// Enrich a PendingWorkoutImport with heart-rate data for its time window.
  Future<PendingWorkoutImport> enrichWithHeartRate(
    PendingWorkoutImport workout,
    HealthService healthService,
  ) async {
    try {
      final hrPoints = await _fetchHeartRateForTimeRange(
        healthService,
        workout.startTime,
        workout.endTime,
      );

      if (hrPoints.isEmpty) return workout;

      final values = hrPoints
          .map((p) =>
              (p.value as NumericHealthValue).numericValue.toInt())
          .toList();

      final avg = values.reduce((a, b) => a + b) ~/ values.length;
      final max = values.reduce((a, b) => a > b ? a : b);
      final min = values.reduce((a, b) => a < b ? a : b);

      return workout.copyWithHeartRate(
        avgHeartRate: avg,
        maxHeartRate: max,
        minHeartRate: min,
      );
    } catch (e) {
      debugPrint(
          '⚠️ [HealthImport] Could not enrich HR for ${workout.uuid}: $e');
      return workout;
    }
  }

  /// Mark a workout as imported so it won't appear again.
  Future<void> markImported(String uuid) async {
    await _tracker.markTracked(uuid);
  }

  // -- Private helpers that delegate to HealthService --

  /// Read WORKOUT data points via HealthService.
  Future<List<HealthDataPoint>> _fetchWorkoutSessions(
    HealthService healthService,
    {int days = 7,}
  ) async {
    return await healthService.getWorkoutSessions(days: days);
  }

  /// Read HEART_RATE data points for a specific time range via HealthService.
  Future<List<HealthDataPoint>> _fetchHeartRateForTimeRange(
    HealthService healthService,
    DateTime start,
    DateTime end,
  ) async {
    return await healthService.getHeartRateForTimeRange(start, end);
  }
}
