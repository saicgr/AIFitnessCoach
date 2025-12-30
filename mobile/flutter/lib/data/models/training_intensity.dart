import 'package:json_annotation/json_annotation.dart';

part 'training_intensity.g.dart';

/// User's stored 1RM for an exercise
@JsonSerializable()
class UserExercise1RM {
  @JsonKey(name: 'exercise_name')
  final String exerciseName;

  @JsonKey(name: 'one_rep_max_kg')
  final double oneRepMaxKg;

  /// Source of the 1RM: 'manual', 'calculated', 'tested'
  final String source;

  /// Confidence level 0.0 to 1.0
  final double confidence;

  @JsonKey(name: 'last_tested_at')
  final String? lastTestedAt;

  @JsonKey(name: 'created_at')
  final String? createdAt;

  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  const UserExercise1RM({
    required this.exerciseName,
    required this.oneRepMaxKg,
    this.source = 'manual',
    this.confidence = 1.0,
    this.lastTestedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory UserExercise1RM.fromJson(Map<String, dynamic> json) =>
      _$UserExercise1RMFromJson(json);

  Map<String, dynamic> toJson() => _$UserExercise1RMToJson(this);

  /// Get a display string for the source
  String get sourceDisplay {
    switch (source) {
      case 'manual':
        return 'Entered manually';
      case 'calculated':
        return 'Estimated from workouts';
      case 'tested':
        return 'Tested 1RM';
      default:
        return source;
    }
  }

  /// Get weight in user's preferred unit (assumes kg input, can be extended)
  String get weightDisplay => '${oneRepMaxKg.toStringAsFixed(1)} kg';

  UserExercise1RM copyWith({
    String? exerciseName,
    double? oneRepMaxKg,
    String? source,
    double? confidence,
    String? lastTestedAt,
    String? createdAt,
    String? updatedAt,
  }) {
    return UserExercise1RM(
      exerciseName: exerciseName ?? this.exerciseName,
      oneRepMaxKg: oneRepMaxKg ?? this.oneRepMaxKg,
      source: source ?? this.source,
      confidence: confidence ?? this.confidence,
      lastTestedAt: lastTestedAt ?? this.lastTestedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// User's training intensity settings
@JsonSerializable()
class TrainingIntensitySettings {
  @JsonKey(name: 'global_intensity_percent')
  final int globalIntensityPercent;

  @JsonKey(name: 'global_description')
  final String globalDescription;

  @JsonKey(name: 'exercise_overrides')
  final Map<String, int> exerciseOverrides;

  const TrainingIntensitySettings({
    this.globalIntensityPercent = 75,
    this.globalDescription = 'Working Weight / Hypertrophy',
    this.exerciseOverrides = const {},
  });

  factory TrainingIntensitySettings.fromJson(Map<String, dynamic> json) =>
      _$TrainingIntensitySettingsFromJson(json);

  Map<String, dynamic> toJson() => _$TrainingIntensitySettingsToJson(this);

  /// Get the intensity for a specific exercise (override or global)
  int getIntensityForExercise(String exerciseName) {
    final lowerName = exerciseName.toLowerCase();
    return exerciseOverrides[lowerName] ??
        exerciseOverrides[exerciseName] ??
        globalIntensityPercent;
  }

  /// Check if an exercise has an override
  bool hasOverride(String exerciseName) {
    final lowerName = exerciseName.toLowerCase();
    return exerciseOverrides.containsKey(lowerName) ||
        exerciseOverrides.containsKey(exerciseName);
  }

  TrainingIntensitySettings copyWith({
    int? globalIntensityPercent,
    String? globalDescription,
    Map<String, int>? exerciseOverrides,
  }) {
    return TrainingIntensitySettings(
      globalIntensityPercent:
          globalIntensityPercent ?? this.globalIntensityPercent,
      globalDescription: globalDescription ?? this.globalDescription,
      exerciseOverrides: exerciseOverrides ?? this.exerciseOverrides,
    );
  }
}

/// Response from setting intensity
@JsonSerializable()
class IntensityResponse {
  @JsonKey(name: 'intensity_percent')
  final int intensityPercent;

  final String description;

  const IntensityResponse({
    required this.intensityPercent,
    required this.description,
  });

  factory IntensityResponse.fromJson(Map<String, dynamic> json) =>
      _$IntensityResponseFromJson(json);

  Map<String, dynamic> toJson() => _$IntensityResponseToJson(this);
}

/// Calculated working weight result
@JsonSerializable()
class WorkingWeightResult {
  @JsonKey(name: 'exercise_name')
  final String exerciseName;

  @JsonKey(name: 'one_rep_max_kg')
  final double oneRepMaxKg;

  @JsonKey(name: 'intensity_percent')
  final int intensityPercent;

  @JsonKey(name: 'working_weight_kg')
  final double workingWeightKg;

  @JsonKey(name: 'is_from_override')
  final bool isFromOverride;

  const WorkingWeightResult({
    required this.exerciseName,
    required this.oneRepMaxKg,
    required this.intensityPercent,
    required this.workingWeightKg,
    this.isFromOverride = false,
  });

  factory WorkingWeightResult.fromJson(Map<String, dynamic> json) =>
      _$WorkingWeightResultFromJson(json);

  Map<String, dynamic> toJson() => _$WorkingWeightResultToJson(this);

  /// Get display string for the working weight
  String get display =>
      '${workingWeightKg.toStringAsFixed(1)} kg ($intensityPercent% of 1RM)';
}

/// Auto-populate response
@JsonSerializable()
class AutoPopulateResponse {
  final int count;
  final String message;

  const AutoPopulateResponse({
    required this.count,
    required this.message,
  });

  factory AutoPopulateResponse.fromJson(Map<String, dynamic> json) =>
      _$AutoPopulateResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AutoPopulateResponseToJson(this);
}

/// Intensity level descriptions
class IntensityLevelInfo {
  final int minPercent;
  final int maxPercent;
  final String label;
  final String description;

  const IntensityLevelInfo({
    required this.minPercent,
    required this.maxPercent,
    required this.label,
    required this.description,
  });

  static const List<IntensityLevelInfo> levels = [
    IntensityLevelInfo(
      minPercent: 50,
      maxPercent: 60,
      label: 'Light',
      description: 'Recovery / Deload',
    ),
    IntensityLevelInfo(
      minPercent: 61,
      maxPercent: 70,
      label: 'Moderate',
      description: 'Endurance / Volume',
    ),
    IntensityLevelInfo(
      minPercent: 71,
      maxPercent: 80,
      label: 'Working',
      description: 'Hypertrophy / Building',
    ),
    IntensityLevelInfo(
      minPercent: 81,
      maxPercent: 90,
      label: 'Heavy',
      description: 'Strength / Power',
    ),
    IntensityLevelInfo(
      minPercent: 91,
      maxPercent: 100,
      label: 'Max',
      description: 'Near Max / Peaking',
    ),
  ];

  static IntensityLevelInfo getForPercent(int percent) {
    for (final level in levels) {
      if (percent >= level.minPercent && percent <= level.maxPercent) {
        return level;
      }
    }
    return levels[2]; // Default to working weight
  }

  static String getDescriptionForPercent(int percent) {
    return getForPercent(percent).description;
  }
}
