/// Pre-warms the You/Overview tab data so the screen renders instantly the
/// first time the user taps the You tab post-onboarding / post-sign-in /
/// after a cold start.
///
/// Three layers of pre-warming, each addressing a different failure mode:
///
///   1. In-memory cache (`youOverviewCache`) — populated synchronously at
///      module-init time from SharedPreferences (last-known good payload).
///      The You tab's `initState` reads this cache directly, so a user who
///      cold-launches the app and immediately taps You sees their previous
///      session's data instantly with zero network.
///
///   2. Network pre-warm (`YouOverviewPrewarmer.warm`) — fires fire-and-
///      forget after every successful sign-in / `_init()` cache restore.
///      Refreshes the 6 gamification endpoints + XP + the daily activity
///      provider in parallel and writes both the in-memory cache AND the
///      disk cache. Typically completes in 300–800ms while the user is
///      reading the home screen, well before they navigate to You.
///
///   3. Health-card pre-warm — same `warm()` call also kicks
///      `dailyActivityProvider.loadTodayActivity()` so the steps card at
///      the top of the You tab also renders without spinning.
///
/// Failure handling: every endpoint and disk read/write is best-effort. We
/// never throw — pre-warming is fire-and-forget. A blanket-failure refresh
/// (e.g. signed in offline) leaves the cache untouched so the previously-
/// persisted data survives.
library;

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/xp_provider.dart';
import 'api_client.dart';
import 'health_service.dart';

/// SharedPreferences key for the persisted Overview payload. Bump the suffix
/// if the cached schema changes in a way that older blobs would deserialize
/// into incorrect UI state — the loader will treat the unknown key as empty
/// and the next live refresh will populate fresh data.
const String _kPersistKey = 'you_overview_cache_v1';

/// Disk cache TTL. Anything older than this is ignored on cold start so we
/// don't render stale streak counts / leaderboard ranks from yesterday.
/// 24h is loose enough that a returning user almost always sees instant data,
/// tight enough that the user never sees a multi-day-old "Top X%" headline.
const Duration _kDiskStaleAfter = Duration(hours: 24);

/// In-memory cache shared between the prewarmer and `overview_tab.dart`.
/// Reads/writes are synchronous from the UI thread — no locking needed.
class YouOverviewCache {
  List<dynamic>? streaks;
  Map<String, dynamic>? latestSummary;
  Map<String, dynamic>? trophySummary;
  List<dynamic>? recentTrophies;
  Map<String, dynamic>? skillsSummary;
  bool? leaderboardUnlocked;
  int workoutsNeeded = 10;
  double? percentile;
  DateTime? cachedAt;

  bool get hasData => cachedAt != null;

  Duration get age =>
      cachedAt == null ? Duration.zero : DateTime.now().difference(cachedAt!);

  void clear() {
    streaks = null;
    latestSummary = null;
    trophySummary = null;
    recentTrophies = null;
    skillsSummary = null;
    leaderboardUnlocked = null;
    workoutsNeeded = 10;
    percentile = null;
    cachedAt = null;
  }

  /// Snapshot to a JSON-encodable map. Returns null when there's no data
  /// to persist. Only types SharedPreferences can round-trip via JSON live
  /// in here — Lists and Maps of primitives.
  Map<String, dynamic>? toJson() {
    if (cachedAt == null) return null;
    return {
      'streaks': streaks,
      'latestSummary': latestSummary,
      'trophySummary': trophySummary,
      'recentTrophies': recentTrophies,
      'skillsSummary': skillsSummary,
      'leaderboardUnlocked': leaderboardUnlocked,
      'workoutsNeeded': workoutsNeeded,
      'percentile': percentile,
      'cachedAt': cachedAt!.toIso8601String(),
    };
  }

