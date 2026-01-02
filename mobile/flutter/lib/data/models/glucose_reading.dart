import 'package:json_annotation/json_annotation.dart';

part 'glucose_reading.g.dart';

/// Glucose reading status based on value
enum GlucoseStatus {
  @JsonValue('low')
  low('low', 'Low', 0xFFF44336),
  @JsonValue('normal')
  normal('normal', 'Normal', 0xFF4CAF50),
  @JsonValue('elevated')
  elevated('elevated', 'Elevated', 0xFFFF9800),
  @JsonValue('high')
  high('high', 'High', 0xFFE65100),
  @JsonValue('very_high')
  veryHigh('very_high', 'Very High', 0xFFD32F2F);

  final String value;
  final String displayName;
  final int colorValue;

  const GlucoseStatus(this.value, this.displayName, this.colorValue);

  static GlucoseStatus fromValue(String? value) {
    if (value == null) return GlucoseStatus.normal;
    return GlucoseStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => GlucoseStatus.normal,
    );
  }
}

/// Context when the reading was taken
enum MealContext {
  @JsonValue('fasting')
  fasting('fasting', 'Fasting', 'Before eating in the morning'),
  @JsonValue('before_breakfast')
  beforeBreakfast('before_breakfast', 'Before Breakfast', 'Before breakfast'),
  @JsonValue('after_breakfast')
  afterBreakfast('after_breakfast', 'After Breakfast', '1-2 hours after breakfast'),
  @JsonValue('before_lunch')
  beforeLunch('before_lunch', 'Before Lunch', 'Before lunch'),
  @JsonValue('after_lunch')
  afterLunch('after_lunch', 'After Lunch', '1-2 hours after lunch'),
  @JsonValue('before_dinner')
  beforeDinner('before_dinner', 'Before Dinner', 'Before dinner'),
  @JsonValue('after_dinner')
  afterDinner('after_dinner', 'After Dinner', '1-2 hours after dinner'),
  @JsonValue('bedtime')
  bedtime('bedtime', 'Bedtime', 'Before going to sleep'),
  @JsonValue('night')
  night('night', 'Night', 'During the night (2-3 AM)'),
  @JsonValue('before_exercise')
  beforeExercise('before_exercise', 'Before Exercise', 'Before workout'),
  @JsonValue('after_exercise')
  afterExercise('after_exercise', 'After Exercise', 'After workout'),
  @JsonValue('other')
  other('other', 'Other', 'Other time');

  final String value;
  final String displayName;
  final String description;

  const MealContext(this.value, this.displayName, this.description);

  static MealContext fromValue(String? value) {
    if (value == null) return MealContext.other;
    return MealContext.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MealContext.other,
    );
  }
}

/// How the reading was obtained
enum ReadingType {
  @JsonValue('manual')
  manual('manual', 'Manual', 'Finger prick or manual entry'),
  @JsonValue('cgm')
  cgm('cgm', 'CGM', 'Continuous Glucose Monitor'),
  @JsonValue('flash')
  flash('flash', 'Flash', 'Flash glucose monitor scan'),
  @JsonValue('health_connect')
  healthConnect('health_connect', 'Health Connect', 'Synced from Health Connect');

  final String value;
  final String displayName;
  final String description;

  const ReadingType(this.value, this.displayName, this.description);

  static ReadingType fromValue(String? value) {
    if (value == null) return ReadingType.manual;
    return ReadingType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReadingType.manual,
    );
  }
}

