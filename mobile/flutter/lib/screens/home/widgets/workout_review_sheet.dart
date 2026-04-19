import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/workout.dart';
import '../../../data/models/exercise.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../widgets/exercise_image.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/main_shell.dart';
import '../../workout/widgets/exercise_swap_sheet.dart';
import '../../workout/widgets/exercise_add_sheet.dart';
import '../../workout/widgets/exercise_detail_sheet.dart';
import 'components/components.dart';

/// Shows workout review sheet after regeneration.
///
/// The sheet operates on a *preview* workout held in a short-lived backend
/// cache keyed by [previewId]. The original (still-live) workout is
/// [originalWorkoutId]. Closing the sheet:
///   - via "Approve Plan" → commits the preview (supersedes the original) and
///     returns the committed [Workout].
///   - via "Back" / close icon / (any non-approve path) → discards the preview
///     cache entry and returns null. The original workout is untouched.
///
/// Callers should refresh home caches / today-workout provider / Drift ONLY
/// when the returned [Workout] is non-null. On null, the on-device view of the
/// original workout is still authoritative.
///
/// Throws are caught internally and surfaced as snackbars + an inline banner
/// with a "Try again" CTA; the sheet always pops either null or a committed
/// workout (never a preview) to keep downstream callers simple.
Future<Workout?> showWorkoutReviewSheet(
  BuildContext context,
  WidgetRef ref,
  Workout generatedWorkout, {
  required String previewId,
  required String originalWorkoutId,
}) async {
  // Hide nav bar while sheet is open
  ref.read(floatingNavBarVisibleProvider.notifier).state = false;

  return await showGlassSheet<Workout>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    builder: (context) => _WorkoutReviewSheet(
      workout: generatedWorkout,
      previewId: previewId,
      originalWorkoutId: originalWorkoutId,
    ),
  ).whenComplete(() {
    // Show nav bar when sheet is closed
    ref.read(floatingNavBarVisibleProvider.notifier).state = true;
  });
}

class _WorkoutReviewSheet extends ConsumerStatefulWidget {
  final Workout workout;
  final String previewId;
  final String originalWorkoutId;

  const _WorkoutReviewSheet({
    required this.workout,
    required this.previewId,
    required this.originalWorkoutId,
  });

  @override
  ConsumerState<_WorkoutReviewSheet> createState() =>
      _WorkoutReviewSheetState();
}

class _WorkoutReviewSheetState extends ConsumerState<_WorkoutReviewSheet> {
  late Workout _currentWorkout;
  bool _isSwapping = false;
  bool _isAdding = false;
  // True while /regenerate-commit is in flight. Disables Approve so a
  // double-tap can't fire the commit twice (commit itself is idempotent on
  // preview_id, but defense-in-depth; also gates Back during commit).
  bool _isApproving = false;
  // True while /regenerate-discard is in flight. Kept brief — we don't block
  // the user from leaving if the network lags; discard is fire-and-forget.
  bool _isDiscarding = false;
  // Non-null when a PREVIEW_EXPIRED / ORIGINAL_ALREADY_SUPERSEDED error came
  // back during approval. Rendered as an inline banner at the top of the
  // sheet so the user sees the state transition before their next action.
  _ReviewBannerError? _bannerError;

  @override
  void initState() {
    super.initState();
    _currentWorkout = widget.workout;
  }

  Future<void> _swapExercise(WorkoutExercise exercise) async {
    if (_currentWorkout.id == null) return;

    setState(() => _isSwapping = true);

    final updatedWorkout = await showExerciseSwapSheet(
      context,
      ref,
      workoutId: _currentWorkout.id!,
      exercise: exercise,
      previewId: widget.previewId,
    );

    if (mounted) {
      setState(() => _isSwapping = false);
      if (updatedWorkout != null) {
        setState(() => _currentWorkout = updatedWorkout);
      }
    }
  }

  Future<void> _viewExerciseDetail(WorkoutExercise exercise) async {
    await showExerciseDetailSheet(
      context,
      ref,
      exercise: exercise,
    );
  }

  Future<void> _addExercise() async {
    if (_currentWorkout.id == null) return;

    setState(() => _isAdding = true);

    final updatedWorkout = await showExerciseAddSheet(
      context,
      ref,
      workoutId: _currentWorkout.id!,
      workoutType: _currentWorkout.type ?? 'strength',
      currentExerciseNames:
          _currentWorkout.exercises.map((e) => e.name).toList(),
      previewId: widget.previewId,
    );

    if (mounted) {
      setState(() => _isAdding = false);
      if (updatedWorkout != null) {
        setState(() => _currentWorkout = updatedWorkout);
      }
    }
  }

