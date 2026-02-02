import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../services/api_client.dart';

/// Measurements repository provider
final measurementsRepositoryProvider = Provider<MeasurementsRepository>((ref) {
  return MeasurementsRepository(ref.watch(apiClientProvider));
});

/// Measurement type enum for body measurements
enum MeasurementType {
  weight('weight', 'Weight', 'kg', 'lbs'),
  bodyFat('body_fat', 'Body Fat', '%', '%'),
  chest('chest', 'Chest', 'cm', 'in'),
  waist('waist', 'Waist', 'cm', 'in'),
  hips('hips', 'Hips', 'cm', 'in'),
  bicepsLeft('biceps_left', 'Biceps (L)', 'cm', 'in'),
  bicepsRight('biceps_right', 'Biceps (R)', 'cm', 'in'),
  thighLeft('thigh_left', 'Thigh (L)', 'cm', 'in'),
  thighRight('thigh_right', 'Thigh (R)', 'cm', 'in'),
  calfLeft('calf_left', 'Calf (L)', 'cm', 'in'),
  calfRight('calf_right', 'Calf (R)', 'cm', 'in'),
  neck('neck', 'Neck', 'cm', 'in'),
  shoulders('shoulders', 'Shoulders', 'cm', 'in'),
  forearmLeft('forearm_left', 'Forearm (L)', 'cm', 'in'),
  forearmRight('forearm_right', 'Forearm (R)', 'cm', 'in');

  final String apiValue;
  final String displayName;
  final String metricUnit;
  final String imperialUnit;

  const MeasurementType(this.apiValue, this.displayName, this.metricUnit, this.imperialUnit);

  static MeasurementType? fromApiValue(String value) {
    for (final type in MeasurementType.values) {
      if (type.apiValue == value) return type;
    }
    return null;
  }
}

/// Single measurement entry model
class MeasurementEntry {
  final String id;
  final String userId;
  final MeasurementType type;
  final double value;
  final String unit;
  final DateTime recordedAt;
  final String? notes;

  MeasurementEntry({
    required this.id,
    required this.userId,
    required this.type,
    required this.value,
    required this.unit,
    required this.recordedAt,
    this.notes,
  });

  factory MeasurementEntry.fromJson(Map<String, dynamic> json) {
    final typeStr = json['metric_type'] ?? json['measurement_type'] ?? '';
    final type = MeasurementType.fromApiValue(typeStr) ?? MeasurementType.weight;

    return MeasurementEntry(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      type: type,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] ?? type.metricUnit,
      recordedAt: DateTime.parse(json['recorded_at'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'metric_type': type.apiValue,
    'value': value,
    'unit': unit,
    'recorded_at': recordedAt.toIso8601String(),
    if (notes != null) 'notes': notes,
  };

  /// Get value converted to the specified unit system
  double getValueInUnit(bool isMetric) {
    if (type == MeasurementType.bodyFat) return value; // % doesn't convert

    if (isMetric) {
      // If stored in imperial, convert to metric
      if (unit == 'in') return value * 2.54;
      if (unit == 'lbs') return value / 2.20462;
      return value;
    } else {
      // If stored in metric, convert to imperial
      if (unit == 'cm') return value / 2.54;
      if (unit == 'kg') return value * 2.20462;
      return value;
    }
  }
}

/// Latest measurements summary
class MeasurementsSummary {
  final Map<MeasurementType, MeasurementEntry> latestByType;
  final Map<MeasurementType, double> changeFromPrevious;

  MeasurementsSummary({
    required this.latestByType,
    required this.changeFromPrevious,
  });
}

/// Measurements state
class MeasurementsState {
  final bool isLoading;
  final String? error;
  final Map<MeasurementType, List<MeasurementEntry>> historyByType;
  final MeasurementsSummary? summary;

  const MeasurementsState({
    this.isLoading = false,
    this.error,
    this.historyByType = const {},
    this.summary,
  });

  MeasurementsState copyWith({
    bool? isLoading,
    String? error,
    Map<MeasurementType, List<MeasurementEntry>>? historyByType,
    MeasurementsSummary? summary,
  }) {
    return MeasurementsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      historyByType: historyByType ?? this.historyByType,
      summary: summary ?? this.summary,
    );
  }
}

/// Measurements state provider
final measurementsProvider =
    StateNotifierProvider<MeasurementsNotifier, MeasurementsState>((ref) {
  return MeasurementsNotifier(ref.watch(measurementsRepositoryProvider));
});

/// Measurements state notifier
class MeasurementsNotifier extends StateNotifier<MeasurementsState> {
  final MeasurementsRepository _repository;

  MeasurementsNotifier(this._repository) : super(const MeasurementsState());

  /// Load all measurement history for user
  Future<void> loadAllMeasurements(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final historyByType = <MeasurementType, List<MeasurementEntry>>{};
      final latestByType = <MeasurementType, MeasurementEntry>{};
      final changeFromPrevious = <MeasurementType, double>{};

      // Load history for all measurement types in PARALLEL for faster loading
      // But with a timeout to prevent infinite loading
      final allTypes = MeasurementType.values;
      final futures = allTypes.map((type) =>
        _repository.getMeasurementHistory(userId, type)
      ).toList();

      // Set a 20-second overall timeout to prevent infinite loading
      final allHistories = await Future.wait(futures)
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              debugPrint('⚠️ Timeout loading all measurements, returning partial data');
              // Return empty lists for all types on timeout
              return List.generate(allTypes.length, (_) => <MeasurementEntry>[]);
            },
          );

