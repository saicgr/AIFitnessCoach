/// Model for a piece of equipment with optional quantity and weight details.
class EquipmentItem {
  /// Equipment identifier (e.g., 'dumbbells', 'kettlebells', 'barbell')
  final String name;

  /// Display name (e.g., 'Dumbbells', 'Kettlebells', 'Barbell')
  final String displayName;

  /// Quantity of this equipment (e.g., 2 dumbbells)
  final int quantity;

  /// List of available weights in lbs (e.g., [15, 25, 40] for dumbbells)
  final List<double> weights;

  /// Unit for weights (lbs or kg)
  final String weightUnit;

  /// Optional notes (e.g., "adjustable 5-50lbs")
  final String? notes;

  const EquipmentItem({
    required this.name,
    required this.displayName,
    this.quantity = 1,
    this.weights = const [],
    this.weightUnit = 'lbs',
    this.notes,
  });

  /// Create from JSON map
  factory EquipmentItem.fromJson(Map<String, dynamic> json) {
    return EquipmentItem(
      name: json['name'] as String,
      displayName: json['display_name'] as String? ?? _formatDisplayName(json['name'] as String),
      quantity: json['quantity'] as int? ?? 1,
      weights: (json['weights'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      weightUnit: json['weight_unit'] as String? ?? 'lbs',
      notes: json['notes'] as String?,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'display_name': displayName,
      'quantity': quantity,
      'weights': weights,
      'weight_unit': weightUnit,
      if (notes != null) 'notes': notes,
    };
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

    if (weights.isNotEmpty) {
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
    String? weightUnit,
    String? notes,
  }) {
    return EquipmentItem(
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      quantity: quantity ?? this.quantity,
      weights: weights ?? this.weights,
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
