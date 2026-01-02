import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/consistency.dart';
import '../../data/providers/consistency_provider.dart';
import '../../data/services/api_client.dart';

/// Consistency Insights Dashboard Screen
/// Displays streak information, workout patterns, and recovery options
class ConsistencyScreen extends ConsumerStatefulWidget {
  const ConsistencyScreen({super.key});

  @override
  ConsumerState<ConsistencyScreen> createState() => _ConsistencyScreenState();
}

class _ConsistencyScreenState extends ConsumerState<ConsistencyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fireAnimationController;
  String? _userId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fireAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _loadData();
  }

  @override
  void dispose() {
    _fireAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final userId = await ref.read(apiClientProvider).getUserId();
    if (userId != null && mounted) {
      setState(() {
        _userId = userId;
      });
      final notifier = ref.read(consistencyProvider.notifier);
      notifier.setUserId(userId);
      await notifier.loadAll(userId: userId);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(consistencyProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Consistency'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading || _userId == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref
                  .read(consistencyProvider.notifier)
                  .refresh(userId: _userId),
              child: state.error != null
                  ? _buildErrorState(state.error!, colorScheme)
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Big Streak Counter
                          _buildStreakCard(state, colorScheme),
                          const SizedBox(height: 16),

                          // Calendar Heatmap
                          _buildCalendarHeatmap(state, colorScheme),
                          const SizedBox(height: 16),

                          // Day Patterns
                          _buildDayPatternsCard(state, colorScheme),
                          const SizedBox(height: 16),

                          // Monthly Stats
                          _buildMonthlyStatsCard(state, colorScheme),
                          const SizedBox(height: 16),

                          // Weekly Trend
                          _buildWeeklyTrendCard(state, colorScheme),
                          const SizedBox(height: 16),

                          // Recovery Card (if needed)
                          if (state.needsRecovery)
                            _buildRecoveryCard(state, colorScheme),

                          const SizedBox(height: 80), // Bottom padding
                        ],
                      ),
                    ),
            ),
    );
  }

  Widget _buildErrorState(String error, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // Streak Card with Fire Animation
  // ============================================

  Widget _buildStreakCard(ConsistencyState state, ColorScheme colorScheme) {
    final currentStreak = state.currentStreak;
    final longestStreak = state.longestStreak;
    final isActive = state.isStreakActive;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isActive
              ? [
                  Colors.orange.shade400,
                  Colors.red.shade400,
                ]
              : [
                  colorScheme.surfaceContainerHighest,
                  colorScheme.surfaceContainerHigh,
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // Fire Icon with Animation
          AnimatedBuilder(
            animation: _fireAnimationController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_fireAnimationController.value * 0.1),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow effect
                    if (isActive)
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange
                                  .withValues(alpha: 0.3 + _fireAnimationController.value * 0.2),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    Icon(
                      Icons.local_fire_department,
                      size: 80,
                      color: isActive
                          ? Colors.white
                          : colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Streak Count
          Text(
            '$currentStreak',
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : colorScheme.onSurface,
              height: 1,
            ),
          ),
          Text(
            currentStreak == 1 ? 'DAY STREAK' : 'DAY STREAK',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: isActive
                  ? Colors.white.withValues(alpha: 0.9)
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // Longest Streak Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.2)
                  : colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 18,
                  color: isActive ? Colors.amber : colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Longest: $longestStreak days',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  // ============================================
  // Calendar Heatmap
  // ============================================

  Widget _buildCalendarHeatmap(
      ConsistencyState state, ColorScheme colorScheme) {
    final calendarData = state.calendarData;
    if (calendarData == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today,
                  size: 20, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'Last 4 Weeks',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Day labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((d) => SizedBox(
                      width: 36,
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),

          // Calendar grid
          _buildCalendarGrid(calendarData.data, colorScheme),

          const SizedBox(height: 16),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Completed', Colors.green, colorScheme),
              const SizedBox(width: 16),
              _buildLegendItem('Missed', Colors.red, colorScheme),
              const SizedBox(width: 16),
              _buildLegendItem('Rest', colorScheme.outline, colorScheme),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildCalendarGrid(
      List<CalendarHeatmapData> data, ColorScheme colorScheme) {
    if (data.isEmpty) {
      return const SizedBox(height: 150);
    }

    // Organize data into weeks
    final weeks = <List<CalendarHeatmapData?>>[];
    var currentWeek = <CalendarHeatmapData?>[];

    // Add padding for first week
    if (data.isNotEmpty) {
      final firstDayOfWeek = data.first.dayOfWeek;
      for (var i = 0; i < firstDayOfWeek; i++) {
        currentWeek.add(null);
      }
    }

    for (final day in data) {
      currentWeek.add(day);
      if (currentWeek.length == 7) {
        weeks.add(currentWeek);
        currentWeek = [];
      }
    }

    // Add remaining days
    if (currentWeek.isNotEmpty) {
      while (currentWeek.length < 7) {
        currentWeek.add(null);
      }
      weeks.add(currentWeek);
    }

    return Column(
      children: weeks.map((week) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: week.map((day) {
              if (day == null) {
                return const SizedBox(width: 36, height: 36);
              }

              Color bgColor;
              Color textColor;
              switch (day.statusEnum) {
                case CalendarStatus.completed:
                  bgColor = Colors.green;
                  textColor = Colors.white;
                  break;
                case CalendarStatus.missed:
                  bgColor = Colors.red.shade400;
                  textColor = Colors.white;
                  break;
                case CalendarStatus.rest:
                  bgColor = colorScheme.surfaceContainerHighest;
                  textColor = colorScheme.onSurfaceVariant;
                  break;
                case CalendarStatus.future:
                  bgColor = colorScheme.surfaceContainerHigh;
                  textColor = colorScheme.outline;
                  break;
              }

              return Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    day.dateTime.day.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLegendItem(String label, Color color, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ============================================
  // Day Patterns Card
  // ============================================

  Widget _buildDayPatternsCard(
      ConsistencyState state, ColorScheme colorScheme) {
    final insights = state.insights;
    if (insights == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Workout Patterns',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Best Day
          if (insights.bestDay != null)
            _buildPatternRow(
              'Your best day',
              insights.bestDayDisplay ?? 'N/A',
              Icons.thumb_up,
              Colors.green,
              colorScheme,
            ),
          const SizedBox(height: 12),

          // Worst Day
          if (insights.worstDay != null)
            _buildPatternRow(
              'You tend to skip',
              insights.worstDayDisplay ?? 'N/A',
              Icons.warning_amber,
              Colors.orange,
              colorScheme,
            ),
          const SizedBox(height: 12),

          // Preferred Time
          if (insights.preferredTime != null)
            _buildPatternRow(
              'Preferred time',
              _formatTimeOfDay(insights.preferredTime!),
              Icons.schedule,
              colorScheme.primary,
              colorScheme,
            ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildPatternRow(
    String label,
    String value,
    IconData icon,
    Color iconColor,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  String _formatTimeOfDay(String timeKey) {
    final displays = {
      'early_morning': 'Early Morning',
      'morning': 'Morning',
      'midday': 'Midday',
      'afternoon': 'Afternoon',
      'evening': 'Evening',
      'night': 'Night',
    };
    return displays[timeKey] ?? timeKey;
  }

  // ============================================
  // Monthly Stats Card
  // ============================================

  Widget _buildMonthlyStatsCard(
      ConsistencyState state, ColorScheme colorScheme) {
    final insights = state.insights;
    if (insights == null) return const SizedBox.shrink();

    final completed = insights.monthWorkoutsCompleted;
    final scheduled = insights.monthWorkoutsScheduled;
    final rate = insights.monthCompletionRate;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month,
                  size: 20, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'This Month',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Big number display
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$completed',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'of $scheduled workouts',
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: scheduled > 0 ? completed / scheduled : 0,
              backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                rate >= 80
                    ? Colors.green
                    : rate >= 50
                        ? Colors.orange
                        : Colors.red,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),

          // Completion rate
          Text(
            '${rate.toStringAsFixed(0)}% completion rate',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  // ============================================
  // Weekly Trend Card
  // ============================================

  Widget _buildWeeklyTrendCard(
      ConsistencyState state, ColorScheme colorScheme) {
    final insights = state.insights;
    if (insights == null) return const SizedBox.shrink();

    final weeklyRates = insights.weeklyCompletionRates;
    final avgRate = insights.averageWeeklyRate;
    final trend = insights.weeklyTrendEnum;

    IconData trendIcon;
    Color trendColor;
    String trendText;

    switch (trend) {
      case WeeklyTrend.improving:
        trendIcon = Icons.trending_up;
        trendColor = Colors.green;
        trendText = 'Improving';
        break;
      case WeeklyTrend.declining:
        trendIcon = Icons.trending_down;
        trendColor = Colors.red;
        trendText = 'Needs attention';
        break;
      case WeeklyTrend.stable:
        trendIcon = Icons.trending_flat;
        trendColor = Colors.blue;
        trendText = 'Stable';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart,
                  size: 20, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'Weekly Trend',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(trendIcon, size: 16, color: trendColor),
                    const SizedBox(width: 4),
                    Text(
                      trendText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: trendColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Mini bar chart
          if (weeklyRates.isNotEmpty) _buildWeeklyBars(weeklyRates, colorScheme),

          const SizedBox(height: 12),

          // Average
          Center(
            child: Text(
              'Average: ${avgRate.toStringAsFixed(0)}% weekly completion',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildWeeklyBars(
      List<WeeklyConsistencyMetric> weeks, ColorScheme colorScheme) {
    // Reverse to show oldest first
    final reversedWeeks = weeks.reversed.toList();

    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: reversedWeeks.asMap().entries.map((entry) {
          final index = entry.key;
          final week = entry.value;
          final rate = week.completionRate / 100;
          final isLatest = index == reversedWeeks.length - 1;

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Bar
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 40,
                      height: math.max(4, rate * 50),
                      decoration: BoxDecoration(
                        color: isLatest
                            ? colorScheme.primary
                            : colorScheme.primary.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Label
                Text(
                  isLatest ? 'This week' : 'Wk ${index + 1}',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================
  // Recovery Card
  // ============================================

  Widget _buildRecoveryCard(ConsistencyState state, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.restart_alt,
                  color: colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start Fresh Today!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.insights?.recoverySuggestion ??
                          'Every day is a new opportunity to build your streak.',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _startRecovery('standard'),
                  icon: const Icon(Icons.fitness_center, size: 18),
                  label: const Text('Full Workout'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _startRecovery('quick_recovery'),
                  icon: const Icon(Icons.timer, size: 18),
                  label: const Text('Quick 15min'),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms, duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Future<void> _startRecovery(String type) async {
    final response = await ref.read(consistencyProvider.notifier).initiateRecovery(
      recoveryType: type,
    );

    if (response != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.motivationQuote ?? response.message),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Navigate to workout or home
      Navigator.of(context).pop();
    }
  }
}
