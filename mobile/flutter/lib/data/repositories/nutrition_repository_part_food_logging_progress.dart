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

  // Keyed by user AND date. A single key per user (the old scheme) held only
  // the most-recently-loaded date, so navigating the date strip to yesterday
  // overwrote today's cold-start snapshot — on restart the Nutrition tab then
  // showed an empty day until the network returned (and showed nothing at all
  // if the server read came back empty). Per-date keys make every visited day
  // independently durable; date-nav can never clobber another day's cache.
  static String _key(String userId, String dateStr) =>
      '$_prefix$userId::$dateStr';

  static Future<DailyNutritionSummary?> read(String userId, String todayStr) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(userId, todayStr));
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
        _key(userId, todayStr),
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
      // Remove every per-date snapshot for this user (logout / account switch).
      final userPrefix = '$_prefix$userId::';
      final keys = prefs.getKeys()
          .where((k) => k == '$_prefix$userId' || k.startsWith(userPrefix))
          .toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
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

  /// Gap 1 — water-in-text. {amount_ml, drink_type} when the entry's text
  /// ("2 eggs and a glass of water") contained a beverage that should be logged
  /// to hydration alongside the food. Carried out-of-band (not on
  /// LogFoodResponse, whose codegen is pinned off) so the confirm flow can log
  /// it via the hydration repository. Null when no beverage was detected.
  final Map<String, dynamic>? hydrationDetected;

  /// Gap 1 — true when the entry was a beverage ONLY (no food items). The sheet
  /// logs the hydration and closes instead of showing a food confirm.
  final bool isHydrationOnly;

  /// Gap 7 — opt-in tracker inputs from the analyzed meal ({added_sugar_g,
  /// caffeine_mg, alcohol_g}). Carried out-of-band (not on LogFoodResponse,
  /// whose codegen is pinned off) so the confirm path can forward them to
  /// /log-direct and the sugar/caffeine/alcohol trackers get real data.
  final Map<String, dynamic>? trackerMicros;

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
    this.hydrationDetected,
    this.isHydrationOnly = false,
    this.trackerMicros,
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

/// Local-tz date key (yyyy-MM-dd) for "today". The [dailyNutritionProvider]
/// family is keyed by this string, so a date IS the provider identity — there
/// is no shared single slot another date could clobber.
String todayNutritionKey() => Tz.localDate();

/// Local-tz date key (yyyy-MM-dd) for an arbitrary [date].
String nutritionKeyFor(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// Per-date nutrition state — ONE calendar date's summary + logs.
///
/// One instance lives behind `dailyNutritionProvider(dateKey)`. Because the
/// date is the provider key, cross-date leakage (yesterday's meals rendering as
/// today's) is structurally impossible — there is no shared slot to clobber.
class DailyNutritionState {
  final bool isLoading;
  final String? error;
  final DailyNutritionSummary? summary;
  final List<FoodLog> logs;

  const DailyNutritionState({
    this.isLoading = false,
    this.error,
    this.summary,
    this.logs = const [],
  });

  DailyNutritionState copyWith({
    bool? isLoading,
    String? error,
    DailyNutritionSummary? summary,
    List<FoodLog>? logs,
  }) {
    return DailyNutritionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      summary: summary ?? this.summary,
      logs: logs ?? this.logs,
    );
  }
}

/// User-level (NOT date-scoped) nutrition state: the calorie/macro targets and
/// the offline meal-write-queue depth. Lives behind the singleton
/// [nutritionMetaProvider] so browsing a past date never touches it (the bug
/// the old single-slot `NutritionState` caused, where date-nav corrupted Home's
/// calorie card / today-score / metrics).
class NutritionMetaState {
  final NutritionTargets? targets;

  /// Number of meal-log writes still waiting to sync to the server (offline
  /// queue depth). > 0 means at least one logged meal is NOT yet on the server,
  /// so the UI surfaces a "waiting to sync" affordance with a retry. Keeps a
  /// stranded write visible instead of silently lost.
  final int pendingMealSyncCount;

  const NutritionMetaState({
    this.targets,
    this.pendingMealSyncCount = 0,
  });

