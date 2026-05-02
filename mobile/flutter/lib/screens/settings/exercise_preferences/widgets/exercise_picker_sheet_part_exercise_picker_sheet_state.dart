part of 'exercise_picker_sheet.dart';


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
  // When true, results are limited to the user's own custom exercises —
  // skips the server search entirely so users can browse just their library.
  bool _customOnly = false;

  // Smart search state
  bool _useSmartSearch = true;
  String? _searchCorrection;
  double? _searchTimeMs;

  // Multi-select state — only used when widget.multiSelect is true.
  // Keyed by exercise.id so the same item across smart-search + literal
  // result sets dedupes naturally.
  final List<ExercisePickerResult> _multiPicked = [];
  final Set<String> _multiPickedIds = {};

  int get _activeFilterCount =>
      _selectedBodyParts.length +
      _selectedEquipment.length +
      _selectedExerciseTypes.length +
      (_customOnly ? 1 : 0);

  bool get _hasActiveFilters => _activeFilterCount > 0;

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
    // Ensure custom exercises are loaded for search merging
    ref.read(customExercisesProvider.notifier).initialize();
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

  /// Icon shown on each exercise card's action button. The outlined variants
  /// signal "tap to add" — the card swaps to the filled variant once selected
  /// (handled in `_ExerciseCard`).
  IconData get _actionIcon {
    switch (widget.type) {
      case ExercisePickerType.favorite:
        return Icons.favorite_border;
      case ExercisePickerType.staple:
        // Pin matches the sheet's header icon ("Add Staple Exercise") so the
        // affordance is consistent. Avoid lock icons — users read locked as
        // "can't tap" rather than "click to staple".
        return Icons.push_pin_outlined;
      case ExercisePickerType.queue:
        return Icons.bookmark_border;
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

    // Instant local search from Drift database (no network needed)
    if (query.length >= 2) {
      _performLocalSearch(query);
    }

    // Debounced remote search for better ranking + spell correction
    setState(() => _isSearching = true);
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _performSearch();
    });
  }

  Future<void> _performLocalSearch(String query) async {
    try {
      final db = ref.read(appDatabaseProvider);
      final localResults = await db.exerciseLibraryDao.searchExercises(
        query,
        bodyPart: _selectedBodyParts.isNotEmpty ? _selectedBodyParts.first : null,
        equipment: _selectedEquipment.isNotEmpty ? _selectedEquipment.first : null,
      );

      if (!mounted || _searchQuery != query) return;

      // Convert CachedExercise to LibraryExerciseItem and apply relevance sort
      final items = localResults.map((e) => LibraryExerciseItem(
        id: e.id,
        name: e.name,
        bodyPart: e.bodyPart,
        equipment: e.equipment,
        targetMuscle: e.targetMuscle,
        videoUrl: e.videoUrl,
        imageUrl: e.imageS3Path,
      )).toList();

      // Sort by relevance: exact > prefix > word-boundary > substring
      final queryLower = query.toLowerCase();
      items.sort((a, b) {
        int scoreOf(LibraryExerciseItem item) {
          final name = item.name.toLowerCase();
          if (name == queryLower) return 0;
          if (name.startsWith(queryLower)) return 1;
          if (RegExp(r'\b' + RegExp.escape(queryLower) + r'\b').hasMatch(name)) return 2;
          return 3;
        }
        final cmp = scoreOf(a).compareTo(scoreOf(b));
        if (cmp != 0) return cmp;
        return a.name.length.compareTo(b.name.length);
      });

      // Filter out excluded exercises
      final filtered = items.where((e) =>
        !widget.excludeExercises.any((name) => name.toLowerCase() == e.name.toLowerCase())
      ).take(20).toList();

      // Merge custom exercises
      final customMatches = _getMatchingCustomExercises(query);

      setState(() {
        _searchResults = [...customMatches, ...filtered];
      });

      // Pre-fetch image URLs in batch for faster thumbnail loading
      final names = filtered.map((e) => e.name).toList();
      if (names.isNotEmpty) {
        final apiClient = ref.read(apiClientProvider);
        ImageUrlCache.batchPreFetch(names, apiClient);
      }
    } catch (e) {
      debugPrint('Local search error: $e');
    }
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

    // "Custom only" short-circuits the network search — we already have all
    // the data locally, and skipping the server keeps results instant.
    if (_customOnly) {
      final customMatches =
          _getMatchingCustomExercises(hasQuery ? query : null);
      if (mounted) {
        setState(() {
          _searchResults = customMatches;
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

        // Merge custom exercises into results
        final customMatches = _getMatchingCustomExercises(query);

        if (mounted) {
          setState(() {
            _searchResults = [...customMatches, ...filtered];
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

        // Merge custom exercises into results
        final customMatches = _getMatchingCustomExercises(hasQuery ? query : null);

        if (mounted) {
          setState(() {
            _searchResults = [...customMatches, ...filtered];
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

  /// Get custom exercises matching the current search query and filters
  List<LibraryExerciseItem> _getMatchingCustomExercises(String? query) {
    final customState = ref.read(customExercisesProvider);
    if (customState.exercises.isEmpty) return [];

    final queryLower = query?.toLowerCase() ?? '';

    return customState.exercises.where((ce) {
      // Filter by search query
      if (queryLower.isNotEmpty && !ce.name.toLowerCase().contains(queryLower)) {
        return false;
      }
      // Filter by body part
      if (_selectedBodyParts.isNotEmpty) {
        if (!_selectedBodyParts.any((bp) =>
            bp.toLowerCase() == ce.primaryMuscle.toLowerCase())) {
          return false;
        }
      }
      // Filter by equipment
      if (_selectedEquipment.isNotEmpty) {
        if (!_selectedEquipment.any((eq) =>
            eq.toLowerCase() == ce.equipment.toLowerCase())) {
          return false;
        }
      }
      // Filter out already added exercises
      if (widget.excludeExercises
          .any((name) => name.toLowerCase() == ce.name.toLowerCase())) {
        return false;
      }
      return true;
    }).map((ce) => ce.toLibraryItem()).toList();
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
      _customOnly = false;
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
    final result = ExercisePickerResult(
      exerciseName: exercise.name,
      exerciseId: exercise.id,
      muscleGroup: exercise.targetMuscle ?? exercise.bodyPart,
      targetMuscleGroup: exercise.targetMuscle ?? exercise.bodyPart,
      reason: widget.type == ExercisePickerType.staple ? 'staple' : null,
    );

    // Multi-select: toggle membership instead of popping. Sticky bottom bar
    // shows the running count + Save action.
    if (widget.multiSelect) {
      setState(() {
        if (_multiPickedIds.contains(exercise.id)) {
          _multiPickedIds.remove(exercise.id);
          _multiPicked.removeWhere((r) => r.exerciseId == exercise.id);
        } else {
          _multiPickedIds.add(exercise.id);
          _multiPicked.add(result);
        }
      });
      return;
    }

    Navigator.pop(context, result);
  }

  void _addCustomExercise(String name) {
    HapticFeedback.lightImpact();
    showGlassSheet(
      context: context,
      builder: (context) => CreateExerciseSheet(initialName: name),
    ).then((created) {
      // If exercise was created, select it
      if (created != null && created is CustomExercise && mounted) {
        Navigator.pop(
          this.context,
          ExercisePickerResult(
            exerciseName: created.name,
            exerciseId: 'custom_${created.id}',
            muscleGroup: created.primaryMuscle,
            targetMuscleGroup: created.primaryMuscle,
            reason: widget.type == ExercisePickerType.staple ? 'staple' : null,
          ),
        );
      }
    });
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
                  ? _buildEmptyState(textMuted, textPrimary)
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
                              if (_searchController.text.trim().isNotEmpty) ...[
                                const SizedBox(height: 20),
                                OutlinedButton.icon(
                                  onPressed: () => _addCustomExercise(_searchController.text.trim()),
                                  icon: const Icon(Icons.add, size: 18),
                                  label: Text('Add "${_searchController.text.trim()}" as custom'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _accentColor,
                                    side: BorderSide(color: _accentColor.withValues(alpha: 0.5)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _searchResults.length,
                                itemBuilder: (context, index) {
                                  final exercise = _searchResults[index];
                                  final isAiMatch = exercise is SmartSearchExerciseItem &&
                                      exercise.isSemanticMatch;
                                  final isCustom = exercise.id.startsWith('custom_');
                                  return _ExerciseCard(
                                    exercise: exercise,
                                    accentColor: _accentColor,
                                    actionIcon: _actionIcon,
                                    textPrimary: textPrimary,
                                    textMuted: textMuted,
                                    isAiMatch: isAiMatch,
                                    isSelected: widget.multiSelect &&
                                        _multiPickedIds.contains(exercise.id),
                                    onDetailTap: widget.multiSelect
                                        ? () => _selectExercise(exercise)
                                        : (isCustom
                                            ? () => _selectExercise(exercise)
                                            : () => _openDetailSheet(exercise)),
                                    onAddTap: () => _selectExercise(exercise),
                                  );
                                },
                              ),
                            ),
                            if (_searchController.text.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: GestureDetector(
                                  onTap: () => _addCustomExercise(_searchController.text.trim()),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add, size: 16, color: _accentColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Can't find your exercise? Add it as custom",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: _accentColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
        ),

        // Filter panel (expandable)
        if (_showFilters)
          _buildFilterPanel(isDark, cardBackground, textPrimary, textMuted),

        // Multi-select save bar — only visible in multi-select mode. Shows
        // running count + Save action so users can batch-add exercises (e.g.
        // to the Avoid list) without re-entering the picker for each one.
        if (widget.multiSelect)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
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
                  child: Text(
                    _multiPicked.isEmpty
                        ? 'Tap exercises to select multiple'
                        : '${_multiPicked.length} selected',
                    style: TextStyle(
                      fontSize: 13,
                      color: _multiPicked.isEmpty ? textMuted : textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _multiPicked.isEmpty
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(
                              context, List<ExercisePickerResult>.from(_multiPicked));
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _accentColor.withValues(alpha: 0.3),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    _multiPicked.isEmpty
                        ? 'Save'
                        : 'Save (${_multiPicked.length})',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

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
                    hintText: 'Search — try "push", "row", "squat"',
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
              // AI semantic-search toggle — finds exercises by meaning
              // ("ab burner" → planks, hollow holds) on top of the literal
              // substring match. Tooltip surfaces the purpose so users don't
              // think it's a generic AI action button.
              Tooltip(
                message: _useSmartSearch
                    ? 'AI search ON — matching by meaning'
                    : 'Turn on AI search — find exercises by meaning, not just spelling',
                child: Material(
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
            // Custom-only toggle. Surfacing this as a filter (vs a separate
            // tab) keeps the picker model simple and lets users intersect
            // "Custom only" with body part / equipment filters.
            Builder(builder: (context) {
              final customCount =
                  ref.watch(customExercisesProvider).exercises.length;
              return Row(
                children: [
                  Icon(Icons.tune, size: 16, color: _accentColor),
                  const SizedBox(width: 6),
                  Text(
                    'Custom only',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '($customCount)',
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                  const Spacer(),
                  Switch.adaptive(
                    value: _customOnly,
                    activeColor: _accentColor,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _customOnly = v);
                      // Re-run search so the result set updates immediately.
                      _performSearch();
                    },
                  ),
                ],
              );
            }),
            const SizedBox(height: 8),
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

  void _openCreateExerciseSheet() {
    HapticFeedback.lightImpact();
    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => const GlassSheet(
        child: CreateExerciseSheet(),
      ),
    );
  }

  Widget _buildEmptyState(Color textMuted, Color textPrimary) {
    // Surface the user's existing custom exercises BEFORE the generic search
    // hint — they're the most-likely target when adding to a preference list.
    // Sort by recently created (createdAt desc) and cap at 10 to avoid scroll
    // jail; the rest are reachable via search or the "Custom only" filter.
    final customs = ref.watch(customExercisesProvider).exercises;
    final sortedCustoms = [...customs]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final displayCustoms = sortedCustoms.take(10).toList();
    final hasCustoms = displayCustoms.isNotEmpty;
    final hasMoreCustoms = sortedCustoms.length > displayCustoms.length;

    final createButton = OutlinedButton.icon(
      onPressed: _openCreateExerciseSheet,
      icon: const Icon(Icons.add_circle_outline, size: 18),
      label: const Text('Create Custom Exercise'),
      style: OutlinedButton.styleFrom(
        foregroundColor: _accentColor,
        side: BorderSide(color: _accentColor.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );

    if (!hasCustoms) {
      // No customs yet — keep the original placeholder so the empty state
      // doesn't look broken.
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
            const SizedBox(height: 24),
            createButton,
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Row(
          children: [
            Icon(Icons.tune, size: 16, color: textMuted),
            const SizedBox(width: 6),
            Text(
              'YOUR CUSTOM EXERCISES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textMuted,
                letterSpacing: 0.6,
              ),
            ),
            const Spacer(),
            Text(
              hasMoreCustoms
                  ? 'Showing ${displayCustoms.length} of ${sortedCustoms.length}'
                  : '${sortedCustoms.length}',
              style: TextStyle(fontSize: 11, color: textMuted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...displayCustoms.map((ce) {
          final exercise = ce.toLibraryItem();
          final isSelected = widget.multiSelect && _multiPickedIds.contains(exercise.id);
          return _ExerciseCard(
            exercise: exercise,
            accentColor: _accentColor,
            actionIcon: _actionIcon,
            textPrimary: textPrimary,
            textMuted: textMuted,
            isAiMatch: false,
            isSelected: isSelected,
            onDetailTap: () => _selectExercise(exercise),
            onAddTap: () => _selectExercise(exercise),
          );
        }),
        const SizedBox(height: 16),
        Center(child: createButton),
        const SizedBox(height: 24),
        // Light hint reminding the user they can also browse the full library.
        Center(
          child: Text(
            'Or type above to search the full exercise library',
            style: TextStyle(fontSize: 12, color: textMuted.withValues(alpha: 0.7)),
          ),
        ),
      ],
    );
  }
}

