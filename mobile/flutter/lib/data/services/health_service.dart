import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'activity_service.dart';

/// Health service provider
final healthServiceProvider = Provider<HealthService>((ref) {
  return HealthService();
});

/// Daily activity data
class DailyActivity {
  final int steps;
  final double caloriesBurned;
  final double distanceMeters;
  final int? restingHeartRate;
  final DateTime date;
  final bool isFromHealthConnect;

  const DailyActivity({
    this.steps = 0,
    this.caloriesBurned = 0,
    this.distanceMeters = 0,
    this.restingHeartRate,
    required this.date,
    this.isFromHealthConnect = false,
  });

  /// Distance in kilometers
  double get distanceKm => distanceMeters / 1000;

  /// Distance in miles
  double get distanceMiles => distanceMeters / 1609.344;
}

/// Daily activity state
class DailyActivityState {
  final bool isLoading;
  final String? error;
  final DailyActivity? today;
  final List<DailyActivity> weekHistory;

  const DailyActivityState({
    this.isLoading = false,
    this.error,
    this.today,
    this.weekHistory = const [],
  });

  DailyActivityState copyWith({
    bool? isLoading,
    String? error,
    DailyActivity? today,
    List<DailyActivity>? weekHistory,
  }) {
    return DailyActivityState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      today: today ?? this.today,
      weekHistory: weekHistory ?? this.weekHistory,
    );
  }
}

/// Daily activity provider
final dailyActivityProvider = StateNotifierProvider<DailyActivityNotifier, DailyActivityState>((ref) {
  return DailyActivityNotifier(
    ref.watch(healthServiceProvider),
    ref.watch(healthSyncProvider),
    ref.watch(activityServiceProvider),
    ref.watch(apiClientProvider),
  );
});

/// Daily activity notifier
class DailyActivityNotifier extends StateNotifier<DailyActivityState> {
  final HealthService _healthService;
  final HealthSyncState _syncState;
  final ActivityService _activityService;
  final ApiClient _apiClient;

  DailyActivityNotifier(
    this._healthService,
    this._syncState,
    this._activityService,
    this._apiClient,
  ) : super(const DailyActivityState()) {
    // Auto-load if connected
    if (_syncState.isConnected) {
      loadTodayActivity();
    }
  }

  /// Load today's activity from Health Connect
  Future<void> loadTodayActivity() async {
    if (!_syncState.isConnected) {
      state = state.copyWith(
        today: DailyActivity(date: DateTime.now(), isFromHealthConnect: false),
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final steps = await _healthService.getTodaySteps();
      final activityData = await _healthService.getActivitySummary(days: 1);
      final heartRateData = await _healthService.getHeartRateData(days: 1);

      // Get resting heart rate if available
      int? restingHR;
      for (final point in heartRateData) {
        if (point.type == HealthDataType.RESTING_HEART_RATE) {
          restingHR = (point.value as NumericHealthValue).numericValue.toInt();
          break;
        }
      }

      final today = DailyActivity(
        steps: steps,
        caloriesBurned: (activityData['calories'] as num?)?.toDouble() ?? 0,
        distanceMeters: (activityData['distance'] as num?)?.toDouble() ?? 0,
        restingHeartRate: restingHR,
        date: DateTime.now(),
        isFromHealthConnect: true,
      );

      state = state.copyWith(isLoading: false, today: today);

      // Sync to Supabase in the background
      _syncToSupabase(today);
    } catch (e) {
      debugPrint('❌ Error loading daily activity: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        today: DailyActivity(date: DateTime.now(), isFromHealthConnect: false),
      );
    }
  }

  /// Sync activity to Supabase in the background
  Future<void> _syncToSupabase(DailyActivity activity) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) {
        debugPrint('⚠️ [Activity] No user ID, skipping Supabase sync');
        return;
      }

      // Only sync if there's actual data
      if (activity.steps == 0 && activity.caloriesBurned == 0 && activity.distanceMeters == 0) {
        debugPrint('⚠️ [Activity] No activity data to sync');
        return;
      }

