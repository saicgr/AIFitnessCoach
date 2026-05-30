import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'api_client.dart';
import 'activity_service.dart';
import 'data_cache_service.dart';
import '../../core/services/posthog_service.dart';
import '../providers/demo_health_mode_provider.dart';

part 'health_service_part_daily_activity.dart';

part 'health_service_ui.dart';


/// Health service provider
final healthServiceProvider = Provider<HealthService>((ref) {
  return HealthService();
});

// ===========================================================================
// Disclosed reviewer-demo converters
// ===========================================================================
//
// These convert a backend `DailyActivity` row (one per calendar day, from
// the seeded `daily_activity` table) into the in-memory `SleepSummary` /
// `DailySleep` shapes the sleep UI normally builds from raw Health Connect
// / HealthKit data points. They are used ONLY by the reviewer-demo branches
// of the health providers — see `demoHealthModeProvider`. Real accounts
// never reach this code.

/// Build a [SleepSummary] from a backend [DailyActivity] row's stored sleep
/// totals. Returns `null` when the row carries no usable sleep duration
/// (mirrors the `!sleep.hasData` guards on the real path).
SleepSummary? sleepSummaryFromActivity(DailyActivity a) {
  final total = a.sleepMinutes ?? 0;
  if (total <= 0) return null;
  final deep = a.deepSleepMinutes ?? 0;
  final rem = a.remSleepMinutes ?? 0;
  final awake = a.awakeSleepMinutes ?? 0;
  // Light = remainder when not explicitly stored (the seed always stores it,
  // but stay defensive against older rows).
  final light = a.lightSleepMinutes ?? (total - deep - rem).clamp(0, total);
  final bed = a.sleepStart;
  final wake = a.sleepEnd;
  int? timeInBed;
  if (bed != null && wake != null) {
    final span = wake.difference(bed).inMinutes;
    if (span > 0) timeInBed = span;
  }
  return SleepSummary(
    totalMinutes: total,
    deepMinutes: deep,
    remMinutes: rem,
    lightMinutes: light,
    awakeMinutes: awake,
    bedTime: bed,
    wakeTime: wake,
    timeInBedMinutes: timeInBed,
    efficiency: a.sleepEfficiency,
    latencyMinutes: a.sleepLatencyMinutes,
  );
}

/// Build a [DailySleep] (one main sleep, no naps) from a backend
/// [DailyActivity] row. A `daily_activity` row stores a single combined
/// sleep value per calendar day, so there is exactly one sleep session and
/// the naps list is always empty. Returns `null` when the row has no sleep.
DailySleep? dailySleepFromActivity(DailyActivity a) {
  final main = sleepSummaryFromActivity(a);
  if (main == null) return null;
  // Bucket by the row's activity_date (the wake date), local-midnight key —
  // matches `getNightlySleepHistory`'s wake-date keying.
  final wakeDate = DateTime(a.date.year, a.date.month, a.date.day);
  return DailySleep(
    date: wakeDate,
    mainSleep: main,
    naps: const [],
    totalAsleepMinutes: main.totalMinutes,
  );
}

/// Daily activity provider
final dailyActivityProvider = StateNotifierProvider<DailyActivityNotifier, DailyActivityState>((ref) {
  return DailyActivityNotifier(
    ref.watch(healthServiceProvider),
    ref.watch(healthSyncProvider),
    ref.watch(activityServiceProvider),
    ref.watch(apiClientProvider),
    ref.watch(posthogServiceProvider),
    // Disclosed reviewer demo: when true, today's activity is loaded from
    // the seeded backend row instead of the platform Health store. False
    // for every real account — see `demoHealthModeProvider`.
    ref.watch(demoHealthModeProvider),
  );
});

/// Health sync state provider
final healthSyncProvider = StateNotifierProvider<HealthSyncNotifier, HealthSyncState>((ref) {
  return HealthSyncNotifier(
    ref.watch(healthServiceProvider),
    // Reviewer demo accounts read as connected so the health cards render
    // without a paired wearable. False for every real account.
    ref.watch(demoHealthModeProvider),
  );
});

/// AI / chat / manually-logged calories burned TODAY (Phase 6).
///
/// Powers the home "TRACKING" flame icon so an activity logged through the
/// AI Coach ("I did 30 min yoga") shows its burned calories even when no
/// wearable is connected. The backend de-duplicates against wearable-synced
/// sessions, so this is safe to add to the HealthKit total.
///
/// `family` keyed by userId. Invalidate it after a chat `event_logged`
/// (see chat_repository_part_chat_messages_notifier.dart) to refresh.
final aiBurnedCaloriesProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  final service = ref.watch(activityServiceProvider);
  return service.getAiBurnedCaloriesToday(userId);
});

/// Health service for interacting with Health Connect (Android) / HealthKit (iOS)
class HealthService {
  final Health _health = Health();
  bool _isConfigured = false;

  /// Ensure the health plugin is configured. Only calls configure() once.
  Future<void> _ensureConfigured() async {
    if (!_isConfigured) {
      await _health.configure();
      _isConfigured = true;
    }
  }

