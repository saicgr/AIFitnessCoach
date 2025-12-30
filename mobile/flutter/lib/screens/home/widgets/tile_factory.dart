import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/home_layout.dart';
import '../../../data/repositories/workout_repository.dart';
import 'cards/cards.dart';
import 'daily_activity_card.dart';
import 'components/components.dart';

/// Factory class for creating tile widgets based on TileType
class TileFactory {
  /// Build a widget for the given tile configuration
  static Widget buildTile(
    BuildContext context,
    WidgetRef ref,
    HomeTile tile, {
    bool isDark = true,
  }) {
    switch (tile.type) {
      case TileType.nextWorkout:
        return _buildNextWorkoutTile(context, ref, tile, isDark);
      case TileType.fitnessScore:
        return const FitnessScoreCard();
      case TileType.moodPicker:
        return const MoodPickerCard();
      case TileType.dailyActivity:
        return const DailyActivityCard();
      case TileType.quickActions:
        return const Padding(
          padding: EdgeInsets.only(top: 8, bottom: 8),
          child: QuickActionsRow(),
        );
      case TileType.weeklyProgress:
        return _buildWeeklyProgressTile(context, ref, tile, isDark);
      case TileType.weeklyGoals:
        return WeeklyGoalsCard(isDark: isDark);
      case TileType.weekChanges:
        return const WeekChangesCard();
      case TileType.upcomingFeatures:
        return const UpcomingFeaturesCard();
      case TileType.upcomingWorkouts:
        return _buildUpcomingWorkoutsTile(context, ref, tile, isDark);
      // New tiles - using real implementations
      case TileType.streakCounter:
        return StreakCounterCard(size: tile.size, isDark: isDark);
      case TileType.personalRecords:
        return PersonalRecordsCard(size: tile.size, isDark: isDark);
      case TileType.aiCoachTip:
        return AICoachTipCard(size: tile.size, isDark: isDark);
      case TileType.challengeProgress:
        return ActiveChallengeCard(size: tile.size, isDark: isDark);
      case TileType.caloriesSummary:
        return CaloriesSummaryCard(size: tile.size, isDark: isDark);
      case TileType.macroRings:
        return MacroRingsCard(size: tile.size, isDark: isDark);
      case TileType.bodyWeight:
        return BodyWeightCard(size: tile.size, isDark: isDark);
      case TileType.progressPhoto:
        return _buildPlaceholderTile(tile, isDark, 'Progress Photo');
      case TileType.socialFeed:
        return WorkoutHistoryMiniCard(size: tile.size, isDark: isDark);
      case TileType.leaderboardRank:
        return LeaderboardRankCard(size: tile.size, isDark: isDark);
      case TileType.fasting:
        return _buildPlaceholderTile(tile, isDark, 'Fasting Timer');
      case TileType.weeklyCalendar:
        return _buildPlaceholderTile(tile, isDark, 'Weekly Calendar');
      case TileType.muscleHeatmap:
        return _buildPlaceholderTile(tile, isDark, 'Muscle Heatmap');
      case TileType.sleepScore:
        return SleepScoreCard(size: tile.size, isDark: isDark);
      case TileType.restDayTip:
        return RestDayTipCard(size: tile.size, isDark: isDark);
    }
  }

  /// Build multiple tiles in a row for half-width tiles
  static Widget buildHalfWidthRow(
    BuildContext context,
    WidgetRef ref,
    List<HomeTile> tiles,
    bool isDark,
  ) {
    if (tiles.length == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: buildTile(context, ref, tiles[0], isDark: isDark),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: buildTile(context, ref, tiles[0], isDark: isDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: tiles.length > 1
                ? buildTile(context, ref, tiles[1], isDark: isDark)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  static Widget _buildNextWorkoutTile(
    BuildContext context,
    WidgetRef ref,
    HomeTile tile,
    bool isDark,
  ) {
    // This would need the workout data passed in
    // For now return a simplified version
    return Consumer(
      builder: (context, ref, child) {
        final workoutsNotifier = ref.read(workoutsProvider.notifier);
        final nextWorkout = workoutsNotifier.nextWorkout;

        if (nextWorkout != null) {
          return NextWorkoutCard(
            workout: nextWorkout,
            onStart: () {
              // Navigate to workout
            },
          );
        }

        return EmptyWorkoutCard(
          onGenerate: () async {
            await workoutsNotifier.checkAndRegenerateIfNeeded();
          },
        );
      },
    );
  }

  static Widget _buildWeeklyProgressTile(
    BuildContext context,
    WidgetRef ref,
    HomeTile tile,
    bool isDark,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        final workoutsNotifier = ref.read(workoutsProvider.notifier);
        final weeklyProgress = workoutsNotifier.weeklyProgress;

        return WeeklyProgressCard(
          completed: weeklyProgress.$1,
          total: weeklyProgress.$2,
          isDark: isDark,
        );
      },
    );
  }

  static Widget _buildUpcomingWorkoutsTile(
    BuildContext context,
    WidgetRef ref,
    HomeTile tile,
    bool isDark,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        final workoutsNotifier = ref.read(workoutsProvider.notifier);
        final upcomingWorkouts = workoutsNotifier.upcomingWorkouts;

        if (upcomingWorkouts.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: upcomingWorkouts.take(3).map((workout) {
            return UpcomingWorkoutCard(
              workout: workout,
              onTap: () {
                // Navigate to workout
              },
            );
          }).toList(),
        );
      },
    );
  }

  static Widget _buildPlaceholderTile(
    HomeTile tile,
    bool isDark,
    String title,
  ) {
    return _PlaceholderCard(
      title: title,
      tileType: tile.type,
      size: tile.size,
      isDark: isDark,
    );
  }
}

/// Placeholder card for unimplemented tiles
class _PlaceholderCard extends StatelessWidget {
  final String title;
  final TileType tileType;
  final TileSize size;
  final bool isDark;

  const _PlaceholderCard({
    required this.title,
    required this.tileType,
    required this.size,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevatedColor =
        isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : Colors.black;
    final textMuted = isDark ? Colors.white60 : Colors.black54;
    final iconColor = _getIconColor();

    final isCompact = size == TileSize.compact;
    final isHalf = size == TileSize.half;

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: iconColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getIcon(), color: iconColor, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: isHalf ? null : const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getIcon(), color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9C27B0).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'COMING SOON',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9C27B0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isHalf) ...[
            const SizedBox(height: 12),
            Text(
              tileType.description,
              style: TextStyle(
                fontSize: 13,
                color: textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getIcon() {
    switch (tileType) {
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
      default:
        return Icons.widgets;
    }
  }

  Color _getIconColor() {
    switch (tileType.category) {
      case TileCategory.workout:
        return const Color(0xFF00BCD4);
      case TileCategory.progress:
        return const Color(0xFF4CAF50);
      case TileCategory.nutrition:
        return const Color(0xFFFF9800);
      case TileCategory.social:
        return const Color(0xFF9C27B0);
      case TileCategory.wellness:
        return const Color(0xFFFFEB3B);
      case TileCategory.tools:
        return const Color(0xFF00BCD4);
    }
  }
}
