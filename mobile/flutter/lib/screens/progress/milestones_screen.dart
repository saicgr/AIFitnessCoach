import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/user_provider.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../core/theme/theme_colors.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/design_system/zealova.dart';
import '../../data/models/milestone.dart';
import '../../data/providers/milestones_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/glass_sheet.dart';
import '../../core/services/posthog_service.dart';
import '../reports/widgets/report_share_sheet.dart';
import 'widgets/milestone_celebration_dialog.dart';

import '../../l10n/generated/app_localizations.dart';
import '../common/app_refresh_indicator.dart';
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
    final tc = ThemeColors.of(context);
    final state = ref.watch(milestonesProvider);

    // Check for uncelebrated milestones and show celebration
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForCelebrations(state);
    });

    return Scaffold(
      backgroundColor: tc.background,
      appBar: ZealovaAppBar(
        title: AppLocalizations.of(context).milestonesYourJourney,
        kicker: 'Progress',
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) => ZealovaTextTabs(
                tabs: [
                  AppLocalizations.of(context).trophiesEarnedMilestones,
                  AppLocalizations.of(context).milestonesYourRoi,
                ],
                activeIndex: _tabController.index,
                onChanged: (i) => _tabController.animateTo(i),
              ),
            ),
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
          if (!mounted) return;
          await _openMilestoneShareSheet(milestone);
        },
      ),
    );
  }

  /// Opens the unified ReportShareSheet for a single achieved milestone.
  /// Hero number is the milestone's point value; highlight row shows the
  /// tier + the total points earned across the journey for social proof.
  Future<void> _openMilestoneShareSheet(UserMilestone milestone) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final user = ref.read(currentUserProvider).asData?.value;
    final state = ref.read(milestonesProvider);
    final def = milestone.milestone;
    final tier = def?.tier;
    final periodLabel =
        DateFormat('MMM yyyy').format(DateTime.now()).toUpperCase();

    final highlights = <ReportHighlight>[];
    if (tier != null) {
      highlights.add(
        ReportHighlight(label: 'TIER', value: tier.displayName.toUpperCase()),
      );
    }
    highlights.add(
      ReportHighlight(label: AppLocalizations.of(context).milestonesPoints, value: '${def?.points ?? 0}'),
    );
    highlights.add(
      ReportHighlight(label: 'TOTAL', value: '${state.totalPoints}'),
    );

    final data = ReportShareData(
      reportType: ReportType.milestones,
      title: def?.name ?? AppLocalizations.of(context).milestonesMilestone,
      periodLabel: periodLabel,
      primaryStats: {
        'hero_value': '${def?.points ?? 0}',
        'hero_unit': 'points',
        if (tier != null) 'tier': tier.displayName,
      },
      highlights: highlights,
      userDisplayName: user?.displayName,
      accentColor: accent,
      deepLinkUrl: null,
    );
    if (!mounted) return;
    await ReportShareSheet.show(context, data: data);
  }

  List<MilestoneProgress> _filterByCategory(List<MilestoneProgress> milestones) {
    if (_selectedCategory == null) return milestones;
    return milestones
        .where((m) => m.milestone.category.name == _selectedCategory)
        .toList();
  }

  Widget _buildSummaryCard(bool isDark, MilestonesState state) {
    final tc = ThemeColors.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Column(
        children: [
          const ZealovaRule(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              children: [
                Icon(Icons.emoji_events_outlined, size: 22, color: tc.accent),
                const SizedBox(width: 14),
                Expanded(
                  child: ZealovaStatTile(
                    value: '${state.totalAchieved}',
                    label: AppLocalizations.of(context).milestonesAchieved,
                    valueSize: 30,
                  ),
                ),
                Container(
                  height: 44,
                  width: 1,
                  color: AppColors.hairline,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: ZealovaStatTile(
                    value: '${state.totalPoints}',
                    label: AppLocalizations.of(context).trophyRoomPoints,
                    valueSize: 30,
                    accentValue: true,
                  ),
                ),
              ],
            ),
          ),
          const ZealovaRule(),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(bool isDark, List<MilestoneCategory> categories) {
    return SizedBox(
      height: 36,
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
              child: ZealovaChip(
                label: AppLocalizations.of(context).syncedWorkoutsHistoryAll,
                selected: isSelected,
                onTap: () {
                  HapticService.light();
                  setState(() => _selectedCategory = null);
                },
              ),
            );
          }

          final category = categories[index - 1];
          final isSelected = _selectedCategory == category.name;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ZealovaChip(
              label: category.displayName,
              selected: isSelected,
              onTap: () {
                HapticService.light();
                setState(() => _selectedCategory = isSelected ? null : category.name);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNextMilestoneCard(bool isDark, MilestoneProgress next) {
    final tc = ThemeColors.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ZealovaSectionKicker(
                AppLocalizations.of(context).milestonesNextMilestone,
                accent: true,
              ),
              const Spacer(),
              Text(
                '${next.progressPercentage?.toStringAsFixed(0) ?? 0}%',
                style: ZType.disp(20, color: tc.accent, height: 1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            next.milestone.name,
            style: ZType.lbl(17, color: tc.textPrimary, letterSpacing: 0.5),
          ),
          if (next.milestone.description != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                next.milestone.description!,
                style: ZType.ser(13, color: tc.textMuted),
              ),
            ),
          const SizedBox(height: 14),
          // Progress bar (hairline track)
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: next.progressFraction,
              backgroundColor: AppColors.hairlineStrong,
              valueColor: AlwaysStoppedAnimation<Color>(tc.accent),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${next.currentValue?.toInt() ?? 0} / ${next.milestone.threshold}',
            style: ZType.data(12, color: tc.textMuted),
          ),
        ],
      ),
    );
  }

  /// Milestone strip cell — v2 `.pg-mile` language: an Anton threshold numeral
  /// with a Barlow state line. Achieved = accent-tinted border + check, current
  /// (the next/in-progress milestone) = accent border + "N to go", locked =
  /// muted hairline.
  Widget _buildMilestoneBadge(bool isDark, MilestoneProgress progress, bool isAchieved) {
    final tc = ThemeColors.of(context);

    // Is this the active "current" milestone (the one in progress)?
    final isCurrent = !isAchieved &&
        (progress.progressPercentage != null &&
            progress.progressPercentage! > 0);

    Color borderColor;
    Color numeralColor;
    Color? fillColor;
    Widget stateLine;

    if (isAchieved) {
      borderColor = tc.accent.withValues(alpha: 0.4);
      numeralColor = tc.accent;
      fillColor = tc.accent.withValues(alpha: 0.05);
      stateLine = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check, size: 11, color: tc.accent),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              progress.milestone.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ZType.lbl(8, color: tc.textMuted, letterSpacing: 0.8),
            ),
          ),
        ],
      );
    } else if (isCurrent) {
      borderColor = tc.accent;
      numeralColor = tc.accent;
      fillColor = null;
      stateLine = Text(
        '${progress.progressPercentage!.toStringAsFixed(0)}%',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: ZType.lbl(8, color: tc.accent, letterSpacing: 0.8),
      );
    } else {
      borderColor = AppColors.cardBorder;
      numeralColor = tc.textMuted;
      fillColor = null;
      stateLine = Text(
        progress.milestone.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: ZType.lbl(8, color: tc.textMuted, letterSpacing: 0.8),
      );
    }

    return GestureDetector(
      onTap: () {
        HapticService.light();
        _showMilestoneDetails(progress, isAchieved);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${progress.milestone.threshold}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ZType.disp(22, color: numeralColor, height: 1),
            ),
            const SizedBox(height: 6),
            stateLine,
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
    final tc = ThemeColors.of(context);
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
                    : AppColors.hairlineStrong,
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
                color: tc.textPrimary,
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
                    color: tc.textMuted,
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
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    tier.displayName.toUpperCase(),
                    style: ZType.lbl(10, color: Color(tier.colorValue), letterSpacing: 1.4),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.cardBorder),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars, size: 13, color: tc.accent),
                      const SizedBox(width: 4),
                      Text(
                        '${progress.milestone.points} pts',
                        style: ZType.lbl(10, color: tc.accent, letterSpacing: 1.2),
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
                  backgroundColor: AppColors.hairlineStrong,
                  valueColor: AlwaysStoppedAnimation<Color>(tc.accent),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${progress.currentValue?.toInt() ?? 0} / ${progress.milestone.threshold}',
                style: ZType.data(13, color: tc.textMuted),
              ),
            ],
            if (isAchieved && progress.achievedAt != null) ...[
              const SizedBox(height: 16),
              Text(
                'Achieved ${_formatDate(progress.achievedAt!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: tc.textMuted,
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
    final tc = ThemeColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${roi.totalWorkoutsCompleted}',
          style: ZType.disp(58, color: tc.textPrimary, height: 0.9),
        ),
        const SizedBox(height: 6),
        Text(
          AppLocalizations.of(context).trophiesEarnedTotalWorkouts.toUpperCase(),
          style: ZType.lbl(12, color: tc.textMuted, letterSpacing: 1.6),
        ),
        if (roi.strengthSummary.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: tc.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              roi.strengthSummary,
              style: ZType.lbl(12, color: tc.success, letterSpacing: 0.8),
            ),
          ),
        ],
        const SizedBox(height: 18),
        const ZealovaRule(),
      ],
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
    final tc = ThemeColors.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: tc.textMuted, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style:
                          ZType.lbl(10, color: tc.textMuted, letterSpacing: 1.4),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          subtitle,
                          style: ZType.ser(12, color: tc.textMuted),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                value,
                style: ZType.disp(22, color: tc.textPrimary, height: 1),
              ),
            ],
          ),
        ),
        const ZealovaRule(),
      ],
    );
  }

  Widget _buildJourneyStats(bool isDark, ROIMetrics roi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ZealovaSectionKicker(
          AppLocalizations.of(context).milestonesYourJourney,
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
      ],
    );
  }

  Widget _buildJourneyStatItem(
    bool isDark,
    String label,
    String value,
    IconData icon, {
    bool highlighted = false,
  }) {
    final tc = ThemeColors.of(context);
    final iconColor = highlighted ? tc.accent : tc.textMuted;

    return Column(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: ZType.disp(
            18,
            color: highlighted ? tc.accent : tc.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: ZType.lbl(9, color: tc.textMuted, letterSpacing: 1.2),
        ),
      ],
    );
  }
}
