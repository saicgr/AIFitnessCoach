import 'package:json_annotation/json_annotation.dart';

part 'injury.g.dart';

/// Severity levels for injuries
enum InjurySeverity {
  @JsonValue('mild')
  mild,
  @JsonValue('moderate')
  moderate,
  @JsonValue('severe')
  severe,
}

/// Status of an injury
enum InjuryStatus {
  @JsonValue('active')
  active,
  @JsonValue('recovering')
  recovering,
  @JsonValue('healed')
  healed,
}

/// Recovery phases for injuries
enum RecoveryPhase {
  @JsonValue('acute')
  acute,
  @JsonValue('subacute')
  subacute,
  @JsonValue('remodeling')
  remodeling,
  @JsonValue('return_to_activity')
  returnToActivity,
  @JsonValue('healed')
  healed,
}

/// Types of injuries
enum InjuryType {
  @JsonValue('strain')
  strain,
  @JsonValue('sprain')
  sprain,
  @JsonValue('tendinitis')
  tendinitis,
  @JsonValue('bursitis')
  bursitis,
  @JsonValue('fracture')
  fracture,
  @JsonValue('dislocation')
  dislocation,
  @JsonValue('contusion')
  contusion,
  @JsonValue('tear')
  tear,
  @JsonValue('overuse')
  overuse,
  @JsonValue('other')
  other,
}

/// Body parts that can be injured
class BodyPart {
  final String id;
  final String name;
  final String icon;
  final List<String> relatedMuscles;
  final List<String> relatedExercises;

  const BodyPart({
    required this.id,
    required this.name,
    required this.icon,
    this.relatedMuscles = const [],
    this.relatedExercises = const [],
  });

  /// Common body parts for injury tracking
  static const List<BodyPart> commonBodyParts = [
    BodyPart(
      id: 'shoulder',
      name: 'Shoulder',
      icon: 'shoulder',
      relatedMuscles: ['deltoid', 'rotator_cuff', 'trapezius'],
      relatedExercises: ['overhead_press', 'lateral_raise', 'bench_press'],
    ),
    BodyPart(
      id: 'back',
      name: 'Back',
      icon: 'back',
      relatedMuscles: ['lats', 'rhomboids', 'erector_spinae', 'trapezius'],
      relatedExercises: ['deadlift', 'row', 'pull_up', 'lat_pulldown'],
    ),
    BodyPart(
      id: 'lower_back',
      name: 'Lower Back',
      icon: 'lower_back',
      relatedMuscles: ['erector_spinae', 'quadratus_lumborum'],
      relatedExercises: ['deadlift', 'squat', 'good_morning'],
    ),
    BodyPart(
      id: 'knee',
      name: 'Knee',
      icon: 'knee',
      relatedMuscles: ['quadriceps', 'hamstrings'],
      relatedExercises: ['squat', 'lunge', 'leg_press', 'leg_extension'],
    ),
    BodyPart(
      id: 'hip',
      name: 'Hip',
      icon: 'hip',
      relatedMuscles: ['hip_flexors', 'glutes', 'adductors'],
      relatedExercises: ['squat', 'deadlift', 'hip_thrust', 'lunge'],
    ),
    BodyPart(
      id: 'ankle',
      name: 'Ankle',
      icon: 'ankle',
      relatedMuscles: ['calves', 'tibialis_anterior'],
      relatedExercises: ['calf_raise', 'squat', 'running'],
    ),
    BodyPart(
      id: 'elbow',
      name: 'Elbow',
      icon: 'elbow',
      relatedMuscles: ['biceps', 'triceps', 'forearm'],
      relatedExercises: ['curl', 'tricep_extension', 'push_up'],
    ),
    BodyPart(
      id: 'wrist',
      name: 'Wrist',
      icon: 'wrist',
      relatedMuscles: ['forearm'],
      relatedExercises: ['wrist_curl', 'push_up', 'deadlift'],
    ),
    BodyPart(
      id: 'neck',
      name: 'Neck',
      icon: 'neck',
      relatedMuscles: ['trapezius', 'sternocleidomastoid'],
      relatedExercises: ['shrug', 'overhead_press'],
    ),
    BodyPart(
      id: 'calf',
      name: 'Calf',
      icon: 'calf',
      relatedMuscles: ['gastrocnemius', 'soleus'],
      relatedExercises: ['calf_raise', 'running', 'jumping'],
    ),
    BodyPart(
      id: 'chest',
      name: 'Chest',
      icon: 'chest',
      relatedMuscles: ['pectoralis_major', 'pectoralis_minor'],
      relatedExercises: ['bench_press', 'push_up', 'fly'],
    ),
    BodyPart(
      id: 'hamstring',
      name: 'Hamstring',
      icon: 'hamstring',
      relatedMuscles: ['biceps_femoris', 'semitendinosus', 'semimembranosus'],
      relatedExercises: ['deadlift', 'leg_curl', 'good_morning'],
    ),
    BodyPart(
      id: 'quadriceps',
      name: 'Quadriceps',
      icon: 'quadriceps',
      relatedMuscles: ['rectus_femoris', 'vastus_lateralis', 'vastus_medialis'],
      relatedExercises: ['squat', 'leg_press', 'leg_extension'],
    ),
    BodyPart(
      id: 'other',
      name: 'Other',
      icon: 'other',
      relatedMuscles: [],
      relatedExercises: [],
    ),
  ];

