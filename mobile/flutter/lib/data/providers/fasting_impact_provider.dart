import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fasting_impact.dart';
import '../services/api_client.dart';

/// State for fasting impact analysis
class FastingImpactState {
  final bool isLoading;
  final String? error;
  final FastingImpactData? data;
  final FastingImpactPeriod selectedPeriod;

  const FastingImpactState({
    this.isLoading = false,
    this.error,
    this.data,
    this.selectedPeriod = FastingImpactPeriod.month,
  });

  FastingImpactState copyWith({
    bool? isLoading,
    String? error,
    FastingImpactData? data,
    FastingImpactPeriod? selectedPeriod,
  }) {
    return FastingImpactState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      data: data ?? this.data,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
    );
  }

  bool get hasData => data != null && data!.dailyData.isNotEmpty;
  bool get hasEnoughData =>
      data != null && data!.comparison.fastingDaysCount >= 3;
}

/// Provider for fasting impact analysis
class FastingImpactNotifier extends StateNotifier<FastingImpactState> {
  final ApiClient _apiClient;

  FastingImpactNotifier(this._apiClient) : super(const FastingImpactState());

  /// Convert FastingImpactPeriod to backend period string
  String _periodToBackendString(FastingImpactPeriod period) {
    switch (period) {
      case FastingImpactPeriod.week:
        return 'week';
      case FastingImpactPeriod.month:
        return 'month';
      case FastingImpactPeriod.threeMonths:
        return '3months';
    }
  }

  /// Load fasting impact data from the API
  Future<void> loadImpactData({
    required String userId,
    FastingImpactPeriod? period,
  }) async {
    final targetPeriod = period ?? state.selectedPeriod;

    state = state.copyWith(
      isLoading: true,
      error: null,
      selectedPeriod: targetPeriod,
    );

    try {
      if (kDebugMode) {
        debugPrint(
            '🔍 [FastingImpact] Loading impact data for user $userId, period: ${targetPeriod.displayName}');
      }

      // Fetch analysis data from the backend
      final analysisResponse = await _apiClient.get(
        '/fasting-impact/analysis/$userId',
        queryParameters: {
          'period': _periodToBackendString(targetPeriod),
        },
      );

      if (analysisResponse.statusCode != 200 ||
          analysisResponse.data == null) {
        throw Exception(
            'Failed to fetch fasting impact analysis: ${analysisResponse.statusMessage}');
      }

      final analysisData = analysisResponse.data as Map<String, dynamic>;

      if (kDebugMode) {
        debugPrint('✅ [FastingImpact] Analysis data received: ${analysisData.keys}');
      }

      // Fetch calendar data to get daily breakdown
      final now = DateTime.now();
      final calendarResponse = await _apiClient.get(
        '/fasting-impact/calendar/$userId',
        queryParameters: {
          'month': now.month.toString(),
          'year': now.year.toString(),
        },
      );

      List<FastingDayData> dailyData = [];

      if (calendarResponse.statusCode == 200 &&
          calendarResponse.data != null) {
        final calendarData = calendarResponse.data as Map<String, dynamic>;
        final days = calendarData['days'] as List<dynamic>? ?? [];

        if (kDebugMode) {
          debugPrint(
              '✅ [FastingImpact] Calendar data received: ${days.length} days');
        }

        dailyData = days.map((day) {
          final dayMap = day as Map<String, dynamic>;
          return FastingDayData(
            date: DateTime.parse(dayMap['date'] as String),
            isFastingDay: dayMap['is_fasting_day'] as bool? ?? false,
            fastingHours: (dayMap['fasting_completion_percent'] as num?)
                    ?.toDouble(),
            weight: (dayMap['weight_logged'] as num?)?.toDouble(),
            hadWorkout: dayMap['workout_completed'] as bool? ?? false,
            goalsCompleted: dayMap['goals_hit'] as int? ?? 0,
            goalsTotal: dayMap['goals_total'] as int? ?? 0,
          );
        }).toList();
      } else {
        if (kDebugMode) {
          debugPrint(
              '⚠️ [FastingImpact] Calendar data not available, using empty daily data');
        }
      }

      // Parse the analysis response and map to FastingImpactData
      final impactData = _mapBackendResponseToFastingImpactData(
        userId: userId,
        analysisData: analysisData,
        dailyData: dailyData,
        period: targetPeriod,
      );

      state = state.copyWith(
        isLoading: false,
        data: impactData,
        error: null,
      );

      if (kDebugMode) {
        debugPrint(
            '✅ [FastingImpact] Data loaded successfully. Fasting days: ${impactData.comparison.fastingDaysCount}');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ [FastingImpact] Error loading data: $e');
        debugPrint('Stack: $stackTrace');
      }

      // Set error state - NO mock data fallback
      state = state.copyWith(
        isLoading: false,
        error: _formatErrorMessage(e),
        data: null,
      );
    }
  }

