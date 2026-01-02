// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hormonal_health.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HormonalProfile _$HormonalProfileFromJson(
  Map<String, dynamic> json,
) => HormonalProfile(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  gender: $enumDecodeNullable(_$GenderEnumMap, json['gender']),
  birthSex: $enumDecodeNullable(_$BirthSexEnumMap, json['birth_sex']),
  hormoneGoals:
      (json['hormone_goals'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$HormoneGoalEnumMap, e))
          .toList() ??
      const [],
  menstrualTrackingEnabled:
      json['menstrual_tracking_enabled'] as bool? ?? false,
  cycleLengthDays: (json['cycle_length_days'] as num?)?.toInt(),
  lastPeriodStartDate: json['last_period_start_date'] == null
      ? null
      : DateTime.parse(json['last_period_start_date'] as String),
  typicalPeriodDurationDays: (json['typical_period_duration_days'] as num?)
      ?.toInt(),
  menopauseStatus:
      $enumDecodeNullable(_$MenopauseStatusEnumMap, json['menopause_status']) ??
      MenopauseStatus.notApplicable,
  testosteroneOptimizationEnabled:
      json['testosterone_optimization_enabled'] as bool? ?? false,
  estrogenBalanceEnabled: json['estrogen_balance_enabled'] as bool? ?? false,
  includeHormoneSupportiveFoods:
      json['include_hormone_supportive_foods'] as bool? ?? true,
  includeHormoneSupportiveExercises:
      json['include_hormone_supportive_exercises'] as bool? ?? true,
  cycleSyncWorkouts: json['cycle_sync_workouts'] as bool? ?? false,
  cycleSyncNutrition: json['cycle_sync_nutrition'] as bool? ?? false,
  hasPcos: json['has_pcos'] as bool? ?? false,
  hasEndometriosis: json['has_endometriosis'] as bool? ?? false,
  hasThyroidCondition: json['has_thyroid_condition'] as bool? ?? false,
  onHormoneTherapy: json['on_hormone_therapy'] as bool? ?? false,
  hormoneTherapyType: json['hormone_therapy_type'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$HormonalProfileToJson(
  HormonalProfile instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'gender': _$GenderEnumMap[instance.gender],
  'birth_sex': _$BirthSexEnumMap[instance.birthSex],
  'hormone_goals': instance.hormoneGoals
      .map((e) => _$HormoneGoalEnumMap[e]!)
      .toList(),
  'menstrual_tracking_enabled': instance.menstrualTrackingEnabled,
  'cycle_length_days': instance.cycleLengthDays,
  'last_period_start_date': instance.lastPeriodStartDate?.toIso8601String(),
  'typical_period_duration_days': instance.typicalPeriodDurationDays,
  'menopause_status': _$MenopauseStatusEnumMap[instance.menopauseStatus]!,
  'testosterone_optimization_enabled': instance.testosteroneOptimizationEnabled,
  'estrogen_balance_enabled': instance.estrogenBalanceEnabled,
  'include_hormone_supportive_foods': instance.includeHormoneSupportiveFoods,
  'include_hormone_supportive_exercises':
      instance.includeHormoneSupportiveExercises,
  'cycle_sync_workouts': instance.cycleSyncWorkouts,
  'cycle_sync_nutrition': instance.cycleSyncNutrition,
  'has_pcos': instance.hasPcos,
  'has_endometriosis': instance.hasEndometriosis,
  'has_thyroid_condition': instance.hasThyroidCondition,
  'on_hormone_therapy': instance.onHormoneTherapy,
  'hormone_therapy_type': instance.hormoneTherapyType,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

const _$GenderEnumMap = {
  Gender.male: 'male',
  Gender.female: 'female',
  Gender.nonBinary: 'non_binary',
  Gender.other: 'other',
  Gender.preferNotToSay: 'prefer_not_to_say',
};

const _$BirthSexEnumMap = {
  BirthSex.male: 'male',
  BirthSex.female: 'female',
  BirthSex.intersex: 'intersex',
  BirthSex.preferNotToSay: 'prefer_not_to_say',
};

const _$HormoneGoalEnumMap = {
  HormoneGoal.optimizeTestosterone: 'optimize_testosterone',
  HormoneGoal.balanceEstrogen: 'balance_estrogen',
  HormoneGoal.improveFertility: 'improve_fertility',
  HormoneGoal.menopauseSupport: 'menopause_support',
  HormoneGoal.pcosManagement: 'pcos_management',
  HormoneGoal.perimenopauseSupport: 'perimenopause_support',
  HormoneGoal.andropauseSupport: 'andropause_support',
  HormoneGoal.generalWellness: 'general_wellness',
  HormoneGoal.libidoEnhancement: 'libido_enhancement',
  HormoneGoal.energyOptimization: 'energy_optimization',
  HormoneGoal.moodStabilization: 'mood_stabilization',
  HormoneGoal.sleepImprovement: 'sleep_improvement',
};

const _$MenopauseStatusEnumMap = {
  MenopauseStatus.pre: 'pre',
  MenopauseStatus.peri: 'peri',
  MenopauseStatus.post: 'post',
  MenopauseStatus.notApplicable: 'not_applicable',
};

HormoneLog _$HormoneLogFromJson(Map<String, dynamic> json) => HormoneLog(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  logDate: DateTime.parse(json['log_date'] as String),
  cycleDay: (json['cycle_day'] as num?)?.toInt(),
  cyclePhase: $enumDecodeNullable(_$CyclePhaseEnumMap, json['cycle_phase']),
  energyLevel: (json['energy_level'] as num?)?.toInt(),
  sleepQuality: (json['sleep_quality'] as num?)?.toInt(),
  libidoLevel: (json['libido_level'] as num?)?.toInt(),
  stressLevel: (json['stress_level'] as num?)?.toInt(),
  motivationLevel: (json['motivation_level'] as num?)?.toInt(),
  mood: $enumDecodeNullable(_$MoodEnumMap, json['mood']),
  symptoms:
      (json['symptoms'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$SymptomEnumMap, e))
          .toList() ??
      const [],
  notes: json['notes'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$HormoneLogToJson(HormoneLog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'log_date': instance.logDate.toIso8601String(),
      'cycle_day': instance.cycleDay,
      'cycle_phase': _$CyclePhaseEnumMap[instance.cyclePhase],
      'energy_level': instance.energyLevel,
      'sleep_quality': instance.sleepQuality,
      'libido_level': instance.libidoLevel,
      'stress_level': instance.stressLevel,
      'motivation_level': instance.motivationLevel,
      'mood': _$MoodEnumMap[instance.mood],
      'symptoms': instance.symptoms.map((e) => _$SymptomEnumMap[e]!).toList(),
      'notes': instance.notes,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$CyclePhaseEnumMap = {
  CyclePhase.menstrual: 'menstrual',
  CyclePhase.follicular: 'follicular',
  CyclePhase.ovulation: 'ovulation',
  CyclePhase.luteal: 'luteal',
};

const _$MoodEnumMap = {
  Mood.excellent: 'excellent',
  Mood.good: 'good',
  Mood.stable: 'stable',
  Mood.low: 'low',
  Mood.irritable: 'irritable',
  Mood.anxious: 'anxious',
  Mood.depressed: 'depressed',
};

const _$SymptomEnumMap = {
  Symptom.bloating: 'bloating',
  Symptom.cramps: 'cramps',
  Symptom.headache: 'headache',
  Symptom.migraine: 'migraine',
  Symptom.hotFlashes: 'hot_flashes',
  Symptom.nightSweats: 'night_sweats',
  Symptom.fatigue: 'fatigue',
  Symptom.muscleWeakness: 'muscle_weakness',
  Symptom.brainFog: 'brain_fog',
  Symptom.breastTenderness: 'breast_tenderness',
  Symptom.backPain: 'back_pain',
  Symptom.jointPain: 'joint_pain',
  Symptom.acne: 'acne',
  Symptom.insomnia: 'insomnia',
  Symptom.anxiety: 'anxiety',
  Symptom.irritability: 'irritability',
  Symptom.lowLibido: 'low_libido',
};

CyclePhaseInfo _$CyclePhaseInfoFromJson(Map<String, dynamic> json) =>
    CyclePhaseInfo(
      userId: json['user_id'] as String,
      menstrualTrackingEnabled: json['menstrual_tracking_enabled'] as bool,
      currentCycleDay: (json['current_cycle_day'] as num?)?.toInt(),
      currentPhase: $enumDecodeNullable(
        _$CyclePhaseEnumMap,
        json['current_phase'],
      ),
      daysUntilNextPhase: (json['days_until_next_phase'] as num?)?.toInt(),
      nextPhase: $enumDecodeNullable(_$CyclePhaseEnumMap, json['next_phase']),
      cycleLengthDays: (json['cycle_length_days'] as num?)?.toInt(),
      recommendedIntensity: json['recommended_intensity'] as String?,
      avoidExercises:
          (json['avoid_exercises'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      recommendedExercises:
          (json['recommended_exercises'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      nutritionFocus:
          (json['nutrition_focus'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$CyclePhaseInfoToJson(CyclePhaseInfo instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'menstrual_tracking_enabled': instance.menstrualTrackingEnabled,
      'current_cycle_day': instance.currentCycleDay,
      'current_phase': _$CyclePhaseEnumMap[instance.currentPhase],
      'days_until_next_phase': instance.daysUntilNextPhase,
      'next_phase': _$CyclePhaseEnumMap[instance.nextPhase],
      'cycle_length_days': instance.cycleLengthDays,
      'recommended_intensity': instance.recommendedIntensity,
      'avoid_exercises': instance.avoidExercises,
      'recommended_exercises': instance.recommendedExercises,
      'nutrition_focus': instance.nutritionFocus,
    };

HormoneSupportiveFood _$HormoneSupportiveFoodFromJson(
  Map<String, dynamic> json,
) => HormoneSupportiveFood(
  id: json['id'] as String,
  name: json['name'] as String,
  category: json['category'] as String,
  supportsTestosterone: json['supports_testosterone'] as bool? ?? false,
  supportsEstrogenBalance: json['supports_estrogen_balance'] as bool? ?? false,
  supportsPcos: json['supports_pcos'] as bool? ?? false,
  supportsMenopause: json['supports_menopause'] as bool? ?? false,
  supportsFertility: json['supports_fertility'] as bool? ?? false,
  keyNutrients:
      (json['key_nutrients'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  description: json['description'] as String?,
  servingSuggestion: json['serving_suggestion'] as String?,
);

Map<String, dynamic> _$HormoneSupportiveFoodToJson(
  HormoneSupportiveFood instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'category': instance.category,
  'supports_testosterone': instance.supportsTestosterone,
  'supports_estrogen_balance': instance.supportsEstrogenBalance,
  'supports_pcos': instance.supportsPcos,
  'supports_menopause': instance.supportsMenopause,
  'supports_fertility': instance.supportsFertility,
  'key_nutrients': instance.keyNutrients,
  'description': instance.description,
  'serving_suggestion': instance.servingSuggestion,
};

HormonalRecommendation _$HormonalRecommendationFromJson(
  Map<String, dynamic> json,
) => HormonalRecommendation(
  userId: json['user_id'] as String,
  recommendationType: json['recommendation_type'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  actionItems:
      (json['action_items'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  basedOn:
      (json['based_on'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  priority: json['priority'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$HormonalRecommendationToJson(
  HormonalRecommendation instance,
) => <String, dynamic>{
  'user_id': instance.userId,
  'recommendation_type': instance.recommendationType,
  'title': instance.title,
  'description': instance.description,
  'action_items': instance.actionItems,
  'based_on': instance.basedOn,
  'priority': instance.priority,
  'created_at': instance.createdAt.toIso8601String(),
};
