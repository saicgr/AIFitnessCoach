import 'package:flutter/material.dart';
import '../../../data/models/home_layout.dart';

/// Static mock tile widget for preset preview. No providers, no API calls.
class PreviewTileMock extends StatelessWidget {
  final TileType tileType;

  const PreviewTileMock({super.key, required this.tileType});

  @override
  Widget build(BuildContext context) {
    if (tileType == TileType.fitnessScore) {
      return _buildScoreCard(context);
    }
    final data = _mockData;
    final isHalf = tileType.defaultSize == TileSize.half;

    if (isHalf) {
      return _buildHalfCard(context, data);
    }
    return _buildFullCard(context, data);
  }

  _MockTileData get _mockData {
    switch (tileType) {
      case TileType.nextWorkout:
        return _MockTileData(
          icon: Icons.fitness_center,
          color: const Color(0xFF00BCD4),
          title: 'Push Day - Chest & Triceps',
          subtitle: '45 min - 6 exercises',
        );
      case TileType.fitnessScore:
        return _MockTileData(
          icon: Icons.insights,
          color: const Color(0xFF22C55E),
          title: 'Fitness Score',
          subtitle: 'Good progress',
          value: '72',
        );
      case TileType.bodyWeight:
        return _MockTileData(
          icon: Icons.monitor_weight,
          color: const Color(0xFF22C55E),
          title: 'Weight Tracker',
          subtitle: '-0.3 kg this week',
          value: '72.5 kg',
        );
      case TileType.caloriesSummary:
        return _MockTileData(
          icon: Icons.restaurant,
          color: const Color(0xFFF97316),
          title: 'Calories',
          subtitle: 'On track',
          value: '1,650 / 2,200',
        );
      case TileType.macroRings:
        return _MockTileData(
          icon: Icons.pie_chart,
          color: const Color(0xFFA855F7),
          title: 'Macros',
          subtitle: 'P: 120g  C: 180g  F: 65g',
        );
      case TileType.personalRecords:
        return _MockTileData(
          icon: Icons.emoji_events,
          color: const Color(0xFFEAB308),
          title: 'Personal Records',
          subtitle: '2 new PRs this week',
          value: 'Bench 80 kg',
        );
      case TileType.dailyStats:
        return _MockTileData(
          icon: Icons.directions_walk,
          color: const Color(0xFF22C55E),
          title: 'Daily Stats',
          subtitle: '320 kcal burned',
          value: '8,234 steps',
        );
      case TileType.habits:
        return _MockTileData(
          icon: Icons.checklist,
          color: const Color(0xFF3B82F6),
          title: 'Today\'s Habits',
          subtitle: '3/5 habits completed today',
        );
      case TileType.achievements:
        return _MockTileData(
          icon: Icons.emoji_events,
          color: const Color(0xFFA855F7),
          title: 'Achievements',
          subtitle: '12 badges unlocked',
        );
      case TileType.quickLogWeight:
        return _MockTileData(
          icon: Icons.scale,
          color: const Color(0xFF22C55E),
          title: 'Quick Log Weight',
          subtitle: 'Tap to log today\'s weight',
          value: '72.5 kg',
        );
      case TileType.quickLogMeasurements:
        return _MockTileData(
          icon: Icons.straighten,
          color: const Color(0xFF00BCD4),
          title: 'Quick Measurements',
          subtitle: 'Chest, waist, arms & more',
        );
      case TileType.muscleHeatmap:
        return _MockTileData(
          icon: Icons.accessibility_new,
          color: const Color(0xFFEF4444),
          title: 'Muscle Map',
          subtitle: 'Chest & back trained today',
        );
      case TileType.weekChanges:
        return _MockTileData(
          icon: Icons.swap_horiz,
          color: const Color(0xFF00BCD4),
          title: 'Week Changes',
          subtitle: '3 exercises varied',
        );
      case TileType.challengeProgress:
        return _MockTileData(
          icon: Icons.military_tech,
          color: const Color(0xFFF97316),
          title: 'Active Challenge',
          subtitle: '7/30 days completed',
        );
      case TileType.aiCoachTip:
        return _MockTileData(
          icon: Icons.tips_and_updates,
          color: const Color(0xFFEAB308),
          title: 'Coach Tip',
          subtitle: 'Try adding a warm-up set before heavy lifts',
        );
      case TileType.fasting:
        return _MockTileData(
          icon: Icons.timer,
          color: const Color(0xFFF97316),
          title: 'Fasting Timer',
          subtitle: '14h 30m / 16h elapsed',
        );
      case TileType.moodPicker:
        return _MockTileData(
          icon: Icons.wb_sunny_outlined,
          color: const Color(0xFFEAB308),
          title: 'Mood Check-in',
          subtitle: 'How are you feeling today?',
        );
      case TileType.quickActions:
        return _MockTileData(
          icon: Icons.apps,
          color: const Color(0xFF3B82F6),
          title: 'Quick Actions',
          subtitle: 'Log Food, Stats, Share, Water',
        );
      case TileType.progressCharts:
        return _MockTileData(
          icon: Icons.show_chart,
          color: const Color(0xFF22C55E),
          title: 'Progress Charts',
          subtitle: 'Strength & volume over time',
        );
      case TileType.roiSummary:
        return _MockTileData(
          icon: Icons.trending_up,
          color: const Color(0xFF3B82F6),
          title: 'Your Journey ROI',
          subtitle: '48 workouts, 36 hrs invested',
        );
      case TileType.dailyActivity:
        return _MockTileData(
          icon: Icons.watch,
          color: const Color(0xFF00BCD4),
          title: 'Daily Activity',
          subtitle: 'Health device summary',
        );
      default:
        return _MockTileData(
          icon: Icons.widgets,
          color: const Color(0xFF71717A),
          title: tileType.displayName,
          subtitle: tileType.description,
        );
    }
  }

  Widget _buildFullCard(BuildContext context, _MockTileData data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF4F4F5);
    final textColor = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF18181B);
    final mutedColor = isDark ? const Color(0xFF71717A) : const Color(0xFF71717A);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: data.color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  data.subtitle,
                  style: TextStyle(fontSize: 12, color: mutedColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (data.value != null) ...[
            const SizedBox(width: 8),
            Text(
              data.value!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: data.color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHalfCard(BuildContext context, _MockTileData data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF4F4F5);
    final textColor = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF18181B);
    final mutedColor = isDark ? const Color(0xFF71717A) : const Color(0xFF71717A);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: data.color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(data.icon, color: data.color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (data.value != null)
            Text(
              data.value!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: data.color,
              ),
            ),
          Text(
            data.subtitle,
            style: TextStyle(fontSize: 10, color: mutedColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF4F4F5);
    final textColor = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF18181B);
    final mutedColor = isDark ? const Color(0xFF71717A) : const Color(0xFF71717A);
    const scoreColor = Color(0xFF22C55E);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scoreColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: 0.72,
                  strokeWidth: 5,
                  backgroundColor: scoreColor.withOpacity(0.15),
                  valueColor: const AlwaysStoppedAnimation(scoreColor),
                ),
                Text(
                  '72',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fitness Score',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Good progress - keep it up!',
                  style: TextStyle(fontSize: 12, color: mutedColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MockTileData {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? value;

  const _MockTileData({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.value,
  });
}
