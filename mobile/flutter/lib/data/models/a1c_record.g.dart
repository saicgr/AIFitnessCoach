// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'a1c_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

A1CRecord _$A1CRecordFromJson(Map<String, dynamic> json) => A1CRecord(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  a1cValue: (json['a1c_value'] as num).toDouble(),
  testDate: DateTime.parse(json['test_date'] as String),
  testType: json['test_type'] as String? ?? 'lab',
  labName: json['lab_name'] as String?,
  orderingPhysician: json['ordering_physician'] as String?,
  estimatedAvgGlucose: (json['estimated_avg_glucose'] as num?)?.toInt(),
  notes: json['notes'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$A1CRecordToJson(A1CRecord instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'a1c_value': instance.a1cValue,
  'test_date': instance.testDate.toIso8601String(),
  'test_type': instance.testType,
  'lab_name': instance.labName,
  'ordering_physician': instance.orderingPhysician,
  'estimated_avg_glucose': instance.estimatedAvgGlucose,
  'notes': instance.notes,
  'created_at': instance.createdAt.toIso8601String(),
};

A1CRecordRequest _$A1CRecordRequestFromJson(Map<String, dynamic> json) =>
    A1CRecordRequest(
      a1cValue: (json['a1c_value'] as num).toDouble(),
      testDate: DateTime.parse(json['test_date'] as String),
      testType: json['test_type'] as String?,
      labName: json['lab_name'] as String?,
      orderingPhysician: json['ordering_physician'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$A1CRecordRequestToJson(A1CRecordRequest instance) =>
    <String, dynamic>{
      'a1c_value': instance.a1cValue,
      'test_date': instance.testDate.toIso8601String(),
      'test_type': instance.testType,
      'lab_name': instance.labName,
      'ordering_physician': instance.orderingPhysician,
      'notes': instance.notes,
    };

A1CHistory _$A1CHistoryFromJson(Map<String, dynamic> json) => A1CHistory(
  records:
      (json['records'] as List<dynamic>?)
          ?.map((e) => A1CRecord.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  latestA1c: (json['latest_a1c'] as num?)?.toDouble(),
  previousA1c: (json['previous_a1c'] as num?)?.toDouble(),
  change: (json['change'] as num?)?.toDouble(),
  trend: json['trend'] as String? ?? 'stable',
  avgA1c6Months: (json['avg_a1c_6_months'] as num?)?.toDouble(),
  lowestA1c: (json['lowest_a1c'] as num?)?.toDouble(),
  highestA1c: (json['highest_a1c'] as num?)?.toDouble(),
  daysSinceLastTest: (json['days_since_last_test'] as num?)?.toInt(),
  nextTestDue: json['next_test_due'] == null
      ? null
      : DateTime.parse(json['next_test_due'] as String),
);

Map<String, dynamic> _$A1CHistoryToJson(A1CHistory instance) =>
    <String, dynamic>{
      'records': instance.records,
      'latest_a1c': instance.latestA1c,
      'previous_a1c': instance.previousA1c,
      'change': instance.change,
      'trend': instance.trend,
      'avg_a1c_6_months': instance.avgA1c6Months,
      'lowest_a1c': instance.lowestA1c,
      'highest_a1c': instance.highestA1c,
      'days_since_last_test': instance.daysSinceLastTest,
      'next_test_due': instance.nextTestDue?.toIso8601String(),
    };
