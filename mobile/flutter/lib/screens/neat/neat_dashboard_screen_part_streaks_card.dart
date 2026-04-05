part of 'neat_dashboard_screen.dart';


// ============================================
// Streaks Card
// ============================================

class _StreaksCard extends StatelessWidget {
  final NeatStreak streaks;
  final bool isDark;
  final Color elevatedColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBorder;

  const _StreaksCard({
    required this.streaks,
    required this.isDark,
    required this.elevatedColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.local_fire_department,
                color: AppColors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Streaks',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Current streaks row
          Row(
            children: [
              Expanded(
                child: _StreakItem(
                  icon: Icons.directions_walk,
                  label: 'Steps',
                  current: streaks.currentStepStreak,
                  longest: streaks.longestStepStreak,
                  color: AppColors.cyan,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ),
              Container(
                height: 60,
                width: 1,
                color: cardBorder,
              ),
              Expanded(
                child: _StreakItem(
                  icon: Icons.schedule,
                  label: 'Active',
                  current: streaks.currentActiveHoursStreak,
                  longest: streaks.longestActiveHoursStreak,
                  color: AppColors.success,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ),
              Container(
                height: 60,
                width: 1,
                color: cardBorder,
              ),
              Expanded(
                child: _StreakItem(
                  icon: Icons.insights,
                  label: 'NEAT',
                  current: streaks.currentNeatScoreStreak,
                  longest: streaks.longestNeatScoreStreak,
                  color: AppColors.purple,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Longest streak highlight
          if (streaks.longestNeatScoreStreak > 0)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.orange.withOpacity(0.15),
                    AppColors.purple.withOpacity(0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: AppColors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Longest NEAT Streak',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                        Text(
                          '${streaks.longestNeatScoreStreak} days',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
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
    );
  }
}


class _StreakItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int current;
  final int longest;
  final Color color;
  final Color textPrimary;
  final Color textMuted;

  const _StreakItem({
    required this.icon,
    required this.label,
    required this.current,
    required this.longest,
    required this.color,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_fire_department,
              color: current > 0 ? AppColors.orange : textMuted,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '$current',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: current > 0 ? textPrimary : textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}


// ============================================
// Achievements Card
// ============================================

class _AchievementsCard extends StatelessWidget {
  final List<NeatAchievement> achievements;
  final List<NeatAchievement> recentAchievements;
  final bool isLoading;
  final bool isDark;
  final Color elevatedColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBorder;
  final VoidCallback onSeeAll;

  const _AchievementsCard({
    required this.achievements,
    required this.recentAchievements,
    required this.isLoading,
    required this.isDark,
    required this.elevatedColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBorder,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    // Get next achievements (not yet unlocked, sorted by progress)
    final nextAchievements = achievements
        .where((a) => !a.isUnlocked)
        .toList()
      ..sort((a, b) => b.progress.compareTo(a.progress));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: AppColors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Achievements',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onSeeAll,
                child: Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.cyan,
                  ),
                ),
              ),
            ],
          ),

          if (isLoading) ...[
            const SizedBox(height: 20),
            Center(
              child: CircularProgressIndicator(
                color: AppColors.orange,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(height: 20),
          ] else ...[
            // Recent achievements
            if (recentAchievements.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Recent',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 8),
              ...recentAchievements.map((achievement) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AchievementItem(
                      achievement: achievement,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      textMuted: textMuted,
                    ),
                  )),
            ],

            // Next achievements
            if (nextAchievements.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Up Next',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 8),
              ...nextAchievements.take(2).map((achievement) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AchievementProgressItem(
                      achievement: achievement,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      textMuted: textMuted,
                    ),
                  )),
            ],
          ],
        ],
      ),
    );
  }
}


class _AchievementItem extends StatelessWidget {
  final NeatAchievement achievement;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  const _AchievementItem({
    required this.achievement,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              achievement.icon,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                achievement.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              Text(
                achievement.description,
                style: TextStyle(
                  fontSize: 11,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star,
                color: AppColors.success,
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                '+${achievement.points}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


class _AchievementProgressItem extends StatelessWidget {
  final NeatAchievement achievement;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  const _AchievementProgressItem({
    required this.achievement,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: textMuted.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              achievement.icon,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textMuted,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                achievement.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: achievement.progress,
                  minHeight: 6,
                  backgroundColor: textMuted.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(AppColors.cyan),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${(achievement.progress * 100).round()}%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.cyan,
          ),
        ),
      ],
    );
  }
}


// ============================================
// Movement Reminder Card
// ============================================

class _MovementReminderCard extends StatelessWidget {
  final MovementReminderSettings settings;
  final Function(MovementReminderSettings) onSettingsChanged;
  final bool isDark;
  final Color elevatedColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBorder;

  const _MovementReminderCard({
    required this.settings,
    required this.onSettingsChanged,
    required this.isDark,
    required this.elevatedColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with toggle
          Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: settings.isEnabled ? AppColors.cyan : textMuted,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Movement Reminders',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              Switch(
                value: settings.isEnabled,
                onChanged: (value) {
                  HapticService.light();
                  onSettingsChanged(settings.copyWith(isEnabled: value));
                },
                activeThumbColor: AppColors.cyan,
              ),
            ],
          ),

          if (settings.isEnabled) ...[
            const SizedBox(height: 16),

            // Interval selector
            Text(
              'Remind every',
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [30, 60, 90, 120].map((minutes) {
                  final isSelected = settings.intervalMinutes == minutes;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${minutes}min'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          HapticService.light();
                          onSettingsChanged(
                            settings.copyWith(intervalMinutes: minutes),
                          );
                        }
                      },
                      selectedColor: AppColors.cyan.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.cyan : textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Steps threshold slider
            Row(
              children: [
                Text(
                  'If below',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${settings.stepsThreshold} steps',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cyan,
                  ),
                ),
              ],
            ),
            Slider(
              value: settings.stepsThreshold.toDouble(),
              min: 100,
              max: 500,
              divisions: 8,
              inactiveColor: textMuted.withOpacity(0.3),
              onChanged: (value) {
                onSettingsChanged(
                  settings.copyWith(stepsThreshold: value.round()),
                );
              },
            ),

            const SizedBox(height: 8),

            // Work hours only toggle
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Work hours only (9am - 5pm)',
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                ),
                Switch(
                  value: settings.workHoursOnly,
                  onChanged: (value) {
                    HapticService.light();
                    onSettingsChanged(settings.copyWith(workHoursOnly: value));
                  },
                  activeThumbColor: AppColors.cyan,
                ),
              ],
            ),

