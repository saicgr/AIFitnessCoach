// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'neat_goal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NeatGoal _$NeatGoalFromJson(Map<String, dynamic> json) => NeatGoal(
  id: json['id'] as String?,
  userId: json['user_id'] as String,
  currentStepGoal: (json['current_step_goal'] as num).toInt(),
  baselineSteps: (json['baseline_steps'] as num?)?.toInt() ?? 0,
  goalIncrement: (json['goal_increment'] as num?)?.toInt() ?? 500,
  goalType:
      $enumDecodeNullable(_$NeatGoalTypeEnumMap, json['goal_type']) ??
      NeatGoalType.steps,
  stepsToday: (json['steps_today'] as num?)?.toInt() ?? 0,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$NeatGoalToJson(NeatGoal instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'current_step_goal': instance.currentStepGoal,
  'baseline_steps': instance.baselineSteps,
  'goal_increment': instance.goalIncrement,
  'goal_type': _$NeatGoalTypeEnumMap[instance.goalType]!,
  'steps_today': instance.stepsToday,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};

const _$NeatGoalTypeEnumMap = {
  NeatGoalType.steps: 'steps',
  NeatGoalType.activeHours: 'active_hours',
  NeatGoalType.neatScore: 'neat_score',
};

NeatGoalUpdateResponse _$NeatGoalUpdateResponseFromJson(
  Map<String, dynamic> json,
) => NeatGoalUpdateResponse(
  success: json['success'] as bool? ?? false,
  goal: json['goal'] == null
      ? null
      : NeatGoal.fromJson(json['goal'] as Map<String, dynamic>),
  message: json['message'] as String?,
  goalIncreased: json['goal_increased'] as bool? ?? false,
  newGoal: (json['new_goal'] as num?)?.toInt(),
);

Map<String, dynamic> _$NeatGoalUpdateResponseToJson(
  NeatGoalUpdateResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'goal': instance.goal,
  'message': instance.message,
  'goal_increased': instance.goalIncreased,
  'new_goal': instance.newGoal,
};
