/// Rep accuracy tracking for individual sets
/// Compares planned vs actual reps to help AI understand user behavior
class RepAccuracy {
  final int plannedReps;
  final int actualReps;
  final int repDifference;
  final double accuracyPercentage;
  final String? modificationReason;
  final DateTime? createdAt;

  // Exercise context
  final String? exerciseName;
  final int? exerciseIndex;
  final int? setNumber;
  final double? weightKg;
  final bool wasModified;

  const RepAccuracy({
    required this.plannedReps,
    required this.actualReps,
    required this.repDifference,
    required this.accuracyPercentage,
    this.modificationReason,
    this.createdAt,
    this.exerciseName,
    this.exerciseIndex,
    this.setNumber,
    this.weightKg,
    this.wasModified = false,
  });

  factory RepAccuracy.fromJson(Map<String, dynamic> json) {
    final planned = json['planned_reps'] as int? ?? 0;
    final actual = json['actual_reps'] as int? ?? 0;

    return RepAccuracy(
      plannedReps: planned,
      actualReps: actual,
      repDifference: json['rep_difference'] as int? ?? (actual - planned),
      accuracyPercentage: (json['accuracy_percentage'] as num?)?.toDouble() ??
          (planned > 0 ? (actual / planned * 100).clamp(0, 200) : 100.0),
      modificationReason: json['modification_reason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      exerciseName: json['exercise_name'] as String?,
      exerciseIndex: json['exercise_index'] as int?,
      setNumber: json['set_number'] as int?,
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      wasModified: json['was_modified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'planned_reps': plannedReps,
    'actual_reps': actualReps,
    'rep_difference': repDifference,
    'accuracy_percentage': accuracyPercentage,
    'modification_reason': modificationReason,
    'created_at': createdAt?.toIso8601String(),
    'exercise_name': exerciseName,
    'exercise_index': exerciseIndex,
    'set_number': setNumber,
    'weight_kg': weightKg,
    'was_modified': wasModified,
  };

  /// Create a RepAccuracy from completed set data
  factory RepAccuracy.fromSet({
    required int plannedReps,
    required int actualReps,
    String? exerciseName,
    int? exerciseIndex,
    int? setNumber,
    double? weightKg,
    String? modificationReason,
  }) {
    final difference = actualReps - plannedReps;
    final percentage = plannedReps > 0
        ? (actualReps / plannedReps * 100).clamp(0.0, 200.0)
        : 100.0;

    return RepAccuracy(
      plannedReps: plannedReps,
      actualReps: actualReps,
      repDifference: difference,
      accuracyPercentage: percentage,
      modificationReason: modificationReason,
      createdAt: DateTime.now(),
      exerciseName: exerciseName,
      exerciseIndex: exerciseIndex,
      setNumber: setNumber,
      weightKg: weightKg,
      wasModified: difference != 0,
    );
  }

  /// Whether reps were exactly as planned
  bool get wasAccurate => repDifference == 0;

  /// Whether more reps were completed than planned
  bool get exceededPlan => repDifference > 0;

  /// Whether fewer reps were completed than planned
  bool get fellShort => repDifference < 0;

  /// Get a descriptive status string
  String get statusDescription {
    if (wasAccurate) return 'On target';
    if (exceededPlan) return '+$repDifference reps';
    return '$repDifference reps'; // Already negative
  }

  /// Get formatted accuracy percentage
  String get formattedAccuracy => '${accuracyPercentage.toStringAsFixed(0)}%';
}

/// Summary of rep accuracy across a workout
class RepAccuracySummary {
  final int totalSets;
  final int accurateSets;
  final int exceededSets;
  final int shortSets;
  final double overallAccuracyPercent;
  final int totalRepsDifference;
  final List<RepAccuracy> setDetails;

  const RepAccuracySummary({
    required this.totalSets,
    required this.accurateSets,
    required this.exceededSets,
    required this.shortSets,
    required this.overallAccuracyPercent,
    required this.totalRepsDifference,
    this.setDetails = const [],
  });

  factory RepAccuracySummary.fromJson(Map<String, dynamic> json) {
    final details = (json['set_details'] as List<dynamic>? ?? [])
        .map((e) => RepAccuracy.fromJson(e as Map<String, dynamic>))
        .toList();

    return RepAccuracySummary(
      totalSets: json['total_sets'] as int? ?? 0,
      accurateSets: json['accurate_sets'] as int? ?? 0,
      exceededSets: json['exceeded_sets'] as int? ?? 0,
      shortSets: json['short_sets'] as int? ?? 0,
      overallAccuracyPercent: (json['overall_accuracy_percent'] as num?)?.toDouble() ?? 100.0,
      totalRepsDifference: json['total_reps_difference'] as int? ?? 0,
      setDetails: details,
    );
  }

  factory RepAccuracySummary.fromAccuracyList(List<RepAccuracy> accuracies) {
    if (accuracies.isEmpty) {
      return const RepAccuracySummary(
        totalSets: 0,
        accurateSets: 0,
        exceededSets: 0,
        shortSets: 0,
        overallAccuracyPercent: 100.0,
        totalRepsDifference: 0,
      );
    }

    final totalPlanned = accuracies.fold<int>(0, (sum, a) => sum + a.plannedReps);
    final totalActual = accuracies.fold<int>(0, (sum, a) => sum + a.actualReps);
    final overallAccuracy = totalPlanned > 0
        ? (totalActual / totalPlanned * 100).clamp(0.0, 200.0)
        : 100.0;

    return RepAccuracySummary(
      totalSets: accuracies.length,
      accurateSets: accuracies.where((a) => a.wasAccurate).length,
      exceededSets: accuracies.where((a) => a.exceededPlan).length,
      shortSets: accuracies.where((a) => a.fellShort).length,
      overallAccuracyPercent: overallAccuracy,
      totalRepsDifference: totalActual - totalPlanned,
      setDetails: accuracies,
    );
  }

  /// What percentage of sets were exactly on target
  double get onTargetPercent => totalSets > 0 ? (accurateSets / totalSets * 100) : 100.0;

  /// Get a user-friendly summary message
  String get summaryMessage {
    if (totalSets == 0) return 'No sets completed';
    if (accurateSets == totalSets) return 'Perfect accuracy!';
    if (exceededSets > shortSets) return 'Exceeded targets on $exceededSets sets';
    if (shortSets > exceededSets) return 'Fell short on $shortSets sets';
    return '$accurateSets of $totalSets sets on target';
  }
}
