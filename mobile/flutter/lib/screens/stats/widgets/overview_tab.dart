import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/milestone.dart';
import '../../../data/providers/consistency_provider.dart';
import '../../../data/providers/milestones_provider.dart';
import '../../../data/providers/scores_provider.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/activity_heatmap.dart';
import '../../../widgets/exercise_search_results.dart';
import '../../../widgets/workout_day_detail_sheet.dart';

// ═══════════════════════════════════════════════════════════════════
// OVERVIEW TAB - Summary stats, recent achievements, weekly progress
// ═══════════════════════════════════════════════════════════════════

class OverviewTab extends ConsumerStatefulWidget {
  const OverviewTab({super.key});

  @override
  ConsumerState<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<OverviewTab> {
  Set<String> _highlightedDates = {};
  bool _showSearch = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchQuery = ref.watch(exerciseSearchQueryProvider);
    final consistencyState = ref.watch(consistencyProvider);
    final currentStreak = consistencyState.currentStreak;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    // Stats from heatmap data (this endpoint always works)
    final timeRange = ref.watch(heatmapTimeRangeProvider);
    final apiClient = ref.read(apiClientProvider);
    int completedCount = 0;
    int thisWeekCompleted = 0;
    int thisWeekTotal = 0;
    String totalDurationStr = '0m';

    // Read heatmap data synchronously via FutureBuilder in the widget tree
    // For now, compute from the consistency calendar data
    final calData = consistencyState.calendarData;
    if (calData != null) {
      completedCount = calData.totalCompleted;
      // Weekly: count completed/total this week from calendar data
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      for (final day in calData.data) {
        final dayDate = DateTime.tryParse(day.date);
        if (dayDate != null && !dayDate.isBefore(weekStart) && !dayDate.isAfter(now)) {
          if (day.status == 'completed') thisWeekCompleted++;
          if (day.status == 'completed' || day.status == 'missed') thisWeekTotal++;
        }
      }
      // Estimate total duration: ~45 min per completed workout
      final totalMin = completedCount * 45;
      totalDurationStr = totalMin >= 60 ? '${(totalMin / 60).toStringAsFixed(1)}h' : '${totalMin}m';
    }

    // Update highlighted dates when search query changes
    _updateHighlightedDates(searchQuery);

    return RefreshIndicator(
      onRefresh: () async {
        final uid = await ref.read(apiClientProvider).getUserId();
        if (uid == null) return;

        // Refresh all data
        final timeRange = ref.read(heatmapTimeRangeProvider);
        ref.invalidate(activityHeatmapProvider((userId: uid, weeks: timeRange.weeks, startDate: null, endDate: null)));
        await ref.read(consistencyProvider.notifier).loadCalendar(userId: uid, weeks: 52);
        ref.read(milestonesProvider.notifier).loadMilestoneProgress(userId: uid);
        ref.read(scoresProvider.notifier).loadScoresOverview(userId: uid);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activity Heatmap Card
            Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
              ),
            ),
            child: Column(
              children: [
                ActivityHeatmap(
                  highlightedDates: _highlightedDates,
                  isSearchActive: _showSearch || (searchQuery != null && searchQuery.isNotEmpty),
                  onSearchTapped: () {
                    HapticService.light();
                    setState(() {
                      _showSearch = !_showSearch;
                      if (!_showSearch) {
                        // Clear search when closing
                        ref.read(exerciseSearchQueryProvider.notifier).state = null;
                        _highlightedDates = {};
                      }
                    });
                  },
                  onDayTapped: (date) {
                    HapticService.light();
                    WorkoutDayDetailSheet.show(context, date);
                  },
                ),
                // Expandable Search Bar
                if (_showSearch) ...[
                  const SizedBox(height: 12),
                  ExerciseSearchBar(
                    onSearch: (exerciseName) {
                      // Search results will automatically update via provider
                    },
                    onClear: () {
                      setState(() {
                        _highlightedDates = {};
                      });
                    },
                  ),
                ],
              ],
            ),
          ),

