import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/favorites_provider.dart';
import '../../../data/repositories/exercise_preferences_repository.dart';
import '../../../widgets/glass_back_button.dart';
import 'widgets/exercise_picker_sheet.dart';

/// Screen for managing favorite exercises
class FavoriteExercisesScreen extends ConsumerWidget {
  const FavoriteExercisesScreen({super.key});

  Future<void> _showAddExercisePicker(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();

    final favoritesState = ref.read(favoritesProvider);
    final excludeNames = favoritesState.favorites
        .map((f) => f.exerciseName.toLowerCase())
        .toSet();

    final result = await showExercisePickerSheet(
      context,
      ref,
      type: ExercisePickerType.favorite,
      excludeExercises: excludeNames,
    );

    if (result != null) {
      final success = await ref.read(favoritesProvider.notifier).addFavorite(
        result.exerciseName,
        exerciseId: result.exerciseId,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Added "${result.exerciseName}" to favorites'
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

    final favoritesState = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const GlassBackButton(),
        title: Text(
          'Favorite Exercises',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: AppColors.error),
            onPressed: () => _showAddExercisePicker(context, ref),
            tooltip: 'Add favorite',
          ),
        ],
      ),
      body: favoritesState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : favoritesState.favorites.isEmpty
              ? _buildEmptyState(context, ref, textMuted)
              : _buildFavoritesList(
                  context,
                  ref,
                  favoritesState.favorites,
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
              Icons.favorite_border,
              size: 72,
              color: textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Favorite Exercises',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'The AI will prioritize your favorites when generating workouts.',
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
              label: const Text('Add Favorite'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
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

  Widget _buildFavoritesList(
    BuildContext context,
    WidgetRef ref,
    List<FavoriteExercise> favorites,
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
            color: AppColors.purple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.purple.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: AppColors.purple,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'The AI will prioritize these exercises when generating your workouts.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : AppColorsLight.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Favorites list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final favorite = favorites[index];
              return _FavoriteExerciseTile(
                favorite: favorite,
                isDark: isDark,
                textPrimary: textPrimary,
                textMuted: textMuted,
                elevated: elevated,
                onRemove: () async {
                  HapticFeedback.lightImpact();
                  final confirmed = await _showRemoveDialog(
                    context,
                    favorite.exerciseName,
                    isDark,
                  );
                  if (confirmed == true) {
                    ref
                        .read(favoritesProvider.notifier)
                        .removeFavorite(favorite.exerciseName);
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
        title: const Text('Remove Favorite?'),
        content: Text(
          'Remove "$exerciseName" from your favorites? The AI will no longer prioritize this exercise.',
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

class _FavoriteExerciseTile extends StatelessWidget {
  final FavoriteExercise favorite;
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;
  final Color elevated;
  final VoidCallback onRemove;

  const _FavoriteExerciseTile({
    required this.favorite,
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
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.favorite,
            color: AppColors.error,
            size: 22,
          ),
        ),
        title: Text(
          favorite.exerciseName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        subtitle: Text(
          'Added ${_formatDate(favorite.addedAt)}',
          style: TextStyle(
            fontSize: 12,
            color: textMuted,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: textMuted),
          onPressed: onRemove,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'today';
    } else if (diff.inDays == 1) {
      return 'yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