  NutritionMetaState copyWith({
    NutritionTargets? targets,
    int? pendingMealSyncCount,
  }) {
    return NutritionMetaState(
      targets: targets ?? this.targets,
      pendingMealSyncCount: pendingMealSyncCount ?? this.pendingMealSyncCount,
    );
  }
}


/// Owns the genuinely USER-LEVEL nutrition concerns: the calorie/macro targets
/// and the offline meal-write queue (plus the connectivity listener that drains
/// it). Split out of the old monolithic notifier so the per-date family can be
/// purely date-scoped. Singleton — exactly one per session.
class NutritionMetaNotifier extends StateNotifier<NutritionMetaState> {
  final NutritionRepository _repository;
  final Ref _ref;
  String? _lastLoadedUserId;
  DateTime? _targetsLoadTime;

  /// Connectivity subscription that flushes the offline meal write queue when
  /// the network is restored (A11).
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  bool _isFlushingMealQueue = false;

  NutritionMetaNotifier(this._repository, this._ref)
      : super(const NutritionMetaState()) {
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn);
      if (online) {
        // Defer slightly so the radio + DNS settle before hitting the API.
        Future.delayed(const Duration(milliseconds: 800), () {
          final uid = _lastLoadedUserId;
          if (uid != null) flushMealQueue(uid);
        });
      }
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }

  /// Pre-seed targets from bootstrap so Home renders the calorie ring instantly.
  void preSeedTargets({
    int? targetCalories,
    double? targetProtein,
    double? targetCarbs,
    double? targetFat,
  }) {
    if (state.targets != null || targetCalories == null) return; // keep real data
    state = state.copyWith(
      targets: NutritionTargets(
        userId: '',
        dailyCalorieTarget: targetCalories,
        dailyProteinTargetG: targetProtein ?? 0,
        dailyCarbsTargetG: targetCarbs ?? 0,
        dailyFatTargetG: targetFat ?? 0,
      ),
    );
    debugPrint('⚡ [Nutrition] Pre-seeded targets from bootstrap');
  }

  /// Load nutrition targets (5-minute freshness cache).
  Future<void> loadTargets(String userId, {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _lastLoadedUserId == userId &&
        _targetsLoadTime != null &&
        DateTime.now().difference(_targetsLoadTime!).inMinutes < 5 &&
        state.targets != null) {
      return;
    }
    try {
      final targets = await _repository.getTargets(userId);
      state = state.copyWith(targets: targets);
      _lastLoadedUserId = userId;
      _targetsLoadTime = DateTime.now();
    } catch (e) {
      debugPrint('Error loading nutrition targets: $e');
    }
  }

  /// Update nutrition targets, then refresh them.
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
      await loadTargets(userId, forceRefresh: true);
    } catch (e) {
      debugPrint('Error updating nutrition targets: $e');
    }
  }

  /// Public retry hook for the "N meals waiting to sync" affordance.
  Future<void> retryPendingMealWrites(String userId) async {
    await flushMealQueue(userId);
  }

  /// Recompute the offline-queue depth into state so the "waiting to sync"
  /// surface reflects reality.
  Future<void> refreshPendingMealCount(String userId) async {
    final depth = await _MealWriteQueue.depth(userId);
    if (state.pendingMealSyncCount != depth) {
      state = state.copyWith(pendingMealSyncCount: depth);
    }
  }

  /// Flush the offline meal write queue, then reconcile TODAY's family. Each
  /// queued body is replayed verbatim so its stable `idempotency_key` lets the
  /// server de-dupe any write that already landed.
  Future<void> flushMealQueue(String userId) async {
    _lastLoadedUserId = userId;
    if (_isFlushingMealQueue) return;
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
        final today = todayNutritionKey();
        final n = _ref.read(dailyNutritionProvider(today).notifier);
        await n.load(userId, forceRefresh: true);
        await n.loadLogs(userId, forceRefresh: true);
      }
    } finally {
      _isFlushingMealQueue = false;
      // Whatever remains queued stays visible via the pending badge.
      await refreshPendingMealCount(userId);
    }
  }
}