  /// Fire-and-forget discard, then close with null.
  /// We briefly show a spinner so a user who taps Back immediately sees
  /// something, but we don't block the pop on the network round-trip —
  /// the preview TTL will evict the cache entry even if the request drops.
  Future<void> _goBack() async {
    // Guard: if an approve is already in flight, ignore Back so we don't end
    // up racing a commit against a discard on the same preview_id.
    if (_isApproving || _isDiscarding) return;

    setState(() => _isDiscarding = true);
    final repo = ref.read(workoutRepositoryProvider);
    // Fire-and-forget; regenerateDiscard swallows its own errors.
    // We intentionally do NOT await beyond a short window — the user wants
    // to leave now, and discard is a cleanup hint, not a correctness gate.
    unawaited(repo.regenerateDiscard(previewId: widget.previewId));
    if (!mounted) return;
    Navigator.pop(context, null);
  }

  /// Approve: commit the preview to the DB and pop with the committed Workout.
  /// On typed errors we surface a banner + snackbar and pop with null so the
  /// caller can show the prompt to regenerate.
  Future<void> _approvePlan() async {
    if (_isApproving) return; // double-tap guard
    setState(() {
      _isApproving = true;
      _bannerError = null;
    });

    final repo = ref.read(workoutRepositoryProvider);
    try {
      final committed = await repo.regenerateCommit(
        previewId: widget.previewId,
        originalWorkoutId: widget.originalWorkoutId,
      );
      if (!mounted) return;
      Navigator.pop(context, committed);
    } on PreviewExpiredException catch (e) {
      debugPrint('⚠️ [ReviewSheet] Preview expired: $e');
      if (!mounted) return;
      _showSheetSnack('Preview expired — please regenerate');
      // Render inline banner so if the user lingers they see context.
      setState(() {
        _isApproving = false;
        _bannerError = _ReviewBannerError.previewExpired;
      });
      // Pop null so the parent can re-open the regenerate sheet with the
      // same parameters (preserves form state).
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      Navigator.pop(context, null);
    } on OriginalSupersededException catch (e) {
      debugPrint('⚠️ [ReviewSheet] Original superseded: $e');
      if (!mounted) return;
      _showSheetSnack(
          'This workout was modified elsewhere — please regenerate');
      setState(() {
        _isApproving = false;
        _bannerError = _ReviewBannerError.originalSuperseded;
      });
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      Navigator.pop(context, null);
    } catch (e, stack) {
      debugPrint('❌ [ReviewSheet] Approve failed: $e');
      debugPrint('📍 Stack: $stack');
      if (!mounted) return;
      _showSheetSnack('Failed to save workout. Please try again.');
      setState(() => _isApproving = false);
    }
  }

