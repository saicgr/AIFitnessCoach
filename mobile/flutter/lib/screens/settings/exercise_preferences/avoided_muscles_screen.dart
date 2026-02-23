import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/exercise_preferences_repository.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/body_muscle_selector.dart';
import '../../../widgets/glass_back_button.dart';
import '../../../widgets/glass_sheet.dart';

/// Provider for avoided muscles list
final avoidedMusclesProvider =
    FutureProvider.family<List<AvoidedMuscle>, String>((ref, userId) async {
  final repo = ref.watch(exercisePreferencesRepositoryProvider);
  return repo.getAvoidedMuscles(userId);
});

/// Screen for managing muscle groups to avoid - shows body diagram directly.
/// When [embedded] is true, renders without Scaffold/AppBar for use inside tabs.
class AvoidedMusclesScreen extends ConsumerStatefulWidget {
  final bool embedded;
  const AvoidedMusclesScreen({super.key, this.embedded = false});

  @override
  ConsumerState<AvoidedMusclesScreen> createState() =>
      _AvoidedMusclesScreenState();
}

class _AvoidedMusclesScreenState extends ConsumerState<AvoidedMusclesScreen> {
  bool _isProcessing = false;

  // Track newly selected muscles (not yet saved)
  final Set<String> _pendingMuscles = {};

