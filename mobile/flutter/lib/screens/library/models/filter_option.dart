/// Filter option model for exercise filters
class FilterOption {
  final String name;
  final int count;

  const FilterOption({
    required this.name,
    required this.count,
  });

  factory FilterOption.fromJson(Map<String, dynamic> json) {
    return FilterOption(
      name: json['name'] as String,
      count: json['count'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'count': count,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FilterOption && other.name == name && other.count == count;
  }

  @override
  int get hashCode => name.hashCode ^ count.hashCode;
}

/// Exercise filter options containing all available filter categories
class ExerciseFilterOptions {
  final List<FilterOption> bodyParts;
  final List<FilterOption> equipment;
  final List<FilterOption> exerciseTypes;
  final List<FilterOption> goals;
  final List<FilterOption> suitableFor;
  final List<FilterOption> avoidIf;
  final int totalExercises;

  const ExerciseFilterOptions({
    required this.bodyParts,
    required this.equipment,
    required this.exerciseTypes,
    required this.goals,
    required this.suitableFor,
    required this.avoidIf,
    required this.totalExercises,
  });

  factory ExerciseFilterOptions.fromJson(Map<String, dynamic> json) {
    return ExerciseFilterOptions(
      bodyParts: (json['body_parts'] as List? ?? [])
          .map((e) => FilterOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      equipment: (json['equipment'] as List? ?? [])
          .map((e) => FilterOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      exerciseTypes: (json['exercise_types'] as List? ?? [])
          .map((e) => FilterOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      goals: (json['goals'] as List? ?? [])
          .map((e) => FilterOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      suitableFor: (json['suitable_for'] as List? ?? [])
          .map((e) => FilterOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      avoidIf: (json['avoid_if'] as List? ?? [])
          .map((e) => FilterOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalExercises: json['total_exercises'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'body_parts': bodyParts.map((e) => e.toJson()).toList(),
        'equipment': equipment.map((e) => e.toJson()).toList(),
        'exercise_types': exerciseTypes.map((e) => e.toJson()).toList(),
        'goals': goals.map((e) => e.toJson()).toList(),
        'suitable_for': suitableFor.map((e) => e.toJson()).toList(),
        'avoid_if': avoidIf.map((e) => e.toJson()).toList(),
        'total_exercises': totalExercises,
      };

  /// Create an empty filter options object
  static const ExerciseFilterOptions empty = ExerciseFilterOptions(
    bodyParts: [],
    equipment: [],
    exerciseTypes: [],
    goals: [],
    suitableFor: [],
    avoidIf: [],
    totalExercises: 0,
  );
}
