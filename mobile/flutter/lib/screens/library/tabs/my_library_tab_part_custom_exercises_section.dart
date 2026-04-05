part of 'my_library_tab.dart';


// ============================================================================
// CUSTOM EXERCISES SECTION
// ============================================================================

class _CustomExercisesSection extends ConsumerWidget {
  final bool isDark;

  const _CustomExercisesSection({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customState = ref.watch(customExercisesProvider);
    final exercises = customState.exercises;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(Icons.fitness_center, size: 20, color: orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'My Exercises',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticService.light();
                showGlassSheet(
                  context: context,
                  builder: (context) => const CreateExerciseSheet(),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16, color: orange),
                    const SizedBox(width: 4),
                    Text(
                      'Create',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ).animate().fadeIn().slideY(begin: 0.05),
        const SizedBox(height: 12),

        // Content
        if (customState.isLoading && exercises.isEmpty)
          _buildLoadingPlaceholder()
        else if (exercises.isEmpty)
          _buildEmptyState(context, ref, orange, textMuted)
        else
          ...exercises.asMap().entries.map((entry) {
            final index = entry.key;
            final exercise = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CustomExerciseCard(
                exercise: exercise,
                isDark: isDark,
              ),
            ).animate().fadeIn(delay: (index * 60).ms).slideY(begin: 0.1);
          }),
      ],
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: (isDark ? AppColors.elevated : AppColorsLight.elevated),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    WidgetRef ref,
    Color orange,
    Color textMuted,
  ) {
    return GestureDetector(
      onTap: () {
        HapticService.light();
        showGlassSheet(
          context: context,
          builder: (context) => const CreateExerciseSheet(),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              orange.withValues(alpha: 0.10),
              Colors.amber.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: orange.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.add_circle_outline,
                size: 28,
                color: orange,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Create your first custom exercise',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Build supersets, combos, or unique movements',
              style: TextStyle(
                fontSize: 13,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: orange,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}


class _CustomExerciseCard extends ConsumerWidget {
  final CustomExercise exercise;
  final bool isDark;

  const _CustomExerciseCard({
    required this.exercise,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return GestureDetector(
      onTap: () {
        HapticService.light();
        // Convert CustomExercise to LibraryExercise for the detail sheet
        final libraryExercise = LibraryExercise(
          nameValue: exercise.name,
          bodyPart: exercise.primaryMuscle,
          equipmentValue: exercise.equipment,
        );
        showGlassSheet(
          context: context,
          builder: (context) => ExerciseDetailSheet(exercise: libraryExercise),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              orange.withValues(alpha: 0.10),
              Colors.amber.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: orange.withValues(alpha: 0.15),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail placeholder
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: exercise.customVideoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: exercise.customVideoUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Icon(
                            Icons.fitness_center,
                            size: 22,
                            color: orange,
                          ),
                        ),
                      )
                    : Icon(
                        exercise.isComposite
                            ? Icons.merge_type
                            : Icons.fitness_center,
                        size: 22,
                        color: orange,
                      ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            exercise.name,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (exercise.isComposite) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              exercise.comboType?.toUpperCase() ?? 'COMBO',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: orange,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        _capitalize(exercise.primaryMuscle),
                        _capitalize(exercise.equipment),
                      ].join(' - '),
                      style: TextStyle(
                        fontSize: 12,
                        color: textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Edit button
              GestureDetector(
                onTap: () {
                  HapticService.light();
                  // Open detail sheet which has edit capabilities
                  final libraryExercise = LibraryExercise(
                    nameValue: exercise.name,
                    bodyPart: exercise.primaryMuscle,
                    equipmentValue: exercise.equipment,
                  );
                  showGlassSheet(
                    context: context,
                    builder: (context) =>
                        ExerciseDetailSheet(exercise: libraryExercise),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: elevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}


// ============================================================================
// FAVORITES SECTION
// ============================================================================

class _FavoritesSection extends ConsumerWidget {
  final bool isDark;

  const _FavoritesSection({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesState = ref.watch(favoritesProvider);
    final favoriteNames = favoritesState.favorites;
    final categoryAsync = ref.watch(categoryExercisesProvider);
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final coral = isDark ? AppColors.coral : AppColorsLight.coral;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(Icons.favorite, size: 18, color: coral),
            const SizedBox(width: 8),
            Text(
              'Favorites (${favoriteNames.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            if (favoriteNames.length > 5)
              GestureDetector(
                onTap: () {
                  HapticService.light();
                  // View All could navigate to a full favorites screen
                },
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: coral,
                  ),
                ),
              ),
          ],
        ).animate().fadeIn().slideY(begin: 0.05),
        const SizedBox(height: 12),

        // Content
        if (favoriteNames.isEmpty)
          _buildEmptyState(textMuted)
        else
          categoryAsync.when(
            loading: () => const SizedBox(
              height: 110,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => _buildEmptyState(textMuted),
            data: (categoryData) {
              // Cross-reference favorite names with full exercise data
              final allExercises = categoryData.allExercisesSorted;
              final favoriteExercises = <LibraryExercise>[];
              final favoriteNameSet = favoritesState.favoriteNames;

              for (final exercise in allExercises) {
                if (favoriteNameSet.contains(exercise.name.toLowerCase())) {
                  favoriteExercises.add(exercise);
                }
              }

              if (favoriteExercises.isEmpty) {
                return _buildEmptyState(textMuted);
              }

              return SizedBox(
                height: 130,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: favoriteExercises.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < favoriteExercises.length - 1 ? 10 : 0,
                      ),
                      child: _CompactExerciseCard(
                        exercise: favoriteExercises[index],
                        isDark: isDark,
                        gradientColors: [
                          coral.withValues(alpha: 0.10),
                          AppColors.pink.withValues(alpha: 0.05),
                        ],
                      ),
                    ).animate().fadeIn(delay: (index * 80).ms).slideX(begin: 0.15);
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildEmptyState(Color textMuted) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        'Heart exercises to save them here',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: textMuted.withValues(alpha: 0.7),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}


// ============================================================================
// STAPLES SECTION
// ============================================================================

class _StaplesSection extends ConsumerWidget {
  final bool isDark;

  const _StaplesSection({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staplesState = ref.watch(staplesProvider);
    final staples = staplesState.staples;
    final categoryAsync = ref.watch(categoryExercisesProvider);
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(Icons.push_pin, size: 18, color: purple),
            const SizedBox(width: 8),
            Text(
              'Staples (${staples.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ).animate().fadeIn().slideY(begin: 0.05),
        const SizedBox(height: 2),
        Text(
          'AI prioritizes these in your workouts',
          style: TextStyle(
            fontSize: 12,
            color: textMuted,
          ),
        ).animate().fadeIn().slideY(begin: 0.05),
        const SizedBox(height: 12),

        // Content
        if (staplesState.isLoading && staples.isEmpty)
          const SizedBox(
            height: 130,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (staples.isEmpty)
          _buildEmptyState(textMuted)
        else
          categoryAsync.when(
            loading: () => const SizedBox(
              height: 130,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => _buildEmptyState(textMuted),
            data: (categoryData) {
              // Cross-reference staple names with full exercise data
              final allExercises = categoryData.allExercisesSorted;
              final stapleExercises = <LibraryExercise>[];
              final stapleNameSet = staplesState.stapleNames;

              for (final exercise in allExercises) {
                if (stapleNameSet.contains(exercise.name.toLowerCase())) {
                  stapleExercises.add(exercise);
                }
              }

              if (stapleExercises.isEmpty) {
                // Show staple names even without full exercise data
                return SizedBox(
                  height: 130,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: staples.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          right: index < staples.length - 1 ? 10 : 0,
                        ),
                        child: _StapleNameCard(
                          name: staples[index].exerciseName,
                          muscleGroup: staples[index].muscleGroup,
                          isDark: isDark,
                        ),
                      ).animate().fadeIn(delay: (index * 80).ms).slideX(begin: 0.15);
                    },
                  ),
                );
              }

              return SizedBox(
                height: 130,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: stapleExercises.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < stapleExercises.length - 1 ? 10 : 0,
                      ),
                      child: _CompactExerciseCard(
                        exercise: stapleExercises[index],
                        isDark: isDark,
                        gradientColors: [
                          purple.withValues(alpha: 0.10),
                          AppColors.info.withValues(alpha: 0.05),
                        ],
                      ),
                    ).animate().fadeIn(delay: (index * 80).ms).slideX(begin: 0.15);
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildEmptyState(Color textMuted) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        'Mark exercises as staples for AI to prioritize',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: textMuted.withValues(alpha: 0.7),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}


/// Fallback card when staple exercise is not found in the full library
class _StapleNameCard extends StatelessWidget {
  final String name;
  final String? muscleGroup;
  final bool isDark;

  const _StapleNameCard({
    required this.name,
    required this.isDark,
    this.muscleGroup,
  });

  @override
  Widget build(BuildContext context) {
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return SizedBox(
      width: 110,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              purple.withValues(alpha: 0.10),
              AppColors.info.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: purple.withValues(alpha: 0.15),
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: purple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.push_pin, size: 18, color: purple),
            ),
            const Spacer(),
            Text(
              name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (muscleGroup != null) ...[
              const SizedBox(height: 2),
              Text(
                muscleGroup!,
                style: TextStyle(
                  fontSize: 10,
                  color: textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}


// ============================================================================
// COMPACT EXERCISE CARD (used for Favorites & Staples carousels)
// ============================================================================

class _CompactExerciseCard extends StatelessWidget {
  final LibraryExercise exercise;
  final bool isDark;
  final List<Color> gradientColors;

  const _CompactExerciseCard({
    required this.exercise,
    required this.isDark,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return GestureDetector(
      onTap: () {
        HapticService.light();
        showGlassSheet(
          context: context,
          builder: (context) => ExerciseDetailSheet(exercise: exercise),
        );
      },
      child: SizedBox(
        width: 110,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: gradientColors.first.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image area
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(13),
                ),
                child: SizedBox(
                  height: 65,
                  width: double.infinity,
                  child: exercise.imageUrl != null && exercise.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: exercise.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _buildIconFallback(),
                          errorWidget: (_, __, ___) => _buildIconFallback(),
                        )
                      : _buildIconFallback(),
                ),
              ),

              // Name and muscle
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      if (exercise.muscleGroup != null)
                        Text(
                          exercise.muscleGroup!,
                          style: TextStyle(
                            fontSize: 10,
                            color: textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconFallback() {
    return Container(
      color: gradientColors.first.withValues(alpha: 0.3),
      child: Center(
        child: Icon(
          Icons.fitness_center,
          size: 24,
          color: gradientColors.first.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}


// ============================================================================
// RECENT ACTIVITY SECTION
// ============================================================================

class _RecentActivitySection extends ConsumerWidget {
  final bool isDark;

  const _RecentActivitySection({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(exerciseHistoryProvider);
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(Icons.history, size: 20, color: cyan),
            const SizedBox(width: 8),
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            historyAsync.whenOrNull(
                  data: (history) {
                    if (history.length > 5) {
                      return GestureDetector(
                        onTap: () {
                          HapticService.light();
                          // Navigate to full history view (My Stats tab)
                        },
                        child: Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cyan,
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ) ??
                const SizedBox.shrink(),
          ],
        ).animate().fadeIn().slideY(begin: 0.05),
        const SizedBox(height: 12),

        // Content
        historyAsync.when(
          loading: () => const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, __) => Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Failed to load activity',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: textMuted),
            ),
          ),
          data: (history) {
            if (history.isEmpty) {
              return _buildEmptyState(textMuted);
            }

            final displayItems = history.take(5).toList();
            return Column(
              children: displayItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _HistoryTimelineCard(
                  item: item,
                  isDark: isDark,
                  isLast: index == displayItems.length - 1,
                ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: -0.05);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState(Color textMuted) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        'Complete workouts to see your exercise history',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: textMuted.withValues(alpha: 0.7),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

