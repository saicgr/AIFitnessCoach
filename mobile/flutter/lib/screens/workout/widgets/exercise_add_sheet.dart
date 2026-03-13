import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/user_provider.dart';
import '../../../data/local/database.dart';
import '../../../data/local/database_provider.dart';
import '../../../data/models/workout.dart';
import '../../../data/models/exercise.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/repositories/exercise_preferences_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../screens/library/providers/muscle_group_images_provider.dart';
import '../../../services/exercise_selector.dart' as selector;
import '../../../data/services/exercise_library_loader.dart';
import '../../../services/offline_workout_generator.dart';
import '../../../services/workout_templates.dart' show muscleAliases;
import '../../../core/algorithms/exercise_search_ranker.dart';
import '../../../core/providers/favorites_provider.dart';
import '../../../widgets/exercise_image.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/segmented_tab_bar.dart';
import '../../../data/services/image_url_cache.dart';

/// Top-level function for converting cached exercises in an isolate via compute().
List<OfflineExercise> _convertCachedExercises(List<Map<String, dynamic>> rows) {
  return rows.map((ce) {
    List<String>? secondaryMuscles;
    final sm = ce['secondaryMuscles'] as String?;
    if (sm != null) {
      try {
        secondaryMuscles = (jsonDecode(sm) as List).cast<String>();
      } catch (_) {}
    }
    return OfflineExercise(
      id: ce['id'] as String?,
      name: ce['name'] as String?,
      bodyPart: ce['bodyPart'] as String?,
      equipment: ce['equipment'] as String?,
      targetMuscle: ce['targetMuscle'] as String?,
      primaryMuscle: ce['primaryMuscle'] as String?,
      secondaryMuscles: secondaryMuscles,
      difficulty: ce['difficulty'] as String?,
      difficultyNum: ce['difficultyNum'] as int?,
    );
  }).toList();
}

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
  Set<String> _avoidedMuscles = {};

  // Smart search ranking
  ExerciseSearchRanker? _ranker;
  List<RankedExercise> _rankedResults = [];
  bool _isFuzzyResult = false;

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

          // Load avoided muscles
          try {
            final muscles = await prefsRepo.getAvoidedMuscles(userId);
            _avoidedMuscles = muscles
                .where((m) => m.isActive)
                .map((m) => m.muscleGroup.toLowerCase().replaceAll('_', ' '))
                .toSet();
          } catch (e) {
            debugPrint('⚠️ [Add] Could not fetch avoided muscles: $e');
          }
        }
      } catch (e) {
        debugPrint('⚠️ [Add] Could not fetch avoided exercises: $e');
      }

      final db = ref.read(appDatabaseProvider);

      // Ensure the bundled exercise library is seeded (2078 exercises)
      await ExerciseLibraryLoader.seedDatabaseIfNeeded(db);

      // Load full local cache
      final cachedExercises = await db.exerciseLibraryDao.getAllCachedExercises();

      // 3. Convert CachedExercise -> OfflineExercise (in isolate to avoid jank)
      final rows = cachedExercises.map((ce) => <String, dynamic>{
        'id': ce.id,
        'name': ce.name,
        'bodyPart': ce.bodyPart,
        'equipment': ce.equipment,
        'targetMuscle': ce.targetMuscle,
        'primaryMuscle': ce.primaryMuscle,
        'secondaryMuscles': ce.secondaryMuscles,
        'difficulty': ce.difficulty,
        'difficultyNum': ce.difficultyNum,
      }).toList();
      _allExercises = await compute(_convertCachedExercises, rows);

      // 4. Init search ranker with popularity data
      _ranker = await ExerciseSearchRanker.create();
      _ranker!.resolvePopularityForLibrary(_allExercises);

      // 5. Apply rule-based filter
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
        avoidedMuscles: _avoidedMuscles,
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
          avoidedMuscles: _avoidedMuscles,
          fitnessLevel: _userFitnessLevel,
        );
      } else {
        // Generic workout type — show all exercises with full filtering
        result = _allExercises.where((ex) {
          final name = (ex.name ?? '').toLowerCase();
          if (_avoidedExercises.any((a) => a.toLowerCase() == name)) return false;
          // Filter by avoided muscles
          final target = (ex.targetMuscle ?? '').toLowerCase();
          final primary = (ex.primaryMuscle ?? '').toLowerCase();
          if (_avoidedMuscles.contains(target) || _avoidedMuscles.contains(primary)) return false;
          // Filter by equipment
          if (_userEquipment.isNotEmpty) {
            final exEquip = (ex.equipment ?? '').toLowerCase();
            if (exEquip.isNotEmpty &&
                exEquip != 'body weight' &&
                exEquip != 'bodyweight' &&
                !_userEquipment.any((e) => e.toLowerCase() == exEquip)) {
              return false;
            }
          }
          return true;
        }).toList();
        result.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
      }
    }

    // Exclude exercises already in workout
    result = result.where((ex) {
      final name = (ex.name ?? '').toLowerCase();
      return !widget.currentExerciseNames
          .any((n) => n.toLowerCase() == name);
    }).toList();

    // Smart search ranking with multiplicative scoring
    if (_librarySearchQuery.length >= 2 && _ranker != null) {
      final query = _librarySearchQuery.toLowerCase();
      final favorites = ref.read(favoritesProvider).favoriteNames;

      // Try exact matching first
      var matched = result
          .where((ex) => (ex.name ?? '').toLowerCase().contains(query))
          .toList();

      if (matched.isEmpty && query.length >= 3) {
        // Fuzzy fallback
        matched = _ranker!.fuzzySearch(result, query);
        _isFuzzyResult = matched.isNotEmpty;
      } else {
        _isFuzzyResult = false;
      }

      _rankedResults =
          _ranker!.rank(matched, query, favoriteNames: favorites);
      result = _rankedResults.map((r) => r.exercise).toList();
    } else {
      _rankedResults = [];
      _isFuzzyResult = false;
    }

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

      final suggestions = await repo.getExerciseSuggestionsForAdd(
        workoutType: widget.workoutType,
        existingExercises: widget.currentExerciseNames,
        userId: userId!,
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
          height: 96,
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
                  : _buildExerciseList(textPrimary, textMuted),
        ),
      ],
    );
  }

  Widget _buildExerciseList(Color textPrimary, Color textMuted) {
    final hasRecommendations = _rankedResults.any((r) => r.isRecommended);
    final isSearchActive = _librarySearchQuery.length >= 2;

    // No ranking or no recommendations — flat list
    if (!isSearchActive || (!hasRecommendations && !_isFuzzyResult)) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredExercises.length,
        itemBuilder: (context, index) =>
            _buildExerciseCard(_filteredExercises[index], textPrimary, textMuted),
      );
    }

    // Fuzzy fallback results
    if (_isFuzzyResult) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredExercises.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildSectionHeader('Similar exercises', textMuted);
          }
          return _buildExerciseCard(
            _filteredExercises[index - 1], textPrimary, textMuted);
        },
      );
    }

    // Top Picks + More Results split
    final topPicks = _rankedResults.where((r) => r.isRecommended).toList();
    final moreResults = _rankedResults.where((r) => !r.isRecommended).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: topPicks.length + moreResults.length +
          1 + (moreResults.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        // "Top Picks" header
        if (index == 0) {
          return _buildSectionHeader('Top Picks', textMuted, isTopPicks: true);
        }
        // Top picks cards
        if (index <= topPicks.length) {
          return _buildExerciseCard(
            topPicks[index - 1].exercise, textPrimary, textMuted,
            isRecommended: true,
          );
        }
        // "More Results" header
        final moreHeaderIndex = topPicks.length + 1;
        if (index == moreHeaderIndex && moreResults.isNotEmpty) {
          return _buildSectionHeader('More Results', textMuted);
        }
        // More results cards
        final moreIndex = index - moreHeaderIndex - 1;
        if (moreIndex >= 0 && moreIndex < moreResults.length) {
          return _buildExerciseCard(
            moreResults[moreIndex].exercise, textPrimary, textMuted);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSectionHeader(String title, Color textMuted,
      {bool isTopPicks = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isTopPicks ? const Color(0xFFD4A017) : textMuted,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildExerciseCard(
    OfflineExercise ex,
    Color textPrimary,
    Color textMuted, {
    bool isRecommended = false,
  }) {
    final muscle = ex.targetMuscle ?? ex.bodyPart ?? '';
    final equip = ex.equipment ?? 'Bodyweight';

    return _ExerciseOptionCard(
      name: ex.name ?? 'Exercise',
      subtitle: muscle,
      badge: equip,
      badgeColor: AppColors.purple,
      isRecommended: isRecommended,
      onTap: () => context.push(
        '/exercise-detail',
        extra: <String, dynamic>{
          'name': ex.name,
          'body_part': ex.bodyPart,
          'equipment': ex.equipment,
          'primary_muscle': ex.primaryMuscle ?? ex.targetMuscle,
          'secondary_muscles': ex.secondaryMuscles,
          'video_url': ex.videoUrl,
          'image_s3_path': ex.imageS3Path,
          'is_unilateral': ex.isUnilateral,
        },
      ),
      onAdd: () => _addExercise(ex.name ?? 'Exercise'),
      textPrimary: textPrimary,
      textMuted: textMuted,
      actionIcon: Icons.add_circle,
      actionColor: AppColors.success,
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
  final bool isRecommended;
  final VoidCallback onTap;
  final VoidCallback? onAdd;
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
    this.isRecommended = false,
    required this.onTap,
    this.onAdd,
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
      decoration: isRecommended
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: const Border(
                left: BorderSide(
                  color: Color(0xFFD4A017),
                  width: 2.5,
                ),
              ),
            )
          : null,
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

                // Add button
                GestureDetector(
                  onTap: onAdd ?? onTap,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: actionColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      actionIcon,
                      color: actionColor,
                      size: 26,
                    ),
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
