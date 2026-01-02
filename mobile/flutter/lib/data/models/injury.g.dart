// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'injury.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RehabExercise _$RehabExerciseFromJson(Map<String, dynamic> json) =>
    RehabExercise(
      exerciseName: json['exercise_name'] as String,
      exerciseType: json['exercise_type'] as String,
      sets: (json['sets'] as num?)?.toInt(),
      reps: (json['reps'] as num?)?.toInt(),
      holdSeconds: (json['hold_seconds'] as num?)?.toInt(),
      frequencyPerDay: (json['frequency_per_day'] as num).toInt(),
      notes: json['notes'] as String?,
      videoUrl: json['video_url'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
    );

Map<String, dynamic> _$RehabExerciseToJson(RehabExercise instance) =>
    <String, dynamic>{
      'exercise_name': instance.exerciseName,
      'exercise_type': instance.exerciseType,
      'sets': instance.sets,
      'reps': instance.reps,
      'hold_seconds': instance.holdSeconds,
      'frequency_per_day': instance.frequencyPerDay,
      'notes': instance.notes,
      'video_url': instance.videoUrl,
      'is_completed': instance.isCompleted,
    };

Injury _$InjuryFromJson(Map<String, dynamic> json) => Injury(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  bodyPart: json['body_part'] as String,
  injuryType: json['injury_type'] as String?,
  severity: json['severity'] as String,
  reportedAt: DateTime.parse(json['reported_at'] as String),
  occurredAt: json['occurred_at'] == null
      ? null
      : DateTime.parse(json['occurred_at'] as String),
  expectedRecoveryDate: json['expected_recovery_date'] == null
      ? null
      : DateTime.parse(json['expected_recovery_date'] as String),
  actualRecoveryDate: json['actual_recovery_date'] == null
      ? null
      : DateTime.parse(json['actual_recovery_date'] as String),
  recoveryPhase: json['recovery_phase'] as String,
  painLevel: (json['pain_level'] as num?)?.toInt(),
  affectsExercises: (json['affects_exercises'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  affectsMuscles: (json['affects_muscles'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  notes: json['notes'] as String?,
  status: json['status'] as String,
  rehabExercises: (json['rehab_exercises'] as List<dynamic>?)
      ?.map((e) => RehabExercise.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$InjuryToJson(Injury instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'body_part': instance.bodyPart,
  'injury_type': instance.injuryType,
  'severity': instance.severity,
  'reported_at': instance.reportedAt.toIso8601String(),
  'occurred_at': instance.occurredAt?.toIso8601String(),
  'expected_recovery_date': instance.expectedRecoveryDate?.toIso8601String(),
  'actual_recovery_date': instance.actualRecoveryDate?.toIso8601String(),
  'recovery_phase': instance.recoveryPhase,
  'pain_level': instance.painLevel,
  'affects_exercises': instance.affectsExercises,
  'affects_muscles': instance.affectsMuscles,
  'notes': instance.notes,
  'status': instance.status,
  'rehab_exercises': instance.rehabExercises,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};

InjuryReportRequest _$InjuryReportRequestFromJson(Map<String, dynamic> json) =>
    InjuryReportRequest(
      bodyPart: json['body_part'] as String,
      injuryType: json['injury_type'] as String?,
      severity: json['severity'] as String,
      painLevel: (json['pain_level'] as num?)?.toInt(),
      occurredAt: json['occurred_at'] == null
          ? null
          : DateTime.parse(json['occurred_at'] as String),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$InjuryReportRequestToJson(
  InjuryReportRequest instance,
) => <String, dynamic>{
  'body_part': instance.bodyPart,
  'injury_type': instance.injuryType,
  'severity': instance.severity,
  'pain_level': instance.painLevel,
  'occurred_at': instance.occurredAt?.toIso8601String(),
  'notes': instance.notes,
};

InjuryReportResponse _$InjuryReportResponseFromJson(
  Map<String, dynamic> json,
) => InjuryReportResponse(
  success: json['success'] as bool,
  message: json['message'] as String,
  injury: Injury.fromJson(json['injury'] as Map<String, dynamic>),
  expectedRecoveryDays: (json['expected_recovery_days'] as num?)?.toInt(),
  workoutModifications: (json['workout_modifications'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$InjuryReportResponseToJson(
  InjuryReportResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'injury': instance.injury,
  'expected_recovery_days': instance.expectedRecoveryDays,
  'workout_modifications': instance.workoutModifications,
};

InjuryUpdateRequest _$InjuryUpdateRequestFromJson(Map<String, dynamic> json) =>
    InjuryUpdateRequest(
      painLevel: (json['pain_level'] as num?)?.toInt(),
      mobilityRating: (json['mobility_rating'] as num?)?.toInt(),
      canWorkout: json['can_workout'] as bool?,
      notes: json['notes'] as String?,
      recoveryPhase: json['recovery_phase'] as String?,
    );

Map<String, dynamic> _$InjuryUpdateRequestToJson(
  InjuryUpdateRequest instance,
) => <String, dynamic>{
  'pain_level': instance.painLevel,
  'mobility_rating': instance.mobilityRating,
  'can_workout': instance.canWorkout,
  'notes': instance.notes,
  'recovery_phase': instance.recoveryPhase,
};

InjuryUpdateResponse _$InjuryUpdateResponseFromJson(
  Map<String, dynamic> json,
) => InjuryUpdateResponse(
  success: json['success'] as bool,
  message: json['message'] as String,
  injury: Injury.fromJson(json['injury'] as Map<String, dynamic>),
  phaseChanged: json['phase_changed'] as bool?,
  newPhase: json['new_phase'] as String?,
);

Map<String, dynamic> _$InjuryUpdateResponseToJson(
  InjuryUpdateResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'injury': instance.injury,
  'phase_changed': instance.phaseChanged,
  'new_phase': instance.newPhase,
};

WorkoutModifications _$WorkoutModificationsFromJson(
  Map<String, dynamic> json,
) => WorkoutModifications(
  avoidExercises: (json['avoid_exercises'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  avoidMuscles: (json['avoid_muscles'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  reduceIntensity: json['reduce_intensity'] as bool? ?? false,
  intensityReductionPercent: (json['intensity_reduction_percent'] as num?)
      ?.toInt(),
  maxPainLevelAllowed: (json['max_pain_level_allowed'] as num?)?.toInt() ?? 3,
  activeInjuries: (json['active_injuries'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  recommendations:
      (json['recommendations'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$WorkoutModificationsToJson(
  WorkoutModifications instance,
) => <String, dynamic>{
  'avoid_exercises': instance.avoidExercises,
  'avoid_muscles': instance.avoidMuscles,
  'reduce_intensity': instance.reduceIntensity,
  'intensity_reduction_percent': instance.intensityReductionPercent,
  'max_pain_level_allowed': instance.maxPainLevelAllowed,
  'active_injuries': instance.activeInjuries,
  'recommendations': instance.recommendations,
};

InjuryCheckIn _$InjuryCheckInFromJson(Map<String, dynamic> json) =>
    InjuryCheckIn(
      id: json['id'] as String,
      injuryId: json['injury_id'] as String,
      painLevel: (json['pain_level'] as num).toInt(),
      mobilityRating: (json['mobility_rating'] as num?)?.toInt(),
      canWorkout: json['can_workout'] as bool,
      notes: json['notes'] as String?,
      checkedInAt: DateTime.parse(json['checked_in_at'] as String),
    );

Map<String, dynamic> _$InjuryCheckInToJson(InjuryCheckIn instance) =>
    <String, dynamic>{
      'id': instance.id,
      'injury_id': instance.injuryId,
      'pain_level': instance.painLevel,
      'mobility_rating': instance.mobilityRating,
      'can_workout': instance.canWorkout,
      'notes': instance.notes,
      'checked_in_at': instance.checkedInAt.toIso8601String(),
    };
