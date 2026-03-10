import 'dart:ui' show Color;

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
  final double? bmi;
  final double? waistToHipRatio;
  final double? waistToHeightRatio;
  final double? weightChange;
  final double? bodyFatChange;

  MeasurementEntry({
    required this.id,
    required this.userId,
    required this.type,
    required this.value,
    required this.unit,
    required this.recordedAt,
    this.notes,
    this.bmi,
    this.waistToHipRatio,
    this.waistToHeightRatio,
    this.weightChange,
    this.bodyFatChange,
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
      bmi: (json['bmi'] as num?)?.toDouble(),
      waistToHipRatio: (json['waist_to_hip_ratio'] as num?)?.toDouble(),
      waistToHeightRatio: (json['waist_to_height_ratio'] as num?)?.toDouble(),
      weightChange: (json['weight_change_kg'] as num?)?.toDouble(),
      bodyFatChange: (json['body_fat_change'] as num?)?.toDouble(),
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
    if (bmi != null) 'bmi': bmi,
    if (waistToHipRatio != null) 'waist_to_hip_ratio': waistToHipRatio,
    if (waistToHeightRatio != null) 'waist_to_height_ratio': waistToHeightRatio,
    if (weightChange != null) 'weight_change_kg': weightChange,
    if (bodyFatChange != null) 'body_fat_change': bodyFatChange,
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
  final double? latestBmi;
  final double? latestWaistToHipRatio;
  final double? latestWaistToHeightRatio;

  MeasurementsSummary({
    required this.latestByType,
    required this.changeFromPrevious,
    this.latestBmi,
    this.latestWaistToHipRatio,
    this.latestWaistToHeightRatio,
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
    // Case 1: Instance state has data (navigate away -> come back)
    // Show existing data instantly but always do a background refresh
    if (state.historyByType.isNotEmpty) {
      _fetchAndUpdate(userId);
      return;
    }

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

  /// Force a fresh fetch from Supabase, bypassing all caches.
  Future<void> forceRefresh(String userId) async {
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

      double? latestBmi;
      double? latestWhr;
      double? latestWhtr;
      for (final entries in historyByType.values) {
        for (final e in entries) {
          if (latestBmi == null && e.bmi != null) latestBmi = e.bmi;
          if (latestWhr == null && e.waistToHipRatio != null) latestWhr = e.waistToHipRatio;
          if (latestWhtr == null && e.waistToHeightRatio != null) latestWhtr = e.waistToHeightRatio;
          if (latestBmi != null && latestWhr != null && latestWhtr != null) break;
        }
        if (latestBmi != null && latestWhr != null && latestWhtr != null) break;
      }

      final newState = MeasurementsState(
        historyByType: historyByType,
        summary: MeasurementsSummary(
          latestByType: latestByType,
          changeFromPrevious: changeFromPrevious,
          latestBmi: latestBmi,
          latestWaistToHipRatio: latestWhr,
          latestWaistToHeightRatio: latestWhtr,
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

      double? latestBmi;
      double? latestWhr;
      double? latestWhtr;
      for (final entries in historyByType.values) {
        for (final e in entries) {
          if (latestBmi == null && e.bmi != null) latestBmi = e.bmi;
          if (latestWhr == null && e.waistToHipRatio != null) latestWhr = e.waistToHipRatio;
          if (latestWhtr == null && e.waistToHeightRatio != null) latestWhtr = e.waistToHeightRatio;
          if (latestBmi != null && latestWhr != null && latestWhtr != null) break;
        }
        if (latestBmi != null && latestWhr != null && latestWhtr != null) break;
      }

      return MeasurementsState(
        historyByType: historyByType,
        summary: MeasurementsSummary(
          latestByType: latestByType,
          changeFromPrevious: changeFromPrevious,
          latestBmi: latestBmi,
          latestWaistToHipRatio: latestWhr,
          latestWaistToHeightRatio: latestWhtr,
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
          latestBmi: state.summary?.latestBmi,
          latestWaistToHipRatio: state.summary?.latestWaistToHipRatio,
          latestWaistToHeightRatio: state.summary?.latestWaistToHeightRatio,
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
            latestBmi: state.summary?.latestBmi,
            latestWaistToHipRatio: state.summary?.latestWaistToHipRatio,
            latestWaistToHeightRatio: state.summary?.latestWaistToHeightRatio,
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
      // Build select columns: id, user_id, measured_at, created_at, notes + all metric columns + derived columns
      final cols = [
        'id', 'user_id', 'measured_at', 'created_at', 'notes',
        ...kMetricTypeToColumn.values,
        'bmi', 'waist_to_hip_ratio', 'waist_to_height_ratio', 'weight_change_kg', 'body_fat_change',
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
        final rowBmi = (rowMap['bmi'] as num?)?.toDouble();
        final rowWhr = (rowMap['waist_to_hip_ratio'] as num?)?.toDouble();
        final rowWhtr = (rowMap['waist_to_height_ratio'] as num?)?.toDouble();
        final rowWeightChange = (rowMap['weight_change_kg'] as num?)?.toDouble();
        final rowBodyFatChange = (rowMap['body_fat_change'] as num?)?.toDouble();

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
            bmi: rowBmi,
            waistToHipRatio: rowWhr,
            waistToHeightRatio: rowWhtr,
            weightChange: rowWeightChange,
            bodyFatChange: rowBodyFatChange,
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

/// Enum for derived metric types (display-only, computed client-side)
enum DerivedMetricType {
  bmi('BMI', ''),
  waistToHipRatio('Waist-to-Hip Ratio', ''),
  waistToHeightRatio('Waist-to-Height Ratio', ''),
  ffmi('FFMI', ''),
  leanBodyMass('Lean Body Mass', 'kg'),
  shoulderToWaistRatio('Shoulder-to-Waist', ''),
  chestToWaistRatio('Chest-to-Waist', ''),
  armSymmetry('Arm Symmetry', '%'),
  legSymmetry('Leg Symmetry', '%');

  final String displayName;
  final String unit;
  const DerivedMetricType(this.displayName, this.unit);
}

/// Computed derived metric result
class DerivedMetricResult {
  final double value;
  final String label;
  final Color color;
  final String? info;

  const DerivedMetricResult({
    required this.value,
    required this.label,
    required this.color,
    this.info,
  });
}

/// Compute derived body metrics from latest measurements.
/// Returns only metrics that have sufficient input data.
Map<DerivedMetricType, DerivedMetricResult> computeDerivedMetrics({
  required MeasurementsSummary summary,
  required double? heightCm,
  String? gender, // 'male', 'female'
}) {
  final results = <DerivedMetricType, DerivedMetricResult>{};
  final g = gender?.toLowerCase() ?? 'male';

  final weightEntry = summary.latestByType[MeasurementType.weight];
  final bodyFatEntry = summary.latestByType[MeasurementType.bodyFat];
  final waistEntry = summary.latestByType[MeasurementType.waist];
  final hipEntry = summary.latestByType[MeasurementType.hips];
  final shoulderEntry = summary.latestByType[MeasurementType.shoulders];
  final chestEntry = summary.latestByType[MeasurementType.chest];
  final bicepsL = summary.latestByType[MeasurementType.bicepsLeft];
  final bicepsR = summary.latestByType[MeasurementType.bicepsRight];
  final thighL = summary.latestByType[MeasurementType.thighLeft];
  final thighR = summary.latestByType[MeasurementType.thighRight];

  // BMI - from DB or computed
  if (summary.latestBmi != null) {
    final bmi = summary.latestBmi!;
    String label;
    Color color;
    if (bmi < 18.5) {
      label = 'Underweight'; color = const Color(0xFF3B82F6);
    } else if (bmi < 25) {
      label = 'Normal'; color = const Color(0xFF22C55E);
    } else if (bmi < 30) {
      label = 'Overweight'; color = const Color(0xFFF59E0B);
    } else {
      label = 'Obese'; color = const Color(0xFFEF4444);
    }
    results[DerivedMetricType.bmi] = DerivedMetricResult(
      value: bmi, label: label, color: color,
      info: 'Body Mass Index measures body fat based on weight and height. Formula: weight(kg) / height(m)\u00B2. Categories: Underweight <18.5, Normal 18.5-24.9, Overweight 25-29.9, Obese 30+. Note: BMI doesn\'t distinguish muscle from fat. Source: WHO.',
    );
  } else if (weightEntry != null && heightCm != null && heightCm > 0) {
    final heightM = heightCm / 100;
    final bmi = weightEntry.value / (heightM * heightM);
    String label;
    Color color;
    if (bmi < 18.5) {
      label = 'Underweight'; color = const Color(0xFF3B82F6);
    } else if (bmi < 25) {
      label = 'Normal'; color = const Color(0xFF22C55E);
    } else if (bmi < 30) {
      label = 'Overweight'; color = const Color(0xFFF59E0B);
    } else {
      label = 'Obese'; color = const Color(0xFFEF4444);
    }
    results[DerivedMetricType.bmi] = DerivedMetricResult(
      value: bmi, label: label, color: color,
      info: 'Body Mass Index measures body fat based on weight and height. Formula: weight(kg) / height(m)\u00B2. Categories: Underweight <18.5, Normal 18.5-24.9, Overweight 25-29.9, Obese 30+. Note: BMI doesn\'t distinguish muscle from fat. Source: WHO.',
    );
  }

  // WHR - Waist-to-Hip Ratio
  if (summary.latestWaistToHipRatio != null) {
    final whr = summary.latestWaistToHipRatio!;
    String label; Color color;
    if (g == 'female') {
      if (whr < 0.80) { label = 'Low Risk'; color = const Color(0xFF22C55E); }
      else if (whr < 0.85) { label = 'Moderate'; color = const Color(0xFFF59E0B); }
      else { label = 'High Risk'; color = const Color(0xFFEF4444); }
    } else {
      if (whr < 0.90) { label = 'Low Risk'; color = const Color(0xFF22C55E); }
      else if (whr < 0.95) { label = 'Moderate'; color = const Color(0xFFF59E0B); }
      else { label = 'High Risk'; color = const Color(0xFFEF4444); }
    }
    results[DerivedMetricType.waistToHipRatio] = DerivedMetricResult(
      value: whr, label: label, color: color,
      info: 'Waist-to-Hip Ratio is the circumference of the waist divided by the circumference of the hips. It indicates fat distribution. ${g == "female" ? "Women: <0.80 low risk, 0.80-0.85 moderate, >0.85 high." : "Men: <0.90 low risk, 0.90-0.95 moderate, >0.95 high."} Source: WHO.',
    );
  } else if (waistEntry != null && hipEntry != null && hipEntry.value > 0) {
    final whr = waistEntry.value / hipEntry.value;
    String label; Color color;
    if (g == 'female') {
      if (whr < 0.80) { label = 'Low Risk'; color = const Color(0xFF22C55E); }
      else if (whr < 0.85) { label = 'Moderate'; color = const Color(0xFFF59E0B); }
      else { label = 'High Risk'; color = const Color(0xFFEF4444); }
    } else {
      if (whr < 0.90) { label = 'Low Risk'; color = const Color(0xFF22C55E); }
      else if (whr < 0.95) { label = 'Moderate'; color = const Color(0xFFF59E0B); }
      else { label = 'High Risk'; color = const Color(0xFFEF4444); }
    }
    results[DerivedMetricType.waistToHipRatio] = DerivedMetricResult(
      value: whr, label: label, color: color,
      info: 'Waist-to-Hip Ratio is the circumference of the waist divided by the circumference of the hips. It indicates fat distribution. ${g == "female" ? "Women: <0.80 low risk, 0.80-0.85 moderate, >0.85 high." : "Men: <0.90 low risk, 0.90-0.95 moderate, >0.95 high."} Source: WHO.',
    );
  }

  // WHtR - Waist-to-Height Ratio
  if (summary.latestWaistToHeightRatio != null) {
    final whtr = summary.latestWaistToHeightRatio!;
    String label; Color color;
    if (whtr < 0.5) { label = 'Healthy'; color = const Color(0xFF22C55E); }
    else if (whtr < 0.6) { label = 'At Risk'; color = const Color(0xFFF59E0B); }
    else { label = 'High Risk'; color = const Color(0xFFEF4444); }
    results[DerivedMetricType.waistToHeightRatio] = DerivedMetricResult(
      value: whtr, label: label, color: color,
      info: 'Waist-to-Height Ratio: waist circumference divided by height. A ratio below 0.5 is considered healthy regardless of gender. Simple and effective predictor of cardiovascular risk. Source: British Medical Journal.',
    );
  } else if (waistEntry != null && heightCm != null && heightCm > 0) {
    final whtr = waistEntry.value / heightCm;
    String label; Color color;
    if (whtr < 0.5) { label = 'Healthy'; color = const Color(0xFF22C55E); }
    else if (whtr < 0.6) { label = 'At Risk'; color = const Color(0xFFF59E0B); }
    else { label = 'High Risk'; color = const Color(0xFFEF4444); }
    results[DerivedMetricType.waistToHeightRatio] = DerivedMetricResult(
      value: whtr, label: label, color: color,
      info: 'Waist-to-Height Ratio: waist circumference divided by height. A ratio below 0.5 is considered healthy regardless of gender. Simple and effective predictor of cardiovascular risk. Source: British Medical Journal.',
    );
  }

  // FFMI - Fat-Free Mass Index
  if (weightEntry != null && bodyFatEntry != null && heightCm != null && heightCm > 0) {
    final weightKg = weightEntry.value;
    final bf = bodyFatEntry.value;
    final heightM = heightCm / 100;
    final leanMass = weightKg * (1 - bf / 100);
    final ffmi = leanMass / (heightM * heightM) + 6.1 * (1.8 - heightM);
    String label; Color color;
    if (ffmi < 18) { label = 'Below Average'; color = const Color(0xFF3B82F6); }
    else if (ffmi < 20) { label = 'Average'; color = const Color(0xFF22C55E); }
    else if (ffmi < 22) { label = 'Above Average'; color = const Color(0xFF06B6D4); }
    else if (ffmi < 23) { label = 'Excellent'; color = const Color(0xFF8B5CF6); }
    else if (ffmi < 25) { label = 'Near Limit'; color = const Color(0xFFF59E0B); }
    else { label = 'Exceptional'; color = const Color(0xFFEF4444); }
    results[DerivedMetricType.ffmi] = DerivedMetricResult(
      value: ffmi, label: label, color: color,
      info: 'Fat-Free Mass Index measures lean body mass relative to height. Formula: lean_mass / height\u00B2 + 6.1 \u00D7 (1.8 - height). Normal 18-20, Above Avg 20-22, Excellent 22-23, Near Natural Limit 23-25. Values above 25 are rare without enhancement. Source: Kouri et al.',
    );
  }

  // Lean Body Mass
  if (weightEntry != null && bodyFatEntry != null) {
    final lbm = weightEntry.value * (1 - bodyFatEntry.value / 100);
    results[DerivedMetricType.leanBodyMass] = DerivedMetricResult(
      value: lbm, label: '', color: const Color(0xFF22C55E),
      info: 'Lean Body Mass is your total weight minus fat mass. Formula: weight \u00D7 (1 - body_fat% / 100). Useful for tracking muscle gain during a cut or recomp.',
    );
  }

  // Shoulder-to-Waist Ratio
  if (shoulderEntry != null && waistEntry != null && waistEntry.value > 0) {
    final swr = shoulderEntry.value / waistEntry.value;
    String label; Color color;
    if (swr < 1.3) { label = 'Narrow'; color = const Color(0xFF3B82F6); }
    else if (swr < 1.5) { label = 'Good'; color = const Color(0xFFF59E0B); }
    else if (swr < 1.618) { label = 'Great'; color = const Color(0xFF22C55E); }
    else { label = 'Golden Ratio'; color = const Color(0xFFEAB308); }
    results[DerivedMetricType.shoulderToWaistRatio] = DerivedMetricResult(
      value: swr, label: label, color: color,
      info: 'Shoulder-to-Waist Ratio indicates the V-taper physique. Formula: shoulder / waist circumference. The "golden ratio" of 1.618 is considered the aesthetic ideal. <1.3 narrow, 1.3-1.5 good, 1.5-1.618 great, \u22651.618 golden ratio.',
    );
  }

  // Chest-to-Waist Ratio
  if (chestEntry != null && waistEntry != null && waistEntry.value > 0) {
    final cwr = chestEntry.value / waistEntry.value;
    String label; Color color;
    if (cwr < 1.1) { label = 'Below Average'; color = const Color(0xFF3B82F6); }
    else if (cwr < 1.2) { label = 'Average'; color = const Color(0xFFF59E0B); }
    else if (cwr < 1.3) { label = 'Good'; color = const Color(0xFF22C55E); }
    else { label = 'Excellent'; color = const Color(0xFF8B5CF6); }
    results[DerivedMetricType.chestToWaistRatio] = DerivedMetricResult(
      value: cwr, label: label, color: color,
      info: 'Chest-to-Waist Ratio indicates upper body development. Formula: chest / waist circumference. A higher ratio indicates a more developed chest relative to waist. <1.1 below avg, 1.1-1.2 average, 1.2-1.3 good, >1.3 excellent.',
    );
  }

  // Arm Symmetry
  if (bicepsL != null && bicepsR != null) {
    final maxVal = bicepsL.value > bicepsR.value ? bicepsL.value : bicepsR.value;
    if (maxVal > 0) {
      final diff = (bicepsL.value - bicepsR.value).abs();
      final symmetry = diff / maxVal * 100;
      String label; Color color;
      if (symmetry < 5) { label = 'Balanced'; color = const Color(0xFF22C55E); }
      else if (symmetry < 10) { label = 'Minor Imbalance'; color = const Color(0xFFF59E0B); }
      else { label = 'Significant'; color = const Color(0xFFEF4444); }
      results[DerivedMetricType.armSymmetry] = DerivedMetricResult(
        value: symmetry, label: label, color: color,
        info: 'Arm Symmetry measures the difference between left and right biceps. Formula: |left - right| / max \u00D7 100. <5% balanced, 5-10% minor imbalance, >10% significant imbalance. Consider unilateral exercises to correct.',
      );
    }
  }

  // Leg Symmetry
  if (thighL != null && thighR != null) {
    final maxVal = thighL.value > thighR.value ? thighL.value : thighR.value;
    if (maxVal > 0) {
      final diff = (thighL.value - thighR.value).abs();
      final symmetry = diff / maxVal * 100;
      String label; Color color;
      if (symmetry < 5) { label = 'Balanced'; color = const Color(0xFF22C55E); }
      else if (symmetry < 10) { label = 'Minor Imbalance'; color = const Color(0xFFF59E0B); }
      else { label = 'Significant'; color = const Color(0xFFEF4444); }
      results[DerivedMetricType.legSymmetry] = DerivedMetricResult(
        value: symmetry, label: label, color: color,
        info: 'Leg Symmetry measures the difference between left and right thighs. Formula: |left - right| / max \u00D7 100. <5% balanced, 5-10% minor imbalance, >10% significant imbalance. Consider unilateral exercises to correct.',
      );
    }
  }

  return results;
}
