import 'package:json_annotation/json_annotation.dart';
import 'consistency.dart';

part 'workout_day_detail.g.dart';

/// Detailed workout data for a specific day
@JsonSerializable()
class WorkoutDayDetail {
  final String date;
  final String status;

  @JsonKey(name: 'workout_id')
  final String? workoutId;

  @JsonKey(name: 'workout_name')
  final String? workoutName;

  @JsonKey(name: 'workout_type')
  final String? workoutType;

  @JsonKey(name: 'difficulty')
  final String? difficulty;

  @JsonKey(name: 'duration_minutes')
  final int? durationMinutes;

  @JsonKey(name: 'total_volume')
  final double? totalVolume;

  @JsonKey(name: 'calories_burned')
  final int? caloriesBurned;

  @JsonKey(name: 'muscles_worked')
  final List<String> musclesWorked;

  final List<ExerciseSetDetail> exercises;

  @JsonKey(name: 'shared_images')
  final List<String>? sharedImages;

  @JsonKey(name: 'coach_feedback')
  final String? coachFeedback;

  @JsonKey(name: 'completed_at')
  final String? completedAt;

  @JsonKey(name: 'average_rpe')
  final double? averageRpe;

  const WorkoutDayDetail({
    required this.date,
    required this.status,
    this.workoutId,
    this.workoutName,
    this.workoutType,
    this.difficulty,
    this.durationMinutes,
    this.totalVolume,
    this.caloriesBurned,
    this.musclesWorked = const [],
    this.exercises = const [],
    this.sharedImages,
    this.coachFeedback,
    this.completedAt,
    this.averageRpe,
  });

  factory WorkoutDayDetail.fromJson(Map<String, dynamic> json) =>
      _$WorkoutDayDetailFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutDayDetailToJson(this);

  CalendarStatus get statusEnum {
    switch (status.toLowerCase()) {
      case 'completed':
        return CalendarStatus.completed;
      case 'missed':
        return CalendarStatus.missed;
      case 'future':
        return CalendarStatus.future;
      default:
        return CalendarStatus.rest;
    }
  }

  DateTime get dateTime => DateTime.parse(date);

  String get formattedVolume {
    if (totalVolume == null) return '-';
    if (totalVolume! >= 1000) {
      return '${(totalVolume! / 1000).toStringAsFixed(1)}k kg';
    }
    return '${totalVolume!.toStringAsFixed(0)} kg';
  }

  String get formattedDuration {
    if (durationMinutes == null) return '-';
    if (durationMinutes! >= 60) {
      final hours = durationMinutes! ~/ 60;
      final mins = durationMinutes! % 60;
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    }
    return '${durationMinutes}m';
  }
}

/// Exercise detail with all sets
@JsonSerializable()
class ExerciseSetDetail {
  @JsonKey(name: 'exercise_name')
  final String exerciseName;

  @JsonKey(name: 'exercise_id')
  final String? exerciseId;

  @JsonKey(name: 'muscle_group')
  final String muscleGroup;

  final List<SetData> sets;

  @JsonKey(name: 'has_pr')
  final bool hasPr;

  @JsonKey(name: 'pr_type')
  final String? prType;

  @JsonKey(name: 'total_volume')
  final double? totalVolume;

  @JsonKey(name: 'best_set_weight')
  final double? bestSetWeight;

  @JsonKey(name: 'best_set_reps')
  final int? bestSetReps;

  const ExerciseSetDetail({
    required this.exerciseName,
    this.exerciseId,
    required this.muscleGroup,
    this.sets = const [],
    this.hasPr = false,
    this.prType,
    this.totalVolume,
    this.bestSetWeight,
    this.bestSetReps,
  });

  factory ExerciseSetDetail.fromJson(Map<String, dynamic> json) =>
      _$ExerciseSetDetailFromJson(json);
  Map<String, dynamic> toJson() => _$ExerciseSetDetailToJson(this);

