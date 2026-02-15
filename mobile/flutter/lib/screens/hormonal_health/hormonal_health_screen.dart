import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/hormonal_health.dart';
import '../../data/providers/hormonal_health_provider.dart';
import '../../data/repositories/hormonal_health_repository.dart';
import '../../core/providers/user_provider.dart';
import 'widgets/cycle_tracker_widget.dart';
import 'widgets/hormone_log_sheet.dart';
import 'widgets/hormone_goals_card.dart';
import 'widgets/quick_stats_card.dart';
import '../../widgets/glass_sheet.dart';

/// Main screen for hormonal health tracking and insights
class HormonalHealthScreen extends ConsumerStatefulWidget {
  const HormonalHealthScreen({super.key});

  @override
  ConsumerState<HormonalHealthScreen> createState() => _HormonalHealthScreenState();
}

class _HormonalHealthScreenState extends ConsumerState<HormonalHealthScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final profileAsync = ref.watch(hormonalProfileProvider);
    final cyclePhaseAsync = ref.watch(cyclePhaseProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hormonal Health'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _navigateToSettings(context),
            tooltip: 'Hormonal Health Settings',
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildErrorState(context, e),
        data: (profile) {
          if (profile == null) {
            return _buildSetupPrompt(context);
          }
          return _buildDashboard(context, profile, cyclePhaseAsync);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLogSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Log Today'),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load hormonal health data',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.invalidate(hormonalProfileProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupPrompt(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.monitor_heart_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Hormonal Health Tracking',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Optimize your workouts and nutrition based on your hormonal health goals. '
              'Track your cycle, manage testosterone optimization, or support hormonal balance.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _navigateToSettings(context),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    HormonalProfile profile,
    AsyncValue<CyclePhaseInfo?> cyclePhaseAsync,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(hormonalProfileProvider);
        ref.invalidate(cyclePhaseProvider);
        ref.invalidate(todayHormoneLogProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cycle Tracker (if menstrual tracking enabled)
          if (profile.menstrualTrackingEnabled)
            cyclePhaseAsync.when(
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (cycleInfo) => CycleTrackerWidget(
                cycleInfo: cycleInfo,
                onLogPeriod: () => _showLogPeriodDialog(context),
              ),
            ),
          if (profile.menstrualTrackingEnabled) const SizedBox(height: 16),

          // Quick Stats Card
          QuickStatsCard(profile: profile),
          const SizedBox(height: 16),

          // Hormone Goals Card
          HormoneGoalsCard(
            goals: profile.hormoneGoals,
            onEditGoals: () => _navigateToSettings(context),
          ),
          const SizedBox(height: 16),

          // Today's Log Status
          _buildTodayLogCard(context),
          const SizedBox(height: 16),

          // Recommendations Section
          _buildRecommendationsCard(context, profile, cyclePhaseAsync.value),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildTodayLogCard(BuildContext context) {
    final todayLogAsync = ref.watch(todayHormoneLogProvider);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  "Today's Check-in",
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            todayLogAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Unable to load today\'s log'),
              data: (log) {
                if (log == null) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.add_circle_outline,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    title: const Text('No check-in yet today'),
                    subtitle: const Text('Log how you\'re feeling'),
                    trailing: FilledButton.tonal(
                      onPressed: () => _showLogSheet(context),
                      child: const Text('Log Now'),
                    ),
                  );
                }

                return Column(
                  children: [
                    _buildLogMetric('Energy', log.energyLevel, Icons.bolt),
                    _buildLogMetric('Sleep', log.sleepQuality, Icons.bedtime),
                    _buildLogMetric('Stress', log.stressLevel, Icons.psychology),
                    if (log.symptoms.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: log.symptoms.take(4).map((s) {
                          return Chip(
                            label: Text(
                              s.displayName,
                              style: theme.textTheme.labelSmall,
                            ),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogMetric(String label, int? value, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.bodyMedium),
          const Spacer(),
          if (value != null) ...[
            ...List.generate(10, (index) {
              return Container(
                width: 8,
                height: 16,
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  color: index < value
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
            const SizedBox(width: 8),
            Text('$value/10', style: theme.textTheme.labelSmall),
          ] else
            Text('Not logged', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(
    BuildContext context,
    HormonalProfile profile,
    CyclePhaseInfo? cycleInfo,
  ) {
    final theme = Theme.of(context);
    final recommendations = <String>[];

    // Add phase-based recommendations
    if (cycleInfo?.currentPhase != null) {
      final phase = cycleInfo!.currentPhase!;
      recommendations.add(
        '${phase.displayName} phase: ${phase.workoutIntensity} intensity recommended',
      );
      if (cycleInfo.nutritionFocus.isNotEmpty) {
        recommendations.add('Focus on: ${cycleInfo.nutritionFocus.first}');
      }
    }

    // Add goal-based recommendations
    for (final goal in profile.hormoneGoals.take(2)) {
      switch (goal) {
        case HormoneGoal.optimizeTestosterone:
          recommendations.add('Include compound exercises like squats and deadlifts');
          break;
        case HormoneGoal.balanceEstrogen:
          recommendations.add('Add cruciferous vegetables to your meals');
          break;
        case HormoneGoal.pcosManagement:
          recommendations.add('Focus on low glycemic foods for blood sugar stability');
          break;
        default:
          break;
      }
    }

    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 20,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recommendations',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rec,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _showLogSheet(BuildContext context) {
    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: const HormoneLogSheet(),
      ),
    );
  }

  void _showLogPeriodDialog(BuildContext context) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
      helpText: 'When did your period start?',
    );

    if (selectedDate != null && context.mounted) {
      try {
        final repository = ref.read(hormonalHealthRepositoryProvider);
        await repository.logPeriodStart(user.id, periodDate: selectedDate);
        ref.invalidate(cyclePhaseProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Period start logged')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to log period: $e')),
          );
        }
      }
    }
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.of(context).pushNamed('/hormonal-health/settings');
  }
}
