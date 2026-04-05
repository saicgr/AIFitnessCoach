part of 'netflix_exercises_tab.dart';

/// Methods extracted from _NetflixExercisesTabState
extension __NetflixExercisesTabStateExt on _NetflixExercisesTabState {

  Widget _buildExercisesContent(
    List<LibraryExercise> allExercises,
    CategoryExercisesData categoryData,
    String searchQuery,
    bool isDark,
    Color textMuted,
  ) {
    // Smart search active: show AI results
    if (_useSmartSearch && searchQuery.isNotEmpty && searchQuery.length >= 2) {
      if (_isSmartSearching) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: isDark ? AppColors.cyan : AppColorsLight.cyan),
              const SizedBox(height: 16),
              Text('Searching...', style: TextStyle(color: textMuted)),
            ],
          ),
        );
      }

      if (_smartSearchResults.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, color: textMuted, size: 48),
              const SizedBox(height: 16),
              const Text('No exercises found'),
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _smartSearchResults = [];
                    _searchCorrection = null;
                    _searchTimeMs = null;
                  });
                },
                child: const Text('Clear search'),
              ),
            ],
          ),
        );
      }

      final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
      final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

      return Column(
        children: [
          // Correction banner
          if (_searchCorrection != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.auto_fix_high, size: 14, color: isDark ? AppColors.cyan : AppColorsLight.cyan),
                  const SizedBox(width: 6),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 13, color: textSecondary),
                        children: [
                          const TextSpan(text: 'Showing results for '),
                          TextSpan(
                            text: _searchCorrection,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_searchTimeMs != null)
                    Text(
                      '${_searchTimeMs!.round()}ms',
                      style: TextStyle(fontSize: 11, color: textMuted),
                    ),
                ],
              ),
            ),
          // Smart search results list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _smartSearchResults.length,
              itemBuilder: (context, index) {
                final result = _smartSearchResults[index];
                // Convert SmartSearchExerciseItem to LibraryExercise for detail sheet
                final exercise = LibraryExercise(
                  id: result.id,
                  nameValue: result.name,
                  bodyPart: result.bodyPart,
                  equipmentValue: result.equipment,
                  targetMuscle: result.targetMuscle,
                  gifUrl: result.gifUrl,
                  videoUrl: result.videoUrl,
                  imageUrl: result.imageUrl,
                  difficultyLevelValue: result.difficulty,
                  instructionsValue: result.instructions,
                );
                return _ExerciseListCard(
                  exercise: exercise,
                  isDark: isDark,
                  isAiMatch: result.isSemanticMatch,
                  onTap: () => _showExerciseDetail(exercise),
                )
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: index * 30));
              },
            ),
          ),
        ],
      );
    }

    // Client-side search filter: show list view
    if (!_useSmartSearch && searchQuery.isNotEmpty) {
      if (allExercises.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fitness_center, color: textMuted, size: 48),
              const SizedBox(height: 16),
              const Text('No exercises found'),
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                  });
                },
                child: const Text('Clear filters'),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        itemCount: allExercises.length,
        itemBuilder: (context, index) {
          final exercise = allExercises[index];
          return _ExerciseListCard(
            exercise: exercise,
            isDark: isDark,
            onTap: () => _showExerciseDetail(exercise),
          )
              .animate()
              .fadeIn(delay: Duration(milliseconds: index * 30));
        },
      );
    }

    // If a section is expanded, show full list for that section
    if (_expandedSection != null) {
      final muscleGroups = _groupExercisesByMuscle(allExercises);
      final equipmentGroups = _groupExercisesByEquipment(allExercises);

      // Check muscle groups and equipment groups for exercises
      List<LibraryExercise> sectionExercises = muscleGroups[_expandedSection] ?? [];
      if (sectionExercises.isEmpty) {
        sectionExercises = equipmentGroups[_expandedSection] ?? [];
      }

      return Column(
        children: [
          // Back to sections header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticService.light();
                    setState(() => _expandedSection = null);
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_back_ios,
                        size: 16,
                        color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Back',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  _expandedSection!,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${sectionExercises.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Exercise list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: sectionExercises.length,
              itemBuilder: (context, index) {
                final exercise = sectionExercises[index];
                return _ExerciseListCard(
                  exercise: exercise,
                  isDark: isDark,
                  onTap: () => _showExerciseDetail(exercise),
                )
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: index * 20));
              },
            ),
          ),
        ],
      );
    }

    // Clean hierarchy: Muscle Groups → Equipment → Splits
    final muscleGroups = _groupExercisesByMuscle(allExercises);
    final equipmentGroups = _groupExercisesByEquipment(allExercises);

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        // 1. Training Splits (top priority — program discovery)
        _buildGravlSplitsSection(isDark)
            .animate().fadeIn(),

        // 2. Muscle group pills
        _buildMuscleGroupsSection(
          muscleGroups,
          isDark,
          textMuted,
        ).animate().fadeIn(delay: const Duration(milliseconds: 100)),

        // 3. Equipment pills
        _buildEquipmentPillsSection(
          equipmentGroups,
          isDark,
          textMuted,
        ).animate().fadeIn(delay: const Duration(milliseconds: 200)),

        // 4. My Custom Exercises
        _buildCustomExercisesSection(isDark, textMuted)
            .animate().fadeIn(delay: const Duration(milliseconds: 300)),

        // 5. All Exercises (paginated, alphabetical)
        _buildAllExercisesSection(
          categoryData.allExercisesSorted,
          isDark,
          textMuted,
        ).animate().fadeIn(delay: const Duration(milliseconds: 400)),
      ],
    );
  }

}
