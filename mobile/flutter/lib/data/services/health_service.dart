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
  final int? sleepMinutes;
  final int? deepSleepMinutes;
  final int? remSleepMinutes;
  final DateTime date;
  final bool isFromHealthConnect;
  final bool isFromWatch;
  final int? avgHeartRate;
  final int? maxHeartRate;
  final double? hrv;              // RMSSD (Android) or SDNN (iOS)
  final double? bloodOxygen;      // SpO2 %
  final double? bodyTemperature;  // Celsius
  final int? respiratoryRate;     // breaths/min
  final int? flightsClimbed;
  final double? basalCalories;    // BMR calories
  final int? lightSleepMinutes;
  final int? awakeSleepMinutes;   // time awake during sleep
  final int? waterMl;             // hydration in ml

  const DailyActivity({
    this.steps = 0,
    this.caloriesBurned = 0,
    this.distanceMeters = 0,
    this.restingHeartRate,
    this.sleepMinutes,
    this.deepSleepMinutes,
    this.remSleepMinutes,
    required this.date,
    this.isFromHealthConnect = false,
    this.isFromWatch = false,
    this.avgHeartRate,
    this.maxHeartRate,
    this.hrv,
    this.bloodOxygen,
    this.bodyTemperature,
    this.respiratoryRate,
    this.flightsClimbed,
    this.basalCalories,
    this.lightSleepMinutes,
    this.awakeSleepMinutes,
    this.waterMl,
  });

  /// Distance in kilometers
  double get distanceKm => distanceMeters / 1000;

  /// Distance in miles
  double get distanceMiles => distanceMeters / 1609.344;
}

/// Sleep data summary
class SleepSummary {
  final int totalMinutes;
  final int deepMinutes;
  final int remMinutes;
  final int lightMinutes;
  final int awakeMinutes;
  final DateTime? bedTime;
  final DateTime? wakeTime;

  const SleepSummary({
    this.totalMinutes = 0,
    this.deepMinutes = 0,
    this.remMinutes = 0,
    this.lightMinutes = 0,
    this.awakeMinutes = 0,
    this.bedTime,
    this.wakeTime,
  });

  /// Sleep quality based on duration and composition
  /// <6h = poor, 6-7h = fair, 7-8h = good, 8+ = excellent
  /// Bonus tier if >20% deep sleep
  String get quality {
    final hours = totalMinutes / 60.0;
    String base;
    if (hours < 6) {
      base = 'poor';
    } else if (hours < 7) {
      base = 'fair';
    } else if (hours < 8) {
      base = 'good';
    } else {
      base = 'excellent';
    }

    // Bonus for deep sleep composition
    if (totalMinutes > 0 && deepMinutes / totalMinutes > 0.20) {
      if (base == 'poor') return 'fair';
      if (base == 'fair') return 'good';
      if (base == 'good') return 'excellent';
    }
    return base;
  }

  bool get hasData => totalMinutes > 0;
}

/// Recovery metrics from Health Connect
class RecoveryMetrics {
  final int? restingHR;
  final double? hrv;
  final double? bloodOxygen;

  const RecoveryMetrics({
    this.restingHR,
    this.hrv,
    this.bloodOxygen,
  });

  bool get hasData => restingHR != null || hrv != null || bloodOxygen != null;
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
      final sleepData = await _healthService.getSleepData(days: 1);
      final vitalsData = await _healthService.getTodayVitals();

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
        sleepMinutes: sleepData.hasData ? sleepData.totalMinutes : null,
        deepSleepMinutes: sleepData.hasData ? sleepData.deepMinutes : null,
        remSleepMinutes: sleepData.hasData ? sleepData.remMinutes : null,
        date: DateTime.now(),
        isFromHealthConnect: true,
        avgHeartRate: vitalsData['avgHeartRate'] as int?,
        maxHeartRate: vitalsData['maxHeartRate'] as int?,
        hrv: vitalsData['hrv'] as double?,
        bloodOxygen: vitalsData['bloodOxygen'] as double?,
        bodyTemperature: vitalsData['bodyTemperature'] as double?,
        respiratoryRate: vitalsData['respiratoryRate'] as int?,
        flightsClimbed: vitalsData['flightsClimbed'] as int?,
        basalCalories: vitalsData['basalCalories'] as double?,
        lightSleepMinutes: sleepData.hasData ? sleepData.lightMinutes : null,
        awakeSleepMinutes: sleepData.hasData && sleepData.awakeMinutes > 0 ? sleepData.awakeMinutes : null,
        waterMl: vitalsData['waterMl'] as int?,
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

