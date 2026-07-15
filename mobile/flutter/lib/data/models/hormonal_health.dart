import 'package:json_annotation/json_annotation.dart';

part 'hormonal_health.g.dart';

// ============================================================================
// ENUMS
// ============================================================================

enum Gender {
  @JsonValue('male')
  male,
  @JsonValue('female')
  female,
  @JsonValue('non_binary')
  nonBinary,
  @JsonValue('other')
  other,
  @JsonValue('prefer_not_to_say')
  preferNotToSay,
}

enum BirthSex {
  @JsonValue('male')
  male,
  @JsonValue('female')
  female,
  @JsonValue('intersex')
  intersex,
  @JsonValue('prefer_not_to_say')
  preferNotToSay,
}

extension GenderExtension on Gender {
  String get displayName {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.nonBinary:
        return 'Non-Binary';
      case Gender.other:
        return 'Other';
      case Gender.preferNotToSay:
        return 'Prefer Not to Say';
    }
  }

  String get value {
    switch (this) {
      case Gender.male:
        return 'male';
      case Gender.female:
        return 'female';
      case Gender.nonBinary:
        return 'non_binary';
      case Gender.other:
        return 'other';
      case Gender.preferNotToSay:
        return 'prefer_not_to_say';
    }
  }
}

extension BirthSexExtension on BirthSex {
  String get displayName {
    switch (this) {
      case BirthSex.male:
        return 'Male';
      case BirthSex.female:
        return 'Female';
      case BirthSex.intersex:
        return 'Intersex';
      case BirthSex.preferNotToSay:
        return 'Prefer Not to Say';
    }
  }

  String get value {
    switch (this) {
      case BirthSex.male:
        return 'male';
      case BirthSex.female:
        return 'female';
      case BirthSex.intersex:
        return 'intersex';
      case BirthSex.preferNotToSay:
        return 'prefer_not_to_say';
    }
  }
}

enum HormoneGoal {
  @JsonValue('optimize_testosterone')
  optimizeTestosterone,
  @JsonValue('balance_estrogen')
  balanceEstrogen,
  @JsonValue('improve_fertility')
  improveFertility,
  @JsonValue('menopause_support')
  menopauseSupport,
  @JsonValue('pcos_management')
  pcosManagement,
  @JsonValue('perimenopause_support')
  perimenopauseSupport,
  @JsonValue('andropause_support')
  andropauseSupport,
  @JsonValue('general_wellness')
  generalWellness,
  @JsonValue('libido_enhancement')
  libidoEnhancement,
  @JsonValue('energy_optimization')
  energyOptimization,
  @JsonValue('mood_stabilization')
  moodStabilization,
  @JsonValue('sleep_improvement')
  sleepImprovement,
}

extension HormoneGoalExtension on HormoneGoal {
  String get displayName {
    switch (this) {
      case HormoneGoal.optimizeTestosterone:
        return 'Optimize Testosterone';
      case HormoneGoal.balanceEstrogen:
        return 'Balance Estrogen';
      case HormoneGoal.improveFertility:
        return 'Improve Fertility';
      case HormoneGoal.menopauseSupport:
        return 'Menopause Support';
      case HormoneGoal.pcosManagement:
        return 'PCOS Management';
      case HormoneGoal.perimenopauseSupport:
        return 'Perimenopause Support';
      case HormoneGoal.andropauseSupport:
        return 'Andropause Support';
      case HormoneGoal.generalWellness:
        return 'General Wellness';
      case HormoneGoal.libidoEnhancement:
        return 'Libido Enhancement';
      case HormoneGoal.energyOptimization:
        return 'Energy Optimization';
      case HormoneGoal.moodStabilization:
        return 'Mood Stabilization';
      case HormoneGoal.sleepImprovement:
        return 'Sleep Improvement';
    }
  }

  String get description {
    switch (this) {
      case HormoneGoal.optimizeTestosterone:
        return 'Support healthy testosterone levels through nutrition, exercise, and lifestyle';
      case HormoneGoal.balanceEstrogen:
        return 'Maintain healthy estrogen metabolism and balance';
      case HormoneGoal.improveFertility:
        return 'Optimize reproductive health and fertility';
      case HormoneGoal.menopauseSupport:
        return 'Manage menopause symptoms and support hormonal transition';
      case HormoneGoal.pcosManagement:
        return 'Support PCOS management through lifestyle interventions';
      case HormoneGoal.perimenopauseSupport:
        return 'Navigate perimenopause with targeted support';
      case HormoneGoal.andropauseSupport:
        return 'Support male hormonal health during aging';
      case HormoneGoal.generalWellness:
        return 'Overall hormonal health and balance';
      case HormoneGoal.libidoEnhancement:
        return 'Support healthy libido and sexual wellness';
      case HormoneGoal.energyOptimization:
        return 'Optimize energy levels through hormonal balance';
      case HormoneGoal.moodStabilization:
        return 'Support stable mood through hormonal health';
      case HormoneGoal.sleepImprovement:
        return 'Improve sleep quality through hormonal optimization';
    }
  }

