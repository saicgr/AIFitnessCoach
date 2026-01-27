import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/hormonal_health.dart';
import '../../data/providers/hormonal_health_provider.dart';
import '../../data/repositories/hormonal_health_repository.dart';
import '../../core/providers/user_provider.dart';
import '../settings/sections/kegel_settings_section.dart';

/// Settings screen for hormonal health configuration
class HormonalHealthSettingsScreen extends ConsumerStatefulWidget {
  const HormonalHealthSettingsScreen({super.key});

  @override
  ConsumerState<HormonalHealthSettingsScreen> createState() =>
      _HormonalHealthSettingsScreenState();
}

class _HormonalHealthSettingsScreenState
    extends ConsumerState<HormonalHealthSettingsScreen> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final profileAsync = ref.watch(hormonalProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hormonal Health Settings'),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          return ListView(
            children: [
              // Profile Section
              _buildSectionHeader(context, 'Profile', Icons.person_outline),
              _buildGenderSection(context, profile),

              const Divider(height: 32),

              // Hormone Goals Section
              _buildSectionHeader(context, 'Hormone Goals', Icons.flag_outlined),
              _buildHormoneGoalsSection(context, profile),

              const Divider(height: 32),

              // Cycle Tracking Section (for those who menstruate)
              if (profile?.gender == Gender.female ||
                  profile?.birthSex == BirthSex.female) ...[
                _buildSectionHeader(
                    context, 'Cycle Tracking', Icons.calendar_month_outlined),
                _buildCycleTrackingSection(context, profile),
                const Divider(height: 32),
              ],

              // Feature Toggles
              _buildSectionHeader(
                  context, 'Features', Icons.toggle_on_outlined),
              _buildFeatureToggles(context, profile),

              const Divider(height: 32),

              // Pelvic Floor Training (Kegel)
              const KegelSettingsSection(),

              const SizedBox(height: 100),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSection(BuildContext context, HormonalProfile? profile) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const SizedBox.shrink();

    return Column(
      children: [
        ListTile(
          title: const Text('Gender Identity'),
          subtitle: Text(profile?.gender?.displayName ?? 'Not set'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showGenderPicker(context, user.id, profile),
        ),
        ListTile(
          title: const Text('Birth Sex'),
          subtitle: Text(profile?.birthSex?.displayName ?? 'Not set'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showBirthSexPicker(context, user.id, profile),
        ),
      ],
    );
  }

  Widget _buildHormoneGoalsSection(
      BuildContext context, HormonalProfile? profile) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const SizedBox.shrink();

    final goals = profile?.hormoneGoals ?? [];
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (goals.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: goals.map((goal) {
                return Chip(
                  label: Text(goal.displayName),
                  onDeleted: () => _removeHormoneGoal(user.id, goal, goals),
                  deleteIcon: const Icon(Icons.close, size: 18),
                );
              }).toList(),
            ),
          ),
        ListTile(
          leading: const Icon(Icons.add_circle_outline),
          title: const Text('Add Hormone Goal'),
          onTap: () => _showHormoneGoalsPicker(context, user.id, goals),
        ),
      ],
    );
  }

  Widget _buildCycleTrackingSection(
      BuildContext context, HormonalProfile? profile) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const SizedBox.shrink();

    return Column(
      children: [
        SwitchListTile(
          title: const Text('Enable Cycle Tracking'),
          subtitle: const Text('Track your menstrual cycle for optimized workouts'),
          value: profile?.menstrualTrackingEnabled ?? false,
          onChanged: (value) async {
            await _updateProfile(user.id, {'menstrual_tracking_enabled': value});
          },
        ),
        if (profile?.menstrualTrackingEnabled ?? false) ...[
          ListTile(
            title: const Text('Cycle Length'),
            subtitle: Text('${profile?.cycleLengthDays ?? 28} days'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showCycleLengthPicker(context, user.id, profile),
          ),
          ListTile(
            title: const Text('Period Duration'),
            subtitle: Text('${profile?.typicalPeriodDurationDays ?? 5} days'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPeriodDurationPicker(context, user.id, profile),
          ),
          ListTile(
            title: const Text('Last Period Start'),
            subtitle: Text(profile?.lastPeriodStartDate != null
                ? _formatDate(profile!.lastPeriodStartDate!)
                : 'Not set'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _showPeriodDatePicker(context, user.id, profile),
          ),
        ],
      ],
    );
  }

  Widget _buildFeatureToggles(BuildContext context, HormonalProfile? profile) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const SizedBox.shrink();

    return Column(
      children: [
        SwitchListTile(
          title: const Text('Cycle-Sync Workouts'),
          subtitle: const Text(
              'Adjust workout intensity based on your cycle phase'),
          value: profile?.cycleSyncWorkouts ?? false,
          onChanged: profile?.menstrualTrackingEnabled == true
              ? (value) async {
                  await _updateProfile(user.id, {'cycle_sync_workouts': value});
                }
              : null,
        ),
        SwitchListTile(
          title: const Text('Cycle-Sync Nutrition'),
          subtitle:
              const Text('Get nutrition tips based on your cycle phase'),
          value: profile?.cycleSyncNutrition ?? false,
          onChanged: profile?.menstrualTrackingEnabled == true
              ? (value) async {
                  await _updateProfile(user.id, {'cycle_sync_nutrition': value});
                }
              : null,
        ),
        SwitchListTile(
          title: const Text('Hormone-Supportive Foods'),
          subtitle: const Text('Include hormone-friendly food suggestions'),
          value: profile?.includeHormoneSupportiveFoods ?? true,
          onChanged: (value) async {
            await _updateProfile(
                user.id, {'include_hormone_supportive_foods': value});
          },
        ),
        SwitchListTile(
          title: const Text('Hormone-Supportive Exercises'),
          subtitle: const Text('Prioritize exercises that support your goals'),
          value: profile?.includeHormoneSupportiveExercises ?? true,
          onChanged: (value) async {
            await _updateProfile(
                user.id, {'include_hormone_supportive_exercises': value});
          },
        ),
      ],
    );
  }

  Future<void> _updateProfile(
      String userId, Map<String, dynamic> updates) async {
    setState(() => _isSaving = true);
    try {
      final repository = ref.read(hormonalHealthRepositoryProvider);
      await repository.upsertProfile(userId, updates);
      ref.invalidate(hormonalProfileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showGenderPicker(
      BuildContext context, String userId, HormonalProfile? profile) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Gender Identity',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              ...Gender.values.map((gender) {
                return ListTile(
                  leading: Radio<Gender>(
                    value: gender,
                    groupValue: profile?.gender,
                    onChanged: (_) async {
                      await _updateProfile(userId, {'gender': gender.value});
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  title: Text(gender.displayName),
                  onTap: () async {
                    await _updateProfile(userId, {'gender': gender.value});
                    if (context.mounted) Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showBirthSexPicker(
      BuildContext context, String userId, HormonalProfile? profile) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Birth Sex',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              ...BirthSex.values.map((sex) {
                return ListTile(
                  leading: Radio<BirthSex>(
                    value: sex,
                    groupValue: profile?.birthSex,
                    onChanged: (_) async {
                      await _updateProfile(userId, {'birth_sex': sex.value});
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  title: Text(sex.displayName),
                  onTap: () async {
                    await _updateProfile(userId, {'birth_sex': sex.value});
                    if (context.mounted) Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showHormoneGoalsPicker(
      BuildContext context, String userId, List<HormoneGoal> currentGoals) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Select Hormone Goals',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: HormoneGoal.values.map((goal) {
                      final isSelected = currentGoals.contains(goal);
                      return CheckboxListTile(
                        title: Text(goal.displayName),
                        subtitle: Text(_getGoalDescription(goal)),
                        value: isSelected,
                        onChanged: (selected) async {
                          final newGoals = List<HormoneGoal>.from(currentGoals);
                          if (selected == true) {
                            newGoals.add(goal);
                          } else {
                            newGoals.remove(goal);
                          }
                          await _updateProfile(userId, {
                            'hormone_goals':
                                newGoals.map((g) => g.value).toList()
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _removeHormoneGoal(
      String userId, HormoneGoal goal, List<HormoneGoal> currentGoals) async {
    final newGoals = currentGoals.where((g) => g != goal).toList();
    await _updateProfile(
        userId, {'hormone_goals': newGoals.map((g) => g.value).toList()});
  }

  void _showCycleLengthPicker(
      BuildContext context, String userId, HormonalProfile? profile) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) {
        int selected = profile?.cycleLengthDays ?? 28;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Cycle Length',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  Slider(
                    value: selected.toDouble(),
                    min: 21,
                    max: 45,
                    divisions: 24,
                    label: '$selected days',
                    onChanged: (value) {
                      setModalState(() => selected = value.round());
                    },
                  ),
                  Text('$selected days',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      await _updateProfile(
                          userId, {'cycle_length_days': selected});
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPeriodDurationPicker(
      BuildContext context, String userId, HormonalProfile? profile) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) {
        int selected = profile?.typicalPeriodDurationDays ?? 5;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Period Duration',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  Slider(
                    value: selected.toDouble(),
                    min: 2,
                    max: 10,
                    divisions: 8,
                    label: '$selected days',
                    onChanged: (value) {
                      setModalState(() => selected = value.round());
                    },
                  ),
                  Text('$selected days',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      await _updateProfile(
                          userId, {'typical_period_duration_days': selected});
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPeriodDatePicker(
      BuildContext context, String userId, HormonalProfile? profile) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: profile?.lastPeriodStartDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 45)),
      lastDate: DateTime.now(),
      helpText: 'When did your last period start?',
    );

    if (selectedDate != null) {
      await _updateProfile(userId, {
        'last_period_start_date': selectedDate.toIso8601String().split('T')[0]
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getGoalDescription(HormoneGoal goal) {
    switch (goal) {
      case HormoneGoal.optimizeTestosterone:
        return 'Exercises and nutrition to support healthy testosterone levels';
      case HormoneGoal.balanceEstrogen:
        return 'Support healthy estrogen metabolism and balance';
      case HormoneGoal.improveFertility:
        return 'Optimize hormonal health for fertility';
      case HormoneGoal.menopauseSupport:
        return 'Manage menopause symptoms through exercise and diet';
      case HormoneGoal.pcosManagement:
        return 'Support PCOS management with lifestyle changes';
      case HormoneGoal.perimenopauseSupport:
        return 'Transition support for perimenopause';
      case HormoneGoal.andropauseSupport:
        return 'Support healthy aging for men';
      case HormoneGoal.generalWellness:
        return 'Overall hormonal balance and wellness';
      case HormoneGoal.libidoEnhancement:
        return 'Support healthy libido through exercise and nutrition';
      case HormoneGoal.energyOptimization:
        return 'Optimize energy levels through hormonal support';
      case HormoneGoal.moodStabilization:
        return 'Support mood through hormonal balance';
      case HormoneGoal.sleepImprovement:
        return 'Improve sleep quality through hormonal support';
    }
  }
}
