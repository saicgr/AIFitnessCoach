import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'activity_service.dart';
import '../../core/services/posthog_service.dart';

part 'health_service_part_daily_activity.dart';

part 'health_service_ui.dart';


/// Health service provider
final healthServiceProvider = Provider<HealthService>((ref) {
  return HealthService();
});

/// Daily activity provider
final dailyActivityProvider = StateNotifierProvider<DailyActivityNotifier, DailyActivityState>((ref) {
  return DailyActivityNotifier(
    ref.watch(healthServiceProvider),
    ref.watch(healthSyncProvider),
    ref.watch(activityServiceProvider),
    ref.watch(apiClientProvider),
    ref.watch(posthogServiceProvider),
  );
});

/// Health sync state provider
final healthSyncProvider = StateNotifierProvider<HealthSyncNotifier, HealthSyncState>((ref) {
  return HealthSyncNotifier(ref.watch(healthServiceProvider));
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

      // Get available types for this platform
      final availableReadTypes = _getAvailableTypes(HealthServiceExt._readTypes);
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

  // Types that are only available on iOS (not supported on Android)
  static const Set<HealthDataType> _iOSOnlyTypes = {
    HealthDataType.HEART_RATE_VARIABILITY_SDNN,
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.INSULIN_DELIVERY,
    HealthDataType.DISTANCE_WALKING_RUNNING,
  };

  // Types that are only available on Android (not supported on iOS)
  static const Set<HealthDataType> _androidOnlyTypes = {
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_REM,
    HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_AWAKE_IN_BED,
    HealthDataType.SLEEP_OUT_OF_BED,
    HealthDataType.SLEEP_SESSION,
  };

  /// Get health data types available on current platform
  List<HealthDataType> _getAvailableTypes(List<HealthDataType> types) {
    return types.where((type) {
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

  /// Get activity summary for a date range
  Future<Map<String, dynamic>> getActivitySummary({int days = 7}) async {
    try {
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));

      final distanceType = Platform.isIOS
          ? HealthDataType.DISTANCE_WALKING_RUNNING
          : HealthDataType.DISTANCE_DELTA;
      final rawData = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: [
          HealthDataType.STEPS,
          HealthDataType.ACTIVE_ENERGY_BURNED,
          distanceType,
        ],
      );

      // Remove duplicates before aggregating
      final data = _health.removeDuplicates(rawData);

      int totalSteps = 0;
      double totalCalories = 0;
      double totalDistance = 0;

      for (final point in data) {
        final value = (point.value as NumericHealthValue).numericValue.toDouble();
        switch (point.type) {
          case HealthDataType.STEPS:
            totalSteps += value.toInt();
            break;
          case HealthDataType.ACTIVE_ENERGY_BURNED:
            totalCalories += value;
            break;
          case HealthDataType.DISTANCE_DELTA:
          case HealthDataType.DISTANCE_WALKING_RUNNING:
            totalDistance += value;
            break;
          default:
            break;
        }
      }

      return {
        'steps': totalSteps,
        'calories': totalCalories,
        'distance': totalDistance, // in meters
        'days': days,
      };
    } catch (e) {
      debugPrint('❌ Error getting activity summary: $e');
      return {'steps': 0, 'calories': 0, 'distance': 0, 'days': days};
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
      case HealthDataType.DISTANCE_DELTA:
        return 'm';
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
          source: point.sourceName ?? 'Health Connect',
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
          source: point.sourceName ?? 'Health Connect',
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

  /// Map FitWiz workout type string to HealthWorkoutActivityType (platform-aware).
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

  /// Map FitWiz meal type string to health package MealType.
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
}
