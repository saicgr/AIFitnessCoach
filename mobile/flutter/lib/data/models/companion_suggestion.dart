/// Returned by ``POST /api/v1/nutrition/companions``. Drives the
/// [CompanionPickerSheet] — each suggestion is rendered as a toggleable
/// row with macros so the user can opt in before logging.
///
/// Plain hand-written class (not freezed) because this project ships
/// generated files pre-committed and does NOT run build_runner.
class CompanionSuggestion {
  /// Display name (e.g. "Coconut Chutney", "Waffle Fries").
  final String name;

  /// 'history' when this came from the user's own past logs (pre-check at
  /// higher confidence); 'global' when it's a culturally-common pairing
  /// sourced from the cached Gemini call (always unchecked by default).
  final String source;

  /// 0.0 – 1.0. Used to drive the explanatory chip ("4 of your last 5 logs")
  /// and to decide whether to pre-check the row.
  final double confidence;

  final int estCalories;
  final double estProteinG;
  final double estCarbsG;
  final double estFatG;
  final double typicalPortionG;
  final String cuisineTag;
  final String why;

  const CompanionSuggestion({
    required this.name,
    required this.source,
    required this.confidence,
    required this.estCalories,
    required this.estProteinG,
    required this.estCarbsG,
    required this.estFatG,
    required this.typicalPortionG,
    required this.cuisineTag,
    required this.why,
  });

  bool get isFromHistory => source == 'history';

  factory CompanionSuggestion.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
    int asInt(dynamic v) => (v as num?)?.toInt() ?? 0;
    return CompanionSuggestion(
      name: (json['name'] as String?) ?? '',
      source: (json['source'] as String?) ?? 'global',
      confidence: asDouble(json['confidence']),
      estCalories: asInt(json['est_calories']),
      estProteinG: asDouble(json['est_protein_g']),
      estCarbsG: asDouble(json['est_carbs_g']),
      estFatG: asDouble(json['est_fat_g']),
      typicalPortionG: asDouble(json['typical_portion_g']),
      cuisineTag: (json['cuisine_tag'] as String?) ?? '',
      why: (json['why'] as String?) ?? '',
    );
  }

  /// Convert to the JSON shape expected by ``POST /nutrition/log-direct``'s
  /// ``food_items`` array. Includes best-effort macros so the backend's
  /// ``total_*`` totals line up with what was displayed to the user.
  Map<String, dynamic> toLogItem() {
    return {
      'name': name,
      'calories': estCalories,
      'protein_g': estProteinG,
      'carbs_g': estCarbsG,
      'fat_g': estFatG,
      if (typicalPortionG > 0) 'weight_g': typicalPortionG,
      'source_label': source == 'history' ? 'recent' : 'suggested',
    };
  }
}
