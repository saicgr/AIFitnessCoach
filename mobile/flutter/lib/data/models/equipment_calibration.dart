import 'package:flutter/foundation.dart';

/// Mirror of the backend `equipment_inventory` row (migration 2100).
///
/// Per-user equipment with calibration fields so plate math matches reality
/// — the Reddit insight that kicked off Phase 1: "I told it my EZ bar is
/// 17.5lb. Now plate suggestions actually work."
///
/// Source of truth lives in the backend table; this Dart model is a thin
/// transport object consumed by [EquipmentCalibrationRepository] and the
/// barbell-plate indicator + weight-increments provider.
@immutable
class EquipmentCalibration {
  final String id;
  final String userId;
  final String? equipmentTypeId;
  final String? label;
  final String? category; // 'barbell' | 'dumbbell' | 'cable' | 'machine' | 'plate_set' | 'kettlebell' | 'other'

  final double? barEmptyWeightKg;
  final double? machineEmptyWeightKg;
  final double? cablePinStartKg;
  final double? cablePinIncrementKg;

  /// Plate weight string -> count (e.g. {"45": 4, "25": 4, "10": 2, "5": 2}).
  /// Units per [weightUnit]. Counts are total physical plates (not pairs).
  final Map<String, int> plateInventory;

  /// Dumbbell weight string -> count.
  final Map<String, int> dumbbellInventory;

  final String weightUnit; // 'kg' | 'lb'
  final int count;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EquipmentCalibration({
    required this.id,
    required this.userId,
    this.equipmentTypeId,
    this.label,
    this.category,
    this.barEmptyWeightKg,
    this.machineEmptyWeightKg,
    this.cablePinStartKg,
    this.cablePinIncrementKg,
    this.plateInventory = const {},
    this.dumbbellInventory = const {},
    this.weightUnit = 'kg',
    this.count = 1,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convenience: bar weight in the user's preferred unit (lbs by default per
  /// `feedback_weight_units`). Returns null when no override is set.
  double? barEmptyWeightIn(String unit) {
    final kg = barEmptyWeightKg;
    if (kg == null) return null;
    return unit == 'lb' ? kg / 0.45359237 : kg;
  }

  double? machineEmptyWeightIn(String unit) {
    final kg = machineEmptyWeightKg;
    if (kg == null) return null;
    return unit == 'lb' ? kg / 0.45359237 : kg;
  }

  factory EquipmentCalibration.fromJson(Map<String, dynamic> json) {
    Map<String, int> parseInventory(dynamic raw) {
      if (raw is! Map) return const {};
      final out = <String, int>{};
      raw.forEach((k, v) {
        if (v is int) {
          out[k.toString()] = v;
        } else if (v is num) {
          out[k.toString()] = v.toInt();
        }
      });
      return out;
    }

    return EquipmentCalibration(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      equipmentTypeId: json['equipment_type_id'] as String?,
      label: json['label'] as String?,
      category: json['category'] as String?,
      barEmptyWeightKg: (json['bar_empty_weight_kg'] as num?)?.toDouble(),
      machineEmptyWeightKg: (json['machine_empty_weight_kg'] as num?)?.toDouble(),
      cablePinStartKg: (json['cable_pin_start_kg'] as num?)?.toDouble(),
      cablePinIncrementKg: (json['cable_pin_increment_kg'] as num?)?.toDouble(),
      plateInventory: parseInventory(json['plate_inventory']),
      dumbbellInventory: parseInventory(json['dumbbell_inventory']),
      weightUnit: (json['weight_unit'] as String?) ?? 'kg',
      count: (json['count'] as num?)?.toInt() ?? 1,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Partial-update payload for PATCH /api/v1/equipment/calibration/{id}.
  /// Only non-null fields are emitted (matches the backend's CalibrationUpdate
  /// PATCH semantics).
  Map<String, dynamic> toPatchJson({
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
  }) {
    final body = <String, dynamic>{};
    if (label != null) body['label'] = label;
    if (category != null) body['category'] = category;
    if (barEmptyWeightKg != null) body['bar_empty_weight_kg'] = barEmptyWeightKg;
    if (machineEmptyWeightKg != null) body['machine_empty_weight_kg'] = machineEmptyWeightKg;
    if (cablePinStartKg != null) body['cable_pin_start_kg'] = cablePinStartKg;
    if (cablePinIncrementKg != null) body['cable_pin_increment_kg'] = cablePinIncrementKg;
    if (plateInventory != null) body['plate_inventory'] = plateInventory;
    if (dumbbellInventory != null) body['dumbbell_inventory'] = dumbbellInventory;
    if (weightUnit != null) body['weight_unit'] = weightUnit;
    if (count != null) body['count'] = count;
    if (notes != null) body['notes'] = notes;
    return body;
  }

  EquipmentCalibration copyWith({
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
    DateTime? updatedAt,
  }) {
    return EquipmentCalibration(
      id: id,
      userId: userId,
      equipmentTypeId: equipmentTypeId,
      label: label ?? this.label,
      category: category ?? this.category,
      barEmptyWeightKg: barEmptyWeightKg ?? this.barEmptyWeightKg,
      machineEmptyWeightKg: machineEmptyWeightKg ?? this.machineEmptyWeightKg,
      cablePinStartKg: cablePinStartKg ?? this.cablePinStartKg,
      cablePinIncrementKg: cablePinIncrementKg ?? this.cablePinIncrementKg,
      plateInventory: plateInventory ?? this.plateInventory,
      dumbbellInventory: dumbbellInventory ?? this.dumbbellInventory,
      weightUnit: weightUnit ?? this.weightUnit,
      count: count ?? this.count,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
