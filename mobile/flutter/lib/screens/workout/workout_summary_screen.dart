import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/models/workout.dart';
import '../../data/models/exercise.dart';
import '../../data/providers/today_workout_provider.dart';
import '../../data/repositories/workout_repository.dart';
import '../../widgets/glass_back_button.dart';
import 'widgets/share_workout_sheet.dart';

class WorkoutSummaryScreen extends ConsumerStatefulWidget {
  final String workoutId;

  const WorkoutSummaryScreen({super.key, required this.workoutId});

  @override
  ConsumerState<WorkoutSummaryScreen> createState() =>
      _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends ConsumerState<WorkoutSummaryScreen> {
  late Future<WorkoutSummaryResponse?> _summaryFuture;
  bool _isReverting = false;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _fetchSummary();
  }

  Future<WorkoutSummaryResponse?> _fetchSummary() {
    final repo = ref.read(workoutRepositoryProvider);
    return repo.getWorkoutCompletionSummary(widget.workoutId);
  }

  void _retry() {
    setState(() {
      _summaryFuture = _fetchSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = ref.watch(accentColorProvider);
    final accentColor = accent.getColor(isDark);

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const GlassBackButton(),
        title: Text(
          'Workout Summary',
          style: TextStyle(
            color: isDark ? AppColors.textPrimary : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<WorkoutSummaryResponse?>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingShimmer(isDark);
          }

          if (snapshot.hasError || snapshot.data == null) {
            return _buildErrorState(isDark, snapshot.error);
          }

          final summary = snapshot.data!;
          if (summary.isMarkedDone) {
            return _buildMarkedDoneBody(summary, isDark, accentColor);
          }
          return _buildTrackedBody(summary, isDark, accentColor);
        },
      ),
    );
  }

  // ── Loading shimmer ──────────────────────────────────────────────