/// Individual glucose reading
@JsonSerializable()
class GlucoseReading {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'glucose_value')
  final int glucoseValue; // mg/dL
  @JsonKey(name: 'meal_context')
  final String mealContext;
  @JsonKey(name: 'reading_type')
  final String readingType;
  @JsonKey(name: 'recorded_at')
  final DateTime recordedAt;
  final String? notes;
  @JsonKey(name: 'food_log_id')
  final String? foodLogId;
  @JsonKey(name: 'workout_id')
  final String? workoutId;
  @JsonKey(name: 'insulin_dose_id')
  final String? insulinDoseId;
  @JsonKey(name: 'carbs_consumed')
  final int? carbsConsumed;
  @JsonKey(name: 'is_flagged')
  final bool isFlagged;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const GlucoseReading({
    required this.id,
    required this.userId,
    required this.glucoseValue,
    required this.mealContext,
    this.readingType = 'manual',
    required this.recordedAt,
    this.notes,
    this.foodLogId,
    this.workoutId,
    this.insulinDoseId,
    this.carbsConsumed,
    this.isFlagged = false,
    required this.createdAt,
  });

  factory GlucoseReading.fromJson(Map<String, dynamic> json) =>
      _$GlucoseReadingFromJson(json);
  Map<String, dynamic> toJson() => _$GlucoseReadingToJson(this);

  MealContext get mealContextEnum => MealContext.fromValue(mealContext);
  ReadingType get readingTypeEnum => ReadingType.fromValue(readingType);

  /// Get glucose status based on value and context
  GlucoseStatus getStatus({int hypoThreshold = 70, int hyperThreshold = 180}) {
    if (glucoseValue < hypoThreshold) {
      return GlucoseStatus.low;
    } else if (glucoseValue < 100) {
      return GlucoseStatus.normal;
    } else if (glucoseValue < hyperThreshold) {
      return GlucoseStatus.elevated;
    } else if (glucoseValue < 250) {
      return GlucoseStatus.high;
    } else {
      return GlucoseStatus.veryHigh;
    }
  }

  /// Get status color as int (0xAARRGGBB)
  int getStatusColor({int hypoThreshold = 70, int hyperThreshold = 180}) {
    return getStatus(
      hypoThreshold: hypoThreshold,
      hyperThreshold: hyperThreshold,
    ).colorValue;
  }

  /// Check if this is a fasting reading
  bool get isFasting =>
      mealContextEnum == MealContext.fasting ||
      mealContextEnum == MealContext.beforeBreakfast;

  /// Check if this is a post-meal reading
  bool get isPostMeal =>
      mealContextEnum == MealContext.afterBreakfast ||
      mealContextEnum == MealContext.afterLunch ||
      mealContextEnum == MealContext.afterDinner;

  /// Convert to mmol/L
  double get glucoseValueMmol => glucoseValue / 18.0;

  /// Format for display with unit
  String getDisplayValue({bool useMmol = false}) {
    if (useMmol) {
      return '${glucoseValueMmol.toStringAsFixed(1)} mmol/L';
    }
    return '$glucoseValue mg/dL';
  }
}

/// Request to log a new glucose reading
@JsonSerializable()
class GlucoseReadingRequest {
  @JsonKey(name: 'glucose_value')
  final int glucoseValue;
  @JsonKey(name: 'meal_context')
  final String mealContext;
  @JsonKey(name: 'reading_type')
  final String? readingType;
  @JsonKey(name: 'recorded_at')
  final DateTime? recordedAt;
  final String? notes;
  @JsonKey(name: 'food_log_id')
  final String? foodLogId;
  @JsonKey(name: 'carbs_consumed')
  final int? carbsConsumed;

  const GlucoseReadingRequest({
    required this.glucoseValue,
    required this.mealContext,
    this.readingType,
    this.recordedAt,
    this.notes,
    this.foodLogId,
    this.carbsConsumed,
  });

  factory GlucoseReadingRequest.fromJson(Map<String, dynamic> json) =>
      _$GlucoseReadingRequestFromJson(json);
  Map<String, dynamic> toJson() => _$GlucoseReadingRequestToJson(this);
}

/// Daily glucose summary
@JsonSerializable()
class DailyGlucoseSummary {
  final String date;
  @JsonKey(name: 'reading_count')
  final int readingCount;
  @JsonKey(name: 'avg_glucose')
  final double avgGlucose;
  @JsonKey(name: 'min_glucose')
  final int minGlucose;
  @JsonKey(name: 'max_glucose')
  final int maxGlucose;
  @JsonKey(name: 'time_in_range_percent')
  final double timeInRangePercent;
  @JsonKey(name: 'low_count')
  final int lowCount;
  @JsonKey(name: 'high_count')
  final int highCount;
  final List<GlucoseReading> readings;

  const DailyGlucoseSummary({
    required this.date,
    this.readingCount = 0,
    this.avgGlucose = 0,
    this.minGlucose = 0,
    this.maxGlucose = 0,
    this.timeInRangePercent = 0,
    this.lowCount = 0,
    this.highCount = 0,
    this.readings = const [],
  });

  factory DailyGlucoseSummary.fromJson(Map<String, dynamic> json) =>
      _$DailyGlucoseSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$DailyGlucoseSummaryToJson(this);

  /// Get average as formatted string
  String get avgGlucoseDisplay => avgGlucose.toStringAsFixed(0);

  /// Check if day had any hypo events
  bool get hasHypoEvents => lowCount > 0;

  /// Check if day had any hyper events
  bool get hasHyperEvents => highCount > 0;

  /// Get time in range as percentage string
  String get timeInRangeDisplay => '${timeInRangePercent.toStringAsFixed(0)}%';
}
