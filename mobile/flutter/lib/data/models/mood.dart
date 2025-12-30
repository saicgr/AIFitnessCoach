import 'package:flutter/material.dart';

/// Mood types for quick workout generation.
enum Mood {
  great('great', 'Great', 0xFF4CAF50),
  good('good', 'Good', 0xFF2196F3),
  tired('tired', 'Tired', 0xFFFF9800),
  stressed('stressed', 'Stressed', 0xFF9C27B0);

  const Mood(this.value, this.label, this.colorValue);

  final String value;
  final String label;
  final int colorValue;

  Color get color => Color(colorValue);

  String get emoji {
    switch (this) {
      case Mood.great:
        return '\u{1F525}'; // fire
      case Mood.good:
        return '\u{1F60A}'; // smiling face
      case Mood.tired:
        return '\u{1F634}'; // sleeping face
      case Mood.stressed:
        return '\u{1F624}'; // face with steam
    }
  }

  String get description {
    switch (this) {
      case Mood.great:
        return 'High energy, challenging workout';
      case Mood.good:
        return 'Balanced, effective workout';
      case Mood.tired:
        return 'Recovery, mobility focus';
      case Mood.stressed:
        return 'Stress-relief, flowing workout';
    }
  }

  /// Get Mood from string value.
  static Mood fromString(String value) {
    return Mood.values.firstWhere(
      (m) => m.value == value.toLowerCase(),
      orElse: () => Mood.good,
    );
  }
}

/// Mood check-in record from the backend.
class MoodCheckIn {
  final String? id;
  final String userId;
  final Mood mood;
  final DateTime? checkInTime;
  final bool workoutGenerated;
  final String? workoutId;
  final bool workoutCompleted;
  final Map<String, dynamic>? context;

  const MoodCheckIn({
    this.id,
    required this.userId,
    required this.mood,
    this.checkInTime,
    this.workoutGenerated = false,
    this.workoutId,
    this.workoutCompleted = false,
    this.context,
  });

  factory MoodCheckIn.fromJson(Map<String, dynamic> json) {
    return MoodCheckIn(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      mood: Mood.fromString(json['mood'] as String),
      checkInTime: json['check_in_time'] != null
          ? DateTime.parse(json['check_in_time'] as String)
          : null,
      workoutGenerated: json['workout_generated'] as bool? ?? false,
      workoutId: json['workout_id'] as String?,
      workoutCompleted: json['workout_completed'] as bool? ?? false,
      context: json['context'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'mood': mood.value,
      if (checkInTime != null) 'check_in_time': checkInTime!.toIso8601String(),
      'workout_generated': workoutGenerated,
      if (workoutId != null) 'workout_id': workoutId,
      'workout_completed': workoutCompleted,
      if (context != null) 'context': context,
    };
  }

  MoodCheckIn copyWith({
    String? id,
    String? userId,
    Mood? mood,
    DateTime? checkInTime,
    bool? workoutGenerated,
    String? workoutId,
    bool? workoutCompleted,
    Map<String, dynamic>? context,
  }) {
    return MoodCheckIn(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mood: mood ?? this.mood,
      checkInTime: checkInTime ?? this.checkInTime,
      workoutGenerated: workoutGenerated ?? this.workoutGenerated,
      workoutId: workoutId ?? this.workoutId,
      workoutCompleted: workoutCompleted ?? this.workoutCompleted,
      context: context ?? this.context,
    );
  }
}

/// Mood workout configuration from backend.
class MoodWorkoutConfig {
  final String mood;
  final String moodEmoji;
  final String moodColor;
  final int durationMinutes;
  final String intensityPreference;
  final String workoutTypePreference;

  const MoodWorkoutConfig({
    required this.mood,
    required this.moodEmoji,
    required this.moodColor,
    required this.durationMinutes,
    required this.intensityPreference,
    required this.workoutTypePreference,
  });

