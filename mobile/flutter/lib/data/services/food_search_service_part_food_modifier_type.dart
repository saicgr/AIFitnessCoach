part of 'food_search_service.dart';



enum FoodModifierType {
  addon,
  removal,
  cookingMethod,
  doneness,
  sizePortion,
  qualityLabel,
  stateTemp;

  static FoodModifierType fromString(String value) {
    switch (value) {
      case 'addon': return FoodModifierType.addon;
      case 'removal': return FoodModifierType.removal;
      case 'cooking_method': return FoodModifierType.cookingMethod;
      case 'doneness': return FoodModifierType.doneness;
      case 'size_portion': return FoodModifierType.sizePortion;
      case 'quality_label': return FoodModifierType.qualityLabel;
      case 'state_temp': return FoodModifierType.stateTemp;
      default: return FoodModifierType.addon;
    }
  }
}


class ModifierGroupOption {
  final String phrase;
  final String label;
  final int calDelta;

  const ModifierGroupOption({required this.phrase, required this.label, required this.calDelta});

  factory ModifierGroupOption.fromJson(Map<String, dynamic> json) {
    return ModifierGroupOption(
      phrase: json['phrase'] as String? ?? '',
      label: json['label'] as String? ?? '',
      calDelta: (json['cal_delta'] as num?)?.toInt() ?? 0,
    );
  }
}


class NutrientPerGram {
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;

  const NutrientPerGram({
    required this.calories, required this.proteinG,
    required this.carbsG, required this.fatG, required this.fiberG,
  });

  factory NutrientPerGram.fromJson(Map<String, dynamic> json) {
    return NutrientPerGram(
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0,
      fiberG: (json['fiber_g'] as num?)?.toDouble() ?? 0,
    );
  }
}


class FoodModifier {
  final String phrase;
  final FoodModifierType type;
  final String? displayLabel;
  final Map<String, double> delta;
  final double? defaultWeightG;
  final double? weightPerUnitG;
  final String? unitName;
  final NutrientPerGram? perGram;
  final String? group;
  final List<ModifierGroupOption> groupOptions;

  const FoodModifier({
    required this.phrase,
    required this.type,
    this.displayLabel,
    required this.delta,
    this.defaultWeightG,
    this.weightPerUnitG,
    this.unitName,
    this.perGram,
    this.group,
    this.groupOptions = const [],
  });

