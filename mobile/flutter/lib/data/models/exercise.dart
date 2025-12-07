import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'exercise.g.dart';

/// Exercise within a workout
@JsonSerializable()
class WorkoutExercise extends Equatable {
  final String? id;
  @JsonKey(name: 'exercise_id')
  final String? exerciseId;
  @JsonKey(name: 'library_id')
  final String? libraryId;
  @JsonKey(name: 'name')
  final String? nameValue;
  final int? sets;
  final int? reps;
  @JsonKey(name: 'rest_seconds')
  final int? restSeconds;
  @JsonKey(name: 'duration_seconds')
  final int? durationSeconds;
  final double? weight;
  final String? notes;
  @JsonKey(name: 'gif_url')
  final String? gifUrl;
  @JsonKey(name: 'video_url')
  final String? videoUrl;
  @JsonKey(name: 'image_s3_path')
  final String? imageS3Path;
  @JsonKey(name: 'video_s3_path')
  final String? videoS3Path;
  @JsonKey(name: 'body_part')
  final String? bodyPart;
  final String? equipment;
  @JsonKey(name: 'muscle_group')
  final String? muscleGroup;
  @JsonKey(name: 'primary_muscle')
  final String? primaryMuscle;
  @JsonKey(name: 'secondary_muscles')
  final dynamic secondaryMuscles;
  final String? instructions;
  @JsonKey(name: 'is_completed')
  final bool? isCompleted;

