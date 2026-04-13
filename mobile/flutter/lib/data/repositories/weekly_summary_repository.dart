import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/weekly_summary.dart';
import '../models/insights_report.dart';
import '../services/api_client.dart';

/// Weekly summary repository provider
final weeklySummaryRepositoryProvider = Provider<WeeklySummaryRepository>((ref) {
  return WeeklySummaryRepository(ref.watch(apiClientProvider));
});

/// Weekly summary state
class WeeklySummaryState {
  final bool isLoading;
  final bool isGenerating;
  final String? error;
  final WeeklySummary? latestSummary;
  final List<WeeklySummary> summaries;

  const WeeklySummaryState({
    this.isLoading = false,
    this.isGenerating = false,
    this.error,
    this.latestSummary,
    this.summaries = const [],
  });

  WeeklySummaryState copyWith({
    bool? isLoading,
    bool? isGenerating,
    String? error,
    WeeklySummary? latestSummary,
    List<WeeklySummary>? summaries,
  }) {
    return WeeklySummaryState(
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
      latestSummary: latestSummary ?? this.latestSummary,
      summaries: summaries ?? this.summaries,
    );
  }
}

/// Weekly summary state provider
final weeklySummaryProvider =
    StateNotifierProvider<WeeklySummaryNotifier, WeeklySummaryState>((ref) {
  return WeeklySummaryNotifier(ref.watch(weeklySummaryRepositoryProvider));
});

/// Weekly summary state notifier
class WeeklySummaryNotifier extends StateNotifier<WeeklySummaryState> {
  final WeeklySummaryRepository _repository;

  WeeklySummaryNotifier(this._repository) : super(const WeeklySummaryState());

  /// Load latest summary for a user
  Future<void> loadLatestSummary(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final summary = await _repository.getLatestSummary(userId);
      state = state.copyWith(isLoading: false, latestSummary: summary);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load all summaries for a user
  Future<void> loadSummaries(String userId, {int limit = 12}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final summaries = await _repository.getSummaries(userId, limit: limit);
      state = state.copyWith(isLoading: false, summaries: summaries);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Generate a new weekly summary
  Future<WeeklySummary?> generateSummary(String userId, {String? weekStart}) async {
    // Prevent duplicate concurrent generation requests
    if (state.isGenerating) return null;
    state = state.copyWith(isGenerating: true, error: null);
    try {
      final summary = await _repository.generateSummary(userId, weekStart: weekStart);
      state = state.copyWith(
        isGenerating: false,
        latestSummary: summary,
        summaries: [summary, ...state.summaries],
      );
      return summary;
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: e.toString());
      return null;
    }
  }
}

/// In-memory insights-report cache entry. Short TTL because the report
/// changes whenever the user completes a workout, logs readiness, etc. — we
/// only want to spare repeat renders in the same session.
class _CachedReport {
  final InsightsReport report;
  final DateTime fetchedAt;
  const _CachedReport(this.report, this.fetchedAt);
}

/// Weekly summary repository
class WeeklySummaryRepository {
  final ApiClient _client;

  WeeklySummaryRepository(this._client);

  /// In-memory TTL cache keyed on (userId, startDate, endDate, groupBy, include).
  /// 60 s is short enough to never show stale post-workout numbers but long
  /// enough to cover the "user tapped back, then back into Insights" pattern.
  static const Duration _cacheTtl = Duration(seconds: 60);
  final Map<String, _CachedReport> _reportCache = {};

  String _reportCacheKey(
    String userId, {
    required String startDate,
    required String endDate,
    required String groupBy,
    required String include,
  }) =>
      '$userId|$startDate|$endDate|$groupBy|$include';

  /// Non-blocking peek at the cache. Returns the last report we fetched for
  /// this key if it's still within [_cacheTtl], else null.
  InsightsReport? getCachedInsightsReport(
    String userId, {
    required String startDate,
    required String endDate,
    String groupBy = 'week',
    String include = 'all',
  }) {
    final key = _reportCacheKey(
      userId,
      startDate: startDate,
      endDate: endDate,
      groupBy: groupBy,
      include: include,
    );
    final entry = _reportCache[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.fetchedAt) > _cacheTtl) {
      _reportCache.remove(key);
      return null;
    }
    return entry.report;
  }

  /// Invalidate all cached reports for a user. Call after a workout completes
  /// or the user logs nutrition so the next Insights open refetches.
  void invalidateInsightsCache({String? userId}) {
    if (userId == null) {
      _reportCache.clear();
      return;
    }
    final prefix = '$userId|';
    _reportCache.removeWhere((k, _) => k.startsWith(prefix));
  }

  /// Generate a new weekly summary
  Future<WeeklySummary> generateSummary(String userId, {String? weekStart}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (weekStart != null) queryParams['week_start'] = weekStart;

      final response = await _client.post(
        '/summaries/generate/$userId',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return WeeklySummary.fromJson(response.data);
    } catch (e) {
      debugPrint('Error generating weekly summary: $e');
      rethrow;
    }
  }

  /// Get all summaries for a user
  Future<List<WeeklySummary>> getSummaries(String userId, {int limit = 12}) async {
    try {
      final response = await _client.get(
        '/summaries/user/$userId',
        queryParameters: {'limit': limit},
      );
      final data = response.data as List;
      return data.map((json) => WeeklySummary.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting summaries: $e');
      rethrow;
    }
  }

  /// Get latest summary for a user
  Future<WeeklySummary?> getLatestSummary(String userId) async {
    try {
      final response = await _client.get('/summaries/user/$userId/latest');
      if (response.data == null) return null;
      return WeeklySummary.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting latest summary: $e');
      return null;
    }
  }

  /// Get insights report for an arbitrary date range.
  ///
  /// Always hits the network; populates the in-memory cache on success so a
  /// subsequent [getCachedInsightsReport] call for the same key returns
  /// instantly within the TTL window.
  Future<InsightsReport> getInsightsReport(
    String userId, {
    required String startDate,
    required String endDate,
    String groupBy = 'week',
    String include = 'all',
  }) async {
    try {
      final response = await _client.get(
        '/summaries/user/$userId/report',
        queryParameters: {
          'start_date': startDate,
          'end_date': endDate,
          'group_by': groupBy,
          'include': include,
        },
      );
      final report = InsightsReport.fromJson(response.data);
      final key = _reportCacheKey(
        userId,
        startDate: startDate,
        endDate: endDate,
        groupBy: groupBy,
        include: include,
      );
      _reportCache[key] = _CachedReport(report, DateTime.now());
      return report;
    } catch (e) {
      debugPrint('Error getting insights report: $e');
      rethrow;
    }
  }

  /// Generate AI insight narrative for an arbitrary date range
  Future<InsightsAiNarrative> generateInsightNarrative(
    String userId, {
    required String startDate,
    required String endDate,
    required String periodLabel,
  }) async {
    try {
      final response = await _client.post(
        '/summaries/user/$userId/generate-insight',
        queryParameters: {
          'start_date': startDate,
          'end_date': endDate,
          'period_label': periodLabel,
        },
      );
      return InsightsAiNarrative.fromJson(response.data);
    } catch (e) {
      debugPrint('Error generating insight narrative: $e');
      rethrow;
    }
  }
}
