/// Per-meal macro targets (protein / carbs / fat + calories) for a single
/// meal type on a given day.
///
/// PLAIN hand-written model — NOT `@JsonSerializable`. The repo's codegen
/// (`build_runner`) is disabled here (analyzer 7.x crash with Dart 3.11), so
/// any model that needs JSON (de)serialization must carry it manually. Keep
/// it in this standalone file so it never drags a `.g.dart` `part` into the
/// `@JsonSerializable` `NutritionPreferences` family.
///
/// Backend contract (`GET /nutrition/dynamic-targets/{user_id}` →
/// `per_meal_targets`): a map keyed by meal type
/// (`breakfast`/`lunch`/`dinner`/`snacks`) → an object of
/// `{target_protein_g, target_carbs_g, target_fat_g, target_calories}`.
class MealMacroTargets {
  final double proteinG;
  final double carbsG;
  final double fatG;
  final int calories;

  const MealMacroTargets({
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.calories,
  });

  /// Tolerant numeric coercion — the backend may send ints, doubles, or
  /// numeric strings. Never throws on a malformed field; falls back to 0.
  static double _asDouble(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  static int _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.round();
    if (v is String) return int.tryParse(v) ?? (double.tryParse(v)?.round() ?? 0);
    return 0;
  }

  factory MealMacroTargets.fromJson(Map<String, dynamic> json) {
    return MealMacroTargets(
      proteinG: _asDouble(json['target_protein_g']),
      carbsG: _asDouble(json['target_carbs_g']),
      fatG: _asDouble(json['target_fat_g']),
      calories: _asInt(json['target_calories']),
    );
  }

  Map<String, dynamic> toJson() => {
        'target_protein_g': proteinG.round(),
        'target_carbs_g': carbsG.round(),
        'target_fat_g': fatG.round(),
        'target_calories': calories,
      };

  /// Parse the whole `per_meal_targets` map. Returns null when the value is
  /// null/absent (feature disabled) or not a map. Skips any entry whose value
  /// isn't a JSON object so one malformed meal can't blank the rest.
  static Map<String, MealMacroTargets>? parseMap(Object? raw) {
    if (raw is! Map) return null;
    final out = <String, MealMacroTargets>{};
    raw.forEach((key, value) {
      if (key is String && value is Map<String, dynamic>) {
        out[key] = MealMacroTargets.fromJson(value);
      } else if (key is String && value is Map) {
        out[key] = MealMacroTargets.fromJson(
          value.map((k, v) => MapEntry(k.toString(), v)),
        );
      }
    });
    return out.isEmpty ? null : out;
  }
}
