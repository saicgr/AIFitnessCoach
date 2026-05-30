part of 'nutrition_repository.dart';


/// Persistent (cross-launch) cache for the user's daily nutrition summary.
///
/// Backed by SharedPreferences so we don't need a Drift schema bump (which
/// would require running build_runner — pinned off per project rules). The
/// payload is a JSON-encoded `DailyNutritionSummary` keyed by user_id; we
/// also stamp the date so a stale Wednesday cache doesn't accidentally
/// render as Thursday data.
///
/// Used to power stale-while-revalidate on the Nutrition tab: cold-start
/// app open seeds `state.todaySummary` from disk synchronously so the UI
/// renders immediately, while the network refetch fires in parallel.
class _NutritionDiskCache {
  static const _prefix = 'nutrition_summary_v1::';

  static String _key(String userId) => '$_prefix$userId';

  static Future<DailyNutritionSummary?> read(String userId, String todayStr) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(userId));
      if (raw == null || raw.isEmpty) return null;
      final envelope = jsonDecode(raw) as Map<String, dynamic>;
      // Discard the cache if it's not for today's local date — yesterday's
      // numbers rendered as today's would be far worse than a quick skeleton.
      final cachedDate = envelope['date'] as String?;
      if (cachedDate != todayStr) return null;
      final body = envelope['summary'] as Map<String, dynamic>?;
      if (body == null) return null;
      return DailyNutritionSummary.fromJson(body);
    } catch (e) {
      debugPrint('🥗 [NutritionDiskCache] read failed: $e');
      return null;
    }
  }

  static Future<void> write(
    String userId,
    String todayStr,
    DailyNutritionSummary summary,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(userId),
        jsonEncode({
          'date': todayStr,
          'cached_at': DateTime.now().toIso8601String(),
          'summary': summary.toJson(),
        }),
      );
    } catch (e) {
      debugPrint('🥗 [NutritionDiskCache] write failed: $e');
    }
  }

  static Future<void> clear(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(userId));
    } catch (_) {/* best-effort */}
  }
}


// ===========================================================================
// _MealWriteQueue — offline meal-logging write queue (A11)
// ===========================================================================

/// Thrown when an offline meal log can't even be persisted to the local sync
/// queue (e.g. SharedPreferences write failed). The caller must treat this as
/// a genuine save failure — roll back the optimistic row and offer a retry —
/// rather than showing a meal that will never reach the server.
class MealLogPersistException implements Exception {
  final String message;
  const MealLogPersistException(this.message);
  @override
  String toString() => 'MealLogPersistException: $message';
}

/// Disk-backed FIFO queue of meal-log writes (`POST /nutrition/log-direct`)
/// made while the device is offline.
///
/// Each entry stores the FULL request body (the map `logAdjustedFood` builds)
/// — including a stable `idempotency_key`. On a connectivity-restored event
/// the queue flushes in FIFO order, de-duped by idempotency key; the same key
/// on the body means a partial-flush-then-retry can't double-log either.
///
/// Versioned, user-scoped SharedPreferences envelope `{v, items:[...]}` — a
/// schema mismatch drops the queue rather than crashing.
class _MealWriteQueue {
  static const _prefix = 'meal_write_queue_v1::';
  static const _schemaVersion = 1;

  static String _key(String userId) => '$_prefix$userId';

  /// Append a meal-log request body to the on-disk queue, de-duping on the
  /// embedded `idempotency_key`.
  ///
  /// Returns true when the body is safely on disk (or already queued under the
  /// same idempotency key), false when persistence itself failed. The offline
  /// log path MUST surface a false return rather than pretend the meal was
  /// saved — otherwise a SharedPreferences failure silently loses the write.
  static Future<bool> enqueue(String userId, Map<String, dynamic> body) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await _read(prefs, userId);
      final key = body['idempotency_key'];
      if (key != null && list.any((b) => b['idempotency_key'] == key)) {
        return true; // already queued — never enqueue twice
      }
      list.add(body);
      await _persist(prefs, userId, list);
      debugPrint('🥗 [MealQueue] enqueued (depth=${list.length})');
      return true;
    } catch (e) {
      debugPrint('🥗 [MealQueue] enqueue failed: $e');
      return false;
    }
  }

  /// Current number of meal-log writes still waiting to sync for [userId].
  /// Drives the pending-sync surface so a stuck queue is never invisible.
  static Future<int> depth(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (await _read(prefs, userId)).length;
    } catch (_) {
      return 0;
    }
  }

  static Future<List<Map<String, dynamic>>> _read(
      SharedPreferences prefs, String userId) async {
    final raw = prefs.getString(_key(userId));
    if (raw == null || raw.isEmpty) return [];
    try {
      final envelope = jsonDecode(raw);
      if (envelope is! Map<String, dynamic>) return [];
      if (envelope['v'] != _schemaVersion) return []; // drop on schema bump
      final items = envelope['items'];
      if (items is! List) return [];
      return items
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _persist(SharedPreferences prefs, String userId,
      List<Map<String, dynamic>> list) async {
    if (list.isEmpty) {
      await prefs.remove(_key(userId));
      return;
    }
    await prefs.setString(
      _key(userId),
      jsonEncode({'v': _schemaVersion, 'items': list}),
    );
  }

  /// Drain the queue in FIFO order via [send]. Stops on the first transient
  /// failure and re-persists the remainder so order + idempotency hold for
  /// the next online event. Returns the number of writes flushed.
  static Future<int> flush(
    String userId,
    Future<bool> Function(Map<String, dynamic> body) send,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var list = await _read(prefs, userId);
      if (list.isEmpty) return 0;
      var flushed = 0;
      while (list.isNotEmpty) {
        final ok = await send(list.first);
        if (!ok) break; // transient failure — keep the rest queued
        list = list.sublist(1);
        flushed++;
        await _persist(prefs, userId, list);
      }
      debugPrint('🥗 [MealQueue] flushed $flushed, remaining ${list.length}');
      return flushed;
    } catch (e) {
      debugPrint('🥗 [MealQueue] flush failed: $e');
      return 0;
    }
  }

  static Future<bool> isEmpty(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (await _read(prefs, userId)).isEmpty;
    } catch (_) {
      return true;
    }
  }
}


/// Progress event for streaming food logging
class FoodLoggingProgress {
  /// Current step number (1-indexed)
  final int step;

  /// Total number of steps
  final int totalSteps;

  /// Human-readable status message
  final String message;

