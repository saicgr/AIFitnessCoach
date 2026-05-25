/// Per-day summary card rendered at the top of each day section in the
/// Timeline. 3 hero stat tiles (workouts / calories net / sleep) + 4
/// mini pills (water / habits / mood / steps) + streak flame indicator.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/timeline_entry.dart';

import '../../../l10n/generated/app_localizations.dart';
class TimelineSummaryCard extends StatelessWidget {
  final TimelineSummary summary;
  final Color accent;
  final bool isDark;

  const TimelineSummaryCard({
    super.key,
    required this.summary,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor =
        isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (summary.streakDay != null && summary.streakDay! > 0) ...[
                const Icon(Icons.local_fire_department,
                    color: Colors.orange, size: 18),
                const SizedBox(width: 4),
                Text(
                  'Day ${summary.streakDay}',
                  style: TextStyle(
                      color: textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
              ],
              if (summary.xpEarned != null && summary.xpEarned! > 0) ...[
                Icon(Icons.stars, color: accent, size: 16),
                const SizedBox(width: 4),
                Text('${summary.xpEarned} XP',
                    style:
                        TextStyle(color: textSecondary, fontSize: 12)),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _HeroStat(
                icon: Icons.fitness_center,
                value: '${summary.workoutsCount}',
                label: summary.workoutsTotalMinutes > 0
                    ? '${summary.workoutsTotalMinutes}m'
                    : 'workouts',
                accent: accent,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              _HeroStat(
                icon: Icons.local_fire_department_outlined,
                value: _fmtCalories(summary.caloriesNet),
                label: AppLocalizations.of(context).timelineSummaryCardNetKcal,
                accent: _calorieColor(summary.caloriesNet, accent),
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              _HeroStat(
                icon: Icons.bedtime_outlined,
                value: _fmtSleep(summary.sleepMinutes),
                label: 'sleep',
                accent: accent,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _MiniPill(
                icon: Icons.water_drop,
                color: Colors.blue,
                label: '${summary.waterMl}/${summary.waterGoalMl} ml',
              ),
              _MiniPill(
                icon: Icons.restaurant,
                color: Colors.orange,
                label: '${summary.caloriesEaten} kcal in',
              ),
              if (summary.habitsCompleted > 0)
                _MiniPill(
                  icon: Icons.check_circle,
                  color: Colors.green,
                  label: '${summary.habitsCompleted} habits',
                ),
              if (summary.mood != null)
                _MiniPill(
                  icon: Icons.mood,
                  color: Colors.amber,
                  label: 'Mood: ${summary.mood}',
                ),
              if (summary.steps != null && summary.steps! > 0)
                _MiniPill(
                  icon: Icons.directions_walk,
                  color: Colors.teal,
                  label: '${summary.steps} steps',
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmtCalories(int net) =>
      net >= 0 ? '+$net' : '$net';

  static Color _calorieColor(int net, Color accent) =>
      net <= 0 ? Colors.green : Colors.orange;

  static String _fmtSleep(int minutes) {
    if (minutes <= 0) return '—';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return h > 0 ? '${h}h${m > 0 ? ' ${m}m' : ''}' : '${m}m';
  }
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  const _HeroStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
          Text(label,
              style: TextStyle(color: textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _MiniPill(
      {required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
