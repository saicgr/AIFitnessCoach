/// Exercise Analytics Page
///
/// Full page showing comprehensive exercise analytics:
/// - Weight progression chart
/// - Volume chart
/// - Personal records
/// - Set type distribution
/// - Friends tab to compare performance
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise.dart';

/// Exercise Analytics Page - full page with My Analytics and Friends tabs
class ExerciseAnalyticsPage extends StatefulWidget {
  final WorkoutExercise exercise;
  final bool useKg;
  final Map<String, dynamic>? lastSessionData;
  final Map<String, dynamic>? prData;

  const ExerciseAnalyticsPage({
    super.key,
    required this.exercise,
    required this.useKg,
    this.lastSessionData,
    this.prData,
  });

  @override
  State<ExerciseAnalyticsPage> createState() => _ExerciseAnalyticsPageState();
}

class _ExerciseAnalyticsPageState extends State<ExerciseAnalyticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String get _unit => widget.useKg ? 'kg' : 'lbs';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surface : Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textPrimary,
            size: 20,
          ),
        ),
        title: Column(
          children: [
            Text(
              widget.exercise.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Analytics',
              style: TextStyle(
                fontSize: 12,
                color: textMuted,
              ),
            ),
          ],
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => HapticFeedback.selectionClick(),
          indicatorColor: AppColors.success,
          indicatorWeight: 3,
          labelColor: AppColors.success,
          unselectedLabelColor: textMuted,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'My Analytics'),
            Tab(text: 'Friends'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // My Analytics Tab
          _buildMyAnalyticsTab(isDark, textPrimary, textMuted),
          // Friends Tab
          _buildFriendsTab(isDark, textPrimary, textMuted),
        ],
      ),
    );
  }

  /// Build My Analytics tab content
  Widget _buildMyAnalyticsTab(bool isDark, Color textPrimary, Color textMuted) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Personal Records Card
        _buildPRCard(isDark, textPrimary, textMuted),
        const SizedBox(height: 16),

        // Last Session Card
        _buildLastSessionCard(isDark, textPrimary, textMuted),
        const SizedBox(height: 16),

        // Weight Progression Chart
        _buildChartCard(
          title: 'Weight Progression',
          icon: Icons.trending_up_rounded,
          color: AppColors.electricBlue,
          isDark: isDark,
          textPrimary: textPrimary,
          textMuted: textMuted,
          chart: _buildWeightChart(isDark, textMuted),
        ),
        const SizedBox(height: 16),

        // Volume Chart
        _buildChartCard(
          title: 'Total Volume',
          icon: Icons.bar_chart_rounded,
          color: AppColors.purple,
          isDark: isDark,
          textPrimary: textPrimary,
          textMuted: textMuted,
          chart: _buildVolumeChart(isDark, textMuted),
        ),
        const SizedBox(height: 16),

        // Set Type Distribution
        _buildSetTypeDistribution(isDark, textPrimary, textMuted),
        const SizedBox(height: 16),

        // Stats Summary
        _buildStatsSummary(isDark, textPrimary, textMuted),

        SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
      ],
    );
  }

  /// Build Friends tab content
  Widget _buildFriendsTab(bool isDark, Color textPrimary, Color textMuted) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.purple.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 48,
                color: AppColors.purple,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Compare with Friends',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'See how your performance on ${widget.exercise.name} compares to your friends.',
              style: TextStyle(
                fontSize: 14,
                color: textMuted,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildComingSoonBadge(isDark),
            const SizedBox(height: 24),
            // Invite friends button
            OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                // TODO: Implement friend invite
              },
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Invite Friends'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.purple,
                side: BorderSide(color: AppColors.purple),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoonBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.rocket_launch_rounded,
            size: 16,
            color: AppColors.orange,
          ),
          const SizedBox(width: 8),
          Text(
            'Coming Soon',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.orange,
            ),
          ),
        ],
      ),
    );
  }

  /// Build Personal Record card
  Widget _buildPRCard(bool isDark, Color textPrimary, Color textMuted) {
    String prDisplay = 'No PR yet';
    String prSubtitle = 'Complete sets to set your first PR';

    if (widget.prData != null) {
      final weight = widget.prData!['weight'] as double?;
      final reps = widget.prData!['reps'] as int?;
      final date = widget.prData!['date'] as String?;
      if (weight != null && reps != null) {
        final displayWeight = widget.useKg ? weight : weight * 2.20462;
        prDisplay = '${displayWeight.toStringAsFixed(0)} $_unit x $reps reps';
        if (date != null) {
          prSubtitle = 'Set on $date';
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withOpacity(0.15),
            AppColors.success.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.success.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.emoji_events_rounded,
              color: AppColors.success,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personal Record',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  prDisplay,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
                Text(
                  prSubtitle,
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

  /// Build Last Session card
  Widget _buildLastSessionCard(bool isDark, Color textPrimary, Color textMuted) {
    String lastDisplay = 'No previous data';
    String lastSubtitle = 'Complete a workout to see history';

    if (widget.lastSessionData != null) {
      final weight = widget.lastSessionData!['weight'] as double?;
      final reps = widget.lastSessionData!['reps'] as int?;
      final date = widget.lastSessionData!['date'] as String?;
      if (weight != null && reps != null) {
        final displayWeight = widget.useKg ? weight : weight * 2.20462;
        lastDisplay = '${displayWeight.toStringAsFixed(0)} $_unit x $reps reps';
        if (date != null) {
          lastSubtitle = date;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.electricBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.history_rounded,
              color: AppColors.electricBlue,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last Session',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lastDisplay,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                Text(
                  lastSubtitle,
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

  /// Build chart card container
  Widget _buildChartCard({
    required String title,
    required IconData icon,
    required Color color,
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required Widget chart,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          chart,
        ],
      ),
    );
  }

  /// Build placeholder weight chart
  Widget _buildWeightChart(bool isDark, Color textMuted) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 40,
              color: AppColors.electricBlue.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Weight progression chart',
              style: TextStyle(
                fontSize: 13,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Complete more sessions to see trends',
              style: TextStyle(
                fontSize: 11,
                color: textMuted.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build placeholder volume chart
  Widget _buildVolumeChart(bool isDark, Color textMuted) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 40,
              color: AppColors.purple.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Volume (weight x reps) over time',
              style: TextStyle(
                fontSize: 13,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Complete more sessions to see trends',
              style: TextStyle(
                fontSize: 11,
                color: textMuted.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build set type distribution
  Widget _buildSetTypeDistribution(bool isDark, Color textPrimary, Color textMuted) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_outline_rounded, color: AppColors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                'Set Type Distribution',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSetTypeItem(
                  label: 'Working',
                  count: 0,
                  color: AppColors.electricBlue,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ),
              Expanded(
                child: _buildSetTypeItem(
                  label: 'Warmup',
                  count: 0,
                  color: AppColors.orange,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ),
              Expanded(
                child: _buildSetTypeItem(
                  label: 'Drop',
                  count: 0,
                  color: AppColors.purple,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ),
              Expanded(
                child: _buildSetTypeItem(
                  label: 'Failure',
                  count: 0,
                  color: AppColors.error,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSetTypeItem({
    required String label,
    required int count,
    required Color color,
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Build stats summary
  Widget _buildStatsSummary(bool isDark, Color textPrimary, Color textMuted) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, color: AppColors.cyan, size: 20),
              const SizedBox(width: 8),
              Text(
                'Quick Stats',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  label: 'Total Sessions',
                  value: '0',
                  color: AppColors.electricBlue,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  label: 'Total Sets',
                  value: '0',
                  color: AppColors.purple,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  label: 'Total Volume',
                  value: '0 $_unit',
                  color: AppColors.success,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textMuted,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
