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
  Comparable<dynamic>? sortValue(SortField field) {
    switch (field) {
      case SortField.calories: return scaledCalories;
      case SortField.protein: return scaledProteinG;
      case SortField.carbs: return scaledCarbsG;
      case SortField.fat: return scaledFatG;
      case SortField.health: return _ratingRank(rating);
      case SortField.inflammation: return inflammationScore ?? 5;
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
