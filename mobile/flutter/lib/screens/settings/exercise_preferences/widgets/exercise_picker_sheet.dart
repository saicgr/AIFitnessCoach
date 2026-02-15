import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/exercise.dart';
import '../../../../data/repositories/library_repository.dart';
import '../../../../widgets/exercise_image.dart';
import '../../../../widgets/glass_sheet.dart';
import '../../../library/components/exercise_detail_sheet.dart';

/// The type of exercise preference being selected
enum ExercisePickerType {
  favorite,
  staple,
  queue,
  avoided,
}

/// Result from the exercise picker
class ExercisePickerResult {
  final String exerciseName;
  final String? exerciseId;
  final String? muscleGroup;
  final String? reason; // For staples or avoided
  final bool isTemporary; // For avoided
  final DateTime? endDate; // For avoided
  final String? targetMuscleGroup; // For queue

  const ExercisePickerResult({
    required this.exerciseName,
    this.exerciseId,
    this.muscleGroup,
    this.reason,
    this.isTemporary = false,
    this.endDate,
    this.targetMuscleGroup,
  });
}

/// Shows exercise picker sheet and returns the selected exercise with options
Future<ExercisePickerResult?> showExercisePickerSheet(
  BuildContext context,
  WidgetRef ref, {
  required ExercisePickerType type,
  Set<String>? excludeExercises,
}) async {
  return await showGlassSheet<ExercisePickerResult>(
    context: context,
    builder: (context) => GlassSheet(child: _ExercisePickerSheet(
      type: type,
      excludeExercises: excludeExercises ?? {},
    )),
  );
}

class _ExercisePickerSheet extends ConsumerStatefulWidget {
  final ExercisePickerType type;
  final Set<String> excludeExercises;

  const _ExercisePickerSheet({
    required this.type,
    required this.excludeExercises,
  });

  @override
  ConsumerState<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<_ExercisePickerSheet> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _isSearching = false;
  List<LibraryExerciseItem> _searchResults = [];
  String _searchQuery = '';

  // Debounce + cancel
  Timer? _debounceTimer;
  CancelToken? _cancelToken;

  // Filters
  bool _showFilters = false;
  Map<String, List<FilterOption>> _filterOptions = {};
  final Set<String> _selectedBodyParts = {};
  final Set<String> _selectedEquipment = {};
  final Set<String> _selectedExerciseTypes = {};

  // Smart search state
  bool _useSmartSearch = true;
  String? _searchCorrection;
  double? _searchTimeMs;

  int get _activeFilterCount =>
      _selectedBodyParts.length +
      _selectedEquipment.length +
      _selectedExerciseTypes.length;

  bool get _hasActiveFilters => _activeFilterCount > 0;

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<void> _loadFilterOptions() async {
    final libraryRepo = ref.read(libraryRepositoryProvider);
    final options = await libraryRepo.getFilterOptions();
    if (mounted) {
      setState(() => _filterOptions = options);
    }
  }

  String get _title {
    switch (widget.type) {
      case ExercisePickerType.favorite:
        return 'Add Favorite Exercise';
      case ExercisePickerType.staple:
        return 'Add Staple Exercise';
      case ExercisePickerType.queue:
        return 'Add to Exercise Queue';
      case ExercisePickerType.avoided:
        return 'Add Exercise to Avoid';
    }
  }

  String get _subtitle {
    switch (widget.type) {
      case ExercisePickerType.favorite:
        return 'Search for exercises to add to your favorites';
      case ExercisePickerType.staple:
        return 'Search for core lifts to lock in your workouts';
      case ExercisePickerType.queue:
        return 'Search for exercises to include in your next workout';
      case ExercisePickerType.avoided:
        return 'Search for exercises you want to skip';
    }
  }

  Color get _accentColor {
    switch (widget.type) {
      case ExercisePickerType.favorite:
        return AppColors.error; // Heart color
      case ExercisePickerType.staple:
        return AppColors.cyan;
      case ExercisePickerType.queue:
        return AppColors.cyan;
      case ExercisePickerType.avoided:
        return AppColors.orange;
    }
  }

  /// Icon for the header badge
  IconData get _icon {
    switch (widget.type) {
      case ExercisePickerType.favorite:
        return Icons.favorite_border;
      case ExercisePickerType.staple:
        return Icons.push_pin_outlined;
      case ExercisePickerType.queue:
        return Icons.add_circle_outline;
      case ExercisePickerType.avoided:
        return Icons.block_outlined;
    }
  }

