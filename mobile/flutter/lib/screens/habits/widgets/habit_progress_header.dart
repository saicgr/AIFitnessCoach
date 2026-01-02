import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Progress header showing today's habit completion stats
class HabitProgressHeader extends StatelessWidget {
  final int completed;
  final int total;
  final double percentage;

  const HabitProgressHeader({
    super.key,
    required this.completed,
    required this.total,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completed / total : 0.0;
    final isComplete = total > 0 && completed >= total;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isComplete
              ? [Colors.green.shade400, Colors.green.shade600]
              : [AppColors.teal, AppColors.teal.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isComplete ? Colors.green : AppColors.teal)
                .withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular progress
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isComplete)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 32,
                    )
                  else ...[
                    Text(
                      '$completed',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'of $total',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(width: 20),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isComplete ? 'All Done!' : "Today's Habits",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isComplete
                      ? 'You completed all your habits today!'
                      : '${total - completed} habits remaining',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${percentage.round()}% complete',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
