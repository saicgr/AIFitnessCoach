import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/providers/neat_provider.dart';
import '../../../../data/services/api_client.dart';

/// NEAT Activity Card for the home screen
/// Shows step progress, NEAT score, and active hours at a glance
/// Tapping navigates to the full NEAT dashboard
class NeatActivityCard extends ConsumerStatefulWidget {
  const NeatActivityCard({super.key});

  @override
  ConsumerState<NeatActivityCard> createState() => _NeatActivityCardState();
}

class _NeatActivityCardState extends ConsumerState<NeatActivityCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  bool _hasLoadedData = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _loadDataIfNeeded();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _loadDataIfNeeded() async {
    if (_hasLoadedData) return;

    final userId = await ref.read(apiClientProvider).getUserId();
    if (userId != null && mounted) {
      final notifier = ref.read(neatProvider.notifier);
      await notifier.loadDashboard(userId: userId);
      _hasLoadedData = true;
      if (mounted) {
        _progressController.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(neatProvider);

    // Loading state
    if (state.isLoading && state.dashboard == null) {
      return _buildLoadingCard(colorScheme);
    }

    // Error or no data state
    if (state.dashboard == null) {
      return _buildConnectCard(colorScheme);
    }

    final dashboard = state.dashboard!;
    final stepsToday = dashboard.stepGoal?.currentValue ?? 0;
    final stepGoalValue = dashboard.stepGoal?.targetValue ?? 10000;
    final progress = stepsToday / stepGoalValue;
    final neatScore = dashboard.todayScore?.score ?? 0;
    final activeHours = dashboard.todayScore?.totalStandingHours ?? 0;
    final streak = dashboard.streaks.isNotEmpty
        ? dashboard.streaks.firstWhere(
            (s) => s.streakType == 'steps',
            orElse: () => dashboard.streaks.first,
          )
        : null;

    return GestureDetector(
      onTap: () => context.push('/neat'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getProgressColor(progress).withValues(alpha: 0.15),
              colorScheme.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Icon(
                  Icons.directions_walk_rounded,
                  color: _getProgressColor(progress),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Daily Activity',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (streak != null && streak.currentStreak > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          '${streak.currentStreak}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Step progress
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    final animatedSteps =
                        (stepsToday * _progressController.value).round();
                    return Text(
                      _formatNumber(animatedSteps),
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getProgressColor(progress),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '/ ${_formatNumber(stepGoalValue)} steps',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Progress bar
            AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                final animatedProgress =
                    progress * _progressController.value;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: animatedProgress.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(
                      _getProgressColor(progress),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Bottom stats row
            Row(
              children: [
                _buildStatPill(
                  icon: Icons.score_rounded,
                  label: 'NEAT',
                  value: neatScore.toString(),
                  color: _getScoreColor(neatScore),
                  colorScheme: colorScheme,
                  theme: theme,
                ),
                const SizedBox(width: 8),
                _buildStatPill(
                  icon: Icons.timer_outlined,
                  label: 'Active',
                  value: '${activeHours}h',
                  color: activeHours >= 8
                      ? Colors.green
                      : activeHours >= 5
                          ? Colors.orange
                          : Colors.red,
                  colorScheme: colorScheme,
                  theme: theme,
                ),
                const Spacer(),
                if (progress >= 1.0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Goal Met!',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.directions_walk_rounded,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Daily Activity',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildConnectCard(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () => context.push('/neat'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.directions_walk_rounded,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Daily Activity',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Track your daily steps and activity',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Set up step goals →',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.75) return Colors.lightGreen;
    if (progress >= 0.5) return Colors.amber;
    if (progress >= 0.25) return Colors.orange;
    return Colors.red;
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.lightGreen;
    if (score >= 50) return Colors.amber;
    if (score >= 25) return Colors.orange;
    return Colors.red;
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}
