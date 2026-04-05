part of 'exercise_add_sheet.dart';

/// Methods extracted from _ExerciseAddSheetState
extension __ExerciseAddSheetStateExt on _ExerciseAddSheetState {

  Widget _buildMyExercisesTab(bool isDark, Color textPrimary, Color textMuted) {
    final cardBackground =
        isDark ? AppColors.elevated : AppColorsLight.elevated;
    final customState = ref.watch(customExercisesProvider);
    final favoritesState = ref.watch(favoritesProvider);
    final staplesState = ref.watch(staplesProvider);

    final queryLower = _mySearchQuery.toLowerCase();
    final currentNames = widget.currentExerciseNames
        .map((n) => n.toLowerCase())
        .toSet();

    // Filter custom exercises
    final customExercises = customState.exercises.where((ce) {
      if (currentNames.contains(ce.name.toLowerCase())) return false;
      if (queryLower.isNotEmpty &&
          !ce.name.toLowerCase().contains(queryLower)) return false;
      return true;
    }).toList();

    // Filter favorites
    final favorites = favoritesState.favorites.where((f) {
      if (currentNames.contains(f.exerciseName.toLowerCase())) return false;
      if (queryLower.isNotEmpty &&
          !f.exerciseName.toLowerCase().contains(queryLower)) return false;
      return true;
    }).toList();

    // Filter staples
    final staples = staplesState.staples.where((s) {
      if (currentNames.contains(s.exerciseName.toLowerCase())) return false;
      if (queryLower.isNotEmpty &&
          !s.exerciseName.toLowerCase().contains(queryLower)) return false;
      return true;
    }).toList();

    final isEmpty =
        customExercises.isEmpty && favorites.isEmpty && staples.isEmpty;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search my exercises...',
              hintStyle: TextStyle(color: textMuted),
              prefixIcon: Icon(Icons.search, color: textMuted),
              filled: true,
              fillColor: cardBackground,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() => _mySearchQuery = value);
            },
          ),
        ),

        Expanded(
          child: isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fitness_center,
                          size: 48,
                          color: textMuted.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'No custom exercises, favorites,\nor staples yet',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: textMuted),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create custom exercises or mark favorites\nin Library → Mine',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13,
                            color: textMuted.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Custom Exercises section
                    if (customExercises.isNotEmpty) ...[
                      _buildMineSectionHeader(
                        'Custom Exercises',
                        Icons.fitness_center,
                        AppColors.orange,
                        customExercises.length,
                        textPrimary,
                        textMuted,
                      ),
                      const SizedBox(height: 8),
                      ...customExercises.map((ce) => _buildMyExerciseCard(
                            name: ce.name,
                            subtitle:
                                '${_capitalize(ce.primaryMuscle)} · ${_capitalize(ce.equipment)}',
                            badge: 'CUSTOM',
                            badgeColor: AppColors.orange,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                            isDark: isDark,
                          )),
                      const SizedBox(height: 16),
                    ],

                    // Favorites section
                    if (favorites.isNotEmpty) ...[
                      _buildMineSectionHeader(
                        'Favorites',
                        Icons.favorite,
                        AppColors.coral,
                        favorites.length,
                        textPrimary,
                        textMuted,
                      ),
                      const SizedBox(height: 8),
                      ...favorites.map((f) => _buildMyExerciseCard(
                            name: f.exerciseName,
                            subtitle: '',
                            badge: 'FAV',
                            badgeColor: AppColors.coral,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                            isDark: isDark,
                          )),
                      const SizedBox(height: 16),
                    ],

                    // Staples section
                    if (staples.isNotEmpty) ...[
                      _buildMineSectionHeader(
                        'Staples',
                        Icons.push_pin,
                        AppColors.purple,
                        staples.length,
                        textPrimary,
                        textMuted,
                      ),
                      const SizedBox(height: 8),
                      ...staples.map((s) => _buildMyExerciseCard(
                            name: s.exerciseName,
                            subtitle: s.muscleGroup ?? '',
                            badge: 'STAPLE',
                            badgeColor: AppColors.purple,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                            isDark: isDark,
                          )),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

}