  /// Replace this cache's contents from a previously persisted JSON map.
  /// Tolerant — missing or wrong-type fields are silently dropped so a
  /// schema drift doesn't crash the cold-start path.
  void hydrateFromJson(Map<String, dynamic> j) {
    try {
      final raw = j['streaks'];
      streaks = raw is List ? raw : null;
      final ls = j['latestSummary'];
      latestSummary = ls is Map ? ls.cast<String, dynamic>() : null;
      final ts = j['trophySummary'];
      trophySummary = ts is Map ? ts.cast<String, dynamic>() : null;
      final rt = j['recentTrophies'];
      recentTrophies = rt is List ? rt : null;
      final ss = j['skillsSummary'];
      skillsSummary = ss is Map ? ss.cast<String, dynamic>() : null;
      leaderboardUnlocked = j['leaderboardUnlocked'] as bool?;
      workoutsNeeded = (j['workoutsNeeded'] as num?)?.toInt() ?? 10;
      percentile = (j['percentile'] as num?)?.toDouble();
      final at = j['cachedAt'] as String?;
      cachedAt = at != null ? DateTime.tryParse(at) : null;
    } catch (e) {
      // Bad blob — leave cache empty.
      debugPrint('⚠️ [YouOverviewCache] hydrate failed: $e');
      clear();
    }
  }
}

/// Single shared instance — survives tab swaps and is populated by either the
/// prewarmer, the You overview tab, or [hydrateFromDisk] at app boot.
final YouOverviewCache youOverviewCache = YouOverviewCache();

/// Single in-flight de-duper. Prevents the prewarmer from racing itself if
/// both sign-in and `_init()` fire it concurrently.
Completer<void>? _inFlight;

/// Tracks whether `hydrateFromDisk` has finished, so callers can `await` it
/// once during app boot without worrying about races.
Completer<void>? _diskHydration;

class YouOverviewPrewarmer {
  /// SharedPreferences key for the persisted Overview blob. Exposed so
  /// [PrewarmerBoot.hydrateAll] can batch-read all prewarmer keys in a single
  /// SharedPreferences call instead of opening prefs 5 times.
  static const String persistKey = _kPersistKey;

