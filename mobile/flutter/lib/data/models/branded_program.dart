import 'package:json_annotation/json_annotation.dart';

part 'branded_program.g.dart';

/// A branded workout program template that users can adopt.
///
/// This is the primary model for programs in the app. It combines fields
/// from the branded_programs table in the backend. Previously there was a
/// separate LibraryProgram model, but this has been unified into BrandedProgram.
@JsonSerializable()
class BrandedProgram {
  final String id;
  final String name;
  final String? category;
  final String? subcategory;
  @JsonKey(name: 'difficulty_level')
  final String? difficultyLevel;
  @JsonKey(name: 'duration_weeks')
  final int? durationWeeks;
  @JsonKey(name: 'sessions_per_week')
  final int? sessionsPerWeek;
  @JsonKey(name: 'session_duration_minutes')
  final int? sessionDurationMinutes;
  final String? description;
  @JsonKey(name: 'short_description')
  final String? shortDescription;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'celebrity_name')
  final String? celebrityName;
  final List<String>? tags;
  final List<String>? goals;
  @JsonKey(name: 'is_featured')
  final bool? isFeatured;
  @JsonKey(name: 'is_popular')
  final bool? isPopular;
  @JsonKey(name: 'is_premium')
  final bool? isPremium;
  @JsonKey(name: 'requires_gym')
  final bool? requiresGym;
  @JsonKey(name: 'icon_name')
  final String? iconName;
  @JsonKey(name: 'color_hex')
  final String? colorHex;
  @JsonKey(name: 'created_at')
  final String? createdAt;

  const BrandedProgram({
    required this.id,
    required this.name,
    this.category,
    this.subcategory,
    this.difficultyLevel,
    this.durationWeeks,
    this.sessionsPerWeek,
    this.sessionDurationMinutes,
    this.description,
    this.shortDescription,
    this.imageUrl,
    this.celebrityName,
    this.tags,
    this.goals,
    this.isFeatured,
    this.isPopular,
    this.isPremium,
    this.requiresGym,
    this.iconName,
    this.colorHex,
    this.createdAt,
  });

  factory BrandedProgram.fromJson(Map<String, dynamic> json) =>
      _$BrandedProgramFromJson(json);

  Map<String, dynamic> toJson() => _$BrandedProgramToJson(this);

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

  /// Create a copy with new values
  BrandedProgram copyWith({
    String? id,
    String? name,
    String? category,
    String? difficultyLevel,
    int? durationWeeks,
    int? sessionsPerWeek,
    int? sessionDurationMinutes,
    String? description,
    String? shortDescription,
    String? imageUrl,
    String? celebrityName,
    List<String>? tags,
    List<String>? goals,
    bool? isFeatured,
    bool? isPopular,
    String? createdAt,
  }) {
    return BrandedProgram(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      sessionsPerWeek: sessionsPerWeek ?? this.sessionsPerWeek,
      sessionDurationMinutes:
          sessionDurationMinutes ?? this.sessionDurationMinutes,
      description: description ?? this.description,
      shortDescription: shortDescription ?? this.shortDescription,
      imageUrl: imageUrl ?? this.imageUrl,
      celebrityName: celebrityName ?? this.celebrityName,
      tags: tags ?? this.tags,
      goals: goals ?? this.goals,
      isFeatured: isFeatured ?? this.isFeatured,
      isPopular: isPopular ?? this.isPopular,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// User's current assigned program
@JsonSerializable()
class UserProgram {
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'program_id')
  final String programId;
  @JsonKey(name: 'custom_name')
  final String? customName;
  @JsonKey(name: 'started_at')
  final String? startedAt;
  @JsonKey(name: 'current_week')
  final int? currentWeek;
  @JsonKey(name: 'is_active')
  final bool? isActive;
  final BrandedProgram? program;

  const UserProgram({
    required this.userId,
    required this.programId,
    this.customName,
    this.startedAt,
    this.currentWeek,
    this.isActive,
    this.program,
  });

  factory UserProgram.fromJson(Map<String, dynamic> json) =>
      _$UserProgramFromJson(json);

  Map<String, dynamic> toJson() => _$UserProgramToJson(this);

  /// Get the display name (custom name or program name)
  String get displayName => customName ?? program?.name ?? 'Current Program';

  /// Get weeks completed
  int get weeksCompleted => (currentWeek ?? 1) - 1;

  /// Get total weeks
  int get totalWeeks => program?.durationWeeks ?? 0;

  /// Get progress percentage (0.0 to 1.0)
  double get progressPercent {
    if (totalWeeks <= 0) return 0.0;
    return (weeksCompleted / totalWeeks).clamp(0.0, 1.0);
  }
}
