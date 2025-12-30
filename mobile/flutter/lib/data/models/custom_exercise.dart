import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'custom_exercise.g.dart';

/// Type of combination for composite exercises
enum ComboType {
  @JsonValue('superset')
  superset,
  @JsonValue('compound_set')
  compoundSet,
  @JsonValue('giant_set')
  giantSet,
  @JsonValue('complex')
  complex,
  @JsonValue('hybrid')
  hybrid,
}

extension ComboTypeExtension on ComboType {
  String get value {
    switch (this) {
      case ComboType.superset:
        return 'superset';
      case ComboType.compoundSet:
        return 'compound_set';
      case ComboType.giantSet:
        return 'giant_set';
      case ComboType.complex:
        return 'complex';
      case ComboType.hybrid:
        return 'hybrid';
    }
  }

  String get displayName {
    switch (this) {
      case ComboType.superset:
        return 'Superset';
      case ComboType.compoundSet:
        return 'Compound Set';
      case ComboType.giantSet:
        return 'Giant Set';
      case ComboType.complex:
        return 'Complex';
      case ComboType.hybrid:
        return 'Hybrid';
    }
  }

  String get description {
    switch (this) {
      case ComboType.superset:
        return 'Two exercises back-to-back with minimal rest';
      case ComboType.compoundSet:
        return 'Same muscle group, back-to-back';
      case ComboType.giantSet:
        return '3+ exercises in sequence';
      case ComboType.complex:
        return 'Weight never leaves hands between movements';
      case ComboType.hybrid:
        return 'Two movements merged into one motion';
    }
  }

  static ComboType fromString(String? value) {
    switch (value) {
      case 'superset':
        return ComboType.superset;
      case 'compound_set':
        return ComboType.compoundSet;
      case 'giant_set':
        return ComboType.giantSet;
      case 'complex':
        return ComboType.complex;
      case 'hybrid':
        return ComboType.hybrid;
      default:
        return ComboType.superset;
    }
  }
}

/// Component of a composite exercise
@JsonSerializable()
class ComponentExercise extends Equatable {
  final String name;
  final int order;
  final int? reps;
  @JsonKey(name: 'duration_seconds')
  final int? durationSeconds;
  @JsonKey(name: 'transition_note')
  final String? transitionNote;

  const ComponentExercise({
    required this.name,
    required this.order,
    this.reps,
    this.durationSeconds,
    this.transitionNote,
  });

  factory ComponentExercise.fromJson(Map<String, dynamic> json) =>
      _$ComponentExerciseFromJson(json);
  Map<String, dynamic> toJson() => _$ComponentExerciseToJson(this);

  /// Get display string for reps or duration
  String get targetDisplay {
    if (reps != null) {
      return '$reps reps';
    }
    if (durationSeconds != null) {
      if (durationSeconds! >= 60) {
        final mins = durationSeconds! ~/ 60;
        final secs = durationSeconds! % 60;
        if (secs > 0) {
          return '${mins}m ${secs}s';
        }
        return '${mins}m';
      }
      return '${durationSeconds}s';
    }
    return '';
  }

  ComponentExercise copyWith({
    String? name,
    int? order,
    int? reps,
    int? durationSeconds,
    String? transitionNote,
  }) {
    return ComponentExercise(
      name: name ?? this.name,
      order: order ?? this.order,
      reps: reps ?? this.reps,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      transitionNote: transitionNote ?? this.transitionNote,
    );
  }

  @override
  List<Object?> get props => [name, order, reps, durationSeconds, transitionNote];
}

/// Custom exercise created by the user
@JsonSerializable()
class CustomExercise extends Equatable {
  final String id;
  final String name;
  @JsonKey(name: 'primary_muscle')
  final String primaryMuscle;
  @JsonKey(name: 'secondary_muscles')
  final List<String>? secondaryMuscles;
  final String equipment;
  final String? instructions;
  @JsonKey(name: 'default_sets')
  final int defaultSets;
  @JsonKey(name: 'default_reps')
  final int? defaultReps;
  @JsonKey(name: 'default_rest_seconds')
  final int? defaultRestSeconds;
  @JsonKey(name: 'is_compound')
  final bool isCompound;
  @JsonKey(name: 'is_composite')
  final bool isComposite;
  @JsonKey(name: 'combo_type')
  final String? comboType;
  @JsonKey(name: 'component_exercises')
  final List<ComponentExercise>? componentExercises;
  @JsonKey(name: 'custom_notes')
  final String? customNotes;
  @JsonKey(name: 'custom_video_url')
  final String? customVideoUrl;
  final List<String> tags;
  @JsonKey(name: 'usage_count')
  final int usageCount;
  @JsonKey(name: 'last_used')
  final String? lastUsed;
  @JsonKey(name: 'created_at')
  final String createdAt;

