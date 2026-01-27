import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/weekly_summary.dart';
import '../../data/repositories/weekly_summary_repository.dart';
import '../../data/services/api_client.dart';

class WeeklySummaryScreen extends ConsumerStatefulWidget {
  const WeeklySummaryScreen({super.key});

  @override
  ConsumerState<WeeklySummaryScreen> createState() =>
      _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends ConsumerState<WeeklySummaryScreen> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = await ref.read(apiClientProvider).getUserId();
    if (userId != null) {
      setState(() => _userId = userId);
      ref.read(weeklySummaryProvider.notifier).loadSummaries(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(weeklySummaryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimary,
        title: Text('Weekly Summaries', style: TextStyle(color: textPrimary)),
        actions: [
          if (!state.isGenerating)
            IconButton(
              icon: Icon(Icons.add, color: textPrimary),
              onPressed: _generateSummary,
              tooltip: 'Generate Summary',
            ),
        ],
      ),
      body: state.isLoading
          ? Center(
              child: CircularProgressIndicator(color: purple),
            )
          : state.summaries.isEmpty
              ? _EmptyState(onGenerate: _generateSummary, isDark: isDark)
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: purple,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.summaries.length,
                    itemBuilder: (context, index) {
                      final summary = state.summaries[index];
                      return _SummaryCard(summary: summary, isDark: isDark)
                          .animate()
                          .fadeIn(delay: (50 * index).ms)
                          .slideY(begin: 0.1, delay: (50 * index).ms);
                    },
                  ),
                ),
    );
  }

  Future<void> _generateSummary() async {
    if (_userId == null) return;

    final result = await ref
        .read(weeklySummaryProvider.notifier)
        .generateSummary(_userId!);

    if (mounted && result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Weekly summary generated!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// Summary Card
// ─────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final WeeklySummary summary;
  final bool isDark;

  const _SummaryCard({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return GestureDetector(
      onTap: () => _showDetailSheet(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              purple.withOpacity(0.15),
              cyan.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: purple.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: purple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatWeekRange(summary.weekStart, summary.weekEnd),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        '${summary.workoutsCompleted}/${summary.workoutsScheduled} workouts completed',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Completion badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _getCompletionColor(summary.completionRate, isDark)
                            .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${summary.completionRate.toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color:
                          _getCompletionColor(summary.completionRate, isDark),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Stats row
            Row(
              children: [
                _StatChip(
                  icon: Icons.fitness_center,
                  value: '${summary.totalExercises}',
                  label: 'exercises',
                  color: cyan,
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  icon: Icons.timer,
                  value: '${summary.totalTimeMinutes}',
                  label: 'minutes',
                  color: isDark ? AppColors.orange : AppColorsLight.orange,
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  icon: Icons.local_fire_department,
                  value: '${summary.caloriesBurnedEstimate}',
                  label: 'calories',
                  color: isDark ? AppColors.coral : AppColorsLight.coral,
                  isDark: isDark,
                ),
              ],
            ),

            // Streak and PRs
            if (summary.currentStreak > 0 || summary.prsAchieved > 0) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (summary.currentStreak > 0)
                    _StreakBadge(streak: summary.currentStreak, isDark: isDark),
                  if (summary.currentStreak > 0 && summary.prsAchieved > 0)
                    const SizedBox(width: 12),
                  if (summary.prsAchieved > 0)
                    _PRBadge(count: summary.prsAchieved, isDark: isDark),
                ],
              ),
            ],

            // AI Summary preview
            if (summary.aiSummary != null) ...[
              const SizedBox(height: 16),
              Text(
                summary.aiSummary!,
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // View more indicator
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Tap to view details',
                  style: TextStyle(
                    fontSize: 12,
                    color: textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: textMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.nearBlack : AppColorsLight.nearWhite,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: _SummaryDetailSheet(
            summary: summary,
            scrollController: scrollController,
            isDark: isDark,
          ),
        ),
      ),
    );
  }

  String _formatWeekRange(String start, String end) {
    final startDate = DateTime.parse(start);
    final endDate = DateTime.parse(end);
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    if (startDate.month == endDate.month) {
      return '${months[startDate.month - 1]} ${startDate.day} - ${endDate.day}';
    }
    return '${months[startDate.month - 1]} ${startDate.day} - ${months[endDate.month - 1]} ${endDate.day}';
  }

  Color _getCompletionColor(double rate, bool isDark) {
    if (rate >= 80) return isDark ? AppColors.success : AppColorsLight.success;
    if (rate >= 50) return isDark ? AppColors.warning : AppColorsLight.warning;
    return isDark ? AppColors.error : AppColorsLight.error;
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
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
        ),
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int streak;
  final bool isDark;

  const _StreakBadge({required this.streak, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            size: 16,
            color: orange,
          ),
          const SizedBox(width: 4),
          Text(
            '$streak day streak',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: orange,
            ),
          ),
        ],
      ),
    );
  }
}

class _PRBadge extends StatelessWidget {
  final int count;
  final bool isDark;

  const _PRBadge({required this.count, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final success = isDark ? AppColors.success : AppColorsLight.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: success.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.trending_up,
            size: 16,
            color: success,
          ),
          const SizedBox(width: 4),
          Text(
            '$count PRs',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: success,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Summary Detail Sheet
// ─────────────────────────────────────────────────────────────────

class _SummaryDetailSheet extends StatelessWidget {
  final WeeklySummary summary;
  final ScrollController scrollController;
  final bool isDark;

  const _SummaryDetailSheet({
    required this.summary,
    required this.scrollController,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;
    final success = isDark ? AppColors.success : AppColorsLight.success;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Column(
      children: [
        // Handle
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Week of ${_formatDate(summary.weekStart)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 24),

                // AI Summary
                if (summary.aiSummary != null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          cyan.withOpacity(0.1),
                          purple.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: cyan.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: cyan,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'AI Summary',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: cyan,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          summary.aiSummary!,
                          style: TextStyle(
                            fontSize: 15,
                            color: textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Highlights
                if (summary.aiHighlights != null &&
                    summary.aiHighlights!.isNotEmpty) ...[
                  _SectionTitle(title: 'Highlights', isDark: isDark),
                  const SizedBox(height: 12),
                  ...summary.aiHighlights!.map((highlight) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.star,
                            color: orange,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              highlight,
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                ],

                // Encouragement
                if (summary.aiEncouragement != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: success.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          color: success,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            summary.aiEncouragement!,
                            style: TextStyle(
                              fontSize: 14,
                              color: textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Tips for next week
                if (summary.aiNextWeekTips != null &&
                    summary.aiNextWeekTips!.isNotEmpty) ...[
                  _SectionTitle(title: 'Tips for Next Week', isDark: isDark),
                  const SizedBox(height: 12),
                  ...summary.aiNextWeekTips!.asMap().entries.map((entry) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: elevated,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: purple.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: purple,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionTitle({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onGenerate;
  final bool isDark;

  const _EmptyState({required this.onGenerate, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: purple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.summarize,
                size: 64,
                color: purple,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No summaries yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generate your first weekly summary to see your progress with AI-powered insights',
              style: TextStyle(
                fontSize: 14,
                color: textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onGenerate,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate Summary'),
              style: ElevatedButton.styleFrom(
                backgroundColor: purple,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
