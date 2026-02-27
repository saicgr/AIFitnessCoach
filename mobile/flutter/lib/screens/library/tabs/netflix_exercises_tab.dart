import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/ai_split_preset.dart';
import '../../../data/repositories/library_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../providers/library_providers.dart';
import '../../../widgets/glass_sheet.dart';
import '../components/exercise_detail_sheet.dart';
import '../components/ai_split_preset_detail_sheet.dart';
import '../widgets/filter_chip_widget.dart';

/// Group exercises into sections for carousel display
/// Returns full lists - the UI limits what's shown in carousel
Map<String, List<LibraryExercise>> _groupExercisesIntoSections(
  List<LibraryExercise> exercises,
  Map<String, List<LibraryExercise>?> categoryData,
) {
  final Map<String, List<LibraryExercise>> sections = {};

  // Featured - Popular category or first exercises
  final popular = categoryData['Popular'] ?? exercises.take(50).toList();
  if (popular.isNotEmpty) {
    sections['Featured Exercises'] = popular;
  }

  // Upper Body
  final upperBody = exercises.where((e) =>
    e.bodyPart?.toLowerCase() == 'upper body' ||
    e.bodyPart?.toLowerCase() == 'chest' ||
    e.bodyPart?.toLowerCase() == 'back' ||
    e.bodyPart?.toLowerCase() == 'shoulders'
  ).toList();
  if (upperBody.isNotEmpty) {
    sections['Upper Body'] = upperBody;
  }

  // Lower Body
  final lowerBody = exercises.where((e) =>
    e.bodyPart?.toLowerCase() == 'lower body' ||
    e.bodyPart?.toLowerCase() == 'legs' ||
    e.bodyPart?.toLowerCase() == 'glutes'
  ).toList();
  if (lowerBody.isNotEmpty) {
    sections['Lower Body'] = lowerBody;
  }

  // Core & Abs
  final core = exercises.where((e) =>
    e.bodyPart?.toLowerCase() == 'core' ||
    e.bodyPart?.toLowerCase() == 'abs' ||
    e.bodyPart?.toLowerCase() == 'waist'
  ).toList();
  if (core.isNotEmpty) {
    sections['Core & Abs'] = core;
  }

  // Arms
  final arms = exercises.where((e) =>
    e.bodyPart?.toLowerCase() == 'arms' ||
    e.bodyPart?.toLowerCase() == 'biceps' ||
    e.bodyPart?.toLowerCase() == 'triceps' ||
    e.bodyPart?.toLowerCase() == 'forearms'
  ).toList();
  if (arms.isNotEmpty) {
    sections['Arms'] = arms;
  }

  // Cardio
  final cardio = exercises.where((e) =>
    e.bodyPart?.toLowerCase() == 'cardio' ||
    e.equipment.any((eq) => eq.toLowerCase().contains('cardio'))
  ).toList();
  if (cardio.isNotEmpty) {
    sections['Cardio'] = cardio;
  }

  // Beginner Friendly
  final beginner = exercises.where((e) =>
    e.difficulty?.toLowerCase() == 'beginner'
  ).toList();
  if (beginner.isNotEmpty) {
    sections['Beginner Friendly'] = beginner;
  }

  // Advanced
  final advanced = exercises.where((e) =>
    e.difficulty?.toLowerCase() == 'advanced'
  ).toList();
  if (advanced.isNotEmpty) {
    sections['Advanced'] = advanced;
  }

  return sections;
}

