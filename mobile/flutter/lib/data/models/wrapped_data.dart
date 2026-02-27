class WrappedData {
  final String periodKey;
  final Map<String, dynamic> stats;
  final Map<String, dynamic>? aiPersonality;
  final DateTime? createdAt;

  const WrappedData({
    required this.periodKey,
    required this.stats,
    this.aiPersonality,
    this.createdAt,
  });

  factory WrappedData.fromJson(Map<String, dynamic> json) {
    return WrappedData(
      periodKey: json['period_key'] as String,
      stats: json['stats'] as Map<String, dynamic>,
      aiPersonality: json['ai_personality'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  // Helper getters for common stats
  int get totalWorkouts => (stats['total_workouts'] as num?)?.toInt() ?? 0;
  int get totalDurationMinutes =>
      (stats['total_duration_minutes'] as num?)?.toInt() ?? 0;
  double get totalVolumeLbs =>
      (stats['total_volume_lbs'] as num?)?.toDouble() ?? 0;
  int get totalExercises =>
      (stats['total_exercises'] as num?)?.toInt() ?? 0;
  int get totalSets => (stats['total_sets'] as num?)?.toInt() ?? 0;
  int get totalReps => (stats['total_reps'] as num?)?.toInt() ?? 0;
  String get favoriteExercise =>
      stats['favorite_exercise'] as String? ?? 'N/A';
  String get favoriteMuscleGroup =>
      stats['favorite_muscle_group'] as String? ?? 'N/A';
  int get longestWorkoutMinutes =>
      (stats['longest_workout_minutes'] as num?)?.toInt() ?? 0;
  int get personalRecordsCount =>
      (stats['personal_records_count'] as num?)?.toInt() ?? 0;
  Map<String, dynamic>? get bestPr =>
      stats['best_pr'] as Map<String, dynamic>?;
  int get streakBest => (stats['streak_best'] as num?)?.toInt() ?? 0;
  int get streakCurrent => (stats['streak_current'] as num?)?.toInt() ?? 0;
  int get totalCaloriesLogged =>
      (stats['total_calories_logged'] as num?)?.toInt() ?? 0;
  double get avgProteinG =>
      (stats['avg_protein_g'] as num?)?.toDouble() ?? 0;
  String get mostActiveDayOfWeek =>
      stats['most_active_day_of_week'] as String? ?? 'N/A';
  int get mostActiveHour =>
      (stats['most_active_hour'] as num?)?.toInt() ?? 0;
  double get workoutConsistencyPct =>
      (stats['workout_consistency_pct'] as num?)?.toDouble() ?? 0;
  int get socialReactionsReceived =>
      (stats['social_reactions_received'] as num?)?.toInt() ?? 0;
  int get socialPostsCount =>
      (stats['social_posts_count'] as num?)?.toInt() ?? 0;
  int get xpEarned => (stats['xp_earned'] as num?)?.toInt() ?? 0;

  // AI personality getters
  String get fitnessPersonality =>
      aiPersonality?['fitness_personality'] as String? ?? 'Fitness Warrior';
  String get personalityDescription =>
      aiPersonality?['personality_description'] as String? ?? '';
  String get funFact => aiPersonality?['fun_fact'] as String? ?? '';
  String get motivationQuote =>
      aiPersonality?['motivation_quote'] as String? ?? '';

  // Helper: month display name
  String get monthDisplayName {
    final parts = periodKey.split('-');
    if (parts.length != 2) return periodKey;
    final month = int.tryParse(parts[1]) ?? 1;
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month - 1];
  }

  String get yearDisplay {
    final parts = periodKey.split('-');
    return parts.isNotEmpty ? parts[0] : '';
  }
}
