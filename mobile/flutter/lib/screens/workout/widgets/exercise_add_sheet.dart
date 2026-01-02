import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/workout.dart';
import '../../../data/models/exercise.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/repositories/library_repository.dart';
import '../../../data/repositories/exercise_preferences_repository.dart';
import '../../../data/services/api_client.dart';

/// Shows exercise add sheet with AI suggestions and library search
Future<Workout?> showExerciseAddSheet(
  BuildContext context,
  WidgetRef ref, {
  required String workoutId,
  required String workoutType,
  List<String>? currentExerciseNames,
}) async {
  return await showModalBottomSheet<Workout>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _ExerciseAddSheet(
      workoutId: workoutId,
      workoutType: workoutType,
      currentExerciseNames: currentExerciseNames ?? [],
    ),
  );
}

class _ExerciseAddSheet extends ConsumerStatefulWidget {
  final String workoutId;
  final String workoutType;
  final List<String> currentExerciseNames;

  const _ExerciseAddSheet({
    required this.workoutId,
    required this.workoutType,
    required this.currentExerciseNames,
  });

  @override
  ConsumerState<_ExerciseAddSheet> createState() => _ExerciseAddSheetState();
}

class _ExerciseAddSheetState extends ConsumerState<_ExerciseAddSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingSuggestions = true;
  bool _isLoadingLibrary = false;
  bool _isAdding = false;
  List<Map<String, dynamic>> _suggestions = [];
  List<LibraryExerciseItem> _libraryExercises = [];
  String _searchQuery = '';
  String? _selectedCategory;

  final _categories = [
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Core',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSuggestions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    setState(() => _isLoadingSuggestions = true);

    try {
      final userId = await ref.read(apiClientProvider).getUserId();
      final repo = ref.read(workoutRepositoryProvider);
      final prefsRepo = ref.read(exercisePreferencesRepositoryProvider);

      // Get avoided exercises to filter from suggestions
      List<String> avoidedExerciseNames = [];
      try {
        final avoided = await prefsRepo.getAvoidedExercises(userId!);
        avoidedExerciseNames = avoided
            .where((a) => a.isActive)
            .map((a) => a.exerciseName)
            .toList();
        debugPrint('🚫 [Add] Filtering ${avoidedExerciseNames.length} avoided exercises');
      } catch (e) {
        debugPrint('⚠️ [Add] Could not fetch avoided exercises: $e');
      }

      // Use a generic message to get complementary exercises for this workout
      final message = _selectedCategory != null
          ? 'Suggest $_selectedCategory exercises'
          : 'Suggest exercises to add to my ${widget.workoutType} workout';

      final suggestions = await repo.getExerciseSuggestions(
        workoutId: widget.workoutId,
        exercise: _createPlaceholderExercise(),
        userId: userId!,
        reason: message,
        avoidedExercises: avoidedExerciseNames,
      );

      // Filter out exercises already in the workout
      final filteredSuggestions = suggestions.where((s) {
        final name = (s['name'] as String?)?.toLowerCase() ?? '';
        return !widget.currentExerciseNames
            .any((existing) => existing.toLowerCase() == name);
      }).toList();

      if (mounted) {
        setState(() {
          _suggestions = filteredSuggestions;
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading suggestions: $e');
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoadingSuggestions = false;
        });
      }
    }
  }

  // Create a placeholder exercise for getting general suggestions
  WorkoutExercise _createPlaceholderExercise() {
    return WorkoutExercise(
      nameValue: 'Any Exercise',
      muscleGroup: _selectedCategory ?? widget.workoutType,
      sets: 3,
      reps: 10,
    );
  }

  Future<void> _searchLibrary(String query) async {
    setState(() {
      _searchQuery = query;
      _isLoadingLibrary = true;
    });

    final libraryRepo = ref.read(libraryRepositoryProvider);
    final exercises = await libraryRepo.searchExercises(query: query);

    // Filter out exercises already in the workout
    final filteredExercises = exercises.where((e) {
      return !widget.currentExerciseNames
          .any((existing) => existing.toLowerCase() == e.name.toLowerCase());
    }).toList();

    if (mounted) {
      setState(() {
        _libraryExercises = filteredExercises;
        _isLoadingLibrary = false;
      });
    }
  }

  Future<void> _addExercise(String exerciseName) async {
    setState(() => _isAdding = true);

    final repo = ref.read(workoutRepositoryProvider);
    final updatedWorkout = await repo.addExercise(
      workoutId: widget.workoutId,
      exerciseName: exerciseName,
    );

    setState(() => _isAdding = false);

    if (mounted) {
      if (updatedWorkout != null) {
        Navigator.pop(context, updatedWorkout);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $exerciseName'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add exercise'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.nearBlack : AppColorsLight.pureWhite;
    final cardBackground = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.add_circle, color: AppColors.success),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Add Exercise',
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

                const SizedBox(height: 8),

                Text(
                  'Find the perfect exercise to add to your workout',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),

                // Category selector
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text(
                        'Category: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                        ),
                      ),
                      ..._categories.map((category) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _selectedCategory == category
                                      ? Colors.white
                                      : textSecondary,
                                ),
                              ),
                              selected: _selectedCategory == category,
                              selectedColor: AppColors.success,
                              backgroundColor: cardBackground,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategory = selected ? category : null;
                                });
                                _loadSuggestions();
                              },
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.success,
            labelColor: AppColors.success,
            unselectedLabelColor: textMuted,
            tabs: const [
              Tab(text: 'AI Suggestions'),
              Tab(text: 'Search Library'),
            ],
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // AI Suggestions tab
                _buildSuggestionsTab(textMuted, textPrimary),

                // Library search tab
                _buildLibraryTab(cardBackground, textMuted, textPrimary),
              ],
            ),
          ),

          // Loading overlay
          if (_isAdding)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.success),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsTab(Color textMuted, Color textPrimary) {
    if (_isLoadingSuggestions) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.success),
            const SizedBox(height: 16),
            Text(
              'Getting AI suggestions...',
              style: TextStyle(color: textMuted),
            ),
          ],
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lightbulb_outline, size: 48, color: textMuted),
            const SizedBox(height: 16),
            Text(
              'No suggestions available',
              style: TextStyle(color: textMuted),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadSuggestions,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        final name = suggestion['name'] ?? 'Exercise';
        final reason = suggestion['reason'] ?? '';
        final rank = suggestion['rank'] ?? (index + 1);
        final equipment = suggestion['equipment'] ?? '';
        final targetMuscle = suggestion['target_muscle'] ?? suggestion['body_part'] ?? '';
        final gifUrl = suggestion['gif_url'] as String?;

        final subtitle = reason.isNotEmpty
            ? reason
            : [targetMuscle, equipment].where((s) => s.isNotEmpty).join(' - ');

        String badge;
        Color badgeColor;
        if (rank == 1) {
          badge = 'Recommended';
          badgeColor = AppColors.success;
        } else if (rank <= 3) {
          badge = 'Great Choice';
          badgeColor = AppColors.cyan;
        } else {
          badge = equipment.isNotEmpty ? equipment : 'Good Option';
          badgeColor = AppColors.purple;
        }

        return _ExerciseOptionCard(
          name: name,
          subtitle: subtitle,
          gifUrl: gifUrl,
          badge: badge,
          badgeColor: badgeColor,
          onTap: () => _addExercise(name),
          textPrimary: textPrimary,
          textMuted: textMuted,
          actionIcon: Icons.add_circle,
          actionColor: AppColors.success,
        );
      },
    );
  }

  Widget _buildLibraryTab(Color cardBackground, Color textMuted, Color textPrimary) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
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
            ),
            onChanged: (value) {
              if (value.length >= 2) {
                _searchLibrary(value);
              }
            },
          ),
        ),

        // Results
        Expanded(
          child: _isLoadingLibrary
              ? const Center(child: CircularProgressIndicator(color: AppColors.success))
              : _libraryExercises.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'Search for exercises to add'
                            : 'No exercises found',
                        style: TextStyle(color: textMuted),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _libraryExercises.length,
                      itemBuilder: (context, index) {
                        final exercise = _libraryExercises[index];
                        return _ExerciseOptionCard(
                          name: exercise.name,
                          subtitle: exercise.targetMuscle ?? exercise.bodyPart ?? '',
                          gifUrl: exercise.gifUrl,
                          badge: exercise.equipment ?? 'Bodyweight',
                          badgeColor: AppColors.purple,
                          onTap: () => _addExercise(exercise.name),
                          textPrimary: textPrimary,
                          textMuted: textMuted,
                          actionIcon: Icons.add_circle,
                          actionColor: AppColors.success,
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _ExerciseOptionCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String? gifUrl;
  final String badge;
  final Color badgeColor;
  final VoidCallback onTap;
  final Color textPrimary;
  final Color textMuted;
  final IconData actionIcon;
  final Color actionColor;

  const _ExerciseOptionCard({
    required this.name,
    required this.subtitle,
    this.gifUrl,
    required this.badge,
    required this.badgeColor,
    required this.onTap,
    required this.textPrimary,
    required this.textMuted,
    this.actionIcon = Icons.add_circle,
    this.actionColor = AppColors.success,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackground = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                // GIF
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: glassSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: gifUrl != null
                      ? CachedNetworkImage(
                          imageUrl: gifUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (_, __, ___) => Icon(
                            Icons.fitness_center,
                            color: textMuted,
                          ),
                        )
                      : Icon(
                          Icons.fitness_center,
                          color: textMuted,
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
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: textMuted,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Add icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: actionColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    actionIcon,
                    color: actionColor,
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
}
