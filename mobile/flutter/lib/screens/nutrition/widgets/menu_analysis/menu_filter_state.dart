import '../../../../data/models/allergen.dart';
import '../../../../data/models/menu_item.dart';

/// Immutable snapshot of everything the filter sheet can toggle.
///
/// Kept separate from the sheet UI so the main MenuAnalysisSheet can
/// own the state, persist it across filter-sheet open/close, and
/// render an active-chip strip above the list without poking into
/// stateful sheet internals.
class MenuFilterState {
  /// 'green' / 'yellow' / 'red' — empty set means no health filter.
  final Set<String> healthRatings;

  /// 'anti' (0-3) / 'mild' (4-6) / 'high' (7-10) / empty = any.
  final Set<String> inflammationBuckets;

  /// min / max for macro and price ranges. null = no bound.
  final double? minProteinG;
  final double? maxCarbsG;
  final double? maxFatG;
  final double? maxCalories;
  final double? maxPriceUsd;

  /// When true, hide dishes whose detected allergens intersect with
  /// the user's allergen profile. Defaults true when the user has at
  /// least one allergen set — see MenuAnalysisSheet's constructor.
  final bool hideAllergenDishes;

  /// Filter by section (lowercase canonical value from MenuItem.section).
  /// Empty = show all sections.
  final Set<String> sections;

  /// Free-text search over dish name + coach tip. Lowercased.
  final String searchQuery;

  /// Diabetes filter: max glycemic load per serving. 9 ≈ "low only", 19 ≈
  /// "low or medium", null = no bound. Items with null glycemic_load pass
  /// through (we don't penalize Gemini's "unknown" as failure).
  final double? maxGlycemicLoad;

  /// IBS / FODMAP filter: highest rating allowed. 'low' keeps only low,
  /// 'medium' keeps low+medium, 'high' (or null) keeps everything.
  final String? fodmapMax;

  /// Ultra-processed toggle. When true, hide items flagged
  /// `is_ultra_processed == true`.
  final bool hideUltraProcessed;

  const MenuFilterState({
    this.healthRatings = const {},
    this.inflammationBuckets = const {},
    this.minProteinG,
    this.maxCarbsG,
    this.maxFatG,
    this.maxCalories,
    this.maxPriceUsd,
    this.hideAllergenDishes = false,
    this.sections = const {},
    this.searchQuery = '',
    this.maxGlycemicLoad,
    this.fodmapMax,
    this.hideUltraProcessed = false,
  });

  static const empty = MenuFilterState();

  bool get hasAnyFilter =>
      healthRatings.isNotEmpty ||
      inflammationBuckets.isNotEmpty ||
      minProteinG != null ||
      maxCarbsG != null ||
      maxFatG != null ||
      maxCalories != null ||
      maxPriceUsd != null ||
      hideAllergenDishes ||
      sections.isNotEmpty ||
      searchQuery.isNotEmpty ||
      maxGlycemicLoad != null ||
      fodmapMax != null ||
      hideUltraProcessed;

  MenuFilterState copyWith({
    Set<String>? healthRatings,
    Set<String>? inflammationBuckets,
    double? minProteinG,
    double? maxCarbsG,
    double? maxFatG,
    double? maxCalories,
    double? maxPriceUsd,
    bool? hideAllergenDishes,
    Set<String>? sections,
    String? searchQuery,
    bool clearMinProteinG = false,
    bool clearMaxCarbsG = false,
    bool clearMaxFatG = false,
    bool clearMaxCalories = false,
    bool clearMaxPriceUsd = false,
    double? maxGlycemicLoad,
    String? fodmapMax,
    bool? hideUltraProcessed,
    bool clearMaxGlycemicLoad = false,
    bool clearFodmapMax = false,
  }) {
    return MenuFilterState(
      healthRatings: healthRatings ?? this.healthRatings,
      inflammationBuckets: inflammationBuckets ?? this.inflammationBuckets,
      minProteinG: clearMinProteinG ? null : (minProteinG ?? this.minProteinG),
      maxCarbsG: clearMaxCarbsG ? null : (maxCarbsG ?? this.maxCarbsG),
      maxFatG: clearMaxFatG ? null : (maxFatG ?? this.maxFatG),
      maxCalories: clearMaxCalories ? null : (maxCalories ?? this.maxCalories),
      maxPriceUsd: clearMaxPriceUsd ? null : (maxPriceUsd ?? this.maxPriceUsd),
      hideAllergenDishes: hideAllergenDishes ?? this.hideAllergenDishes,
      sections: sections ?? this.sections,
      searchQuery: searchQuery ?? this.searchQuery,
      maxGlycemicLoad: clearMaxGlycemicLoad ? null : (maxGlycemicLoad ?? this.maxGlycemicLoad),
      fodmapMax: clearFodmapMax ? null : (fodmapMax ?? this.fodmapMax),
      hideUltraProcessed: hideUltraProcessed ?? this.hideUltraProcessed,
    );
  }

  /// Apply every filter in a single pass. Returns true if item survives.
  /// Ordered so the cheapest checks short-circuit first.
  bool accepts(MenuItem item, {UserAllergenProfile? profile}) {
    if (sections.isNotEmpty && !sections.contains(item.section)) return false;
    if (healthRatings.isNotEmpty && !healthRatings.contains(item.rating)) {
      return false;
    }
    if (inflammationBuckets.isNotEmpty) {
      final bucket = _inflammationBucket(item.inflammationScore);
      if (!inflammationBuckets.contains(bucket)) return false;
    }
    if (minProteinG != null && item.proteinG < minProteinG!) return false;
    if (maxCarbsG != null && item.carbsG > maxCarbsG!) return false;
    if (maxFatG != null && item.fatG > maxFatG!) return false;
    if (maxCalories != null && item.calories > maxCalories!) return false;
    if (maxPriceUsd != null && item.price != null && item.price! > maxPriceUsd!) {
      return false;
    }
    // Diabetes: drop items whose glycemic_load exceeds the user's bound.
    // Unknown GL (null) passes — Gemini didn't compute it; don't penalise
    // the user by hiding items we can't judge.
    if (maxGlycemicLoad != null && item.glycemicLoad != null && item.glycemicLoad! > maxGlycemicLoad!) {
      return false;
    }
    // FODMAP: keep only items whose rating is ≤ the user's ceiling. Unknown
    // fodmap_rating passes.
    if (fodmapMax != null && item.fodmapRating != null) {
      const rank = {'low': 0, 'medium': 1, 'high': 2};
      final cap = rank[fodmapMax] ?? 2;
      final got = rank[item.fodmapRating] ?? 0;
      if (got > cap) return false;
    }
    if (hideUltraProcessed && item.isUltraProcessed == true) return false;
    if (hideAllergenDishes && profile != null && !profile.isEmpty) {
      final hits = profile.matchesForDish(
        dishName: item.name,
        detectedAllergens: item.detectedAllergens,
        dishDescription: item.coachTip,
      );
      if (hits.isNotEmpty) return false;
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      final name = item.name.toLowerCase();
      final tip = item.coachTip?.toLowerCase() ?? '';
      if (!name.contains(q) && !tip.contains(q)) return false;
    }
    return true;
  }

  static String _inflammationBucket(int? score) {
    if (score == null) return 'mild';
    if (score <= 3) return 'anti';
    if (score <= 6) return 'mild';
    return 'high';
  }
}