          // Search Results (shown when search is active)
          if (searchQuery != null && searchQuery.isNotEmpty) ...[
            const SizedBox(height: 12),
            ExerciseSearchResults(
              exerciseName: searchQuery,
              onResultTapped: (date) {
                // Optionally highlight the tapped date
              },
            ),
          ],

          const SizedBox(height: 16),

          // Compact Stats Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _CompactStat(
                  icon: Icons.fitness_center,
                  value: '$completedCount',
                  label: 'Total',
                  color: AppColors.cyan,
                ),
                _StatDivider(),
                _CompactStat(
                  icon: Icons.local_fire_department,
                  value: '$thisWeekCompleted/$thisWeekTotal',
                  label: 'Week',
                  color: AppColors.orange,
                ),
                _StatDivider(),
                _CompactStat(
                  icon: Icons.trending_up,
                  value: currentStreak > 0 ? '$currentStreak' : '0',
                  label: 'Streak',
                  color: AppColors.success,
                ),
                _StatDivider(),
                _CompactStat(
                  icon: Icons.timer_outlined,
                  value: totalDurationStr,
                  label: 'Time',
                  color: AppColors.purple,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Achievements Preview
          SectionHeader(
            title: 'Recent Achievements',
            onViewAll: () => context.push('/achievements'),
          ),
          const SizedBox(height: 12),
          _AchievementsPreview(),

          const SizedBox(height: 24),

          // Quick Actions
          SectionHeader(title: 'Quick Access'),
          const SizedBox(height: 12),
          QuickActionButton(
            icon: Icons.monitor_weight_outlined,
            label: 'Body Measurements',
            onTap: () => context.push('/measurements'),
          ),
          const SizedBox(height: 8),
          QuickActionButton(
            icon: Icons.calendar_month,
            label: 'Reports & Insights',
            onTap: () => context.push('/reports'),
          ),
          const SizedBox(height: 8),
          QuickActionButton(
            icon: Icons.fitness_center,
            label: 'My 1RMs',
            onTap: () => context.push('/settings/my-1rms'),
          ),
          const SizedBox(height: 8),
          QuickActionButton(
            icon: Icons.emoji_events,
            label: 'Personal Records',
            onTap: () => context.push('/stats/personal-records'),
          ),
          const SizedBox(height: 8),
          QuickActionButton(
            icon: Icons.history,
            label: 'Exercise History',
            onTap: () => context.push('/stats/exercise-history'),
          ),
          const SizedBox(height: 8),
          QuickActionButton(
            icon: Icons.pie_chart_outline,
            label: 'Muscle Analytics',
            onTap: () => context.push('/stats/muscle-analytics'),
          ),

          // Bottom padding for floating nav bar
          const SizedBox(height: 80),
        ],
      ),
    ),
    );
  }

  Future<void> _updateHighlightedDates(String? searchQuery) async {
    if (searchQuery == null || searchQuery.isEmpty) {
      if (_highlightedDates.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _highlightedDates = {};
            });
          }
        });
      }
      return;
    }

    try {
      final apiClient = ref.read(apiClientProvider);
      final timeRange = ref.read(heatmapTimeRangeProvider);

      final userId = await apiClient.getUserId();
      if (userId == null || !mounted) return;

      final response = await ref.read(exerciseSearchProvider((
        userId: userId,
        exerciseName: searchQuery,
        weeks: timeRange.weeks,
      )).future);

      if (!mounted) return;
      setState(() {
        _highlightedDates = response.matchingDates.toSet();
      });
    } catch (_) {
      // Ignore errors
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════════

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;

  const SectionHeader({super.key, required this.title, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: const Text('View All'),
          ),
      ],
    );
  }
}

/// Compact stat widget for horizontal row display
class _CompactStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _CompactStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
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
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: textMuted,
          ),
        ),
      ],
    );
  }
}

/// Vertical divider for compact stats row
class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 1,
      height: 40,
      color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
    );
  }
}

