import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/equipment_calibration.dart';
import '../services/api_client.dart';

/// Repository for `equipment_inventory` rows (per-user equipment calibration).
///
/// Caches rows in memory after first fetch. Mutations PATCH/POST/DELETE
/// against `/api/v1/equipment/calibration*` and update the cache locally so
/// the active-workout plate indicator picks up changes instantly.
///
/// No silent fallbacks — failed fetches surface as exceptions (per
/// `feedback_no_silent_fallbacks`). Callers can `.maybeWhen` / try/catch.
class EquipmentCalibrationRepository {
  EquipmentCalibrationRepository(this._api);

  final ApiClient _api;
  final List<EquipmentCalibration> _cache = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;
  List<EquipmentCalibration> get cached => List.unmodifiable(_cache);

  /// First call hits the network; subsequent calls return cache unless
  /// [forceRefresh] is true.
  Future<List<EquipmentCalibration>> list({bool forceRefresh = false}) async {
    if (_loaded && !forceRefresh) return cached;
    final resp = await _api.get('/equipment/calibration');
    if (resp.statusCode != 200 || resp.data == null) {
      throw Exception(
        'equipment calibration list failed (status=${resp.statusCode})',
      );
    }
    final items = (resp.data['items'] as List<dynamic>? ?? const [])
        .map((e) => EquipmentCalibration.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache
      ..clear()
      ..addAll(items);
    _loaded = true;
    return cached;
  }

  /// Find the first calibration row matching [category] (e.g. 'barbell').
  /// Returns null when no row matches — callers fall back to hardcoded
  /// defaults (NOT a silent error: absence is meaningful).
  EquipmentCalibration? findByCategory(String category) {
    for (final c in _cache) {
      if (c.category == category) return c;
    }
    return null;
  }

  /// Find a row by id.
  EquipmentCalibration? findById(String id) {
    for (final c in _cache) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<EquipmentCalibration> create({
    String? label,
    String? category,
    String? equipmentTypeId,
    double? barEmptyWeightKg,
    double? machineEmptyWeightKg,
    double? cablePinStartKg,
    double? cablePinIncrementKg,
    Map<String, int>? plateInventory,
    Map<String, int>? dumbbellInventory,
    String weightUnit = 'kg',
    int count = 1,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'weight_unit': weightUnit,
      'count': count,
    };
    if (label != null) body['label'] = label;
    if (category != null) body['category'] = category;
    if (equipmentTypeId != null) body['equipment_type_id'] = equipmentTypeId;
    if (barEmptyWeightKg != null) body['bar_empty_weight_kg'] = barEmptyWeightKg;
    if (machineEmptyWeightKg != null) body['machine_empty_weight_kg'] = machineEmptyWeightKg;
    if (cablePinStartKg != null) body['cable_pin_start_kg'] = cablePinStartKg;
    if (cablePinIncrementKg != null) body['cable_pin_increment_kg'] = cablePinIncrementKg;
    if (plateInventory != null) body['plate_inventory'] = plateInventory;
    if (dumbbellInventory != null) body['dumbbell_inventory'] = dumbbellInventory;
    if (notes != null) body['notes'] = notes;

    final resp = await _api.post('/equipment/calibration', data: body);
    if (resp.statusCode != 200 || resp.data == null) {
      throw Exception('calibration create failed (status=${resp.statusCode})');
    }
    final created = EquipmentCalibration.fromJson(
      resp.data as Map<String, dynamic>,
    );
    _cache.add(created);
    debugPrint('🏋️ [EquipmentCalibration] created id=${created.id} '
        'category=${created.category}');
    return created;
  }

  Future<EquipmentCalibration> patch(
    String id, {
    String? label,
    String? category,
    double? barEmptyWeightKg,
    double? machineEmptyWeightKg,
    double? cablePinStartKg,
    double? cablePinIncrementKg,
    Map<String, int>? plateInventory,
    Map<String, int>? dumbbellInventory,
    String? weightUnit,
    int? count,
    String? notes,
  }) async {
    final existing = findById(id);
    if (existing == null) {
      throw StateError('No cached calibration with id=$id; call list() first.');
    }
    final body = existing.toPatchJson(
      label: label,
      category: category,
      barEmptyWeightKg: barEmptyWeightKg,
      machineEmptyWeightKg: machineEmptyWeightKg,
      cablePinStartKg: cablePinStartKg,
      cablePinIncrementKg: cablePinIncrementKg,
      plateInventory: plateInventory,
      dumbbellInventory: dumbbellInventory,
      weightUnit: weightUnit,
      count: count,
      notes: notes,
    );
    if (body.isEmpty) {
      throw ArgumentError('patch called with no fields');
    }
    final resp = await _api.patch('/equipment/calibration/$id', data: body);
    if (resp.statusCode != 200 || resp.data == null) {
      throw Exception('calibration patch failed (status=${resp.statusCode})');
    }
    final updated = EquipmentCalibration.fromJson(
      resp.data as Map<String, dynamic>,
    );
    final idx = _cache.indexWhere((c) => c.id == id);
    if (idx >= 0) {
      _cache[idx] = updated;
    } else {
      _cache.add(updated);
    }
    debugPrint('🏋️ [EquipmentCalibration] patched id=$id fields=${body.keys}');
    return updated;
  }

  Future<void> delete(String id) async {
    final resp = await _api.delete('/equipment/calibration/$id');
    if (resp.statusCode != 200) {
      throw Exception('calibration delete failed (status=${resp.statusCode})');
    }
    _cache.removeWhere((c) => c.id == id);
    debugPrint('🏋️ [EquipmentCalibration] deleted id=$id');
  }

  void invalidate() {
    _cache.clear();
    _loaded = false;
  }
}

/// Riverpod provider — depends on [apiClientProvider]. Singleton per app
/// session so the cache survives screen navigation.
final equipmentCalibrationRepositoryProvider =
    Provider<EquipmentCalibrationRepository>((ref) {
  final api = ref.read(apiClientProvider);
  return EquipmentCalibrationRepository(api);
});

/// Async list provider — UI screens can `ref.watch(...)` to render.
final equipmentCalibrationListProvider =
    FutureProvider<List<EquipmentCalibration>>((ref) async {
  final repo = ref.read(equipmentCalibrationRepositoryProvider);
  return repo.list();
});

/// By-category lookup. UI components like the plate indicator watch this for
/// their specific category (e.g. 'barbell') and react to calibration changes.
final equipmentCalibrationByCategoryProvider =
    FutureProvider.family<EquipmentCalibration?, String>((ref, category) async {
  await ref.watch(equipmentCalibrationListProvider.future);
  final repo = ref.read(equipmentCalibrationRepositoryProvider);
  return repo.findByCategory(category);
});
