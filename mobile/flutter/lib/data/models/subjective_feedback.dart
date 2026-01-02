import 'package:flutter/material.dart';

/// Subjective feedback for tracking how users "feel" before and after workouts.
/// Enables insights like "Your mood improved 23% since starting".
class SubjectiveFeedback {
  final String? id;
  final String userId;
  final String? workoutId;

  // Pre-workout check-in (1-5 scale)
  final int? moodBefore;
  final int? energyBefore;
  final int? sleepQuality;
  final int? stressLevel;

  // Post-workout check-in (1-5 scale)
  final int? moodAfter;
  final int? energyAfter;
  final int? confidenceLevel;
  final int? sorenessLevel;

  // Qualitative
  final bool feelingStronger;
  final String? notes;

  // Timestamps
  final DateTime? preCheckinAt;
  final DateTime? postCheckinAt;
  final DateTime? createdAt;

  // Computed
  final int? moodChange;

  const SubjectiveFeedback({
    this.id,
    required this.userId,
    this.workoutId,
    this.moodBefore,
    this.energyBefore,
    this.sleepQuality,
    this.stressLevel,
    this.moodAfter,
    this.energyAfter,
    this.confidenceLevel,
    this.sorenessLevel,
    this.feelingStronger = false,
    this.notes,
    this.preCheckinAt,
    this.postCheckinAt,
    this.createdAt,
    this.moodChange,
  });

