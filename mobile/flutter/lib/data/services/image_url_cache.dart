import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

/// Persistent cache for exercise image URLs.
///
/// URLs resolved from `/exercise-images/...` point at public S3/CDN objects
/// whose paths are stable, so cache entries never expire.
///
/// Two-tier design (Home-perf plan A9):
///  - **In-memory tier** (`_memoryCache`): the session fast path. Capped at
///    [_maxMemoryEntries] so a long browsing session of the exercise library
///    can't grow it unbounded.
///  - **Disk tier** (`SharedPreferences`): hydrated on [initialize] so that on
///    a cold app start the hero workout card and exercise thumbnails know their
///    image URL instantly — no `/exercise-images/` network round-trip before
///    the first paint. The disk tier is LRU-capped at [_maxPersistedEntries]
///    (the most-recently-used entries) so the prefs blob stays tiny.
///
/// LRU ordering is tracked with [_recency] — a list of keys ordered
/// oldest-first. Every read/write touches a key, moving it to the most-recent
/// end. Persistence writes only the [_maxPersistedEntries] most-recent keys.
class ImageUrlCache {
  /// SharedPreferences key under which the URL map is persisted.
  ///
  /// Bumped v2 -> v3 (2026-06-28): the v2 blob cached presigned URLs built from
  /// the legacy wrong `ILLUSTRATIONS/` S3 prefix (exercise_demos data bug). Those
  /// URLs 404 forever and survive hot restart. v3 starts clean and the poisoned
  /// v2 blob is purged on [initialize] (NOT migrated — its contents are stale).
  static const String _cacheKey = 'exercise_image_urls_v3';

  /// Stale key whose cached URLs may point at the dead `ILLUSTRATIONS/` prefix.
  /// Purged once on [initialize]; never migrated.
  static const String _stalePrefixCacheKey = 'exercise_image_urls_v2';

  /// Legacy v1 key — read once on [initialize] for a one-time migration, then
  /// removed. Keeps URLs warm for users upgrading from the pre-A9 build.
  static const String _legacyCacheKey = 'exercise_image_urls';

  /// In-memory cap. Larger than the disk cap because RAM is cheap within a
  /// session and avoids re-fetching while scrolling a big library grid.
  static const int _maxMemoryEntries = 500;

  /// Disk cap. Only the last [_maxPersistedEntries] most-recently-used entries
  /// are written to SharedPreferences so the persisted blob stays small and
  /// hydration on the next cold start is fast. Plan A9 target: ~50.
  static const int _maxPersistedEntries = 50;

  /// In-memory cache for fast access during the session.
  static Map<String, String>? _memoryCache;

  /// LRU recency list, oldest key first / most-recently-used key last.
  /// Kept in sync with [_memoryCache] on every get/set.
  static final List<String> _recency = <String>[];

