import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../services/api_client.dart';

/// Metrics repository provider
final metricsRepositoryProvider = Provider<MetricsRepository>((ref) {
  return MetricsRepository(ref.watch(apiClientProvider));
});

/// Health metrics model
class HealthMetrics {
  final double? bmi;
  final String? bmiCategory;
  final double? tdee;
  final double? bmr;
  final double? bodyFatPercent;
  final double? leanMass;
  final double? fatMass;
  final int? dailyCalorieTarget;
  final int? dailyProteinTarget;
  final int? dailyCarbsTarget;
  final int? dailyFatTarget;

  // Additional dashboard fields
  final double? weightKg;
  final double? previousWeightKg;
  final int? restingHeartRate;
  final int? workoutsCompleted;
  final int? streak;
  final int? totalMinutes;
  final int? caloriesBurned;

  HealthMetrics({
    this.bmi,
    this.bmiCategory,
    this.tdee,
    this.bmr,
    this.bodyFatPercent,
    this.leanMass,
    this.fatMass,
    this.dailyCalorieTarget,
    this.dailyProteinTarget,
    this.dailyCarbsTarget,
    this.dailyFatTarget,
    this.weightKg,
    this.previousWeightKg,
    this.restingHeartRate,
    this.workoutsCompleted,
    this.streak,
    this.totalMinutes,
    this.caloriesBurned,
  });

  factory HealthMetrics.fromJson(Map<String, dynamic> json) {
    return HealthMetrics(
      bmi: (json['bmi'] as num?)?.toDouble(),
      bmiCategory: json['bmi_category'],
      tdee: (json['tdee'] as num?)?.toDouble(),
      bmr: (json['bmr'] as num?)?.toDouble(),
      bodyFatPercent: (json['body_fat_percentage'] as num?)?.toDouble() ??
          (json['body_fat_percent'] as num?)?.toDouble(),
      leanMass: (json['lean_mass'] as num?)?.toDouble(),
      fatMass: (json['fat_mass'] as num?)?.toDouble(),
      dailyCalorieTarget: json['daily_calorie_target'],
      dailyProteinTarget: json['daily_protein_target'],
      dailyCarbsTarget: json['daily_carbs_target'],
      dailyFatTarget: json['daily_fat_target'],
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      previousWeightKg: (json['previous_weight_kg'] as num?)?.toDouble(),
      restingHeartRate: json['resting_heart_rate'],
      workoutsCompleted: json['workouts_completed'] ?? json['workouts_this_week'],
      streak: json['streak'] ?? json['active_streak'],
      totalMinutes: json['total_minutes'] ?? json['workout_minutes'],
      caloriesBurned: json['calories_burned'] ?? json['total_calories'],
    );
  }
}

/// Metric history entry
class MetricHistoryEntry {
  final String id;
  final String metricType;
  final double value;
  final String? unit;
  final DateTime recordedAt;
  final String? notes;

  MetricHistoryEntry({
    required this.id,
    required this.metricType,
    required this.value,
    this.unit,
    required this.recordedAt,
    this.notes,
  });

  factory MetricHistoryEntry.fromJson(Map<String, dynamic> json) {
    return MetricHistoryEntry(
      id: json['id']?.toString() ?? '',
      metricType: json['metric_type'] ?? '',
      value: (json['value'] as num).toDouble(),
      unit: json['unit'],
      recordedAt: DateTime.parse(json['recorded_at'] ?? json['created_at']),
      notes: json['notes'],
    );
  }
}

/// Metrics state
class MetricsState {
  final bool isLoading;
  final String? error;
  final HealthMetrics? latestMetrics;
  final List<MetricHistoryEntry> history;
  final Map<String, List<MetricHistoryEntry>> historyByType;

  const MetricsState({
    this.isLoading = false,
    this.error,
    this.latestMetrics,
    this.history = const [],
    this.historyByType = const {},
  });

  MetricsState copyWith({
    bool? isLoading,
    String? error,
    HealthMetrics? latestMetrics,
    List<MetricHistoryEntry>? history,
    Map<String, List<MetricHistoryEntry>>? historyByType,
  }) {
    return MetricsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      latestMetrics: latestMetrics ?? this.latestMetrics,
      history: history ?? this.history,
      historyByType: historyByType ?? this.historyByType,
    );
  }
}

/// Metrics state provider
final metricsProvider =
    StateNotifierProvider<MetricsNotifier, MetricsState>((ref) {
  return MetricsNotifier(ref.watch(metricsRepositoryProvider));
});

