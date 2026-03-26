import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/ai_split_preset.dart';
import '../../../data/repositories/library_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../core/services/posthog_service.dart';
import '../providers/library_providers.dart';
import '../providers/muscle_group_images_provider.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../data/models/custom_exercise.dart';
import '../../../core/providers/custom_exercises_provider.dart';
import '../../../screens/custom_exercises/widgets/create_exercise_sheet.dart';
import '../components/exercise_detail_sheet.dart';
import '../components/ai_split_preset_detail_sheet.dart';
/// Exercises tab with search, muscle group pills, equipment pills, and splits
class NetflixExercisesTab extends ConsumerStatefulWidget {
  const NetflixExercisesTab({super.key});

  @override
  ConsumerState<NetflixExercisesTab> createState() =>
      _NetflixExercisesTabState();
}

class _NetflixExercisesTabState extends ConsumerState<NetflixExercisesTab> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String? _expandedSection; // Track which section is showing "View All"

  // Smart search state
  bool _useSmartSearch = false;
  bool _isSmartSearching = false;
  List<SmartSearchExerciseItem> _smartSearchResults = [];
  String? _searchCorrection;
  double? _searchTimeMs;
  Timer? _debounceTimer;
  CancelToken? _cancelToken;

  // Track whether we've already prefetched exercise images
  bool _imagesPrefetched = false;

  // "All Exercises" pagination: show N exercises at a time for performance
  int _displayedAllExercisesCount = 100;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      final oldCount = _displayedAllExercisesCount;
      final newCount = oldCount + 100;
      if (newCount != oldCount) {
        setState(() {
          _displayedAllExercisesCount = newCount;
        });
      }
    }
  }

  /// Prefetch first batch of exercise images into CachedNetworkImage's
  /// disk + memory cache so they appear instantly.
  void _prefetchImages(List<LibraryExercise> exercises) {
    if (_imagesPrefetched || !mounted) return;
    _imagesPrefetched = true;

    // Prefetch first 30 exercise images (covers initial viewport)
    var count = 0;
    for (final exercise in exercises) {
      if (count >= 30) break;
      final url = exercise.imageUrl;
      if (url != null && url.isNotEmpty) {
        precacheImage(
          CachedNetworkImageProvider(url),
          context,
        );
        count++;
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    _cancelToken?.cancel();
    super.dispose();
  }

  void _showExerciseDetail(LibraryExercise exercise) {
    HapticService.selection();
    ref.read(posthogServiceProvider).capture(
      eventName: 'exercise_viewed',
      properties: <String, Object>{
        'exercise_name': exercise.name,
        if (exercise.id != null) 'exercise_id': exercise.id!,
        if (exercise.targetMuscle != null) 'muscle_group': exercise.targetMuscle!,
      },
    );
    showGlassSheet(
      context: context,
      builder: (context) => ExerciseDetailSheet(exercise: exercise),
    );
  }

  void _onSearchChanged(String query) {
    if (_useSmartSearch) {
      _debounceTimer?.cancel();
      if (query.length < 2) {
        _cancelToken?.cancel();
        setState(() {
          _smartSearchResults = [];
          _isSmartSearching = false;
          _searchCorrection = null;
          _searchTimeMs = null;
        });
        return;
      }
      setState(() => _isSmartSearching = true);
      _debounceTimer = Timer(const Duration(milliseconds: 400), () {
        _performSmartSearch(query);
      });
    } else {
      // Client-side filter triggers immediately via setState
      setState(() {});
    }
  }

  Future<void> _performSmartSearch(String query) async {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    if (query.length < 2) {
      if (mounted) {
        setState(() {
          _smartSearchResults = [];
          _isSmartSearching = false;
          _searchCorrection = null;
          _searchTimeMs = null;
        });
      }
      return;
    }

    if (mounted) setState(() => _isSmartSearching = true);

    try {
      final libraryRepo = ref.read(libraryRepositoryProvider);
      final smartResponse = await libraryRepo.smartSearchExercises(
        query: query,
        cancelToken: _cancelToken,
      );

      if (mounted) {
        setState(() {
          _smartSearchResults = smartResponse.results;
          _isSmartSearching = false;
          _searchCorrection = smartResponse.correction;
          _searchTimeMs = smartResponse.searchTimeMs;
        });
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) return;
      if (mounted) {
        setState(() {
          _smartSearchResults = [];
          _isSmartSearching = false;
          _searchCorrection = null;
          _searchTimeMs = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final accentColor = ref.colors(context).accent;

    final categoryExercisesAsync = ref.watch(categoryExercisesProvider);
    final searchQuery = _searchController.text.toLowerCase();

    return categoryExercisesAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: cyan),
      ),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: textMuted),
            const SizedBox(height: 16),
            Text('Failed to load exercises', style: TextStyle(color: textMuted)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(categoryExercisesProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (categoryData) {
        // Prefetch exercise images into cache as soon as data is available
        if (!_imagesPrefetched) {
          final allForPrefetch = <LibraryExercise>[];
          for (final exercises in categoryData.all.values) {
            allForPrefetch.addAll(exercises);
          }
          _prefetchImages(allForPrefetch);
        }

        // Always collect all exercises
        List<LibraryExercise> allExercises = [];
        for (final exercises in categoryData.all.values) {
          allExercises.addAll(exercises);
        }

        // Apply client-side search filter with relevance ranking
        if (!_useSmartSearch && searchQuery.isNotEmpty) {
          allExercises = _rankSearchResults(allExercises, searchQuery);
        }

        return Column(
          children: [
            // Search bar (inline, always visible at top)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildSamsungSearchBar(context, isDark, accentColor, textMuted),
            ),

            // Exercises content
            Expanded(
              child: _buildExercisesContent(
                allExercises,
                categoryData,
                searchQuery,
                isDark,
                textMuted,
              ),
            ),
          ],
        );
      },
    );
  }

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

  /// Rank search results by relevance:
  /// 1. Exact name match (e.g. "Push Up" for query "push up")
  /// 2. Name starts with query (e.g. "Push Up Plus" for query "push")
  /// 3. Word in name starts with query (e.g. "Diamond Push Up" for query "push")
  /// 4. Name contains query anywhere
  /// 5. Body part or equipment match
  List<LibraryExercise> _rankSearchResults(
    List<LibraryExercise> exercises,
    String query,
  ) {
    final scored = <(LibraryExercise, int)>[];
    final queryWords = query.split(RegExp(r'\s+'));

    for (final e in exercises) {
      final nameLower = e.name.toLowerCase();
      final bodyPart = (e.bodyPart ?? '').toLowerCase();
      final equipment = e.equipment.map((eq) => eq.toLowerCase()).toList();

      int score;

      // Exact match
      if (nameLower == query) {
        score = 100;
      }
      // Name starts with query
      else if (nameLower.startsWith(query)) {
        // Shorter names rank higher (closer to exact match)
        score = 90 - (nameLower.length - query.length).clamp(0, 30);
      }
      // A word in the name starts with query
      else if (nameLower.split(RegExp(r'[\s\-]+')).any((w) => w.startsWith(query))) {
        score = 50 - (nameLower.length - query.length).clamp(0, 20);
      }
      // All query words appear in name (multi-word search)
      else if (queryWords.length > 1 && queryWords.every((w) => nameLower.contains(w))) {
        score = 40;
      }
      // Name contains query substring
      else if (nameLower.contains(query)) {
        score = 30 - (nameLower.indexOf(query)).clamp(0, 15);
      }
      // Body part match
      else if (bodyPart.contains(query)) {
        score = 10;
      }
      // Equipment match
      else if (equipment.any((eq) => eq.contains(query))) {
        score = 5;
      }
      // No match
      else {
        continue;
      }

      scored.add((e, score));
    }

    // Sort by score descending, then alphabetically for ties
    scored.sort((a, b) {
      final cmp = b.$2.compareTo(a.$2);
      if (cmp != 0) return cmp;
      return a.$1.name.compareTo(b.$1.name);
    });

    return scored.map((s) => s.$1).toList();
  }

  /// Group exercises by muscle for the "Exercises by muscle" section
  /// Uses targetMuscle field which contains actual muscle names like "Hamstrings", "Pectoralis major"
  Map<String, List<LibraryExercise>> _groupExercisesByMuscle(List<LibraryExercise> exercises) {
    final Map<String, List<LibraryExercise>> muscleGroups = {};

    // Define muscle groups in order
    const muscleOrder = ['Chest', 'Back', 'Shoulders', 'Arms', 'Legs', 'Core', 'Glutes'];

    for (final muscle in muscleOrder) {
      muscleGroups[muscle] = [];
    }

    for (final exercise in exercises) {
      // Use targetMuscle (e.g., "Hamstrings (Biceps Femoris...)") as primary source
      // Fall back to bodyPart if targetMuscle is empty
      final muscle = (exercise.targetMuscle ?? exercise.bodyPart ?? '').toLowerCase();

      // Chest muscles
      if (muscle.contains('chest') || muscle.contains('pectoralis') || muscle.contains('pec')) {
        muscleGroups['Chest']!.add(exercise);
      }
      // Back muscles
      else if (muscle.contains('back') || muscle.contains('lat') || muscle.contains('rhomboid') ||
               muscle.contains('trapezius') || muscle.contains('erector') || muscle.contains('rear delt')) {
        muscleGroups['Back']!.add(exercise);
      }
      // Shoulder muscles
      else if (muscle.contains('shoulder') || muscle.contains('deltoid') || muscle.contains('delt')) {
        muscleGroups['Shoulders']!.add(exercise);
      }
      // Arm muscles
      else if (muscle.contains('bicep') || muscle.contains('tricep') || muscle.contains('forearm') ||
               muscle.contains('brachii') || muscle.contains('brachialis')) {
        muscleGroups['Arms']!.add(exercise);
      }
      // Leg muscles
      else if (muscle.contains('leg') || muscle.contains('quad') || muscle.contains('hamstring') ||
               muscle.contains('calf') || muscle.contains('calves') || muscle.contains('thigh') ||
               muscle.contains('femor') || muscle.contains('gastrocnemius') || muscle.contains('soleus') ||
               muscle.contains('tibialis') || muscle.contains('adductor') || muscle.contains('abductor')) {
        muscleGroups['Legs']!.add(exercise);
      }
      // Core muscles
      else if (muscle.contains('core') || muscle.contains('abs') || muscle.contains('abdominal') ||
               muscle.contains('oblique') || muscle.contains('rectus') || muscle.contains('waist') ||
               muscle.contains('transverse')) {
        muscleGroups['Core']!.add(exercise);
      }
      // Glute muscles
      else if (muscle.contains('glute') || muscle.contains('gluteus') || muscle.contains('hip')) {
        muscleGroups['Glutes']!.add(exercise);
      }
    }

    // Remove empty groups
    muscleGroups.removeWhere((key, value) => value.isEmpty);

    return muscleGroups;
  }

  /// Group exercises by equipment type
  /// Checks equipment field, exercise name, and bodyPart for categorization
  Map<String, List<LibraryExercise>> _groupExercisesByEquipment(List<LibraryExercise> exercises) {
    final Map<String, List<LibraryExercise>> equipmentGroups = {
      'Weights': [],
      'Bodyweight': [],
      'Machines': [],
      'Cardio': [],
    };

    for (final exercise in exercises) {
      // Combine equipment list, exercise name, and bodyPart for better matching
      final equipmentList = exercise.equipment.map((e) => e.toLowerCase()).toList();
      final exerciseName = exercise.name.toLowerCase();
      final bodyPart = (exercise.bodyPart ?? '').toLowerCase();

      // Create combined search string
      final searchText = [...equipmentList, exerciseName, bodyPart].join(' ');

      // Cardio equipment
      if (searchText.contains('treadmill') || searchText.contains('bike') ||
          searchText.contains('elliptical') || searchText.contains('rowing') ||
          searchText.contains('cardio') || searchText.contains('airbike') ||
          searchText.contains('stair') || searchText.contains('run') ||
          searchText.contains('jog') || searchText.contains('sprint')) {
        equipmentGroups['Cardio']!.add(exercise);
      }
      // Machine exercises
      else if (searchText.contains('machine') || searchText.contains('cable') ||
               searchText.contains('smith') || searchText.contains('leg press') ||
               searchText.contains('lat pulldown') || searchText.contains('chest press') ||
               searchText.contains('seated row') || searchText.contains('hack squat') ||
               searchText.contains('pec deck') || searchText.contains('leg curl') ||
               searchText.contains('leg extension')) {
        equipmentGroups['Machines']!.add(exercise);
      }
      // Free weights
      else if (searchText.contains('barbell') || searchText.contains('dumbbell') ||
               searchText.contains('kettlebell') || searchText.contains('weight') ||
               searchText.contains('ez bar') || searchText.contains('ez-bar') ||
               searchText.contains('plate') || searchText.contains('olympic')) {
        equipmentGroups['Weights']!.add(exercise);
      }
      // Bodyweight (includes "body weight" spelled out)
      else if (searchText.contains('body weight') || searchText.contains('bodyweight') ||
               equipmentList.isEmpty || equipmentList.contains('none') ||
               searchText.contains('push up') || searchText.contains('push-up') ||
               searchText.contains('pull up') || searchText.contains('pull-up') ||
               searchText.contains('plank') || searchText.contains('squat') ||
               searchText.contains('lunge') || searchText.contains('crunch') ||
               searchText.contains('sit up') || searchText.contains('sit-up')) {
        equipmentGroups['Bodyweight']!.add(exercise);
      }
      // Default to Weights for unmatched
      else {
        equipmentGroups['Weights']!.add(exercise);
      }
    }

    // Remove empty groups
    equipmentGroups.removeWhere((key, value) => value.isEmpty);

    return equipmentGroups;
  }

  /// Build the "Exercises by muscle" section - Gravl style with muscle anatomy images
  /// Shows 3 cards stacked vertically with horizontal scroll showing peek of NEXT 3 cards
  Widget _buildMuscleGroupsSection(
    Map<String, List<LibraryExercise>> muscleGroups,
    bool isDark,
    Color textMuted,
  ) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final entries = muscleGroups.entries.toList();

    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Exercises by muscle',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ),

        // Horizontal scroll of circular muscle pills
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final assetPath = muscleGroupAssets[entry.key];
              return _MuscleGroupPill(
                muscleName: entry.key,
                exerciseCount: entry.value.length,
                assetPath: assetPath,
                isDark: isDark,
                onTap: () {
                  HapticService.light();
                  setState(() {
                    _expandedSection = entry.key;
                  });
                },
              );
            },
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  /// Build Equipment pills section — matches muscle group pill style
  Widget _buildEquipmentPillsSection(
    Map<String, List<LibraryExercise>> equipmentGroups,
    bool isDark,
    Color textMuted,
  ) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final entries = equipmentGroups.entries.toList();

    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Equipment',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ),

        // Horizontal scroll of circular equipment pills
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _EquipmentPill(
                equipmentName: entry.key,
                exerciseCount: entry.value.length,
                isDark: isDark,
                onTap: () {
                  HapticService.light();
                  setState(() {
                    _expandedSection = entry.key;
                  });
                },
              );
            },
          ),
        ),

        const SizedBox(height: 8),
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

  /// Inline search bar with text field and AI toggle
  Widget _buildSamsungSearchBar(
    BuildContext context,
    bool isDark,
    Color accentColor,
    Color textMuted,
  ) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.shade900
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: isDark ? Colors.white70 : Colors.black54,
            size: 22,
          ),
          const SizedBox(width: 10),
          // Inline search field (always visible)
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              cursorColor: accentColor,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: _useSmartSearch
                    ? 'AI search (e.g. "something for chest")'
                    : 'Search exercises...',
                hintStyle: TextStyle(
                  color: textMuted.withValues(alpha: 0.6),
                  fontSize: 15,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          // Clear button when searching
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                HapticService.light();
                _cancelToken?.cancel();
                _debounceTimer?.cancel();
                setState(() {
                  _searchController.clear();
                  _smartSearchResults = [];
                  _isSmartSearching = false;
                  _searchCorrection = null;
                  _searchTimeMs = null;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.close_rounded,
                  color: textMuted,
                  size: 18,
                ),
              ),
            ),
          // AI toggle button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _useSmartSearch = !_useSmartSearch;
                _searchCorrection = null;
                _searchTimeMs = null;
                _smartSearchResults = [];
                _isSmartSearching = false;
              });
              // Re-trigger search with new mode
              final query = _searchController.text;
              if (query.length >= 2) {
                if (_useSmartSearch) {
                  _debounceTimer?.cancel();
                  setState(() => _isSmartSearching = true);
                  _debounceTimer = Timer(const Duration(milliseconds: 100), () {
                    _performSmartSearch(query);
                  });
                } else {
                  setState(() {}); // Triggers client-side rebuild
                }
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _useSmartSearch
                      ? (isDark ? AppColors.cyan : AppColorsLight.cyan).withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: _useSmartSearch
                      ? (isDark ? AppColors.cyan : AppColorsLight.cyan)
                      : textMuted,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCustomExercise(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
            Icon(
              Icons.construction_rounded,
              size: 48,
              color: orange,
            ),
            const SizedBox(height: 16),
            Text(
              'Custom Exercises',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your own exercises with custom reps, sets, and instructions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// Exercise list card (for search results)
class _ExerciseListCard extends StatelessWidget {
  final LibraryExercise exercise;
  final bool isDark;
  final VoidCallback onTap;
  final bool isAiMatch;

  const _ExerciseListCard({
    required this.exercise,
    required this.isDark,
    required this.onTap,
    this.isAiMatch = false,
  });

  Color _getDifficultyColor(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'beginner':
        return AppColors.green;
      case 'intermediate':
        return AppColors.yellow;
      case 'advanced':
        return AppColors.orange;
      default:
        return AppColors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final difficultyColor = _getDifficultyColor(exercise.difficulty);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            // Exercise image or fallback icon
            Container(
              width: 48,
              height: 48,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: difficultyColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: exercise.imageUrl != null && exercise.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: exercise.imageUrl!,
                      fit: BoxFit.cover,
                      width: 48,
                      height: 48,
                      memCacheWidth: 96,
                      memCacheHeight: 96,
                      placeholder: (_, __) => Icon(
                        Icons.fitness_center,
                        color: difficultyColor,
                        size: 24,
                      ),
                      errorWidget: (_, __, ___) => Icon(
                        Icons.fitness_center,
                        color: difficultyColor,
                        size: 24,
                      ),
                    )
                  : Icon(
                      Icons.fitness_center,
                      color: difficultyColor,
                      size: 24,
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
                      Expanded(
                        child: Text(
                          exercise.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isAiMatch) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.cyan.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'AI',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.cyan,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (exercise.bodyPart != null) ...[
                        Text(
                          exercise.bodyPart!,
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                        Text(' • ', style: TextStyle(color: textMuted)),
                      ],
                      Text(
                        exercise.equipment.isNotEmpty
                            ? exercise.equipment.first
                            : 'Bodyweight',
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(
              Icons.chevron_right,
              color: textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular muscle group pill — image on top, label below.
class _MuscleGroupPill extends StatelessWidget {
  final String muscleName;
  final int exerciseCount;
  final String? assetPath;
  final bool isDark;
  final VoidCallback onTap;

  const _MuscleGroupPill({
    required this.muscleName,
    required this.exerciseCount,
    this.assetPath,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final bgColor = isDark ? Colors.grey.shade900 : Colors.grey.shade100;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: SizedBox(
          width: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular image
              Container(
                width: 60,
                height: 60,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bgColor,
                  border: Border.all(
                    color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                  ),
                ),
                child: assetPath != null
                    ? Image.asset(
                        assetPath!,
                        fit: BoxFit.cover,
                        cacheWidth: 120,
                        cacheHeight: 120,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.fitness_center,
                          size: 24,
                          color: textMuted,
                        ),
                      )
                    : Icon(
                        Icons.fitness_center,
                        size: 24,
                        color: textMuted,
                      ),
              ),
              const SizedBox(height: 6),
              // Label
              Text(
                muscleName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              Text(
                '$exerciseCount',
                style: TextStyle(
                  fontSize: 10,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular equipment pill — icon on top, label below. Matches _MuscleGroupPill style.
class _EquipmentPill extends StatelessWidget {
  final String equipmentName;
  final int exerciseCount;
  final bool isDark;
  final VoidCallback onTap;

  const _EquipmentPill({
    required this.equipmentName,
    required this.exerciseCount,
    required this.isDark,
    required this.onTap,
  });

  IconData _getEquipmentIcon(String name) {
    switch (name) {
      case 'Weights':
        return Icons.fitness_center;
      case 'Bodyweight':
        return Icons.accessibility_new;
      case 'Machines':
        return Icons.precision_manufacturing;
      case 'Cardio':
        return Icons.directions_run;
      default:
        return Icons.fitness_center;
    }
  }

  Color _getEquipmentColor(String name, bool isDark) {
    switch (name) {
      case 'Weights':
        return isDark ? AppColors.orange : AppColorsLight.orange;
      case 'Bodyweight':
        return isDark ? AppColors.green : AppColorsLight.green;
      case 'Machines':
        return isDark ? AppColors.cyan : AppColorsLight.cyan;
      case 'Cardio':
        return AppColors.yellow;
      default:
        return isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final iconColor = _getEquipmentColor(equipmentName, isDark);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: SizedBox(
          width: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(alpha: 0.15),
                  border: Border.all(
                    color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                  ),
                ),
                child: Icon(
                  _getEquipmentIcon(equipmentName),
                  size: 26,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 6),
              // Label
              Text(
                equipmentName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              Text(
                '$exerciseCount',
                style: TextStyle(
                  fontSize: 10,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card widget for Gravl Split Preset
class _GravlSplitCard extends StatelessWidget {
  final AISplitPreset preset;
  final bool isDark;
  final VoidCallback onTap;

  const _GravlSplitCard({
    required this.preset,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;

    // Get gradient colors based on preset category
    final gradientColors = _getGradientColors(preset.category, isDark);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140, // Smaller width
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                _getPresetIcon(preset.id),
                size: 100,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AI badge if applicable
                  if (preset.isAIPowered) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 10,
                            color: Colors.white,
                          ),
                          SizedBox(width: 3),
                          Text(
                            'AI',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  const Spacer(),

                  // Preset name
                  Text(
                    preset.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  // Days and duration
                  Text(
                    preset.daysPerWeek == 0
                        ? 'Flexible • ${preset.duration}'
                        : '${preset.daysPerWeek} days/week • ${preset.duration}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Difficulty
                  Text(
                    preset.difficulty.first,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getGradientColors(String category, bool isDark) {
    switch (category) {
      case 'ai_powered':
        return [
          const Color(0xFFEA580C), // Orange
          const Color(0xFFDC2626), // Red
        ];
      case 'specialty':
        return [
          const Color(0xFF7C3AED), // Purple
          const Color(0xFF4F46E5), // Indigo
        ];
      case 'classic':
      default:
        return isDark
            ? [
                const Color(0xFF374151), // Gray 700
                const Color(0xFF1F2937), // Gray 800
              ]
            : [
                const Color(0xFF4B5563), // Gray 600
                const Color(0xFF374151), // Gray 700
              ];
    }
  }

  IconData _getPresetIcon(String id) {
    switch (id) {
      case 'hell_week':
        return Icons.local_fire_department;
      case 'ai_adaptive':
        return Icons.psychology;
      case 'quick_gains':
        return Icons.bolt;
      case 'home_warrior':
        return Icons.home;
      case 'deload_recover':
        return Icons.spa;
      case 'strength_builder':
        return Icons.fitness_center;
      case 'mood_based':
        return Icons.emoji_emotions;
      case 'hybrid_athlete':
        return Icons.directions_run;
      case 'weak_point_destroyer':
        return Icons.gps_fixed;
      case 'senior_strength':
        return Icons.accessibility_new;
      case 'comeback_program':
        return Icons.replay;
      case 'arnold_split':
        return Icons.star;
      case 'ppl_6day':
      case 'ppl_3day':
        return Icons.view_column;
      case 'upper_lower':
        return Icons.swap_vert;
      case 'full_body':
      case 'full_body_minimal':
        return Icons.accessibility_new;
      default:
        return Icons.fitness_center;
    }
  }
}

/// Compact horizontal chip for custom exercises in the library
class _CustomExerciseChip extends StatelessWidget {
  final CustomExercise exercise;
  final bool isDark;

  const _CustomExerciseChip({required this.exercise, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.07);

    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Exercise icon based on equipment
          Icon(
            _equipmentIcon(exercise.equipment),
            size: 22,
            color: isDark ? AppColors.cyan : AppColorsLight.cyan,
          ),
          const SizedBox(height: 8),
          Text(
            exercise.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            exercise.primaryMuscle,
            style: TextStyle(
              fontSize: 11,
              color: textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  IconData _equipmentIcon(String equipment) {
    switch (equipment.toLowerCase()) {
      case 'barbell': return Icons.fitness_center;
      case 'dumbbell': return Icons.fitness_center;
      case 'cable': return Icons.swap_vert;
      case 'machine': return Icons.precision_manufacturing;
      case 'bodyweight': return Icons.accessibility_new;
      case 'kettlebell': return Icons.sports_martial_arts;
      case 'resistance band': return Icons.all_inclusive;
      default: return Icons.fitness_center;
    }
  }
}