  String get icon {
    switch (this) {
      case HormoneGoal.optimizeTestosterone:
        return '💪';
      case HormoneGoal.balanceEstrogen:
        return '⚖️';
      case HormoneGoal.improveFertility:
        return '🌱';
      case HormoneGoal.menopauseSupport:
        return '🌸';
      case HormoneGoal.pcosManagement:
        return '🎯';
      case HormoneGoal.perimenopauseSupport:
        return '🌺';
      case HormoneGoal.andropauseSupport:
        return '🔄';
      case HormoneGoal.generalWellness:
        return '✨';
      case HormoneGoal.libidoEnhancement:
        return '❤️';
      case HormoneGoal.energyOptimization:
        return '⚡';
      case HormoneGoal.moodStabilization:
        return '😊';
      case HormoneGoal.sleepImprovement:
        return '😴';
    }
  }

  String get value {
    switch (this) {
      case HormoneGoal.optimizeTestosterone:
        return 'optimize_testosterone';
      case HormoneGoal.balanceEstrogen:
        return 'balance_estrogen';
      case HormoneGoal.improveFertility:
        return 'improve_fertility';
      case HormoneGoal.menopauseSupport:
        return 'menopause_support';
      case HormoneGoal.pcosManagement:
        return 'pcos_management';
      case HormoneGoal.perimenopauseSupport:
        return 'perimenopause_support';
      case HormoneGoal.andropauseSupport:
        return 'andropause_support';
      case HormoneGoal.generalWellness:
        return 'general_wellness';
      case HormoneGoal.libidoEnhancement:
        return 'libido_enhancement';
      case HormoneGoal.energyOptimization:
        return 'energy_optimization';
      case HormoneGoal.moodStabilization:
        return 'mood_stabilization';
      case HormoneGoal.sleepImprovement:
        return 'sleep_improvement';
    }
  }
}

enum MenopauseStatus {
  @JsonValue('pre')
  pre,
  @JsonValue('peri')
  peri,
  @JsonValue('post')
  post,
  @JsonValue('not_applicable')
  notApplicable,
}

enum CyclePhase {
  @JsonValue('menstrual')
  menstrual,
  @JsonValue('follicular')
  follicular,
  @JsonValue('ovulation')
  ovulation,
  @JsonValue('luteal')
  luteal,
}

extension CyclePhaseExtension on CyclePhase {
  String get displayName {
    switch (this) {
      case CyclePhase.menstrual:
        return 'Menstrual';
      case CyclePhase.follicular:
        return 'Follicular';
      case CyclePhase.ovulation:
        return 'Ovulation';
      case CyclePhase.luteal:
        return 'Luteal';
    }
  }

  String get description {
    switch (this) {
      case CyclePhase.menstrual:
        return 'Days 1-5: Rest and recovery phase';
      case CyclePhase.follicular:
        return 'Days 6-13: Rising energy, great for new challenges';
      case CyclePhase.ovulation:
        return 'Days 14-16: Peak energy and performance';
      case CyclePhase.luteal:
        return 'Days 17-28: Winding down, focus on maintenance';
    }
  }

  String get color {
    switch (this) {
      case CyclePhase.menstrual:
        return '#E57373'; // Red
      case CyclePhase.follicular:
        return '#81C784'; // Green
      case CyclePhase.ovulation:
        return '#FFD54F'; // Yellow
      case CyclePhase.luteal:
        return '#64B5F6'; // Blue
    }
  }

  String get workoutIntensity {
    switch (this) {
      case CyclePhase.menstrual:
        return 'Light to Moderate';
      case CyclePhase.follicular:
        return 'Moderate to High';
      case CyclePhase.ovulation:
        return 'High';
      case CyclePhase.luteal:
        return 'Moderate';
    }
  }
}

enum Mood {
  @JsonValue('excellent')
  excellent,
  @JsonValue('good')
  good,
  @JsonValue('stable')
  stable,
  @JsonValue('low')
  low,
  @JsonValue('irritable')
  irritable,
  @JsonValue('anxious')
  anxious,
  @JsonValue('depressed')
  depressed,
}

enum Symptom {
  @JsonValue('bloating')
  bloating,
  @JsonValue('cramps')
  cramps,
  @JsonValue('headache')
  headache,
  @JsonValue('migraine')
  migraine,
  @JsonValue('hot_flashes')
  hotFlashes,
  @JsonValue('night_sweats')
  nightSweats,
  @JsonValue('fatigue')
  fatigue,
  @JsonValue('muscle_weakness')
  muscleWeakness,
  @JsonValue('brain_fog')
  brainFog,
  @JsonValue('breast_tenderness')
  breastTenderness,
  @JsonValue('back_pain')
  backPain,
  @JsonValue('joint_pain')
  jointPain,
  @JsonValue('acne')
  acne,
  @JsonValue('insomnia')
  insomnia,
  @JsonValue('anxiety')
  anxiety,
  @JsonValue('irritability')
  irritability,
  @JsonValue('low_libido')
  lowLibido,
}

