import 'package:json_annotation/json_annotation.dart';

part 'skill_progression.g.dart';

/// A chain of exercises that progressively build toward a skill
@JsonSerializable()
class ProgressionChain {
  final String id;
  final String name;
  final String description;
  final String category;
  final String? icon;
  @JsonKey(name: 'difficulty_start')
  final int difficultyStart;
  @JsonKey(name: 'difficulty_end')
  final int difficultyEnd;
  @JsonKey(name: 'estimated_weeks')
  final int? estimatedWeeks;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  final List<ProgressionStep>? steps;

  const ProgressionChain({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.icon,
    this.difficultyStart = 1,
    this.difficultyEnd = 10,
    this.estimatedWeeks,
    this.createdAt,
    this.updatedAt,
    this.steps,
  });

  factory ProgressionChain.fromJson(Map<String, dynamic> json) =>
      _$ProgressionChainFromJson(json);
  Map<String, dynamic> toJson() => _$ProgressionChainToJson(this);

  /// Get progression percentage based on current step
  double getProgressPercentage(int currentStepOrder) {
    final totalSteps = steps?.length ?? 1;
    if (totalSteps == 0) return 0;
    return (currentStepOrder / totalSteps).clamp(0.0, 1.0);
  }

  /// Get current step from order
  ProgressionStep? getStepByOrder(int order) {
    return steps?.firstWhere(
      (s) => s.stepOrder == order,
      orElse: () => steps!.first,
    );
  }
}

/// A single step/exercise in a progression chain
@JsonSerializable()
class ProgressionStep {
  final String id;
  @JsonKey(name: 'chain_id')
  final String chainId;
  @JsonKey(name: 'exercise_name')
  final String exerciseName;
  @JsonKey(name: 'exercise_id')
  final String? exerciseId;
  @JsonKey(name: 'step_order')
  final int stepOrder;
  @JsonKey(name: 'difficulty_level')
  final int difficultyLevel;
  final String? prerequisites;
  @JsonKey(name: 'unlock_criteria')
  final Map<String, dynamic>? unlockCriteria;
  final String? tips;
  @JsonKey(name: 'video_url')
  final String? videoUrl;
  @JsonKey(name: 'thumbnail_url')
  final String? thumbnailUrl;
  @JsonKey(name: 'target_reps')
  final int? targetReps;
  @JsonKey(name: 'target_sets')
  final int? targetSets;
  @JsonKey(name: 'target_hold_seconds')
  final int? targetHoldSeconds;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  const ProgressionStep({
    required this.id,
    required this.chainId,
    required this.exerciseName,
    this.exerciseId,
    required this.stepOrder,
    required this.difficultyLevel,
    this.prerequisites,
    this.unlockCriteria,
    this.tips,
    this.videoUrl,
    this.thumbnailUrl,
    this.targetReps,
    this.targetSets,
    this.targetHoldSeconds,
    this.createdAt,
  });

  factory ProgressionStep.fromJson(Map<String, dynamic> json) =>
      _$ProgressionStepFromJson(json);
  Map<String, dynamic> toJson() => _$ProgressionStepToJson(this);

  /// Get difficulty label
  String get difficultyLabel {
    if (difficultyLevel <= 2) return 'Beginner';
    if (difficultyLevel <= 4) return 'Easy';
    if (difficultyLevel <= 6) return 'Intermediate';
    if (difficultyLevel <= 8) return 'Advanced';
    return 'Expert';
  }

  /// Get unlock criteria display text
  String get unlockCriteriaText {
    if (unlockCriteria == null) return 'No criteria';
    final reps = unlockCriteria!['min_reps'] as int?;
    final sets = unlockCriteria!['min_sets'] as int?;
    final holdSeconds = unlockCriteria!['min_hold_seconds'] as int?;

    final parts = <String>[];
    if (reps != null && sets != null) {
      parts.add('$sets x $reps reps');
    } else if (reps != null) {
      parts.add('$reps reps');
    }
    if (holdSeconds != null) {
      parts.add('${holdSeconds}s hold');
    }
    return parts.isEmpty ? 'Complete exercise' : parts.join(' or ');
  }
}

