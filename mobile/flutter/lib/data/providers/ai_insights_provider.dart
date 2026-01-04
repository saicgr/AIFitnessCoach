import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../repositories/auth_repository.dart';

// ============================================
// AI Insights State
// ============================================

/// State for AI-generated insights
class AIInsightsState {
  final String? dailyTip;
  final String? weightInsight;
  final List<HabitSuggestion> habitSuggestions;
  final bool isLoadingTip;
  final bool isLoadingWeight;
  final bool isLoadingHabits;
  final String? error;
  final DateTime? lastUpdated;

  const AIInsightsState({
    this.dailyTip,
    this.weightInsight,
    this.habitSuggestions = const [],
    this.isLoadingTip = false,
    this.isLoadingWeight = false,
    this.isLoadingHabits = false,
    this.error,
    this.lastUpdated,
  });

  AIInsightsState copyWith({
    String? dailyTip,
    String? weightInsight,
    List<HabitSuggestion>? habitSuggestions,
    bool? isLoadingTip,
    bool? isLoadingWeight,
    bool? isLoadingHabits,
    String? error,
    DateTime? lastUpdated,
    bool clearError = false,
  }) {
    return AIInsightsState(
      dailyTip: dailyTip ?? this.dailyTip,
      weightInsight: weightInsight ?? this.weightInsight,
      habitSuggestions: habitSuggestions ?? this.habitSuggestions,
      isLoadingTip: isLoadingTip ?? this.isLoadingTip,
      isLoadingWeight: isLoadingWeight ?? this.isLoadingWeight,
      isLoadingHabits: isLoadingHabits ?? this.isLoadingHabits,
      error: clearError ? null : (error ?? this.error),
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  bool get isLoading => isLoadingTip || isLoadingWeight || isLoadingHabits;
  bool get hasTip => dailyTip != null && dailyTip!.isNotEmpty;
  bool get hasWeightInsight => weightInsight != null && weightInsight!.isNotEmpty;
  bool get hasHabitSuggestions => habitSuggestions.isNotEmpty;
}

/// Habit suggestion model
class HabitSuggestion {
  final String name;
  final String reason;

  const HabitSuggestion({required this.name, required this.reason});

  factory HabitSuggestion.fromJson(Map<String, dynamic> json) {
    return HabitSuggestion(
      name: json['name'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
    );
  }
}

// ============================================
// AI Insights Notifier
// ============================================

class AIInsightsNotifier extends StateNotifier<AIInsightsState> {
  final ApiClient _apiClient;
  String? _userId;

  AIInsightsNotifier(this._apiClient) : super(const AIInsightsState());

  /// Set user ID and load initial data
  Future<void> initialize(String userId) async {
    _userId = userId;
    await loadDailyTip();
  }

  /// Load daily tip from AI
  Future<void> loadDailyTip({bool forceRefresh = false}) async {
    if (_userId == null) return;
    if (state.isLoadingTip) return;

    state = state.copyWith(isLoadingTip: true, clearError: true);

    try {
      final response = await _apiClient.dio.get(
        '/insights/$_userId/daily-tip',
        queryParameters: {'force_refresh': forceRefresh},
      );

      if (response.statusCode == 200 && response.data != null) {
        final tip = response.data['tip'] as String?;
        state = state.copyWith(
          dailyTip: tip,
          isLoadingTip: false,
          lastUpdated: DateTime.now(),
        );
      } else {
        state = state.copyWith(isLoadingTip: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingTip: false,
        error: 'Failed to load daily tip',
      );
    }
  }

  /// Load weight insight from AI
  Future<void> loadWeightInsight({bool forceRefresh = false}) async {
    if (_userId == null) return;
    if (state.isLoadingWeight) return;

    state = state.copyWith(isLoadingWeight: true, clearError: true);

    try {
      final response = await _apiClient.dio.get(
        '/insights/$_userId/weight-insight',
        queryParameters: {'force_refresh': forceRefresh},
      );

      if (response.statusCode == 200 && response.data != null) {
        final insight = response.data['insight'] as String?;
        state = state.copyWith(
          weightInsight: insight,
          isLoadingWeight: false,
          lastUpdated: DateTime.now(),
        );
      } else {
        state = state.copyWith(isLoadingWeight: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingWeight: false,
        error: 'Failed to load weight insight',
      );
    }
  }

  /// Load habit suggestions from AI
  Future<void> loadHabitSuggestions({bool forceRefresh = false}) async {
    if (_userId == null) return;
    if (state.isLoadingHabits) return;

    state = state.copyWith(isLoadingHabits: true, clearError: true);

    try {
      final response = await _apiClient.dio.get(
        '/insights/$_userId/habit-suggestions',
        queryParameters: {'force_refresh': forceRefresh},
      );

      if (response.statusCode == 200 && response.data != null) {
        final suggestionsJson = response.data['suggestions'] as List<dynamic>?;
        final suggestions = suggestionsJson
                ?.map((s) => HabitSuggestion.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [];

        state = state.copyWith(
          habitSuggestions: suggestions,
          isLoadingHabits: false,
          lastUpdated: DateTime.now(),
        );
      } else {
        state = state.copyWith(isLoadingHabits: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingHabits: false,
        error: 'Failed to load habit suggestions',
      );
    }
  }

  /// Refresh all insights
  Future<void> refreshAll() async {
    await Future.wait([
      loadDailyTip(forceRefresh: true),
      loadWeightInsight(forceRefresh: true),
      loadHabitSuggestions(forceRefresh: true),
    ]);
  }
}

// ============================================
// Providers
// ============================================

/// Main AI insights provider
final aiInsightsProvider =
    StateNotifierProvider<AIInsightsNotifier, AIInsightsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AIInsightsNotifier(apiClient);
});

/// Auto-dispose provider for daily tip (with user ID)
final dailyTipProvider = FutureProvider.autoDispose<String?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.id;

  if (userId == null) return null;

  try {
    final apiClient = ref.watch(apiClientProvider);
    final response = await apiClient.dio.get('/insights/$userId/daily-tip');

    if (response.statusCode == 200 && response.data != null) {
      return response.data['tip'] as String?;
    }
  } catch (e) {
    // Return fallback tip on error
    return _getFallbackTip();
  }

  return _getFallbackTip();
});

/// Auto-dispose provider for weight insight
final weightInsightProvider = FutureProvider.autoDispose<String?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.id;

  if (userId == null) return null;

  try {
    final apiClient = ref.watch(apiClientProvider);
    final response = await apiClient.dio.get('/insights/$userId/weight-insight');

    if (response.statusCode == 200 && response.data != null) {
      return response.data['insight'] as String?;
    }
  } catch (e) {
    return null;
  }

  return null;
});

/// Helper function for fallback tips
String _getFallbackTip() {
  final hour = DateTime.now().hour;
  if (hour < 12) {
    return "Start your day with 10 minutes of stretching to boost energy and flexibility.";
  } else if (hour < 17) {
    return "Stay hydrated! Aim for at least 8 glasses of water before dinner.";
  } else {
    return "Wind down with some light mobility work to improve tomorrow's workout.";
  }
}
