import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/user_provider.dart';
import '../../../data/local/database_provider.dart';
import '../../../data/models/workout.dart';
import '../../../data/models/exercise.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/repositories/exercise_preferences_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../screens/library/providers/muscle_group_images_provider.dart';
import '../../../services/exercise_selector.dart' as selector;
import '../../../services/offline_workout_generator.dart';
import '../../../services/workout_templates.dart' show muscleAliases;
import '../../../widgets/exercise_image.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/segmented_tab_bar.dart';
import '../../../data/services/image_url_cache.dart';

/// Shows exercise add sheet with Library tab first, AI Suggestions second
Future<Workout?> showExerciseAddSheet(
  BuildContext context,
  WidgetRef ref, {
  required String workoutId,
  required String workoutType,
  List<String>? currentExerciseNames,
}) async {
  return await showGlassSheet<Workout>(
    context: context,
    builder: (context) => GlassSheet(
      showHandle: false,
      child: _ExerciseAddSheet(
        workoutId: workoutId,
        workoutType: workoutType,
        currentExerciseNames: currentExerciseNames ?? [],
      ),
    ),
  );
}

const _libraryMuscleGroups = [
  'Chest',
  'Back',
  'Shoulders',
  'Legs',
  'Arms',
  'Core',
  'Glutes',
];

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

  // Library tab state
  List<OfflineExercise> _allExercises = [];
  List<OfflineExercise> _filteredExercises = [];
  String? _selectedMuscle; // null = "All" (recommended for workout type)
  String _librarySearchQuery = '';
  bool _isLoadingLibrary = true;
  List<String> _userEquipment = [];
  String _userFitnessLevel = 'intermediate';
  List<String> _avoidedExercises = [];

  // AI Suggestions tab state
  bool _aiSuggestionsLoaded = false;
  bool _isLoadingSuggestions = false;
  List<Map<String, dynamic>> _suggestions = [];

  // Shared state
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadLibraryExercises();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.index == 1 && !_aiSuggestionsLoaded) {
      _loadSuggestions();
    }
  }

  Future<void> _loadLibraryExercises() async {
    try {
      // Read user profile
      final userAsync = ref.read(currentUserProvider);
      final user = userAsync.valueOrNull;
      if (user != null) {
        _userEquipment = user.equipmentList;
        _userFitnessLevel = user.fitnessLevel ?? 'intermediate';
      }

      // Load avoided exercises
      try {
        final userId = await ref.read(apiClientProvider).getUserId();
        if (userId != null) {
          final prefsRepo = ref.read(exercisePreferencesRepositoryProvider);
          final avoided = await prefsRepo.getAvoidedExercises(userId);
          _avoidedExercises = avoided
              .where((a) => a.isActive)
              .map((a) => a.exerciseName)
              .toList();
        }
      } catch (e) {
        debugPrint('⚠️ [Add] Could not fetch avoided exercises: $e');
      }

      // Load all cached exercises from local SQLite
      final db = ref.read(appDatabaseProvider);
      final cachedExercises = await db.exerciseLibraryDao.getAllCachedExercises();

      // Convert CachedExercise -> OfflineExercise
      _allExercises = cachedExercises.map((ce) {
        List<String>? secondaryMuscles;
        if (ce.secondaryMuscles != null) {
          try {
            secondaryMuscles =
                (jsonDecode(ce.secondaryMuscles!) as List).cast<String>();
          } catch (_) {}
        }
        return OfflineExercise(
          id: ce.id,
          name: ce.name,
          bodyPart: ce.bodyPart,
          equipment: ce.equipment,
          targetMuscle: ce.targetMuscle,
          primaryMuscle: ce.primaryMuscle,
          secondaryMuscles: secondaryMuscles,
          difficulty: ce.difficulty,
          difficultyNum: ce.difficultyNum,
        );
      }).toList();

      _applyLibraryFilter();

      if (mounted) {
        setState(() => _isLoadingLibrary = false);
      }
    } catch (e) {
      debugPrint('❌ [Add] Error loading library exercises: $e');
      if (mounted) {
        setState(() => _isLoadingLibrary = false);
      }
    }
  }

  void _applyLibraryFilter() {
    List<OfflineExercise> result;

    if (_selectedMuscle != null) {
      // Specific muscle selected
      result = selector.filterExercises(
        _allExercises,
        targetMuscle: _selectedMuscle!.toLowerCase(),
        equipment: _userEquipment,
        avoidedExercises: _avoidedExercises,
        fitnessLevel: _userFitnessLevel,
      );
    } else {
      // "All" = recommended for this workout type
      final workoutLower = widget.workoutType.toLowerCase();
      final matchesAlias = muscleAliases.containsKey(workoutLower);

      if (matchesAlias) {
        result = selector.filterExercises(
          _allExercises,
          targetMuscle: workoutLower,
          equipment: _userEquipment,
          avoidedExercises: _avoidedExercises,
          fitnessLevel: _userFitnessLevel,
        );
      } else {
        // Generic workout type — show all exercises filtered by avoided
        result = _allExercises.where((ex) {
          final name = (ex.name ?? '').toLowerCase();
          if (_avoidedExercises.any((a) => a.toLowerCase() == name)) {
            return false;
          }
          return true;
        }).toList();
        result.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
      }
    }

    // Text search filter
    if (_librarySearchQuery.length >= 2) {
      final query = _librarySearchQuery.toLowerCase();
      result = result
          .where((ex) => (ex.name ?? '').toLowerCase().contains(query))
          .toList();
    }

    // Exclude exercises already in workout
    result = result.where((ex) {
      final name = (ex.name ?? '').toLowerCase();
      return !widget.currentExerciseNames
          .any((n) => n.toLowerCase() == name);
    }).toList();

    setState(() => _filteredExercises = result);
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoadingSuggestions = true;
      _aiSuggestionsLoaded = true;
    });

    try {
      final userId = await ref.read(apiClientProvider).getUserId();
      final repo = ref.read(workoutRepositoryProvider);

      final message =
          'Suggest exercises to add to my ${widget.workoutType} workout';

      final suggestions = await repo.getExerciseSuggestions(
        workoutId: widget.workoutId,
        exercise: WorkoutExercise(
          nameValue: 'Any Exercise',
          muscleGroup: widget.workoutType,
          sets: 3,
          reps: 10,
        ),
        userId: userId!,
        reason: message,
        avoidedExercises: _avoidedExercises,
      );

      // Filter out exercises already in the workout
      final filteredSuggestions = suggestions.where((s) {
        final name = (s['name'] as String?)?.toLowerCase() ?? '';
        return !widget.currentExerciseNames
            .any((existing) => existing.toLowerCase() == name);
      }).toList();

      if (mounted) {
        // Batch pre-fetch images
        final suggestionNames = filteredSuggestions
            .map((s) => s['name'] as String?)
            .whereType<String>()
            .toList();
        if (suggestionNames.isNotEmpty) {
          final apiClient = ref.read(apiClientProvider);
          await ImageUrlCache.batchPreFetch(suggestionNames, apiClient);
        }

        if (mounted) {
          setState(() {
            _suggestions = filteredSuggestions;
            _isLoadingSuggestions = false;
          });
        }
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
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.add_circle, color: AppColors.success),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Exercise',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Find the perfect exercise to add to your workout',
                      style: TextStyle(fontSize: 13, color: textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: textMuted),
              ),
            ],
          ),
        ),

        // Tabs — Library first, AI Suggestions second
        SegmentedTabBar(
          controller: _tabController,
          showIcons: false,
          tabs: const [
            SegmentedTabItem(label: 'Library'),
            SegmentedTabItem(label: 'AI Suggestions'),
          ],
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildLibraryTab(isDark, textPrimary, textMuted),
              _buildSuggestionsTab(textMuted, textPrimary),
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
    );
  }

  // ─── Library Tab ──────────────────────────────────────────────────

  Widget _buildLibraryTab(bool isDark, Color textPrimary, Color textMuted) {
    final cardBackground =
        isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Column(
      children: [
        // Muscle image pill strip
        SizedBox(
          height: 90,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              // "All" pill
              _buildMuscleGroupPill(
                label: 'All',
                isSelected: _selectedMuscle == null,
                isDark: isDark,
                textPrimary: textPrimary,
                textMuted: textMuted,
                onTap: () {
                  setState(() => _selectedMuscle = null);
                  _applyLibraryFilter();
                },
              ),
              ..._libraryMuscleGroups.map((muscle) {
                return _buildMuscleGroupPill(
                  label: muscle,
                  assetPath: muscleGroupAssets[muscle],
                  isSelected: _selectedMuscle == muscle,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  onTap: () {
                    setState(() => _selectedMuscle = muscle);
                    _applyLibraryFilter();
                  },
                );
              }),
            ],
          ),
        ),

        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search exercises...',
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
              _librarySearchQuery = value;
              _applyLibraryFilter();
            },
          ),
        ),

        const SizedBox(height: 4),

        // Exercise list
        Expanded(
          child: _isLoadingLibrary
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.success))
              : _filteredExercises.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off, size: 48, color: textMuted),
                          const SizedBox(height: 12),
                          Text(
                            _librarySearchQuery.isNotEmpty
                                ? 'No exercises found'
                                : 'No exercises available',
                            style: TextStyle(color: textMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredExercises.length,
                      itemBuilder: (context, index) {
                        final ex = _filteredExercises[index];
                        final muscle =
                            ex.targetMuscle ?? ex.bodyPart ?? '';
                        final equip = ex.equipment ?? 'Bodyweight';

                        return _ExerciseOptionCard(
                          name: ex.name ?? 'Exercise',
                          subtitle: muscle,
                          badge: equip,
                          badgeColor: AppColors.purple,
                          onTap: () =>
                              _addExercise(ex.name ?? 'Exercise'),
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

  Widget _buildMuscleGroupPill({
    required String label,
    String? assetPath,
    required bool isSelected,
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required VoidCallback onTap,
  }) {
    final bgColor = isDark ? Colors.grey.shade900 : Colors.grey.shade100;
    final borderColor = isSelected
        ? AppColors.success
        : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 14),
        child: SizedBox(
          width: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bgColor,
                  border: Border.all(
                    color: borderColor,
                    width: isSelected ? 2.5 : 1,
                  ),
                ),
                child: assetPath != null
                    ? Image.asset(
                        assetPath,
                        fit: BoxFit.cover,
                        cacheWidth: 112,
                        cacheHeight: 112,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.fitness_center,
                          size: 22,
                          color: textMuted,
                        ),
                      )
                    : Icon(
                        Icons.fitness_center,
                        size: 22,
                        color: isSelected ? AppColors.success : textMuted,
                      ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? AppColors.success : textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── AI Suggestions Tab ───────────────────────────────────────────

  Widget _buildSuggestionsTab(Color textMuted, Color textPrimary) {
    if (_isLoadingSuggestions || !_aiSuggestionsLoaded) {
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
              onPressed: () {
                _aiSuggestionsLoaded = false;
                _loadSuggestions();
              },
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
        final targetMuscle =
            suggestion['target_muscle'] ?? suggestion['body_part'] ?? '';

        final subtitle = reason.isNotEmpty
            ? reason
            : [targetMuscle, equipment]
                .where((s) => s.isNotEmpty)
                .join(' - ');

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
}

class _ExerciseOptionCard extends ConsumerWidget {
  final String name;
  final String? imageUrl;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final VoidCallback onTap;
  final Color textPrimary;
  final Color textMuted;
  final IconData actionIcon;
  final Color actionColor;

  const _ExerciseOptionCard({
    required this.name,
    this.imageUrl,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.onTap,
    required this.textPrimary,
    required this.textMuted,
    this.actionIcon = Icons.add_circle,
    this.actionColor = AppColors.success,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackground =
        isDark ? AppColors.elevated : AppColorsLight.elevated;
    final glassSurface =
        isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

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
                // Exercise image
                ExerciseImage(
                  exerciseName: name,
                  imageUrl: imageUrl,
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
