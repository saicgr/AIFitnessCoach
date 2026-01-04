import 'dart:ui';

import 'package:json_annotation/json_annotation.dart';

part 'home_layout.g.dart';

/// Tile types available for home screen customization
enum TileType {
  // Existing tiles
  @JsonValue('quickStart')
  quickStart,
  @JsonValue('nextWorkout')
  nextWorkout,
  @JsonValue('fitnessScore')
  fitnessScore,
  @JsonValue('moodPicker')
  moodPicker,
  @JsonValue('dailyActivity')
  dailyActivity,
  @JsonValue('quickActions')
  quickActions,
  @JsonValue('weeklyProgress')
  weeklyProgress,
  @JsonValue('weeklyGoals')
  weeklyGoals,
  @JsonValue('weekChanges')
  weekChanges,
  @JsonValue('upcomingFeatures')
  upcomingFeatures,
  @JsonValue('upcomingWorkouts')
  upcomingWorkouts,
  // New tiles
  @JsonValue('streakCounter')
  streakCounter,
  @JsonValue('personalRecords')
  personalRecords,
  @JsonValue('aiCoachTip')
  aiCoachTip,
  @JsonValue('challengeProgress')
  challengeProgress,
  @JsonValue('caloriesSummary')
  caloriesSummary,
  @JsonValue('macroRings')
  macroRings,
  @JsonValue('bodyWeight')
  bodyWeight,
  @JsonValue('progressPhoto')
  progressPhoto,
  @JsonValue('socialFeed')
  socialFeed,
  @JsonValue('leaderboardRank')
  leaderboardRank,
  @JsonValue('fasting')
  fasting,
  @JsonValue('weeklyCalendar')
  weeklyCalendar,
  @JsonValue('muscleHeatmap')
  muscleHeatmap,
  @JsonValue('sleepScore')
  sleepScore,
  @JsonValue('restDayTip')
  restDayTip,
  @JsonValue('myJourney')
  myJourney,
  @JsonValue('progressCharts')
  progressCharts,
  @JsonValue('roiSummary')
  roiSummary,
  @JsonValue('weeklyPlan')
  weeklyPlan,
  // New tiles for fat loss UX
  @JsonValue('weightTrend')
  weightTrend,
  @JsonValue('dailyStats')
  dailyStats,
  @JsonValue('achievements')
  achievements,
  @JsonValue('heroSection')
  heroSection,
  @JsonValue('quickLogWeight')
  quickLogWeight,
  @JsonValue('quickLogMeasurements')
  quickLogMeasurements,
  @JsonValue('habits')
  habits,
}

/// Extension to provide metadata for tile types
extension TileTypeExtension on TileType {
  /// Get human-readable display name
  String get displayName {
    switch (this) {
      case TileType.quickStart:
        return 'Quick Start';
      case TileType.nextWorkout:
        return 'Next Workout';
      case TileType.fitnessScore:
        return 'Fitness Score';
      case TileType.moodPicker:
        return 'Mood Check-in';
      case TileType.dailyActivity:
        return 'Daily Activity';
      case TileType.quickActions:
        return 'Quick Actions';
      case TileType.weeklyProgress:
        return 'Weekly Progress';
      case TileType.weeklyGoals:
        return 'Weekly Goals';
      case TileType.weekChanges:
        return 'Week Changes';
      case TileType.upcomingFeatures:
        return 'Upcoming Features';
      case TileType.upcomingWorkouts:
        return 'Upcoming Workouts';
      case TileType.streakCounter:
        return 'Streak Fire';
      case TileType.personalRecords:
        return 'Personal Records';
      case TileType.aiCoachTip:
        return 'Coach Tip';
      case TileType.challengeProgress:
        return 'Active Challenge';
      case TileType.caloriesSummary:
        return 'Today\'s Calories';
      case TileType.macroRings:
        return 'Macro Rings';
      case TileType.bodyWeight:
        return 'Weight Tracker';
      case TileType.progressPhoto:
        return 'Photo Compare';
      case TileType.socialFeed:
        return 'Friend Activity';
      case TileType.leaderboardRank:
        return 'My Rank';
      case TileType.fasting:
        return 'Fasting Timer';
      case TileType.weeklyCalendar:
        return 'Mini Calendar';
      case TileType.muscleHeatmap:
        return 'Muscle Map';
      case TileType.sleepScore:
        return 'Sleep Quality';
      case TileType.restDayTip:
        return 'Rest Day Card';
      case TileType.myJourney:
        return 'My Journey';
      case TileType.progressCharts:
        return 'Progress Charts';
      case TileType.roiSummary:
        return 'Your Journey ROI';
      case TileType.weeklyPlan:
        return 'Weekly Plan';
      case TileType.weightTrend:
        return 'Weight Trend';
      case TileType.dailyStats:
        return 'Daily Stats';
      case TileType.achievements:
        return 'Achievements';
      case TileType.heroSection:
        return 'Hero Section';
      case TileType.quickLogWeight:
        return 'Quick Log Weight';
      case TileType.quickLogMeasurements:
        return 'Quick Measurements';
      case TileType.habits:
        return 'Today\'s Habits';
    }
  }

