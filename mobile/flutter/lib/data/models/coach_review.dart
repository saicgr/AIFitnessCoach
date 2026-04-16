/// AI nutrition-pro review models for recipes and meal plans.
library;

enum CoachReviewSubject { recipe, mealPlan;
  String get value => this == recipe ? 'recipe' : 'meal_plan';
  static CoachReviewSubject fromValue(String? v) =>
      v == 'meal_plan' ? mealPlan : recipe;
}

enum CoachReviewKind {
  aiAuto('ai_auto'),
  aiRequested('ai_requested'),
  humanProPending('human_pro_pending'),
  humanProComplete('human_pro_complete');

  final String value;
  const CoachReviewKind(this.value);
  static CoachReviewKind fromValue(String? v) =>
      CoachReviewKind.values.firstWhere((e) => e.value == v, orElse: () => CoachReviewKind.aiAuto);
}

class MicronutrientGap {
  final String nutrient;
  final int deficitPct;
  final String? suggestion;
  const MicronutrientGap({required this.nutrient, required this.deficitPct, this.suggestion});
  factory MicronutrientGap.fromJson(Map<String, dynamic> j) => MicronutrientGap(
        nutrient: j['nutrient'] as String,
        deficitPct: j['deficit_pct'] as int? ?? 0,
        suggestion: j['suggestion'] as String?,
      );
}

class SwapSuggestion {
  final String targetLabel;
  final String suggestedLabel;
  final String rationale;
  final Map<String, double> deltas;
  final String? targetItemId;
  final String? suggestedRecipeId;

  const SwapSuggestion({
    required this.targetLabel,
    required this.suggestedLabel,
    required this.rationale,
    this.deltas = const {},
    this.targetItemId,
    this.suggestedRecipeId,
  });

  factory SwapSuggestion.fromJson(Map<String, dynamic> j) {
    final deltasRaw = (j['deltas'] as Map?) ?? {};
    return SwapSuggestion(
      targetLabel: (j['target_label'] ?? '') as String,
      suggestedLabel: (j['suggested_label'] ?? '') as String,
      rationale: (j['rationale'] ?? '') as String,
      deltas: deltasRaw.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
      targetItemId: j['target_item_id'] as String?,
      suggestedRecipeId: j['suggested_recipe_id'] as String?,
    );
  }
}

class CoachReview {
  final String id;
  final String userId;
  final CoachReviewSubject subjectType;
  final String subjectId;
  final int? subjectVersion;
  final CoachReviewKind reviewKind;
  final int? overallScore;
  final String? macroBalanceNotes;
  final List<MicronutrientGap> micronutrientGaps;
  final List<String> allergenFlags;
  final int? glycemicLoadScore;
  final List<SwapSuggestion> swapSuggestions;
  final String? fullFeedback;
  final String? modelId;
  final DateTime reviewedAt;
  final bool isStale;

  const CoachReview({
    required this.id,
    required this.userId,
    required this.subjectType,
    required this.subjectId,
    required this.reviewKind,
    required this.reviewedAt,
    this.subjectVersion,
    this.overallScore,
    this.macroBalanceNotes,
    this.micronutrientGaps = const [],
    this.allergenFlags = const [],
    this.glycemicLoadScore,
    this.swapSuggestions = const [],
    this.fullFeedback,
    this.modelId,
    this.isStale = false,
  });

  factory CoachReview.fromJson(Map<String, dynamic> j) => CoachReview(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        subjectType: CoachReviewSubject.fromValue(j['subject_type'] as String?),
        subjectId: j['subject_id'] as String,
        subjectVersion: j['subject_version'] as int?,
        reviewKind: CoachReviewKind.fromValue(j['review_kind'] as String?),
        overallScore: j['overall_score'] as int?,
        macroBalanceNotes: j['macro_balance_notes'] as String?,
        micronutrientGaps: (j['micronutrient_gaps'] as List? ?? [])
            .map((e) => MicronutrientGap.fromJson(e as Map<String, dynamic>))
            .toList(),
        allergenFlags: (j['allergen_flags'] as List? ?? []).map((e) => e as String).toList(),
        glycemicLoadScore: j['glycemic_load_score'] as int?,
        swapSuggestions: (j['swap_suggestions'] as List? ?? [])
            .map((e) => SwapSuggestion.fromJson(e as Map<String, dynamic>))
            .toList(),
        fullFeedback: j['full_feedback'] as String?,
        modelId: j['model_id'] as String?,
        reviewedAt: DateTime.parse(j['reviewed_at'] as String),
        isStale: j['is_stale'] as bool? ?? false,
      );
}
