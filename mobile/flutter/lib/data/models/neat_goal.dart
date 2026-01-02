/// NEAT (Non-Exercise Activity Thermogenesis) goal models.
///
/// These models support:
/// - User step goals and baselines
/// - Progressive goal increments
/// - Daily progress tracking
/// - Goal type customization
library;

import 'package:json_annotation/json_annotation.dart';

part 'neat_goal.g.dart';

/// Type of NEAT goal the user is pursuing
enum NeatGoalType {
  @JsonValue('steps')
  steps,
  @JsonValue('active_hours')
  activeHours,
  @JsonValue('neat_score')
  neatScore;

  String get displayName {
    switch (this) {
      case NeatGoalType.steps:
        return 'Daily Steps';
      case NeatGoalType.activeHours:
        return 'Active Hours';
      case NeatGoalType.neatScore:
        return 'NEAT Score';
    }
  }

  String get icon {
    switch (this) {
      case NeatGoalType.steps:
        return 'directions_walk';
      case NeatGoalType.activeHours:
        return 'schedule';
      case NeatGoalType.neatScore:
        return 'trending_up';
    }
  }
}

/// User's NEAT goal configuration and progress
@JsonSerializable()
class NeatGoal {
  final String? id;

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'current_step_goal')
  final int currentStepGoal;

  @JsonKey(name: 'baseline_steps')
  final int baselineSteps;

  @JsonKey(name: 'goal_increment')
  final int goalIncrement;

  @JsonKey(name: 'goal_type')
  final NeatGoalType goalType;

  @JsonKey(name: 'steps_today')
  final int stepsToday;

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const NeatGoal({
    this.id,
    required this.userId,
    required this.currentStepGoal,
    this.baselineSteps = 0,
    this.goalIncrement = 500,
    this.goalType = NeatGoalType.steps,
    this.stepsToday = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory NeatGoal.fromJson(Map<String, dynamic> json) =>
      _$NeatGoalFromJson(json);

  Map<String, dynamic> toJson() => _$NeatGoalToJson(this);

  /// Progress as a value between 0 and 1
  double get progress {
    if (currentStepGoal <= 0) return 0.0;
    return (stepsToday / currentStepGoal).clamp(0.0, 1.0);
  }

  /// Progress as a percentage (0-100)
  double get progressPercentage => progress * 100;

  /// Whether the goal has been achieved today
  bool get isGoalAchieved => stepsToday >= currentStepGoal;

  /// Steps remaining to reach goal
  int get stepsRemaining {
    final remaining = currentStepGoal - stepsToday;
    return remaining > 0 ? remaining : 0;
  }

  /// Formatted progress text
  String get progressText => '${stepsToday.formatted}/${currentStepGoal.formatted}';

  /// Get the next goal after increment
  int get nextGoal => currentStepGoal + goalIncrement;

  /// Calculate improvement percentage from baseline
  double get improvementFromBaseline {
    if (baselineSteps <= 0) return 0.0;
    return ((currentStepGoal - baselineSteps) / baselineSteps) * 100;
  }

  /// Create a copy with updated values
  NeatGoal copyWith({
    String? id,
    String? userId,
    int? currentStepGoal,
    int? baselineSteps,
    int? goalIncrement,
    NeatGoalType? goalType,
    int? stepsToday,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NeatGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      currentStepGoal: currentStepGoal ?? this.currentStepGoal,
      baselineSteps: baselineSteps ?? this.baselineSteps,
      goalIncrement: goalIncrement ?? this.goalIncrement,
      goalType: goalType ?? this.goalType,
      stepsToday: stepsToday ?? this.stepsToday,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Extension for number formatting
extension _IntFormatting on int {
  String get formatted {
    if (this >= 1000) {
      return '${(this / 1000).toStringAsFixed(1)}k';
    }
    return toString();
  }
}

/// Response from goal update API
@JsonSerializable()
class NeatGoalUpdateResponse {
  final bool success;
  final NeatGoal? goal;
  final String? message;
  @JsonKey(name: 'goal_increased')
  final bool goalIncreased;
  @JsonKey(name: 'new_goal')
  final int? newGoal;

  const NeatGoalUpdateResponse({
    this.success = false,
    this.goal,
    this.message,
    this.goalIncreased = false,
    this.newGoal,
  });

  factory NeatGoalUpdateResponse.fromJson(Map<String, dynamic> json) =>
      _$NeatGoalUpdateResponseFromJson(json);

  Map<String, dynamic> toJson() => _$NeatGoalUpdateResponseToJson(this);
}