  /// Get description for the tile
  String get description {
    switch (this) {
      case TileType.quickStart:
        return 'One-tap to start today\'s workout';
      case TileType.nextWorkout:
        return 'Your upcoming workout session';
      case TileType.fitnessScore:
        return 'Overall fitness, strength & nutrition scores';
      case TileType.moodPicker:
        return 'Quick mood picker for instant workouts';
      case TileType.dailyActivity:
        return 'Health device activity summary';
      case TileType.quickActions:
        return 'Log Food, Stats, Share, Water buttons';
      case TileType.weeklyProgress:
        return 'Workout completion progress ring';
      case TileType.weeklyGoals:
        return 'Goals and milestones for the week';
      case TileType.weekChanges:
        return 'Exercise variation this week';
      case TileType.upcomingFeatures:
        return 'Feature voting and roadmap preview';
      case TileType.upcomingWorkouts:
        return 'Your scheduled workouts';
      case TileType.streakCounter:
        return 'Your current workout streak';
      case TileType.personalRecords:
        return 'Recent personal records';
      case TileType.aiCoachTip:
        return 'Daily tip from your AI coach';
      case TileType.challengeProgress:
        return 'Active challenge mini-card';
      case TileType.caloriesSummary:
        return 'Today\'s intake vs target';
      case TileType.macroRings:
        return 'Visual donut charts for protein/carbs/fat';
      case TileType.bodyWeight:
        return 'Recent weight with trend arrow';
      case TileType.progressPhoto:
        return 'Before/after comparison';
      case TileType.socialFeed:
        return 'See what friends are doing';
      case TileType.leaderboardRank:
        return 'Your position on leaderboard';
      case TileType.fasting:
        return 'Current fasting window timer';
      case TileType.weeklyCalendar:
        return 'Mini calendar with workout days';
      case TileType.muscleHeatmap:
        return 'Muscle groups trained recently';
      case TileType.sleepScore:
        return 'Sleep quality from health app';
      case TileType.restDayTip:
        return 'Recovery tips for rest days';
      case TileType.myJourney:
        return 'Your fitness journey progress';
      case TileType.progressCharts:
        return 'Strength and volume charts over time';
      case TileType.roiSummary:
        return 'Total workouts, time invested, and milestones';
      case TileType.weeklyPlan:
        return 'Holistic plan with workouts, nutrition & fasting';
      case TileType.weightTrend:
        return 'Weekly weight change with trend arrow';
      case TileType.dailyStats:
        return 'Steps count and calorie deficit';
      case TileType.achievements:
        return 'Recent badges and next milestone';
      case TileType.heroSection:
        return 'Swipeable workout, nutrition & fasting focus';
      case TileType.quickLogWeight:
        return 'Quickly log your weight';
      case TileType.quickLogMeasurements:
        return 'Track body measurements';
      case TileType.habits:
        return 'Daily habits and goals tracker';
    }
  }