  factory SubjectiveFeedback.fromJson(Map<String, dynamic> json) {
    return SubjectiveFeedback(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      workoutId: json['workout_id'] as String?,
      moodBefore: json['mood_before'] as int?,
      energyBefore: json['energy_before'] as int?,
      sleepQuality: json['sleep_quality'] as int?,
      stressLevel: json['stress_level'] as int?,
      moodAfter: json['mood_after'] as int?,
      energyAfter: json['energy_after'] as int?,
      confidenceLevel: json['confidence_level'] as int?,
      sorenessLevel: json['soreness_level'] as int?,
      feelingStronger: json['feeling_stronger'] as bool? ?? false,
      notes: json['notes'] as String?,
      preCheckinAt: json['pre_checkin_at'] != null
          ? DateTime.parse(json['pre_checkin_at'] as String)
          : null,
      postCheckinAt: json['post_checkin_at'] != null
          ? DateTime.parse(json['post_checkin_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      moodChange: json['mood_change'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      if (workoutId != null) 'workout_id': workoutId,
      if (moodBefore != null) 'mood_before': moodBefore,
      if (energyBefore != null) 'energy_before': energyBefore,
      if (sleepQuality != null) 'sleep_quality': sleepQuality,
      if (stressLevel != null) 'stress_level': stressLevel,
      if (moodAfter != null) 'mood_after': moodAfter,
      if (energyAfter != null) 'energy_after': energyAfter,
      if (confidenceLevel != null) 'confidence_level': confidenceLevel,
      if (sorenessLevel != null) 'soreness_level': sorenessLevel,
      'feeling_stronger': feelingStronger,
      if (notes != null) 'notes': notes,
    };
  }

  SubjectiveFeedback copyWith({
    String? id,
    String? userId,
    String? workoutId,
    int? moodBefore,
    int? energyBefore,
    int? sleepQuality,
    int? stressLevel,
    int? moodAfter,
    int? energyAfter,
    int? confidenceLevel,
    int? sorenessLevel,
    bool? feelingStronger,
    String? notes,
    DateTime? preCheckinAt,
    DateTime? postCheckinAt,
    DateTime? createdAt,
    int? moodChange,
  }) {
    return SubjectiveFeedback(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      workoutId: workoutId ?? this.workoutId,
      moodBefore: moodBefore ?? this.moodBefore,
      energyBefore: energyBefore ?? this.energyBefore,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      stressLevel: stressLevel ?? this.stressLevel,
      moodAfter: moodAfter ?? this.moodAfter,
      energyAfter: energyAfter ?? this.energyAfter,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      sorenessLevel: sorenessLevel ?? this.sorenessLevel,
      feelingStronger: feelingStronger ?? this.feelingStronger,
      notes: notes ?? this.notes,
      preCheckinAt: preCheckinAt ?? this.preCheckinAt,
      postCheckinAt: postCheckinAt ?? this.postCheckinAt,
      createdAt: createdAt ?? this.createdAt,
      moodChange: moodChange ?? this.moodChange,
    );
  }
}

/// Response model for subjective trends over time.
class SubjectiveTrendsResponse {
  final String userId;
  final int periodDays;
  final int totalWorkouts;

  // Averages
  final double avgMoodBefore;
  final double avgMoodAfter;
  final double avgMoodChange;
  final double avgEnergyBefore;
  final double avgEnergyAfter;
  final double avgSleepQuality;
  final double avgConfidence;

  // Trends over time (positive = improving)
  final double moodTrendPercent;
  final double energyTrendPercent;
  final double confidenceTrendPercent;

  // Weekly breakdown
  final List<WeeklySubjectiveData> weeklyData;

  // Insights
  final int feelingStrongerCount;
  final double feelingStrongerPercent;

  const SubjectiveTrendsResponse({
    required this.userId,
    required this.periodDays,
    required this.totalWorkouts,
    required this.avgMoodBefore,
    required this.avgMoodAfter,
    required this.avgMoodChange,
    required this.avgEnergyBefore,
    required this.avgEnergyAfter,
    required this.avgSleepQuality,
    required this.avgConfidence,
    required this.moodTrendPercent,
    required this.energyTrendPercent,
    required this.confidenceTrendPercent,
    required this.weeklyData,
    required this.feelingStrongerCount,
    required this.feelingStrongerPercent,
  });

  factory SubjectiveTrendsResponse.fromJson(Map<String, dynamic> json) {
    final weeklyList = json['weekly_data'] as List<dynamic>? ?? [];
    return SubjectiveTrendsResponse(
      userId: json['user_id'] as String,
      periodDays: json['period_days'] as int,
      totalWorkouts: json['total_workouts'] as int,
      avgMoodBefore: (json['avg_mood_before'] as num).toDouble(),
      avgMoodAfter: (json['avg_mood_after'] as num).toDouble(),
      avgMoodChange: (json['avg_mood_change'] as num).toDouble(),
      avgEnergyBefore: (json['avg_energy_before'] as num).toDouble(),
      avgEnergyAfter: (json['avg_energy_after'] as num).toDouble(),
      avgSleepQuality: (json['avg_sleep_quality'] as num).toDouble(),
      avgConfidence: (json['avg_confidence'] as num).toDouble(),
      moodTrendPercent: (json['mood_trend_percent'] as num).toDouble(),
      energyTrendPercent: (json['energy_trend_percent'] as num).toDouble(),
      confidenceTrendPercent: (json['confidence_trend_percent'] as num).toDouble(),
      weeklyData: weeklyList
          .map((w) => WeeklySubjectiveData.fromJson(w as Map<String, dynamic>))
          .toList(),
      feelingStrongerCount: json['feeling_stronger_count'] as int,
      feelingStrongerPercent: (json['feeling_stronger_percent'] as num).toDouble(),
    );
  }
}

/// Weekly breakdown of subjective data.
class WeeklySubjectiveData {
  final int week;
  final String weekStart;
  final int workoutCount;
  final double avgMood;
  final double avgEnergy;

  const WeeklySubjectiveData({
    required this.week,
    required this.weekStart,
    required this.workoutCount,
    required this.avgMood,
    required this.avgEnergy,
  });

  factory WeeklySubjectiveData.fromJson(Map<String, dynamic> json) {
    return WeeklySubjectiveData(
      week: json['week'] as int,
      weekStart: json['week_start'] as String,
      workoutCount: json['workout_count'] as int,
      avgMood: (json['avg_mood'] as num).toDouble(),
      avgEnergy: (json['avg_energy'] as num).toDouble(),
    );
  }
}

/// High-level summary for "Feel Results" screen.
class FeelResultsSummary {
  final String userId;
  final int totalWorkoutsTracked;

  // Headline metrics
  final double moodImprovementPercent;
  final double avgPostWorkoutMood;
  final double avgPostWorkoutEnergy;
  final double feelingStrongerPercent;

  // Motivational insights
  final String insightHeadline;
  final String insightDetail;

  // Patterns
  final String? bestWorkoutDay;
  final String? bestTimeOfDay;
  final double moodBoostFromExercise;

  const FeelResultsSummary({
    required this.userId,
    required this.totalWorkoutsTracked,
    required this.moodImprovementPercent,
    required this.avgPostWorkoutMood,
    required this.avgPostWorkoutEnergy,
    required this.feelingStrongerPercent,
    required this.insightHeadline,
    required this.insightDetail,
    this.bestWorkoutDay,
    this.bestTimeOfDay,
    required this.moodBoostFromExercise,
  });

  factory FeelResultsSummary.fromJson(Map<String, dynamic> json) {
    return FeelResultsSummary(
      userId: json['user_id'] as String,
      totalWorkoutsTracked: json['total_workouts_tracked'] as int,
      moodImprovementPercent: (json['mood_improvement_percent'] as num).toDouble(),
      avgPostWorkoutMood: (json['avg_post_workout_mood'] as num).toDouble(),
      avgPostWorkoutEnergy: (json['avg_post_workout_energy'] as num).toDouble(),
      feelingStrongerPercent: (json['feeling_stronger_percent'] as num).toDouble(),
      insightHeadline: json['insight_headline'] as String,
      insightDetail: json['insight_detail'] as String,
      bestWorkoutDay: json['best_workout_day'] as String?,
      bestTimeOfDay: json['best_time_of_day'] as String?,
      moodBoostFromExercise: (json['mood_boost_from_exercise'] as num).toDouble(),
    );
  }

  bool get hasData => totalWorkoutsTracked > 0;
}

/// Quick stats for home screen widgets.
class SubjectiveQuickStats {
  final bool hasData;
  final int totalCheckins;
  final double? avgMoodAfter;
  final double? moodTrend;
  final double? feelingStrongerRate;

  const SubjectiveQuickStats({
    required this.hasData,
    required this.totalCheckins,
    this.avgMoodAfter,
    this.moodTrend,
    this.feelingStrongerRate,
  });

  factory SubjectiveQuickStats.fromJson(Map<String, dynamic> json) {
    return SubjectiveQuickStats(
      hasData: json['has_data'] as bool,
      totalCheckins: json['total_checkins'] as int,
      avgMoodAfter: json['avg_mood_after'] != null
          ? (json['avg_mood_after'] as num).toDouble()
          : null,
      moodTrend: json['mood_trend'] != null
          ? (json['mood_trend'] as num).toDouble()
          : null,
      feelingStrongerRate: json['feeling_stronger_rate'] != null
          ? (json['feeling_stronger_rate'] as num).toDouble()
          : null,
    );
  }
}

/// Emoji and label helpers for mood levels.
extension MoodLevelExtension on int {
  String get moodEmoji {
    switch (this) {
      case 1:
        return '\u{1F625}'; // Crying face
      case 2:
        return '\u{1F641}'; // Slightly frowning face
      case 3:
        return '\u{1F610}'; // Neutral face
      case 4:
        return '\u{1F642}'; // Slightly smiling face
      case 5:
        return '\u{1F604}'; // Grinning face
      default:
        return '\u{1F610}';
    }
  }

  String get moodLabel {
    switch (this) {
      case 1:
        return 'Awful';
      case 2:
        return 'Low';
      case 3:
        return 'Okay';
      case 4:
        return 'Good';
      case 5:
        return 'Great';
      default:
        return 'Unknown';
    }
  }

  String get energyEmoji {
    switch (this) {
      case 1:
        return '\u{1F634}'; // Sleeping face
      case 2:
        return '\u{1F971}'; // Yawning face
      case 3:
        return '\u{1F610}'; // Neutral face
      case 4:
        return '\u{26A1}'; // Lightning
      case 5:
        return '\u{1F525}'; // Fire
      default:
        return '\u{1F610}';
    }
  }

  String get energyLabel {
    switch (this) {
      case 1:
        return 'Exhausted';
      case 2:
        return 'Tired';
      case 3:
        return 'Okay';
      case 4:
        return 'Energized';
      case 5:
        return 'Pumped';
      default:
        return 'Unknown';
    }
  }

  String get sleepEmoji {
    switch (this) {
      case 1:
        return '\u{1F62B}'; // Tired face
      case 2:
        return '\u{1F634}'; // Sleeping face
      case 3:
        return '\u{1F610}'; // Neutral
      case 4:
        return '\u{1F31F}'; // Star
      case 5:
        return '\u{1F4AB}'; // Dizzy (good sleep)
      default:
        return '\u{1F610}';
    }
  }

  String get sleepLabel {
    switch (this) {
      case 1:
        return 'Terrible';
      case 2:
        return 'Poor';
      case 3:
        return 'Okay';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent';
      default:
        return 'Unknown';
    }
  }

  Color get moodColor {
    switch (this) {
      case 1:
        return const Color(0xFFE53935); // Red
      case 2:
        return const Color(0xFFFF9800); // Orange
      case 3:
        return const Color(0xFFFFEB3B); // Yellow
      case 4:
        return const Color(0xFF8BC34A); // Light green
      case 5:
        return const Color(0xFF4CAF50); // Green
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }
}
