import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../data/models/workout.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/api_client.dart';

/// Shows a bottom sheet with workout actions
Future<void> showWorkoutActionsSheet(
  BuildContext context,
  WidgetRef ref,
  Workout workout, {
  VoidCallback? onRefresh,
}) async {
  await showGlassSheet(
    context: context,
    builder: (context) => GlassSheet(
      showHandle: false,
      child: _WorkoutActionsSheet(
        workout: workout,
        onRefresh: onRefresh,
      ),
    ),
  );
}

class _WorkoutActionsSheet extends ConsumerStatefulWidget {
  final Workout workout;
  final VoidCallback? onRefresh;

  const _WorkoutActionsSheet({required this.workout, this.onRefresh});

  @override
  ConsumerState<_WorkoutActionsSheet> createState() => _WorkoutActionsSheetState();
}

class _WorkoutActionsSheetState extends ConsumerState<_WorkoutActionsSheet> {
  bool _isLoading = false;
  String? _loadingAction;

  // Streaming progress state for regeneration
  int _regenerateStep = 0;
  int _regenerateTotalSteps = 4;
  String _regenerateMessage = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentColor = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            // Title
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      color: accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Workout Options',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.workout.name ?? 'Workout',
                          style: TextStyle(
                            fontSize: 14,
                            color: accentColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: textMuted, size: 22),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: cardBorder),

            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _ActionTile(
                    icon: Icons.calendar_month,
                    title: 'Reschedule',
                    subtitle: 'Change workout date',
                    isLoading: _loadingAction == 'reschedule',
                    onTap: () => _handleReschedule(context),
                  ),
                  _ActionTile(
                    icon: Icons.refresh,
                    title: 'Regenerate',
                    subtitle: _loadingAction == 'regenerate' && _regenerateMessage.isNotEmpty
                        ? '$_regenerateMessage ($_regenerateStep/$_regenerateTotalSteps)'
                        : 'Create a new workout for this day',
                    isLoading: _loadingAction == 'regenerate',
                    onTap: () => _handleRegenerate(context),
                  ),
                  _ActionTile(
                    icon: Icons.history,
                    title: 'Version History',
                    subtitle: 'View and restore previous versions',
                    isLoading: _loadingAction == 'versions',
                    onTap: () => _handleVersionHistory(context),
                  ),
                  _ActionTile(
                    icon: Icons.directions_run,
                    title: 'Generate Warmup',
                    subtitle: 'Create warmup exercises',
                    isLoading: _loadingAction == 'warmup',
                    onTap: () => _handleGenerateWarmup(context),
                  ),
                  _ActionTile(
                    icon: Icons.self_improvement,
                    title: 'Generate Stretches',
                    subtitle: 'Create cool-down stretches',
                    isLoading: _loadingAction == 'stretches',
                    onTap: () => _handleGenerateStretches(context),
                  ),
                  _ActionTile(
                    icon: Icons.delete_outline,
                    title: 'Delete Workout',
                    subtitle: 'Remove this workout',
                    isDestructive: true,
                    isLoading: _loadingAction == 'delete',
                    onTap: () => _handleDelete(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
          ],
            ),
    );
  }

  Future<void> _handleReschedule(BuildContext context) async {
    final newDate = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(widget.workout.scheduledDate ?? '') ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.cyan,
              surface: AppColors.nearBlack,
            ),
          ),
          child: child!,
        );
      },
    );

    if (newDate != null && mounted) {
      setState(() {
        _isLoading = true;
        _loadingAction = 'reschedule';
      });

      final repo = ref.read(workoutRepositoryProvider);
      final success = await repo.rescheduleWorkout(
        widget.workout.id!,
        newDate.toIso8601String().split('T')[0],
      );

      setState(() {
        _isLoading = false;
        _loadingAction = null;
      });

      if (mounted) {
        Navigator.pop(context);
        if (success) {
          widget.onRefresh?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Workout rescheduled'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to reschedule workout'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleRegenerate(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.nearBlack,
        title: const Text('Regenerate Workout?'),
        content: const Text(
          'This will create a new workout plan for this day. The current workout will be saved in version history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.cyan),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() {
        _isLoading = true;
        _loadingAction = 'regenerate';
        _regenerateStep = 0;
        _regenerateMessage = 'Starting regeneration...';
      });

      final userId = await ref.read(apiClientProvider).getUserId();
      final repo = ref.read(workoutRepositoryProvider);
      Workout? generatedWorkout;

      // Use streaming for real-time progress updates
      await for (final progress in repo.regenerateWorkoutStreaming(
        workoutId: widget.workout.id!,
        userId: userId!,
      )) {
        if (!mounted) break;

        if (progress.hasError) {
          setState(() {
            _isLoading = false;
            _loadingAction = null;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${progress.message}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }

        setState(() {
          _regenerateStep = progress.step;
          _regenerateTotalSteps = progress.totalSteps;
          _regenerateMessage = progress.message;
        });

        if (progress.isCompleted && progress.workout != null) {
          generatedWorkout = progress.workout;
          break;
        }
      }

      setState(() {
        _isLoading = false;
        _loadingAction = null;
      });

      if (mounted) {
        Navigator.pop(context);
        if (generatedWorkout != null) {
          widget.onRefresh?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Workout regenerated'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to regenerate workout'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleVersionHistory(BuildContext context) async {
    setState(() {
      _loadingAction = 'versions';
    });

    final repo = ref.read(workoutRepositoryProvider);
    final versions = await repo.getWorkoutVersions(widget.workout.id!);

    setState(() {
      _loadingAction = null;
    });

    if (!mounted) return;

    Navigator.pop(context);

    await showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: _VersionHistorySheet(
          workoutId: widget.workout.id!,
          versions: versions,
          onRevert: () {
            widget.onRefresh?.call();
          },
        ),
      ),
    );
  }

  Future<void> _handleGenerateWarmup(BuildContext context) async {
    setState(() {
      _isLoading = true;
      _loadingAction = 'warmup';
    });

    final repo = ref.read(workoutRepositoryProvider);
    final warmup = await repo.generateWarmup(widget.workout.id!);

    setState(() {
      _isLoading = false;
      _loadingAction = null;
    });

    if (!mounted) return;

    Navigator.pop(context);

    if (warmup.isNotEmpty) {
      await showGlassSheet(
        context: context,
        builder: (context) => GlassSheet(
          child: _WarmupStretchesSheet(
            title: 'Warmup Exercises',
            exercises: warmup,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to generate warmup'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleGenerateStretches(BuildContext context) async {
    setState(() {
      _isLoading = true;
      _loadingAction = 'stretches';
    });

    final repo = ref.read(workoutRepositoryProvider);
    final stretches = await repo.generateStretches(widget.workout.id!);

    setState(() {
      _isLoading = false;
      _loadingAction = null;
    });

    if (!mounted) return;

    Navigator.pop(context);

    if (stretches.isNotEmpty) {
      await showGlassSheet(
        context: context,
        builder: (context) => GlassSheet(
          child: _WarmupStretchesSheet(
            title: 'Cool-Down Stretches',
            exercises: stretches,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to generate stretches'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.nearBlack,
        title: const Text('Delete Workout?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() {
        _isLoading = true;
        _loadingAction = 'delete';
      });

      final repo = ref.read(workoutRepositoryProvider);
      final success = await repo.deleteWorkout(widget.workout.id!);

      setState(() {
        _isLoading = false;
        _loadingAction = null;
      });

      if (mounted) {
        Navigator.pop(context);
        if (success) {
          widget.onRefresh?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Workout deleted'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    }
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDestructive;
  final bool isLoading;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isDestructive = false,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final accentColor = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final errorColor = isDark ? AppColors.error : AppColorsLight.error;

    final iconColor = isDestructive ? errorColor : accentColor;
    final titleColor = isDestructive ? errorColor : textPrimary;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: iconColor,
                ),
              )
            : Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          subtitle,
          style: TextStyle(
            color: isDestructive ? errorColor.withValues(alpha: 0.7) : textSecondary,
            fontSize: 13,
          ),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      onTap: isLoading ? null : onTap,
    );
  }
}

// Version History Sheet
class _VersionHistorySheet extends ConsumerWidget {
  final String workoutId;
  final List<Map<String, dynamic>> versions;
  final VoidCallback? onRevert;

  const _VersionHistorySheet({
    required this.workoutId,
    required this.versions,
    this.onRevert,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: AppColors.nearBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.history, color: AppColors.cyan),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Version History',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Versions list
          Flexible(
            child: versions.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history, size: 48, color: AppColors.textMuted),
                        SizedBox(height: 16),
                        Text(
                          'No version history',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: versions.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final version = versions[index];
                      final versionNum = version['version'] ?? index + 1;
                      final createdAt = version['created_at'] ?? '';
                      final name = version['name'] ?? 'Version $versionNum';
                      final isCurrent = index == 0;

                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppColors.cyan.withOpacity(0.2)
                                : AppColors.elevated,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              'v$versionNum',
                              style: TextStyle(
                                color: isCurrent ? AppColors.cyan : AppColors.textMuted,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        title: Text(name),
                        subtitle: Text(
                          _formatDate(createdAt),
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: isCurrent
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'CURRENT',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                              )
                            : TextButton(
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: AppColors.nearBlack,
                                      title: const Text('Revert to this version?'),
                                      content: Text('Restore "$name"?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.cyan,
                                          ),
                                          child: const Text('Revert'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    final repo = ref.read(workoutRepositoryProvider);
                                    await repo.revertWorkout(workoutId, versionNum);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      onRevert?.call();
                                    }
                                  }
                                },
                                child: const Text('Revert'),
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}

// Warmup/Stretches Sheet
class _WarmupStretchesSheet extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> exercises;

  const _WarmupStretchesSheet({
    required this.title,
    required this.exercises,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.nearBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  title.contains('Warmup') ? Icons.directions_run : Icons.self_improvement,
                  color: AppColors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Exercises list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: exercises.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                final name = exercise['name'] ?? 'Exercise ${index + 1}';
                final duration = exercise['duration_seconds'] ?? exercise['duration'] ?? 30;
                final instructions = exercise['instructions'] ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.elevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Index
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.orange.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: AppColors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (instructions.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                instructions,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Duration
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.glassSurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${duration}s',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