  /// Map backend FastingGoalImpactResponse to Flutter FastingImpactData
  FastingImpactData _mapBackendResponseToFastingImpactData({
    required String userId,
    required Map<String, dynamic> analysisData,
    required List<FastingDayData> dailyData,
    required FastingImpactPeriod period,
  }) {
    // Extract comparison stats from backend response
    // Note: These values are computed but actual counts come from dailyData
    final _ = (analysisData['workouts_on_fasting_days'] as int? ?? 0) +
        (analysisData['goals_hit_on_fasting_days'] as int? ?? 0);
    final __ = (analysisData['workouts_on_non_fasting_days'] as int? ?? 0) +
        (analysisData['goals_hit_on_non_fasting_days'] as int? ?? 0);

    final comparison = FastingComparisonStats(
      fastingDaysCount:
          dailyData.where((d) => d.isFastingDay).length,
      nonFastingDaysCount:
          dailyData.where((d) => !d.isFastingDay).length,
      avgWeightFasting:
          (analysisData['avg_weight_fasting_days'] as num?)?.toDouble(),
      avgWeightNonFasting:
          (analysisData['avg_weight_non_fasting_days'] as num?)?.toDouble(),
      avgWorkoutPerformanceFasting:
          (analysisData['avg_workout_completion_fasting'] as num?)?.toDouble(),
      avgWorkoutPerformanceNonFasting:
          (analysisData['avg_workout_completion_non_fasting'] as num?)
              ?.toDouble(),
      workoutsOnFastingDays:
          analysisData['workouts_on_fasting_days'] as int? ?? 0,
      workoutsOnNonFastingDays:
          analysisData['workouts_on_non_fasting_days'] as int? ?? 0,
      goalCompletionRateFasting:
          (analysisData['goal_completion_rate_fasting'] as num?)?.toDouble() ??
              0,
      goalCompletionRateNonFasting:
          (analysisData['goal_completion_rate_non_fasting'] as num?)
                  ?.toDouble() ??
              0,
    );

    // Extract correlation score
    final correlationScore =
        (analysisData['correlation_score'] as num?)?.toDouble() ?? 0;

    // Build insights from backend recommendations and summary
    final insights = _buildInsightsFromBackend(analysisData);

    return FastingImpactData(
      userId: userId,
      period: period,
      analysisDate: DateTime.tryParse(
              analysisData['analysis_date'] as String? ?? '') ??
          DateTime.now(),
      weightCorrelationScore: correlationScore,
      workoutCorrelationScore: correlationScore, // Backend provides single correlation
      goalCorrelationScore: correlationScore,
      overallCorrelationScore: correlationScore,
      dailyData: dailyData,
      comparison: comparison,
      insights: insights,
      summaryText: analysisData['fasting_impact_summary'] as String?,
    );
  }