            // Quiet hours
            if (!settings.workHoursOnly)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Quiet hours: ${_formatTime(settings.quietHoursStart)} - ${_formatTime(settings.quietHoursEnd)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: textMuted,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showQuietHoursPicker(context),
                    child: Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.cyan,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.hour < 12 ? 'AM' : 'PM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }

  void _showQuietHoursPicker(BuildContext context) async {
    HapticService.light();
    final startTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 22, minute: 0),
      helpText: 'Quiet hours START',
    );
    if (startTime == null || !context.mounted) return;

    final endTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 7, minute: 0),
      helpText: 'Quiet hours END',
    );
    if (endTime == null || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Quiet hours: ${startTime.format(context)} - ${endTime.format(context)}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}


// ============================================
// AI Tips Card
// ============================================

class _AiTipsCard extends StatelessWidget {
  final String tip;
  final bool isDark;
  final Color elevatedColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBorder;

  const _AiTipsCard({
    required this.tip,
    required this.isDark,
    required this.elevatedColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.purple.withOpacity(0.15),
            AppColors.cyan.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.purple.withOpacity(0.3),
        ),
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
                  color: AppColors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: AppColors.purple,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'AI Coach Tip',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            tip,
            style: TextStyle(
              fontSize: 14,
              color: textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