/// Per-date nutrition notifier — the single source of truth for ONE date's
/// summary + logs. Created via `dailyNutritionProvider(dateKey)`; today's
/// instance is kept alive (read app-wide + prewarmed), past dates auto-dispose.
///
/// Because the date is the provider key, the cross-date leak the old single-slot
/// `NutritionState` allowed (yesterday's meals rendering as today's, and
/// browsing a past day corrupting Home/score/metrics) is structurally
/// impossible: a refresh only ever merges THIS date against THIS date.
class DailyNutritionNotifier extends StateNotifier<DailyNutritionState> {
  final NutritionRepository _repository;
  final Ref _ref;

  /// yyyy-MM-dd (user local tz) this notifier owns — the provider key.
  final String _dateKey;

  String? _lastLoadedUserId;
  DateTime? _lastLoadTime;

  /// Tombstones for meals deleted optimistically (A12c) — filtered out of an
  /// incoming server summary so an in-flight refresh can't resurrect them.
  /// Per-date (this instance only).
  final Set<String> _deletedTombstones = {};

  /// Monotonic counter — each load increments it. A response whose epoch no
  /// longer matches has been superseded by a newer load and is dropped.
  int _summaryLoadEpoch = 0;

  DailyNutritionNotifier(this._repository, this._ref, this._dateKey)
      : super(const DailyNutritionState());

  bool get _isToday => _dateKey == todayNutritionKey();