  /// Get a body part by ID
  static BodyPart? getById(String id) {
    try {
      return commonBodyParts.firstWhere((bp) => bp.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// A rehab exercise assigned to help recover from an injury
@JsonSerializable()
class RehabExercise {
  @JsonKey(name: 'exercise_name')
  final String exerciseName;
  @JsonKey(name: 'exercise_type')
  final String exerciseType;
  final int? sets;
  final int? reps;
  @JsonKey(name: 'hold_seconds')
  final int? holdSeconds;
  @JsonKey(name: 'frequency_per_day')
  final int frequencyPerDay;
  final String? notes;
  @JsonKey(name: 'video_url')
  final String? videoUrl;
  @JsonKey(name: 'is_completed')
  final bool isCompleted;

  const RehabExercise({
    required this.exerciseName,
    required this.exerciseType,
    this.sets,
    this.reps,
    this.holdSeconds,
    required this.frequencyPerDay,
    this.notes,
    this.videoUrl,
    this.isCompleted = false,
  });

  factory RehabExercise.fromJson(Map<String, dynamic> json) =>
      _$RehabExerciseFromJson(json);
  Map<String, dynamic> toJson() => _$RehabExerciseToJson(this);

  /// Get formatted prescription text
  String get prescriptionText {
    if (holdSeconds != null) {
      return '${sets ?? 3} x ${holdSeconds}s hold';
    }
    if (reps != null) {
      return '${sets ?? 3} x $reps reps';
    }
    return '${sets ?? 3} sets';
  }

  /// Get frequency display text
  String get frequencyText {
    if (frequencyPerDay == 1) return 'Once daily';
    if (frequencyPerDay == 2) return 'Twice daily';
    return '$frequencyPerDay times daily';
  }

  RehabExercise copyWith({
    String? exerciseName,
    String? exerciseType,
    int? sets,
    int? reps,
    int? holdSeconds,
    int? frequencyPerDay,
    String? notes,
    String? videoUrl,
    bool? isCompleted,
  }) {
    return RehabExercise(
      exerciseName: exerciseName ?? this.exerciseName,
      exerciseType: exerciseType ?? this.exerciseType,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      holdSeconds: holdSeconds ?? this.holdSeconds,
      frequencyPerDay: frequencyPerDay ?? this.frequencyPerDay,
      notes: notes ?? this.notes,
      videoUrl: videoUrl ?? this.videoUrl,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// An injury record with recovery tracking
@JsonSerializable()
class Injury {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'body_part')
  final String bodyPart;
  @JsonKey(name: 'injury_type')
  final String? injuryType;
  final String severity;
  @JsonKey(name: 'reported_at')
  final DateTime reportedAt;
  @JsonKey(name: 'occurred_at')
  final DateTime? occurredAt;
  @JsonKey(name: 'expected_recovery_date')
  final DateTime? expectedRecoveryDate;
  @JsonKey(name: 'actual_recovery_date')
  final DateTime? actualRecoveryDate;
  @JsonKey(name: 'recovery_phase')
  final String recoveryPhase;
  @JsonKey(name: 'pain_level')
  final int? painLevel;
  @JsonKey(name: 'affects_exercises')
  final List<String> affectsExercises;
  @JsonKey(name: 'affects_muscles')
  final List<String> affectsMuscles;
  final String? notes;
  final String status;
  @JsonKey(name: 'rehab_exercises')
  final List<RehabExercise>? rehabExercises;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const Injury({
    required this.id,
    required this.userId,
    required this.bodyPart,
    this.injuryType,
    required this.severity,
    required this.reportedAt,
    this.occurredAt,
    this.expectedRecoveryDate,
    this.actualRecoveryDate,
    required this.recoveryPhase,
    this.painLevel,
    required this.affectsExercises,
    required this.affectsMuscles,
    this.notes,
    required this.status,
    this.rehabExercises,
    this.createdAt,
    this.updatedAt,
  });

  factory Injury.fromJson(Map<String, dynamic> json) => _$InjuryFromJson(json);
  Map<String, dynamic> toJson() => _$InjuryToJson(this);

  /// Get days since injury was reported
  int get daysSinceReported {
    return DateTime.now().difference(reportedAt).inDays;
  }

  /// Get days until expected recovery
  int? get daysUntilRecovery {
    if (expectedRecoveryDate == null) return null;
    final days = expectedRecoveryDate!.difference(DateTime.now()).inDays;
    return days < 0 ? 0 : days;
  }

  /// Get recovery progress as a percentage (0-100)
  double get recoveryProgress {
    if (status == 'healed') return 100;
    if (expectedRecoveryDate == null) return 0;

    final totalDays = expectedRecoveryDate!.difference(reportedAt).inDays;
    if (totalDays <= 0) return 0;

    final elapsedDays = DateTime.now().difference(reportedAt).inDays;
    final progress = (elapsedDays / totalDays) * 100;
    return progress.clamp(0, 100);
  }

  /// Get body part display name
  String get bodyPartDisplay {
    final bp = BodyPart.getById(bodyPart);
    if (bp != null) return bp.name;
    return bodyPart
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  /// Get severity display with color info
  String get severityDisplay {
    switch (severity.toLowerCase()) {
      case 'mild':
        return 'Mild';
      case 'moderate':
        return 'Moderate';
      case 'severe':
        return 'Severe';
      default:
        return severity;
    }
  }

  /// Get severity color hex
  String get severityColorHex {
    switch (severity.toLowerCase()) {
      case 'mild':
        return '#22C55E'; // Green
      case 'moderate':
        return '#F59E0B'; // Amber
      case 'severe':
        return '#EF4444'; // Red
      default:
        return '#71717A'; // Grey
    }
  }

  /// Get recovery phase display
  String get recoveryPhaseDisplay {
    switch (recoveryPhase.toLowerCase()) {
      case 'acute':
        return 'Acute Phase';
      case 'subacute':
        return 'Subacute Phase';
      case 'remodeling':
        return 'Remodeling Phase';
      case 'return_to_activity':
        return 'Return to Activity';
      case 'healed':
        return 'Healed';
      default:
        return recoveryPhase;
    }
  }

  /// Check if this is an active injury
  bool get isActive =>
      status.toLowerCase() == 'active' || status.toLowerCase() == 'recovering';

  Injury copyWith({
    String? id,
    String? userId,
    String? bodyPart,
    String? injuryType,
    String? severity,
    DateTime? reportedAt,
    DateTime? occurredAt,
    DateTime? expectedRecoveryDate,
    DateTime? actualRecoveryDate,
    String? recoveryPhase,
    int? painLevel,
    List<String>? affectsExercises,
    List<String>? affectsMuscles,
    String? notes,
    String? status,
    List<RehabExercise>? rehabExercises,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Injury(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bodyPart: bodyPart ?? this.bodyPart,
      injuryType: injuryType ?? this.injuryType,
      severity: severity ?? this.severity,
      reportedAt: reportedAt ?? this.reportedAt,
      occurredAt: occurredAt ?? this.occurredAt,
      expectedRecoveryDate: expectedRecoveryDate ?? this.expectedRecoveryDate,
      actualRecoveryDate: actualRecoveryDate ?? this.actualRecoveryDate,
      recoveryPhase: recoveryPhase ?? this.recoveryPhase,
      painLevel: painLevel ?? this.painLevel,
      affectsExercises: affectsExercises ?? this.affectsExercises,
      affectsMuscles: affectsMuscles ?? this.affectsMuscles,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      rehabExercises: rehabExercises ?? this.rehabExercises,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Request model for reporting a new injury
@JsonSerializable()
class InjuryReportRequest {
  @JsonKey(name: 'body_part')
  final String bodyPart;
  @JsonKey(name: 'injury_type')
  final String? injuryType;
  final String severity;
  @JsonKey(name: 'pain_level')
  final int? painLevel;
  @JsonKey(name: 'occurred_at')
  final DateTime? occurredAt;
  final String? notes;

  const InjuryReportRequest({
    required this.bodyPart,
    this.injuryType,
    required this.severity,
    this.painLevel,
    this.occurredAt,
    this.notes,
  });

  factory InjuryReportRequest.fromJson(Map<String, dynamic> json) =>
      _$InjuryReportRequestFromJson(json);
  Map<String, dynamic> toJson() => _$InjuryReportRequestToJson(this);
}

/// Response from reporting a new injury
@JsonSerializable()
class InjuryReportResponse {
  final bool success;
  final String message;
  final Injury injury;
  @JsonKey(name: 'expected_recovery_days')
  final int? expectedRecoveryDays;
  @JsonKey(name: 'workout_modifications')
  final List<String>? workoutModifications;

  const InjuryReportResponse({
    required this.success,
    required this.message,
    required this.injury,
    this.expectedRecoveryDays,
    this.workoutModifications,
  });

  factory InjuryReportResponse.fromJson(Map<String, dynamic> json) =>
      _$InjuryReportResponseFromJson(json);
  Map<String, dynamic> toJson() => _$InjuryReportResponseToJson(this);
}

/// Request model for updating an injury status
@JsonSerializable()
class InjuryUpdateRequest {
  @JsonKey(name: 'pain_level')
  final int? painLevel;
  @JsonKey(name: 'mobility_rating')
  final int? mobilityRating;
  @JsonKey(name: 'can_workout')
  final bool? canWorkout;
  final String? notes;
  @JsonKey(name: 'recovery_phase')
  final String? recoveryPhase;

  const InjuryUpdateRequest({
    this.painLevel,
    this.mobilityRating,
    this.canWorkout,
    this.notes,
    this.recoveryPhase,
  });

  factory InjuryUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$InjuryUpdateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$InjuryUpdateRequestToJson(this);
}

/// Response from updating an injury
@JsonSerializable()
class InjuryUpdateResponse {
  final bool success;
  final String message;
  final Injury injury;
  @JsonKey(name: 'phase_changed')
  final bool? phaseChanged;
  @JsonKey(name: 'new_phase')
  final String? newPhase;

  const InjuryUpdateResponse({
    required this.success,
    required this.message,
    required this.injury,
    this.phaseChanged,
    this.newPhase,
  });

  factory InjuryUpdateResponse.fromJson(Map<String, dynamic> json) =>
      _$InjuryUpdateResponseFromJson(json);
  Map<String, dynamic> toJson() => _$InjuryUpdateResponseToJson(this);
}

/// Workout modifications based on active injuries
@JsonSerializable()
class WorkoutModifications {
  @JsonKey(name: 'avoid_exercises')
  final List<String> avoidExercises;
  @JsonKey(name: 'avoid_muscles')
  final List<String> avoidMuscles;
  @JsonKey(name: 'reduce_intensity')
  final bool reduceIntensity;
  @JsonKey(name: 'intensity_reduction_percent')
  final int? intensityReductionPercent;
  @JsonKey(name: 'max_pain_level_allowed')
  final int maxPainLevelAllowed;
  @JsonKey(name: 'active_injuries')
  final List<String> activeInjuries;
  final List<String> recommendations;

  const WorkoutModifications({
    required this.avoidExercises,
    required this.avoidMuscles,
    this.reduceIntensity = false,
    this.intensityReductionPercent,
    this.maxPainLevelAllowed = 3,
    required this.activeInjuries,
    this.recommendations = const [],
  });

  factory WorkoutModifications.fromJson(Map<String, dynamic> json) =>
      _$WorkoutModificationsFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutModificationsToJson(this);

  /// Check if any modifications are active
  bool get hasModifications =>
      avoidExercises.isNotEmpty || avoidMuscles.isNotEmpty || reduceIntensity;
}

/// Injury check-in history entry
@JsonSerializable()
class InjuryCheckIn {
  final String id;
  @JsonKey(name: 'injury_id')
  final String injuryId;
  @JsonKey(name: 'pain_level')
  final int painLevel;
  @JsonKey(name: 'mobility_rating')
  final int? mobilityRating;
  @JsonKey(name: 'can_workout')
  final bool canWorkout;
  final String? notes;
  @JsonKey(name: 'checked_in_at')
  final DateTime checkedInAt;

  const InjuryCheckIn({
    required this.id,
    required this.injuryId,
    required this.painLevel,
    this.mobilityRating,
    required this.canWorkout,
    this.notes,
    required this.checkedInAt,
  });

  factory InjuryCheckIn.fromJson(Map<String, dynamic> json) =>
      _$InjuryCheckInFromJson(json);
  Map<String, dynamic> toJson() => _$InjuryCheckInToJson(this);
}
