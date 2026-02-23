import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/home_layout.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../widgets/xp_progress_card.dart';
import 'cards/cards.dart';
import 'cards/roi_summary_card.dart';
import 'cards/weekly_plan_card.dart';
import 'daily_activity_card.dart';
import 'components/components.dart';
import 'habits_section.dart';
import 'body_metrics_section.dart';
import 'achievements_section.dart';
import 'today_stats_row.dart';

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
      case TileType.quickStart:
        return QuickStartCard(isDark: isDark);
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
        // Removed feature - return empty widget
        return const SizedBox.shrink();
      case TileType.weeklyGoals:
        return WeeklyGoalsCard(isDark: isDark);
      case TileType.weekChanges:
        return const WeekChangesCard();
      case TileType.upcomingFeatures:
        // Removed feature - return empty widget
        return const SizedBox.shrink();
      case TileType.upcomingWorkouts:
        return _buildUpcomingWorkoutsTile(context, ref, tile, isDark);
      // New tiles - using real implementations
      case TileType.streakCounter:
        // Deprecated - return empty widget
        return const SizedBox.shrink();
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
        return const BodyMetricsSection();
      case TileType.progressPhoto:
        return ProgressPhotoCard(size: tile.size, isDark: isDark);
      case TileType.socialFeed:
        return WorkoutHistoryMiniCard(size: tile.size, isDark: isDark);
      case TileType.leaderboardRank:
        return LeaderboardRankCard(size: tile.size, isDark: isDark);
      case TileType.fasting:
        return FastingTimerCard(size: tile.size, isDark: isDark);
      case TileType.weeklyCalendar:
        return WeeklyCalendarCard(size: tile.size, isDark: isDark);
      case TileType.muscleHeatmap:
        return MuscleHeatmapCard(size: tile.size, isDark: isDark);
      case TileType.sleepScore:
        // Deprecated - return empty widget
        return const SizedBox.shrink();
      case TileType.restDayTip:
        return RestDayTipCard(size: tile.size, isDark: isDark);
      case TileType.myJourney:
        return MyJourneyCard(size: tile.size, isDark: isDark);
      case TileType.progressCharts:
        return ProgressChartsTile(size: tile.size, isDark: isDark);
      case TileType.roiSummary:
        return const ROISummaryCard();
      case TileType.weeklyPlan:
        return const WeeklyPlanCard();
      // New fat loss UX tiles
      case TileType.weightTrend:
        // Deprecated - return empty widget
        return const SizedBox.shrink();
      case TileType.dailyStats:
        return DailyStatsCard(size: tile.size, isDark: isDark);
      case TileType.achievements:
        return const AchievementsSection();
      case TileType.heroSection:
        // Hero section removed - return empty widget
        return const SizedBox.shrink();
      case TileType.quickLogWeight:
        return QuickLogWeightCard(size: tile.size, isDark: isDark);
      case TileType.quickLogMeasurements:
        return QuickLogMeasurementsCard(size: tile.size, isDark: isDark);
      case TileType.habits:
        return const HabitsSection();
      case TileType.xpProgress:
        return XPProgressCard(size: tile.size, isDark: isDark);
      case TileType.upNext:
        return UpNextCard(isDark: isDark);
      case TileType.todayStats:
        return const TodayStatsRow();
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
    // M5: Use Consumer with selective read to avoid full provider rebuilds
    return Consumer(
      builder: (context, ref, child) {
        // TODO: M5 - Ideally use ref.watch(workoutsProvider.select((s) => s.valueOrNull?.nextWorkout))
        // but nextWorkout is a getter on the notifier, not on the state value.
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
          onGenerate: () {
            // Navigate to Workouts tab where user can generate more
            context.go('/workouts');
          },
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
        // TODO: M5 - Ideally use ref.watch(workoutsProvider.select(...)) for upcomingWorkouts
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

}