  /// Get icon name (Material Icons)
  String get iconName {
    switch (this) {
      case TileType.quickStart:
        return 'play_circle_filled';
      case TileType.nextWorkout:
        return 'fitness_center';
      case TileType.fitnessScore:
        return 'insights';
      case TileType.moodPicker:
        return 'wb_sunny_outlined';
      case TileType.dailyActivity:
        return 'watch';
      case TileType.quickActions:
        return 'apps';
      case TileType.weeklyProgress:
        return 'donut_large';
      case TileType.weeklyGoals:
        return 'flag_outlined';
      case TileType.weekChanges:
        return 'swap_horiz';
      case TileType.upcomingFeatures:
        return 'new_releases_outlined';
      case TileType.upcomingWorkouts:
        return 'calendar_today';
      case TileType.streakCounter:
        return 'local_fire_department';
      case TileType.personalRecords:
        return 'emoji_events';
      case TileType.aiCoachTip:
        return 'tips_and_updates';
      case TileType.challengeProgress:
        return 'military_tech';
      case TileType.caloriesSummary:
        return 'restaurant';
      case TileType.macroRings:
        return 'pie_chart';
      case TileType.bodyWeight:
        return 'monitor_weight';
      case TileType.progressPhoto:
        return 'compare';
      case TileType.socialFeed:
        return 'people';
      case TileType.leaderboardRank:
        return 'leaderboard';
      case TileType.fasting:
        return 'timer';
      case TileType.weeklyCalendar:
        return 'calendar_month';
      case TileType.muscleHeatmap:
        return 'accessibility_new';
      case TileType.sleepScore:
        return 'bedtime';
      case TileType.restDayTip:
        return 'spa';
      case TileType.myJourney:
        return 'route';
      case TileType.progressCharts:
        return 'show_chart';
      case TileType.roiSummary:
        return 'trending_up';
      case TileType.weeklyPlan:
        return 'calendar_view_week';
      case TileType.weightTrend:
        return 'trending_down';
      case TileType.dailyStats:
        return 'directions_walk';
      case TileType.achievements:
        return 'emoji_events';
      case TileType.heroSection:
        return 'view_carousel';
      case TileType.quickLogWeight:
        return 'scale';
      case TileType.quickLogMeasurements:
        return 'straighten';
      case TileType.habits:
        return 'checklist';
    }
  }

  /// Get category for the tile
  TileCategory get category {
    switch (this) {
      case TileType.quickStart:
      case TileType.nextWorkout:
      case TileType.weekChanges:
      case TileType.upcomingWorkouts:
      case TileType.personalRecords:
      case TileType.challengeProgress:
      case TileType.muscleHeatmap:
        return TileCategory.workout;
      case TileType.fitnessScore:
      case TileType.weeklyProgress:
      case TileType.weeklyGoals:
      case TileType.streakCounter:
      case TileType.weeklyCalendar:
      case TileType.bodyWeight:
      case TileType.progressPhoto:
        return TileCategory.progress;
      case TileType.caloriesSummary:
      case TileType.macroRings:
      case TileType.fasting:
        return TileCategory.nutrition;
      case TileType.socialFeed:
      case TileType.leaderboardRank:
      case TileType.upcomingFeatures:
        return TileCategory.social;
      case TileType.moodPicker:
      case TileType.dailyActivity:
      case TileType.sleepScore:
      case TileType.restDayTip:
        return TileCategory.wellness;
      case TileType.quickActions:
      case TileType.aiCoachTip:
        return TileCategory.tools;
      case TileType.myJourney:
      case TileType.progressCharts:
      case TileType.roiSummary:
        return TileCategory.progress;
      case TileType.weeklyPlan:
        return TileCategory.wellness;
      case TileType.weightTrend:
      case TileType.achievements:
        return TileCategory.progress;
      case TileType.dailyStats:
        return TileCategory.wellness;
      case TileType.heroSection:
        return TileCategory.workout;
      case TileType.quickLogWeight:
      case TileType.quickLogMeasurements:
        return TileCategory.progress;
      case TileType.habits:
        return TileCategory.wellness;
    }
  }

