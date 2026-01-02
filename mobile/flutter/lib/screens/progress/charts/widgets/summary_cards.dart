import 'package:flutter/material.dart';
import '../../../../data/models/progress_charts.dart';

/// Summary cards displaying key progress metrics
class SummaryCards extends StatelessWidget {
  final ProgressSummary summary;

  const SummaryCards({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildCard(
              context,
              icon: Icons.fitness_center,
              value: '${summary.totalWorkouts}',
              label: 'Workouts',
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCard(
              context,
              icon: Icons.emoji_events,
              value: '${summary.totalPRs}',
              label: 'PRs',
              color: Colors.amber,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCard(
              context,
              icon: _getTrendIcon(summary.volumeIncreasePercent),
              value: '${summary.volumeIncreasePercent >= 0 ? '+' : ''}${summary.volumeIncreasePercent.toStringAsFixed(1)}%',
              label: 'Volume',
              color: _getTrendColor(summary.volumeIncreasePercent),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCard(
              context,
              icon: Icons.local_fire_department,
              value: '${summary.currentStreak}',
              label: 'Streak',
              color: Colors.deepOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTrendIcon(double percent) {
    if (percent > 5) return Icons.trending_up;
    if (percent < -5) return Icons.trending_down;
    return Icons.trending_flat;
  }

  Color _getTrendColor(double percent) {
    if (percent > 5) return Colors.green;
    if (percent < -5) return Colors.red;
    return Colors.grey;
  }
}