class _AchievementsPreview extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final milestonesState = ref.watch(milestonesProvider);

    if (milestonesState.isLoading) {
      return Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final achieved = milestonesState.achieved;
    final upcoming = milestonesState.upcoming;

    // Build display list: up to 4 UNIQUE items by name, achieved first then upcoming
    final displayItems = <MilestoneProgress>[];
    final seenNames = <String>{};
    for (final mp in achieved) {
      if (seenNames.add(mp.milestone.name)) displayItems.add(mp);
      if (displayItems.length >= 4) break;
    }
    if (displayItems.length < 4) {
      for (final mp in upcoming) {
        if (seenNames.add(mp.milestone.name)) displayItems.add(mp);
        if (displayItems.length >= 4) break;
      }
    }

    if (displayItems.isEmpty) {
      return Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events_outlined,
                  color: AppColors.textMuted, size: 32),
              const SizedBox(height: 8),
              Text(
                'No achievements yet',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: displayItems.map((mp) {
          return _BadgeIcon(
            iconData: _milestoneIcon(mp.milestone.icon),
            label: mp.milestone.name,
            unlocked: mp.isAchieved,
            color: Color(mp.milestone.tier.colorValue),
            tier: mp.milestone.tier,
          );
        }).toList(),
      ),
    );
  }

  static IconData _milestoneIcon(String? iconName) {
    switch (iconName) {
      case 'fire': return Icons.local_fire_department;
      case 'flame': return Icons.whatshot;
      case 'crown': return Icons.workspace_premium;
      case 'trophy': return Icons.emoji_events;
      case 'diamond': return Icons.diamond;
      case 'star': return Icons.star;
      case 'medal': return Icons.military_tech;
      case 'target': return Icons.gps_fixed;
      case 'muscle': return Icons.fitness_center;
      case 'dumbbell': return Icons.fitness_center;
      case 'clock': return Icons.timer;
      case 'hourglass': return Icons.hourglass_bottom;
      case 'scale': return Icons.monitor_weight;
      case 'calendar': return Icons.calendar_month;
      case 'chat_bubble': return Icons.chat_bubble;
      case 'camera_alt': return Icons.camera_alt;
      case 'qr_code_scanner': return Icons.qr_code_scanner;
      case 'fitness_center': return Icons.fitness_center;
      case 'emoji_events': return Icons.emoji_events;
      default: return Icons.emoji_events;
    }
  }
}

class _BadgeIcon extends StatelessWidget {
  final IconData iconData;
  final String label;
  final bool unlocked;
  final Color color;
  final MilestoneTier tier;

  const _BadgeIcon({
    required this.iconData,
    required this.label,
    required this.unlocked,
    required this.color,
    required this.tier,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 72,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Badge container with glow effect for unlocked
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unlocked
                  ? color.withValues(alpha: 0.15)
                  : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.08)),
              border: Border.all(
                color: unlocked ? color.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.15),
                width: unlocked ? 2 : 1,
              ),
              boxShadow: unlocked ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ] : null,
            ),
            child: Icon(
              iconData,
              size: 24,
              color: unlocked ? color : Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: unlocked ? AppColors.textSecondary : AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class QuickActionButton extends ConsumerWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accent = ref.watch(accentColorProvider);
    final accentColor = accent.getColor(isDark);

    return Material(
      color: elevatedColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          HapticService.light();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: accentColor),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right,
                color: textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PRListWidget extends ConsumerWidget {
  const PRListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final prStats = ref.watch(prStatsProvider);
    final recentPrs = prStats?.recentPrs ?? [];

    if (recentPrs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.emoji_events_outlined, size: 48, color: textMuted),
              const SizedBox(height: 12),
              Text(
                'No Personal Records Yet',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Personal records are tracked as you complete workouts. Start training to see your progress here!',
                textAlign: TextAlign.center,
                style: TextStyle(color: textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recentPrs.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
        itemBuilder: (context, index) {
          final pr = recentPrs[index];
          final date = DateTime.tryParse(pr.achievedAt);
          final dateStr = date != null
              ? DateFormat('MMM d').format(date)
              : '';

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: AppColors.orange, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pr.exerciseDisplayName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${pr.liftDescription}  •  $dateStr',
                        style: TextStyle(fontSize: 13, color: textMuted),
                      ),
                    ],
                  ),
                ),
                if (pr.improvementPercent != null && pr.improvementPercent! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+${pr.improvementPercent!.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
