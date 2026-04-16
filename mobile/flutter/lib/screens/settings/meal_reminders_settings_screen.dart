/// Meal Reminders settings — master toggle + list of active recipe schedules
/// + public-sharing default + auto-snapshot versions.
///
/// Per `feedback_user_notification_control.md`, every new push type must have
/// a user-facing toggle. Schedules can be paused or disabled per-row here.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/models/scheduled_recipe.dart';
import '../../data/providers/recipe_providers.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../data/services/api_client.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
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
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text('Meal reminders', style: TextStyle(color: text)),
        iconTheme: IconThemeData(color: text),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text('Meal reminder notifications', style: TextStyle(color: text)),
            subtitle: Text(
              'Push notifications for scheduled recipes. Tap to confirm and one-tap log.',
              style: TextStyle(color: muted, fontSize: 12),
            ),
            value: _mealReminders,
            onChanged: (v) {
              setState(() => _mealReminders = v);
              _setBool(_prefMealReminders, v);
            },
            activeThumbColor: accent,
          ),
          SwitchListTile(
            title: Text('Public sharing default', style: TextStyle(color: text)),
            subtitle: Text(
              'New recipes are shareable by default. You can always toggle per recipe.',
              style: TextStyle(color: muted, fontSize: 12),
            ),
            value: _publicDefault,
            onChanged: (v) {
              setState(() => _publicDefault = v);
              _setBool(_prefPublicSharingDefault, v);
            },
            activeThumbColor: accent,
          ),
          SwitchListTile(
            title: Text('Auto-snapshot recipe versions', style: TextStyle(color: text)),
            subtitle: Text(
              'Every edit captures a new version for diff + revert.',
              style: TextStyle(color: muted, fontSize: 12),
            ),
            value: _autoSnapshot,
            onChanged: (v) {
              setState(() => _autoSnapshot = v);
              _setBool(_prefAutoSnapshotVersions, v);
            },
            activeThumbColor: accent,
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'ACTIVE SCHEDULES',
              style: TextStyle(
                color: muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8,
              ),
            ),
          ),
          if (_userId == null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Sign in to see your schedules.', style: TextStyle(color: muted)),
            )
          else
            _SchedulesList(userId: _userId!, isDark: isDark, accent: accent),
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
            child: Text('No schedules yet. Add one from a recipe detail screen.',
                style: TextStyle(color: muted)),
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
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (dCtx) => AlertDialog(
                title: const Text('Delete schedule?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
                  ElevatedButton(onPressed: () => Navigator.pop(dCtx, true), child: const Text('Delete')),
                ],
              ),
            ) ==
            true;
      },
      onDismissed: (_) => onDelete(),
      child: SwitchListTile(
        title: Text('${schedule.mealType.value} reminder', style: TextStyle(color: text)),
        subtitle: Text(modeLabel, style: TextStyle(color: muted, fontSize: 12)),
        value: schedule.enabled,
        onChanged: onToggle,
        activeThumbColor: accent,
      ),
    );
  }
}