  const WorkoutExercise({
    this.id,
    this.exerciseId,
    this.libraryId,
    this.nameValue,
    this.sets,
    this.reps,
    this.restSeconds,
    this.durationSeconds,
    this.weight,
    this.notes,
    this.gifUrl,
    this.videoUrl,
    this.imageS3Path,
    this.videoS3Path,
    this.bodyPart,
    this.equipment,
    this.muscleGroup,
    this.primaryMuscle,
    this.secondaryMuscles,
    this.instructions,
    this.isCompleted,
  });

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) =>
      _$WorkoutExerciseFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutExerciseToJson(this);

  /// Get name (never null for display)
  String get name => nameValue ?? 'Exercise';

  /// Format sets x reps
  String get setsRepsDisplay {
    if (sets != null && reps != null) {
      return '$sets × $reps';
    } else if (durationSeconds != null) {
      final minutes = durationSeconds! ~/ 60;
      final seconds = durationSeconds! % 60;
      if (minutes > 0 && seconds > 0) {
        return '${minutes}m ${seconds}s';
      } else if (minutes > 0) {
        return '${minutes}m';
      } else {
        return '${seconds}s';
      }
    }
    return '';
  }

  /// Get rest time display
  String get restDisplay {
    if (restSeconds == null || restSeconds == 0) return '';
    if (restSeconds! >= 60) {
      final minutes = restSeconds! ~/ 60;
      final seconds = restSeconds! % 60;
      if (seconds > 0) {
        return '${minutes}m ${seconds}s rest';
      }
      return '${minutes}m rest';
    }
    return '${restSeconds}s rest';
  }

  /// Get weight display
  String get weightDisplay {
    if (weight == null || weight == 0) return '';
    if (weight! == weight!.toInt()) {
      return '${weight!.toInt()} kg';
    }
    return '${weight!.toStringAsFixed(1)} kg';
  }

  @override
  List<Object?> get props => [
        id,
        exerciseId,
        nameValue,
        sets,
        reps,
        restSeconds,
        durationSeconds,
        weight,
      ];

  WorkoutExercise copyWith({
    String? id,
    String? exerciseId,
    String? libraryId,
    String? nameValue,
    int? sets,
    int? reps,
    int? restSeconds,
    int? durationSeconds,
    double? weight,
    String? notes,
    String? gifUrl,
    String? videoUrl,
    String? imageS3Path,
    String? videoS3Path,
    String? bodyPart,
    String? equipment,
    String? muscleGroup,
    String? primaryMuscle,
    dynamic secondaryMuscles,
    String? instructions,
    bool? isCompleted,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      libraryId: libraryId ?? this.libraryId,
      nameValue: nameValue ?? this.nameValue,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      restSeconds: restSeconds ?? this.restSeconds,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      weight: weight ?? this.weight,
      notes: notes ?? this.notes,
      gifUrl: gifUrl ?? this.gifUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      imageS3Path: imageS3Path ?? this.imageS3Path,
      videoS3Path: videoS3Path ?? this.videoS3Path,
      bodyPart: bodyPart ?? this.bodyPart,
      equipment: equipment ?? this.equipment,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      primaryMuscle: primaryMuscle ?? this.primaryMuscle,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      instructions: instructions ?? this.instructions,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Library exercise (full details)
@JsonSerializable()
class LibraryExercise extends Equatable {
  final String? id;
  @JsonKey(name: 'external_id')
  final String? externalId;
  @JsonKey(name: 'name')
  final String? nameValue;
  final String? category;
  final String? subcategory;
  @JsonKey(name: 'difficulty_level')
  final int? difficultyLevel;
  @JsonKey(name: 'primary_muscle')
  final String? primaryMuscle;
  @JsonKey(name: 'secondary_muscles')
  final String? secondaryMuscles;
  @JsonKey(name: 'equipment_required')
  final String? equipmentRequired;
  @JsonKey(name: 'body_part')
  final String? bodyPart;
  final String? target;
  @JsonKey(name: 'default_sets')
  final int? defaultSets;
  @JsonKey(name: 'default_reps')
  final int? defaultReps;
  @JsonKey(name: 'default_duration_seconds')
  final int? defaultDurationSeconds;
  @JsonKey(name: 'default_rest_seconds')
  final int? defaultRestSeconds;
  @JsonKey(name: 'gif_url')
  final String? gifUrl;
  @JsonKey(name: 'video_url')
  final String? videoUrl;
  @JsonKey(name: 'instructions')
  final String? instructionsValue;
  @JsonKey(name: 'is_compound')
  final bool? isCompound;
  @JsonKey(name: 'is_unilateral')
  final bool? isUnilateral;
  final String? tags;

  const LibraryExercise({
    this.id,
    this.externalId,
    this.nameValue,
    this.category,
    this.subcategory,
    this.difficultyLevel,
    this.primaryMuscle,
    this.secondaryMuscles,
    this.equipmentRequired,
    this.bodyPart,
    this.target,
    this.defaultSets,
    this.defaultReps,
    this.defaultDurationSeconds,
    this.defaultRestSeconds,
    this.gifUrl,
    this.videoUrl,
    this.instructionsValue,
    this.isCompound,
    this.isUnilateral,
    this.tags,
  });

  factory LibraryExercise.fromJson(Map<String, dynamic> json) =>
      _$LibraryExerciseFromJson(json);
  Map<String, dynamic> toJson() => _$LibraryExerciseToJson(this);

  /// Get name (never null for display)
  String get name => nameValue ?? 'Unknown Exercise';

  /// Get muscle group for filtering
  String? get muscleGroup => primaryMuscle ?? bodyPart;

  /// Get difficulty string
  String? get difficulty {
    if (difficultyLevel == null) return null;
    switch (difficultyLevel) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Intermediate';
      case 3:
        return 'Advanced';
      default:
        return 'Intermediate';
    }
  }

  /// Get type (category)
  String? get type => category;

  /// Get equipment as list (normalized)
  List<String>? get equipment {
    if (equipmentRequired == null || equipmentRequired!.isEmpty) return null;
    return equipmentRequired!.split(',').map((e) {
      final eq = e.trim();
      final lower = eq.toLowerCase();
      // Normalize "None (Bodyweight)" and similar to just "Bodyweight"
      if (lower.contains('none') || lower == 'bodyweight' || lower == 'body weight') {
        return 'Bodyweight';
      }
      return eq;
    }).toList();
  }

  /// Get instructions as list
  List<String>? get instructions {
    if (instructionsValue == null || instructionsValue!.isEmpty) return null;
    // Try to split by numbered list or periods
    final lines = instructionsValue!
        .split(RegExp(r'(?:\d+\.\s*|\n|\.(?=\s+[A-Z]))'))
        .where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim())
        .toList();
    return lines.isNotEmpty ? lines : [instructionsValue!];
  }

  @override
  List<Object?> get props => [id, externalId, nameValue, primaryMuscle, bodyPart];
}
