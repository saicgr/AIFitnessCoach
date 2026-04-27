import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/home_layout.dart';
import '../../../data/services/health_service.dart';
import '../../../widgets/app_tour/app_tour_controller.dart';
import '../../../data/repositories/workout_repository.dart';
// import '../../../widgets/xp_progress_card.dart'; // Coming soon
import 'cards/cards.dart';
// import 'cards/roi_summary_card.dart'; // Coming soon
// import 'cards/weekly_plan_card.dart'; // Coming soon
// import 'daily_activity_card.dart'; // Coming soon
import 'components/components.dart';
import 'habits_section.dart';
// import 'body_metrics_section.dart'; // Coming soon
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
        // Coming soon
        return const SizedBox.shrink();
      case TileType.nextWorkout:
        return _buildNextWorkoutTile(context, ref, tile, isDark);
      case TileType.fitnessScore:
        // Coming soon
        return const SizedBox.shrink();
      case TileType.moodPicker:
        // Coming soon
        return const SizedBox.shrink();
      case TileType.dailyActivity:
        // Coming soon
        return const SizedBox.shrink();
      case TileType.quickActions:
        return Padding(
          key: AppTourKeys.quickLogKey,
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: const QuickActionsRow(),
        );
      case TileType.weeklyProgress:
        // Removed feature - return empty widget
        return const SizedBox.shrink();
      case TileType.weeklyGoals:
        return WeeklyGoalsCard(isDark: isDark);
      case TileType.weekChanges:
        // Coming soon
        return const SizedBox.shrink();
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
        // Coming soon
        return const SizedBox.shrink();
      case TileType.caloriesSummary:
        return CaloriesSummaryCard(size: tile.size, isDark: isDark);
      case TileType.macroRings:
        return MacroRingsCard(size: tile.size, isDark: isDark);
      case TileType.bodyWeight:
        // Coming soon
        return const SizedBox.shrink();
      case TileType.progressPhoto:
        // Coming soon
        return const SizedBox.shrink();
      case TileType.socialFeed:
        // Coming soon
        return const SizedBox.shrink();
      case TileType.leaderboardRank:
        // Coming soon
        return const SizedBox.shrink();
      case TileType.fasting:
        return FastingTimerCard(size: tile.size, isDark: isDark);
      case TileType.weeklyCalendar:
        // Coming soon
        return const SizedBox.shrink();
      case TileType.muscleHeatmap:
        // Coming soon
        return const SizedBox.shrink();
      case TileType.sleepScore:
        // Re-activated 2026-04-25 — surfaces the existing Health Connect /
        // HealthKit SLEEP_DEEP / SLEEP_LIGHT / SLEEP_REM samples that the
        // dailyActivityProvider already collects but had no UI for. Renders
        // nothing when no sleep was tracked last night, so layouts that
        // include this tile stay clean for users without a wearable.
        return const LastNightSleepCard();
      case TileType.restDayTip:
        // Coming soon
        return const SizedBox.shrink();
      case TileType.myJourney:
        // Coming soon
        return const SizedBox.shrink();
      case TileType.progressCharts:
        // Coming soon
        return const SizedBox.shrink();
      case TileType.roiSummary:
        // Coming soon
        return const SizedBox.shrink();
      case TileType.weeklyPlan:
        // Coming soon
        return const SizedBox.shrink();
      // New fat loss UX tiles
      case TileType.weightTrend:
        // Deprecated - return empty widget
        return const SizedBox.shrink();
      case TileType.dailyStats:
        // Coming soon
        return const SizedBox.shrink();
      case TileType.achievements:
        return const AchievementsSection();
      case TileType.heroSection:
        // Hero section removed - return empty widget
        return const SizedBox.shrink();
      case TileType.quickLogWeight:
        return QuickLogWeightCard(size: tile.size, isDark: isDark);
      case TileType.quickLogMeasurements:
        // Coming soon
        return const SizedBox.shrink();
      case TileType.habits:
        return const HabitsSection();
      case TileType.xpProgress:
        // Coming soon
        return const SizedBox.shrink();
      case TileType.upNext:
        // Coming soon
        return const SizedBox.shrink();
      case TileType.todayStats:
        return const TodayStatsRow();
      case TileType.stepsCounter:
        // The single-metric DailyStepsTile (just steps + ring) was the only
        // surfacing of Health Connect data and didn't show calories or HR
        // even when both were available — competitors (GymBeat, FitOn) ship
        // a richer composite. We now render the composite when the user is
        // connected and fall back to the original tile (which owns the
        // "Connect" CTA) when they aren't.
        return Consumer(builder: (context, ref, _) {
          final connected = ref.watch(healthSyncProvider).isConnected;
          return connected
              ? const TodaysHealthCard()
              : const DailyStepsTile();
        });
      case TileType.nutritionPatterns:
        return const _NutritionPatternsTile();
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

/// Home-screen tile that deep-links into Nutrition > Patterns. Subtitle is
/// dynamic — surfaces the user's top draining food when available, otherwise
/// a first-time CTA.
class _NutritionPatternsTile extends ConsumerWidget {
  const _NutritionPatternsTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06);

    // Read lazily — if the user hasn't signed in yet, bail to a neutral card.
    return GestureDetector(
      onTap: () => context.go('/nutrition?tab=2'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.insights_rounded, color: Color(0xFF6366F1)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Food Patterns',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'See which foods fuel you and which drag you down',
                    style: TextStyle(fontSize: 12, height: 1.35),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14),
          ],
        ),
      ),
    );
  }
}