  /// Get supported sizes for this tile type
  List<TileSize> get supportedSizes {
    switch (this) {
      // Full-only tiles
      case TileType.quickStart:
      case TileType.nextWorkout:
      case TileType.moodPicker:
      case TileType.weeklyCalendar:
      case TileType.muscleHeatmap:
      case TileType.socialFeed:
      case TileType.progressPhoto:
      case TileType.quickActions:
        return [TileSize.full];
      // Full and half
      case TileType.fitnessScore:
      case TileType.dailyActivity:
      case TileType.weeklyProgress:
      case TileType.weeklyGoals:
      case TileType.weekChanges:
      case TileType.personalRecords:
      case TileType.challengeProgress:
      case TileType.fasting:
      case TileType.upcomingFeatures:
      case TileType.upcomingWorkouts:
      case TileType.restDayTip:
      case TileType.myJourney:
      case TileType.progressCharts:
      case TileType.roiSummary:
      case TileType.weeklyPlan:
        return [TileSize.full, TileSize.half];
      // Half and compact
      case TileType.streakCounter:
      case TileType.leaderboardRank:
      case TileType.bodyWeight:
      case TileType.sleepScore:
        return [TileSize.half, TileSize.compact];
      // Half only
      case TileType.caloriesSummary:
      case TileType.macroRings:
        return [TileSize.half];
      // Full and compact
      case TileType.aiCoachTip:
        return [TileSize.full, TileSize.compact];
      // New tiles - half and full
      case TileType.weightTrend:
      case TileType.dailyStats:
      case TileType.achievements:
      case TileType.quickLogWeight:
      case TileType.quickLogMeasurements:
      case TileType.habits:
        return [TileSize.full, TileSize.half, TileSize.compact];
      // Hero section is full only
      case TileType.heroSection:
        return [TileSize.full];
    }
  }

  /// Get default size for this tile type
  TileSize get defaultSize {
    switch (this) {
      case TileType.streakCounter:
      case TileType.caloriesSummary:
      case TileType.macroRings:
      case TileType.bodyWeight:
      case TileType.leaderboardRank:
      case TileType.sleepScore:
      case TileType.weightTrend:
      case TileType.dailyStats:
      case TileType.achievements:
      case TileType.quickLogWeight:
      case TileType.quickLogMeasurements:
      case TileType.habits:
        return TileSize.half;
      default:
        return TileSize.full;
    }
  }

  /// Whether this is a new tile (not yet implemented)
  bool get isNew {
    switch (this) {
      case TileType.quickStart:
      case TileType.nextWorkout:
      case TileType.fitnessScore:
      case TileType.moodPicker:
      case TileType.dailyActivity:
      case TileType.quickActions:
      case TileType.weeklyProgress:
      case TileType.weeklyGoals:
      case TileType.weekChanges:
      case TileType.upcomingFeatures:
      case TileType.upcomingWorkouts:
        return false;
      default:
        return true;
    }
  }
}

/// Category for grouping tiles in the picker
enum TileCategory {
  workout,
  progress,
  nutrition,
  social,
  wellness,
  tools,
}

/// Extension for tile category
extension TileCategoryExtension on TileCategory {
  String get displayName {
    switch (this) {
      case TileCategory.workout:
        return 'Workout';
      case TileCategory.progress:
        return 'Progress';
      case TileCategory.nutrition:
        return 'Nutrition';
      case TileCategory.social:
        return 'Social';
      case TileCategory.wellness:
        return 'Wellness';
      case TileCategory.tools:
        return 'Tools';
    }
  }

  String get emoji {
    switch (this) {
      case TileCategory.workout:
        return '🏋️';
      case TileCategory.progress:
        return '📊';
      case TileCategory.nutrition:
        return '🍎';
      case TileCategory.social:
        return '👥';
      case TileCategory.wellness:
        return '🧘';
      case TileCategory.tools:
        return '🛠️';
    }
  }

  /// Get color for the category
  Color get color {
    switch (this) {
      case TileCategory.workout:
        return const Color(0xFF00BCD4); // Cyan
      case TileCategory.progress:
        return const Color(0xFF4CAF50); // Green
      case TileCategory.nutrition:
        return const Color(0xFFFF9800); // Orange
      case TileCategory.social:
        return const Color(0xFF9C27B0); // Purple
      case TileCategory.wellness:
        return const Color(0xFFFFEB3B); // Yellow
      case TileCategory.tools:
        return const Color(0xFF00BCD4); // Cyan
    }
  }
}

