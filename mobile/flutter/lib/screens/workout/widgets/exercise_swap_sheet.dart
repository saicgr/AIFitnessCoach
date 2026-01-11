import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/workout.dart';
import '../../../data/models/exercise.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/repositories/library_repository.dart';
import '../../../data/repositories/exercise_preferences_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../widgets/exercise_image.dart';

/// Shows exercise swap sheet with AI suggestions
Future<Workout?> showExerciseSwapSheet(
  BuildContext context,
  WidgetRef ref, {
  required String workoutId,
  required WorkoutExercise exercise,
}) async {
  return await showModalBottomSheet<Workout>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _ExerciseSwapSheet(
      workoutId: workoutId,
      exercise: exercise,
    ),
  );
}

class _ExerciseSwapSheet extends ConsumerStatefulWidget {
  final String workoutId;
  final WorkoutExercise exercise;

  const _ExerciseSwapSheet({
    required this.workoutId,
    required this.exercise,
  });

  @override
  ConsumerState<_ExerciseSwapSheet> createState() => _ExerciseSwapSheetState();
}

class _ExerciseSwapSheetState extends ConsumerState<_ExerciseSwapSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingSuggestions = true;
  bool _isLoadingLibrary = false;
  bool _isSwapping = false;
  List<Map<String, dynamic>> _suggestions = [];
  List<LibraryExerciseItem> _libraryExercises = [];
  String _searchQuery = '';
  String? _selectedReason;

  final _reasons = [
    'Too difficult',
    'Too easy',
    'Equipment unavailable',
    'Injury concern',
    'Personal preference',
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
        debugPrint('🚫 [Swap] Filtering ${avoidedExerciseNames.length} avoided exercises');
      } catch (e) {
        debugPrint('⚠️ [Swap] Could not fetch avoided exercises: $e');
      }

      final suggestions = await repo.getExerciseSuggestions(
        workoutId: widget.workoutId,
        exercise: widget.exercise,
        userId: userId!,
        reason: _selectedReason,
        avoidedExercises: avoidedExerciseNames,
      );

      if (mounted) {
        setState(() {
          _suggestions = suggestions;
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

  Future<void> _searchLibrary(String query) async {
    setState(() {
      _searchQuery = query;
      _isLoadingLibrary = true;
    });

    final libraryRepo = ref.read(libraryRepositoryProvider);
    final exercises = await libraryRepo.searchExercises(query: query);

    if (mounted) {
      setState(() {
        _libraryExercises = exercises;
        _isLoadingLibrary = false;
      });
    }
  }

  Future<void> _swapExercise(String newExerciseName) async {
    setState(() => _isSwapping = true);

    final repo = ref.read(workoutRepositoryProvider);
    final updatedWorkout = await repo.swapExercise(
      workoutId: widget.workoutId,
      oldExerciseName: widget.exercise.name,
      newExerciseName: newExerciseName,
    );

    setState(() => _isSwapping = false);

    if (mounted) {
      if (updatedWorkout != null) {
        Navigator.pop(context, updatedWorkout);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Swapped to $newExerciseName'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to swap exercise'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme-aware colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.nearBlack : AppColorsLight.pureWhite;
    final cardBackground = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

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

          // Header with current exercise
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.swap_horiz, color: AppColors.cyan),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Swap Exercise',
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

                const SizedBox(height: 12),

                // Current exercise
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      ExerciseImage(
                        exerciseName: widget.exercise.name,
                        width: 50,
                        height: 50,
                        borderRadius: 8,
                        backgroundColor: glassSurface,
                        iconColor: textMuted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'REPLACING',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: textMuted,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.exercise.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Reason selector
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text(
                        'Reason: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                        ),
                      ),
                      ..._reasons.map((reason) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                reason,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _selectedReason == reason
                                      ? Colors.white
                                      : textSecondary,
                                ),
                              ),
                              selected: _selectedReason == reason,
                              selectedColor: AppColors.cyan,
                              backgroundColor: cardBackground,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedReason = selected ? reason : null;
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
            indicatorColor: AppColors.cyan,
            labelColor: AppColors.cyan,
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
          if (_isSwapping)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.cyan),
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
            const CircularProgressIndicator(color: AppColors.cyan),
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

        // Create subtitle from reason or equipment/muscle info
        final subtitle = reason.isNotEmpty
            ? reason
            : [targetMuscle, equipment].where((s) => s.isNotEmpty).join(' • ');

        // Badge text based on rank
        String badge;
        Color badgeColor;
        if (rank == 1) {
          badge = 'Best Match';
          badgeColor = AppColors.success;
        } else if (rank <= 3) {
          badge = 'Top Pick';
          badgeColor = AppColors.cyan;
        } else {
          badge = equipment.isNotEmpty ? equipment : 'Alternative';
          badgeColor = AppColors.purple;
        }

        return _ExerciseOptionCard(
          name: name,
          subtitle: subtitle,
          badge: badge,
          badgeColor: badgeColor,
          onTap: () => _swapExercise(name),
          textPrimary: textPrimary,
          textMuted: textMuted,
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
              ? const Center(child: CircularProgressIndicator(color: AppColors.cyan))
              : _libraryExercises.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'Search for exercises'
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
                          badge: exercise.equipment ?? 'Bodyweight',
                          badgeColor: AppColors.purple,
                          onTap: () => _swapExercise(exercise.name),
                          textPrimary: textPrimary,
                          textMuted: textMuted,
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _ExerciseOptionCard extends ConsumerWidget {
  final String name;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final VoidCallback onTap;
  final Color textPrimary;
  final Color textMuted;

  const _ExerciseOptionCard({
    required this.name,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.onTap,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                // Exercise image (fetches presigned URL from API)
                ExerciseImage(
                  exerciseName: name,
                  width: 60,
                  height: 60,
                  borderRadius: 8,
                  backgroundColor: glassSurface,
                  iconColor: textMuted,
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

                // Swap icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.swap_horiz,
                    color: AppColors.cyan,
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
