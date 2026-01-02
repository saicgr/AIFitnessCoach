import 'package:json_annotation/json_annotation.dart';

part 'program.g.dart';

/// A workout program from the library.
///
/// This model is used for displaying programs in the Library tab.
/// It maps to the branded_programs table in the backend.
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

  // Additional fields from branded_programs table
  @JsonKey(name: 'is_featured')
  final bool? isFeatured;
  @JsonKey(name: 'is_premium')
  final bool? isPremium;
  @JsonKey(name: 'requires_gym')
  final bool? requiresGym;
  @JsonKey(name: 'icon_name')
  final String? iconName;
  @JsonKey(name: 'color_hex')
  final String? colorHex;
  @JsonKey(name: 'split_type')
  final String? splitType;

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
    this.isFeatured,
    this.isPremium,
    this.requiresGym,
    this.iconName,
    this.colorHex,
    this.splitType,
  });

  factory LibraryProgram.fromJson(Map<String, dynamic> json) =>
      _$LibraryProgramFromJson(json);

  Map<String, dynamic> toJson() => _$LibraryProgramToJson(this);

  /// Get a display-friendly difficulty string
  String get difficulty => difficultyLevel ?? 'All Levels';

  /// Get duration display string
  String get durationDisplay =>
      durationWeeks != null ? '$durationWeeks weeks' : 'Flexible';

  /// Get sessions display string
  String get sessionsDisplay =>
      sessionsPerWeek != null ? '$sessionsPerWeek days/week' : 'Flexible';

  /// Get session duration display string
  String get sessionDurationDisplay =>
      sessionDurationMinutes != null ? '$sessionDurationMinutes min' : 'Varies';

  /// Check if this is a featured program
  bool get featured => isFeatured ?? false;

  /// Check if this is a premium program
  bool get premium => isPremium ?? false;

  /// Check if this program requires gym equipment
  bool get gymRequired => requiresGym ?? false;
}
