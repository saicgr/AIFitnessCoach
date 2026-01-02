import 'package:flutter/material.dart';
import '../../../data/models/hormonal_health.dart';

/// Card displaying user's hormone optimization goals
class HormoneGoalsCard extends StatelessWidget {
  final List<HormoneGoal> goals;
  final VoidCallback? onEditGoals;

  const HormoneGoalsCard({
    super.key,
    required this.goals,
    this.onEditGoals,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (goals.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.flag_outlined,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                'No hormone goals set',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: onEditGoals,
                child: const Text('Set Goals'),
              ),
            ],
          ),
        ),
      );
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
                  Icons.flag,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Your Goals',
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                if (onEditGoals != null)
                  TextButton(
                    onPressed: onEditGoals,
                    child: const Text('Edit'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: goals.map((goal) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(goal.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        goal.displayName,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
