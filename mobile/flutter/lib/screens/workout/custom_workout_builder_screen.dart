import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/repositories/library_repository.dart';
import '../../data/services/api_client.dart';
import '../../widgets/lottie_animations.dart';

/// Custom Workout Builder Screen
///
/// Addresses the complaint: "It's much better to just use the Daily Strength app
/// and put together your own plan."
///
/// Allows users to:
/// 1. Create a workout from scratch
/// 2. Select exercises from the library
/// 3. Customize sets, reps, and weights
/// 4. Save and start the workout immediately
class CustomWorkoutBuilderScreen extends ConsumerStatefulWidget {
  const CustomWorkoutBuilderScreen({super.key});

  @override
  ConsumerState<CustomWorkoutBuilderScreen> createState() =>
      _CustomWorkoutBuilderScreenState();
}

class _CustomWorkoutBuilderScreenState
    extends ConsumerState<CustomWorkoutBuilderScreen> {
  final _nameController = TextEditingController(text: 'My Custom Workout');
  String _workoutType = 'strength';
  String _difficulty = 'medium';
  final List<Map<String, dynamic>> _selectedExercises = [];
  bool _isCreating = false;
  bool _showExerciseSearch = false;

  // Exercise search state
  bool _isSearching = false;
  List<LibraryExerciseItem> _searchResults = [];
  String _searchQuery = '';
  String? _selectedCategory;

  final _categories = [
    'All',
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Core',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _searchExercises(String query) async {
    if (query.isEmpty && _selectedCategory == null) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final libraryRepo = ref.read(libraryRepositoryProvider);
      final results = await libraryRepo.searchExercises(
        query: query.isNotEmpty ? query : null,
        bodyPart: _selectedCategory != null && _selectedCategory != 'All'
            ? _selectedCategory!.toLowerCase()
            : null,
        limit: 50,
      );

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('Error searching exercises: $e');
      setState(() => _isSearching = false);
    }
  }

  void _addExercise(LibraryExerciseItem exercise) {
    // Check if already added
    if (_selectedExercises.any((e) => e['name'] == exercise.name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${exercise.name} is already in your workout'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _selectedExercises.add({
        'name': exercise.name,
        'sets': 3,
        'reps': 10,
        'weight_kg': 0.0,
        'rest_seconds': 60,
        'equipment': exercise.equipment ?? 'bodyweight',
        'muscle_group': exercise.targetMuscle ?? exercise.bodyPart ?? '',
        'notes': '',
        'thumbnail_url': exercise.gifUrl ?? exercise.imageUrl,
      });
      _showExerciseSearch = false;
    });
  }

  void _removeExercise(int index) {
    setState(() {
      _selectedExercises.removeAt(index);
    });
  }

  void _updateExercise(int index, String field, dynamic value) {
    setState(() {
      _selectedExercises[index][field] = value;
    });
  }

  void _reorderExercises(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final exercise = _selectedExercises.removeAt(oldIndex);
      _selectedExercises.insert(newIndex, exercise);
    });
  }

  Future<void> _createWorkout() async {
    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one exercise'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a workout name'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final workoutRepo = ref.read(workoutRepositoryProvider);
      final workout = await workoutRepo.createCustomWorkout(
        userId: userId,
        name: _nameController.text.trim(),
        workoutType: _workoutType,
        difficulty: _difficulty,
        exercises: _selectedExercises.map((e) {
          // Remove thumbnail_url before sending to API
          final exercise = Map<String, dynamic>.from(e);
          exercise.remove('thumbnail_url');
          return exercise;
        }).toList(),
        durationMinutes: _estimateDuration(),
      );

      setState(() => _isCreating = false);

      if (workout != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Custom workout created!'),
              backgroundColor: AppColors.success,
            ),
          );
          // Navigate to the active workout screen
          context.go('/workout/active', extra: workout);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create workout'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isCreating = false);
      debugPrint('Error creating custom workout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  int _estimateDuration() {
    // Estimate duration based on exercises
    // Average ~5 min per exercise
    return (_selectedExercises.length * 5).clamp(15, 120);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Build Custom Workout'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createWorkout,
            child: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: LottieLoading(size: 20, useDots: true),
                  )
                : Text(
                    'Start',
                    style: TextStyle(
                      color: _selectedExercises.isEmpty
                          ? textSecondary
                          : AppColors.cyan,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: _showExerciseSearch
          ? _buildExerciseSearch(surface, textPrimary, textSecondary)
          : _buildWorkoutBuilder(surface, textPrimary, textSecondary),
      floatingActionButton: !_showExerciseSearch
          ? FloatingActionButton.extended(
              onPressed: () {
                setState(() {
                  _showExerciseSearch = true;
                  _searchQuery = '';
                  _selectedCategory = null;
                  _searchResults = [];
                });
                // Load initial results
                _searchExercises('');
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Exercise'),
              backgroundColor: AppColors.cyan,
            )
          : null,
    );
  }

  Widget _buildWorkoutBuilder(
      Color surface, Color textPrimary, Color textSecondary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Workout Name
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Workout Name',
              filled: true,
              fillColor: surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: TextStyle(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Workout Type
          Text('Workout Type',
              style: TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTypeChip('strength', 'Strength', Icons.fitness_center),
              const SizedBox(width: 8),
              _buildTypeChip('cardio', 'Cardio', Icons.directions_run),
              const SizedBox(width: 8),
              _buildTypeChip('mixed', 'Mixed', Icons.all_inclusive),
            ],
          ),
          const SizedBox(height: 16),

          // Difficulty
          Text('Difficulty',
              style: TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildDifficultyChip('easy', 'Easy'),
              const SizedBox(width: 8),
              _buildDifficultyChip('medium', 'Medium'),
              const SizedBox(width: 8),
              _buildDifficultyChip('hard', 'Hard'),
            ],
          ),
          const SizedBox(height: 24),

          // Exercises List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exercises (${_selectedExercises.length})',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_selectedExercises.isNotEmpty)
                Text(
                  '~${_estimateDuration()} min',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (_selectedExercises.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: textSecondary.withValues(alpha: 0.2),
                  style: BorderStyle.solid,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.fitness_center,
                      size: 48, color: textSecondary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'No exercises added yet',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the button below to add exercises',
                    style: TextStyle(
                      color: textSecondary.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _selectedExercises.length,
              onReorder: _reorderExercises,
              itemBuilder: (context, index) {
                final exercise = _selectedExercises[index];
                return _buildExerciseCard(
                  key: ValueKey('exercise_$index'),
                  exercise: exercise,
                  index: index,
                  surface: surface,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                );
              },
            ),

          // Spacer for FAB
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String value, String label, IconData icon) {
    final isSelected = _workoutType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _workoutType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.cyan : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.cyan
                  : AppColors.textSecondary.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(String value, String label) {
    final isSelected = _difficulty == value;
    final color = value == 'easy'
        ? AppColors.success
        : (value == 'medium' ? AppColors.warning : AppColors.error);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _difficulty = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? color
                  : AppColors.textSecondary.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseCard({
    required Key key,
    required Map<String, dynamic> exercise,
    required int index,
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header with drag handle and exercise name
          ListTile(
            leading: ReorderableDragStartListener(
              index: index,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.drag_handle, color: textSecondary),
              ),
            ),
            title: Text(
              exercise['name'] ?? 'Exercise',
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              exercise['muscle_group'] ?? '',
              style: TextStyle(color: textSecondary, fontSize: 12),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _removeExercise(index),
            ),
          ),

          // Sets, Reps, Weight controls
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // Sets
                Expanded(
                  child: _buildNumberControl(
                    label: 'Sets',
                    value: exercise['sets'] ?? 3,
                    onChanged: (v) => _updateExercise(index, 'sets', v),
                    min: 1,
                    max: 10,
                  ),
                ),
                const SizedBox(width: 12),
                // Reps
                Expanded(
                  child: _buildNumberControl(
                    label: 'Reps',
                    value: exercise['reps'] ?? 10,
                    onChanged: (v) => _updateExercise(index, 'reps', v),
                    min: 1,
                    max: 30,
                  ),
                ),
                const SizedBox(width: 12),
                // Weight
                Expanded(
                  child: _buildNumberControl(
                    label: 'Weight (kg)',
                    value: (exercise['weight_kg'] ?? 0).toInt(),
                    onChanged: (v) =>
                        _updateExercise(index, 'weight_kg', v.toDouble()),
                    min: 0,
                    max: 200,
                    step: 5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberControl({
    required String label,
    required int value,
    required Function(int) onChanged,
    int min = 0,
    int max = 100,
    int step = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: value > min ? () => onChanged(value - step) : null,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.remove,
                  size: 16,
                  color: value > min
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                value.toString(),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GestureDetector(
              onTap: value < max ? () => onChanged(value + step) : null,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add,
                  size: 16,
                  color: value < max
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExerciseSearch(
      Color surface, Color textPrimary, Color textSecondary) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _showExerciseSearch = false),
              ),
              Expanded(
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search exercises...',
                    filled: true,
                    fillColor: surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.search),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (value) {
                    _searchQuery = value;
                    _searchExercises(value);
                  },
                ),
              ),
            ],
          ),
        ),

        // Category chips
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category ||
                  (category == 'All' && _selectedCategory == null);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory =
                          (category == 'All' || !selected) ? null : category;
                    });
                    _searchExercises(_searchQuery);
                  },
                  selectedColor: AppColors.cyan.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.cyan,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Results
        Expanded(
          child: _isSearching
              ? const Center(child: LottieLoading(size: 50))
              : _searchResults.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isEmpty && _selectedCategory == null
                            ? 'Search for exercises or select a category'
                            : 'No exercises found',
                        style: TextStyle(color: textSecondary),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final exercise = _searchResults[index];
                        final isAdded = _selectedExercises
                            .any((e) => e['name'] == exercise.name);
                        final exerciseImageUrl = exercise.gifUrl ?? exercise.imageUrl;
                        return ListTile(
                          leading: exerciseImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: exerciseImageUrl,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      width: 50,
                                      height: 50,
                                      color: surface,
                                      child: const Center(
                                          child: LottieLoading(size: 20)),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      width: 50,
                                      height: 50,
                                      color: surface,
                                      child: const Icon(Icons.fitness_center),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: surface,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.fitness_center),
                                ),
                          title: Text(
                            exercise.name,
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            exercise.targetMuscle ?? exercise.bodyPart ?? exercise.equipment ?? '',
                            style: TextStyle(color: textSecondary, fontSize: 12),
                          ),
                          trailing: isAdded
                              ? const Icon(Icons.check, color: AppColors.success)
                              : IconButton(
                                  icon: const Icon(Icons.add_circle_outline,
                                      color: AppColors.cyan),
                                  onPressed: () => _addExercise(exercise),
                                ),
                          onTap: isAdded ? null : () => _addExercise(exercise),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
