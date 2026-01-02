import 'package:json_annotation/json_annotation.dart';

part 'diabetes_medication.g.dart';

/// Type of diabetes medication
enum MedicationType {
  @JsonValue('metformin')
  metformin('metformin', 'Metformin', 'Biguanide - reduces glucose production'),
  @JsonValue('sulfonylurea')
  sulfonylurea('sulfonylurea', 'Sulfonylurea', 'Stimulates insulin release'),
  @JsonValue('sglt2_inhibitor')
  sglt2Inhibitor('sglt2_inhibitor', 'SGLT2 Inhibitor', 'Blocks glucose reabsorption'),
  @JsonValue('dpp4_inhibitor')
  dpp4Inhibitor('dpp4_inhibitor', 'DPP-4 Inhibitor', 'Enhances incretin hormones'),
  @JsonValue('glp1_agonist')
  glp1Agonist('glp1_agonist', 'GLP-1 Agonist', 'Mimics incretin hormones'),
  @JsonValue('thiazolidinedione')
  thiazolidinedione('thiazolidinedione', 'Thiazolidinedione', 'Improves insulin sensitivity'),
  @JsonValue('alpha_glucosidase')
  alphaGlucosidase('alpha_glucosidase', 'Alpha-Glucosidase Inhibitor', 'Slows carb digestion'),
  @JsonValue('meglitinide')
  meglitinide('meglitinide', 'Meglitinide', 'Short-acting insulin stimulator'),
  @JsonValue('combination')
  combination('combination', 'Combination', 'Multiple drug classes combined'),
  @JsonValue('other')
  other('other', 'Other', 'Other diabetes medication');

  final String value;
  final String displayName;
  final String description;

  const MedicationType(this.value, this.displayName, this.description);

  static MedicationType fromValue(String? value) {
    if (value == null) return MedicationType.other;
    return MedicationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MedicationType.other,
    );
  }
}

/// How often medication is taken
enum DosageFrequency {
  @JsonValue('once_daily')
  onceDaily('once_daily', 'Once Daily', 'One time per day'),
  @JsonValue('twice_daily')
  twiceDaily('twice_daily', 'Twice Daily', 'Two times per day'),
  @JsonValue('three_daily')
  threeDaily('three_daily', 'Three Times Daily', 'Three times per day'),
  @JsonValue('with_meals')
  withMeals('with_meals', 'With Meals', 'With each meal'),
  @JsonValue('weekly')
  weekly('weekly', 'Weekly', 'Once per week'),
  @JsonValue('as_needed')
  asNeeded('as_needed', 'As Needed', 'When required');

  final String value;
  final String displayName;
  final String description;

  const DosageFrequency(this.value, this.displayName, this.description);

  static DosageFrequency fromValue(String? value) {
    if (value == null) return DosageFrequency.onceDaily;
    return DosageFrequency.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DosageFrequency.onceDaily,
    );
  }
}

/// Common diabetes medication brands
class MedicationBrand {
  final String genericName;
  final String brandName;
  final MedicationType type;
  final String typicalDose;

  const MedicationBrand(this.genericName, this.brandName, this.type, this.typicalDose);

  static const List<MedicationBrand> commonBrands = [
    // Metformin
    MedicationBrand('Metformin', 'Glucophage', MedicationType.metformin, '500-2000mg'),
    MedicationBrand('Metformin XR', 'Glucophage XR', MedicationType.metformin, '500-2000mg'),
    // SGLT2 Inhibitors
    MedicationBrand('Empagliflozin', 'Jardiance', MedicationType.sglt2Inhibitor, '10-25mg'),
    MedicationBrand('Dapagliflozin', 'Farxiga', MedicationType.sglt2Inhibitor, '5-10mg'),
    MedicationBrand('Canagliflozin', 'Invokana', MedicationType.sglt2Inhibitor, '100-300mg'),
    // DPP-4 Inhibitors
    MedicationBrand('Sitagliptin', 'Januvia', MedicationType.dpp4Inhibitor, '100mg'),
    MedicationBrand('Linagliptin', 'Tradjenta', MedicationType.dpp4Inhibitor, '5mg'),
    MedicationBrand('Saxagliptin', 'Onglyza', MedicationType.dpp4Inhibitor, '2.5-5mg'),
    // GLP-1 Agonists
    MedicationBrand('Semaglutide', 'Ozempic', MedicationType.glp1Agonist, '0.25-1mg weekly'),
    MedicationBrand('Semaglutide', 'Rybelsus', MedicationType.glp1Agonist, '3-14mg daily'),
    MedicationBrand('Liraglutide', 'Victoza', MedicationType.glp1Agonist, '0.6-1.8mg'),
    MedicationBrand('Dulaglutide', 'Trulicity', MedicationType.glp1Agonist, '0.75-4.5mg weekly'),
    MedicationBrand('Tirzepatide', 'Mounjaro', MedicationType.glp1Agonist, '2.5-15mg weekly'),
    // Sulfonylureas
    MedicationBrand('Glimepiride', 'Amaryl', MedicationType.sulfonylurea, '1-8mg'),
    MedicationBrand('Glipizide', 'Glucotrol', MedicationType.sulfonylurea, '5-40mg'),
    MedicationBrand('Glyburide', 'Diabeta', MedicationType.sulfonylurea, '1.25-20mg'),
    // Thiazolidinediones
    MedicationBrand('Pioglitazone', 'Actos', MedicationType.thiazolidinedione, '15-45mg'),
    // Combinations
    MedicationBrand('Metformin/Sitagliptin', 'Janumet', MedicationType.combination, 'Varies'),
    MedicationBrand('Metformin/Empagliflozin', 'Synjardy', MedicationType.combination, 'Varies'),
  ];
}