  /// Icon shown on each exercise card's action button
  IconData get _actionIcon {
    switch (widget.type) {
      case ExercisePickerType.favorite:
        return Icons.favorite_border;
      case ExercisePickerType.staple:
        return Icons.lock_open;
      case ExercisePickerType.queue:
        return Icons.add_circle_outline;
      case ExercisePickerType.avoided:
        return Icons.block_outlined;
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    setState(() => _searchQuery = query);

    if (query.length < 2 && !_hasActiveFilters) {
      _cancelToken?.cancel();
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _performSearch();
    });
  }

  Future<void> _performSearch() async {
    // Cancel any in-flight request
    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    final query = _searchQuery;
    final hasQuery = query.length >= 2;
    final hasFilters = _hasActiveFilters;

    if (!hasQuery && !hasFilters) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
          _searchCorrection = null;
          _searchTimeMs = null;
        });
      }
      return;
    }

    if (mounted) setState(() => _isSearching = true);

    try {
      final libraryRepo = ref.read(libraryRepositoryProvider);

      // Use smart search when enabled and we have a text query
      if (_useSmartSearch && hasQuery) {
        final smartResponse = await libraryRepo.smartSearchExercises(
          query: query,
          equipment: _selectedEquipment.isNotEmpty
              ? _selectedEquipment.join(',')
              : null,
          bodyParts: _selectedBodyParts.isNotEmpty
              ? _selectedBodyParts.join(',')
              : null,
          cancelToken: _cancelToken,
        );

        // Filter out already added exercises
        final filtered = smartResponse.results.where((e) {
          return !widget.excludeExercises
              .any((name) => name.toLowerCase() == e.name.toLowerCase());
        }).toList();

        if (mounted) {
          setState(() {
            _searchResults = filtered;
            _isSearching = false;
            _searchCorrection = smartResponse.correction;
            _searchTimeMs = smartResponse.searchTimeMs;
          });
        }
      } else {
        // Regular fuzzy search (filter-only or smart search disabled)
        final results = await libraryRepo.searchExercises(
          query: hasQuery ? query : null,
          bodyPart: _selectedBodyParts.isNotEmpty
              ? _selectedBodyParts.join(',')
              : null,
          equipment: _selectedEquipment.isNotEmpty
              ? _selectedEquipment.join(',')
              : null,
          exerciseTypes: _selectedExerciseTypes.isNotEmpty
              ? _selectedExerciseTypes.join(',')
              : null,
          cancelToken: _cancelToken,
        );

        // Filter out already added exercises
        final filtered = results.where((e) {
          return !widget.excludeExercises
              .any((name) => name.toLowerCase() == e.name.toLowerCase());
        }).toList();

        if (mounted) {
          setState(() {
            _searchResults = filtered;
            _isSearching = false;
            _searchCorrection = null;
            _searchTimeMs = null;
          });
        }
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) return;
      debugPrint('Error searching exercises: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
          _searchCorrection = null;
          _searchTimeMs = null;
        });
      }
    }
  }

  void _toggleFilter(Set<String> filterSet, String value) {
    HapticFeedback.selectionClick();
    setState(() {
      if (filterSet.contains(value)) {
        filterSet.remove(value);
      } else {
        filterSet.add(value);
      }
    });
    // Trigger search with updated filters
    _debounceTimer?.cancel();
    setState(() => _isSearching = true);
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      _performSearch();
    });
  }

  void _removeFilter(String category, String value) {
    HapticFeedback.selectionClick();
    setState(() {
      switch (category) {
        case 'body_parts':
          _selectedBodyParts.remove(value);
        case 'equipment':
          _selectedEquipment.remove(value);
        case 'exercise_types':
          _selectedExerciseTypes.remove(value);
      }
    });
    _debounceTimer?.cancel();
    setState(() => _isSearching = true);
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      _performSearch();
    });
  }

  void _clearAllFilters() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedBodyParts.clear();
      _selectedEquipment.clear();
      _selectedExerciseTypes.clear();
      _showFilters = false;
    });
    if (_searchQuery.length >= 2) {
      _debounceTimer?.cancel();
      setState(() => _isSearching = true);
      _debounceTimer = Timer(const Duration(milliseconds: 200), () {
        _performSearch();
      });
    } else {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  void _selectExercise(LibraryExerciseItem exercise) {
    HapticFeedback.lightImpact();
    Navigator.pop(
      context,
      ExercisePickerResult(
        exerciseName: exercise.name,
        exerciseId: exercise.id,
        muscleGroup: exercise.targetMuscle ?? exercise.bodyPart,
        targetMuscleGroup: exercise.targetMuscle ?? exercise.bodyPart,
        reason: widget.type == ExercisePickerType.staple ? 'staple' : null,
      ),
    );
  }

  void _openDetailSheet(LibraryExerciseItem exercise) {
    final libraryExercise = LibraryExercise(
      id: exercise.id,
      nameValue: exercise.name,
      bodyPart: exercise.bodyPart,
      equipmentValue: exercise.equipment,
      targetMuscle: exercise.targetMuscle,
      gifUrl: exercise.gifUrl,
      videoUrl: exercise.videoUrl,
      imageUrl: exercise.imageUrl,
      difficultyLevelValue: exercise.difficulty,
      instructionsValue: exercise.instructions,
    );

    showGlassSheet(
      context: context,
      builder: (context) => ExerciseDetailSheet(exercise: libraryExercise),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackground = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final showResults = _searchQuery.length >= 2 || _hasActiveFilters;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_icon, color: _accentColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _title,
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
                _subtitle,
                style: TextStyle(fontSize: 14, color: textSecondary),
              ),
            ],
          ),
        ),

        // Active filter chips
        if (_hasActiveFilters)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Clear all button
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text('Clear all', style: TextStyle(fontSize: 12, color: textMuted)),
                    avatar: Icon(Icons.clear_all, size: 16, color: textMuted),
                    onPressed: _clearAllFilters,
                    backgroundColor: cardBackground,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                ..._selectedBodyParts.map((bp) => _buildActiveChip(bp, 'body_parts', textPrimary, cardBackground)),
                ..._selectedEquipment.map((eq) => _buildActiveChip(eq, 'equipment', textPrimary, cardBackground)),
                ..._selectedExerciseTypes.map((et) => _buildActiveChip(et, 'exercise_types', textPrimary, cardBackground)),
              ],
            ),
          ),

        if (_hasActiveFilters) const SizedBox(height: 8),

        // Spelling correction banner
        if (_searchCorrection != null && showResults)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.auto_fix_high, size: 14, color: AppColors.cyan),
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

        // Results area
        Expanded(
          child: _isSearching
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: _accentColor),
                      const SizedBox(height: 16),
                      Text('Searching...', style: TextStyle(color: textMuted)),
                    ],
                  ),
                )
              : !showResults
                  ? _buildEmptyState(textMuted)
                  : _searchResults.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off, size: 48, color: textMuted.withValues(alpha: 0.5)),
                              const SizedBox(height: 16),
                              Text('No exercises found', style: TextStyle(fontSize: 16, color: textMuted)),
                              const SizedBox(height: 8),
                              Text(
                                'Try a different search or filter',
                                style: TextStyle(fontSize: 13, color: textMuted.withValues(alpha: 0.7)),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final exercise = _searchResults[index];
                            final isAiMatch = exercise is SmartSearchExerciseItem &&
                                exercise.isSemanticMatch;
                            return _ExerciseCard(
                              exercise: exercise,
                              accentColor: _accentColor,
                              actionIcon: _actionIcon,
                              textPrimary: textPrimary,
                              textMuted: textMuted,
                              isAiMatch: isAiMatch,
                              onDetailTap: () => _openDetailSheet(exercise),
                              onAddTap: () => _selectExercise(exercise),
                            );
                          },
                        ),
        ),

        // Filter panel (expandable)
        if (_showFilters)
          _buildFilterPanel(isDark, cardBackground, textPrimary, textMuted),

        // Bottom search bar + filter button
        Container(
          padding: EdgeInsets.fromLTRB(
            16, 12, 16,
            12 + MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.nearBlack : AppColorsLight.pureWhite,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  autofocus: true,
                  style: TextStyle(color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search exercises...',
                    hintStyle: TextStyle(color: textMuted),
                    prefixIcon: Icon(Icons.search, color: textMuted),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: textMuted, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: cardBackground,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _accentColor),
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              const SizedBox(width: 8),
              // AI toggle button
              Material(
                color: _useSmartSearch
                    ? AppColors.cyan.withValues(alpha: 0.2)
                    : cardBackground,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _useSmartSearch = !_useSmartSearch;
                      _searchCorrection = null;
                      _searchTimeMs = null;
                    });
                    if (_searchQuery.length >= 2 || _hasActiveFilters) {
                      _debounceTimer?.cancel();
                      setState(() => _isSearching = true);
                      _debounceTimer = Timer(const Duration(milliseconds: 100), () {
                        _performSearch();
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.auto_awesome,
                      color: _useSmartSearch ? AppColors.cyan : textMuted,
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Filter button with active count badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Material(
                    color: _showFilters
                        ? _accentColor.withValues(alpha: 0.2)
                        : cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _showFilters = !_showFilters);
                        if (_showFilters) _searchFocusNode.unfocus();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.tune,
                          color: _showFilters ? _accentColor : textMuted,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  if (_activeFilterCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$_activeFilterCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveChip(String label, String category, Color textPrimary, Color cardBackground) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InputChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: textPrimary)),
        onDeleted: () => _removeFilter(category, label),
        deleteIconColor: _accentColor,
        backgroundColor: _accentColor.withValues(alpha: 0.12),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildFilterPanel(bool isDark, Color cardBackground, Color textPrimary, Color textMuted) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: isDark ? AppColors.nearBlack : AppColorsLight.pureWhite,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Body Parts
            if (_filterOptions['body_parts']?.isNotEmpty == true) ...[
              _buildFilterSectionHeader('Body Part', Icons.accessibility_new, textPrimary),
              const SizedBox(height: 8),
              _buildFilterChips(
                _filterOptions['body_parts']!,
                _selectedBodyParts,
                (v) => _toggleFilter(_selectedBodyParts, v),
                isDark,
              ),
              const SizedBox(height: 16),
            ],
            // Equipment
            if (_filterOptions['equipment']?.isNotEmpty == true) ...[
              _buildFilterSectionHeader('Equipment', Icons.fitness_center, textPrimary),
              const SizedBox(height: 8),
              _buildFilterChips(
                _filterOptions['equipment']!,
                _selectedEquipment,
                (v) => _toggleFilter(_selectedEquipment, v),
                isDark,
              ),
              const SizedBox(height: 16),
            ],
            // Exercise Types
            if (_filterOptions['exercise_types']?.isNotEmpty == true) ...[
              _buildFilterSectionHeader('Type', Icons.category, textPrimary),
              const SizedBox(height: 8),
              _buildFilterChips(
                _filterOptions['exercise_types']!,
                _selectedExerciseTypes,
                (v) => _toggleFilter(_selectedExerciseTypes, v),
                isDark,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSectionHeader(String title, IconData icon, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _accentColor),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(
    List<FilterOption> options,
    Set<String> selected,
    ValueChanged<String> onToggle,
    bool isDark,
  ) {
    // Show max 15 options
    final displayOptions = options.take(15).toList();
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: displayOptions.map((option) {
        final isSelected = selected.contains(option.name);
        return FilterChip(
          label: Text(
            '${option.name} (${option.count})',
            style: TextStyle(
              fontSize: 12,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.textSecondary : AppColorsLight.textSecondary),
            ),
          ),
          selected: isSelected,
          onSelected: (_) => onToggle(option.name),
          selectedColor: _accentColor,
          checkmarkColor: Colors.white,
          backgroundColor: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(Color textMuted) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, size: 48, color: textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Search for exercises',
            style: TextStyle(fontSize: 16, color: textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            'Type to search or use filters to browse',
            style: TextStyle(fontSize: 13, color: textMuted.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final LibraryExerciseItem exercise;
  final Color accentColor;
  final IconData actionIcon;
  final Color textPrimary;
  final Color textMuted;
  final bool isAiMatch;
  final VoidCallback onDetailTap;
  final VoidCallback onAddTap;

  const _ExerciseCard({
    required this.exercise,
    required this.accentColor,
    required this.actionIcon,
    required this.textPrimary,
    required this.textMuted,
    this.isAiMatch = false,
    required this.onDetailTap,
    required this.onAddTap,
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
          onTap: onDetailTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Exercise image with play overlay
                GestureDetector(
                  onTap: onDetailTap,
                  child: Stack(
                    children: [
                      ExerciseImage(
                        exerciseName: exercise.name,
                        width: 60,
                        height: 60,
                        borderRadius: 8,
                        backgroundColor: glassSurface,
                        iconColor: textMuted,
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.play_circle_outline,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
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
                              style: TextStyle(
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
                                color: AppColors.cyan.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'AI',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.cyan,
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
                          exercise.targetMuscle ?? exercise.bodyPart,
                          exercise.equipment,
                        ].where((s) => s != null && s.isNotEmpty).join(' • '),
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

                // Add/lock action button
                Material(
                  color: accentColor.withValues(alpha: 0.2),
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onAddTap,
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        actionIcon,
                        color: accentColor,
                        size: 22,
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
}