  /// Additional detail about the current step
  final String? detail;

  /// Time elapsed since start in milliseconds
  final int elapsedMs;

  /// The logged food response (only set when complete)
  final LogFoodResponse? foodLog;

  /// Whether logging completed successfully
  final bool isCompleted;

  /// Whether an error occurred
  final bool hasError;

  /// Whether this is an analysis-only result (not yet saved to database)
  final bool isAnalysisOnly;

  /// Coaching tips delivered via the late `coach_tips` SSE event (streamed
  /// AFTER `done` so the card renders fast). Keys: ai_suggestion,
  /// encouragements, warnings, recommended_swap, health_score. Null on the
  /// normal `done` / `progress` events; set only on the coach_tips event.
  final Map<String, dynamic>? coachTips;

  FoodLoggingProgress({
    required this.step,
    required this.totalSteps,
    required this.message,
    this.detail,
    required this.elapsedMs,
    this.foodLog,
    this.isCompleted = false,
    this.hasError = false,
    this.isAnalysisOnly = false,
    this.coachTips,
  });

  /// True when this event carries late-arriving coaching tips.
  bool get hasCoachTips => coachTips != null;

  /// Progress as a percentage (0.0 to 1.0)
  double get progress => totalSteps > 0 ? step / totalSteps : 0;

  /// Whether logging is still in progress
  bool get isLoading => !isCompleted && !hasError;

  @override
  String toString() => 'FoodLoggingProgress(step: $step/$totalSteps, message: $message, elapsedMs: $elapsedMs)';
}


/// Progress event for multi-image food analysis. Carries the raw backend
/// payload in [result] on completion so the caller can branch on
/// `analysis_type` ("plate" / "menu" / "buffet") and render appropriately.
///
/// Menu + buffet modes additionally emit per-page events: one [isPageEvent]
/// with [pageItems] filled as each page finishes Gemini analysis on the
/// backend. The caller can open the MenuAnalysisSheet on the first page event
/// and append items progressively as later pages arrive.
class MultiImageAnalysisProgress {
  final int step;
  final int totalSteps;
  final String message;
  final String? detail;
  final int elapsedMs;

  /// Raw response payload from backend's `done` event. Includes:
  /// - `analysis_type`: "plate" | "menu" | "buffet"
  /// - `food_items`: flat list of dishes (for menu/buffet) or food items (plate)
  /// - `sections`, `suggested_plate`, `recommended_order`, `tips` (menu/buffet)
  /// - `food_log_id`, macros, `health_score`, `ai_suggestion` (plate auto-log)
  /// - `image_urls`, `storage_keys`, `mime_types`
  final Map<String, dynamic>? result;

  final bool isCompleted;
  final bool hasError;

  /// Per-page fields (populated when [isPageEvent] or [isPageError] is true).
  final bool isPageEvent;
  final bool isPageError;
  final int? pageNumber;
  final int? totalPages;
  final List<Map<String, dynamic>> pageItems;
  final String? pageAnalysisType;
  final String? pageImageUrl;
  final String? pageStorageKey;

  MultiImageAnalysisProgress({
    required this.step,
    required this.totalSteps,
    required this.message,
    this.detail,
    required this.elapsedMs,
    this.result,
    this.isCompleted = false,
    this.hasError = false,
    this.isPageEvent = false,
    this.isPageError = false,
    this.pageNumber,
    this.totalPages,
    this.pageItems = const [],
    this.pageAnalysisType,
    this.pageImageUrl,
    this.pageStorageKey,
  });

  double get progress => totalSteps > 0 ? step / totalSteps : 0;
  bool get isLoading => !isCompleted && !hasError;

  String? get analysisType => result?['analysis_type'] as String?;
  List<Map<String, dynamic>> get foodItems {
    final raw = result?['food_items'] as List? ?? const [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  @override
  String toString() =>
      'MultiImageAnalysisProgress(step: $step/$totalSteps, type: $analysisType, message: $message)';
}

/// Nutrition state
///
/// `loadedSummaryDate` / `loadedLogsDate` (yyyy-MM-dd in the user's local
/// timezone) record which date the currently cached `todaySummary` /
/// `recentLogs` actually belong to. They exist so that switching dates
/// (Today → Yesterday → back to Today) doesn't serve the wrong day from the
/// in-memory cache — the short-circuit in `_shouldSkipLoad` must verify both
/// user AND date.
class NutritionState {
  final bool isLoading;
  final String? error;
  final DailyNutritionSummary? todaySummary;
  final NutritionTargets? targets;
  final List<FoodLog> recentLogs;
  final String? loadedSummaryDate;
  final String? loadedLogsDate;

  /// Number of meal-log writes still waiting to sync to the server (offline
  /// queue depth). > 0 means at least one logged meal is NOT yet on the server,
  /// so the UI surfaces a "waiting to sync" affordance with a retry. Keeps a
  /// stranded write visible instead of silently lost.
  final int pendingMealSyncCount;

  const NutritionState({
    this.isLoading = false,
    this.error,
    this.todaySummary,
    this.targets,
    this.recentLogs = const [],
    this.loadedSummaryDate,
    this.loadedLogsDate,
    this.pendingMealSyncCount = 0,
  });

  NutritionState copyWith({
    bool? isLoading,
    String? error,
    DailyNutritionSummary? todaySummary,
    NutritionTargets? targets,
    List<FoodLog>? recentLogs,
    String? loadedSummaryDate,
    String? loadedLogsDate,
    int? pendingMealSyncCount,
  }) {
    return NutritionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      todaySummary: todaySummary ?? this.todaySummary,
      targets: targets ?? this.targets,
      recentLogs: recentLogs ?? this.recentLogs,
      loadedSummaryDate: loadedSummaryDate ?? this.loadedSummaryDate,
      loadedLogsDate: loadedLogsDate ?? this.loadedLogsDate,
      pendingMealSyncCount:
          pendingMealSyncCount ?? this.pendingMealSyncCount,
    );
  }
}


/// Nutrition state notifier
class NutritionNotifier extends StateNotifier<NutritionState> {
  final NutritionRepository _repository;
  final Ref _ref;
  String? _lastLoadedUserId;  // Track which user data is loaded for
  DateTime? _lastLoadTime;     // Track when data was last loaded

  /// Connectivity subscription that flushes the offline meal write queue
  /// when the network is restored (A11).
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  bool _isFlushingMealQueue = false;

