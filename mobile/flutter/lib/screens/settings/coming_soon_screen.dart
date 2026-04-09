import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/pill_app_bar.dart';

/// Screen showing upcoming features that are planned but not yet available.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const PillAppBar(title: 'Coming Soon'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: elevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.rocket_launch_rounded,
                      color: AppColors.purple,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Upcoming Home Widgets',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'These features are in development and will be available as toggleable home screen widgets soon.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.05),

            const SizedBox(height: 16),

            // Feature list
            ..._comingSoonFeatures.asMap().entries.map((entry) {
              final i = entry.key;
              final feature = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _FeatureCard(
                  icon: feature.icon,
                  iconColor: feature.color,
                  title: feature.title,
                  description: feature.description,
                  isDark: isDark,
                  elevated: elevated,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              )
                  .animate()
                  .fadeIn(delay: (100 + i * 50).ms, duration: 300.ms)
                  .slideX(begin: 0.03);
            }),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonFeature {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _ComingSoonFeature({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
}

const _comingSoonFeatures = [
  _ComingSoonFeature(
    icon: Icons.insights,
    color: AppColors.green,
    title: 'Fitness Score',
    description: 'Overall fitness, strength & nutrition scores',
  ),
  _ComingSoonFeature(
    icon: Icons.directions_walk,
    color: AppColors.cyan,
    title: 'Daily Stats',
    description: 'Steps count and calorie deficit tracking',
  ),
  _ComingSoonFeature(
    icon: Icons.monitor_weight,
    color: AppColors.green,
    title: 'Weight Tracker',
    description: 'Recent weight with trend arrow',
  ),
  _ComingSoonFeature(
    icon: Icons.restaurant,
    color: AppColors.orange,
    title: 'Calories Summary',
    description: "Today's intake vs target at a glance",
  ),
  _ComingSoonFeature(
    icon: Icons.pie_chart,
    color: AppColors.orange,
    title: 'Macro Rings',
    description: 'Visual donut charts for protein, carbs & fat',
  ),
  _ComingSoonFeature(
    icon: Icons.show_chart,
    color: AppColors.green,
    title: 'Progress Charts',
    description: 'Strength and volume charts over time',
  ),
  _ComingSoonFeature(
    icon: Icons.accessibility_new,
    color: AppColors.cyan,
    title: 'Muscle Heatmap',
    description: 'Muscle groups trained recently',
  ),
  _ComingSoonFeature(
    icon: Icons.straighten,
    color: AppColors.green,
    title: 'Quick Measurements',
    description: 'Track body measurements easily',
  ),
  _ComingSoonFeature(
    icon: Icons.swap_horiz,
    color: AppColors.cyan,
    title: 'Week Changes',
    description: 'Exercise variation this week',
  ),
  _ComingSoonFeature(
    icon: Icons.wb_sunny_outlined,
    color: AppColors.yellow,
    title: 'Mood Check-in',
    description: 'Quick mood picker for instant workouts',
  ),
  _ComingSoonFeature(
    icon: Icons.watch,
    color: AppColors.cyan,
    title: 'Daily Activity',
    description: 'Health device activity summary',
  ),
  _ComingSoonFeature(
    icon: Icons.route,
    color: AppColors.green,
    title: 'My Journey',
    description: 'Your fitness journey progress',
  ),
  _ComingSoonFeature(
    icon: Icons.trending_up,
    color: AppColors.green,
    title: 'Your Journey ROI',
    description: 'Total workouts, time invested, and milestones',
  ),
  _ComingSoonFeature(
    icon: Icons.calendar_view_week,
    color: AppColors.cyan,
    title: 'Weekly Plan',
    description: 'Holistic plan with workouts, nutrition & fasting',
  ),
  _ComingSoonFeature(
    icon: Icons.spa,
    color: AppColors.yellow,
    title: 'Rest Day Tips',
    description: 'Recovery tips for rest days',
  ),
  _ComingSoonFeature(
    icon: Icons.military_tech,
    color: AppColors.cyan,
    title: 'Active Challenges',
    description: 'Challenge progress mini-card',
  ),
  _ComingSoonFeature(
    icon: Icons.leaderboard,
    color: AppColors.purple,
    title: 'Leaderboard',
    description: 'Your position on the leaderboard',
  ),
  _ComingSoonFeature(
    icon: Icons.people,
    color: AppColors.purple,
    title: 'Friend Activity',
    description: 'See what friends are doing',
  ),
  _ComingSoonFeature(
    icon: Icons.compare,
    color: AppColors.green,
    title: 'Photo Compare',
    description: 'Before/after progress comparison',
  ),
  _ComingSoonFeature(
    icon: Icons.calendar_month,
    color: AppColors.cyan,
    title: 'Mini Calendar',
    description: 'Mini calendar with workout days',
  ),
  _ComingSoonFeature(
    icon: Icons.play_circle_filled,
    color: AppColors.cyan,
    title: 'Quick Start',
    description: 'One-tap to start today\'s workout',
  ),
];

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final bool isDark;
  final Color elevated;
  final Color cardBorder;
  final Color textPrimary;
  final Color textMuted;

  const _FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.isDark,
    required this.elevated,
    required this.cardBorder,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: textMuted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
