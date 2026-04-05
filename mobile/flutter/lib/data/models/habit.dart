import 'package:json_annotation/json_annotation.dart';


part 'habit_part_habit_category.dart';


/// Main habit model
@JsonSerializable()
class Habit {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final String name;
  final String? description;
  final HabitCategory category;
  @JsonKey(name: 'habit_type')
  final HabitType habitType;
  final HabitFrequency frequency;
  @JsonKey(name: 'specific_days')
  final List<int>? specificDays; // 0 = Sunday, 6 = Saturday
  @JsonKey(name: 'target_count')
  final int? targetCount; // For quantitative habits
  final String? unit; // e.g., "glasses", "minutes", "steps"
  final String icon;
  final String color;
  @JsonKey(name: 'reminder_time')
  final String? reminderTime; // HH:mm format
  @JsonKey(name: 'is_archived')
  final bool isArchived;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  // Computed/joined fields
  @JsonKey(name: 'current_streak')
  final int currentStreak;
  @JsonKey(name: 'best_streak')
  final int bestStreak;
  @JsonKey(name: 'completion_rate_7d')
  final double completionRate7d;
  @JsonKey(name: 'is_completed_today')
  final bool isCompletedToday;
  @JsonKey(name: 'today_progress')
  final int todayProgress;

  const Habit({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.category = HabitCategory.lifestyle,
    this.habitType = HabitType.positive,
    this.frequency = HabitFrequency.daily,
    this.specificDays,
    this.targetCount,
    this.unit,
    this.icon = 'check_circle',
    this.color = '#06B6D4',
    this.reminderTime,
    this.isArchived = false,
    this.createdAt,
    this.updatedAt,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.completionRate7d = 0.0,
    this.isCompletedToday = false,
    this.todayProgress = 0,
  });

  factory Habit.fromJson(Map<String, dynamic> json) => _$HabitFromJson(json);
  Map<String, dynamic> toJson() => _$HabitToJson(this);

  Habit copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    HabitCategory? category,
    HabitType? habitType,
    HabitFrequency? frequency,
    List<int>? specificDays,
    int? targetCount,
    String? unit,
    String? icon,
    String? color,
    String? reminderTime,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? currentStreak,
    int? bestStreak,
    double? completionRate7d,
    bool? isCompletedToday,
    int? todayProgress,
  }) {
    return Habit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      habitType: habitType ?? this.habitType,
      frequency: frequency ?? this.frequency,
      specificDays: specificDays ?? this.specificDays,
      targetCount: targetCount ?? this.targetCount,
      unit: unit ?? this.unit,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      reminderTime: reminderTime ?? this.reminderTime,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      completionRate7d: completionRate7d ?? this.completionRate7d,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
      todayProgress: todayProgress ?? this.todayProgress,
    );
  }

  /// Check if habit is due today based on frequency
  bool get isDueToday {
    if (frequency == HabitFrequency.daily) return true;
    if (frequency == HabitFrequency.specificDays && specificDays != null) {
      final today = DateTime.now().weekday % 7; // Convert to 0-6 (Sun-Sat)
      return specificDays!.contains(today);
    }
    return true;
  }

  /// Get progress percentage for quantitative habits
  double get progressPercentage {
    if (targetCount == null || targetCount == 0) {
      return isCompletedToday ? 1.0 : 0.0;
    }
    return (todayProgress / targetCount!).clamp(0.0, 1.0);
  }
}

/// Habit completion log entry
@JsonSerializable()

/// Daily habits summary
@JsonSerializable()

/// Weekly habit statistics
@JsonSerializable()

/// Habit template for quick creation
@JsonSerializable()

/// AI-generated habit insights
@JsonSerializable()

/// Habit with today's status for provider state
@JsonSerializable()

/// Today's habits response from API
@JsonSerializable()

/// Habits summary for dashboard
@JsonSerializable()

/// Weekly summary for a habit
@JsonSerializable()

/// Habit streak data
@JsonSerializable()

/// Habit suggestion response from AI
@JsonSerializable()

/// Calendar data for visualization
@JsonSerializable()
