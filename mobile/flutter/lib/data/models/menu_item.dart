import 'allergen.dart';
import 'sort_spec.dart';

/// Structured model for a dish parsed out of a menu/plate/buffet image.
///
/// Replaces the ad-hoc `Map<String, dynamic>` used by the original sheet
/// at `menu_analysis_sheet.dart:141-151` — having an actual type lets us
/// sort, filter, score, and display with compile-time field safety, and
/// lets the recommendation service reason about the item without string
/// key typos.
class MenuItem {
  /// Client-generated stable id (index-based) so portions + sort order
  /// survive list mutations without relying on name collisions.
  final String id;
  final String name;

  /// Canonical section enum value (breakfast/appetizers/mains/sides/
  /// desserts/drinks/specials/uncategorized). Backend normalizes Gemini
  /// output to this set — see `_normalize_section` in
  /// backend/api/v1/nutrition/food_logging_stream.py.
  final String section;

  /// Short Gemini-provided serving-size caption (e.g. "1 cup heaping").
  final String? amount;

  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? fiberG;
  final double? weightG;

  /// `'green' | 'yellow' | 'red'` — Gemini's per-item goal rating.
  final String? rating;
  final String? ratingReason;

  /// 0-10. 0-3 anti-inflammatory, 4-6 neutral, 7-10 highly inflammatory.
  final int? inflammationScore;
  final bool? isUltraProcessed;

  /// Structured drivers of the inflammation score. 1-3 short tags like
  /// 'deep_fried', 'refined_flour', 'added_sugar'. Powers the chip-badges
  /// in ScoreExplainSheet when the user taps the inflammation pill.
  /// Human labels are resolved via `InflammationTriggers.label()` in this
  /// file so the tag strings stay stable across backend + DB + UI.
  final List<String>? inflammationTriggers;

  /// Per-serving glycemic load (GI × carbs_g / 100). <10 low, 10-19 medium,
  /// 20+ high. Null = not computed (usually carb-free items like meat/oil).
  final int? glycemicLoad;

  /// Monash-scale FODMAP rating: `'low' | 'medium' | 'high'`. Null = unknown.
  final String? fodmapRating;

  /// Short explanation of the FODMAP trigger(s) when rating >= medium,
  /// e.g. "contains onion, garlic". Null for low-FODMAP items.
  final String? fodmapReason;

  /// Grams of added sugar per serving. Excludes naturally-occurring
  /// whole-fruit / whole-dairy sugars. WHO adult daily limit = 25 g; the
  /// Health Strip colours its pill green / amber / red against that.
  final double? addedSugarG;

  final String? coachTip;

  /// Menu price when detectable on the page. Null = not listed.
  final double? price;
  final String? currency;

  /// S3 URL of the uploaded menu page this dish came from (so the
  /// header photo strip can highlight which page produced the item).
  final String? imageUrl;

  /// FDA Big 9 allergens detected by Gemini from the dish description.
  final Set<Allergen> detectedAllergens;

  /// Optional 1-10 goal score emitted by Gemini for plate-mode items.
  final int? goalScore;

  /// Per-session portion multiplier. 1.0 = as-served; users can +/- 0.5
  /// in the portion stepper. Purely frontend; never sent back to the
  /// backend (the backend only sees the final selected items).
  final double portionMultiplier;

  const MenuItem({
    required this.id,
    required this.name,
    required this.section,
    this.amount,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.fiberG,
    this.weightG,
    this.rating,
    this.ratingReason,
    this.inflammationScore,
    this.isUltraProcessed,
    this.inflammationTriggers,
    this.glycemicLoad,
    this.fodmapRating,
    this.fodmapReason,
    this.addedSugarG,
    this.coachTip,
    this.price,
    this.currency,
    this.imageUrl,
    this.detectedAllergens = const {},
    this.goalScore,
    this.portionMultiplier = 1.0,
  });

  /// Scaled calories after applying the frontend portion multiplier.
  double get scaledCalories => calories * portionMultiplier;
  double get scaledProteinG => proteinG * portionMultiplier;
  double get scaledCarbsG => carbsG * portionMultiplier;
  double get scaledFatG => fatG * portionMultiplier;
  double? get scaledWeightG => weightG == null ? null : weightG! * portionMultiplier;