  factory MoodWorkoutConfig.fromJson(Map<String, dynamic> json) {
    return MoodWorkoutConfig(
      mood: json['mood'] as String,
      moodEmoji: json['mood_emoji'] as String,
      moodColor: json['mood_color'] as String,
      durationMinutes: json['duration_minutes'] as int,
      intensityPreference: json['intensity_preference'] as String,
      workoutTypePreference: json['workout_type_preference'] as String,
    );
  }
}

/// Available moods response from backend.
class MoodOption {
  final String value;
  final String emoji;
  final String color;
  final String label;
  final String description;

  const MoodOption({
    required this.value,
    required this.emoji,
    required this.color,
    required this.label,
    required this.description,
  });

  factory MoodOption.fromJson(Map<String, dynamic> json) {
    return MoodOption(
      value: json['value'] as String,
      emoji: json['emoji'] as String,
      color: json['color'] as String,
      label: json['label'] as String,
      description: json['description'] as String,
    );
  }

  Color get colorValue {
    final hex = color.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}

/// Mood history item from the backend.
class MoodHistoryItem {
  final String? id;
  final String mood;
  final String moodEmoji;
  final String moodColor;
  final DateTime? checkInTime;
  final bool workoutGenerated;
  final bool workoutCompleted;
  final MoodWorkoutSummary? workout;
  final Map<String, dynamic>? context;

  const MoodHistoryItem({
    this.id,
    required this.mood,
    required this.moodEmoji,
    required this.moodColor,
    this.checkInTime,
    this.workoutGenerated = false,
    this.workoutCompleted = false,
    this.workout,
    this.context,
  });

  factory MoodHistoryItem.fromJson(Map<String, dynamic> json) {
    return MoodHistoryItem(
      id: json['id'] as String?,
      mood: json['mood'] as String? ?? 'good',
      moodEmoji: json['mood_emoji'] as String? ?? '',
      moodColor: json['mood_color'] as String? ?? '#2196F3',
      checkInTime: json['check_in_time'] != null
          ? DateTime.parse(json['check_in_time'] as String)
          : null,
      workoutGenerated: json['workout_generated'] as bool? ?? false,
      workoutCompleted: json['workout_completed'] as bool? ?? false,
      workout: json['workout'] != null
          ? MoodWorkoutSummary.fromJson(json['workout'] as Map<String, dynamic>)
          : null,
      context: json['context'] as Map<String, dynamic>?,
    );
  }

  Color get color {
    final hex = moodColor.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  Mood get moodEnum => Mood.fromString(mood);
}

/// Summary of workout from mood check-in.
class MoodWorkoutSummary {
  final String? id;
  final String? name;
  final String? type;
  final String? difficulty;
  final bool? completed;

  const MoodWorkoutSummary({
    this.id,
    this.name,
    this.type,
    this.difficulty,
    this.completed,
  });

  factory MoodWorkoutSummary.fromJson(Map<String, dynamic> json) {
    return MoodWorkoutSummary(
      id: json['id'] as String?,
      name: json['name'] as String?,
      type: json['type'] as String?,
      difficulty: json['difficulty'] as String?,
      completed: json['completed'] as bool?,
    );
  }
}

/// Mood history response from the API.
class MoodHistoryResponse {
  final List<MoodHistoryItem> checkins;
  final int totalCount;
  final bool hasMore;

  const MoodHistoryResponse({
    required this.checkins,
    required this.totalCount,
    required this.hasMore,
  });

  factory MoodHistoryResponse.fromJson(Map<String, dynamic> json) {
    final checkinsJson = json['checkins'] as List<dynamic>? ?? [];
    return MoodHistoryResponse(
      checkins: checkinsJson
          .map((item) => MoodHistoryItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalCount: json['total_count'] as int? ?? 0,
      hasMore: json['has_more'] as bool? ?? false,
    );
  }
}

/// Mood analytics summary from the API.
class MoodAnalyticsSummary {
  final int totalCheckins;
  final int workoutsGenerated;
  final int workoutsCompleted;
  final double completionRate;
  final MoodFrequency? mostFrequentMood;
  final int daysTracked;

