import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/glass_sheet.dart';
import '../../core/services/analytics_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/template_workout_generator.dart';
import '../../core/constants/api_constants.dart';
import '../../data/models/workout.dart';
import '../../data/repositories/workout_repository.dart';
import 'widgets/quiz_progress_bar.dart';
import 'widgets/quiz_header.dart';
import 'widgets/quiz_continue_button.dart';
import 'widgets/quiz_multi_select.dart';
import 'widgets/quiz_fitness_level.dart';
import 'widgets/quiz_days_selector.dart';
import 'widgets/quiz_equipment.dart';
import 'widgets/quiz_training_preferences.dart';
import 'widgets/quiz_motivation.dart';
import 'widgets/quiz_nutrition_goals.dart';
import 'widgets/quiz_fasting.dart';
import 'widgets/equipment_search_sheet.dart';
import 'widgets/quiz_primary_goal.dart';
import 'widgets/quiz_muscle_focus.dart';
import 'widgets/quiz_limitations.dart';
import 'widgets/quiz_personalization_gate.dart';
import 'widgets/quiz_training_style.dart';
import 'widgets/quiz_progression_constraints.dart';
import 'widgets/quiz_nutrition_gate.dart';
import 'widgets/foldable_quiz_scaffold.dart';
import '../../core/providers/window_mode_provider.dart';
import 'plan_preview_screen.dart';

/// Pre-auth quiz data stored in SharedPreferences
class PreAuthQuizData {
  final List<String>? goals;
  final String? fitnessLevel;
  final String? trainingExperience;
  // Activity level (outside of gym) - for TDEE calculations
  final String? activityLevel;  // sedentary, lightly_active, moderately_active, very_active
  // Personal info
  final String? name;
  final DateTime? dateOfBirth;
  // Body metrics for weight projection
  final String? gender;  // 'male', 'female', or 'other'
  final double? heightCm;
  final double? weightKg;
  final double? goalWeightKg;
  final bool useMetricUnits;
  // Two-step weight goal
  final String? weightDirection;  // lose, gain, maintain
  final double? weightChangeAmount;  // Amount to change in kg
  final String? weightChangeRate;  // slow (0.25kg/wk), moderate (0.5kg/wk), fast (0.75kg/wk), aggressive (1kg/wk)
  final int? daysPerWeek;
  final List<int>? workoutDays;
  final int? workoutDuration;  // Duration in minutes (kept for backwards compatibility)
  final int? workoutDurationMin;  // Min duration in minutes (e.g., 45 for "45-60" range)
  final int? workoutDurationMax;  // Max duration in minutes (e.g., 60 for "45-60" range)
  final List<String>? equipment;
  final List<String>? customEquipment;  // User-added custom equipment
  final String? workoutEnvironment;
  final String? trainingSplit;
  final List<String>? motivations;
  final int? dumbbellCount;
  final int? kettlebellCount;
  // Workout type preference (strength, cardio, mixed)
  final String? workoutTypePreference;
  // Workout variety preference (consistent, varied)
  final String? workoutVariety;
  // Progression pace (slow, medium, fast)
  final String? progressionPace;
  // Lifestyle
  final String? sleepQuality;  // poor, fair, good, excellent
  final List<String>? obstacles;  // time, energy, motivation, knowledge, diet, access
  // Nutrition preferences
  final List<String>? nutritionGoals;  // lose_fat, build_muscle, maintain, improve_energy, eat_healthier
  final List<String>? dietaryRestrictions;  // vegetarian, vegan, gluten_free, dairy_free, nut_allergy, keto, none
  final int? mealsPerDay;  // 4, 5, or 6 meals per day
  // Fasting preferences
  final bool? interestedInFasting;
  final String? fastingProtocol;  // 16:8, 18:6, 14:10, 20:4, none
  // Sleep schedule for fasting optimization (stored as "HH:MM" strings)
  final String? wakeTime;  // e.g., "07:00"
  final String? sleepTime;  // e.g., "23:00"
  // Primary training goal (muscle_hypertrophy, muscle_strength, strength_hypertrophy)
  final String? primaryGoal;
  // Muscle focus points allocation (max 5 total)
  // Keys: triceps, upper_traps, obliques, neck, lats, chest, shoulders, biceps, etc.
  final Map<String, int>? muscleFocusPoints;
  // Nutrition opt-in flag (user chose to set nutrition in Phase 3)
  final bool? nutritionEnabled;
  // Physical limitations/injuries (knees, shoulders, lower_back, other, none)
  final List<String>? limitations;

  // Fitness Assessment fields (for AI workout personalization)
  final String? pushupCapacity;    // 'none', '1-10', '11-25', '26-40', '40+'
  final String? pullupCapacity;    // 'none', 'assisted', '1-5', '6-10', '10+'
  final String? plankCapacity;     // '<15sec', '15-30sec', '31-60sec', '1-2min', '2+min'
  final String? squatCapacity;     // '0-10', '11-25', '26-40', '40+'
  final String? cardioCapacity;    // '<5min', '5-15min', '15-30min', '30+min'

  /// Computed age from dateOfBirth
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  PreAuthQuizData({
    this.goals,
    this.fitnessLevel,
    this.trainingExperience,
    this.activityLevel,
    this.name,
    this.dateOfBirth,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.goalWeightKg,
    this.useMetricUnits = true,
    this.weightDirection,
    this.weightChangeAmount,
    this.weightChangeRate,
    this.daysPerWeek,
    this.workoutDays,
    this.workoutDuration,
    this.workoutDurationMin,
    this.workoutDurationMax,
    this.equipment,
    this.customEquipment,
    this.workoutEnvironment,
    this.trainingSplit,
    this.motivations,
    this.dumbbellCount,
    this.kettlebellCount,
    this.workoutTypePreference,
    this.workoutVariety,
    this.progressionPace,
    this.sleepQuality,
    this.obstacles,
    this.nutritionGoals,
    this.dietaryRestrictions,
    this.mealsPerDay,
    this.interestedInFasting,
    this.fastingProtocol,
    this.wakeTime,
    this.sleepTime,
    this.primaryGoal,
    this.muscleFocusPoints,
    this.nutritionEnabled,
    this.limitations,
    this.pushupCapacity,
    this.pullupCapacity,
    this.plankCapacity,
    this.squatCapacity,
    this.cardioCapacity,
  });

  String? get goal => goals?.isNotEmpty == true ? goals!.first : null;
  String? get motivation => motivations?.isNotEmpty == true ? motivations!.first : null;

  /// Check if quiz is complete - requires core fields from Phase 1
  /// Note: workoutDays and motivations are optional (feature-flagged or skippable)
  bool get isComplete =>
      goals != null &&
      goals!.isNotEmpty &&
      fitnessLevel != null &&
      daysPerWeek != null &&
      equipment != null &&
      equipment!.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'goals': goals,
        'goal': goal,
        'fitnessLevel': fitnessLevel,
        'trainingExperience': trainingExperience,
        'activityLevel': activityLevel,
        'name': name,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'gender': gender,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'goalWeightKg': goalWeightKg,
        'useMetricUnits': useMetricUnits,
        'weightDirection': weightDirection,
        'weightChangeAmount': weightChangeAmount,
        'weightChangeRate': weightChangeRate,
        'daysPerWeek': daysPerWeek,
        'workoutDays': workoutDays,
        'workoutDuration': workoutDuration,
        'workoutDurationMin': workoutDurationMin,
        'workoutDurationMax': workoutDurationMax,
        'equipment': equipment,
        'customEquipment': customEquipment,
        'workoutEnvironment': workoutEnvironment,
        'trainingSplit': trainingSplit,
        'motivations': motivations,
        'motivation': motivation,
        'dumbbellCount': dumbbellCount,
        'kettlebellCount': kettlebellCount,
        'workoutTypePreference': workoutTypePreference,
        'progressionPace': progressionPace,
        'sleepQuality': sleepQuality,
        'obstacles': obstacles,
        'nutritionGoals': nutritionGoals,
        'dietaryRestrictions': dietaryRestrictions,
        'mealsPerDay': mealsPerDay,
        'interestedInFasting': interestedInFasting,
        'fastingProtocol': fastingProtocol,
        'wakeTime': wakeTime,
        'sleepTime': sleepTime,
        'primaryGoal': primaryGoal,
        'muscleFocusPoints': muscleFocusPoints,
        'nutritionEnabled': nutritionEnabled,
        'limitations': limitations,
        'pushupCapacity': pushupCapacity,
        'pullupCapacity': pullupCapacity,
        'plankCapacity': plankCapacity,
        'squatCapacity': squatCapacity,
        'cardioCapacity': cardioCapacity,
      };

  factory PreAuthQuizData.fromJson(Map<String, dynamic> json) => PreAuthQuizData(
        goals: (json['goals'] as List<dynamic>?)?.cast<String>() ??
            (json['goal'] != null ? [json['goal'] as String] : null),
        fitnessLevel: json['fitnessLevel'] as String?,
        trainingExperience: json['trainingExperience'] as String?,
        activityLevel: json['activityLevel'] as String?,
        name: json['name'] as String?,
        dateOfBirth: json['dateOfBirth'] != null
            ? DateTime.tryParse(json['dateOfBirth'] as String)
            : null,
        gender: json['gender'] as String?,
        heightCm: (json['heightCm'] as num?)?.toDouble(),
        weightKg: (json['weightKg'] as num?)?.toDouble(),
        goalWeightKg: (json['goalWeightKg'] as num?)?.toDouble(),
        useMetricUnits: json['useMetricUnits'] as bool? ?? true,
        weightDirection: json['weightDirection'] as String?,
        weightChangeAmount: (json['weightChangeAmount'] as num?)?.toDouble(),
        weightChangeRate: json['weightChangeRate'] as String?,
        daysPerWeek: json['daysPerWeek'] as int?,
        workoutDays: (json['workoutDays'] as List<dynamic>?)?.cast<int>(),
        workoutDuration: json['workoutDuration'] as int?,
        workoutDurationMin: json['workoutDurationMin'] as int?,
        workoutDurationMax: json['workoutDurationMax'] as int?,
        equipment: (json['equipment'] as List<dynamic>?)?.cast<String>(),
        customEquipment: (json['customEquipment'] as List<dynamic>?)?.cast<String>(),
        workoutEnvironment: json['workoutEnvironment'] as String?,
        trainingSplit: json['trainingSplit'] as String?,
        motivations: (json['motivations'] as List<dynamic>?)?.cast<String>() ??
            (json['motivation'] != null ? [json['motivation'] as String] : null),
        dumbbellCount: json['dumbbellCount'] as int?,
        kettlebellCount: json['kettlebellCount'] as int?,
        workoutTypePreference: json['workoutTypePreference'] as String?,
        progressionPace: json['progressionPace'] as String?,
        sleepQuality: json['sleepQuality'] as String?,
        obstacles: (json['obstacles'] as List<dynamic>?)?.cast<String>(),
        nutritionGoals: (json['nutritionGoals'] as List<dynamic>?)?.cast<String>(),
        dietaryRestrictions: (json['dietaryRestrictions'] as List<dynamic>?)?.cast<String>(),
        mealsPerDay: json['mealsPerDay'] as int?,
        interestedInFasting: json['interestedInFasting'] as bool?,
        fastingProtocol: json['fastingProtocol'] as String?,
        wakeTime: json['wakeTime'] as String?,
        sleepTime: json['sleepTime'] as String?,
        primaryGoal: json['primaryGoal'] as String?,
        muscleFocusPoints: (json['muscleFocusPoints'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, v as int),
        ),
        nutritionEnabled: json['nutritionEnabled'] as bool?,
        limitations: (json['limitations'] as List<dynamic>?)?.cast<String>(),
        pushupCapacity: json['pushupCapacity'] as String?,
        pullupCapacity: json['pullupCapacity'] as String?,
        plankCapacity: json['plankCapacity'] as String?,
        squatCapacity: json['squatCapacity'] as String?,
        cardioCapacity: json['cardioCapacity'] as String?,
      );
}

/// Provider for pre-auth quiz data
final preAuthQuizProvider = StateNotifierProvider<PreAuthQuizNotifier, PreAuthQuizData>((ref) {
  return PreAuthQuizNotifier();
});

/// Provider to hold the background generation completer.
/// When set, the WorkoutGenerationScreen can check if a workout is already ready
/// instead of starting generation from scratch.
final backgroundGenerationProvider = StateProvider<Completer<Workout?>?>((ref) => null);

class PreAuthQuizNotifier extends StateNotifier<PreAuthQuizData> {
  PreAuthQuizNotifier() : super(PreAuthQuizData()) {
    _loadFromPrefs();
  }

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final goals = prefs.getStringList('preAuth_goals');
    final level = prefs.getString('preAuth_fitnessLevel');
    final trainingExp = prefs.getString('preAuth_trainingExperience');
    final activityLevel = prefs.getString('preAuth_activityLevel');
    // Personal info
    final name = prefs.getString('preAuth_name');
    final dateOfBirthStr = prefs.getString('preAuth_dateOfBirth');
    final dateOfBirth = dateOfBirthStr != null ? DateTime.tryParse(dateOfBirthStr) : null;
    // Body metrics
    final gender = prefs.getString('preAuth_gender');
    final heightCm = prefs.getDouble('preAuth_heightCm');
    final weightKg = prefs.getDouble('preAuth_weightKg');
    final goalWeightKg = prefs.getDouble('preAuth_goalWeightKg');
    final useMetricUnits = prefs.getBool('preAuth_useMetric') ?? true;
    final weightDirection = prefs.getString('preAuth_weightDirection');
    final weightChangeAmount = prefs.getDouble('preAuth_weightChangeAmount');
    final weightChangeRate = prefs.getString('preAuth_weightChangeRate');
    final days = prefs.getInt('preAuth_daysPerWeek');
    final workoutDaysStr = prefs.getStringList('preAuth_workoutDays');
    final workoutDays = workoutDaysStr?.map((s) => int.tryParse(s) ?? 0).toList();
    final workoutDuration = prefs.getInt('preAuth_workoutDuration');
    final workoutDurationMin = prefs.getInt('preAuth_workoutDurationMin');
    final workoutDurationMax = prefs.getInt('preAuth_workoutDurationMax');
    final equipmentStr = prefs.getStringList('preAuth_equipment');
    final customEquipmentStr = prefs.getStringList('preAuth_customEquipment');
    final workoutEnv = prefs.getString('preAuth_workoutEnvironment');
    final trainingSplit = prefs.getString('preAuth_trainingSplit');
    final motivations = prefs.getStringList('preAuth_motivations');
    final dumbbellCount = prefs.getInt('preAuth_dumbbellCount');
    final kettlebellCount = prefs.getInt('preAuth_kettlebellCount');
    final workoutTypePref = prefs.getString('preAuth_workoutTypePreference');
    final workoutVariety = prefs.getString('preAuth_workoutVariety');
    final progressionPace = prefs.getString('preAuth_progressionPace');
    final sleepQuality = prefs.getString('preAuth_sleepQuality');
    final obstacles = prefs.getStringList('preAuth_obstacles');
    final nutritionGoals = prefs.getStringList('preAuth_nutritionGoals');
    final dietaryRestrictions = prefs.getStringList('preAuth_dietaryRestrictions');
    final mealsPerDay = prefs.getInt('preAuth_mealsPerDay');
    final interestedInFasting = prefs.getBool('preAuth_interestedInFasting');
    final fastingProtocol = prefs.getString('preAuth_fastingProtocol');
    final wakeTime = prefs.getString('preAuth_wakeTime');
    final sleepTime = prefs.getString('preAuth_sleepTime');
    final primaryGoal = prefs.getString('preAuth_primaryGoal');
    final muscleFocusPointsStr = prefs.getString('preAuth_muscleFocusPoints');
    Map<String, int>? muscleFocusPoints;
    if (muscleFocusPointsStr != null) {
      try {
        final decoded = Map<String, dynamic>.from(
          Map.castFrom(Uri.splitQueryString(muscleFocusPointsStr).map(
            (k, v) => MapEntry(k, int.tryParse(v) ?? 0),
          )),
        );
        muscleFocusPoints = decoded.map((k, v) => MapEntry(k, v as int));
      } catch (_) {
        muscleFocusPoints = null;
      }
    }
    final nutritionEnabled = prefs.getBool('preAuth_nutritionEnabled');
    final limitations = prefs.getStringList('preAuth_limitations');
    // Fitness assessment fields
    final pushupCapacity = prefs.getString('preAuth_pushupCapacity');
    final pullupCapacity = prefs.getString('preAuth_pullupCapacity');
    final plankCapacity = prefs.getString('preAuth_plankCapacity');
    final squatCapacity = prefs.getString('preAuth_squatCapacity');
    final cardioCapacity = prefs.getString('preAuth_cardioCapacity');

