import 'package:flutter/material.dart';
import '../../../data/models/weekly_plan.dart';

/// Header widget showing weekly plan overview
class PlanHeader extends StatelessWidget {
  final WeeklyPlan plan;

  const PlanHeader({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date range
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 18,
                color: colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                plan.dateRangeDisplay,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (plan.isCurrentWeek)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'This Week',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                icon: Icons.fitness_center,
                label: 'Training',
                value: '${plan.trainingDayCount} days',
                color: Colors.green,
              ),
              _buildStatItem(
                context,
                icon: Icons.self_improvement,
                label: 'Rest',
                value: '${plan.restDayCount} days',
                color: Colors.grey,
              ),
              _buildStatItem(
                context,
                icon: Icons.local_fire_department,
                label: 'Avg Calories',
                value: '${plan.avgDailyCalories}',
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Fasting & Nutrition info
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (plan.fastingProtocol != null)
                _buildChip(
                  context,
                  icon: Icons.timer,
                  label: plan.fastingProtocol!,
                  color: colorScheme.secondary,
                ),
              _buildChip(
                context,
                icon: Icons.restaurant,
                label: plan.parsedNutritionStrategy.displayName,
                color: colorScheme.tertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
