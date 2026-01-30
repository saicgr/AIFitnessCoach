import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/analytics_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/template_workout_generator.dart';
import '../../core/constants/api_constants.dart';
import '../../data/models/workout.dart';
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
import 'widgets/quiz_weight_rate.dart';
import 'widgets/quiz_body_metrics.dart';
import 'widgets/equipment_search_sheet.dart';
import 'widgets/quiz_primary_goal.dart';
import 'widgets/quiz_muscle_focus.dart';
import 'widgets/quiz_personalization_gate.dart';
import 'widgets/quiz_training_style.dart';
import 'widgets/quiz_progression_constraints.dart';
import 'widgets/quiz_nutrition_gate.dart';
import 'plan_preview_screen.dart';
import 'workout_generation_screen.dart';

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
  final int? workoutDuration;  // Duration in minutes (30, 45, 60, 75, 90)
  final List<String>? equipment;
  final List<String>? customEquipment;  // User-added custom equipment
  final String? workoutEnvironment;
  final String? trainingSplit;
  final List<String>? motivations;
  final int? dumbbellCount;
  final int? kettlebellCount;
  // Workout type preference (strength, cardio, mixed)
  final String? workoutTypePreference;
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
    this.equipment,
    this.customEquipment,
    this.workoutEnvironment,
    this.trainingSplit,
    this.motivations,
    this.dumbbellCount,
    this.kettlebellCount,
    this.workoutTypePreference,
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
  });

  String? get goal => goals?.isNotEmpty == true ? goals!.first : null;
  String? get motivation => motivations?.isNotEmpty == true ? motivations!.first : null;

  bool get isComplete =>
      goals != null &&
      goals!.isNotEmpty &&
      fitnessLevel != null &&
      trainingExperience != null &&
      daysPerWeek != null &&
      workoutDays != null &&
      workoutDays!.isNotEmpty &&
      equipment != null &&
      equipment!.isNotEmpty &&
      // trainingSplit is optional - defaults to push_pull_legs if not set
      motivations != null &&
      motivations!.isNotEmpty;

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
      );
}