  /// Build FastingInsight list from backend response
  List<FastingInsight> _buildInsightsFromBackend(
      Map<String, dynamic> analysisData) {
    final insights = <FastingInsight>[];

    // Add summary as main insight
    final summary = analysisData['fasting_impact_summary'] as String?;
    if (summary != null && summary.isNotEmpty) {
      insights.add(FastingInsight(
        id: 'summary',
        title: 'Fasting Impact Analysis',
        description: summary,
        insightType: _determineInsightType(analysisData),
        icon: 'analytics',
        confidence: 0.8,
      ));
    }

    // Add correlation interpretation as insight
    final correlationInterpretation =
        analysisData['correlation_interpretation'] as String?;
    if (correlationInterpretation != null &&
        correlationInterpretation.isNotEmpty) {
      insights.add(FastingInsight(
        id: 'correlation',
        title: 'Correlation Insight',
        description: correlationInterpretation,
        insightType: _determineCorrelationInsightType(
            (analysisData['correlation_score'] as num?)?.toDouble()),
        icon: 'trending_up',
        confidence: 0.7,
      ));
    }

    // Add recommendations as insights
    final recommendations =
        analysisData['recommendations'] as List<dynamic>? ?? [];
    for (int i = 0; i < recommendations.length; i++) {
      final rec = recommendations[i] as String;
      insights.add(FastingInsight(
        id: 'recommendation_$i',
        title: 'Recommendation',
        description: rec,
        insightType: 'suggestion',
        icon: 'lightbulb',
        confidence: 0.6,
      ));
    }

    return insights;
  }

  /// Determine insight type based on backend data
  String _determineInsightType(Map<String, dynamic> data) {
    final correlationScore =
        (data['correlation_score'] as num?)?.toDouble() ?? 0;
    final goalRateFasting =
        (data['goal_completion_rate_fasting'] as num?)?.toDouble() ?? 0;
    final goalRateNonFasting =
        (data['goal_completion_rate_non_fasting'] as num?)?.toDouble() ?? 0;

    if (correlationScore > 0.3 || goalRateFasting > goalRateNonFasting + 10) {
      return 'positive';
    } else if (correlationScore < -0.3 ||
        goalRateFasting < goalRateNonFasting - 10) {
      return 'warning';
    }
    return 'neutral';
  }

  /// Determine insight type based on correlation score
  String _determineCorrelationInsightType(double? score) {
    if (score == null) return 'neutral';
    if (score > 0.3) return 'positive';
    if (score < -0.3) return 'warning';
    return 'neutral';
  }

  /// Format error message for user display
  String _formatErrorMessage(dynamic error) {
    final errorString = error.toString();

    // Handle common error cases with user-friendly messages
    if (errorString.contains('SocketException') ||
        errorString.contains('Connection refused')) {
      return 'Unable to connect to server. Please check your internet connection.';
    }
    if (errorString.contains('TimeoutException') ||
        errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    if (errorString.contains('401') || errorString.contains('Unauthorized')) {
      return 'Session expired. Please sign in again.';
    }
    if (errorString.contains('404') || errorString.contains('Not Found')) {
      return 'Fasting impact data not found. Start tracking your fasts to see insights.';
    }
    if (errorString.contains('500') ||
        errorString.contains('Internal Server Error')) {
      return 'Server error. Please try again later.';
    }

    // Return the original error message for other cases
    return 'Failed to load fasting impact data: $errorString';
  }

  void setPeriod(FastingImpactPeriod period, String userId) {
    if (period != state.selectedPeriod) {
      loadImpactData(userId: userId, period: period);
    }
  }

  void refresh(String userId) {
    loadImpactData(userId: userId, period: state.selectedPeriod);
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for fasting impact state
final fastingImpactProvider =
    StateNotifierProvider<FastingImpactNotifier, FastingImpactState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FastingImpactNotifier(apiClient);
});

/// Provider for quick insight (summary for main fasting screen)
final fastingQuickInsightProvider = Provider<FastingInsight?>((ref) {
  final state = ref.watch(fastingImpactProvider);
  if (!state.hasData || state.data!.insights.isEmpty) return null;

  // Return the first positive insight or first available
  return state.data!.insights.firstWhere(
    (i) => i.isPositive,
    orElse: () => state.data!.insights.first,
  );
});
