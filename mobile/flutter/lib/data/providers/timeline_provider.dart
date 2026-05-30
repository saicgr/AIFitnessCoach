/// Riverpod provider for the Home Timeline section.
///
/// Fetches `/api/v1/timeline?date=today&days=1` and exposes the parsed
/// response. Methods:
///   - refresh()        — refetch latest day, bypass server cache (60s)
///   - loadMorePast()   — append previous days for infinite-scroll
///   - setFilter(f)     — apply a TimelineFilter chip (client-side)
///   - setSearch(q)     — substring filter across title + notes
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/timeline_entry.dart';
import '../repositories/auth_repository.dart' show authStateProvider;
import '../repositories/timeline_repository.dart';
import '../services/api_client.dart';
import '../services/data_cache_service.dart';

final timelineRepositoryProvider = Provider<TimelineRepository>((ref) {
  return TimelineRepository(ref.read(apiClientProvider));
});

/// Module-level cache so a fresh [TimelineNotifier] (provider invalidation,
/// returning to Home) seeds its first frame instantly instead of flashing a
/// loading shimmer. Mirrors `todayWorkoutProvider`'s `_inMemoryCache`. Wiped
/// on real user-id change so a new account never inherits the prior user's
/// timeline. Holds the raw single-day server payload (`days=1` / today).
Map<String, dynamic>? _timelineInMemoryRaw;
String? _timelineCacheOwnerUserId;

class TimelineState {
  final List<TimelineDay> days;
  final TimelineFilter filter;
  final String search;
  final bool isLoading;
  final String? error;

  /// `YYYY-MM-DD` of a day currently being fetched on demand via [loadDate]
  /// (a date-picker / week-strip jump outside the loaded window). Drives a
  /// per-date feed shimmer so the jump isn't a blank flash. Null when idle.
  final String? loadingDate;

  /// True while [loadMorePast] is fetching an older page (drives the
  /// "Show earlier" footer spinner in the multi-day timeline).
  final bool isLoadingMore;

  /// True once a [loadMorePast] page came back with no new days — there's no
  /// more history to load, so the "Show earlier" footer hides.
  final bool reachedEndPast;

  const TimelineState({
    this.days = const [],
    this.filter = TimelineFilter.all,
    this.search = '',
    this.isLoading = false,
    this.error,
    this.loadingDate,
    this.isLoadingMore = false,
    this.reachedEndPast = false,
  });

  TimelineState copyWith({
    List<TimelineDay>? days,
    TimelineFilter? filter,
    String? search,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? loadingDate,
    bool clearLoadingDate = false,
    bool? isLoadingMore,
    bool? reachedEndPast,
  }) {
    return TimelineState(
      days: days ?? this.days,
      filter: filter ?? this.filter,
      search: search ?? this.search,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      loadingDate: clearLoadingDate ? null : (loadingDate ?? this.loadingDate),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      reachedEndPast: reachedEndPast ?? this.reachedEndPast,
    );
  }
}

class TimelineNotifier extends StateNotifier<TimelineState> {
  final Ref _ref;
  bool _disposed = false;

  TimelineNotifier(this._ref) : super(const TimelineState(isLoading: true)) {
    // Cache-first: seed synchronously (in the body, NOT super(), so a parse
    // failure can't crash construction) from the module-level cache so the
    // Home timeline paints last-known events instantly with no loading
    // shimmer. The seed sets state during construction, so the first
    // `ref.watch` already sees the cached days. Cold start (no usable
    // in-memory cache) falls back to the disk read raced against the network.
    final seededDays =
        _timelineInMemoryRaw != null ? _daysFromRawSafe(_timelineInMemoryRaw!) : null;
    if (seededDays != null) {
      state = TimelineState(days: seededDays, isLoading: false);
      refresh(showLoading: false); // already painted — refresh silently
    } else {
      // No cache, or a corrupt in-memory blob — drop the poisoned raw so a
      // later recreation doesn't re-attempt the bad parse, then cold-load.
      _timelineInMemoryRaw = null;
      _loadWithCacheFirst();
    }
  }

  /// Parse a raw timeline payload into days, returning null (instead of
  /// throwing) on any malformed shape — so a corrupt cache entry degrades to a
  /// cold load rather than crashing the notifier's construction.
  static List<TimelineDay>? _daysFromRawSafe(Map<String, dynamic> raw) {
    try {
      return TimelineResponse.fromJson(raw).days;
    } catch (e) {
      debugPrint('⚠️ [Timeline] corrupt cached payload, ignoring: $e');
      return null;
    }
  }

