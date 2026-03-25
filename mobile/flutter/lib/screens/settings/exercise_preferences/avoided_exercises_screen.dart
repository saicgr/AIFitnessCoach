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
import '../../../widgets/pill_app_bar.dart';
import 'widgets/exercise_picker_sheet.dart';

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

  @override
  Widget build(BuildContext context) {
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
          Positioned(
            right: 16,
            bottom: 16,
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

    // Step 1: Pick an exercise using the smart search picker
    final pickerResult = await showExercisePickerSheet(
      context,
      ref,
      type: ExercisePickerType.avoided,
      excludeExercises: excludeNames,
    );

    if (pickerResult == null || !mounted) return;

    // Step 2: Show reason / temporary options sheet
    final avoidOptions = await _showAvoidOptionsSheet(
      context,
      pickerResult.exerciseName,
    );

    if (avoidOptions == null || !mounted) return;

    // Step 3: Add the exercise
    await _addExercise(
      context,
      userId,
      pickerResult.exerciseName,
      avoidOptions.reason,
      avoidOptions.isTemporary,
      avoidOptions.endDate,
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
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
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
      ref.invalidate(todayWorkoutProvider);
      ref.invalidate(workoutsProvider);

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

/// Card widget for an avoided exercise
class _AvoidedExerciseCard extends ConsumerWidget {
  final AvoidedExercise exercise;
  final bool isDark;
  final VoidCallback onRemove;
  final VoidCallback onEdit;

  const _AvoidedExerciseCard({
    required this.exercise,
    required this.isDark,
    required this.onRemove,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.block,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.exerciseName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    if (exercise.reason != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        exercise.reason!,
                        style: TextStyle(
                          fontSize: 13,
                          color: textMuted,
                        ),
                      ),
                    ],
                    if (exercise.isTemporary && exercise.endDate != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.timer, size: 12, color: AppColors.orange),
                          const SizedBox(width: 4),
                          Text(
                            'Until ${exercise.endDate!.day}/${exercise.endDate!.month}/${exercise.endDate!.year}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Edit button
              IconButton(
                icon: Icon(Icons.edit_outlined, color: AppColors.cyan, size: 20),
                onPressed: onEdit,
                tooltip: 'Edit',
              ),
              // Remove button
              IconButton(
                icon: Icon(Icons.close, color: textMuted, size: 20),
                onPressed: onRemove,
              ),
            ],
          ),
          // View Substitutes button
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _showSubstitutesSheet(context, ref),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_horiz, size: 16, color: AppColors.cyan),
                  const SizedBox(width: 6),
                  Text(
                    'View Safe Alternatives',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cyan,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubstitutesSheet(BuildContext context, WidgetRef ref) {
    HapticService.light();
    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(child: _SubstitutesSheet(
        exerciseName: exercise.exerciseName,
        reason: exercise.reason,
        isDark: isDark,
      )),
    );
  }
}

/// Sheet showing substitute exercise suggestions
class _SubstitutesSheet extends ConsumerStatefulWidget {
  final String exerciseName;
  final String? reason;
  final bool isDark;

  const _SubstitutesSheet({
    required this.exerciseName,
    this.reason,
    required this.isDark,
  });

  @override
  ConsumerState<_SubstitutesSheet> createState() => _SubstitutesSheetState();
}

class _SubstitutesSheetState extends ConsumerState<_SubstitutesSheet> {
  bool _isLoading = true;
  SubstituteResponse? _substitutes;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubstitutes();
  }

  Future<void> _loadSubstitutes() async {
    try {
      final repo = ref.read(exercisePreferencesRepositoryProvider);
      final result = await repo.getSuggestedSubstitutes(
        widget.exerciseName,
        reason: widget.reason,
      );
      if (mounted) {
        setState(() {
          _substitutes = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isDark ? AppColors.background : AppColorsLight.background;
    final textColor = widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevatedColor = widget.isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.swap_horiz, color: AppColors.cyan, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Safe Alternatives',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Text(
                            'Instead of ${widget.exerciseName}',
                            style: TextStyle(
                              fontSize: 13,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (widget.reason != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.medical_services, size: 14, color: AppColors.orange),
                        const SizedBox(width: 6),
                        Text(
                          widget.reason!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Content
          Flexible(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: AppColors.error),
                              const SizedBox(height: 16),
                              Text('Error loading alternatives', style: TextStyle(color: textMuted)),
                            ],
                          ),
                        ),
                      )
                    : _substitutes == null || _substitutes!.substitutes.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_off, size: 48, color: textMuted.withValues(alpha: 0.5)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No specific alternatives found',
                                    style: TextStyle(color: textMuted),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Browse the exercise library for options',
                                    style: TextStyle(fontSize: 12, color: textMuted.withValues(alpha: 0.7)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            shrinkWrap: true,
                            itemCount: _substitutes!.substitutes.length,
                            itemBuilder: (context, index) {
                              final sub = _substitutes!.substitutes[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: elevatedColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: sub.isSafeForReason
                                      ? Border.all(color: AppColors.green.withValues(alpha: 0.3))
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.green.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.check_circle,
                                        color: AppColors.green,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sub.name,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: textColor,
                                            ),
                                          ),
                                          if (sub.equipment != null || sub.muscleGroup != null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text(
                                                [
                                                  if (sub.muscleGroup != null) sub.muscleGroup,
                                                  if (sub.equipment != null) sub.equipment,
                                                ].join(' • '),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: textMuted,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (sub.isSafeForReason)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.green.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Safe',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.green,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
          // Message at bottom
          if (_substitutes != null && _substitutes!.message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                _substitutes!.message,
                style: TextStyle(fontSize: 12, color: textMuted),
                textAlign: TextAlign.center,
              ),
            ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
    );
  }
}

/// Options collected from the avoid options sheet
class _AvoidOptions {
  final String? reason;
  final bool isTemporary;
  final DateTime? endDate;

  const _AvoidOptions({
    this.reason,
    this.isTemporary = false,
    this.endDate,
  });
}