    state = PreAuthQuizData(
      goals: goals,
      fitnessLevel: level,
      trainingExperience: trainingExp,
      activityLevel: activityLevel,
      name: name,
      dateOfBirth: dateOfBirth,
      gender: gender,
      heightCm: heightCm,
      weightKg: weightKg,
      goalWeightKg: goalWeightKg,
      useMetricUnits: useMetricUnits,
      weightDirection: weightDirection,
      weightChangeAmount: weightChangeAmount,
      weightChangeRate: weightChangeRate,
      daysPerWeek: days,
      workoutDays: workoutDays,
      workoutDuration: workoutDuration,
      workoutDurationMin: workoutDurationMin,
      workoutDurationMax: workoutDurationMax,
      equipment: equipmentStr,
      customEquipment: customEquipmentStr,
      workoutEnvironment: workoutEnv,
      trainingSplit: trainingSplit,
      motivations: motivations,
      dumbbellCount: dumbbellCount,
      kettlebellCount: kettlebellCount,
      workoutTypePreference: workoutTypePref,
      workoutVariety: workoutVariety,
      progressionPace: progressionPace,
      sleepQuality: sleepQuality,
      obstacles: obstacles,
      nutritionGoals: nutritionGoals,
      dietaryRestrictions: dietaryRestrictions,
      mealsPerDay: mealsPerDay,
      interestedInFasting: interestedInFasting,
      fastingProtocol: fastingProtocol,
      wakeTime: wakeTime,
      sleepTime: sleepTime,
      primaryGoal: primaryGoal,
      muscleFocusPoints: muscleFocusPoints,
      nutritionEnabled: nutritionEnabled,
      limitations: limitations,
      pushupCapacity: pushupCapacity,
      pullupCapacity: pullupCapacity,
      plankCapacity: plankCapacity,
      squatCapacity: squatCapacity,
      cardioCapacity: cardioCapacity,
    );
    _isLoaded = true;
  }

  Future<PreAuthQuizData> ensureLoaded() async {
    if (!_isLoaded) {
      await _loadFromPrefs();
    }
    return state;
  }

  Future<void> setGoals(List<String> goals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('preAuth_goals', goals);
    state = PreAuthQuizData(
      goals: goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      activityLevel: state.activityLevel,
      name: state.name,
      dateOfBirth: state.dateOfBirth,
      gender: state.gender,
      heightCm: state.heightCm,
      weightKg: state.weightKg,
      goalWeightKg: state.goalWeightKg,
      useMetricUnits: state.useMetricUnits,
      weightDirection: state.weightDirection,
      weightChangeAmount: state.weightChangeAmount,
      weightChangeRate: state.weightChangeRate,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      workoutDuration: state.workoutDuration,
      workoutDurationMin: state.workoutDurationMin,
      workoutDurationMax: state.workoutDurationMax,
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      workoutVariety: state.workoutVariety,
      progressionPace: state.progressionPace,
      sleepQuality: state.sleepQuality,
      obstacles: state.obstacles,
      nutritionGoals: state.nutritionGoals,
      dietaryRestrictions: state.dietaryRestrictions,
      mealsPerDay: state.mealsPerDay,
      interestedInFasting: state.interestedInFasting,
      fastingProtocol: state.fastingProtocol,
      wakeTime: state.wakeTime,
      sleepTime: state.sleepTime,
      primaryGoal: state.primaryGoal,
      nutritionEnabled: state.nutritionEnabled,
      limitations: state.limitations,
      muscleFocusPoints: state.muscleFocusPoints,
      pushupCapacity: state.pushupCapacity,
      pullupCapacity: state.pullupCapacity,
      plankCapacity: state.plankCapacity,
      squatCapacity: state.squatCapacity,
      cardioCapacity: state.cardioCapacity,
    );
  }

  Future<void> setFitnessLevel(String level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_fitnessLevel', level);
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: level,
      trainingExperience: state.trainingExperience,
      activityLevel: state.activityLevel,
      name: state.name,
      dateOfBirth: state.dateOfBirth,
      gender: state.gender,
      heightCm: state.heightCm,
      weightKg: state.weightKg,
      goalWeightKg: state.goalWeightKg,
      useMetricUnits: state.useMetricUnits,
      weightDirection: state.weightDirection,
      weightChangeAmount: state.weightChangeAmount,
      weightChangeRate: state.weightChangeRate,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      workoutDuration: state.workoutDuration,
      workoutDurationMin: state.workoutDurationMin,
      workoutDurationMax: state.workoutDurationMax,
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      workoutVariety: state.workoutVariety,
      progressionPace: state.progressionPace,
      sleepQuality: state.sleepQuality,
      obstacles: state.obstacles,
      nutritionGoals: state.nutritionGoals,
      dietaryRestrictions: state.dietaryRestrictions,
      mealsPerDay: state.mealsPerDay,
      interestedInFasting: state.interestedInFasting,
      fastingProtocol: state.fastingProtocol,
      wakeTime: state.wakeTime,
      sleepTime: state.sleepTime,
      primaryGoal: state.primaryGoal,
      nutritionEnabled: state.nutritionEnabled,
      limitations: state.limitations,
      muscleFocusPoints: state.muscleFocusPoints,
      pushupCapacity: state.pushupCapacity,
      pullupCapacity: state.pullupCapacity,
      plankCapacity: state.plankCapacity,
      squatCapacity: state.squatCapacity,
      cardioCapacity: state.cardioCapacity,
    );
  }

  Future<void> setTrainingExperience(String experience) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_trainingExperience', experience);
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: experience,
      activityLevel: state.activityLevel,
      name: state.name,
      dateOfBirth: state.dateOfBirth,
      gender: state.gender,
      heightCm: state.heightCm,
      weightKg: state.weightKg,
      goalWeightKg: state.goalWeightKg,
      useMetricUnits: state.useMetricUnits,
      weightDirection: state.weightDirection,
      weightChangeAmount: state.weightChangeAmount,
      weightChangeRate: state.weightChangeRate,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      workoutDuration: state.workoutDuration,
      workoutDurationMin: state.workoutDurationMin,
      workoutDurationMax: state.workoutDurationMax,
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      workoutVariety: state.workoutVariety,
      progressionPace: state.progressionPace,
      sleepQuality: state.sleepQuality,
      obstacles: state.obstacles,
      nutritionGoals: state.nutritionGoals,
      dietaryRestrictions: state.dietaryRestrictions,
      mealsPerDay: state.mealsPerDay,
      interestedInFasting: state.interestedInFasting,
      fastingProtocol: state.fastingProtocol,
      wakeTime: state.wakeTime,
      sleepTime: state.sleepTime,
      primaryGoal: state.primaryGoal,
      nutritionEnabled: state.nutritionEnabled,
      limitations: state.limitations,
      muscleFocusPoints: state.muscleFocusPoints,
      pushupCapacity: state.pushupCapacity,
      pullupCapacity: state.pullupCapacity,
      plankCapacity: state.plankCapacity,
      squatCapacity: state.squatCapacity,
      cardioCapacity: state.cardioCapacity,
    );
  }

  Future<void> setActivityLevel(String level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_activityLevel', level);
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      activityLevel: level,
      name: state.name,
      dateOfBirth: state.dateOfBirth,
      gender: state.gender,
      heightCm: state.heightCm,
      weightKg: state.weightKg,
      goalWeightKg: state.goalWeightKg,
      useMetricUnits: state.useMetricUnits,
      weightDirection: state.weightDirection,
      weightChangeAmount: state.weightChangeAmount,
      weightChangeRate: state.weightChangeRate,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      workoutDuration: state.workoutDuration,
      workoutDurationMin: state.workoutDurationMin,
      workoutDurationMax: state.workoutDurationMax,
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      workoutVariety: state.workoutVariety,
      progressionPace: state.progressionPace,
      sleepQuality: state.sleepQuality,
      obstacles: state.obstacles,
      nutritionGoals: state.nutritionGoals,
      dietaryRestrictions: state.dietaryRestrictions,
      mealsPerDay: state.mealsPerDay,
      interestedInFasting: state.interestedInFasting,
      fastingProtocol: state.fastingProtocol,
      wakeTime: state.wakeTime,
      sleepTime: state.sleepTime,
      primaryGoal: state.primaryGoal,
      nutritionEnabled: state.nutritionEnabled,
      limitations: state.limitations,
      muscleFocusPoints: state.muscleFocusPoints,
      pushupCapacity: state.pushupCapacity,
      pullupCapacity: state.pullupCapacity,
      plankCapacity: state.plankCapacity,
      squatCapacity: state.squatCapacity,
      cardioCapacity: state.cardioCapacity,
    );
  }

  Future<void> setBodyMetrics({
    String? name,
    DateTime? dateOfBirth,
    String? gender,
    required double heightCm,
    required double weightKg,
    required double goalWeightKg,
    required bool useMetric,
    String? weightDirection,
    double? weightChangeAmount,
    String? weightChangeRate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null) {
      await prefs.setString('preAuth_name', name);
    }
    if (dateOfBirth != null) {
      await prefs.setString('preAuth_dateOfBirth', dateOfBirth.toIso8601String());
    }
    if (gender != null) {
      await prefs.setString('preAuth_gender', gender);
    }
    await prefs.setDouble('preAuth_heightCm', heightCm);
    await prefs.setDouble('preAuth_weightKg', weightKg);
    await prefs.setDouble('preAuth_goalWeightKg', goalWeightKg);
    await prefs.setBool('preAuth_useMetric', useMetric);
    if (weightDirection != null) {
      await prefs.setString('preAuth_weightDirection', weightDirection);
    }
    if (weightChangeAmount != null) {
      await prefs.setDouble('preAuth_weightChangeAmount', weightChangeAmount);
    }
    if (weightChangeRate != null) {
      await prefs.setString('preAuth_weightChangeRate', weightChangeRate);
    }
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      activityLevel: state.activityLevel,
      name: name ?? state.name,
      dateOfBirth: dateOfBirth ?? state.dateOfBirth,
      gender: gender ?? state.gender,
      heightCm: heightCm,
      weightKg: weightKg,
      goalWeightKg: goalWeightKg,
      useMetricUnits: useMetric,
      weightDirection: weightDirection ?? state.weightDirection,
      weightChangeAmount: weightChangeAmount ?? state.weightChangeAmount,
      weightChangeRate: weightChangeRate ?? state.weightChangeRate,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      workoutDuration: state.workoutDuration,
      workoutDurationMin: state.workoutDurationMin,
      workoutDurationMax: state.workoutDurationMax,
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      workoutVariety: state.workoutVariety,
      progressionPace: state.progressionPace,
      sleepQuality: state.sleepQuality,
      obstacles: state.obstacles,
      nutritionGoals: state.nutritionGoals,
      dietaryRestrictions: state.dietaryRestrictions,
      mealsPerDay: state.mealsPerDay,
      interestedInFasting: state.interestedInFasting,
      fastingProtocol: state.fastingProtocol,
      wakeTime: state.wakeTime,
      sleepTime: state.sleepTime,
      primaryGoal: state.primaryGoal,
      nutritionEnabled: state.nutritionEnabled,
      limitations: state.limitations,
      muscleFocusPoints: state.muscleFocusPoints,
      pushupCapacity: state.pushupCapacity,
      pullupCapacity: state.pullupCapacity,
      plankCapacity: state.plankCapacity,
      squatCapacity: state.squatCapacity,
      cardioCapacity: state.cardioCapacity,
    );
  }

  Future<void> setDaysPerWeek(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('preAuth_daysPerWeek', days);
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      activityLevel: state.activityLevel,
      name: state.name,
      dateOfBirth: state.dateOfBirth,
      gender: state.gender,
      heightCm: state.heightCm,
      weightKg: state.weightKg,
      goalWeightKg: state.goalWeightKg,
      useMetricUnits: state.useMetricUnits,
      weightDirection: state.weightDirection,
      weightChangeAmount: state.weightChangeAmount,
      weightChangeRate: state.weightChangeRate,
      daysPerWeek: days,
      workoutDays: state.workoutDays,
      workoutDuration: state.workoutDuration,
      workoutDurationMin: state.workoutDurationMin,
      workoutDurationMax: state.workoutDurationMax,
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      workoutVariety: state.workoutVariety,
      progressionPace: state.progressionPace,
      sleepQuality: state.sleepQuality,
      obstacles: state.obstacles,
      nutritionGoals: state.nutritionGoals,
      dietaryRestrictions: state.dietaryRestrictions,
      mealsPerDay: state.mealsPerDay,
      interestedInFasting: state.interestedInFasting,
      fastingProtocol: state.fastingProtocol,
      wakeTime: state.wakeTime,
      sleepTime: state.sleepTime,
      primaryGoal: state.primaryGoal,
      nutritionEnabled: state.nutritionEnabled,
      limitations: state.limitations,
      muscleFocusPoints: state.muscleFocusPoints,
      pushupCapacity: state.pushupCapacity,
      pullupCapacity: state.pullupCapacity,
      plankCapacity: state.plankCapacity,
      squatCapacity: state.squatCapacity,
      cardioCapacity: state.cardioCapacity,
    );
  }

  Future<void> setWorkoutDays(List<int> workoutDays) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('preAuth_workoutDays', workoutDays.map((d) => d.toString()).toList());
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      activityLevel: state.activityLevel,
      name: state.name,
      dateOfBirth: state.dateOfBirth,
      gender: state.gender,
      heightCm: state.heightCm,
      weightKg: state.weightKg,
      goalWeightKg: state.goalWeightKg,
      useMetricUnits: state.useMetricUnits,
      weightDirection: state.weightDirection,
      weightChangeAmount: state.weightChangeAmount,
      weightChangeRate: state.weightChangeRate,
      daysPerWeek: state.daysPerWeek,
      workoutDays: workoutDays,
      workoutDuration: state.workoutDuration,
      workoutDurationMin: state.workoutDurationMin,
      workoutDurationMax: state.workoutDurationMax,
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      workoutVariety: state.workoutVariety,
      progressionPace: state.progressionPace,
      sleepQuality: state.sleepQuality,
      obstacles: state.obstacles,
      nutritionGoals: state.nutritionGoals,
      dietaryRestrictions: state.dietaryRestrictions,
      mealsPerDay: state.mealsPerDay,
      interestedInFasting: state.interestedInFasting,
      fastingProtocol: state.fastingProtocol,
      wakeTime: state.wakeTime,
      sleepTime: state.sleepTime,
      primaryGoal: state.primaryGoal,
      nutritionEnabled: state.nutritionEnabled,
      limitations: state.limitations,
      muscleFocusPoints: state.muscleFocusPoints,
      pushupCapacity: state.pushupCapacity,
      pullupCapacity: state.pullupCapacity,
      plankCapacity: state.plankCapacity,
      squatCapacity: state.squatCapacity,
      cardioCapacity: state.cardioCapacity,
    );
  }

  Future<void> setWorkoutDuration(int minDuration, int maxDuration) async {
    final prefs = await SharedPreferences.getInstance();
    // Save min and max separately
    await prefs.setInt('preAuth_workoutDurationMin', minDuration);
    await prefs.setInt('preAuth_workoutDurationMax', maxDuration);
    // Keep the old key for backwards compatibility (use max as the single value)
    await prefs.setInt('preAuth_workoutDuration', maxDuration);
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      activityLevel: state.activityLevel,
      name: state.name,
      dateOfBirth: state.dateOfBirth,
      gender: state.gender,
      heightCm: state.heightCm,
      weightKg: state.weightKg,
      goalWeightKg: state.goalWeightKg,
      useMetricUnits: state.useMetricUnits,
      weightDirection: state.weightDirection,
      weightChangeAmount: state.weightChangeAmount,
      weightChangeRate: state.weightChangeRate,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      workoutDuration: maxDuration,
      workoutDurationMin: minDuration,
      workoutDurationMax: maxDuration,
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      workoutVariety: state.workoutVariety,
      progressionPace: state.progressionPace,
      sleepQuality: state.sleepQuality,
      obstacles: state.obstacles,
      nutritionGoals: state.nutritionGoals,
      dietaryRestrictions: state.dietaryRestrictions,
      mealsPerDay: state.mealsPerDay,
      interestedInFasting: state.interestedInFasting,
      fastingProtocol: state.fastingProtocol,
      wakeTime: state.wakeTime,
      sleepTime: state.sleepTime,
      primaryGoal: state.primaryGoal,
      nutritionEnabled: state.nutritionEnabled,
      limitations: state.limitations,
      muscleFocusPoints: state.muscleFocusPoints,
      pushupCapacity: state.pushupCapacity,
      pullupCapacity: state.pullupCapacity,
      plankCapacity: state.plankCapacity,
      squatCapacity: state.squatCapacity,
      cardioCapacity: state.cardioCapacity,
    );
  }

  String _inferWorkoutEnvironment(List<String> equipment) {
    if (equipment.contains('full_gym') ||
        (equipment.contains('barbell') && equipment.contains('cable_machine'))) {
      return 'commercial_gym';
    }
    if (equipment.contains('barbell') || equipment.contains('cable_machine')) {
      return 'home_gym';
    }
    return 'home';
  }

  Future<void> setEquipment(List<String> equipment, {int? dumbbellCount, int? kettlebellCount, List<String>? customEquipment}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('preAuth_equipment', equipment);
    if (dumbbellCount != null) {
      await prefs.setInt('preAuth_dumbbellCount', dumbbellCount);
    }
    if (kettlebellCount != null) {
      await prefs.setInt('preAuth_kettlebellCount', kettlebellCount);
    }
    if (customEquipment != null) {
      await prefs.setStringList('preAuth_customEquipment', customEquipment);
    }
    final workoutEnv = _inferWorkoutEnvironment(equipment);
    await prefs.setString('preAuth_workoutEnvironment', workoutEnv);

    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      activityLevel: state.activityLevel,
      name: state.name,
      dateOfBirth: state.dateOfBirth,
      gender: state.gender,
      heightCm: state.heightCm,
      weightKg: state.weightKg,
      goalWeightKg: state.goalWeightKg,
      useMetricUnits: state.useMetricUnits,
      weightDirection: state.weightDirection,
      weightChangeAmount: state.weightChangeAmount,
      weightChangeRate: state.weightChangeRate,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      equipment: equipment,
      customEquipment: customEquipment ?? state.customEquipment,
      workoutEnvironment: workoutEnv,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: dumbbellCount ?? state.dumbbellCount,
      kettlebellCount: kettlebellCount ?? state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      workoutVariety: state.workoutVariety,
      progressionPace: state.progressionPace,
      sleepQuality: state.sleepQuality,
      obstacles: state.obstacles,
      nutritionGoals: state.nutritionGoals,
      dietaryRestrictions: state.dietaryRestrictions,
      mealsPerDay: state.mealsPerDay,
      interestedInFasting: state.interestedInFasting,
      fastingProtocol: state.fastingProtocol,
      wakeTime: state.wakeTime,
      sleepTime: state.sleepTime,
      primaryGoal: state.primaryGoal,
      nutritionEnabled: state.nutritionEnabled,
      limitations: state.limitations,
      muscleFocusPoints: state.muscleFocusPoints,
      pushupCapacity: state.pushupCapacity,
      pullupCapacity: state.pullupCapacity,
      plankCapacity: state.plankCapacity,
      squatCapacity: state.squatCapacity,
      cardioCapacity: state.cardioCapacity,
    );
  }

  Future<void> setTrainingSplit(String split) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_trainingSplit', split);
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      activityLevel: state.activityLevel,
      name: state.name,
      dateOfBirth: state.dateOfBirth,
      gender: state.gender,
      heightCm: state.heightCm,
      weightKg: state.weightKg,
      goalWeightKg: state.goalWeightKg,
      useMetricUnits: state.useMetricUnits,
      weightDirection: state.weightDirection,
      weightChangeAmount: state.weightChangeAmount,
      weightChangeRate: state.weightChangeRate,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      workoutDuration: state.workoutDuration,
      workoutDurationMin: state.workoutDurationMin,
      workoutDurationMax: state.workoutDurationMax,
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: split,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      workoutVariety: state.workoutVariety,
      progressionPace: state.progressionPace,
      sleepQuality: state.sleepQuality,
      obstacles: state.obstacles,
      nutritionGoals: state.nutritionGoals,
      dietaryRestrictions: state.dietaryRestrictions,
      mealsPerDay: state.mealsPerDay,
      interestedInFasting: state.interestedInFasting,
      fastingProtocol: state.fastingProtocol,
      wakeTime: state.wakeTime,
      sleepTime: state.sleepTime,
      primaryGoal: state.primaryGoal,
      nutritionEnabled: state.nutritionEnabled,
      limitations: state.limitations,
      muscleFocusPoints: state.muscleFocusPoints,
      pushupCapacity: state.pushupCapacity,
      pullupCapacity: state.pullupCapacity,
      plankCapacity: state.plankCapacity,
      squatCapacity: state.squatCapacity,
      cardioCapacity: state.cardioCapacity,
    );
  }

  Future<void> setMotivations(List<String> motivations) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('preAuth_motivations', motivations);
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      activityLevel: state.activityLevel,
      name: state.name,
      dateOfBirth: state.dateOfBirth,
      gender: state.gender,
      heightCm: state.heightCm,
      weightKg: state.weightKg,
      goalWeightKg: state.goalWeightKg,
      useMetricUnits: state.useMetricUnits,
      weightDirection: state.weightDirection,
      weightChangeAmount: state.weightChangeAmount,
      weightChangeRate: state.weightChangeRate,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      workoutDuration: state.workoutDuration,
      workoutDurationMin: state.workoutDurationMin,
      workoutDurationMax: state.workoutDurationMax,
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      workoutVariety: state.workoutVariety,
      progressionPace: state.progressionPace,
      sleepQuality: state.sleepQuality,
      obstacles: state.obstacles,
      nutritionGoals: state.nutritionGoals,
      dietaryRestrictions: state.dietaryRestrictions,
      mealsPerDay: state.mealsPerDay,
      interestedInFasting: state.interestedInFasting,
      fastingProtocol: state.fastingProtocol,
      wakeTime: state.wakeTime,
      sleepTime: state.sleepTime,
      primaryGoal: state.primaryGoal,
      nutritionEnabled: state.nutritionEnabled,
      limitations: state.limitations,
      muscleFocusPoints: state.muscleFocusPoints,
      pushupCapacity: state.pushupCapacity,
      pullupCapacity: state.pullupCapacity,
      plankCapacity: state.plankCapacity,
      squatCapacity: state.squatCapacity,
      cardioCapacity: state.cardioCapacity,
    );
  }

  Future<void> setWorkoutTypePreference(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_workoutTypePreference', type);
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      activityLevel: state.activityLevel,
      name: state.name,
      dateOfBirth: state.dateOfBirth,
      gender: state.gender,
      heightCm: state.heightCm,
      weightKg: state.weightKg,
      goalWeightKg: state.goalWeightKg,
      useMetricUnits: state.useMetricUnits,
      weightDirection: state.weightDirection,
      weightChangeAmount: state.weightChangeAmount,
      weightChangeRate: state.weightChangeRate,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      workoutDuration: state.workoutDuration,
      workoutDurationMin: state.workoutDurationMin,
      workoutDurationMax: state.workoutDurationMax,
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: type,
      workoutVariety: state.workoutVariety,
      progressionPace: state.progressionPace,
      sleepQuality: state.sleepQuality,
      obstacles: state.obstacles,
      nutritionGoals: state.nutritionGoals,
      dietaryRestrictions: state.dietaryRestrictions,
      mealsPerDay: state.mealsPerDay,
      interestedInFasting: state.interestedInFasting,
      fastingProtocol: state.fastingProtocol,
      wakeTime: state.wakeTime,
      sleepTime: state.sleepTime,
      primaryGoal: state.primaryGoal,
      nutritionEnabled: state.nutritionEnabled,
      limitations: state.limitations,
      muscleFocusPoints: state.muscleFocusPoints,
      pushupCapacity: state.pushupCapacity,
      pullupCapacity: state.pullupCapacity,
      plankCapacity: state.plankCapacity,
      squatCapacity: state.squatCapacity,
      cardioCapacity: state.cardioCapacity,
    );
  }

  Future<void> setWorkoutVariety(String variety) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_workoutVariety', variety);
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      activityLevel: state.activityLevel,
      name: state.name,
      dateOfBirth: state.dateOfBirth,
      gender: state.gender,
      heightCm: state.heightCm,
      weightKg: state.weightKg,
      goalWeightKg: state.goalWeightKg,
      useMetricUnits: state.useMetricUnits,
      weightDirection: state.weightDirection,
      weightChangeAmount: state.weightChangeAmount,
      weightChangeRate: state.weightChangeRate,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      workoutDuration: state.workoutDuration,
      workoutDurationMin: state.workoutDurationMin,
      workoutDurationMax: state.workoutDurationMax,
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      workoutVariety: variety,
      progressionPace: state.progressionPace,
      sleepQuality: state.sleepQuality,
      obstacles: state.obstacles,
      nutritionGoals: state.nutritionGoals,
      dietaryRestrictions: state.dietaryRestrictions,
      mealsPerDay: state.mealsPerDay,
      interestedInFasting: state.interestedInFasting,
      fastingProtocol: state.fastingProtocol,
      wakeTime: state.wakeTime,
      sleepTime: state.sleepTime,
      primaryGoal: state.primaryGoal,
      nutritionEnabled: state.nutritionEnabled,
      limitations: state.limitations,
      muscleFocusPoints: state.muscleFocusPoints,
      pushupCapacity: state.pushupCapacity,
      pullupCapacity: state.pullupCapacity,
      plankCapacity: state.plankCapacity,
      squatCapacity: state.squatCapacity,
      cardioCapacity: state.cardioCapacity,
    );
  }

  Future<void> setProgressionPace(String pace) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_progressionPace', pace);
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      activityLevel: state.activityLevel,
      name: state.name,
      dateOfBirth: state.dateOfBirth,
      gender: state.gender,
      heightCm: state.heightCm,
      weightKg: state.weightKg,
      goalWeightKg: state.goalWeightKg,
      useMetricUnits: state.useMetricUnits,
      weightDirection: state.weightDirection,
      weightChangeAmount: state.weightChangeAmount,
      weightChangeRate: state.weightChangeRate,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      workoutDuration: state.workoutDuration,
      workoutDurationMin: state.workoutDurationMin,
      workoutDurationMax: state.workoutDurationMax,
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      workoutVariety: state.workoutVariety,
      progressionPace: pace,
      sleepQuality: state.sleepQuality,
      obstacles: state.obstacles,
      nutritionGoals: state.nutritionGoals,
      dietaryRestrictions: state.dietaryRestrictions,
      mealsPerDay: state.mealsPerDay,
      interestedInFasting: state.interestedInFasting,
      fastingProtocol: state.fastingProtocol,
      wakeTime: state.wakeTime,
      sleepTime: state.sleepTime,
      primaryGoal: state.primaryGoal,
      nutritionEnabled: state.nutritionEnabled,
      limitations: state.limitations,
      muscleFocusPoints: state.muscleFocusPoints,
      pushupCapacity: state.pushupCapacity,
      pullupCapacity: state.pullupCapacity,
      plankCapacity: state.plankCapacity,
      squatCapacity: state.squatCapacity,
      cardioCapacity: state.cardioCapacity,
    );
  }

  Future<void> setNutritionGoals(List<String> nutritionGoals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('preAuth_nutritionGoals', nutritionGoals);
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      activityLevel: state.activityLevel,
      name: state.name,
      dateOfBirth: state.dateOfBirth,
      gender: state.gender,
      heightCm: state.heightCm,
      weightKg: state.weightKg,
      goalWeightKg: state.goalWeightKg,
      useMetricUnits: state.useMetricUnits,
      weightDirection: state.weightDirection,
      weightChangeAmount: state.weightChangeAmount,
      weightChangeRate: state.weightChangeRate,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      workoutDuration: state.workoutDuration,
      workoutDurationMin: state.workoutDurationMin,
      workoutDurationMax: state.workoutDurationMax,
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      workoutVariety: state.workoutVariety,
      progressionPace: state.progressionPace,
      sleepQuality: state.sleepQuality,
      obstacles: state.obstacles,
      nutritionGoals: nutritionGoals,
      dietaryRestrictions: state.dietaryRestrictions,
      mealsPerDay: state.mealsPerDay,
      interestedInFasting: state.interestedInFasting,
      fastingProtocol: state.fastingProtocol,
      wakeTime: state.wakeTime,
      sleepTime: state.sleepTime,
      primaryGoal: state.primaryGoal,
      nutritionEnabled: state.nutritionEnabled,
      limitations: state.limitations,
      muscleFocusPoints: state.muscleFocusPoints,
      pushupCapacity: state.pushupCapacity,
      pullupCapacity: state.pullupCapacity,
      plankCapacity: state.plankCapacity,
      squatCapacity: state.squatCapacity,
      cardioCapacity: state.cardioCapacity,
    );
  }

  Future<void> setFastingPreferences({
    required bool interested,
    String? protocol,
    String? wakeTime,
    String? sleepTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('preAuth_interestedInFasting', interested);
    if (protocol != null) {
      await prefs.setString('preAuth_fastingProtocol', protocol);
    } else {
      await prefs.remove('preAuth_fastingProtocol');
    }
    // Save sleep schedule
    if (wakeTime != null) {
      await prefs.setString('preAuth_wakeTime', wakeTime);
    }
    if (sleepTime != null) {
      await prefs.setString('preAuth_sleepTime', sleepTime);
    }
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      activityLevel: state.activityLevel,
      name: state.name,
      dateOfBirth: state.dateOfBirth,
      gender: state.gender,
      heightCm: state.heightCm,
      weightKg: state.weightKg,
      goalWeightKg: state.goalWeightKg,
      useMetricUnits: state.useMetricUnits,
      weightDirection: state.weightDirection,
      weightChangeAmount: state.weightChangeAmount,
      weightChangeRate: state.weightChangeRate,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      workoutDuration: state.workoutDuration,
      workoutDurationMin: state.workoutDurationMin,
      workoutDurationMax: state.workoutDurationMax,
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      workoutVariety: state.workoutVariety,
      progressionPace: state.progressionPace,
      sleepQuality: state.sleepQuality,
      obstacles: state.obstacles,
      nutritionGoals: state.nutritionGoals,
      dietaryRestrictions: state.dietaryRestrictions,
      interestedInFasting: interested,
      fastingProtocol: protocol,
      wakeTime: wakeTime ?? state.wakeTime,
      sleepTime: sleepTime ?? state.sleepTime,
    );
  }

  Future<void> setSleepQuality(String quality) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_sleepQuality', quality);
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      activityLevel: state.activityLevel,
      name: state.name,
      dateOfBirth: state.dateOfBirth,
      gender: state.gender,
      heightCm: state.heightCm,
      weightKg: state.weightKg,
      goalWeightKg: state.goalWeightKg,
      useMetricUnits: state.useMetricUnits,
      weightDirection: state.weightDirection,
      weightChangeAmount: state.weightChangeAmount,
      weightChangeRate: state.weightChangeRate,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      workoutDuration: state.workoutDuration,
      workoutDurationMin: state.workoutDurationMin,
      workoutDurationMax: state.workoutDurationMax,
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      workoutVariety: state.workoutVariety,
      progressionPace: state.progressionPace,
      sleepQuality: quality,
      obstacles: state.obstacles,
      nutritionGoals: state.nutritionGoals,
      dietaryRestrictions: state.dietaryRestrictions,
      mealsPerDay: state.mealsPerDay,
      interestedInFasting: state.interestedInFasting,
      fastingProtocol: state.fastingProtocol,
      wakeTime: state.wakeTime,
      sleepTime: state.sleepTime,
      primaryGoal: state.primaryGoal,
      nutritionEnabled: state.nutritionEnabled,
      limitations: state.limitations,
      muscleFocusPoints: state.muscleFocusPoints,
      pushupCapacity: state.pushupCapacity,
      pullupCapacity: state.pullupCapacity,
      plankCapacity: state.plankCapacity,
      squatCapacity: state.squatCapacity,
      cardioCapacity: state.cardioCapacity,
    );
  }

  Future<void> setObstacles(List<String> obstacles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('preAuth_obstacles', obstacles);
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      activityLevel: state.activityLevel,
      name: state.name,
      dateOfBirth: state.dateOfBirth,
      gender: state.gender,
      heightCm: state.heightCm,
      weightKg: state.weightKg,
      goalWeightKg: state.goalWeightKg,
      useMetricUnits: state.useMetricUnits,
      weightDirection: state.weightDirection,
      weightChangeAmount: state.weightChangeAmount,
      weightChangeRate: state.weightChangeRate,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      workoutDuration: state.workoutDuration,
      workoutDurationMin: state.workoutDurationMin,
      workoutDurationMax: state.workoutDurationMax,
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      workoutVariety: state.workoutVariety,
      progressionPace: state.progressionPace,
      sleepQuality: state.sleepQuality,
      obstacles: obstacles,
      nutritionGoals: state.nutritionGoals,
      dietaryRestrictions: state.dietaryRestrictions,
      mealsPerDay: state.mealsPerDay,
      interestedInFasting: state.interestedInFasting,
      fastingProtocol: state.fastingProtocol,
      wakeTime: state.wakeTime,
      sleepTime: state.sleepTime,
      primaryGoal: state.primaryGoal,
      nutritionEnabled: state.nutritionEnabled,
      limitations: state.limitations,
      muscleFocusPoints: state.muscleFocusPoints,
      pushupCapacity: state.pushupCapacity,
      pullupCapacity: state.pullupCapacity,
      plankCapacity: state.plankCapacity,
      squatCapacity: state.squatCapacity,
      cardioCapacity: state.cardioCapacity,
    );
  }

  Future<void> setDietaryRestrictions(List<String> restrictions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('preAuth_dietaryRestrictions', restrictions);
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      activityLevel: state.activityLevel,
      name: state.name,
      dateOfBirth: state.dateOfBirth,
      gender: state.gender,
      heightCm: state.heightCm,
      weightKg: state.weightKg,
      goalWeightKg: state.goalWeightKg,
      useMetricUnits: state.useMetricUnits,
      weightDirection: state.weightDirection,
      weightChangeAmount: state.weightChangeAmount,
      weightChangeRate: state.weightChangeRate,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      workoutDuration: state.workoutDuration,
      workoutDurationMin: state.workoutDurationMin,
      workoutDurationMax: state.workoutDurationMax,
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      workoutVariety: state.workoutVariety,
      progressionPace: state.progressionPace,
      sleepQuality: state.sleepQuality,
      obstacles: state.obstacles,
      nutritionGoals: state.nutritionGoals,
      dietaryRestrictions: restrictions,
      mealsPerDay: state.mealsPerDay,
      interestedInFasting: state.interestedInFasting,
      fastingProtocol: state.fastingProtocol,
      wakeTime: state.wakeTime,
      sleepTime: state.sleepTime,
      primaryGoal: state.primaryGoal,
      nutritionEnabled: state.nutritionEnabled,
      limitations: state.limitations,
      muscleFocusPoints: state.muscleFocusPoints,
      pushupCapacity: state.pushupCapacity,
      pullupCapacity: state.pullupCapacity,
      plankCapacity: state.plankCapacity,
      squatCapacity: state.squatCapacity,
      cardioCapacity: state.cardioCapacity,
    );
  }

  Future<void> setMealsPerDay(int meals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('preAuth_mealsPerDay', meals);
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      activityLevel: state.activityLevel,
      name: state.name,
      dateOfBirth: state.dateOfBirth,
      gender: state.gender,
      heightCm: state.heightCm,
      weightKg: state.weightKg,
      goalWeightKg: state.goalWeightKg,
      useMetricUnits: state.useMetricUnits,
      weightDirection: state.weightDirection,
      weightChangeAmount: state.weightChangeAmount,
      weightChangeRate: state.weightChangeRate,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      workoutDuration: state.workoutDuration,
      workoutDurationMin: state.workoutDurationMin,
      workoutDurationMax: state.workoutDurationMax,
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      workoutVariety: state.workoutVariety,
      progressionPace: state.progressionPace,
      sleepQuality: state.sleepQuality,
      obstacles: state.obstacles,
      nutritionGoals: state.nutritionGoals,
      dietaryRestrictions: state.dietaryRestrictions,
      mealsPerDay: meals,
      interestedInFasting: state.interestedInFasting,
      fastingProtocol: state.fastingProtocol,
      wakeTime: state.wakeTime,
      sleepTime: state.sleepTime,
      primaryGoal: state.primaryGoal,
      nutritionEnabled: state.nutritionEnabled,
      limitations: state.limitations,
      muscleFocusPoints: state.muscleFocusPoints,
      pushupCapacity: state.pushupCapacity,
      pullupCapacity: state.pullupCapacity,
      plankCapacity: state.plankCapacity,
      squatCapacity: state.squatCapacity,
      cardioCapacity: state.cardioCapacity,
    );
  }

  Future<void> setPushupCapacity(String capacity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_pushupCapacity', capacity);
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      activityLevel: state.activityLevel,
      name: state.name,
      dateOfBirth: state.dateOfBirth,
      gender: state.gender,
      heightCm: state.heightCm,
      weightKg: state.weightKg,
      goalWeightKg: state.goalWeightKg,
      useMetricUnits: state.useMetricUnits,
      weightDirection: state.weightDirection,
      weightChangeAmount: state.weightChangeAmount,
      weightChangeRate: state.weightChangeRate,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      workoutDuration: state.workoutDuration,
      workoutDurationMin: state.workoutDurationMin,
      workoutDurationMax: state.workoutDurationMax,
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      workoutVariety: state.workoutVariety,
      progressionPace: state.progressionPace,
      sleepQuality: state.sleepQuality,
      obstacles: state.obstacles,
      nutritionGoals: state.nutritionGoals,
      dietaryRestrictions: state.dietaryRestrictions,
      mealsPerDay: state.mealsPerDay,
      interestedInFasting: state.interestedInFasting,
      fastingProtocol: state.fastingProtocol,
      wakeTime: state.wakeTime,
      sleepTime: state.sleepTime,
      primaryGoal: state.primaryGoal,
      nutritionEnabled: state.nutritionEnabled,
      limitations: state.limitations,
      muscleFocusPoints: state.muscleFocusPoints,
      pushupCapacity: capacity,
      pullupCapacity: state.pullupCapacity,
      plankCapacity: state.plankCapacity,
      squatCapacity: state.squatCapacity,
      cardioCapacity: state.cardioCapacity,
    );
  }

  Future<void> setPullupCapacity(String capacity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_pullupCapacity', capacity);
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      activityLevel: state.activityLevel,
      name: state.name,
      dateOfBirth: state.dateOfBirth,
      gender: state.gender,
      heightCm: state.heightCm,
      weightKg: state.weightKg,
      goalWeightKg: state.goalWeightKg,
      useMetricUnits: state.useMetricUnits,
      weightDirection: state.weightDirection,
      weightChangeAmount: state.weightChangeAmount,
      weightChangeRate: state.weightChangeRate,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      workoutDuration: state.workoutDuration,
      workoutDurationMin: state.workoutDurationMin,
      workoutDurationMax: state.workoutDurationMax,
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      workoutVariety: state.workoutVariety,
      progressionPace: state.progressionPace,
      sleepQuality: state.sleepQuality,
      obstacles: state.obstacles,
      nutritionGoals: state.nutritionGoals,
      dietaryRestrictions: state.dietaryRestrictions,
      mealsPerDay: state.mealsPerDay,
      interestedInFasting: state.interestedInFasting,
      fastingProtocol: state.fastingProtocol,
      wakeTime: state.wakeTime,
      sleepTime: state.sleepTime,
      primaryGoal: state.primaryGoal,
      nutritionEnabled: state.nutritionEnabled,
      limitations: state.limitations,
      muscleFocusPoints: state.muscleFocusPoints,
      pushupCapacity: state.pushupCapacity,
      pullupCapacity: capacity,
      plankCapacity: state.plankCapacity,
      squatCapacity: state.squatCapacity,
      cardioCapacity: state.cardioCapacity,
    );
  }

  Future<void> setPlankCapacity(String capacity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_plankCapacity', capacity);
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      activityLevel: state.activityLevel,
      name: state.name,
      dateOfBirth: state.dateOfBirth,
      gender: state.gender,
      heightCm: state.heightCm,
      weightKg: state.weightKg,
      goalWeightKg: state.goalWeightKg,
      useMetricUnits: state.useMetricUnits,
      weightDirection: state.weightDirection,
      weightChangeAmount: state.weightChangeAmount,
      weightChangeRate: state.weightChangeRate,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      workoutDuration: state.workoutDuration,
      workoutDurationMin: state.workoutDurationMin,
      workoutDurationMax: state.workoutDurationMax,
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      workoutVariety: state.workoutVariety,
      progressionPace: state.progressionPace,
      sleepQuality: state.sleepQuality,
      obstacles: state.obstacles,
      nutritionGoals: state.nutritionGoals,
      dietaryRestrictions: state.dietaryRestrictions,
      mealsPerDay: state.mealsPerDay,
      interestedInFasting: state.interestedInFasting,
      fastingProtocol: state.fastingProtocol,
      wakeTime: state.wakeTime,
      sleepTime: state.sleepTime,
      primaryGoal: state.primaryGoal,
      nutritionEnabled: state.nutritionEnabled,
      limitations: state.limitations,
      muscleFocusPoints: state.muscleFocusPoints,
      pushupCapacity: state.pushupCapacity,
      pullupCapacity: state.pullupCapacity,
      plankCapacity: capacity,
      squatCapacity: state.squatCapacity,
      cardioCapacity: state.cardioCapacity,
    );
  }

  Future<void> setSquatCapacity(String capacity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_squatCapacity', capacity);
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      activityLevel: state.activityLevel,
      name: state.name,
      dateOfBirth: state.dateOfBirth,
      gender: state.gender,
      heightCm: state.heightCm,
      weightKg: state.weightKg,
      goalWeightKg: state.goalWeightKg,
      useMetricUnits: state.useMetricUnits,
      weightDirection: state.weightDirection,
      weightChangeAmount: state.weightChangeAmount,
      weightChangeRate: state.weightChangeRate,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      workoutDuration: state.workoutDuration,
      workoutDurationMin: state.workoutDurationMin,
      workoutDurationMax: state.workoutDurationMax,
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      workoutVariety: state.workoutVariety,
      progressionPace: state.progressionPace,
      sleepQuality: state.sleepQuality,
      obstacles: state.obstacles,
      nutritionGoals: state.nutritionGoals,
      dietaryRestrictions: state.dietaryRestrictions,
      mealsPerDay: state.mealsPerDay,
      interestedInFasting: state.interestedInFasting,
      fastingProtocol: state.fastingProtocol,
      wakeTime: state.wakeTime,
      sleepTime: state.sleepTime,
      primaryGoal: state.primaryGoal,
      nutritionEnabled: state.nutritionEnabled,
      limitations: state.limitations,
      muscleFocusPoints: state.muscleFocusPoints,
      pushupCapacity: state.pushupCapacity,
      pullupCapacity: state.pullupCapacity,
      plankCapacity: state.plankCapacity,
      squatCapacity: capacity,
      cardioCapacity: state.cardioCapacity,
    );
  }

  Future<void> setCardioCapacity(String capacity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_cardioCapacity', capacity);
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      activityLevel: state.activityLevel,
      name: state.name,
      dateOfBirth: state.dateOfBirth,
      gender: state.gender,
      heightCm: state.heightCm,
      weightKg: state.weightKg,
      goalWeightKg: state.goalWeightKg,
      useMetricUnits: state.useMetricUnits,
      weightDirection: state.weightDirection,
      weightChangeAmount: state.weightChangeAmount,
      weightChangeRate: state.weightChangeRate,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      workoutDuration: state.workoutDuration,
      workoutDurationMin: state.workoutDurationMin,
      workoutDurationMax: state.workoutDurationMax,
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      workoutVariety: state.workoutVariety,
      progressionPace: state.progressionPace,
      sleepQuality: state.sleepQuality,
      obstacles: state.obstacles,
      nutritionGoals: state.nutritionGoals,
      dietaryRestrictions: state.dietaryRestrictions,
      mealsPerDay: state.mealsPerDay,
      interestedInFasting: state.interestedInFasting,
      fastingProtocol: state.fastingProtocol,
      wakeTime: state.wakeTime,
      sleepTime: state.sleepTime,
      primaryGoal: state.primaryGoal,
      nutritionEnabled: state.nutritionEnabled,
      limitations: state.limitations,
      muscleFocusPoints: state.muscleFocusPoints,
      pushupCapacity: state.pushupCapacity,
      pullupCapacity: state.pullupCapacity,
      plankCapacity: state.plankCapacity,
      squatCapacity: state.squatCapacity,
      cardioCapacity: capacity,
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('preAuth_goals');
    await prefs.remove('preAuth_fitnessLevel');
    await prefs.remove('preAuth_trainingExperience');
    await prefs.remove('preAuth_activityLevel');
    await prefs.remove('preAuth_name');
    await prefs.remove('preAuth_dateOfBirth');
    await prefs.remove('preAuth_gender');
    await prefs.remove('preAuth_heightCm');
    await prefs.remove('preAuth_weightKg');
    await prefs.remove('preAuth_goalWeightKg');
    await prefs.remove('preAuth_useMetric');
    await prefs.remove('preAuth_weightDirection');
    await prefs.remove('preAuth_weightChangeAmount');
    await prefs.remove('preAuth_weightChangeRate');
    await prefs.remove('preAuth_daysPerWeek');
    await prefs.remove('preAuth_workoutDays');
    await prefs.remove('preAuth_workoutDuration');
    await prefs.remove('preAuth_workoutDurationMin');
    await prefs.remove('preAuth_workoutDurationMax');
    await prefs.remove('preAuth_equipment');
    await prefs.remove('preAuth_customEquipment');
    await prefs.remove('preAuth_workoutEnvironment');
    await prefs.remove('preAuth_trainingSplit');
    await prefs.remove('preAuth_motivations');
    await prefs.remove('preAuth_dumbbellCount');
    await prefs.remove('preAuth_kettlebellCount');
    await prefs.remove('preAuth_workoutTypePreference');
    await prefs.remove('preAuth_progressionPace');
    await prefs.remove('preAuth_sleepQuality');
    await prefs.remove('preAuth_obstacles');
    await prefs.remove('preAuth_nutritionGoals');
    await prefs.remove('preAuth_dietaryRestrictions');
    await prefs.remove('preAuth_mealsPerDay');
    await prefs.remove('preAuth_interestedInFasting');
    await prefs.remove('preAuth_fastingProtocol');
    await prefs.remove('preAuth_wakeTime');
    await prefs.remove('preAuth_sleepTime');
    await prefs.remove('preAuth_primaryGoal');
    await prefs.remove('preAuth_muscleFocusPoints');
    // Fitness assessment fields
    await prefs.remove('preAuth_pushupCapacity');
    await prefs.remove('preAuth_pullupCapacity');
    await prefs.remove('preAuth_plankCapacity');
    await prefs.remove('preAuth_squatCapacity');
    await prefs.remove('preAuth_cardioCapacity');
    state = PreAuthQuizData();
  }

  Future<void> setPrimaryGoal(String goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_primaryGoal', goal);
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      activityLevel: state.activityLevel,
      name: state.name,
      dateOfBirth: state.dateOfBirth,
      gender: state.gender,
      heightCm: state.heightCm,
      weightKg: state.weightKg,
      goalWeightKg: state.goalWeightKg,
      useMetricUnits: state.useMetricUnits,
      weightDirection: state.weightDirection,
      weightChangeAmount: state.weightChangeAmount,
      weightChangeRate: state.weightChangeRate,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      workoutDuration: state.workoutDuration,
      workoutDurationMin: state.workoutDurationMin,
      workoutDurationMax: state.workoutDurationMax,
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      workoutVariety: state.workoutVariety,
      progressionPace: state.progressionPace,
      sleepQuality: state.sleepQuality,
      obstacles: state.obstacles,
      nutritionGoals: state.nutritionGoals,
      dietaryRestrictions: state.dietaryRestrictions,
      mealsPerDay: state.mealsPerDay,
      interestedInFasting: state.interestedInFasting,
      fastingProtocol: state.fastingProtocol,
      wakeTime: state.wakeTime,
      sleepTime: state.sleepTime,
      primaryGoal: goal,
      muscleFocusPoints: state.muscleFocusPoints,
      pushupCapacity: state.pushupCapacity,
      pullupCapacity: state.pullupCapacity,
      plankCapacity: state.plankCapacity,
      squatCapacity: state.squatCapacity,
      cardioCapacity: state.cardioCapacity,
    );
  }

  Future<void> setMuscleFocusPoints(Map<String, int> points) async {
    final prefs = await SharedPreferences.getInstance();
    // Store as query string format: "triceps=2&lats=1&obliques=2"
    final encoded = points.entries.map((e) => '${e.key}=${e.value}').join('&');
    await prefs.setString('preAuth_muscleFocusPoints', encoded);
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      activityLevel: state.activityLevel,
      name: state.name,
      dateOfBirth: state.dateOfBirth,
      gender: state.gender,
      heightCm: state.heightCm,
      weightKg: state.weightKg,
      goalWeightKg: state.goalWeightKg,
      useMetricUnits: state.useMetricUnits,
      weightDirection: state.weightDirection,
      weightChangeAmount: state.weightChangeAmount,
      weightChangeRate: state.weightChangeRate,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      workoutDuration: state.workoutDuration,
      workoutDurationMin: state.workoutDurationMin,
      workoutDurationMax: state.workoutDurationMax,
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      workoutVariety: state.workoutVariety,
      progressionPace: state.progressionPace,
      sleepQuality: state.sleepQuality,
      obstacles: state.obstacles,
      nutritionGoals: state.nutritionGoals,
      dietaryRestrictions: state.dietaryRestrictions,
      mealsPerDay: state.mealsPerDay,
      interestedInFasting: state.interestedInFasting,
      fastingProtocol: state.fastingProtocol,
      wakeTime: state.wakeTime,
      sleepTime: state.sleepTime,
      primaryGoal: state.primaryGoal,
      muscleFocusPoints: points,
      nutritionEnabled: state.nutritionEnabled,
      limitations: state.limitations,
    );
  }

  Future<void> setNutritionEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('preAuth_nutritionEnabled', enabled);
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      activityLevel: state.activityLevel,
      name: state.name,
      dateOfBirth: state.dateOfBirth,
      gender: state.gender,
      heightCm: state.heightCm,
      weightKg: state.weightKg,
      goalWeightKg: state.goalWeightKg,
      useMetricUnits: state.useMetricUnits,
      weightDirection: state.weightDirection,
      weightChangeAmount: state.weightChangeAmount,
      weightChangeRate: state.weightChangeRate,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      workoutDuration: state.workoutDuration,
      workoutDurationMin: state.workoutDurationMin,
      workoutDurationMax: state.workoutDurationMax,
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      workoutVariety: state.workoutVariety,
      progressionPace: state.progressionPace,
      sleepQuality: state.sleepQuality,
      obstacles: state.obstacles,
      nutritionGoals: state.nutritionGoals,
      dietaryRestrictions: state.dietaryRestrictions,
      mealsPerDay: state.mealsPerDay,
      interestedInFasting: state.interestedInFasting,
      fastingProtocol: state.fastingProtocol,
      wakeTime: state.wakeTime,
      sleepTime: state.sleepTime,
      primaryGoal: state.primaryGoal,
      muscleFocusPoints: state.muscleFocusPoints,
      nutritionEnabled: enabled,
      limitations: state.limitations,
    );
  }

  Future<void> setLimitations(List<String> limitations) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('preAuth_limitations', limitations);
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      activityLevel: state.activityLevel,
      name: state.name,
      dateOfBirth: state.dateOfBirth,
      gender: state.gender,
      heightCm: state.heightCm,
      weightKg: state.weightKg,
      goalWeightKg: state.goalWeightKg,
      useMetricUnits: state.useMetricUnits,
      weightDirection: state.weightDirection,
      weightChangeAmount: state.weightChangeAmount,
      weightChangeRate: state.weightChangeRate,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      workoutDuration: state.workoutDuration,
      workoutDurationMin: state.workoutDurationMin,
      workoutDurationMax: state.workoutDurationMax,
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      workoutVariety: state.workoutVariety,
      progressionPace: state.progressionPace,
      sleepQuality: state.sleepQuality,
      obstacles: state.obstacles,
      nutritionGoals: state.nutritionGoals,
      dietaryRestrictions: state.dietaryRestrictions,
      mealsPerDay: state.mealsPerDay,
      interestedInFasting: state.interestedInFasting,
      fastingProtocol: state.fastingProtocol,
      wakeTime: state.wakeTime,
      sleepTime: state.sleepTime,
      primaryGoal: state.primaryGoal,
      muscleFocusPoints: state.muscleFocusPoints,
      nutritionEnabled: state.nutritionEnabled,
      limitations: limitations,
    );
  }

  Future<void> setWorkoutEnvironment(String environment) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_workoutEnvironment', environment);
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      activityLevel: state.activityLevel,
      name: state.name,
      dateOfBirth: state.dateOfBirth,
      gender: state.gender,
      heightCm: state.heightCm,
      weightKg: state.weightKg,
      goalWeightKg: state.goalWeightKg,
      useMetricUnits: state.useMetricUnits,
      weightDirection: state.weightDirection,
      weightChangeAmount: state.weightChangeAmount,
      weightChangeRate: state.weightChangeRate,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      workoutDuration: state.workoutDuration,
      workoutDurationMin: state.workoutDurationMin,
      workoutDurationMax: state.workoutDurationMax,
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: environment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      workoutVariety: state.workoutVariety,
      progressionPace: state.progressionPace,
      sleepQuality: state.sleepQuality,
      obstacles: state.obstacles,
      nutritionGoals: state.nutritionGoals,
      dietaryRestrictions: state.dietaryRestrictions,
      mealsPerDay: state.mealsPerDay,
      interestedInFasting: state.interestedInFasting,
      fastingProtocol: state.fastingProtocol,
      wakeTime: state.wakeTime,
      sleepTime: state.sleepTime,
      primaryGoal: state.primaryGoal,
      muscleFocusPoints: state.muscleFocusPoints,
      nutritionEnabled: state.nutritionEnabled,
      limitations: state.limitations,
    );
  }

  Future<void> setIsComplete(bool isComplete) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('preAuth_isComplete', isComplete);
    // isComplete is a computed getter, so we don't need to set it
    // Just save the preference for persistence
  }
}

