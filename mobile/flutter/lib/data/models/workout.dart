import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'exercise.dart';

part 'workout.g.dart';

@JsonSerializable()
class Workout extends Equatable {
  final String? id;
  @JsonKey(name: 'user_id')
  final String? userId;
  final String? name;
  final String? type;
  final String? difficulty;
  @JsonKey(name: 'scheduled_date')
  final String? scheduledDate;
  @JsonKey(name: 'is_completed')
  final bool? isCompleted;
  @JsonKey(name: 'exercises_json')
  final dynamic exercisesJson; // Can be String or List
  @JsonKey(name: 'duration_minutes')
  final int? durationMinutes;
  @JsonKey(name: 'generation_method')
  final String? generationMethod;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  const Workout({
    this.id,
    this.userId,
    this.name,
    this.type,
    this.difficulty,
    this.scheduledDate,
    this.isCompleted,
    this.exercisesJson,
    this.durationMinutes,
    this.generationMethod,
    this.createdAt,
    this.updatedAt,
  });

  factory Workout.fromJson(Map<String, dynamic> json) => _$WorkoutFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutToJson(this);

  /// Parse exercises from JSON
  List<WorkoutExercise> get exercises {
    if (exercisesJson == null) return [];
    try {
      List<dynamic> exercisesList;
      if (exercisesJson is String) {
        exercisesList = jsonDecode(exercisesJson as String) as List;
      } else if (exercisesJson is List) {
        exercisesList = exercisesJson as List;
      } else {
        return [];
      }
      return exercisesList
          .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Get exercise count
  int get exerciseCount => exercises.length;

  /// Calculate estimated calories (6 cal/min)
  int get estimatedCalories => (durationMinutes ?? 0) * 6;

  /// Get formatted date
  String get formattedDate {
    if (scheduledDate == null) return '';
    try {
      final date = DateTime.parse(scheduledDate!);
      return '${date.month}/${date.day}/${date.year}';
    } catch (_) {
      return scheduledDate!;
    }
  }

  /// Check if workout is today
  bool get isToday {
    if (scheduledDate == null) return false;
    try {
      final date = DateTime.parse(scheduledDate!);
      final now = DateTime.now();
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    } catch (_) {
      return false;
    }
  }

  /// Get primary muscle groups
  List<String> get primaryMuscles {
    final muscles = <String>{};
    for (final exercise in exercises) {
      if (exercise.primaryMuscle != null) {
        muscles.add(exercise.primaryMuscle!);
      }
      if (exercise.muscleGroup != null) {
        muscles.add(exercise.muscleGroup!);
      }
    }
    return muscles.toList();
  }

  /// Get equipment needed
  List<String> get equipmentNeeded {
    final equipment = <String>{};
    for (final exercise in exercises) {
      if (exercise.equipment != null && exercise.equipment!.isNotEmpty) {
        String eq = exercise.equipment!;
        // Normalize equipment names
        final lowerEq = eq.toLowerCase();
        if (lowerEq.contains('none') ||
            lowerEq == 'bodyweight' ||
            lowerEq == 'body weight') {
          eq = 'Bodyweight';
        }
        equipment.add(eq);
      }
    }
    // Remove bodyweight variations - we only show actual equipment needed
    equipment.removeWhere((e) => e.toLowerCase() == 'bodyweight');
    return equipment.toList();
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        type,
        difficulty,
        scheduledDate,
        isCompleted,
        durationMinutes,
      ];

  Workout copyWith({
    String? id,
    String? userId,
    String? name,
    String? type,
    String? difficulty,
    String? scheduledDate,
    bool? isCompleted,
    dynamic exercisesJson,
    int? durationMinutes,
    String? generationMethod,
    String? createdAt,
    String? updatedAt,
  }) {
    return Workout(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      isCompleted: isCompleted ?? this.isCompleted,
      exercisesJson: exercisesJson ?? this.exercisesJson,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      generationMethod: generationMethod ?? this.generationMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Personal Record info returned from workout completion API
class PersonalRecordInfo {
  final String exerciseName;
  final double weightKg;
  final int reps;
  final double estimated1rmKg;
  final double? previous1rmKg;
  final double? improvementKg;
  final double? improvementPercent;
  final bool isAllTimePr;
  final String? celebrationMessage;

  const PersonalRecordInfo({
    required this.exerciseName,
    required this.weightKg,
    required this.reps,
    required this.estimated1rmKg,
    this.previous1rmKg,
    this.improvementKg,
    this.improvementPercent,
    this.isAllTimePr = true,
    this.celebrationMessage,
  });

  factory PersonalRecordInfo.fromJson(Map<String, dynamic> json) {
    return PersonalRecordInfo(
      exerciseName: json['exercise_name'] as String? ?? '',
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0.0,
      reps: json['reps'] as int? ?? 0,
      estimated1rmKg: (json['estimated_1rm_kg'] as num?)?.toDouble() ?? 0.0,
      previous1rmKg: (json['previous_1rm_kg'] as num?)?.toDouble(),
      improvementKg: (json['improvement_kg'] as num?)?.toDouble(),
      improvementPercent: (json['improvement_percent'] as num?)?.toDouble(),
      isAllTimePr: json['is_all_time_pr'] as bool? ?? true,
      celebrationMessage: json['celebration_message'] as String?,
    );
  }
}

/// Response from workout completion API including PRs
class WorkoutCompletionResponse {
  final Workout workout;
  final List<PersonalRecordInfo> personalRecords;
  final bool strengthScoresUpdated;
  final String message;

  const WorkoutCompletionResponse({
    required this.workout,
    this.personalRecords = const [],
    this.strengthScoresUpdated = false,
    this.message = 'Workout completed successfully',
  });

  factory WorkoutCompletionResponse.fromJson(Map<String, dynamic> json) {
    final workoutData = json['workout'] as Map<String, dynamic>? ?? json;
    final prsData = json['personal_records'] as List<dynamic>? ?? [];

    return WorkoutCompletionResponse(
      workout: Workout.fromJson(workoutData),
      personalRecords: prsData
          .map((pr) => PersonalRecordInfo.fromJson(pr as Map<String, dynamic>))
          .toList(),
      strengthScoresUpdated: json['strength_scores_updated'] as bool? ?? false,
      message: json['message'] as String? ?? 'Workout completed successfully',
    );
  }

  /// Check if any PRs were achieved
  bool get hasPRs => personalRecords.isNotEmpty;

  /// Get count of PRs
  int get prCount => personalRecords.length;
}
