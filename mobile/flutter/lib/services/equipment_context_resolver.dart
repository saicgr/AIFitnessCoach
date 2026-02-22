import '../models/equipment_item.dart';
import 'equipment_context.dart';

/// Builds [EquipmentContext] from various input sources.
///
/// Handles backward-compatible flat string lists as well as rich
/// [EquipmentItem] data with weight inventories and quantities.
class EquipmentContextResolver {
  EquipmentContextResolver._();

  // =========================================================================
  // Name normalization
  // =========================================================================

  /// Maps display names to normalized equipment type keys.
  static const Map<String, String> _nameNormalization = {
    'dumbbells': 'dumbbell',
    'dumbbell': 'dumbbell',
    'barbell': 'barbell',
    'kettlebell': 'kettlebell',
    'kettlebells': 'kettlebell',
    'pull-up bar': 'pull_up_bar',
    'pull up bar': 'pull_up_bar',
    'pullup bar': 'pull_up_bar',
    'resistance bands': 'resistance_bands',
    'resistance band': 'resistance_bands',
    'bands': 'resistance_bands',
    'bodyweight': 'bodyweight',
    'body weight': 'bodyweight',
    'cable': 'cable',
    'machine': 'machine',
    'smith machine': 'machine',
  };

  /// Normalize an equipment display name to a type key.
  static String normalizeType(String name) {
    return _nameNormalization[name.toLowerCase()] ?? name.toLowerCase();
  }

  // =========================================================================
  // Factory methods
  // =========================================================================

  /// Build from flat string list (backward-compatible path).
  ///
  /// Sets `hasDetailedInventory = false` so the engine behaves
  /// identically to the old code path.
  static EquipmentContext fromStrings(List<String> names) {
    return EquipmentContext(
      equipmentNames: names,
      inventory: const {},
      hasDetailedInventory: false,
    );
  }

  /// Build from rich [EquipmentItem] list.
  ///
  /// Sets `hasDetailedInventory = true` when any item has weight data.
  static EquipmentContext fromItems(List<EquipmentItem> items) {
    if (items.isEmpty) {
      return const EquipmentContext(
        equipmentNames: [],
        inventory: {},
        hasDetailedInventory: false,
      );
    }

    final names = items.map((i) => i.displayName).toList();
    final inventoryMap = <String, EquipmentInventory>{};
    bool hasAnyDetail = false;

    for (final item in items) {
      final typeKey = normalizeType(item.name);
      final sortedWeights = item.availableWeights; // already sorted

      if (sortedWeights.isNotEmpty || item.weightInventory.isNotEmpty) {
        hasAnyDetail = true;
      }

      // Detect adjustable from notes
      final isAdjustable = item.notes != null &&
          item.notes!.toLowerCase().contains('adjustable');

      inventoryMap[typeKey] = EquipmentInventory(
        sortedWeights: sortedWeights,
        weightToQuantity: Map<double, int>.from(item.weightInventory),
        isPairType: item.isPairType,
        isAdjustable: isAdjustable,
        minWeight: sortedWeights.isNotEmpty ? sortedWeights.first : null,
        maxWeight: sortedWeights.isNotEmpty ? sortedWeights.last : null,
        weightUnit: item.weightUnit,
      );
    }

    return EquipmentContext(
      equipmentNames: names,
      inventory: inventoryMap,
      hasDetailedInventory: hasAnyDetail,
    );
  }

  /// Build from flat chip names + optional detail overrides.
  ///
  /// Used when the UI has both selected chip names and inline weight
  /// picker data for some equipment types.
  static EquipmentContext fromMixed(
    List<String> selectedNames,
    Map<String, EquipmentItem>? detailOverrides,
  ) {
    if (detailOverrides == null || detailOverrides.isEmpty) {
      return fromStrings(selectedNames);
    }

    final inventoryMap = <String, EquipmentInventory>{};
    bool hasAnyDetail = false;

    for (final name in selectedNames) {
      final typeKey = normalizeType(name);
      final override = detailOverrides[name];

      if (override != null &&
          (override.weightInventory.isNotEmpty ||
              override.availableWeights.isNotEmpty)) {
        hasAnyDetail = true;
        final sortedWeights = override.availableWeights;

        final isAdjustable = override.notes != null &&
            override.notes!.toLowerCase().contains('adjustable');

        inventoryMap[typeKey] = EquipmentInventory(
          sortedWeights: sortedWeights,
          weightToQuantity: Map<double, int>.from(override.weightInventory),
          isPairType: override.isPairType,
          isAdjustable: isAdjustable,
          minWeight: sortedWeights.isNotEmpty ? sortedWeights.first : null,
          maxWeight: sortedWeights.isNotEmpty ? sortedWeights.last : null,
          weightUnit: override.weightUnit,
        );
      }
    }

    return EquipmentContext(
      equipmentNames: selectedNames,
      inventory: inventoryMap,
      hasDetailedInventory: hasAnyDetail,
    );
  }
}
