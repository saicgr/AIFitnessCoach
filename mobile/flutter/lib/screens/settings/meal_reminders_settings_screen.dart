/// Meal Reminders settings — master toggle + list of active recipe schedules
/// + public-sharing default + auto-snapshot versions.
///
/// Per `feedback_user_notification_control.md`, every new push type must have
/// a user-facing toggle. Schedules can be paused or disabled per-row here.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart' show openAppSettings;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/models/scheduled_recipe.dart';
import '../../data/providers/recipe_providers.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/notification_service.dart';
import '../nutrition/recipes/discover_screen.dart';
import '../../widgets/design_system/zealova.dart';
import '../../widgets/pill_app_bar.dart';

import '../../l10n/generated/app_localizations.dart';
class MealRemindersSettingsScreen extends ConsumerStatefulWidget {
  final bool isDark;
  const MealRemindersSettingsScreen({super.key, required this.isDark});

  @override
  ConsumerState<MealRemindersSettingsScreen> createState() =>
      _MealRemindersSettingsScreenState();
}

class _MealRemindersSettingsScreenState
    extends ConsumerState<MealRemindersSettingsScreen> {
  static const _prefMealReminders = 'meal_reminders_enabled';
  static const _prefPublicSharingDefault = 'public_sharing_default';
  static const _prefAutoSnapshotVersions = 'auto_snapshot_versions';

  bool _mealReminders = true;
  bool _publicDefault = false;
  bool _autoSnapshot = true;
  String? _userId;
  // null = not checked yet. iOS only prompts for permission once, so a
  // "Don't Allow" tap is otherwise invisible to this screen's own on/off
  // state — without this the toggle can render ON while the OS silently
  // drops every push it schedules. Same check the main notifications
  // screen uses (`NotificationsSection`) so both surfaces agree.
  bool? _osNotificationsGranted;

  @override
  void initState() {
    super.initState();
    _load();
    _checkOsPermission();
  }

  Future<void> _checkOsPermission() async {
    final granted = await ref
        .read(notificationServiceProvider)
        .isOsNotificationPermissionGranted();
    if (mounted) {
      setState(() => _osNotificationsGranted = granted);
    }
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = await ref.read(apiClientProvider).getUserId();
    if (!mounted) return;
    setState(() {
      _mealReminders = prefs.getBool(_prefMealReminders) ?? true;
      _publicDefault = prefs.getBool(_prefPublicSharingDefault) ?? false;
      _autoSnapshot = prefs.getBool(_prefAutoSnapshotVersions) ?? true;
      _userId = uid;
    });
  }

  Future<void> _setBool(String key, bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, v);
  }

  @override
  Widget build(BuildContext context) {
    final accent = AccentColorScope.of(context).getColor(widget.isDark);
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Scaffold(
      backgroundColor: bg,
      // Finding #420: matches the majority PillAppBar convention used by
      // other settings sub-screens (ZealovaAppBar's kicker has no PillAppBar
      // equivalent, so it's dropped rather than faked).
      appBar: PillAppBar(
        title: AppLocalizations.of(context).settingsMealReminders,
      ),
      body: ListView(
        children: [
          _reminderToggleRow(
            title: AppLocalizations.of(context).mealRemindersSettingsMealReminderNotifications,
            text: text,
            subtitle: _osNotificationsGranted == false
                ? GestureDetector(
                    onTap: openAppSettings,
                    child: Text(
                      'Notifications are off in iOS Settings — tap to enable',
                      style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  )
                : Text(
                    'Push notifications for scheduled recipes. Tap to confirm and one-tap log.',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
            value: _mealReminders && _osNotificationsGranted != false,
            onChanged: _osNotificationsGranted == false
                ? (_) => openAppSettings()
                : (v) {
                    setState(() => _mealReminders = v);
                    _setBool(_prefMealReminders, v);
                  },
          ),
          _reminderToggleRow(
            title: AppLocalizations.of(context).mealRemindersSettingsPublicSharingDefault,
            text: text,
            subtitle: Text(
              'New recipes are shareable by default. You can always toggle per recipe.',
              style: TextStyle(color: muted, fontSize: 12),
            ),
            value: _publicDefault,
            onChanged: (v) {
              setState(() => _publicDefault = v);
              _setBool(_prefPublicSharingDefault, v);
            },
          ),
          _reminderToggleRow(
            title: AppLocalizations.of(context).mealRemindersSettingsAutoSnapshotRecipeVersions,
            text: text,
            subtitle: Text(
              'Every edit captures a new version for diff + revert.',
              style: TextStyle(color: muted, fontSize: 12),
            ),
            value: _autoSnapshot,
            onChanged: (v) {
              setState(() => _autoSnapshot = v);
              _setBool(_prefAutoSnapshotVersions, v);
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              AppLocalizations.of(context).mealRemindersSettingsActiveSchedules,
              style: TextStyle(
                color: muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8,
              ),
            ),
          ),
          if (_userId == null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(AppLocalizations.of(context).mealRemindersSettingsSignInToSee, style: TextStyle(color: muted)),
            )
          else
            _SchedulesList(userId: _userId!, isDark: isDark, accent: accent),
        ],
      ),
    );
  }

  /// Row #311 — this screen used to render its three toggles with the stock
  /// `SwitchListTile` (a small filled thumb inside a wide, pale-tinted
  /// track), a visibly different treatment from the full-size iOS-style
  /// switch every other settings screen (Nutrition Settings, Workout
  /// Settings, AI Coach) renders via the shared [ZealovaToggle]. Rebuilt on
  /// that shared component so this screen matches the rest of the app.
  Widget _reminderToggleRow({
    required String title,
    required Color text,
    required Widget subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: text, fontSize: 15)),
                const SizedBox(height: 3),
                subtitle,
              ],
            ),
          ),
          const SizedBox(width: 12),
          ZealovaToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SchedulesList extends ConsumerWidget {
  final String userId;
  final bool isDark;
  final Color accent;
  const _SchedulesList({required this.userId, required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final asyncSchedules = ref.watch(allSchedulesProvider(userId));
    return asyncSchedules.when(
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Couldn\'t load schedules: $e', style: TextStyle(color: muted)),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).mealRemindersSettingsNoSchedulesYetAdd,
                    style: TextStyle(color: muted)),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DiscoverScreen(userId: userId, isDark: isDark),
                    ),
                  ),
                  icon: Icon(Icons.restaurant_menu, color: accent),
                  label: Text(
                    'Browse recipes',
                    style: TextStyle(color: accent),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: accent.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          );
        }
        return Column(
          children: list.map((s) => _ScheduleRow(
            schedule: s, isDark: isDark, accent: accent,
            onToggle: (enabled) async {
              try {
                await ref.read(recipeRepositoryProvider)
                    .updateSchedule(s.id, {'enabled': enabled});
                ref.invalidate(allSchedulesProvider(userId));
                ref.invalidate(upcomingSchedulesProvider(userId));
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Update failed: $e')));
                }
              }
            },
            onDelete: () async {
              try {
                await ref.read(recipeRepositoryProvider).deleteSchedule(s.id);
                ref.invalidate(allSchedulesProvider(userId));
                ref.invalidate(upcomingSchedulesProvider(userId));
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Delete failed: $e')));
                }
              }
            },
            text: text, muted: muted,
          )).toList(),
        );
      },
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final ScheduledRecipeLog schedule;
  final bool isDark;
  final Color accent;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  final Color text;
  final Color muted;
  const _ScheduleRow({
    required this.schedule, required this.isDark, required this.accent,
    required this.onToggle, required this.onDelete,
    required this.text, required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final modeLabel = schedule.scheduleMode == ScheduleMode.recurring
        ? '${schedule.scheduleKind?.value ?? "?"} · ${schedule.localTime ?? ""}'
        : 'batch · ${(schedule.batchSlots?.length ?? 0) - schedule.nextSlotIndex} fires left';
    return Dismissible(
      key: ValueKey(schedule.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: AppColors.error,  // accent-allowlist: error/destructive - must stay red
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (dCtx) => AlertDialog(
                title: Text(AppLocalizations.of(context).mealRemindersSettingsDeleteSchedule),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(dCtx, false), child: Text(AppLocalizations.of(context).buttonCancel)),
                  ElevatedButton(onPressed: () => Navigator.pop(dCtx, true), child: Text(AppLocalizations.of(context).buttonDelete)),
                ],
              ),
            ) ==
            true;
      },
      onDismissed: (_) => onDelete(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${schedule.mealType.value} reminder',
                      style: TextStyle(color: text, fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(modeLabel, style: TextStyle(color: muted, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ZealovaToggle(value: schedule.enabled, onChanged: onToggle),
          ],
        ),
      ),
    );
  }
}
