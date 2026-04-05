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

part 'netflix_exercises_tab_part_exercise_list_card.dart';

part 'netflix_exercises_tab_ui.dart';

part 'netflix_exercises_tab_ext.dart';


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
