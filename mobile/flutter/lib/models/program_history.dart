/// Represents a snapshot of a user's workout program configuration
class ProgramHistory {
  final String id;
  final String userId;
  final Map<String, dynamic> preferences;
  final List<String> equipment;
  final List<String> injuries;
  final List<String> focusAreas;
  final String? programName;
  final String? description;
  final bool isCurrent;
  final String createdAt;
  final String? appliedAt;
  final int totalWorkoutsCompleted;
  final String? lastWorkoutDate;

  const ProgramHistory({
    required this.id,
    required this.userId,
    required this.preferences,
    this.equipment = const [],
    this.injuries = const [],
    this.focusAreas = const [],
    this.programName,
    this.description,
    this.isCurrent = false,
    required this.createdAt,
    this.appliedAt,
    this.totalWorkoutsCompleted = 0,
    this.lastWorkoutDate,
  });

  factory ProgramHistory.fromJson(Map<String, dynamic> json) {
    return ProgramHistory(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      preferences: (json['preferences'] as Map<String, dynamic>?) ?? {},
      equipment: (json['equipment'] as List<dynamic>?)?.cast<String>() ?? [],
      injuries: (json['injuries'] as List<dynamic>?)?.cast<String>() ?? [],
      focusAreas: (json['focus_areas'] as List<dynamic>?)?.cast<String>() ?? [],
      programName: json['program_name'] as String?,
      description: json['description'] as String?,
      isCurrent: json['is_current'] as bool? ?? false,
      createdAt: json['created_at'] as String,
      appliedAt: json['applied_at'] as String?,
      totalWorkoutsCompleted: json['total_workouts_completed'] as int? ?? 0,
      lastWorkoutDate: json['last_workout_date'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'preferences': preferences,
      'equipment': equipment,
      'injuries': injuries,
      'focus_areas': focusAreas,
      'program_name': programName,
      'description': description,
      'is_current': isCurrent,
      'created_at': createdAt,
      'applied_at': appliedAt,
      'total_workouts_completed': totalWorkoutsCompleted,
      'last_workout_date': lastWorkoutDate,
    };
  }

  /// Get difficulty from preferences (easy/medium/hard)
  String? get difficulty => preferences['intensity_preference'] as String?;

  /// Get workout duration in minutes
  int? get durationMinutes => preferences['workout_duration'] as int?;

  /// Get selected workout days as indices (0=Mon, 1=Tue, etc.)
  List<int> get selectedDays {
    final days = preferences['selected_days'];
    if (days is List) {
      return days.cast<int>();
    }
    return [];
  }

  /// Get number of days per week
  int? get daysPerWeek => preferences['days_per_week'] as int?;

  /// Get training split (workout type)
  String? get trainingSplit => preferences['training_split'] as String?;

  /// Get dumbbell count
  int? get dumbbellCount => preferences['dumbbell_count'] as int?;

  /// Get kettlebell count
  int? get kettlebellCount => preferences['kettlebell_count'] as int?;

  /// Get day names from selected days
  List<String> get dayNames {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return selectedDays.map((i) => days[i]).toList();
  }

  /// Get formatted date string
  String get formattedDate {
    try {
      final date = DateTime.parse(createdAt);
      return '${date.month}/${date.day}/${date.year}';
    } catch (_) {
      return createdAt;
    }
  }

  /// Get display name (uses programName if available, otherwise generates one)
  String get displayName {
    if (programName != null && programName!.isNotEmpty) {
      return programName!;
    }

    // Generate a name from preferences
    final diff = difficulty ?? 'Custom';
    final days = daysPerWeek ?? selectedDays.length;
    return '$diff Program - $days days/week';
  }
}