      // Process results
      for (var i = 0; i < allTypes.length; i++) {
        final type = allTypes[i];
        final history = allHistories[i];
        if (history.isNotEmpty) {
          historyByType[type] = history;
          latestByType[type] = history.first;

          // Calculate change from previous
          if (history.length > 1) {
            changeFromPrevious[type] = history[0].value - history[1].value;
          }
        }
      }

      final summary = MeasurementsSummary(
        latestByType: latestByType,
        changeFromPrevious: changeFromPrevious,
      );

      state = state.copyWith(
        isLoading: false,
        historyByType: historyByType,
        summary: summary,
      );
    } catch (e) {
      debugPrint('❌ Error loading measurements: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load history for a specific measurement type
  Future<void> loadMeasurementHistory(String userId, MeasurementType type) async {
    try {
      final history = await _repository.getMeasurementHistory(userId, type);
      final newHistoryByType = Map<MeasurementType, List<MeasurementEntry>>.from(state.historyByType);
      newHistoryByType[type] = history;

      // Update summary
      final latestByType = Map<MeasurementType, MeasurementEntry>.from(
        state.summary?.latestByType ?? {},
      );
      final changeFromPrevious = Map<MeasurementType, double>.from(
        state.summary?.changeFromPrevious ?? {},
      );

      if (history.isNotEmpty) {
        latestByType[type] = history.first;
        if (history.length > 1) {
          changeFromPrevious[type] = history[0].value - history[1].value;
        }
      }

      state = state.copyWith(
        historyByType: newHistoryByType,
        summary: MeasurementsSummary(
          latestByType: latestByType,
          changeFromPrevious: changeFromPrevious,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error loading measurement history: $e');
    }
  }

  /// Record a new measurement
  Future<bool> recordMeasurement({
    required String userId,
    required MeasurementType type,
    required double value,
    required String unit,
    String? notes,
  }) async {
    try {
      final entry = await _repository.recordMeasurement(
        userId: userId,
        type: type,
        value: value,
        unit: unit,
        notes: notes,
      );

      if (entry != null) {
        // Add to history
        final newHistoryByType = Map<MeasurementType, List<MeasurementEntry>>.from(state.historyByType);
        final currentHistory = newHistoryByType[type] ?? [];
        newHistoryByType[type] = [entry, ...currentHistory];

        // Update summary
        final latestByType = Map<MeasurementType, MeasurementEntry>.from(
          state.summary?.latestByType ?? {},
        );
        final changeFromPrevious = Map<MeasurementType, double>.from(
          state.summary?.changeFromPrevious ?? {},
        );

        final previousValue = latestByType[type]?.value;
        latestByType[type] = entry;
        if (previousValue != null) {
          changeFromPrevious[type] = entry.value - previousValue;
        }

        state = state.copyWith(
          historyByType: newHistoryByType,
          summary: MeasurementsSummary(
            latestByType: latestByType,
            changeFromPrevious: changeFromPrevious,
          ),
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error recording measurement: $e');
      return false;
    }
  }

  /// Delete a measurement entry
  Future<bool> deleteMeasurement(String userId, String measurementId, MeasurementType type) async {
    try {
      final success = await _repository.deleteMeasurement(userId, measurementId);
      if (success) {
        // Reload history for this type
        await loadMeasurementHistory(userId, type);
      }
      return success;
    } catch (e) {
      debugPrint('❌ Error deleting measurement: $e');
      return false;
    }
  }
}

/// Measurements repository
class MeasurementsRepository {
  final ApiClient _client;

  MeasurementsRepository(this._client);

  /// Get measurement history for a specific type
  Future<List<MeasurementEntry>> getMeasurementHistory(
    String userId,
    MeasurementType type, {
    int limit = 50,
  }) async {
    try {
      // Add an 8-second timeout per request (since we make 15 parallel calls)
      final response = await _client.get(
        '${ApiConstants.metrics}/body/history/$userId',
        queryParameters: {
          'metric_type': type.apiValue,
          'limit': limit,
        },
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          debugPrint('⚠️ Timeout getting ${type.displayName} history');
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        return data.map((json) => MeasurementEntry.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error getting ${type.displayName} history: $e');
      return [];
    }
  }

  /// Record a new measurement
  Future<MeasurementEntry?> recordMeasurement({
    required String userId,
    required MeasurementType type,
    required double value,
    required String unit,
    String? notes,
  }) async {
    try {
      final response = await _client.post(
        '${ApiConstants.metrics}/body/record',
        data: {
          'user_id': userId,
          'metric_type': type.apiValue,
          'value': value,
          'unit': unit,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return MeasurementEntry.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error recording measurement: $e');
      rethrow;
    }
  }

  /// Delete a measurement entry
  Future<bool> deleteMeasurement(String userId, String measurementId) async {
    try {
      final response = await _client.delete(
        '${ApiConstants.metrics}/body/history/$userId/$measurementId',
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error deleting measurement: $e');
      return false;
    }
  }
}
