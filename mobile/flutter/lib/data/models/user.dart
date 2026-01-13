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
  @JsonKey(name: 'coach_selected')
  final bool? coachSelected;
  @JsonKey(name: 'paywall_completed')
  final bool? paywallCompleted;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  final String? timezone; // IANA timezone identifier (e.g., America/New_York)
  final String? role; // 'user', 'admin', or 'super_admin'
  @JsonKey(name: 'is_support_user')
  final bool? isSupportUser; // True for support@fitwiz.us (cannot be unfriended)
  @JsonKey(name: 'weight_unit')
  final String? weightUnit; // 'kg' or 'lbs' - user's preferred weight unit

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
    this.coachSelected,
    this.paywallCompleted,
    this.createdAt,
    this.updatedAt,
    this.timezone,
    this.role,
    this.isSupportUser,
    this.weightUnit,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  /// Parse goals from JSON string or plain string
  List<String> get goalsList {
    if (goals == null || goals!.isEmpty) return [];
    try {
      final decoded = jsonDecode(goals!);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
      // If decoded is a string, return it as a single-item list
      if (decoded is String) {
        return [decoded];
      }
      return [];
    } catch (_) {
      // If JSON parsing fails, treat goals as a plain string
      return [goals!];
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

  /// Check if coach has been selected
  bool get isCoachSelected => coachSelected == true;

  /// Check if paywall has been completed (shown/dismissed)
  bool get isPaywallComplete => paywallCompleted == true;

  /// Check if user is an admin
  bool get isAdmin => role == 'admin' || role == 'super_admin';

  /// Check if user is a super admin
  bool get isSuperAdmin => role == 'super_admin';

  /// Check if user is the support account (cannot be unfriended)
  bool get isSupport => isSupportUser == true;

  /// Get weight unit preference with fallback to 'kg'
  /// Checks weightUnit field first, then preferences JSON, then defaults to 'kg'
  String get preferredWeightUnit {
    // Direct field first
    if (weightUnit != null && weightUnit!.isNotEmpty) {
      return weightUnit!;
    }
    // Try preferences JSON
    if (preferences != null && preferences!.isNotEmpty) {
      try {
        final decoded = jsonDecode(preferences!);
        if (decoded is Map && decoded['weight_unit'] != null) {
          return decoded['weight_unit'] as String;
        }
      } catch (_) {}
    }
    // Default to kg
    return 'kg';
  }

  /// Check if user prefers metric (kg) units
  bool get usesMetricWeight => preferredWeightUnit == 'kg';

  /// Check if user prefers imperial (lbs) units
  bool get usesImperialWeight => preferredWeightUnit == 'lbs';

  /// Get photo URL (placeholder for now - would come from auth provider)
  String? get photoUrl => null;

  /// Get fitness goal (first goal from goals list, formatted for display)
  String? get fitnessGoal {
    final goals = goalsList;
    if (goals.isEmpty) return null;
    // Convert goal ID to user-friendly display name
    const goalDisplayNames = {
      'build_muscle': 'Build Muscle',
      'lose_weight': 'Lose Weight',
      'lose_fat': 'Lose Fat',
      'improve_endurance': 'Improve Endurance',
      'increase_strength': 'Increase Strength',
      'improve_flexibility': 'Improve Flexibility',
      'stay_active': 'Stay Active',
      'mental_health': 'Mental Health',
      'sport_performance': 'Sport Performance',
      'general_fitness': 'General Fitness',
      'tone_up': 'Tone Up',
      'gain_muscle': 'Gain Muscle',
    };
    final firstGoal = goals.first;
    return goalDisplayNames[firstGoal] ?? firstGoal;
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

  /// Get workout duration in minutes from preferences
  int? get workoutDuration {
    if (preferences == null || preferences!.isEmpty) return null;
    try {
      final decoded = jsonDecode(preferences!);
      if (decoded is Map && decoded['workout_duration'] != null) {
        return decoded['workout_duration'] as int;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get workout duration as formatted display string
  String get workoutDurationDisplay {
    final duration = workoutDuration;
    if (duration == null) return 'Not set';
    return '$duration min';
  }

  /// Get workout days from preferences (0=Mon, 6=Sun)
  List<int> get workoutDays {
    if (preferences == null || preferences!.isEmpty) return [];
    try {
      final decoded = jsonDecode(preferences!);
      if (decoded is Map) {
        // Try workout_days first, then selected_days as fallback
        final days = decoded['workout_days'] ?? decoded['selected_days'];
        if (days is List && days.isNotEmpty) {
          // Handle both int indices and string day names
          if (days.first is int || (days.first is String && int.tryParse(days.first) != null)) {
            // Int indices (e.g., [0, 2, 4])
            return days.map((e) => e is int ? e : int.parse(e.toString())).toList().cast<int>()..sort();
          } else if (days.first is String) {
            // String day names (e.g., ["Mon", "Wed", "Fri"])
            const dayMap = {'Mon': 0, 'Tue': 1, 'Wed': 2, 'Thu': 3, 'Fri': 4, 'Sat': 5, 'Sun': 6};
            return days.map((e) => dayMap[e] ?? -1).where((i) => i >= 0).toList().cast<int>()..sort();
          }
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

  /// Check if today is the last workout day of the week
  /// Returns true if today is a workout day and there are no more workout days after today this week
  bool get isLastWorkoutDayOfWeek {
    final days = workoutDays;
    if (days.isEmpty) return false;

    // DateTime.weekday: 1=Monday, 7=Sunday
    // workoutDays uses 0=Monday, 6=Sunday
    final todayIndex = DateTime.now().weekday - 1; // Convert to 0-indexed

    // Check if today is a workout day
    if (!days.contains(todayIndex)) return false;

    // Check if there are any workout days after today this week
    final remainingDays = days.where((d) => d > todayIndex).toList();
    return remainingDays.isEmpty;
  }

  /// Get remaining workout days this week (including today if not completed)
  /// Returns list of day indices (0=Mon, 6=Sun)
  List<int> get remainingWorkoutDaysThisWeek {
    final days = workoutDays;
    if (days.isEmpty) return [];

    final todayIndex = DateTime.now().weekday - 1; // 0=Monday

    // Include today and all days after today
    return days.where((d) => d >= todayIndex).toList();
  }

  /// Get the count of workouts to generate for smart generation
  /// If it's the last workout day, includes next week's workouts
  int getSmartGenerationCount({bool includeNextWeekOnLastDay = true}) {
    final days = workoutDays;
    if (days.isEmpty) return 0;

    final remaining = remainingWorkoutDaysThisWeek;

    if (includeNextWeekOnLastDay && isLastWorkoutDayOfWeek) {
      // Add next week's workout days
      return remaining.length + days.length;
    }

    return remaining.length;
  }

  /// Get training experience from preferences
  String? get trainingExperience {
    if (preferences == null || preferences!.isEmpty) return null;
    try {
      final decoded = jsonDecode(preferences!);
      if (decoded is Map && decoded['training_experience'] != null) {
        return decoded['training_experience'] as String;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get training experience as display text
  String get trainingExperienceDisplay {
    final exp = trainingExperience;
    if (exp == null) return 'Not set';
    switch (exp) {
      case 'never':
        return 'Never lifted';
      case 'less_than_6_months':
        return 'Less than 6 months';
      case '6_months_to_2_years':
        return '6 months - 2 years';
      case '2_to_5_years':
        return '2-5 years';
      case '5_plus_years':
        return '5+ years';
      default:
        return exp;
    }
  }

  /// Get workout environment from preferences (or infer from equipment)
  String? get workoutEnvironment {
    if (preferences == null || preferences!.isEmpty) {
      // If no preferences, try to infer from equipment
      return _inferWorkoutEnvironmentFromEquipment();
    }
    try {
      final decoded = jsonDecode(preferences!);
      if (decoded is Map && decoded['workout_environment'] != null) {
        return decoded['workout_environment'] as String;
      }
      // If workout_environment not in preferences, try to infer from equipment
      return _inferWorkoutEnvironmentFromEquipment();
    } catch (_) {
      return _inferWorkoutEnvironmentFromEquipment();
    }
  }

  /// Infer workout environment from equipment list
  String? _inferWorkoutEnvironmentFromEquipment() {
    final equip = equipmentList;
    if (equip.isEmpty) return null;

    if (equip.contains('full_gym') ||
        (equip.contains('barbell') && equip.contains('cable_machine'))) {
      return 'commercial_gym';
    }
    if (equip.contains('barbell') || equip.contains('cable_machine')) {
      return 'home_gym';
    }
    if (equip.contains('dumbbells') || equip.contains('kettlebell') || equip.contains('resistance_bands')) {
      return 'home';
    }
    if (equip.contains('bodyweight')) {
      return 'home';
    }
    return null;
  }

  /// Get workout environment as display text
  String get workoutEnvironmentDisplay {
    final env = workoutEnvironment;
    if (env == null) return 'Not set';
    switch (env) {
      case 'commercial_gym':
        return 'Commercial Gym';
      case 'home_gym':
        return 'Home Gym';
      case 'home':
        return 'Home (Minimal)';
      case 'outdoors':
        return 'Outdoors';
      case 'hotel':
        return 'Hotel/Travel';
      case 'apartment_gym':
        return 'Apartment Gym';
      case 'office_gym':
        return 'Office Gym';
      case 'custom':
        return 'Custom Setup';
      default:
        return env;
    }
  }

  /// Get focus areas from preferences
  List<String> get focusAreas {
    if (preferences == null || preferences!.isEmpty) return [];
    try {
      final decoded = jsonDecode(preferences!);
      if (decoded is Map && decoded['focus_areas'] != null) {
        final areas = decoded['focus_areas'];
        if (areas is List) {
          return areas.map((e) => e.toString()).toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Get focus areas as display text
  String get focusAreasDisplay {
    final areas = focusAreas;
    if (areas.isEmpty) return 'Full body';
    return areas.map((a) {
      switch (a) {
        case 'chest':
          return 'Chest';
        case 'back':
          return 'Back';
        case 'shoulders':
          return 'Shoulders';
        case 'arms':
          return 'Arms';
        case 'core':
          return 'Core';
        case 'legs':
          return 'Legs';
        case 'glutes':
          return 'Glutes';
        case 'full_body':
          return 'Full Body';
        default:
          return a;
      }
    }).join(', ');
  }

  /// Get motivation from preferences (checks both 'motivation' and 'motivations')
  String? get motivation {
    if (preferences == null || preferences!.isEmpty) return null;
    try {
      final decoded = jsonDecode(preferences!);
      if (decoded is Map) {
        // Check for singular 'motivation' first
        if (decoded['motivation'] != null) {
          return decoded['motivation'] as String;
        }
        // Fall back to 'motivations' (plural) - take first item if it's a list
        if (decoded['motivations'] != null) {
          final motivations = decoded['motivations'];
          if (motivations is List && motivations.isNotEmpty) {
            return motivations.first.toString();
          }
          if (motivations is String) {
            return motivations;
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get all motivations from preferences as a list
  List<String> get motivationsList {
    if (preferences == null || preferences!.isEmpty) return [];
    try {
      final decoded = jsonDecode(preferences!);
      if (decoded is Map && decoded['motivations'] != null) {
        final motivations = decoded['motivations'];
        if (motivations is List) {
          return motivations.map((e) => e.toString()).toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Get motivation as display text
  String get motivationDisplay {
    final mots = motivationsList;
    if (mots.isEmpty) {
      final mot = motivation;
      if (mot == null) return 'Not set';
      return _formatMotivation(mot);
    }
    // Display up to 2 motivations
    return mots.take(2).map(_formatMotivation).join(', ');
  }

  String _formatMotivation(String mot) {
    switch (mot) {
      case 'seeing_progress':
        return 'Seeing progress';
      case 'feeling_stronger':
      case 'feel_stronger':
        return 'Feeling stronger';
      case 'looking_better':
      case 'look_better':
        return 'Looking better';
      case 'health_improvements':
        return 'Health improvements';
      case 'stress_relief':
        return 'Stress relief';
      case 'social':
        return 'Social/accountability';
      case 'more_energy':
        return 'More energy';
      case 'confidence':
        return 'Confidence';
      case 'longevity':
        return 'Longevity';
      default:
        return mot.replaceAll('_', ' ');
    }
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
        coachSelected,
        paywallCompleted,
        timezone,
        role,
        isSupportUser,
        weightUnit,
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
    bool? coachSelected,
    bool? paywallCompleted,
    String? createdAt,
    String? updatedAt,
    String? timezone,
    String? role,
    bool? isSupportUser,
    String? weightUnit,
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
      coachSelected: coachSelected ?? this.coachSelected,
      paywallCompleted: paywallCompleted ?? this.paywallCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      timezone: timezone ?? this.timezone,
      role: role ?? this.role,
      isSupportUser: isSupportUser ?? this.isSupportUser,
      weightUnit: weightUnit ?? this.weightUnit,
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
