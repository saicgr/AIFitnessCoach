import 'package:json_annotation/json_annotation.dart';

part 'a1c_record.g.dart';

/// Risk level based on A1C value
enum A1CRiskLevel {
  @JsonValue('excellent')
  excellent('excellent', 'Excellent', 'Normal range', 0xFF4CAF50),
  @JsonValue('good')
  good('good', 'Good', 'Prediabetes range', 0xFF8BC34A),
  @JsonValue('fair')
  fair('fair', 'Fair', 'Diabetes, well controlled', 0xFFFF9800),
  @JsonValue('poor')
  poor('poor', 'Poor', 'Needs improvement', 0xFFF44336);

  final String value;
  final String displayName;
  final String description;
  final int colorValue;

  const A1CRiskLevel(this.value, this.displayName, this.description, this.colorValue);

  static A1CRiskLevel fromValue(String? value) {
    if (value == null) return A1CRiskLevel.fair;
    return A1CRiskLevel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => A1CRiskLevel.fair,
    );
  }
}

/// A1C test record
@JsonSerializable()
class A1CRecord {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'a1c_value')
  final double a1cValue;
  @JsonKey(name: 'test_date')
  final DateTime testDate;
  @JsonKey(name: 'test_type')
  final String testType; // 'lab', 'home_kit', 'doctor_office'
  @JsonKey(name: 'lab_name')
  final String? labName;
  @JsonKey(name: 'ordering_physician')
  final String? orderingPhysician;
  @JsonKey(name: 'estimated_avg_glucose')
  final int? estimatedAvgGlucose;
  final String? notes;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const A1CRecord({
    required this.id,
    required this.userId,
    required this.a1cValue,
    required this.testDate,
    this.testType = 'lab',
    this.labName,
    this.orderingPhysician,
    this.estimatedAvgGlucose,
    this.notes,
    required this.createdAt,
  });

  factory A1CRecord.fromJson(Map<String, dynamic> json) =>
      _$A1CRecordFromJson(json);
  Map<String, dynamic> toJson() => _$A1CRecordToJson(this);

  /// Get risk level based on A1C value
  /// < 5.7% = Normal (Excellent)
  /// 5.7% - 6.4% = Prediabetes (Good)
  /// 6.5% - 7.0% = Diabetes, well controlled (Fair)
  /// > 7.0% = Needs improvement (Poor)
  A1CRiskLevel getRiskLevel() {
    if (a1cValue < 5.7) {
      return A1CRiskLevel.excellent;
    } else if (a1cValue < 6.5) {
      return A1CRiskLevel.good;
    } else if (a1cValue <= 7.0) {
      return A1CRiskLevel.fair;
    } else {
      return A1CRiskLevel.poor;
    }
  }

  /// Get color for A1C display (0xAARRGGBB)
  int getA1CColor() => getRiskLevel().colorValue;

  /// Get formatted A1C display
  String get a1cDisplay => '${a1cValue.toStringAsFixed(1)}%';

  /// Calculate estimated average glucose (eAG) from A1C
  /// Formula: eAG (mg/dL) = 28.7 x A1C - 46.7
  int get calculatedEAG => ((28.7 * a1cValue) - 46.7).round();

  /// Get the estimated average glucose (from record or calculated)
  int get avgGlucose => estimatedAvgGlucose ?? calculatedEAG;

  /// Get eAG in mmol/L
  double get avgGlucoseMmol => avgGlucose / 18.0;

  /// Get days since test
  int get daysSinceTest => DateTime.now().difference(testDate).inDays;

  /// Check if test is recent (within 90 days)
  bool get isRecent => daysSinceTest <= 90;

  /// Check if test is overdue (more than 90 days)
  bool get isOverdue => daysSinceTest > 90;

  /// Get description for current level
  String get levelDescription {
    final level = getRiskLevel();
    switch (level) {
      case A1CRiskLevel.excellent:
        return 'Your A1C is in the normal range. Keep up the great work!';
      case A1CRiskLevel.good:
        return 'Your A1C indicates prediabetes. Lifestyle changes can help prevent progression.';
      case A1CRiskLevel.fair:
        return 'Your diabetes is reasonably controlled. Work with your doctor to maintain or improve.';
      case A1CRiskLevel.poor:
        return 'Your A1C needs improvement. Talk to your healthcare provider about adjusting treatment.';
    }
  }
}