/// Diabetes medication record
@JsonSerializable()
class DiabetesMedication {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'medication_name')
  final String medicationName;
  @JsonKey(name: 'generic_name')
  final String? genericName;
  @JsonKey(name: 'medication_type')
  final String medicationType;
  @JsonKey(name: 'dosage_mg')
  final double dosageMg;
  @JsonKey(name: 'dosage_unit')
  final String dosageUnit;
  final String frequency;
  @JsonKey(name: 'time_of_day')
  final List<String> timeOfDay;
  @JsonKey(name: 'with_food')
  final bool withFood;
  @JsonKey(name: 'start_date')
  final DateTime startDate;
  @JsonKey(name: 'end_date')
  final DateTime? endDate;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'prescribing_doctor')
  final String? prescribingDoctor;
  final String? notes;
  @JsonKey(name: 'refill_date')
  final DateTime? refillDate;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const DiabetesMedication({
    required this.id,
    required this.userId,
    required this.medicationName,
    this.genericName,
    required this.medicationType,
    required this.dosageMg,
    this.dosageUnit = 'mg',
    required this.frequency,
    this.timeOfDay = const [],
    this.withFood = false,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.prescribingDoctor,
    this.notes,
    this.refillDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DiabetesMedication.fromJson(Map<String, dynamic> json) =>
      _$DiabetesMedicationFromJson(json);
  Map<String, dynamic> toJson() => _$DiabetesMedicationToJson(this);

  MedicationType get medicationTypeEnum => MedicationType.fromValue(medicationType);
  DosageFrequency get frequencyEnum => DosageFrequency.fromValue(frequency);

  /// Get formatted dosage display
  String get dosageDisplay => '${dosageMg.toStringAsFixed(dosageMg.truncateToDouble() == dosageMg ? 0 : 1)} $dosageUnit';

  /// Check if refill is needed soon (within 7 days)
  bool get needsRefillSoon {
    if (refillDate == null) return false;
    final daysUntilRefill = refillDate!.difference(DateTime.now()).inDays;
    return daysUntilRefill <= 7 && daysUntilRefill >= 0;
  }

  /// Check if refill is overdue
  bool get refillOverdue {
    if (refillDate == null) return false;
    return DateTime.now().isAfter(refillDate!);
  }

  /// Get days on this medication
  int get daysTaking => DateTime.now().difference(startDate).inDays;
}

/// Request to add a medication
@JsonSerializable()
class DiabetesMedicationRequest {
  @JsonKey(name: 'medication_name')
  final String medicationName;
  @JsonKey(name: 'generic_name')
  final String? genericName;
  @JsonKey(name: 'medication_type')
  final String medicationType;
  @JsonKey(name: 'dosage_mg')
  final double dosageMg;
  @JsonKey(name: 'dosage_unit')
  final String? dosageUnit;
  final String frequency;
  @JsonKey(name: 'time_of_day')
  final List<String>? timeOfDay;
  @JsonKey(name: 'with_food')
  final bool? withFood;
  @JsonKey(name: 'start_date')
  final DateTime? startDate;
  @JsonKey(name: 'prescribing_doctor')
  final String? prescribingDoctor;
  final String? notes;

  const DiabetesMedicationRequest({
    required this.medicationName,
    this.genericName,
    required this.medicationType,
    required this.dosageMg,
    this.dosageUnit,
    required this.frequency,
    this.timeOfDay,
    this.withFood,
    this.startDate,
    this.prescribingDoctor,
    this.notes,
  });

  factory DiabetesMedicationRequest.fromJson(Map<String, dynamic> json) =>
      _$DiabetesMedicationRequestFromJson(json);
  Map<String, dynamic> toJson() => _$DiabetesMedicationRequestToJson(this);
}

/// Medication dose log (when taken)
@JsonSerializable()
class MedicationDoseLog {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'medication_id')
  final String medicationId;
  @JsonKey(name: 'taken_at')
  final DateTime takenAt;
  @JsonKey(name: 'was_taken')
  final bool wasTaken;
  @JsonKey(name: 'skip_reason')
  final String? skipReason;
  final String? notes;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const MedicationDoseLog({
    required this.id,
    required this.userId,
    required this.medicationId,
    required this.takenAt,
    this.wasTaken = true,
    this.skipReason,
    this.notes,
    required this.createdAt,
  });

  factory MedicationDoseLog.fromJson(Map<String, dynamic> json) =>
      _$MedicationDoseLogFromJson(json);
  Map<String, dynamic> toJson() => _$MedicationDoseLogToJson(this);
}
