part of 'new_tiles.dart';


/// ============================================================
/// MY JOURNEY CARD
/// Shows user's fitness journey progress - where they started,
/// where they are now, and what's next on their path
/// ============================================================
class MyJourneyCard extends ConsumerWidget {
  final TileSize size;
  final bool isDark;

  const MyJourneyCard({
    super.key,
    this.size = TileSize.full,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentColor = ref.colors(context).accent;

    // M5: TODO - Ideally use ref.watch(workoutsProvider.select(...)) for these fields
    // but they are getters on the notifier, not on the state value.
    final workoutsNotifier = ref.read(workoutsProvider.notifier);
    final currentStreak = workoutsNotifier.currentStreak;
    final totalCompleted = workoutsNotifier.completedCount;

    // Calculate journey stats
    final weeklyProgress = workoutsNotifier.weeklyProgress;
    final weekNumber = ((totalCompleted / 3).ceil()).clamp(1, 52);
    final workoutsThisWeek = weeklyProgress.$1;
    final targetWorkoutsPerWeek = 4; // Could be personalized

    // Journey milestones
    final milestones = _getJourneyMilestones(totalCompleted);
    final currentMilestone = milestones.lastWhere(
      (m) => (m['threshold'] as num).toInt() <= totalCompleted,
      orElse: () => milestones.first,
    );
    final nextMilestone = milestones.firstWhere(
      (m) => (m['threshold'] as num).toInt() > totalCompleted,
      orElse: () => milestones.last,
    );

    final progressToNext = totalCompleted > 0
        ? (totalCompleted - (currentMilestone['threshold'] as num).toInt()) /
            ((nextMilestone['threshold'] as num).toInt() - (currentMilestone['threshold'] as num).toInt())
        : 0.0;

    if (size == TileSize.half) {
      return _buildHalfSize(
        context,
        elevatedColor,
        textColor,
        textMuted,
        accentColor,
        weekNumber,
        currentMilestone,
        progressToNext,
      );
    }

    return InkWell(
      onTap: () {
        HapticService.light();
        context.push('/stats');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              elevatedColor,
              accentColor.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.route, color: accentColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Journey',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'Week $weekNumber',
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Current level badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color((currentMilestone['color'] as num).toInt()).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        currentMilestone['icon'] as IconData,
                        color: Color((currentMilestone['color'] as num).toInt()),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        currentMilestone['title'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color((currentMilestone['color'] as num).toInt()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Progress to next milestone
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Next: ${nextMilestone['title']}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Text(
                      '$totalCompleted / ${nextMilestone['threshold']} workouts',
                      style: TextStyle(
                        fontSize: 12,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progressToNext.clamp(0.0, 1.0),
                    backgroundColor: textMuted.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    minHeight: 10,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Stats row
            Row(
              children: [
                _buildStatChip(
                  icon: Icons.local_fire_department,
                  value: '$currentStreak',
                  label: 'day streak',
                  color: AppColors.orange,
                  textMuted: textMuted,
                  textColor: textColor,
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  icon: Icons.check_circle,
                  value: '$workoutsThisWeek/$targetWorkoutsPerWeek',
                  label: 'this week',
                  color: AppColors.green,
                  textMuted: textMuted,
                  textColor: textColor,
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  icon: Icons.emoji_events,
                  value: '$totalCompleted',
                  label: 'total',
                  color: const Color(0xFFFFD700),
                  textMuted: textMuted,
                  textColor: textColor,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // What's next prompt
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.arrow_forward_ios, color: accentColor, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getNextStepMessage(workoutsThisWeek, targetWorkoutsPerWeek),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getMotivationMessage(currentStreak, totalCompleted),
                          style: TextStyle(
                            fontSize: 11,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHalfSize(
    BuildContext context,
    Color elevatedColor,
    Color textColor,
    Color textMuted,
    Color accentColor,
    int weekNumber,
    Map<String, dynamic> currentMilestone,
    double progressToNext,
  ) {
    return InkWell(
      onTap: () {
        HapticService.light();
        context.push('/stats');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'My Journey',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  currentMilestone['icon'] as IconData,
                  color: Color((currentMilestone['color'] as num).toInt()),
                  size: 28,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentMilestone['title'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'Week $weekNumber',
                        style: TextStyle(fontSize: 11, color: textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressToNext.clamp(0.0, 1.0),
                backgroundColor: textMuted.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to see your full journey',
              style: TextStyle(fontSize: 10, color: textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color textMuted,
    required Color textColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: textMuted),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getJourneyMilestones(int totalWorkouts) {
    return [
      {
        'threshold': 0,
        'title': 'Getting Started',
        'icon': Icons.flag,
        'color': 0xFF9E9E9E,
      },
      {
        'threshold': 5,
        'title': 'Beginner',
        'icon': Icons.directions_walk,
        'color': 0xFF4CAF50,
      },
      {
        'threshold': 15,
        'title': 'Building Habit',
        'icon': Icons.trending_up,
        'color': 0xFF2196F3,
      },
      {
        'threshold': 30,
        'title': 'Consistent',
        'icon': Icons.check_circle,
        'color': 0xFF9C27B0,
      },
      {
        'threshold': 50,
        'title': 'Dedicated',
        'icon': Icons.star,
        'color': 0xFFFF9800,
      },
      {
        'threshold': 100,
        'title': 'Athlete',
        'icon': Icons.sports_gymnastics,
        'color': 0xFFE91E63,
      },
      {
        'threshold': 200,
        'title': 'Champion',
        'icon': Icons.emoji_events,
        'color': 0xFFFFD700,
      },
      {
        'threshold': 365,
        'title': 'Legend',
        'icon': Icons.military_tech,
        'color': 0xFF00BCD4,
      },
    ];
  }

  String _getNextStepMessage(int workoutsThisWeek, int target) {
    final remaining = target - workoutsThisWeek;
    if (remaining <= 0) {
      return 'Weekly goal complete!';
    } else if (remaining == 1) {
      return '1 workout left this week';
    } else {
      return '$remaining workouts left this week';
    }
  }

  String _getMotivationMessage(int streak, int total) {
    if (streak >= 7) {
      return 'Amazing streak! You\'re unstoppable!';
    } else if (streak >= 3) {
      return 'Keep the momentum going!';
    } else if (total >= 50) {
      return 'You\'ve come so far. Keep pushing!';
    } else if (total >= 10) {
      return 'Building great habits!';
    } else {
      return 'Every workout counts. Let\'s go!';
    }
  }
}


/// ============================================================
/// PROGRESS CHARTS TILE
/// Quick access tile to view detailed progress charts
/// ============================================================
class ProgressChartsTile extends ConsumerWidget {
  final TileSize size;
  final bool isDark;

  const ProgressChartsTile({
    super.key,
    this.size = TileSize.full,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = AppColors.success;

    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('/progress-charts');
      },
      child: Container(
        margin: size == TileSize.full
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
            : null,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: size == TileSize.half
            ? _buildHalfContent(textColor, textMuted, accentColor)
            : _buildFullContent(textColor, textMuted, accentColor),
      ),
    );
  }

  Widget _buildHalfContent(Color textColor, Color textMuted, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.show_chart, color: accentColor, size: 20),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: textMuted, size: 20),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Progress',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        Text(
          'View charts',
          style: TextStyle(
            fontSize: 12,
            color: textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildFullContent(Color textColor, Color textMuted, Color accentColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.show_chart, color: accentColor, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progress Charts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'View strength and volume trends over time',
                style: TextStyle(
                  fontSize: 13,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.chevron_right, color: textMuted, size: 24),
      ],
    );
  }
}

