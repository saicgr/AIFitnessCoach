import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/user_provider.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/providers/cycle_reminder_sync_provider.dart';
import '../../data/providers/hormonal_health_provider.dart';
import '../../data/repositories/body_analyzer_repository.dart';
import '../../data/repositories/hormonal_health_repository.dart';
import '../../data/services/notification_service.dart';
import '../onboarding/cycle_onboarding_sheet.dart';

/// Cycle settings — the in-app home for everything cycle-related that is a
/// preference rather than logged data.
///
/// Sections:
///  1. Open Cycle — a row into the `/cycle` screen (built by another agent).
///  2. Cycle reminders — the full per-type reminder toggles (Phase E). Every
///     toggle maps 1:1 to a `NotificationPrefsKeys` entry; all cycle
///     reminders additionally respect the global quiet hours configured in
///     the main Notification settings, so this screen does not duplicate a
///     quiet-hours control — it just references it.
///  3. Cycle-aware photo reminders — the pre-existing opt-in that suppresses
///     progress-photo reminders during menstruation.
class CycleSettingsScreen extends ConsumerStatefulWidget {
  const CycleSettingsScreen({super.key});

  @override
  ConsumerState<CycleSettingsScreen> createState() =>
      _CycleSettingsScreenState();
}

class _CycleSettingsScreenState extends ConsumerState<CycleSettingsScreen> {
  bool _photoReminderEnabled = false;
  bool _photoSaving = false;
  bool _trackingSaving = false;

