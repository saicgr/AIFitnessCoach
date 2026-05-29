/// Training-vs-rest fueling split — feeds the Stats-tab "Fueling: Training vs
/// Rest" card. Backed by `GET /api/v1/nutrition/training-vs-rest`.
///
/// Answers "do I eat differently when I lift?" Averages are computed only over
/// days that actually had food logged, so `days` is the sample size for each
/// group (the UI can show "n=X days"). NO fabricated data: a group with no
/// logged days returns zeros + days=0. Hand-written (no codegen).
library;

import 'package:flutter/foundation.dart';

/// Averages for one day-group (training or rest).
@immutable
class FuelingGroup {
  /// Mean protein grams per logged day in this group.
  final double avgProteinG;

  /// Mean calories (kcal) per logged day in this group.
  final double avgCalories;

  /// Number of LOGGED days in this group (days with at least one food log).
  final int days;

  const FuelingGroup({
    required this.avgProteinG,
    required this.avgCalories,
    required this.days,
  });

  /// True when there are no logged days to average — the UI should show an
  /// empty state for this group rather than a misleading "0 g".
  bool get isEmpty => days == 0;

  factory FuelingGroup.fromJson(Map<String, dynamic> json) {
    return FuelingGroup(
      avgProteinG: (json['avg_protein_g'] as num?)?.toDouble() ?? 0.0,
      avgCalories: (json['avg_calories'] as num?)?.toDouble() ?? 0.0,
      days: (json['days'] as num?)?.toInt() ?? 0,
    );
  }
}

/// The training-day vs rest-day comparison.
@immutable
class FuelingSplit {
  final FuelingGroup training;
  final FuelingGroup rest;

  const FuelingSplit({required this.training, required this.rest});

  /// True when neither group has any logged days.
  bool get hasNoData => training.isEmpty && rest.isEmpty;

  /// Protein delta (training minus rest), grams. Positive = eats more protein
  /// on training days. Only meaningful when both groups have data.
  double get proteinDeltaG => training.avgProteinG - rest.avgProteinG;

  /// Calorie delta (training minus rest), kcal.
  double get calorieDelta => training.avgCalories - rest.avgCalories;

  factory FuelingSplit.fromJson(Map<String, dynamic> json) {
    final training = json['training'];
    final rest = json['rest'];
    return FuelingSplit(
      training: training is Map<String, dynamic>
          ? FuelingGroup.fromJson(training)
          : const FuelingGroup(avgProteinG: 0, avgCalories: 0, days: 0),
      rest: rest is Map<String, dynamic>
          ? FuelingGroup.fromJson(rest)
          : const FuelingGroup(avgProteinG: 0, avgCalories: 0, days: 0),
    );
  }
}
