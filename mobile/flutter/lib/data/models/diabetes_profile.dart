import 'package:json_annotation/json_annotation.dart';

part 'diabetes_profile.g.dart';

enum DiabetesType {
  @JsonValue('type1')
  type1('type1', 'Type 1 Diabetes', 'Insulin-dependent diabetes'),
  @JsonValue('type2')
  type2('type2', 'Type 2 Diabetes', 'Insulin-resistant diabetes'),
  @JsonValue('gestational')
  gestational('gestational', 'Gestational Diabetes', 'Pregnancy-related diabetes'),
  @JsonValue('prediabetes')
  prediabetes('prediabetes', 'Prediabetes', 'Elevated blood sugar levels');

  final String value;
  final String displayName;
  final String description;

  const DiabetesType(this.value, this.displayName, this.description);

  static DiabetesType fromValue(String? value) {
    if (value == null) return DiabetesType.type2;
    return DiabetesType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DiabetesType.type2,
    );
  }
}

enum TreatmentApproach {
  @JsonValue('diet_exercise')
  dietExercise('diet_exercise', 'Diet & Exercise', 'Lifestyle management only'),
  @JsonValue('oral_medication')
  oralMedication('oral_medication', 'Oral Medication', 'Pills and tablets'),
  @JsonValue('insulin_therapy')
  insulinTherapy('insulin_therapy', 'Insulin Therapy', 'Insulin injections'),
  @JsonValue('insulin_pump')
  insulinPump('insulin_pump', 'Insulin Pump', 'Continuous insulin delivery'),
  @JsonValue('combination')
  combination('combination', 'Combination', 'Multiple treatment methods');

  final String value;
  final String displayName;
  final String description;

  const TreatmentApproach(this.value, this.displayName, this.description);

  static TreatmentApproach fromValue(String? value) {
    if (value == null) return TreatmentApproach.dietExercise;
    return TreatmentApproach.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TreatmentApproach.dietExercise,
    );
  }
}

enum MonitoringMethod {
  @JsonValue('finger_prick')
  fingerPrick('finger_prick', 'Finger Prick', 'Traditional blood glucose meter'),
  @JsonValue('cgm')
  cgm('cgm', 'CGM', 'Continuous Glucose Monitor'),
  @JsonValue('flash_glucose')
  flashGlucose('flash_glucose', 'Flash Glucose', 'Flash glucose monitoring'),
  @JsonValue('health_connect')
  healthConnect('health_connect', 'Health Connect', 'Synced from Health Connect');

  final String value;
  final String displayName;
  final String description;

  const MonitoringMethod(this.value, this.displayName, this.description);

  static MonitoringMethod fromValue(String? value) {
    if (value == null) return MonitoringMethod.fingerPrick;
    return MonitoringMethod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MonitoringMethod.fingerPrick,
    );
  }
}

@JsonSerializable()
class DiabetesProfile {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'diabetes_type')
  final String diabetesType;
  @JsonKey(name: 'diagnosis_date')
  final DateTime? diagnosisDate;
  @JsonKey(name: 'treatment_approach')
  final String treatmentApproach;
  @JsonKey(name: 'monitoring_method')
  final String monitoringMethod;
  @JsonKey(name: 'target_fasting_min')
  final int targetFastingMin;
  @JsonKey(name: 'target_fasting_max')
  final int targetFastingMax;
  @JsonKey(name: 'target_a1c')
  final double? targetA1c;
  @JsonKey(name: 'hypo_threshold')
  final int hypoThreshold;
  @JsonKey(name: 'hyper_threshold')
  final int hyperThreshold;
  @JsonKey(name: 'glucose_unit')
  final String glucoseUnit;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const DiabetesProfile({
    required this.id,
    required this.userId,
    required this.diabetesType,
    this.diagnosisDate,
    this.treatmentApproach = 'diet_exercise',
    this.monitoringMethod = 'finger_prick',
    this.targetFastingMin = 70,
    this.targetFastingMax = 100,
    this.targetA1c,
    this.hypoThreshold = 70,
    this.hyperThreshold = 180,
    this.glucoseUnit = 'mg/dL',
    required this.createdAt,
    required this.updatedAt,
  });

  factory DiabetesProfile.fromJson(Map<String, dynamic> json) =>
      _$DiabetesProfileFromJson(json);
  Map<String, dynamic> toJson() => _$DiabetesProfileToJson(this);

  DiabetesType get diabetesTypeEnum => DiabetesType.fromValue(diabetesType);
  TreatmentApproach get treatmentApproachEnum => TreatmentApproach.fromValue(treatmentApproach);
  MonitoringMethod get monitoringMethodEnum => MonitoringMethod.fromValue(monitoringMethod);

  bool get usesInsulin =>
      treatmentApproachEnum == TreatmentApproach.insulinTherapy ||
      treatmentApproachEnum == TreatmentApproach.insulinPump ||
      treatmentApproachEnum == TreatmentApproach.combination;

  double mgDlToMmol(int mgDl) => mgDl / 18.0;
  int mmolToMgDl(double mmol) => (mmol * 18.0).round();
}
