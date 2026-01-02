import 'package:flutter/material.dart';
import '../../../data/models/hormonal_health.dart';

/// Card showing quick stats about hormonal health settings
class QuickStatsCard extends StatelessWidget {
  final HormonalProfile profile;

  const QuickStatsCard({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final stats = <_StatItem>[];

    if (profile.menstrualTrackingEnabled) {
      stats.add(_StatItem(
        icon: Icons.favorite,
        label: 'Cycle Tracking',
        value: 'Active',
        color: Colors.pink,
      ));
    }

    if (profile.testosteroneOptimizationEnabled) {
      stats.add(_StatItem(
        icon: Icons.trending_up,
        label: 'T-Optimization',
        value: 'Active',
        color: Colors.blue,
      ));
    }

    if (profile.cycleSyncWorkouts) {
      stats.add(_StatItem(
        icon: Icons.fitness_center,
        label: 'Cycle-Synced Workouts',
        value: 'On',
        color: Colors.green,
      ));
    }

    if (profile.cycleSyncNutrition) {
      stats.add(_StatItem(
        icon: Icons.restaurant,
        label: 'Cycle-Synced Nutrition',
        value: 'On',
        color: Colors.orange,
      ));
    }

    if (profile.hasPcos) {
      stats.add(_StatItem(
        icon: Icons.health_and_safety,
        label: 'PCOS Support',
        value: 'Enabled',
        color: Colors.purple,
      ));
    }

    if (stats.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Configure your hormonal health preferences to get personalized insights.',
                  style: theme.textTheme.bodyMedium,
                ),
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
            Text(
              'Active Features',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: stats.map((stat) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: stat.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: stat.color.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        stat.icon,
                        size: 16,
                        color: stat.color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        stat.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: stat.color,
                          fontWeight: FontWeight.w500,
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

class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}