  String get bestSetDisplay {
    if (bestSetWeight == null || bestSetReps == null) return '-';
    return '${bestSetWeight!.toStringAsFixed(1)}kg × $bestSetReps';
  }
}

/// Individual set data
@JsonSerializable()
class SetData {
  @JsonKey(name: 'set_number')
  final int setNumber;

  final int reps;

  @JsonKey(name: 'weight_kg')
  final double weightKg;

  final int? rpe;
  final int? rir;

  @JsonKey(name: 'is_pr')
  final bool isPr;

  @JsonKey(name: 'set_type')
  final String? setType;

  const SetData({
    required this.setNumber,
    required this.reps,
    required this.weightKg,
    this.rpe,
    this.rir,
    this.isPr = false,
    this.setType,
  });

  factory SetData.fromJson(Map<String, dynamic> json) =>
      _$SetDataFromJson(json);
  Map<String, dynamic> toJson() => _$SetDataToJson(this);

  String get display {
    final weight = weightKg > 0 ? '${weightKg.toStringAsFixed(1)}kg × ' : '';
    final repsStr = '$reps reps';
    final intensity = rpe != null
        ? ' RPE $rpe'
        : (rir != null ? ' RIR $rir' : '');
    return '$weight$repsStr$intensity';
  }
}

/// Search result for exercise history
@JsonSerializable()
class ExerciseSearchResult {
  final String date;

  @JsonKey(name: 'workout_id')
  final String workoutId;

  @JsonKey(name: 'workout_name')
  final String workoutName;

  @JsonKey(name: 'exercise_name')
  final String exerciseName;

  @JsonKey(name: 'sets_completed')
  final int setsCompleted;

  @JsonKey(name: 'best_weight')
  final double bestWeight;

  @JsonKey(name: 'best_reps')
  final int bestReps;

  @JsonKey(name: 'total_volume')
  final double? totalVolume;

  @JsonKey(name: 'has_pr')
  final bool hasPr;

  @JsonKey(name: 'pr_type')
  final String? prType;

  @JsonKey(name: 'average_rpe')
  final double? averageRpe;

  const ExerciseSearchResult({
    required this.date,
    required this.workoutId,
    required this.workoutName,
    required this.exerciseName,
    required this.setsCompleted,
    required this.bestWeight,
    required this.bestReps,
    this.totalVolume,
    this.hasPr = false,
    this.prType,
    this.averageRpe,
  });

  factory ExerciseSearchResult.fromJson(Map<String, dynamic> json) =>
      _$ExerciseSearchResultFromJson(json);
  Map<String, dynamic> toJson() => _$ExerciseSearchResultToJson(this);

  DateTime get dateTime => DateTime.parse(date);

  String get bestSetDisplay => '${bestWeight.toStringAsFixed(1)}kg × $bestReps';
}

/// Response for exercise search
@JsonSerializable()
class ExerciseSearchResponse {
  @JsonKey(name: 'exercise_name')
  final String exerciseName;

  @JsonKey(name: 'total_results')
  final int totalResults;

  final List<ExerciseSearchResult> results;

  @JsonKey(name: 'matching_dates')
  final List<String> matchingDates;

  const ExerciseSearchResponse({
    required this.exerciseName,
    required this.totalResults,
    this.results = const [],
    this.matchingDates = const [],
  });

  factory ExerciseSearchResponse.fromJson(Map<String, dynamic> json) =>
      _$ExerciseSearchResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ExerciseSearchResponseToJson(this);
}

/// Exercise suggestion for autocomplete
@JsonSerializable()
class ExerciseSuggestion {
  final String name;

  @JsonKey(name: 'times_performed')
  final int timesPerformed;

  @JsonKey(name: 'last_performed')
  final String? lastPerformed;

  const ExerciseSuggestion({
    required this.name,
    this.timesPerformed = 0,
    this.lastPerformed,
  });

  factory ExerciseSuggestion.fromJson(Map<String, dynamic> json) =>
      _$ExerciseSuggestionFromJson(json);
  Map<String, dynamic> toJson() => _$ExerciseSuggestionToJson(this);
}