  /// Tombstones for meals deleted optimistically (A12c). A background
  /// `loadTodaySummary` whose request was in flight BEFORE the delete landed
  /// could otherwise resolve afterwards and resurrect the deleted meal. Any
  /// id in this set is filtered out of an incoming server summary. An entry
  /// is cleared once `commitDeleteLog`'s network delete confirms the server
  /// also dropped it (so a later genuine re-log of the same id isn't hidden).
  final Set<String> _deletedTombstones = {};

  /// Monotonic counter — each summary load increments it. A response whose
  /// epoch no longer matches has been superseded by a newer load and is
  /// dropped, so an out-of-order (stale) response never clobbers fresher
  /// state.
  int _summaryLoadEpoch = 0;

  NutritionNotifier(this._repository, this._ref) : super(const NutritionState()) {
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn);
      if (online) {
        // Defer slightly so the radio + DNS settle before hitting the API.
        Future.delayed(const Duration(milliseconds: 800), _flushMealQueue);
      }
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }

  /// Flush the offline meal write queue. Each queued body is replayed verbatim
  /// (via [NutritionRepository.replayQueuedMealLog]) so its stable
  /// `idempotency_key` lets the server de-dupe any write that already landed.
  /// On success the in-memory + disk caches are reconciled with the server.
  Future<void> _flushMealQueue() async {
    final userId = _lastLoadedUserId;
    if (userId == null || _isFlushingMealQueue) return;
    if (await _MealWriteQueue.isEmpty(userId)) {
      // Nothing queued — make sure any stale "waiting to sync" badge clears.
      if (state.pendingMealSyncCount != 0) {
        state = state.copyWith(pendingMealSyncCount: 0);
      }
      return;
    }
    _isFlushingMealQueue = true;
    try {
      final flushed = await _MealWriteQueue.flush(userId, (body) async {
        try {
          await _repository.replayQueuedMealLog(body);
          return true;
        } catch (e) {
          debugPrint('🥗 [Nutrition] queued meal flush item failed: $e');
          return false; // transient — keep it (and the rest) queued
        }
      });
      if (flushed > 0) {
        // Reconcile: server now holds the real rows. forceRefresh so the
        // optimistic splices are replaced by authoritative data in place.
        await loadTodaySummary(userId, forceRefresh: true);
        await loadRecentLogs(userId, forceRefresh: true);
      }
    } finally {
      _isFlushingMealQueue = false;
      // Whatever remains queued (a write that keeps failing to land) stays
      // visible via the pending badge instead of silently lingering.
      await _refreshPendingMealCount(userId);
    }
  }

  /// Recompute the offline-queue depth into state so the "waiting to sync"
  /// surface reflects reality. Cheap (one SharedPreferences read); safe to
  /// call after any load or log.
  Future<void> _refreshPendingMealCount(String userId) async {
    final depth = await _MealWriteQueue.depth(userId);
    if (state.pendingMealSyncCount != depth) {
      state = state.copyWith(pendingMealSyncCount: depth);
    }
  }

  /// Public retry hook for the "N meals waiting to sync" affordance. Forces a
  /// flush attempt regardless of connectivity-change events (the queue is
  /// otherwise only drained on a reconnect event, which never fires when the
  /// app launches already-online with a stranded queue from a prior session).
  Future<void> retryPendingMealWrites() async {
    await _flushMealQueue();
  }

  /// Pre-seed state from bootstrap data so the home screen shows nutrition instantly.
  void preSeedFromBootstrap({
    required int calories,
    int? targetCalories,
    required double protein,
    required double carbs,
    required double fat,
    double? targetProtein,
    double? targetCarbs,
    double? targetFat,
  }) {
    if (state.todaySummary != null) return; // Don't overwrite real data
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    state = state.copyWith(
      todaySummary: DailyNutritionSummary(
        date: todayStr,
        totalCalories: calories,
        totalProteinG: protein,
        totalCarbsG: carbs,
        totalFatG: fat,
      ),
      targets: targetCalories != null ? NutritionTargets(
        userId: '',
        dailyCalorieTarget: targetCalories,
        dailyProteinTargetG: targetProtein ?? 0,
        dailyCarbsTargetG: targetCarbs ?? 0,
        dailyFatTargetG: targetFat ?? 0,
      ) : null,
    );
    debugPrint('⚡ [Nutrition] Pre-seeded from bootstrap');
  }

  /// Check if we should skip loading (data is fresh - less than 5 minutes old).
  ///
  /// [forDate] — the date the caller is asking about (yyyy-MM-dd, local tz).
  /// The cache is only usable when the requested date matches the last-loaded
  /// date; cross-date calls (e.g. toggling from Yesterday back to Today) must
  /// fall through to the network even when the TTL hasn't elapsed.
  bool _shouldSkipLoad(String userId, {String? forDate, String? forLoadedDate}) {
    if (_lastLoadedUserId != userId) return false;
    if (_lastLoadTime == null) return false;
    if (forDate != null && forLoadedDate != null && forDate != forLoadedDate) {
      return false;
    }
    final elapsed = DateTime.now().difference(_lastLoadTime!);
    return elapsed.inMinutes < 5;  // Cache for 5 minutes to improve navigation speed
  }