      await _activityService.syncActivity(
        userId: userId,
        activity: activity,
      );
    } catch (e) {
      debugPrint('❌ [Activity] Error syncing to Supabase: $e');
      // Don't throw - this is background sync, shouldn't affect UI
    }
  }

  /// Load week history
  Future<void> loadWeekHistory() async {
    if (!_syncState.isConnected) return;

    try {
      final activityData = await _healthService.getActivitySummary(days: 7);
      // For now, just update total - detailed daily breakdown would need more API work
      debugPrint('🏃 Week activity: $activityData');
    } catch (e) {
      debugPrint('❌ Error loading week history: $e');
    }
  }

  /// Refresh activity data
  Future<void> refresh() async {
    await loadTodayActivity();
  }
}

/// Health sync state
class HealthSyncState {
  final bool isConnected;
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final String? error;
  final int? syncedCount;

  const HealthSyncState({
    this.isConnected = false,
    this.isSyncing = false,
    this.lastSyncTime,
    this.error,
    this.syncedCount,
  });

  HealthSyncState copyWith({
    bool? isConnected,
    bool? isSyncing,
    DateTime? lastSyncTime,
    String? error,
    int? syncedCount,
  }) {
    return HealthSyncState(
      isConnected: isConnected ?? this.isConnected,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      error: error,
      syncedCount: syncedCount ?? this.syncedCount,
    );
  }
}

/// Health sync state provider
final healthSyncProvider = StateNotifierProvider<HealthSyncNotifier, HealthSyncState>((ref) {
  return HealthSyncNotifier(ref.watch(healthServiceProvider));
});

/// Health sync state notifier
class HealthSyncNotifier extends StateNotifier<HealthSyncState> {
  final HealthService _healthService;

  HealthSyncNotifier(this._healthService) : super(const HealthSyncState()) {
    _loadSyncState();
  }

  Future<void> _loadSyncState() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncMs = prefs.getInt('health_last_sync');
    final storedIsConnected = prefs.getBool('health_connected') ?? false;

    // First, set state from stored preferences
    state = state.copyWith(
      isConnected: storedIsConnected,
      lastSyncTime: lastSyncMs != null ? DateTime.fromMillisecondsSinceEpoch(lastSyncMs) : null,
    );

    // Then verify actual permissions - user may have granted them in Health Connect app directly
    await _verifyAndUpdateConnectionStatus();
  }

  /// Verify actual Health Connect permissions and update state accordingly.
  /// This handles the case where user grants permissions in Health Connect app
  /// outside of FitWiz, so our stored state becomes stale.
  Future<void> _verifyAndUpdateConnectionStatus() async {
    try {
      // Check if Health Connect is available first
      final available = await _healthService.isHealthConnectAvailable();
      if (!available) {
        debugPrint('🏥 Health Connect not available on this device');
        return;
      }

      // Try to check if we have permissions by attempting to read data
      final hasPermissions = await _healthService.hasHealthPermissions();

      if (hasPermissions && !state.isConnected) {
        // User granted permissions outside the app - update our state
        debugPrint('🏥 Health Connect permissions detected (granted externally), updating state');
        state = state.copyWith(isConnected: true);
        await _saveSyncState();
      } else if (!hasPermissions && state.isConnected) {
        // User revoked permissions - update our state
        debugPrint('🏥 Health Connect permissions revoked, updating state');
        state = state.copyWith(isConnected: false);
        await _saveSyncState();
      }
    } catch (e) {
      debugPrint('⚠️ Error verifying Health Connect status: $e');
      // Don't change state on error - keep existing state
    }
  }

  /// Refresh connection status - call this when app resumes to detect external changes
  Future<void> refreshConnectionStatus() async {
    await _verifyAndUpdateConnectionStatus();
  }

  Future<void> _saveSyncState() async {
    final prefs = await SharedPreferences.getInstance();
    if (state.lastSyncTime != null) {
      await prefs.setInt('health_last_sync', state.lastSyncTime!.millisecondsSinceEpoch);
    }
    await prefs.setBool('health_connected', state.isConnected);
  }

  /// Check if Health Connect/HealthKit is available
  Future<bool> checkAvailability() async {
    return await _healthService.isHealthConnectAvailable();
  }

  /// Request permissions and connect
  Future<bool> connect() async {
    state = state.copyWith(isSyncing: true, error: null);

    try {
      final granted = await _healthService.requestPermissions();
      state = state.copyWith(
        isConnected: granted,
        isSyncing: false,
        error: granted ? null : 'Permissions not granted',
      );
      await _saveSyncState();
      return granted;
    } catch (e) {
      state = state.copyWith(
        isConnected: false,
        isSyncing: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Disconnect from Health Connect
  Future<void> disconnect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('health_last_sync');
    await prefs.setBool('health_connected', false);
    state = const HealthSyncState();
  }

  /// Sync measurements from Health Connect
  Future<List<HealthDataPoint>> syncMeasurements({int days = 30}) async {
    if (!state.isConnected) {
      final connected = await connect();
      if (!connected) return [];
    }

    state = state.copyWith(isSyncing: true, error: null);

    try {
      final data = await _healthService.getMeasurements(days: days);
      state = state.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
        syncedCount: data.length,
      );
      await _saveSyncState();
      return data;
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: e.toString(),
      );
      return [];
    }
  }

  /// Write a measurement to Health Connect
  Future<bool> writeMeasurement({
    required HealthDataType type,
    required double value,
    DateTime? time,
  }) async {
    if (!state.isConnected) return false;

    try {
      return await _healthService.writeMeasurement(
        type: type,
        value: value,
        time: time ?? DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Error writing to Health Connect: $e');
      return false;
    }
  }
}