  /// Update activity data from watch.
  /// Watch data takes priority when available since it's more accurate.
  void updateFromWatch({
    int? steps,
    int? heartRate,
    int? caloriesBurned,
    int? activeMinutes,
  }) {
    final current = state.today;

    // Merge watch data with current state
    // Watch data takes priority (it's usually more accurate when worn)
    final updated = DailyActivity(
      steps: steps ?? current?.steps ?? 0,
      caloriesBurned: caloriesBurned?.toDouble() ?? current?.caloriesBurned ?? 0,
      distanceMeters: current?.distanceMeters ?? 0, // Keep existing, watch doesn't send this
      restingHeartRate: heartRate ?? current?.restingHeartRate,
      sleepMinutes: current?.sleepMinutes,
      deepSleepMinutes: current?.deepSleepMinutes,
      remSleepMinutes: current?.remSleepMinutes,
      date: DateTime.now(),
      isFromHealthConnect: current?.isFromHealthConnect ?? false,
      isFromWatch: true, // Mark that we have watch data
      avgHeartRate: current?.avgHeartRate,
      maxHeartRate: current?.maxHeartRate,
      hrv: current?.hrv,
      bloodOxygen: current?.bloodOxygen,
      bodyTemperature: current?.bodyTemperature,
      respiratoryRate: current?.respiratoryRate,
      flightsClimbed: current?.flightsClimbed,
      basalCalories: current?.basalCalories,
      lightSleepMinutes: current?.lightSleepMinutes,
      awakeSleepMinutes: current?.awakeSleepMinutes,
      waterMl: current?.waterMl,
    );

    state = state.copyWith(today: updated);
    debugPrint('⌚ [Activity] Updated from watch: $steps steps, ${heartRate}bpm, ${caloriesBurned}cal');

    // Sync to Supabase in the background
    _syncToSupabase(updated);
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
  ///
  /// IMPORTANT: We only *upgrade* isConnected (false -> true) based on
  /// hasPermissions(), never *downgrade* (true -> false). The hasPermissions
  /// API on Android is unreliable and can return false even when permissions
  /// ARE granted, which causes the Health Connect popup to reappear.
  /// We only revoke isConnected when an actual data-read fails with a
  /// permission error (handled in loadTodayActivity and other read methods).
  Future<void> _verifyAndUpdateConnectionStatus() async {
    try {
      // Check if Health Connect is available first
      final available = await _healthService.isHealthConnectAvailable();
      if (!available) {
        debugPrint('🏥 Health Connect not available on this device');
        return;
      }

      // Try to check if we have permissions
      final hasPermissions = await _healthService.hasHealthPermissions();

      if (hasPermissions && !state.isConnected) {
        // User granted permissions outside the app - upgrade our state
        debugPrint('🏥 Health Connect permissions detected (granted externally), updating state');
        state = state.copyWith(isConnected: true);
        await _saveSyncState();
      }
      // NOTE: We intentionally do NOT downgrade isConnected to false here.
      // Android's hasPermissions() API is unreliable and can return false
      // even when permissions are still granted. Trust the stored flag.
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

  /// Write a completed workout to Health Connect / HealthKit.
  Future<bool> writeWorkoutToHealth({
    required String workoutType,
    required DateTime startTime,
    required DateTime endTime,
    int? totalCaloriesBurned,
    String? title,
  }) async {
    if (!state.isConnected) return false;

    try {
      return await _healthService.writeWorkoutSession(
        workoutType: workoutType,
        startTime: startTime,
        endTime: endTime,
        totalCaloriesBurned: totalCaloriesBurned,
        title: title,
      );
    } catch (e) {
      debugPrint('❌ Error writing workout to Health: $e');
      return false;
    }
  }

  /// Write a meal to Health Connect / HealthKit.
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
    if (!state.isConnected) return false;

    try {
      return await _healthService.writeMealToHealth(
        mealType: mealType,
        loggedAt: loggedAt,
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
      debugPrint('❌ Error writing meal to Health: $e');
      return false;
    }
  }

  /// Write hydration / water intake to Health Connect / HealthKit.
  Future<bool> writeHydrationToHealth({
    required int amountMl,
    DateTime? time,
  }) async {
    if (!state.isConnected) return false;

    try {
      return await _healthService.writeHydrationToHealth(
        amountMl: amountMl,
        time: time,
      );
    } catch (e) {
      debugPrint('❌ Error writing hydration to Health: $e');
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
  bool _isConfigured = false;

  /// Ensure the health plugin is configured. Only calls configure() once.
  Future<void> _ensureConfigured() async {
    if (!_isConfigured) {
      await _health.configure();
      _isConfigured = true;
    }
  }

  // Data types we want to read from Health Connect
  static final List<HealthDataType> _readTypes = [
    // Body measurements
    HealthDataType.WEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.HEIGHT,
    HealthDataType.BODY_MASS_INDEX,
    HealthDataType.BODY_TEMPERATURE,
    HealthDataType.BODY_WATER_MASS,

    // Heart
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.HEART_RATE_VARIABILITY_SDNN,
    HealthDataType.HEART_RATE_VARIABILITY_RMSSD,

    // Activity
    HealthDataType.STEPS,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.BASAL_ENERGY_BURNED,
    HealthDataType.FLIGHTS_CLIMBED,

    // Workout
    HealthDataType.WORKOUT,

    // Vitals
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.RESPIRATORY_RATE,

    // Sleep
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_AWAKE_IN_BED,
    HealthDataType.SLEEP_OUT_OF_BED,
    HealthDataType.SLEEP_SESSION,

    // Hydration
    HealthDataType.WATER,

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
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.NUTRITION,
    HealthDataType.WATER,
  ];

  /// Check if Health Connect is available on the device
  Future<bool> isHealthConnectAvailable() async {
    try {
      await _ensureConfigured();
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
  };

  // Types that are only available on Android (not supported on iOS)
  static const Set<HealthDataType> _androidOnlyTypes = {
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_REM,
    HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
    HealthDataType.BODY_WATER_MASS,
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

      final rawData = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: [
          HealthDataType.STEPS,
          HealthDataType.ACTIVE_ENERGY_BURNED,
          HealthDataType.DISTANCE_DELTA,
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
  // Sleep Data
  // ============================================

  /// Get sleep data summary for recent nights
  Future<SleepSummary> getSleepData({int days = 1}) async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));

      // Fetch all sleep-related types
      final sleepTypes = _getAvailableTypes([
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_LIGHT,
        HealthDataType.SLEEP_REM,
        HealthDataType.SLEEP_AWAKE,
        HealthDataType.SLEEP_AWAKE_IN_BED,
      ]);

      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: sleepTypes,
      );

      final uniqueData = _health.removeDuplicates(data);

      int totalMinutes = 0;
      int deepMinutes = 0;
      int remMinutes = 0;
      int lightMinutes = 0;
      int awakeMinutes = 0;
      DateTime? earliestBed;
      DateTime? latestWake;

      for (final point in uniqueData) {
        final durationMin = point.dateTo.difference(point.dateFrom).inMinutes;
        switch (point.type) {
          case HealthDataType.SLEEP_ASLEEP:
            totalMinutes += durationMin;
            break;
          case HealthDataType.SLEEP_DEEP:
            deepMinutes += durationMin;
            break;
          case HealthDataType.SLEEP_REM:
            remMinutes += durationMin;
            break;
          case HealthDataType.SLEEP_LIGHT:
            lightMinutes += durationMin;
            break;
          case HealthDataType.SLEEP_AWAKE:
          case HealthDataType.SLEEP_AWAKE_IN_BED:
            awakeMinutes += durationMin;
            break;
          default:
            break;
        }

        // Track bed/wake times
        if (earliestBed == null || point.dateFrom.isBefore(earliestBed)) {
          earliestBed = point.dateFrom;
        }
        if (latestWake == null || point.dateTo.isAfter(latestWake)) {
          latestWake = point.dateTo;
        }
      }

      // If we only have stage breakdown but no SLEEP_ASLEEP total, sum the stages
      if (totalMinutes == 0 && (deepMinutes > 0 || remMinutes > 0 || lightMinutes > 0)) {
        totalMinutes = deepMinutes + remMinutes + lightMinutes;
      }

      // Include awake minutes in total if SLEEP_ASLEEP was 0 (some devices report only stages)
      if (totalMinutes == 0 && awakeMinutes > 0) {
        totalMinutes = awakeMinutes;
      }

      debugPrint('😴 Sleep data: ${totalMinutes}min total, ${deepMinutes}min deep, ${remMinutes}min REM, ${lightMinutes}min light, ${awakeMinutes}min awake');
      return SleepSummary(
        totalMinutes: totalMinutes,
        deepMinutes: deepMinutes,
        remMinutes: remMinutes,
        lightMinutes: lightMinutes,
        awakeMinutes: awakeMinutes,
        bedTime: earliestBed,
        wakeTime: latestWake,
      );
    } catch (e) {
      debugPrint('❌ Error getting sleep data: $e');
      return const SleepSummary();
    }
  }

  // ============================================
  // Recovery Metrics
  // ============================================

  /// Get recovery metrics (resting HR, HRV, SpO2) in parallel
  Future<RecoveryMetrics> getRecoveryMetrics() async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 1));

      final types = _getAvailableTypes([
        HealthDataType.RESTING_HEART_RATE,
        HealthDataType.HEART_RATE_VARIABILITY_SDNN,
        HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
        HealthDataType.BLOOD_OXYGEN,
      ]);

      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: types,
      );

