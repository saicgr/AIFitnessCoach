import 'dart:ui';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/home_layout.dart';
import '../../../data/services/haptic_service.dart';

/// Bottom sheet for picking tiles to add to home screen
class TilePickerSheet extends StatelessWidget {
  final List<HomeTile> currentTiles;
  final Function(TileType type, TileSize? size) onTileSelected;

  const TilePickerSheet({
    super.key,
    required this.currentTiles,
    required this.onTileSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.background : AppColorsLight.background;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Get tiles already in the layout
    final existingTypes = currentTiles.map((t) => t.type).toSet();

    // Group tiles by category
    final tilesByCategory = <TileCategory, List<TileType>>{};
    for (final type in TileType.values) {
      if (!existingTypes.contains(type)) {
        final category = type.category;
        tilesByCategory.putIfAbsent(category, () => []).add(type);
      }
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.6),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
          ),
          child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Add Tile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Tile categories
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: TileCategory.values.length,
                  itemBuilder: (context, index) {
                    final category = TileCategory.values[index];
                    final tiles = tilesByCategory[category] ?? [];

                    if (tiles.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category header
                        Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 8),
                          child: Row(
                            children: [
                              Text(
                                category.emoji,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                category.displayName.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: textMuted,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Tiles in category
                        ...tiles.map((type) => _buildTileRow(
                              context,
                              type,
                              elevatedColor,
                              textColor,
                              textMuted,
                            )),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
          ),
        ),
      ),
    );
  }

  Widget _buildTileRow(
    BuildContext context,
    TileType type,
    Color elevatedColor,
    Color textColor,
    Color textMuted,
  ) {
    final iconColor = _getIconColorForCategory(type.category);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getIconForType(type),
              color: iconColor,
              size: 20,
            ),
          ),
          title: Row(
            children: [
              Text(
                type.displayName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              if (type.isNew) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'NEW',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppColors.purple,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(
            type.description,
            style: TextStyle(
              fontSize: 11,
              color: textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: ElevatedButton(
            onPressed: () {
              HapticService.light();
              onTileSelected(type, type.defaultSize);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cyan,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(60, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 16),
                SizedBox(width: 4),
                Text('Add', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(TileType type) {
    switch (type) {
      case TileType.nextWorkout:
        return Icons.fitness_center;
      case TileType.fitnessScore:
        return Icons.insights;
      case TileType.moodPicker:
        return Icons.wb_sunny_outlined;
      case TileType.dailyActivity:
        return Icons.watch;
      case TileType.quickActions:
        return Icons.apps;
      case TileType.weeklyProgress:
        return Icons.donut_large;
      case TileType.weeklyGoals:
        return Icons.flag_outlined;
      case TileType.weekChanges:
        return Icons.swap_horiz;
      case TileType.upcomingFeatures:
        return Icons.new_releases_outlined;
      case TileType.upcomingWorkouts:
        return Icons.calendar_today;
      case TileType.streakCounter:
        return Icons.local_fire_department;
      case TileType.personalRecords:
        return Icons.emoji_events;
      case TileType.aiCoachTip:
        return Icons.tips_and_updates;
      case TileType.challengeProgress:
        return Icons.military_tech;
      case TileType.caloriesSummary:
        return Icons.restaurant;
      case TileType.macroRings:
        return Icons.pie_chart;
      case TileType.bodyWeight:
        return Icons.monitor_weight;
      case TileType.progressPhoto:
        return Icons.compare;
      case TileType.socialFeed:
        return Icons.people;
      case TileType.leaderboardRank:
        return Icons.leaderboard;
      case TileType.fasting:
        return Icons.timer;
      case TileType.weeklyCalendar:
        return Icons.calendar_month;
      case TileType.muscleHeatmap:
        return Icons.accessibility_new;
      case TileType.sleepScore:
        return Icons.bedtime;
      case TileType.restDayTip:
        return Icons.spa;
      case TileType.quickStart:
        return Icons.play_circle_filled;
      case TileType.myJourney:
        return Icons.route;
      case TileType.progressCharts:
        return Icons.show_chart;
      case TileType.roiSummary:
        return Icons.trending_up;
      case TileType.weeklyPlan:
        return Icons.calendar_view_week;
      case TileType.weightTrend:
        return Icons.trending_up;
      case TileType.dailyStats:
        return Icons.bar_chart;
      case TileType.achievements:
        return Icons.emoji_events;
      case TileType.heroSection:
        return Icons.star;
      case TileType.quickLogWeight:
        return Icons.scale;
      case TileType.quickLogMeasurements:
        return Icons.straighten;
      case TileType.habits:
        return Icons.check_circle_outline;
    }
  }

  Color _getIconColorForCategory(TileCategory category) {
    switch (category) {
      case TileCategory.workout:
        return AppColors.cyan;
      case TileCategory.progress:
        return AppColors.green;
      case TileCategory.nutrition:
        return AppColors.orange;
      case TileCategory.social:
        return AppColors.purple;
      case TileCategory.wellness:
        return AppColors.yellow;
      case TileCategory.tools:
        return AppColors.cyan;
    }
  }
}
