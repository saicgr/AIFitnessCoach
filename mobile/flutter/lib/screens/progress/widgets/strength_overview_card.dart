import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/models/scores.dart';
import '../../../data/providers/scores_provider.dart';

/// Card showing overall strength score and muscle group breakdown
class StrengthOverviewCard extends ConsumerStatefulWidget {
  final String userId;
  final Function(String muscleGroup)? onTapMuscleGroup;

  const StrengthOverviewCard({
    super.key,
    required this.userId,
    this.onTapMuscleGroup,
  });

  @override
  ConsumerState<StrengthOverviewCard> createState() =>
      _StrengthOverviewCardState();
}

class _StrengthOverviewCardState extends ConsumerState<StrengthOverviewCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scoresProvider.notifier).loadStrengthScores(userId: widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final scoresState = ref.watch(scoresProvider);
    final strengthScores = scoresState.strengthScores;
    final isLoading = scoresState.isLoading;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.fitness_center, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Strength Score',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    onPressed: () {
                      ref.read(scoresProvider.notifier).recalculateStrengthScores(userId: widget.userId);
                    },
                    icon: const Icon(Icons.refresh),
                    iconSize: 20,
                    tooltip: 'Recalculate',
                  ),
              ],
            ),
          ),

          if (isLoading && strengthScores == null)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (strengthScores == null)
            _buildEmptyState(colorScheme)
          else
            _buildContent(strengthScores, colorScheme),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 48,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No Strength Data Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete workouts with resistance exercises\nto track your strength progress.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AllStrengthScores scores, ColorScheme colorScheme) {
    // Get level color
    final levelColor = _getLevelColor(scores.level);

    return Column(
      children: [
        // Overall Score
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                levelColor.withOpacity(0.15),
                levelColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: levelColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: levelColor.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${scores.overallScore}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Level',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      scores.overallLevel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: levelColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${scores.muscleScores.length} muscle groups tracked',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Muscle Group Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'By Muscle Group',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Tap for details',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: scores.sortedMuscleScores
                    .map((muscle) => _buildMuscleChip(muscle, colorScheme))
                    .toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMuscleChip(StrengthScoreData muscle, ColorScheme colorScheme) {
    final levelColor = Color(muscle.levelColor);

    return InkWell(
      onTap: () => widget.onTapMuscleGroup?.call(muscle.muscleGroup),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: levelColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: levelColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: levelColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${muscle.strengthScore}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  muscle.muscleGroupDisplayName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  muscle.levelDisplayName,
                  style: TextStyle(
                    fontSize: 10,
                    color: levelColor,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            Icon(
              _getTrendIcon(muscle.trendDirection),
              size: 16,
              color: _getTrendColor(muscle.trendDirection),
            ),
          ],
        ),
      ),
    );
  }

  Color _getLevelColor(StrengthLevel level) {
    switch (level) {
      case StrengthLevel.elite:
        return const Color(0xFF9C27B0); // Purple
      case StrengthLevel.advanced:
        return const Color(0xFF2196F3); // Blue
      case StrengthLevel.intermediate:
        return const Color(0xFF4CAF50); // Green
      case StrengthLevel.novice:
        return const Color(0xFFFF9800); // Orange
      case StrengthLevel.beginner:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  IconData _getTrendIcon(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.improving:
        return Icons.trending_up;
      case TrendDirection.declining:
        return Icons.trending_down;
      case TrendDirection.maintaining:
        return Icons.trending_flat;
    }
  }

  Color _getTrendColor(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.improving:
        return Colors.green;
      case TrendDirection.declining:
        return Colors.red;
      case TrendDirection.maintaining:
        return Colors.grey;
    }
  }
}
