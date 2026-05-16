/// A4 — AI-assisted custom food creation models.
///
/// These intentionally use hand-written `fromJson` (no `json_serializable`
/// codegen) because the project must NOT run `dart run build_runner build`
/// (analyzer crash — see CLAUDE.md). Keeping these self-contained avoids
/// touching the committed `nutrition.g.dart`.
library;

/// An existing custom food that closely matches an AI suggestion.
/// Surfaced so the UI can offer "use existing" instead of creating a dupe.
class AiSuggestedDuplicate {
  final String id;
  final String name;
  final int? totalCalories;
  final double? totalProteinG;
  final String sourceType;

  const AiSuggestedDuplicate({
    required this.id,
    required this.name,
    this.totalCalories,
    this.totalProteinG,
    this.sourceType = 'text',
  });

  factory AiSuggestedDuplicate.fromJson(Map<String, dynamic> json) {
    return AiSuggestedDuplicate(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      totalCalories: (json['total_calories'] as num?)?.toInt(),
      totalProteinG: (json['total_protein_g'] as num?)?.toDouble(),
      sourceType: json['source_type'] as String? ?? 'text',
    );
  }
}

/// AI suggestions for a new custom food. EVERY field is advisory — the UI
/// renders all of these into editable inputs (C5). Macros the AI could not
/// determine arrive as null and are listed in [missingFields].
class AiSuggestedFood {
  final String? name;
  final String? brand;
  final String? emoji;
  final String? amount;
  final int? calories;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final double? fiberG;

  /// "text" or "nutrition_label".
  final String source;

  /// True → UI shows a "double-check these numbers" hint.
  final bool lowConfidence;

  /// Macro field names the AI could not read (e.g. ["fat_g"]).
  final List<String> missingFields;

  /// Human-readable caveat, if any.
  final String? note;

  /// A matching existing custom food, if one was found.
  final AiSuggestedDuplicate? duplicate;

  const AiSuggestedFood({
    this.name,
    this.brand,
    this.emoji,
    this.amount,
    this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.fiberG,
    this.source = 'text',
    this.lowConfidence = false,
    this.missingFields = const [],
    this.note,
    this.duplicate,
  });

  factory AiSuggestedFood.fromJson(Map<String, dynamic> json) {
    return AiSuggestedFood(
      name: json['name'] as String?,
      brand: json['brand'] as String?,
      emoji: json['emoji'] as String?,
      amount: json['amount'] as String?,
      calories: (json['calories'] as num?)?.toInt(),
      proteinG: (json['protein_g'] as num?)?.toDouble(),
      carbsG: (json['carbs_g'] as num?)?.toDouble(),
      fatG: (json['fat_g'] as num?)?.toDouble(),
      fiberG: (json['fiber_g'] as num?)?.toDouble(),
      source: json['source'] as String? ?? 'text',
      lowConfidence: json['low_confidence'] as bool? ?? false,
      missingFields: (json['missing_fields'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      note: json['note'] as String?,
      duplicate: json['duplicate'] != null
          ? AiSuggestedDuplicate.fromJson(
              json['duplicate'] as Map<String, dynamic>)
          : null,
    );
  }

  bool isFieldMissing(String field) => missingFields.contains(field);
}
