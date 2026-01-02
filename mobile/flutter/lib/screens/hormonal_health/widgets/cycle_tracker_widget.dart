import 'package:flutter/material.dart';
import '../../../data/models/hormonal_health.dart';

/// Widget to display and track menstrual cycle phase
class CycleTrackerWidget extends StatelessWidget {
  final CyclePhaseInfo? cycleInfo;
  final VoidCallback? onLogPeriod;

  const CycleTrackerWidget({
    super.key,
    this.cycleInfo,
    this.onLogPeriod,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (cycleInfo == null || !cycleInfo!.menstrualTrackingEnabled) {
      return const SizedBox.shrink();
    }

    final currentPhase = cycleInfo!.currentPhase;
    final cycleDay = cycleInfo!.currentCycleDay;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  size: 20,
                  color: _getPhaseColor(currentPhase),
                ),
                const SizedBox(width: 8),
                Text(
                  'Cycle Tracker',
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                if (onLogPeriod != null)
                  TextButton.icon(
                    onPressed: onLogPeriod,
                    icon: const Icon(Icons.water_drop, size: 16),
                    label: const Text('Log Period'),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Cycle visualization
            _buildCycleVisualization(context),

            const SizedBox(height: 16),

            // Current phase info
            if (currentPhase != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getPhaseColor(currentPhase).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getPhaseColor(currentPhase).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getPhaseColor(currentPhase).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _getPhaseEmoji(currentPhase),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentPhase.displayName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: _getPhaseColor(currentPhase),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Day $cycleDay of ${cycleInfo!.cycleLengthDays ?? 28}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currentPhase.workoutIntensity,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (cycleInfo!.daysUntilNextPhase != null)
                          Text(
                            '${cycleInfo!.daysUntilNextPhase} days to ${cycleInfo!.nextPhase?.displayName ?? 'next'}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // Recommendations
            if (cycleInfo!.avoidExercises.isNotEmpty ||
                cycleInfo!.recommendedExercises.isNotEmpty) ...[
              const SizedBox(height: 12),
              if (cycleInfo!.recommendedExercises.isNotEmpty)
                _buildRecommendationRow(
                  context,
                  Icons.check_circle,
                  'Good for now',
                  cycleInfo!.recommendedExercises.take(3).join(', '),
                  Colors.green,
                ),
              if (cycleInfo!.avoidExercises.isNotEmpty)
                _buildRecommendationRow(
                  context,
                  Icons.remove_circle,
                  'Consider avoiding',
                  cycleInfo!.avoidExercises.take(3).join(', '),
                  Colors.orange,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCycleVisualization(BuildContext context) {
    final cycleLength = cycleInfo?.cycleLengthDays ?? 28;
    final currentDay = cycleInfo?.currentCycleDay ?? 1;

    return Column(
      children: [
        // Phase segments
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              _buildPhaseSegment(
                CyclePhase.menstrual,
                5 / cycleLength,
                currentDay <= 5,
              ),
              _buildPhaseSegment(
                CyclePhase.follicular,
                8 / cycleLength,
                currentDay > 5 && currentDay <= 13,
              ),
              _buildPhaseSegment(
                CyclePhase.ovulation,
                3 / cycleLength,
                currentDay > 13 && currentDay <= 16,
              ),
              _buildPhaseSegment(
                CyclePhase.luteal,
                (cycleLength - 16) / cycleLength,
                currentDay > 16,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Day indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Day 1', style: Theme.of(context).textTheme.labelSmall),
            Text('Day $cycleLength', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ],
    );
  }

  Widget _buildPhaseSegment(CyclePhase phase, double fraction, bool isActive) {
    return Expanded(
      flex: (fraction * 100).round(),
      child: Container(
        height: 24,
        decoration: BoxDecoration(
          color: isActive
              ? _getPhaseColor(phase)
              : _getPhaseColor(phase).withOpacity(0.3),
          border: isActive
              ? Border.all(color: Colors.white, width: 2)
              : null,
        ),
        child: isActive
            ? Center(
                child: Text(
                  phase.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildRecommendationRow(
    BuildContext context,
    IconData icon,
    String label,
    String content,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              content,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPhaseColor(CyclePhase? phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return const Color(0xFFE57373);
      case CyclePhase.follicular:
        return const Color(0xFF81C784);
      case CyclePhase.ovulation:
        return const Color(0xFFFFD54F);
      case CyclePhase.luteal:
        return const Color(0xFF64B5F6);
      default:
        return Colors.grey;
    }
  }

  String _getPhaseEmoji(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return '🌙';
      case CyclePhase.follicular:
        return '🌱';
      case CyclePhase.ovulation:
        return '☀️';
      case CyclePhase.luteal:
        return '🍂';
    }
  }
}