  const MoodAnalyticsSummary({
    this.totalCheckins = 0,
    this.workoutsGenerated = 0,
    this.workoutsCompleted = 0,
    this.completionRate = 0.0,
    this.mostFrequentMood,
    this.daysTracked = 30,
  });

  factory MoodAnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return MoodAnalyticsSummary(
      totalCheckins: json['total_checkins'] as int? ?? 0,
      workoutsGenerated: json['workouts_generated'] as int? ?? 0,
      workoutsCompleted: json['workouts_completed'] as int? ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0.0,
      mostFrequentMood: json['most_frequent_mood'] != null
          ? MoodFrequency.fromJson(json['most_frequent_mood'] as Map<String, dynamic>)
          : null,
      daysTracked: json['days_tracked'] as int? ?? 30,
    );
  }
}

/// Most frequent mood data.
class MoodFrequency {
  final String mood;
  final String emoji;
  final String color;
  final int count;

  const MoodFrequency({
    required this.mood,
    required this.emoji,
    required this.color,
    required this.count,
  });

  factory MoodFrequency.fromJson(Map<String, dynamic> json) {
    return MoodFrequency(
      mood: json['mood'] as String? ?? 'good',
      emoji: json['emoji'] as String? ?? '',
      color: json['color'] as String? ?? '#2196F3',
      count: json['count'] as int? ?? 0,
    );
  }

  Color get colorValue {
    final hex = color.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}

/// Mood distribution data.
class MoodDistribution {
  final String mood;
  final int count;
  final double percentage;
  final String emoji;

  const MoodDistribution({
    required this.mood,
    required this.count,
    required this.percentage,
    required this.emoji,
  });

  factory MoodDistribution.fromJson(Map<String, dynamic> json) {
    return MoodDistribution(
      mood: json['mood'] as String? ?? 'good',
      count: json['count'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      emoji: json['emoji'] as String? ?? '',
    );
  }
}

/// Mood pattern data.
class MoodPattern {
  final String type;
  final String title;
  final List<dynamic> data;

  const MoodPattern({
    required this.type,
    required this.title,
    required this.data,
  });

  factory MoodPattern.fromJson(Map<String, dynamic> json) {
    return MoodPattern(
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      data: json['data'] as List<dynamic>? ?? [],
    );
  }
}

/// Mood streak data.
class MoodStreaks {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCheckin;

  const MoodStreaks({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCheckin,
  });

  factory MoodStreaks.fromJson(Map<String, dynamic> json) {
    return MoodStreaks(
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      lastCheckin: json['last_checkin'] != null
          ? DateTime.parse(json['last_checkin'] as String)
          : null,
    );
  }
}

/// Complete mood analytics response from the API.
class MoodAnalyticsResponse {
  final MoodAnalyticsSummary summary;
  final List<MoodPattern> patterns;
  final MoodStreaks streaks;
  final List<String> recommendations;

  const MoodAnalyticsResponse({
    required this.summary,
    required this.patterns,
    required this.streaks,
    required this.recommendations,
  });

  factory MoodAnalyticsResponse.fromJson(Map<String, dynamic> json) {
    final patternsJson = json['patterns'] as List<dynamic>? ?? [];
    final recommendationsJson = json['recommendations'] as List<dynamic>? ?? [];

    return MoodAnalyticsResponse(
      summary: MoodAnalyticsSummary.fromJson(
        json['summary'] as Map<String, dynamic>? ?? {},
      ),
      patterns: patternsJson
          .map((item) => MoodPattern.fromJson(item as Map<String, dynamic>))
          .toList(),
      streaks: MoodStreaks.fromJson(
        json['streaks'] as Map<String, dynamic>? ?? {},
      ),
      recommendations: recommendationsJson.map((r) => r.toString()).toList(),
    );
  }

  /// Get mood distribution pattern data.
  List<MoodDistribution> get moodDistribution {
    final pattern = patterns.firstWhere(
      (p) => p.type == 'mood_distribution',
      orElse: () => const MoodPattern(type: '', title: '', data: []),
    );
    return (pattern.data)
        .map((item) => MoodDistribution.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
