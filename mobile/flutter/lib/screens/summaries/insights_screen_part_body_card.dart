part of 'insights_screen.dart';


// ---------------------------------------------------------------------------
// Body Card — weight and body fat changes
// ---------------------------------------------------------------------------

class _BodyCard extends StatelessWidget {
  final InsightsTotals totals;
  final bool isDark;

  const _BodyCard({
    required this.totals,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final coral = isDark ? AppColors.coral : AppColorsLight.coral;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final hasWeight = totals.weightChangeKg != null;
    final hasBodyFat = totals.bodyFatChange != null;

    if (!hasWeight && !hasBodyFat) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              coral.withOpacity(0.15),
              coral.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: coral.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: coral.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.monitor_weight_outlined,
                      color: coral, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Body',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Log your measurements to track body composition changes',
              style: TextStyle(fontSize: 14, color: textMuted),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            coral.withOpacity(0.15),
            coral.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: coral.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: coral.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.monitor_weight_outlined,
                    color: coral, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Body',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              if (hasWeight)
                Expanded(
                  child: _BodyMetric(
                    label: 'Weight',
                    value: totals.weightChangeKg!,
                    unit: 'kg',
                    isDark: isDark,
                  ),
                ),
              if (hasWeight && hasBodyFat) const SizedBox(width: 16),
              if (hasBodyFat)
                Expanded(
                  child: _BodyMetric(
                    label: 'Body Fat',
                    value: totals.bodyFatChange!,
                    unit: '%',
                    isDark: isDark,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}


class _BodyMetric extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final bool isDark;

  const _BodyMetric({
    required this.label,
    required this.value,
    required this.unit,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    // For body metrics, a decrease is typically desirable (losing weight/fat),
    // but this is context-dependent. Show neutral colors and let the user interpret.
    final isPositive = value > 0;
    final success = isDark ? AppColors.success : AppColorsLight.success;
    final coral = isDark ? AppColors.coral : AppColorsLight.coral;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 18,
                color: isPositive ? coral : success,
              ),
              const SizedBox(width: 4),
              Text(
                '${value.abs().toStringAsFixed(1)} $unit',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// AI Narrative Section
// ---------------------------------------------------------------------------

class _AiNarrativeSection extends StatelessWidget {
  final InsightsAiNarrative? narrative;
  final bool isGenerating;
  final bool hasReport;
  final bool isDark;
  final VoidCallback onGenerate;

  const _AiNarrativeSection({
    this.narrative,
    required this.isGenerating,
    required this.hasReport,
    required this.isDark,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;
    final success = isDark ? AppColors.success : AppColorsLight.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cyan.withOpacity(0.15),
            cyan.withOpacity(0.05),
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
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.auto_awesome, color: cyan, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'AI Analysis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (isGenerating)
            // Shimmer loading state
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(4, (i) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  height: 14,
                  width: i == 3 ? 180 : double.infinity,
                  decoration: BoxDecoration(
                    color: elevated,
                    borderRadius: BorderRadius.circular(7),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(
                      duration: 1200.ms,
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.04),
                    );
              }),
            )
          else if (narrative != null) ...[
            // Summary
            Text(
              narrative!.summary,
              style: TextStyle(
                fontSize: 15,
                color: textPrimary,
                height: 1.5,
              ),
            ),

            // Highlights
            if (narrative!.highlights.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...narrative!.highlights.map((highlight) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.star_rounded, color: orange, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          highlight,
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            // Encouragement
            if (narrative!.encouragement.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: success.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.favorite_rounded, color: success, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        narrative!.encouragement,
                        style: TextStyle(
                          fontSize: 14,
                          color: textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Tips
            if (narrative!.tips.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Tips',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ...narrative!.tips.asMap().entries.map((entry) {
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
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ] else ...[
            // Generate button
            Text(
              hasReport
                  ? 'Get personalized AI analysis of your training data for this period.'
                  : 'Load your report data first, then generate AI insights.',
              style: TextStyle(fontSize: 14, color: textMuted),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: hasReport ? onGenerate : null,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Generate AI Insight'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cyan,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: elevated,
                  disabledForegroundColor: textMuted,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// Section Header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// Past Report Card — compact card for weekly summary history
// ---------------------------------------------------------------------------

class _PastReportCard extends StatelessWidget {
  final WeeklySummary summary;
  final bool isDark;
  final VoidCallback onTap;

  const _PastReportCard({
    required this.summary,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
          ),
        ),
        child: Row(
          children: [
            // Date icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: purple.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _monthAbbr(summary.weekStart),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: purple,
                    ),
                  ),
                  Text(
                    _dayNumber(summary.weekStart),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: purple,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatWeekRange(summary.weekStart, summary.weekEnd),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${summary.workoutsCompleted}/${summary.workoutsScheduled} workouts  |  ${summary.totalTimeMinutes}min  |  ${summary.caloriesBurnedEstimate} kcal',
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Completion badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _completionColor(summary.completionRate)
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${summary.completionRate.toInt()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _completionColor(summary.completionRate),
                ),
              ),
            ),

            const SizedBox(width: 2),
            // Inline share — tap fires ShareWeeklySummarySheet without
            // navigating into the detail screen. The IconButton consumes the
            // gesture so the outer GestureDetector's row-tap (navigate) only
            // fires when the user taps anywhere else on the card.
            IconButton(
              icon: Icon(
                Icons.ios_share_rounded,
                size: 18,
                color: textMuted,
              ),
              tooltip: 'Share this report',
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              visualDensity: VisualDensity.compact,
              onPressed: () =>
                  ShareWeeklySummarySheet.show(context, summary),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Color _completionColor(double rate) {
    if (rate >= 80) return isDark ? AppColors.success : AppColorsLight.success;
    if (rate >= 50) return isDark ? AppColors.warning : AppColorsLight.warning;
    return isDark ? AppColors.error : AppColorsLight.error;
  }

  String _monthAbbr(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[date.month - 1];
  }

  String _dayNumber(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    return '${date.day}';
  }

  String _formatWeekRange(String start, String end) {
    final startDate = DateTime.tryParse(start);
    final endDate = DateTime.tryParse(end);
    if (startDate == null || endDate == null) return '$start - $end';

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


// ---------------------------------------------------------------------------
// Empty Past Reports
// ---------------------------------------------------------------------------

class _EmptyPastReports extends StatelessWidget {
  final bool isDark;

  const _EmptyPastReports({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history_outlined,
            size: 40,
            color: textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'No past reports yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color:
                  isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Weekly reports will appear here as they are generated.',
            style: TextStyle(fontSize: 13, color: textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