/// Metrics state notifier
class MetricsNotifier extends StateNotifier<MetricsState> {
  final MetricsRepository _repository;

  MetricsNotifier(this._repository) : super(const MetricsState());

  /// Load current metrics for user
  Future<void> loadMetrics(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final metrics = await _repository.getLatestMetrics(userId);
      state = state.copyWith(isLoading: false, latestMetrics: metrics);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load metric history
  Future<void> loadHistory(String userId, {String? metricType}) async {
    try {
      final history = await _repository.getMetricHistory(userId, metricType: metricType);
      if (metricType != null) {
        final newHistoryByType = Map<String, List<MetricHistoryEntry>>.from(state.historyByType);
        newHistoryByType[metricType] = history;
        state = state.copyWith(historyByType: newHistoryByType);
      } else {
        state = state.copyWith(history: history);
      }
    } catch (e) {
      debugPrint('❌ Error loading metric history: $e');
    }
  }

  /// Record a new metric
  Future<bool> recordMetric({
    required String userId,
    required String metricType,
    required double value,
    String? unit,
    String? notes,
  }) async {
    try {
      await _repository.recordMetric(
        userId: userId,
        metricType: metricType,
        value: value,
        unit: unit,
        notes: notes,
      );
      // Reload metrics after recording
      await loadMetrics(userId);
      return true;
    } catch (e) {
      debugPrint('❌ Error recording metric: $e');
      return false;
    }
  }

  /// Calculate metrics from user data
  Future<HealthMetrics?> calculateMetrics({
    required double heightCm,
    required double weightKg,
    required int age,
    required String gender,
    required String activityLevel,
    required String goal,
  }) async {
    try {
      return await _repository.calculateMetrics(
        heightCm: heightCm,
        weightKg: weightKg,
        age: age,
        gender: gender,
        activityLevel: activityLevel,
        goal: goal,
      );
    } catch (e) {
      debugPrint('❌ Error calculating metrics: $e');
      return null;
    }
  }
}

/// Metrics repository
class MetricsRepository {
  final ApiClient _client;

  MetricsRepository(this._client);

  /// Get latest metrics for user
  Future<HealthMetrics?> getLatestMetrics(String userId) async {
    try {
      final response = await _client.get('${ApiConstants.metrics}/latest/$userId');
      if (response.statusCode == 200) {
        return HealthMetrics.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting latest metrics: $e');
      return null;
    }
  }

  /// Get metric history
  Future<List<MetricHistoryEntry>> getMetricHistory(
    String userId, {
    String? metricType,
    int limit = 30,
  }) async {
    try {
      final params = <String, dynamic>{'limit': limit};
      if (metricType != null) {
        params['metric_type'] = metricType;
      }

      final response = await _client.get(
        '${ApiConstants.metrics}/history/$userId',
        queryParameters: params,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        return data.map((json) => MetricHistoryEntry.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error getting metric history: $e');
      return [];
    }
  }

  /// Record a new metric
  Future<MetricHistoryEntry?> recordMetric({
    required String userId,
    required String metricType,
    required double value,
    String? unit,
    String? notes,
  }) async {
    try {
      final response = await _client.post(
        '${ApiConstants.metrics}/record',
        data: {
          'user_id': userId,
          'metric_type': metricType,
          'value': value,
          if (unit != null) 'unit': unit,
          if (notes != null) 'notes': notes,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return MetricHistoryEntry.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error recording metric: $e');
      rethrow;
    }
  }

  /// Calculate metrics
  Future<HealthMetrics?> calculateMetrics({
    required double heightCm,
    required double weightKg,
    required int age,
    required String gender,
    required String activityLevel,
    required String goal,
  }) async {
    try {
      final response = await _client.post(
        '${ApiConstants.metrics}/calculate',
        data: {
          'height_cm': heightCm,
          'weight_kg': weightKg,
          'age': age,
          'gender': gender,
          'activity_level': activityLevel,
          'goal': goal,
        },
      );

      if (response.statusCode == 200) {
        return HealthMetrics.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error calculating metrics: $e');
      return null;
    }
  }

  /// Delete a metric entry
  Future<bool> deleteMetricEntry(String userId, String metricId) async {
    try {
      final response = await _client.delete(
        '${ApiConstants.metrics}/history/$userId/$metricId',
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error deleting metric: $e');
      return false;
    }
  }
}