  /// Derive a portion multiplier from a user-entered target weight in grams.
  /// If we don't know the base `weightG` we can't map → returns null so the
  /// caller falls back to the discrete multiplier stepper.
  double? multiplierForWeight(double targetGrams) {
    if (weightG == null || weightG! <= 0) return null;
    final mult = targetGrams / weightG!;
    // Clamp to sane bounds so the UI can't drive us to 0× / 20×.
    return mult.clamp(0.25, 5.0).toDouble();
  }

  MenuItem copyWith({
    double? portionMultiplier,
    String? section,
  }) {
    return MenuItem(
      id: id,
      name: name,
      section: section ?? this.section,
      amount: amount,
      calories: calories,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      fiberG: fiberG,
      weightG: weightG,
      rating: rating,
      ratingReason: ratingReason,
      inflammationScore: inflammationScore,
      isUltraProcessed: isUltraProcessed,
      inflammationTriggers: inflammationTriggers,
      glycemicLoad: glycemicLoad,
      fodmapRating: fodmapRating,
      fodmapReason: fodmapReason,
      addedSugarG: addedSugarG,
      coachTip: coachTip,
      price: price,
      currency: currency,
      imageUrl: imageUrl,
      detectedAllergens: detectedAllergens,
      goalScore: goalScore,
      portionMultiplier: portionMultiplier ?? this.portionMultiplier,
    );
  }

