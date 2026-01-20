import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../data/services/api_client.dart';
import '../../core/constants/api_constants.dart';
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
    );
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
  // Dynamic total - 12 questions if user wants to lose/gain, 11 if maintaining
  int get _totalQuestions {
    // If maintaining weight, skip the rate question
    if (_weightDirection == 'maintain') return 11;
    return 12;
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

  double get _progress => (_currentQuestion + 1) / _totalQuestions;

  void _nextQuestion() async {
    HapticFeedback.mediumImpact();

    // Determine if we're showing the rate question (not maintaining weight)
    final showRateQuestion = _weightDirection != null && _weightDirection != 'maintain';

    await _saveCurrentQuestionData(showRateQuestion);

    // Check if this is the last question
    if (_currentQuestion == _totalQuestions - 1) {
      if (mounted) {
        context.go('/weight-projection');
      }
      return;
    }

    setState(() {
      _currentQuestion++;
    });
    _questionController.forward(from: 0);
  }

  Future<void> _saveCurrentQuestionData(bool showRateQuestion) async {
    // New order: Goals -> Fitness -> Days -> Equipment -> BodyMetrics -> Rate(conditional) -> Training -> Nutrition -> Fasting -> Motivation
    // Question flow with rate: 0-Goals, 1-Fitness, 2-Days, 3-Equipment, 4-BodyMetrics, 5-Rate, 6-Training, 7-Nutrition, 8-Fasting, 9-Motivation
    // Question flow without rate: 0-Goals, 1-Fitness, 2-Days, 3-Equipment, 4-BodyMetrics, 5-Training, 6-Nutrition, 7-Fasting, 8-Motivation

    switch (_currentQuestion) {
      case 0:
        // Goals
        if (_selectedGoals.isNotEmpty) {
          await ref.read(preAuthQuizProvider.notifier).setGoals(_selectedGoals.toList());
        }
        break;
      case 1:
        // Fitness Level
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
      case 2:
        // Days selector
        await _saveDaysData();
        break;
      case 3:
        // Equipment
        await _saveEquipmentData();
        break;
      case 4:
        // Body metrics with name, DOB, gender, weight direction and amount
        if (_heightCm != null && _weightKg != null && _goalWeightKg != null) {
          await ref.read(preAuthQuizProvider.notifier).setBodyMetrics(
            name: _name,
            dateOfBirth: _dateOfBirth,
            gender: _gender,
            heightCm: _heightCm!,
            weightKg: _weightKg!,
            goalWeightKg: _goalWeightKg!,
            useMetric: _useMetric,
            weightDirection: _weightDirection,
            weightChangeAmount: _weightChangeAmount,
            weightChangeRate: _weightChangeRate,
          );
        }
        break;
      case 5:
        if (showRateQuestion) {
          // Rate selection - update body metrics with rate
          if (_weightChangeRate != null && _heightCm != null && _weightKg != null && _goalWeightKg != null) {
            await ref.read(preAuthQuizProvider.notifier).setBodyMetrics(
              name: _name,
              dateOfBirth: _dateOfBirth,
              gender: _gender,
              heightCm: _heightCm!,
              weightKg: _weightKg!,
              goalWeightKg: _goalWeightKg!,
              useMetric: _useMetric,
              weightDirection: _weightDirection,
              weightChangeAmount: _weightChangeAmount,
              weightChangeRate: _weightChangeRate,
            );
          }
        } else {
          // Training preferences
          await _saveTrainingPreferencesData();
        }
        break;
      case 6:
        if (showRateQuestion) {
          await _saveTrainingPreferencesData();
        } else {
          await _saveNutritionData();
        }
        break;
      case 7:
        if (showRateQuestion) {
          await _saveNutritionData();
        } else {
          await _saveFastingData();
        }
        break;
      case 8:
        if (showRateQuestion) {
          await _saveFastingData();
        } else {
          await _saveMotivationData();
        }
        break;
      case 9:
        if (showRateQuestion) {
          await _saveMotivationData();
        } else {
          await _savePrimaryGoalData();
        }
        break;
      case 10:
        if (showRateQuestion) {
          await _savePrimaryGoalData();
        } else {
          await _saveMuscleFocusData();
        }
        break;
      case 11:
        // Only reached if showing rate question (12 questions total) - Muscle Focus
        await _saveMuscleFocusData();
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
    // New order: Goals -> Fitness -> Days -> Equipment -> BodyMetrics -> Rate(conditional) -> Training -> Nutrition -> Fasting -> Motivation -> PrimaryGoal -> MuscleFocus
    // With rate (12 total): 0-Goals, 1-Fitness, 2-Days, 3-Equipment, 4-BodyMetrics, 5-Rate, 6-Training, 7-Nutrition, 8-Fasting, 9-Motivation, 10-PrimaryGoal, 11-MuscleFocus
    // Without rate (11 total): 0-Goals, 1-Fitness, 2-Days, 3-Equipment, 4-BodyMetrics, 5-Training, 6-Nutrition, 7-Fasting, 8-Motivation, 9-PrimaryGoal, 10-MuscleFocus
    final showRateQuestion = _weightDirection != null && _weightDirection != 'maintain';

    switch (_currentQuestion) {
      case 0:
        // Goals
        return _selectedGoals.isNotEmpty;
      case 1:
        // Fitness Level
        return _selectedLevel != null && _selectedTrainingExperience != null && _selectedActivityLevel != null;
      case 2:
        // Days selector (days + which days + duration)
        return _selectedDays != null && _selectedWorkoutDays.length >= _selectedDays! && _workoutDuration != null;
      case 3:
        // Equipment
        return _selectedEquipment.isNotEmpty || _otherSelectedEquipment.isNotEmpty;
      case 4:
        // Body metrics: name, DOB, gender, height, weight, and goal weight are required
        return _name != null && _name!.isNotEmpty && _dateOfBirth != null && _gender != null && _heightCm != null && _weightKg != null && _goalWeightKg != null;
      case 5:
        if (showRateQuestion) {
          // Rate selection page - must select a rate
          return _weightChangeRate != null;
        }
        // Training preferences are optional
        return true;
      case 6:
        if (showRateQuestion) {
          // Training preferences are optional
          return true;
        }
        // Nutrition goals are optional
        return true;
      case 7:
        if (showRateQuestion) {
          // Nutrition goals are optional
          return true;
        }
        // Fasting - must answer yes or no
        return _interestedInFasting != null;
      case 8:
        if (showRateQuestion) {
          // Fasting - must answer yes or no
          return _interestedInFasting != null;
        }
        // Motivation
        return _selectedMotivations.isNotEmpty;
      case 9:
        if (showRateQuestion) {
          // Motivation
          return _selectedMotivations.isNotEmpty;
        }
        // Primary Goal - must select one
        return _selectedPrimaryGoal != null;
      case 10:
        if (showRateQuestion) {
          // Primary Goal - must select one
          return _selectedPrimaryGoal != null;
        }
        // Muscle Focus - optional (can have 0 focus points)
        return true;
      case 11:
        // Only reached if showing rate question (12 questions) - Muscle Focus
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
          child: Column(
            children: [
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
              QuizContinueButton(
                canProceed: _canProceed,
                isLastQuestion: _currentQuestion == _totalQuestions - 1,
                onPressed: _nextQuestion,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentQuestion() {
    // New order: Goals -> Fitness -> Days -> Equipment -> BodyMetrics -> Rate(conditional) -> Training -> Nutrition -> Fasting -> Motivation -> PrimaryGoal -> MuscleFocus
    // With rate question (12 total): 0-Goals, 1-Fitness, 2-Days, 3-Equipment, 4-BodyMetrics, 5-Rate, 6-Training, 7-Nutrition, 8-Fasting, 9-Motivation, 10-PrimaryGoal, 11-MuscleFocus
    // Without rate (11 total): 0-Goals, 1-Fitness, 2-Days, 3-Equipment, 4-BodyMetrics, 5-Training, 6-Nutrition, 7-Fasting, 8-Motivation, 9-PrimaryGoal, 10-MuscleFocus
    final showRateQuestion = _weightDirection != null && _weightDirection != 'maintain';

    switch (_currentQuestion) {
      case 0:
        return _buildGoalQuestion();
      case 1:
        return QuizFitnessLevel(
          key: const ValueKey('fitness_level'),
          selectedLevel: _selectedLevel,
          selectedExperience: _selectedTrainingExperience,
          selectedActivityLevel: _selectedActivityLevel,
          onLevelChanged: (level) => setState(() => _selectedLevel = level),
          onExperienceChanged: (exp) => setState(() => _selectedTrainingExperience = exp),
          onActivityLevelChanged: (level) => setState(() => _selectedActivityLevel = level),
        );
      case 2:
        return _buildDaysSelector();
      case 3:
        return _buildEquipmentSelector();
      case 4:
        return QuizBodyMetrics(
          key: const ValueKey('body_metrics'),
          name: _name,
          dateOfBirth: _dateOfBirth,
          gender: _gender,
          heightCm: _heightCm,
          weightKg: _weightKg,
          goalWeightKg: _goalWeightKg,
          useMetric: _useMetric,
          weightDirection: _weightDirection,
          weightChangeAmount: _weightChangeAmount,
          onNameChanged: (name) => setState(() => _name = name),
          onDateOfBirthChanged: (dob) => setState(() => _dateOfBirth = dob),
          onGenderChanged: (gender) => setState(() => _gender = gender),
          onHeightChanged: (height) => setState(() => _heightCm = height),
          onWeightChanged: (weight) => setState(() => _weightKg = weight),
          onGoalWeightChanged: (goalWeight) => setState(() => _goalWeightKg = goalWeight),
          onUnitChanged: (useMetric) => setState(() => _useMetric = useMetric),
          onWeightDirectionChanged: (direction) => setState(() => _weightDirection = direction),
          onWeightChangeAmountChanged: (amount) => setState(() => _weightChangeAmount = amount),
        );
      case 5:
        if (showRateQuestion) {
          return QuizWeightRate(
            key: const ValueKey('weight_rate'),
            weightDirection: _weightDirection,
            selectedRate: _weightChangeRate,
            currentWeight: _weightKg,
            goalWeight: _goalWeightKg,
            useMetric: _useMetric,
            onRateChanged: (rate) => setState(() => _weightChangeRate = rate),
          );
        }
        return _buildTrainingPreferences();
      case 6:
        if (showRateQuestion) {
          return _buildTrainingPreferences();
        }
        return _buildNutritionGoals();
      case 7:
        if (showRateQuestion) {
          return _buildNutritionGoals();
        }
        return _buildFasting();
      case 8:
        if (showRateQuestion) {
          return _buildFasting();
        }
        return _buildMotivation();
      case 9:
        if (showRateQuestion) {
          return _buildMotivation();
        }
        return _buildPrimaryGoal();
      case 10:
        if (showRateQuestion) {
          return _buildPrimaryGoal();
        }
        return _buildMuscleFocus();
      case 11:
        // Only reached if showing rate question (12 questions)
        return _buildMuscleFocus();
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
        'label': 'Muscle Hypertrophy',
        'description': 'Workouts will focus on increasing muscle size using moderate weights and higher reps (8-12 reps).',
        'icon': Icons.fitness_center,
        'color': AppColors.accent,
      },
      {
        'id': 'muscle_strength',
        'label': 'Muscle Strength',
        'description': 'Workouts will focus on increasing maximal strength using heavier weights for fewer reps (3-6 reps).',
        'icon': Icons.bolt,
        'color': AppColors.electricBlue,
      },
      {
        'id': 'strength_hypertrophy',
        'label': 'Both Strength & Hypertrophy',
        'description': 'Workouts will balance strength and size with a variety of weight and rep schemes (6-10 reps).',
        'icon': Icons.all_inclusive,
        'color': AppColors.teal,
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
      {'id': 'build_muscle', 'label': 'Build Muscle', 'icon': Icons.fitness_center, 'color': AppColors.accent},
      {'id': 'lose_weight', 'label': 'Lose Weight', 'icon': Icons.monitor_weight_outlined, 'color': AppColors.accent},
      {'id': 'increase_strength', 'label': 'Get Stronger', 'icon': Icons.bolt, 'color': AppColors.accent},
      {'id': 'improve_endurance', 'label': 'Build Endurance', 'icon': Icons.directions_run, 'color': AppColors.teal},
      {'id': 'stay_active', 'label': 'Stay Active', 'icon': Icons.favorite_outline, 'color': AppColors.success},
      {'id': 'athletic_performance', 'label': 'Athletic Performance', 'icon': Icons.sports_martial_arts, 'color': AppColors.electricBlue},
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
