import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/weekly_plan.dart';
import '../../../../data/providers/weekly_plan_provider.dart';

/// Home screen card showing today's plan and weekly overview
class WeeklyPlanCard extends ConsumerStatefulWidget {
  const WeeklyPlanCard({super.key});

  @override
  ConsumerState<WeeklyPlanCard> createState() => _WeeklyPlanCardState();
}

class _WeeklyPlanCardState extends ConsumerState<WeeklyPlanCard> {
  @override
  void initState() {
    super.initState();
    // Load plan if not already loaded
    Future.microtask(() {
      final planState = ref.read(weeklyPlanProvider);
      if (planState.currentPlan == null && !planState.isLoading) {
        ref.read(weeklyPlanProvider.notifier).loadCurrentPlan();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final planState = ref.watch(weeklyPlanProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (planState.isLoading) {
      return _buildLoadingCard(colorScheme);
    }

    if (planState.currentPlan == null) {
      return _buildEmptyCard(context, colorScheme);
    }

    return _buildPlanCard(context, planState.currentPlan!, colorScheme);
  }

  Widget _buildLoadingCard(ColorScheme colorScheme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildEmptyCard(BuildContext context, ColorScheme colorScheme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.push('/weekly-plan'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.calendar_month,
                  size: 32,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Create Your Weekly Plan',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Get a holistic plan that coordinates workouts, nutrition, and fasting',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => context.push('/weekly-plan'),
                child: const Text('Get Started'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    WeeklyPlan plan,
    ColorScheme colorScheme,
  ) {
    final todayEntry = plan.todayEntry;
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.push('/weekly-plan'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Weekly Plan',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      plan.dateRangeDisplay,
                      style: TextStyle(
                        color: colorScheme.onSecondaryContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Mini week calendar
              _buildMiniCalendar(plan, colorScheme),

              if (todayEntry != null) ...[
                const SizedBox(height: 16),
                Divider(color: colorScheme.outlineVariant),
                const SizedBox(height: 12),

                // Today's plan summary
                Row(
                  children: [
                    Text(
                      "Today's Plan",
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: todayEntry.dayType.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        todayEntry.dayType.displayName,
                        style: TextStyle(
                          color: todayEntry.dayType.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Today's stats
                Row(
                  children: [
                    Expanded(
                      child: _buildStatChip(
                        icon: Icons.local_fire_department,
                        value: '${todayEntry.calorieTarget}',
                        label: 'cal',
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatChip(
                        icon: Icons.egg_alt,
                        value: '${todayEntry.proteinTargetG.toInt()}g',
                        label: 'protein',
                        color: Colors.red,
                      ),
                    ),
                    if (todayEntry.eatingWindowDisplay != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatChip(
                          icon: Icons.timer,
                          value: todayEntry.eatingWindowStart ?? '',
                          label: 'eating',
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ],
                ),

                // Workout info if training day
                if (todayEntry.dayType == DayType.training &&
                    todayEntry.workoutFocus != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.fitness_center,
                          color: Colors.green,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            todayEntry.workoutFocus!,
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (todayEntry.workoutTime != null)
                          Text(
                            todayEntry.workoutTime!,
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 12),
              // View full plan button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => context.push('/weekly-plan'),
                  child: const Text('View Full Plan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniCalendar(WeeklyPlan plan, ColorScheme colorScheme) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now().weekday - 1; // 0-indexed

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        final isToday = index == today;
        final isTrainingDay = plan.workoutDays.contains(index);
        final entry = index < plan.dailyEntries.length
            ? plan.dailyEntries[index]
            : null;
        final isCompleted = entry?.workoutCompleted ?? false;

        return Column(
          children: [
            Text(
              days[index],
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isToday
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isToday
                    ? colorScheme.primary
                    : isTrainingDay
                        ? isCompleted
                            ? Colors.green.withOpacity(0.15)
                            : colorScheme.primaryContainer.withOpacity(0.5)
                        : Colors.transparent,
                border: isTrainingDay && !isToday
                    ? Border.all(
                        color: isCompleted
                            ? Colors.green
                            : colorScheme.primary.withOpacity(0.3),
                        width: 1.5,
                      )
                    : null,
              ),
              child: Center(
                child: isTrainingDay
                    ? Icon(
                        isCompleted ? Icons.check : Icons.fitness_center,
                        size: 14,
                        color: isToday
                            ? colorScheme.onPrimary
                            : isCompleted
                                ? Colors.green
                                : colorScheme.primary,
                      )
                    : null,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
