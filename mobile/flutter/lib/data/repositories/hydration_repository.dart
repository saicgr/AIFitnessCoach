import 'dart:async';
import 'dart:convert';
import 'dart:math' show Random;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hydration.dart';
import '../services/api_client.dart';
import '../services/custom_bottle_store.dart';
import '../services/widget_service.dart';
import '../../utils/tz.dart';
import '../services/health_service.dart';
import '../providers/xp_provider.dart';
import '../providers/timeline_provider.dart';
import '../providers/nutrition_preferences_provider.dart';

/// In-memory cache for instant display on provider recreation
/// Survives provider invalidation and prevents loading flash
HydrationState? _hydrationInMemoryCache;

/// Generate a client-side idempotency key for a hydration write.
///
/// Attached to every log/quick-log request so a rapid double-tap (or an
/// offline-queued write that is later replayed) cannot double-count water on
/// the server — the backend de-dupes on this key. Format: a timestamp plus a
/// random suffix, unique enough for a single device's write stream.
String _newIdempotencyKey() {
  final ts = DateTime.now().microsecondsSinceEpoch;
  final rand = Random().nextInt(1 << 32).toRadixString(16);
  return 'hyd_${ts}_$rand';
}

// ===========================================================================
// _HydrationDiskCache — stale-while-revalidate disk cache (A2)
// ===========================================================================

/// Persistent (cross-launch) cache for the user's daily hydration summary.
///
/// Mirrors `_NutritionDiskCache` in
/// `nutrition_repository_part_food_logging_progress.dart`: a JSON-encoded
/// `DailyHydrationSummary` in a versioned envelope, keyed by user_id and
/// stamped with the LOCAL calendar date so yesterday's water can never render
/// as today's. Powers cold-start stale-while-revalidate on the Water tile.
class _HydrationDiskCache {
  static const _prefix = 'hydration_summary_v1::';
  static const _schemaVersion = 1;

  static String _key(String userId) => '$_prefix$userId';

  /// Read the cached summary IF it is for [todayStr] (the caller's current
  /// local date). A date or schema mismatch is dropped (returns null), never
  /// thrown — a stale cache is worse than a brief skeleton.
  static Future<DailyHydrationSummary?> read(String userId, String todayStr) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(userId));
      if (raw == null || raw.isEmpty) return null;
      final envelope = jsonDecode(raw);
      if (envelope is! Map<String, dynamic>) return null;
      // Versioned envelope — drop on schema bump instead of crashing.
      if (envelope['v'] != _schemaVersion) return null;
      // Local-date guard (A12a): a Wednesday cache must not seed Thursday.
      if (envelope['date'] != todayStr) return null;
      final body = envelope['summary'];
      if (body is! Map<String, dynamic>) return null;
      return DailyHydrationSummary.fromJson(body);
    } catch (e) {
      debugPrint('💧 [HydrationDiskCache] read failed: $e');
      return null;
    }
  }

  /// Write-through the summary for [todayStr]. Best-effort — a failure only
  /// costs a slower next cold start.
  static Future<void> write(
    String userId,
    String todayStr,
    DailyHydrationSummary summary,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(userId),
        jsonEncode({
          'v': _schemaVersion,
          'date': todayStr,
          'cached_at': DateTime.now().toIso8601String(),
          'summary': summary.toJson(),
        }),
      );
    } catch (e) {
      debugPrint('💧 [HydrationDiskCache] write failed: $e');
    }
  }

  /// Drop the cache — provided for logout / account-switch cleanup parity
  /// with `_NutritionDiskCache.clear`.
  // ignore: unused_element
  static Future<void> clear(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(userId));
    } catch (_) {/* best-effort */}
  }
}

// ===========================================================================
// _HydrationWriteQueue — offline write queue (A11)
// ===========================================================================

/// One queued hydration write, persisted to disk so it survives an app kill.
class _QueuedHydrationWrite {
  final String idempotencyKey;
  final String userId;
  final String drinkType;
  final int amountMl;
  final String? workoutId;
  final String? notes;
  final String localDate;
  final String source; // HydrationSource.value
  final int queuedAtMs;

  _QueuedHydrationWrite({
    required this.idempotencyKey,
    required this.userId,
    required this.drinkType,
    required this.amountMl,
    required this.workoutId,
    required this.notes,
    required this.localDate,
    required this.source,
    required this.queuedAtMs,
  });

