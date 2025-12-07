import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/workout.dart';
import '../../../data/models/exercise.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/repositories/library_repository.dart';
import '../../../data/services/api_client.dart';

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

    final userId = await ref.read(apiClientProvider).getUserId();
    final repo = ref.read(workoutRepositoryProvider);

    final suggestions = await repo.getExerciseSuggestions(
      workoutId: widget.workoutId,
      exerciseName: widget.exercise.name,
      userId: userId!,
      reason: _selectedReason,
    );

    if (mounted) {
      setState(() {
        _suggestions = suggestions;
        _isLoadingSuggestions = false;
      });
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
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.nearBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              color: AppColors.textMuted.withOpacity(0.3),
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
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Current exercise
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.elevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.glassSurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: widget.exercise.gifUrl != null
                            ? CachedNetworkImage(
                                imageUrl: widget.exercise.gifUrl!,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.fitness_center,
                                color: AppColors.textMuted),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'REPLACING',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMuted,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.exercise.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
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
                      const Text(
                        'Reason: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
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
                                      ? AppColors.pureBlack
                                      : AppColors.textSecondary,
                                ),
                              ),
                              selected: _selectedReason == reason,
                              selectedColor: AppColors.cyan,
                              backgroundColor: AppColors.elevated,
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
            unselectedLabelColor: AppColors.textMuted,
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
                _buildSuggestionsTab(),

                // Library search tab
                _buildLibraryTab(),
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

  Widget _buildSuggestionsTab() {
    if (_isLoadingSuggestions) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.cyan),
            SizedBox(height: 16),
            Text(
              'Getting AI suggestions...',
              style: TextStyle(color: AppColors.textMuted),
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
            const Icon(Icons.lightbulb_outline, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text(
              'No suggestions available',
              style: TextStyle(color: AppColors.textMuted),
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
        final similarity = suggestion['similarity_score'] ?? 0.0;
        final gifUrl = suggestion['gif_url'];

        return _ExerciseOptionCard(
          name: name,
          subtitle: reason,
          gifUrl: gifUrl,
          badge: '${(similarity * 100).toInt()}% match',
          badgeColor: AppColors.success,
          onTap: () => _swapExercise(name),
        );
      },
    );
  }

  Widget _buildLibraryTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search exercises...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.elevated,
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
                        style: const TextStyle(color: AppColors.textMuted),
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
                          onTap: () => _swapExercise(exercise.name),
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

  const _ExerciseOptionCard({
    required this.name,
    required this.subtitle,
    this.gifUrl,
    required this.badge,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.elevated,
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
                    color: AppColors.glassSurface,
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
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.fitness_center,
                            color: AppColors.textMuted,
                          ),
                        )
                      : const Icon(
                          Icons.fitness_center,
                          color: AppColors.textMuted,
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
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
