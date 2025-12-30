import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/staples_provider.dart';
import '../../../data/repositories/exercise_preferences_repository.dart';

/// Screen for managing staple exercises (core lifts that never rotate)
class StapleExercisesScreen extends ConsumerWidget {
  const StapleExercisesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final staplesState = ref.watch(staplesProvider);

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
          'Staple Exercises',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: staplesState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : staplesState.staples.isEmpty
              ? _buildEmptyState(context, textMuted)
              : _buildStaplesList(
                  context,
                  ref,
                  staplesState.staples,
                  isDark,
                  textPrimary,
                  textMuted,
                  elevated,
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context, Color textMuted) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 72,
              color: textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Staple Exercises',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Mark exercises as staples from the Exercise Library. Staple exercises are your core lifts (like Squat, Bench Press, Deadlift) that will NEVER be rotated out of your workouts.',
              style: TextStyle(
                fontSize: 14,
                color: textMuted.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaplesList(
    BuildContext context,
    WidgetRef ref,
    List<StapleExercise> staples,
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
                Icons.lock,
                color: AppColors.cyan,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'These core lifts will NEVER be rotated out of your workouts, regardless of your variety setting.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : AppColorsLight.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Staples list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: staples.length,
            itemBuilder: (context, index) {
              final staple = staples[index];
              return _StapleExerciseTile(
                staple: staple,
                isDark: isDark,
                textPrimary: textPrimary,
                textMuted: textMuted,
                elevated: elevated,
                onRemove: () async {
                  HapticFeedback.lightImpact();
                  final confirmed = await _showRemoveDialog(
                    context,
                    staple.exerciseName,
                    isDark,
                  );
                  if (confirmed == true) {
                    ref
                        .read(staplesProvider.notifier)
                        .removeStaple(staple.id);
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
        title: const Text('Remove Staple?'),
        content: Text(
          'Remove "$exerciseName" from your staples? This exercise may be rotated out in future workouts.',
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

class _StapleExerciseTile extends StatelessWidget {
  final StapleExercise staple;
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;
  final Color elevated;
  final VoidCallback onRemove;

  const _StapleExerciseTile({
    required this.staple,
    required this.isDark,
    required this.textPrimary,
    required this.textMuted,
    required this.elevated,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
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
          child: Icon(
            Icons.lock,
            color: AppColors.cyan,
            size: 22,
          ),
        ),
        title: Text(
          staple.exerciseName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (staple.muscleGroup != null)
              Text(
                staple.muscleGroup!,
                style: TextStyle(
                  fontSize: 12,
                  color: textMuted,
                ),
              ),
            if (staple.reason != null)
              Text(
                _formatReason(staple.reason!),
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.cyan.withValues(alpha: 0.8),
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: textMuted),
          onPressed: onRemove,
        ),
      ),
    );
  }

  String _formatReason(String reason) {
    switch (reason) {
      case 'core_compound':
        return 'Core Compound';
      case 'favorite':
        return 'Personal Favorite';
      case 'rehab':
        return 'Rehab / Recovery';
      case 'strength_focus':
        return 'Strength Focus';
      default:
        return reason.replaceAll('_', ' ').split(' ').map((w) =>
          w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
    }
  }
}