  /// Apply a previously-decoded blob to the in-memory cache. Used by
  /// [PrewarmerBoot.hydrateAll] when it batch-reads all 5 prewarmer keys at
  /// boot. Safe to call with null/empty (no-op).
  ///
  /// Caller is responsible for stale-checking — if the blob is older than
  /// [_kDiskStaleAfter] this method still applies it; the next [warm] call
  /// will overwrite. Pre-applying stale data is preferred over an empty
  /// cache because the user can still see SOMETHING immediately on cold-
  /// start while the silent revalidation runs.
  static void hydrateFromJsonStatic(String? raw) {
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      youOverviewCache.hydrateFromJson(decoded.cast<String, dynamic>());
      if (youOverviewCache.cachedAt != null &&
          youOverviewCache.age > _kDiskStaleAfter) {
        // Stale: drop in-memory; warm() will refetch.
        youOverviewCache.clear();
      }
    } catch (e) {
      debugPrint('⚠️ [YouOverviewPrewarmer] hydrateFromJsonStatic failed: $e');
    }
  }

  /// Read the persisted cache off disk and populate [youOverviewCache] in
  /// memory. Safe to call multiple times — second call is a no-op.
  ///
  /// Prefer [PrewarmerBoot.hydrateAll] over calling this directly — it batches
  /// the SharedPreferences open across all 5 prewarmers. This method is kept
  /// for backwards compatibility and as a single-tab fallback.
  ///
  /// Always resolves; never throws. A bad/missing blob just leaves the
  /// in-memory cache empty.
  static Future<void> hydrateFromDisk() async {
    final existing = _diskHydration;
    if (existing != null) return existing.future;

    final completer = Completer<void>();
    _diskHydration = completer;

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kPersistKey);
      if (raw == null || raw.isEmpty) {
        debugPrint('🔍 [YouOverviewPrewarmer] no disk cache found');
        return;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        debugPrint('⚠️ [YouOverviewPrewarmer] disk cache not a map — ignoring');
        return;
      }

      youOverviewCache.hydrateFromJson(decoded.cast<String, dynamic>());

      if (youOverviewCache.cachedAt != null &&
          youOverviewCache.age > _kDiskStaleAfter) {
        debugPrint(
          '⏰ [YouOverviewPrewarmer] disk cache stale '
          '(age=${youOverviewCache.age.inHours}h) — clearing',
        );
        youOverviewCache.clear();
        // Drop the stale blob so we don't redo this work next launch.
        unawaited(prefs.remove(_kPersistKey));
      } else if (youOverviewCache.hasData) {
        debugPrint(
          '⚡ [YouOverviewPrewarmer] disk cache hydrated '
          '(age=${youOverviewCache.age.inMinutes}min)',
        );
      }
    } catch (e, st) {
      debugPrint('⚠️ [YouOverviewPrewarmer] hydrateFromDisk failed: $e\n$st');
    } finally {
      if (!completer.isCompleted) completer.complete();
    }
  }

  /// Wipe BOTH the in-memory and on-disk caches. Use on sign-out so the next
  /// user that signs in on this device doesn't briefly see the previous
  /// account's streaks / trophies before the network refresh lands.
  static Future<void> clearAll() async {
    youOverviewCache.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kPersistKey);
    } catch (e) {
      debugPrint('⚠️ [YouOverviewPrewarmer] clearAll disk wipe failed: $e');
    }
  }

  /// Manual refresh trigger — clears in-memory cache then forces a fresh
  /// network warm. Wire this into the You tab's RefreshIndicator.onRefresh
  /// so pull-to-refresh invalidates the prewarmer cache (otherwise the next
  /// tab switch shows the OLD cached data before the just-fetched data lands).
  static Future<void> invalidateAndRefresh(dynamic ref) async {
    youOverviewCache.clear();
    await warm(ref, force: true);
  }

  /// Pre-fetch the 6 You-overview endpoints + XP + daily activity and stash
  /// them in [youOverviewCache] (in-memory + on-disk). Safe to call multiple
  /// times — concurrent calls share a single in-flight future, and a
  /// recently-populated cache short-circuits to a no-op unless [force].
  ///
  /// Always returns normally; never throws. Designed for `unawaited()` from
  /// sign-in / `_init()` sites.
  static Future<void> warm(dynamic ref, {bool force = false}) async {
    // Cache hit, recent enough → skip. 5 min mirrors the stale window the
    // overview tab itself uses on AppLifecycleState.resumed.
    if (!force &&
        youOverviewCache.hasData &&
        youOverviewCache.age < const Duration(minutes: 5)) {
      return;
    }

    // Already warming → join the existing future.
    final existing = _inFlight;
    if (existing != null) {
      return existing.future;
    }

    final completer = Completer<void>();
    _inFlight = completer;

    try {
      await _doWarm(ref);
    } catch (e, st) {
      // Swallow — pre-warming is best-effort.
      debugPrint('⚠️ [YouOverviewPrewarmer] warm failed: $e\n$st');
    } finally {
      _inFlight = null;
      if (!completer.isCompleted) completer.complete();
    }
  }

  static Future<void> _doWarm(Ref ref) async {
    final api = ref.read(apiClientProvider);
    final userId = await api.getUserId();
    if (userId == null) {
      debugPrint('🔍 [YouOverviewPrewarmer] no userId yet — skipping');
      return;
    }

    debugPrint('🎯 [YouOverviewPrewarmer] warming for $userId');

    // XP refresh fires off independently — its provider holds its own cache.
    unawaited(ref.read(xpProvider.notifier).loadUserXP(userId: userId));

    // Health-card pre-warm. The TodaysHealthCard at the top of the Overview
    // tab watches `dailyActivityProvider` and lazily fires this on first
    // build; pre-firing it here means the steps card also renders instantly
    // once the user navigates. Gated by isConnected so we don't spuriously
    // request Health Connect / HealthKit before the user has linked it.
    try {
      final sync = ref.read(healthSyncProvider);
      if (sync.isConnected) {
        unawaited(
          ref.read(dailyActivityProvider.notifier).loadTodayActivity(),
        );
      }
    } catch (e) {
      // Health provider not ready yet — non-fatal, the card will load on tap.
      debugPrint('⚠️ [YouOverviewPrewarmer] health pre-warm skipped: $e');
    }

    // Match the overview tab's per-call options so behavior is identical
    // when the user lands on the screen.
    final opts = Options(
      sendTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 15),
      validateStatus: (s) => s != null && s < 500,
    );

    Future<Response<dynamic>?> safeGet(
      String path, {
      Map<String, dynamic>? query,
    }) async {
      try {
        return await api.dio
            .get(path, queryParameters: query, options: opts);
      } catch (_) {
        return null;
      }
    }

    final results = await Future.wait<Response<dynamic>?>([
      safeGet('/achievements/user/$userId/streaks'),
      safeGet('/summaries/user/$userId/latest'),
      safeGet('/progress/trophies/$userId/summary'),
      safeGet('/progress/trophies/$userId/recent', query: {'limit': 1}),
      safeGet('/skill-progressions/user/$userId/summary'),
      safeGet('/leaderboard/unlock-status', query: {'user_id': userId}),
    ], eagerError: false);

    int errorCount = 0;
    void countErr(Response<dynamic>? r) {
      if (r == null || r.statusCode != 200) errorCount++;
    }

    List<dynamic>? streaks;
    Map<String, dynamic>? latestSummary;
    Map<String, dynamic>? trophySummary;
    List<dynamic>? recentTrophies;
    Map<String, dynamic>? skillsSummary;
    bool? leaderboardUnlocked;
    int workoutsNeeded = 10;
    double? percentile;

    final streaksRes = results[0];
    countErr(streaksRes);
    if (streaksRes?.statusCode == 200) {
      final data = streaksRes!.data;
      if (data is List) streaks = data;
      if (data is Map && data['streaks'] is List) {
        streaks = data['streaks'] as List;
      }
    }
    final latestRes = results[1];
    countErr(latestRes);
    if (latestRes?.statusCode == 200 && latestRes!.data is Map) {
      latestSummary = (latestRes.data as Map).cast<String, dynamic>();
    }
    final trophySumRes = results[2];
    countErr(trophySumRes);
    if (trophySumRes?.statusCode == 200 && trophySumRes!.data is Map) {
      trophySummary = (trophySumRes.data as Map).cast<String, dynamic>();
    }
    final trophyRecentRes = results[3];
    countErr(trophyRecentRes);
    if (trophyRecentRes?.statusCode == 200 && trophyRecentRes!.data is List) {
      recentTrophies = trophyRecentRes.data as List;
    }
    final skillsRes = results[4];
    countErr(skillsRes);
    if (skillsRes?.statusCode == 200 && skillsRes!.data is Map) {
      skillsSummary = (skillsRes.data as Map).cast<String, dynamic>();
    }
    final unlockRes = results[5];
    countErr(unlockRes);
    if (unlockRes?.statusCode == 200 && unlockRes!.data is Map) {
      final m = (unlockRes.data as Map).cast<String, dynamic>();
      leaderboardUnlocked = m['is_unlocked'] as bool? ?? false;
      workoutsNeeded = (m['workouts_needed'] as num?)?.toInt() ?? 10;
      if (leaderboardUnlocked == true) {
        try {
          final rankRes = await api.dio.get('/leaderboard/rank',
              queryParameters: {'user_id': userId}, options: opts);
          if (rankRes.statusCode == 200 && rankRes.data is Map) {
            final rm = (rankRes.data as Map).cast<String, dynamic>();
            percentile = (rm['percentile'] as num?)?.toDouble();
          }
        } catch (_) {
          // Best-effort — leaderboard rank is an optional flourish.
        }
      }
    }

    // Stamp the cache only if at least one call succeeded — a full blackout
    // (offline) keeps any previous cache intact for the next attempt.
    if (errorCount < 6) {
      youOverviewCache
        ..streaks = streaks
        ..latestSummary = latestSummary
        ..trophySummary = trophySummary
        ..recentTrophies = recentTrophies
        ..skillsSummary = skillsSummary
        ..leaderboardUnlocked = leaderboardUnlocked
        ..workoutsNeeded = workoutsNeeded
        ..percentile = percentile
        ..cachedAt = DateTime.now();

      // Persist to disk so the NEXT cold start can rehydrate before the
      // user even has time to navigate to the You tab. Fire-and-forget —
      // a write failure doesn't compromise this session.
      unawaited(_persistToDisk());

      debugPrint(
        '✅ [YouOverviewPrewarmer] cache populated '
        '(${6 - errorCount}/6 endpoints succeeded)',
      );
    } else {
      debugPrint(
        '⚠️ [YouOverviewPrewarmer] all 6 endpoints failed — cache not stamped',
      );
    }
  }

  /// Write the current in-memory cache to SharedPreferences. Best-effort.
  static Future<void> _persistToDisk() async {
    try {
      final snapshot = youOverviewCache.toJson();
      if (snapshot == null) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPersistKey, jsonEncode(snapshot));
    } catch (e) {
      debugPrint('⚠️ [YouOverviewPrewarmer] persist failed: $e');
    }
  }
}