  /// Master enable/disable for cycle tracking — writes
  /// `hormonal_profiles.menstrual_tracking_enabled`, the single gate every
  /// cycle surface checks. This is the Settings opt-in path the gender-gating
  /// table promises (and the only way a male / opted-out user can turn it on).
  ///
  /// Enabling runs the cycle setup sheet first, because predictions need a
  /// last-period date to anchor on; cancelling the sheet leaves tracking off.
  Future<void> _setTracking(bool enabled) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    HapticFeedback.lightImpact();
    setState(() => _trackingSaving = true);
    try {
      if (enabled) {
        final completed =
            await CycleOnboardingSheet.show(context, userId: user.id);
        if (completed != true) return; // cancelled — stays off
      } else {
        await ref
            .read(hormonalHealthRepositoryProvider)
            .upsertProfile(user.id, {'menstrual_tracking_enabled': false});
      }
      ref.invalidate(hormonalProfileProvider);
      ref.invalidate(cyclePredictionProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update cycle tracking: $e')),
      );
    } finally {
      if (mounted) setState(() => _trackingSaving = false);
    }
  }

  Future<void> _togglePhotoReminders(bool v) async {
    setState(() {
      _photoReminderEnabled = v;
      _photoSaving = true;
    });
    try {
      await ref.read(menstrualCycleRepositoryProvider).setCycleAwareReminders(v);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
      setState(() => _photoReminderEnabled = !v);
    } finally {
      if (mounted) setState(() => _photoSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    // Keep the date-anchored cycle reminders in sync with the latest cycle
    // prediction while this screen is open (a no-op when there is no
    // prediction). The Cycle screen does the same so reminders stay fresh
    // wherever the user lands.
    ref.watch(cycleReminderSyncProvider);

    final prefs = ref.watch(notificationPreferencesProvider);
    final notifier = ref.read(notificationPreferencesProvider.notifier);
    final isTtc = prefs.cycleTrackingMode == 'ttc';
    final isPregnancy = prefs.cycleTrackingMode == 'pregnancy';
    // The per-type toggles only do anything when the master toggle is on.
    final remindersOn = prefs.cycleRemindersMaster;

    // Master gate — `hormonal_profiles.menstrual_tracking_enabled`.
    final trackingEnabled =
        ref.watch(hormonalProfileProvider).value?.menstrualTrackingEnabled ??
            false;

    return Scaffold(
      appBar: AppBar(title: const Text('Cycle')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // ── Master enable toggle ──────────────────────────────
            _Card(
              isDark: isDark,
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: trackingEnabled,
                onChanged: _trackingSaving ? null : _setTracking,
                activeThumbColor: accent,
                secondary: Icon(Icons.bloodtype_outlined, color: accent),
                title: Text('Cycle tracking',
                    style: TextStyle(
                        color: textPrimary, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  trackingEnabled
                      ? 'Period, fertility window and cycle-phase predictions '
                          'are on.'
                      : 'Turn on to track your period, fertility window and '
                          'cycle phase. We will ask for your last period date '
                          'to start predictions.',
                  style: TextStyle(color: textMuted, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cycle predictions are estimates, not a birth-control method or '
              'medical advice.',
              style: TextStyle(fontSize: 12, color: textMuted, height: 1.5),
            ),
            const SizedBox(height: 20),

            // ── Open the Cycle screen ─────────────────────────────
            _Card(
              isDark: isDark,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.favorite_rounded, color: accent),
                title: Text('Open Cycle',
                    style: TextStyle(
                        color: textPrimary, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  'Calendar, predictions, logging, and insights',
                  style: TextStyle(color: textMuted, fontSize: 12),
                ),
                trailing: Icon(Icons.chevron_right, color: textMuted),
                onTap: () => context.push('/cycle'),
              ),
            ),
            const SizedBox(height: 20),

            // ── Cycle reminders ───────────────────────────────────
            _SectionLabel('CYCLE REMINDERS', textMuted),
            const SizedBox(height: 8),
            _Card(
              isDark: isDark,
              child: Column(
                children: [
                  _ToggleRow(
                    icon: Icons.notifications_active_outlined,
                    accent: accent,
                    title: 'Cycle reminders',
                    subtitle: 'Master switch for all cycle notifications',
                    value: prefs.cycleRemindersMaster,
                    onChanged: notifier.setCycleRemindersMaster,
                    isDark: isDark,
                  ),
                  if (isPregnancy)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Text(
                        'Cycle reminders are paused while tracking mode is '
                        'set to Pregnancy.',
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                    ),
                  if (remindersOn && !isPregnancy) ...[
                    _Divider(isDark),
                    _ToggleRow(
                      icon: Icons.event_outlined,
                      accent: accent,
                      title: 'Period approaching',
                      subtitle:
                          'A heads-up ${prefs.cyclePeriodApproachingLeadDays} '
                          'day(s) before your predicted period',
                      value: prefs.cyclePeriodApproaching,
                      onChanged: notifier.setCyclePeriodApproaching,
                      isDark: isDark,
                    ),
                    if (prefs.cyclePeriodApproaching)
                      _LeadDaysRow(
                        accent: accent,
                        isDark: isDark,
                        days: prefs.cyclePeriodApproachingLeadDays,
                        onChanged: notifier.setCyclePeriodApproachingLeadDays,
                      ),
                    _Divider(isDark),
                    _ToggleRow(
                      icon: Icons.water_drop_outlined,
                      accent: accent,
                      title: 'Period start day',
                      subtitle: 'On your predicted period start date',
                      value: prefs.cyclePeriodStart,
                      onChanged: notifier.setCyclePeriodStart,
                      isDark: isDark,
                    ),
                    _Divider(isDark),
                    _ToggleRow(
                      icon: Icons.run_circle_outlined,
                      accent: accent,
                      title: 'Period running late',
                      subtitle:
                          'An alert if no period is logged past the window',
                      value: prefs.cycleLatePeriodAlert,
                      onChanged: notifier.setCycleLatePeriodAlert,
                      isDark: isDark,
                    ),
                    // Fertility reminders — TTC mode only. Shown disabled
                    // with an explanatory caption outside TTC so the user
                    // understands why they cannot toggle them.
                    _Divider(isDark),
                    _ToggleRow(
                      icon: Icons.spa_outlined,
                      accent: accent,
                      title: 'Fertile window',
                      subtitle: isTtc
                          ? 'When your estimated fertile window opens'
                          : 'Available in Trying to Conceive mode',
                      value: isTtc && prefs.cycleFertileWindow,
                      onChanged:
                          isTtc ? notifier.setCycleFertileWindow : null,
                      isDark: isDark,
                    ),
                    _Divider(isDark),
                    _ToggleRow(
                      icon: Icons.auto_awesome_outlined,
                      accent: accent,
                      title: 'Peak fertility',
                      subtitle: isTtc
                          ? 'On your estimated peak fertility days'
                          : 'Available in Trying to Conceive mode',
                      value: isTtc && prefs.cyclePeakFertility,
                      onChanged:
                          isTtc ? notifier.setCyclePeakFertility : null,
                      isDark: isDark,
                    ),
                    _Divider(isDark),
                    // Reminder time-of-day — applies to all date-anchored
                    // reminders above. Compact single control.
                    _TimeRow(
                      icon: Icons.schedule_outlined,
                      accent: accent,
                      title: 'Reminder time',
                      subtitle: 'When the reminders above are delivered',
                      time: prefs.cycleReminderTimeOfDay,
                      onChanged: notifier.setCycleReminderTimeOfDay,
                      isDark: isDark,
                    ),
                    _Divider(isDark),
                    // Daily logging reminders (repeat every day).
                    _ToggleRow(
                      icon: Icons.thermostat_outlined,
                      accent: accent,
                      title: 'Daily temperature reminder',
                      subtitle: 'A morning nudge to log your BBT',
                      value: prefs.cycleBbtReminder,
                      onChanged: notifier.setCycleBbtReminder,
                      isDark: isDark,
                    ),
                    if (prefs.cycleBbtReminder)
                      _TimeRow(
                        icon: Icons.wb_sunny_outlined,
                        accent: accent,
                        title: 'Temperature reminder time',
                        subtitle: 'Best taken before getting up',
                        time: prefs.cycleBbtReminderTime,
                        onChanged: notifier.setCycleBbtReminderTime,
                        isDark: isDark,
                        inset: true,
                      ),
                    _Divider(isDark),
                    _ToggleRow(
                      icon: Icons.edit_note_outlined,
                      accent: accent,
                      title: 'Symptom check-in',
                      subtitle: 'An evening nudge to log how you feel',
                      value: prefs.cycleSymptomCheckin,
                      onChanged: notifier.setCycleSymptomCheckin,
                      isDark: isDark,
                    ),
                    if (prefs.cycleSymptomCheckin)
                      _TimeRow(
                        icon: Icons.nightlight_outlined,
                        accent: accent,
                        title: 'Check-in time',
                        subtitle: null,
                        time: prefs.cycleSymptomCheckinTime,
                        onChanged: notifier.setCycleSymptomCheckinTime,
                        isDark: isDark,
                        inset: true,
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All cycle reminders respect your Quiet Hours and per-category '
              'controls in Notification settings. Reminders are delivered in '
              'your device timezone.',
              style: TextStyle(fontSize: 12, color: textMuted, height: 1.5),
            ),
            const SizedBox(height: 20),

            // ── Cycle-aware photo reminders ───────────────────────
            _SectionLabel('PHOTO REMINDERS', textMuted),
            const SizedBox(height: 8),
            _Card(
              isDark: isDark,
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _photoReminderEnabled,
                onChanged: _photoSaving ? null : _togglePhotoReminders,
                activeThumbColor: accent,
                title: Text('Cycle-aware photo reminders',
                    style: TextStyle(
                        color: textPrimary, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  'Skip progress-photo reminders during your period so water '
                  'retention does not skew your photos.',
                  style: TextStyle(color: textMuted, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Small presentational helpers
// ─────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _Card({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.6,
          ),
        ),
      );
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider(this.isDark);

  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
      );
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String? subtitle;
  final bool value;

  /// Null disables the row (e.g. a TTC-only reminder outside TTC mode).
  final ValueChanged<bool>? onChanged;
  final bool isDark;

  const _ToggleRow({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: value && enabled ? accent : textMuted, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(fontSize: 14.5, color: textPrimary)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: TextStyle(fontSize: 12, color: textMuted)),
                  ],
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeThumbColor: accent,
              activeTrackColor: accent.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String? subtitle;
  final String time; // "HH:mm"
  final ValueChanged<String> onChanged;
  final bool isDark;
  final bool inset;

  const _TimeRow({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.onChanged,
    required this.isDark,
    this.inset = false,
  });

  Future<void> _pick(BuildContext context) async {
    HapticFeedback.selectionClick();
    final parts = time.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 9,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );
    final picked =
        await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final hh = picked.hour.toString().padLeft(2, '0');
      final mm = picked.minute.toString().padLeft(2, '0');
      onChanged('$hh:$mm');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return InkWell(
      onTap: () => _pick(context),
      child: Padding(
        padding: EdgeInsets.fromLTRB(inset ? 24 : 0, 10, 0, 10),
        child: Row(
          children: [
            Icon(icon, color: textMuted, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(fontSize: 14.5, color: textPrimary)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: TextStyle(fontSize: 12, color: textMuted)),
                  ],
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                time,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeadDaysRow extends StatelessWidget {
  final Color accent;
  final bool isDark;
  final int days;
  final ValueChanged<int> onChanged;

  const _LeadDaysRow({
    required this.accent,
    required this.isDark,
    required this.days,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 0, 10),
      child: Row(
        children: [
          Text('Days before',
              style: TextStyle(fontSize: 12.5, color: textMuted)),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: accent,
                thumbColor: accent,
                inactiveTrackColor: accent.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: days.toDouble().clamp(1, 5),
                min: 1,
                max: 5,
                divisions: 4,
                label: '$days',
                onChanged: (v) => onChanged(v.round()),
              ),
            ),
          ),
          Text('$days',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: accent)),
        ],
      ),
    );
  }
}