  /// Read the live user id straight from Supabase's session (never a cached
  /// field — see the JWT-expiry rule in project memory). Used to scope the
  /// disk cache slot per user.
  String? _currentUserId() {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Cold-start path: fire the network refresh immediately and, in parallel,
  /// read the disk cache — painting stale-but-real events the instant they're
  /// available, but only if the network hasn't already delivered fresh data
  /// (never clobber fresh with stale). Mirrors `todayWorkoutProvider`.
  Future<void> _loadWithCacheFirst() async {
    final apiFuture = refresh(showLoading: false);
    try {
      final cached = await DataCacheService.instance.getCached(
        DataCacheService.timelineKey,
        userId: _currentUserId(),
        returnExpiredOnMiss: true,
      );
      // Parse BEFORE assigning the static, so a corrupt entry never poisons
      // `_timelineInMemoryRaw` (a later recreation would parse it in this same
      // safe path, but keeping the static clean avoids the foot-gun entirely).
      final days = cached != null ? _daysFromRawSafe(cached) : null;
      if (days != null && !_disposed && state.days.isEmpty) {
        _timelineInMemoryRaw = cached;
        state = state.copyWith(days: days, isLoading: false);
        debugPrint('⚡ [Timeline] Seeded from disk cache');
      }
    } catch (e) {
      debugPrint('⚠️ [Timeline] disk cache read error: $e');
    }
    await apiFuture;
  }

  Future<void> refresh({bool showLoading = true}) async {
    if (_disposed) return;
    final apiClient = _ref.read(apiClientProvider);
    final userId = await apiClient.getUserId();
    if (userId == null) {
      // Preserve any seeded/cached days on a transient signed-out read (e.g.
      // the logout teardown window) — only surface the error when empty, so a
      // widget that prioritizes `error` can't blank good cached data.
      state = state.copyWith(
        isLoading: false,
        error: state.days.isEmpty ? 'Not signed in' : null,
        clearError: state.days.isNotEmpty,
      );
      return;
    }
    // Only show the loading shimmer when we have nothing to paint yet — a
    // silent revalidation over already-visible cached data must not blank it.
    if (showLoading && state.days.isEmpty) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(clearError: true);
    }
    try {
      final repo = _ref.read(timelineRepositoryProvider);
      final result = await repo.fetchWithRaw(userId: userId, days: 1);
      if (_disposed) return;
      state = state.copyWith(days: result.parsed.days, isLoading: false);
      // Write-through to in-memory + disk for the next cold start / recreation.
      _timelineInMemoryRaw = result.raw;
      unawaited(DataCacheService.instance.cache(
        DataCacheService.timelineKey,
        result.raw,
        userId: userId,
      ));
    } catch (e) {
      debugPrint('⚠️ [Timeline] refresh failed: $e');
      if (_disposed) return;
      // Keep any cached days visible; only surface the error when we have
      // nothing to show (no silent blanking of real cached data).
      state = state.copyWith(
        isLoading: false,
        error: state.days.isEmpty ? e.toString() : null,
        clearError: state.days.isNotEmpty,
      );
    }
  }

  /// Whether an initial history page has already been requested (so the
  /// multi-day timeline doesn't re-trigger it on every rebuild).
  bool _initialHistoryRequested = false;

  /// Load the first window of PAST days once today's feed is present, so the
  /// timeline shows multiple days (today + the past week) instead of just
  /// today. Idempotent — runs at most once per notifier.
  Future<void> ensureInitialHistory({int days = 7}) async {
    if (_disposed || _initialHistoryRequested) return;
    if (state.days.isEmpty) return; // wait until today is loaded
    _initialHistoryRequested = true;
    await loadMorePast(additionalDays: days);
  }

  /// Append the next page of past days (infinite scroll). Sets [isLoadingMore]
  /// while in flight and [reachedEndPast] when a page returns no new days.
  Future<void> loadMorePast({int additionalDays = 7}) async {
    if (_disposed || state.days.isEmpty || state.isLoadingMore) return;
    final apiClient = _ref.read(apiClientProvider);
    final userId = await apiClient.getUserId();
    if (userId == null) return;

    // Anchor on the oldest currently-loaded day, fetch the previous N
    final oldestDate = state.days.last.date; // days are DESC
    final anchor = DateTime.parse(oldestDate)
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);

