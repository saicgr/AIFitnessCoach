/// Part 1 of the instant-load standard — a reusable cache-first load primitive
/// for Riverpod `StateNotifier`s.
///
/// This generalizes the hand-rolled stale-while-revalidate (SWR) pattern that
/// already lives in `_NutritionDiskCache`, `_HydrationDiskCache` and
/// `youOverviewCache`. Instead of every repository re-implementing the same
/// "read disk → emit instantly → fetch network → emit fresh → write-through"
/// dance, a notifier mixes in [CacheFirstMixin] and calls a single
/// [loadCacheFirst] method.
///
/// ---------------------------------------------------------------------------
/// USAGE EXAMPLE
/// ---------------------------------------------------------------------------
/// ```dart
/// class StepsNotifier extends StateNotifier<AsyncValue<StepsData>>
///     with CacheFirstMixin {
///   StepsNotifier(this._api, this._userId) : super(const AsyncLoading());
///
///   final ApiClient _api;
///   final String _userId;
///
///   Future<void> load() => loadCacheFirst<StepsData>(
///         // Base name; the mixin appends user-scope + schema version + date.
///         cacheKey: 'steps_overview',
///         userId: _userId,
///         ttl: const Duration(hours: 6),
///         // Set true for keys whose value is "today only" (rolls at midnight).
///         localDateScoped: true,
///         fetch: () async => _api.fetchSteps(_userId),
///         decode: StepsData.fromJson,
///         encode: (d) => d.toJson(),
///         emit: (data, {required bool fromCache}) {
///           // Called up to twice: once with the cached value (fromCache:true)
///           // and once with the network value (fromCache:false).
///           state = AsyncData(data);
///         },
///         onError: (e, st) {
///           // Only fired when the NETWORK fetch fails. If a cache value was
///           // already emitted the screen keeps showing it; otherwise surface.
///           if (!mounted) return;
///           state = AsyncError(e, st);
///         },
///       );
/// }
/// ```
///
/// ---------------------------------------------------------------------------
/// GUARANTEES
/// ---------------------------------------------------------------------------
///  - **Never throws to the caller.** A failed disk read is treated as a cache
///    miss; a failed network fetch is routed to the [onError] callback. The
///    returned `Future` always completes normally.
///  - **Cache-first, network-second.** If a valid cached value exists it is
///    decoded and `emit(..., fromCache: true)` runs synchronously-fast, before
///    any network I/O — that is what makes screens render instantly.
///  - **Versioned envelope.** Every blob carries a schema version. On a schema
///    bump the old blob is silently dropped (treated as a miss) — never
///    deserialized into a wrong-shaped object that would crash the UI.
///  - **User + date scoped.** Keys are `<base>::v<schema>::<userId>` and, when
///    [loadCacheFirst]'s `localDateScoped` is true, additionally carry the
///    device's local calendar date so "today" data can't bleed across a
///    midnight / timezone rollover.
///  - **Write-through.** After a successful fetch the fresh value is persisted
///    so the *next* cold start is instant too.
///
/// `PerfTrace.cacheHit` / `cacheMiss` are recorded per `cacheKey`, and a
/// `PerfTrace.mark` fires when the first value (cached OR fresh) reaches the
/// UI, so downstream perf dashboards can measure time-to-first-content.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../perf/perf_trace.dart';

/// The schema version stamped onto every [CacheFirstMixin] envelope. Bump this
/// constant when the *envelope* shape itself changes (not the payload — that is
/// the caller's concern, see [loadCacheFirst]'s `schemaVersion`). A mismatch
/// causes the stored blob to be dropped as if it were never written.
const int _kEnvelopeVersion = 1;

/// Shared SharedPreferences key prefix so all cache-first slots are easy to
/// enumerate / wipe on logout (`cachefirst::...`).
const String _kKeyPrefix = 'cachefirst';

