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
  bool _advancedExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final cardBackground = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final notifPrefs = ref.watch(notificationPreferencesProvider);
    final preset = notifPrefs.frequencyPreset;
    final isBundleMode = preset == 'minimal' || preset == 'balanced';

    return Container(
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // ─── Frequency Preset Picker ─────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notification Frequency',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildPresetCard(
                      icon: Icons.notifications_paused_outlined,
                      label: 'Minimal',
                      subtitle: '3/day',
                      isSelected: preset == 'minimal',
                      onTap: () => ref.read(notificationPreferencesProvider.notifier)
                          .setFrequencyPreset('minimal'),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildPresetCard(
                      icon: Icons.notifications_active_outlined,
                      label: 'Balanced',
                      subtitle: '4-5/day',
                      isSelected: preset == 'balanced',
                      isRecommended: true,
                      onTap: () => ref.read(notificationPreferencesProvider.notifier)
                          .setFrequencyPreset('balanced'),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildPresetCard(
                      icon: Icons.notifications_outlined,
                      label: 'Full Coach',
                      subtitle: '8-10/day',
                      isSelected: preset == 'full_coach',
                      onTap: () => ref.read(notificationPreferencesProvider.notifier)
                          .setFrequencyPreset('full_coach'),
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cardBorder),

          // ─── Bundle Time Pickers (Minimal/Balanced only) ─────────
          if (isBundleMode) ...[
            _buildBundleTimePicker(
              icon: Icons.wb_sunny_outlined,
              iconColor: const Color(0xFFFBBF24),
              label: 'Morning Brief',
              subtitle: 'Workout + Breakfast',
              time: notifPrefs.morningBundleTime,
              onTimeChanged: (time) =>
                  ref.read(notificationPreferencesProvider.notifier).setMorningBundleTime(time),
              textMuted: textMuted,
              isDark: isDark,
            ),
            Divider(height: 1, color: cardBorder, indent: 50),
            _buildBundleTimePicker(
              icon: Icons.wb_cloudy_outlined,
              iconColor: const Color(0xFF60A5FA),
              label: 'Midday Check',
              subtitle: 'Lunch + Hydration',
              time: notifPrefs.middayBundleTime,
              onTimeChanged: (time) =>
                  ref.read(notificationPreferencesProvider.notifier).setMiddayBundleTime(time),
              textMuted: textMuted,
              isDark: isDark,
            ),
            if (preset == 'balanced') ...[
              Divider(height: 1, color: cardBorder, indent: 50),
              _buildBundleTimePicker(
                icon: Icons.directions_walk_outlined,
                iconColor: const Color(0xFF34D399),
                label: 'Afternoon Nudge',
                subtitle: 'Movement + Hydration',
                time: notifPrefs.afternoonNudgeTime,
                onTimeChanged: (time) =>
                    ref.read(notificationPreferencesProvider.notifier).setAfternoonNudgeTime(time),
                textMuted: textMuted,
                isDark: isDark,
              ),
            ],
            Divider(height: 1, color: cardBorder, indent: 50),
            _buildBundleTimePicker(
              icon: Icons.nights_stay_outlined,
              iconColor: const Color(0xFFA78BFA),
              label: 'Evening Wrap',
              subtitle: 'Dinner + Streak',
              time: notifPrefs.eveningBundleTime,
              onTimeChanged: (time) =>
                  ref.read(notificationPreferencesProvider.notifier).setEveningBundleTime(time),
              textMuted: textMuted,
              isDark: isDark,
            ),
            Divider(height: 1, color: cardBorder),

            // ─── Weekend Times Toggle ─────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.weekend_outlined, color: textMuted, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Weekend times', style: TextStyle(fontSize: 14)),
                        Text(
                          'Different schedule on Sat & Sun',
                          style: TextStyle(fontSize: 11, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: notifPrefs.weekendTimesEnabled,
                    onChanged: (value) =>
                        ref.read(notificationPreferencesProvider.notifier).setWeekendTimesEnabled(value),
                    activeThumbColor: AppColors.cyan,
                  ),
                ],
              ),
            ),
            if (notifPrefs.weekendTimesEnabled) ...[
              Padding(
                padding: const EdgeInsets.only(left: 50, right: 16, bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      TimePickerTile(
                        label: 'Morning',
                        time: notifPrefs.morningBundleTimeWeekend,
                        onTimeChanged: (time) =>
                            ref.read(notificationPreferencesProvider.notifier).setWeekendBundleTimes(
                              time,
                              notifPrefs.middayBundleTimeWeekend,
                              notifPrefs.eveningBundleTimeWeekend,
                            ),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      TimePickerTile(
                        label: 'Midday',
                        time: notifPrefs.middayBundleTimeWeekend,
                        onTimeChanged: (time) =>
                            ref.read(notificationPreferencesProvider.notifier).setWeekendBundleTimes(
                              notifPrefs.morningBundleTimeWeekend,
                              time,
                              notifPrefs.eveningBundleTimeWeekend,
                            ),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      TimePickerTile(
                        label: 'Evening',
                        time: notifPrefs.eveningBundleTimeWeekend,
                        onTimeChanged: (time) =>
                            ref.read(notificationPreferencesProvider.notifier).setWeekendBundleTimes(
                              notifPrefs.morningBundleTimeWeekend,
                              notifPrefs.middayBundleTimeWeekend,
                              time,
                            ),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            Divider(height: 1, color: cardBorder),
          ],

          // ─── Always Visible: Quiet Hours, Weekly Report, Guilt, Style ─────────

          // Quiet Hours
          _buildNotificationToggleWithTime(
            sectionKey: 'quiet',
            icon: Icons.do_not_disturb_on_outlined,
            iconColor: const Color(0xFFEF4444),
            title: 'Quiet Hours',
            subtitle: '${notifPrefs.quietHoursStart} - ${notifPrefs.quietHoursEnd}',
            value: true,
            onChanged: (_) {},
            textSecondary: textSecondary,
            textMuted: textMuted,
            isDark: isDark,
            timeWidget: Row(
              children: [
                Expanded(
                  child: TimePickerTile(
                    label: 'Start',
                    time: notifPrefs.quietHoursStart,
                    onTimeChanged: (time) =>
                        ref.read(notificationPreferencesProvider.notifier).setQuietHours(
                          time, notifPrefs.quietHoursEnd,
                        ),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TimePickerTile(
                    label: 'End',
                    time: notifPrefs.quietHoursEnd,
                    onTimeChanged: (time) =>
                        ref.read(notificationPreferencesProvider.notifier).setQuietHours(
                          notifPrefs.quietHoursStart, time,
                        ),
                    isDark: isDark,
                  ),
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
                      day, notifPrefs.weeklySummaryTime,
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
                      notifPrefs.weeklySummaryDay, time,
                    );
                  },
                  isDark: isDark,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cardBorder, indent: 50),

          // Guilt Notifications
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.sentiment_dissatisfied_outlined,
                  color: notifPrefs.guiltNotifications ? const Color(0xFFF97316) : textMuted,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Guilt Notifications', style: TextStyle(fontSize: 15)),
                      Text(
                        'Duolingo-style nudges when inactive',
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: notifPrefs.guiltNotifications,
                  onChanged: (value) =>
                      ref.read(notificationPreferencesProvider.notifier).setGuiltNotifications(value),
                  activeThumbColor: AppColors.cyan,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cardBorder, indent: 50),

          // Notification Style
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.emoji_emotions_outlined, color: textMuted, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Include Emoji', style: TextStyle(fontSize: 15)),
                      Text(
                        'Show emoji in notification text',
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: notifPrefs.notificationEmoji,
                  onChanged: (value) =>
                      ref.read(notificationPreferencesProvider.notifier).setNotificationEmoji(value),
                  activeThumbColor: AppColors.cyan,
                ),
              ],
            ),
          ),

          // ─── Advanced Notifications (Collapsible) ─────────
          Divider(height: 1, color: cardBorder),
          InkWell(
            onTap: () => setState(() => _advancedExpanded = !_advancedExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.tune, color: textMuted, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Advanced',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                        Text(
                          'Fine-tune individual notification types',
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _advancedExpanded ? Icons.expand_less : Icons.expand_more,
                    color: textMuted,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                Divider(height: 1, color: cardBorder, indent: 50),
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
                // Meal Reminders
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
                                  time, notifPrefs.hydrationEndTime, notifPrefs.hydrationIntervalMinutes,
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
                                  notifPrefs.hydrationStartTime, time, notifPrefs.hydrationIntervalMinutes,
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
                            notifPrefs.hydrationStartTime, notifPrefs.hydrationEndTime, minutes,
                          );
                        },
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: cardBorder, indent: 50),
                // Movement Reminders
                _buildNotificationToggleWithTime(
                  sectionKey: 'movement',
                  icon: Icons.directions_walk,
                  iconColor: const Color(0xFFEAB308),
                  title: 'Movement Reminders',
                  subtitle: 'Hourly during work hours',
                  value: notifPrefs.movementReminders,
                  onChanged: (value) {
                    ref.read(notificationPreferencesProvider.notifier).setMovementReminders(value);
                  },
                  textSecondary: textSecondary,
                  textMuted: textMuted,
                  isDark: isDark,
                  timeWidget: Row(
                    children: [
                      Expanded(
                        child: TimePickerTile(
                          label: 'Start',
                          time: notifPrefs.movementReminderStartTime,
                          onTimeChanged: (time) {
                            ref.read(notificationPreferencesProvider.notifier).setMovementReminderTimes(
                              time, notifPrefs.movementReminderEndTime,
                            );
                          },
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TimePickerTile(
                          label: 'End',
                          time: notifPrefs.movementReminderEndTime,
                          onTimeChanged: (time) {
                            ref.read(notificationPreferencesProvider.notifier).setMovementReminderTimes(
                              notifPrefs.movementReminderStartTime, time,
                            );
                          },
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            crossFadeState: _advancedExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  // ─── Preset Card Widget ─────────────────────────────────
  Widget _buildPresetCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    bool isRecommended = false,
  }) {
    final selectedBg = AppColors.cyan.withValues(alpha: 0.15);
    final unselectedBg = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final selectedBorder = AppColors.cyan;
    final unselectedBorder = Colors.transparent;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : unselectedBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? selectedBorder : unselectedBorder,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.cyan : textMuted,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.cyan : (isDark ? Colors.white : Colors.black87),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: textMuted),
              ),
              if (isRecommended) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Recommended',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cyan,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Bundle Time Picker ─────────────────────────────────
  Widget _buildBundleTimePicker({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required String time,
    required ValueChanged<String> onTimeChanged,
    required Color textMuted,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 15)),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              final parts = time.split(':');
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: int.parse(parts[0]),
                  minute: int.parse(parts[1]),
                ),
              );
              if (picked != null) {
                onTimeChanged(
                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                time,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.cyan,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Toggle with Expandable Time Picker ─────────────────
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
