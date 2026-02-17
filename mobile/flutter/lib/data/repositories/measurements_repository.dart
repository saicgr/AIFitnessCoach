import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/api_constants.dart';
import '../services/api_client.dart';
import '../services/data_cache_service.dart';

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

/// Maps MeasurementType.apiValue to the Supabase body_measurements column name.
/// Mirrors METRIC_TYPE_TO_COLUMN from backend/api/v1/metrics.py:409
const Map<String, String> kMetricTypeToColumn = {
  'weight': 'weight_kg',
  'body_fat': 'body_fat_percent',
  'chest': 'chest_cm',
  'waist': 'waist_cm',
  'hips': 'hip_cm',
  'neck': 'neck_cm',
  'shoulders': 'shoulder_cm',
  'biceps_left': 'bicep_left_cm',
  'biceps_right': 'bicep_right_cm',
  'forearm_left': 'forearm_left_cm',
  'forearm_right': 'forearm_right_cm',
  'thigh_left': 'thigh_left_cm',
  'thigh_right': 'thigh_right_cm',
  'calf_left': 'calf_left_cm',
  'calf_right': 'calf_right_cm',
};

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

/// Measurements state notifier with 3-tier cache:
/// 1. In-memory static cache (0ms, survives ref.invalidate)
/// 2. SharedPreferences persistent cache (~10ms, survives app restart)
/// 3. Live Supabase query (~200-500ms, always fresh)
class MeasurementsNotifier extends StateNotifier<MeasurementsState> {
  final MeasurementsRepository _repository;

  // Static cache survives ref.invalidate() (which recreates the notifier instance)
  static MeasurementsState? _cache;

  MeasurementsNotifier(this._repository) : super(
    _cache ?? const MeasurementsState(),
  );

  /// Load all measurement history for user with 3-tier cache.
  Future<void> loadAllMeasurements(String userId) async {
    // Case 1: Instance state has data (navigate away -> come back) -> skip fetch
    if (state.historyByType.isNotEmpty) return;

    // Case 2: Static in-memory cache exists (after ref.invalidate) -> show instantly + background refresh
    if (_cache != null && _cache!.historyByType.isNotEmpty) {
      state = _cache!;
      _fetchAndUpdate(userId);
      return;
    }

    // Case 3: Try persistent cache (SharedPreferences) -> show instantly + background refresh
    final persistedState = await _loadFromPersistentCache();
    if (persistedState != null && persistedState.historyByType.isNotEmpty) {
      debugPrint('💾 [Measurements] Loaded from persistent cache');
      state = persistedState;
      _cache = persistedState;
      _fetchAndUpdate(userId);
      return;
    }

    // Case 4: First ever load -> show loading spinner -> fetch
    state = state.copyWith(isLoading: true, error: null);
    await _fetchAndUpdate(userId);
  }