  Widget _buildLoadingShimmer(bool isDark) {
    final shimmerBase =
        isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200;

    Widget shimmerBox(double width, double height, {double radius = 8}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: shimmerBase,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          shimmerBox(200, 28, radius: 6),
          const SizedBox(height: 8),
          shimmerBox(140, 16, radius: 4),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: shimmerBox(double.infinity, 60, radius: 12)),
              const SizedBox(width: 12),
              Expanded(child: shimmerBox(double.infinity, 60, radius: 12)),
              const SizedBox(width: 12),
              Expanded(child: shimmerBox(double.infinity, 60, radius: 12)),
            ],
          ),
          const SizedBox(height: 24),
          for (int i = 0; i < 4; i++) ...[
            shimmerBox(double.infinity, 72, radius: 12),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 16),
          shimmerBox(double.infinity, 100, radius: 12),
        ],
      ),
    );
  }

  // ── Error state ──────────────────────────────────────────────────

  Widget _buildErrorState(bool isDark, Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 48,
                color: isDark ? AppColors.textMuted : Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Failed to load summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimary : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondary : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor:
                    isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade200,
                foregroundColor: isDark ? AppColors.textPrimary : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TRACKED WORKOUT BODY
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildTrackedBody(
      WorkoutSummaryResponse summary, bool isDark, Color accentColor) {
    final workout = _parseWorkout(summary.workout);
    final exercises = workout?.exercises ?? [];
    final comparison = summary.performanceComparison;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        // Header
        _buildHeader(workout, summary, isDark, accentColor, isTracked: true),
        const SizedBox(height: 16),

        // Stats row
        _buildStatsRow(workout, comparison, isDark),
        const SizedBox(height: 24),

        // Exercises list with comparison
        if (exercises.isNotEmpty) ...[
          _buildSectionTitle('Exercises', isDark),
          const SizedBox(height: 8),
          ...exercises.asMap().entries.map((entry) {
            final exercise = entry.value;
            final comparisonMatch = comparison?.exerciseComparisons
                .where((c) =>
                    c.exerciseName.toLowerCase() ==
                    exercise.name.toLowerCase())
                .firstOrNull;
            return _buildTrackedExerciseCard(
                exercise, comparisonMatch, isDark, accentColor);
          }),
          const SizedBox(height: 16),
        ],

        // Performance comparison section
        if (comparison != null) ...[
          _buildPerformanceSection(comparison, isDark, accentColor),
          const SizedBox(height: 16),
        ],

        // Personal records
        if (summary.hasPRs) ...[
          _buildPRsSection(summary.personalRecords, isDark, accentColor),
          const SizedBox(height: 16),
        ],

        // Coach summary
        if (summary.coachSummary != null &&
            summary.coachSummary!.isNotEmpty) ...[
          _buildCoachSummarySection(summary.coachSummary!, isDark, accentColor),
          const SizedBox(height: 16),
        ],

        // Share button
        _buildShareButton(workout, isDark, accentColor),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // MARKED-DONE WORKOUT BODY
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildMarkedDoneBody(
      WorkoutSummaryResponse summary, bool isDark, Color accentColor) {
    final workout = _parseWorkout(summary.workout);
    final exercises = workout?.exercises ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        // Header with marked-done badge
        _buildHeader(workout, summary, isDark, accentColor, isTracked: false),
        const SizedBox(height: 12),

        // Timestamp notice
        if (summary.completedAt != null)
          _buildTimestampNotice(summary.completedAt!, isDark),
        const SizedBox(height: 16),

        // Planned exercises only
        if (exercises.isNotEmpty) ...[
          _buildSectionTitle('Planned Exercises', isDark),
          const SizedBox(height: 8),
          ...exercises.map((e) => _buildPlannedExerciseCard(e, isDark)),
          const SizedBox(height: 16),
        ],

        // Share button
        _buildShareButton(workout, isDark, accentColor),
        const SizedBox(height: 12),

        // Revert button
        _buildRevertButton(isDark),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildHeader(Workout? workout, WorkoutSummaryResponse summary,
      bool isDark, Color accentColor,
      {required bool isTracked}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Workout name
        Text(
          workout?.name ?? 'Workout',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimary : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        // Date + badge
        Row(
          children: [
            if (workout?.formattedDate != null)
              Text(
                workout!.formattedDate,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      isDark ? AppColors.textSecondary : Colors.grey.shade600,
                ),
              ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isTracked
                    ? accentColor.withValues(alpha: 0.15)
                    : AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isTracked ? 'Tracked' : 'Manually Marked Done',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isTracked ? accentColor : AppColors.warning,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // STATS ROW
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildStatsRow(
      Workout? workout, PerformanceComparisonInfo? comparison, bool isDark) {
    final wc = comparison?.workoutComparison;
    final duration = wc != null
        ? _formatDuration(wc.currentDurationSeconds)
        : workout?.formattedDurationShort ?? '--';
    final exerciseCount = wc?.currentExercises ?? workout?.exerciseCount ?? 0;
    final volume = wc != null
        ? '${wc.currentTotalVolumeKg.toStringAsFixed(0)} kg'
        : '--';

    return Row(
      children: [
        Expanded(child: _buildStatTile('Duration', duration, isDark)),
        const SizedBox(width: 8),
        Expanded(
            child:
                _buildStatTile('Exercises', '$exerciseCount', isDark)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatTile('Volume', volume, isDark)),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimary : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.textMuted : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SECTION TITLE
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textPrimary : Colors.black87,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TRACKED EXERCISE CARD (with comparison)
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildTrackedExerciseCard(WorkoutExercise exercise,
      ExerciseComparisonInfo? comparison, bool isDark, Color accentColor) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise name + comparison badge
          Row(
            children: [
              Expanded(
                child: Text(
                  exercise.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimary : Colors.black87,
                  ),
                ),
              ),
              if (comparison != null && comparison.hasPrevious)
                _buildComparisonBadge(comparison, isDark, accentColor),
            ],
          ),
          const SizedBox(height: 6),
          // Sets x reps @ weight
          Text(
            _exerciseSetDisplay(exercise),
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondary : Colors.grey.shade600,
            ),
          ),
          // Comparison detail
          if (comparison != null && comparison.hasPrevious) ...[
            const SizedBox(height: 6),
            Text(
              _comparisonDetailText(comparison),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textMuted : Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComparisonBadge(
      ExerciseComparisonInfo comparison, bool isDark, Color accentColor) {
    Color badgeColor;
    IconData icon;
    String label;

    if (comparison.isImproved) {
      badgeColor = AppColors.success;
      icon = Icons.trending_up;
      label = comparison.formattedPercentDiff.isNotEmpty
          ? comparison.formattedPercentDiff
          : 'Improved';
    } else if (comparison.isDeclined) {
      badgeColor = AppColors.error;
      icon = Icons.trending_down;
      label = comparison.formattedPercentDiff.isNotEmpty
          ? comparison.formattedPercentDiff
          : 'Declined';
    } else {
      badgeColor = isDark ? AppColors.textMuted : Colors.grey.shade500;
      icon = Icons.trending_flat;
      label = 'Same';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: badgeColor),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  String _comparisonDetailText(ExerciseComparisonInfo comparison) {
    final parts = <String>[];
    if (comparison.weightDiffKg != null && comparison.weightDiffKg != 0) {
      parts.add(
          'Weight: ${comparison.previousMaxWeightKg?.toStringAsFixed(1) ?? "?"} -> ${comparison.currentMaxWeightKg?.toStringAsFixed(1) ?? "?"} kg');
    }
    if (comparison.volumeDiffKg != null && comparison.volumeDiffKg != 0) {
      final sign = comparison.volumeDiffKg! >= 0 ? '+' : '';
      parts.add(
          'Volume: $sign${comparison.volumeDiffKg!.toStringAsFixed(0)} kg');
    }
    if (comparison.repsDiff != null && comparison.repsDiff != 0) {
      final sign = comparison.repsDiff! >= 0 ? '+' : '';
      parts.add('Reps: $sign${comparison.repsDiff}');
    }
    return parts.isEmpty ? 'No change from last session' : parts.join(' | ');
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
          // Volume and duration changes
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
            // Exercise breakdown
            Row(
              children: [
                _buildCountChip(
                    '${comparison.improvedCount} improved',
                    AppColors.success,
                    isDark),
                const SizedBox(width: 6),
                _buildCountChip(
                    '${comparison.maintainedCount} same',
                    isDark ? AppColors.textMuted : Colors.grey,
                    isDark),
                const SizedBox(width: 6),
                if (comparison.declinedCount > 0)
                  _buildCountChip(
                      '${comparison.declinedCount} declined',
                      AppColors.error,
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

  Widget _buildChangeRow(
      String label, String diff, double? percent, bool isDark) {
    if (diff.isEmpty) return const SizedBox.shrink();
    final isPositive = percent != null && percent >= 0;
    final color = percent == null
        ? (isDark ? AppColors.textSecondary : Colors.grey.shade600)
        : isPositive
            ? AppColors.success
            : AppColors.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.textMuted : Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          diff,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCountChip(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // PERSONAL RECORDS SECTION
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildPRsSection(
      List<PersonalRecordInfo> prs, bool isDark, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, size: 20, color: AppColors.warning),
              const SizedBox(width: 6),
              _buildSectionTitle('Personal Records', isDark),
            ],
          ),
          const SizedBox(height: 12),
          ...prs.map((pr) => _buildPRCard(pr, isDark, accentColor)),
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

  // ═══════════════════════════════════════════════════════════════════
  // COACH SUMMARY SECTION
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildCoachSummarySection(
      String summary, bool isDark, Color accentColor) {
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
              Icon(Icons.smart_toy_outlined,
                  size: 18,
                  color:
                      isDark ? AppColors.textSecondary : Colors.grey.shade600),
              const SizedBox(width: 6),
              _buildSectionTitle('Coach Review', isDark),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            summary,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? AppColors.textSecondary : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TIMESTAMP NOTICE (marked-done)
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildTimestampNotice(String completedAt, bool isDark) {
    final dateTime = DateTime.tryParse(completedAt);
    final formatted = dateTime != null
        ? '${dateTime.toLocal().month}/${dateTime.toLocal().day}/${dateTime.toLocal().year} at ${dateTime.toLocal().hour.toString().padLeft(2, '0')}:${dateTime.toLocal().minute.toString().padLeft(2, '0')}'
        : completedAt;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Manually marked as done at $formatted',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSecondary : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SHARE BUTTON
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildShareButton(
      Workout? workout, bool isDark, Color accentColor) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: workout != null
            ? () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => ShareWorkoutSheet(
                    workoutName: workout.name ?? 'Workout',
                    workoutLogId: workout.id ?? '',
                    durationSeconds: (workout.durationMinutes ?? 0) * 60,
                    calories: workout.estimatedCalories,
                    exercisesCount: workout.exerciseCount,
                  ),
                );
              }
            : null,
        icon: const Icon(Icons.share, size: 18),
        label: const Text('Share Workout'),
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? AppColors.textPrimary : Colors.black87,
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.grey.shade300,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // REVERT BUTTON
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildRevertButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _isReverting ? null : _handleRevert,
        icon: _isReverting
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDark ? Colors.black : Colors.white,
                ),
              )
            : const Icon(Icons.undo, size: 18),
        label: Text(_isReverting
            ? 'Reverting...'
            : 'Revert - Mark as Not Done'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.error.withValues(alpha: 0.9),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Future<void> _handleRevert() async {
    setState(() => _isReverting = true);
    try {
      final repo = ref.read(workoutRepositoryProvider);
      final success = await repo.uncompleteWorkout(widget.workoutId);
      if (success && mounted) {
        TodayWorkoutNotifier.clearCache();
        ref.invalidate(todayWorkoutProvider);
        ref.invalidate(workoutsProvider);
        if (mounted) context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to revert workout')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isReverting = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════

  Workout? _parseWorkout(Map<String, dynamic> workoutMap) {
    try {
      return Workout.fromJson(workoutMap);
    } catch (e) {
      debugPrint('Warning: Could not parse workout from summary: $e');
      return null;
    }
  }

  String _exerciseSetDisplay(WorkoutExercise exercise) {
    final parts = <String>[];
    if (exercise.sets != null) parts.add('${exercise.sets} sets');
    if (exercise.reps != null) parts.add('${exercise.reps} reps');
    if (exercise.weight != null && exercise.weight! > 0) {
      parts.add('@ ${exercise.weight!.toStringAsFixed(1)} kg');
    }
    if (exercise.durationSeconds != null) {
      parts.add('${exercise.durationSeconds}s');
    }
    return parts.isEmpty ? 'N/A' : parts.join(' x ');
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '--';
    final mins = seconds ~/ 60;
    if (mins < 60) return '${mins}m';
    final hrs = mins ~/ 60;
    final remainMins = mins % 60;
    return '${hrs}h ${remainMins}m';
  }

  String _overallStatusLabel(String status) {
    switch (status) {
      case 'improved':
        return 'Improved';
      case 'maintained':
        return 'Maintained';
      case 'declined':
        return 'Declined';
      case 'first_time':
        return 'First Time';
      default:
        return status;
    }
  }

  Color _statusColor(String status, bool isDark) {
    switch (status) {
      case 'improved':
        return AppColors.success;
      case 'maintained':
        return isDark ? AppColors.textSecondary : Colors.grey;
      case 'declined':
        return AppColors.error;
      case 'first_time':
        return AppColors.info;
      default:
        return isDark ? AppColors.textSecondary : Colors.grey;
    }
  }
}
