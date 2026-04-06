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