  Map<String, dynamic> toJson() => {
        'idempotency_key': idempotencyKey,
        'user_id': userId,
        'drink_type': drinkType,
        'amount_ml': amountMl,
        if (workoutId != null) 'workout_id': workoutId,
        if (notes != null) 'notes': notes,
        'local_date': localDate,
        'source': source,
        'queued_at_ms': queuedAtMs,
      };

  factory _QueuedHydrationWrite.fromJson(Map<String, dynamic> j) =>
      _QueuedHydrationWrite(
        idempotencyKey: j['idempotency_key'] as String,
        userId: j['user_id'] as String,
        drinkType: j['drink_type'] as String,
        amountMl: (j['amount_ml'] as num).toInt(),
        workoutId: j['workout_id'] as String?,
        notes: j['notes'] as String?,
        localDate: j['local_date'] as String,
        source: j['source'] as String,
        queuedAtMs: (j['queued_at_ms'] as num).toInt(),
      );
}

/// Disk-backed FIFO queue of hydration writes made while offline.
///
/// On a connectivity-restored event the queue flushes in order, de-duped by
/// idempotency key. The same key also rides on the request body so even a
/// partial-flush-then-online-retry can't double-log. Persisted under a
/// versioned, user-scoped SharedPreferences key.
class _HydrationWriteQueue {
  static const _prefix = 'hydration_write_queue_v1::';
  static const _schemaVersion = 1;

  static String _key(String userId) => '$_prefix$userId';

