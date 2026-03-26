import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/notification_service.dart';
import '../widgets/widgets.dart';

class NotificationsSection extends StatelessWidget {
  const NotificationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SectionHeader(title: 'NOTIFICATIONS'),
        SizedBox(height: 12),
        _NotificationsCard(),
      ],
    );
  }
}

class _NotificationsCard extends ConsumerStatefulWidget {
  const _NotificationsCard();

  @override
  ConsumerState<_NotificationsCard> createState() => _NotificationsCardState();
}

class _NotificationsCardState extends ConsumerState<_NotificationsCard> {
  String? _expandedSection;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final notifPrefs = ref.watch(notificationPreferencesProvider);

    return Container(
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // ─── Reminders ─────────────────────
          // Workout Reminders
          _buildNotificationToggleWithTime(
            sectionKey: 'workout',
            icon: Icons.fitness_center,
            iconColor: AppColors.cyan,
            title: 'Workout Reminders',
            subtitle: 'Remind on workout days',
            value: notifPrefs.workoutReminders,
            onChanged: (value) {
              ref.read(notificationPreferencesProvider.notifier).setWorkoutReminders(value);
            },
            textSecondary: textSecondary,
            textMuted: textMuted,
            isDark: isDark,
            timeWidget: TimePickerTile(
              label: 'Reminder time',
              time: notifPrefs.workoutReminderTime,
              onTimeChanged: (time) {
                ref.read(notificationPreferencesProvider.notifier).setWorkoutReminderTime(time);
              },
              isDark: isDark,
            ),
          ),
          Divider(height: 1, color: cardBorder, indent: 50),

          // Nutrition Reminders
          _buildNotificationToggleWithTime(
            sectionKey: 'nutrition',
            icon: Icons.restaurant,
            iconColor: AppColors.success,
            title: 'Meal Reminders',
            subtitle: 'Breakfast, lunch & dinner',
            value: notifPrefs.nutritionReminders,
            onChanged: (value) {
              ref.read(notificationPreferencesProvider.notifier).setNutritionReminders(value);
            },
            textSecondary: textSecondary,
            textMuted: textMuted,
            isDark: isDark,
            timeWidget: Column(
              children: [
                TimePickerTile(
                  label: 'Breakfast',
                  time: notifPrefs.nutritionBreakfastTime,
                  onTimeChanged: (time) {
                    ref.read(notificationPreferencesProvider.notifier).setNutritionBreakfastTime(time);
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                TimePickerTile(
                  label: 'Lunch',
                  time: notifPrefs.nutritionLunchTime,
                  onTimeChanged: (time) {
                    ref.read(notificationPreferencesProvider.notifier).setNutritionLunchTime(time);
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                TimePickerTile(
                  label: 'Dinner',
                  time: notifPrefs.nutritionDinnerTime,
                  onTimeChanged: (time) {
                    ref.read(notificationPreferencesProvider.notifier).setNutritionDinnerTime(time);
                  },
                  isDark: isDark,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cardBorder, indent: 50),

          // Hydration Reminders
          _buildNotificationToggleWithTime(
            sectionKey: 'hydration',
            icon: Icons.water_drop,
            iconColor: Colors.blue,
            title: 'Water Reminders',
            subtitle: 'Stay hydrated throughout the day',
            value: notifPrefs.hydrationReminders,
            onChanged: (value) {
              ref.read(notificationPreferencesProvider.notifier).setHydrationReminders(value);
            },
            textSecondary: textSecondary,
            textMuted: textMuted,
            isDark: isDark,
            timeWidget: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TimePickerTile(
                        label: 'Start',
                        time: notifPrefs.hydrationStartTime,
                        onTimeChanged: (time) {
                          ref.read(notificationPreferencesProvider.notifier).setHydrationTimes(
                            time,
                            notifPrefs.hydrationEndTime,
                            notifPrefs.hydrationIntervalMinutes,
                          );
                        },
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TimePickerTile(
                        label: 'End',
                        time: notifPrefs.hydrationEndTime,
                        onTimeChanged: (time) {
                          ref.read(notificationPreferencesProvider.notifier).setHydrationTimes(
                            notifPrefs.hydrationStartTime,
                            time,
                            notifPrefs.hydrationIntervalMinutes,
                          );
                        },
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                IntervalPickerTile(
                  label: 'Remind every',
                  minutes: notifPrefs.hydrationIntervalMinutes,
                  onChanged: (minutes) {
                    ref.read(notificationPreferencesProvider.notifier).setHydrationTimes(
                      notifPrefs.hydrationStartTime,
                      notifPrefs.hydrationEndTime,
                      minutes,
                    );
                  },
                  isDark: isDark,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cardBorder, indent: 50),

          // Weekly Summary
          _buildNotificationToggleWithTime(
            sectionKey: 'weekly',
            icon: Icons.bar_chart,
            iconColor: AppColors.purple,
            title: 'Weekly Report',
            subtitle: 'Your progress summary',
            value: notifPrefs.weeklySummary,
            onChanged: (value) {
              ref.read(notificationPreferencesProvider.notifier).setWeeklySummary(value);
            },
            textSecondary: textSecondary,
            textMuted: textMuted,
            isDark: isDark,
            timeWidget: Column(
              children: [
                DayPickerTile(
                  label: 'Day',
                  day: notifPrefs.weeklySummaryDay,
                  onChanged: (day) {
                    ref.read(notificationPreferencesProvider.notifier).setWeeklySummarySchedule(
                      day,
                      notifPrefs.weeklySummaryTime,
                    );
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                TimePickerTile(
                  label: 'Time',
                  time: notifPrefs.weeklySummaryTime,
                  onTimeChanged: (time) {
                    ref.read(notificationPreferencesProvider.notifier).setWeeklySummarySchedule(
                      notifPrefs.weeklySummaryDay,
                      time,
                    );
                  },
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggleWithTime({
    required String sectionKey,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color textSecondary,
    required Color textMuted,
    required bool isDark,
    required Widget timeWidget,
  }) {
    final isExpanded = _expandedSection == sectionKey;
    final cardBackground = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Column(
      children: [
        InkWell(
          onTap: value
              ? () {
                  setState(() {
                    _expandedSection = isExpanded ? null : sectionKey;
                  });
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: value ? iconColor : textMuted, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 15)),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              subtitle,
                              style: TextStyle(fontSize: 12, color: textMuted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (value) ...[
                            const SizedBox(width: 4),
                            Icon(
                              isExpanded ? Icons.expand_less : Icons.expand_more,
                              size: 16,
                              color: textMuted,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: (newValue) {
                    onChanged(newValue);
                    if (!newValue && isExpanded) {
                      setState(() => _expandedSection = null);
                    }
                  },
                  activeThumbColor: AppColors.cyan,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final leftMargin = screenWidth < 380 ? 32.0 : 50.0;
              return Container(
                margin: EdgeInsets.only(left: leftMargin, right: 16, bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: timeWidget,
              );
            },
          ),
          crossFadeState: isExpanded && value ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

}