  /// Initialize cache from SharedPreferences on app start.
  /// URLs are permanent (no expiration) so cached entries are valid
  /// indefinitely. Safe to call more than once (idempotent).
  static Future<void> initialize() async {
    if (_memoryCache != null) return; // already hydrated

    final prefs = await SharedPreferences.getInstance();
    _memoryCache = {};
    _recency.clear();

    // One-time purge of the poisoned v2 blob (legacy ILLUSTRATIONS/ prefix
    // URLs that 404 forever). Do NOT migrate it — start clean under v3.
    if (prefs.containsKey(_stalePrefixCacheKey)) {
      await prefs.remove(_stalePrefixCacheKey);
    }

    // Preferred: the v3 ordered blob (already LRU-ordered, oldest first).
    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      try {
        final decoded = Map<String, String>.from(json.decode(cached) as Map);
        // JSON object key order is preserved on decode, so iteration order
        // here is the LRU order we persisted (oldest first).
        decoded.forEach((key, value) {
          _memoryCache![key] = value;
          _recency.add(key);
        });
      } catch (_) {
        // Corrupt blob — start clean rather than crash.
        _memoryCache = {};
        _recency.clear();
      }
    } else {
      // One-time migration from the pre-A9 unordered v1 blob.
      final legacy = prefs.getString(_legacyCacheKey);
      if (legacy != null) {
        try {
          final decoded = Map<String, String>.from(json.decode(legacy) as Map);
          decoded.forEach((key, value) {
            _memoryCache![key] = value;
            _recency.add(key);
          });
          await prefs.remove(_legacyCacheKey);
          await _persistCache(); // rewrite under the v2 key
        } catch (_) {
          _memoryCache = {};
          _recency.clear();
        }
      }
    }
  }

  /// Mark [key] as most-recently-used in the LRU recency list.
  static void _touch(String key) {
    _recency.remove(key); // O(n) but n<=500; negligible
    _recency.add(key); // most-recent end
  }

  /// Get a cached URL for an exercise name (or id-keyed slot).
  /// A hit refreshes the entry's LRU recency so frequently-shown images
  /// (e.g. the hero card) survive eviction and stay on disk.
  static String? get(String exerciseName) {
    if (_memoryCache == null) return null;
    final key = exerciseName.toLowerCase();
    final url = _memoryCache![key];
    if (url != null) _touch(key);
    return url;
  }

  /// Store a URL in cache. Additive public API — unchanged signature so
  /// existing callers / `precacheImage` flows keep working.
  static Future<void> set(String exerciseName, String url) async {
    _memoryCache ??= {};
    final key = exerciseName.toLowerCase();
    _memoryCache![key] = url;
    _touch(key);

    _evictMemoryIfNeeded();

    // Persist on every write. The disk blob is capped at
    // [_maxPersistedEntries] so a write is cheap (small JSON), and we never
    // lose recent URLs the way the old "every 10th entry" debounce could.
    await _persistCache();
  }

  /// Store multiple URLs at once (single persistence write — more efficient
  /// than calling [set] in a loop).
  static Future<void> setAll(Map<String, String> urls) async {
    if (urls.isEmpty) return;
    _memoryCache ??= {};
    for (final entry in urls.entries) {
      final key = entry.key.toLowerCase();
      _memoryCache![key] = entry.value;
      _touch(key);
    }
    _evictMemoryIfNeeded();
    await _persistCache();
  }

  /// Evict least-recently-used entries when the in-memory map exceeds its cap.
  static void _evictMemoryIfNeeded() {
    if (_memoryCache == null) return;
    while (_memoryCache!.length > _maxMemoryEntries && _recency.isNotEmpty) {
      final oldest = _recency.removeAt(0); // oldest-first
      _memoryCache!.remove(oldest);
    }
  }

  /// Persist the [_maxPersistedEntries] most-recently-used entries to
  /// SharedPreferences, ordered oldest-first so [initialize] rehydrates the
  /// LRU order exactly.
  static Future<void> _persistCache() async {
    if (_memoryCache == null) return;

    final prefs = await SharedPreferences.getInstance();
    if (_memoryCache!.isEmpty || _recency.isEmpty) {
      await prefs.remove(_cacheKey);
      return;
    }

    // Take the tail (most-recent) slice of the recency list, capped.
    final start = _recency.length > _maxPersistedEntries
        ? _recency.length - _maxPersistedEntries
        : 0;
    final keysToPersist = _recency.sublist(start);

    // Build an ordered map (insertion order == oldest-first LRU order).
    final toPersist = <String, String>{};
    for (final key in keysToPersist) {
      final url = _memoryCache![key];
      if (url != null) toPersist[key] = url;
    }
    await prefs.setString(_cacheKey, json.encode(toPersist));
  }

  /// Batch pre-fetch image URLs for multiple exercises in a single API call.
  /// Calls POST /exercise-images/batch and caches all results.
  static Future<void> batchPreFetch(
    List<String> names,
    ApiClient apiClient,
  ) async {
    if (names.isEmpty) return;

    // Filter out names already in cache (do NOT touch LRU here — a pre-fetch
    // is not a user view, so we read the map directly instead of via get()).
    final uncachedNames = names.where((name) {
      final key = name.toLowerCase();
      return _memoryCache?[key] == null;
    }).toList();
    if (uncachedNames.isEmpty) return;

    try {
      final response = await apiClient.post(
        '/exercise-images/batch',
        data: {'names': uncachedNames.take(100).toList()},
      );

      if (response.statusCode == 200 && response.data != null) {
        final rawUrls = response.data['urls'] as Map?;
        if (rawUrls != null && rawUrls.isNotEmpty) {
          final urls = rawUrls.map<String, String>(
            (key, value) => MapEntry(key.toString(), value.toString()),
          );
          await setAll(urls);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Batch image pre-fetch failed: $e');
    }
  }

  /// Clear all cached URLs (call when presigned URLs might have expired).
  static Future<void> clear() async {
    _memoryCache = {};
    _recency.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_legacyCacheKey);
  }

  /// Check if cache has any entries.
  static bool get isEmpty => _memoryCache?.isEmpty ?? true;

  /// Get cache size (in-memory entry count).
  static int get size => _memoryCache?.length ?? 0;

  /// Number of entries that would be written to disk (debug/diagnostics only).
  @visibleForTesting
  static int get persistedSize =>
      _recency.length > _maxPersistedEntries
          ? _maxPersistedEntries
          : _recency.length;
}
