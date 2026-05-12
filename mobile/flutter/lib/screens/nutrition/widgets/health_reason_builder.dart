/// Locally derive `health_score_reasons` from per-meal signals when the
/// server / AI didn't emit them.
///
/// The "?" Health Score explainer renders these tags as chips. Server-emitted
/// AI reasons always win — local derivation only kicks in for older logs that
/// pre-date the `health_score_reasons` column.
library;

List<String> healthReasonsFromSignals({
  List<String>? aiReasons,
  int? calories,
  double? proteinG,
  double? fiberG,
  double? sugarG,
  bool? isUltraProcessed,
  int? inflammationScore,
}) {
  if (aiReasons != null && aiReasons.isNotEmpty) return aiReasons;
  final out = <String>[];
  if ((proteinG ?? 0) >= 25) out.add('high_protein');
  if ((fiberG ?? 0) >= 8) out.add('high_fiber');
  if ((sugarG ?? 0) >= 25) out.add('added_sugar');
  if (isUltraProcessed == true) out.add('ultra_processed');
  if ((inflammationScore ?? 0) >= 7) out.add('high_inflammation');
  if ((calories ?? 0) >= 800) out.add('calorie_dense');
  if (out.isEmpty) out.add('balanced_macros');
  return out;
}
