import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../data/models/consistency.dart';
import '../data/models/workout_day_detail.dart';
import '../data/providers/consistency_provider.dart';
import '../data/services/api_client.dart';

/// Bottom sheet showing detailed workout information for a specific day
class WorkoutDayDetailSheet extends ConsumerWidget {
  final String date;

  const WorkoutDayDetailSheet({
    super.key,
    required this.date,
  });

  /// Show the bottom sheet
  static Future<void> show(BuildContext context, String date) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WorkoutDayDetailSheet(date: date),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiClient = ref.watch(apiClientProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.6),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
              ),
              child: FutureBuilder<String?>(
            future: apiClient.getUserId(),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData || userSnapshot.data == null) {
                return const _LoadingContent();
              }

              final userId = userSnapshot.data!;
              final detailAsync = ref.watch(
                workoutDayDetailProvider((userId: userId, date: date)),
              );

              return detailAsync.when(
                data: (detail) => _DetailContent(
                  detail: detail,
                  scrollController: scrollController,
                ),
                loading: () => const _LoadingContent(),
                error: (e, _) => _ErrorContent(error: e.toString()),
              );
            },
          ),
        ),
      ),
    );
      },
    );
  }
}

/// Content showing workout details
class _DetailContent extends StatelessWidget {
  final WorkoutDayDetail detail;
  final ScrollController scrollController;

  const _DetailContent({
    required this.detail,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final dateTime = detail.dateTime;
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(dateTime);

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        // Drag handle
        SliverToBoxAdapter(
          child: Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),

        // Header
        SliverToBoxAdapter(
          child: _buildHeader(context, formattedDate),
        ),

        // Content based on status
        if (detail.statusEnum == CalendarStatus.completed)
          ..._buildCompletedContent(context)
        else if (detail.statusEnum == CalendarStatus.missed)
          SliverToBoxAdapter(child: _buildMissedContent(context))
        else
          SliverToBoxAdapter(child: _buildRestContent(context)),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 32),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, String formattedDate) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  formattedDate,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              _StatusBadge(status: detail.statusEnum),
            ],
          ),
          if (detail.workoutName != null) ...[
            const SizedBox(height: 8),
            Text(
              detail.workoutName!,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (detail.workoutType != null)
              Text(
                detail.workoutType!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
          ],
          if (detail.statusEnum == CalendarStatus.completed) ...[
            const SizedBox(height: 16),
            _buildQuickStats(context),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Row(
      children: [
        if (detail.durationMinutes != null)
          _QuickStat(
            icon: Icons.timer_outlined,
            value: detail.formattedDuration,
            label: 'Duration',
          ),
        if (detail.totalVolume != null)
          _QuickStat(
            icon: Icons.fitness_center,
            value: detail.formattedVolume,
            label: 'Volume',
          ),
        if (detail.caloriesBurned != null)
          _QuickStat(
            icon: Icons.local_fire_department_outlined,
            value: '${detail.caloriesBurned}',
            label: 'Calories',
          ),
        if (detail.averageRpe != null)
          _QuickStat(
            icon: Icons.speed,
            value: detail.averageRpe!.toStringAsFixed(1),
            label: 'Avg RPE',
          ),
      ],
    );
  }

  List<Widget> _buildCompletedContent(BuildContext context) {
    return [
      // Exercises section
      if (detail.exercises.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _SectionHeader(title: 'Exercises'),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _ExerciseCard(exercise: detail.exercises[index]),
            childCount: detail.exercises.length,
          ),
        ),
      ],

      // Muscles worked
      if (detail.musclesWorked.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(title: 'Muscles Worked'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: detail.musclesWorked
                      .map((muscle) => _MuscleChip(muscle: muscle))
                      .toList(),
                ),
              ],
            ),
          ),
        ),

      // Coach feedback
      if (detail.coachFeedback != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(title: 'Coach Feedback'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.glassSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.cyan.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: AppColors.cyan,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          detail.coachFeedback!,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    ];
  }

  Widget _buildMissedContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.coral.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.coral.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_busy,
              color: AppColors.coral,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Workout Missed',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              detail.workoutName != null
                  ? 'Scheduled: ${detail.workoutName}'
                  : 'No workout completed this day',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.glassSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.self_improvement,
              color: AppColors.teal,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Rest Day',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Recovery is just as important as training. Your muscles grow during rest!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Status badge
class _StatusBadge extends StatelessWidget {
  final CalendarStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, text, icon) = switch (status) {
      CalendarStatus.completed => (
          AppColors.success,
          'Completed',
          Icons.check_circle
        ),
      CalendarStatus.missed => (AppColors.coral, 'Missed', Icons.cancel),
      CalendarStatus.rest => (AppColors.teal, 'Rest', Icons.bedtime),
      CalendarStatus.future => (AppColors.textMuted, 'Upcoming', Icons.schedule),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

/// Quick stat widget
class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _QuickStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.glassSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.cyan, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section header
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
      ),
    );
  }
}

/// Exercise card showing sets and details
class _ExerciseCard extends StatelessWidget {
  final ExerciseSetDetail exercise;

  const _ExerciseCard({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(12),
        border: exercise.hasPr
            ? Border.all(color: AppColors.yellow.withOpacity(0.4))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.exerciseName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      exercise.muscleGroup,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
              if (exercise.hasPr)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: AppColors.yellow,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        exercise.prType ?? 'PR',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.yellow,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Sets
          ...exercise.sets.asMap().entries.map((entry) {
            final set = entry.value;
            return _SetRow(set: set);
          }),

          // Best set summary
          if (exercise.bestSetWeight != null && exercise.bestSetReps != null) ...[
            const SizedBox(height: 8),
            const Divider(color: AppColors.cardBorder),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Best Set',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                Text(
                  exercise.bestSetDisplay,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.cyan,
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Individual set row
class _SetRow extends StatelessWidget {
  final SetData set;

  const _SetRow({required this.set});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Set number
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: set.isPr
                  ? AppColors.yellow.withOpacity(0.2)
                  : AppColors.cardBorder,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${set.setNumber}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: set.isPr ? AppColors.yellow : AppColors.textSecondary,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Weight and reps
          Expanded(
            child: Text(
              set.display,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),

          // PR indicator
          if (set.isPr)
            const Icon(
              Icons.star,
              color: AppColors.yellow,
              size: 16,
            ),
        ],
      ),
    );
  }
}

/// Muscle chip
class _MuscleChip extends StatelessWidget {
  final String muscle;

  const _MuscleChip({required this.muscle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cyan.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        muscle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.cyan,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}

/// Loading content
class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppColors.cyan),
        ),
      ),
    );
  }
}

/// Error content
class _ErrorContent extends StatelessWidget {
  final String error;

  const _ErrorContent({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
