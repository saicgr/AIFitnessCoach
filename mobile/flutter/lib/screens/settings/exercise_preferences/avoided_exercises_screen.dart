import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/exercise_preferences_repository.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../core/services/posthog_service.dart';
import '../../../widgets/pill_app_bar.dart';
import 'widgets/exercise_picker_sheet.dart';

part 'avoided_exercises_screen_part_avoided_exercise_card.dart';


/// Provider for avoided exercises list
final avoidedExercisesProvider = FutureProvider.family<List<AvoidedExercise>, String>((ref, userId) async {
  final repo = ref.watch(exercisePreferencesRepositoryProvider);
  return repo.getAvoidedExercises(userId);
});

/// Screen for managing exercises to avoid.
/// When [embedded] is true, renders without Scaffold/AppBar for use inside tabs.
class AvoidedExercisesScreen extends ConsumerStatefulWidget {
  final bool embedded;
  const AvoidedExercisesScreen({super.key, this.embedded = false});

  @override
  ConsumerState<AvoidedExercisesScreen> createState() => _AvoidedExercisesScreenState();
}

class _AvoidedExercisesScreenState extends ConsumerState<AvoidedExercisesScreen> {
  bool _isAdding = false;

  bool _hasTrackedView = false;

  @override
  Widget build(BuildContext context) {
    if (!_hasTrackedView) {
      _hasTrackedView = true;
      ref.read(posthogServiceProvider).capture(eventName: 'avoided_exercises_viewed');
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final authState = ref.watch(authStateProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      final notLoggedIn = Center(child: Text('Please log in', style: TextStyle(color: textMuted)));
      if (widget.embedded) return notLoggedIn;
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: const PillAppBar(title: 'Exercises to Avoid'),
        body: notLoggedIn,
      );
    }

    final avoidedAsync = ref.watch(avoidedExercisesProvider(userId));

    final body = Column(
      children: [
        // Info Card
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.orange, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Exercises you add here will be excluded from AI-generated workout plans.',
                    style: TextStyle(
                      fontSize: 13,
                      color: textColor,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // List
        Expanded(
          child: avoidedAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Error loading exercises', style: TextStyle(color: textMuted)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => ref.invalidate(avoidedExercisesProvider(userId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (exercises) {
              if (exercises.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: AppColors.green.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No exercises to avoid',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to add exercises you want to skip',
                        style: TextStyle(color: textMuted),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final exercise = exercises[index];
                  return _AvoidedExerciseCard(
                    exercise: exercise,
                    isDark: isDark,
                    onRemove: () => _removeExercise(userId, exercise),
                    onEdit: () => _showEditAvoidedSheet(context, userId, exercise),
                  );
                },
              );
            },
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return Stack(
        children: [
          body,
          // Above the floating tab bar in MyExercisesScreen (Issue 2).
          Positioned(
            right: 16,
            bottom: 96,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              onPressed: () => _showAddExerciseSheet(context, userId),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PillAppBar(
        title: 'Exercises to Avoid',
        actions: [
          PillAppBarAction(icon: Icons.add, onTap: () => _showAddExerciseSheet(context, userId)),
        ],
      ),
      body: body,
    );
  }

  Future<void> _showAddExerciseSheet(BuildContext context, String userId) async {
    HapticFeedback.lightImpact();

    // Get existing avoided exercise names to exclude
    final avoidedAsync = ref.read(avoidedExercisesProvider(userId));
    final excludeNames = avoidedAsync.valueOrNull
            ?.map((e) => e.exerciseName.toLowerCase())
            .toSet() ??
        {};

    // Multi-select picker — users frequently want to avoid a batch of
    // exercises in one go (e.g. "all overhead pressing variants"), so we let
    // them pick several and then collect the optional reason once.
    final picked = await showExercisePickerSheetMulti(
      context,
      ref,
      type: ExercisePickerType.avoided,
      excludeExercises: excludeNames,
    );

    if (picked == null || picked.isEmpty || !mounted) return;

    // Single-pick path keeps the original reason/temporary sheet for one
    // exercise (more friction for one-off avoids would feel wrong).
    if (picked.length == 1) {
      final avoidOptions = await _showAvoidOptionsSheet(context, picked.first.exerciseName);
      if (avoidOptions == null || avoidOptions.goBack || !mounted) return;
      await _addExercise(
        context,
        userId,
        picked.first.exerciseName,
        avoidOptions.reason,
        avoidOptions.isTemporary,
        avoidOptions.endDate,
      );
      return;
    }

    // Batch path — collect a single shared reason (optional) and apply it
    // to every selected exercise. Avoids forcing the user through N option
    // sheets in a row.
    final batchOptions = await _showBatchAvoidOptionsSheet(context, picked.length);
    if (batchOptions == null || !mounted) return;

    for (final entry in picked) {
      if (!mounted) return;
      await _addExercise(
        context,
        userId,
        entry.exerciseName,
        batchOptions.reason,
        batchOptions.isTemporary,
        batchOptions.endDate,
      );
    }
  }

  /// Lightweight options sheet used after a multi-select. The reason+temporary
  /// settings apply to every picked exercise; users can edit individual entries
  /// later from the avoided-list cards.
  Future<_AvoidOptions?> _showBatchAvoidOptionsSheet(
    BuildContext context,
    int count,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    String reason = '';
    bool isTemporary = false;
    DateTime? endDate;

    return await showGlassSheet<_AvoidOptions>(
      context: context,
      builder: (sheetContext) => GlassSheet(
        child: StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Avoid $count exercises',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reason and temporary settings will apply to every exercise. You can edit individual entries afterwards.',
                    style: TextStyle(fontSize: 13, color: textMuted, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    autofocus: true,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Reason (optional)',
                      labelStyle: TextStyle(color: textMuted),
                      hintText: 'e.g., Knee injury',
                      hintStyle: TextStyle(color: textMuted.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: elevatedColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) => reason = value,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: elevatedColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Temporary',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                'Set an end date for these restrictions',
                                style: TextStyle(fontSize: 12, color: textMuted),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isTemporary,
                          onChanged: (value) {
                            setSheetState(() {
                              isTemporary = value;
                              if (!value) endDate = null;
                            });
                          },
                          activeThumbColor: AppColors.cyan,
                        ),
                      ],
                    ),
                  ),
                  if (isTemporary) ...[
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setSheetState(() => endDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: elevatedColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: AppColors.cyan, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                endDate != null
                                    ? 'Until ${endDate!.day}/${endDate!.month}/${endDate!.year}'
                                    : 'Select end date',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: endDate != null ? textColor : textMuted,
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right, color: textMuted),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(
                          sheetContext,
                          _AvoidOptions(
                            reason: reason.trim().isEmpty ? null : reason.trim(),
                            isTemporary: isTemporary,
                            endDate: endDate,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyan,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Add $count to Avoid List',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shows a sheet for reason / temporary toggle after exercise is picked
  Future<_AvoidOptions?> _showAvoidOptionsSheet(
    BuildContext context,
    String exerciseName,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    String reason = '';
    bool isTemporary = false;
    DateTime? endDate;

    return await showGlassSheet<_AvoidOptions>(
      context: context,
      builder: (sheetContext) => GlassSheet(
        child: StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Avoid "$exerciseName"',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Reason field
                  TextField(
                    autofocus: true,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Reason (optional)',
                      labelStyle: TextStyle(color: textMuted),
                      hintText: 'e.g., Knee injury',
                      hintStyle: TextStyle(color: textMuted.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: elevatedColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) => reason = value,
                  ),
                  const SizedBox(height: 16),
                  // Temporary toggle
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: elevatedColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Temporary',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                'Set an end date for this restriction',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isTemporary,
                          onChanged: (value) {
                            setSheetState(() {
                              isTemporary = value;
                              if (!value) endDate = null;
                            });
                          },
                          activeThumbColor: AppColors.cyan,
                        ),
                      ],
                    ),
                  ),
                  if (isTemporary) ...[
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setSheetState(() => endDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: elevatedColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: AppColors.cyan, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                endDate != null
                                    ? 'Until ${endDate!.day}/${endDate!.month}/${endDate!.year}'
                                    : 'Select end date',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: endDate != null ? textColor : textMuted,
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right, color: textMuted),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Add button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(
                          sheetContext,
                          _AvoidOptions(
                            reason: reason.trim().isEmpty ? null : reason.trim(),
                            isTemporary: isTemporary,
                            endDate: endDate,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyan,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Add to Avoid List',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // Change exercise button
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext, const _AvoidOptions(goBack: true));
                      },
                      icon: Icon(Icons.swap_horiz, size: 18, color: textMuted),
                      label: Text(
                        'Change Exercise',
                        style: TextStyle(fontSize: 14, color: textMuted),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addExercise(
    BuildContext parentContext,
    String userId,
    String exerciseName,
    String? reason,
    bool isTemporary,
    DateTime? endDate,
  ) async {
    setState(() => _isAdding = true);
    HapticService.light();

    try {
      // Save the exercise — backend handles swaps inline (no regeneration needed)
      final repo = ref.read(exercisePreferencesRepositoryProvider);
      await repo.addAvoidedExercise(
        userId,
        exerciseName,
        reason: reason,
        isTemporary: isTemporary,
        endDate: endDate,
      );

      ref.invalidate(avoidedExercisesProvider(userId));
      ref.read(todayWorkoutProvider.notifier).invalidateAndRefresh();
      ref.read(workoutsProvider.notifier).silentRefresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Replaced "$exerciseName" in upcoming workouts'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _showEditAvoidedSheet(
    BuildContext context,
    String userId,
    AvoidedExercise exercise,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    String reason = exercise.reason ?? '';
    bool isTemporary = exercise.isTemporary;
    DateTime? endDate = exercise.endDate;

    final result = await showGlassSheet<_AvoidOptions>(
      context: context,
      builder: (sheetContext) => GlassSheet(
        child: StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit "${exercise.exerciseName}"',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Reason field
                  TextFormField(
                    initialValue: reason,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Reason (optional)',
                      labelStyle: TextStyle(color: textMuted),
                      hintText: 'e.g., Knee injury',
                      hintStyle: TextStyle(color: textMuted.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: elevatedColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) => reason = value,
                  ),
                  const SizedBox(height: 16),
                  // Temporary toggle
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: elevatedColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Temporary',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                'Set an end date for this restriction',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isTemporary,
                          onChanged: (value) {
                            setSheetState(() {
                              isTemporary = value;
                              if (!value) endDate = null;
                            });
                          },
                          activeThumbColor: AppColors.cyan,
                        ),
                      ],
                    ),
                  ),
                  if (isTemporary) ...[
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endDate ?? DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setSheetState(() => endDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: elevatedColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: AppColors.cyan, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                endDate != null
                                    ? 'Until ${endDate!.day}/${endDate!.month}/${endDate!.year}'
                                    : 'Select end date',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: endDate != null ? textColor : textMuted,
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right, color: textMuted),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(
                          sheetContext,
                          _AvoidOptions(
                            reason: reason.trim().isEmpty ? null : reason.trim(),
                            isTemporary: isTemporary,
                            endDate: endDate,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyan,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (result != null && mounted) {
      try {
        final repo = ref.read(exercisePreferencesRepositoryProvider);
        await repo.updateAvoidedExercise(
          userId,
          exercise.id,
          exerciseName: exercise.exerciseName,
          reason: result.reason,
          isTemporary: result.isTemporary,
          endDate: result.endDate,
        );
        ref.invalidate(avoidedExercisesProvider(userId));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Updated "${exercise.exerciseName}"'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _removeExercise(String userId, AvoidedExercise exercise) async {
    HapticService.light();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Exercise'),
        content: Text('Remove "${exercise.exerciseName}" from avoid list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(exercisePreferencesRepositoryProvider);
        await repo.removeAvoidedExercise(userId, exercise.id);
        ref.invalidate(avoidedExercisesProvider(userId));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed "${exercise.exerciseName}"'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}