  /// Append a write to the on-disk queue, de-duping on idempotency key.
  static Future<void> enqueue(_QueuedHydrationWrite write) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await _read(prefs, write.userId);
      if (list.any((w) => w.idempotencyKey == write.idempotencyKey)) {
        return; // already queued — never enqueue twice
      }
      list.add(write);
      await _persist(prefs, write.userId, list);
      debugPrint('💧 [HydrationQueue] enqueued (depth=${list.length})');
    } catch (e) {
      debugPrint('💧 [HydrationQueue] enqueue failed: $e');
    }
  }

  static Future<List<_QueuedHydrationWrite>> _read(
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
          .map((m) => _QueuedHydrationWrite.fromJson(
              Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _persist(SharedPreferences prefs, String userId,
      List<_QueuedHydrationWrite> list) async {
    if (list.isEmpty) {
      await prefs.remove(_key(userId));
      return;
    }
    await prefs.setString(
      _key(userId),
      jsonEncode({
        'v': _schemaVersion,
        'items': list.map((w) => w.toJson()).toList(),
      }),
    );
  }

  /// Drain the queue in FIFO order via [send]. Stops on the first transient
  /// failure (network flaked again) and re-persists the remainder so order
  /// and idempotency are preserved for the next online event.
  static Future<int> flush(
    String userId,
    Future<bool> Function(_QueuedHydrationWrite) send,
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
      debugPrint('💧 [HydrationQueue] flushed $flushed, remaining ${list.length}');
      return flushed;
    } catch (e) {
      debugPrint('💧 [HydrationQueue] flush failed: $e');
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

/// Hydration repository provider
final hydrationRepositoryProvider = Provider<HydrationRepository>((ref) {
  return HydrationRepository(ref.watch(apiClientProvider));
});

/// Hydration state
class HydrationState {
  final bool isLoading;
  final String? error;
  final DailyHydrationSummary? todaySummary;
  final List<HydrationLog> recentLogs;
  final int dailyGoalMl;

  const HydrationState({
    this.isLoading = false,
    this.error,
    this.todaySummary,
    this.recentLogs = const [],
    this.dailyGoalMl = 2500,
  });

  HydrationState copyWith({
    bool? isLoading,
    String? error,
    DailyHydrationSummary? todaySummary,
    List<HydrationLog>? recentLogs,
    int? dailyGoalMl,
  }) {
    return HydrationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      todaySummary: todaySummary ?? this.todaySummary,
      recentLogs: recentLogs ?? this.recentLogs,
      dailyGoalMl: dailyGoalMl ?? this.dailyGoalMl,
    );
  }
}

/// Hydration state provider
final hydrationProvider =
    StateNotifierProvider<HydrationNotifier, HydrationState>((ref) {
  return HydrationNotifier(ref.watch(hydrationRepositoryProvider), ref);
});

/// Hydration state notifier
class HydrationNotifier extends StateNotifier<HydrationState> {
  final HydrationRepository _repository;
  final Ref _ref;

  /// Monotonic counter to discard stale responses from earlier loads.
  /// Incremented at the start of every [loadTodaySummary]; the response is
  /// only applied when the epoch still matches (i.e. no newer load started).
  int _loadEpoch = 0;

  /// When the last optimistic +water write happened. Used to reject a stale
  /// server summary (lower total) that would wipe a just-logged drink before
  /// the backend cache catches up.
  DateTime? _lastOptimisticAddAt;

  /// Local calendar date the current [HydrationState.todaySummary] belongs to
  /// (yyyy-MM-dd, device tz). Used to detect a midnight/timezone rollover
  /// while the app is open (A12a) so stale water doesn't persist into the new
  /// day.
  String? _loadedDate;

  /// The last user we loaded for — needed by the connectivity flush callback.
  String? _lastUserId;

  /// Connectivity subscription that flushes the offline write queue when the
  /// network is restored (A11).
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  bool _isFlushing = false;

  HydrationNotifier(this._repository, this._ref)
      : super(_hydrationInMemoryCache ?? const HydrationState()) {
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn);
      if (online) {
        // Defer slightly so the radio + DNS settle before hitting the API.
        Future.delayed(const Duration(milliseconds: 800), _flushQueue);
      }
    });
  }

  /// Clear in-memory cache (called on logout)
  static void clearCache() {
    _hydrationInMemoryCache = null;
    debugPrint('🧹 [HydrationProvider] In-memory cache cleared');
  }

  /// Push the latest hydration state to the native home-screen water widget,
  /// carrying the Gap-6 enabled flag + the Gap-5 saved bottles. Fire-and-forget;
  /// never throws into the load path.
  Future<void> _syncWaterWidget(String userId, int currentMl, int goalMl) async {
    try {
      final enabled = _ref
              .read(nutritionPreferencesProvider)
              .preferences
              ?.hydrationTrackingEnabled ??
          true;
      final bottles = await CustomBottleStore.load(userId);
      await WidgetService.updateWaterWidget(
        currentMl: currentMl,
        goalMl: goalMl,
        enabled: enabled,
        bottles: [
          for (final b in bottles) {'label': b.label, 'ml': b.ml},
        ],
      );
    } catch (e) {
      debugPrint('💧 [HydrationProvider] water widget sync skipped: $e');
    }
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }

  /// Detect a local-date rollover (midnight crossed, or timezone changed)
  /// while the app stayed open. When the day has changed, the cached
  /// `todaySummary` belongs to a stale day, so we drop it and force a fresh
  /// load. (A12a)
  void _invalidateOnDateRollover() {
    final today = Tz.localDate();
    if (_loadedDate != null && _loadedDate != today) {
      debugPrint('💧 [Hydration] Local date rolled over $_loadedDate → $today — invalidating cache');
      _loadedDate = null;
      _hydrationInMemoryCache = null;
      // Drop the now-stale summary; the next loadTodaySummary refetches.
      state = HydrationState(dailyGoalMl: state.dailyGoalMl);
      ++_loadEpoch; // discard any in-flight load tied to the old day
    }
  }

  /// Flush the offline write queue, sending each write with its original
  /// idempotency key so the server de-dupes any that already landed.
  Future<void> _flushQueue() async {
    final userId = _lastUserId;
    if (userId == null || _isFlushing) return;
    if (await _HydrationWriteQueue.isEmpty(userId)) return;
    _isFlushing = true;
    try {
      final flushed = await _HydrationWriteQueue.flush(userId, (w) async {
        try {
          await _repository.logHydration(
            userId: w.userId,
            drinkType: w.drinkType,
            amountMl: w.amountMl,
            workoutId: w.workoutId,
            notes: w.notes,
            localDate: w.localDate,
            source: HydrationSource.fromString(w.source),
            idempotencyKey: w.idempotencyKey,
          );
          return true;
        } catch (e) {
          debugPrint('💧 [Hydration] queued flush item failed: $e');
          return false; // transient — keep it (and the rest) queued
        }
      });
      if (flushed > 0) {
        // Reconcile in-memory state with the server now that writes landed.
        await loadTodaySummary(userId, showLoading: false);
      }
    } finally {
      _isFlushing = false;
    }
  }

  /// Pre-seed state from bootstrap data so the home screen shows hydration instantly.
  void preSeedFromBootstrap({required int currentMl, required int targetMl}) {
    if (state.todaySummary != null) return; // Don't overwrite real data
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    state = state.copyWith(
      todaySummary: DailyHydrationSummary(
        date: todayStr,
        totalMl: currentMl,
        waterMl: currentMl,
        goalMl: targetMl,
        goalPercentage: targetMl > 0 ? (currentMl / targetMl * 100).clamp(0, 100) : 0,
      ),
      dailyGoalMl: targetMl,
    );
    debugPrint('⚡ [Hydration] Pre-seeded from bootstrap');
  }

  /// Load today's hydration summary.
  ///
  /// Stale-while-revalidate (A2): when in-memory state is empty, seed from the
  /// disk cache and render immediately, then refresh from the network. Every
  /// successful load (and every mutation) writes through to disk.
  ///
  /// Set [showLoading] to false for background refreshes (e.g., after adding
  /// water).
  Future<void> loadTodaySummary(String userId, {bool showLoading = true}) async {
    // (A12a) Drop a summary left over from a previous calendar day before we
    // decide whether the in-memory state counts as "data on screen".
    _invalidateOnDateRollover();

    _lastUserId = userId;
    final localDate = Tz.localDate();
    final epoch = ++_loadEpoch;

    // Disk seed — only when in-memory state has nothing for today. Renders
    // instantly with no skeleton while the network call runs in parallel.
    if (state.todaySummary == null) {
      if (showLoading) {
        state = state.copyWith(isLoading: true, error: null);
      }
      final cached = await _HydrationDiskCache.read(userId, localDate);
      if (cached != null && _loadEpoch == epoch) {
        debugPrint('💧 [Hydration] Seeded from disk cache for $localDate');
        state = state.copyWith(
          isLoading: false,
          todaySummary: cached,
          dailyGoalMl: cached.goalMl > 0 ? cached.goalMl : state.dailyGoalMl,
        );
        _loadedDate = localDate;
      }
    } else if (showLoading) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      // Pass local date to avoid UTC mismatch on server (Render runs in UTC)
      final summary = await _repository.getDailySummary(userId, date: localDate);
      // Only apply if no newer load was started while we were awaiting
      if (_loadEpoch != epoch) return;
      // Reject a stale/cached server payload: if a drink was logged in the
      // last 90 s and the server total is LOWER than what's on screen, the
      // response predates that write — keep local; the next refetch (after
      // the backend cache busts) reconciles. A delete legitimately lowers the
      // total but does not set `_lastOptimisticAddAt`, so it is unaffected.
      final local = state.todaySummary;
      final recentAdd = _lastOptimisticAddAt != null &&
          DateTime.now().difference(_lastOptimisticAddAt!) <
              const Duration(seconds: 90);
      if (recentAdd && local != null && summary.totalMl < local.totalMl) {
        debugPrint('💧 [Hydration] kept local total — server response stale');
        state = state.copyWith(isLoading: false);
        return;
      }
      state = state.copyWith(
        isLoading: false,
        todaySummary: summary,
        dailyGoalMl: summary.goalMl,
      );
      _loadedDate = localDate;
      // Update in-memory cache for instant access on provider recreation
      _hydrationInMemoryCache = state;
      // Write through to disk for the next cold start.
      unawaited(_HydrationDiskCache.write(userId, localDate, summary));

      // Home-screen water widget — push fresh totals + pref + saved bottles.
      unawaited(_syncWaterWidget(userId, summary.totalMl, summary.goalMl));

      _checkHydrationGoal(summary);
    } catch (e) {
      if (_loadEpoch != epoch) return;
      // Keep any cached/optimistic data on screen; only surface the error
      // when we have nothing else to show.
      if (state.todaySummary == null) {
        state = state.copyWith(isLoading: false, error: e.toString());
      } else {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// Fire-once-per-day XP award when the user crosses their hydration goal.
  /// `markHydrationGoalHit` is idempotent — subsequent calls are no-ops.
  void _checkHydrationGoal(DailyHydrationSummary summary) {
    if (summary.goalMl > 0 && summary.totalMl >= summary.goalMl) {
      _ref.read(xpProvider.notifier).markHydrationGoalHit();
    }
  }

  /// Apply an optimistic +[amountMl] of [drinkType] to `todaySummary` and
  /// return the PRE-mutation summary so the caller can roll back on failure.
  /// When `todaySummary` is null (first log before initial load) a fresh
  /// summary is created; the returned snapshot is then null, meaning "roll
  /// back by clearing".
  DailyHydrationSummary? _applyOptimistic(String drinkType, int amountMl) {
    final snapshot = state.todaySummary;
    final currentSummary = snapshot ??
        DailyHydrationSummary(date: Tz.localDate(), goalMl: state.dailyGoalMl);
    final newTotal = currentSummary.totalMl + amountMl;
    final goalMl =
        currentSummary.goalMl > 0 ? currentSummary.goalMl : state.dailyGoalMl;
    state = state.copyWith(
      // Clear any prior error so a fresh tap surfaces a clean state.
      error: null,
      todaySummary: DailyHydrationSummary(
        date: currentSummary.date,
        totalMl: newTotal,
        waterMl: drinkType == 'water'
            ? currentSummary.waterMl + amountMl
            : currentSummary.waterMl,
        proteinShakeMl: drinkType == 'protein_shake'
            ? currentSummary.proteinShakeMl + amountMl
            : currentSummary.proteinShakeMl,
        sportsDrinkMl: drinkType == 'sports_drink'
            ? currentSummary.sportsDrinkMl + amountMl
            : currentSummary.sportsDrinkMl,
        otherMl: (drinkType != 'water' &&
                drinkType != 'protein_shake' &&
                drinkType != 'sports_drink')
            ? currentSummary.otherMl + amountMl
            : currentSummary.otherMl,
        goalMl: goalMl,
        goalPercentage: goalMl > 0 ? newTotal / goalMl : 0,
        entries: currentSummary.entries,
      ),
    );
    _lastOptimisticAddAt = DateTime.now();
    return snapshot;
  }

  /// Roll the optimistic mutation back to [snapshot] and surface a calm error
  /// the UI can show. [snapshot] null means the optimistic write created the
  /// first summary — roll back by clearing it.
  void _rollback(DailyHydrationSummary? snapshot, Object error) {
    state = HydrationState(
      isLoading: false,
      todaySummary: snapshot,
      recentLogs: state.recentLogs,
      dailyGoalMl: state.dailyGoalMl,
      error: 'Could not save your water log. We\'ll retry when you\'re back online.',
    );
    debugPrint('💧 [Hydration] optimistic write rolled back: $error');
  }

  /// Whether the device currently has connectivity. Used to decide between a
  /// live write and an offline-queued one.
  Future<bool> _isOnline() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.any((r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn);
    } catch (_) {
      return true; // assume online on error — the write itself will fail-fast
    }
  }

  /// Log hydration. `source` is the surface this came from
  /// (HydrationSource enum) — drives the per-row icon + badge in the
  /// Fuel/Water tab Today's Log. Defaults to manual when unspecified so the
  /// UI never renders an empty origin.
  ///
  /// Optimistic + offline-safe (A11):
  ///  • The UI total updates IMMEDIATELY, before the network call.
  ///  • A client-generated idempotency key is attached so a rapid double-tap
  ///    cannot double-log.
  ///  • Offline: the write is persisted to the disk queue and flushed on the
  ///    next connectivity-restored event. The optimistic total stays.
  ///  • Online failure: the optimistic change is rolled back and a calm error
  ///    is exposed on `state.error`.
  Future<bool> logHydration({
    required String userId,
    required String drinkType,
    required int amountMl,
    String? workoutId,
    String? notes,
    HydrationSource source = HydrationSource.manual,
  }) async {
    _lastUserId = userId;
    final idempotencyKey = _newIdempotencyKey();
    final localDate = Tz.localDate();
    // Invalidate any in-flight background load so it doesn't overwrite
    ++_loadEpoch;
    final snapshot = _applyOptimistic(drinkType, amountMl);

    // Offline → queue and keep the optimistic total. No rollback.
    if (!await _isOnline()) {
      await _HydrationWriteQueue.enqueue(_QueuedHydrationWrite(
        idempotencyKey: idempotencyKey,
        userId: userId,
        drinkType: drinkType,
        amountMl: amountMl,
        workoutId: workoutId,
        notes: notes,
        localDate: localDate,
        source: source.value,
        queuedAtMs: DateTime.now().millisecondsSinceEpoch,
      ));
      // Persist the optimistic summary so a cold start still shows it.
      final s = state.todaySummary;
      if (s != null) unawaited(_HydrationDiskCache.write(userId, localDate, s));
      debugPrint('💧 [Hydration] offline — log queued ($idempotencyKey)');
      return true;
    }

    try {
      await _repository.logHydration(
        userId: userId,
        drinkType: drinkType,
        amountMl: amountMl,
        workoutId: workoutId,
        notes: notes,
        localDate: localDate,
        source: source,
        idempotencyKey: idempotencyKey,
      );

      // Fire-and-forget: sync hydration to Health Connect / HealthKit
      HealthService.syncHydrationToHealthIfEnabled(amountMl: amountMl);

      // Refresh summary in background (no loading indicator). This reconciles
      // the optimistic total with the authoritative server value in place.
      await loadTodaySummary(userId, showLoading: false);

      // Home "Today's Journal" reads timelineProvider, which has its own
      // cached state. Backend already invalidates its server-side cache on
      // /hydration/log (see backend/api/v1/hydration.py invalidate_timeline_cache),
      // but the Riverpod state needs an explicit refresh so the new water
      // entry actually appears without pull-to-refresh.
      // ignore: unawaited_futures
      _ref.read(timelineProvider.notifier).refresh();
      // The home trends rail's WATER tile reads timelineTrendsProvider (a
      // separate 14-day metrics_only fetch), so it must be refreshed too or it
      // shows a stale total (0.5L) while the Today pill shows the fresh 1.0L.
      // ignore: unawaited_futures
      _ref.read(timelineTrendsProvider.notifier).refresh();
      return true;
    } catch (e) {
      // Online but the write failed — roll back the optimistic change.
      _rollback(snapshot, e);
      return false;
    }
  }

  /// Quick log hydration. `source` defaults to home — every quickLog caller
  /// today is the home-screen quick-add hero. Workout/chat/nutrition surfaces
  /// must pass an explicit source so the badge is correct.
  ///
  /// Optimistic + offline-safe — see [logHydration] for the full contract.
  Future<bool> quickLog({
    required String userId,
    String drinkType = 'water',
    int amountMl = 250,
    HydrationSource source = HydrationSource.home,
  }) async {
    _lastUserId = userId;
    final idempotencyKey = _newIdempotencyKey();
    final localDate = Tz.localDate();
    // Invalidate any in-flight background load so it doesn't overwrite
    ++_loadEpoch;
    final snapshot = _applyOptimistic(drinkType, amountMl);

    // Offline → queue (via the same /hydration/log path on flush) and keep
    // the optimistic total.
    if (!await _isOnline()) {
      await _HydrationWriteQueue.enqueue(_QueuedHydrationWrite(
        idempotencyKey: idempotencyKey,
        userId: userId,
        drinkType: drinkType,
        amountMl: amountMl,
        workoutId: null,
        notes: null,
        localDate: localDate,
        source: source.value,
        queuedAtMs: DateTime.now().millisecondsSinceEpoch,
      ));
      final s = state.todaySummary;
      if (s != null) unawaited(_HydrationDiskCache.write(userId, localDate, s));
      debugPrint('💧 [Hydration] offline — quick-log queued ($idempotencyKey)');
      return true;
    }

    try {
      await _repository.quickLog(
        userId: userId,
        drinkType: drinkType,
        amountMl: amountMl,
        localDate: localDate,
        source: source,
        idempotencyKey: idempotencyKey,
      );

      // Fire-and-forget: sync hydration to Health Connect / HealthKit
      HealthService.syncHydrationToHealthIfEnabled(amountMl: amountMl);

      // Refresh summary in background (no loading indicator)
      await loadTodaySummary(userId, showLoading: false);

      // Refresh Today's Journal so the new entry appears immediately.
      // ignore: unawaited_futures
      _ref.read(timelineProvider.notifier).refresh();
      // Keep the home trends rail's WATER tile (timelineTrendsProvider) in sync.
      // ignore: unawaited_futures
      _ref.read(timelineTrendsProvider.notifier).refresh();
      return true;
    } catch (e) {
      _rollback(snapshot, e);
      return false;
    }
  }

  /// Update daily goal
  Future<void> updateGoal(String userId, int goalMl) async {
    try {
      // Optimistic update
      state = state.copyWith(dailyGoalMl: goalMl);
      await _repository.updateGoal(userId, goalMl);
      // Refresh in background
      await loadTodaySummary(userId, showLoading: false);
      // The goal is the "/2.4L" denominator the trends rail renders, so a goal
      // change must refresh that provider too (the Today timeline reads the
      // goal from the summary load above).
      // ignore: unawaited_futures
      _ref.read(timelineTrendsProvider.notifier).refresh();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Delete a log entry
  Future<void> deleteLog(String userId, String logId) async {
    try {
      await _repository.deleteLog(logId);
      // Refresh in background (no loading indicator)
      await loadTodaySummary(userId, showLoading: false);
      // Removing a water entry must drop BOTH home water displays (the Today
      // timeline pill and the trends-rail WATER tile), not just the summary.
      // ignore: unawaited_futures
      _ref.read(timelineProvider.notifier).refresh();
      // ignore: unawaited_futures
      _ref.read(timelineTrendsProvider.notifier).refresh();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Hydration repository
class HydrationRepository {
  final ApiClient _client;

  HydrationRepository(this._client);

  /// Get daily hydration summary
  Future<DailyHydrationSummary> getDailySummary(String userId, {String? date}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) {
        queryParams['date_str'] = date;
      }
      final response = await _client.get(
        '/hydration/daily/$userId',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return DailyHydrationSummary.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting daily hydration: $e');
      rethrow;
    }
  }

  /// Log hydration.
  ///
  /// [idempotencyKey] — a client-generated key that rides on the request
  /// body. The backend de-dupes on it, so a rapid double-tap or an
  /// offline-queued write replayed after reconnect cannot double-count water.
  Future<HydrationLog> logHydration({
    required String userId,
    required String drinkType,
    required int amountMl,
    String? workoutId,
    String? notes,
    String? localDate,
    HydrationSource source = HydrationSource.manual,
    String? idempotencyKey,
  }) async {
    try {
      final response = await _client.post(
        '/hydration/log',
        data: {
          'user_id': userId,
          'drink_type': drinkType,
          'amount_ml': amountMl,
          if (workoutId != null) 'workout_id': workoutId,
          if (notes != null) 'notes': notes,
          if (localDate != null) 'local_date': localDate,
          'source': source.value,
          if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
        },
      );
      return HydrationLog.fromJson(response.data);
    } catch (e) {
      debugPrint('Error logging hydration: $e');
      rethrow;
    }
  }

  /// Quick log hydration.
  ///
  /// [idempotencyKey] — see [logHydration]; passed as a query parameter on
  /// the quick-log endpoint to guard against double-logging.
  Future<HydrationLog> quickLog({
    required String userId,
    String drinkType = 'water',
    int amountMl = 250,
    String? workoutId,
    String? localDate,
    HydrationSource source = HydrationSource.home,
    String? idempotencyKey,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'drink_type': drinkType,
        'amount_ml': amountMl,
        'source': source.value,
      };
      if (workoutId != null) {
        queryParams['workout_id'] = workoutId;
      }
      if (localDate != null) {
        queryParams['local_date'] = localDate;
      }
      if (idempotencyKey != null) {
        queryParams['idempotency_key'] = idempotencyKey;
      }
      final response = await _client.post(
        '/hydration/quick-log/$userId',
        queryParameters: queryParams,
      );
      return HydrationLog.fromJson(response.data);
    } catch (e) {
      debugPrint('Error quick logging hydration: $e');
      rethrow;
    }
  }

  /// Get hydration logs
  Future<List<HydrationLog>> getLogs(String userId, {int days = 7}) async {
    try {
      final response = await _client.get(
        '/hydration/logs/$userId',
        queryParameters: {'days': days},
      );
      final data = response.data as List;
      return data.map((json) => HydrationLog.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting hydration logs: $e');
      rethrow;
    }
  }

  /// Delete a log
  Future<void> deleteLog(String logId) async {
    try {
      await _client.delete('/hydration/log/$logId');
    } catch (e) {
      debugPrint('Error deleting hydration log: $e');
      rethrow;
    }
  }

  /// Get user's hydration goal
  Future<int> getGoal(String userId) async {
    try {
      final response = await _client.get('/hydration/goal/$userId');
      return response.data['daily_goal_ml'] ?? 2500;
    } catch (e) {
      debugPrint('Error getting hydration goal: $e');
      return 2500;
    }
  }

  /// Update user's hydration goal
  Future<void> updateGoal(String userId, int goalMl) async {
    try {
      await _client.put(
        '/hydration/goal/$userId',
        data: {'daily_goal_ml': goalMl},
      );
    } catch (e) {
      debugPrint('Error updating hydration goal: $e');
      rethrow;
    }
  }
}