extension SymptomExtension on Symptom {
  String get displayName {
    switch (this) {
      case Symptom.bloating:
        return 'Bloating';
      case Symptom.cramps:
        return 'Cramps';
      case Symptom.headache:
        return 'Headache';
      case Symptom.migraine:
        return 'Migraine';
      case Symptom.hotFlashes:
        return 'Hot Flashes';
      case Symptom.nightSweats:
        return 'Night Sweats';
      case Symptom.fatigue:
        return 'Fatigue';
      case Symptom.muscleWeakness:
        return 'Muscle Weakness';
      case Symptom.brainFog:
        return 'Brain Fog';
      case Symptom.breastTenderness:
        return 'Breast Tenderness';
      case Symptom.backPain:
        return 'Back Pain';
      case Symptom.jointPain:
        return 'Joint Pain';
      case Symptom.acne:
        return 'Acne';
      case Symptom.insomnia:
        return 'Insomnia';
      case Symptom.anxiety:
        return 'Anxiety';
      case Symptom.irritability:
        return 'Irritability';
      case Symptom.lowLibido:
        return 'Low Libido';
    }
  }
}

// ============================================================================
// HORMONAL PROFILE MODEL
// ============================================================================

@JsonSerializable()
class HormonalProfile {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final Gender? gender;
  @JsonKey(name: 'birth_sex')
  final BirthSex? birthSex;
  @JsonKey(name: 'hormone_goals')
  final List<HormoneGoal> hormoneGoals;
  @JsonKey(name: 'menstrual_tracking_enabled')
  final bool menstrualTrackingEnabled;
  @JsonKey(name: 'cycle_length_days')
  final int? cycleLengthDays;
  @JsonKey(name: 'last_period_start_date')
  final DateTime? lastPeriodStartDate;
  @JsonKey(name: 'typical_period_duration_days')
  final int? typicalPeriodDurationDays;
  @JsonKey(name: 'menopause_status')
  final MenopauseStatus menopauseStatus;
  @JsonKey(name: 'testosterone_optimization_enabled')
  final bool testosteroneOptimizationEnabled;
  @JsonKey(name: 'estrogen_balance_enabled')
  final bool estrogenBalanceEnabled;
  @JsonKey(name: 'include_hormone_supportive_foods')
  final bool includeHormoneSupportiveFoods;
  @JsonKey(name: 'include_hormone_supportive_exercises')
  final bool includeHormoneSupportiveExercises;
  @JsonKey(name: 'cycle_sync_workouts')
  final bool cycleSyncWorkouts;
  @JsonKey(name: 'cycle_sync_nutrition')
  final bool cycleSyncNutrition;
  @JsonKey(name: 'has_pcos')
  final bool hasPcos;
  @JsonKey(name: 'has_endometriosis')
  final bool hasEndometriosis;
  @JsonKey(name: 'has_thyroid_condition')
  final bool hasThyroidCondition;
  @JsonKey(name: 'on_hormone_therapy')
  final bool onHormoneTherapy;
  @JsonKey(name: 'hormone_therapy_type')
  final String? hormoneTherapyType;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  HormonalProfile({
    required this.id,
    required this.userId,
    this.gender,
    this.birthSex,
    this.hormoneGoals = const [],
    this.menstrualTrackingEnabled = false,
    this.cycleLengthDays,
    this.lastPeriodStartDate,
    this.typicalPeriodDurationDays,
    this.menopauseStatus = MenopauseStatus.notApplicable,
    this.testosteroneOptimizationEnabled = false,
    this.estrogenBalanceEnabled = false,
    this.includeHormoneSupportiveFoods = true,
    this.includeHormoneSupportiveExercises = true,
    this.cycleSyncWorkouts = false,
    this.cycleSyncNutrition = false,
    this.hasPcos = false,
    this.hasEndometriosis = false,
    this.hasThyroidCondition = false,
    this.onHormoneTherapy = false,
    this.hormoneTherapyType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HormonalProfile.fromJson(Map<String, dynamic> json) =>
      _$HormonalProfileFromJson(json);

  Map<String, dynamic> toJson() => _$HormonalProfileToJson(this);

  HormonalProfile copyWith({
    String? id,
    String? userId,
    Gender? gender,
    BirthSex? birthSex,
    List<HormoneGoal>? hormoneGoals,
    bool? menstrualTrackingEnabled,
    int? cycleLengthDays,
    DateTime? lastPeriodStartDate,
    int? typicalPeriodDurationDays,
    MenopauseStatus? menopauseStatus,
    bool? testosteroneOptimizationEnabled,
    bool? estrogenBalanceEnabled,
    bool? includeHormoneSupportiveFoods,
    bool? includeHormoneSupportiveExercises,
    bool? cycleSyncWorkouts,
    bool? cycleSyncNutrition,
    bool? hasPcos,
    bool? hasEndometriosis,
    bool? hasThyroidCondition,
    bool? onHormoneTherapy,
    String? hormoneTherapyType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HormonalProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      gender: gender ?? this.gender,
      birthSex: birthSex ?? this.birthSex,
      hormoneGoals: hormoneGoals ?? this.hormoneGoals,
      menstrualTrackingEnabled:
          menstrualTrackingEnabled ?? this.menstrualTrackingEnabled,
      cycleLengthDays: cycleLengthDays ?? this.cycleLengthDays,
      lastPeriodStartDate: lastPeriodStartDate ?? this.lastPeriodStartDate,
      typicalPeriodDurationDays:
          typicalPeriodDurationDays ?? this.typicalPeriodDurationDays,
      menopauseStatus: menopauseStatus ?? this.menopauseStatus,
      testosteroneOptimizationEnabled:
          testosteroneOptimizationEnabled ?? this.testosteroneOptimizationEnabled,
      estrogenBalanceEnabled:
          estrogenBalanceEnabled ?? this.estrogenBalanceEnabled,
      includeHormoneSupportiveFoods:
          includeHormoneSupportiveFoods ?? this.includeHormoneSupportiveFoods,
      includeHormoneSupportiveExercises: includeHormoneSupportiveExercises ??
          this.includeHormoneSupportiveExercises,
      cycleSyncWorkouts: cycleSyncWorkouts ?? this.cycleSyncWorkouts,
      cycleSyncNutrition: cycleSyncNutrition ?? this.cycleSyncNutrition,
      hasPcos: hasPcos ?? this.hasPcos,
      hasEndometriosis: hasEndometriosis ?? this.hasEndometriosis,
      hasThyroidCondition: hasThyroidCondition ?? this.hasThyroidCondition,
      onHormoneTherapy: onHormoneTherapy ?? this.onHormoneTherapy,
      hormoneTherapyType: hormoneTherapyType ?? this.hormoneTherapyType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ============================================================================
// HORMONE LOG MODEL
// ============================================================================

@JsonSerializable()
class HormoneLog {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'log_date')
  final DateTime logDate;
  @JsonKey(name: 'cycle_day')
  final int? cycleDay;
  @JsonKey(name: 'cycle_phase')
  final CyclePhase? cyclePhase;
  @JsonKey(name: 'energy_level')
  final int? energyLevel;
  @JsonKey(name: 'sleep_quality')
  final int? sleepQuality;
  @JsonKey(name: 'libido_level')
  final int? libidoLevel;
  @JsonKey(name: 'stress_level')
  final int? stressLevel;
  @JsonKey(name: 'motivation_level')
  final int? motivationLevel;
  final Mood? mood;
  final List<Symptom> symptoms;
  final String? notes;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  HormoneLog({
    required this.id,
    required this.userId,
    required this.logDate,
    this.cycleDay,
    this.cyclePhase,
    this.energyLevel,
    this.sleepQuality,
    this.libidoLevel,
    this.stressLevel,
    this.motivationLevel,
    this.mood,
    this.symptoms = const [],
    this.notes,
    required this.createdAt,
  });

  factory HormoneLog.fromJson(Map<String, dynamic> json) =>
      _$HormoneLogFromJson(json);

  Map<String, dynamic> toJson() => _$HormoneLogToJson(this);
}

// ============================================================================
// CYCLE PHASE INFO MODEL
// ============================================================================

@JsonSerializable()
class CyclePhaseInfo {
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'menstrual_tracking_enabled')
  final bool menstrualTrackingEnabled;
  @JsonKey(name: 'current_cycle_day')
  final int? currentCycleDay;
  @JsonKey(name: 'current_phase')
  final CyclePhase? currentPhase;
  @JsonKey(name: 'days_until_next_phase')
  final int? daysUntilNextPhase;
  @JsonKey(name: 'next_phase')
  final CyclePhase? nextPhase;
  @JsonKey(name: 'cycle_length_days')
  final int? cycleLengthDays;
  @JsonKey(name: 'recommended_intensity')
  final String? recommendedIntensity;
  @JsonKey(name: 'avoid_exercises')
  final List<String> avoidExercises;
  @JsonKey(name: 'recommended_exercises')
  final List<String> recommendedExercises;
  @JsonKey(name: 'nutrition_focus')
  final List<String> nutritionFocus;

  CyclePhaseInfo({
    required this.userId,
    required this.menstrualTrackingEnabled,
    this.currentCycleDay,
    this.currentPhase,
    this.daysUntilNextPhase,
    this.nextPhase,
    this.cycleLengthDays,
    this.recommendedIntensity,
    this.avoidExercises = const [],
    this.recommendedExercises = const [],
    this.nutritionFocus = const [],
  });

  factory CyclePhaseInfo.fromJson(Map<String, dynamic> json) =>
      _$CyclePhaseInfoFromJson(json);

  Map<String, dynamic> toJson() => _$CyclePhaseInfoToJson(this);
}

// ============================================================================
// HORMONE SUPPORTIVE FOOD MODEL
// ============================================================================

@JsonSerializable()
class HormoneSupportiveFood {
  final String id;
  final String name;
  final String category;
  @JsonKey(name: 'supports_testosterone')
  final bool supportsTestosterone;
  @JsonKey(name: 'supports_estrogen_balance')
  final bool supportsEstrogenBalance;
  @JsonKey(name: 'supports_pcos')
  final bool supportsPcos;
  @JsonKey(name: 'supports_menopause')
  final bool supportsMenopause;
  @JsonKey(name: 'supports_fertility')
  final bool supportsFertility;
  @JsonKey(name: 'key_nutrients')
  final List<String> keyNutrients;
  final String? description;
  @JsonKey(name: 'serving_suggestion')
  final String? servingSuggestion;

  HormoneSupportiveFood({
    required this.id,
    required this.name,
    required this.category,
    this.supportsTestosterone = false,
    this.supportsEstrogenBalance = false,
    this.supportsPcos = false,
    this.supportsMenopause = false,
    this.supportsFertility = false,
    this.keyNutrients = const [],
    this.description,
    this.servingSuggestion,
  });

  factory HormoneSupportiveFood.fromJson(Map<String, dynamic> json) =>
      _$HormoneSupportiveFoodFromJson(json);

  Map<String, dynamic> toJson() => _$HormoneSupportiveFoodToJson(this);
}

// ============================================================================
// HORMONAL RECOMMENDATION MODEL
// ============================================================================

@JsonSerializable()
class HormonalRecommendation {
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'recommendation_type')
  final String recommendationType;
  final String title;
  final String description;
  @JsonKey(name: 'action_items')
  final List<String> actionItems;
  @JsonKey(name: 'based_on')
  final List<String> basedOn;
  final String priority;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  HormonalRecommendation({
    required this.userId,
    required this.recommendationType,
    required this.title,
    required this.description,
    this.actionItems = const [],
    this.basedOn = const [],
    required this.priority,
    required this.createdAt,
  });

  factory HormonalRecommendation.fromJson(Map<String, dynamic> json) =>
      _$HormonalRecommendationFromJson(json);

  Map<String, dynamic> toJson() => _$HormonalRecommendationToJson(this);
}

// ============================================================================
// CYCLE TRACKING — Phase B
// ----------------------------------------------------------------------------
// The classes below are HAND-WRITTEN (no @JsonSerializable / no generated
// `.g.dart` part) on purpose: this repo pins Flutter 3.44.6 and commits its
// `.g.dart` files, and `build_runner` is intentionally not runnable here.
// Field names mirror the backend Pydantic models in
// `backend/models/hormonal_health.py` (snake_case JSON keys) exactly.
// ============================================================================

// --- Date helpers (ISO yyyy-MM-dd, null-safe) -------------------------------

/// Parse a backend ISO date string (`yyyy-MM-dd`) or full datetime into a
/// local-midnight [DateTime]. Returns null on null/empty/unparseable input so
/// missing data never crashes the cycle UI.
DateTime? _cycleParseDate(Object? raw) {
  if (raw == null) return null;
  if (raw is DateTime) return DateTime(raw.year, raw.month, raw.day);
  final s = raw.toString().trim();
  if (s.isEmpty) return null;
  final parsed = DateTime.tryParse(s);
  if (parsed == null) return null;
  // Normalise to local-midnight — cycle math is calendar-date based and must
  // not drift across timezones / DST.
  return DateTime(parsed.year, parsed.month, parsed.day);
}

/// Format a [DateTime] back to the backend's `yyyy-MM-dd` contract.
String? _cycleFormatDate(DateTime? d) {
  if (d == null) return null;
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd';
}

DateTime? _cycleParseDateTime(Object? raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  return DateTime.tryParse(raw.toString());
}

int? _cycleAsInt(Object? raw) {
  if (raw == null) return null;
  if (raw is int) return raw;
  if (raw is double) return raw.round();
  return int.tryParse(raw.toString());
}

double? _cycleAsDouble(Object? raw) {
  if (raw == null) return null;
  if (raw is num) return raw.toDouble();
  return double.tryParse(raw.toString());
}

// --- Tracking-mode / LH / pregnancy enums -----------------------------------
// Backend enums: TrackingMode, LhTestResult, PregnancyTestResult. Parsed
// permissively from the wire string; unknown values fall back to a safe
// default so a backend addition never throws on an old client.

/// Mirrors backend `TrackingMode` (tracking | ttc | pregnancy).
enum CycleTrackingMode {
  tracking,
  ttc,
  pregnancy;

  String get value {
    switch (this) {
      case CycleTrackingMode.tracking:
        return 'tracking';
      case CycleTrackingMode.ttc:
        return 'ttc';
      case CycleTrackingMode.pregnancy:
        return 'pregnancy';
    }
  }

  String get displayName {
    switch (this) {
      case CycleTrackingMode.tracking:
        return 'Cycle Tracking';
      case CycleTrackingMode.ttc:
        return 'Trying to Conceive';
      case CycleTrackingMode.pregnancy:
        return 'Pregnancy';
    }
  }

  /// Permissive parse — unknown / null → [CycleTrackingMode.tracking].
  static CycleTrackingMode fromValue(Object? raw) {
    switch (raw?.toString().trim().toLowerCase()) {
      case 'ttc':
        return CycleTrackingMode.ttc;
      case 'pregnancy':
        return CycleTrackingMode.pregnancy;
      case 'tracking':
      default:
        return CycleTrackingMode.tracking;
    }
  }
}

/// Mirrors backend `LhTestResult` (untested | negative | positive | peak).
enum LhTestResult {
  untested,
  negative,
  positive,
  peak;

  String get value {
    switch (this) {
      case LhTestResult.untested:
        return 'untested';
      case LhTestResult.negative:
        return 'negative';
      case LhTestResult.positive:
        return 'positive';
      case LhTestResult.peak:
        return 'peak';
    }
  }

  String get displayName {
    switch (this) {
      case LhTestResult.untested:
        return 'Not Tested';
      case LhTestResult.negative:
        return 'Negative';
      case LhTestResult.positive:
        return 'Positive';
      case LhTestResult.peak:
        return 'Peak';
    }
  }

  /// True when the result corroborates an imminent ovulation (LH surge).
  bool get isPositiveSurge =>
      this == LhTestResult.positive || this == LhTestResult.peak;

  static LhTestResult fromValue(Object? raw) {
    switch (raw?.toString().trim().toLowerCase()) {
      case 'negative':
        return LhTestResult.negative;
      case 'positive':
        return LhTestResult.positive;
      case 'peak':
        return LhTestResult.peak;
      case 'untested':
      default:
        return LhTestResult.untested;
    }
  }
}

/// Mirrors backend `PregnancyTestResult` (not_taken | negative | positive).
enum PregnancyTestResult {
  notTaken,
  negative,
  positive;

  String get value {
    switch (this) {
      case PregnancyTestResult.notTaken:
        return 'not_taken';
      case PregnancyTestResult.negative:
        return 'negative';
      case PregnancyTestResult.positive:
        return 'positive';
    }
  }

  String get displayName {
    switch (this) {
      case PregnancyTestResult.notTaken:
        return 'Not Taken';
      case PregnancyTestResult.negative:
        return 'Negative';
      case PregnancyTestResult.positive:
        return 'Positive';
    }
  }

  static PregnancyTestResult fromValue(Object? raw) {
    switch (raw?.toString().trim().toLowerCase()) {
      case 'negative':
        return PregnancyTestResult.negative;
      case 'positive':
        return PregnancyTestResult.positive;
      case 'not_taken':
      default:
        return PregnancyTestResult.notTaken;
    }
  }
}

// ============================================================================
// CYCLE PERIOD — one observed menstrual period
// Mirrors backend `CyclePeriod` (`backend/models/hormonal_health.py`).
// ============================================================================

class CyclePeriod {
  final String id;
  final String userId;

  /// Day 1 of bleeding. Always present.
  final DateTime startDate;

  /// Last day of bleeding. Null while a period is still in progress (logged
  /// start but not yet ended).
  final DateTime? endDate;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CyclePeriod({
    required this.id,
    required this.userId,
    required this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
  });

  /// Inclusive period length in days, or null when the period has no end yet.
  int? get lengthDays {
    final end = endDate;
    if (end == null) return null;
    final n = end.difference(startDate).inDays + 1;
    return n >= 1 ? n : null;
  }

  factory CyclePeriod.fromJson(Map<String, dynamic> json) {
    final start = _cycleParseDate(json['start_date']);
    if (start == null) {
      // start_date is non-nullable in the backend contract; a missing one is
      // a hard data error, not something to silently paper over.
      throw const FormatException('CyclePeriod.fromJson: missing start_date');
    }
    return CyclePeriod(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      startDate: start,
      endDate: _cycleParseDate(json['end_date']),
      createdAt: _cycleParseDateTime(json['created_at']),
      updatedAt: _cycleParseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'start_date': _cycleFormatDate(startDate),
        'end_date': _cycleFormatDate(endDate),
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  CyclePeriod copyWith({
    String? id,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CyclePeriod(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ============================================================================
// CYCLE STATS — aggregate statistics over a user's period history
// Mirrors backend `CycleStats`.
// ============================================================================

class CycleStats {
  final int periodsLogged;
  final int cyclesTracked;
  final double? avgCycleLength;
  final int? minCycleLength;
  final int? maxCycleLength;
  final double? cycleLengthStddev;
  final double? avgPeriodLength;

  /// `regular` | `irregular` | `unknown`.
  final String regularity;

  const CycleStats({
    this.periodsLogged = 0,
    this.cyclesTracked = 0,
    this.avgCycleLength,
    this.minCycleLength,
    this.maxCycleLength,
    this.cycleLengthStddev,
    this.avgPeriodLength,
    this.regularity = 'unknown',
  });

  bool get isRegular => regularity == 'regular';
  bool get isIrregular => regularity == 'irregular';

  factory CycleStats.fromJson(Map<String, dynamic> json) {
    return CycleStats(
      periodsLogged: _cycleAsInt(json['periods_logged']) ?? 0,
      cyclesTracked: _cycleAsInt(json['cycles_tracked']) ?? 0,
      avgCycleLength: _cycleAsDouble(json['avg_cycle_length']),
      minCycleLength: _cycleAsInt(json['min_cycle_length']),
      maxCycleLength: _cycleAsInt(json['max_cycle_length']),
      cycleLengthStddev: _cycleAsDouble(json['cycle_length_stddev']),
      avgPeriodLength: _cycleAsDouble(json['avg_period_length']),
      regularity: (json['regularity'] ?? 'unknown').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'periods_logged': periodsLogged,
        'cycles_tracked': cyclesTracked,
        'avg_cycle_length': avgCycleLength,
        'min_cycle_length': minCycleLength,
        'max_cycle_length': maxCycleLength,
        'cycle_length_stddev': cycleLengthStddev,
        'avg_period_length': avgPeriodLength,
        'regularity': regularity,
      };
}

// ============================================================================
// CYCLE PREDICTION — full output of the deterministic prediction engine
// Mirrors backend `CyclePrediction`. Every date is an ESTIMATE — never a
// contraceptive method. `confidence` + the next-period window communicate
// uncertainty.
// ============================================================================

class CyclePrediction {
  final String? userId;
  final bool predictionsAvailable;

  /// `tracking` | `ttc` | `pregnancy`.
  final CycleTrackingMode trackingMode;

  /// The date the prediction was computed for (user-local "today").
  final DateTime today;

  // --- Current position in the cycle ---
  final int? currentCycleDay;
  final CyclePhase? currentPhase;
  final int? daysUntilNextPhase;
  final CyclePhase? nextPhase;
  final DateTime? lastPeriodStart;
  final bool inPeriod;

  // --- Next-period forecast ---
  final DateTime? nextPeriodDate;
  final DateTime? nextPeriodWindowStart;
  final DateTime? nextPeriodWindowEnd;
  final int? daysUntilNextPeriod;

  /// Set instead of [daysUntilNextPeriod] when today is past the prediction
  /// window with no new period logged.
  final int? periodLateBy;

  /// `low` | `medium` | `high`.
  final String confidence;

  // --- Ovulation + fertile window ---
  final DateTime? ovulationDate;

  /// `estimated` | `confirmed` (confirmed = BBT/sympto-thermal verified).
  final String ovulationStatus;
  final DateTime? fertileWindowStart;
  final DateTime? fertileWindowEnd;
  final DateTime? peakFertilityStart;
  final DateTime? peakFertilityEnd;

  /// `high` | `low` | null.
  final String? conceptionChance;

  /// Marshall cover-line temperature in Celsius (post-ovulation threshold).
  final double? coverLineCelsius;

  final CycleStats stats;

  /// Human-readable estimate/limitation notes from the engine.
  final List<String> notes;

  const CyclePrediction({
    this.userId,
    required this.predictionsAvailable,
    this.trackingMode = CycleTrackingMode.tracking,
    required this.today,
    this.currentCycleDay,
    this.currentPhase,
    this.daysUntilNextPhase,
    this.nextPhase,
    this.lastPeriodStart,
    this.inPeriod = false,
    this.nextPeriodDate,
    this.nextPeriodWindowStart,
    this.nextPeriodWindowEnd,
    this.daysUntilNextPeriod,
    this.periodLateBy,
    this.confidence = 'low',
    this.ovulationDate,
    this.ovulationStatus = 'estimated',
    this.fertileWindowStart,
    this.fertileWindowEnd,
    this.peakFertilityStart,
    this.peakFertilityEnd,
    this.conceptionChance,
    this.coverLineCelsius,
    this.stats = const CycleStats(),
    this.notes = const [],
  });

  bool get isOvulationConfirmed => ovulationStatus == 'confirmed';
  bool get isLate => periodLateBy != null && periodLateBy! > 0;
  bool get isHighConfidence => confidence == 'high';

  /// True when today falls inside the fertile window estimate.
  bool get inFertileWindow {
    final start = fertileWindowStart;
    final end = fertileWindowEnd;
    if (start == null || end == null) return false;
    final t = DateTime(today.year, today.month, today.day);
    return !t.isBefore(start) && !t.isAfter(end);
  }

  static CyclePhase? _parsePhase(Object? raw) {
    switch (raw?.toString().trim().toLowerCase()) {
      case 'menstrual':
        return CyclePhase.menstrual;
      case 'follicular':
        return CyclePhase.follicular;
      case 'ovulation':
        return CyclePhase.ovulation;
      case 'luteal':
        return CyclePhase.luteal;
      default:
        return null;
    }
  }

  factory CyclePrediction.fromJson(Map<String, dynamic> json) {
    final rawStats = json['stats'];
    return CyclePrediction(
      userId: json['user_id']?.toString(),
      predictionsAvailable: json['predictions_available'] == true,
      trackingMode: CycleTrackingMode.fromValue(json['tracking_mode']),
      today: _cycleParseDate(json['today']) ??
          DateTime.now().let((n) => DateTime(n.year, n.month, n.day)),
      currentCycleDay: _cycleAsInt(json['current_cycle_day']),
      currentPhase: _parsePhase(json['current_phase']),
      daysUntilNextPhase: _cycleAsInt(json['days_until_next_phase']),
      nextPhase: _parsePhase(json['next_phase']),
      lastPeriodStart: _cycleParseDate(json['last_period_start']),
      inPeriod: json['in_period'] == true,
      nextPeriodDate: _cycleParseDate(json['next_period_date']),
      nextPeriodWindowStart: _cycleParseDate(json['next_period_window_start']),
      nextPeriodWindowEnd: _cycleParseDate(json['next_period_window_end']),
      daysUntilNextPeriod: _cycleAsInt(json['days_until_next_period']),
      periodLateBy: _cycleAsInt(json['period_late_by']),
      confidence: (json['confidence'] ?? 'low').toString(),
      ovulationDate: _cycleParseDate(json['ovulation_date']),
      ovulationStatus: (json['ovulation_status'] ?? 'estimated').toString(),
      fertileWindowStart: _cycleParseDate(json['fertile_window_start']),
      fertileWindowEnd: _cycleParseDate(json['fertile_window_end']),
      peakFertilityStart: _cycleParseDate(json['peak_fertility_start']),
      peakFertilityEnd: _cycleParseDate(json['peak_fertility_end']),
      conceptionChance: json['conception_chance']?.toString(),
      coverLineCelsius: _cycleAsDouble(json['cover_line_celsius']),
      stats: rawStats is Map
          ? CycleStats.fromJson(Map<String, dynamic>.from(rawStats))
          : const CycleStats(),
      notes: (json['notes'] is List)
          ? (json['notes'] as List).map((e) => e.toString()).toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'predictions_available': predictionsAvailable,
        'tracking_mode': trackingMode.value,
        'today': _cycleFormatDate(today),
        'current_cycle_day': currentCycleDay,
        'current_phase': currentPhase?.name,
        'days_until_next_phase': daysUntilNextPhase,
        'next_phase': nextPhase?.name,
        'last_period_start': _cycleFormatDate(lastPeriodStart),
        'in_period': inPeriod,
        'next_period_date': _cycleFormatDate(nextPeriodDate),
        'next_period_window_start': _cycleFormatDate(nextPeriodWindowStart),
        'next_period_window_end': _cycleFormatDate(nextPeriodWindowEnd),
        'days_until_next_period': daysUntilNextPeriod,
        'period_late_by': periodLateBy,
        'confidence': confidence,
        'ovulation_date': _cycleFormatDate(ovulationDate),
        'ovulation_status': ovulationStatus,
        'fertile_window_start': _cycleFormatDate(fertileWindowStart),
        'fertile_window_end': _cycleFormatDate(fertileWindowEnd),
        'peak_fertility_start': _cycleFormatDate(peakFertilityStart),
        'peak_fertility_end': _cycleFormatDate(peakFertilityEnd),
        'conception_chance': conceptionChance,
        'cover_line_celsius': coverLineCelsius,
        'stats': stats.toJson(),
        'notes': notes,
      };
}

/// Tiny scope helper so `fromJson` can compute a fallback `today` inline
/// without a separate statement.
extension _CycleLet<T> on T {
  R let<R>(R Function(T) op) => op(this);
}