/// Health data point converted for app use
class AppHealthData {
  final String type;
  final double value;
  final String unit;
  final DateTime dateFrom;
  final DateTime dateTo;
  final String? sourceName;

  AppHealthData({
    required this.type,
    required this.value,
    required this.unit,
    required this.dateFrom,
    required this.dateTo,
    this.sourceName,
  });

  factory AppHealthData.fromHealthDataPoint(HealthDataPoint point) {
    return AppHealthData(
      type: point.type.name,
      value: (point.value as NumericHealthValue).numericValue.toDouble(),
      unit: point.unit.name,
      dateFrom: point.dateFrom,
      dateTo: point.dateTo,
      sourceName: point.sourceName,
    );
  }
}

/// Health service for interacting with Health Connect (Android) / HealthKit (iOS)
class HealthService {
  final Health _health = Health();

  // Data types we want to read from Health Connect
  static final List<HealthDataType> _readTypes = [
    // Body measurements
    HealthDataType.WEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.HEIGHT,
    HealthDataType.BODY_MASS_INDEX,

    // Heart
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.HEART_RATE_VARIABILITY_SDNN,

    // Activity
    HealthDataType.STEPS,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.TOTAL_CALORIES_BURNED,

    // Vitals
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,

    // Sleep
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_IN_BED,

    // Diabetic metrics (Blood glucose & insulin)
    HealthDataType.BLOOD_GLUCOSE,
    HealthDataType.INSULIN_DELIVERY,
  ];

  // Data types we want to write to Health Connect
  static final List<HealthDataType> _writeTypes = [
    HealthDataType.WEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.HEIGHT,
    HealthDataType.WORKOUT,
  ];