    state = state.copyWith(isLoadingMore: true);
    try {
      final repo = _ref.read(timelineRepositoryProvider);
      final response = await repo.fetch(
        userId: userId,
        date: anchor,
        days: additionalDays,
      );
      if (_disposed) return;
      // Merge: keep existing days + append the new ones (skip duplicates).
      final existingDates = state.days.map((d) => d.date).toSet();
      final fresh =
          response.days.where((d) => !existingDates.contains(d.date)).toList();
      state = state.copyWith(
        days: [...state.days, ...fresh],
        isLoadingMore: false,
        // No new days came back → we've hit the bottom of the history.
        reachedEndPast: fresh.isEmpty ? true : null,
      );
    } catch (e) {
      debugPrint('⚠️ [Timeline] loadMorePast failed: $e');
      if (_disposed) return;
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Ensure [day] (any local DateTime — normalized to its date) has its
  /// entries loaded, fetching on demand and merging if absent. Called when the
  /// header date picker (or a week-strip tap) selects a day outside the
  /// initially-loaded window, so the feed shows that day's real events rather
  /// than an empty state. No-op if the day is already loaded or in flight.
  Future<void> loadDate(DateTime day) async {
    if (_disposed) return;
    final dateStr = _ymd(day);
    if (dateStr == state.loadingDate) return; // already in flight
    if (state.days.any((d) => d.date == dateStr)) return; // already loaded
    final apiClient = _ref.read(apiClientProvider);
    final userId = await apiClient.getUserId();
    if (userId == null) return;
    state = state.copyWith(loadingDate: dateStr);
    try {
      final repo = _ref.read(timelineRepositoryProvider);
      final response = await repo.fetch(userId: userId, date: dateStr, days: 1);
      if (_disposed) return;
      final existing = state.days.map((d) => d.date).toSet();
      final merged = [
        ...state.days,
        ...response.days.where((d) => !existing.contains(d.date)),
      ]..sort((a, b) => b.date.compareTo(a.date)); // keep newest-first
      state = state.copyWith(days: merged, clearLoadingDate: true);
    } catch (e) {
      debugPrint('⚠️ [Timeline] loadDate($dateStr) failed: $e');
      if (_disposed) return;
      state = state.copyWith(clearLoadingDate: true);
    }
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  void setFilter(TimelineFilter filter) {
    if (_disposed) return;
    state = state.copyWith(filter: filter);
  }

  void setSearch(String query) {
    if (_disposed) return;
    state = state.copyWith(search: query);
  }

  /// Optimistically remove an entry from local state (used when the user
  /// taps Delete in the detail sheet — server delete fires in parallel).
  void removeEntry(String entryId) {
    if (_disposed) return;
    final updated = state.days
        .map((d) => TimelineDay(
              date: d.date,
              dayLabel: d.dayLabel,
              summary: d.summary,
              insights: d.insights,
              entries: d.entries.where((e) => e.id != entryId).toList(),
            ))
        .toList();
    state = state.copyWith(days: updated);
  }

  /// Apply current filter + search across all loaded days.
  List<TimelineDay> get visibleDays {
    if (state.filter == TimelineFilter.all && state.search.isEmpty) {
      return state.days;
    }
    final q = state.search.toLowerCase().trim();
    return state.days.map((d) {
      final filtered = d.entries.where((e) {
        if (!state.filter.matches(e)) return false;
        if (q.isEmpty) return true;
        return e.title.toLowerCase().contains(q) ||
            (e.subtitle ?? '').toLowerCase().contains(q);
      }).toList();
      return TimelineDay(
        date: d.date,
        dayLabel: d.dayLabel,
        summary: d.summary,
        insights: d.insights,
        entries: filtered,
      );
    }).toList();
  }
}

final timelineProvider =
    StateNotifierProvider<TimelineNotifier, TimelineState>((ref) {
  // Wipe the cross-instance cache on a real user-id change so a new account
  // never inherits the prior user's timeline (mirrors todayWorkoutProvider).
  final userId = ref.watch(authStateProvider.select((s) => s.user?.id));
  if (userId != null && userId != _timelineCacheOwnerUserId) {
    _timelineCacheOwnerUserId = userId;
    _timelineInMemoryRaw = null;
  }
  return TimelineNotifier(ref);
});

// ---------------------------------------------------------------------------
// Trends — a separate, lightweight 14-day fetch (summaries only) powering the
// Home timeline's trend rail (Sleep / Calories / Water sparklines). Kept apart
// from `timelineProvider` so the multi-day series never blocks the single-day
// event feed and the heavy `entries` arrays are skipped over the wire.
// ---------------------------------------------------------------------------

/// How many days of summaries the trend rail plots.
const int kTimelineTrendDays = 14;

class TimelineTrendsState {
  /// Newest-first list of days, each carrying only `date` + `summary`.
  final List<TimelineDay> days;
  final bool isLoading;
  final String? error;

  const TimelineTrendsState({
    this.days = const [],
    this.isLoading = false,
    this.error,
  });

  TimelineTrendsState copyWith({
    List<TimelineDay>? days,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TimelineTrendsState(
      days: days ?? this.days,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class TimelineTrendsNotifier extends StateNotifier<TimelineTrendsState> {
  final Ref _ref;
  bool _disposed = false;

  TimelineTrendsNotifier(this._ref)
      : super(const TimelineTrendsState(isLoading: true)) {
    refresh();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> refresh() async {
    if (_disposed) return;
    final apiClient = _ref.read(apiClientProvider);
    final userId = await apiClient.getUserId();
    if (userId == null) {
      state = state.copyWith(isLoading: false);
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = _ref.read(timelineRepositoryProvider);
      final response = await repo.fetch(
        userId: userId,
        days: kTimelineTrendDays,
        metricsOnly: true,
      );
      if (_disposed) return;
      state = state.copyWith(days: response.days, isLoading: false);
    } catch (e) {
      // The trend rail is secondary chrome — on failure it self-hides rather
      // than showing an error tile (the event feed owns the retry surface).
      debugPrint('⚠️ [TimelineTrends] refresh failed: $e');
      if (_disposed) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final timelineTrendsProvider =
    StateNotifierProvider<TimelineTrendsNotifier, TimelineTrendsState>((ref) {
  return TimelineTrendsNotifier(ref);
});
