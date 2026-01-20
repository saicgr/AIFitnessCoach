import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/material.dart';

part 'gym_profile.g.dart';

/// Default color palette for gym profiles
class GymProfileColors {
  static const List<String> palette = [
    '#00BCD4', // Cyan (default for first profile)
    '#F97316', // Orange
    '#8B5CF6', // Purple
    '#10B981', // Green
    '#EF4444', // Red
    '#F59E0B', // Amber
    '#EC4899', // Pink
    '#6366F1', // Indigo
  ];

  /// Get the next color in the palette based on existing profile count
  static String getNextColor(int profileCount) {
    return palette[profileCount % palette.length];
  }

  /// Parse hex color string to Color
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

/// Gym profile model for multi-gym profile system
@JsonSerializable()
class GymProfile extends Equatable {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final String name;
  final String icon;
  final String color;
  final List<String> equipment;
  @JsonKey(name: 'equipment_details')
  final List<Map<String, dynamic>>? equipmentDetails;
  @JsonKey(name: 'workout_environment')
  final String workoutEnvironment;
  @JsonKey(name: 'training_split')
  final String? trainingSplit;
  @JsonKey(name: 'workout_days')
  final List<int> workoutDays;
  @JsonKey(name: 'duration_minutes')
  final int durationMinutes;
  @JsonKey(name: 'duration_minutes_min')
  final int? durationMinutesMin;
  @JsonKey(name: 'duration_minutes_max')
  final int? durationMinutesMax;
  final List<String> goals;
  @JsonKey(name: 'focus_areas')
  final List<String> focusAreas;
  @JsonKey(name: 'current_program_id')
  final String? currentProgramId;
  @JsonKey(name: 'program_custom_name')
  final String? programCustomName;
  @JsonKey(name: 'display_order')
  final int displayOrder;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  const GymProfile({
    required this.id,
    required this.userId,
    required this.name,
    this.icon = 'fitness_center',
    this.color = '#00BCD4',
    this.equipment = const [],
    this.equipmentDetails,
    this.workoutEnvironment = 'commercial_gym',
    this.trainingSplit,
    this.workoutDays = const [],
    this.durationMinutes = 45,
    this.durationMinutesMin,
    this.durationMinutesMax,
    this.goals = const [],
    this.focusAreas = const [],
    this.currentProgramId,
    this.programCustomName,
    this.displayOrder = 0,
    this.isActive = false,
    this.createdAt,
    this.updatedAt,
  });

  factory GymProfile.fromJson(Map<String, dynamic> json) =>
      _$GymProfileFromJson(json);
  Map<String, dynamic> toJson() => _$GymProfileToJson(this);

  /// Get the profile color as a Flutter Color
  Color get profileColor => GymProfileColors.fromHex(color);

  /// Get a friendly name for the workout environment
  String get environmentDisplayName {
    switch (workoutEnvironment) {
      case 'commercial_gym':
        return 'Commercial Gym';
      case 'home_gym':
        return 'Home Gym';
      case 'home':
        return 'Home';
      case 'hotel':
        return 'Hotel';
      case 'outdoors':
        return 'Outdoors';
      default:
        return workoutEnvironment;
    }
  }

  /// Get the icon as an IconData (supports both material icons and emoji)
  String get iconDisplay {
    // If it's an emoji, return as-is
    if (icon.contains(RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true))) {
      return icon;
    }
    // Return the icon name for lookup
    return icon;
  }

  /// Check if this profile has equipment
  bool get hasEquipment => equipment.isNotEmpty;

  /// Get equipment count
  int get equipmentCount => equipment.length;

  /// Duration range as formatted string
  String get durationDisplay {
    if (durationMinutesMin != null && durationMinutesMax != null) {
      return '$durationMinutesMin-$durationMinutesMax min';
    }
    return '$durationMinutes min';
  }

