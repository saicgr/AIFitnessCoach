import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';

/// Calibration repository provider
final calibrationRepositoryProvider = Provider<CalibrationRepository>((ref) {
  return CalibrationRepository(ref.watch(apiClientProvider));
});

/// Repository for calibration workout operations
class CalibrationRepository {
  final ApiClient _client;

  CalibrationRepository(this._client);

  // ─────────────────────────────────────────────────────────────────
  // Calibration Status
  // ─────────────────────────────────────────────────────────────────

  /// Get calibration status for the current user
  Future<CalibrationStatus> getCalibrationStatus() async {
    try {
      final response = await _client.get('/calibration/status');
      return CalibrationStatus.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting calibration status: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Calibration Workout Generation
  // ─────────────────────────────────────────────────────────────────

  /// Generate a new calibration workout
  Future<CalibrationWorkout> generateCalibrationWorkout() async {
    try {
      final response = await _client.post('/calibration/generate');
      return CalibrationWorkout.fromJson(response.data);
    } catch (e) {
      debugPrint('Error generating calibration workout: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Calibration Flow
  // ─────────────────────────────────────────────────────────────────

  /// Start a calibration workout
  Future<CalibrationWorkout> startCalibration(String calibrationId) async {
    try {
      final response = await _client.post('/calibration/start/$calibrationId');
      return CalibrationWorkout.fromJson(response.data);
    } catch (e) {
      debugPrint('Error starting calibration: $e');
      rethrow;
    }
  }

  /// Complete a calibration workout and get analysis
  Future<CalibrationAnalysis> completeCalibration({
    required String calibrationId,
    required CalibrationResult result,
  }) async {
    try {
      final response = await _client.post(
        '/calibration/complete/$calibrationId',
        data: result.toJson(),
      );
      return CalibrationAnalysis.fromJson(response.data);
    } catch (e) {
      debugPrint('Error completing calibration: $e');
      rethrow;
    }
  }

  /// Accept the recommended adjustments from calibration
  Future<void> acceptAdjustments(String calibrationId) async {
    try {
      await _client.post('/calibration/accept-adjustments/$calibrationId');
      debugPrint('Accepted adjustments for calibration: $calibrationId');
    } catch (e) {
      debugPrint('Error accepting adjustments: $e');
      rethrow;
    }
  }

  /// Decline the recommended adjustments from calibration
  Future<void> declineAdjustments(String calibrationId) async {
    try {
      await _client.post('/calibration/decline-adjustments/$calibrationId');
      debugPrint('Declined adjustments for calibration: $calibrationId');
    } catch (e) {
      debugPrint('Error declining adjustments: $e');
      rethrow;
    }
  }

  /// Skip calibration (user opts out)
  Future<void> skipCalibration() async {
    try {
      await _client.post('/calibration/skip');
      debugPrint('Calibration skipped');
    } catch (e) {
      debugPrint('Error skipping calibration: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Calibration Results
  // ─────────────────────────────────────────────────────────────────

  /// Get results for a specific calibration
  Future<CalibrationWorkout> getCalibrationResults(String calibrationId) async {
    try {
      final response = await _client.get('/calibration/results/$calibrationId');
      return CalibrationWorkout.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting calibration results: $e');
      rethrow;
    }
  }

  /// Get user's strength baselines
  Future<List<StrengthBaseline>> getStrengthBaselines() async {
    try {
      final response = await _client.get('/calibration/baselines');
      final data = response.data as List? ?? [];
      return data.map((json) => StrengthBaseline.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting strength baselines: $e');
      rethrow;
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────────────────────────

/// Calibration status for a user
class CalibrationStatus {
  final bool isRequired;
  final bool isCompleted;
  final bool isSkipped;
  final DateTime? lastCalibrationDate;
  final DateTime? nextCalibrationDate;
  final String? calibrationId;
  final int daysUntilNextCalibration;
  final String statusMessage;

  const CalibrationStatus({
    this.isRequired = true,
    this.isCompleted = false,
    this.isSkipped = false,
    this.lastCalibrationDate,
    this.nextCalibrationDate,
    this.calibrationId,
    this.daysUntilNextCalibration = 0,
    this.statusMessage = '',
  });

  factory CalibrationStatus.fromJson(Map<String, dynamic> json) {
    return CalibrationStatus(
      isRequired: json['is_required'] as bool? ?? true,
      isCompleted: json['is_completed'] as bool? ?? false,
      isSkipped: json['is_skipped'] as bool? ?? false,
      lastCalibrationDate: json['last_calibration_date'] != null
          ? DateTime.parse(json['last_calibration_date'] as String)
          : null,
      nextCalibrationDate: json['next_calibration_date'] != null
          ? DateTime.parse(json['next_calibration_date'] as String)
          : null,
      calibrationId: json['calibration_id'] as String?,
      daysUntilNextCalibration: json['days_until_next_calibration'] as int? ?? 0,
      statusMessage: json['status_message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'is_required': isRequired,
        'is_completed': isCompleted,
        'is_skipped': isSkipped,
        'last_calibration_date': lastCalibrationDate?.toIso8601String(),
        'next_calibration_date': nextCalibrationDate?.toIso8601String(),
        'calibration_id': calibrationId,
        'days_until_next_calibration': daysUntilNextCalibration,
        'status_message': statusMessage,
      };

  /// Check if user needs to calibrate
  bool get needsCalibration => isRequired && !isCompleted && !isSkipped;

  /// Check if recalibration is recommended
  bool get recalibrationRecommended =>
      isCompleted && daysUntilNextCalibration <= 0;
}

/// A calibration workout with exercises
class CalibrationWorkout {
  final String id;
  final String name;
  final String description;
  final String status;
  final List<CalibrationExercise> exercises;
  final int estimatedDurationMinutes;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;

  const CalibrationWorkout({
    required this.id,
    required this.name,
    required this.description,
    this.status = 'pending',
    this.exercises = const [],
    this.estimatedDurationMinutes = 15,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
  });

  factory CalibrationWorkout.fromJson(Map<String, dynamic> json) {
    final exercisesList = json['exercises'] as List? ?? [];
    return CalibrationWorkout(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Calibration Workout',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      exercises: exercisesList
          .map((e) => CalibrationExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      estimatedDurationMinutes: json['estimated_duration_minutes'] as int? ?? 15,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'status': status,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'estimated_duration_minutes': estimatedDurationMinutes,
        'started_at': startedAt?.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  /// Check if workout is in progress
  bool get isInProgress => status == 'in_progress';

  /// Check if workout is completed
  bool get isCompleted => status == 'completed';

  /// Get progress percentage
  double get progressPercentage {
    if (exercises.isEmpty) return 0;
    final completed = exercises.where((e) => e.isCompleted).length;
    return (completed / exercises.length) * 100;
  }
}

/// An exercise in a calibration workout
class CalibrationExercise {
  final String id;
  final String name;
  final String muscleGroup;
  final int targetReps;
  final int? actualReps;
  final double? weight;
  final double? suggestedWeight;
  final int restSeconds;
  final String? instructions;
  final String? videoUrl;
  final bool isCompleted;
  final int order;

  const CalibrationExercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    this.targetReps = 10,
    this.actualReps,
    this.weight,
    this.suggestedWeight,
    this.restSeconds = 60,
    this.instructions,
    this.videoUrl,
    this.isCompleted = false,
    this.order = 0,
  });

  factory CalibrationExercise.fromJson(Map<String, dynamic> json) {
    return CalibrationExercise(
      id: json['id'] as String,
      name: json['name'] as String,
      muscleGroup: json['muscle_group'] as String? ?? 'full_body',
      targetReps: json['target_reps'] as int? ?? 10,
      actualReps: json['actual_reps'] as int?,
      weight: (json['weight'] as num?)?.toDouble(),
      suggestedWeight: (json['suggested_weight'] as num?)?.toDouble(),
      restSeconds: json['rest_seconds'] as int? ?? 60,
      instructions: json['instructions'] as String?,
      videoUrl: json['video_url'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
      order: json['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'muscle_group': muscleGroup,
        'target_reps': targetReps,
        'actual_reps': actualReps,
        'weight': weight,
        'suggested_weight': suggestedWeight,
        'rest_seconds': restSeconds,
        'instructions': instructions,
        'video_url': videoUrl,
        'is_completed': isCompleted,
        'order': order,
      };

  /// Create a copy with updated values
  CalibrationExercise copyWith({
    String? id,
    String? name,
    String? muscleGroup,
    int? targetReps,
    int? actualReps,
    double? weight,
    double? suggestedWeight,
    int? restSeconds,
    String? instructions,
    String? videoUrl,
    bool? isCompleted,
    int? order,
  }) {
    return CalibrationExercise(
      id: id ?? this.id,
      name: name ?? this.name,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      targetReps: targetReps ?? this.targetReps,
      actualReps: actualReps ?? this.actualReps,
      weight: weight ?? this.weight,
      suggestedWeight: suggestedWeight ?? this.suggestedWeight,
      restSeconds: restSeconds ?? this.restSeconds,
      instructions: instructions ?? this.instructions,
      videoUrl: videoUrl ?? this.videoUrl,
      isCompleted: isCompleted ?? this.isCompleted,
      order: order ?? this.order,
    );
  }
}

/// Result from completing a calibration workout
class CalibrationResult {
  final String calibrationId;
  final List<ExerciseResult> exerciseResults;
  final int totalDurationSeconds;
  final String? notes;

  const CalibrationResult({
    required this.calibrationId,
    required this.exerciseResults,
    this.totalDurationSeconds = 0,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'calibration_id': calibrationId,
        'exercise_results': exerciseResults.map((e) => e.toJson()).toList(),
        'total_duration_seconds': totalDurationSeconds,
        'notes': notes,
      };

  factory CalibrationResult.fromJson(Map<String, dynamic> json) {
    final resultsList = json['exercise_results'] as List? ?? [];
    return CalibrationResult(
      calibrationId: json['calibration_id'] as String,
      exerciseResults: resultsList
          .map((e) => ExerciseResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalDurationSeconds: json['total_duration_seconds'] as int? ?? 0,
      notes: json['notes'] as String?,
    );
  }
}

/// Result for a single exercise in calibration
class ExerciseResult {
  final String exerciseId;
  final int repsCompleted;
  final double weightUsed;
  final int perceivedDifficulty; // 1-10 scale
  final String? notes;

  const ExerciseResult({
    required this.exerciseId,
    required this.repsCompleted,
    required this.weightUsed,
    this.perceivedDifficulty = 5,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'exercise_id': exerciseId,
        'reps_completed': repsCompleted,
        'weight_used': weightUsed,
        'perceived_difficulty': perceivedDifficulty,
        'notes': notes,
      };

  factory ExerciseResult.fromJson(Map<String, dynamic> json) {
    return ExerciseResult(
      exerciseId: json['exercise_id'] as String,
      repsCompleted: json['reps_completed'] as int? ?? 0,
      weightUsed: (json['weight_used'] as num?)?.toDouble() ?? 0,
      perceivedDifficulty: json['perceived_difficulty'] as int? ?? 5,
      notes: json['notes'] as String?,
    );
  }
}

/// Analysis results from calibration
class CalibrationAnalysis {
  final String calibrationId;
  final String message;
  final List<StrengthAssessment> strengthAssessments;
  final List<WeightAdjustment> recommendedAdjustments;
  final String overallFitnessLevel;
  final Map<String, String> muscleGroupLevels;
  final List<String> insights;
  final bool adjustmentsAccepted;

  const CalibrationAnalysis({
    required this.calibrationId,
    required this.message,
    this.strengthAssessments = const [],
    this.recommendedAdjustments = const [],
    this.overallFitnessLevel = 'intermediate',
    this.muscleGroupLevels = const {},
    this.insights = const [],
    this.adjustmentsAccepted = false,
  });

  factory CalibrationAnalysis.fromJson(Map<String, dynamic> json) {
    final assessmentsList = json['strength_assessments'] as List? ?? [];
    final adjustmentsList = json['recommended_adjustments'] as List? ?? [];
    final muscleGroupMap = json['muscle_group_levels'] as Map<String, dynamic>? ?? {};

    return CalibrationAnalysis(
      calibrationId: json['calibration_id'] as String,
      message: json['message'] as String? ?? '',
      strengthAssessments: assessmentsList
          .map((e) => StrengthAssessment.fromJson(e as Map<String, dynamic>))
          .toList(),
      recommendedAdjustments: adjustmentsList
          .map((e) => WeightAdjustment.fromJson(e as Map<String, dynamic>))
          .toList(),
      overallFitnessLevel: json['overall_fitness_level'] as String? ?? 'intermediate',
      muscleGroupLevels: muscleGroupMap.map((k, v) => MapEntry(k, v.toString())),
      insights: (json['insights'] as List?)?.cast<String>() ?? [],
      adjustmentsAccepted: json['adjustments_accepted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'calibration_id': calibrationId,
        'message': message,
        'strength_assessments': strengthAssessments.map((e) => e.toJson()).toList(),
        'recommended_adjustments': recommendedAdjustments.map((e) => e.toJson()).toList(),
        'overall_fitness_level': overallFitnessLevel,
        'muscle_group_levels': muscleGroupLevels,
        'insights': insights,
        'adjustments_accepted': adjustmentsAccepted,
      };

  /// Get display text for fitness level
  String get fitnessLevelDisplay {
    return overallFitnessLevel[0].toUpperCase() +
        overallFitnessLevel.substring(1).replaceAll('_', ' ');
  }

  /// Check if there are any adjustments recommended
  bool get hasAdjustments => recommendedAdjustments.isNotEmpty;
}

/// Strength assessment for a specific exercise/muscle group
class StrengthAssessment {
  final String exerciseId;
  final String exerciseName;
  final String muscleGroup;
  final double maxWeight;
  final int maxReps;
  final String strengthLevel;
  final double estimatedOneRepMax;

  const StrengthAssessment({
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    this.maxWeight = 0,
    this.maxReps = 0,
    this.strengthLevel = 'intermediate',
    this.estimatedOneRepMax = 0,
  });

  factory StrengthAssessment.fromJson(Map<String, dynamic> json) {
    return StrengthAssessment(
      exerciseId: json['exercise_id'] as String,
      exerciseName: json['exercise_name'] as String? ?? '',
      muscleGroup: json['muscle_group'] as String? ?? '',
      maxWeight: (json['max_weight'] as num?)?.toDouble() ?? 0,
      maxReps: json['max_reps'] as int? ?? 0,
      strengthLevel: json['strength_level'] as String? ?? 'intermediate',
      estimatedOneRepMax: (json['estimated_one_rep_max'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'exercise_id': exerciseId,
        'exercise_name': exerciseName,
        'muscle_group': muscleGroup,
        'max_weight': maxWeight,
        'max_reps': maxReps,
        'strength_level': strengthLevel,
        'estimated_one_rep_max': estimatedOneRepMax,
      };

  /// Get display text for strength level
  String get strengthLevelDisplay {
    return strengthLevel[0].toUpperCase() +
        strengthLevel.substring(1).replaceAll('_', ' ');
  }
}

/// Recommended weight adjustment for an exercise
class WeightAdjustment {
  final String exerciseId;
  final String exerciseName;
  final double currentWeight;
  final double recommendedWeight;
  final double changePercentage;
  final String reason;

  const WeightAdjustment({
    required this.exerciseId,
    required this.exerciseName,
    this.currentWeight = 0,
    this.recommendedWeight = 0,
    this.changePercentage = 0,
    this.reason = '',
  });

  factory WeightAdjustment.fromJson(Map<String, dynamic> json) {
    return WeightAdjustment(
      exerciseId: json['exercise_id'] as String,
      exerciseName: json['exercise_name'] as String? ?? '',
      currentWeight: (json['current_weight'] as num?)?.toDouble() ?? 0,
      recommendedWeight: (json['recommended_weight'] as num?)?.toDouble() ?? 0,
      changePercentage: (json['change_percentage'] as num?)?.toDouble() ?? 0,
      reason: json['reason'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'exercise_id': exerciseId,
        'exercise_name': exerciseName,
        'current_weight': currentWeight,
        'recommended_weight': recommendedWeight,
        'change_percentage': changePercentage,
        'reason': reason,
      };

  /// Check if this is an increase
  bool get isIncrease => recommendedWeight > currentWeight;

  /// Get formatted change text
  String get changeText {
    final sign = isIncrease ? '+' : '';
    return '$sign${changePercentage.toStringAsFixed(0)}%';
  }
}

/// User's strength baseline for an exercise
class StrengthBaseline {
  final String id;
  final String exerciseId;
  final String exerciseName;
  final String muscleGroup;
  final double baselineWeight;
  final int baselineReps;
  final double estimatedOneRepMax;
  final String strengthLevel;
  final DateTime calibratedAt;
  final DateTime? updatedAt;

  const StrengthBaseline({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    this.baselineWeight = 0,
    this.baselineReps = 10,
    this.estimatedOneRepMax = 0,
    this.strengthLevel = 'intermediate',
    required this.calibratedAt,
    this.updatedAt,
  });

  factory StrengthBaseline.fromJson(Map<String, dynamic> json) {
    return StrengthBaseline(
      id: json['id'] as String,
      exerciseId: json['exercise_id'] as String,
      exerciseName: json['exercise_name'] as String? ?? '',
      muscleGroup: json['muscle_group'] as String? ?? '',
      baselineWeight: (json['baseline_weight'] as num?)?.toDouble() ?? 0,
      baselineReps: json['baseline_reps'] as int? ?? 10,
      estimatedOneRepMax: (json['estimated_one_rep_max'] as num?)?.toDouble() ?? 0,
      strengthLevel: json['strength_level'] as String? ?? 'intermediate',
      calibratedAt: json['calibrated_at'] != null
          ? DateTime.parse(json['calibrated_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'exercise_id': exerciseId,
        'exercise_name': exerciseName,
        'muscle_group': muscleGroup,
        'baseline_weight': baselineWeight,
        'baseline_reps': baselineReps,
        'estimated_one_rep_max': estimatedOneRepMax,
        'strength_level': strengthLevel,
        'calibrated_at': calibratedAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  /// Get formatted weight with reps
  String get formattedBaseline {
    return '${baselineWeight.toStringAsFixed(0)} lbs x $baselineReps reps';
  }

  /// Get days since calibration
  int get daysSinceCalibration {
    return DateTime.now().difference(calibratedAt).inDays;
  }

  /// Check if recalibration is recommended (older than 30 days)
  bool get needsRecalibration => daysSinceCalibration > 30;
}