/// User's progress in a specific progression chain
@JsonSerializable()
class UserSkillProgress {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'chain_id')
  final String chainId;
  @JsonKey(name: 'current_step_order')
  final int currentStepOrder;
  @JsonKey(name: 'unlocked_steps')
  final List<int> unlockedSteps;
  @JsonKey(name: 'attempts_at_current')
  final int attemptsAtCurrent;
  @JsonKey(name: 'best_reps_at_current')
  final int bestRepsAtCurrent;
  @JsonKey(name: 'best_hold_seconds')
  final int? bestHoldSeconds;
  @JsonKey(name: 'last_practiced_at')
  final DateTime? lastPracticedAt;
  @JsonKey(name: 'started_at')
  final DateTime? startedAt;
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;
  final ProgressionChain? chain;

  const UserSkillProgress({
    required this.id,
    required this.userId,
    required this.chainId,
    this.currentStepOrder = 1,
    this.unlockedSteps = const [1],
    this.attemptsAtCurrent = 0,
    this.bestRepsAtCurrent = 0,
    this.bestHoldSeconds,
    this.lastPracticedAt,
    this.startedAt,
    this.completedAt,
    this.chain,
  });

  factory UserSkillProgress.fromJson(Map<String, dynamic> json) =>
      _$UserSkillProgressFromJson(json);
  Map<String, dynamic> toJson() => _$UserSkillProgressToJson(this);

  /// Check if a step is unlocked
  bool isStepUnlocked(int stepOrder) => unlockedSteps.contains(stepOrder);

  /// Check if chain is completed
  bool get isCompleted => completedAt != null;

  /// Get progress percentage
  double getProgressPercentage(int totalSteps) {
    if (totalSteps == 0) return 0;
    return (currentStepOrder / totalSteps).clamp(0.0, 1.0);
  }

  /// Get days since last practice
  int? get daysSinceLastPractice {
    if (lastPracticedAt == null) return null;
    return DateTime.now().difference(lastPracticedAt!).inDays;
  }
}

/// Attempt log for a progression step
@JsonSerializable()
class ProgressionAttempt {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'chain_id')
  final String chainId;
  @JsonKey(name: 'step_id')
  final String stepId;
  @JsonKey(name: 'step_order')
  final int stepOrder;
  @JsonKey(name: 'reps_completed')
  final int? repsCompleted;
  @JsonKey(name: 'sets_completed')
  final int? setsCompleted;
  @JsonKey(name: 'hold_seconds')
  final int? holdSeconds;
  @JsonKey(name: 'was_successful')
  final bool wasSuccessful;
  @JsonKey(name: 'unlocked_next')
  final bool unlockedNext;
  final String? notes;
  @JsonKey(name: 'attempted_at')
  final DateTime attemptedAt;

  const ProgressionAttempt({
    required this.id,
    required this.userId,
    required this.chainId,
    required this.stepId,
    required this.stepOrder,
    this.repsCompleted,
    this.setsCompleted,
    this.holdSeconds,
    this.wasSuccessful = false,
    this.unlockedNext = false,
    this.notes,
    required this.attemptedAt,
  });

  factory ProgressionAttempt.fromJson(Map<String, dynamic> json) =>
      _$ProgressionAttemptFromJson(json);
  Map<String, dynamic> toJson() => _$ProgressionAttemptToJson(this);
}

/// Summary of user's skill progression activity
@JsonSerializable()
class SkillProgressionSummary {
  @JsonKey(name: 'total_chains_started')
  final int totalChainsStarted;
  @JsonKey(name: 'total_chains_completed')
  final int totalChainsCompleted;
  @JsonKey(name: 'total_steps_unlocked')
  final int totalStepsUnlocked;
  @JsonKey(name: 'total_attempts')
  final int totalAttempts;
  @JsonKey(name: 'current_progressions')
  final List<UserSkillProgress> currentProgressions;
  @JsonKey(name: 'recently_practiced')
  final List<UserSkillProgress> recentlyPracticed;

  const SkillProgressionSummary({
    this.totalChainsStarted = 0,
    this.totalChainsCompleted = 0,
    this.totalStepsUnlocked = 0,
    this.totalAttempts = 0,
    this.currentProgressions = const [],
    this.recentlyPracticed = const [],
  });

  factory SkillProgressionSummary.fromJson(Map<String, dynamic> json) =>
      _$SkillProgressionSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$SkillProgressionSummaryToJson(this);
}
