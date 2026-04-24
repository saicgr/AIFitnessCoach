/// `📋 View plan` glass bottom sheet — shared between Easy and Advanced.
///
/// Shows the full workout at a glance so the user can jump to any exercise
/// without scrolling the active surface. The sheet itself scrolls; the
/// no-scroll rule applies to the active-workout Column, not to sheets.
///
/// Originally lived at `simple/widgets/simple_plan_sheet.dart` when the
/// app had a Simple tier. That tier was retired and the sheet moved here
/// verbatim; public names shortened to `showPlanSheet`.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/exercise.dart';
import '../../../widgets/exercise_image.dart';
import '../../../widgets/glass_sheet.dart';
import '../models/workout_state.dart';

Future<void> showPlanSheet({
  required BuildContext context,
  required List<WorkoutExercise> exercises,
  required Map<int, List<SetLog>> completedSets,
  required Map<int, int> totalSetsPerExercise,
  required int currentExerciseIndex,
  required ValueChanged<int> onJumpTo,
}) {
  return showGlassSheet<void>(
    context: context,
    builder: (ctx) => GlassSheet(
      maxHeightFraction: 0.9,
      showHandle: true,
      child: _PlanSheet(
        exercises: exercises,
        completedSets: completedSets,
        totalSetsPerExercise: totalSetsPerExercise,
        currentExerciseIndex: currentExerciseIndex,
        onJumpTo: (i) {
          Navigator.pop(ctx);
          onJumpTo(i);
        },
      ),
    ),
  );
}

class _PlanSheet extends StatelessWidget {
  final List<WorkoutExercise> exercises;
  final Map<int, List<SetLog>> completedSets;
  final Map<int, int> totalSetsPerExercise;
  final int currentExerciseIndex;
  final ValueChanged<int> onJumpTo;

  const _PlanSheet({
    required this.exercises,
    required this.completedSets,
    required this.totalSetsPerExercise,
    required this.currentExerciseIndex,
    required this.onJumpTo,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final fg = isDark ? Colors.white : Colors.black87;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.78,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
            child: Row(children: [
              Text("Today's plan",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700, color: fg)),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close, color: fg),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: exercises.length,
              itemBuilder: (c, i) {
                final ex = exercises[i];
                final total = totalSetsPerExercise[i] ?? 3;
                final done = completedSets[i]?.length ?? 0;
                final isCurrent = i == currentExerciseIndex;
                final isDone = done >= total && total > 0;
                return _PlanRow(
                  exercise: ex,
                  totalSets: total,
                  doneSets: done,
                  isCurrent: isCurrent,
                  isDone: isDone,
                  accent: accent,
                  isDark: isDark,
                  onTap: () => onJumpTo(i),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  final WorkoutExercise exercise;
  final int totalSets;
  final int doneSets;
  final bool isCurrent;
  final bool isDone;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const _PlanRow({
    required this.exercise,
    required this.totalSets,
    required this.doneSets,
    required this.isCurrent,
    required this.isDone,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? Colors.white : Colors.black87;
    final muted = fg.withOpacity(0.6);
    final status = isDone
        ? '✓ Done'
        : isCurrent
            ? '← Current'
            : doneSets > 0
                ? '$doneSets / $totalSets'
                : 'Up next';
    final statusColor = isDone
        ? Colors.green
        : isCurrent
            ? accent
            : muted;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isCurrent ? accent : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(children: [
          _thumb(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: fg)),
                const SizedBox(height: 2),
                Text(
                  '${totalSets}×${exercise.reps ?? '—'}',
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ],
            ),
          ),
          Text(status,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor)),
        ]),
      ),
    );
  }

  Widget _thumb() {
    // imageS3Path on the workout payload is often a raw S3 key (not a URL) or
    // a presigned URL that has already expired. Go through ExerciseImage so
    // the `/exercise-images/{name}` endpoint can mint a fresh presigned URL
    // when the pre-resolved value isn't usable.
    final preResolved =
        exercise.imageS3Path ?? exercise.gifUrl ?? exercise.videoUrl;
    return ExerciseImage(
      exerciseName: exercise.name,
      imageUrl: preResolved,
      width: 40,
      height: 40,
      borderRadius: 8,
      backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
      iconColor: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
    );
  }
}