  Future<void> _fetchAndUpdate(String userId) async {
    try {
      final historyByType = await _repository.getAllMeasurementsGrouped(userId);

      final latestByType = <MeasurementType, MeasurementEntry>{};
      final changeFromPrevious = <MeasurementType, double>{};
      for (final entry in historyByType.entries) {
        if (entry.value.isNotEmpty) {
          latestByType[entry.key] = entry.value.first;
          if (entry.value.length > 1) {
            changeFromPrevious[entry.key] =
                entry.value[0].value - entry.value[1].value;
          }
        }
      }

      final newState = MeasurementsState(
        historyByType: historyByType,
        summary: MeasurementsSummary(
          latestByType: latestByType,
          changeFromPrevious: changeFromPrevious,
        ),
      );
      _cache = newState;
      state = newState;
      _saveToPersistentCache(newState);
    } catch (e) {
      debugPrint('❌ Error loading measurements: $e');
      if (state.historyByType.isEmpty) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    } finally {
      if (state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// Load from SharedPreferences persistent cache
  Future<MeasurementsState?> _loadFromPersistentCache() async {
    try {
      final cached = await DataCacheService.instance.getCached(
        DataCacheService.bodyMeasurementsKey,
      );
      if (cached == null) return null;

      final historyByType = <MeasurementType, List<MeasurementEntry>>{};
      for (final key in cached.keys) {
        final type = MeasurementType.fromApiValue(key);
        if (type == null) continue;
        final entries = (cached[key] as List?)
            ?.map((e) => MeasurementEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        if (entries != null && entries.isNotEmpty) {
          historyByType[type] = entries;
        }
      }

      if (historyByType.isEmpty) return null;

      final latestByType = <MeasurementType, MeasurementEntry>{};
      final changeFromPrevious = <MeasurementType, double>{};
      for (final entry in historyByType.entries) {
        if (entry.value.isNotEmpty) {
          latestByType[entry.key] = entry.value.first;
          if (entry.value.length > 1) {
            changeFromPrevious[entry.key] =
                entry.value[0].value - entry.value[1].value;
          }
        }
      }

      return MeasurementsState(
        historyByType: historyByType,
        summary: MeasurementsSummary(
          latestByType: latestByType,
          changeFromPrevious: changeFromPrevious,
        ),
      );
    } catch (e) {
      debugPrint('⚠️ [Measurements] Persistent cache parse error: $e');
      return null;
    }
  }

  /// Save state to SharedPreferences persistent cache
  Future<void> _saveToPersistentCache(MeasurementsState state) async {
    try {
      final data = <String, dynamic>{};
      for (final entry in state.historyByType.entries) {
        data[entry.key.apiValue] = entry.value.map((e) => e.toJson()).toList();
      }
      await DataCacheService.instance.cache(
        DataCacheService.bodyMeasurementsKey,
        data,
      );
    } catch (e) {
      debugPrint('⚠️ [Measurements] Persistent cache save error: $e');
    }
  }

  /// Clear both in-memory and persistent caches (called on logout)
  static void clearCache() {
    _cache = null;
    DataCacheService.instance.invalidate(DataCacheService.bodyMeasurementsKey);
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

      final newState = state.copyWith(
        historyByType: newHistoryByType,
        summary: MeasurementsSummary(
          latestByType: latestByType,
          changeFromPrevious: changeFromPrevious,
        ),
      );
      _cache = newState;
      state = newState;
      _saveToPersistentCache(newState);
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

        final newState = state.copyWith(
          historyByType: newHistoryByType,
          summary: MeasurementsSummary(
            latestByType: latestByType,
            changeFromPrevious: changeFromPrevious,
          ),
        );
        _cache = newState;
        state = newState;
        _saveToPersistentCache(newState);
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

/// Measurements repository — reads directly from Supabase, writes through backend API
class MeasurementsRepository {
  final ApiClient _client;

  MeasurementsRepository(this._client);

  SupabaseClient get _supabase => Supabase.instance.client;

  /// Get all measurements grouped by type via direct Supabase query.
  /// RLS policy (auth.uid() = user_id) secures the query automatically.
  Future<Map<MeasurementType, List<MeasurementEntry>>> getAllMeasurementsGrouped(
    String userId, {int limit = 300}
  ) async {
    try {
      // Build select columns: id, user_id, measured_at, created_at, notes + all metric columns
      final cols = [
        'id', 'user_id', 'measured_at', 'created_at', 'notes',
        ...kMetricTypeToColumn.values,
      ].join(',');

      debugPrint('🔍 [Measurements] Direct Supabase query for $userId (limit: $limit)');

      final response = await _supabase
          .from('body_measurements')
          .select(cols)
          .eq('user_id', userId)
          .order('measured_at', ascending: false)
          .limit(limit);

      final rows = response as List<dynamic>;
      debugPrint('✅ [Measurements] Got ${rows.length} rows from Supabase');

      // Parse wide-table rows into grouped entries
      final result = <MeasurementType, List<MeasurementEntry>>{};

      for (final row in rows) {
        final rowMap = row as Map<String, dynamic>;
        final recordedAt = rowMap['measured_at'] ?? rowMap['created_at'] ?? DateTime.now().toIso8601String();
        final id = rowMap['id']?.toString() ?? '';
        final rowUserId = rowMap['user_id']?.toString() ?? '';
        final notes = rowMap['notes'] as String?;

        for (final entry in kMetricTypeToColumn.entries) {
          final metricTypeKey = entry.key;
          final column = entry.value;
          final value = rowMap[column];
          if (value == null) continue;

          final type = MeasurementType.fromApiValue(metricTypeKey);
          if (type == null) continue;

          final unit = metricTypeKey == 'weight'
              ? 'kg'
              : (metricTypeKey == 'body_fat' ? '%' : 'cm');

          final measurementEntry = MeasurementEntry(
            id: id,
            userId: rowUserId,
            type: type,
            value: (value as num).toDouble(),
            unit: unit,
            recordedAt: DateTime.parse(recordedAt),
            notes: notes,
          );

          result.putIfAbsent(type, () => []).add(measurementEntry);
        }
      }

      return result;
    } catch (e) {
      debugPrint('❌ Error getting grouped measurements (Supabase): $e');
      rethrow;
    }
  }

  /// Get measurement history for a specific type via direct Supabase query
  Future<List<MeasurementEntry>> getMeasurementHistory(
    String userId,
    MeasurementType type, {
    int limit = 50,
  }) async {
    try {
      final columnName = kMetricTypeToColumn[type.apiValue];
      if (columnName == null) return [];

      final unit = type.apiValue == 'weight'
          ? 'kg'
          : (type.apiValue == 'body_fat' ? '%' : 'cm');

      debugPrint('🔍 [Measurements] Direct Supabase query for ${type.displayName}');

      final response = await _supabase
          .from('body_measurements')
          .select('id, user_id, $columnName, measured_at, created_at, notes')
          .eq('user_id', userId)
          .not(columnName, 'is', null)
          .order('measured_at', ascending: false)
          .limit(limit);

      final rows = response as List<dynamic>;
      return rows.map((row) {
        final rowMap = row as Map<String, dynamic>;
        return MeasurementEntry(
          id: rowMap['id']?.toString() ?? '',
          userId: rowMap['user_id']?.toString() ?? '',
          type: type,
          value: (rowMap[columnName] as num).toDouble(),
          unit: unit,
          recordedAt: DateTime.parse(
            rowMap['measured_at'] ?? rowMap['created_at'] ?? DateTime.now().toIso8601String(),
          ),
          notes: rowMap['notes'] as String?,
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting ${type.displayName} history (Supabase): $e');
      return [];
    }
  }

  /// Record a new measurement (through backend API — triggers need it)
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

  /// Delete a measurement entry (through backend API)
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