  // Key to force body selector rebuild on clear
  int _bodySelectorKey = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textColor =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final authState = ref.watch(authStateProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      final notLoggedIn = Center(child: Text('Please log in', style: TextStyle(color: textMuted)));
      if (widget.embedded) return notLoggedIn;
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(title: const Text('Muscles to Avoid')),
        body: notLoggedIn,
      );
    }

    final avoidedAsync = ref.watch(avoidedMusclesProvider(userId));

    final body = avoidedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error loading muscles', style: TextStyle(color: textMuted)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(avoidedMusclesProvider(userId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (avoidedMuscles) {
          // Get already avoided muscle names
          final alreadyAvoidedNames =
              avoidedMuscles.map((m) => m.muscleGroup).toSet();

          // Combined set for display (already avoided + pending)
          final allSelectedMuscles = {...alreadyAvoidedNames, ..._pendingMuscles};

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Instruction text
                        Text(
                          'Select muscles to avoid or reduce in your workouts',
                          style: TextStyle(
                            fontSize: 14,
                            color: textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // Body diagram - multi-select enabled
                        BodyMuscleSelectorWidget(
                          key: ValueKey(_bodySelectorKey),
                          height: 550,
                          selectedMuscles: allSelectedMuscles,
                          onMuscleToggle: (muscle) {
                            HapticService.light();
                            setState(() {
                              // Check if already saved (can't toggle those here)
                              if (alreadyAvoidedNames.contains(muscle)) {
                                // Show removal option for already avoided
                                _showRemoveConfirmation(context, userId,
                                    avoidedMuscles.firstWhere((m) => m.muscleGroup == muscle));
                                return;
                              }

                              // Toggle pending selection
                              if (_pendingMuscles.contains(muscle)) {
                                _pendingMuscles.remove(muscle);
                              } else {
                                _pendingMuscles.add(muscle);
                              }
                            });
                          },
                        ),

                        const SizedBox(height: 20),

                        // Already avoided muscles section
                        if (avoidedMuscles.isNotEmpty) ...[
                          Text(
                            'Currently Avoided',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: avoidedMuscles.map((muscle) {
                              final isAvoid = muscle.severity == 'avoid';
                              final severityColor = isAvoid ? AppColors.error : AppColors.orange;
                              return GestureDetector(
                                onTap: () => _showEditSheet(context, userId, muscle),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: severityColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: severityColor.withValues(alpha: 0.5)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isAvoid ? Icons.block : Icons.remove_circle_outline,
                                        size: 14,
                                        color: severityColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        muscle.displayName,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom action bar (show when there are pending selections)
              if (_pendingMuscles.isNotEmpty)
                Container(
                  padding: EdgeInsets.fromLTRB(
                    16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
                  decoration: BoxDecoration(
                    color: elevatedColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Selected muscles preview
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _pendingMuscles.map((muscle) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.cyan.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                getMuscleDisplayName(muscle),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isProcessing
                                  ? null
                                  : () => _addMuscles(userId, 'avoid'),
                              icon: const Icon(Icons.block, size: 18),
                              label: const Text('Avoid'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isProcessing
                                  ? null
                                  : () => _addMuscles(userId, 'reduce'),
                              icon: const Icon(Icons.remove_circle_outline, size: 18),
                              label: const Text('Reduce'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
    );

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const GlassBackButton(),
        title: Text(
          'Muscles to Avoid',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_pendingMuscles.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  _pendingMuscles.clear();
                  _bodySelectorKey++;
                });
                HapticService.light();
              },
              child: Text(
                'Clear',
                style: TextStyle(color: textMuted),
              ),
            ),
        ],
      ),
      body: body,
    );
  }

  void _showRemoveConfirmation(
      BuildContext context, String userId, AvoidedMuscle muscle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.background : AppColorsLight.background,
        title: Text(
          'Remove "${muscle.displayName}"?',
          style: TextStyle(color: textColor),
        ),
        content: Text(
          'This muscle will no longer be avoided in your workouts.',
          style: TextStyle(
            color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeMuscle(userId, muscle);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(
      BuildContext context, String userId, AvoidedMuscle muscle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.background : AppColorsLight.background;
    final textColor =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              muscle.displayName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (muscle.severity == 'avoid'
                        ? AppColors.error
                        : AppColors.orange)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                muscle.severity == 'avoid' ? 'AVOIDED' : 'REDUCED',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: muscle.severity == 'avoid'
                      ? AppColors.error
                      : AppColors.orange,
                ),
              ),
            ),
            if (muscle.reason != null) ...[
              const SizedBox(height: 12),
              Text(
                'Reason: ${muscle.reason}',
                style: TextStyle(color: textMuted),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _removeMuscle(userId, muscle);
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove from Avoid List'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  /// Shows a bottom sheet asking the user whether to update the current workout
  /// or apply the avoided muscles to future workouts only.
  /// Returns `true` (update current), `false` (future only), or `null` (cancelled).
  Future<bool?> _showMuscleAvoidChoiceSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.background : AppColorsLight.background;
    final textColor =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return showGlassSheet<bool?>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      useRootNavigator: true,
      builder: (sheetContext) => GlassSheet(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'When should this apply?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 20),

            // Option 1: Update current workout
            GestureDetector(
              onTap: () => Navigator.pop(sheetContext, true),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.cyan.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.update,
                        color: AppColors.cyan,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Update current workout',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Regenerate today\'s workout without these muscles',
                            style: TextStyle(
                              fontSize: 12,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.cyan,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Option 2: Apply to future workouts only
            GestureDetector(
              onTap: () => Navigator.pop(sheetContext, false),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.skip_next,
                        color: textMuted,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Apply to future workouts only',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Current workout stays unchanged',
                            style: TextStyle(
                              fontSize: 12,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: textMuted,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Cancel button
            TextButton(
              onPressed: () {
                // Show discard confirmation dialog
                showDialog(
                  context: sheetContext,
                  builder: (dialogContext) => AlertDialog(
                    backgroundColor: backgroundColor,
                    title: Text(
                      'Discard selection?',
                      style: TextStyle(color: textColor),
                    ),
                    content: Text(
                      'Selected muscles won\'t be added to the avoid list.',
                      style: TextStyle(color: textMuted),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(
                          'Go Back',
                          style: TextStyle(color: textMuted),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext); // close dialog
                          Navigator.pop(sheetContext, null); // close sheet
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Discard'),
                      ),
                    ],
                  ),
                );
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 15,
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  Future<void> _addMuscles(String userId, String severity) async {
    if (_isProcessing || _pendingMuscles.isEmpty) return;

    // Show choice sheet before saving
    final shouldRegenerate = await _showMuscleAvoidChoiceSheet(context);
    if (shouldRegenerate == null) {
      // User cancelled - clear pending muscles
      setState(() {
        _pendingMuscles.clear();
        _bodySelectorKey++;
      });
      return;
    }

    setState(() => _isProcessing = true);
    HapticService.medium();

    try {
      final repo = ref.read(exercisePreferencesRepositoryProvider);

      // Add each muscle
      for (final muscle in _pendingMuscles) {
        await repo.addAvoidedMuscle(userId, muscle, severity: severity);
      }

      ref.invalidate(avoidedMusclesProvider(userId));

      // Only regenerate if user chose to update current workout
      if (shouldRegenerate) {
        final response = ref.read(todayWorkoutProvider).valueOrNull;
        final workoutToRegenerate = response?.todayWorkout ?? response?.nextWorkout;
        if (workoutToRegenerate != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Updating workout to ${severity == 'avoid' ? 'avoid' : 'reduce'} selected muscles...'),
                backgroundColor: AppColors.cyan,
                duration: const Duration(seconds: 1),
              ),
            );
          }

          final workoutRepo = ref.read(workoutRepositoryProvider);
          await for (final progress in workoutRepo.regenerateWorkoutStreaming(
            workoutId: workoutToRegenerate.id,
            userId: userId,
          )) {
            debugPrint('Muscle avoid regeneration: ${progress.message}');
            if (progress.isCompleted || progress.hasError) break;
          }
        }
      }

      ref.invalidate(todayWorkoutProvider);
      ref.invalidate(workoutsProvider);

      final count = _pendingMuscles.length;
      setState(() => _pendingMuscles.clear());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              shouldRegenerate
                  ? (count == 1
                      ? 'Workout updated - muscle will be ${severity == 'avoid' ? 'avoided' : 'reduced'}'
                      : 'Workout updated - $count muscles will be ${severity == 'avoid' ? 'avoided' : 'reduced'}')
                  : (count == 1
                      ? 'Muscle will be ${severity == 'avoid' ? 'avoided' : 'reduced'} in future workouts'
                      : '$count muscles will be ${severity == 'avoid' ? 'avoided' : 'reduced'} in future workouts'),
            ),
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
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _removeMuscle(String userId, AvoidedMuscle muscle) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    HapticService.light();

    try {
      final repo = ref.read(exercisePreferencesRepositoryProvider);
      await repo.removeAvoidedMuscle(userId, muscle.id);
      ref.invalidate(avoidedMusclesProvider(userId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed "${muscle.displayName}"'),
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
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
