import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/pill_app_bar.dart';
import '../../data/models/milestone.dart';
import '../../data/providers/milestones_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/glass_sheet.dart';
import '../../widgets/segmented_tab_bar.dart';
import '../../core/services/posthog_service.dart';
import 'widgets/milestone_celebration_dialog.dart';

part 'milestones_screen_ui.dart';


/// Milestones screen showing achieved and upcoming milestones with ROI metrics.
class MilestonesScreen extends ConsumerStatefulWidget {
  const MilestonesScreen({super.key});

  @override
  ConsumerState<MilestonesScreen> createState() => _MilestonesScreenState();
}

class _MilestonesScreenState extends ConsumerState<MilestonesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    ref.read(posthogServiceProvider).capture(eventName: 'milestones_viewed');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId != null) {
      ref.read(milestonesProvider.notifier).loadAll(userId: userId);
      ref.read(milestonesProvider.notifier).loadROIMetrics(userId: userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(milestonesProvider);
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.background;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    // Check for uncelebrated milestones and show celebration
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForCelebrations(state);
    });

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PillAppBar(
        title: 'Your Journey',
      ),
      body: Column(
        children: [
          SegmentedTabBar(
            controller: _tabController,
            showIcons: false,
            tabs: [
              SegmentedTabItem(label: 'Milestones'),
              SegmentedTabItem(label: 'Your ROI'),
            ],
          ),
          Expanded(
            child: state.isLoading
                ? AppLoading.fullScreen()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMilestonesTab(isDark, state),
                      _buildROITab(isDark, state),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _checkForCelebrations(MilestonesState state) {
    if (state.hasUncelebrated && state.uncelebrated.isNotEmpty) {
      final first = state.uncelebrated.first;
      if (first.milestone != null) {
        _showCelebrationDialog(first);
      }
    }
  }

  void _showCelebrationDialog(UserMilestone milestone) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MilestoneCelebrationDialog(
        milestone: milestone,
        onCelebrated: () async {
          await ref.read(milestonesProvider.notifier).markAsCelebrated([milestone.id]);
          ref.read(posthogServiceProvider).capture(
            eventName: 'milestone_celebrated',
            properties: <String, Object>{
              'milestone_name': milestone.milestone?.name ?? 'unknown',
              'milestone_id': milestone.id,
            },
          );
          if (mounted) {
            Navigator.of(context).pop();
          }
        },
        onShare: (platform) async {
          await ref.read(milestonesProvider.notifier).recordShare(
            milestone.id,
            platform,
          );
          ref.read(posthogServiceProvider).capture(
            eventName: 'milestone_shared',
            properties: <String, Object>{
              'milestone_name': milestone.milestone?.name ?? 'unknown',
              'milestone_id': milestone.id,
              'platform': platform,
            },
          );
          final shareText = milestone.milestone?.shareMessage ??
              'I just achieved ${milestone.milestone?.name} in FitWiz!';
          await Share.share(shareText);
        },
      ),
    );
  }

  List<MilestoneProgress> _filterByCategory(List<MilestoneProgress> milestones) {
    if (_selectedCategory == null) return milestones;
    return milestones
        .where((m) => m.milestone.category.name == _selectedCategory)
        .toList();
  }

  Widget _buildSummaryCard(bool isDark, MilestonesState state) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppColors.purple.withOpacity(0.1),
              AppColors.cyan.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            // Total points
            Expanded(
              child: Column(
                children: [
                  Icon(
                    Icons.stars,
                    color: AppColors.yellow,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${state.totalPoints}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    'Points',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 60,
              width: 1,
              color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
            ),
            // Total achieved
            Expanded(
              child: Column(
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: AppColors.purple,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${state.totalAchieved}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    'Achieved',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(bool isDark, List<MilestoneCategory> categories) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            // "All" option
            final isSelected = _selectedCategory == null;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text('All'),
                selected: isSelected,
                onSelected: (_) {
                  HapticService.light();
                  setState(() => _selectedCategory = null);
                },
                backgroundColor: glassSurface,
                selectedColor: AppColors.purple.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.purple : textMuted,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                showCheckmark: false,
              ),
            );
          }

          final category = categories[index - 1];
          final isSelected = _selectedCategory == category.name;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category.displayName),
              selected: isSelected,
              onSelected: (_) {
                HapticService.light();
                setState(() => _selectedCategory = isSelected ? null : category.name);
              },
              backgroundColor: glassSurface,
              selectedColor: AppColors.purple.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.purple : textMuted,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildNextMilestoneCard(bool isDark, MilestoneProgress next) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.cyan.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flag,
                  color: AppColors.cyan,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Next Milestone',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                Text(
                  '${next.progressPercentage?.toStringAsFixed(0) ?? 0}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cyan,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              next.milestone.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            if (next.milestone.description != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  next.milestone.description!,
                  style: TextStyle(
                    fontSize: 13,
                    color: textMuted,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: next.progressFraction,
                backgroundColor: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${next.currentValue?.toInt() ?? 0} / ${next.milestone.threshold}',
              style: TextStyle(
                fontSize: 12,
                color: textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneBadge(bool isDark, MilestoneProgress progress, bool isAchieved) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final tier = progress.milestone.tier;

    return GestureDetector(
      onTap: () {
        HapticService.light();
        _showMilestoneDetails(progress, isAchieved);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isAchieved ? elevatedColor : elevatedColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAchieved
                ? Color(tier.colorValue).withOpacity(0.5)
                : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isAchieved
                    ? Color(tier.colorValue).withOpacity(0.2)
                    : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getIconForMilestone(progress.milestone.icon ?? 'star'),
                  style: TextStyle(
                    fontSize: 24,
                    color: isAchieved ? null : textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Name
            Text(
              progress.milestone.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isAchieved ? textColor : textMuted,
              ),
            ),
            // Progress for upcoming
            if (!isAchieved && progress.progressPercentage != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${progress.progressPercentage!.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.cyan,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getIconForMilestone(String iconName) {
    // Map icon names to emojis
    final iconMap = {
      'trophy': '\u{1F3C6}',
      'fire': '\u{1F525}',
      'muscle': '\u{1F4AA}',
      'star': '\u{2B50}',
      'flame': '\u{1F525}',
      'crown': '\u{1F451}',
      'diamond': '\u{1F48E}',
      'calendar': '\u{1F4C5}',
      'medal': '\u{1F3C5}',
      'target': '\u{1F3AF}',
      'clock': '\u{23F0}',
      'hourglass': '\u{23F3}',
      'dumbbell': '\u{1F3CB}',
      'scale': '\u{2696}',
    };
    return iconMap[iconName] ?? '\u{2B50}';
  }

  void _showMilestoneDetails(MilestoneProgress progress, bool isAchieved) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final tier = progress.milestone.tier;

    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isAchieved
                    ? Color(tier.colorValue).withOpacity(0.2)
                    : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                shape: BoxShape.circle,
                border: isAchieved
                    ? Border.all(color: Color(tier.colorValue), width: 2)
                    : null,
              ),
              child: Center(
                child: Text(
                  _getIconForMilestone(progress.milestone.icon ?? 'star'),
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              progress.milestone.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            if (progress.milestone.description != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  progress.milestone.description!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: textMuted,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Tier and points
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(tier.colorValue).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tier.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(tier.colorValue),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars, size: 14, color: AppColors.yellow),
                      const SizedBox(width: 4),
                      Text(
                        '${progress.milestone.points} pts',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.yellow,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!isAchieved) ...[
              const SizedBox(height: 24),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.progressFraction,
                  backgroundColor: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${progress.currentValue?.toInt() ?? 0} / ${progress.milestone.threshold}',
                style: TextStyle(
                  fontSize: 14,
                  color: textMuted,
                ),
              ),
            ],
            if (isAchieved && progress.achievedAt != null) ...[
              const SizedBox(height: 16),
              Text(
                'Achieved ${_formatDate(progress.achievedAt!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: textMuted,
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7} weeks ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildROIHeader(bool isDark, ROIMetrics roi) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            AppColors.purple.withOpacity(0.15),
            AppColors.cyan.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Text(
            '${roi.totalWorkoutsCompleted}',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            'Total Workouts',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          if (roi.strengthSummary.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                roi.strengthSummary,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.green,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildROIMetricCard(
    bool isDark,
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: textMuted,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyStats(bool isDark, ROIMetrics roi) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Journey',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildJourneyStatItem(
                  isDark,
                  'Days',
                  '${roi.journeyDays}',
                  Icons.calendar_today,
                ),
              ),
              Expanded(
                child: _buildJourneyStatItem(
                  isDark,
                  'This Week',
                  '${roi.workoutsThisWeek}',
                  Icons.date_range,
                ),
              ),
              Expanded(
                child: _buildJourneyStatItem(
                  isDark,
                  'This Month',
                  '${roi.workoutsThisMonth}',
                  Icons.calendar_month,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildJourneyStatItem(
                  isDark,
                  'Avg/Week',
                  roi.averageWorkoutsPerWeek.toStringAsFixed(1),
                  Icons.show_chart,
                ),
              ),
              Expanded(
                child: _buildJourneyStatItem(
                  isDark,
                  'Current Streak',
                  '${roi.currentStreakDays}',
                  Icons.local_fire_department,
                  highlighted: roi.currentStreakDays >= 7,
                ),
              ),
              Expanded(
                child: _buildJourneyStatItem(
                  isDark,
                  'Best Streak',
                  '${roi.longestStreakDays}',
                  Icons.emoji_events,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyStatItem(
    bool isDark,
    String label,
    String value,
    IconData icon, {
    bool highlighted = false,
  }) {
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final color = highlighted ? AppColors.orange : textMuted;

    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: highlighted ? AppColors.orange : textColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textMuted,
          ),
        ),
      ],
    );
  }
}
