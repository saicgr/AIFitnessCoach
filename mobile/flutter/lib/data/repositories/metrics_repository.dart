import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/stats/stat_trend.dart' show GoodDirection;
import '../../widgets/trends/trend_correlation.dart' show TrendPoint;
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

/// Maps a backend `good_direction` string to the shared [GoodDirection] enum
/// that drives trend coloring. Unknown / missing values fall through to
/// [GoodDirection.neutral] so an unclassified custom metric shows a factual
/// arrow with no green/red judgment (never a fabricated direction).
GoodDirection goodDirectionFromString(String? raw) {
  switch (raw?.toLowerCase().trim()) {
    case 'higher':
    case 'higher_is_better':
    case 'up':
      return GoodDirection.higher;
    case 'lower':
    case 'lower_is_better':
    case 'down':
      return GoodDirection.lower;
    default:
      return GoodDirection.neutral;
  }
}

/// Serialises a [GoodDirection] back to the backend's `good_direction` string.
String goodDirectionToString(GoodDirection d) {
  switch (d) {
    case GoodDirection.higher:
      return 'higher';
    case GoodDirection.lower:
      return 'lower';
    case GoodDirection.neutral:
      return 'neutral';
  }
}

/// A user-defined custom metric definition (e.g. "Sleep quality", "Mood").
///
/// Mirrors the backend `GET /metrics/custom` row. [goodDirection] is resolved
/// from the stored string so the dashboard can color the trend without
/// re-deriving direction per screen.
class CustomMetricDef {
  final String id;
  final String key;
  final String label;
  final String unit;
  final GoodDirection goodDirection;
  final bool isActive;

  const CustomMetricDef({
    required this.id,
    required this.key,
    required this.label,
    required this.unit,
    required this.goodDirection,
    this.isActive = true,
  });

  factory CustomMetricDef.fromJson(Map<String, dynamic> json) {
    return CustomMetricDef(
      id: json['id']?.toString() ?? '',
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      goodDirection: goodDirectionFromString(json['good_direction'] as String?),
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

/// A single logged value for a custom metric.
class CustomMetricLog {
  final double value;
  final DateTime recordedAt;
  final String? notes;

  const CustomMetricLog({
    required this.value,
    required this.recordedAt,
    this.notes,
  });

  factory CustomMetricLog.fromJson(Map<String, dynamic> json) {
    return CustomMetricLog(
      value: (json['value'] as num).toDouble(),
      recordedAt: DateTime.parse(
        (json['recorded_at'] ?? json['created_at']) as String,
      ),
      notes: json['notes'] as String?,
    );
  }

  /// A chartable [TrendPoint] for sparklines / delta math.
  TrendPoint toTrendPoint() => TrendPoint(date: recordedAt, value: value);
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

  // ── User-defined custom metrics ───────────────────────────────────────────

  /// Lists the user's custom metric definitions.
  /// `GET /metrics/custom?user_id=...`
  Future<List<CustomMetricDef>> listCustomMetrics(String userId) async {
    try {
      final response = await _client.get(
        '${ApiConstants.metrics}/custom',
        queryParameters: {'user_id': userId},
      );
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data as List;
        return data
            .map((json) =>
                CustomMetricDef.fromJson(Map<String, dynamic>.from(json as Map)))
            .toList();
      }
      return const [];
    } catch (e) {
      debugPrint('❌ Error listing custom metrics: $e');
      rethrow;
    }
  }

  /// Creates a custom metric definition.
  /// `POST /metrics/custom {user_id, label, unit?, good_direction}`
  Future<CustomMetricDef> createCustomMetric({
    required String userId,
    required String label,
    String? unit,
    GoodDirection goodDirection = GoodDirection.neutral,
  }) async {
    try {
      final response = await _client.post(
        '${ApiConstants.metrics}/custom',
        data: {
          'user_id': userId,
          'label': label,
          if (unit != null && unit.isNotEmpty) 'unit': unit,
          'good_direction': goodDirectionToString(goodDirection),
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return CustomMetricDef.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }
      throw Exception('Create custom metric failed (${response.statusCode})');
    } catch (e) {
      debugPrint('❌ Error creating custom metric: $e');
      rethrow;
    }
  }

  /// Logs a value for a custom metric.
  /// `POST /metrics/custom/{metric_id}/log {user_id, value, recorded_at?, notes?}`
  Future<CustomMetricLog> logCustomMetric({
    required String metricId,
    required String userId,
    required double value,
    DateTime? recordedAt,
    String? notes,
  }) async {
    try {
      final response = await _client.post(
        '${ApiConstants.metrics}/custom/$metricId/log',
        data: {
          'user_id': userId,
          'value': value,
          if (recordedAt != null)
            'recorded_at': recordedAt.toUtc().toIso8601String(),
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return CustomMetricLog.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }
      throw Exception('Log custom metric failed (${response.statusCode})');
    } catch (e) {
      debugPrint('❌ Error logging custom metric: $e');
      rethrow;
    }
  }

  /// Fetches a custom metric's logged history (most recent first or as the
  /// backend orders it). Returned ascending by date is not guaranteed by the
  /// API, so callers that need chart order should sort by [CustomMetricLog.recordedAt].
  /// `GET /metrics/custom/{metric_id}/history?user_id=...&days=...`
  Future<List<CustomMetricLog>> customMetricHistory({
    required String metricId,
    required String userId,
    int days = 90,
  }) async {
    try {
      final response = await _client.get(
        '${ApiConstants.metrics}/custom/$metricId/history',
        queryParameters: {'user_id': userId, 'days': days},
      );
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data as List;
        return data
            .map((json) =>
                CustomMetricLog.fromJson(Map<String, dynamic>.from(json as Map)))
            .toList();
      }
      return const [];
    } catch (e) {
      debugPrint('❌ Error getting custom metric history: $e');
      rethrow;
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
