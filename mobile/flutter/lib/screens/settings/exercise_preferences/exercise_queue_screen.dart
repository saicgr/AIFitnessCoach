import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/exercise_queue_provider.dart';
import '../../../data/repositories/exercise_preferences_repository.dart';
import 'widgets/exercise_picker_sheet.dart';

/// Screen for managing the exercise queue
class ExerciseQueueScreen extends ConsumerWidget {
  const ExerciseQueueScreen({super.key});

  Future<void> _showAddExercisePicker(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();

    final queueState = ref.read(exerciseQueueProvider);
    final excludeNames = queueState.activeQueue
        .map((q) => q.exerciseName.toLowerCase())
        .toSet();

    final result = await showExercisePickerSheet(
      context,
      ref,
      type: ExercisePickerType.queue,
      excludeExercises: excludeNames,
    );

    if (result != null) {
      final success = await ref.read(exerciseQueueProvider.notifier).addToQueue(
        result.exerciseName,
        exerciseId: result.exerciseId,
        targetMuscleGroup: result.targetMuscleGroup,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Added "${result.exerciseName}" to queue'
                  : 'Failed to add exercise',
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final queueState = ref.watch(exerciseQueueProvider);
    final activeQueue = queueState.activeQueue;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Exercise Queue',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: AppColors.cyan),
            onPressed: () => _showAddExercisePicker(context, ref),
            tooltip: 'Add to queue',
          ),
        ],
      ),
      body: queueState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : activeQueue.isEmpty
              ? _buildEmptyState(context, ref, textMuted)
              : _buildQueueList(
                  context,
                  ref,
                  activeQueue,
                  isDark,
                  textPrimary,
                  textMuted,
                  elevated,
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, Color textMuted) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.queue_outlined,
              size: 72,
              color: textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Exercises Queued',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Queued exercises will be included in your next workout. Items expire after 7 days.',
              style: TextStyle(
                fontSize: 14,
                color: textMuted.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddExercisePicker(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add to Queue'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueList(
    BuildContext context,
    WidgetRef ref,
    List<QueuedExercise> queue,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color elevated,
  ) {
    return Column(
      children: [
        // Info banner
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cyan.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.cyan.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.cyan,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'These exercises will be included in your next workout. Queue items expire after 7 days.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : AppColorsLight.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Queue list
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: queue.length,
            onReorder: (oldIndex, newIndex) {
              // TODO: Implement reorder with priority update
              HapticFeedback.lightImpact();
            },
            itemBuilder: (context, index) {
              final item = queue[index];
              return _QueuedExerciseTile(
                key: ValueKey(item.id),
                item: item,
                index: index,
                isDark: isDark,
                textPrimary: textPrimary,
                textMuted: textMuted,
                elevated: elevated,
                onRemove: () async {
                  HapticFeedback.lightImpact();
                  final confirmed = await _showRemoveDialog(
                    context,
                    item.exerciseName,
                    isDark,
                  );
                  if (confirmed == true) {
                    ref
                        .read(exerciseQueueProvider.notifier)
                        .removeFromQueue(item.exerciseName);
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<bool?> _showRemoveDialog(
    BuildContext context,
    String exerciseName,
    bool isDark,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        title: const Text('Remove from Queue?'),
        content: Text(
          'Remove "$exerciseName" from your queue? It won\'t be included in your next workout.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Remove',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _QueuedExerciseTile extends StatelessWidget {
  final QueuedExercise item;
  final int index;
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;
  final Color elevated;
  final VoidCallback onRemove;

  const _QueuedExerciseTile({
    super.key,
    required this.item,
    required this.index,
    required this.isDark,
    required this.textPrimary,
    required this.textMuted,
    required this.elevated,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = item.expiresAt.difference(DateTime.now()).inDays;
    final isExpiringSoon = daysLeft <= 2;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.cyan.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.cyan,
              ),
            ),
          ),
        ),
        title: Text(
          item.exerciseName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        subtitle: Row(
          children: [
            if (item.targetMuscleGroup != null) ...[
              Text(
                item.targetMuscleGroup!,
                style: TextStyle(
                  fontSize: 12,
                  color: textMuted,
                ),
              ),
              Text(' • ', style: TextStyle(color: textMuted)),
            ],
            Text(
              isExpiringSoon
                  ? 'Expires in $daysLeft days'
                  : 'Expires ${_formatDate(item.expiresAt)}',
              style: TextStyle(
                fontSize: 12,
                color: isExpiringSoon ? AppColors.warning : textMuted,
                fontWeight: isExpiringSoon ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Icon(
                Icons.drag_handle,
                color: textMuted,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.delete_outline, color: textMuted),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