/// Exercises tab with search, category chips, featured carousel, and grid layout
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
  String? _selectedCategory;
  String? _expandedSection; // Track which section is showing "View All"

  // Smart search state
  bool _useSmartSearch = true;
  bool _isSmartSearching = false;
  List<SmartSearchExerciseItem> _smartSearchResults = [];
  String? _searchCorrection;
  double? _searchTimeMs;
  Timer? _debounceTimer;
  CancelToken? _cancelToken;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    _cancelToken?.cancel();
    super.dispose();
  }

  void _showExerciseDetail(LibraryExercise exercise) {
    HapticService.selection();
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
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final accentColor = ref.colors(context).accent;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

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
        // Get all categories
        final categories = categoryData.preview.keys.toList();

        // Get exercises based on selection
        List<LibraryExercise> allExercises = [];

        if (_selectedCategory == null) {
          // Show all exercises
          for (final exercises in categoryData.all.values) {
            allExercises.addAll(exercises);
          }
        } else {
          // Show selected category
          allExercises = categoryData.all[_selectedCategory] ?? [];
        }

        // Apply client-side search filter (only when smart search is off)
        if (!_useSmartSearch && searchQuery.isNotEmpty) {
          allExercises = allExercises.where((e) {
            return e.name.toLowerCase().contains(searchQuery) ||
                (e.bodyPart?.toLowerCase().contains(searchQuery) ?? false) ||
                e.equipment.any((eq) => eq.toLowerCase().contains(searchQuery));
          }).toList();
        }

        return Stack(
          children: [
            // Main content
            Column(
              children: [
                // Category filter chips
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      FilterChipWidget(
                        label: 'All',
                        isSelected: _selectedCategory == null,
                        onTap: () {
                          HapticService.light();
                          setState(() => _selectedCategory = null);
                        },
                      ),
                      ...categories.map((category) => FilterChipWidget(
                        label: category,
                        isSelected: _selectedCategory == category,
                        onTap: () {
                          HapticService.light();
                          setState(() => _selectedCategory =
                              _selectedCategory == category ? null : category);
                        },
                      )),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

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
            ),

            // Bottom fade gradient
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  height: bottomPadding + 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        backgroundColor.withValues(alpha: 0),
                        backgroundColor.withValues(alpha: 0.8),
                        backgroundColor,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Samsung-style bottom search bar (always visible with inline text field)
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomPadding + 16,
              child: Center(
                child: _buildSamsungSearchBar(context, isDark, accentColor, textMuted),
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
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

    // Client-side search or category filter: show list view
    if (searchQuery.isNotEmpty || _selectedCategory != null) {
      if (allExercises.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fitness_center, color: textMuted, size: 48),
              const SizedBox(height: 16),
              const Text('No exercises found'),
              if (searchQuery.isNotEmpty || _selectedCategory != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _selectedCategory = null;
                    });
                  },
                  child: const Text('Clear filters'),
                ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
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
      final sections = _groupExercisesIntoSections(allExercises, categoryData.all);
      final muscleGroups = _groupExercisesByMuscle(allExercises);
      final equipmentGroups = _groupExercisesByEquipment(allExercises);

      // Check all possible sources for exercises
      List<LibraryExercise> sectionExercises = sections[_expandedSection] ?? [];
      if (sectionExercises.isEmpty) {
        sectionExercises = muscleGroups[_expandedSection] ?? [];
      }
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
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

    // Gravl-style layout with muscle groups and equipment
    final sections = _groupExercisesIntoSections(allExercises, categoryData.all);
    final muscleGroups = _groupExercisesByMuscle(allExercises);
    final equipmentGroups = _groupExercisesByEquipment(allExercises);

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        // Gravl Splits section at the very top (like Gravl app)
        _buildGravlSplitsSection(isDark).animate().fadeIn(),

        // Featured Exercises carousel (no count in header)
        if (sections['Featured Exercises']?.isNotEmpty ?? false)
          _ExerciseCarouselSection(
            title: 'Featured Exercises',
            exercises: sections['Featured Exercises']!,
            isFeatured: true,
            isDark: isDark,
            showCount: false, // No count in header
            onExerciseTap: _showExerciseDetail,
            onViewAll: () {
              HapticService.light();
              setState(() => _expandedSection = 'Featured Exercises');
            },
          ).animate().fadeIn(),

        // Exercises by muscle section
        _buildMuscleGroupsSection(
          muscleGroups,
          isDark,
          textMuted,
        ).animate().fadeIn(delay: const Duration(milliseconds: 100)),

        // Equipment sections (Weights, Bodyweight, Cardio) - Gravl style
        _buildEquipmentSections(
          equipmentGroups,
          isDark,
          textMuted,
        ).animate().fadeIn(delay: const Duration(milliseconds: 200)),

        // Beginner Friendly
        if (sections['Beginner Friendly']?.isNotEmpty ?? false)
          _ExerciseCarouselSection(
            title: 'Beginner Friendly',
            exercises: sections['Beginner Friendly']!,
            isFeatured: false,
            isDark: isDark,
            showCount: false,
            onExerciseTap: _showExerciseDetail,
            onViewAll: () {
              HapticService.light();
              setState(() => _expandedSection = 'Beginner Friendly');
            },
          ).animate().fadeIn(delay: const Duration(milliseconds: 300)),

        // Advanced
        if (sections['Advanced']?.isNotEmpty ?? false)
          _ExerciseCarouselSection(
            title: 'Advanced',
            exercises: sections['Advanced']!,
            isFeatured: false,
            isDark: isDark,
            showCount: false,
            onExerciseTap: _showExerciseDetail,
            onViewAll: () {
              HapticService.light();
              setState(() => _expandedSection = 'Advanced');
            },
          ).animate().fadeIn(delay: const Duration(milliseconds: 400)),
      ],
    );
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

    // If no muscle groups, don't show section
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
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

        // Horizontal scroll with 3 cards stacked vertically per column
        // Shows peek of NEXT 3 cards on the right
        SizedBox(
          height: 220, // Height for 3 stacked cards (3 * 68 + spacing)
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              // Each column takes 85% of screen width, leaving 15% peek of next column
              final columnWidth = screenWidth * 0.85;

              // Group entries into columns of 3
              final columnCount = (entries.length / 3).ceil();

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16),
                itemCount: columnCount,
                itemBuilder: (context, columnIndex) {
                  final startIdx = columnIndex * 3;
                  final endIdx = (startIdx + 3).clamp(0, entries.length);
                  final columnEntries = entries.sublist(startIdx, endIdx);

                  return SizedBox(
                    width: columnWidth,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: columnEntries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _MuscleAnatomyCard(
                              muscleName: entry.key,
                              exerciseCount: entry.value.length,
                              completedCount: 0,
                              isDark: isDark,
                              onTap: () {
                                HapticService.light();
                                setState(() {
                                  _expandedSection = entry.key;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  /// Build the Equipment sections - Gravl style (Weights, Bodyweight, Cardio)
  /// Each section shows 3 exercises stacked vertically with horizontal scroll showing peek of next 3
  Widget _buildEquipmentSections(
    Map<String, List<LibraryExercise>> equipmentGroups,
    bool isDark,
    Color textMuted,
  ) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: equipmentGroups.entries.map((entry) {
        final equipmentName = entry.key;
        final exercises = entry.value;

        // Group exercises into columns of 3 for horizontal scroll
        final columnCount = (exercises.length / 3).ceil().clamp(1, 10); // Max 10 columns

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header with arrow
            GestureDetector(
              onTap: () {
                HapticService.light();
                setState(() => _expandedSection = equipmentName);
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Text(
                      equipmentName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: textMuted,
                    ),
                  ],
                ),
              ),
            ),

            // Horizontal scroll with 3 exercises stacked vertically per column
            // Shows peek of NEXT 3 exercises on the right
            SizedBox(
              height: 220, // Height for 3 stacked exercise cards
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  // Each column takes 85% of screen width, leaving 15% peek of next column
                  final columnWidth = screenWidth * 0.85;

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 16),
                    itemCount: columnCount,
                    itemBuilder: (context, columnIndex) {
                      final startIdx = columnIndex * 3;
                      final endIdx = (startIdx + 3).clamp(0, exercises.length);
                      final columnExercises = exercises.sublist(startIdx, endIdx);

                      return SizedBox(
                        width: columnWidth,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: columnExercises.map((exercise) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: _EquipmentExerciseCard(
                                  exercise: exercise,
                                  isDark: isDark,
                                  onTap: () => _showExerciseDetail(exercise),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      }).toList(),
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

  /// Samsung-style bottom search bar with inline text field and add button
  Widget _buildSamsungSearchBar(
    BuildContext context,
    bool isDark,
    Color accentColor,
    Color textMuted,
  ) {
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;

    return SizedBox(
      width: MediaQuery.of(context).size.width - 32,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey.shade900.withValues(alpha: 0.85)
                  : Colors.grey.shade200.withValues(alpha: 0.9),
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
          ),
        ),
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

/// Exercise carousel section (Netflix style)
class _ExerciseCarouselSection extends StatelessWidget {
  final String title;
  final List<LibraryExercise> exercises;
  final bool isFeatured;
  final bool isDark;
  final bool showCount;
  final Function(LibraryExercise) onExerciseTap;
  final VoidCallback onViewAll;

  /// Maximum items to show in carousel before "View All"
  static const int _carouselLimit = 10;

  const _ExerciseCarouselSection({
    required this.title,
    required this.exercises,
    required this.isFeatured,
    required this.isDark,
    this.showCount = true,
    required this.onExerciseTap,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentColor = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final cardHeight = isFeatured ? 180.0 : 150.0;
    final showViewAll = exercises.length > _carouselLimit;
    final displayExercises = showViewAll ? exercises.take(_carouselLimit).toList() : exercises;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title with View All
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                if (isFeatured) ...[
                  Icon(Icons.star, color: AppColors.yellow, size: 18),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onViewAll,
                  child: Row(
                    children: [
                      if (showCount) ...[
                        Text(
                          '${exercises.length}',
                          style: TextStyle(
                            fontSize: 13,
                            color: textMuted,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: accentColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Horizontal carousel with visible peek of next cards
          SizedBox(
            height: cardHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                // Card width: show ~2.5 cards so next one peeks (40% each)
                final cardWidth = isFeatured
                    ? screenWidth * 0.65  // Featured: wider cards, show ~1.5
                    : screenWidth * 0.35; // Compact: narrower, show ~2.8

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 16),
                  itemCount: displayExercises.length + (showViewAll ? 1 : 0),
                  itemBuilder: (context, index) {
                    // "View All" card at the end
                    if (showViewAll && index == displayExercises.length) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: _ViewAllCard(
                          count: exercises.length - _carouselLimit,
                          isDark: isDark,
                          onTap: onViewAll,
                          height: cardHeight,
                        ),
                      );
                    }

                    final exercise = displayExercises[index];
                    return SizedBox(
                      width: cardWidth,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: isFeatured
                            ? _FeaturedExerciseCard(
                                exercise: exercise,
                                isDark: isDark,
                                onTap: () => onExerciseTap(exercise),
                              )
                            : _CompactExerciseCard(
                                exercise: exercise,
                                isDark: isDark,
                                onTap: () => onExerciseTap(exercise),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// "View All" card at the end of carousel
class _ViewAllCard extends StatelessWidget {
  final int count;
  final bool isDark;
  final VoidCallback onTap;
  final double height;

  const _ViewAllCard({
    required this.count,
    required this.isDark,
    required this.onTap,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: height,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: accentColor,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '+$count more',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'View All',
              style: TextStyle(
                fontSize: 11,
                color: accentColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact exercise card for non-featured sections
class _CompactExerciseCard extends StatelessWidget {
  final LibraryExercise exercise;
  final bool isDark;
  final VoidCallback onTap;

  const _CompactExerciseCard({
    required this.exercise,
    required this.isDark,
    required this.onTap,
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
        width: 130, // Narrower for peek effect
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      difficultyColor.withValues(alpha: 0.3),
                      difficultyColor.withValues(alpha: 0.5),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.fitness_center,
                        size: 32,
                        color: difficultyColor,
                      ),
                    ),
                    // Body part badge
                    if (exercise.bodyPart != null)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            exercise.bodyPart!,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    exercise.equipment.isNotEmpty
                        ? exercise.equipment.first
                        : 'Bodyweight',
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
          ],
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
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: difficultyColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
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

/// Featured exercise card (horizontal carousel)
class _FeaturedExerciseCard extends StatelessWidget {
  final LibraryExercise exercise;
  final bool isDark;
  final VoidCallback onTap;

  const _FeaturedExerciseCard({
    required this.exercise,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240, // Narrower for peek effect
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade400,
              Colors.grey.shade600,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Category badge
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  exercise.bodyPart ?? 'Exercise',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Exercise info at bottom
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (exercise.equipment.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.fitness_center, size: 12, color: Colors.white70),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            exercise.equipment.join(', '),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Muscle anatomy card with body silhouette and highlighted muscle area
/// Gravl-style design showing muscle group with progress count
/// Full-width card for stacked vertical layout with chevron
class _MuscleAnatomyCard extends StatelessWidget {
  final String muscleName;
  final int exerciseCount;
  final int completedCount;
  final bool isDark;
  final VoidCallback onTap;

  const _MuscleAnatomyCard({
    required this.muscleName,
    required this.exerciseCount,
    required this.completedCount,
    required this.isDark,
    required this.onTap,
  });

  // Get muscle highlight color
  Color _getMuscleColor() {
    switch (muscleName.toLowerCase()) {
      case 'chest':
        return const Color(0xFFEF4444); // Red
      case 'back':
        return const Color(0xFF3B82F6); // Blue
      case 'shoulders':
        return const Color(0xFFA855F7); // Purple
      case 'arms':
        return const Color(0xFF22C55E); // Green
      case 'legs':
        return const Color(0xFFF97316); // Orange
      case 'core':
        return const Color(0xFFEAB308); // Yellow
      case 'glutes':
        return const Color(0xFFEC4899); // Pink
      case 'cardio':
        return const Color(0xFF06B6D4); // Cyan
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final muscleColor = _getMuscleColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 66, // Compact height for 3 cards stacked
        decoration: BoxDecoration(
          color: isDark ? AppColors.elevated : AppColorsLight.elevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            // Left side - Body silhouette with highlighted muscle
            Container(
              width: 56,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Center(
                child: CustomPaint(
                  size: const Size(36, 48),
                  painter: _BodySilhouettePainter(
                    bodyColor: isDark
                        ? Colors.grey.shade700
                        : Colors.grey.shade400,
                    highlightColor: muscleColor,
                    highlightMuscle: muscleName.toLowerCase(),
                  ),
                ),
              ),
            ),

            // Middle - Muscle name and count
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      muscleName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$completedCount/$exerciseCount',
                      style: TextStyle(
                        fontSize: 12,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Right side - Chevron
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.chevron_right,
                color: textMuted,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Equipment exercise card - compact card for equipment section horizontal scroll
class _EquipmentExerciseCard extends StatelessWidget {
  final LibraryExercise exercise;
  final bool isDark;
  final VoidCallback onTap;

  const _EquipmentExerciseCard({
    required this.exercise,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final primaryMuscle = exercise.targetMuscle ?? exercise.bodyPart ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 66, // Same height as muscle cards
        decoration: BoxDecoration(
          color: isDark ? AppColors.elevated : AppColorsLight.elevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            // Left side - Exercise icon
            Container(
              width: 56,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.fitness_center,
                  size: 24,
                  color: textMuted,
                ),
              ),
            ),

            // Middle - Exercise name and muscle
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      exercise.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (primaryMuscle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        primaryMuscle,
                        style: TextStyle(
                          fontSize: 11,
                          color: textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Right side - Chevron
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.chevron_right,
                color: textMuted,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for body silhouette with highlighted muscle
class _BodySilhouettePainter extends CustomPainter {
  final Color bodyColor;
  final Color highlightColor;
  final String highlightMuscle;

  _BodySilhouettePainter({
    required this.bodyColor,
    required this.highlightColor,
    required this.highlightMuscle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;

    final highlightPaint = Paint()
      ..color = highlightColor
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final scale = size.height / 85;

    // Draw body silhouette
    // Head
    canvas.drawCircle(
      Offset(centerX, 8 * scale),
      6 * scale,
      bodyPaint,
    );

    // Neck
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(centerX, 16 * scale),
        width: 6 * scale,
        height: 4 * scale,
      ),
      bodyPaint,
    );

    // Torso (main body)
    final torsoPath = Path();
    torsoPath.moveTo(centerX - 18 * scale, 20 * scale); // Left shoulder
    torsoPath.lineTo(centerX + 18 * scale, 20 * scale); // Right shoulder
    torsoPath.lineTo(centerX + 14 * scale, 50 * scale); // Right hip
    torsoPath.lineTo(centerX - 14 * scale, 50 * scale); // Left hip
    torsoPath.close();
    canvas.drawPath(torsoPath, bodyPaint);

    // Arms
    // Left arm
    canvas.drawRect(
      Rect.fromLTWH(centerX - 26 * scale, 20 * scale, 8 * scale, 25 * scale),
      bodyPaint,
    );
    // Right arm
    canvas.drawRect(
      Rect.fromLTWH(centerX + 18 * scale, 20 * scale, 8 * scale, 25 * scale),
      bodyPaint,
    );

    // Legs
    // Left leg
    canvas.drawRect(
      Rect.fromLTWH(centerX - 12 * scale, 50 * scale, 10 * scale, 30 * scale),
      bodyPaint,
    );
    // Right leg
    canvas.drawRect(
      Rect.fromLTWH(centerX + 2 * scale, 50 * scale, 10 * scale, 30 * scale),
      bodyPaint,
    );

    // Draw highlighted muscle area
    switch (highlightMuscle) {
      case 'chest':
        // Chest area
        final chestPath = Path();
        chestPath.moveTo(centerX - 14 * scale, 22 * scale);
        chestPath.lineTo(centerX + 14 * scale, 22 * scale);
        chestPath.lineTo(centerX + 12 * scale, 35 * scale);
        chestPath.lineTo(centerX - 12 * scale, 35 * scale);
        chestPath.close();
        canvas.drawPath(chestPath, highlightPaint);
        break;

      case 'back':
        // Back area (full torso highlight for back view representation)
        final backPath = Path();
        backPath.moveTo(centerX - 16 * scale, 20 * scale);
        backPath.lineTo(centerX + 16 * scale, 20 * scale);
        backPath.lineTo(centerX + 14 * scale, 48 * scale);
        backPath.lineTo(centerX - 14 * scale, 48 * scale);
        backPath.close();
        canvas.drawPath(backPath, highlightPaint);
        break;

      case 'shoulders':
        // Shoulder areas
        canvas.drawCircle(Offset(centerX - 16 * scale, 22 * scale), 5 * scale, highlightPaint);
        canvas.drawCircle(Offset(centerX + 16 * scale, 22 * scale), 5 * scale, highlightPaint);
        break;

      case 'arms':
        // Arm areas
        canvas.drawRect(
          Rect.fromLTWH(centerX - 26 * scale, 20 * scale, 8 * scale, 25 * scale),
          highlightPaint,
        );
        canvas.drawRect(
          Rect.fromLTWH(centerX + 18 * scale, 20 * scale, 8 * scale, 25 * scale),
          highlightPaint,
        );
        break;

      case 'legs':
        // Leg areas
        canvas.drawRect(
          Rect.fromLTWH(centerX - 12 * scale, 50 * scale, 10 * scale, 30 * scale),
          highlightPaint,
        );
        canvas.drawRect(
          Rect.fromLTWH(centerX + 2 * scale, 50 * scale, 10 * scale, 30 * scale),
          highlightPaint,
        );
        break;

      case 'core':
        // Core/abs area
        final corePath = Path();
        corePath.moveTo(centerX - 10 * scale, 35 * scale);
        corePath.lineTo(centerX + 10 * scale, 35 * scale);
        corePath.lineTo(centerX + 10 * scale, 48 * scale);
        corePath.lineTo(centerX - 10 * scale, 48 * scale);
        corePath.close();
        canvas.drawPath(corePath, highlightPaint);
        break;

      case 'glutes':
        // Glute area (hip/lower back region)
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(centerX, 52 * scale),
            width: 24 * scale,
            height: 10 * scale,
          ),
          highlightPaint,
        );
        break;

      case 'cardio':
        // Heart/cardio area
        canvas.drawCircle(
          Offset(centerX, 30 * scale),
          8 * scale,
          highlightPaint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
