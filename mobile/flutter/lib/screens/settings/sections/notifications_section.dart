import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/providers/hormonal_health_provider.dart';
import '../../../data/services/notification_service.dart';
import '../widgets/widgets.dart';

import '../../../l10n/generated/app_localizations.dart';
class NotificationsSection extends StatelessWidget {
  const NotificationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: AppLocalizations.of(context).notificationsNotifications),
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
    // Toggle colors: pair the active thumb with a translucent matching
    // track so on/off reads as one color, not the previous orange-track /
    // cyan-thumb mismatch. Falls back through the user's selected accent
    // → app default — so changing the accent in Appearance restyles every
    // switch on this screen automatically.
    final accent = ThemeColors.of(context).accent;
    final activeTrack = accent.withValues(alpha: 0.45);

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
                  AppLocalizations.of(context).notificationsNotificationFrequency,
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
                      label: AppLocalizations.of(context).notificationsMinimal,
                      subtitle: AppLocalizations.of(context).notifications3Day,
                      isSelected: preset == 'minimal',
                      onTap: () => ref.read(notificationPreferencesProvider.notifier)
                          .setFrequencyPreset('minimal'),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildPresetCard(
                      icon: Icons.notifications_active_outlined,
                      label: AppLocalizations.of(context).quizProgressionConstraintsBalanced,
                      subtitle: AppLocalizations.of(context).notifications45Day,
                      isSelected: preset == 'balanced',
                      isRecommended: true,
                      onTap: () => ref.read(notificationPreferencesProvider.notifier)
                          .setFrequencyPreset('balanced'),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildPresetCard(
                      icon: Icons.notifications_outlined,
                      label: AppLocalizations.of(context).notificationsFullCoach,
                      subtitle: AppLocalizations.of(context).notifications810Day,
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
              subtitle: AppLocalizations.of(context).notificationsWorkoutBreakfast,
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
                subtitle: AppLocalizations.of(context).notificationsMovementHydration,
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
                        Text(AppLocalizations.of(context).notificationsWeekendTimes, style: TextStyle(fontSize: 14)),
                        Text(
                          AppLocalizations.of(context).notificationsDifferentScheduleOnSat,
                          style: TextStyle(fontSize: 11, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: notifPrefs.weekendTimesEnabled,
                    onChanged: (value) =>
                        ref.read(notificationPreferencesProvider.notifier).setWeekendTimesEnabled(value),
                    activeThumbColor: accent,
                    activeTrackColor: activeTrack,
                  ),
                ],
              ),
            ),
            if (notifPrefs.weekendTimesEnabled) ...[
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 50, end: 16, bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      TimePickerTile(
                        label: AppLocalizations.of(context).notificationsMorning,
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
                        label: AppLocalizations.of(context).notificationsMidday,
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
                        label: AppLocalizations.of(context).notificationsEvening,
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
                    label: AppLocalizations.of(context).buttonStart,
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
                    label: AppLocalizations.of(context).quickActionsSheetEnd,
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
            title: AppLocalizations.of(context).notificationsWeeklyReport,
            subtitle: AppLocalizations.of(context).notificationsYourProgressSummary,
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
                  label: AppLocalizations.of(context).notificationsDay,
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
                  label: AppLocalizations.of(context).workoutShowcaseTime,
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

          // Guilt Notifications + Include Emoji moved into the Advanced
          // disclosure below — they're niche tuning, not first-line settings.

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
                          AppLocalizations.of(context).workoutUiModeAdvanced,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context).notificationsFineTuneIndividualNotificat,
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
                  title: AppLocalizations.of(context).notificationsWorkoutReminders,
                  subtitle: AppLocalizations.of(context).notificationsRemindOnWorkoutDays,
                  value: notifPrefs.workoutReminders,
                  onChanged: (value) {
                    ref.read(notificationPreferencesProvider.notifier).setWorkoutReminders(value);
                  },
                  textSecondary: textSecondary,
                  textMuted: textMuted,
                  isDark: isDark,
                  timeWidget: TimePickerTile(
                    label: AppLocalizations.of(context).notificationsReminderTime,
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
                  title: AppLocalizations.of(context).settingsMealReminders,
                  subtitle: AppLocalizations.of(context).notificationsBreakfastLunchDinner,
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
                        label: AppLocalizations.of(context).quickLogOverlayBreakfast,
                        time: notifPrefs.nutritionBreakfastTime,
                        onTimeChanged: (time) {
                          ref.read(notificationPreferencesProvider.notifier).setNutritionBreakfastTime(time);
                        },
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      TimePickerTile(
                        label: AppLocalizations.of(context).quickLogOverlayLunch,
                        time: notifPrefs.nutritionLunchTime,
                        onTimeChanged: (time) {
                          ref.read(notificationPreferencesProvider.notifier).setNutritionLunchTime(time);
                        },
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      TimePickerTile(
                        label: AppLocalizations.of(context).quickLogOverlayDinner,
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
                  title: AppLocalizations.of(context).notificationsWaterReminders,
                  subtitle: AppLocalizations.of(context).notificationsStayHydratedThroughoutThe,
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
                              label: AppLocalizations.of(context).buttonStart,
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
                              label: AppLocalizations.of(context).quickActionsSheetEnd,
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
                        label: AppLocalizations.of(context).notificationsRemindEvery,
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
                  subtitle: AppLocalizations.of(context).notificationsHourlyDuringWorkHours,
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
                          label: AppLocalizations.of(context).buttonStart,
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
                          label: AppLocalizations.of(context).quickActionsSheetEnd,
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
                Divider(height: 1, color: cardBorder, indent: 50),
                // ─── Proactive Health Coaching (Phase C2) ───────────
                // Daily Briefing — morning readiness push, with a delivery
                // time control (the time the cron sends it, user-local).
                _buildNotificationToggleWithTime(
                  sectionKey: 'daily_briefing',
                  icon: Icons.wb_twilight,
                  iconColor: const Color(0xFFFB923C),
                  title: 'Daily Briefing',
                  subtitle: AppLocalizations.of(context).notificationsMorningReadinessCheckIn,
                  value: notifPrefs.dailyBriefingNudge,
                  onChanged: (value) {
                    ref.read(notificationPreferencesProvider.notifier)
                        .setDailyBriefingNudge(value);
                  },
                  textSecondary: textSecondary,
                  textMuted: textMuted,
                  isDark: isDark,
                  timeWidget: TimePickerTile(
                    label: AppLocalizations.of(context).notificationsDeliveryTime,
                    time: notifPrefs.dailyBriefingTime,
                    onTimeChanged: (time) {
                      ref.read(notificationPreferencesProvider.notifier)
                          .setDailyBriefingTime(time);
                    },
                    isDark: isDark,
                  ),
                ),
                Divider(height: 1, color: cardBorder, indent: 50),
                // Anomaly Alerts — event-driven (resting-HR), so no time
                // control; a plain toggle row.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.monitor_heart_outlined,
                        color: notifPrefs.healthAnomalyNudge
                            ? const Color(0xFFEF4444)
                            : textMuted,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context).notificationsAnomalyAlerts,
                                style: TextStyle(fontSize: 15)),
                            Text(
                              AppLocalizations.of(context).notificationsHeadsUpWhenResting,
                              style: TextStyle(fontSize: 12, color: textMuted),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: notifPrefs.healthAnomalyNudge,
                        onChanged: (value) => ref
                            .read(notificationPreferencesProvider.notifier)
                            .setHealthAnomalyNudge(value),
                        activeThumbColor: accent,
                        activeTrackColor: activeTrack,
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: cardBorder, indent: 50),
                // Activity Nudges — afternoon step-goal nudge, with a
                // delivery time control.
                _buildNotificationToggleWithTime(
                  sectionKey: 'activity_nudge',
                  icon: Icons.directions_walk_outlined,
                  iconColor: const Color(0xFF34D399),
                  title: 'Activity Nudges',
                  subtitle: AppLocalizations.of(context).notificationsReminderWhenYouRe,
                  value: notifPrefs.activityGoalNudge,
                  onChanged: (value) {
                    ref.read(notificationPreferencesProvider.notifier)
                        .setActivityGoalNudge(value);
                  },
                  textSecondary: textSecondary,
                  textMuted: textMuted,
                  isDark: isDark,
                  timeWidget: TimePickerTile(
                    label: AppLocalizations.of(context).notificationsNudgeTime,
                    time: notifPrefs.activityNudgeTime,
                    onTimeChanged: (time) {
                      ref.read(notificationPreferencesProvider.notifier)
                          .setActivityNudgeTime(time);
                    },
                    isDark: isDark,
                  ),
                ),
                Divider(height: 1, color: cardBorder, indent: 50),
                // ─── Cycle Reminders (Phase E) ──────────────────────
                // Shown only when cycle tracking is enabled
                // (`menstrual_tracking_enabled`). The full per-type cycle
                // reminder controls live on the dedicated Cycle settings
                // screen — this row is the discoverable entry point so the
                // notifications card stays compact.
                if (ref.watch(hasHormonalTrackingProvider))
                  InkWell(
                    onTap: () => context.push('/settings/cycle'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.favorite_outline,
                              color: Color(0xFFEC4899), size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppLocalizations.of(context).notificationsCycleReminders,
                                    style: TextStyle(fontSize: 15)),
                                Text(
                                  AppLocalizations.of(context).notificationsPeriodFertilityAndLogging,
                                  style: TextStyle(
                                      fontSize: 12, color: textMuted),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: textMuted, size: 22),
                        ],
                      ),
                    ),
                  ),
                if (ref.watch(hasHormonalTrackingProvider))
                  Divider(height: 1, color: cardBorder, indent: 50),
                // Guilt Notifications (moved here from the always-visible section)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.sentiment_dissatisfied_outlined,
                        color: notifPrefs.guiltNotifications
                            ? const Color(0xFFF97316)
                            : textMuted,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context).notificationsGuiltNotifications,
                                style: TextStyle(fontSize: 15)),
                            Text(
                              AppLocalizations.of(context).notificationsDuolingoStyleNudgesWhen,
                              style: TextStyle(fontSize: 12, color: textMuted),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: notifPrefs.guiltNotifications,
                        onChanged: (value) => ref
                            .read(notificationPreferencesProvider.notifier)
                            .setGuiltNotifications(value),
                        activeThumbColor: accent,
                    activeTrackColor: activeTrack,
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: cardBorder, indent: 50),
                // Include Emoji (moved here from the always-visible section)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_emotions_outlined,
                          color: textMuted, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context).notificationsIncludeEmoji,
                                style: TextStyle(fontSize: 15)),
                            Text(
                              AppLocalizations.of(context).notificationsShowEmojiInNotification,
                              style: TextStyle(fontSize: 12, color: textMuted),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: notifPrefs.notificationEmoji,
                        onChanged: (value) => ref
                            .read(notificationPreferencesProvider.notifier)
                            .setNotificationEmoji(value),
                        activeThumbColor: accent,
                    activeTrackColor: activeTrack,
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
                    AppLocalizations.of(context).settingsCardPartRecommended,
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
    final accent = ThemeColors.of(context).accent;
    final activeTrack = accent.withValues(alpha: 0.45);

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
                  activeThumbColor: accent,
                    activeTrackColor: activeTrack,
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
                margin: EdgeInsetsDirectional.only(start: leftMargin, end: 16, bottom: 12),
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
