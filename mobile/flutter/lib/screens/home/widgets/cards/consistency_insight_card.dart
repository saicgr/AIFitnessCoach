
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/providers/consistency_provider.dart';
import '../../../../data/services/api_client.dart';

/// Consistency Insight Card for the home screen
/// Shows current streak prominently with fire animation
class ConsistencyInsightCard extends ConsumerStatefulWidget {
  const ConsistencyInsightCard({super.key});

  @override
  ConsumerState<ConsistencyInsightCard> createState() =>
      _ConsistencyInsightCardState();
}

class _ConsistencyInsightCardState
    extends ConsumerState<ConsistencyInsightCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _hasLoadedData = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadDataIfNeeded();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadDataIfNeeded() async {
    if (_hasLoadedData) return;

    final userId = await ref.read(apiClientProvider).getUserId();
    if (userId != null && mounted) {
      final notifier = ref.read(consistencyProvider.notifier);
      notifier.setUserId(userId);
      await notifier.loadInsights(userId: userId);
      _hasLoadedData = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(consistencyProvider);

    // Loading state
    if (state.isLoading && !state.hasInsights) {
      return _buildLoadingCard(colorScheme);
    }

    // Error state - show minimal card
    if (state.error != null && !state.hasInsights) {
      return _buildErrorCard(colorScheme);
    }

    final currentStreak = state.currentStreak;
    final isActive = state.isStreakActive;
    final needsRecovery = state.needsRecovery;

    return GestureDetector(
      onTap: () => context.push('/consistency'),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isActive
                    ? [
                        Colors.orange.shade400,
                        Colors.deepOrange.shade400,
                      ]
                    : needsRecovery
                        ? [
                            colorScheme.secondaryContainer,
                            colorScheme.tertiaryContainer,
                          ]
                        : [
                            colorScheme.surfaceContainerHighest,
                            colorScheme.surfaceContainerHigh,
                          ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha:
                            0.3 + _pulseController.value * 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Fire Icon with Animation
                _buildFireIcon(isActive, colorScheme),
                const SizedBox(width: 12),

                // Streak Info
                Expanded(
                  child: _buildStreakInfo(
                    currentStreak,
                    isActive,
                    needsRecovery,
                    state,
                    colorScheme,
                  ),
                ),

                // Arrow indicator
                Icon(
                  Icons.chevron_right,
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.8)
                      : colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05, end: 0);
  }

  Widget _buildFireIcon(bool isActive, ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: isActive ? 1.0 + _pulseController.value * 0.1 : 1.0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow effect for active streak
              if (isActive)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha:
                            0.4 + _pulseController.value * 0.2),
                        blurRadius: 12,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.2)
                      : colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.local_fire_department,
                  size: 28,
                  color: isActive ? Colors.white : colorScheme.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStreakInfo(
    int currentStreak,
    bool isActive,
    bool needsRecovery,
    ConsistencyState state,
    ColorScheme colorScheme,
  ) {
    final textColor = isActive ? Colors.white : colorScheme.onSurface;
    final subtextColor = isActive
        ? Colors.white.withValues(alpha: 0.9)
        : colorScheme.onSurfaceVariant;

    if (needsRecovery) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Start Fresh Today!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Tap to begin a new streak',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSecondaryContainer.withValues(alpha: 0.8),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$currentStreak',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: textColor,
                height: 1,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              currentStreak == 1 ? 'day streak' : 'day streak',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: subtextColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          state.insights?.streakMessage ?? _getStreakMessage(currentStreak, isActive),
          style: TextStyle(
            fontSize: 12,
            color: subtextColor,
          ),
        ),
      ],
    );
  }

  String _getStreakMessage(int streak, bool isActive) {
    if (streak == 0) {
      return 'Start your streak today!';
    } else if (streak < 3) {
      return 'Building momentum!';
    } else if (streak < 7) {
      return 'Great consistency!';
    } else if (streak < 14) {
      return 'On fire! Keep going!';
    } else if (streak < 30) {
      return 'Incredible dedication!';
    } else {
      return 'Legendary streak!';
    }
  }

  Widget _buildLoadingCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.local_fire_department,
              size: 28,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 120,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: 1500.ms,
          color: colorScheme.outline.withValues(alpha: 0.3),
        );
  }

  Widget _buildErrorCard(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        _hasLoadedData = false;
        _loadDataIfNeeded();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.local_fire_department,
                size: 28,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Streak',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to refresh',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.refresh,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact streak widget for tight spaces
class CompactStreakWidget extends ConsumerWidget {
  const CompactStreakWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(consistencyProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final streak = state.currentStreak;
    final isActive = state.isStreakActive;

    return GestureDetector(
      onTap: () => context.push('/consistency'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.orange.shade400
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department,
              size: 18,
              color: isActive ? Colors.white : colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              '$streak',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