/// A mixin for Riverpod `StateNotifier`s that adds a single cache-first loader.
///
/// `StateNotifier` already exposes a `mounted` getter; this mixin uses it to
/// avoid emitting into a disposed notifier. The mixin is intentionally typed
/// loosely (no `on StateNotifier` clause) so it can also be mixed into plain
/// classes / `ChangeNotifier`s that expose a compatible `mounted` — but the
/// common case is a `StateNotifier`.
mixin CacheFirstMixin {
  /// Whether the host object is still alive — guards every `emit`/`onError` so
  /// we never write `state` into a disposed notifier.
  ///
  /// ABSTRACT on purpose. A previous default (`=> true`) silently SHADOWED
  /// `StateNotifier.mounted` due to mixin linearization (the mixin is applied
  /// ON TOP of the superclass), so the guards were always-true and an async
  /// fetch completing after the screen closed threw "Tried to use <Notifier>
  /// after dispose". Leaving it abstract lets the superclass's real `mounted`
  /// (StateNotifier's) satisfy it, so the guards actually work. Plain
  /// (non-StateNotifier) hosts that genuinely have no lifecycle must implement
  /// `bool get mounted => true;` themselves.
  bool get mounted;

  /// Load [cacheKey] cache-first.
  ///
  /// Step 1 — read the disk cache. If a valid (correct schema, in-TTL,
  /// matching user + optional date) blob exists, decode it and call
  /// `emit(value, fromCache: true)` immediately.
  ///
  /// Step 2 — await [fetch]. On success call `emit(value, fromCache: false)`
  /// and write the value through to disk. On failure route the error to
  /// [onError] (the cached value, if any, stays on screen).
  ///
  /// Parameters:
  ///  - [cacheKey]   Base name for the slot. Combined with user-scope + schema
  ///                 version (+ optional local date) into the real key.
  ///  - [userId]     The owning user. Required for correct multi-account
  ///                 isolation. An empty string is tolerated but logs a warning
  ///                 and shares a global slot (mirrors `DataCacheService`).
  ///  - [ttl]        Max age before a cached blob is considered stale and
  ///                 ignored on read.
  ///  - [schemaVersion] Caller-owned payload schema version. Bump it when
  ///                 [decode]/[encode] change shape so old blobs are dropped.
  ///                 Defaults to `1`.
  ///  - [localDateScoped] When true the key also embeds the device's local
  ///                 `yyyy-MM-dd`, so a value cached "today" is never read back
  ///                 "tomorrow". Use for day-bucketed data (today's steps,
  ///                 today's nutrition summary, etc).
  ///  - [fetch]      Produces the fresh value from the network. May throw —
  ///                 the throw is caught and routed to [onError].
  ///  - [decode]     Turns the persisted JSON map back into `T`. May throw —
  ///                 a throw is treated as a corrupt-cache miss.
  ///  - [encode]     Turns a fresh `T` into a JSON-encodable map for write-
  ///                 through. May throw — a throw just skips persistence.
  ///  - [emit]       Delivers a value to the UI. Called 0–2 times: once for the
  ///                 cached value (if present) and once for the fresh value (if
  ///                 the fetch succeeds). `fromCache` distinguishes the two so
  ///                 the caller can, e.g., cross-fade stale→fresh.
  ///  - [onError]    Optional. Invoked only when [fetch] throws. If omitted the
  ///                 error is swallowed (the cached value, if any, remains).
  ///
  /// Always completes normally — never rethrows.
  Future<void> loadCacheFirst<T>({
    required String cacheKey,
    required String userId,
    required Duration ttl,
    required Future<T> Function() fetch,
    required T Function(Map<String, dynamic>) decode,
    required Map<String, dynamic> Function(T) encode,
    required void Function(T data, {required bool fromCache}) emit,
    int schemaVersion = 1,
    bool localDateScoped = false,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    final storageKey = _storageKey(
      base: cacheKey,
      userId: userId,
      schemaVersion: schemaVersion,
      localDateScoped: localDateScoped,
    );

    var servedFromCache = false;

    // ---- Step 1: disk cache ------------------------------------------------
    try {
      final cached = await _readCache<T>(
        storageKey: storageKey,
        ttl: ttl,
        schemaVersion: schemaVersion,
        decode: decode,
      );
      if (cached != null) {
        servedFromCache = true;
        PerfTrace.cacheHit(cacheKey);
        if (mounted) {
          emit(cached, fromCache: true);
          PerfTrace.mark('cachefirst:$cacheKey:first_content_cache');
        }
      } else {
        PerfTrace.cacheMiss(cacheKey);
      }
    } catch (e, st) {
      // A read failure must never break the load — degrade to a miss.
      debugPrint('💾 [CacheFirst] read failed for $cacheKey: $e\n$st');
      PerfTrace.cacheMiss(cacheKey);
    }

    // ---- Step 2: network fetch --------------------------------------------
    try {
      final fresh = await fetch();
      if (mounted) {
        emit(fresh, fromCache: false);
        if (!servedFromCache) {
          // First content reached the UI via the network (cold cache).
          PerfTrace.mark('cachefirst:$cacheKey:first_content_network');
        }
      }
      // Write-through so the next cold start is instant. Best-effort.
      await _writeCache<T>(
        storageKey: storageKey,
        schemaVersion: schemaVersion,
        value: fresh,
        encode: encode,
      );
    } catch (e, st) {
      debugPrint('💾 [CacheFirst] fetch failed for $cacheKey: $e');
      // Surface the failure. If we already emitted a cached value the screen
      // keeps showing it; the caller's onError can decide whether to also flag
      // a soft "couldn't refresh" state.
      if (onError != null && mounted) {
        onError(e, st);
      }
    }
  }

  /// Drop the persisted blob for [cacheKey] (current user/date scope). Use when
  /// a write elsewhere invalidates this cache (e.g. user edited the data) so
  /// the next [loadCacheFirst] does a clean network read.
  Future<void> invalidateCacheFirst({
    required String cacheKey,
    required String userId,
    int schemaVersion = 1,
    bool localDateScoped = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey(
        base: cacheKey,
        userId: userId,
        schemaVersion: schemaVersion,
        localDateScoped: localDateScoped,
      ));
    } catch (e) {
      debugPrint('💾 [CacheFirst] invalidate failed for $cacheKey: $e');
    }
  }

  // ---- internals -----------------------------------------------------------

  /// Build the fully-qualified SharedPreferences key.
  ///
  /// Shape: `cachefirst::<base>::v<schema>::<userId|_global>[::<yyyy-MM-dd>]`.
  static String _storageKey({
    required String base,
    required String userId,
    required int schemaVersion,
    required bool localDateScoped,
  }) {
    final scope = userId.isEmpty ? '_global' : userId;
    if (userId.isEmpty) {
      debugPrint(
        '⚠️ [CacheFirst] "$base" used with empty userId — sharing a global '
        'slot. Thread the real user_id to isolate accounts.',
      );
    }
    final buf = StringBuffer('$_kKeyPrefix::$base::v$schemaVersion::$scope');
    if (localDateScoped) {
      buf.write('::${DateFormat('yyyy-MM-dd').format(DateTime.now())}');
    }
    return buf.toString();
  }

  /// Read + validate + decode the cached value. Returns null on miss, expiry,
  /// schema mismatch, or any corruption.
  static Future<T?> _readCache<T>({
    required String storageKey,
    required Duration ttl,
    required int schemaVersion,
    required T Function(Map<String, dynamic>) decode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;

    // Envelope-version + caller-schema-version gate.
    if (decoded['ev'] != _kEnvelopeVersion) return null;
    if (decoded['sv'] != schemaVersion) return null;

    final cachedAtMs = decoded['cachedAt'];
    if (cachedAtMs is! int) return null;
    final age = DateTime.now().millisecondsSinceEpoch - cachedAtMs;
    // Negative age = device clock moved backwards → treat as invalid.
    if (age < 0 || age >= ttl.inMilliseconds) {
      // Stale — drop it so we don't keep re-checking a dead blob.
      await prefs.remove(storageKey);
      return null;
    }

    final body = decoded['data'];
    if (body is! Map<String, dynamic>) return null;
    return decode(body);
  }

  /// Persist [value] in a versioned TTL envelope. Best-effort.
  static Future<void> _writeCache<T>({
    required String storageKey,
    required int schemaVersion,
    required T value,
    required Map<String, dynamic> Function(T) encode,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final envelope = <String, dynamic>{
        'ev': _kEnvelopeVersion,
        'sv': schemaVersion,
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
        'data': encode(value),
      };
      await prefs.setString(storageKey, jsonEncode(envelope));
    } catch (e) {
      debugPrint('💾 [CacheFirst] write-through failed for $storageKey: $e');
    }
  }

  /// Wipe every cache-first slot on this device — call on logout. Removes any
  /// key under the `cachefirst::` prefix regardless of user/date scope.
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys()
          .where((k) => k.startsWith('$_kKeyPrefix::'))
          .toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
      debugPrint('🧹 [CacheFirst] cleared ${keys.length} cache-first slots');
    } catch (e) {
      debugPrint('💾 [CacheFirst] clearAll failed: $e');
    }
  }
}
