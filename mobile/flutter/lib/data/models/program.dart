import 'package:json_annotation/json_annotation.dart';

part 'program.g.dart';

@JsonSerializable()
class LibraryProgram {
  final String id;
  final String name;
  final String category;
  final String? subcategory;
  @JsonKey(name: 'difficulty_level')
  final String? difficultyLevel;
  @JsonKey(name: 'duration_weeks')
  final int? durationWeeks;
  @JsonKey(name: 'sessions_per_week')
  final int? sessionsPerWeek;
  @JsonKey(name: 'session_duration_minutes')
  final int? sessionDurationMinutes;
  final List<String>? tags;
  final List<String>? goals;
  final String? description;
  @JsonKey(name: 'short_description')
  final String? shortDescription;
  @JsonKey(name: 'celebrity_name')
  final String? celebrityName;

  LibraryProgram({
    required this.id,
    required this.name,
    required this.category,
    this.subcategory,
    this.difficultyLevel,
    this.durationWeeks,
    this.sessionsPerWeek,
    this.sessionDurationMinutes,
    this.tags,
    this.goals,
    this.description,
    this.shortDescription,
    this.celebrityName,
  });

  factory LibraryProgram.fromJson(Map<String, dynamic> json) =>
      _$LibraryProgramFromJson(json);

  Map<String, dynamic> toJson() => _$LibraryProgramToJson(this);

  /// Get a display-friendly difficulty string
  String get difficulty => difficultyLevel ?? 'Unknown';

  /// Get duration display string
  String get durationDisplay =>
      durationWeeks != null ? '$durationWeeks weeks' : 'Varies';

  /// Get sessions display string
  String get sessionsDisplay =>
      sessionsPerWeek != null ? '$sessionsPerWeek days/week' : 'Flexible';
}