/// Pre-auth quiz screen with 6 animated questions
class PreAuthQuizScreen extends ConsumerStatefulWidget {
  const PreAuthQuizScreen({super.key});

  @override
  ConsumerState<PreAuthQuizScreen> createState() => _PreAuthQuizScreenState();
}

class _PreAuthQuizScreenState extends ConsumerState<PreAuthQuizScreen>
    with TickerProviderStateMixin {
  int _currentQuestion = 0;

  // Feature flag for conditional workout days screen
  static const bool _featureFlagWorkoutDays = false;

  // Dynamic total - 13 screens base, minus 1 if workout days feature disabled
  // New flow: 0-Goals, 1-Fitness+Exp, 2-Schedule, 3-WorkoutDays[COND], 4-Equipment,
  //           5-Limitations, 6-PrimaryGoal+Generate, 7-PersonalizationGate, 8-MuscleFocus,
  //           9-TrainingStyle, 10-Progression(pace), 11-NutritionGate, 12-NutritionDetails
  int get _totalQuestions {
    int total = 13; // New flow: 13 screens total
    if (!_featureFlagWorkoutDays) {
      total -= 1; // Skip Screen 3 (Workout Days)
    }
    return total;
  }

  // Question 1: Goals (multi-select)
  final Set<String> _selectedGoals = {};
  // Question 2: Fitness Level + Training Experience
  String? _selectedLevel;
  String? _selectedTrainingExperience;
  // Question 3: Body Metrics (name, DOB, gender, height, weight, goal weight)
  String? _name;
  DateTime? _dateOfBirth;
  String? _gender;  // 'male', 'female', or 'other'
  double? _heightCm;
  double? _weightKg;
  double? _goalWeightKg;
  bool _useMetric = true;
  // Two-step weight goal
  String? _weightDirection;  // lose, gain, maintain
  double? _weightChangeAmount;  // Amount to change in kg
  String? _weightChangeRate;  // slow, moderate, fast
  // Activity level (added to fitness level screen)
  String? _selectedActivityLevel;
  // Lifestyle (Sleep quality and Obstacles)
  String? _selectedSleepQuality;
  final Set<String> _selectedObstacles = {};
  // Dietary restrictions (added to nutrition goals screen)
  final Set<String> _selectedDietaryRestrictions = {};
  // Question 4: Days per week + which days + duration
  int? _selectedDays;
  final Set<int> _selectedWorkoutDays = {};
  int? _workoutDurationMin;  // Min duration in minutes (e.g., 45 for "45-60" range)
  int? _workoutDurationMax;  // Max duration in minutes (e.g., 60 for "45-60" range)
  // Question 5: Equipment
  final Set<String> _selectedEquipment = {};
  final Set<String> _otherSelectedEquipment = {};
  final List<String> _customEquipment = [];  // User-added equipment not in predefined list
  int _dumbbellCount = 2;
  int _kettlebellCount = 1;
  String? _selectedEnvironment;  // Workout environment (home, home_gym, commercial_gym, hotel)
  // Question 6: Training Preferences (Split + Workout Type + Variety + Progression Pace)
  String? _selectedTrainingSplit;
  String? _selectedWorkoutType;
  String? _selectedWorkoutVariety;  // 'consistent' or 'varied'
  String? _selectedProgressionPace;
  // Question 7: Nutrition Goals
  final Set<String> _selectedNutritionGoals = {};
  int? _mealsPerDay;  // 4, 5, or 6 meals per day
  // Question 8: Fasting Interest & Protocol
  bool? _interestedInFasting;
  String? _selectedFastingProtocol;
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _sleepTime = const TimeOfDay(hour: 23, minute: 0);
  // Question 9: Motivations
  final Set<String> _selectedMotivations = {};
  // Question 10: Primary Goal (muscle_hypertrophy, muscle_strength, strength_hypertrophy)
  String? _selectedPrimaryGoal;
  // Question 11: Muscle Focus Points (max 5 total)
  Map<String, int> _muscleFocusPoints = {};

  // NEW: Phase 2 and Phase 3 tracking
  bool _skipPersonalization = false;  // Track if user skipped Phase 2
  bool? _nutritionEnabled;  // Track nutrition opt-in
  final Set<String> _selectedLimitations = {'none'};  // Physical limitations (default: none)
  String? _customLimitation;  // Custom limitation text when "Other" is selected

  // Background pre-generation: starts after Screen 6 (PrimaryGoal) while user goes through optional screens
  Completer<Workout?>? _backgroundGenerationCompleter;
  StreamSubscription<WorkoutGenerationProgress>? _backgroundGenerationSub;

  late AnimationController _progressController;
  late AnimationController _questionController;

  /// Calculate age from date of birth
  int _calculateAge(DateTime dateOfBirth) {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _questionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _questionController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndResetIfNeeded();
    });
  }

  Future<void> _checkAndResetIfNeeded() async {
    final quizData = ref.read(preAuthQuizProvider);
    final authState = ref.read(authStateProvider);

    if (authState.status == AuthStatus.authenticated &&
        authState.user != null &&
        !quizData.isComplete) {
      debugPrint('Resetting backend onboarding data...');
      ref.read(onboardingStateProvider.notifier).reset();

      try {
        final apiClient = ref.read(apiClientProvider);
        await apiClient.post('${ApiConstants.users}/${authState.user!.id}/reset-onboarding');
      } catch (e) {
        debugPrint('Failed to reset backend onboarding: $e');
        // Don't navigate away on failure - the user is already on the quiz
      }
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _questionController.dispose();
    _backgroundGenerationSub?.cancel();
    super.dispose();
  }

  /// Calculate progress value with phase-aware behavior
  /// Phase 1 (0-5): Show 0-100% progress
  /// Phase 2 & 3 (6+): Stay at 100% to show Phase 1 completion
  double get _progress {
    if (_currentQuestion <= 6) {
      return (_currentQuestion + 1) / 7;  // Phase 1 only (7 screens: 0-6)
    }
    return 1.0;  // User-selected: Fill to 100% for optional phases
  }

  void _nextQuestion() async {
    HapticFeedback.mediumImpact();

    await _saveCurrentQuestionData();

    // Log analytics for current screen
    AnalyticsService.logScreenView('onboarding_screen_$_currentQuestion');

    // Special handling for Screen 2 -> Skip Screen 3 if feature flag disabled
    if (_currentQuestion == 2 && !_featureFlagWorkoutDays) {
      setState(() => _currentQuestion = 4); // Skip to equipment
      _questionController.forward(from: 0);
      return;
    }

    // Special handling for Screen 6 (Primary Goal + Generate Preview)
    // Note: This should be triggered by button in _buildPrimaryGoal, not auto-advance
    // The preview screen will handle navigation to Screen 7 or 11

    // Check if this is the last question (screen 12 - Nutrition Details)
    // Note: _totalQuestions adjusts for feature flags but screen indices stay fixed (0-12)
    if (_currentQuestion == 12) {
      _finishOnboarding();
      return;
    }

    setState(() {
      _currentQuestion++;
    });
    _questionController.forward(from: 0);
  }

  Future<void> _saveCurrentQuestionData() async {
    // 13-SCREEN FLOW (Progressive Profiling)
    // Phase 1 (Required): 0-Goals, 1-Fitness+Experience, 2-Schedule, 3-WorkoutDays[COND], 4-Equipment, 5-Limitations, 6-PrimaryGoal+Generate
    // Phase 2 (Optional): 7-PersonalizationGate, 8-MuscleFocus, 9-TrainingStyle, 10-Progression(pace)
    // Phase 3 (Optional): 11-NutritionGate, 12-NutritionDetails

    switch (_currentQuestion) {
      // PHASE 1: REQUIRED (Screens 0-6)
      case 0: // Goals (multi-select)
        if (_selectedGoals.isNotEmpty) {
          await ref.read(preAuthQuizProvider.notifier).setGoals(_selectedGoals.toList());
        }
        break;

      case 1: // Fitness Level + Training Experience (optional)
        if (_selectedLevel != null) {
          await ref.read(preAuthQuizProvider.notifier).setFitnessLevel(_selectedLevel!);
        }
        if (_selectedTrainingExperience != null) {
          await ref.read(preAuthQuizProvider.notifier).setTrainingExperience(_selectedTrainingExperience!);
        }
        if (_selectedActivityLevel != null) {
          await ref.read(preAuthQuizProvider.notifier).setActivityLevel(_selectedActivityLevel!);
        }
        break;

      case 2: // Schedule (days/week + duration)
        await _saveDaysData();
        break;

      case 3: // Workout Days [CONDITIONAL - only if feature flag enabled]
        if (_featureFlagWorkoutDays && _selectedWorkoutDays.isNotEmpty) {
          await ref.read(preAuthQuizProvider.notifier).setWorkoutDays(_selectedWorkoutDays.toList()..sort());
        }
        break;

      case 4: // Equipment (environment + equipment list)
        await _saveEquipmentData();
        if (_selectedEnvironment != null) {
          await ref.read(preAuthQuizProvider.notifier).setWorkoutEnvironment(_selectedEnvironment!);
        }
        break;

      case 5: // Injuries/Limitations (NEW POSITION - moved from old Screen 9)
        if (_selectedLimitations.isNotEmpty) {
          final limitationsList = _selectedLimitations.toList();
          if (_selectedLimitations.contains('other') && _customLimitation != null && _customLimitation!.isNotEmpty) {
            limitationsList.remove('other');
            limitationsList.add('other: $_customLimitation');
          }
          await ref.read(preAuthQuizProvider.notifier).setLimitations(limitationsList);
        }
        break;

      case 6: // Primary Goal (saved when user clicks "Generate My First Workout")
        if (_selectedPrimaryGoal != null) {
          await ref.read(preAuthQuizProvider.notifier).setPrimaryGoal(_selectedPrimaryGoal!);
        }
        break;

      // PHASE 2: OPTIONAL PERSONALIZATION (Screens 7-10)
      case 7: // Personalization Gate (no data to save, just navigation)
        break;

      case 8: // Muscle Focus Points
        await _saveMuscleFocusData();
        break;

      case 9: // Training Style (split + workout type + variety)
        if (_selectedTrainingSplit != null) {
          await ref.read(preAuthQuizProvider.notifier).setTrainingSplit(_selectedTrainingSplit!);
        }
        if (_selectedWorkoutType != null) {
          await ref.read(preAuthQuizProvider.notifier).setWorkoutTypePreference(_selectedWorkoutType!);
        }
        if (_selectedWorkoutVariety != null) {
          await ref.read(preAuthQuizProvider.notifier).setWorkoutVariety(_selectedWorkoutVariety!);
        }
        break;

      case 10: // Progression pace only (limitations moved to Screen 5)
        if (_selectedProgressionPace != null) {
          await ref.read(preAuthQuizProvider.notifier).setProgressionPace(_selectedProgressionPace!);
        }
        break;

      // PHASE 3: OPTIONAL NUTRITION (Screens 11-12)
      case 11: // Nutrition Opt-In Gate (handled in button callbacks)
        break;

      case 12: // Nutrition Details (merged nutrition + fasting)
        await _saveNutritionData();
        await _saveFastingData();
        break;
    }
  }

  Future<void> _saveDaysData() async {
    debugPrint('🔍 [Quiz] Saving days data: days=$_selectedDays, duration=$_workoutDurationMin-$_workoutDurationMax');
    if (_selectedDays != null) {
      await ref.read(preAuthQuizProvider.notifier).setDaysPerWeek(_selectedDays!);
    }
    if (_selectedWorkoutDays.isNotEmpty) {
      await ref.read(preAuthQuizProvider.notifier).setWorkoutDays(_selectedWorkoutDays.toList()..sort());
    }
    if (_workoutDurationMin != null && _workoutDurationMax != null) {
      await ref.read(preAuthQuizProvider.notifier).setWorkoutDuration(_workoutDurationMin!, _workoutDurationMax!);
      debugPrint('✅ [Quiz] Saved workout duration range: $_workoutDurationMin-$_workoutDurationMax min');
    } else {
      debugPrint('⚠️ [Quiz] workoutDuration is null, not saving!');
    }
  }

  Future<void> _saveEquipmentData() async {
    if (_selectedEquipment.isNotEmpty || _otherSelectedEquipment.isNotEmpty) {
      final hasFullGym = _selectedEquipment.contains('full_gym');
      final allEquipment = {..._selectedEquipment, ..._otherSelectedEquipment}.toList();
      await ref.read(preAuthQuizProvider.notifier).setEquipment(
        allEquipment,
        dumbbellCount: _selectedEquipment.contains('dumbbells') ? (hasFullGym ? 2 : _dumbbellCount) : null,
        kettlebellCount: _selectedEquipment.contains('kettlebell') ? (hasFullGym ? 2 : _kettlebellCount) : null,
        customEquipment: _customEquipment.isNotEmpty ? _customEquipment : null,
      );
    }
  }

  Future<void> _saveTrainingPreferencesData() async {
    if (_selectedTrainingSplit != null) {
      await ref.read(preAuthQuizProvider.notifier).setTrainingSplit(_selectedTrainingSplit!);
    }
    if (_selectedWorkoutType != null) {
      await ref.read(preAuthQuizProvider.notifier).setWorkoutTypePreference(_selectedWorkoutType!);
    }
    if (_selectedProgressionPace != null) {
      await ref.read(preAuthQuizProvider.notifier).setProgressionPace(_selectedProgressionPace!);
    }
    if (_selectedSleepQuality != null) {
      await ref.read(preAuthQuizProvider.notifier).setSleepQuality(_selectedSleepQuality!);
    }
    if (_selectedObstacles.isNotEmpty) {
      await ref.read(preAuthQuizProvider.notifier).setObstacles(_selectedObstacles.toList());
    }
  }

  Future<void> _saveNutritionData() async {
    if (_selectedNutritionGoals.isNotEmpty) {
      await ref.read(preAuthQuizProvider.notifier).setNutritionGoals(_selectedNutritionGoals.toList());
    }
    if (_selectedDietaryRestrictions.isNotEmpty) {
      await ref.read(preAuthQuizProvider.notifier).setDietaryRestrictions(_selectedDietaryRestrictions.toList());
    }
    if (_mealsPerDay != null) {
      await ref.read(preAuthQuizProvider.notifier).setMealsPerDay(_mealsPerDay!);
    }
  }

  Future<void> _saveFastingData() async {
    if (_interestedInFasting != null) {
      String formatTime(TimeOfDay time) {
        return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      }
      await ref.read(preAuthQuizProvider.notifier).setFastingPreferences(
        interested: _interestedInFasting!,
        protocol: _selectedFastingProtocol,
        wakeTime: formatTime(_wakeTime),
        sleepTime: formatTime(_sleepTime),
      );
    }
  }

  Future<void> _saveMotivationData() async {
    if (_selectedMotivations.isNotEmpty) {
      await ref.read(preAuthQuizProvider.notifier).setMotivations(_selectedMotivations.toList());
    }
  }

  Future<void> _savePrimaryGoalData() async {
    if (_selectedPrimaryGoal != null) {
      await ref.read(preAuthQuizProvider.notifier).setPrimaryGoal(_selectedPrimaryGoal!);
    }
  }

  Future<void> _saveMuscleFocusData() async {
    // Save even if empty - clearing all focus points is valid
    await ref.read(preAuthQuizProvider.notifier).setMuscleFocusPoints(_muscleFocusPoints);
  }

  /// Generate workout preview and navigate to plan preview screen
  ///
  /// Shows instant template-based preview without waiting for AI generation
  /// Start background workout generation via the streaming API.
  /// Called after the user completes Screen 6 (PrimaryGoal).
  /// The result is stored in a Completer that the WorkoutGenerationScreen can check.
  void _startBackgroundGeneration() {
    // Don't start if already running
    if (_backgroundGenerationCompleter != null && !_backgroundGenerationCompleter!.isCompleted) {
      debugPrint('⚠️ [Onboarding] Background generation already in progress');
      return;
    }

    _backgroundGenerationCompleter = Completer<Workout?>();
    // Store in provider so WorkoutGenerationScreen can access it
    ref.read(backgroundGenerationProvider.notifier).state = _backgroundGenerationCompleter;

    () async {
      try {
        final apiClient = ref.read(apiClientProvider);
        final userId = await apiClient.getUserId();
        if (userId == null) {
          debugPrint('⚠️ [Onboarding] No userId for background generation');
          _backgroundGenerationCompleter?.complete(null);
          return;
        }

        final quizData = ref.read(preAuthQuizProvider);
        final workoutDuration = quizData.workoutDuration ?? 45;

        // Calculate duration range
        int? durationMin;
        int? durationMax;
        if (workoutDuration == 30) {
          durationMax = 30;
        } else if (workoutDuration == 45) {
          durationMin = 30;
          durationMax = 45;
        } else if (workoutDuration == 60) {
          durationMin = 45;
          durationMax = 60;
        } else if (workoutDuration == 75) {
          durationMin = 60;
          durationMax = 75;
        } else if (workoutDuration == 90) {
          durationMin = 75;
          durationMax = 90;
        }

        final repository = ref.read(workoutRepositoryProvider);
        final todayLocal = DateTime.now().toIso8601String().substring(0, 10);

        debugPrint('🚀 [Onboarding] Starting background workout generation');
        final stream = repository.generateWorkoutStreaming(
          userId: userId,
          durationMinutes: workoutDuration,
          durationMinutesMin: durationMin,
          durationMinutesMax: durationMax,
          scheduledDate: todayLocal,
        );

        _backgroundGenerationSub = stream.listen(
          (progress) {
            if (progress.status == WorkoutGenerationStatus.completed && progress.workout != null) {
              debugPrint('✅ [Onboarding] Background generation complete: ${progress.workout!.name}');
              if (!_backgroundGenerationCompleter!.isCompleted) {
                _backgroundGenerationCompleter!.complete(progress.workout);
              }
            }
          },
          onError: (error) {
            debugPrint('❌ [Onboarding] Background generation error: $error');
            if (!_backgroundGenerationCompleter!.isCompleted) {
              _backgroundGenerationCompleter!.complete(null);
            }
          },
          onDone: () {
            if (!_backgroundGenerationCompleter!.isCompleted) {
              _backgroundGenerationCompleter!.complete(null);
            }
          },
        );
      } catch (e) {
        debugPrint('❌ [Onboarding] Background generation exception: $e');
        if (!_backgroundGenerationCompleter!.isCompleted) {
          _backgroundGenerationCompleter!.complete(null);
        }
      }
    }();
  }

  Future<void> _generateAndShowPreview() async {
    try {
      // Save current primary goal selection
      await _saveCurrentQuestionData();

      // Log analytics
      AnalyticsService.logWorkoutGenerated(
        primaryGoal: _selectedPrimaryGoal ?? 'unknown',
        duration: _workoutDurationMax ?? 60,
        equipment: _selectedEquipment.toList(),
      );

      // Get current quiz data
      final quizData = ref.read(preAuthQuizProvider);

      if (!mounted) return;

      // Generate instant template-based workout preview
      final templateWorkout = TemplateWorkoutGenerator.generateTemplateWorkout(quizData);

      debugPrint('✅ [Onboarding] Generated template workout: ${templateWorkout.name}');
      debugPrint('   Exercises: ${templateWorkout.exercises.length}');
      debugPrint('   Duration: ${templateWorkout.estimatedDurationMinutes} min');

      // Kick off background AI generation while user reviews preview
      _startBackgroundGeneration();

      // Show plan preview immediately with template workout
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PlanPreviewScreen(
            quizData: quizData,
            generatedWorkout: templateWorkout,
            onContinue: () {
              Navigator.of(context).pop();
              setState(() => _currentQuestion = 7); // Go to personalization gate
              _questionController.forward(from: 0);
            },
            onStartNow: () {
              Navigator.of(context).pop();
              setState(() {
                _skipPersonalization = true;
                _currentQuestion = 11; // Skip to nutrition gate
              });
              _questionController.forward(from: 0);
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ [Onboarding] Failed to generate preview: $e');
      // Show error and stay on current screen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate workout: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Finish onboarding and navigate to coach selection
  Future<void> _finishOnboarding() async {
    try {
      // Save final screen data
      await _saveCurrentQuestionData();

      // Mark onboarding as complete
      await ref.read(preAuthQuizProvider.notifier).setIsComplete(true);

      // Log analytics
      final skippedScreens = _skipPersonalization ? 4 : 0; // Screens 7-10 skipped
      AnalyticsService.logOnboardingCompleted(
        totalScreens: _totalQuestions,
        skippedScreens: skippedScreens,
        nutritionOptedIn: _nutritionEnabled ?? false,
        personalizationCompleted: !_skipPersonalization,
      );

      // Navigate to sign-in screen (user must create account before coach selection)
      // Flow: Pre-Auth Quiz → Sign In → Coach Selection → Paywall → Home
      if (mounted) {
        context.go('/sign-in');
      }
    } catch (e) {
      debugPrint('❌ [Onboarding] Failed to finish onboarding: $e');
      // Show error but still try to navigate
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save onboarding data. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _previousQuestion() {
    if (_currentQuestion > 0) {
      HapticFeedback.lightImpact();
      setState(() {
        // If on nutrition gate (11) and personalization was skipped,
        // jump back to personalization gate (7) instead of question 10
        if (_currentQuestion == 11 && _skipPersonalization) {
          _currentQuestion = 7;
        } else {
          _currentQuestion--;
        }
      });
      _questionController.forward(from: 0);
    }
  }

  bool get _canProceed {
    // 13-SCREEN FLOW (Progressive Profiling)
    // Phase 1 (Required): 0-Goals, 1-Fitness+Exp, 2-Schedule, 3-WorkoutDays[COND], 4-Equipment, 5-Limitations, 6-PrimaryGoal+Generate
    // Phase 2 (Optional): 7-PersonalizationGate, 8-MuscleFocus, 9-TrainingStyle, 10-Progression(pace)
    // Phase 3 (Optional): 11-NutritionGate, 12-NutritionDetails

    switch (_currentQuestion) {
      // PHASE 1: REQUIRED (Screens 0-6)
      case 0: // Goals (must select at least 1)
        return _selectedGoals.isNotEmpty;

      case 1: // Fitness Level + Training Experience (fitness required, experience optional)
        return _selectedLevel != null;

      case 2: // Schedule (days/week + duration both required)
        return _selectedDays != null && _workoutDurationMax != null;

      case 3: // Workout Days [CONDITIONAL - only if feature flag enabled]
        if (_featureFlagWorkoutDays) {
          return _selectedWorkoutDays.length >= (_selectedDays ?? 0);
        }
        return true;

      case 4: // Equipment (must select environment + at least 1 equipment)
        return _selectedEnvironment != null &&
               (_selectedEquipment.isNotEmpty || _otherSelectedEquipment.isNotEmpty);

      case 5: // Injuries/Limitations (always valid - defaults to 'none')
        return true;

      case 6: // Primary Goal (must select 1, but "Generate" button handles navigation)
        return _selectedPrimaryGoal != null;

      // PHASE 2: OPTIONAL PERSONALIZATION (Screens 7-10, all optional)
      case 7: // Personalization Gate (no validation, just navigation)
        return true;

      case 8: // Muscle Focus Points (optional, 0-5 total)
        final totalPoints = _muscleFocusPoints.values.fold(0, (sum, val) => sum + val);
        return totalPoints <= 5;

      case 9: // Training Style (optional)
        return true;

      case 10: // Progression pace (optional)
        return true;

      // PHASE 3: OPTIONAL NUTRITION (Screens 11-12)
      case 11: // Nutrition Opt-In Gate (no validation, buttons handle navigation)
        return true;

      case 12: // Nutrition Details (all optional)
        return true;

      default:
        return false;
    }
  }

  /// Get the title for a given quiz step (used by FoldableQuizScaffold left pane).
  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'What are your fitness goals?';
      case 1:
        return "What's your current fitness level?";
      case 2:
        return 'How many days per week can you train?';
      case 3:
        return 'Which days work best?';
      case 4:
        return 'What equipment do you have access to?';
      case 5:
        return 'Any injuries or limitations?';
      case 6:
        return 'What is your primary training focus?';
      case 7:
        return 'Personalize Your Plan';
      case 8:
        return 'Would you like to give extra focus to any muscles?';
      case 9:
        return 'Training Style';
      case 10:
        return 'Progression Pace';
      case 11:
        return 'Nutrition Setup';
      case 12:
        return 'What are your nutrition goals?';
      default:
        return '';
    }
  }

  /// Get the subtitle for a given quiz step.
  String? _getStepSubtitle(int step) {
    switch (step) {
      case 0:
        return 'Select all that apply';
      case 1:
        return "Be honest - we'll adjust as you progress";
      case 2:
        return 'Consistency beats intensity - pick what you can maintain';
      case 3:
        return 'Select ${_selectedDays ?? 0} days for your workouts';
      case 4:
        return "Select all that apply - we'll design workouts around what you have";
      case 5:
        return "We'll avoid exercises that stress these areas";
      case 6:
        return 'This helps us customize your workout intensity and rep ranges';
      case 8:
        return 'Allocate up to 5 focus points to prioritize specific muscle groups';
      case 9:
        return 'Choose how you want to structure your workouts';
      case 10:
        return 'How fast do you want to progress?';
      case 12:
        return 'Select all that apply';
      default:
        return null;
    }
  }

  /// Extra widget shown in the scaffold's left pane (foldable only).
  /// Used for info buttons that belong near the question title.
  Widget? _getStepHeaderExtra(BuildContext context, int step) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    Widget buildTip({
      required IconData icon,
      required Color color,
      required String title,
      required String body,
      List<({IconData icon, String text})>? bullets,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (bullets != null) ...[
            const SizedBox(height: 12),
            ...bullets.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(b.icon, size: 15, color: color.withValues(alpha: 0.7)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          b.text,
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      );
    }

    switch (step) {
      case 0:
        return buildTip(
          icon: Icons.flag_rounded,
          color: AppColors.orange,
          title: 'Your goals shape everything',
          body: 'We use your goals to determine training split, exercise selection, and how fast you progress.',
          bullets: [
            (icon: Icons.fitness_center, text: 'Exercise type & volume'),
            (icon: Icons.speed, text: 'Intensity & rest periods'),
            (icon: Icons.trending_up, text: 'Weekly progression rate'),
          ],
        );
      case 1:
        return buildTip(
          icon: Icons.person_outline,
          color: const Color(0xFF3B82F6),
          title: 'Calibrating your baseline',
          body: 'Fitness level helps set the right starting point — proper weights, rep ranges, and exercise complexity.',
        );
      case 2:
        return buildTip(
          icon: Icons.calendar_today_rounded,
          color: AppColors.green,
          title: 'Consistency beats intensity',
          body: 'We\'ll build the optimal training split for your schedule. More days isn\'t always better — recovery matters.',
          bullets: [
            (icon: Icons.looks_two, text: '2-3 days → Full Body'),
            (icon: Icons.looks_4, text: '4 days → Upper/Lower'),
            (icon: Icons.looks_5, text: '5-6 days → Push/Pull/Legs'),
          ],
        );
      case 3:
        return buildTip(
          icon: Icons.event_available,
          color: const Color(0xFFA855F7),
          title: 'Smart scheduling',
          body: 'Your chosen days help us space workouts optimally for muscle recovery between sessions.',
        );
      case 4:
        return buildTip(
          icon: Icons.home_rounded,
          color: isDark ? AppColors.cyan : AppColorsLight.cyan,
          title: 'Matched to your setup',
          body: 'Every exercise will be chosen based on what equipment you actually have. No substitutions needed.',
          bullets: [
            (icon: Icons.check_circle_outline, text: 'Only exercises you can do'),
            (icon: Icons.swap_horiz, text: 'Smart alternatives when needed'),
          ],
        );
      case 5:
        return buildTip(
          icon: Icons.shield_outlined,
          color: AppColors.green,
          title: 'Safety first',
          body: 'Telling us about injuries ensures we avoid exercises that could cause pain or setbacks.',
        );
      case 6:
        return QuizPrimaryGoal.buildInfoButton(context);
      case 7:
        return buildTip(
          icon: Icons.tune_rounded,
          color: AppColors.orange,
          title: 'Fine-tuning your plan',
          body: 'These optional details make your workouts even more personalized. Skip if you prefer AI defaults.',
        );
      case 8:
        return buildTip(
          icon: Icons.accessibility_new,
          color: const Color(0xFFEF4444),
          title: 'Target weak points',
          body: 'Selected muscles get extra volume and priority placement in your workouts.',
        );
      case 9:
        return buildTip(
          icon: Icons.view_week_rounded,
          color: const Color(0xFF3B82F6),
          title: 'Training philosophy',
          body: 'Each style structures your week differently. Let AI decide if you\'re unsure — it adapts to your schedule.',
        );
      case 10:
        return buildTip(
          icon: Icons.speed_rounded,
          color: AppColors.green,
          title: 'Your progression speed',
          body: 'Controls how quickly weights, reps, and difficulty increase each week.',
        );
      case 11:
      case 12:
        return buildTip(
          icon: Icons.restaurant_rounded,
          color: AppColors.orange,
          title: 'Fuel your training',
          body: 'Nutrition tracking is optional but powerful. AI calculates macros based on your goals and activity level.',
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final windowState = ref.watch(windowModeProvider);
    final isFoldableOpen = FoldableQuizScaffold.shouldUseFoldableLayout(windowState);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0A1628), AppColors.pureBlack],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE3F2FD), Color(0xFFF5F5F5), Colors.white],
                ),
        ),
        child: SafeArea(
          child: FoldableQuizScaffold(
            headerTitle: _getStepTitle(_currentQuestion),
            headerSubtitle: _getStepSubtitle(_currentQuestion),
            headerExtra: isFoldableOpen ? _getStepHeaderExtra(context, _currentQuestion) : null,
            progressBar: QuizProgressBar(progress: _progress),
            headerOverlay: QuizHeader(
              currentQuestion: _currentQuestion,
              totalQuestions: _totalQuestions,
              canGoBack: _currentQuestion > 0,
              onBack: _previousQuestion,
              onBackToWelcome: () {
                HapticFeedback.lightImpact();
                context.go('/stats-welcome');
              },
            ),
            content: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.1, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  ),
                );
              },
              child: _buildCurrentQuestion(showHeader: !isFoldableOpen),
            ),
            button: _buildActionButton(isDark),
          ),
        ),
      ),
    );
  }

  /// Build the action button for the current question step.
  Widget? _buildActionButton(bool isDark) {
    // Case 6 gets special "Generate" button
    if (_currentQuestion == 6) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _canProceed ? _generateAndShowPreview : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _canProceed
                  ? AppColors.orange
                  : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
              foregroundColor: _canProceed
                  ? Colors.white
                  : (isDark ? AppColors.textMuted : AppColorsLight.textMuted),
              elevation: _canProceed ? 4 : 0,
              shadowColor: _canProceed ? AppColors.orange.withValues(alpha: 0.4) : Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Generate My First Workout',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_canProceed) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.auto_awesome_rounded, size: 20),
                ],
              ],
            ),
          ),
        ),
      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
    }
    // Cases 7 and 11 have their own action buttons (gate screens)
    if (_currentQuestion == 7 || _currentQuestion == 11) {
      return null;
    }
    // All other cases: standard continue button
    return QuizContinueButton(
      canProceed: _canProceed,
      isLastQuestion: _currentQuestion == _totalQuestions - 1,
      onPressed: _nextQuestion,
    );
  }

  Widget _buildCurrentQuestion({bool showHeader = true}) {
    // 13-SCREEN FLOW (Progressive Profiling)
    // Phase 1 (Required): 0-Goals, 1-Fitness+Exp, 2-Schedule, 3-WorkoutDays[COND], 4-Equipment, 5-Limitations, 6-PrimaryGoal+Generate
    // Phase 2 (Optional): 7-PersonalizationGate, 8-MuscleFocus, 9-TrainingStyle, 10-Progression(pace)
    // Phase 3 (Optional): 11-NutritionGate, 12-NutritionDetails

    switch (_currentQuestion) {
      // PHASE 1: REQUIRED (Screens 0-6)
      case 0: // Goals (multi-select)
        return _buildGoalQuestion(showHeader: showHeader);

      case 1: // Fitness Level + Training Experience (combined, experience optional)
        return QuizFitnessLevel(
          key: const ValueKey('fitness_level'),
          selectedLevel: _selectedLevel,
          selectedExperience: _selectedTrainingExperience,
          selectedActivityLevel: _selectedActivityLevel,
          onLevelChanged: (level) => setState(() => _selectedLevel = level),
          onExperienceChanged: (exp) => setState(() => _selectedTrainingExperience = exp),
          onActivityLevelChanged: (level) => setState(() => _selectedActivityLevel = level),
          showHeader: showHeader,
        );

      case 2: // Schedule (days/week + duration combined)
        return _buildDaysSelector(showHeader: showHeader);

      case 3: // Workout Days [CONDITIONAL - only if feature flag enabled]
        if (_featureFlagWorkoutDays) {
          return _buildWorkoutDaysSelector(showHeader: showHeader);
        }
        return const SizedBox.shrink();

      case 4: // Equipment (2-step: environment + equipment list)
        return _buildEquipmentSelector(showHeader: showHeader);

      case 5: // Injuries/Limitations (NEW POSITION - moved from old Phase 2)
        return QuizLimitations(
          key: const ValueKey('limitations'),
          selectedLimitations: _selectedLimitations.toList(),
          customLimitation: _customLimitation,
          onLimitationsChanged: (limitations) => setState(() {
            _selectedLimitations.clear();
            _selectedLimitations.addAll(limitations);
          }),
          onCustomLimitationChanged: (customText) => setState(() {
            _customLimitation = customText;
          }),
          showHeader: showHeader,
        );

      case 6: // Training Focus (Primary Goal) + Generate Preview
        return _buildPrimaryGoal(showHeader: showHeader);

      // PHASE 2: OPTIONAL PERSONALIZATION (Screens 7-10, shown AFTER preview)
      case 7: // Personalization Gate
        return QuizPersonalizationGate(
          key: const ValueKey('personalization_gate'),
          onPersonalize: () {
            HapticFeedback.mediumImpact();
            setState(() => _skipPersonalization = false);
            _nextQuestion();
          },
          onSkip: () {
            HapticFeedback.selectionClick();
            AnalyticsService.logPersonalizationSkipped();
            setState(() {
              _skipPersonalization = true;
              _currentQuestion = 11; // Jump to nutrition gate
            });
            _questionController.forward(from: 0);
          },
        );

      case 8: // Muscle Focus Points
        return _buildMuscleFocus(showHeader: showHeader);

      case 9: // Training Style (split + workout type)
        return QuizTrainingStyle(
          key: const ValueKey('training_style'),
          selectedSplit: _selectedTrainingSplit,
          selectedWorkoutType: _selectedWorkoutType,
          selectedWorkoutVariety: _selectedWorkoutVariety,
          daysPerWeek: _selectedDays ?? 4,
          onSplitChanged: (split) => setState(() => _selectedTrainingSplit = split),
          onWorkoutTypeChanged: (type) => setState(() => _selectedWorkoutType = type),
          onWorkoutVarietyChanged: (variety) => setState(() => _selectedWorkoutVariety = variety),
          onDaysPerWeekChanged: (newDays) async {
            setState(() => _selectedDays = newDays);
            await ref.read(preAuthQuizProvider.notifier).setDaysPerWeek(newDays);
          },
          showHeader: showHeader,
        );

      case 10: // Progression pace only (limitations already collected in Screen 5)
        return QuizProgressionConstraints(
          key: const ValueKey('progression_pace'),
          selectedPace: _selectedProgressionPace,
          fitnessLevel: _selectedLevel ?? 'intermediate',
          onPaceChanged: (pace) => setState(() => _selectedProgressionPace = pace),
          showHeader: showHeader,
        );

      // PHASE 3: OPTIONAL NUTRITION (Screens 11-12)
      case 11: // Nutrition Opt-In Gate
        return QuizNutritionGate(
          key: const ValueKey('nutrition_gate'),
          goals: _selectedGoals.toList(),
          onSetNutrition: () async {
            HapticFeedback.mediumImpact();
            AnalyticsService.logNutritionOptIn(true);
            await ref.read(preAuthQuizProvider.notifier).setNutritionEnabled(true);
            setState(() => _nutritionEnabled = true);
            _nextQuestion();
          },
          onSkip: () async {
            HapticFeedback.selectionClick();
            AnalyticsService.logNutritionOptIn(false);
            await ref.read(preAuthQuizProvider.notifier).setNutritionEnabled(false);
            setState(() => _nutritionEnabled = false);
            _finishOnboarding();
          },
        );

      case 12: // Nutrition Details (merged nutrition + fasting)
        return _buildNutritionGoals(showHeader: showHeader);

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDaysSelector({bool showHeader = true}) {
    return QuizDaysSelector(
      key: const ValueKey('days_selector'),
      selectedDays: _selectedDays,
      selectedWorkoutDays: _selectedWorkoutDays,
      workoutDurationMin: _workoutDurationMin,
      workoutDurationMax: _workoutDurationMax,
      showHeader: showHeader,
      onDaysChanged: (days) {
        setState(() {
          _selectedDays = days;
          if (_selectedWorkoutDays.length > days) {
            _selectedWorkoutDays.clear();
          }
        });
      },
      onWorkoutDayToggled: (day) {
        setState(() {
          if (_selectedWorkoutDays.contains(day)) {
            _selectedWorkoutDays.remove(day);
          } else if (_selectedWorkoutDays.length < (_selectedDays ?? 7)) {
            _selectedWorkoutDays.add(day);
          }
        });
      },
      onDurationChanged: (minDuration, maxDuration) {
        setState(() {
          _workoutDurationMin = minDuration;
          _workoutDurationMax = maxDuration;
        });
        // Save immediately to provider to ensure it's never lost
        ref.read(preAuthQuizProvider.notifier).setWorkoutDuration(minDuration, maxDuration);
      },
    );
  }

  Widget _buildWorkoutDaysSelector({bool showHeader = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            // Title
            Text(
              'Which days work best?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF0A0A0A),
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 6),
            Text(
              'Select ${_selectedDays ?? 0} days for your workouts',
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFD4D4D8)
                    : const Color(0xFF52525B),
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 24),
          ],
          // Days of week selector
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDayCheckbox(1, 'Monday', 300.ms),
                const SizedBox(height: 12),
                _buildDayCheckbox(2, 'Tuesday', 350.ms),
                const SizedBox(height: 12),
                _buildDayCheckbox(3, 'Wednesday', 400.ms),
                const SizedBox(height: 12),
                _buildDayCheckbox(4, 'Thursday', 450.ms),
                const SizedBox(height: 12),
                _buildDayCheckbox(5, 'Friday', 500.ms),
                const SizedBox(height: 12),
                _buildDayCheckbox(6, 'Saturday', 550.ms),
                const SizedBox(height: 12),
                _buildDayCheckbox(7, 'Sunday', 600.ms),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCheckbox(int day, String label, Duration delay) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedWorkoutDays.contains(day);
    final canSelect = _selectedWorkoutDays.length < (_selectedDays ?? 7);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          if (_selectedWorkoutDays.contains(day)) {
            _selectedWorkoutDays.remove(day);
          } else if (canSelect || isSelected) {
            _selectedWorkoutDays.add(day);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.orange.withValues(alpha: 0.15)
              : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.orange
                : (isDark ? AppColors.glassBorder : AppColorsLight.cardBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Checkbox indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.orange : textPrimary.withValues(alpha: 0.5),
                  width: 2,
                ),
                color: isSelected ? AppColors.orange : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            // Day label
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.orange : textPrimary,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay).slideX(begin: -0.05);
  }

  Widget _buildEquipmentSelector({bool showHeader = true}) {
    return QuizEquipment(
      key: const ValueKey('equipment'),
      selectedEquipment: _selectedEquipment,
      dumbbellCount: _dumbbellCount,
      kettlebellCount: _kettlebellCount,
      onEquipmentToggled: (id) => _handleEquipmentToggle(id),
      onDumbbellCountChanged: (count) => setState(() => _dumbbellCount = count),
      onKettlebellCountChanged: (count) => setState(() => _kettlebellCount = count),
      onInfoTap: _showEquipmentInfo,
      onOtherTap: _showOtherEquipmentSheet,
      otherSelectedEquipment: _otherSelectedEquipment,
      selectedEnvironment: _selectedEnvironment,
      onEnvironmentChanged: _handleEnvironmentChange,
      showHeader: showHeader,
    );
  }

  Widget _buildTrainingPreferences() {
    return QuizTrainingPreferences(
      key: const ValueKey('training_preferences'),
      selectedSplit: _selectedTrainingSplit,
      selectedWorkoutType: _selectedWorkoutType,
      selectedProgressionPace: _selectedProgressionPace,
      selectedSleepQuality: _selectedSleepQuality,
      selectedObstacles: _selectedObstacles,
      onSplitChanged: (split) => setState(() => _selectedTrainingSplit = split),
      onWorkoutTypeChanged: (type) => setState(() => _selectedWorkoutType = type),
      onProgressionPaceChanged: (pace) => setState(() => _selectedProgressionPace = pace),
      onSleepQualityChanged: (quality) => setState(() => _selectedSleepQuality = quality),
      onObstacleToggle: (id) {
        setState(() {
          if (_selectedObstacles.contains(id)) {
            _selectedObstacles.remove(id);
          } else if (_selectedObstacles.length < 3) {
            _selectedObstacles.add(id);
          }
        });
      },
    );
  }

  Widget _buildNutritionGoals({bool showHeader = true}) {
    return QuizNutritionGoals(
      key: const ValueKey('nutrition_goals'),
      selectedGoals: _selectedNutritionGoals,
      selectedRestrictions: _selectedDietaryRestrictions,
      showHeader: showHeader,
      onToggle: (id) {
        setState(() {
          if (_selectedNutritionGoals.contains(id)) {
            _selectedNutritionGoals.remove(id);
          } else {
            _selectedNutritionGoals.add(id);
          }
        });
      },
      onRestrictionToggle: (id) {
        setState(() {
          // Handle "none" special case - clears all other restrictions
          if (id == 'none') {
            if (_selectedDietaryRestrictions.contains('none')) {
              _selectedDietaryRestrictions.remove('none');
            } else {
              _selectedDietaryRestrictions.clear();
              _selectedDietaryRestrictions.add('none');
            }
          } else {
            // Remove "none" if selecting another restriction
            _selectedDietaryRestrictions.remove('none');
            if (_selectedDietaryRestrictions.contains(id)) {
              _selectedDietaryRestrictions.remove(id);
            } else {
              _selectedDietaryRestrictions.add(id);
            }
          }
        });
      },
      // Meals per day
      mealsPerDay: _mealsPerDay,
      onMealsPerDayChanged: (meals) => setState(() => _mealsPerDay = meals),
      // Pass user data for nutrition targets preview (calculate age from DOB)
      age: _dateOfBirth != null ? _calculateAge(_dateOfBirth!) : null,
      gender: _gender,
      heightCm: _heightCm,
      weightKg: _weightKg,
      activityLevel: _selectedActivityLevel,
      weightDirection: _weightDirection,
      weightChangeRate: _weightChangeRate,
      goalWeightKg: _goalWeightKg,
      workoutDaysPerWeek: _selectedDays,
    );
  }

  Widget _buildFasting() {
    return QuizFasting(
      key: const ValueKey('fasting'),
      interestedInFasting: _interestedInFasting,
      selectedProtocol: _selectedFastingProtocol,
      onInterestChanged: (interested) => setState(() => _interestedInFasting = interested),
      onProtocolChanged: (protocol) => setState(() => _selectedFastingProtocol = protocol),
      // Pass user data for recommendations
      fitnessLevel: _selectedLevel,
      weightDirection: _weightDirection,
      activityLevel: _selectedActivityLevel,
      // Sleep schedule
      wakeTime: _wakeTime,
      sleepTime: _sleepTime,
      onWakeTimeChanged: (time) => setState(() => _wakeTime = time),
      onSleepTimeChanged: (time) => setState(() => _sleepTime = time),
      // Meals per day for validation
      mealsPerDay: _mealsPerDay,
      onMealsPerDayChanged: (meals) => setState(() => _mealsPerDay = meals),
    );
  }

  Widget _buildMotivation() {
    return QuizMotivation(
      key: const ValueKey('motivation'),
      selectedMotivations: _selectedMotivations,
      onToggle: (id) {
        setState(() {
          if (_selectedMotivations.contains(id)) {
            _selectedMotivations.remove(id);
          } else {
            _selectedMotivations.add(id);
          }
        });
      },
    );
  }

  Widget _buildPrimaryGoal({bool showHeader = true}) {
    final options = [
      {
        'id': 'muscle_hypertrophy',
        'label': 'Hypertrophy',  // ← SHORTENED from "Muscle Hypertrophy"
        'description': '8–12 reps • muscle size',  // ← CONDENSED to concise format
        'icon': Icons.fitness_center_rounded,
        'color': AppColors.orange, // Vibrant orange for visibility
      },
      {
        'id': 'muscle_strength',
        'label': 'Strength',  // ← SHORTENED from "Muscle Strength"
        'description': '3–6 reps • heavy & powerful',  // ← CONDENSED
        'icon': Icons.bolt_rounded,
        'color': const Color(0xFF3B82F6), // Bright blue
      },
      {
        'id': 'strength_hypertrophy',
        'label': 'Balanced',  // ← SHORTENED from "Both Strength & Hypertrophy"
        'description': '6–10 reps • size + strength',  // ← CONDENSED
        'icon': Icons.all_inclusive_rounded,
        'color': const Color(0xFF8B5CF6), // Vibrant purple
      },
      {
        'id': 'endurance',
        'label': 'Endurance',  // ← KEEP as-is
        'description': '12+ reps • stamina',  // ← CONDENSED
        'icon': Icons.directions_run_rounded,
        'color': const Color(0xFF10B981), // Vibrant green
      },
    ];

    return QuizPrimaryGoal(
      key: const ValueKey('primary_goal'),
      question: 'What is your primary training focus?',
      subtitle: 'This helps us customize your workout intensity and rep ranges',
      options: options,
      selectedValue: _selectedPrimaryGoal,
      onSelect: (value) {
        setState(() => _selectedPrimaryGoal = value);
      },
      showHeader: showHeader,
    );
  }

  Widget _buildMuscleFocus({bool showHeader = true}) {
    return QuizMuscleFocus(
      key: const ValueKey('muscle_focus'),
      question: 'Would you like to give extra focus to any muscles?',
      subtitle: 'Allocate up to 5 focus points to prioritize specific muscle groups in your workouts',
      showHeader: showHeader,
      focusPoints: _muscleFocusPoints,
      onPointsChanged: (points) {
        setState(() => _muscleFocusPoints = points);
      },
    );
  }

  Widget _buildGoalQuestion({bool showHeader = true}) {
    final goals = [
      {'id': 'build_muscle', 'label': 'Build Muscle', 'icon': Icons.fitness_center, 'color': AppColors.orange},
      {'id': 'lose_weight', 'label': 'Lose Weight', 'icon': Icons.monitor_weight_outlined, 'color': AppColors.orange},
      {'id': 'increase_strength', 'label': 'Get Stronger', 'icon': Icons.bolt, 'color': AppColors.orange},
      {'id': 'improve_endurance', 'label': 'Build Endurance', 'icon': Icons.directions_run, 'color': AppColors.purple},
      {'id': 'stay_active', 'label': 'Stay Active', 'icon': Icons.favorite_outline, 'color': AppColors.green},
      {'id': 'athletic_performance', 'label': 'Athletic Performance', 'icon': Icons.sports_martial_arts, 'color': const Color(0xFF3B82F6)}, // Bright blue
    ];

    return QuizMultiSelect(
      key: const ValueKey('goals'),
      question: 'What are your fitness goals?',
      subtitle: 'Select all that apply',
      options: goals,
      selectedValues: _selectedGoals,
      onToggle: (value) {
        setState(() {
          if (_selectedGoals.contains(value)) {
            _selectedGoals.remove(value);
          } else {
            _selectedGoals.add(value);
          }
        });
      },
      showHeader: showHeader,
    );
  }

  void _handleEquipmentToggle(String id) {
    setState(() {
      if (id == 'full_gym') {
        if (_selectedEquipment.contains('full_gym')) {
          _selectedEquipment.clear();
        } else {
          _selectedEquipment.clear();
          _selectedEquipment.addAll([
            'bodyweight',
            'dumbbells',
            'barbell',
            'resistance_bands',
            'pull_up_bar',
            'kettlebell',
            'cable_machine',
            'full_gym',
          ]);
        }
      } else {
        if (_selectedEquipment.contains(id)) {
          _selectedEquipment.remove(id);
          _selectedEquipment.remove('full_gym');
        } else {
          _selectedEquipment.add(id);
        }
      }
    });
  }

  /// Handle environment selection - pre-populates equipment based on environment
  void _handleEnvironmentChange(String envId) {
    setState(() {
      // If tapping the same environment, deselect it and clear equipment
      if (_selectedEnvironment == envId) {
        _selectedEnvironment = null;
        _selectedEquipment.clear();
        _otherSelectedEquipment.clear();
        return;
      }

      _selectedEnvironment = envId;

      // Pre-populate equipment based on environment
      _selectedEquipment.clear();
      _otherSelectedEquipment.clear();

      switch (envId) {
        case 'home':
          _selectedEquipment.addAll(['bodyweight', 'resistance_bands']);
          break;
        case 'home_gym':
          _selectedEquipment.addAll([
            'bodyweight',
            'dumbbells',
            'barbell',
            'resistance_bands',
            'pull_up_bar',
            'kettlebell',
          ]);
          break;
        case 'commercial_gym':
          _selectedEquipment.addAll([
            'bodyweight',
            'dumbbells',
            'barbell',
            'resistance_bands',
            'pull_up_bar',
            'kettlebell',
            'cable_machine',
            'full_gym',
          ]);
          break;
        case 'hotel':
          _selectedEquipment.addAll([
            'bodyweight',
            'dumbbells',
            'resistance_bands',
          ]);
          break;
      }
    });
  }

  void _showOtherEquipmentSheet() {
    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        child: EquipmentSearchSheet(
        selectedEquipment: _otherSelectedEquipment,
        allEquipment: EquipmentSearchSheet.databaseEquipment,
        initialCustomEquipment: _customEquipment,
        onSelectionChanged: (selected) {
          setState(() {
            _otherSelectedEquipment.clear();
            _otherSelectedEquipment.addAll(selected);
          });
        },
        onCustomEquipmentChanged: (customList) {
          setState(() {
            _customEquipment.clear();
            _customEquipment.addAll(customList);
          });
        },
        ),
      ),
    );
  }

  void _showEquipmentInfo(BuildContext context, String equipmentId, bool isDark) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    String title;
    String description;
    if (equipmentId == 'dumbbells') {
      title = 'Dumbbell Count';
      description = 'Single dumbbell: Unilateral exercises only (one arm at a time)\n\n'
          'Pair of dumbbells: Full range of exercises including bilateral movements';
    } else {
      title = 'Kettlebell Count';
      description = 'Single kettlebell: Perfect for swings, Turkish get-ups, and single-arm work\n\n'
          'Multiple kettlebells: Allows for double KB exercises and weight progression';
    }

    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.accent),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