  /// Check if we have permissions to read health data.
  /// This verifies actual permissions by checking authorization status.
  Future<bool> hasHealthPermissions() async {
    try {
      await _ensureConfigured();

      // Check permissions for the most basic data type (STEPS)
      // If we can read steps, we likely have permissions
      final types = [HealthDataType.STEPS];
      final permissions = [HealthDataAccess.READ];

      // Use hasPermissions to check if we already have authorization
      final hasAuth = await _health.hasPermissions(types, permissions: permissions);

      // hasPermissions returns null if status is unknown, true if granted, false if denied
      if (hasAuth == true) {
        debugPrint('🏥 Health permissions verified: granted');
        return true;
      }

      // On iOS, hasPermissions often returns null for READ permissions.
      // Use SharedPreferences to check if we've previously requested and been granted.
      if (hasAuth == null && Platform.isIOS) {
        final prefs = await SharedPreferences.getInstance();
        final previouslyGranted = prefs.getBool('health_permissions_granted') ?? false;
        if (previouslyGranted) {
          debugPrint('🏥 iOS: hasPermissions returned null but previously granted flag is set');
          return true;
        }
        debugPrint('🏥 iOS: hasPermissions returned null and no previous grant recorded');
        return false;
      }

      debugPrint('🏥 Health permissions verified: not granted');
      return false;
    } catch (e) {
      debugPrint('⚠️ Error checking health permissions: $e');
      return false;
    }
  }

