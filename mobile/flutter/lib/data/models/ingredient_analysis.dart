/// Per-row ingredient AI analysis models for the Recipe Builder.
library;

enum NutritionSourceKind {
  branded('branded', 'Brand'),
  usda('usda', 'USDA'),
  aiEstimate('ai_estimate', 'AI');

  final String value;
  final String shortLabel;
  const NutritionSourceKind(this.value, this.shortLabel);
  static NutritionSourceKind fromValue(String? v) =>
      NutritionSourceKind.values.firstWhere((e) => e.value == v, orElse: () => NutritionSourceKind.aiEstimate);
}

class IngredientAnalysis {
  final String foodName;
  final String? brand;
  final double amount;
  final String unit;
  final double? amountGrams;
  final String? cookingMethod;
  final NutritionSourceKind nutritionSource;
  final int nutritionConfidence;
  final bool isNegligible;
  final String rawText;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final double sugarG;
  final double? vitaminDIu;
  final double? calciumMg;
  final double? ironMg;
  final double? sodiumMg;
  final double? omega3G;

  const IngredientAnalysis({
    required this.foodName,
    required this.amount,
    required this.unit,
    required this.nutritionSource,
    required this.nutritionConfidence,
    required this.rawText,
    this.brand,
    this.amountGrams,
    this.cookingMethod,
    this.isNegligible = false,
    this.calories = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.fiberG = 0,
    this.sugarG = 0,
    this.vitaminDIu,
    this.calciumMg,
    this.ironMg,
    this.sodiumMg,
    this.omega3G,
  });

  factory IngredientAnalysis.fromJson(Map<String, dynamic> j) => IngredientAnalysis(
        foodName: j['food_name'] as String,
        brand: j['brand'] as String?,
        amount: (j['amount'] as num).toDouble(),
        unit: j['unit'] as String,
        amountGrams: (j['amount_grams'] as num?)?.toDouble(),
        cookingMethod: j['cooking_method'] as String?,
        nutritionSource: NutritionSourceKind.fromValue(j['nutrition_source'] as String?),
        nutritionConfidence: (j['nutrition_confidence'] as num?)?.toInt() ?? 0,
        isNegligible: j['is_negligible'] as bool? ?? false,
        rawText: (j['raw_text'] ?? '') as String,
        calories: (j['calories'] as num?)?.toDouble() ?? 0,
        proteinG: (j['protein_g'] as num?)?.toDouble() ?? 0,
        carbsG: (j['carbs_g'] as num?)?.toDouble() ?? 0,
        fatG: (j['fat_g'] as num?)?.toDouble() ?? 0,
        fiberG: (j['fiber_g'] as num?)?.toDouble() ?? 0,
        sugarG: (j['sugar_g'] as num?)?.toDouble() ?? 0,
        vitaminDIu: (j['vitamin_d_iu'] as num?)?.toDouble(),
        calciumMg: (j['calcium_mg'] as num?)?.toDouble(),
        ironMg: (j['iron_mg'] as num?)?.toDouble(),
        sodiumMg: (j['sodium_mg'] as num?)?.toDouble(),
        omega3G: (j['omega3_g'] as num?)?.toDouble(),
      );
}

class PantryDetectedItem {
  final String name;
  final int confidence;
  final String source;
  const PantryDetectedItem({required this.name, required this.confidence, required this.source});
  factory PantryDetectedItem.fromJson(Map<String, dynamic> j) => PantryDetectedItem(
        name: j['name'] as String,
        confidence: j['confidence'] as int? ?? 0,
        source: j['source'] as String? ?? 'text',
      );
}

class PantrySuggestion {
  final String name;
  final String? description;
  final String? cuisine;
  final String? category;
  final int servings;
  final int? prepTimeMinutes;
  final int? cookTimeMinutes;
  final int? caloriesPerServing;
  final double? proteinPerServingG;
  final double? carbsPerServingG;
  final double? fatPerServingG;
  final double? fiberPerServingG;
  final List<String> matchedPantryItems;
  final List<String> missingIngredients;
  final int overallMatchScore;
  final String? suggestionReason;

  const PantrySuggestion({
    required this.name,
    required this.servings,
    this.description,
    this.cuisine,
    this.category,
    this.prepTimeMinutes,
    this.cookTimeMinutes,
    this.caloriesPerServing,
    this.proteinPerServingG,
    this.carbsPerServingG,
    this.fatPerServingG,
    this.fiberPerServingG,
    this.matchedPantryItems = const [],
    this.missingIngredients = const [],
    this.overallMatchScore = 0,
    this.suggestionReason,
  });

  factory PantrySuggestion.fromJson(Map<String, dynamic> j) => PantrySuggestion(
        name: j['name'] as String,
        description: j['description'] as String?,
        cuisine: j['cuisine'] as String?,
        category: j['category'] as String?,
        servings: j['servings'] as int? ?? 1,
        prepTimeMinutes: j['prep_time_minutes'] as int?,
        cookTimeMinutes: j['cook_time_minutes'] as int?,
        caloriesPerServing: j['calories_per_serving'] as int?,
        proteinPerServingG: (j['protein_per_serving_g'] as num?)?.toDouble(),
        carbsPerServingG: (j['carbs_per_serving_g'] as num?)?.toDouble(),
        fatPerServingG: (j['fat_per_serving_g'] as num?)?.toDouble(),
        fiberPerServingG: (j['fiber_per_serving_g'] as num?)?.toDouble(),
        matchedPantryItems:
            (j['matched_pantry_items'] as List?)?.map((e) => e as String).toList() ?? const [],
        missingIngredients:
            (j['missing_ingredients'] as List?)?.map((e) => e as String).toList() ?? const [],
        overallMatchScore: j['overall_match_score'] as int? ?? 0,
        suggestionReason: j['suggestion_reason'] as String?,
      );
}

class PantryAnalyzeResponse {
  final List<PantryDetectedItem> detectedItems;
  final List<PantrySuggestion> suggestions;

  const PantryAnalyzeResponse({required this.detectedItems, required this.suggestions});

  factory PantryAnalyzeResponse.fromJson(Map<String, dynamic> j) => PantryAnalyzeResponse(
        detectedItems: (j['detected_items'] as List? ?? [])
            .map((e) => PantryDetectedItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        suggestions: (j['suggestions'] as List? ?? [])
            .map((e) => PantrySuggestion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ImportProgressEvent {
  final String step;       // fetching | extracting | parsing | analyzing | done | error
  final String message;
  final int? confidence;
  final Map<String, dynamic>? recipe;

  const ImportProgressEvent({
    required this.step,
    required this.message,
    this.confidence,
    this.recipe,
  });

  factory ImportProgressEvent.fromJson(Map<String, dynamic> j) => ImportProgressEvent(
        step: j['step'] as String? ?? 'unknown',
        message: (j['message'] ?? '') as String,
        confidence: j['confidence'] as int?,
        recipe: (j['recipe'] as Map?)?.cast<String, dynamic>(),
      );
}