/// Provider for pre-auth quiz data
final preAuthQuizProvider = StateNotifierProvider<PreAuthQuizNotifier, PreAuthQuizData>((ref) {
  return PreAuthQuizNotifier();
});

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
    final equipmentStr = prefs.getStringList('preAuth_equipment');
    final customEquipmentStr = prefs.getStringList('preAuth_customEquipment');
    final workoutEnv = prefs.getString('preAuth_workoutEnvironment');
    final trainingSplit = prefs.getString('preAuth_trainingSplit');
    final motivations = prefs.getStringList('preAuth_motivations');
    final dumbbellCount = prefs.getInt('preAuth_dumbbellCount');
    final kettlebellCount = prefs.getInt('preAuth_kettlebellCount');
    final workoutTypePref = prefs.getString('preAuth_workoutTypePreference');
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
      equipment: equipmentStr,
      customEquipment: customEquipmentStr,
      workoutEnvironment: workoutEnv,
      trainingSplit: trainingSplit,
      motivations: motivations,
      dumbbellCount: dumbbellCount,
      kettlebellCount: kettlebellCount,
      workoutTypePreference: workoutTypePref,
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
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
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
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
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
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
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
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
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
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
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
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
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
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
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
    );
  }

  Future<void> setWorkoutDuration(int duration) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('preAuth_workoutDuration', duration);
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
      workoutDuration: duration,
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
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
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: split,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
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
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
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
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: type,
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
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
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
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
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
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
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
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
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
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
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
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
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
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
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
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
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
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
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
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
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
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
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
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: environment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
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

  // Dynamic total - 12 screens base, minus 1 if workout days feature disabled
  int get _totalQuestions {
    int total = 12; // New flow: 12 screens total
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
  int? _workoutDuration;  // Duration in minutes (30, 45, 60, 75, 90)
  // Question 5: Equipment
  final Set<String> _selectedEquipment = {};
  final Set<String> _otherSelectedEquipment = {};
  final List<String> _customEquipment = [];  // User-added equipment not in predefined list
  int _dumbbellCount = 2;
  int _kettlebellCount = 1;
  String? _selectedEnvironment;  // Workout environment (home, home_gym, commercial_gym, hotel)
  // Question 6: Training Preferences (Split + Workout Type + Progression Pace)
  String? _selectedTrainingSplit;
  String? _selectedWorkoutType;
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
  String? _customLimitation;  // ← ADDED: Custom limitation text when "Other" is selected

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
    super.dispose();
  }

  /// Calculate progress value with phase-aware behavior
  /// Phase 1 (0-5): Show 0-100% progress
  /// Phase 2 & 3 (6+): Stay at 100% to show Phase 1 completion
  double get _progress {
    if (_currentQuestion <= 5) {
      return (_currentQuestion + 1) / 6;  // Phase 1 only (6 screens)
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

    // Special handling for Screen 5 (Primary Goal + Generate Preview)
    // Note: This should be triggered by button in _buildPrimaryGoal, not auto-advance
    // The preview screen will handle navigation to Screen 6 or 10

    // Check if this is the last question (screen 11 - Nutrition Details)
    // Note: _totalQuestions adjusts for feature flags but screen indices stay fixed (0-11)
    if (_currentQuestion == 11) {
      _finishOnboarding();
      return;
    }

    setState(() {
      _currentQuestion++;
    });
    _questionController.forward(from: 0);
  }

  Future<void> _saveCurrentQuestionData() async {
    // NEW 12-SCREEN FLOW (Progressive Profiling)
    // Phase 1 (Required): 0-Goals, 1-Fitness+Experience, 2-Schedule, 3-WorkoutDays[COND], 4-Equipment, 5-PrimaryGoal+Generate
    // Phase 2 (Optional): 6-PersonalizationGate, 7-MuscleFocus, 8-TrainingStyle, 9-Progression+Constraints
    // Phase 3 (Optional): 10-NutritionGate, 11-NutritionDetails

    switch (_currentQuestion) {
      // PHASE 1: REQUIRED (Screens 0-5)
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

      case 5: // Primary Goal (saved when user clicks "Generate My First Workout")
        if (_selectedPrimaryGoal != null) {
          await ref.read(preAuthQuizProvider.notifier).setPrimaryGoal(_selectedPrimaryGoal!);
        }
        break;

      // PHASE 2: OPTIONAL PERSONALIZATION (Screens 6-9)
      case 6: // Personalization Gate (no data to save, just navigation)
        break;

      case 7: // Muscle Focus Points
        await _saveMuscleFocusData();
        break;

      case 8: // Training Style (split + workout type)
        if (_selectedTrainingSplit != null) {
          await ref.read(preAuthQuizProvider.notifier).setTrainingSplit(_selectedTrainingSplit!);
        }
        if (_selectedWorkoutType != null) {
          await ref.read(preAuthQuizProvider.notifier).setWorkoutTypePreference(_selectedWorkoutType!);
        }
        break;

      case 9: // Progression + Constraints
        if (_selectedProgressionPace != null) {
          await ref.read(preAuthQuizProvider.notifier).setProgressionPace(_selectedProgressionPace!);
        }
        if (_selectedLimitations.isNotEmpty) {
          // Build limitations list, including custom limitation if present
          final limitationsList = _selectedLimitations.toList();

          // If "other" is selected and custom text is provided, append it
          if (_selectedLimitations.contains('other') && _customLimitation != null && _customLimitation!.isNotEmpty) {
            // Replace "other" with actual custom limitation text
            limitationsList.remove('other');
            limitationsList.add('other: $_customLimitation');
          }

          await ref.read(preAuthQuizProvider.notifier).setLimitations(limitationsList);
        }
        break;

      // PHASE 3: OPTIONAL NUTRITION (Screens 10-11)
      case 10: // Nutrition Opt-In Gate (handled in button callbacks)
        break;

      case 11: // Nutrition Details (merged nutrition + fasting)
        await _saveNutritionData();
        await _saveFastingData();
        break;
    }
  }

  Future<void> _saveDaysData() async {
    if (_selectedDays != null) {
      await ref.read(preAuthQuizProvider.notifier).setDaysPerWeek(_selectedDays!);
    }
    if (_selectedWorkoutDays.isNotEmpty) {
      await ref.read(preAuthQuizProvider.notifier).setWorkoutDays(_selectedWorkoutDays.toList()..sort());
    }
    if (_workoutDuration != null) {
      await ref.read(preAuthQuizProvider.notifier).setWorkoutDuration(_workoutDuration!);
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
  Future<void> _generateAndShowPreview() async {
    try {
      // Save current primary goal selection
      await _saveCurrentQuestionData();

      // Log analytics
      AnalyticsService.logWorkoutGenerated(
        primaryGoal: _selectedPrimaryGoal ?? 'unknown',
        duration: _workoutDuration ?? 60,
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

      // Show plan preview immediately with template workout
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PlanPreviewScreen(
            quizData: quizData,
            generatedWorkout: templateWorkout,  // ← Pass template workout
            onContinue: () {
              Navigator.of(context).pop();
              setState(() => _currentQuestion = 6); // Go to personalization gate
              _questionController.forward(from: 0);
            },
            onStartNow: () {
              Navigator.of(context).pop();
              setState(() => _currentQuestion = 10); // Skip to nutrition gate
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
      final skippedScreens = _skipPersonalization ? 4 : 0; // Screens 6-9 skipped
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
        _currentQuestion--;
      });
      _questionController.forward(from: 0);
    }
  }

  bool get _canProceed {
    // NEW 12-SCREEN FLOW (Progressive Profiling)
    // Phase 1 (Required): 0-Goals, 1-Fitness+Experience, 2-Schedule, 3-WorkoutDays[COND], 4-Equipment, 5-PrimaryGoal+Generate
    // Phase 2 (Optional): 6-PersonalizationGate, 7-MuscleFocus, 8-TrainingStyle, 9-Progression+Constraints
    // Phase 3 (Optional): 10-NutritionGate, 11-NutritionDetails

    switch (_currentQuestion) {
      // PHASE 1: REQUIRED (Screens 0-5)
      case 0: // Goals (must select at least 1)
        return _selectedGoals.isNotEmpty;

      case 1: // Fitness Level + Training Experience (fitness required, experience optional)
        return _selectedLevel != null;

      case 2: // Schedule (days/week + duration both required)
        return _selectedDays != null && _workoutDuration != null;

      case 3: // Workout Days [CONDITIONAL - only if feature flag enabled]
        if (_featureFlagWorkoutDays) {
          // Must select at least the number of days specified
          return _selectedWorkoutDays.length >= (_selectedDays ?? 0);
        }
        return true; // Skip validation if feature disabled

      case 4: // Equipment (must select environment + at least 1 equipment)
        return _selectedEnvironment != null &&
               (_selectedEquipment.isNotEmpty || _otherSelectedEquipment.isNotEmpty);

      case 5: // Primary Goal (must select 1, but "Generate" button handles navigation)
        return _selectedPrimaryGoal != null;

      // PHASE 2: OPTIONAL PERSONALIZATION (Screens 6-9, all optional)
      case 6: // Personalization Gate (no validation, just navigation)
        return true;

      case 7: // Muscle Focus Points (optional, 0-5 total)
        final totalPoints = _muscleFocusPoints.values.fold(0, (sum, val) => sum + val);
        return totalPoints <= 5; // Can be 0, but max is 5

      case 8: // Training Style (optional)
        return true;

      case 9: // Progression + Constraints (optional)
        return true;

      // PHASE 3: OPTIONAL NUTRITION (Screens 10-11)
      case 10: // Nutrition Opt-In Gate (no validation, buttons handle navigation)
        return true;

      case 11: // Nutrition Details (all optional)
        return true;

      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          child: Stack(
            children: [
              // Main content
              Column(
                children: [
                  const SizedBox(height: 72), // Space for floating header
                  QuizProgressBar(progress: _progress),
                  const SizedBox(height: 32),
                  Expanded(
                    child: AnimatedSwitcher(
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
                      child: _buildCurrentQuestion(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Case 5 gets special "Generate" button
                  if (_currentQuestion == 5)
                    Padding(
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
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1)
                  // Cases 6 and 10 have their own action buttons (gate screens)
                  else if (_currentQuestion != 6 && _currentQuestion != 10)
                    QuizContinueButton(
                      canProceed: _canProceed,
                      isLastQuestion: _currentQuestion == _totalQuestions - 1,
                      onPressed: _nextQuestion,
                    ),
                  const SizedBox(height: 16),
                ],
              ),

              // Floating header overlay
              QuizHeader(
                currentQuestion: _currentQuestion,
                totalQuestions: _totalQuestions,
                canGoBack: _currentQuestion > 0,
                onBack: _previousQuestion,
                onBackToWelcome: () {
                  HapticFeedback.lightImpact();
                  context.go('/stats-welcome');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentQuestion() {
    // NEW 12-SCREEN FLOW (Progressive Profiling)
    // Phase 1 (Required): 0-Goals, 1-Fitness+Experience, 2-Schedule, 3-WorkoutDays[COND], 4-Equipment, 5-PrimaryGoal+Generate
    // Phase 2 (Optional): 6-PersonalizationGate, 7-MuscleFocus, 8-TrainingStyle, 9-Progression+Constraints
    // Phase 3 (Optional): 10-NutritionGate, 11-NutritionDetails

    switch (_currentQuestion) {
      // PHASE 1: REQUIRED (Screens 0-5)
      case 0: // Goals (multi-select) - NO CHANGES
        return _buildGoalQuestion();

      case 1: // Fitness Level + Training Experience (combined, experience optional)
        return QuizFitnessLevel(
          key: const ValueKey('fitness_level'),
          selectedLevel: _selectedLevel,
          selectedExperience: _selectedTrainingExperience,
          selectedActivityLevel: null, // Remove activity level from Phase 1
          onLevelChanged: (level) => setState(() => _selectedLevel = level),
          onExperienceChanged: (exp) => setState(() => _selectedTrainingExperience = exp),
          onActivityLevelChanged: null,
        );

      case 2: // Schedule (days/week + duration combined)
        return _buildDaysSelector(); // Already shows both days + duration

      case 3: // Workout Days [CONDITIONAL - only if feature flag enabled]
        if (_featureFlagWorkoutDays) {
          return _buildWorkoutDaysSelector();
        }
        // If feature disabled, this case shouldn't be reached due to skip logic
        return const SizedBox.shrink();

      case 4: // Equipment (2-step: environment + equipment list)
        return _buildEquipmentSelector();

      case 5: // Training Focus (Primary Goal) + Generate Preview
        return _buildPrimaryGoal();
        // Note: Generate button in _buildPrimaryGoal should call _generateAndShowPreview()

      // PHASE 2: OPTIONAL PERSONALIZATION (Screens 6-9, shown AFTER preview)
      case 6: // Personalization Gate
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
              _currentQuestion = 10; // Jump to nutrition gate
            });
            _questionController.forward(from: 0);
          },
        );

      case 7: // Muscle Focus Points (existing widget, repositioned)
        return _buildMuscleFocus();

      case 8: // Training Style (split + workout type)
        return QuizTrainingStyle(
          key: const ValueKey('training_style'),
          selectedSplit: _selectedTrainingSplit,
          selectedWorkoutType: _selectedWorkoutType,
          daysPerWeek: _selectedDays ?? 4,
          onSplitChanged: (split) => setState(() => _selectedTrainingSplit = split),
          onWorkoutTypeChanged: (type) => setState(() => _selectedWorkoutType = type),
          onDaysPerWeekChanged: (newDays) async {
            // Update local state
            setState(() => _selectedDays = newDays);
            // Save to SharedPreferences via state notifier
            await ref.read(preAuthQuizProvider.notifier).setDaysPerWeek(newDays);
          },
        );

      case 9: // Progression + Constraints
        return QuizProgressionConstraints(
          key: const ValueKey('progression_constraints'),
          selectedPace: _selectedProgressionPace,
          selectedLimitations: _selectedLimitations.toList(),
          customLimitation: _customLimitation,  // ← ADDED: Pass custom limitation text
          fitnessLevel: _selectedLevel ?? 'intermediate',
          onPaceChanged: (pace) => setState(() => _selectedProgressionPace = pace),
          onLimitationsChanged: (limitations) => setState(() {
            _selectedLimitations.clear();
            _selectedLimitations.addAll(limitations);
          }),
          onCustomLimitationChanged: (customText) => setState(() {  // ← ADDED: Handle custom text changes
            _customLimitation = customText;
          }),
        );

      // PHASE 3: OPTIONAL NUTRITION (Screens 10-11)
      case 10: // Nutrition Opt-In Gate
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

      case 11: // Nutrition Details (merged nutrition + fasting)
        return _buildNutritionGoals(); // TODO: Should be merged widget with fasting

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDaysSelector() {
    return QuizDaysSelector(
      key: const ValueKey('days_selector'),
      selectedDays: _selectedDays,
      selectedWorkoutDays: _selectedWorkoutDays,
      workoutDuration: _workoutDuration,
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
      onDurationChanged: (duration) {
        setState(() {
          _workoutDuration = duration;
        });
      },
    );
  }

  Widget _buildWorkoutDaysSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

  Widget _buildEquipmentSelector() {
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

  Widget _buildNutritionGoals() {
    return QuizNutritionGoals(
      key: const ValueKey('nutrition_goals'),
      selectedGoals: _selectedNutritionGoals,
      selectedRestrictions: _selectedDietaryRestrictions,
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

  Widget _buildPrimaryGoal() {
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
    );
  }

  Widget _buildMuscleFocus() {
    return QuizMuscleFocus(
      key: const ValueKey('muscle_focus'),
      question: 'Would you like to give extra focus to any muscles?',
      subtitle: 'Allocate up to 5 focus points to prioritize specific muscle groups in your workouts',
      focusPoints: _muscleFocusPoints,
      onPointsChanged: (points) {
        setState(() => _muscleFocusPoints = points);
      },
    );
  }

  Widget _buildGoalQuestion() {
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EquipmentSearchSheet(
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

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
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
    );
  }
}
