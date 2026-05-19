import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/user_provider.dart';
import '../models/schedule_item.dart';
import '../repositories/schedule_repository.dart';

/// Simple refresh trigger -- increment to invalidate schedule providers
final scheduleRefreshProvider = StateProvider<int>((ref) => 0);

// ===========================================================================
// Cache-first disk SWR for schedule data
// ===========================================================================
//
// The schedule screens watch one [dailyScheduleProvider] per visible day plus
// [upNextScheduleProvider]. Both are FutureProviders, so without a disk cache
// every cold start blanks the agenda until the network resolves.
//
// [_ScheduleDiskCache] persists the last response per (user, key) into
// SharedPreferences inside a versioned + TTL envelope. The providers below
// read it synchronously-fast first (returning instantly) and revalidate on a
// post-frame microtask via [scheduleRefreshProvider]. This mirrors the
// stale-while-revalidate contract of CacheFirstMixin, adapted to the
// FutureProvider shape (a FutureProvider can only yield one value, so the
// revalidate is driven by a refresh trigger that re-runs the provider).

/// Schema version for the persisted schedule envelope. Bump on shape changes.
const int _kScheduleCacheVersion = 1;

/// SharedPreferences key prefix for all schedule disk-cache slots.
const String _kScheduleCachePrefix = 'schedule_cache';

/// How long a cached schedule blob is considered fresh enough to serve before
/// a network read. 24h: stale data still beats a blank screen and the
/// background revalidate corrects it within the same session.
const Duration _kScheduleCacheTtl = Duration(hours: 24);

/// Disk-persisted stale-while-revalidate cache for schedule responses.
class _ScheduleDiskCache {
  const _ScheduleDiskCache._();

  /// Build the fully-qualified key:
  /// `schedule_cache::v<n>::<userId>::<slot>`.
  static String _key(String userId, String slot) =>
      '$_kScheduleCachePrefix::v$_kScheduleCacheVersion::$userId::$slot';

  /// Read + validate a cached JSON map. Returns null on miss / expiry /
  /// schema mismatch / corruption — never throws.
  static Future<Map<String, dynamic>?> read(String userId, String slot) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(userId, slot));
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['v'] != _kScheduleCacheVersion) return null;
      final cachedAt = decoded['cachedAt'];
      if (cachedAt is! int) return null;
      final age = DateTime.now().millisecondsSinceEpoch - cachedAt;
      // Negative age = clock skew → treat as invalid.
      if (age < 0 || age >= _kScheduleCacheTtl.inMilliseconds) {
        await prefs.remove(_key(userId, slot));
        return null;
      }
      final body = decoded['data'];
      return body is Map<String, dynamic> ? body : null;
    } catch (e) {
      debugPrint('💾 [ScheduleCache] read failed for $slot: $e');
      return null;
    }
  }

  /// Persist a JSON map in a versioned TTL envelope. Best-effort.
  static Future<void> write(
      String userId, String slot, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(userId, slot),
        jsonEncode({
          'v': _kScheduleCacheVersion,
          'cachedAt': DateTime.now().millisecondsSinceEpoch,
          'data': data,
        }),
      );
    } catch (e) {
      debugPrint('💾 [ScheduleCache] write failed for $slot: $e');
    }
  }
}

/// Week start day preference: 1 = Monday (default), 7 = Sunday
/// Persisted to SharedPreferences
final weekStartDayProvider =
    StateNotifierProvider<WeekStartDayNotifier, int>((ref) {
  return WeekStartDayNotifier();
});

class WeekStartDayNotifier extends StateNotifier<int> {
  static const _key = 'week_start_day';

  WeekStartDayNotifier() : super(1) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt(_key) ?? 1; // default Monday
  }

  Future<void> toggle() async {
    final newValue = state == 1 ? 7 : 1;
    state = newValue;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, newValue);
  }
}

