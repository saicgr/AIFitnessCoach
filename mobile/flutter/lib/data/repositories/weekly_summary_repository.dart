import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/weekly_summary.dart';
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

/// Weekly summary repository
class WeeklySummaryRepository {
  final ApiClient _client;

  WeeklySummaryRepository(this._client);

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
}
