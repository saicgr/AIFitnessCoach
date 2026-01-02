import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise.dart';

/// Shows a picker to select an exercise from the current workout exercises
Future<WorkoutExercise?> showSupersetExercisePicker(
  BuildContext context, {
  required List<WorkoutExercise> exercises,
  List<WorkoutExercise> excludeExercises = const [],
  String title = 'Select Exercise',
}) async {
  return await showModalBottomSheet<WorkoutExercise>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _SupersetExercisePicker(
      exercises: exercises,
      excludeExercises: excludeExercises,
      title: title,
    ),
  );
}

class _SupersetExercisePicker extends StatefulWidget {
  final List<WorkoutExercise> exercises;
  final List<WorkoutExercise> excludeExercises;
  final String title;

  const _SupersetExercisePicker({
    required this.exercises,
    required this.excludeExercises,
    required this.title,
  });

  @override
  State<_SupersetExercisePicker> createState() => _SupersetExercisePickerState();
}

class _SupersetExercisePickerState extends State<_SupersetExercisePicker> {
  String _searchQuery = '';

  List<WorkoutExercise> get _filteredExercises {
    // Filter out excluded exercises and those already in supersets
    final available = widget.exercises.where((e) {
      // Exclude exercises that are already selected
      if (widget.excludeExercises.any((ex) => ex.name == e.name)) {
        return false;
      }
      // Exclude exercises already in supersets
      if (e.isInSuperset) {
        return false;
      }
      return true;
    }).toList();

    // Apply search filter
    if (_searchQuery.isEmpty) {
      return available;
    }

    final query = _searchQuery.toLowerCase();
    return available.where((e) {
      return e.name.toLowerCase().contains(query) ||
          (e.muscleGroup?.toLowerCase().contains(query) ?? false) ||
          (e.primaryMuscle?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.nearBlack : AppColorsLight.pureWhite;
    final cardBackground = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
              color: textMuted.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.fitness_center, color: AppColors.purple),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: textMuted),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                hintStyle: TextStyle(color: textMuted),
                prefixIcon: Icon(Icons.search, color: textMuted),
                filled: true,
                fillColor: cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          const SizedBox(height: 8),

          // Exercise list
          Expanded(
            child: _filteredExercises.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: textMuted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No exercises available'
                              : 'No exercises found',
                          style: TextStyle(color: textMuted),
                        ),
                        if (widget.exercises.isEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Add exercises to your workout first',
                            style: TextStyle(
                              fontSize: 12,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: _filteredExercises.length,
                    itemBuilder: (context, index) {
                      final exercise = _filteredExercises[index];
                      return _ExercisePickerCard(
                        exercise: exercise,
                        onTap: () => Navigator.pop(context, exercise),
                        cardBackground: cardBackground,
                        glassSurface: glassSurface,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        textMuted: textMuted,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ExercisePickerCard extends StatelessWidget {
  final WorkoutExercise exercise;
  final VoidCallback onTap;
  final Color cardBackground;
  final Color glassSurface;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  const _ExercisePickerCard({
    required this.exercise,
    required this.onTap,
    required this.cardBackground,
    required this.glassSurface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    final muscleInfo = exercise.muscleGroup ?? exercise.primaryMuscle ?? exercise.bodyPart;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Exercise GIF/Image
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: glassSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: exercise.gifUrl != null && exercise.gifUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: exercise.gifUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Center(
                            child: Icon(
                              Icons.fitness_center,
                              color: textMuted,
                              size: 24,
                            ),
                          ),
                          errorWidget: (_, __, ___) => Icon(
                            Icons.fitness_center,
                            color: textMuted,
                            size: 24,
                          ),
                        )
                      : Icon(
                          Icons.fitness_center,
                          color: textMuted,
                          size: 24,
                        ),
                ),
                const SizedBox(width: 12),

                // Exercise info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (muscleInfo != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.purple.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _formatMuscleGroup(muscleInfo),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.purple,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            exercise.setsRepsDisplay,
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Select indicator
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    color: AppColors.purple,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatMuscleGroup(String muscle) {
    // Capitalize first letter of each word
    return muscle
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }
}