  /// Check if Health Connect is available on the device
  Future<bool> isHealthConnectAvailable() async {
    try {
      if (Platform.isAndroid) {
        final status = await _health.getHealthConnectSdkStatus();
        return status == HealthConnectSdkStatus.sdkAvailable;
      } else if (Platform.isIOS) {
        // HealthKit is always available on iOS (if device supports it)
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error checking Health Connect availability: $e');
      return false;
    }
  }

  /// Check if we have permissions to read health data.
  /// This verifies actual permissions by checking authorization status.
  Future<bool> hasHealthPermissions() async {
    try {
      // Configure the health plugin first
      await _health.configure();

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

      // If hasPermissions returns false or null, try to actually read some data
      // This is a fallback check - if we can read data, we have permissions
      if (hasAuth == null) {
        try {
          final now = DateTime.now();
          final start = now.subtract(const Duration(hours: 1));
          final data = await _health.getHealthDataFromTypes(
            startTime: start,
            endTime: now,
            types: types,
          );
          // If we get here without error, we have permissions
          debugPrint('🏥 Health permissions verified via data read: granted (${data.length} points)');
          return true;
        } catch (e) {
          debugPrint('🏥 Health data read failed, assuming no permissions: $e');
          return false;
        }
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
      // Configure the health plugin
      await _health.configure();

      // Get available types for this platform
      final availableReadTypes = _getAvailableTypes(_readTypes);
      final availableWriteTypes = _getAvailableTypes(_writeTypes);

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
      return granted;
    } catch (e) {
      debugPrint('❌ Error requesting health permissions: $e');
      return false;
    }
  }

  /// Get health data types available on current platform
  List<HealthDataType> _getAvailableTypes(List<HealthDataType> types) {
    // Filter types based on platform availability
    return types.where((type) {
      try {
        // This will throw if type is not available
        return true;
      } catch (e) {
        return false;
      }
    }).toList();
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

      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: [
          HealthDataType.STEPS,
          HealthDataType.ACTIVE_ENERGY_BURNED,
          HealthDataType.DISTANCE_DELTA,
        ],
      );

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

// ============================================
// Diabetic Data Models
// ============================================

/// Blood glucose reading from Health Connect
class BloodGlucoseReading {
  final double value;
  final String unit;
  final DateTime recordedAt;
  final String source;
  final String? mealContext;
  final String? notes;

  const BloodGlucoseReading({
    required this.value,
    required this.unit,
    required this.recordedAt,
    required this.source,
    this.mealContext,
    this.notes,
  });

  /// Get status based on glucose level
  GlucoseStatus get status {
    if (value < 70) return GlucoseStatus.low;
    if (value <= 100) return GlucoseStatus.normal;
    if (value <= 125) return GlucoseStatus.elevated;
    if (value <= 180) return GlucoseStatus.high;
    return GlucoseStatus.veryHigh;
  }

  /// Get display color based on status
  String get statusColor {
    switch (status) {
      case GlucoseStatus.low:
        return 'red';
      case GlucoseStatus.normal:
        return 'green';
      case GlucoseStatus.elevated:
        return 'yellow';
      case GlucoseStatus.high:
        return 'orange';
      case GlucoseStatus.veryHigh:
        return 'red';
    }
  }
}

/// Glucose status levels
enum GlucoseStatus {
  low,       // < 70 mg/dL - Hypoglycemia
  normal,    // 70-100 mg/dL - Normal fasting
  elevated,  // 100-125 mg/dL - Pre-diabetes range
  high,      // 126-180 mg/dL - Diabetes range
  veryHigh,  // > 180 mg/dL - Very high
}

/// Insulin dose record
class InsulinDose {
  final double units;
  final DateTime deliveredAt;
  final String source;
  final String insulinType; // 'rapid', 'short', 'intermediate', 'long', 'unknown'
  final String? notes;

  const InsulinDose({
    required this.units,
    required this.deliveredAt,
    required this.source,
    required this.insulinType,
    this.notes,
  });
}

/// Daily blood glucose summary
class BloodGlucoseSummary {
  final DateTime date;
  final int readingCount;
  final double averageGlucose;
  final double minGlucose;
  final double maxGlucose;
  final double timeInRange;     // Percentage
  final double timeAboveRange;  // Percentage
  final double timeBelowRange;  // Percentage

  const BloodGlucoseSummary({
    required this.date,
    required this.readingCount,
    required this.averageGlucose,
    required this.minGlucose,
    required this.maxGlucose,
    required this.timeInRange,
    required this.timeAboveRange,
    required this.timeBelowRange,
  });

  factory BloodGlucoseSummary.empty({required DateTime date}) {
    return BloodGlucoseSummary(
      date: date,
      readingCount: 0,
      averageGlucose: 0,
      minGlucose: 0,
      maxGlucose: 0,
      timeInRange: 0,
      timeAboveRange: 0,
      timeBelowRange: 0,
    );
  }

  bool get hasData => readingCount > 0;

  /// Get overall glucose control status
  String get controlStatus {
    if (!hasData) return 'No data';
    if (timeInRange >= 70) return 'Excellent';
    if (timeInRange >= 50) return 'Good';
    if (timeInRange >= 30) return 'Needs improvement';
    return 'Poor control';
  }
}
