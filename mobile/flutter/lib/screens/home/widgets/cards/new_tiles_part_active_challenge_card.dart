part of 'new_tiles.dart';


/// ============================================================
/// ACTIVE CHALLENGE CARD
/// Shows progress on active workout challenge
/// ============================================================
class ActiveChallengeCard extends ConsumerWidget {
  final TileSize size;
  final bool isDark;

  const ActiveChallengeCard({
    super.key,
    this.size = TileSize.full,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final pinkColor = const Color(0xFFE91E63);

    final userId = ref.watch(currentUserIdProvider);
    final challengesAsync = userId != null
        ? ref.watch(userActiveChallengesProvider(userId))
        : const AsyncValue<List<Map<String, dynamic>>>.data([]);
    final challenges = challengesAsync.valueOrNull ?? [];
    final activeChallenge = challenges.isNotEmpty ? challenges.first : null;
    final challengeName = activeChallenge?['name'] as String? ?? 'No active challenge';
    final participation = activeChallenge?['user_participation'] as Map<String, dynamic>?;
    final currentDay = participation?['current_day'] as int? ?? 0;
    final totalDays = participation?['total_days'] as int? ?? 1;
    final todayReps = participation?['today_reps'] as int? ?? 0;
    final targetReps = participation?['target_reps'] as int? ?? 0;
    final progress = totalDays > 0 ? currentDay / totalDays : 0.0;

    return InkWell(
      onTap: () {
        HapticService.light();
        // Navigate to challenge detail
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: pinkColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: pinkColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.military_tech, color: pinkColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challengeName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Day $currentDay of $totalDays',
                        style: TextStyle(fontSize: 12, color: textMuted),
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
                value: progress,
                backgroundColor: textMuted.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(pinkColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Today: $todayReps / $targetReps reps',
                  style: TextStyle(fontSize: 13, color: textMuted),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    HapticService.medium();
                    // Start challenge workout
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pinkColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Start', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


/// ============================================================
/// REST DAY TIP CARD
/// Shows recovery tips on rest days
/// ============================================================
class RestDayTipCard extends StatelessWidget {
  final TileSize size;
  final bool isDark;

  const RestDayTipCard({
    super.key,
    this.size = TileSize.full,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final tealColor = const Color(0xFF009688);

    const tips = [
      'Get 7-9 hours of quality sleep tonight',
      'Stay hydrated - aim for 2-3 liters of water',
      'Light stretching can help muscle recovery',
      'Eat protein-rich foods to aid muscle repair',
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tealColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tealColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.spa, color: tealColor, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'Rest Day Recovery',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, color: tealColor, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(fontSize: 13, color: textMuted, height: 1.3),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}


/// ============================================================
/// WORKOUT HISTORY MINI CARD
/// Quick view of recent workout history
/// ============================================================
class WorkoutHistoryMiniCard extends ConsumerWidget {
  final TileSize size;
  final bool isDark;

  const WorkoutHistoryMiniCard({
    super.key,
    this.size = TileSize.full,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cyanColor = ref.colors(context).accent;

    final summaryAsync = ref.watch(workoutScreenSummaryProvider);
    final summary = summaryAsync.valueOrNull;
    final sessions = summary?.previousSessions ?? [];
    final recentWorkouts = sessions.take(3).map((w) {
      final date = DateTime.tryParse(w.scheduledDate);
      final daysAgo = date != null ? DateTime.now().difference(date).inDays : 0;
      final dateStr = daysAgo == 0 ? 'Today' : daysAgo == 1 ? 'Yesterday' : '$daysAgo days ago';
      return {'name': w.name, 'date': dateStr, 'duration': '${w.durationMinutes} min'};
    }).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: cyanColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Recent Workouts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  HapticService.light();
                  context.push('/stats');
                },
                child: Text(
                  'View All',
                  style: TextStyle(fontSize: 12, color: cyanColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...recentWorkouts.map((workout) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 32,
                      decoration: BoxDecoration(
                        color: cyanColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workout['name']!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                          Text(
                            workout['date']!,
                            style: TextStyle(fontSize: 11, color: textMuted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      workout['duration']!,
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}


/// ============================================================
/// STEPS COUNTER CARD
/// Today's step count from health API
/// ============================================================
class StepsCounterCard extends ConsumerWidget {
  final TileSize size;
  final bool isDark;

  const StepsCounterCard({
    super.key,
    this.size = TileSize.half,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final greenColor = AppColors.green;

    final steps = ref.watch(currentStepsProvider);
    final targetSteps = ref.watch(stepGoalProvider);
    final progress = ref.watch(stepProgressProvider);

    return Container(
      margin: size == TileSize.full
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
          : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: greenColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_walk, color: greenColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Steps',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            steps.toString().replaceAllMapped(
              RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
              (match) => '${match.group(1)},',
            ),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: textMuted.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(greenColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(progress * 100).toInt()}% of $targetSteps goal',
            style: TextStyle(fontSize: 11, color: textMuted),
          ),
        ],
      ),
    );
  }
}


/// ============================================================
/// HEART RATE CARD
/// Current/resting heart rate
/// ============================================================
class HeartRateCard extends ConsumerWidget {
  final TileSize size;
  final bool isDark;

  const HeartRateCard({
    super.key,
    this.size = TileSize.half,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final redColor = AppColors.error;

    final recoveryAsync = ref.watch(recoveryProvider);
    final recovery = recoveryAsync.valueOrNull;
    final currentBPM = recovery?.restingHR;
    final restingBPM = recovery?.restingHR;

    return Container(
      margin: size == TileSize.full
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
          : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: redColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: redColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Heart Rate',
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
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currentBPM?.toString() ?? '--',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('BPM', style: TextStyle(fontSize: 14, color: textMuted)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            restingBPM != null ? 'Resting: $restingBPM BPM' : 'Connect Health to track',
            style: TextStyle(fontSize: 11, color: textMuted),
          ),
        ],
      ),
    );
  }
}

