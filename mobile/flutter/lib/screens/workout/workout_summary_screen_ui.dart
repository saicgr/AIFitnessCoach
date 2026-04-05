part of 'workout_summary_screen.dart';

/// UI builder methods extracted from _WorkoutSummaryScreenState
extension _WorkoutSummaryScreenStateUI on _WorkoutSummaryScreenState {

  // ═══════════════════════════════════════════════════════════════════
  // STATS GRID (2x2)
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildStatsGrid(
      Workout? workout, PerformanceComparisonInfo? comparison, bool isDark, Color accentColor) {
    final wc = comparison?.workoutComparison;
    final duration = wc != null
        ? _formatDuration(wc.currentDurationSeconds)
        : workout?.formattedDurationShort ?? '--';
    final exerciseCount = wc?.currentExercises ?? workout?.exerciseCount ?? 0;
    final volume = wc != null
        ? '${wc.currentTotalVolumeKg.toStringAsFixed(0)} kg'
        : '--';
    final calories = wc != null && wc.currentCalories > 0
        ? '${wc.currentCalories}'
        : workout?.estimatedCalories.toString() ?? '--';

    // Delta values
    String? durationDelta;
    bool? durationPositive;
    if (wc != null && wc.hasPrevious && wc.durationDiffPercent != null) {
      durationDelta = '${wc.durationDiffPercent! >= 0 ? '+' : ''}${wc.durationDiffPercent!.toStringAsFixed(0)}%';
      durationPositive = wc.durationDiffPercent! <= 0; // Less time is positive
    }

    String? volumeDelta;
    bool? volumePositive;
    if (wc != null && wc.hasPrevious && wc.volumeDiffPercent != null) {
      volumeDelta = '${wc.volumeDiffPercent! >= 0 ? '+' : ''}${wc.volumeDiffPercent!.toStringAsFixed(0)}%';
      volumePositive = wc.volumeDiffPercent! >= 0;
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatTile(
                'Duration', duration, isDark,
                delta: durationDelta,
                isPositive: durationPositive,
                icon: Icons.timer_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatTile(
                'Exercises', '$exerciseCount', isDark,
                icon: Icons.fitness_center,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatTile(
                'Volume', volume, isDark,
                delta: volumeDelta,
                isPositive: volumePositive,
                icon: Icons.monitor_weight_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatTile(
                'Calories', calories, isDark,
                icon: Icons.local_fire_department_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildStatTile(String label, String value, bool isDark, {
    String? delta,
    bool? isPositive,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: isDark ? AppColors.textMuted : Colors.grey.shade500),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textMuted : Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimary : Colors.black87,
                  ),
                ),
              ),
              if (delta != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isPositive == true ? AppColors.success : AppColors.error)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    delta,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isPositive == true ? AppColors.success : AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }


  // ═══════════════════════════════════════════════════════════════════
  // PLANNED EXERCISE CARD (for marked-done)
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildPlannedExerciseCard(WorkoutExercise exercise, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimary : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _exerciseSetDisplay(exercise),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textSecondary
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle_outline,
            size: 20,
            color: isDark ? AppColors.textMuted : Colors.grey.shade400,
          ),
        ],
      ),
    );
  }


  // ═══════════════════════════════════════════════════════════════════
  // PERFORMANCE SECTION
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildPerformanceSection(
      PerformanceComparisonInfo comparison, bool isDark, Color accentColor) {
    final wc = comparison.workoutComparison;
    final statusLabel = _overallStatusLabel(wc.overallStatus);
    final statusColor = _statusColor(wc.overallStatus, isDark);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSectionTitle('Performance', isDark),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (wc.hasPrevious) ...[
            Row(
              children: [
                Expanded(
                  child: _buildChangeRow(
                    'Volume',
                    wc.formattedVolumeDiff,
                    wc.volumeDiffPercent,
                    isDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildChangeRow(
                    'Duration',
                    wc.formattedDurationDiff,
                    wc.durationDiffPercent,
                    isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (comparison.improvedCount > 0)
                  _buildCountChip(
                      '${comparison.improvedCount} improved',
                      AppColors.success,
                      isDark),
                if (comparison.maintainedCount > 0)
                  _buildCountChip(
                      '${comparison.maintainedCount} same',
                      isDark ? AppColors.textMuted : Colors.grey,
                      isDark),
                if (comparison.declinedCount > 0)
                  _buildCountChip(
                      '${comparison.declinedCount} declined',
                      AppColors.error,
                      isDark),
                if (comparison.firstTimeCount > 0)
                  _buildCountChip(
                      '${comparison.firstTimeCount} new',
                      AppColors.info,
                      isDark),
              ],
            ),
          ] else
            Text(
              'First time performing this workout type!',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSecondary : Colors.grey.shade600,
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildPRCard(
      PersonalRecordInfo pr, bool isDark, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.warning.withValues(alpha: 0.06)
            : AppColors.warning.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pr.exerciseName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimary : Colors.black87,
                  ),
                ),
              ),
              if (pr.isAllTimePr)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'ALL-TIME',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${pr.weightKg.toStringAsFixed(1)} kg x ${pr.reps} reps  |  Est. 1RM: ${pr.estimated1rmKg.toStringAsFixed(1)} kg',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textSecondary : Colors.grey.shade600,
            ),
          ),
          if (pr.improvementPercent != null && pr.improvementPercent! > 0) ...[
            const SizedBox(height: 2),
            Text(
              '+${pr.improvementPercent!.toStringAsFixed(1)}% improvement',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.success,
              ),
            ),
          ],
          if (pr.celebrationMessage != null &&
              pr.celebrationMessage!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              pr.celebrationMessage!,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: isDark ? AppColors.textMuted : Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildStructuredCoachReview(
      CoachReview review, bool isDark, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with rating
          Row(
            children: [
              Icon(Icons.smart_toy_outlined,
                  size: 18,
                  color: isDark ? AppColors.textSecondary : Colors.grey.shade600),
              const SizedBox(width: 6),
              _buildSectionTitle('AI Coach Review', isDark),
              const Spacer(),
              // Rating badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _ratingColor(review.overallRating).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 14,
                        color: _ratingColor(review.overallRating)),
                    const SizedBox(width: 3),
                    Text(
                      '${review.overallRating}/10',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _ratingColor(review.overallRating),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Highlights
          if (review.highlights.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.thumb_up_outlined, size: 14, color: AppColors.success),
                const SizedBox(width: 6),
                Text(
                  'Highlights',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...review.highlights.map((h) => Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('  \u2022  ', style: TextStyle(color: isDark ? AppColors.textSecondary : Colors.grey.shade600)),
                  Expanded(
                    child: Text(
                      h,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: isDark ? AppColors.textSecondary : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 10),
          ],

          // Areas to improve
          if (review.areasToImprove.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.flag_outlined, size: 14, color: AppColors.warning),
                const SizedBox(width: 6),
                Text(
                  'Areas to Watch',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...review.areasToImprove.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('  \u2022  ', style: TextStyle(color: isDark ? AppColors.textSecondary : Colors.grey.shade600)),
                  Expanded(
                    child: Text(
                      a,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: isDark ? AppColors.textSecondary : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 10),
          ],

          // Overall summary
          if (review.summary.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                review.summary,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: isDark ? AppColors.textSecondary : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

}
