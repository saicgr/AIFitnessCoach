part of 'health_service.dart';


/// Daily activity data.
///
/// The following fields were removed 2026-05-07 to comply with Google Play's
/// Health Connect "Minimum Scope" policy (and dropped on iOS per the same
/// product decision):
///   distanceMeters / distanceKm / distanceMiles, hrv, bloodOxygen,
///   bodyTemperature, respiratoryRate, flightsClimbed, basalCalories.
/// Distance for cardio workouts is still tracked through the cardio session
/// pipeline (manual entry / Strava / Garmin / direct watch sync), which is
/// independent of Health Connect.
class DailyActivity {
  final int steps;
  final double caloriesBurned;
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
  final int? lightSleepMinutes;
  final int? awakeSleepMinutes;   // time awake during sleep
  final int? waterMl;             // hydration in ml
  final int? activeMinutes;       // active/exercise minutes (watch-synced)
  final DateTime? sleepStart;     // bed time — earliest stage/session start
  final DateTime? sleepEnd;       // wake time — latest stage/session end
  final int? sleepLatencyMinutes; // minutes from getting into bed to first asleep stage
  final double? sleepEfficiency;  // 0.0-1.0 = total asleep / time-in-bed

  const DailyActivity({
    this.steps = 0,
    this.caloriesBurned = 0,
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
    this.lightSleepMinutes,
    this.awakeSleepMinutes,
    this.waterMl,
    this.activeMinutes,
    this.sleepStart,
    this.sleepEnd,
    this.sleepLatencyMinutes,
    this.sleepEfficiency,
  });

  /// Lossless serialization for the SharedPreferences disk cache so the Home
  /// activity/steps metric paints last-known values instantly on a connected
  /// cold start while Health Connect / HealthKit is still being queried. Keys
  /// are self-contained (not the backend `daily_activity` wire shape) and
  /// cover EVERY field so a round-trip never drops a metric.
  Map<String, dynamic> toJson() => {
        'steps': steps,
        'calories_burned': caloriesBurned,
        'resting_heart_rate': restingHeartRate,
        'sleep_minutes': sleepMinutes,
        'deep_sleep_minutes': deepSleepMinutes,
        'rem_sleep_minutes': remSleepMinutes,
        'date': date.toIso8601String(),
        'is_from_health_connect': isFromHealthConnect,
        'is_from_watch': isFromWatch,
        'avg_heart_rate': avgHeartRate,
        'max_heart_rate': maxHeartRate,
        'min_heart_rate': minHeartRate,
        'light_sleep_minutes': lightSleepMinutes,
        'awake_sleep_minutes': awakeSleepMinutes,
        'water_ml': waterMl,
        'active_minutes': activeMinutes,
        'sleep_start': sleepStart?.toIso8601String(),
        'sleep_end': sleepEnd?.toIso8601String(),
        'sleep_latency_minutes': sleepLatencyMinutes,
        'sleep_efficiency': sleepEfficiency,
      };

  factory DailyActivity.fromJson(Map<String, dynamic> json) => DailyActivity(
        steps: json['steps'] as int? ?? 0,
        caloriesBurned: (json['calories_burned'] as num?)?.toDouble() ?? 0,
        restingHeartRate: json['resting_heart_rate'] as int?,
        sleepMinutes: json['sleep_minutes'] as int?,
        deepSleepMinutes: json['deep_sleep_minutes'] as int?,
        remSleepMinutes: json['rem_sleep_minutes'] as int?,
        date: DateTime.parse(json['date'] as String),
        isFromHealthConnect: json['is_from_health_connect'] as bool? ?? false,
        isFromWatch: json['is_from_watch'] as bool? ?? false,
        avgHeartRate: json['avg_heart_rate'] as int?,
        maxHeartRate: json['max_heart_rate'] as int?,
        minHeartRate: json['min_heart_rate'] as int?,
        lightSleepMinutes: json['light_sleep_minutes'] as int?,
        awakeSleepMinutes: json['awake_sleep_minutes'] as int?,
        waterMl: json['water_ml'] as int?,
        activeMinutes: json['active_minutes'] as int?,
        sleepStart: json['sleep_start'] != null
            ? DateTime.tryParse(json['sleep_start'] as String)
            : null,
        sleepEnd: json['sleep_end'] != null
            ? DateTime.tryParse(json['sleep_end'] as String)
            : null,
        sleepLatencyMinutes: json['sleep_latency_minutes'] as int?,
        sleepEfficiency: (json['sleep_efficiency'] as num?)?.toDouble(),
      );
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

