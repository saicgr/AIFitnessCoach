import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  // Captured at personal info step — TRUE if user identified as a personal trainer.
  // Warm-lead segment for Reppora alpha launch invites.
  final bool? isTrainer;

  // ── Onboarding v5 fields ───────────────────────────────────────
  // Market research — captured during pre-auth quiz, useful even for
  // users who never sign up (analytics on funnel sources + competitors).
  final String? referralSource;          // "tiktok" | "friend" | "appstore" | etc.
  final List<String>? priorAppsTried;    // competitor apps user tried before
  // Personalization
  final String? referralCode;            // optional discount code at signup
  final String? coachName;               // user-named AI coach (loss aversion lever)
  // Pre-signup goal projection — server-computed via /onboarding/computed-goal-date.
  // Anchored throughout trial (home header, coach messages, trial summary).
  final String? goalTargetDate;          // ISO date YYYY-MM-DD

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
    this.isTrainer,
    this.referralSource,
    this.priorAppsTried,
    this.referralCode,
    this.coachName,
    this.goalTargetDate,
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

  /// Create a copy of this data with the given fields replaced.
  /// Eliminates the need to repeat all fields in every setter.
  PreAuthQuizData copyWith({
    List<String>? goals,
    String? fitnessLevel,
    String? trainingExperience,
    String? activityLevel,
    String? name,
    DateTime? dateOfBirth,
    String? gender,
    double? heightCm,
    double? weightKg,
    double? goalWeightKg,
    bool? useMetricUnits,
    String? weightDirection,
    double? weightChangeAmount,
    String? weightChangeRate,
    int? daysPerWeek,
    List<int>? workoutDays,
    int? workoutDuration,
    int? workoutDurationMin,
    int? workoutDurationMax,
    List<String>? equipment,
    List<String>? customEquipment,
    String? workoutEnvironment,
    String? trainingSplit,
    List<String>? motivations,
    int? dumbbellCount,
    int? kettlebellCount,
    String? workoutTypePreference,
    String? workoutVariety,
    String? progressionPace,
    String? sleepQuality,
    List<String>? obstacles,
    List<String>? nutritionGoals,
    List<String>? dietaryRestrictions,
    int? mealsPerDay,
    bool? interestedInFasting,
    String? fastingProtocol,
    String? wakeTime,
    String? sleepTime,
    String? primaryGoal,
    Map<String, int>? muscleFocusPoints,
    bool? nutritionEnabled,
    List<String>? limitations,
    String? pushupCapacity,
    String? pullupCapacity,
    String? plankCapacity,
    String? squatCapacity,
    String? cardioCapacity,
    bool? isTrainer,
    String? referralSource,
    List<String>? priorAppsTried,
    String? referralCode,
    String? coachName,
    String? goalTargetDate,
  }) {
    return PreAuthQuizData(
      goals: goals ?? this.goals,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      trainingExperience: trainingExperience ?? this.trainingExperience,
      activityLevel: activityLevel ?? this.activityLevel,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      goalWeightKg: goalWeightKg ?? this.goalWeightKg,
      useMetricUnits: useMetricUnits ?? this.useMetricUnits,
      weightDirection: weightDirection ?? this.weightDirection,
      weightChangeAmount: weightChangeAmount ?? this.weightChangeAmount,
      weightChangeRate: weightChangeRate ?? this.weightChangeRate,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      workoutDays: workoutDays ?? this.workoutDays,
      workoutDuration: workoutDuration ?? this.workoutDuration,
      workoutDurationMin: workoutDurationMin ?? this.workoutDurationMin,
      workoutDurationMax: workoutDurationMax ?? this.workoutDurationMax,
      equipment: equipment ?? this.equipment,
      customEquipment: customEquipment ?? this.customEquipment,
      workoutEnvironment: workoutEnvironment ?? this.workoutEnvironment,
      trainingSplit: trainingSplit ?? this.trainingSplit,
      motivations: motivations ?? this.motivations,
      dumbbellCount: dumbbellCount ?? this.dumbbellCount,
      kettlebellCount: kettlebellCount ?? this.kettlebellCount,
      workoutTypePreference: workoutTypePreference ?? this.workoutTypePreference,
      workoutVariety: workoutVariety ?? this.workoutVariety,
      progressionPace: progressionPace ?? this.progressionPace,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      obstacles: obstacles ?? this.obstacles,
      nutritionGoals: nutritionGoals ?? this.nutritionGoals,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      interestedInFasting: interestedInFasting ?? this.interestedInFasting,
      fastingProtocol: fastingProtocol ?? this.fastingProtocol,
      wakeTime: wakeTime ?? this.wakeTime,
      sleepTime: sleepTime ?? this.sleepTime,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      muscleFocusPoints: muscleFocusPoints ?? this.muscleFocusPoints,
      nutritionEnabled: nutritionEnabled ?? this.nutritionEnabled,
      limitations: limitations ?? this.limitations,
      pushupCapacity: pushupCapacity ?? this.pushupCapacity,
      pullupCapacity: pullupCapacity ?? this.pullupCapacity,
      plankCapacity: plankCapacity ?? this.plankCapacity,
      squatCapacity: squatCapacity ?? this.squatCapacity,
      cardioCapacity: cardioCapacity ?? this.cardioCapacity,
      isTrainer: isTrainer ?? this.isTrainer,
      referralSource: referralSource ?? this.referralSource,
      priorAppsTried: priorAppsTried ?? this.priorAppsTried,
      referralCode: referralCode ?? this.referralCode,
      coachName: coachName ?? this.coachName,
      goalTargetDate: goalTargetDate ?? this.goalTargetDate,
    );
  }

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
        'isTrainer': isTrainer,
        'referralSource': referralSource,
        'priorAppsTried': priorAppsTried,
        'referralCode': referralCode,
        'coachName': coachName,
        'goalTargetDate': goalTargetDate,
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
        isTrainer: json['isTrainer'] as bool?,
        referralSource: json['referralSource'] as String?,
        priorAppsTried: (json['priorAppsTried'] as List<dynamic>?)?.cast<String>(),
        referralCode: json['referralCode'] as String?,
        coachName: json['coachName'] as String?,
        goalTargetDate: json['goalTargetDate'] as String?,
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

  /// True while [_loadFromPrefs] is executing. Used by [state] override to
  /// suppress timestamp updates triggered by hydration (only real user input
  /// should refresh the staleness clock).
  bool _suppressTouch = false;

  /// Quiz answers older than this are treated as abandoned and cleared on the
  /// next cold-start `_loadFromPrefs`. Handles the anonymous-user case where
  /// User A fills quiz, never signs in, days later User B opens the app and
  /// would otherwise see prefilled answers.
  static const Duration _staleQuizThreshold = Duration(days: 14);

  static const _lastTouchedAtKey = 'preAuth_lastTouchedAt';

  @override
  set state(PreAuthQuizData value) {
    super.state = value;
    if (!_suppressTouch) {
      // Fire-and-forget — never block UI on the timestamp write.
      // ignore: discarded_futures
      _touchTimestamp();
    }
  }

  Future<void> _touchTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastTouchedAtKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {
      // Non-fatal — staleness check just falls back to "no timestamp" branch.
    }
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Stale-data guard: if the quiz was last touched longer than
    // [_staleQuizThreshold] ago, treat it as abandoned and wipe before loading.
    // Without this, User B picking up a device User A briefly used could see
    // User A's prefilled answers in the quiz UI.
    final lastTouchedMs = prefs.getInt(_lastTouchedAtKey);
    if (lastTouchedMs != null) {
      final age = DateTime.now().millisecondsSinceEpoch - lastTouchedMs;
      if (age > _staleQuizThreshold.inMilliseconds) {
        await _wipeQuizKeys(prefs);
        await prefs.remove(_lastTouchedAtKey);
        state = PreAuthQuizData();
        _isLoaded = true;
        return;
      }
    }
    final goals = prefs.getStringList('preAuth_goals');
    final level = prefs.getString('preAuth_fitnessLevel');
    final trainingExp = prefs.getString('preAuth_trainingExperience');
    final activityLevel = prefs.getString('preAuth_activityLevel');
    final name = prefs.getString('preAuth_name');
    final dateOfBirthStr = prefs.getString('preAuth_dateOfBirth');
    final dateOfBirth = dateOfBirthStr != null ? DateTime.tryParse(dateOfBirthStr) : null;
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
    final pushupCapacity = prefs.getString('preAuth_pushupCapacity');
    final pullupCapacity = prefs.getString('preAuth_pullupCapacity');
    final plankCapacity = prefs.getString('preAuth_plankCapacity');
    final squatCapacity = prefs.getString('preAuth_squatCapacity');
    final cardioCapacity = prefs.getString('preAuth_cardioCapacity');
    final isTrainer = prefs.getBool('preAuth_isTrainer');
    final referralSource = prefs.getString('preAuth_referralSource');
    final priorAppsTried = prefs.getStringList('preAuth_priorAppsTried');
    final referralCode = prefs.getString('preAuth_referralCode');
    final coachName = prefs.getString('preAuth_coachName');
    final goalTargetDate = prefs.getString('preAuth_goalTargetDate');

    _suppressTouch = true;
    try {
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
        isTrainer: isTrainer,
        referralSource: referralSource,
        priorAppsTried: priorAppsTried,
        referralCode: referralCode,
        coachName: coachName,
        goalTargetDate: goalTargetDate,
      );
    } finally {
      _suppressTouch = false;
    }
    _isLoaded = true;
  }

  Future<PreAuthQuizData> ensureLoaded() async {
    if (!_isLoaded) {
      await _loadFromPrefs();
    }
    return state;
  }

  /// Hydrate quiz state from a backend user object's preferences.
  /// Used after sign-in when local quiz is empty but the user has previously
  /// saved preferences server-side (e.g. uninstall/reinstall mid-onboarding).
  ///
  /// Reads from both top-level user columns (fitness_level, equipment, etc.)
  /// and the nested preferences JSONB. Only writes fields that are present
  /// in the source — does not nullify existing local data.
  Future<void> hydrateFromUserPreferences(Map<String, dynamic> userJson) async {
    final prefs = await SharedPreferences.getInstance();

    Map<String, dynamic> nested = {};
    final prefsRaw = userJson['preferences'];
    if (prefsRaw is String && prefsRaw.isNotEmpty) {
      try {
        final decoded = _safeJsonDecode(prefsRaw);
        if (decoded is Map<String, dynamic>) nested = decoded;
      } catch (_) {}
    } else if (prefsRaw is Map<String, dynamic>) {
      nested = prefsRaw;
    }

    // Merge: nested preferences first, top-level columns override (more authoritative)
    T? pick<T>(String nestedKey, [String? topKey]) {
      final topVal = topKey != null ? userJson[topKey] : null;
      if (topVal != null) return topVal as T?;
      final nestedVal = nested[nestedKey];
      return nestedVal as T?;
    }

    // Goals (stored as JSON list in user.goals OR plain list in preferences.goals)
    List<String>? goalsList;
    final goalsRaw = userJson['goals'] ?? nested['goals'];
    if (goalsRaw is List) {
      goalsList = goalsRaw.map((e) => e.toString()).toList();
    } else if (goalsRaw is String && goalsRaw.isNotEmpty) {
      try {
        final decoded = _safeJsonDecode(goalsRaw);
        if (decoded is List) {
          goalsList = decoded.map((e) => e.toString()).toList();
        } else if (decoded is String) {
          goalsList = [decoded];
        }
      } catch (_) {
        goalsList = [goalsRaw];
      }
    }
    if (goalsList != null && goalsList.isNotEmpty) {
      await prefs.setStringList('preAuth_goals', goalsList);
    }

    // Equipment (same dual-format handling)
    List<String>? equipmentList;
    final equipmentRaw = userJson['equipment'] ?? nested['equipment'];
    if (equipmentRaw is List) {
      equipmentList = equipmentRaw.map((e) => e.toString()).toList();
    } else if (equipmentRaw is String && equipmentRaw.isNotEmpty) {
      try {
        final decoded = _safeJsonDecode(equipmentRaw);
        if (decoded is List) {
          equipmentList = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }
    if (equipmentList != null && equipmentList.isNotEmpty) {
      await prefs.setStringList('preAuth_equipment', equipmentList);
    }

    // String fields
    final fitnessLevel = pick<String>('fitness_level', 'fitness_level');
    if (fitnessLevel != null) await prefs.setString('preAuth_fitnessLevel', fitnessLevel);

    final trainingExperience = pick<String>('training_experience');
    if (trainingExperience != null) await prefs.setString('preAuth_trainingExperience', trainingExperience);

    final activityLevel = pick<String>('activity_level', 'activity_level');
    if (activityLevel != null) await prefs.setString('preAuth_activityLevel', activityLevel);

    final gender = pick<String>('gender', 'gender');
    if (gender != null) await prefs.setString('preAuth_gender', gender);

    final name = pick<String>('name', 'name');
    if (name != null) await prefs.setString('preAuth_name', name);

    final dob = pick<String>('date_of_birth', 'date_of_birth');
    if (dob != null) await prefs.setString('preAuth_dateOfBirth', dob);

    final primaryGoal = pick<String>('primary_goal', 'primary_goal');
    if (primaryGoal != null) await prefs.setString('preAuth_primaryGoal', primaryGoal);

    final trainingSplit = pick<String>('training_split');
    if (trainingSplit != null) await prefs.setString('preAuth_trainingSplit', trainingSplit);

    final progressionPace = pick<String>('progression_pace');
    if (progressionPace != null) await prefs.setString('preAuth_progressionPace', progressionPace);

    final workoutEnvironment = pick<String>('workout_environment');
    if (workoutEnvironment != null) await prefs.setString('preAuth_workoutEnvironment', workoutEnvironment);

    final weightDirection = pick<String>('weight_direction');
    if (weightDirection != null) await prefs.setString('preAuth_weightDirection', weightDirection);

    final weightChangeRate = pick<String>('weight_change_rate');
    if (weightChangeRate != null) await prefs.setString('preAuth_weightChangeRate', weightChangeRate);

    // Numeric fields
    final heightCm = pick<num>('height_cm', 'height_cm');
    if (heightCm != null) await prefs.setDouble('preAuth_heightCm', heightCm.toDouble());

    final weightKg = pick<num>('weight_kg', 'weight_kg');
    if (weightKg != null) await prefs.setDouble('preAuth_weightKg', weightKg.toDouble());

    final goalWeightKg = pick<num>('goal_weight_kg', 'target_weight_kg');
    if (goalWeightKg != null) await prefs.setDouble('preAuth_goalWeightKg', goalWeightKg.toDouble());

    final weightChangeAmount = pick<num>('weight_change_amount');
    if (weightChangeAmount != null) await prefs.setDouble('preAuth_weightChangeAmount', weightChangeAmount.toDouble());

    final daysPerWeek = pick<num>('days_per_week') ?? pick<num>('workouts_per_week');
    if (daysPerWeek != null) await prefs.setInt('preAuth_daysPerWeek', daysPerWeek.toInt());

    final workoutDuration = pick<num>('workout_duration');
    if (workoutDuration != null) await prefs.setInt('preAuth_workoutDuration', workoutDuration.toInt());

    final workoutDurationMin = pick<num>('workout_duration_min');
    if (workoutDurationMin != null) await prefs.setInt('preAuth_workoutDurationMin', workoutDurationMin.toInt());

    final workoutDurationMax = pick<num>('workout_duration_max');
    if (workoutDurationMax != null) await prefs.setInt('preAuth_workoutDurationMax', workoutDurationMax.toInt());

    // workout_days (List<int>) — stored as List<String> in prefs
    final workoutDaysRaw = nested['workout_days'] ?? nested['selected_days'];
    if (workoutDaysRaw is List && workoutDaysRaw.isNotEmpty) {
      final asStrings = workoutDaysRaw.map((e) => e.toString()).toList();
      await prefs.setStringList('preAuth_workoutDays', asStrings);
    }

    // List fields stored as List<String>
    void writeStringList(String nestedKey, String prefKey) {
      final raw = nested[nestedKey];
      if (raw is List && raw.isNotEmpty) {
        prefs.setStringList(prefKey, raw.map((e) => e.toString()).toList());
      }
    }
    writeStringList('motivations', 'preAuth_motivations');
    writeStringList('obstacles', 'preAuth_obstacles');
    writeStringList('limitations', 'preAuth_limitations');

    // Reload state from the freshly-populated prefs so consumers see the new values.
    await _loadFromPrefs();
  }

  dynamic _safeJsonDecode(String s) => jsonDecode(s);

  // --- Setters using copyWith to reduce boilerplate ---

  Future<void> setGoals(List<String> goals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('preAuth_goals', goals);
    state = state.copyWith(goals: goals);
  }

  Future<void> setFitnessLevel(String level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_fitnessLevel', level);
    state = state.copyWith(fitnessLevel: level);
  }

  Future<void> setTrainingExperience(String experience) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_trainingExperience', experience);
    state = state.copyWith(trainingExperience: experience);
  }

  Future<void> setActivityLevel(String level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_activityLevel', level);
    state = state.copyWith(activityLevel: level);
  }

  Future<void> setIsTrainer(bool isTrainer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('preAuth_isTrainer', isTrainer);
    state = state.copyWith(isTrainer: isTrainer);
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
    if (name != null) await prefs.setString('preAuth_name', name);
    if (dateOfBirth != null) await prefs.setString('preAuth_dateOfBirth', dateOfBirth.toIso8601String());
    if (gender != null) await prefs.setString('preAuth_gender', gender);
    await prefs.setDouble('preAuth_heightCm', heightCm);
    await prefs.setDouble('preAuth_weightKg', weightKg);
    await prefs.setDouble('preAuth_goalWeightKg', goalWeightKg);
    await prefs.setBool('preAuth_useMetric', useMetric);
    if (weightDirection != null) await prefs.setString('preAuth_weightDirection', weightDirection);
    if (weightChangeAmount != null) await prefs.setDouble('preAuth_weightChangeAmount', weightChangeAmount);
    if (weightChangeRate != null) await prefs.setString('preAuth_weightChangeRate', weightChangeRate);
    state = state.copyWith(
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
    );
  }

  Future<void> setDaysPerWeek(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('preAuth_daysPerWeek', days);
    state = state.copyWith(daysPerWeek: days);
  }

  Future<void> setWorkoutDays(List<int> workoutDays) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('preAuth_workoutDays', workoutDays.map((d) => d.toString()).toList());
    state = state.copyWith(workoutDays: workoutDays);
  }

  Future<void> setWorkoutDuration(int minDuration, int maxDuration) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('preAuth_workoutDurationMin', minDuration);
    await prefs.setInt('preAuth_workoutDurationMax', maxDuration);
    await prefs.setInt('preAuth_workoutDuration', maxDuration);
    state = state.copyWith(
      workoutDuration: maxDuration,
      workoutDurationMin: minDuration,
      workoutDurationMax: maxDuration,
    );
  }

  String _inferWorkoutEnvironment(List<String> equipment) {
    if (equipment.contains('full_gym') ||
        (equipment.contains('barbell') && equipment.contains('cable_machine'))) {
      return 'commercial_gym';
    }
    if (equipment.contains('barbell') || equipment.contains('cable_machine') ||
        equipment.contains('smith_machine') || equipment.contains('leg_press') ||
        equipment.contains('lat_pulldown') || equipment.contains('squat_rack')) {
      return 'home_gym';
    }
    const bodyweightOnly = {'bodyweight', 'yoga_mat', 'jump_rope'};
    final hasRealEquipment = equipment.any((e) => !bodyweightOnly.contains(e));
    if (hasRealEquipment) {
      return 'home';
    }
    return 'home';
  }

  Future<void> setEquipment(List<String> equipment, {int? dumbbellCount, int? kettlebellCount, List<String>? customEquipment}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('preAuth_equipment', equipment);
    if (dumbbellCount != null) await prefs.setInt('preAuth_dumbbellCount', dumbbellCount);
    if (kettlebellCount != null) await prefs.setInt('preAuth_kettlebellCount', kettlebellCount);
    if (customEquipment != null) await prefs.setStringList('preAuth_customEquipment', customEquipment);
    final workoutEnv = _inferWorkoutEnvironment(equipment);
    await prefs.setString('preAuth_workoutEnvironment', workoutEnv);
    state = state.copyWith(
      equipment: equipment,
      customEquipment: customEquipment ?? state.customEquipment,
      workoutEnvironment: workoutEnv,
      dumbbellCount: dumbbellCount ?? state.dumbbellCount,
      kettlebellCount: kettlebellCount ?? state.kettlebellCount,
    );
  }

  Future<void> setTrainingSplit(String split) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_trainingSplit', split);
    state = state.copyWith(trainingSplit: split);
  }

  Future<void> setMotivations(List<String> motivations) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('preAuth_motivations', motivations);
    state = state.copyWith(motivations: motivations);
  }

  Future<void> setWorkoutTypePreference(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_workoutTypePreference', type);
    state = state.copyWith(workoutTypePreference: type);
  }

  Future<void> setWorkoutVariety(String variety) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_workoutVariety', variety);
    state = state.copyWith(workoutVariety: variety);
  }

  Future<void> setProgressionPace(String pace) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_progressionPace', pace);
    state = state.copyWith(progressionPace: pace);
  }

  Future<void> setNutritionGoals(List<String> nutritionGoals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('preAuth_nutritionGoals', nutritionGoals);
    state = state.copyWith(nutritionGoals: nutritionGoals);
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
    if (wakeTime != null) await prefs.setString('preAuth_wakeTime', wakeTime);
    if (sleepTime != null) await prefs.setString('preAuth_sleepTime', sleepTime);
    state = state.copyWith(
      interestedInFasting: interested,
      fastingProtocol: protocol,
      wakeTime: wakeTime ?? state.wakeTime,
      sleepTime: sleepTime ?? state.sleepTime,
    );
  }

  Future<void> setSleepQuality(String quality) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_sleepQuality', quality);
    state = state.copyWith(sleepQuality: quality);
  }

  Future<void> setObstacles(List<String> obstacles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('preAuth_obstacles', obstacles);
    state = state.copyWith(obstacles: obstacles);
  }

  Future<void> setDietaryRestrictions(List<String> restrictions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('preAuth_dietaryRestrictions', restrictions);
    state = state.copyWith(dietaryRestrictions: restrictions);
  }

  Future<void> setMealsPerDay(int meals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('preAuth_mealsPerDay', meals);
    state = state.copyWith(mealsPerDay: meals);
  }

  Future<void> setPushupCapacity(String capacity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_pushupCapacity', capacity);
    state = state.copyWith(pushupCapacity: capacity);
  }

  Future<void> setPullupCapacity(String capacity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_pullupCapacity', capacity);
    state = state.copyWith(pullupCapacity: capacity);
  }

  Future<void> setPlankCapacity(String capacity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_plankCapacity', capacity);
    state = state.copyWith(plankCapacity: capacity);
  }

  Future<void> setSquatCapacity(String capacity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_squatCapacity', capacity);
    state = state.copyWith(squatCapacity: capacity);
  }

  Future<void> setCardioCapacity(String capacity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_cardioCapacity', capacity);
    state = state.copyWith(cardioCapacity: capacity);
  }

  /// Remove every pre-auth quiz key from SharedPreferences. Used by both
  /// [clear] (state-resetting) and the stale-clear path inside [_loadFromPrefs]
  /// (avoids recursion through state setter).
  Future<void> _wipeQuizKeys(SharedPreferences prefs) async {
    const keysToRemove = [
      'preAuth_goals', 'preAuth_fitnessLevel', 'preAuth_trainingExperience',
      'preAuth_activityLevel', 'preAuth_name', 'preAuth_dateOfBirth',
      'preAuth_gender', 'preAuth_heightCm', 'preAuth_weightKg',
      'preAuth_goalWeightKg', 'preAuth_useMetric', 'preAuth_weightDirection',
      'preAuth_weightChangeAmount', 'preAuth_weightChangeRate',
      'preAuth_daysPerWeek', 'preAuth_workoutDays', 'preAuth_workoutDuration',
      'preAuth_workoutDurationMin', 'preAuth_workoutDurationMax',
      'preAuth_equipment', 'preAuth_customEquipment', 'preAuth_workoutEnvironment',
      'preAuth_trainingSplit', 'preAuth_motivations', 'preAuth_dumbbellCount',
      'preAuth_kettlebellCount', 'preAuth_workoutTypePreference',
      'preAuth_progressionPace', 'preAuth_sleepQuality', 'preAuth_obstacles',
      'preAuth_nutritionGoals', 'preAuth_dietaryRestrictions', 'preAuth_mealsPerDay',
      'preAuth_interestedInFasting', 'preAuth_fastingProtocol',
      'preAuth_wakeTime', 'preAuth_sleepTime', 'preAuth_primaryGoal',
      'preAuth_muscleFocusPoints', 'preAuth_pushupCapacity',
      'preAuth_pullupCapacity', 'preAuth_plankCapacity',
      'preAuth_squatCapacity', 'preAuth_cardioCapacity',
      'preAuth_isTrainer',
      // Onboarding v5 fields
      'preAuth_referralSource', 'preAuth_priorAppsTried',
      'preAuth_referralCode', 'preAuth_coachName',
      'preAuth_goalTargetDate',
    ];
    for (final key in keysToRemove) {
      await prefs.remove(key);
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await _wipeQuizKeys(prefs);
    await prefs.remove(_lastTouchedAtKey);
    _suppressTouch = true;
    try {
      state = PreAuthQuizData();
    } finally {
      _suppressTouch = false;
    }
  }

  Future<void> setPrimaryGoal(String goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_primaryGoal', goal);
    state = state.copyWith(primaryGoal: goal);
  }

  Future<void> setMuscleFocusPoints(Map<String, int> points) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = points.entries.map((e) => '${e.key}=${e.value}').join('&');
    await prefs.setString('preAuth_muscleFocusPoints', encoded);
    state = state.copyWith(muscleFocusPoints: points);
  }

  Future<void> setNutritionEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('preAuth_nutritionEnabled', enabled);
    state = state.copyWith(nutritionEnabled: enabled);
  }

  Future<void> setLimitations(List<String> limitations) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('preAuth_limitations', limitations);
    state = state.copyWith(limitations: limitations);
  }

  Future<void> setWorkoutEnvironment(String environment) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_workoutEnvironment', environment);
    state = state.copyWith(workoutEnvironment: environment);
  }

  Future<void> setIsComplete(bool isComplete) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('preAuth_isComplete', isComplete);
  }

  // ── Onboarding v5 setters ─────────────────────────────────────────

  Future<void> setReferralSource(String source) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_referralSource', source);
    state = state.copyWith(referralSource: source);
  }

  Future<void> setPriorAppsTried(List<String> apps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('preAuth_priorAppsTried', apps);
    state = state.copyWith(priorAppsTried: apps);
  }

  Future<void> setReferralCode(String? code) async {
    final prefs = await SharedPreferences.getInstance();
    if (code == null || code.isEmpty) {
      await prefs.remove('preAuth_referralCode');
      state = state.copyWith(referralCode: null);
    } else {
      await prefs.setString('preAuth_referralCode', code);
      state = state.copyWith(referralCode: code);
    }
  }

  Future<void> setCoachName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_coachName', name);
    state = state.copyWith(coachName: name);
  }

  Future<void> setGoalTargetDate(String isoDate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_goalTargetDate', isoDate);
    state = state.copyWith(goalTargetDate: isoDate);
  }
}