  const CustomExercise({
    required this.id,
    required this.name,
    required this.primaryMuscle,
    this.secondaryMuscles,
    required this.equipment,
    this.instructions,
    required this.defaultSets,
    this.defaultReps,
    this.defaultRestSeconds,
    required this.isCompound,
    required this.isComposite,
    this.comboType,
    this.componentExercises,
    this.customNotes,
    this.customVideoUrl,
    required this.tags,
    required this.usageCount,
    this.lastUsed,
    required this.createdAt,
  });

  factory CustomExercise.fromJson(Map<String, dynamic> json) =>
      _$CustomExerciseFromJson(json);
  Map<String, dynamic> toJson() => _$CustomExerciseToJson(this);

  /// Get the combo type enum
  ComboType? get comboTypeEnum {
    if (comboType == null) return null;
    return ComboTypeExtension.fromString(comboType);
  }

  /// Get a display label for the exercise type
  String get typeLabel {
    if (isComposite && comboType != null) {
      return ComboTypeExtension.fromString(comboType).displayName;
    }
    if (isCompound) {
      return 'Compound';
    }
    return 'Isolation';
  }

  /// Get component count for display
  int get componentCount => componentExercises?.length ?? 0;

  /// Whether the exercise has ever been used
  bool get hasBeenUsed => usageCount > 0;

  /// Get formatted last used date
  String? get lastUsedFormatted {
    if (lastUsed == null) return null;
    try {
      final date = DateTime.parse(lastUsed!);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        return 'Today';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} days ago';
      } else if (diff.inDays < 30) {
        final weeks = diff.inDays ~/ 7;
        return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
      } else {
        final months = diff.inDays ~/ 30;
        return '$months ${months == 1 ? 'month' : 'months'} ago';
      }
    } catch (e) {
      return lastUsed;
    }
  }

  CustomExercise copyWith({
    String? id,
    String? name,
    String? primaryMuscle,
    List<String>? secondaryMuscles,
    String? equipment,
    String? instructions,
    int? defaultSets,
    int? defaultReps,
    int? defaultRestSeconds,
    bool? isCompound,
    bool? isComposite,
    String? comboType,
    List<ComponentExercise>? componentExercises,
    String? customNotes,
    String? customVideoUrl,
    List<String>? tags,
    int? usageCount,
    String? lastUsed,
    String? createdAt,
  }) {
    return CustomExercise(
      id: id ?? this.id,
      name: name ?? this.name,
      primaryMuscle: primaryMuscle ?? this.primaryMuscle,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      equipment: equipment ?? this.equipment,
      instructions: instructions ?? this.instructions,
      defaultSets: defaultSets ?? this.defaultSets,
      defaultReps: defaultReps ?? this.defaultReps,
      defaultRestSeconds: defaultRestSeconds ?? this.defaultRestSeconds,
      isCompound: isCompound ?? this.isCompound,
      isComposite: isComposite ?? this.isComposite,
      comboType: comboType ?? this.comboType,
      componentExercises: componentExercises ?? this.componentExercises,
      customNotes: customNotes ?? this.customNotes,
      customVideoUrl: customVideoUrl ?? this.customVideoUrl,
      tags: tags ?? this.tags,
      usageCount: usageCount ?? this.usageCount,
      lastUsed: lastUsed ?? this.lastUsed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        primaryMuscle,
        equipment,
        isComposite,
        usageCount,
      ];
}

/// Request model for creating a simple custom exercise
@JsonSerializable()
class CreateCustomExerciseRequest extends Equatable {
  final String name;
  @JsonKey(name: 'primary_muscle')
  final String primaryMuscle;
  final String equipment;
  final String? instructions;
  @JsonKey(name: 'default_sets')
  final int defaultSets;
  @JsonKey(name: 'default_reps')
  final int? defaultReps;
  @JsonKey(name: 'is_compound')
  final bool isCompound;

