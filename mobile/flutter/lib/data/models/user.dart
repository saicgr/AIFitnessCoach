import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User extends Equatable {
  final String id;
  final String? username;
  final String? name;
  final String? email;
  @JsonKey(name: 'fitness_level')
  final String? fitnessLevel;
  final String? goals; // JSON string
  final String? equipment; // JSON string
  final String? preferences; // JSON string
  @JsonKey(name: 'active_injuries')
  final String? activeInjuries; // JSON string
  @JsonKey(name: 'height_cm')
  final double? heightCm;
  @JsonKey(name: 'weight_kg')
  final double? weightKg;
  @JsonKey(name: 'target_weight_kg')
  final double? targetWeightKg;
  final int? age;
  @JsonKey(name: 'date_of_birth')
  final String? dateOfBirth;
  final String? gender;
  @JsonKey(name: 'activity_level')
  final String? activityLevel;
  @JsonKey(name: 'onboarding_completed')
  final bool? onboardingCompleted;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  const User({
    required this.id,
    this.username,
    this.name,
    this.email,
    this.fitnessLevel,
    this.goals,
    this.equipment,
    this.preferences,
    this.activeInjuries,
    this.heightCm,
    this.weightKg,
    this.targetWeightKg,
    this.age,
    this.dateOfBirth,
    this.gender,
    this.activityLevel,
    this.onboardingCompleted,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  /// Parse goals from JSON string
  List<String> get goalsList {
    if (goals == null || goals!.isEmpty) return [];
    try {
      final decoded = jsonDecode(goals!);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Parse equipment from JSON string
  List<String> get equipmentList {
    if (equipment == null || equipment!.isEmpty) return [];
    try {
      final decoded = jsonDecode(equipment!);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Parse active injuries from JSON string
  List<String> get injuriesList {
    if (activeInjuries == null || activeInjuries!.isEmpty) return [];
    try {
      final decoded = jsonDecode(activeInjuries!);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Get display name
  String get displayName => name ?? username ?? 'User';

  /// Check if onboarding is done
  bool get isOnboardingComplete => onboardingCompleted == true;

  /// Get photo URL (placeholder for now - would come from auth provider)
  String? get photoUrl => null;

  /// Get fitness goal (first goal from goals list)
  String? get fitnessGoal {
    final goals = goalsList;
    return goals.isNotEmpty ? goals.first : null;
  }

  /// Get workouts per week from preferences
  int? get workoutsPerWeek {
    if (preferences == null || preferences!.isEmpty) return null;
    try {
      final decoded = jsonDecode(preferences!);
      if (decoded is Map && decoded['workouts_per_week'] != null) {
        return decoded['workouts_per_week'] as int;
      }
      // Fall back to workout_days length if available
      if (decoded is Map && decoded['workout_days'] != null) {
        final days = decoded['workout_days'];
        if (days is List) return days.length;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get workout days from preferences (0=Mon, 6=Sun)
  List<int> get workoutDays {
    if (preferences == null || preferences!.isEmpty) return [];
    try {
      final decoded = jsonDecode(preferences!);
      if (decoded is Map && decoded['workout_days'] != null) {
        final days = decoded['workout_days'];
        if (days is List) {
          return days.map((e) => e as int).toList()..sort();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Get workout days as abbreviated day names (Mon, Tue, etc.)
  List<String> get workoutDayNames {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final days = workoutDays;
    if (days.isEmpty) return [];
    return days.map((d) => d >= 0 && d < 7 ? dayNames[d] : '').where((s) => s.isNotEmpty).toList();
  }

  /// Get workout days as formatted string (e.g., "Mon, Wed, Fri")
  String get workoutDaysFormatted {
    final names = workoutDayNames;
    if (names.isEmpty) return 'Not set';
    return names.join(', ');
  }

  @override
  List<Object?> get props => [
        id,
        username,
        name,
        email,
        fitnessLevel,
        goals,
        equipment,
        onboardingCompleted,
      ];

  User copyWith({
    String? id,
    String? username,
    String? name,
    String? email,
    String? fitnessLevel,
    String? goals,
    String? equipment,
    String? preferences,
    String? activeInjuries,
    double? heightCm,
    double? weightKg,
    double? targetWeightKg,
    int? age,
    String? dateOfBirth,
    String? gender,
    String? activityLevel,
    bool? onboardingCompleted,
    String? createdAt,
    String? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      email: email ?? this.email,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      goals: goals ?? this.goals,
      equipment: equipment ?? this.equipment,
      preferences: preferences ?? this.preferences,
      activeInjuries: activeInjuries ?? this.activeInjuries,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      age: age ?? this.age,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Request model for Google auth
@JsonSerializable()
class GoogleAuthRequest {
  @JsonKey(name: 'access_token')
  final String accessToken;

  const GoogleAuthRequest({required this.accessToken});

  factory GoogleAuthRequest.fromJson(Map<String, dynamic> json) =>
      _$GoogleAuthRequestFromJson(json);
  Map<String, dynamic> toJson() => _$GoogleAuthRequestToJson(this);
}