/// Tile size options
enum TileSize {
  @JsonValue('full')
  full,
  @JsonValue('half')
  half,
  @JsonValue('compact')
  compact,
}

/// Extension for tile size
extension TileSizeExtension on TileSize {
  String get displayName {
    switch (this) {
      case TileSize.full:
        return 'Full';
      case TileSize.half:
        return 'Half';
      case TileSize.compact:
        return 'Compact';
    }
  }
}

/// A single tile configuration
@JsonSerializable()
class HomeTile {
  final String id;
  final TileType type;
  final TileSize size;
  final int order;
  @JsonKey(name: 'is_visible')
  final bool isVisible;

  const HomeTile({
    required this.id,
    required this.type,
    required this.size,
    required this.order,
    this.isVisible = true,
  });

  factory HomeTile.fromJson(Map<String, dynamic> json) =>
      _$HomeTileFromJson(json);
  Map<String, dynamic> toJson() => _$HomeTileToJson(this);

  HomeTile copyWith({
    String? id,
    TileType? type,
    TileSize? size,
    int? order,
    bool? isVisible,
  }) {
    return HomeTile(
      id: id ?? this.id,
      type: type ?? this.type,
      size: size ?? this.size,
      order: order ?? this.order,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}

/// A saved layout configuration
@JsonSerializable()
class HomeLayout {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final String name;
  final List<HomeTile> tiles;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'template_id')
  final String? templateId;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const HomeLayout({
    required this.id,
    required this.userId,
    required this.name,
    required this.tiles,
    this.isActive = false,
    this.templateId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HomeLayout.fromJson(Map<String, dynamic> json) =>
      _$HomeLayoutFromJson(json);
  Map<String, dynamic> toJson() => _$HomeLayoutToJson(this);

  HomeLayout copyWith({
    String? id,
    String? userId,
    String? name,
    List<HomeTile>? tiles,
    bool? isActive,
    String? templateId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HomeLayout(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      tiles: tiles ?? this.tiles,
      isActive: isActive ?? this.isActive,
      templateId: templateId ?? this.templateId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get visible tiles sorted by order
  List<HomeTile> get visibleTiles {
    return tiles.where((t) => t.isVisible).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  /// Get hidden tiles sorted by order
  List<HomeTile> get hiddenTiles {
    return tiles.where((t) => !t.isVisible).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }
}

/// A system-provided layout template
@JsonSerializable()
class HomeLayoutTemplate {
  final String id;
  final String name;
  final String? description;
  final List<HomeTile> tiles;
  final String? icon;
  final String? category;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  const HomeLayoutTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.tiles,
    this.icon,
    this.category,
    this.createdAt,
  });

  factory HomeLayoutTemplate.fromJson(Map<String, dynamic> json) =>
      _$HomeLayoutTemplateFromJson(json);
  Map<String, dynamic> toJson() => _$HomeLayoutTemplateToJson(this);
}

/// Request to create a new layout
@JsonSerializable()
class CreateLayoutRequest {
  final String name;
  final List<HomeTile> tiles;
  @JsonKey(name: 'template_id')
  final String? templateId;

  const CreateLayoutRequest({
    required this.name,
    required this.tiles,
    this.templateId,
  });

  factory CreateLayoutRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateLayoutRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateLayoutRequestToJson(this);
}

/// Request to update an existing layout
@JsonSerializable()
class UpdateLayoutRequest {
  final String? name;
  final List<HomeTile>? tiles;

  const UpdateLayoutRequest({
    this.name,
    this.tiles,
  });

  factory UpdateLayoutRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateLayoutRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateLayoutRequestToJson(this);
}

/// Default tile order for new users
const List<TileType> defaultTileOrder = [
  TileType.quickStart, // Quick start at the top for easy workout access
  TileType.nextWorkout,
  TileType.fitnessScore,
  TileType.moodPicker,
  TileType.dailyActivity,
  TileType.quickActions,
  TileType.weeklyProgress,
  TileType.weeklyGoals,
  TileType.weekChanges,
  TileType.upcomingWorkouts,
];

/// Create default tiles for a new user
List<HomeTile> createDefaultTiles() {
  return defaultTileOrder.asMap().entries.map((entry) {
    return HomeTile(
      id: 'tile_${entry.key}',
      type: entry.value,
      size: entry.value.defaultSize,
      order: entry.key,
      isVisible: true,
    );
  }).toList();
}

/// Layout preset types
enum LayoutPreset {
  fatLossFocus,
  gymFocused,
  nutritionFocused,
  trackerOnly,
  fastingFocused,
  minimal,
}

extension LayoutPresetExtension on LayoutPreset {
  String get displayName {
    switch (this) {
      case LayoutPreset.fatLossFocus:
        return 'Fat Loss Focus';
      case LayoutPreset.gymFocused:
        return 'Gym Focused';
      case LayoutPreset.nutritionFocused:
        return 'Nutrition Focused';
      case LayoutPreset.trackerOnly:
        return 'Tracker Only';
      case LayoutPreset.fastingFocused:
        return 'Fasting Focused';
      case LayoutPreset.minimal:
        return 'Minimal';
    }
  }

  String get description {
    switch (this) {
      case LayoutPreset.fatLossFocus:
        return 'Weight trends, daily stats, streak tracking';
      case LayoutPreset.gymFocused:
        return 'Workout-centric with personal records';
      case LayoutPreset.nutritionFocused:
        return 'Calories, macros, and meal logging';
      case LayoutPreset.trackerOnly:
        return 'Simple progress tracking';
      case LayoutPreset.fastingFocused:
        return 'Intermittent fasting with weight trends';
      case LayoutPreset.minimal:
        return 'Just the essentials';
    }
  }

  String get icon {
    switch (this) {
      case LayoutPreset.fatLossFocus:
        return 'trending_down';
      case LayoutPreset.gymFocused:
        return 'fitness_center';
      case LayoutPreset.nutritionFocused:
        return 'restaurant';
      case LayoutPreset.trackerOnly:
        return 'insights';
      case LayoutPreset.fastingFocused:
        return 'timer';
      case LayoutPreset.minimal:
        return 'view_agenda';
    }
  }

  /// Get tile order for this preset
  List<TileType> get tileOrder {
    switch (this) {
      case LayoutPreset.fatLossFocus:
        return [
          TileType.weightTrend,
          TileType.heroSection,
          TileType.dailyStats,
          TileType.quickActions,
          TileType.streakCounter,
          TileType.weeklyProgress,
          TileType.habits,
        ];
      case LayoutPreset.gymFocused:
        return [
          TileType.heroSection,
          TileType.streakCounter,
          TileType.personalRecords,
          TileType.weeklyProgress,
          TileType.quickActions,
          TileType.roiSummary,
        ];
      case LayoutPreset.nutritionFocused:
        return [
          TileType.heroSection,
          TileType.caloriesSummary,
          TileType.macroRings,
          TileType.weightTrend,
          TileType.quickActions,
          TileType.fasting,
        ];
      case LayoutPreset.trackerOnly:
        return [
          TileType.weightTrend,
          TileType.dailyStats,
          TileType.streakCounter,
          TileType.achievements,
          TileType.weeklyProgress,
          TileType.habits,
        ];
      case LayoutPreset.fastingFocused:
        return [
          TileType.heroSection,
          TileType.fasting,
          TileType.weightTrend,
          TileType.streakCounter,
          TileType.quickActions,
        ];
      case LayoutPreset.minimal:
        return [
          TileType.heroSection,
          TileType.quickActions,
        ];
    }
  }
}

/// Create tiles for a specific preset
List<HomeTile> createPresetTiles(LayoutPreset preset) {
  return preset.tileOrder.asMap().entries.map((entry) {
    return HomeTile(
      id: 'tile_${entry.key}',
      type: entry.value,
      size: entry.value.defaultSize,
      order: entry.key,
      isVisible: true,
    );
  }).toList();
}