  /// Tolerant JSON parser: reads both the current backend schema and the
  /// legacy fields the sheet previously normalized by hand. Numeric
  /// fields accept int OR float (Gemini emits both).
  factory MenuItem.fromJson(
    Map<String, dynamic> json, {
    required String id,
    String? fallbackImageUrl,
  }) {
    double num0(dynamic v) => v == null ? 0 : (v as num).toDouble();
    double? numN(dynamic v) => v == null ? null : (v as num).toDouble();
    int? intN(dynamic v) => v == null ? null : (v as num).toInt();

    return MenuItem(
      id: id,
      name: (json['name'] as String?)?.trim() ?? 'Unknown',
      section: _canonicalSection(json['section']),
      amount: json['amount'] as String?,
      calories: num0(json['calories']),
      proteinG: num0(json['protein_g'] ?? json['protein']),
      carbsG: num0(json['carbs_g'] ?? json['carbs']),
      fatG: num0(json['fat_g'] ?? json['fat']),
      fiberG: numN(json['fiber_g']),
      weightG: numN(json['weight_g']),
      rating: json['rating'] as String?,
      ratingReason: json['rating_reason'] as String?,
      inflammationScore: intN(json['inflammation_score']),
      isUltraProcessed: json['is_ultra_processed'] as bool?,
      // inflammation_triggers arrives as a JSON array; tolerate null + non-list
      // defensively so a legacy saved menu without the field doesn't crash.
      inflammationTriggers: (json['inflammation_triggers'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      glycemicLoad: intN(json['glycemic_load']),
      fodmapRating: json['fodmap_rating'] as String?,
      fodmapReason: json['fodmap_reason'] as String?,
      addedSugarG: numN(json['added_sugar_g']),
      coachTip: json['coach_tip'] as String?,
      price: numN(json['price']),
      currency: json['currency'] as String?,
      imageUrl: json['image_url'] as String? ?? fallbackImageUrl,
      detectedAllergens: Allergen.parseAll(json['detected_allergens'] as List?),
      goalScore: intN(json['goal_score']),
    );
  }

  static String _canonicalSection(dynamic raw) {
    const allowed = {
      'breakfast', 'appetizers', 'mains', 'sides',
      'desserts', 'drinks', 'specials', 'uncategorized',
    };
    if (raw == null) return 'uncategorized';
    final s = raw.toString().trim().toLowerCase();
    if (allowed.contains(s)) return s;
    // Defensive fallthrough — backend _normalize_section already does
    // this mapping, but we guard against a legacy menu analysis loaded
    // from history pre-upgrade.
    return 'uncategorized';
  }

  /// Comparable extractor used by `SortSpecList.comparator` so the sheet
  /// can sort by any field without if/else forests at call sites.
  /// Missing data defaults to a neutral midpoint so dishes without a signal
  /// don't sort to the top/bottom and dominate the list. Ultra-processed
  /// sorts false-first (0) so clean dishes surface when the user picks that
  /// dimension asc; FODMAP uses the 0/1/2 rank of low/medium/high.
  Comparable<dynamic>? sortValue(SortField field) {
    switch (field) {
      case SortField.calories: return scaledCalories;
      case SortField.protein: return scaledProteinG;
      case SortField.carbs: return scaledCarbsG;
      case SortField.fat: return scaledFatG;
      case SortField.health: return _ratingRank(rating);
      case SortField.inflammation: return inflammationScore ?? 5;
      case SortField.glycemicLoad: return glycemicLoad ?? 10;
      case SortField.addedSugar: return addedSugarG ?? 0.0;
      case SortField.ultraProcessed: return (isUltraProcessed == true) ? 1 : 0;
      case SortField.price: return price;
      case SortField.weight: return scaledWeightG;
    }
  }

  /// Sort rank for the colored health pill — higher = healthier.
  static int _ratingRank(String? r) {
    switch (r) {
      case 'green': return 2;
      case 'yellow': return 1;
      case 'red': return 0;
      default: return -1;
    }
  }
}

/// Display grouping for section labels in the sheet. Ordering is
/// deliberately meal-flow-aware, not alphabetical.
const List<String> kCanonicalSectionOrder = [
  'breakfast',
  'appetizers',
  'mains',
  'sides',
  'desserts',
  'drinks',
  'specials',
  'uncategorized',
];

String displaySectionName(String section) {
  switch (section) {
    case 'breakfast': return 'Breakfast';
    case 'appetizers': return 'Appetizers';
    case 'mains': return 'Mains';
    case 'sides': return 'Sides';
    case 'desserts': return 'Desserts';
    case 'drinks': return 'Drinks';
    case 'specials': return 'Specials';
    case 'uncategorized':
    default: return 'Other';
  }
}

/// Human-label + directional metadata for the canonical inflammation trigger
/// tags Gemini emits per dish (see `MenuItem.inflammationTriggers`).
///
/// Tags are stored verbatim so backend + DB + UI stay in sync, but the user
/// never sees the raw snake_case — this helper provides:
///   • `label(tag)`  → short Title-Case string for chip badges
///   • `isPositive(tag)` → true if the tag reflects an anti-inflammatory
///     driver (omega-3, leafy greens, turmeric, whole grains, fermented,
///     berries, fatty fish, olive oil) so the chip renders green instead of
///     red; otherwise the driver is pushing the score up and renders red.
///
/// Unknown tags fall back to a de-snake-cased Title Case label + a neutral
/// amber colour so free-form Gemini strings still display cleanly.
class InflammationTriggers {
  InflammationTriggers._();

  static const Map<String, String> _labels = {
    'deep_fried': 'Deep-fried',
    'seed_oil': 'Seed oil',
    'refined_flour': 'Refined flour',
    'added_sugar': 'Added sugar',
    'processed_meat': 'Processed meat',
    'saturated_fat': 'Saturated fat',
    'omega6_high': 'High omega-6',
    'artificial_additives': 'Additives',
    'omega3_rich': 'Omega-3 rich',
    'leafy_greens': 'Leafy greens',
    'olive_oil': 'Olive oil',
    'turmeric': 'Turmeric',
    'whole_grains': 'Whole grains',
    'fermented': 'Fermented',
    'berries': 'Berries',
    'fatty_fish': 'Fatty fish',
    // Fallback defaults written by the backend schema-sanity layer when
    // Gemini drops the array entirely (see _apply_dish_health_fallbacks).
    'whole_foods': 'Whole foods',
    'mixed_ingredients': 'Mixed ingredients',
    'processed_ingredients': 'Processed ingredients',
  };

  static const Set<String> _positiveTags = {
    'omega3_rich',
    'leafy_greens',
    'olive_oil',
    'turmeric',
    'whole_grains',
    'fermented',
    'berries',
    'fatty_fish',
    'whole_foods',
  };

  /// Map a raw tag to its display label. Unknown tags are de-snake-cased
  /// and Title-Cased so free-form Gemini output still reads cleanly.
  static String label(String tag) {
    final hit = _labels[tag.toLowerCase()];
    if (hit != null) return hit;
    return tag
        .split(RegExp(r'[_\s]+'))
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  /// True when the tag drives inflammation DOWN (anti-inflammatory signal).
  /// The Score Explain sheet renders positive tags in green and the rest in
  /// red so the user can tell at a glance which ingredients are helping vs
  /// hurting.
  static bool isPositive(String tag) => _positiveTags.contains(tag.toLowerCase());
}
