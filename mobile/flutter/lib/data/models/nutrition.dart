import 'package:json_annotation/json_annotation.dart';


part 'nutrition_part_food_mood.dart';
part 'nutrition_part_save_food_request.dart';
part 'nutrition.g.dart';


DateTime _parseDateTimeOrNow(String? value) {
  if (value == null || value.isEmpty) return DateTime.now();
  return DateTime.parse(value);
}

/// Individual food item
@JsonSerializable()
class FoodItem {
  final String name;
  final String? amount;
  final int? calories;
  @JsonKey(name: 'protein_g')
  final double? proteinG;
  @JsonKey(name: 'carbs_g')
  final double? carbsG;
  @JsonKey(name: 'fat_g')
  final double? fatG;
  @JsonKey(name: 'fiber_g')
  final double? fiberG;
  // Scaling fields from JSONB
  @JsonKey(name: 'weight_g')
  final double? weightG;
  final String? unit;
  final int? count;
  @JsonKey(name: 'weight_per_unit_g')
  final double? weightPerUnitG;
  @JsonKey(name: 'inflammation_score')
  final int? inflammationScore;
  @JsonKey(name: 'is_ultra_processed')
  final bool? isUltraProcessed;
  // Menu-scan provenance. `description` is the dish's printed menu copy
  // ("Maple-lacquered Pork Belly, Smoked Cheese Grits, Perfect Egg") so a
  // logged item still says what it was months later. `addonGroup` +
  // `parentDishName` mark a row that was an add-on (a sauce/side logged
  // alongside a dish) so the pairing stays legible in history.
  final String? description;
  @JsonKey(name: 'addon_group')
  final String? addonGroup;
  @JsonKey(name: 'parent_dish_name')
  final String? parentDishName;
  // Layer-3 portion-validation tripwire flags. When the backend can't
  // confidently size the portion (e.g. blueberries 99×148g) it sets these
  // so the UI can prompt the user to confirm before persisting.
  final String? confidence;
  @JsonKey(name: 'requires_user_confirmation')
  final bool? requiresUserConfirmation;
  /// Set by the backend macro-integrity chokepoint
  /// (`services/gemini/parsers.flag_unknown_macros`) when this item's calories
  /// are known but its protein/carbs/fat genuinely are not. When true, the
  /// macro fields above are NULL — and null means UNKNOWN, never zero. UI must
  /// render a placeholder ("—") or prompt the user; a "0 g" reading here is a
  /// fabricated number.
  @JsonKey(name: 'macros_unknown')
  final bool? macrosUnknown;

  const FoodItem({
    required this.name,
    this.amount,
    this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.fiberG,
    this.weightG,
    this.unit,
    this.count,
    this.weightPerUnitG,
    this.inflammationScore,
    this.isUltraProcessed,
    this.description,
    this.addonGroup,
    this.parentDishName,
    this.confidence,
    this.requiresUserConfirmation,
    this.macrosUnknown,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) =>
      _$FoodItemFromJson(json);
  Map<String, dynamic> toJson() => _$FoodItemToJson(this);

  /// True when the macro split for this item is unknown — either the backend
  /// flagged it explicitly, or every macro came back null. Callers must branch
  /// on this instead of substituting `?? 0`.
  bool get hasUnknownMacros =>
      macrosUnknown == true ||
      (proteinG == null && carbsG == null && fatG == null);

  /// Whether this item has weight data for scaling
  bool get hasWeightData => weightG != null && weightG! > 0;

  /// Whether this item has count data for scaling
  bool get hasCountData => count != null && count! > 0 && weightPerUnitG != null;
}

