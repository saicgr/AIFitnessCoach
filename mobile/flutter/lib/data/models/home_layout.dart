import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';


part 'home_layout_part_tile_type.dart';
part 'home_layout.g.dart';


/// Tiles that are deprecated and should be hidden from the layout editor
const Set<TileType> deprecatedTiles = {
  TileType.weeklyProgress,
  TileType.upcomingFeatures,
  TileType.streakCounter,
  TileType.sleepScore,
  TileType.weightTrend,
  TileType.heroSection,
};

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

/// Default tile order for new users
const List<TileType> defaultVisibleTiles = [
  TileType.nextWorkout, // Hero workout card at the top
  TileType.quickActions, // Quick actions row (compact: Workout, Food, Water, Chat, +)
  TileType.todayStats, // Goals, calories, water pills
  TileType.habits, // Daily habits and goals tracker
  TileType.weeklyGoals, // Weekly workout goals progress
];

/// Hidden tiles available in the layout editor
const List<TileType> defaultHiddenTiles = [
  TileType.fitnessScore,
  TileType.dailyStats,
  TileType.quickLogWeight,
  TileType.bodyWeight,
  TileType.upcomingWorkouts,
  TileType.aiCoachTip,
  TileType.personalRecords,
  TileType.achievements,
  TileType.weekChanges,
  TileType.quickStart,
  TileType.moodPicker,
  TileType.dailyActivity,
  TileType.quickLogMeasurements,
  TileType.caloriesSummary,
  TileType.macroRings,
  TileType.myJourney,
  TileType.progressCharts,
  TileType.roiSummary,
  TileType.weeklyPlan,
  TileType.restDayTip,
  TileType.leaderboardRank,
  TileType.challengeProgress,
  TileType.socialFeed,
];

/// Create default tiles for a new user
List<HomeTile> createDefaultTiles() {
  final tiles = <HomeTile>[];
  int order = 0;

  // Add visible tiles first
  for (final type in defaultVisibleTiles) {
    tiles.add(HomeTile(
      id: 'tile_$order',
      type: type,
      size: type.defaultSize,
      order: order,
      isVisible: true,
    ));
    order++;
  }

  // Add hidden tiles
  for (final type in defaultHiddenTiles) {
    tiles.add(HomeTile(
      id: 'tile_$order',
      type: type,
      size: type.defaultSize,
      order: order,
      isVisible: false,
    ));
    order++;
  }

  return tiles;
}

/// Available preset layouts (all use non-deprecated tile types only)
const List<LayoutPreset> layoutPresets = [
  LayoutPreset(
    id: 'minimalist',
    name: 'Minimalist',
    description: 'Clean and focused - just your workout, actions, and stats',
    icon: Icons.spa,
    color: Color(0xFF1A1A2E),
    tiles: [
      TileType.nextWorkout,
      TileType.quickActions,
      TileType.todayStats,
    ],
  ),
  LayoutPreset(
    id: 'gym_focused',
    name: 'Gym Focused',
    description: 'Workout-centric with personal records',
    icon: Icons.fitness_center,
    color: Color(0xFF00BCD4),
    tiles: [
      TileType.nextWorkout,
      TileType.personalRecords,
      TileType.muscleHeatmap,
      TileType.weekChanges,
      TileType.challengeProgress,
      TileType.aiCoachTip,
    ],
  ),
  LayoutPreset(
    id: 'fat_loss',
    name: 'Fat Loss Focus',
    description: 'Weight trends, daily stats, habits',
    icon: Icons.trending_down,
    color: Color(0xFFF97316),
    tiles: [
      TileType.nextWorkout,
      TileType.dailyStats,
      TileType.quickLogWeight,
      TileType.habits,
      TileType.bodyWeight,
      TileType.achievements,
    ],
  ),
  LayoutPreset(
    id: 'nutrition_focused',
    name: 'Nutrition Focused',
    description: 'Calories, macros, and meal logging',
    icon: Icons.restaurant,
    color: Color(0xFF22C55E),
    tiles: [
      TileType.caloriesSummary,
      TileType.macroRings,
      TileType.bodyWeight,
      TileType.fasting,
      TileType.nextWorkout,
      TileType.moodPicker,
      TileType.aiCoachTip,
    ],
  ),
  LayoutPreset(
    id: 'tracker_only',
    name: 'Tracker Only',
    description: 'Simple progress tracking',
    icon: Icons.insights,
    color: Color(0xFFA855F7),
    tiles: [
      TileType.nextWorkout,
      TileType.dailyStats,
      TileType.quickLogWeight,
      TileType.habits,
      TileType.achievements,
    ],
  ),
  LayoutPreset(
    id: 'fasting_focused',
    name: 'Fasting Focused',
    description: 'Intermittent fasting with weight trends',
    icon: Icons.timer,
    color: Color(0xFFEAB308),
    tiles: [
      TileType.nextWorkout,
      TileType.fasting,
      TileType.quickLogWeight,
      TileType.bodyWeight,
      TileType.moodPicker,
    ],
  ),
  LayoutPreset(
    id: 'bare_bones',
    name: 'Bare Bones',
    description: 'Just the essentials - workout and actions only',
    icon: Icons.view_agenda,
    color: Color(0xFF00BCD4),
    tiles: [
      TileType.nextWorkout,
      TileType.quickActions,
    ],
  ),
  LayoutPreset(
    id: 'metrics',
    name: 'Metrics',
    description: 'Body metrics, scores, and progress charts',
    icon: Icons.analytics,
    color: Color(0xFF3B82F6),
    tiles: [
      TileType.fitnessScore,
      TileType.bodyWeight,
      TileType.quickLogWeight,
      TileType.quickLogMeasurements,
      TileType.dailyStats,
      TileType.progressCharts,
      TileType.roiSummary,
      TileType.dailyActivity,
      TileType.achievements,
    ],
  ),
];
