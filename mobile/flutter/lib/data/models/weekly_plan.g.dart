// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FoodItem _$FoodItemFromJson(Map<String, dynamic> json) => FoodItem(
  name: json['name'] as String,
  amount: json['amount'] as String,
  calories: (json['calories'] as num).toInt(),
  proteinG: (json['protein_g'] as num).toDouble(),
  carbsG: (json['carbs_g'] as num).toDouble(),
  fatG: (json['fat_g'] as num).toDouble(),
);

Map<String, dynamic> _$FoodItemToJson(FoodItem instance) => <String, dynamic>{
  'name': instance.name,
  'amount': instance.amount,
  'calories': instance.calories,
  'protein_g': instance.proteinG,
  'carbs_g': instance.carbsG,
  'fat_g': instance.fatG,
};

MealSuggestion _$MealSuggestionFromJson(Map<String, dynamic> json) =>
    MealSuggestion(
      mealType: json['meal_type'] as String,
      suggestedTime: json['suggested_time'] as String,
      foods: (json['foods'] as List<dynamic>)
          .map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCalories: (json['total_calories'] as num?)?.toInt(),
      totalProteinG: (json['total_protein_g'] as num?)?.toDouble(),
      totalCarbsG: (json['total_carbs_g'] as num?)?.toDouble(),
      totalFatG: (json['total_fat_g'] as num?)?.toDouble(),
      prepTimeMinutes: (json['prep_time_minutes'] as num?)?.toInt(),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$MealSuggestionToJson(MealSuggestion instance) =>
    <String, dynamic>{
      'meal_type': instance.mealType,
      'suggested_time': instance.suggestedTime,
      'foods': instance.foods,
      'total_calories': instance.totalCalories,
      'total_protein_g': instance.totalProteinG,
      'total_carbs_g': instance.totalCarbsG,
      'total_fat_g': instance.totalFatG,
      'prep_time_minutes': instance.prepTimeMinutes,
      'notes': instance.notes,
    };

CoordinationNote _$CoordinationNoteFromJson(Map<String, dynamic> json) =>
    CoordinationNote(
      type: json['type'] as String,
      message: json['message'] as String,
      severity: json['severity'] as String?,
      suggestion: json['suggestion'] as String?,
    );

Map<String, dynamic> _$CoordinationNoteToJson(CoordinationNote instance) =>
    <String, dynamic>{
      'type': instance.type,
      'message': instance.message,
      'severity': instance.severity,
      'suggestion': instance.suggestion,
    };

DailyPlanEntry _$DailyPlanEntryFromJson(Map<String, dynamic> json) =>
    DailyPlanEntry(
      id: json['id'] as String,
      weeklyPlanId: json['weekly_plan_id'] as String,
      planDate: DateTime.parse(json['plan_date'] as String),
      dayType: $enumDecode(_$DayTypeEnumMap, json['day_type']),
      workoutId: json['workout_id'] as String?,
      workoutTime: json['workout_time'] as String?,
      workoutFocus: json['workout_focus'] as String?,
      workoutDurationMinutes: (json['workout_duration_minutes'] as num?)
          ?.toInt(),
      calorieTarget: (json['calorie_target'] as num).toInt(),
      proteinTargetG: (json['protein_target_g'] as num).toDouble(),
      carbsTargetG: (json['carbs_target_g'] as num).toDouble(),
      fatTargetG: (json['fat_target_g'] as num).toDouble(),
      fiberTargetG: (json['fiber_target_g'] as num?)?.toDouble(),
      fastingStartTime: json['fasting_start_time'] as String?,
      eatingWindowStart: json['eating_window_start'] as String?,
      eatingWindowEnd: json['eating_window_end'] as String?,
      fastingProtocol: json['fasting_protocol'] as String?,
      fastingDurationHours: (json['fasting_duration_hours'] as num?)?.toInt(),
      mealSuggestions:
          (json['meal_suggestions'] as List<dynamic>?)
              ?.map((e) => MealSuggestion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      coordinationNotes:
          (json['coordination_notes'] as List<dynamic>?)
              ?.map((e) => CoordinationNote.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      nutritionLogged: json['nutrition_logged'] as bool? ?? false,
      workoutCompleted: json['workout_completed'] as bool? ?? false,
      fastingCompleted: json['fasting_completed'] as bool? ?? false,
    );

Map<String, dynamic> _$DailyPlanEntryToJson(DailyPlanEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'weekly_plan_id': instance.weeklyPlanId,
      'plan_date': instance.planDate.toIso8601String(),
      'day_type': _$DayTypeEnumMap[instance.dayType]!,
      'workout_id': instance.workoutId,
      'workout_time': instance.workoutTime,
      'workout_focus': instance.workoutFocus,
      'workout_duration_minutes': instance.workoutDurationMinutes,
      'calorie_target': instance.calorieTarget,
      'protein_target_g': instance.proteinTargetG,
      'carbs_target_g': instance.carbsTargetG,
      'fat_target_g': instance.fatTargetG,
      'fiber_target_g': instance.fiberTargetG,
      'fasting_start_time': instance.fastingStartTime,
      'eating_window_start': instance.eatingWindowStart,
      'eating_window_end': instance.eatingWindowEnd,
      'fasting_protocol': instance.fastingProtocol,
      'fasting_duration_hours': instance.fastingDurationHours,
      'meal_suggestions': instance.mealSuggestions,
      'coordination_notes': instance.coordinationNotes,
      'nutrition_logged': instance.nutritionLogged,
      'workout_completed': instance.workoutCompleted,
      'fasting_completed': instance.fastingCompleted,
    };

const _$DayTypeEnumMap = {
  DayType.training: 'training',
  DayType.rest: 'rest',
  DayType.activeRecovery: 'active_recovery',
};

WeeklyPlan _$WeeklyPlanFromJson(Map<String, dynamic> json) => WeeklyPlan(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  weekStartDate: DateTime.parse(json['week_start_date'] as String),
  status: json['status'] as String,
  workoutDays: (json['workout_days'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  fastingProtocol: json['fasting_protocol'] as String?,
  nutritionStrategy: json['nutrition_strategy'] as String,
  baseCalorieTarget: (json['base_calorie_target'] as num?)?.toInt(),
  baseProteinTargetG: (json['base_protein_target_g'] as num?)?.toDouble(),
  baseCarbsTargetG: (json['base_carbs_target_g'] as num?)?.toDouble(),
  baseFatTargetG: (json['base_fat_target_g'] as num?)?.toDouble(),
  generatedAt: json['generated_at'] == null
      ? null
      : DateTime.parse(json['generated_at'] as String),
  aiModelUsed: json['ai_model_used'] as String?,
  dailyEntries:
      (json['daily_entries'] as List<dynamic>?)
          ?.map((e) => DailyPlanEntry.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$WeeklyPlanToJson(WeeklyPlan instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'week_start_date': instance.weekStartDate.toIso8601String(),
      'status': instance.status,
      'workout_days': instance.workoutDays,
      'fasting_protocol': instance.fastingProtocol,
      'nutrition_strategy': instance.nutritionStrategy,
      'base_calorie_target': instance.baseCalorieTarget,
      'base_protein_target_g': instance.baseProteinTargetG,
      'base_carbs_target_g': instance.baseCarbsTargetG,
      'base_fat_target_g': instance.baseFatTargetG,
      'generated_at': instance.generatedAt?.toIso8601String(),
      'ai_model_used': instance.aiModelUsed,
      'daily_entries': instance.dailyEntries,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

GenerateWeeklyPlanRequest _$GenerateWeeklyPlanRequestFromJson(
  Map<String, dynamic> json,
) => GenerateWeeklyPlanRequest(
  workoutDays: (json['workout_days'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  fastingProtocol: json['fasting_protocol'] as String?,
  nutritionStrategy: json['nutrition_strategy'] as String,
  preferredWorkoutTime: json['preferred_workout_time'] as String?,
  goals: (json['goals'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

Map<String, dynamic> _$GenerateWeeklyPlanRequestToJson(
  GenerateWeeklyPlanRequest instance,
) => <String, dynamic>{
  'workout_days': instance.workoutDays,
  'fasting_protocol': instance.fastingProtocol,
  'nutrition_strategy': instance.nutritionStrategy,
  'preferred_workout_time': instance.preferredWorkoutTime,
  'goals': instance.goals,
};

GenerateMealSuggestionsRequest _$GenerateMealSuggestionsRequestFromJson(
  Map<String, dynamic> json,
) => GenerateMealSuggestionsRequest(
  planDate: json['plan_date'] as String,
  dayType: json['day_type'] as String,
  calorieTarget: (json['calorie_target'] as num).toInt(),
  proteinTargetG: (json['protein_target_g'] as num).toDouble(),
  eatingWindowStart: json['eating_window_start'] as String?,
  eatingWindowEnd: json['eating_window_end'] as String?,
  workoutTime: json['workout_time'] as String?,
);

Map<String, dynamic> _$GenerateMealSuggestionsRequestToJson(
  GenerateMealSuggestionsRequest instance,
) => <String, dynamic>{
  'plan_date': instance.planDate,
  'day_type': instance.dayType,
  'calorie_target': instance.calorieTarget,
  'protein_target_g': instance.proteinTargetG,
  'eating_window_start': instance.eatingWindowStart,
  'eating_window_end': instance.eatingWindowEnd,
  'workout_time': instance.workoutTime,
};
