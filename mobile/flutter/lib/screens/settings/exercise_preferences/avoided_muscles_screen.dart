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

/// Provider for avoided muscles list
final avoidedMusclesProvider =
    FutureProvider.family<List<AvoidedMuscle>, String>((ref, userId) async {
  final repo = ref.watch(exercisePreferencesRepositoryProvider);
  return repo.getAvoidedMuscles(userId);
});

/// Screen for managing muscle groups to avoid - shows body diagram directly
class AvoidedMusclesScreen extends ConsumerStatefulWidget {
  const AvoidedMusclesScreen({super.key});

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
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(title: const Text('Muscles to Avoid')),
        body: const Center(child: Text('Please log in')),
      );
    }

    final avoidedAsync = ref.watch(avoidedMusclesProvider(userId));

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Muscles to Avoid',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Clear selection button (only show if there are pending selections)
          if (_pendingMuscles.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  _pendingMuscles.clear();
                  _bodySelectorKey++; // Force body selector to rebuild
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
      body: avoidedAsync.when(
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
      ),
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

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
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

  Future<void> _addMuscles(String userId, String severity) async {
    if (_isProcessing || _pendingMuscles.isEmpty) return;
    setState(() => _isProcessing = true);
    HapticService.medium();

    try {
      final repo = ref.read(exercisePreferencesRepositoryProvider);

      // Add each muscle
      for (final muscle in _pendingMuscles) {
        await repo.addAvoidedMuscle(userId, muscle, severity: severity);
      }

      ref.invalidate(avoidedMusclesProvider(userId));
      ref.invalidate(todayWorkoutProvider);
      ref.invalidate(workoutsProvider);

      final count = _pendingMuscles.length;
      setState(() => _pendingMuscles.clear());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              count == 1
                  ? 'Added muscle to ${severity == 'avoid' ? 'avoid' : 'reduce'} list'
                  : 'Added $count muscles to ${severity == 'avoid' ? 'avoid' : 'reduce'} list',
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
