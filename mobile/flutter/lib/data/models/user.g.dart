// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  username: json['username'] as String?,
  name: json['name'] as String?,
  email: json['email'] as String?,
  fitnessLevel: json['fitness_level'] as String?,
  goals: json['goals'] as String?,
  equipment: json['equipment'] as String?,
  preferences: json['preferences'] as String?,
  activeInjuries: json['active_injuries'] as String?,
  heightCm: (json['height_cm'] as num?)?.toDouble(),
  weightKg: (json['weight_kg'] as num?)?.toDouble(),
  targetWeightKg: (json['target_weight_kg'] as num?)?.toDouble(),
  age: (json['age'] as num?)?.toInt(),
  dateOfBirth: json['date_of_birth'] as String?,
  gender: json['gender'] as String?,
  activityLevel: json['activity_level'] as String?,
  onboardingCompleted: json['onboarding_completed'] as bool?,
  coachSelected: json['coach_selected'] as bool?,
  paywallCompleted: json['paywall_completed'] as bool?,
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
  timezone: json['timezone'] as String?,
  role: json['role'] as String?,
  isSupportUser: json['is_support_user'] as bool?,
  isNewUser: json['is_new_user'] as bool?,
  supportFriendAdded: json['support_friend_added'] as bool?,
  weightUnit: json['weight_unit'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'name': instance.name,
  'email': instance.email,
  'fitness_level': instance.fitnessLevel,
  'goals': instance.goals,
  'equipment': instance.equipment,
  'preferences': instance.preferences,
  'active_injuries': instance.activeInjuries,
  'height_cm': instance.heightCm,
  'weight_kg': instance.weightKg,
  'target_weight_kg': instance.targetWeightKg,
  'age': instance.age,
  'date_of_birth': instance.dateOfBirth,
  'gender': instance.gender,
  'activity_level': instance.activityLevel,
  'onboarding_completed': instance.onboardingCompleted,
  'coach_selected': instance.coachSelected,
  'paywall_completed': instance.paywallCompleted,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
  'timezone': instance.timezone,
  'role': instance.role,
  'is_support_user': instance.isSupportUser,
  'is_new_user': instance.isNewUser,
  'support_friend_added': instance.supportFriendAdded,
  'weight_unit': instance.weightUnit,
};

GoogleAuthRequest _$GoogleAuthRequestFromJson(Map<String, dynamic> json) =>
    GoogleAuthRequest(accessToken: json['access_token'] as String);

Map<String, dynamic> _$GoogleAuthRequestToJson(GoogleAuthRequest instance) =>
    <String, dynamic>{'access_token': instance.accessToken};
