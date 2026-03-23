import 'package:json_annotation/json_annotation.dart';

part 'sauna_log.g.dart';

/// Sauna session log entry
@JsonSerializable()
class SaunaLog {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'workout_id')
  final String? workoutId;
  @JsonKey(name: 'duration_minutes')
  final int durationMinutes;
  @JsonKey(name: 'estimated_calories')
  final int? estimatedCalories;
  final String? notes;
  @JsonKey(name: 'logged_at')
  final DateTime? loggedAt;

  const SaunaLog({
    required this.id,
    required this.userId,
    this.workoutId,
    required this.durationMinutes,
    this.estimatedCalories,
    this.notes,
    this.loggedAt,
  });

  factory SaunaLog.fromJson(Map<String, dynamic> json) =>
      _$SaunaLogFromJson(json);
  Map<String, dynamic> toJson() => _$SaunaLogToJson(this);
}

/// Daily sauna summary
@JsonSerializable()
class DailySaunaSummary {
  final String date;
  @JsonKey(name: 'total_minutes')
  final int totalMinutes;
  @JsonKey(name: 'total_calories')
  final int totalCalories;
  final List<SaunaLog> entries;

  const DailySaunaSummary({
    required this.date,
    this.totalMinutes = 0,
    this.totalCalories = 0,
    this.entries = const [],
  });

  factory DailySaunaSummary.fromJson(Map<String, dynamic> json) =>
      _$DailySaunaSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$DailySaunaSummaryToJson(this);
}
