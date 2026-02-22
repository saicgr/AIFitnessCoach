/// Unified equipment information consumed by the workout engine.
///
/// Wraps flat equipment names (backward-compat) with optional detailed
/// inventory data for weight snapping and bilateral availability checks.
class EquipmentContext {
  /// Flat equipment names for backward-compatible exercise filtering.
  final List<String> equipmentNames;

  /// Detailed per-type inventory, keyed by normalized type
  /// ('dumbbell', 'barbell', 'kettlebell', etc.).
  final Map<String, EquipmentInventory> inventory;

  /// When false, behave exactly like the old path (no snapping).
  final bool hasDetailedInventory;

  const EquipmentContext({
    required this.equipmentNames,
    this.inventory = const {},
    this.hasDetailedInventory = false,
  });

  /// Snap a target weight to the nearest available weight for [equipmentType].
  WeightSnapResult snapWeight(double targetWeight, String equipmentType) {
    final inv = inventory[equipmentType];
    if (inv == null || !hasDetailedInventory) {
      return WeightSnapResult(
        snappedWeight: targetWeight,
        targetWeight: targetWeight,
        ratio: 1.0,
        wasSnapped: false,
      );
    }
    return inv.snap(targetWeight);
  }

  /// Get inventory for a specific equipment type (normalized key).
  EquipmentInventory? getInventory(String equipmentType) {
    return inventory[equipmentType];
  }
}

/// Weight details for one equipment type.
class EquipmentInventory {
  /// Sorted ascending list of available weights.
  final List<double> sortedWeights;

  /// Map of weight -> quantity owned.
  final Map<double, int> weightToQuantity;

  /// Whether this equipment is typically used in pairs (dumbbells, kettlebells).
  final bool isPairType;

  /// Whether the equipment is adjustable (e.g., adjustable dumbbells 5-50kg).
  final bool isAdjustable;

  /// Minimum available weight.
  final double? minWeight;

  /// Maximum available weight.
  final double? maxWeight;

  /// Weight unit ('kg' or 'lbs').
  final String weightUnit;

  const EquipmentInventory({
    required this.sortedWeights,
    this.weightToQuantity = const {},
    this.isPairType = false,
    this.isAdjustable = false,
    this.minWeight,
    this.maxWeight,
    this.weightUnit = 'kg',
  });

  /// Check if the user can do a bilateral exercise at [weight].
  ///
  /// For pair types (dumbbells, kettlebells), needs quantity >= 2.
  /// For non-pair types (barbell), always true if weight is available.
  bool canDoBilateral(double weight) {
    if (!isPairType) return true;
    return (weightToQuantity[weight] ?? 0) >= 2;
  }

  /// Snap down: nearest weight <= [target]. Returns null if none available.
  double? snapDown(double target) {
    if (sortedWeights.isEmpty) return null;
    // Binary search for largest weight <= target
    int lo = 0;
    int hi = sortedWeights.length - 1;
    double? result;
    while (lo <= hi) {
      final mid = (lo + hi) ~/ 2;
      if (sortedWeights[mid] <= target) {
        result = sortedWeights[mid];
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return result;
  }

  /// Snap up: nearest weight >= [target]. Returns null if none available.
  double? snapUp(double target) {
    if (sortedWeights.isEmpty) return null;
    int lo = 0;
    int hi = sortedWeights.length - 1;
    double? result;
    while (lo <= hi) {
      final mid = (lo + hi) ~/ 2;
      if (sortedWeights[mid] >= target) {
        result = sortedWeights[mid];
        hi = mid - 1;
      } else {
        lo = mid + 1;
      }
    }
    return result;
  }

  /// Snap target weight to nearest available, preferring snap-down.
  WeightSnapResult snap(double target) {
    if (sortedWeights.isEmpty) {
      return WeightSnapResult(
        snappedWeight: null,
        targetWeight: target,
        ratio: 1.0,
        wasSnapped: false,
      );
    }

    // For adjustable equipment, clamp to range
    if (isAdjustable && minWeight != null && maxWeight != null) {
      final clamped = target.clamp(minWeight!, maxWeight!);
      return WeightSnapResult(
        snappedWeight: clamped,
        targetWeight: target,
        ratio: clamped > 0 ? target / clamped : 1.0,
        wasSnapped: (clamped - target).abs() > 0.01,
        exceedsMax: target > maxWeight!,
        belowMin: target < minWeight!,
      );
    }

    final down = snapDown(target);
    final up = snapUp(target);

    // Smart snap: prefer snap-down, but snap UP if within 10% of target
    double? snapped;
    if (down != null && up != null) {
      // If snap-up is within 10% of target, prefer it (closer to prescribed stimulus)
      final upDelta = (up - target).abs();
      if (upDelta / target <= 0.10) {
        snapped = up;
      } else {
        snapped = down;
      }
    } else if (down != null) {
      snapped = down;
    } else if (up != null) {
      snapped = up;
    }

    if (snapped == null) {
      return WeightSnapResult(
        snappedWeight: null,
        targetWeight: target,
        ratio: 1.0,
        wasSnapped: false,
      );
    }

    final ratio = snapped > 0 ? target / snapped : 1.0;
    final exceedsMax = maxWeight != null && target > maxWeight!;
    final belowMin = minWeight != null && target < minWeight!;

    // Check if this weight requires unilateral (only 1 available for pair type)
    final requiresUnilateral =
        isPairType && (weightToQuantity[snapped] ?? 0) < 2;

    String? note;
    if ((snapped - target).abs() > 0.01) {
      final snapDir = snapped < target ? 'down' : 'up';
      note =
          'Using ${snapped.toStringAsFixed(1)}$weightUnit (snapped $snapDir from ${target.toStringAsFixed(1)}$weightUnit)';
    }

    return WeightSnapResult(
      snappedWeight: snapped,
      targetWeight: target,
      ratio: ratio,
      wasSnapped: (snapped - target).abs() > 0.01,
      exceedsMax: exceedsMax,
      belowMin: belowMin,
      requiresUnilateral: requiresUnilateral,
      adjustmentNote: note,
    );
  }

  /// Get a conservative starting weight from inventory.
  ///
  /// [percentile] 0.0-1.0 — e.g., 0.40 for compounds, 0.25 for isolation.
  double? getPercentileWeight(double percentile) {
    if (sortedWeights.isEmpty) return null;
    final idx =
        (sortedWeights.length * percentile).floor().clamp(0, sortedWeights.length - 1);
    return sortedWeights[idx];
  }
}

/// Result of snapping a target weight to available inventory.
class WeightSnapResult {
  /// The weight snapped to (null if no weights available).
  final double? snappedWeight;

  /// The originally calculated target weight.
  final double targetWeight;

  /// Ratio of target / snapped (>1 means snapped down, <1 means snapped up).
  final double ratio;

  /// Whether any snapping occurred.
  final bool wasSnapped;

  /// Whether the target exceeded the max available weight.
  final bool exceedsMax;

  /// Whether the target was below the min available weight.
  final bool belowMin;

  /// Whether this weight only has quantity 1 for a pair-type equipment.
  final bool requiresUnilateral;

  /// Human-readable note about the adjustment.
  final String? adjustmentNote;

  const WeightSnapResult({
    required this.snappedWeight,
    required this.targetWeight,
    required this.ratio,
    required this.wasSnapped,
    this.exceedsMax = false,
    this.belowMin = false,
    this.requiresUnilateral = false,
    this.adjustmentNote,
  });
}
