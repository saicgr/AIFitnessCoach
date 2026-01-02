import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:flutter/foundation.dart';

/// Service to bridge Flutter app data to native iOS/Android home screen widgets.
/// Uses the home_widget package to communicate with WidgetKit (iOS) and App Widgets (Android).
class WidgetService {
  static const String _appGroupId = 'group.com.fitwiz.widgets';
  static const String _androidWidgetName = 'FitnessWidgetReceiver';

  // Widget data keys
  static const String keyWorkout = 'workout_data';
  static const String keyStreak = 'streak_data';
  static const String keyWater = 'water_data';
  static const String keyFood = 'food_data';
  static const String keyStats = 'stats_data';
  static const String keyChallenges = 'challenges_data';
  static const String keyAchievements = 'achievements_data';
  static const String keyGoals = 'goals_data';
  static const String keyCalendar = 'calendar_data';
  static const String keyAICoach = 'aicoach_data';

  /// Initialize the widget service with app group configuration
  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  /// Update Today's Workout widget data
  static Future<void> updateWorkoutWidget({
    String? workoutId,
    String? workoutName,
    int? durationMinutes,
    int? exerciseCount,
    String? muscleGroup,
    bool? isRestDay,
  }) async {
    try {
      final data = {
        'id': workoutId,
        'name': workoutName ?? 'No Workout',
        'duration': durationMinutes ?? 0,
        'exercises': exerciseCount ?? 0,
        'muscle': muscleGroup ?? '',
        'isRestDay': isRestDay ?? false,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      await HomeWidget.saveWidgetData(keyWorkout, jsonEncode(data));
      await _updateWidgets();
      debugPrint('Updated workout widget: $data');
    } catch (e) {
      debugPrint('Error updating workout widget: $e');
    }
  }

  /// Update Streak & Motivation widget data
  static Future<void> updateStreakWidget({
    required int currentStreak,
    int? longestStreak,
    String? motivationalMessage,
    List<bool>? weeklyConsistency,
  }) async {
    try {
      final data = {
        'current': currentStreak,
        'longest': longestStreak ?? currentStreak,
        'message': motivationalMessage ?? _getMotivationalMessage(currentStreak),
        'weekly': weeklyConsistency ?? [],
        'updatedAt': DateTime.now().toIso8601String(),
      };
      await HomeWidget.saveWidgetData(keyStreak, jsonEncode(data));
      await _updateWidgets();
      debugPrint('Updated streak widget: $data');
    } catch (e) {
      debugPrint('Error updating streak widget: $e');
    }
  }

  /// Update Quick Water Log widget data
  static Future<void> updateWaterWidget({
    required int currentMl,
    required int goalMl,
    List<WaterLogEntry>? todayLogs,
  }) async {
    try {
      final data = {
        'current': currentMl,
        'goal': goalMl,
        'percent': goalMl > 0 ? (currentMl / goalMl * 100).round() : 0,
        'logs': todayLogs?.map((e) => e.toJson()).toList() ?? [],
        'updatedAt': DateTime.now().toIso8601String(),
      };
      await HomeWidget.saveWidgetData(keyWater, jsonEncode(data));
      await _updateWidgets();
      debugPrint('Updated water widget: $data');
    } catch (e) {
      debugPrint('Error updating water widget: $e');
    }
  }

  /// Update Quick Food Log widget data
  static Future<void> updateFoodWidget({
    required int caloriesConsumed,
    required int calorieGoal,
    int? proteinGrams,
    int? carbsGrams,
    int? fatGrams,
    List<MealLogEntry>? recentMeals,
  }) async {
    try {
      final data = {
        'calories': caloriesConsumed,
        'calorieGoal': calorieGoal,
        'protein': proteinGrams ?? 0,
        'carbs': carbsGrams ?? 0,
        'fat': fatGrams ?? 0,
        'meals': recentMeals?.map((e) => e.toJson()).toList() ?? [],
        'updatedAt': DateTime.now().toIso8601String(),
      };
      await HomeWidget.saveWidgetData(keyFood, jsonEncode(data));
      await _updateWidgets();
      debugPrint('Updated food widget: $data');
    } catch (e) {
      debugPrint('Error updating food widget: $e');
    }
  }

  /// Update Stats Dashboard widget data
  static Future<void> updateStatsWidget({
    required int workoutsCompleted,
    required int workoutsGoal,
    int? totalMinutes,
    int? caloriesBurned,
    int? currentStreak,
    int? prsThisWeek,
    double? weightChange,
  }) async {
    try {
      final data = {
        'workouts': workoutsCompleted,
        'workoutsGoal': workoutsGoal,
        'minutes': totalMinutes ?? 0,
        'calories': caloriesBurned ?? 0,
        'streak': currentStreak ?? 0,
        'prs': prsThisWeek ?? 0,
        'weightChange': weightChange ?? 0.0,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      await HomeWidget.saveWidgetData(keyStats, jsonEncode(data));
      await _updateWidgets();
      debugPrint('Updated stats widget: $data');
    } catch (e) {
      debugPrint('Error updating stats widget: $e');
    }
  }

  /// Update Active Challenges widget data
  static Future<void> updateChallengesWidget({
    required List<ChallengeWidgetData> challenges,
  }) async {
    try {
      final data = {
        'count': challenges.length,
        'challenges': challenges.map((e) => e.toJson()).toList(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      await HomeWidget.saveWidgetData(keyChallenges, jsonEncode(data));
      await _updateWidgets();
      debugPrint('Updated challenges widget: $data');
    } catch (e) {
      debugPrint('Error updating challenges widget: $e');
    }
  }

  /// Update Achievements widget data
  static Future<void> updateAchievementsWidget({
    required List<AchievementWidgetData> recentAchievements,
    int? totalPoints,
    String? nextMilestone,
    int? progressToNext,
  }) async {
    try {
      final data = {
        'achievements': recentAchievements.map((e) => e.toJson()).toList(),
        'points': totalPoints ?? 0,
        'nextMilestone': nextMilestone ?? '',
        'progress': progressToNext ?? 0,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      await HomeWidget.saveWidgetData(keyAchievements, jsonEncode(data));
      await _updateWidgets();
      debugPrint('Updated achievements widget: $data');
    } catch (e) {
      debugPrint('Error updating achievements widget: $e');
    }
  }

  /// Update Personal Goals widget data
  static Future<void> updateGoalsWidget({
    required List<GoalWidgetData> goals,
  }) async {
    try {
      final data = {
        'goals': goals.map((e) => e.toJson()).toList(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      await HomeWidget.saveWidgetData(keyGoals, jsonEncode(data));
      await _updateWidgets();
      debugPrint('Updated goals widget: $data');
    } catch (e) {
      debugPrint('Error updating goals widget: $e');
    }
  }

  /// Update Weekly Calendar widget data
  static Future<void> updateCalendarWidget({
    required List<CalendarDayData> weekDays,
    required int todayIndex,
  }) async {
    try {
      final data = {
        'days': weekDays.map((e) => e.toJson()).toList(),
        'todayIndex': todayIndex,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      await HomeWidget.saveWidgetData(keyCalendar, jsonEncode(data));
      await _updateWidgets();
      debugPrint('Updated calendar widget: $data');
    } catch (e) {
      debugPrint('Error updating calendar widget: $e');
    }
  }

  /// Update AI Coach Chat widget data
  static Future<void> updateAICoachWidget({
    String? lastMessagePreview,
    String? lastAgent,
    DateTime? lastInteraction,
    List<String>? quickPrompts,
  }) async {
    try {
      final data = {
        'lastMessage': lastMessagePreview ?? '',
        'lastAgent': lastAgent ?? 'coach',
        'lastInteraction': lastInteraction?.toIso8601String() ?? '',
        'prompts': quickPrompts ?? [
          'What should I eat today?',
          'Modify my workout',
          'I\'m feeling tired',
        ],
        'updatedAt': DateTime.now().toIso8601String(),
      };
      await HomeWidget.saveWidgetData(keyAICoach, jsonEncode(data));
      await _updateWidgets();
      debugPrint('Updated AI coach widget: $data');
    } catch (e) {
      debugPrint('Error updating AI coach widget: $e');
    }
  }

  /// Trigger widget refresh on iOS and Android
  static Future<void> _updateWidgets() async {
    // iOS - Update all widget families
    await HomeWidget.updateWidget(
      iOSName: 'WorkoutWidget',
      androidName: _androidWidgetName,
    );
    await HomeWidget.updateWidget(
      iOSName: 'StreakWidget',
      androidName: _androidWidgetName,
    );
    await HomeWidget.updateWidget(
      iOSName: 'WaterLogWidget',
      androidName: _androidWidgetName,
    );
    await HomeWidget.updateWidget(
      iOSName: 'FoodLogWidget',
      androidName: _androidWidgetName,
    );
    await HomeWidget.updateWidget(
      iOSName: 'StatsWidget',
      androidName: _androidWidgetName,
    );
    await HomeWidget.updateWidget(
      iOSName: 'ChallengesWidget',
      androidName: _androidWidgetName,
    );
    await HomeWidget.updateWidget(
      iOSName: 'AchievementsWidget',
      androidName: _androidWidgetName,
    );
    await HomeWidget.updateWidget(
      iOSName: 'GoalsWidget',
      androidName: _androidWidgetName,
    );
    await HomeWidget.updateWidget(
      iOSName: 'CalendarWidget',
      androidName: _androidWidgetName,
    );
    await HomeWidget.updateWidget(
      iOSName: 'AICoachWidget',
      androidName: _androidWidgetName,
    );
  }

  /// Handle deep link from widget tap
  static Future<Uri?> getInitialUri() async {
    return HomeWidget.initiallyLaunchedFromHomeWidget();
  }

  /// Listen for widget click events
  static Stream<Uri?> get widgetClicked => HomeWidget.widgetClicked;

  /// Get motivational message based on streak
  static String _getMotivationalMessage(int streak) {
    if (streak == 0) return 'Start your fitness journey today!';
    if (streak == 1) return 'Great start! Keep it going!';
    if (streak < 7) return 'You\'re building momentum!';
    if (streak < 14) return 'One week strong! Amazing!';
    if (streak < 30) return 'You\'re on fire! Don\'t stop!';
    if (streak < 60) return 'A month of dedication!';
    if (streak < 100) return 'Incredible consistency!';
    return 'You\'re a fitness legend!';
  }
}

// Widget data models

class WaterLogEntry {
  final int amountMl;
  final String drinkType;
  final DateTime timestamp;

  WaterLogEntry({
    required this.amountMl,
    required this.drinkType,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'amount': amountMl,
    'type': drinkType,
    'time': timestamp.toIso8601String(),
  };
}

class MealLogEntry {
  final String name;
  final String mealType;
  final int calories;
  final DateTime timestamp;

  MealLogEntry({
    required this.name,
    required this.mealType,
    required this.calories,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': mealType,
    'calories': calories,
    'time': timestamp.toIso8601String(),
  };
}

class ChallengeWidgetData {
  final String id;
  final String title;
  final int yourScore;
  final int opponentScore;
  final String opponentName;
  final String? opponentAvatar;
  final DateTime endsAt;
  final bool isLeading;

  ChallengeWidgetData({
    required this.id,
    required this.title,
    required this.yourScore,
    required this.opponentScore,
    required this.opponentName,
    this.opponentAvatar,
    required this.endsAt,
    required this.isLeading,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'yourScore': yourScore,
    'opponentScore': opponentScore,
    'opponentName': opponentName,
    'opponentAvatar': opponentAvatar,
    'endsAt': endsAt.toIso8601String(),
    'isLeading': isLeading,
  };
}

class AchievementWidgetData {
  final String id;
  final String name;
  final String icon;
  final DateTime earnedAt;

  AchievementWidgetData({
    required this.id,
    required this.name,
    required this.icon,
    required this.earnedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'earnedAt': earnedAt.toIso8601String(),
  };
}

class GoalWidgetData {
  final String id;
  final String title;
  final int progressPercent;
  final DateTime? targetDate;

  GoalWidgetData({
    required this.id,
    required this.title,
    required this.progressPercent,
    this.targetDate,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'progress': progressPercent,
    'targetDate': targetDate?.toIso8601String(),
  };
}

class CalendarDayData {
  final String dayName;
  final int dayNumber;
  final bool hasWorkout;
  final bool isCompleted;
  final bool isRestDay;
  final String? workoutName;

  CalendarDayData({
    required this.dayName,
    required this.dayNumber,
    required this.hasWorkout,
    required this.isCompleted,
    required this.isRestDay,
    this.workoutName,
  });

  Map<String, dynamic> toJson() => {
    'day': dayName,
    'number': dayNumber,
    'hasWorkout': hasWorkout,
    'completed': isCompleted,
    'isRest': isRestDay,
    'workoutName': workoutName,
  };
}
