import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../data/models/home_layout.dart';
import '../../../../data/providers/ai_insights_provider.dart';
import '../../../../data/repositories/workout_repository.dart';
import '../../../../data/services/haptic_service.dart';

/// ============================================================
/// STREAK COUNTER CARD
/// Shows current workout streak with fire animation
/// ============================================================
class StreakCounterCard extends ConsumerWidget {
  final TileSize size;
  final bool isDark;

  const StreakCounterCard({
    super.key,
    this.size = TileSize.half,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // M5: TODO - Ideally use ref.watch(workoutsProvider.select((s) => s.valueOrNull?.currentStreak))
    // but currentStreak is a getter on the notifier, not on the state value.
    final workoutsNotifier = ref.read(workoutsProvider.notifier);
    final currentStreak = workoutsNotifier.currentStreak;

    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final orangeColor = AppColors.orange;

    if (size == TileSize.compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: orangeColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // M6: orangeColor is from AppColors (not const-constructable with dynamic color)
            Icon(Icons.local_fire_department, color: orangeColor, size: 20),
            const SizedBox(width: 6),
            Text(
              '$currentStreak',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: currentStreak > 0 ? orangeColor : textColor,
              ),
            ),
          ],
        ),
      );
    }

    // Half or Full size
    return Container(
      margin: size == TileSize.full
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
          : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: orangeColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: orangeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.local_fire_department, color: orangeColor, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'Streak',
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
            '$currentStreak',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: currentStreak > 0 ? orangeColor : textColor,
            ),
          ),
          Text(
            currentStreak == 1 ? 'day' : 'days',
            style: TextStyle(fontSize: 14, color: textMuted),
          ),
          if (currentStreak > 0) ...[
            const SizedBox(height: 8),
            Text(
              currentStreak >= 7
                  ? 'Amazing streak! Keep going!'
                  : 'Keep the fire burning!',
              style: TextStyle(
                fontSize: 12,
                color: textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ============================================================
/// PERSONAL RECORDS CARD
/// Shows recent PRs (Personal Records) achieved
/// ============================================================
class PersonalRecordsCard extends ConsumerWidget {
  final TileSize size;
  final bool isDark;

  const PersonalRecordsCard({
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
    final accentColor = ref.colors(context).accent;

    // TODO: Connect to actual PR data from provider
    final mockPRs = [
      {'exercise': 'Bench Press', 'value': '100kg', 'date': '2 days ago'},
      {'exercise': 'Squat', 'value': '140kg', 'date': '1 week ago'},
      {'exercise': 'Deadlift', 'value': '180kg', 'date': '2 weeks ago'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.emoji_events, color: accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'Personal Records',
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
                  context.push('/achievements');
                },
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...mockPRs.take(size == TileSize.half ? 2 : 3).map((pr) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.military_tech, color: accentColor, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pr['exercise']!,
                        style: TextStyle(fontSize: 14, color: textColor),
                      ),
                    ),
                    Text(
                      pr['value']!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
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
/// AI COACH TIP CARD
/// Daily tip from AI coach (powered by Gemini)
/// ============================================================
class AICoachTipCard extends ConsumerWidget {
  final TileSize size;
  final bool isDark;

  const AICoachTipCard({
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
    final accentColor = ref.colors(context).accent;

    // Watch the daily tip provider
    final tipAsync = ref.watch(dailyTipProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.tips_and_updates, color: accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Coach Tip',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: accentColor, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'AI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          tipAsync.when(
            data: (tip) => Text(
              tip ?? _getDefaultTip(),
              style: TextStyle(
                fontSize: 14,
                color: textMuted,
                height: 1.4,
              ),
            ),
            loading: () => _buildLoadingState(textMuted),
            error: (_, __) => Text(
              _getDefaultTip(),
              style: TextStyle(
                fontSize: 14,
                color: textMuted,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              HapticService.light();
              context.push('/chat');
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ask coach for more',
                  style: TextStyle(
                    fontSize: 13,
                    color: accentColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward, color: accentColor, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(Color textMuted) {
    return Row(
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: textMuted,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Getting your personalized tip...',
          style: TextStyle(
            fontSize: 14,
            color: textMuted,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  String _getDefaultTip() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Start your day with 10 minutes of stretching to boost energy and flexibility.";
    } else if (hour < 17) {
      return "Stay hydrated! Aim for at least 8 glasses of water before dinner.";
    } else {
      return "Wind down with some light mobility work to improve tomorrow's workout.";
    }
  }
}

/// ============================================================
/// CALORIES SUMMARY CARD
/// Today's calorie intake vs target
/// ============================================================
class CaloriesSummaryCard extends ConsumerWidget {
  final TileSize size;
  final bool isDark;

  const CaloriesSummaryCard({
    super.key,
    this.size = TileSize.half,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = ref.colors(context).accent;

    // TODO: Connect to nutrition provider
    const consumed = 1850;
    const target = 2200;
    final progress = consumed / target;

    return Container(
      margin: size == TileSize.full
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
          : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Calories',
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
                '$consumed',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '/ $target',
                  style: TextStyle(fontSize: 14, color: textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: textMuted.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 1.0 ? AppColors.error : accentColor,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${target - consumed} kcal remaining',
            style: TextStyle(fontSize: 11, color: textMuted),
          ),
        ],
      ),
    );
  }
}

/// ============================================================
/// MACRO RINGS CARD
/// Visual donut charts for Protein/Carbs/Fat
/// ============================================================
class MacroRingsCard extends ConsumerWidget {
  final TileSize size;
  final bool isDark;

  const MacroRingsCard({
    super.key,
    this.size = TileSize.half,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = ref.colors(context).accent;

    // TODO: Connect to nutrition provider
    // Use accent color with varying opacity for visual distinction
    final macros = [
      {'name': 'Protein', 'current': 120, 'target': 150, 'color': accentColor},
      {'name': 'Carbs', 'current': 180, 'target': 250, 'color': accentColor.withValues(alpha: 0.7)},
      {'name': 'Fat', 'current': 55, 'target': 70, 'color': accentColor.withValues(alpha: 0.4)},
    ];

    return Container(
      margin: size == TileSize.full
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
          : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Macros',
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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: macros.map((macro) {
              final progress = (macro['current'] as int) / (macro['target'] as int);
              final color = macro['color'] as Color;

              return Column(
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          strokeWidth: 4,
                          backgroundColor: textMuted.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    macro['name'] as String,
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// ============================================================
/// BODY WEIGHT CARD
/// Recent weight with trend arrow
/// ============================================================
class BodyWeightCard extends ConsumerWidget {
  final TileSize size;
  final bool isDark;

  const BodyWeightCard({
    super.key,
    this.size = TileSize.half,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = ref.colors(context).accent;

    // TODO: Connect to measurements provider
    const currentWeight = 75.5;
    const previousWeight = 76.2;
    final change = currentWeight - previousWeight;
    final isDown = change < 0;

    return InkWell(
      onTap: () {
        HapticService.light();
        context.push('/measurements');
      },
      borderRadius: BorderRadius.circular(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monitor_weight, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Weight',
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
                  currentWeight.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('kg', style: TextStyle(fontSize: 14, color: textMuted)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDown ? Icons.trending_down : Icons.trending_up,
                        size: 14,
                        color: accentColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${change.abs().toStringAsFixed(1)} kg',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
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
/// LEADERBOARD RANK CARD
/// User's position on the leaderboard
/// ============================================================
class LeaderboardRankCard extends ConsumerWidget {
  final TileSize size;
  final bool isDark;

  const LeaderboardRankCard({
    super.key,
    this.size = TileSize.half,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = ref.colors(context).accent;

    // TODO: Connect to leaderboard provider
    const rank = 42;
    const totalUsers = 1250;
    final percentile = ((totalUsers - rank) / totalUsers * 100).toInt();

    return InkWell(
      onTap: () {
        HapticService.light();
        context.push('/social');
      },
      borderRadius: BorderRadius.circular(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.leaderboard, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Rank',
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
                  '#$rank',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Top $percentile%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    Text(
                      'of $totalUsers users',
                      style: TextStyle(fontSize: 10, color: textMuted),
                    ),
                  ],
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
/// WATER INTAKE CARD
/// Daily hydration tracking
/// ============================================================
class WaterIntakeCard extends ConsumerWidget {
  final TileSize size;
  final bool isDark;

  const WaterIntakeCard({
    super.key,
    this.size = TileSize.half,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = ref.colors(context).accent;

    // TODO: Connect to hydration provider
    const glasses = 5;
    const targetGlasses = 8;
    final progress = glasses / targetGlasses;

    return InkWell(
      onTap: () {
        HapticService.light();
        context.push('/hydration');
      },
      borderRadius: BorderRadius.circular(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.water_drop, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Water',
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
              children: List.generate(targetGlasses, (index) {
                final isFilled = index < glasses;
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    isFilled ? Icons.water_drop : Icons.water_drop_outlined,
                    color: isFilled ? accentColor : textMuted.withValues(alpha: 0.3),
                    size: 18,
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              '$glasses / $targetGlasses glasses',
              style: TextStyle(fontSize: 12, color: textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================
/// SLEEP SCORE CARD
/// Last night's sleep quality
/// ============================================================
class SleepScoreCard extends StatelessWidget {
  final TileSize size;
  final bool isDark;

  const SleepScoreCard({
    super.key,
    this.size = TileSize.half,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final purpleColor = const Color(0xFF7C4DFF);

    // TODO: Connect to Health API
    const sleepHours = 7.5;
    const sleepScore = 85;

    return Container(
      margin: size == TileSize.full
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
          : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: purpleColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bedtime, color: purpleColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Sleep',
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
                '${sleepHours}h',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: purpleColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$sleepScore',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: purpleColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Good quality sleep',
            style: TextStyle(fontSize: 11, color: textMuted),
          ),
        ],
      ),
    );
  }
}

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

    // TODO: Connect to challenges provider
    const challengeName = '30-Day Push-up Challenge';
    const currentDay = 12;
    const totalDays = 30;
    const todayReps = 0;
    const targetReps = 50;
    final progress = currentDay / totalDays;

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

    // TODO: Connect to workout history provider
    final recentWorkouts = [
      {'name': 'Upper Body', 'date': 'Yesterday', 'duration': '45 min'},
      {'name': 'Lower Body', 'date': '2 days ago', 'duration': '52 min'},
      {'name': 'Push Day', 'date': '4 days ago', 'duration': '38 min'},
    ];

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
class StepsCounterCard extends StatelessWidget {
  final TileSize size;
  final bool isDark;

  const StepsCounterCard({
    super.key,
    this.size = TileSize.half,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final greenColor = AppColors.green;

    // TODO: Connect to Health API
    const steps = 7842;
    const targetSteps = 10000;
    final progress = steps / targetSteps;

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
class HeartRateCard extends StatelessWidget {
  final TileSize size;
  final bool isDark;

  const HeartRateCard({
    super.key,
    this.size = TileSize.half,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final redColor = AppColors.error;

    // TODO: Connect to Health API
    const currentBPM = 72;
    const restingBPM = 62;

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
                '$currentBPM',
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
            'Resting: $restingBPM BPM',
            style: TextStyle(fontSize: 11, color: textMuted),
          ),
        ],
      ),
    );
  }
}

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
      (m) => m['threshold'] as int <= totalCompleted,
      orElse: () => milestones.first,
    );
    final nextMilestone = milestones.firstWhere(
      (m) => (m['threshold'] as int) > totalCompleted,
      orElse: () => milestones.last,
    );

    final progressToNext = totalCompleted > 0
        ? (totalCompleted - (currentMilestone['threshold'] as int)) /
            ((nextMilestone['threshold'] as int) - (currentMilestone['threshold'] as int))
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
                    color: Color(currentMilestone['color'] as int).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        currentMilestone['icon'] as IconData,
                        color: Color(currentMilestone['color'] as int),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        currentMilestone['title'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(currentMilestone['color'] as int),
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
                  color: Color(currentMilestone['color'] as int),
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