  /// Create a copy with updated fields
  GymProfile copyWith({
    String? id,
    String? userId,
    String? name,
    String? icon,
    String? color,
    List<String>? equipment,
    List<Map<String, dynamic>>? equipmentDetails,
    String? workoutEnvironment,
    String? trainingSplit,
    List<int>? workoutDays,
    int? durationMinutes,
    int? durationMinutesMin,
    int? durationMinutesMax,
    List<String>? goals,
    List<String>? focusAreas,
    String? currentProgramId,
    String? programCustomName,
    int? displayOrder,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return GymProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      equipment: equipment ?? this.equipment,
      equipmentDetails: equipmentDetails ?? this.equipmentDetails,
      workoutEnvironment: workoutEnvironment ?? this.workoutEnvironment,
      trainingSplit: trainingSplit ?? this.trainingSplit,
      workoutDays: workoutDays ?? this.workoutDays,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      durationMinutesMin: durationMinutesMin ?? this.durationMinutesMin,
      durationMinutesMax: durationMinutesMax ?? this.durationMinutesMax,
      goals: goals ?? this.goals,
      focusAreas: focusAreas ?? this.focusAreas,
      currentProgramId: currentProgramId ?? this.currentProgramId,
      programCustomName: programCustomName ?? this.programCustomName,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        icon,
        color,
        equipment,
        equipmentDetails,
        workoutEnvironment,
        trainingSplit,
        workoutDays,
        durationMinutes,
        durationMinutesMin,
        durationMinutesMax,
        goals,
        focusAreas,
        currentProgramId,
        programCustomName,
        displayOrder,
        isActive,
        createdAt,
        updatedAt,
      ];
}

/// Request model for creating a gym profile
@JsonSerializable()
class GymProfileCreate {
  final String name;
  final String icon;
  final String color;
  final List<String> equipment;
  @JsonKey(name: 'equipment_details')
  final List<Map<String, dynamic>>? equipmentDetails;
  @JsonKey(name: 'workout_environment')
  final String workoutEnvironment;
  @JsonKey(name: 'training_split')
  final String? trainingSplit;
  @JsonKey(name: 'workout_days')
  final List<int> workoutDays;
  @JsonKey(name: 'duration_minutes')
  final int durationMinutes;
  @JsonKey(name: 'duration_minutes_min')
  final int? durationMinutesMin;
  @JsonKey(name: 'duration_minutes_max')
  final int? durationMinutesMax;
  final List<String> goals;
  @JsonKey(name: 'focus_areas')
  final List<String> focusAreas;

  const GymProfileCreate({
    required this.name,
    this.icon = 'fitness_center',
    this.color = '#00BCD4',
    this.equipment = const [],
    this.equipmentDetails,
    this.workoutEnvironment = 'commercial_gym',
    this.trainingSplit,
    this.workoutDays = const [],
    this.durationMinutes = 45,
    this.durationMinutesMin,
    this.durationMinutesMax,
    this.goals = const [],
    this.focusAreas = const [],
  });

  factory GymProfileCreate.fromJson(Map<String, dynamic> json) =>
      _$GymProfileCreateFromJson(json);
  Map<String, dynamic> toJson() => _$GymProfileCreateToJson(this);
}

/// Request model for updating a gym profile
@JsonSerializable(includeIfNull: false)
class GymProfileUpdate {
  final String? name;
  final String? icon;
  final String? color;
  final List<String>? equipment;
  @JsonKey(name: 'equipment_details')
  final List<Map<String, dynamic>>? equipmentDetails;
  @JsonKey(name: 'workout_environment')
  final String? workoutEnvironment;
  @JsonKey(name: 'training_split')
  final String? trainingSplit;
  @JsonKey(name: 'workout_days')
  final List<int>? workoutDays;
  @JsonKey(name: 'duration_minutes')
  final int? durationMinutes;
  @JsonKey(name: 'duration_minutes_min')
  final int? durationMinutesMin;
  @JsonKey(name: 'duration_minutes_max')
  final int? durationMinutesMax;
  final List<String>? goals;
  @JsonKey(name: 'focus_areas')
  final List<String>? focusAreas;
  @JsonKey(name: 'current_program_id')
  final String? currentProgramId;
  @JsonKey(name: 'program_custom_name')
  final String? programCustomName;

  const GymProfileUpdate({
    this.name,
    this.icon,
    this.color,
    this.equipment,
    this.equipmentDetails,
    this.workoutEnvironment,
    this.trainingSplit,
    this.workoutDays,
    this.durationMinutes,
    this.durationMinutesMin,
    this.durationMinutesMax,
    this.goals,
    this.focusAreas,
    this.currentProgramId,
    this.programCustomName,
  });

  factory GymProfileUpdate.fromJson(Map<String, dynamic> json) =>
      _$GymProfileUpdateFromJson(json);
  Map<String, dynamic> toJson() => _$GymProfileUpdateToJson(this);
}

/// Response for listing gym profiles
@JsonSerializable()
class GymProfileListResponse {
  final List<GymProfile> profiles;
  @JsonKey(name: 'active_profile_id')
  final String? activeProfileId;
  final int count;

  const GymProfileListResponse({
    required this.profiles,
    this.activeProfileId,
    required this.count,
  });

  factory GymProfileListResponse.fromJson(Map<String, dynamic> json) =>
      _$GymProfileListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$GymProfileListResponseToJson(this);
}

/// Response for profile activation
@JsonSerializable()
class ActivateProfileResponse {
  final bool success;
  @JsonKey(name: 'active_profile')
  final GymProfile activeProfile;
  final String message;

  const ActivateProfileResponse({
    required this.success,
    required this.activeProfile,
    required this.message,
  });

  factory ActivateProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$ActivateProfileResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ActivateProfileResponseToJson(this);
}