  /// Parse [_dateKey] into a DateTime stamped with the current wall-clock time —
  /// used to place an optimistic backfill row on the correct (past) date.
  DateTime _dateAtNow() {
    final p = _dateKey.split('-');
    final now = DateTime.now();
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]),
        now.hour, now.minute, now.second);
  }

  /// 5-minute in-memory freshness for the same user.
  bool _fresh(String userId) =>
      _lastLoadedUserId == userId &&
      _lastLoadTime != null &&
      DateTime.now().difference(_lastLoadTime!).inMinutes < 5;

  /// Pre-seed THIS date's summary from bootstrap (today only) so Home renders
  /// instantly. No-op if data is already present or this isn't today.
  void preSeedSummary({
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
  }) {
    if (!_isToday || state.summary != null) return;
    state = state.copyWith(
      summary: DailyNutritionSummary(
        date: _dateKey,
        totalCalories: calories,
        totalProteinG: protein,
        totalCarbsG: carbs,
        totalFatG: fat,
      ),
    );
    debugPrint('⚡ [Nutrition] Pre-seeded today summary from bootstrap');
  }

  /// Load this date's summary (stale-while-revalidate).
  ///
  /// Unifies the old `loadTodaySummary` + `loadSummaryForDate`: the date is
  /// [_dateKey], so the merge can never pull another day's meals in.
  ///   1. In-memory cache hit (<5 min, same user) → return, clearing any error.
  ///   2. Else, if in-memory is empty, seed from the per-date disk cache.
  ///   3. Network fetch → merge → persist to disk for the next cold start.
  ///   4. On failure: keep any data on screen, only surface error if empty.
  Future<void> load(String userId, {bool forceRefresh = false}) async {
    // (1) In-memory freshness short-circuit.
    if (!forceRefresh && _fresh(userId) && state.summary != null) {
      if (state.error != null) state = state.copyWith(error: null);
      return;
    }

    // (2) Disk seed when in-memory is empty.
    if (!forceRefresh && state.summary == null) {
      state = state.copyWith(isLoading: true, error: null);
      final cached = await _NutritionDiskCache.read(userId, _dateKey);
      if (cached != null) {
        debugPrint('🥗 [Nutrition] Seeded $_dateKey from disk cache');
        state = state.copyWith(isLoading: false, summary: cached);
      }
      // else: keep isLoading=true, the network call below resolves it
    } else {
      state = state.copyWith(error: null);
    }

    final stopwatch = Stopwatch()..start();
    final epoch = ++_summaryLoadEpoch;
    // Snapshot what's on screen NOW so the merge can protect a just-logged meal.
    final localBefore = state.summary;
    try {
      final raw = await _repository.getDailySummary(userId, date: _dateKey);
      debugPrint(
        '🥗 [Nutrition] load($_dateKey) network: ${stopwatch.elapsedMilliseconds}ms '
        '(meals=${raw.meals.length}, kcal=${raw.totalCalories})',
      );
      if (epoch != _summaryLoadEpoch) return;
      // A raced response for a DIFFERENT date must never render here.
      if (raw.date.isNotEmpty && raw.date != _dateKey) return;
      final summary = _mergeServerSummary(raw, localBefore);
      state = state.copyWith(isLoading: false, summary: summary);
      _lastLoadedUserId = userId;
      _lastLoadTime = DateTime.now();

      // Persist per-date for instant revisit / cold start.
      unawaited(_NutritionDiskCache.write(userId, _dateKey, summary));

      if (_isToday) {
        // A successful read proves we're online — drain any stranded queue.
        unawaited(
            _ref.read(nutritionMetaProvider.notifier).flushMealQueue(userId));
        // Home food widget + XP only ever track TODAY.
        final t = _ref.read(nutritionMetaProvider).targets;
        unawaited(WidgetService.updateFoodWidget(
          caloriesConsumed: summary.totalCalories,
          calorieGoal: t?.dailyCalorieTarget ?? 2000,
          proteinGrams: summary.totalProteinG.round(),
          carbsGrams: summary.totalCarbsG.round(),
          fatGrams: summary.totalFatG.round(),
        ));
        _checkProteinGoal(summary);
      }
    } catch (e) {
      debugPrint(
        '🥗 [Nutrition] load($_dateKey) FAILED after ${stopwatch.elapsedMilliseconds}ms: $e',
      );
      if (epoch != _summaryLoadEpoch) return;
      if (state.summary == null) {
        state = state.copyWith(isLoading: false, error: e.toString());
      } else {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// Check if user hit their daily protein goal and award XP (today only).
  void _checkProteinGoal(DailyNutritionSummary summary) {
    final targets = _ref.read(nutritionMetaProvider).targets;
    if (targets == null) return;

    final proteinConsumed = summary.totalProteinG ?? 0;
    final proteinTarget = targets.dailyProteinTargetG ?? 150;

    if (proteinConsumed >= proteinTarget) {
      debugPrint('🎯 [Nutrition] Protein goal hit! ${proteinConsumed.toInt()}g / ${proteinTarget.toInt()}g');
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
    final targets = _ref.read(nutritionMetaProvider).targets;
    if (targets == null) return;

    final caloriesConsumed = summary.totalCalories;
    final calorieTarget = targets.dailyCalorieTarget;
    if (calorieTarget == null || calorieTarget <= 0) return;

    final floor = (calorieTarget * 0.8).round();
    if (caloriesConsumed >= floor && caloriesConsumed < calorieTarget) {
      debugPrint('🎯 [Nutrition] Calorie deficit hit! $caloriesConsumed / $calorieTarget kcal');
      _ref.read(xpProvider.notifier).markCalorieGoalHit();
    }
  }

  /// Load this date's food logs. For today this uses the recent-logs path with
  /// unsynced-row protection; for past dates it fetches the [date, date+1] range
  /// and filters to this local date (so a log that lands on the next UTC day due
  /// to timezone offset is still included).
  Future<void> loadLogs(String userId,
      {int limit = 50, bool forceRefresh = false}) async {
    if (_isToday) {
      if (!forceRefresh && _fresh(userId) && state.logs.isNotEmpty) {
        debugPrint('🥗 [Nutrition] Skipping loadLogs(today) - data is fresh');
        return;
      }
      try {
        final logs = await _repository.getFoodLogs(userId, limit: limit);
        // Don't let an empty (stale/cached/flaky) response wipe logs still on
        // screen when an unsynced or just-written local row is present.
        if (logs.isEmpty && _hasUnconfirmedOrRecentLocalLog()) {
          debugPrint(
              '🥗 [Nutrition] loadLogs: ignored empty response — unsynced/recent local log present');
        } else {
          final unsynced = [
            for (final l in state.logs)
              if (l.id.startsWith('optimistic_') &&
                  !logs.any((s) =>
                      s.id == l.id ||
                      (l.idempotencyKey != null &&
                          l.idempotencyKey!.isNotEmpty &&
                          s.idempotencyKey == l.idempotencyKey)))
                l,
          ];
          final merged = unsynced.isEmpty ? logs : [...unsynced, ...logs];
          state = state.copyWith(logs: merged);
        }
        _lastLoadedUserId = userId;
        unawaited(
            _ref.read(nutritionMetaProvider.notifier).flushMealQueue(userId));
      } catch (e) {
        debugPrint('Error loading recent food logs: $e');
      }
      return;
    }

    // Past / other date — fetch [date, date+1] and filter to this local date.
    try {
      final date = DateTime.parse(_dateKey);
      final nextDayStr = nutritionKeyFor(date.add(const Duration(days: 1)));
      final rawLogs = await _repository.getFoodLogs(userId,
          fromDate: _dateKey, toDate: nextDayStr);
      final logs = rawLogs.where((log) {
        final local = log.loggedAt.isUtc ? log.loggedAt.toLocal() : log.loggedAt;
        return nutritionKeyFor(local) == _dateKey;
      }).toList();
      state = state.copyWith(logs: logs);
      _lastLoadedUserId = userId;
    } catch (e) {
      debugPrint('Error loading food logs for $_dateKey: $e');
    }
  }

  /// True when `logs` holds an UNSYNCED row (optimistic id) or a row written
  /// within the last 120 s. An all-old, all-synced list returns false, so a
  /// genuine "everything deleted" empty response is still accepted.
  bool _hasUnconfirmedOrRecentLocalLog() {
    if (state.logs.isEmpty) return false;
    final cutoff = DateTime.now().subtract(const Duration(seconds: 120));
    return state.logs.any(
        (l) => l.id.startsWith('optimistic_') || l.createdAt.isAfter(cutoff));
  }

  /// Force refresh this date's summary + logs (and the user-level targets).
  Future<void> refreshAll(String userId) async {
    _lastLoadTime = null; // clear cache
    await Future.wait([
      load(userId, forceRefresh: true),
      loadLogs(userId, forceRefresh: true),
      _ref
          .read(nutritionMetaProvider.notifier)
          .loadTargets(userId, forceRefresh: true),
    ]);
  }

  /// Delete a food log (synchronous flow — force-refresh after).
  Future<void> deleteLog(String userId, String logId) async {
    try {
      await _repository.deleteFoodLog(logId);
      await load(userId, forceRefresh: true);
      await loadLogs(userId, forceRefresh: true);
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
    final summary = state.summary;
    if (summary == null) return null;
    final idx = summary.meals.indexWhere((m) => m.id == logId);
    if (idx < 0) return null;
    final removed = summary.meals[idx];
    final remaining = [...summary.meals]..removeAt(idx);
    // Tombstone the id so an in-flight background refresh can't resurrect it.
    _deletedTombstones.add(logId);
    // Keep `logs` consistent so the history list never shows a meal the summary
    // just dropped (#12 divergence — the two lists are independent).
    final nextLogs = state.logs.any((m) => m.id == logId)
        ? state.logs.where((m) => m.id != logId).toList()
        : state.logs;
    state = state.copyWith(
      summary: _recomputeTotals(summary, remaining),
      logs: nextLogs,
    );
    return removed;
  }

  /// Replace the meal with the given id by applying [transform] to it.
  /// Returns the original meal so callers can roll back on network failure.
  /// No-op + null return when the id isn't in `todaySummary` (e.g. viewing
  /// a different date than the meal lives on).
  FoodLog? optimisticUpdateLog(String logId, FoodLog Function(FoodLog) transform) {
    final summary = state.summary;
    if (summary == null) return null;
    final idx = summary.meals.indexWhere((m) => m.id == logId);
    if (idx < 0) return null;
    final original = summary.meals[idx];
    final updated = transform(original);
    final next = [...summary.meals]..[idx] = updated;
    state = state.copyWith(summary: _recomputeTotals(summary, next));
    return original;
  }

  /// (WR9b) Reconcile an optimistic row to its authoritative server identity.
  /// Once `/nutrition/log-direct` returns the real `food_log_id`, swap the
  /// synthetic `optimistic_<ts>` id for it (and stamp the idempotency key) in
  /// BOTH `todaySummary.meals` and `recentLogs`, in place. This makes a later
  /// summary refresh dedupe by id, and makes any delete/edit target the
  /// PERSISTED row instead of the phantom. Without it, the merge re-adds the
  /// optimistic row next to the server row — the duplicate the user sees, where
  /// deleting one then orphans the survivor and the day vanishes on reload.
  ///
  /// No-op if the optimistic row is already gone (deleted, or already replaced
  /// by the key-based merge). If the server row is ALSO present (a refresh
  /// raced ahead and merged by key), the optimistic duplicate is dropped rather
  /// than creating two rows that share the real id.
  void reconcileLoggedMeal(String optimisticId, String realId,
      {String? idempotencyKey}) {
    if (optimisticId == realId || realId.isEmpty) return;

    // Tombstones are keyed by id. If the user deleted the optimistic row before
    // the save returned, carry that delete forward to the real id so an in-
    // flight refresh can't resurrect the now-persisted row.
    if (_deletedTombstones.remove(optimisticId)) {
      _deletedTombstones.add(realId);
    }

    List<FoodLog> reconcileList(List<FoodLog> list) {
      final idx = list.indexWhere((m) => m.id == optimisticId);
      if (idx < 0) return list;
      final next = [...list];
      if (next.any((m) => m.id == realId)) {
        // Server row already merged in by key — drop the optimistic duplicate.
        next.removeAt(idx);
      } else {
        next[idx] = next[idx]
            .copyWith(id: realId, idempotencyKey: idempotencyKey);
      }
      return next;
    }

    final summary = state.summary;
    final logs = state.logs;
    final nextLogs = reconcileList(logs);

    DailyNutritionSummary? nextSummary = summary;
    if (summary != null) {
      final nextMeals = reconcileList(summary.meals);
      if (!identical(nextMeals, summary.meals)) {
        nextSummary = _recomputeTotals(summary, nextMeals);
      }
    }

    final summaryChanged = !identical(nextSummary, summary);
    final logsChanged = !identical(nextLogs, logs);
    if (summaryChanged || logsChanged) {
      state = state.copyWith(summary: nextSummary, logs: nextLogs);
    }
  }

  /// Re-insert a meal previously removed via [optimisticRemoveLog]. Used by
  /// the Undo action on swipe-delete. Inserts at the position that keeps
  /// the list sorted by `loggedAt` ascending.
  void restoreLog(FoodLog meal) {
    final summary = state.summary;
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
    // Restore into `logs` too (optimisticRemoveLog dropped it from both), so
    // Undo brings the meal back to the history list as well as the summary.
    final logs = state.logs.any((m) => m.id == meal.id)
        ? state.logs
        : [meal, ...state.logs];
    state = state.copyWith(
      summary: _recomputeTotals(summary, list),
      logs: logs,
    );
  }

  /// Instantly add an already-constructed [FoodLog] to local state.
  /// Use this when callers have already converted the API response to a
  /// [FoodLog] (e.g. recipe logging, browser-panel relog).
  void spliceRawLog(FoodLog newLog, String userId) {
    final updatedLogs = [newLog, ...state.logs];
    final currentSummary = state.summary;
    final updatedMeals = <FoodLog>[...(currentSummary?.meals ?? []), newLog];
    final newSummary = _recomputeTotals(
      currentSummary ??
          DailyNutritionSummary(
            date: _dateKey,
            totalCalories: 0,
            totalProteinG: 0,
            totalCarbsG: 0,
            totalFatG: 0,
            totalFiberG: 0,
            mealCount: 0,
          ),
      updatedMeals,
    );
    state = state.copyWith(logs: updatedLogs, summary: newSummary);
    unawaited(_NutritionDiskCache.write(userId, _dateKey, newSummary));
  }

  /// Instantly add a newly logged meal to local state so the UI updates
  /// before the network round-trip that `loadTodaySummary(forceRefresh)`
  /// would otherwise require. The background refresh that follows (still
  /// fired by the log sheet) reconciles server-derived fields.
  ///
  /// (Part 4 / WR1) Returns the optimistic [FoodLog] it spliced in so the
  /// caller can pass its `id` to [optimisticRemoveLog] for a clean WR4
  /// rollback if the background `/nutrition/log-direct` POST later fails.
  FoodLog spliceLog(LogFoodResponse response, String mealType, String userId,
      {String? idempotencyKey}) {
    final now = DateTime.now();
    // Today → now; a past-date backfill → that date with the current time, so
    // the optimistic row sorts on the right day until the server row replaces it.
    final loggedAt = _isToday ? now : _dateAtNow();
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
      // (WR9b) Stamp the same client key the write carries so the merge can
      // reconcile this optimistic row against the authoritative server row by
      // key — immune to the synthetic id never matching the server's UUID.
      idempotencyKey: idempotencyKey,
      userId: userId,
      mealType: mealType,
      loggedAt: loggedAt,
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

    final updatedLogs = [newLog, ...state.logs];
    final currentSummary = state.summary;
    final updatedMeals = <FoodLog>[
      ...(currentSummary?.meals ?? []),
      newLog,
    ];
    final newSummary = _recomputeTotals(
      currentSummary ??
          DailyNutritionSummary(
            date: _dateKey,
            totalCalories: 0,
            totalProteinG: 0,
            totalCarbsG: 0,
            totalFatG: 0,
            totalFiberG: 0,
            mealCount: 0,
          ),
      updatedMeals,
    );

    state = state.copyWith(logs: updatedLogs, summary: newSummary);

    // Persist the updated totals so the next cold-start shows the new log.
    unawaited(_NutritionDiskCache.write(userId, _dateKey, newSummary));

    // If this splice corresponds to an offline-queued write, reflect the
    // pending-sync badge immediately rather than waiting for the next load.
    unawaited(_ref
        .read(nutritionMetaProvider.notifier)
        .refreshPendingMealCount(userId));

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
    final loggedAt = _isToday ? now : _dateAtNow();
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
          'optimistic_${now.microsecondsSinceEpoch}_${state.logs.length}',
      userId: userId,
      mealType: mealType,
      loggedAt: loggedAt,
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
      unawaited(loadLogs(userId, forceRefresh: true));
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
  ///  - matches a local optimistic row to its authoritative server row by
  ///    `idempotency_key` (not the synthetic `optimistic_<ts>` id), so a
  ///    just-reconciled row is recognised as already-present and never re-added
  ///    as a phantom duplicate — even if a refresh raced ahead of the id swap;
  ///  - re-adds a local meal the payload omitted when it is still UNSYNCED
  ///    (synthetic `optimistic_` id — its `/log-direct` write hasn't confirmed)
  ///    regardless of age, so a slow / failed / offline-queued save can never
  ///    silently drop a logged meal. A CONFIRMED local row (real id) the server
  ///    momentarily omits is re-added only within a short cache-lag window, so
  ///    a genuine cross-device delete still reconciles instead of resurrecting
  ///    forever.
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
      // Server identity = real ids ∪ idempotency keys. A reconciled or keyed
      // local row matches its server row by EITHER, so it is never re-added.
      final presentIds = meals.map((m) => m.id).toSet();
      final presentKeys = <String>{
        for (final m in meals)
          if (m.idempotencyKey != null && m.idempotencyKey!.isNotEmpty)
            m.idempotencyKey!,
      };
      // Confirmed rows the server momentarily omits (cache lag) are re-added
      // only within this short window; unsynced rows are re-added regardless.
      final cutoff = DateTime.now().subtract(const Duration(seconds: 120));
      final extras = <FoodLog>[
        for (final m in local.meals)
          if (!presentIds.contains(m.id) &&
              !(m.idempotencyKey != null &&
                  m.idempotencyKey!.isNotEmpty &&
                  presentKeys.contains(m.idempotencyKey)) &&
              !_deletedTombstones.contains(m.id) &&
              (m.id.startsWith('optimistic_') || m.createdAt.isAfter(cutoff)))
            m,
      ];
      if (extras.isNotEmpty) {
        meals = [...meals, ...extras];
        changed = true;
      }
    }

    return changed ? _recomputeTotals(server, meals) : server;
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

