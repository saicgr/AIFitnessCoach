import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/weekly_summary.dart';
import '../../widgets/pill_app_bar.dart';

/// Full detail screen for a past weekly summary report.
///
/// Receives a [WeeklySummary] via GoRouter's `extra` parameter and
/// renders the complete breakdown: completion, workout stats, and
/// AI-generated narrative with highlights, encouragement, and tips.
class InsightsDetailScreen extends StatelessWidget {
  final WeeklySummary summary;

  const InsightsDetailScreen({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PillAppBar(
        title: '${_formatWeekRange(summary.weekStart, summary.weekEnd)} Report',
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _CompletionHeader(summary: summary, isDark: isDark),
          const SizedBox(height: 16),
          _WorkoutCard(summary: summary, isDark: isDark),
          const SizedBox(height: 16),
          _AiNarrativeCard(summary: summary, isDark: isDark),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Formats the week range for the app bar title.
  /// Same month: "Mar 16 - 22"
  /// Cross month: "Mar 16 - Apr 2"
  String _formatWeekRange(String start, String end) {
    final startDate = DateTime.parse(start);
    final endDate = DateTime.parse(end);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    if (startDate.month == endDate.month) {
      return '${months[startDate.month - 1]} ${startDate.day} - ${endDate.day}';
    }
    return '${months[startDate.month - 1]} ${startDate.day} - ${months[endDate.month - 1]} ${endDate.day}';
  }
}

// ---------------------------------------------------------------------
// Completion Header — circular progress + percentage + date range
// ---------------------------------------------------------------------

class _CompletionHeader extends StatelessWidget {
  final WeeklySummary summary;
  final bool isDark;

  const _CompletionHeader({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final completionColor = _getCompletionColor(summary.completionRate);
    final rate = summary.completionRate;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            purple.withOpacity(0.12),
            completionColor.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: purple.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          // Circular progress indicator
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: rate / 100,
                    strokeWidth: 6,
                    backgroundColor: completionColor.withOpacity(0.15),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(completionColor),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '${rate.toInt()}%',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: completionColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Completion Rate',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatFullDateRange(
                      summary.weekStart, summary.weekEnd),
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${summary.workoutsCompleted} of ${summary.workoutsScheduled} workouts',
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCompletionColor(double rate) {
    if (rate >= 80) return isDark ? AppColors.success : AppColorsLight.success;
    if (rate >= 50) return isDark ? AppColors.warning : AppColorsLight.warning;
    return isDark ? AppColors.error : AppColorsLight.error;
  }

  String _formatFullDateRange(String start, String end) {
    final startDate = DateTime.parse(start);
    final endDate = DateTime.parse(end);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    if (startDate.month == endDate.month) {
      return '${months[startDate.month - 1]} ${startDate.day} - ${endDate.day}, ${startDate.year}';
    }
    return '${months[startDate.month - 1]} ${startDate.day} - ${months[endDate.month - 1]} ${endDate.day}, ${endDate.year}';
  }
}

// ---------------------------------------------------------------------
// Workout Card — stats, streak, PRs
// ---------------------------------------------------------------------

class _WorkoutCard extends StatelessWidget {
  final WeeklySummary summary;
  final bool isDark;

  const _WorkoutCard({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;
    final coral = isDark ? AppColors.coral : AppColorsLight.coral;
    final success = isDark ? AppColors.success : AppColorsLight.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cyan.withOpacity(0.15),
            purple.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cyan.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Row(
            children: [
              Icon(Icons.fitness_center, color: cyan, size: 20),
              const SizedBox(width: 8),
              Text(
                'Workout Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats row 1: workouts, exercises, sets
          Row(
            children: [
              _StatTile(
                icon: Icons.check_circle_outline,
                value: '${summary.workoutsCompleted}/${summary.workoutsScheduled}',
                label: 'workouts',
                color: purple,
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _StatTile(
                icon: Icons.fitness_center,
                value: '${summary.totalExercises}',
                label: 'exercises',
                color: cyan,
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _StatTile(
                icon: Icons.repeat,
                value: '${summary.totalSets}',
                label: 'sets',
                color: orange,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stats row 2: time, calories
          Row(
            children: [
              _StatTile(
                icon: Icons.timer,
                value: '${summary.totalTimeMinutes}',
                label: 'minutes',
                color: orange,
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _StatTile(
                icon: Icons.local_fire_department,
                value: '${summary.caloriesBurnedEstimate}',
                label: 'calories',
                color: coral,
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              // Empty spacer to keep the grid balanced
              const Expanded(child: SizedBox()),
            ],
          ),

          // Streak badge
          if (summary.currentStreak > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    '${summary.currentStreak} day streak',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: orange,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // PR badge + details
          if (summary.prsAchieved > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: success.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.trending_up, size: 16, color: success),
                  const SizedBox(width: 4),
                  Text(
                    '${summary.prsAchieved} PRs',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: success,
                    ),
                  ),
                ],
              ),
            ),

            // PR details list
            if (summary.prDetails != null &&
                summary.prDetails!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...summary.prDetails!.map((pr) {
                final exerciseName =
                    pr['exercise_name'] as String? ?? 'Unknown exercise';
                final detail =
                    pr['detail'] as String? ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.emoji_events,
                          size: 16, color: success.withOpacity(0.8)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          detail.isNotEmpty
                              ? '$exerciseName - $detail'
                              : exerciseName,
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Stat Tile — reusable icon + value + label column within a row
// ---------------------------------------------------------------------

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  const _StatTile({
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

// ---------------------------------------------------------------------
// AI Narrative Card — summary, highlights, encouragement, tips
// ---------------------------------------------------------------------

class _AiNarrativeCard extends StatelessWidget {
  final WeeklySummary summary;
  final bool isDark;

  const _AiNarrativeCard({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;
    final success = isDark ? AppColors.success : AppColorsLight.success;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final bool hasAiContent = summary.aiSummary != null ||
        (summary.aiHighlights != null && summary.aiHighlights!.isNotEmpty) ||
        summary.aiEncouragement != null ||
        (summary.aiNextWeekTips != null && summary.aiNextWeekTips!.isNotEmpty);

    // Show a fallback message when there is no AI content at all
    if (!hasAiContent) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? AppColors.cardBorder
                : AppColorsLight.cardBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.auto_awesome, color: textMuted, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No AI insights generated for this report',
                style: TextStyle(
                  fontSize: 14,
                  color: textMuted,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cyan.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: cyan, size: 20),
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
          const SizedBox(height: 16),
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
                  Icon(Icons.star, color: orange, size: 18),
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
          const SizedBox(height: 16),
        ],

        // Encouragement
        if (summary.aiEncouragement != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: success.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.favorite, color: success, size: 24),
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
          const SizedBox(height: 16),
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
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Section Title — reusable heading for card sections
// ---------------------------------------------------------------------

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