  /// Request permissions for reading/writing health data
  Future<bool> requestPermissions() async {
    try {
      await _ensureConfigured();

      // Get available types for this platform.
      //
      // MINDFULNESS (Apple Health "Mindful Minutes") is requested on iOS ONLY.
      // It is deliberately NOT added to the Android Health Connect scope so we
      // stay at the minimum-permission set that passed Google Play review
      // (project_play_health_connect_rejection). On Android the mindful-minutes
      // metric is sourced purely from in-app session logs.
      final availableReadTypes = _getAvailableTypes([
        ...HealthServiceExt._readTypes,
        if (Platform.isIOS) HealthDataType.MINDFULNESS,
      ]);
      final availableWriteTypes = _getAvailableTypes(HealthServiceExt._writeTypes);

      // Combine all types we need
      final allTypes = <HealthDataType>{...availableReadTypes, ...availableWriteTypes}.toList();

      // Create permissions list - READ for read-only types, READ_WRITE for write types
      final permissions = allTypes.map((type) {
        if (availableWriteTypes.contains(type)) {
          return HealthDataAccess.READ_WRITE;
        }
        return HealthDataAccess.READ;
      }).toList();

      // Request authorization
      final granted = await _health.requestAuthorization(
        allTypes,
        permissions: permissions,
      );

      debugPrint('🏥 Health permissions granted: $granted');

      // Store permission grant flag for iOS (where hasPermissions returns null)
      if (granted && Platform.isIOS) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('health_permissions_granted', true);
      }

      return granted;
    } catch (e) {
      debugPrint('❌ Error requesting health permissions: $e');
      return false;
    }
  }

  // Types that are only available on iOS (not supported on Android).
  static const Set<HealthDataType> _iOSOnlyTypes = {
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.INSULIN_DELIVERY,
  };

  // Types that are only available on Android (not supported on iOS).
  static const Set<HealthDataType> _androidOnlyTypes = {
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_AWAKE_IN_BED,
    HealthDataType.SLEEP_OUT_OF_BED,
    HealthDataType.SLEEP_SESSION,
  };

  // Types that were removed entirely (both Android Health Connect AND iOS
  // HealthKit) on 2026-05-07 to comply with Google Play's "Minimum Scope"
  // Health Connect Permissions policy. None of these data types are read
  // or surfaced anywhere in the user-facing product, so requesting them
  // would be excessive scope on both platforms.
  //
  // Removed: Distance (delta + walking/running), FloorsClimbed,
  // HeartRateVariability (RMSSD + SDNN), ElevationGained, Power, Speed,
  // RespiratoryRate, BasalMetabolicRate (basal energy burned),
  // OxygenSaturation (blood oxygen), BodyTemperature.
  static const Set<HealthDataType> _removedTypes = {
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.DISTANCE_WALKING_RUNNING,
    HealthDataType.FLIGHTS_CLIMBED,
    HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
    HealthDataType.HEART_RATE_VARIABILITY_SDNN,
    HealthDataType.RESPIRATORY_RATE,
    HealthDataType.BASAL_ENERGY_BURNED,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.BODY_TEMPERATURE,
  };

  /// Get health data types available on current platform
  List<HealthDataType> _getAvailableTypes(List<HealthDataType> types) {
    return types.where((type) {
      if (_removedTypes.contains(type)) return false;
      if (Platform.isAndroid) {
        return !_iOSOnlyTypes.contains(type);
      } else if (Platform.isIOS) {
        return !_androidOnlyTypes.contains(type);
      }
      return true;
    }).toList();
  }

  /// Install Health Connect app on Android
  Future<void> installHealthConnect() async {
    await _health.installHealthConnect();
  }

  /// Get all body measurements from Health Connect
  Future<List<HealthDataPoint>> getMeasurements({int days = 30}) async {
    try {
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));

      // Body measurement types
      final measurementTypes = [
        HealthDataType.WEIGHT,
        HealthDataType.BODY_FAT_PERCENTAGE,
        HealthDataType.HEIGHT,
        HealthDataType.BODY_MASS_INDEX,
        HealthDataType.HEART_RATE,
        HealthDataType.RESTING_HEART_RATE,
      ];

      final availableTypes = _getAvailableTypes(measurementTypes);

      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: availableTypes,
      );

      // Remove duplicates
      final uniqueData = _health.removeDuplicates(data);

      debugPrint('🏥 Fetched ${uniqueData.length} health data points');
      return uniqueData;
    } catch (e) {
      debugPrint('❌ Error getting measurements: $e');
      return [];
    }
  }

  /// Get weight history
  Future<List<HealthDataPoint>> getWeightHistory({int days = 90}) async {
    try {
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));

      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: [HealthDataType.WEIGHT],
      );

      return _health.removeDuplicates(data);
    } catch (e) {
      debugPrint('❌ Error getting weight history: $e');
      return [];
    }
  }

  /// Get body fat history
  Future<List<HealthDataPoint>> getBodyFatHistory({int days = 90}) async {
    try {
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));

      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: [HealthDataType.BODY_FAT_PERCENTAGE],
      );

      return _health.removeDuplicates(data);
    } catch (e) {
      debugPrint('❌ Error getting body fat history: $e');
      return [];
    }
  }

  /// Get heart rate data
  Future<List<HealthDataPoint>> getHeartRateData({int days = 7}) async {
    try {
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));

      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: [HealthDataType.HEART_RATE, HealthDataType.RESTING_HEART_RATE],
      );

      return _health.removeDuplicates(data);
    } catch (e) {
      debugPrint('❌ Error getting heart rate data: $e');
      return [];
    }
  }

  /// Get steps data
  Future<int> getTodaySteps() async {
    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      final steps = await _health.getTotalStepsInInterval(midnight, now);
      return steps ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting steps: $e');
      return 0;
    }
  }

  /// Get total steps for an arbitrary [start, end] range. Used by the
  /// 30-day backfill (Issue 12) so days like "April 23" populate the
  /// synced-workouts grid even if the user wasn't running the app then.
  Future<int?> getStepsForRange(DateTime start, DateTime end) async {
    try {
      return await _health.getTotalStepsInInterval(start, end);
    } catch (e) {
      debugPrint('❌ Error getting steps for range $start..$end: $e');
      return null;
    }
  }

  /// Get activity summary for a date range
  Future<Map<String, dynamic>> getActivitySummary({int days = 7}) async {
    try {
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));

      // Distance was removed 2026-05-07 (Google Play Health Connect minimum
      // scope policy). Activity summary now reports steps + active calories
      // only — these are the values surfaced in the home/health card UI.
      final rawData = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: [
          HealthDataType.STEPS,
          HealthDataType.ACTIVE_ENERGY_BURNED,
        ],
      );

      // Remove duplicates before aggregating
      final data = _health.removeDuplicates(rawData);

      int totalSteps = 0;
      double totalCalories = 0;

      for (final point in data) {
        final value = (point.value as NumericHealthValue).numericValue.toDouble();
        switch (point.type) {
          case HealthDataType.STEPS:
            totalSteps += value.toInt();
            break;
          case HealthDataType.ACTIVE_ENERGY_BURNED:
            totalCalories += value;
            break;
          default:
            break;
        }
      }

      return {
        'steps': totalSteps,
        'calories': totalCalories,
        'days': days,
      };
    } catch (e) {
      debugPrint('❌ Error getting activity summary: $e');
      return {'steps': 0, 'calories': 0, 'days': days};
    }
  }

  /// Write a measurement to Health Connect
  Future<bool> writeMeasurement({
    required HealthDataType type,
    required double value,
    required DateTime time,
  }) async {
    try {
      final success = await _health.writeHealthData(
        value: value,
        type: type,
        startTime: time,
        endTime: time,
      );

      debugPrint('🏥 Write to Health Connect: $type = $value, success: $success');
      return success;
    } catch (e) {
      debugPrint('❌ Error writing to Health Connect: $e');
      return false;
    }
  }

  /// Write weight measurement
  Future<bool> writeWeight(double kg) async {
    return writeMeasurement(
      type: HealthDataType.WEIGHT,
      value: kg,
      time: DateTime.now(),
    );
  }

  /// Write body fat percentage
  Future<bool> writeBodyFat(double percentage) async {
    return writeMeasurement(
      type: HealthDataType.BODY_FAT_PERCENTAGE,
      value: percentage,
      time: DateTime.now(),
    );
  }

  /// Write height
  Future<bool> writeHeight(double cm) async {
    return writeMeasurement(
      type: HealthDataType.HEIGHT,
      value: cm / 100, // Health expects meters
      time: DateTime.now(),
    );
  }

  /// Get latest value for a specific health type
  Future<double?> getLatestValue(HealthDataType type) async {
    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 30));

      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: [type],
      );

      if (data.isEmpty) return null;

      // Sort by date and get the most recent
      data.sort((a, b) => b.dateTo.compareTo(a.dateTo));
      return (data.first.value as NumericHealthValue).numericValue.toDouble();
    } catch (e) {
      debugPrint('❌ Error getting latest value: $e');
      return null;
    }
  }

  /// Convert HealthDataType to our app's measurement type string
  static String healthTypeToMeasurementType(HealthDataType type) {
    switch (type) {
      case HealthDataType.WEIGHT:
        return 'weight';
      case HealthDataType.BODY_FAT_PERCENTAGE:
        return 'body_fat';
      case HealthDataType.HEIGHT:
        return 'height';
      case HealthDataType.HEART_RATE:
        return 'heart_rate';
      case HealthDataType.RESTING_HEART_RATE:
        return 'resting_heart_rate';
      case HealthDataType.BODY_MASS_INDEX:
        return 'bmi';
      case HealthDataType.STEPS:
        return 'steps';
      case HealthDataType.ACTIVE_ENERGY_BURNED:
        return 'calories_burned';
      default:
        return type.name.toLowerCase();
    }
  }

  /// Get unit for health data type
  static String getUnitForType(HealthDataType type) {
    switch (type) {
      case HealthDataType.WEIGHT:
        return 'kg';
      case HealthDataType.BODY_FAT_PERCENTAGE:
        return '%';
      case HealthDataType.HEIGHT:
        return 'm';
      case HealthDataType.HEART_RATE:
      case HealthDataType.RESTING_HEART_RATE:
        return 'bpm';
      case HealthDataType.STEPS:
        return 'steps';
      case HealthDataType.ACTIVE_ENERGY_BURNED:
      case HealthDataType.TOTAL_CALORIES_BURNED:
        return 'kcal';
      case HealthDataType.BLOOD_GLUCOSE:
        return 'mg/dL';
      case HealthDataType.INSULIN_DELIVERY:
        return 'units';
      default:
        return '';
    }
  }

  // ============================================
  // Workout Sessions
  // ============================================

  /// Get workout sessions from Health Connect
  Future<List<HealthDataPoint>> getWorkoutSessions({int days = 7}) async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));

      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: [HealthDataType.WORKOUT],
      );

      final uniqueData = _health.removeDuplicates(data);
      debugPrint('🏋️ Fetched ${uniqueData.length} workout sessions (last $days days)');
      return uniqueData;
    } catch (e) {
      debugPrint('❌ Error getting workout sessions: $e');
      return [];
    }
  }

  // ============================================
  // Heart Rate for Time Range
  // ============================================

  /// Get heart rate data for a specific time range
  Future<List<HealthDataPoint>> getHeartRateForTimeRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      await _ensureConfigured();

      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: [HealthDataType.HEART_RATE],
      );

      final uniqueData = _health.removeDuplicates(data);
      debugPrint('❤️ Heart rate: ${uniqueData.length} data points for range');
      return uniqueData;
    } catch (e) {
      debugPrint('❌ Error getting heart rate for time range: $e');
      return [];
    }
  }

  /// Polls HealthKit / Health Connect for live heart-rate samples during
  /// an active workout. The Flutter `health` plugin doesn't expose a true
  /// HKAnchoredObjectQuery stream, but a 5-second polling cadence over the
  /// last 15s window catches every Amazfit Helios / Apple Watch / Pixel
  /// Watch beat write within ~5s of it landing in HealthKit.
  ///
  /// Cancel by closing the returned subscription. Persisted samples for
  /// the post-workout graph should be appended in the consumer (we keep
  /// this method side-effect-free).
  Stream<int> streamLiveHeartRate({
    Duration pollInterval = const Duration(seconds: 5),
  }) async* {
    int? lastEmitted;
    while (true) {
      try {
        await _ensureConfigured();
        final now = DateTime.now();
        final from = now.subtract(const Duration(seconds: 15));
        final pts = await _health.getHealthDataFromTypes(
          startTime: from,
          endTime: now,
          types: const [HealthDataType.HEART_RATE],
        );
        if (pts.isNotEmpty) {
          // Latest sample wins.
          pts.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
          final raw = pts.first.value;
          int? bpm;
          if (raw is NumericHealthValue) {
            bpm = raw.numericValue.toInt();
          }
          if (bpm != null && bpm > 0 && bpm != lastEmitted) {
            lastEmitted = bpm;
            yield bpm;
          }
        }
      } catch (e) {
        debugPrint('⚠️ Live HR poll error: $e');
      }
      await Future<void>.delayed(pollInterval);
    }
  }

  /// Generic fetcher — pull raw HealthDataPoints for any set of types
  /// within a window. Used by the workout-import enrichment pass to pull
  /// HR, STEPS, DISTANCE_*, ENERGY_*, FLIGHTS, SpO2, BODY_TEMP, RESP_RATE,
  /// HRV etc. in a single call.
  ///
  /// Types must be present in `_readTypes` (see health_service_ui.dart) for
  /// permissions to apply; otherwise the underlying call will return empty.
  Future<List<HealthDataPoint>> getDataInRange({
    required DateTime start,
    required DateTime end,
    required List<HealthDataType> types,
  }) async {
    try {
      await _ensureConfigured();
      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: types,
      );
      return _health.removeDuplicates(data);
    } catch (e) {
      debugPrint('⚠️ Error fetching window data (${types.length} types): $e');
      return [];
    }
  }

  // ============================================
  // Diabetic Health Metrics (Blood Glucose & Insulin)
  // ============================================

  /// Get blood glucose readings from Health Connect
  Future<List<BloodGlucoseReading>> getBloodGlucoseData({int days = 7}) async {
    try {
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));

      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: [HealthDataType.BLOOD_GLUCOSE],
      );

      final uniqueData = _health.removeDuplicates(data);

      return uniqueData.map((point) {
        final value = (point.value as NumericHealthValue).numericValue.toDouble();
        return BloodGlucoseReading(
          value: value,
          unit: 'mg/dL',
          recordedAt: point.dateTo,
          // `sourceName` is non-nullable in health 12.x.
          source: point.sourceName,
          mealContext: _inferMealContext(point.dateTo),
        );
      }).toList()
        ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    } catch (e) {
      debugPrint('❌ Error getting blood glucose data: $e');
      return [];
    }
  }

  /// Get insulin delivery data from Health Connect
  Future<List<InsulinDose>> getInsulinData({int days = 7}) async {
    try {
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));

      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: [HealthDataType.INSULIN_DELIVERY],
      );

      final uniqueData = _health.removeDuplicates(data);

      return uniqueData.map((point) {
        final value = (point.value as NumericHealthValue).numericValue.toDouble();
        return InsulinDose(
          units: value,
          deliveredAt: point.dateTo,
          // `sourceName` is non-nullable in health 12.x.
          source: point.sourceName,
          insulinType: 'unknown', // Health Connect doesn't differentiate
        );
      }).toList()
        ..sort((a, b) => b.deliveredAt.compareTo(a.deliveredAt));
    } catch (e) {
      debugPrint('❌ Error getting insulin data: $e');
      return [];
    }
  }

  /// Write manual blood glucose reading
  Future<bool> writeBloodGlucose(double mgDl) async {
    return writeMeasurement(
      type: HealthDataType.BLOOD_GLUCOSE,
      value: mgDl,
      time: DateTime.now(),
    );
  }

  /// Get daily blood glucose summary
  Future<BloodGlucoseSummary> getDailyGlucoseSummary({DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final start = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final end = start.add(const Duration(days: 1));

    try {
      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: [HealthDataType.BLOOD_GLUCOSE],
      );

      if (data.isEmpty) {
        return BloodGlucoseSummary.empty(date: targetDate);
      }

      final values = data.map((p) =>
        (p.value as NumericHealthValue).numericValue.toDouble()
      ).toList();

      final average = values.reduce((a, b) => a + b) / values.length;
      final min = values.reduce((a, b) => a < b ? a : b);
      final max = values.reduce((a, b) => a > b ? a : b);

      // Calculate time in range (70-180 mg/dL is typical target)
      final inRangeCount = values.where((v) => v >= 70 && v <= 180).length;
      final timeInRange = (inRangeCount / values.length) * 100;

      return BloodGlucoseSummary(
        date: targetDate,
        readingCount: values.length,
        averageGlucose: average,
        minGlucose: min,
        maxGlucose: max,
        timeInRange: timeInRange,
        timeAboveRange: values.where((v) => v > 180).length / values.length * 100,
        timeBelowRange: values.where((v) => v < 70).length / values.length * 100,
      );
    } catch (e) {
      debugPrint('❌ Error getting daily glucose summary: $e');
      return BloodGlucoseSummary.empty(date: targetDate);
    }
  }

  // ============================================
  // Write Workout / Meal / Hydration to Health
  // ============================================

  /// Map Zealova workout type string to HealthWorkoutActivityType (platform-aware).
  static HealthWorkoutActivityType _mapWorkoutType(String fitWizType) {
    final type = fitWizType.toLowerCase().trim();
    switch (type) {
      case 'strength':
      case 'resistance':
        return Platform.isIOS
            ? HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING
            : HealthWorkoutActivityType.STRENGTH_TRAINING;
      case 'hiit':
        return HealthWorkoutActivityType.HIGH_INTENSITY_INTERVAL_TRAINING;
      case 'cardio':
      case 'running':
        return HealthWorkoutActivityType.RUNNING;
      case 'yoga':
        return HealthWorkoutActivityType.YOGA;
      case 'pilates':
        return HealthWorkoutActivityType.PILATES;
      case 'flexibility':
      case 'stretching':
        return Platform.isIOS
            ? HealthWorkoutActivityType.FLEXIBILITY
            : HealthWorkoutActivityType.YOGA;
      case 'calisthenics':
      case 'bodyweight':
        return Platform.isIOS
            ? HealthWorkoutActivityType.FUNCTIONAL_STRENGTH_TRAINING
            : HealthWorkoutActivityType.CALISTHENICS;
      case 'swimming':
        return HealthWorkoutActivityType.SWIMMING;
      case 'cycling':
      case 'biking':
        return HealthWorkoutActivityType.BIKING;
      case 'walking':
        return HealthWorkoutActivityType.WALKING;
      case 'rowing':
        return HealthWorkoutActivityType.ROWING;
      case 'boxing':
        return HealthWorkoutActivityType.BOXING;
      default:
        return HealthWorkoutActivityType.OTHER;
    }
  }

  /// Map Zealova meal type string to health package MealType.
  static MealType _mapMealType(String fitWizMealType) {
    switch (fitWizMealType.toLowerCase().trim()) {
      case 'breakfast':
        return MealType.BREAKFAST;
      case 'lunch':
        return MealType.LUNCH;
      case 'dinner':
        return MealType.DINNER;
      case 'snack':
        return MealType.SNACK;
      default:
        return MealType.UNKNOWN;
    }
  }

  /// Write a completed workout session to Health Connect / HealthKit.
  Future<bool> writeWorkoutSession({
    required String workoutType,
    required DateTime startTime,
    required DateTime endTime,
    int? totalCaloriesBurned,
    String? title,
  }) async {
    try {
      await _ensureConfigured();
      final activityType = _mapWorkoutType(workoutType);

      final success = await _health.writeWorkoutData(
        activityType: activityType,
        start: startTime,
        end: endTime,
        totalEnergyBurned: totalCaloriesBurned,
        title: title,
      );

      // Also write separate ACTIVE_ENERGY_BURNED data point for daily activity totals
      if (totalCaloriesBurned != null && totalCaloriesBurned > 0) {
        try {
          await _health.writeHealthData(
            value: totalCaloriesBurned.toDouble(),
            type: HealthDataType.ACTIVE_ENERGY_BURNED,
            startTime: startTime,
            endTime: endTime,
          );
        } catch (e) {
          debugPrint('⚠️ Non-critical: Failed to write active calories: $e');
        }
      }

      debugPrint('🏋️ Wrote workout to Health: $activityType, success: $success');
      return success;
    } catch (e) {
      debugPrint('❌ Error writing workout to Health: $e');
      return false;
    }
  }

  /// Write a meal / food log to Health Connect / HealthKit.
  Future<bool> writeMealToHealth({
    required String mealType,
    required DateTime loggedAt,
    required double calories,
    double? proteinG,
    double? carbsG,
    double? fatG,
    double? fiberG,
    double? sodiumMg,
    double? sugarG,
    double? cholesterolMg,
    double? potassiumMg,
    double? vitaminAIu,
    double? vitaminCMg,
    double? vitaminDIu,
    double? calciumMg,
    double? ironMg,
    double? saturatedFatG,
    String? name,
  }) async {
    try {
      await _ensureConfigured();
      final healthMealType = _mapMealType(mealType);

      final success = await _health.writeMeal(
        mealType: healthMealType,
        startTime: loggedAt,
        endTime: loggedAt.add(const Duration(minutes: 30)),
        caloriesConsumed: calories,
        protein: proteinG,
        carbohydrates: carbsG,
        fatTotal: fatG,
        fiber: fiberG,
        sodium: sodiumMg,
        sugar: sugarG,
        cholesterol: cholesterolMg,
        potassium: potassiumMg,
        vitaminA: vitaminAIu,
        vitaminC: vitaminCMg,
        vitaminD: vitaminDIu,
        calcium: calciumMg,
        iron: ironMg,
        fatSaturated: saturatedFatG,
        name: name,
      );

      debugPrint('🥗 Wrote meal to Health: $mealType (${calories.toInt()} cal), success: $success');
      return success;
    } catch (e) {
      debugPrint('❌ Error writing meal to Health: $e');
      return false;
    }
  }

  /// Write a hydration / water intake entry to Health Connect / HealthKit.
  Future<bool> writeHydrationToHealth({
    required int amountMl,
    DateTime? time,
  }) async {
    try {
      await _ensureConfigured();
      final now = time ?? DateTime.now();

      final success = await _health.writeHealthData(
        value: amountMl.toDouble(),
        type: HealthDataType.WATER,
        startTime: now,
        endTime: now,
      );

      debugPrint('💧 Wrote hydration to Health: ${amountMl}ml, success: $success');
      return success;
    } catch (e) {
      debugPrint('❌ Error writing hydration to Health: $e');
      return false;
    }
  }

  // ============================================
  // Static fire-and-forget helpers (no Riverpod)
  // ============================================

  /// Fire-and-forget: write a meal to Health if connected and user pref enabled.
  /// Safe to call from anywhere (repository, UI) without Riverpod.
  static Future<void> syncMealToHealthIfEnabled({
    required String mealType,
    required double calories,
    double? proteinG,
    double? carbsG,
    double? fatG,
    double? fiberG,
    double? sodiumMg,
    double? sugarG,
    double? cholesterolMg,
    double? potassiumMg,
    double? vitaminAIu,
    double? vitaminCMg,
    double? vitaminDIu,
    double? calciumMg,
    double? ironMg,
    double? saturatedFatG,
    String? name,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool('health_connected') ?? false)) return;
      if (!(prefs.getBool('health_sync_meals_write') ?? true)) return;

      final service = HealthService();
      await service.writeMealToHealth(
        mealType: mealType,
        loggedAt: DateTime.now(),
        calories: calories,
        proteinG: proteinG,
        carbsG: carbsG,
        fatG: fatG,
        fiberG: fiberG,
        sodiumMg: sodiumMg,
        sugarG: sugarG,
        cholesterolMg: cholesterolMg,
        potassiumMg: potassiumMg,
        vitaminAIu: vitaminAIu,
        vitaminCMg: vitaminCMg,
        vitaminDIu: vitaminDIu,
        calciumMg: calciumMg,
        ironMg: ironMg,
        saturatedFatG: saturatedFatG,
        name: name,
      );
    } catch (e) {
      debugPrint('⚠️ Non-critical: meal health sync failed: $e');
    }
  }

  /// Fire-and-forget: write hydration to Health if connected and user pref enabled.
  /// Safe to call from anywhere without Riverpod.
  static Future<void> syncHydrationToHealthIfEnabled({
    required int amountMl,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool('health_connected') ?? false)) return;
      if (!(prefs.getBool('health_sync_hydration_write') ?? true)) return;

      final service = HealthService();
      await service.writeHydrationToHealth(amountMl: amountMl);
    } catch (e) {
      debugPrint('⚠️ Non-critical: hydration health sync failed: $e');
    }
  }

  /// Infer meal context based on time of day
  String _inferMealContext(DateTime time) {
    final hour = time.hour;
    if (hour >= 5 && hour < 9) return 'before_breakfast';
    if (hour >= 9 && hour < 11) return 'after_breakfast';
    if (hour >= 11 && hour < 13) return 'before_lunch';
    if (hour >= 13 && hour < 15) return 'after_lunch';
    if (hour >= 17 && hour < 19) return 'before_dinner';
    if (hour >= 19 && hour < 22) return 'after_dinner';
    return 'general';
  }

  // ===========================================================================
  // CYCLE TRACKING — menstruation flow + body/wrist temperature (Phase B)
  // ---------------------------------------------------------------------------
  // Added 2026-05-22 for the in-app Cycle tracker. Two data types:
  //   * MENSTRUATION_FLOW — two-way: import period days logged in Apple Health
  //     / Health Connect (other apps) AND export app-logged periods back so
  //     nothing is logged twice across apps.
  //   * BODY_TEMPERATURE  — read-only: feeds the BBT graph. On iOS this is
  //     where the Apple Watch (Series 8+) sleeping *wrist* temperature lands
  //     (HealthKit exposes it as a body-temperature sample); on Android any
  //     wearable writing temperature to Health Connect surfaces here too.
  //
  // These are gated behind their OWN permission request (`requestCyclePermissions`)
  // so a user who only wants steps/sleep is never asked for reproductive-health
  // scope — and the general steps/sleep/weight flow is untouched. BODY_TEMPERATURE
  // is in `_removedTypes` for the general request precisely so it is only ever
  // requested when the cycle feature explicitly needs it.
  // ===========================================================================

  /// Health types the cycle tracker needs. MENSTRUATION_FLOW is read+write,
  /// BODY_TEMPERATURE is read-only (BBT signal).
  static const List<HealthDataType> cycleReadTypes = [
    HealthDataType.MENSTRUATION_FLOW,
    HealthDataType.BODY_TEMPERATURE,
  ];

  static const List<HealthDataType> cycleWriteTypes = [
    HealthDataType.MENSTRUATION_FLOW,
  ];

  /// Request the cycle-specific health permissions (menstruation flow R/W +
  /// body temperature read). Separate from [requestPermissions] so the
  /// reproductive-health scope is only ever requested when the user opts into
  /// the Cycle feature. Returns true when the grant succeeded.
  Future<bool> requestCyclePermissions() async {
    try {
      await _ensureConfigured();

      final permissions = cycleReadTypes.map((type) {
        return cycleWriteTypes.contains(type)
            ? HealthDataAccess.READ_WRITE
            : HealthDataAccess.READ;
      }).toList();

      final granted = await _health.requestAuthorization(
        cycleReadTypes,
        permissions: permissions,
      );
      debugPrint('🩸 Cycle health permissions granted: $granted');

      if (granted && Platform.isIOS) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('health_cycle_permissions_granted', true);
      }
      return granted;
    } catch (e) {
      debugPrint('❌ Error requesting cycle health permissions: $e');
      return false;
    }
  }

  /// Whether the cycle-specific health permissions have been granted.
  Future<bool> hasCyclePermissions() async {
    try {
      await _ensureConfigured();
      final hasAuth = await _health.hasPermissions(
        cycleReadTypes,
        permissions: cycleReadTypes
            .map((t) => cycleWriteTypes.contains(t)
                ? HealthDataAccess.READ_WRITE
                : HealthDataAccess.READ)
            .toList(),
      );
      if (hasAuth == true) return true;
      // iOS routinely returns null for READ scopes — trust our stored flag.
      if (hasAuth == null && Platform.isIOS) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getBool('health_cycle_permissions_granted') ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('⚠️ Error checking cycle health permissions: $e');
      return false;
    }
  }

  /// Read raw body / wrist temperature samples (°C) over the last [days].
  ///
  /// On iOS this includes the Apple Watch sleeping *wrist* temperature
  /// (HealthKit reports it as a body-temperature quantity). The cycle
  /// predictor consumes Celsius directly — no conversion is applied here.
  Future<List<CycleTemperatureSample>> getBodyTemperatureHistory({
    int days = 120,
  }) async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));

      final raw = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: const [HealthDataType.BODY_TEMPERATURE],
      );
      final data = _health.removeDuplicates(raw);

      final out = <CycleTemperatureSample>[];
      for (final point in data) {
        final value = point.value;
        if (value is! NumericHealthValue) continue;
        out.add(CycleTemperatureSample(
          dateTime: point.dateFrom,
          celsius: value.numericValue.toDouble(),
          source: point.sourceName,
        ));
      }
      out.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      debugPrint('🌡️ Fetched ${out.length} body-temperature samples '
          '(last $days days)');
      return out;
    } catch (e) {
      debugPrint('❌ Error getting body temperature history: $e');
      return [];
    }
  }

  /// Read menstruation-flow samples logged in Apple Health / Health Connect
  /// (by any app) over the last [days]. The returned [CyclePeriodDay]s are
  /// per-day flow observations — group consecutive non-`none` days into a
  /// period before pushing to the backend `/periods` endpoint.
  Future<List<CyclePeriodDay>> getMenstruationFlowHistory({
    int days = 365,
  }) async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));

      final raw = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: const [HealthDataType.MENSTRUATION_FLOW],
      );
      final data = _health.removeDuplicates(raw);

      final out = <CyclePeriodDay>[];
      for (final point in data) {
        final value = point.value;
        if (value is! MenstruationFlowHealthValue) continue;
        out.add(CyclePeriodDay(
          date: DateTime(
            point.dateFrom.year,
            point.dateFrom.month,
            point.dateFrom.day,
          ),
          flow: value.flow ?? MenstrualFlow.unspecified,
          isCycleStart: value.isStartOfCycle ?? false,
          source: point.sourceName,
        ));
      }
      out.sort((a, b) => a.date.compareTo(b.date));
      debugPrint('🩸 Fetched ${out.length} menstruation-flow days '
          '(last $days days)');
      return out;
    } catch (e) {
      debugPrint('❌ Error getting menstruation flow history: $e');
      return [];
    }
  }

  /// Map the app's `period_flow` enum string onto the `health` package's
  /// [MenstrualFlow]. Unknown / `none` → `MenstrualFlow.none`.
  static MenstrualFlow mapPeriodFlow(String? fitWizFlow) {
    switch (fitWizFlow?.toLowerCase().trim()) {
      case 'spotting':
        return MenstrualFlow.spotting;
      case 'light':
        return MenstrualFlow.light;
      case 'medium':
        return MenstrualFlow.medium;
      case 'heavy':
        return MenstrualFlow.heavy;
      case 'none':
        return MenstrualFlow.none;
      default:
        return MenstrualFlow.unspecified;
    }
  }

  /// Write one menstruation-flow day to Apple Health / Health Connect.
  ///
  /// [isStartOfCycle] must be true for Day 1 of bleeding so HealthKit /
  /// Health Connect anchor the cycle correctly. [date] is treated as a
  /// calendar day (the sample spans local-midnight → +1 day).
  Future<bool> writeMenstruationFlow({
    required DateTime date,
    required MenstrualFlow flow,
    required bool isStartOfCycle,
  }) async {
    try {
      await _ensureConfigured();
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final success = await _health.writeMenstruationFlow(
        flow: flow,
        startTime: dayStart,
        endTime: dayEnd,
        isStartOfCycle: isStartOfCycle,
        // App-logged period data is a manual user entry, not automatic.
        recordingMethod: RecordingMethod.manual,
      );
      debugPrint('🩸 Wrote menstruation flow to Health: '
          '${flow.name} on $dayStart (start=$isStartOfCycle), success: $success');
      return success;
    } catch (e) {
      debugPrint('❌ Error writing menstruation flow to Health: $e');
      return false;
    }
  }

  /// Export an app-logged period to Apple Health / Health Connect.
  ///
  /// Writes one `MENSTRUATION_FLOW` sample per day from [startDate] through
  /// [endDate] inclusive (or just the start day when [endDate] is null),
  /// flagging the first day as the start of the cycle. This is the "export"
  /// half of the two-way period sync — so a period logged in Zealova also
  /// appears in Apple Health and is not re-imported as a duplicate.
  ///
  /// Returns the number of days successfully written.
  Future<int> exportPeriodToHealth({
    required DateTime startDate,
    DateTime? endDate,
    String periodFlow = 'medium',
  }) async {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = endDate == null
        ? start
        : DateTime(endDate.year, endDate.month, endDate.day);
    if (end.isBefore(start)) {
      debugPrint('⚠️ exportPeriodToHealth: endDate before startDate, skipping');
      return 0;
    }
    final flow = mapPeriodFlow(periodFlow);
    var written = 0;
    for (var day = start;
        !day.isAfter(end);
        day = day.add(const Duration(days: 1))) {
      final ok = await writeMenstruationFlow(
        date: day,
        flow: flow,
        isStartOfCycle: day == start,
      );
      if (ok) written++;
    }
    debugPrint('🩸 Exported period $start..$end to Health ($written days)');
    return written;
  }

  /// Import the periods recorded in Apple Health / Health Connect, collapsing
  /// consecutive bleeding days into discrete periods.
  ///
  /// Returns a list of [CycleImportedPeriod] (`startDate` + optional
  /// `endDate`) ready to be POSTed to `/hormonal-health/periods/{user_id}` by
  /// the repository layer. A gap of more than [gapDays] non-bleeding days
  /// ends a period; a `none`-flow day is treated as a non-bleeding day.
  ///
  /// This is the "import" half of the two-way period sync. The caller should
  /// de-duplicate against already-known periods before writing.
  Future<List<CycleImportedPeriod>> importPeriodsFromHealth({
    int days = 365,
    int gapDays = 1,
  }) async {
    final flowDays = await getMenstruationFlowHistory(days: days);
    // Keep only actual bleeding days (drop explicit `none`).
    final bleeding = flowDays
        .where((d) => d.flow != MenstrualFlow.none)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (bleeding.isEmpty) return const [];

    final periods = <CycleImportedPeriod>[];
    DateTime runStart = bleeding.first.date;
    DateTime runEnd = bleeding.first.date;

    for (var i = 1; i < bleeding.length; i++) {
      final day = bleeding[i].date;
      final gap = day.difference(runEnd).inDays;
      if (gap <= gapDays + 1 && gap > 0) {
        // Same period — extend the run (small gaps tolerate a missed log).
        runEnd = day;
      } else if (gap == 0) {
        // Duplicate same-day sample — ignore.
        continue;
      } else {
        periods.add(CycleImportedPeriod(startDate: runStart, endDate: runEnd));
        runStart = day;
        runEnd = day;
      }
    }
    periods.add(CycleImportedPeriod(startDate: runStart, endDate: runEnd));
    debugPrint('🩸 Imported ${periods.length} periods from Health '
        '(${bleeding.length} bleeding days)');
    return periods;
  }
}

// ===========================================================================
// Cycle sync value types (Phase B)
// ===========================================================================

/// One body/wrist-temperature sample read from Apple Health / Health Connect.
class CycleTemperatureSample {
  final DateTime dateTime;

  /// Temperature in Celsius (the cycle predictor's canonical unit).
  final double celsius;
  final String? source;

  const CycleTemperatureSample({
    required this.dateTime,
    required this.celsius,
    this.source,
  });
}

/// One day's menstruation-flow observation read from the platform health store.
class CyclePeriodDay {
  final DateTime date;
  final MenstrualFlow flow;
  final bool isCycleStart;
  final String? source;

  const CyclePeriodDay({
    required this.date,
    required this.flow,
    required this.isCycleStart,
    this.source,
  });
}

/// A period reconstructed from imported menstruation-flow days — ready to be
/// pushed to the backend `/hormonal-health/periods/{user_id}` endpoint.
class CycleImportedPeriod {
  final DateTime startDate;
  final DateTime? endDate;

  const CycleImportedPeriod({required this.startDate, this.endDate});
}
