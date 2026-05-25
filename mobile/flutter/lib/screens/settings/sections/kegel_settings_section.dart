import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/kegel.dart';
import '../../../data/providers/kegel_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../widgets/glass_sheet.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Settings section for kegel/pelvic floor exercise preferences
class KegelSettingsSection extends ConsumerWidget {
  const KegelSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final prefsAsync = ref.watch(kegelPreferencesProvider);
    final theme = Theme.of(context);

    if (user == null) {
      return const SizedBox.shrink();
    }

    return prefsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (prefs) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.accessibility_new,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context).kegelSettingsPelvicFloorTraining,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                AppLocalizations.of(context).kegelSettingsStrengthenYourPelvicFloor,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Main Toggle
            SwitchListTile(
              title: Text(AppLocalizations.of(context).kegelSettingsEnableKegelExercises),
              subtitle: Text(AppLocalizations.of(context).kegelSettingsIncludePelvicFloorExercises),
              value: prefs?.kegelsEnabled ?? false,
              onChanged: (value) async {
                final notifier = ref.read(
                  kegelPreferencesNotifierProvider(user.id).notifier,
                );
                await notifier.toggleKegelsEnabled(value);
                ref.invalidate(kegelPreferencesProvider);
              },
            ),

            if (prefs?.kegelsEnabled ?? false) ...[
              const Divider(),

              // Where to include
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  AppLocalizations.of(context).kegelSettingsIncludeIn,
                  style: theme.textTheme.titleSmall,
                ),
              ),

              CheckboxListTile(
                title: Text(AppLocalizations.of(context).workoutSummaryAdvancedWarmup),
                subtitle: Text(AppLocalizations.of(context).kegelSettingsAddKegelsToYour),
                value: prefs?.includeInWarmup ?? false,
                onChanged: (value) async {
                  if (value == null) return;
                  final notifier = ref.read(
                    kegelPreferencesNotifierProvider(user.id).notifier,
                  );
                  await notifier.toggleIncludeInWarmup(value);
                  ref.invalidate(kegelPreferencesProvider);
                },
              ),

              CheckboxListTile(
                title: Text(AppLocalizations.of(context).kegelSettingsCooldown),
                subtitle: Text(AppLocalizations.of(context).kegelSettingsAddKegelsToYour2),
                value: prefs?.includeInCooldown ?? false,
                onChanged: (value) async {
                  if (value == null) return;
                  final notifier = ref.read(
                    kegelPreferencesNotifierProvider(user.id).notifier,
                  );
                  await notifier.toggleIncludeInCooldown(value);
                  ref.invalidate(kegelPreferencesProvider);
                },
              ),

              CheckboxListTile(
                title: Text(AppLocalizations.of(context).kegelSettingsStandaloneSessions),
                subtitle: Text(AppLocalizations.of(context).kegelSettingsDedicatedPelvicFloorWorkout),
                value: prefs?.includeAsStandalone ?? false,
                onChanged: (value) async {
                  if (value == null) return;
                  final notifier = ref.read(
                    kegelPreferencesNotifierProvider(user.id).notifier,
                  );
                  await notifier.updatePreferences({
                    'include_as_standalone': value,
                  });
                  ref.invalidate(kegelPreferencesProvider);
                },
              ),

              const Divider(),

              // Daily Goal
              ListTile(
                title: Text(AppLocalizations.of(context).kegelSettingsDailySessionsGoal),
                subtitle: Text('${prefs?.targetSessionsPerDay ?? 3} sessions per day'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: (prefs?.targetSessionsPerDay ?? 3) > 1
                          ? () async {
                              final notifier = ref.read(
                                kegelPreferencesNotifierProvider(user.id).notifier,
                              );
                              await notifier.setTargetSessionsPerDay(
                                (prefs?.targetSessionsPerDay ?? 3) - 1,
                              );
                              ref.invalidate(kegelPreferencesProvider);
                            }
                          : null,
                    ),
                    Text(
                      '${prefs?.targetSessionsPerDay ?? 3}',
                      style: theme.textTheme.titleMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: (prefs?.targetSessionsPerDay ?? 3) < 10
                          ? () async {
                              final notifier = ref.read(
                                kegelPreferencesNotifierProvider(user.id).notifier,
                              );
                              await notifier.setTargetSessionsPerDay(
                                (prefs?.targetSessionsPerDay ?? 3) + 1,
                              );
                              ref.invalidate(kegelPreferencesProvider);
                            }
                          : null,
                    ),
                  ],
                ),
              ),

              // Difficulty Level
              ListTile(
                title: Text(AppLocalizations.of(context).kegelSettingsExerciseLevel),
                subtitle: Text(prefs?.currentLevel.displayName ?? AppLocalizations.of(context).xpGoalsScreenBeginner),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLevelPicker(context, ref, user.id, prefs),
              ),

              // Focus Area
              ListTile(
                title: Text(AppLocalizations.of(context).kegelSettingsFocusArea),
                subtitle: Text(prefs?.focusArea.displayName ?? AppLocalizations.of(context).kegelSettingsGeneral),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showFocusPicker(context, ref, user.id, prefs),
              ),

              const Divider(),

              // Reminders
              SwitchListTile(
                title: Text(AppLocalizations.of(context).kegelSettingsDailyReminders),
                subtitle: Text(AppLocalizations.of(context).kegelSettingsGetRemindedToDo),
                value: prefs?.dailyReminderEnabled ?? false,
                onChanged: (value) async {
                  final notifier = ref.read(
                    kegelPreferencesNotifierProvider(user.id).notifier,
                  );
                  await notifier.updatePreferences({
                    'daily_reminder_enabled': value,
                  });
                  ref.invalidate(kegelPreferencesProvider);
                },
              ),

              // Stats Preview
              const Divider(),
              _buildStatsPreview(context, ref),
            ],
          ],
        );
      },
    );
  }

  Widget _buildStatsPreview(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(kegelStatsProvider);
    final theme = Theme.of(context);

    return statsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) {
        if (stats == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                context,
                '${stats.currentStreak}',
                'Day Streak',
                Icons.local_fire_department,
              ),
              _buildStatColumn(
                context,
                '${stats.totalSessions}',
                'Total Sessions',
                Icons.check_circle,
              ),
              _buildStatColumn(
                context,
                stats.totalDurationFormatted,
                'Total Time',
                Icons.timer,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  void _showLevelPicker(
    BuildContext context,
    WidgetRef ref,
    String userId,
    KegelPreferences? prefs,
  ) {
    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) {
        return GlassSheet(
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(context).kegelSettingsSelectExerciseLevel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ...KegelLevel.values.map((level) {
                  return ListTile(
                    leading: Radio<KegelLevel>(
                      value: level,
                      groupValue: prefs?.currentLevel,
                      onChanged: (_) async {
                        final notifier = ref.read(
                          kegelPreferencesNotifierProvider(userId).notifier,
                        );
                        await notifier.setCurrentLevel(level);
                        ref.invalidate(kegelPreferencesProvider);
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                    title: Text(level.displayName),
                    subtitle: Text(_getLevelDescription(level)),
                    onTap: () async {
                      final notifier = ref.read(
                        kegelPreferencesNotifierProvider(userId).notifier,
                      );
                      await notifier.setCurrentLevel(level);
                      ref.invalidate(kegelPreferencesProvider);
                      if (context.mounted) Navigator.pop(context);
                    },
                  );
                }),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFocusPicker(
    BuildContext context,
    WidgetRef ref,
    String userId,
    KegelPreferences? prefs,
  ) {
    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) {
        return GlassSheet(
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(context).kegelSettingsSelectFocusArea,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ...KegelFocusArea.values.map((focus) {
                  return ListTile(
                    leading: Radio<KegelFocusArea>(
                      value: focus,
                      groupValue: prefs?.focusArea,
                      onChanged: (_) async {
                        final notifier = ref.read(
                          kegelPreferencesNotifierProvider(userId).notifier,
                        );
                        await notifier.setFocusArea(focus);
                        ref.invalidate(kegelPreferencesProvider);
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                    title: Text(focus.displayName),
                    subtitle: Text(_getFocusDescription(focus)),
                    onTap: () async {
                      final notifier = ref.read(
                        kegelPreferencesNotifierProvider(userId).notifier,
                      );
                      await notifier.setFocusArea(focus);
                      ref.invalidate(kegelPreferencesProvider);
                      if (context.mounted) Navigator.pop(context);
                    },
                  );
                }),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getLevelDescription(KegelLevel level) {
    switch (level) {
      case KegelLevel.beginner:
        return 'Start with basic holds and short durations';
      case KegelLevel.intermediate:
        return 'Longer holds and progressive exercises';
      case KegelLevel.advanced:
        return 'Complex exercises with integration movements';
    }
  }

  String _getFocusDescription(KegelFocusArea focus) {
    switch (focus) {
      case KegelFocusArea.general:
        return 'Balanced pelvic floor strengthening for everyone';
      case KegelFocusArea.maleSpecific:
        return 'Exercises targeting male pelvic floor anatomy';
      case KegelFocusArea.femaleSpecific:
        return 'Exercises targeting female pelvic floor anatomy';
      case KegelFocusArea.postpartum:
        return 'Gentle recovery exercises after childbirth';
      case KegelFocusArea.prostateHealth:
        return 'Support prostate health and urinary control';
    }
  }
}
