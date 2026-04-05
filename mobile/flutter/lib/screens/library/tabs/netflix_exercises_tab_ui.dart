part of 'netflix_exercises_tab.dart';

/// UI builder methods extracted from _NetflixExercisesTabState
extension _NetflixExercisesTabStateUI on _NetflixExercisesTabState {

  /// Build "My Custom Exercises" section with create button
  Widget _buildCustomExercisesSection(bool isDark, Color textMuted) {
    final customExercisesState = ref.watch(customExercisesProvider);
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    final exercises = customExercisesState.exercises;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with create button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            children: [
              Icon(Icons.add_circle_outline, size: 18, color: cyan),
              const SizedBox(width: 8),
              Text(
                'My Custom Exercises',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              if (exercises.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  '${exercises.length}',
                  style: TextStyle(fontSize: 13, color: textMuted),
                ),
              ],
              const Spacer(),
              GestureDetector(
                onTap: () {
                  HapticService.light();
                  showGlassSheet(
                    context: context,
                    builder: (_) => const CreateExerciseSheet(),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: cyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 16, color: cyan),
                      const SizedBox(width: 4),
                      Text(
                        'Create',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cyan,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Custom exercises list or empty state
        if (exercises.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.fitness_center_outlined, size: 32, color: textMuted),
                  const SizedBox(height: 8),
                  Text(
                    'No custom exercises yet',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create your own exercises with photos and AI analysis',
                    style: TextStyle(fontSize: 12, color: textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: exercises.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                return _CustomExerciseChip(
                  exercise: exercise,
                  isDark: isDark,
                );
              },
            ),
          ),
      ],
    );
  }


  /// Build "All Exercises" section with client-side pagination
  Widget _buildAllExercisesSection(
    List<LibraryExercise> sortedExercises,
    bool isDark,
    Color textMuted,
  ) {
    if (sortedExercises.isEmpty) return const SizedBox.shrink();

    final displayCount = _displayedAllExercisesCount.clamp(0, sortedExercises.length);
    final displayedExercises = sortedExercises.take(displayCount).toList();
    final hasMore = displayCount < sortedExercises.length;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            children: [
              Text(
                'All Exercises',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${sortedExercises.length}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),
        // Exercise list (non-scrollable, inside parent ListView)
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: displayedExercises.length + (hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= displayedExercises.length) {
              // Loading indicator at bottom
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: textMuted,
                    ),
                  ),
                ),
              );
            }
            final exercise = displayedExercises[index];
            return _ExerciseListCard(
              exercise: exercise,
              isDark: isDark,
              onTap: () => _showExerciseDetail(exercise),
            );
          },
        ),
        if (!hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'All ${sortedExercises.length} exercises loaded',
                style: TextStyle(
                  fontSize: 13,
                  color: textMuted,
                ),
              ),
            ),
          ),
      ],
    );
  }


  /// Build the "Gravl Splits" section with AI Split Presets carousel
  Widget _buildGravlSplitsSection(bool isDark) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Icon(Icons.fitness_center, color: orange, size: 18),
              const SizedBox(width: 8),
              Text(
                'Training Splits',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),

        // Carousel of preset cards - with partial peek to show more items exist
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16, right: 40), // Right padding for peek effect
            itemCount: aiSplitPresets.length,
            itemBuilder: (context, index) {
              final preset = aiSplitPresets[index];
              return _GravlSplitCard(
                preset: preset,
                isDark: isDark,
                onTap: () {
                  HapticService.light();
                  showGlassSheet(
                    context: context,
                    builder: (context) => AISplitPresetDetailSheet(preset: preset),
                  );
                },
              );
            },
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

}
