/// Riverpod provider for the Home Timeline section.
///
/// Fetches `/api/v1/timeline?date=today&days=1` and exposes the parsed
/// response. Methods:
///   - refresh()        — refetch latest day, bypass server cache (60s)
///   - loadMorePast()   — append previous days for infinite-scroll
///   - setFilter(f)     — apply a TimelineFilter chip (client-side)
///   - setSearch(q)     — substring filter across title + notes
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/timeline_entry.dart';
import '../repositories/timeline_repository.dart';
import '../services/api_client.dart';

final timelineRepositoryProvider = Provider<TimelineRepository>((ref) {
  return TimelineRepository(ref.read(apiClientProvider));
});

class TimelineState {
  final List<TimelineDay> days;
  final TimelineFilter filter;
  final String search;
  final bool isLoading;
  final String? error;

  const TimelineState({
    this.days = const [],
    this.filter = TimelineFilter.all,
    this.search = '',
    this.isLoading = false,
    this.error,
  });

  TimelineState copyWith({
    List<TimelineDay>? days,
    TimelineFilter? filter,
    String? search,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TimelineState(
      days: days ?? this.days,
      filter: filter ?? this.filter,
      search: search ?? this.search,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class TimelineNotifier extends StateNotifier<TimelineState> {
  final Ref _ref;
  bool _disposed = false;

  TimelineNotifier(this._ref) : super(const TimelineState(isLoading: true)) {
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
      state = state.copyWith(isLoading: false, error: 'Not signed in');
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = _ref.read(timelineRepositoryProvider);
      final response = await repo.fetch(userId: userId, days: 1);
      if (_disposed) return;
      state = state.copyWith(days: response.days, isLoading: false);
    } catch (e) {
      debugPrint('⚠️ [Timeline] refresh failed: $e');
      if (_disposed) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Append the next page of past days (infinite scroll).
  Future<void> loadMorePast({int additionalDays = 7}) async {
    if (_disposed || state.days.isEmpty) return;
    final apiClient = _ref.read(apiClientProvider);
    final userId = await apiClient.getUserId();
    if (userId == null) return;

    // Anchor on the oldest currently-loaded day, fetch the previous N
    final oldestDate = state.days.last.date; // days are DESC
    final anchor = DateTime.parse(oldestDate)
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);

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
      final merged = [
        ...state.days,
        ...response.days.where((d) => !existingDates.contains(d.date)),
      ];
      state = state.copyWith(days: merged);
    } catch (e) {
      debugPrint('⚠️ [Timeline] loadMorePast failed: $e');
    }
  }

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
  return TimelineNotifier(ref);
});