/// Fetches the up-next schedule items for the current user.
///
/// Cache-first: on a cold start the last-known up-next list is read from disk
/// and returned instantly, while a background revalidate is scheduled via
/// [scheduleRefreshProvider]. The first build after the cache hit shows real
/// content (no spinner); the revalidate then writes through the fresh data.
final upNextScheduleProvider =
    FutureProvider.autoDispose<UpNextResponse>((ref) async {
  // Watch refresh trigger so providers auto-refresh when it changes
  ref.watch(scheduleRefreshProvider);

  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    debugPrint('⚠️ [ScheduleProvider] No user ID for up-next');
    return UpNextResponse(items: [], asOf: DateTime.now());
  }

  // Skip the disk cache on an explicit refresh so a forced reload always hits
  // the network instead of re-serving the just-served stale blob.
  final isRefresh = ref.read(scheduleRefreshProvider) > 0;
  if (!isRefresh) {
    final cached = await _ScheduleDiskCache.read(userId, 'up_next');
    if (cached != null) {
      try {
        final response = UpNextResponse.fromJson(cached);
        debugPrint(
            '✅ [ScheduleProvider] Up-next from cache: ${response.items.length} items');
        // Revalidate in the background — bumping the trigger re-runs this
        // provider on the network path on the next microtask. Wrapped in a
        // try/catch because the provider may have been disposed by then.
        Future.microtask(() {
          try {
            ref.read(scheduleRefreshProvider.notifier).state++;
          } catch (_) {/* provider disposed — nothing to revalidate */}
        });
        return response;
      } catch (e) {
        debugPrint('💾 [ScheduleProvider] Corrupt up-next cache ignored: $e');
      }
    }
  }

  final repository = ref.watch(scheduleRepositoryProvider);
  try {
    debugPrint('🔍 [ScheduleProvider] Fetching up-next for user $userId');
    final upNext = await repository.getUpNext(userId);
    debugPrint(
        '✅ [ScheduleProvider] Up-next loaded: ${upNext.items.length} items');
    // Write-through so the next cold start is instant.
    await _ScheduleDiskCache.write(userId, 'up_next', upNext.toJson());
    return upNext;
  } catch (e) {
    debugPrint('❌ [ScheduleProvider] Error fetching up-next: $e');
    rethrow;
  }
});

/// Fetches the daily schedule for a specific date.
///
/// Cache-first per (user, date): the last-known schedule for the date is read
/// from disk and returned instantly on a cold start, with a background
/// revalidate scheduled via [scheduleRefreshProvider].
final dailyScheduleProvider = FutureProvider.autoDispose
    .family<DailyScheduleResponse, DateTime>((ref, date) async {
  // Watch refresh trigger so providers auto-refresh when it changes
  ref.watch(scheduleRefreshProvider);

  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    debugPrint('⚠️ [ScheduleProvider] No user ID for daily schedule');
    return DailyScheduleResponse(
      date: date,
      items: [],
      summary: {'total_items': 0, 'completed': 0, 'upcoming': 0},
    );
  }

  // Per-date cache slot — normalized to yyyy-MM-dd so the key is timezone-safe.
  final slot = 'daily::${DateFormat('yyyy-MM-dd').format(date)}';

  final isRefresh = ref.read(scheduleRefreshProvider) > 0;
  if (!isRefresh) {
    final cached = await _ScheduleDiskCache.read(userId, slot);
    if (cached != null) {
      try {
        final response = DailyScheduleResponse.fromJson(cached);
        debugPrint(
            '✅ [ScheduleProvider] Daily schedule from cache for $slot: '
            '${response.items.length} items');
        Future.microtask(() {
          try {
            ref.read(scheduleRefreshProvider.notifier).state++;
          } catch (_) {/* provider disposed — nothing to revalidate */}
        });
        return response;
      } catch (e) {
        debugPrint(
            '💾 [ScheduleProvider] Corrupt daily-schedule cache ignored: $e');
      }
    }
  }

  final repository = ref.watch(scheduleRepositoryProvider);
  try {
    debugPrint(
        '📅 [ScheduleProvider] Fetching daily schedule for ${date.toIso8601String().split('T')[0]}');
    final schedule = await repository.getDailySchedule(userId, date);
    debugPrint(
        '✅ [ScheduleProvider] Daily schedule loaded: ${schedule.items.length} items');
    // Write-through so the next cold start renders this day instantly.
    await _ScheduleDiskCache.write(userId, slot, schedule.toJson());
    return schedule;
  } catch (e) {
    debugPrint('❌ [ScheduleProvider] Error fetching daily schedule: $e');
    rethrow;
  }
});