  factory FoodModifier.fromJson(Map<String, dynamic> json) {
    final deltaRaw = json['delta'] as Map<String, dynamic>? ?? {};
    final delta = <String, double>{};
    for (final entry in deltaRaw.entries) {
      delta[entry.key] = (entry.value as num?)?.toDouble() ?? 0;
    }

    return FoodModifier(
      phrase: json['phrase'] as String? ?? '',
      type: FoodModifierType.fromString(json['type'] as String? ?? 'addon'),
      displayLabel: json['display_label'] as String?,
      delta: delta,
      defaultWeightG: (json['default_weight_g'] as num?)?.toDouble(),
      weightPerUnitG: (json['weight_per_unit_g'] as num?)?.toDouble(),
      unitName: json['unit_name'] as String?,
      perGram: () {
        final v = json['per_gram'];
        if (v is NutrientPerGram) return v;
        if (v is Map<String, dynamic>) return NutrientPerGram.fromJson(v);
        if (v is Map) return NutrientPerGram.fromJson(Map<String, dynamic>.from(v));
        return null;
      }(),
      group: json['group'] as String?,
      groupOptions: (json['group_options'] as List<dynamic>?)
          ?.map((e) => ModifierGroupOption.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}


/// A single food item from NL analysis
class NLFoodItem {
  final String name;
  final String? amount;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? fiberG;
  final double? weightG;
  final String? weightSource;
  final String? unit;
  final Map<String, dynamic>? aiPerGram;
  final List<FoodModifier> modifiers;

  const NLFoodItem({
    required this.name,
    this.amount,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.fiberG,
    this.weightG,
    this.weightSource,
    this.unit,
    this.aiPerGram,
    this.modifiers = const [],
  });

  factory NLFoodItem.fromJson(Map<String, dynamic> json) {
    return NLFoodItem(
      name: json['name'] as String? ?? 'Unknown',
      amount: json['amount'] as String?,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0,
      fiberG: (json['fiber_g'] as num?)?.toDouble(),
      weightG: (json['weight_g'] as num?)?.toDouble(),
      weightSource: json['weight_source'] as String?,
      unit: json['unit'] as String?,
      aiPerGram: json['ai_per_gram'] is Map
          ? Map<String, dynamic>.from(json['ai_per_gram'] as Map)
          : null,
      modifiers: (json['modifiers'] as List<dynamic>?)
          ?.map((e) => FoodModifier.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    if (amount != null) 'amount': amount,
    'calories': calories,
    'protein_g': proteinG,
    'carbs_g': carbsG,
    'fat_g': fatG,
    if (fiberG != null) 'fiber_g': fiberG,
    if (weightG != null) 'weight_g': weightG,
    if (weightSource != null) 'weight_source': weightSource,
    if (unit != null) 'unit': unit,
    if (aiPerGram != null) 'ai_per_gram': aiPerGram,
    if (modifiers.isNotEmpty) 'modifiers': modifiers.map((m) => {'phrase': m.phrase, 'type': m.type.name}).toList(),
  };
}


/// AI review for a food item (from POST /nutrition/food-review)
class FoodReview {
  final List<String> encouragements;
  final List<String> warnings;
  final String? aiSuggestion;
  final String? recommendedSwap;
  final int? healthScore;

  const FoodReview({
    this.encouragements = const [],
    this.warnings = const [],
    this.aiSuggestion,
    this.recommendedSwap,
    this.healthScore,
  });

  factory FoodReview.fromJson(Map<String, dynamic> json) {
    return FoodReview(
      encouragements: (json['encouragements'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      warnings: (json['warnings'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      aiSuggestion: json['ai_suggestion'] as String?,
      recommendedSwap: json['recommended_swap'] as String?,
      healthScore: (json['health_score'] as num?)?.toInt(),
    );
  }
}


/// Wrapper for the NL analyze-text endpoint response
class FoodAnalysisResult {
  final List<NLFoodItem> foodItems;
  final int totalCalories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? fiberG;
  final String? dataSource;
  final bool cacheHit;
  final String? cacheSource;
  // AI review fields (parsed from NL response if present)
  final List<String>? encouragements;
  final List<String>? warnings;
  final String? aiSuggestion;
  final String? recommendedSwap;
  final int? healthScore;

  const FoodAnalysisResult({
    required this.foodItems,
    required this.totalCalories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.fiberG,
    this.dataSource,
    this.cacheHit = false,
    this.cacheSource,
    this.encouragements,
    this.warnings,
    this.aiSuggestion,
    this.recommendedSwap,
    this.healthScore,
  });

  factory FoodAnalysisResult.fromJson(Map<String, dynamic> json) {
    final items = (json['food_items'] as List<dynamic>?)
        ?.map((e) => NLFoodItem.fromJson(e as Map<String, dynamic>))
        .toList() ?? [];
    return FoodAnalysisResult(
      foodItems: items,
      totalCalories: (json['total_calories'] as num?)?.toInt() ?? 0,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0,
      fiberG: (json['fiber_g'] as num?)?.toDouble(),
      dataSource: json['data_source'] as String?,
      cacheHit: json['cache_hit'] as bool? ?? false,
      cacheSource: json['cache_source'] as String?,
      encouragements: (json['encouragements'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      warnings: (json['warnings'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      aiSuggestion: json['ai_suggestion'] as String?,
      recommendedSwap: json['recommended_swap'] as String?,
      healthScore: (json['health_score'] as num?)?.toInt(),
    );
  }
}


/// Result model for food search
class FoodSearchResult {
  final String id;
  final String name;
  final String? brand;
  final int calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final String? servingSize;
  final FoodSearchSource source;
  final double? distance; // For similarity ranking (lower = more similar)
  final Map<String, dynamic>? originalData;
  final double? weightPerUnitG; // Weight of 1 piece (e.g. 1 burger = 219g)
  final int? defaultCount; // Default number of pieces (e.g. 10 for 10pc nuggets)
  final double? servingWeightG; // Standard serving weight in grams
  final String? matchedQuery; // Which sub-query matched (for multi-food queries)

  const FoodSearchResult({
    required this.id,
    required this.name,
    this.brand,
    required this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.servingSize,
    required this.source,
    this.distance,
    this.originalData,
    this.weightPerUnitG,
    this.defaultCount,
    this.servingWeightG,
    this.matchedQuery,
  });

  /// Create from SavedFood model
  factory FoodSearchResult.fromSavedFood(SavedFood saved) {
    return FoodSearchResult(
      id: saved.id,
      name: saved.name,
      calories: saved.totalCalories ?? 0,
      protein: saved.totalProteinG,
      carbs: saved.totalCarbsG,
      fat: saved.totalFatG,
      source: FoodSearchSource.saved,
      originalData: saved.toJson(),
    );
  }

  /// Create from FoodLog model (recent)
  factory FoodSearchResult.fromFoodLog(FoodLog log) {
    // Get primary food name from items
    final primaryFood = log.foodItems.isNotEmpty
        ? log.foodItems.first.name
        : log.mealType;

    return FoodSearchResult(
      id: log.id,
      name: primaryFood,
      calories: log.totalCalories,
      protein: log.proteinG,
      carbs: log.carbsG,
      fat: log.fatG,
      source: FoodSearchSource.recent,
      originalData: log.toJson(),
    );
  }

  /// Create from barcode product
  factory FoodSearchResult.fromBarcodeProduct(BarcodeProduct product) {
    return FoodSearchResult(
      id: product.barcode,
      name: product.productName,
      brand: product.brand,
      calories: product.caloriesPer100g.round(),
      protein: product.proteinPer100g,
      carbs: product.carbsPer100g,
      fat: product.fatPer100g,
      servingSize: product.servingSizeG != null
          ? '${product.servingSizeG!.round()}g'
          : '100g',
      source: FoodSearchSource.barcode,
      originalData: product.toJson(),
    );
  }

  /// Create from semantic search result (RAG)
  factory FoodSearchResult.fromSearchResult(Map<String, dynamic> result) {
    return FoodSearchResult(
      id: result['id'] as String,
      name: result['name'] as String? ?? 'Unknown',
      calories: (result['total_calories'] as num?)?.toInt() ?? 0,
      protein: (result['total_protein_g'] as num?)?.toDouble(),
      source: FoodSearchSource.database,
      distance: (result['distance'] as num?)?.toDouble(),
      originalData: result,
    );
  }
}


/// Source of the food search result
enum FoodSearchSource {
  saved('Saved'),
  recent('Recent'),
  database('Database'),
  barcode('Barcode'),
  foodDatabase('Food DB');

  final String label;
  const FoodSearchSource(this.label);
}


class FoodSearchInitial extends FoodSearchState {
  const FoodSearchInitial();
}


class FoodSearchLoading extends FoodSearchState {
  final String query;
  const FoodSearchLoading(this.query);
}


class FoodSearchResults extends FoodSearchState {
  final String query;
  final List<FoodSearchResult> saved;
  final List<FoodSearchResult> recent;
  final List<FoodSearchResult> database;
  final List<FoodSearchResult> foodDatabase;
  final bool fromCache;
  final int? searchTimeMs;

  const FoodSearchResults({
    required this.query,
    this.saved = const [],
    this.recent = const [],
    this.database = const [],
    this.foodDatabase = const [],
    this.fromCache = false,
    this.searchTimeMs,
  });

  bool get isEmpty =>
      saved.isEmpty &&
      recent.isEmpty &&
      database.isEmpty &&
      foodDatabase.isEmpty;

  int get totalCount =>
      saved.length + recent.length + database.length + foodDatabase.length;

  List<FoodSearchResult> get allResults =>
      [...saved, ...recent, ...database, ...foodDatabase];
}


class FoodSearchError extends FoodSearchState {
  final String message;
  final String query;
  const FoodSearchError(this.message, this.query);
}


/// State: NL analysis is loading
class FoodSearchNLLoading extends FoodSearchState {
  final String query;
  const FoodSearchNLLoading(this.query);
}


/// State: NL analysis returned results
class FoodSearchNLResults extends FoodSearchState {
  final String query;
  final FoodAnalysisResult result;
  const FoodSearchNLResults({required this.query, required this.result});
}


/// State: NL analysis errored
class FoodSearchNLError extends FoodSearchState {
  final String message;
  final String query;
  const FoodSearchNLError(this.message, this.query);
}


/// Notifier for managing recent searches
class RecentSearchesNotifier extends StateNotifier<List<String>> {
  static const int _maxRecentSearches = 10;

  RecentSearchesNotifier() : super([]);

  void addSearch(String query) {
    final normalized = query.trim();
    if (normalized.isEmpty) return;

    // Remove if already exists
    final updated = state.where((s) => s != normalized).toList();

    // Add to front
    updated.insert(0, normalized);

    // Trim to max size
    if (updated.length > _maxRecentSearches) {
      updated.removeLast();
    }

    state = updated;
  }

  void removeSearch(String query) {
    state = state.where((s) => s != query).toList();
  }

  void clearSearches() {
    state = [];
  }
}

