import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/models/workout.dart';
import '../../data/models/exercise.dart';
import '../../data/providers/today_workout_provider.dart';
import '../../data/repositories/workout_repository.dart';
import '../../widgets/pill_app_bar.dart';
import '../../widgets/glass_sheet.dart';
import 'widgets/expandable_summary_exercise_card.dart';
import 'widgets/exercise_mini_chart.dart';
import 'widgets/edit_set_sheet.dart';
import 'widgets/exercise_add_sheet.dart';
import 'widgets/share_workout_sheet.dart';

part 'workout_summary_screen_ui.dart';


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
  final Set<int> _expandedExercises = {};

  @override
  void initState() {
    super.initState();
    _summaryFuture = _fetchSummary();

    ref.read(posthogServiceProvider).capture(
      eventName: 'workout_summary_viewed',
      properties: {'workout_id': widget.workoutId},
    );
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
      appBar: const PillAppBar(title: 'Workout Summary'),
      floatingActionButton: FutureBuilder<WorkoutSummaryResponse?>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.data == null || snapshot.data!.isMarkedDone) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: _handleAddExercise,
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Add Exercise'),
          );
        },
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
          // 2x2 grid shimmer
          Row(
            children: [
              Expanded(child: shimmerBox(double.infinity, 72, radius: 12)),
              const SizedBox(width: 8),
              Expanded(child: shimmerBox(double.infinity, 72, radius: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: shimmerBox(double.infinity, 72, radius: 12)),
              const SizedBox(width: 8),
              Expanded(child: shimmerBox(double.infinity, 72, radius: 12)),
            ],
          ),
          const SizedBox(height: 24),
          for (int i = 0; i < 4; i++) ...[
            shimmerBox(double.infinity, 72, radius: 12),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 16),
          shimmerBox(double.infinity, 120, radius: 12),
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
    final setLogsByExercise = summary.setLogsByExercise;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      children: [
        // Header
        _buildHeader(workout, summary, isDark, accentColor, isTracked: true),
        const SizedBox(height: 16),

        // Stats grid (2x2)
        _buildStatsGrid(workout, comparison, isDark, accentColor),
        const SizedBox(height: 16),

        // Total weight lifted banner
        if (comparison?.workoutComparison != null &&
            comparison!.workoutComparison.currentTotalVolumeKg > 0)
          _buildVolumeBanner(comparison.workoutComparison, isDark, accentColor),

        const SizedBox(height: 20),

        // Exercises list with expandable cards
        if (exercises.isNotEmpty) ...[
          Row(
            children: [
              _buildSectionTitle('Exercises', isDark),
              const Spacer(),
              if (_expandedExercises.isEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      for (int i = 0; i < exercises.length; i++) {
                        _expandedExercises.add(i);
                      }
                    });
                  },
                  icon: Icon(Icons.unfold_more, size: 16, color: isDark ? AppColors.textMuted : Colors.grey),
                  label: Text('Expand All', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMuted : Colors.grey)),
                )
              else
                TextButton.icon(
                  onPressed: () => setState(() => _expandedExercises.clear()),
                  icon: Icon(Icons.unfold_less, size: 16, color: isDark ? AppColors.textMuted : Colors.grey),
                  label: Text('Collapse All', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMuted : Colors.grey)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...exercises.asMap().entries.map((entry) {
            final index = entry.key;
            final exercise = entry.value;
            final comparisonMatch = comparison?.exerciseComparisons
                .where((c) =>
                    c.exerciseName.toLowerCase() ==
                    exercise.name.toLowerCase())
                .firstOrNull;
            final exerciseSets =
                setLogsByExercise[exercise.name] ?? [];

            return ExpandableSummaryExerciseCard(
              exercise: exercise,
              comparison: comparisonMatch,
              setLogs: exerciseSets,
              isDark: isDark,
              accentColor: accentColor,
              isExpanded: _expandedExercises.contains(index),
              onToggle: () {
                setState(() {
                  if (_expandedExercises.contains(index)) {
                    _expandedExercises.remove(index);
                  } else {
                    _expandedExercises.add(index);
                  }
                });
              },
              onEdit: () => _handleEditExercise(index, exercise, exerciseSets, isDark, accentColor),
              miniChart: exerciseSets.isNotEmpty
                  ? ExerciseMiniChart(
                      weights: exerciseSets
                          .map((s) => s.weightKg)
                          .where((w) => w > 0)
                          .toList(),
                      isDark: isDark,
                      accentColor: accentColor,
                      onTap: () {
                        context.push('/exercise-progress-detail', extra: {
                          'exercise_name': exercise.name,
                        });
                      },
                    )
                  : null,
            );
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

        // Coach summary - try structured first, fallback to raw text
        if (summary.coachSummary != null &&
            summary.coachSummary!.isNotEmpty) ...[
          _buildCoachReviewSection(summary, isDark, accentColor),
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
        _buildHeader(workout, summary, isDark, accentColor, isTracked: false),
        const SizedBox(height: 12),
        if (summary.completedAt != null)
          _buildTimestampNotice(summary.completedAt!, isDark),
        const SizedBox(height: 16),
        if (exercises.isNotEmpty) ...[
          _buildSectionTitle('Planned Exercises', isDark),
          const SizedBox(height: 8),
          ...exercises.map((e) => _buildPlannedExerciseCard(e, isDark)),
          const SizedBox(height: 16),
        ],
        _buildShareButton(workout, isDark, accentColor),
        const SizedBox(height: 12),
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
        Text(
          workout?.name ?? 'Workout',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimary : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
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
  // TOTAL VOLUME BANNER
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildVolumeBanner(WorkoutComparisonInfo wc, bool isDark, Color accentColor) {
    final volume = wc.currentTotalVolumeKg;
    final comparison = _getVolumeComparison(volume);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.15),
            accentColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.fitness_center, size: 24, color: accentColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total: ${volume.toStringAsFixed(0)} kg lifted',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimary : Colors.black87,
                  ),
                ),
                if (comparison.isNotEmpty)
                  Text(
                    comparison,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondary : Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getVolumeComparison(double volumeKg) {
    if (volumeKg >= 20000) return 'That\'s like lifting a truck axle!';
    if (volumeKg >= 10000) return 'Equivalent to a grand piano!';
    if (volumeKg >= 5000) return 'That\'s like lifting a small car!';
    if (volumeKg >= 2000) return 'More than a motorcycle!';
    if (volumeKg >= 1000) return 'That\'s a concert grand!';
    if (volumeKg >= 500) return 'More than a washing machine!';
    return '';
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

  // ═══════════════════════════════════════════════════════════════════
  // COACH REVIEW SECTION (Rich structured + fallback)
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildCoachReviewSection(
      WorkoutSummaryResponse summary, bool isDark, Color accentColor) {
    final structured = summary.parsedCoachReview;

    if (structured != null) {
      return _buildStructuredCoachReview(structured, isDark, accentColor);
    }

    // Fallback to raw text
    return _buildRawCoachReview(summary.coachSummary!, isDark, accentColor);
  }

  Widget _buildRawCoachReview(String summary, bool isDark, Color accentColor) {
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

  Color _ratingColor(int rating) {
    if (rating >= 8) return AppColors.success;
    if (rating >= 6) return AppColors.warning;
    return AppColors.error;
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
                showGlassSheet(
                  context: context,
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

  // ═══════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _handleRevert() async {
    setState(() => _isReverting = true);
    try {
      final repo = ref.read(workoutRepositoryProvider);
      final success = await repo.uncompleteWorkout(widget.workoutId);
      if (success && mounted) {
        ref.read(todayWorkoutProvider.notifier).invalidateAndRefresh();
        ref.read(workoutsProvider.notifier).silentRefresh();
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

  void _handleEditExercise(
    int exerciseIndex,
    WorkoutExercise exercise,
    List<SetLogInfo> currentSets,
    bool isDark,
    Color accentColor,
  ) {
    EditSetSheet.show(
      context,
      exerciseName: exercise.name,
      initialSets: currentSets,
      isDark: isDark,
      accentColor: accentColor,
      onSave: (updatedSets) async {
        try {
          final repo = ref.read(workoutRepositoryProvider);
          await repo.updateExerciseSets(
            widget.workoutId,
            exerciseIndex,
            updatedSets,
          );
          _retry();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sets updated successfully')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to save: $e')),
            );
          }
        }
      },
    );
  }

  void _handleAddExercise() async {
    // Get current workout data for context
    final summaryData = await _summaryFuture;
    final workout = summaryData != null ? _parseWorkout(summaryData.workout) : null;
    final exercises = workout?.exercises ?? [];

    if (!mounted) return;

    final result = await showExerciseAddSheet(
      context,
      ref,
      workoutId: widget.workoutId,
      workoutType: workout?.type ?? 'strength',
      currentExerciseNames: exercises.map((e) => e.name).toList(),
    );
    if (result != null) {
      _retry();
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

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.textPrimary : Colors.black87,
      ),
    );
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