/// Request to add A1C record
@JsonSerializable()
class A1CRecordRequest {
  @JsonKey(name: 'a1c_value')
  final double a1cValue;
  @JsonKey(name: 'test_date')
  final DateTime testDate;
  @JsonKey(name: 'test_type')
  final String? testType;
  @JsonKey(name: 'lab_name')
  final String? labName;
  @JsonKey(name: 'ordering_physician')
  final String? orderingPhysician;
  final String? notes;

  const A1CRecordRequest({
    required this.a1cValue,
    required this.testDate,
    this.testType,
    this.labName,
    this.orderingPhysician,
    this.notes,
  });

  factory A1CRecordRequest.fromJson(Map<String, dynamic> json) =>
      _$A1CRecordRequestFromJson(json);
  Map<String, dynamic> toJson() => _$A1CRecordRequestToJson(this);
}

/// A1C history with trend analysis
@JsonSerializable()
class A1CHistory {
  final List<A1CRecord> records;
  @JsonKey(name: 'latest_a1c')
  final double? latestA1c;
  @JsonKey(name: 'previous_a1c')
  final double? previousA1c;
  @JsonKey(name: 'change')
  final double? change;
  final String trend; // 'improving', 'stable', 'worsening'
  @JsonKey(name: 'avg_a1c_6_months')
  final double? avgA1c6Months;
  @JsonKey(name: 'lowest_a1c')
  final double? lowestA1c;
  @JsonKey(name: 'highest_a1c')
  final double? highestA1c;
  @JsonKey(name: 'days_since_last_test')
  final int? daysSinceLastTest;
  @JsonKey(name: 'next_test_due')
  final DateTime? nextTestDue;

  const A1CHistory({
    this.records = const [],
    this.latestA1c,
    this.previousA1c,
    this.change,
    this.trend = 'stable',
    this.avgA1c6Months,
    this.lowestA1c,
    this.highestA1c,
    this.daysSinceLastTest,
    this.nextTestDue,
  });

  factory A1CHistory.fromJson(Map<String, dynamic> json) =>
      _$A1CHistoryFromJson(json);
  Map<String, dynamic> toJson() => _$A1CHistoryToJson(this);

  /// Check if improving
  bool get isImproving => trend == 'improving';

  /// Check if stable
  bool get isStable => trend == 'stable';

  /// Check if worsening
  bool get isWorsening => trend == 'worsening';

  /// Get change as formatted string
  String get changeDisplay {
    if (change == null) return 'N/A';
    final sign = change! > 0 ? '+' : '';
    return '$sign${change!.toStringAsFixed(1)}%';
  }

  /// Get color for trend
  int get trendColor {
    switch (trend) {
      case 'improving':
        return 0xFF4CAF50; // Green
      case 'stable':
        return 0xFFFF9800; // Orange
      case 'worsening':
        return 0xFFF44336; // Red
      default:
        return 0xFF9E9E9E; // Grey
    }
  }

  /// Check if next test is due
  bool get isTestDue {
    if (nextTestDue == null) return false;
    return DateTime.now().isAfter(nextTestDue!);
  }
}

/// A1C to average glucose conversion table entry
class A1CConversionEntry {
  final double a1c;
  final int mgDL;
  final double mmolL;

  const A1CConversionEntry(this.a1c, this.mgDL, this.mmolL);

  static const List<A1CConversionEntry> conversionTable = [
    A1CConversionEntry(5.0, 97, 5.4),
    A1CConversionEntry(5.5, 111, 6.2),
    A1CConversionEntry(6.0, 126, 7.0),
    A1CConversionEntry(6.5, 140, 7.8),
    A1CConversionEntry(7.0, 154, 8.6),
    A1CConversionEntry(7.5, 169, 9.4),
    A1CConversionEntry(8.0, 183, 10.2),
    A1CConversionEntry(8.5, 197, 10.9),
    A1CConversionEntry(9.0, 212, 11.8),
    A1CConversionEntry(9.5, 226, 12.6),
    A1CConversionEntry(10.0, 240, 13.4),
    A1CConversionEntry(10.5, 255, 14.2),
    A1CConversionEntry(11.0, 269, 14.9),
    A1CConversionEntry(11.5, 283, 15.7),
    A1CConversionEntry(12.0, 298, 16.5),
  ];
}
