/// Model for a piece of equipment with optional quantity and weight details.
class EquipmentItem {
  /// Equipment identifier (e.g., 'dumbbells', 'kettlebells', 'barbell')
  final String name;

  /// Display name (e.g., 'Dumbbells', 'Kettlebells', 'Barbell')
  final String displayName;

  /// Quantity of this equipment (e.g., 2 dumbbells)
  final int quantity;

  /// List of available weights in lbs (e.g., [15, 25, 40] for dumbbells)
  /// DEPRECATED: Use weightInventory instead for quantity tracking
  final List<double> weights;

  /// Map of weight to quantity (e.g., {15: 1, 20: 2, 25: 2})
  /// This allows tracking "1x 15lb, 2x 20lb, 2x 25lb" dumbbells
  final Map<double, int> weightInventory;

  /// Unit for weights (lbs or kg)
  final String weightUnit;

  /// Optional notes (e.g., "adjustable 5-50lbs")
  final String? notes;

  const EquipmentItem({
    required this.name,
    required this.displayName,
    this.quantity = 1,
    this.weights = const [],
    this.weightInventory = const {},
    this.weightUnit = 'lbs',
    this.notes,
  });

  /// Create from JSON map
  factory EquipmentItem.fromJson(Map<String, dynamic> json) {
    // Parse weight inventory if present
    Map<double, int> inventory = {};
    if (json['weight_inventory'] != null) {
      final rawInventory = json['weight_inventory'] as Map<String, dynamic>;
      inventory = rawInventory.map(
        (key, value) => MapEntry(double.parse(key), value as int),
      );
    }

    // Parse legacy weights list
    final legacyWeights = (json['weights'] as List<dynamic>?)
            ?.map((e) => (e as num).toDouble())
            .toList() ??
        [];

    // If no inventory but has legacy weights, migrate them (assume quantity 2 for pairs)
    if (inventory.isEmpty && legacyWeights.isNotEmpty) {
      inventory = {for (final w in legacyWeights) w: 2};
    }

    return EquipmentItem(
      name: json['name'] as String,
      displayName: json['display_name'] as String? ??
          _formatDisplayName(json['name'] as String),
      quantity: json['quantity'] as int? ?? 1,
      weights: legacyWeights,
      weightInventory: inventory,
      weightUnit: json['weight_unit'] as String? ?? 'lbs',
      notes: json['notes'] as String?,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    // Convert weightInventory to string keys for JSON compatibility
    final inventoryJson = weightInventory.map(
      (key, value) => MapEntry(key.toString(), value),
    );

    // Also output weights list for backward compatibility
    final weightsList = weightInventory.keys.toList()..sort();

    return {
      'name': name,
      'display_name': displayName,
      'quantity': quantity,
      'weights': weightsList,
      'weight_inventory': inventoryJson,
      'weight_unit': weightUnit,
      if (notes != null) 'notes': notes,
    };
  }

  /// Get sorted list of weights from inventory
  List<double> get availableWeights {
    final keys = weightInventory.keys.toList()..sort();
    return keys;
  }

  /// Get quantity for a specific weight
  int getQuantityForWeight(double weight) {
    return weightInventory[weight] ?? 0;
  }

  /// Check if this is a "pair" type equipment (dumbbells, kettlebells)
  bool get isPairType {
    return name == 'dumbbells' || name == 'kettlebells';
  }

  /// Create from just a name (legacy format)
  factory EquipmentItem.fromName(String name) {
    return EquipmentItem(
      name: name,
      displayName: _formatDisplayName(name),
    );
  }

  /// Format snake_case to Title Case
  static String _formatDisplayName(String name) {
    return name
        .split('_')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }

  /// Get a summary string for display
  String get summary {
    final parts = <String>[];

    if (quantity > 1) {
      parts.add('$quantity');
    }

    // Use weight inventory for detailed summary
    if (weightInventory.isNotEmpty) {
      final sortedWeights = availableWeights;
      if (sortedWeights.length == 1) {
        final w = sortedWeights.first;
        final qty = weightInventory[w]!;
        parts.add('${qty}x ${_formatWeight(w)}$weightUnit');
      } else if (sortedWeights.length <= 3) {
        parts.add(sortedWeights
            .map((w) => '${weightInventory[w]}x ${_formatWeight(w)}')
            .join(', ') + weightUnit);
      } else {
        // Show range with total count
        final totalCount = weightInventory.values.fold(0, (a, b) => a + b);
        parts.add('${_formatWeight(sortedWeights.first)}-${_formatWeight(sortedWeights.last)}$weightUnit ($totalCount items)');
      }
    } else if (weights.isNotEmpty) {
      // Fallback to legacy weights display
      if (weights.length == 1) {
        parts.add('${_formatWeight(weights.first)}$weightUnit');
      } else if (weights.length <= 3) {
        parts.add(weights.map((w) => '${_formatWeight(w)}$weightUnit').join(', '));
      } else {
        parts.add('${_formatWeight(weights.first)}-${_formatWeight(weights.last)}$weightUnit');
      }
    }

    if (notes != null && notes!.isNotEmpty) {
      parts.add(notes!);
    }

    return parts.isEmpty ? '' : parts.join(' - ');
  }

  /// Format weight (remove .0 for whole numbers)
  static String _formatWeight(double weight) {
    return weight == weight.roundToDouble() ? weight.toInt().toString() : weight.toString();
  }

  /// Copy with modifications
  EquipmentItem copyWith({
    String? name,
    String? displayName,
    int? quantity,
    List<double>? weights,
    Map<double, int>? weightInventory,
    String? weightUnit,
    String? notes,
  }) {
    return EquipmentItem(
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      quantity: quantity ?? this.quantity,
      weights: weights ?? this.weights,
      weightInventory: weightInventory ?? this.weightInventory,
      weightUnit: weightUnit ?? this.weightUnit,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EquipmentItem && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}

/// Model for a workout environment with its equipment
class WorkoutEnvironmentData {
  /// Environment identifier (e.g., 'home_gym', 'commercial_gym')
  final String id;

  /// Display name (e.g., 'Home Gym', 'Commercial Gym')
  final String name;

  /// Description of the environment
  final String description;

  /// Icon/emoji for the environment
  final String icon;

  /// List of equipment in this environment
  final List<EquipmentItem> equipment;

  /// Whether this is a user-created custom environment
  final bool isCustom;

  const WorkoutEnvironmentData({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.equipment = const [],
    this.isCustom = false,
  });

  /// Create from JSON
  factory WorkoutEnvironmentData.fromJson(Map<String, dynamic> json) {
    return WorkoutEnvironmentData(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '🏋️',
      equipment: (json['equipment'] as List<dynamic>?)
              ?.map((e) => e is String
                  ? EquipmentItem.fromName(e)
                  : EquipmentItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isCustom: json['is_custom'] as bool? ?? false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'equipment': equipment.map((e) => e.toJson()).toList(),
      'is_custom': isCustom,
    };
  }

  /// Copy with modifications
  WorkoutEnvironmentData copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    List<EquipmentItem>? equipment,
    bool? isCustom,
  }) {
    return WorkoutEnvironmentData(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      equipment: equipment ?? this.equipment,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  /// Get equipment count display
  String get equipmentCountDisplay {
    if (equipment.isEmpty) return 'No equipment';
    if (equipment.length == 1) return '1 item';
    return '${equipment.length} items';
  }
}
