// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gym_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GymProfile _$GymProfileFromJson(Map<String, dynamic> json) => GymProfile(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  name: json['name'] as String,
  icon: json['icon'] as String? ?? 'fitness_center',
  color: json['color'] as String? ?? '#00BCD4',
  equipment:
      (json['equipment'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  equipmentDetails: (json['equipment_details'] as List<dynamic>?)
      ?.map((e) => e as Map<String, dynamic>)
      .toList(),
  workoutEnvironment:
      json['workout_environment'] as String? ?? 'commercial_gym',
  address: json['address'] as String?,
  city: json['city'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  placeId: json['place_id'] as String?,
  locationRadiusMeters:
      (json['location_radius_meters'] as num?)?.toInt() ?? 100,
  autoSwitchEnabled: json['auto_switch_enabled'] as bool? ?? true,
  preferredTimeSlot: json['preferred_time_slot'] as String?,
  timeAutoSwitchEnabled: json['time_auto_switch_enabled'] as bool? ?? true,
  trainingSplit: json['training_split'] as String?,
  workoutDays:
      (json['workout_days'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [],
  durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 45,
  durationMinutesMin: (json['duration_minutes_min'] as num?)?.toInt(),
  durationMinutesMax: (json['duration_minutes_max'] as num?)?.toInt(),
  goals:
      (json['goals'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  focusAreas:
      (json['focus_areas'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  currentProgramId: json['current_program_id'] as String?,
  programCustomName: json['program_custom_name'] as String?,
  displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
  isActive: json['is_active'] as bool? ?? false,
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
);

Map<String, dynamic> _$GymProfileToJson(GymProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'name': instance.name,
      'icon': instance.icon,
      'color': instance.color,
      'equipment': instance.equipment,
      'equipment_details': instance.equipmentDetails,
      'workout_environment': instance.workoutEnvironment,
      'address': instance.address,
      'city': instance.city,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'place_id': instance.placeId,
      'location_radius_meters': instance.locationRadiusMeters,
      'auto_switch_enabled': instance.autoSwitchEnabled,
      'preferred_time_slot': instance.preferredTimeSlot,
      'time_auto_switch_enabled': instance.timeAutoSwitchEnabled,
      'training_split': instance.trainingSplit,
      'workout_days': instance.workoutDays,
      'duration_minutes': instance.durationMinutes,
      'duration_minutes_min': instance.durationMinutesMin,
      'duration_minutes_max': instance.durationMinutesMax,
      'goals': instance.goals,
      'focus_areas': instance.focusAreas,
      'current_program_id': instance.currentProgramId,
      'program_custom_name': instance.programCustomName,
      'display_order': instance.displayOrder,
      'is_active': instance.isActive,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

GymProfileCreate _$GymProfileCreateFromJson(Map<String, dynamic> json) =>
    GymProfileCreate(
      name: json['name'] as String,
      icon: json['icon'] as String? ?? 'fitness_center',
      color: json['color'] as String? ?? '#00BCD4',
      equipment:
          (json['equipment'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      equipmentDetails: (json['equipment_details'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      workoutEnvironment:
          json['workout_environment'] as String? ?? 'commercial_gym',
      address: json['address'] as String?,
      city: json['city'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      placeId: json['place_id'] as String?,
      locationRadiusMeters:
          (json['location_radius_meters'] as num?)?.toInt() ?? 100,
      autoSwitchEnabled: json['auto_switch_enabled'] as bool? ?? true,
      preferredTimeSlot: json['preferred_time_slot'] as String?,
      timeAutoSwitchEnabled: json['time_auto_switch_enabled'] as bool? ?? true,
      trainingSplit: json['training_split'] as String?,
      workoutDays:
          (json['workout_days'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 45,
      durationMinutesMin: (json['duration_minutes_min'] as num?)?.toInt(),
      durationMinutesMax: (json['duration_minutes_max'] as num?)?.toInt(),
      goals:
          (json['goals'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      focusAreas:
          (json['focus_areas'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$GymProfileCreateToJson(GymProfileCreate instance) =>
    <String, dynamic>{
      'name': instance.name,
      'icon': instance.icon,
      'color': instance.color,
      'equipment': instance.equipment,
      'equipment_details': instance.equipmentDetails,
      'workout_environment': instance.workoutEnvironment,
      'address': instance.address,
      'city': instance.city,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'place_id': instance.placeId,
      'location_radius_meters': instance.locationRadiusMeters,
      'auto_switch_enabled': instance.autoSwitchEnabled,
      'preferred_time_slot': instance.preferredTimeSlot,
      'time_auto_switch_enabled': instance.timeAutoSwitchEnabled,
      'training_split': instance.trainingSplit,
      'workout_days': instance.workoutDays,
      'duration_minutes': instance.durationMinutes,
      'duration_minutes_min': instance.durationMinutesMin,
      'duration_minutes_max': instance.durationMinutesMax,
      'goals': instance.goals,
      'focus_areas': instance.focusAreas,
    };

GymProfileUpdate _$GymProfileUpdateFromJson(Map<String, dynamic> json) =>
    GymProfileUpdate(
      name: json['name'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      equipment: (json['equipment'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      equipmentDetails: (json['equipment_details'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      workoutEnvironment: json['workout_environment'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      placeId: json['place_id'] as String?,
      locationRadiusMeters: (json['location_radius_meters'] as num?)?.toInt(),
      autoSwitchEnabled: json['auto_switch_enabled'] as bool?,
      preferredTimeSlot: json['preferred_time_slot'] as String?,
      timeAutoSwitchEnabled: json['time_auto_switch_enabled'] as bool?,
      trainingSplit: json['training_split'] as String?,
      workoutDays: (json['workout_days'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      durationMinutesMin: (json['duration_minutes_min'] as num?)?.toInt(),
      durationMinutesMax: (json['duration_minutes_max'] as num?)?.toInt(),
      goals: (json['goals'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      focusAreas: (json['focus_areas'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      currentProgramId: json['current_program_id'] as String?,
      programCustomName: json['program_custom_name'] as String?,
    );

Map<String, dynamic> _$GymProfileUpdateToJson(
  GymProfileUpdate instance,
) => <String, dynamic>{
  if (instance.name case final value?) 'name': value,
  if (instance.icon case final value?) 'icon': value,
  if (instance.color case final value?) 'color': value,
  if (instance.equipment case final value?) 'equipment': value,
  if (instance.equipmentDetails case final value?) 'equipment_details': value,
  if (instance.workoutEnvironment case final value?)
    'workout_environment': value,
  if (instance.address case final value?) 'address': value,
  if (instance.city case final value?) 'city': value,
  if (instance.latitude case final value?) 'latitude': value,
  if (instance.longitude case final value?) 'longitude': value,
  if (instance.placeId case final value?) 'place_id': value,
  if (instance.locationRadiusMeters case final value?)
    'location_radius_meters': value,
  if (instance.autoSwitchEnabled case final value?)
    'auto_switch_enabled': value,
  if (instance.preferredTimeSlot case final value?)
    'preferred_time_slot': value,
  if (instance.timeAutoSwitchEnabled case final value?)
    'time_auto_switch_enabled': value,
  if (instance.trainingSplit case final value?) 'training_split': value,
  if (instance.workoutDays case final value?) 'workout_days': value,
  if (instance.durationMinutes case final value?) 'duration_minutes': value,
  if (instance.durationMinutesMin case final value?)
    'duration_minutes_min': value,
  if (instance.durationMinutesMax case final value?)
    'duration_minutes_max': value,
  if (instance.goals case final value?) 'goals': value,
  if (instance.focusAreas case final value?) 'focus_areas': value,
  if (instance.currentProgramId case final value?) 'current_program_id': value,
  if (instance.programCustomName case final value?)
    'program_custom_name': value,
};

GymProfileListResponse _$GymProfileListResponseFromJson(
  Map<String, dynamic> json,
) => GymProfileListResponse(
  profiles: (json['profiles'] as List<dynamic>)
      .map((e) => GymProfile.fromJson(e as Map<String, dynamic>))
      .toList(),
  activeProfileId: json['active_profile_id'] as String?,
  count: (json['count'] as num).toInt(),
);

Map<String, dynamic> _$GymProfileListResponseToJson(
  GymProfileListResponse instance,
) => <String, dynamic>{
  'profiles': instance.profiles,
  'active_profile_id': instance.activeProfileId,
  'count': instance.count,
};

ActivateProfileResponse _$ActivateProfileResponseFromJson(
  Map<String, dynamic> json,
) => ActivateProfileResponse(
  success: json['success'] as bool,
  activeProfile: GymProfile.fromJson(
    json['active_profile'] as Map<String, dynamic>,
  ),
  message: json['message'] as String,
);

Map<String, dynamic> _$ActivateProfileResponseToJson(
  ActivateProfileResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'active_profile': instance.activeProfile,
  'message': instance.message,
};