  /// Load today's nutrition summary.
  ///
  /// Stale-while-revalidate flow:
  ///   1. In-memory cache hit (<5 min, same user) → return immediately,
  ///      clearing any leftover error so retry works.
  ///   2. Otherwise, if the in-memory state is empty, try the disk cache
  ///      (SharedPreferences, scoped to today's local date). On hit, render
  ///      that data instantly (no skeleton) and continue to the network
  ///      refresh in the background.
  ///   3. Otherwise, show the skeleton and wait for the network.
  ///   4. On network success, update state + write to disk for the next
  ///      cold start.
  ///   5. On network failure: if we're displaying any data (in-memory or
  ///      from disk), keep it and silently swallow the error. Only surface
  ///      the error banner when we have nothing else to show.
  Future<void> loadTodaySummary(String userId, {bool forceRefresh = false}) async {
    final localDate = Tz.localDate();

    // (1) In-memory freshness short-circuit. Require BOTH user AND date
    // match — otherwise we'd serve yesterday's summary (left in state by a
    // prior loadSummaryForDate call) as today's.
    if (!forceRefresh &&
        _shouldSkipLoad(userId,
            forDate: localDate, forLoadedDate: state.loadedSummaryDate) &&
        state.todaySummary != null &&
        state.loadedSummaryDate == localDate) {
      debugPrint('🥗 [NutritionProvider] Skipping loadTodaySummary - data is fresh');
      if (state.error != null) {
        state = state.copyWith(error: null);
      }
      return;
    }

    // (2) Disk seed. Only when in-memory is empty AND we're not force-
    // refreshing (force = user explicitly asked for fresh data).
    if (!forceRefresh && state.todaySummary == null) {
      // Set isLoading=true synchronously *before* yielding to the disk read,
      // so the first build frame shows the skeleton instead of an empty
      // TabBarView. The disk read is fast (~10ms) — either resolves to
      // cached data (skeleton replaced immediately) or stays as skeleton
      // until the network call below returns.
      state = state.copyWith(isLoading: true, error: null);
      final cached = await _NutritionDiskCache.read(userId, localDate);
      if (cached != null) {
        debugPrint('🥗 [NutritionProvider] Seeded from disk cache for $localDate');
        state = state.copyWith(
          isLoading: false,
          todaySummary: cached,
          loadedSummaryDate: localDate,
        );
      }
      // else: keep isLoading=true, the network call below will resolve it
    } else {
      // We already have data on screen; just clear any error so the network
      // call below can refresh silently without flashing the error banner.
      state = state.copyWith(error: null);
    }

    final stopwatch = Stopwatch()..start();
    final epoch = ++_summaryLoadEpoch;
    // Snapshot what's on screen NOW so the merge below can protect a
    // just-logged meal from a stale/cached server payload.
    final localBefore = state.todaySummary;
    try {
      // Pass local date to avoid UTC mismatch on server (Render runs in UTC)
      final raw = await _repository.getDailySummary(userId, date: localDate);
      debugPrint(
        '🥗 [NutritionProvider] loadTodaySummary network: ${stopwatch.elapsedMilliseconds}ms '
        '(meals=${raw.meals.length}, kcal=${raw.totalCalories})',
      );
      // A newer load superseded this request — drop this (now stale) response
      // instead of letting it overwrite fresher state.
      if (epoch != _summaryLoadEpoch) return;
      // Reconcile against what's on screen: drop optimistically-deleted meals
      // a (possibly cached) server payload still carries (A12c), and re-add a
      // just-logged local meal the payload omitted. Never blind-overwrite.
      final summary = _mergeServerSummary(raw, localBefore);
      state = state.copyWith(
        isLoading: false,
        todaySummary: summary,
        loadedSummaryDate: localDate,
      );
      _lastLoadedUserId = userId;
      _lastLoadTime = DateTime.now();

      // (Sync-recovery) This network call just succeeded, so we are demonstrably
      // online. Opportunistically drain any stranded offline meal-write queue.
      // The connectivity listener only fires on a CHANGE event, so a queue left
      // from a prior session never flushes when the app launches already-online
      // — the meal sits unsynced forever while the user believes it saved. A
      // tab-open flush closes that hole. Cheap + idempotent (isEmpty short-
      // circuits; idempotency keys de-dupe), so fire-and-forget is safe.
      unawaited(_flushMealQueue());

      // (4) Persist the RECONCILED result to disk for next cold start.
      // Fire-and-forget — never block the UI on disk I/O.
      unawaited(_NutritionDiskCache.write(userId, localDate, summary));

      // Check if protein goal was hit and award XP
      _checkProteinGoal(summary);
    } catch (e) {
      debugPrint(
        '🥗 [NutritionProvider] loadTodaySummary FAILED after ${stopwatch.elapsedMilliseconds}ms: $e',
      );
      if (epoch != _summaryLoadEpoch) return;
      // (5) Only surface the error if we have nothing on screen.
      if (state.todaySummary == null) {
        state = state.copyWith(isLoading: false, error: e.toString());
      } else {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// Check if user hit their daily protein goal and award XP
  void _checkProteinGoal(DailyNutritionSummary summary) {
    final targets = state.targets;
    if (targets == null) return;

    final proteinConsumed = summary.totalProteinG ?? 0;
    final proteinTarget = targets.dailyProteinTargetG ?? 150;

    if (proteinConsumed >= proteinTarget) {
      debugPrint('🎯 [NutritionProvider] Protein goal hit! ${proteinConsumed.toInt()}g / ${proteinTarget.toInt()}g');
      // Award XP - the provider handles duplicate prevention
      _ref.read(xpProvider.notifier).markProteinGoalHit();
    }

    _checkCalorieGoal(summary);
  }

  /// Fire the "calorie deficit" XP award when the user has logged the bulk of
  /// their day's food (>= 80% of target) AND stayed under their calorie
  /// target. The 80% floor prevents premature firing after a single small
  /// snack; the upper bound is the target itself since "less than target"
  /// defines the deficit. Idempotent per day via the provider.
  void _checkCalorieGoal(DailyNutritionSummary summary) {
    final targets = state.targets;
    if (targets == null) return;

    final caloriesConsumed = summary.totalCalories;
    final calorieTarget = targets.dailyCalorieTarget;
    if (calorieTarget == null || calorieTarget <= 0) return;

    final floor = (calorieTarget * 0.8).round();
    if (caloriesConsumed >= floor && caloriesConsumed < calorieTarget) {
      debugPrint('🎯 [NutritionProvider] Calorie deficit hit! $caloriesConsumed / $calorieTarget kcal');
      _ref.read(xpProvider.notifier).markCalorieGoalHit();
    }
  }

  /// Load nutrition summary for a specific date (used when navigating dates)
  Future<void> loadSummaryForDate(String userId, DateTime date) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    // Cache match: same user, same date, fresh → skip.
    if (_shouldSkipLoad(userId,
            forDate: dateStr, forLoadedDate: state.loadedSummaryDate) &&
        state.todaySummary != null &&
        state.loadedSummaryDate == dateStr) {
      return;
    }

    // Clear stale data from a different date BEFORE the fetch so the UI
    // doesn't render the wrong day while the network call is in flight.
    state = state.copyWith(
      isLoading: true,
      error: null,
      todaySummary: state.loadedSummaryDate == dateStr ? state.todaySummary : null,
    );
    final epoch = ++_summaryLoadEpoch;
    final localBefore = state.todaySummary;
    try {
      final raw = await _repository.getDailySummary(userId, date: dateStr);
      // Superseded by a newer load — drop this response.
      if (epoch != _summaryLoadEpoch) return;
      // A raced response for a DIFFERENT date must never render as this date.
      if (raw.date.isNotEmpty && raw.date != dateStr) return;
      // Merge only against a local summary that is for the SAME date, so the
      // recency re-add can't pull another day's meals in.
      final summary = _mergeServerSummary(
        raw,
        localBefore?.date == dateStr ? localBefore : null,
      );
      state = state.copyWith(
        isLoading: false,
        todaySummary: summary,
        loadedSummaryDate: dateStr,
      );
      _lastLoadedUserId = userId;
      _lastLoadTime = DateTime.now();
      // Disk cache holds a single summary per user and is keyed to today's
      // local date (see `_NutritionDiskCache.read`). We deliberately DON'T
      // write non-today summaries here — doing so would overwrite the
      // today-cold-start payload with stale data. Historical dates simply
      // re-fetch on revisit (typical usage is infrequent).
    } catch (e) {
      if (epoch != _summaryLoadEpoch) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load food logs for a specific date
  Future<void> loadLogsForDate(String userId, DateTime date) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    // Clear logs from a different date so we don't render stale rows while
    // fetching.
    if (state.loadedLogsDate != dateStr) {
      state = state.copyWith(recentLogs: const [], loadedLogsDate: dateStr);
    }
    try {
      // Request [date, date+1] so logs that land on the next UTC day due to
      // timezone offset (e.g. 7 PM CT = 00:49 UTC next day) are included.
      // Filter client-side to keep only logs whose local date matches `date`.
      final nextDay = date.add(const Duration(days: 1));
      final nextDayStr = '${nextDay.year}-${nextDay.month.toString().padLeft(2, '0')}-${nextDay.day.toString().padLeft(2, '0')}';
      final rawLogs = await _repository.getFoodLogs(userId, fromDate: dateStr, toDate: nextDayStr);
      final logs = rawLogs.where((log) {
        final local = log.loggedAt.isUtc ? log.loggedAt.toLocal() : log.loggedAt;
        return local.year == date.year && local.month == date.month && local.day == date.day;
      }).toList();
      state = state.copyWith(recentLogs: logs, loadedLogsDate: dateStr);
    } catch (e) {
      debugPrint('Error loading food logs for date: $e');
    }
  }

  /// Load nutrition targets
  Future<void> loadTargets(String userId, {bool forceRefresh = false}) async {
    // Skip if data is fresh
    if (!forceRefresh && _shouldSkipLoad(userId) && state.targets != null) {
      return;
    }

    try {
      final targets = await _repository.getTargets(userId);
      state = state.copyWith(targets: targets);
    } catch (e) {
      debugPrint('Error loading nutrition targets: $e');
    }
  }

  /// Load recent food logs (for Today).
  ///
  /// `recentLogs` is shared with `loadLogsForDate` — so if a prior call loaded
  /// yesterday's logs, skipping here would show yesterday's rows as "today's."
  /// Gate on the loaded date matching today's local date.
  Future<void> loadRecentLogs(String userId, {int limit = 50, bool forceRefresh = false}) async {
    final todayStr = Tz.localDate();
    if (!forceRefresh &&
        _shouldSkipLoad(userId,
            forDate: todayStr, forLoadedDate: state.loadedLogsDate) &&
        state.recentLogs.isNotEmpty &&
        state.loadedLogsDate == todayStr) {
      debugPrint('🥗 [NutritionProvider] Skipping loadRecentLogs - data is fresh');
      return;
    }

    try {
      final logs = await _repository.getFoodLogs(userId, limit: limit);
      // Don't let an empty (stale/cached/flaky) response wipe logs still on
      // screen when a just-written local row is present — keep last-good.
      if (logs.isEmpty && _hasRecentLocalLog()) {
        debugPrint(
            '🥗 [NutritionProvider] loadRecentLogs: ignored empty response — recent local log present');
      } else {
        state = state.copyWith(recentLogs: logs, loadedLogsDate: todayStr);
      }
    } catch (e) {
      debugPrint('Error loading recent food logs: $e');
    }
  }

  /// True when `recentLogs` holds a log written within the last 90 s — used
  /// to reject an empty server response that would wipe a just-logged row.
  /// An all-old `recentLogs` (or an empty one) returns false, so a genuine
  /// "everything deleted" empty response is still accepted.
  bool _hasRecentLocalLog() {
    if (state.recentLogs.isEmpty) return false;
    final cutoff = DateTime.now().subtract(const Duration(seconds: 90));
    return state.recentLogs.any((l) => l.createdAt.isAfter(cutoff));
  }

  /// Force refresh all data (use after logging a meal, etc.)
  Future<void> refreshAll(String userId) async {
    _lastLoadTime = null;  // Clear cache
    await Future.wait([
      loadTodaySummary(userId, forceRefresh: true),
      loadTargets(userId, forceRefresh: true),
      loadRecentLogs(userId, forceRefresh: true),
    ]);
  }

  /// Delete a food log
  Future<void> deleteLog(String userId, String logId) async {
    try {
      await _repository.deleteFoodLog(logId);
      // Force-refresh: without this, the cache-skip in loadTodaySummary
      // returns immediately and the deleted meal stays visible in the UI.
      // The disk cache is overwritten by loadTodaySummary's success path,
      // so the next cold start won't re-render the deleted meal either.
      await loadTodaySummary(userId, forceRefresh: true);
      await loadRecentLogs(userId, forceRefresh: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Optimistically remove a meal from the in-memory `todaySummary` so the
  /// UI updates *instantly* on swipe-delete — no waiting for the network
  /// round-trip + force-refresh chain that `deleteLog` does. Returns the
  /// removed meal so callers can pass it back to [restoreLog] if the user
  /// taps Undo. Returns null if the log isn't in `todaySummary` (e.g. it
  /// was logged on another date and we're looking at a backfilled view).
  FoodLog? optimisticRemoveLog(String logId) {
    final summary = state.todaySummary;
    if (summary == null) return null;
    final idx = summary.meals.indexWhere((m) => m.id == logId);
    if (idx < 0) return null;
    final removed = summary.meals[idx];
    final remaining = [...summary.meals]..removeAt(idx);
    // Tombstone the id so an in-flight background refresh can't resurrect it.
    _deletedTombstones.add(logId);
    state = state.copyWith(
      todaySummary: _recomputeTotals(summary, remaining),
    );
    return removed;
  }

  /// Replace the meal with the given id by applying [transform] to it.
  /// Returns the original meal so callers can roll back on network failure.
  /// No-op + null return when the id isn't in `todaySummary` (e.g. viewing
  /// a different date than the meal lives on).
  FoodLog? optimisticUpdateLog(String logId, FoodLog Function(FoodLog) transform) {
    final summary = state.todaySummary;
    if (summary == null) return null;
    final idx = summary.meals.indexWhere((m) => m.id == logId);
    if (idx < 0) return null;
    final original = summary.meals[idx];
    final updated = transform(original);
    final next = [...summary.meals]..[idx] = updated;
    state = state.copyWith(
      todaySummary: _recomputeTotals(summary, next),
    );
    return original;
  }

  /// Re-insert a meal previously removed via [optimisticRemoveLog]. Used by
  /// the Undo action on swipe-delete. Inserts at the position that keeps
  /// the list sorted by `loggedAt` ascending.
  void restoreLog(FoodLog meal) {
    final summary = state.todaySummary;
    if (summary == null) return;
    // Undo — lift the tombstone so the meal can re-appear from the server.
    _deletedTombstones.remove(meal.id);
    final list = [...summary.meals];
    int insertAt = list.length;
    for (var i = 0; i < list.length; i++) {
      if (list[i].loggedAt.isAfter(meal.loggedAt)) {
        insertAt = i;
        break;
      }
    }
    list.insert(insertAt, meal);
    state = state.copyWith(
      todaySummary: _recomputeTotals(summary, list),
    );
  }

  /// Instantly add an already-constructed [FoodLog] to local state.
  /// Use this when callers have already converted the API response to a
  /// [FoodLog] (e.g. recipe logging, browser-panel relog).
  void spliceRawLog(FoodLog newLog, String userId) {
    final updatedLogs = [newLog, ...state.recentLogs];
    final currentSummary = state.todaySummary;
    final todayStr = Tz.localDate();
    final updatedMeals = <FoodLog>[...(currentSummary?.meals ?? []), newLog];
    final newSummary = _recomputeTotals(
      currentSummary ??
          DailyNutritionSummary(
            date: todayStr,
            totalCalories: 0,
            totalProteinG: 0,
            totalCarbsG: 0,
            totalFatG: 0,
            totalFiberG: 0,
            mealCount: 0,
          ),
      updatedMeals,
    );
    state = state.copyWith(
      recentLogs: updatedLogs,
      todaySummary: newSummary,
      loadedSummaryDate: todayStr,
      loadedLogsDate: todayStr,
    );
    unawaited(_NutritionDiskCache.write(userId, todayStr, newSummary));
  }

  /// Instantly add a newly logged meal to local state so the UI updates
  /// before the network round-trip that `loadTodaySummary(forceRefresh)`
  /// would otherwise require. The background refresh that follows (still
  /// fired by the log sheet) reconciles server-derived fields.
  ///
  /// (Part 4 / WR1) Returns the optimistic [FoodLog] it spliced in so the
  /// caller can pass its `id` to [optimisticRemoveLog] for a clean WR4
  /// rollback if the background `/nutrition/log-direct` POST later fails.
  FoodLog spliceLog(LogFoodResponse response, String mealType, String userId) {
    final now = DateTime.now();
    final foodItems = response.foodItems
        .map((r) => FoodItem(
              name: r.name,
              amount: r.amount,
              calories: r.calories,
              proteinG: r.proteinG,
              carbsG: r.carbsG,
              fatG: r.fatG,
              fiberG: r.fiberG,
              weightG: r.weightG,
              unit: r.unit,
              count: r.count,
              weightPerUnitG: r.weightPerUnitG,
            ))
        .toList();

    final newLog = FoodLog(
      id: response.foodLogId ?? 'optimistic_${now.millisecondsSinceEpoch}',
      userId: userId,
      mealType: mealType,
      loggedAt: now,
      foodItems: foodItems,
      totalCalories: response.totalCalories,
      proteinG: response.proteinG,
      carbsG: response.carbsG,
      fatG: response.fatG,
      fiberG: response.fiberG,
      healthScore: response.healthScore,
      aiFeedback: response.aiSuggestion,
      imageUrl: response.imageUrl,
      sourceType: response.sourceType,
      sodiumMg: response.sodiumMg,
      sugarG: response.sugarG,
      saturatedFatG: response.saturatedFatG,
      cholesterolMg: response.cholesterolMg,
      potassiumMg: response.potassiumMg,
      calciumMg: response.calciumMg,
      ironMg: response.ironMg,
      vitaminCMg: response.vitaminCMg,
      vitaminDIu: response.vitaminDIu,
      inflammationScore: response.inflammationScore,
      isUltraProcessed: response.isUltraProcessed,
      createdAt: now,
    );

    // Update recentLogs
    final updatedLogs = [newLog, ...state.recentLogs];

    // Update todaySummary by appending to meals and recomputing totals
    final currentSummary = state.todaySummary;
    final todayStr = Tz.localDate();
    final updatedMeals = <FoodLog>[
      ...(currentSummary?.meals ?? []),
      newLog,
    ];
    final newSummary = _recomputeTotals(
      currentSummary ??
          DailyNutritionSummary(
            date: todayStr,
            totalCalories: 0,
            totalProteinG: 0,
            totalCarbsG: 0,
            totalFatG: 0,
            totalFiberG: 0,
            mealCount: 0,
          ),
      updatedMeals,
    );

    state = state.copyWith(
      recentLogs: updatedLogs,
      todaySummary: newSummary,
      loadedSummaryDate: todayStr,
      loadedLogsDate: todayStr,
    );

    // Persist the updated totals so the next cold-start shows the new log
    unawaited(_NutritionDiskCache.write(userId, todayStr, newSummary));

    // If this splice corresponds to an offline-queued write, reflect the
    // pending-sync badge immediately rather than waiting for the next load.
    unawaited(_refreshPendingMealCount(userId));

    // (WR1) Hand the optimistic row back so callers can roll it back by id.
    return newLog;
  }

  /// (Part 4 / WR1) Build + splice an optimistic [FoodLog] for one menu /
  /// buffet dish that the user ticked off a menu-analysis checklist.
  ///
  /// The menu / buffet log path posts via `/nutrition/log-selected-items`
  /// (one food_log row per dish) — that endpoint returns only the new
  /// `food_log_ids`, not the full rows. The client already holds every
  /// dish's macros (the `selected` maps passed to `onLogItems`), so we build
  /// the optimistic [FoodLog] here from those maps and the returned id.
  ///
  /// [item] is one entry of the `selected` list — keys mirror the backend
  /// `LogSelectedItemsRequest` item shape: name / calories / protein_g /
  /// carbs_g / fat_g / fiber_g / amount (macros already portion-scaled).
  /// [logId] is the real server id when known (post-success reconcile is
  /// then a no-op for this row); pass null pre-network for a synthetic id.
  ///
  /// Returns the spliced [FoodLog] so the caller can roll it back via
  /// [optimisticRemoveLog] if the network write fails (WR4).
  FoodLog spliceMenuItem({
    required Map<String, dynamic> item,
    required String mealType,
    required String userId,
    required String sourceType,
    String? logId,
    String? imageUrl,
  }) {
    final now = DateTime.now();
    final calories = ((item['calories'] as num?) ?? 0).round();
    final proteinG = ((item['protein_g'] as num?) ?? 0).toDouble();
    final carbsG = ((item['carbs_g'] as num?) ?? 0).toDouble();
    final fatG = ((item['fat_g'] as num?) ?? 0).toDouble();
    final fiberG = (item['fiber_g'] as num?)?.toDouble();
    final foodItem = FoodItem(
      name: (item['name'] as String?) ?? 'Food',
      amount: item['amount'] as String?,
      calories: calories,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      fiberG: fiberG,
      inflammationScore: (item['inflammation_score'] as num?)?.toInt(),
      isUltraProcessed: item['is_ultra_processed'] as bool?,
    );
    final newLog = FoodLog(
      // A real id when the POST already returned; otherwise a synthetic id
      // unique enough that a rapid multi-item splice can't collide.
      id: logId ??
          'optimistic_${now.microsecondsSinceEpoch}_${state.recentLogs.length}',
      userId: userId,
      mealType: mealType,
      loggedAt: now,
      foodItems: [foodItem],
      totalCalories: calories,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      fiberG: fiberG,
      aiFeedback: item['coach_tip'] as String?,
      imageUrl: imageUrl,
      sourceType: sourceType,
      inflammationScore: (item['inflammation_score'] as num?)?.toInt(),
      isUltraProcessed: item['is_ultra_processed'] as bool?,
      createdAt: now,
    );
    // Reuse spliceRawLog so totals + disk cache stay consistent (WR1).
    spliceRawLog(newLog, userId);
    return newLog;
  }

  /// (Part 4 / WR6) Refresh Home's "Today's Journal" timeline so a freshly
  /// logged meal appears there without a manual pull-to-refresh.
  ///
  /// Home's timeline reads `timelineProvider`, which has its own cached
  /// state. The backend already invalidates its server-side timeline cache
  /// on a food-log write, but the Riverpod state needs an explicit refresh —
  /// this mirrors what the hydration log path does after `/hydration/log`.
  /// Best-effort and fire-and-forget — never blocks or fails a food log.
  void refreshTimeline() {
    try {
      // ignore: unawaited_futures
      _ref.read(timelineProvider.notifier).refresh();
    } catch (e) {
      debugPrint('🥗 [Nutrition] timeline refresh skipped: $e');
    }
  }

  /// (Part 4 / WR4) Roll back a set of optimistic rows in one shot. Used when
  /// a multi-dish menu log fails after several rows were already spliced.
  void optimisticRemoveLogs(Iterable<String> logIds) {
    for (final id in logIds) {
      optimisticRemoveLog(id);
    }
  }

  /// (Part 4 / WR5) Swap the local image path on an already-spliced optimistic
  /// row for the remote URL once the photo upload finishes server-side.
  ///
  /// While a food photo is still uploading, the meal-list row is spliced with
  /// `imageUrl` pointing at a `file://` path (the local capture). When the
  /// background `/nutrition/log-direct` POST returns the real S3 URL, call
  /// this so the row swaps to the remote image without a full refresh.
  void updateLogImageUrl(String logId, String? remoteImageUrl) {
    if (remoteImageUrl == null || remoteImageUrl.isEmpty) return;
    // FoodLog has no copyWith (generated model, not owned here) — rebuild the
    // row with every field preserved and only `imageUrl` swapped.
    optimisticUpdateLog(
      logId,
      (m) => FoodLog(
        id: m.id,
        userId: m.userId,
        mealType: m.mealType,
        loggedAt: m.loggedAt,
        foodItems: m.foodItems,
        totalCalories: m.totalCalories,
        proteinG: m.proteinG,
        carbsG: m.carbsG,
        fatG: m.fatG,
        fiberG: m.fiberG,
        healthScore: m.healthScore,
        healthScoreReasons: m.healthScoreReasons,
        aiFeedback: m.aiFeedback,
        notes: m.notes,
        moodBefore: m.moodBefore,
        moodAfter: m.moodAfter,
        energyLevel: m.energyLevel,
        sodiumMg: m.sodiumMg,
        sugarG: m.sugarG,
        saturatedFatG: m.saturatedFatG,
        cholesterolMg: m.cholesterolMg,
        potassiumMg: m.potassiumMg,
        calciumMg: m.calciumMg,
        ironMg: m.ironMg,
        vitaminAUg: m.vitaminAUg,
        vitaminCMg: m.vitaminCMg,
        vitaminDIu: m.vitaminDIu,
        inflammationScore: m.inflammationScore,
        isUltraProcessed: m.isUltraProcessed,
        glycemicLoad: m.glycemicLoad,
        fodmapRating: m.fodmapRating,
        fodmapReason: m.fodmapReason,
        imageUrl: remoteImageUrl, // ← the only swapped field (WR5)
        sourceType: m.sourceType,
        userQuery: m.userQuery,
        createdAt: m.createdAt,
      ),
    );
  }

  /// (Part 4 / WR2) Commit a food-log EDIT optimistically.
  ///
  /// Applies [transform] to the in-memory row IMMEDIATELY (so the meal row +
  /// rings update within one frame), then runs the network PUT in the
  /// background. On network failure the original row is restored and a calm
  /// error is exposed on `state.error` — no silent divergence.
  ///
  /// [networkUpdate] performs the actual `/nutrition/food-logs/{id}` PUT; it
  /// is only awaited AFTER the optimistic mutation lands.
  Future<void> commitUpdateLog(
    String logId,
    FoodLog Function(FoodLog) transform,
    Future<void> Function() networkUpdate,
  ) async {
    final original = optimisticUpdateLog(logId, transform);
    if (original == null) {
      // Row isn't in todaySummary (e.g. viewing another date) — just run the
      // network write so the server still gets the edit.
      try {
        await networkUpdate();
      } catch (e) {
        state = state.copyWith(error: e.toString());
      }
      return;
    }
    try {
      await networkUpdate();
    } catch (e) {
      // Roll back to the pre-edit row so the UI never shows an edit the
      // server rejected.
      optimisticUpdateLog(logId, (_) => original);
      state = state.copyWith(
        error: 'Could not save your edit. Please try again.',
      );
      debugPrint('🥗 [Nutrition] optimistic edit rolled back: $e');
    }
  }

  /// Fire-and-forget the network delete *after* the optimistic local
  /// removal has already updated the UI. We still force-refresh on success
  /// so any server-side derived fields (streak/adherence) line up with the
  /// new totals; on failure we restore the local state and surface the
  /// error.
  Future<void> commitDeleteLog(String userId, String logId, FoodLog snapshot) async {
    try {
      await _repository.deleteFoodLog(logId);
      // Server has now dropped the row — future refreshes can't resurrect it,
      // so the tombstone is no longer needed (and keeping it would hide a
      // genuine re-log of a recycled id).
      _deletedTombstones.remove(logId);
      // Refresh in the background — UI is already correct, this just keeps
      // server-derived metadata (recent logs, weekly aggregates) in sync.
      unawaited(loadRecentLogs(userId, forceRefresh: true));
    } catch (e) {
      // Roll back the optimistic removal if the network call fails so the
      // user doesn't end up with a deleted-locally-but-still-on-server row.
      // restoreLog also lifts the tombstone.
      restoreLog(snapshot);
      state = state.copyWith(error: e.toString());
    }
  }

  DailyNutritionSummary _recomputeTotals(
    DailyNutritionSummary summary,
    List<FoodLog> meals,
  ) {
    var cal = 0;
    var protein = 0.0;
    var carbs = 0.0;
    var fat = 0.0;
    var fiber = 0.0;
    for (final m in meals) {
      cal += m.totalCalories;
      protein += m.proteinG;
      carbs += m.carbsG;
      fat += m.fatG;
      fiber += m.fiberG ?? 0;
    }
    return DailyNutritionSummary(
      date: summary.date,
      totalCalories: cal,
      totalProteinG: protein,
      totalCarbsG: carbs,
      totalFatG: fat,
      totalFiberG: fiber,
      mealCount: meals.length,
      avgHealthScore: summary.avgHealthScore,
      meals: meals,
    );
  }

  /// Reconciles a freshly-fetched [server] summary against the [local]
  /// summary currently on screen, so a stale or cached server payload never
  /// makes a just-logged meal disappear:
  ///  - drops meals optimistically deleted (tombstoned) that the payload
  ///    still carries (a refetch whose request predated the delete);
  ///  - re-adds a local meal the payload omitted IF it was logged in the last
  ///    90 s — a just-logged meal the server cache predates. An OLDER meal the
  ///    server omits is treated as a genuine delete and is NOT resurrected, so
  ///    a truly empty day and cross-device deletes still reconcile correctly.
  DailyNutritionSummary _mergeServerSummary(
    DailyNutritionSummary server,
    DailyNutritionSummary? local,
  ) {
    var meals = server.meals;
    var changed = false;

    // Data-loss guard: a 0-meal server payload must NOT blank a day that
    // already has meals on screen. The daily summary is computed live from
    // food_logs server-side, so an empty response for a populated day is a
    // stale-cache / racy-read / timezone-window artifact — never the user
    // clearing their whole day (real deletes are tombstoned + force-refreshed,
    // and a genuinely empty day starts empty locally so this never trips).
    // Without this, ANY reload that came back empty (e.g. the refresh fired
    // right after saving daily targets) silently dropped every meal logged
    // more than 90s ago via the re-add window below — the "my food vanished
    // after I changed my targets" bug.
    if (server.meals.isEmpty &&
        local != null &&
        local.meals.any((m) => !_deletedTombstones.contains(m.id))) {
      debugPrint(
          '🥗 [NutritionProvider] Ignored empty server summary — kept ${local.meals.length} on-screen meal(s)');
      return local;
    }

    if (_deletedTombstones.isNotEmpty) {
      final kept =
          meals.where((m) => !_deletedTombstones.contains(m.id)).toList();
      if (kept.length != meals.length) {
        meals = kept;
        changed = true;
      }
    }

    if (local != null && local.meals.isNotEmpty) {
      final present = meals.map((m) => m.id).toSet();
      final cutoff = DateTime.now().subtract(const Duration(seconds: 90));
      final extras = <FoodLog>[
        for (final m in local.meals)
          if (!present.contains(m.id) &&
              !_deletedTombstones.contains(m.id) &&
              m.createdAt.isAfter(cutoff))
            m,
      ];
      if (extras.isNotEmpty) {
        meals = [...meals, ...extras];
        changed = true;
      }
    }

    return changed ? _recomputeTotals(server, meals) : server;
  }

  /// Update nutrition targets
  Future<void> updateTargets(
    String userId, {
    int? calorieTarget,
    double? proteinTarget,
    double? carbsTarget,
    double? fatTarget,
  }) async {
    try {
      await _repository.updateTargets(
        userId,
        calorieTarget: calorieTarget,
        proteinTarget: proteinTarget,
        carbsTarget: carbsTarget,
        fatTarget: fatTarget,
      );
      await loadTargets(userId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}


/// Combined data for the enhanced weekly check-in screen
class WeeklyCheckinData {
  final DetailedTDEE? detailedTdee;
  final AdherenceSummary? adherenceSummary;
  final RecommendationOptions? recommendationOptions;
  final WeeklySummaryData? weeklySummary;

  const WeeklyCheckinData({
    this.detailedTdee,
    this.adherenceSummary,
    this.recommendationOptions,
    this.weeklySummary,
  });

  /// Check if we have enough data for a meaningful check-in
  bool get hasEnoughData =>
      detailedTdee != null ||
      adherenceSummary != null ||
      recommendationOptions != null;

  /// Check if metabolic adaptation was detected
  bool get hasMetabolicAdaptation =>
      detailedTdee?.hasAdaptation ?? false;

  /// Get the current sustainability rating
  String? get sustainabilityRating =>
      adherenceSummary?.sustainabilityRating;

  /// Check if there are multiple recommendation options
  bool get hasMultipleOptions =>
      (recommendationOptions?.options.length ?? 0) > 1;
}