  void _showSheetSnack(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.sheetColors;
    final exercises = _currentWorkout.exercises;

    return GlassSheet(
      maxHeightFraction: 0.85,
      showHandle: false,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(colors),
            Divider(height: 1, color: colors.cardBorder),
            // Inline error banner (PREVIEW_EXPIRED / ORIGINAL_ALREADY_SUPERSEDED)
            // surfaces above the summary with a "Try again" CTA that pops the
            // sheet with null so the parent can re-open the regenerate flow
            // with the same preserved form parameters.
            if (_bannerError != null) _buildErrorBanner(colors, _bannerError!),
            _buildWorkoutSummary(colors),
            Divider(height: 1, color: colors.cardBorder),
            Flexible(
              child: _buildExerciseList(colors, exercises),
            ),
            _buildAddExerciseButton(colors),
            _buildBottomActions(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(SheetColors colors, _ReviewBannerError err) {
    final (title, description) = switch (err) {
      _ReviewBannerError.previewExpired => (
          'Preview expired',
          'The preview timed out before you approved. Tap "Try again" to regenerate.',
        ),
      _ReviewBannerError.originalSuperseded => (
          'Workout changed',
          'This workout was modified elsewhere. Tap "Try again" to regenerate against the latest version.',
        ),
    };
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: colors.orange, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // "Try again" pops null; the parent (regenerate sheet) re-enables
          // its UI and the user can press Regenerate with the same form
          // state already in memory.
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Title row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: colors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Review Your Workout',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                // Close icon follows the same guards as the Back button so
                // we can't fire a discard while a commit is in flight.
                onPressed: (_isApproving || _isDiscarding)
                    ? null
                    : () {
                        _goBack();
                      },
                icon: Icon(Icons.close, color: colors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutSummary(SheetColors colors) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeColor = getWorkoutTypeColor(_currentWorkout.type ?? 'strength', isDark: isDark);
    final difficultyColor =
        getDifficultyColor(_currentWorkout.difficulty ?? 'medium', isDark: isDark);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Workout name
          Text(
            _currentWorkout.name ?? 'Your Workout',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // Badges and stats row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Type badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  (_currentWorkout.type ?? 'strength').toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: typeColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              // Difficulty badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: difficultyColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  (_currentWorkout.difficulty ?? 'medium').toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: difficultyColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              // Duration
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.textMuted.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined,
                        size: 12, color: colors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      _currentWorkout.formattedDurationShort,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Exercise count
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.textMuted.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fitness_center,
                        size: 12, color: colors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${_currentWorkout.exerciseCount} exercises',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList(SheetColors colors, List<WorkoutExercise> exercises) {
    if (exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 48, color: colors.textMuted),
            const SizedBox(height: 12),
            Text(
              'No exercises yet',
              style: TextStyle(color: colors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return _ReviewExerciseCard(
          exercise: exercise,
          index: index,
          colors: colors,
          isSwapping: _isSwapping,
          onSwap: () => _swapExercise(exercise),
          onTap: () => _viewExerciseDetail(exercise),
        );
      },
    );
  }

  Widget _buildAddExerciseButton(SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: OutlinedButton.icon(
        onPressed: _isAdding ? null : _addExercise,
        icon: _isAdding
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.success,
                ),
              )
            : Icon(Icons.add, color: colors.success),
        label: Text(
          _isAdding ? 'Adding...' : 'Add Exercise',
          style: TextStyle(color: colors.success),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colors.success.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(SheetColors colors) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button — disabled during approve so a user who double-taps
          // can't race a discard against a commit on the same preview_id.
          Expanded(
            child: OutlinedButton.icon(
              onPressed: (_isApproving || _isDiscarding)
                  ? null
                  : () {
                      _goBack();
                    },
              icon: _isDiscarding
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.textPrimary,
                      ),
                    )
                  : Icon(Icons.arrow_back,
                      size: 18, color: colors.textPrimary),
              label: Text(
                _isDiscarding ? 'Closing...' : 'Back',
                style: TextStyle(color: colors.textPrimary),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.textPrimary,
                side: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.2),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Approve Plan button — disabled + spinner while commit is in flight.
          // The handler itself also early-returns on re-entry, so a rapid
          // double-tap at the exact frame boundary is a no-op.
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _isApproving
                  ? null
                  : () {
                      _approvePlan();
                    },
              icon: _isApproving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check, size: 18),
              label: Text(_isApproving ? 'Saving...' : 'Approve Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.success,
                foregroundColor: Colors.white,
                disabledBackgroundColor: colors.success.withOpacity(0.6),
                disabledForegroundColor: Colors.white.withOpacity(0.9),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reasons the sheet surfaces an inline error banner at the top. Keeps the
/// banner copy and "Try again" UX centralized — adding a new error code
/// means extending this enum + its switch in _buildErrorBanner.
enum _ReviewBannerError {
  /// Backend returned 404 `PREVIEW_EXPIRED` on commit — TTL lapsed.
  previewExpired,

  /// Backend returned 409 `ORIGINAL_ALREADY_SUPERSEDED` on commit — the
  /// original workout was mutated by another flow while the user reviewed.
  originalSuperseded,
}

/// Individual exercise card for review
class _ReviewExerciseCard extends StatelessWidget {
  final WorkoutExercise exercise;
  final int index;
  final SheetColors colors;
  final bool isSwapping;
  final VoidCallback onSwap;
  final VoidCallback onTap;

  const _ReviewExerciseCard({
    required this.exercise,
    required this.index,
    required this.colors,
    required this.isSwapping,
    required this.onSwap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Backend's enrich_exercises_with_video_urls() populates image_s3_path
    // (from exercise_library_cleaned.image_url) for ~84% of exercises; gif_url
    // is almost never populated. Prefer the populated field, then let
    // ExerciseImage fuzzy-fetch by name as a final fallback.
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.glassSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
        children: [
          ExerciseImage(
            exerciseName: exercise.name,
            imageUrl: exercise.imageS3Path ?? exercise.gifUrl ?? exercise.videoUrl,
            width: 60,
            height: 60,
            borderRadius: 8,
            backgroundColor: colors.textMuted.withOpacity(0.1),
            iconColor: colors.textMuted,
          ),
          const SizedBox(width: 12),
          // Exercise details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exercise name
                Text(
                  exercise.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Muscle group and equipment
                Text(
                  _buildMuscleEquipmentText(),
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Sets, reps, rest
                Row(
                  children: [
                    _buildStatChip(
                      '${exercise.sets ?? 3} sets',
                      colors,
                    ),
                    const SizedBox(width: 6),
                    _buildStatChip(
                      '${exercise.reps ?? '10-12'} reps',
                      colors,
                    ),
                    const SizedBox(width: 6),
                    _buildStatChip(
                      '${exercise.restSeconds ?? 60}s',
                      colors,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Swap button
          IconButton(
            onPressed: isSwapping ? null : onSwap,
            icon: isSwapping
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.cyan,
                    ),
                  )
                : Icon(
                    Icons.swap_horiz,
                    color: colors.cyan,
                    size: 24,
                  ),
            tooltip: 'Swap exercise',
          ),
        ],
      ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String text, SheetColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.textMuted.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: colors.textMuted,
        ),
      ),
    );
  }

  String _buildMuscleEquipmentText() {
    final parts = <String>[];
    if (exercise.muscleGroup != null && exercise.muscleGroup!.isNotEmpty) {
      parts.add(exercise.muscleGroup!);
    }
    if (exercise.equipment != null && exercise.equipment!.isNotEmpty) {
      parts.add(exercise.equipment!);
    }
    return parts.join(' • ');
  }
}
