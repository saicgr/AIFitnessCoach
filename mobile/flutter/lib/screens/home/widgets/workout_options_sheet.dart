import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/workout.dart';
import '../../../data/providers/consistency_provider.dart';
import '../../../data/providers/quick_workout_provider.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/haptic_service.dart';
import '../../../shareables/adapters/workout_adapter.dart';
import '../../../shareables/shareable_sheet.dart';
import '../../../widgets/app_dialog.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/main_shell.dart';
import '../../settings/sections/social_privacy_section.dart'
    show publicShareLinksProvider;
import '../../workout/widgets/exercise_add_sheet.dart';
import 'regenerate_workout_sheet.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Standalone, reusable workout-options bottom sheet.
///
/// This is the exact option set the Workouts-tab hero carousel exposes
/// (`_showOptionsMenu` in `hero_workout_card_ext.dart`), extracted out of
/// `_HeroWorkoutCardState` so any surface — notably the unified home
/// workout card — can present the full menu without owning the hero card's
/// State. Every action is a self-contained function: confirmation dialogs,
/// repository calls, provider invalidation and snackbars all run here.
///
/// Options: Glance · View · Add Exercises · Ask Coach · Regenerate ·
/// Share to Social · Mark as Done · Dismiss Quick (quick workouts only) ·
/// Skip Workout.
Future<void> showWorkoutOptionsSheet(
  BuildContext context,
  WidgetRef ref,
  Workout workout,
) {
  HapticService.light();
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final fg = isDark ? Colors.white : Colors.black87;
  final iconColor = isDark ? Colors.white70 : Colors.black54;

  return showGlassSheet(
    context: context,
    builder: (sheetContext) {
      ListTile tile(IconData icon, String label, VoidCallback onTap,
          {Color? color}) {
        return ListTile(
          leading: Icon(icon, color: color ?? iconColor),
          title: Text(label,
              style: TextStyle(
                  color: color ?? fg,
                  fontWeight:
                      color != null ? FontWeight.w500 : FontWeight.normal)),
          onTap: () {
            Navigator.pop(sheetContext);
            onTap();
          },
        );
      }

      return GlassSheet(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                tile(Icons.remove_red_eye_outlined, 'Glance Workout',
                    () => _glanceWorkout(context, workout)),
                if (workout.id != null)
                  tile(
                      Icons.visibility_outlined,
                      'View Workout',
                      () => context.push('/workout/${workout.id}',
                          extra: workout)),
                if (workout.id != null)
                  tile(Icons.add_circle_outline, 'Add Exercises',
                      () => _addExercises(context, ref, workout)),
                tile(Icons.chat_bubble_outline, 'Ask Coach',
                    () => _askCoach(context, workout)),
                tile(Icons.refresh, 'Regenerate Workout',
                    () => _regenerate(context, ref, workout)),
                tile(Icons.share_outlined, 'Share to Social',
                    () => _shareToSocial(context, ref, workout)),
                tile(Icons.check_circle_outline, 'Mark as Done',
                    () => _markAsDone(context, ref, workout),
                    color: AppColors.success),
                const Divider(height: 1),
                if (_isQuickWorkout(workout))
                  tile(Icons.close_rounded, 'Dismiss Quick',
                      () => _dismissQuick(context, ref, workout),
                      color: AppColors.textMuted),
                tile(Icons.skip_next_outlined, 'Skip Workout',
                    () => _skipWorkout(context, ref, workout),
                    color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Helpers — faithful 1:1 ports of the hero card's private actions.
// ---------------------------------------------------------------------------

bool _isQuickWorkout(Workout w) {
  final method = w.generationMethod?.toLowerCase() ?? '';
  if (method == 'quick_rule_based' || method == 'ai_quick_workout') return true;
  final duration = w.durationMinutes ?? w.durationMinutesMax ?? 0;
  return duration > 0 && duration <= 15 && w.exerciseCount <= 5;
}

String _scheduledDateLabel(String? scheduledDate) {
  if (scheduledDate == null) return 'TODAY';
  final parts = scheduledDate.split('T')[0].split('-');
  if (parts.length != 3) return 'TODAY';
  try {
    final date = DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (date == today) return 'TODAY';
    if (date == today.add(const Duration(days: 1))) return 'TOMORROW';
    if (date == today.subtract(const Duration(days: 1))) return 'YESTERDAY';
    const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return weekdays[date.weekday - 1];
  } catch (_) {
    return 'TODAY';
  }
}

void _snack(BuildContext context, String msg, Color color) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: color),
  );
}

void _askCoach(BuildContext context, Workout workout) {
  final name = workout.name ?? 'your workout';
  final count = workout.exerciseCount;
  final duration = workout.formattedDurationShort;
  context.push('/chat', extra: {
    'initialMessage':
        'I have questions about my upcoming workout "$name" ($count exercises, '
            '$duration). Can you help me prepare for it?',
  });
}

Future<void> _regenerate(
    BuildContext context, WidgetRef ref, Workout workout) async {
  try {
    final newWorkout =
        await showRegenerateWorkoutSheet(context, ref, workout);
    if (!context.mounted) return;
    if (newWorkout != null) {
      _snack(context, 'Workout regenerated!', AppColors.success);
    }
  } catch (_) {
    _snack(context, "Couldn't regenerate workout. Please try again.",
        AppColors.error);
  }
}

Future<void> _addExercises(
    BuildContext context, WidgetRef ref, Workout workout) async {
  final updated = await showExerciseAddSheet(
    context,
    ref,
    workoutId: workout.id!,
    workoutType: workout.type ?? 'strength',
    currentExerciseNames: workout.exercises.map((e) => e.name).toList(),
  );
  if (!context.mounted) return;
  if (updated != null) {
    ref.read(todayWorkoutProvider.notifier).invalidateAndRefresh();
    ref.read(workoutsProvider.notifier).silentRefresh();
    _snack(context, 'Exercise added!', AppColors.success);
  }
}

Future<void> _markAsDone(
    BuildContext context, WidgetRef ref, Workout workout) async {
  final dateLabel = _scheduledDateLabel(workout.scheduledDate);
  final isToday = dateLabel == 'TODAY';
  final confirm = await AppDialog.confirm(
    context,
    title: AppLocalizations.of(context).workoutOptionsMarkAsDone,
    message: isToday
        ? AppLocalizations.of(context).workoutOptionsThisWillMarkThe
        : 'Mark workout for $dateLabel as done? This will mark it as '
            'completed without tracking sets.',
    confirmText: 'Mark Done',
    confirmColor: AppColors.success,
    icon: Icons.check_circle_rounded,
  );
  if (!context.mounted || !confirm) return;

  try {
    final repo = ref.read(workoutRepositoryProvider);
    final result = await repo.markWorkoutAsDone(workout.id!);
    if (!context.mounted) return;
    if (result != null) {
      ref.read(todayWorkoutProvider.notifier).invalidateAndRefresh();
      ref.read(workoutsProvider.notifier).silentRefresh();
      _snack(context, 'Workout marked as done!', AppColors.success);
    }
  } catch (_) {
    _snack(context, 'Could not mark workout as done', AppColors.error);
  }
}

Future<void> _skipWorkout(
    BuildContext context, WidgetRef ref, Workout workout) async {
  final confirm = await AppDialog.destructive(
    context,
    title: AppLocalizations.of(context).workoutOptionsSkipWorkout,
    message: AppLocalizations.of(context).workoutOptionsThisWorkoutWillBe,
    confirmText: 'Skip',
    icon: Icons.skip_next_rounded,
  );
  if (!context.mounted || !confirm) return;

  try {
    final repo = ref.read(workoutRepositoryProvider);
    final success = await repo.deleteWorkout(workout.id!);
    if (!context.mounted) return;
    if (success) {
      ref.read(todayWorkoutProvider.notifier).invalidateAndRefresh();
      ref.read(workoutsProvider.notifier).silentRefresh();
      _snack(context, 'Workout skipped', AppColors.textMuted);
    }
  } catch (_) {
    _snack(context, 'Could not skip workout', AppColors.error);
  }
}

Future<void> _dismissQuick(
    BuildContext context, WidgetRef ref, Workout workout) async {
  final keepGoing = await AppDialog.destructive(
    context,
    title: AppLocalizations.of(context).workoutOptionsDismissQuickWorkout,
    message:
        "You'll lose this Quick. Any logged sets in it will be discarded. "
        'Continue?',
    confirmText: 'Dismiss',
    icon: Icons.delete_outline,
  );
  if (!context.mounted || !keepGoing) return;

  try {
    final ok = await ref
        .read(quickWorkoutProvider.notifier)
        .dismissCurrentQuickWorkout();
    if (!context.mounted) return;
    if (!ok) {
      _snack(context, 'Dismissed offline — will sync when online',
          AppColors.textMuted);
    } else {
      ref.read(workoutsProvider.notifier).silentRefresh();
      _snack(context, 'Quick workout dismissed', AppColors.textMuted);
    }
  } catch (_) {
    _snack(context, 'Could not dismiss workout', AppColors.error);
  }
}

void _shareToSocial(BuildContext context, WidgetRef ref, Workout workout) {
  HapticService.light();
  final streak = ref.read(currentStreakProvider);
  final shareable = WorkoutAdapter.fromCompletion(
    ref: ref,
    workoutName: workout.name ?? 'Workout',
    durationSeconds:
        (workout.estimatedDurationMinutes ?? workout.durationMinutes ?? 45) *
            60,
    plannedExercises: workout.exercises,
    totalSets: workout.exercises.fold<int>(0, (a, e) => a + (e.sets ?? 0)),
    totalReps: workout.exercises
        .fold<int>(0, (a, e) => a + ((e.sets ?? 0) * (e.reps ?? 0))),
    currentStreak: streak > 0 ? streak : null,
  );
  if (shareable == null) {
    _snack(context, 'Nothing to share yet — log a workout first',
        AppColors.textMuted);
    return;
  }
  final allowPublicLinks = ref.read(publicShareLinksProvider);
  ref.read(floatingNavBarVisibleProvider.notifier).state = false;
  ShareableSheet.show(
    context,
    data: shareable,
    onGenerateShareLink: !allowPublicLinks
        ? null
        : () async {
            try {
              final api = ref.read(apiClientProvider);
              final id = workout.id;
              if (id == null || id.isEmpty) return null;
              final res = await api.dio.post('/workouts/$id/share-link');
              final data = res.data;
              if (data is Map && data['url'] is String) {
                return data['url'] as String;
              }
              return null;
            } catch (_) {
              return null;
            }
          },
  ).then((_) {
    if (context.mounted) {
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
    }
  });
}

void _glanceWorkout(BuildContext context, Workout workout) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (dialogContext) => Dialog(
      backgroundColor: isDark ? AppColors.elevated : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    workout.name ?? AppLocalizations.of(context).navWorkout,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close,
                      color: isDark ? Colors.white70 : Colors.black54),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${workout.formattedDurationShort} • '
              '${workout.exerciseCount} exercises',
              style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(height: 16),
            ...workout.exercises.take(5).map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.fitness_center,
                            size: 16,
                            color: isDark ? Colors.white54 : Colors.black45),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 14,
                                color:
                                    isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                        Text(
                          '${e.sets ?? 0} sets',
                          style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDark ? Colors.white54 : Colors.black45),
                        ),
                      ],
                    ),
                  ),
                ),
            if (workout.exercises.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+${workout.exercises.length - 5} more exercises',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
