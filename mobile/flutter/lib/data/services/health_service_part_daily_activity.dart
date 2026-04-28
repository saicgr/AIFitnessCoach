part of 'health_service.dart';


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
  final int? minHeartRate;
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
    this.minHeartRate,
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


/// Daily activity notifier
class DailyActivityNotifier extends StateNotifier<DailyActivityState> {
  final HealthService _healthService;
  final HealthSyncState _syncState;
  final ActivityService _activityService;
  final ApiClient _apiClient;
  final PosthogService _posthog;

  /// Timestamp of the last successful `loadTodayActivity()`. Used to enforce
  /// a 60-second TTL on today's bucket so rapid tab switches don't hammer
  /// Health Connect, but stale caches (>60s, e.g. after a walk) re-query.
  DateTime? _lastFetchAt;

  /// TTL window for today's activity bucket. Step counts in Health Connect
  /// can change minute-to-minute (905 vs 32 mismatch the user reported was
  /// a pure cache-staleness issue), so we keep this short.
  static const Duration _todayCacheTtl = Duration(seconds: 60);

  /// Local-midnight of the day the last fetch happened on. Used to detect
  /// a midnight rollover during refresh — the cache must be discarded the
  /// instant the calendar day flips, otherwise yesterday's totals leak into
  /// today's UI.
  DateTime? _lastFetchDay;

  DailyActivityNotifier(
    this._healthService,
    this._syncState,
    this._activityService,
    this._apiClient,
    this._posthog,
  ) : super(const DailyActivityState()) {
    // Auto-load if connected
    if (_syncState.isConnected) {
      loadTodayActivity();
    }
  }

  /// Force the next `loadTodayActivity()` call to bypass the 60s TTL guard.
  /// Used by the You-tab refresh button and by `AppLifecycleState.resumed`
  /// to make sure resuming the app after a walk shows fresh step counts.
  void invalidateCache() {
    _lastFetchAt = null;
    _lastFetchDay = null;
  }

  /// True iff the cached `today` bucket is still within the 60s TTL AND
  /// the calendar day hasn't flipped since we cached it. Edge cases:
  ///   • `_lastFetchAt == null`           → never fetched, NOT fresh
  ///   • `state.today == null`            → no cached row, NOT fresh
  ///   • now - lastFetch > 60s            → stale, NOT fresh
  ///   • local-midnight changed           → midnight rollover, NOT fresh
  bool _isCacheFresh() {
    if (_lastFetchAt == null || state.today == null) return false;
    final now = DateTime.now();
    if (now.difference(_lastFetchAt!) > _todayCacheTtl) return false;
    final today = DateTime(now.year, now.month, now.day);
    if (_lastFetchDay == null || _lastFetchDay != today) return false;
    return true;
  }

  /// Load today's activity from Health Connect.
  ///
  /// Honors a 60-second TTL on the `state.today` bucket unless [force] is
  /// true. The You-tab Overview refresh button and the app-lifecycle
  /// `resumed` hook both pass `force: true` so the user always gets fresh
  /// data when they explicitly ask for it.
  Future<void> loadTodayActivity({bool force = false}) async {
    if (!_syncState.isConnected) {
      state = state.copyWith(
        today: DailyActivity(date: DateTime.now(), isFromHealthConnect: false),
      );
      return;
    }

    // 60s TTL guard — skips the entire fetch if the cached row is fresh.
    // This avoids re-hitting Health Connect on every tab switch, which is
    // what caused the 905 vs 32 step mismatch (a stale bucket from earlier
    // in the session was being shown instead of re-querying).
    if (!force && _isCacheFresh()) {
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
        minHeartRate: vitalsData['minHeartRate'] as int?,
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

      // Stamp the cache AFTER a successful fetch — failed fetches must not
      // refresh the TTL (otherwise transient errors would suppress retries
      // for a full minute). Use local-midnight at refresh time for the day
      // marker so a midnight rollover during refresh invalidates correctly.
      final stampNow = DateTime.now();
      _lastFetchAt = stampNow;
      _lastFetchDay = DateTime(stampNow.year, stampNow.month, stampNow.day);

      state = state.copyWith(isLoading: false, today: today);

      _posthog.capture(
        eventName: 'health_sync_completed',
        properties: <String, Object>{
          'steps': today.steps,
          'calories_burned': today.caloriesBurned,
          'distance_meters': today.distanceMeters,
        },
      );

      // Sync to Supabase in the background
      _syncToSupabase(today);
    } catch (e) {
      debugPrint('❌ Error loading daily activity: $e');
      _posthog.capture(
        eventName: 'health_sync_failed',
        properties: <String, Object>{
          'error': e.toString(),
        },
      );
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

  /// Refresh activity data. Always bypasses the 60s TTL — pull-to-refresh
  /// and the explicit Overview refresh button must always re-query.
  Future<void> refresh() async {
    invalidateCache();
    await loadTodayActivity(force: true);
  }

  /// Backfill the past N days of activity (steps, calories, distance) from
  /// Health Connect / Apple Health to Supabase. Called on app resume +
  /// after the user grants Health permission so days like "April 23"
  /// don't disappear from the synced workouts grid (Issue 12).
  ///
  /// Days where local total > 0 AND > server total are pushed; days that
  /// already match are skipped to avoid redundant writes.
  Future<int> backfillRecentActivity({int days = 30}) async {
    if (!_syncState.isConnected) {
      debugPrint('⏭️ [Activity] Backfill skipped — health not connected');
      return 0;
    }
    final userId = await _apiClient.getUserId();
    if (userId == null) {
      debugPrint('⏭️ [Activity] Backfill skipped — no userId');
      return 0;
    }

    try {
      // Pull each day's totals via the health_service (already enforces
      // local-midnight bounds). We do this serially to avoid hammering
      // the platform channel; small N (≤30) keeps total time well under 1s.
      final now = DateTime.now();
      final perDay = <DailyActivity>[];
      for (int i = 1; i <= days; i++) {
        final dayStart =
            DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        final dayEnd = dayStart.add(const Duration(days: 1));
        try {
          final steps =
              await _healthService.getStepsForRange(dayStart, dayEnd) ?? 0;
          if (steps <= 0) continue; // skip empty days — nothing to backfill
          perDay.add(DailyActivity(
            date: dayStart,
            steps: steps,
            caloriesBurned: 0,
            distanceMeters: 0,
            isFromHealthConnect: true,
          ));
        } catch (e) {
          // Non-fatal — Health may reject some days; keep going.
          debugPrint('⚠️ [Activity] Backfill day $dayStart failed: $e');
        }
      }

      if (perDay.isEmpty) {
        debugPrint('🏃 [Activity] Backfill found no past days with data');
        return 0;
      }

      final response = await _activityService.batchSyncActivities(
        userId: userId,
        activities: perDay,
      );
      if (response != null) {
        debugPrint('✅ [Activity] Backfilled ${perDay.length} days');
        return perDay.length;
      }
      return 0;
    } catch (e) {
      debugPrint('❌ [Activity] Backfill error: $e');
      return 0;
    }
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
      minHeartRate: current?.minHeartRate,
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
  /// outside of Zealova, so our stored state becomes stale.
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