      final uniqueData = _health.removeDuplicates(data);

      int? restingHR;
      double? hrv;
      double? bloodOxygen;

      // Get the most recent value for each type
      for (final point in uniqueData) {
        final value = (point.value as NumericHealthValue).numericValue.toDouble();
        switch (point.type) {
          case HealthDataType.RESTING_HEART_RATE:
            restingHR ??= value.toInt();
            break;
          case HealthDataType.HEART_RATE_VARIABILITY_SDNN:
          case HealthDataType.HEART_RATE_VARIABILITY_RMSSD:
            hrv ??= value;
            break;
          case HealthDataType.BLOOD_OXYGEN:
            bloodOxygen ??= value;
            break;
          default:
            break;
        }
      }

      debugPrint('💚 Recovery: HR=$restingHR, HRV=$hrv, SpO2=$bloodOxygen');
      return RecoveryMetrics(
        restingHR: restingHR,
        hrv: hrv,
        bloodOxygen: bloodOxygen,
      );
    } catch (e) {
      debugPrint('❌ Error getting recovery metrics: $e');
      return const RecoveryMetrics();
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

  /// Get today's vitals data (HRV, SpO2, body temp, respiratory rate, basal cal, flights, water)
  Future<Map<String, dynamic>> getTodayVitals() async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      final types = _getAvailableTypes([
        HealthDataType.HEART_RATE,
        HealthDataType.HEART_RATE_VARIABILITY_SDNN,
        HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
        HealthDataType.BLOOD_OXYGEN,
        HealthDataType.BODY_TEMPERATURE,
        HealthDataType.RESPIRATORY_RATE,
        HealthDataType.BASAL_ENERGY_BURNED,
        HealthDataType.FLIGHTS_CLIMBED,
        HealthDataType.WATER,
      ]);

      final data = await _health.getHealthDataFromTypes(
        startTime: midnight,
        endTime: now,
        types: types,
      );

      final uniqueData = _health.removeDuplicates(data);

      int heartRateSum = 0;
      int heartRateCount = 0;
      int maxHeartRate = 0;
      double? hrv;
      double? bloodOxygen;
      double? bodyTemperature;
      int? respiratoryRate;
      double basalCalories = 0;
      int flightsClimbed = 0;
      double waterMl = 0;

      for (final point in uniqueData) {
        final value = (point.value as NumericHealthValue).numericValue.toDouble();
        switch (point.type) {
          case HealthDataType.HEART_RATE:
            heartRateSum += value.toInt();
            heartRateCount++;
            if (value.toInt() > maxHeartRate) maxHeartRate = value.toInt();
            break;
          case HealthDataType.HEART_RATE_VARIABILITY_SDNN:
          case HealthDataType.HEART_RATE_VARIABILITY_RMSSD:
            hrv ??= value;
            break;
          case HealthDataType.BLOOD_OXYGEN:
            bloodOxygen ??= value;
            break;
          case HealthDataType.BODY_TEMPERATURE:
            bodyTemperature ??= value;
            break;
          case HealthDataType.RESPIRATORY_RATE:
            respiratoryRate ??= value.toInt();
            break;
          case HealthDataType.BASAL_ENERGY_BURNED:
            basalCalories += value;
            break;
          case HealthDataType.FLIGHTS_CLIMBED:
            flightsClimbed += value.toInt();
            break;
          case HealthDataType.WATER:
            waterMl += value;
            break;
          default:
            break;
        }
      }

      return {
        'avgHeartRate': heartRateCount > 0 ? heartRateSum ~/ heartRateCount : null,
        'maxHeartRate': maxHeartRate > 0 ? maxHeartRate : null,
        'hrv': hrv,
        'bloodOxygen': bloodOxygen,
        'bodyTemperature': bodyTemperature,
        'respiratoryRate': respiratoryRate,
        'basalCalories': basalCalories > 0 ? basalCalories : null,
        'flightsClimbed': flightsClimbed > 0 ? flightsClimbed : null,
        'waterMl': waterMl > 0 ? waterMl.toInt() : null,
      };
    } catch (e) {
      debugPrint('❌ Error getting today vitals: $e');
      return {};
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
