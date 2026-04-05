import 'package:json_annotation/json_annotation.dart';


part 'nutrition_part_food_mood.dart';
part 'nutrition_part_save_food_request.dart';


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

  const FoodItem({
    required this.name,
    this.amount,
    this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) =>
      _$FoodItemFromJson(json);
  Map<String, dynamic> toJson() => _$FoodItemToJson(this);
}

/// Food log entry
@JsonSerializable()

/// Daily nutrition summary
@JsonSerializable()

/// Nutrition targets
@JsonSerializable()

/// Product nutrients from barcode lookup
@JsonSerializable()

/// Barcode product lookup response
@JsonSerializable()

/// Response after logging food from barcode
@JsonSerializable()

/// USDA per-100g nutrient data for accurate portion scaling
@JsonSerializable()

/// AI-estimated per-gram nutrition data (fallback when USDA has no match)
@JsonSerializable()

/// Individual food item with goal-based ranking
@JsonSerializable(explicitToJson: true)

/// Response after logging food from image or text with goal-based analysis
@JsonSerializable()

/// Saved food item with goal-based ranking
@JsonSerializable(explicitToJson: true)

/// Saved food (favorite recipe)
@JsonSerializable()

/// Response for saved foods list
@JsonSerializable()

/// Request to save a food from log
@JsonSerializable()

/// Request to re-log a saved food
@JsonSerializable()