  const CreateCustomExerciseRequest({
    required this.name,
    required this.primaryMuscle,
    required this.equipment,
    this.instructions,
    this.defaultSets = 3,
    this.defaultReps = 10,
    this.isCompound = false,
  });

  factory CreateCustomExerciseRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateCustomExerciseRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateCustomExerciseRequestToJson(this);

  @override
  List<Object?> get props => [name, primaryMuscle, equipment];
}

/// Request model for creating a composite/combo exercise
@JsonSerializable()
class CreateCompositeExerciseRequest extends Equatable {
  final String name;
  @JsonKey(name: 'primary_muscle')
  final String primaryMuscle;
  @JsonKey(name: 'secondary_muscles')
  final List<String> secondaryMuscles;
  final String equipment;
  @JsonKey(name: 'combo_type')
  final String comboType;
  @JsonKey(name: 'component_exercises')
  final List<ComponentExercise> componentExercises;
  final String? instructions;
  @JsonKey(name: 'custom_notes')
  final String? customNotes;
  @JsonKey(name: 'default_sets')
  final int defaultSets;
  @JsonKey(name: 'default_rest_seconds')
  final int defaultRestSeconds;
  final List<String> tags;

  const CreateCompositeExerciseRequest({
    required this.name,
    required this.primaryMuscle,
    this.secondaryMuscles = const [],
    required this.equipment,
    required this.comboType,
    required this.componentExercises,
    this.instructions,
    this.customNotes,
    this.defaultSets = 3,
    this.defaultRestSeconds = 60,
    this.tags = const [],
  });

  factory CreateCompositeExerciseRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateCompositeExerciseRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateCompositeExerciseRequestToJson(this);

  @override
  List<Object?> get props => [name, primaryMuscle, comboType, componentExercises];
}

/// Statistics for custom exercises
@JsonSerializable()
class CustomExerciseStats extends Equatable {
  @JsonKey(name: 'total_custom_exercises')
  final int totalCustomExercises;
  @JsonKey(name: 'simple_exercises')
  final int simpleExercises;
  @JsonKey(name: 'composite_exercises')
  final int compositeExercises;
  @JsonKey(name: 'total_uses')
  final int totalUses;
  @JsonKey(name: 'most_used')
  final List<MostUsedExercise> mostUsed;

  const CustomExerciseStats({
    required this.totalCustomExercises,
    required this.simpleExercises,
    required this.compositeExercises,
    required this.totalUses,
    required this.mostUsed,
  });

  factory CustomExerciseStats.fromJson(Map<String, dynamic> json) =>
      _$CustomExerciseStatsFromJson(json);
  Map<String, dynamic> toJson() => _$CustomExerciseStatsToJson(this);

  @override
  List<Object?> get props => [totalCustomExercises, totalUses];
}

/// Most used exercise in stats
@JsonSerializable()
class MostUsedExercise extends Equatable {
  @JsonKey(name: 'exercise_id')
  final String exerciseId;
  final String name;
  @JsonKey(name: 'usage_count')
  final int usageCount;
  @JsonKey(name: 'avg_rating')
  final double? avgRating;

  const MostUsedExercise({
    required this.exerciseId,
    required this.name,
    required this.usageCount,
    this.avgRating,
  });

  factory MostUsedExercise.fromJson(Map<String, dynamic> json) =>
      _$MostUsedExerciseFromJson(json);
  Map<String, dynamic> toJson() => _$MostUsedExerciseToJson(this);

  @override
  List<Object?> get props => [exerciseId, name, usageCount];
}

/// Exercise search result from library
@JsonSerializable()
class ExerciseSearchResult extends Equatable {
  final int id;
  final String name;
  @JsonKey(name: 'body_part')
  final String? bodyPart;
  final String? equipment;
  @JsonKey(name: 'target_muscle')
  final String? targetMuscle;

  const ExerciseSearchResult({
    required this.id,
    required this.name,
    this.bodyPart,
    this.equipment,
    this.targetMuscle,
  });

  factory ExerciseSearchResult.fromJson(Map<String, dynamic> json) =>
      _$ExerciseSearchResultFromJson(json);
  Map<String, dynamic> toJson() => _$ExerciseSearchResultToJson(this);

  @override
  List<Object?> get props => [id, name];
}