  /// Total time inside the session envelope(s) — asleep + awake-in-bed.
  /// Summed across the kept sessions (after the multi-source overlap
  /// pre-pass drops duplicate-night sessions). Null when no session
  /// contributed an envelope or stage span at all.
  final int? timeInBedMinutes;

  /// Sleep efficiency 0.0-1.0 = total asleep minutes / time-in-bed minutes.
  /// Null when time-in-bed is unknown or zero (can't divide).
  final double? efficiency;

  /// Sleep latency — minutes from the start of the session to the first
  /// ASLEEP/DEEP/LIGHT/REM stage. When several sessions are kept, this is
  /// the longest kept session's latency. Null when it can't be computed
  /// (no staged asleep point, or no known session start).
  final int? latencyMinutes;

  const SleepSummary({
    this.totalMinutes = 0,
    this.deepMinutes = 0,
    this.remMinutes = 0,
    this.lightMinutes = 0,
    this.awakeMinutes = 0,
    this.bedTime,
    this.wakeTime,
    this.timeInBedMinutes,
    this.efficiency,
    this.latencyMinutes,
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


/// One night of sleep, split into a main sleep + any daytime naps.
///
/// A "night" is keyed by its WAKE date — the local calendar date the
/// longest (main) session ended on — so a sleep that crosses midnight
/// (e.g. 11pm Mon -> 6am Tue) is filed under Tuesday. The [mainSleep] is
/// the longest session of that night; every other session of the same
/// wake date is a [nap]. [totalAsleepMinutes] is the sum of asleep
/// minutes across the main sleep and all naps.
class DailySleep {
  /// The wake date this night is filed under (local calendar date, time
  /// component zeroed).
  final DateTime date;

  /// The night's primary sleep — the longest session of the night.
  final SleepSummary mainSleep;

  /// Daytime / secondary sleeps of the same wake date, longest first.
  final List<SleepSummary> naps;

  /// Asleep minutes across the main sleep AND every nap.
  final int totalAsleepMinutes;

  const DailySleep({
    required this.date,
    required this.mainSleep,
    required this.naps,
    required this.totalAsleepMinutes,
  });

  bool get hasData => totalAsleepMinutes > 0;
}


/// Recovery metrics from Health Connect / HealthKit.
///
/// `hrv` and `bloodOxygen` removed 2026-05-07 — Google Play Health Connect
/// minimum-scope policy required dropping those permissions on Android, and
/// per the same product decision they were dropped on iOS too.
class RecoveryMetrics {
  final int? restingHR;

  const RecoveryMetrics({
    this.restingHR,
  });

  bool get hasData => restingHR != null;
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

  /// Disclosed App Store / Play reviewer demo flag. True ONLY for the
  /// reviewer account in `demoHealthModeProvider`'s allowlist. When true,
  /// `loadTodayActivity` sources today's row from the seeded backend data
  /// (`ActivityService.getTodayActivity`) instead of the platform Health
  /// store. For every real account this is false and the load path is
  /// byte-identical to before.
  final bool _demoMode;

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
    this._demoMode,
  ) : super(const DailyActivityState()) {
    // Auto-load if connected
    if (_syncState.isConnected) {
      // Cache-first: paint last-known steps/activity from disk instantly while
      // the (potentially slow) Health Connect / HealthKit query runs. Only the
      // real platform fetch ever overwrites it — the seed never blocks it.
      _seedFromDisk();
      loadTodayActivity();
    }
  }

  /// Live user id from Supabase's session (never a cached field — JWT-expiry
  /// rule). Scopes the disk cache slot per user.
  String? _liveUserId() {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  /// Seed today's activity from the SharedPreferences disk cache on a cold
  /// start so the Home steps/activity metric isn't blank while Health Connect
  /// is queried. The `dailyActivityKey` envelope is TZ-rollover aware, so a
  /// stale day is rejected by [DataCacheService] automatically.
  Future<void> _seedFromDisk() async {
    try {
      final cached = await DataCacheService.instance.getCached(
        DataCacheService.dailyActivityKey,
        userId: _liveUserId(),
        returnExpiredOnMiss: true,
      );
      if (cached == null || state.today != null) return;
      final today = DailyActivity.fromJson(cached);
      // Only seed if it's actually today's row (defend against a stale
      // envelope the TTL hasn't dropped yet).
      final now = DateTime.now();
      if (today.date.year == now.year &&
          today.date.month == now.month &&
          today.date.day == now.day) {
        state = state.copyWith(today: today);
        debugPrint('⚡ [DailyActivity] Seeded from disk cache');
      }
    } catch (e) {
      debugPrint('⚠️ [DailyActivity] disk seed error: $e');
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

    // Disclosed reviewer demo: source today's activity from the seeded
    // backend row instead of the platform Health store. Reviewers cannot
    // pair a wearable and Health Connect / HealthKit do not run on an
    // emulator, so the real path below would always yield empty for them.
    // This branch is entered ONLY for the allowlisted reviewer account
    // (`demoHealthModeProvider`); every real account skips it entirely.
    if (_demoMode) {
      state = state.copyWith(isLoading: true, error: null);
      try {
        final userId = await _apiClient.getUserId();
        DailyActivity? today;
        if (userId != null) {
          today = await _activityService.getTodayActivity(userId);
        }
        // The most recent seeded `daily_activity` row ends yesterday, so a
        // demo "today" may be absent. Fall back to the latest history row
        // so the cards still render real seeded numbers for the reviewer.
        if (today == null && userId != null) {
          final history = await _activityService.getActivityHistory(
            userId,
            limit: 1,
          );
          if (history.isNotEmpty) today = history.first;
        }
        final stampNow = DateTime.now();
        _lastFetchAt = stampNow;
        _lastFetchDay = DateTime(stampNow.year, stampNow.month, stampNow.day);
        state = state.copyWith(
          isLoading: false,
          today: today ??
              DailyActivity(date: DateTime.now(), isFromHealthConnect: false),
        );
      } catch (e) {
        debugPrint('❌ [Demo] Error loading reviewer demo activity: $e');
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
          today: DailyActivity(date: DateTime.now(), isFromHealthConnect: false),
        );
      }
      return;
    }

    // Only show the loading shimmer when there's nothing cached to paint — a
    // silent revalidation over a disk-seeded `today` must not blank it.
    if (state.today == null) {
      state = state.copyWith(isLoading: true, error: null);
    }

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
        restingHeartRate: restingHR,
        sleepMinutes: sleepData.hasData ? sleepData.totalMinutes : null,
        deepSleepMinutes: sleepData.hasData ? sleepData.deepMinutes : null,
        remSleepMinutes: sleepData.hasData ? sleepData.remMinutes : null,
        date: DateTime.now(),
        isFromHealthConnect: true,
        avgHeartRate: vitalsData['avgHeartRate'] as int?,
        maxHeartRate: vitalsData['maxHeartRate'] as int?,
        minHeartRate: vitalsData['minHeartRate'] as int?,
        lightSleepMinutes: sleepData.hasData ? sleepData.lightMinutes : null,
        awakeSleepMinutes: sleepData.hasData && sleepData.awakeMinutes > 0 ? sleepData.awakeMinutes : null,
        waterMl: vitalsData['waterMl'] as int?,
        sleepStart: sleepData.hasData ? sleepData.bedTime : null,
        sleepEnd: sleepData.hasData ? sleepData.wakeTime : null,
        sleepLatencyMinutes: sleepData.hasData ? sleepData.latencyMinutes : null,
        sleepEfficiency: sleepData.hasData ? sleepData.efficiency : null,
      );

      // Stamp the cache AFTER a successful fetch — failed fetches must not
      // refresh the TTL (otherwise transient errors would suppress retries
      // for a full minute). Use local-midnight at refresh time for the day
      // marker so a midnight rollover during refresh invalidates correctly.
      final stampNow = DateTime.now();
      _lastFetchAt = stampNow;
      _lastFetchDay = DateTime(stampNow.year, stampNow.month, stampNow.day);

      state = state.copyWith(isLoading: false, today: today);

      // Write-through to disk so the next cold start paints instantly.
      unawaited(DataCacheService.instance.cache(
        DataCacheService.dailyActivityKey,
        today.toJson(),
        userId: _liveUserId(),
      ));

      _posthog.capture(
        eventName: 'health_sync_completed',
        properties: <String, Object>{
          'steps': today.steps,
          'calories_burned': today.caloriesBurned,
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
      // Keep any disk-seeded/cached `today` visible on a transient fetch
      // error — only fall back to the empty placeholder when there's nothing
      // to show, so a flaky Health query doesn't wipe last-known steps.
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        today: state.today ??
            DailyActivity(date: DateTime.now(), isFromHealthConnect: false),
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

      // Only sync if there's actual data. Sleep counts as data: a user who
      // opens the app in the morning has 0 steps so far but may have slept
      // 8h — that sleep must still sync, not wait until they walk.
      if (activity.steps == 0 &&
          activity.caloriesBurned == 0 &&
          (activity.sleepMinutes ?? 0) == 0) {
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

      // Sleep is fetched for the WHOLE window ONCE and bucketed by wake
      // date in our own code — NOT per day. A sleep that crosses midnight
      // (11pm Mon -> 6am Tue) overlaps two per-day windows; a per-day
      // `getSleepForRange` loop would either double-count it or file it
      // under the bed day. `getDailySleepByWakeDate` attributes each night
      // to its wake date (the morning it ended) exactly once. Keyed by
      // local-midnight `DateTime`, so `dayStart` is a direct lookup key.
      Map<DateTime, SleepSummary> sleepByDate = const {};
      try {
        sleepByDate =
            await _healthService.getDailySleepByWakeDate(days: days);
      } catch (e) {
        // Non-fatal — a sleep-fetch failure must not abort the steps
        // backfill; days simply get null sleep fields.
        debugPrint('⚠️ [Activity] Backfill sleep fetch failed: $e');
      }

      final perDay = <DailyActivity>[];
      for (int i = 1; i <= days; i++) {
        final dayStart =
            DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        final dayEnd = dayStart.add(const Duration(days: 1));
        try {
          final steps =
              await _healthService.getStepsForRange(dayStart, dayEnd) ?? 0;
          // Sleep attributed to this calendar day by WAKE date — looked up
          // from the single pre-fetched, wake-date-bucketed map.
          final sleep = sleepByDate[dayStart];
          final hasSleep = sleep != null && sleep.hasData;
          // Skip a day only when it has NEITHER steps NOR sleep — a
          // wearable-only sleep night (phone left at home, 0 steps) must
          // still be backfilled.
          if (steps <= 0 && !hasSleep) continue;
          perDay.add(DailyActivity(
            date: dayStart,
            steps: steps,
            caloriesBurned: 0,
            isFromHealthConnect: true,
            sleepMinutes: hasSleep ? sleep.totalMinutes : null,
            deepSleepMinutes: hasSleep ? sleep.deepMinutes : null,
            remSleepMinutes: hasSleep ? sleep.remMinutes : null,
            lightSleepMinutes: hasSleep ? sleep.lightMinutes : null,
            awakeSleepMinutes:
                hasSleep && sleep.awakeMinutes > 0 ? sleep.awakeMinutes : null,
            sleepStart: hasSleep ? sleep.bedTime : null,
            sleepEnd: hasSleep ? sleep.wakeTime : null,
            sleepLatencyMinutes: hasSleep ? sleep.latencyMinutes : null,
            sleepEfficiency: hasSleep ? sleep.efficiency : null,
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
      lightSleepMinutes: current?.lightSleepMinutes,
      awakeSleepMinutes: current?.awakeSleepMinutes,
      waterMl: current?.waterMl,
      activeMinutes: activeMinutes ?? current?.activeMinutes,
      sleepStart: current?.sleepStart,
      sleepEnd: current?.sleepEnd,
      sleepLatencyMinutes: current?.sleepLatencyMinutes,
      sleepEfficiency: current?.sleepEfficiency,
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

  /// Disclosed App Store / Play reviewer demo flag. True ONLY for the
  /// reviewer account in `demoHealthModeProvider`'s allowlist. When true the
  /// notifier reports `isConnected: true` immediately (and skips the real
  /// platform permission probe) so the health cards render against the
  /// seeded backend data. For every real account this is false and the
  /// notifier behaves byte-identically to before.
  final bool _demoMode;

  HealthSyncNotifier(this._healthService, this._demoMode)
      : super(HealthSyncState(isConnected: _demoMode)) {
    if (_demoMode) {
      // Reviewer demo: skip the real Health Connect / HealthKit probe
      // entirely — `isConnected` is already true and there is no platform
      // store to verify against on a reviewer's emulator.
      return;
    }
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

