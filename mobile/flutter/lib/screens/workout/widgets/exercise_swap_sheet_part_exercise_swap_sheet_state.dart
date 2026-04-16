part of 'exercise_swap_sheet.dart';


class _ExerciseSwapSheetState extends ConsumerState<_ExerciseSwapSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Similar tab (fast DB queries)
  bool _isLoadingSimilar = false;
  List<Map<String, dynamic>> _similarExercises = [];

  // AI Picks tab (slow AI suggestions)
  bool _isLoadingAI = false;
  bool _aiLoaded = false;
  List<Map<String, dynamic>> _aiSuggestions = [];
  String? _aiError;

  // Recent tab
  bool _isLoadingRecent = true;
  List<Map<String, dynamic>> _recentExercises = [];

  // Library tab
  bool _isLoadingLibrary = false;
  List<LibraryExerciseItem> _libraryExercises = [];
  String _searchQuery = '';

  // Swap state
  bool _isSwapping = false;
  String? _selectedReason;

  // AI input state (voice + text)
  final TextEditingController _aiInputController = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();
  bool _isSpeechAvailable = false;
  bool _isListening = false;

  // Cached for filtering
  List<String> _avoidedExerciseNames = [];

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
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    // Defer provider state mutation until after the first frame so we don't
    // trip Riverpod's "modify while building" guard. initialize() synchronously
    // sets isLoading=true on its first call, which is what the guard catches.
    Future.microtask(() {
      if (!mounted) return;
      ref.read(customExercisesProvider.notifier).initialize();
    });
    _loadAvoidedExercises();
    _loadSimilarExercises();
    _loadRecentExercises();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _isSpeechAvailable = await _speechToText.initialize(
        onError: (error) {
          debugPrint('Speech error: $error');
          if (mounted) {
            setState(() => _isListening = false);
          }
        },
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'done' && mounted) {
            setState(() => _isListening = false);
          }
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Speech init error: $e');
      _isSpeechAvailable = false;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _aiInputController.dispose();
    if (_isListening) {
      _speechToText.stop();
    }
    super.dispose();
  }

  void _onTabChanged() {
    // Load AI suggestions when user switches to AI Picks tab (index 3)
    // Only auto-load if no custom input is provided
    if (_tabController.index == 3 &&
        !_aiLoaded &&
        !_isLoadingAI &&
        _aiInputController.text.isEmpty) {
      _loadAISuggestions();
    }
  }

  Future<void> _toggleListening() async {
    if (!_isSpeechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition not available'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speechToText.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _aiInputController.text = result.recognizedWords;
            });
            // Automatically trigger search when final result
            if (result.finalResult && result.recognizedWords.isNotEmpty) {
              setState(() => _isListening = false);
            }
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
      );
    }
  }

  Future<void> _loadAvoidedExercises() async {
    try {
      final userId = await ref.read(apiClientProvider).getUserId();
      final prefsRepo = ref.read(exercisePreferencesRepositoryProvider);
      final avoided = await prefsRepo.getAvoidedExercises(userId!);
      _avoidedExerciseNames = avoided
          .where((a) => a.isActive)
          .map((a) => a.exerciseName)
          .toList();
      debugPrint(
          '🚫 [Swap] Loaded ${_avoidedExerciseNames.length} avoided exercises');
    } catch (e) {
      debugPrint('⚠️ [Swap] Could not fetch avoided exercises: $e');
    }
  }

  /// Load fast database-based suggestions (~500ms)
  Future<void> _loadSimilarExercises() async {
    if (_isLoadingSimilar) return;
    setState(() => _isLoadingSimilar = true);

    try {
      final userId = await ref.read(apiClientProvider).getUserId();
      final repo = ref.read(workoutRepositoryProvider);

      final suggestions = await repo.getExerciseSuggestionsFast(
        exerciseName: widget.exercise.name,
        userId: userId!,
        avoidedExercises: _avoidedExerciseNames,
      );

      // Merge user's custom exercises that match the current exercise's body
      // part or target muscle. Custom exercises aren't in the library DB
      // (unless RAG-indexed post-import), so they'd otherwise be invisible
      // here. Matched customs get a "Your Exercise" badge and are inserted
      // at the top, because the user's own exercises are more relevant than
      // generic library alternatives.
      final merged = _mergeCustomExercisesIntoSimilar(suggestions);

      if (mounted) {
        setState(() {
          _similarExercises = merged;
          _isLoadingSimilar = false;
        });

        // Pre-fetch images in background (non-blocking)
        final exerciseNames = merged
            .map((s) => s['name'] as String?)
            .whereType<String>()
            .toList();
        if (exerciseNames.isNotEmpty) {
          final apiClient = ref.read(apiClientProvider);
          ImageUrlCache.batchPreFetch(exerciseNames, apiClient);
        }
      }
    } catch (e) {
      debugPrint('Error loading similar exercises: $e');
      if (mounted) {
        setState(() {
          _similarExercises = [];
          _isLoadingSimilar = false;
        });
      }
    }
  }

  /// Merge user custom exercises that match the current exercise's body-part
  /// or target_muscle into the Similar-tab list. Returns a new list — does
  /// not mutate [librarySuggestions].
  List<Map<String, dynamic>> _mergeCustomExercisesIntoSimilar(
    List<Map<String, dynamic>> librarySuggestions,
  ) {
    final customs = ref.read(customExercisesProvider).exercises;
    if (customs.isEmpty) return librarySuggestions;

    // Avoid duplicates vs. the library-sourced list and the exercise we're
    // currently trying to replace.
    final librarySet = librarySuggestions
        .map((s) => (s['name'] as String? ?? '').toLowerCase())
        .toSet();
    final replacingLower = widget.exercise.name.toLowerCase();

    // Heuristic matcher: share body-part or any muscle token with the
    // replacing exercise. We fall back across the taxonomy fields that the
    // backend populates in different scenarios (primary_muscle, body_part,
    // muscle_group) so the matcher still fires regardless of which the
    // workout row happens to carry.
    final replacingMuscle = (widget.exercise.primaryMuscle ??
            widget.exercise.bodyPart ??
            widget.exercise.muscleGroup ??
            '')
        .toLowerCase();
    final replacingEquip = (widget.exercise.equipment ?? '').toLowerCase();

    final matches = <Map<String, dynamic>>[];
    for (final ex in customs) {
      final nameLower = ex.name.toLowerCase();
      if (nameLower == replacingLower) continue;
      if (librarySet.contains(nameLower)) continue;

      final primary = ex.primaryMuscle.toLowerCase();
      final secondaries =
          (ex.secondaryMuscles ?? const <String>[]).map((m) => m.toLowerCase());
      final allMuscles = {primary, ...secondaries};

      // Match when primary/secondary muscle overlaps OR equipment matches.
      final muscleHit = replacingMuscle.isNotEmpty &&
          allMuscles.any((m) =>
              m.contains(replacingMuscle) || replacingMuscle.contains(m));
      final equipHit = replacingEquip.isNotEmpty &&
          ex.equipment.toLowerCase().contains(replacingEquip);

      if (!muscleHit && !equipHit) continue;

      matches.add(<String, dynamic>{
        'name': ex.name,
        'target_muscle': ex.primaryMuscle,
        'body_part': ex.primaryMuscle,
        'equipment': ex.equipment,
        'reason': 'From your custom exercises',
        'rank': 1,
        'source': 'custom_exercise',
        'is_custom': true,
      });
    }

    if (matches.isEmpty) return librarySuggestions;
    // Put customs first, keep library ordering below.
    return [...matches, ...librarySuggestions];
  }

  /// Append all user customs to the AI Picks results so the user sees their
  /// own exercises even if the RAG pass somehow missed them (legacy / pre-
  /// import rows, or very low similarity scores).
  List<Map<String, dynamic>> _appendCustomExercisesToAI(
    List<Map<String, dynamic>> aiSuggestions,
  ) {
    final customs = ref.read(customExercisesProvider).exercises;
    if (customs.isEmpty) return aiSuggestions;
    final existing = aiSuggestions
        .map((s) => (s['name'] as String? ?? '').toLowerCase())
        .toSet();
    final replacingLower = widget.exercise.name.toLowerCase();
    final extras = <Map<String, dynamic>>[];
    for (final ex in customs) {
      final nameLower = ex.name.toLowerCase();
      if (nameLower == replacingLower) continue;
      if (existing.contains(nameLower)) continue;
      extras.add(<String, dynamic>{
        'name': ex.name,
        'target_muscle': ex.primaryMuscle,
        'body_part': ex.primaryMuscle,
        'equipment': ex.equipment,
        'reason': 'From your custom exercises',
        'rank': 99,
        'source': 'custom_exercise',
        'is_custom': true,
      });
    }
    return [...aiSuggestions, ...extras];
  }

  /// Load slow AI-powered suggestions (~10s) - only called when AI tab is selected
  /// Uses user's text/voice input if provided, otherwise uses selected reason chip.
  Future<void> _loadAISuggestions() async {
    setState(() {
      _isLoadingAI = true;
      _aiError = null;
    });

    try {
      final userId = await ref.read(apiClientProvider).getUserId();
      final repo = ref.read(workoutRepositoryProvider);

      // Freeform input goes through customMessage; the chip (if any) goes
      // through reason. The repository picks whichever is set.
      final userInput = _aiInputController.text.trim();
      final suggestions = await repo.getExerciseSuggestions(
        workoutId: widget.workoutId,
        exercise: widget.exercise,
        userId: userId!,
        reason: _selectedReason,
        customMessage: userInput.isEmpty ? null : userInput,
        avoidedExercises: _avoidedExerciseNames,
      );

      // Always append user custom exercises at the end so they're reachable
      // even when the RAG pass didn't surface them (custom exercises aren't
      // always indexed into ChromaDB — legacy cases).
      final mergedAI = _appendCustomExercisesToAI(suggestions);

      if (mounted) {
        setState(() {
          _aiSuggestions = mergedAI;
          _isLoadingAI = false;
          _aiLoaded = true;
        });

        final aiNames = mergedAI
            .map((s) => s['name'] as String?)
            .whereType<String>()
            .toList();
        if (aiNames.isNotEmpty) {
          final apiClient = ref.read(apiClientProvider);
          ImageUrlCache.batchPreFetch(aiNames, apiClient);
        }
      }
    } catch (e) {
      debugPrint('Error loading AI suggestions: $e');
      if (mounted) {
        setState(() {
          _aiSuggestions = [];
          _aiError = _friendlyAIError(e);
          _isLoadingAI = false;
          _aiLoaded = true;
        });
      }
    }
  }

  /// Map a raw exception into a human-readable AI Picks error. Distinguishes
  /// the common cases so the user knows if it's a rate limit vs. a network
  /// issue vs. a server problem, rather than the generic "No AI suggestions".
  String _friendlyAIError(Object e) {
    final msg = e.toString();
    if (msg.contains('429')) {
      return 'You\'re asking a bit fast — try again in a minute.';
    }
    if (msg.contains('401') || msg.contains('403')) {
      return 'Session expired. Please sign in again.';
    }
    if (msg.contains('SocketException') ||
        msg.contains('timeout') ||
        msg.contains('TimeoutException') ||
        msg.contains('Network')) {
      return 'Network problem. Check your connection and try again.';
    }
    if (msg.contains('500') || msg.contains('502') || msg.contains('503')) {
      return 'The AI service is having trouble right now. Please try again.';
    }
    return 'Couldn\'t reach the AI service. Please try again.';
  }

  Future<void> _searchLibrary(String query) async {
    setState(() {
      _searchQuery = query;
      _isLoadingLibrary = true;
    });

    try {
      final libraryRepo = ref.read(libraryRepositoryProvider);
      final exercises = await libraryRepo.searchExercises(query: query);

      // Also search custom exercises
      final customState = ref.read(customExercisesProvider);
      final queryLower = query.toLowerCase();
      final customMatches = customState.exercises
          .where((ce) => ce.name.toLowerCase().contains(queryLower))
          .map((ce) => ce.toLibraryItem())
          .toList();

      if (mounted) {
        setState(() {
          _libraryExercises = [...customMatches, ...exercises];
          _isLoadingLibrary = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching library: $e');
      if (mounted) {
        setState(() {
          _libraryExercises = [];
          _isLoadingLibrary = false;
        });
      }
    }
  }

  Future<void> _loadRecentExercises() async {
    setState(() => _isLoadingRecent = true);
    try {
      final userId = await ref.read(apiClientProvider).getUserId();
      if (userId != null) {
        final repo = ref.read(workoutRepositoryProvider);
        final recentSwaps = await repo.getRecentSwapHistory(
          userId: userId,
          limit: 10,
        );

        if (mounted) {
          setState(() {
            _recentExercises = recentSwaps;
            _isLoadingRecent = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingRecent = false);
        }
      }
    } catch (e) {
      debugPrint('Error loading recent exercises: $e');
      if (mounted) {
        setState(() => _isLoadingRecent = false);
      }
    }
  }

  Future<void> _swapExercise(String newExerciseName,
      {String source = 'ai_suggestion'}) async {
    setState(() => _isSwapping = true);

    final repo = ref.read(workoutRepositoryProvider);
    final (updatedWorkout, errorMessage) = await repo.swapExercise(
      workoutId: widget.workoutId,
      oldExerciseName: widget.exercise.name,
      newExerciseName: newExerciseName,
      reason: _selectedReason,
      swapSource: source,
    );

    setState(() => _isSwapping = false);

    if (mounted) {
      if (updatedWorkout != null) {
        ref.read(posthogServiceProvider).capture(
          eventName: 'exercise_swapped',
          properties: {
            'from_exercise': widget.exercise.name,
            'to_exercise': newExerciseName,
            'swap_source': source,
          },
        );
        Navigator.pop(context, updatedWorkout);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Swapped to $newExerciseName'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? 'Failed to swap exercise'),
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
    final cardBackground = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final glassSurface =
        isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                            style:
                                Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary,
                                    ),
                          ),
                        ),
                        // AI import entry point — launches the full 3-mode
                        // importer and refreshes the custom-exercise list so
                        // newly imported items appear in Similar/Library/AI.
                        TextButton.icon(
                          onPressed: () async {
                            final saved =
                                await showImportExerciseScreen(context);
                            if (saved && context.mounted) {
                              await ref
                                  .read(customExercisesProvider.notifier)
                                  .refresh();
                              _loadSimilarExercises();
                              if (_searchQuery.isNotEmpty) {
                                _searchLibrary(_searchQuery);
                              }
                              if (_tabController.index == 3) {
                                // Let the user regenerate AI picks on demand —
                                // don't silently burn tokens.
                                setState(() => _aiLoaded = false);
                              }
                            }
                          },
                          icon: const Icon(
                            Icons.auto_awesome_outlined,
                            size: 16,
                            color: AppColors.cyan,
                          ),
                          label: const Text(
                            'Import',
                            style: TextStyle(
                              color: AppColors.cyan,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            minimumSize: const Size(0, 32),
                            tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
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

                    // Reason selector (no longer triggers reload)
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
                                      _selectedReason =
                                          selected ? reason : null;
                                    });
                                    // Reason is passed when swapping, no reload needed
                                  },
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tabs - 4 tabs now
              SegmentedTabBar(
                controller: _tabController,
                showIcons: false,
                tabs: [
                  SegmentedTabItem(label: 'Similar'),
                  SegmentedTabItem(label: 'Recent'),
                  SegmentedTabItem(label: 'Library'),
                  SegmentedTabItem(label: 'AI Picks'),
                ],
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Similar tab (fast DB queries)
                    _buildSimilarTab(textMuted, textPrimary),

                    // Recent tab
                    _buildRecentTab(textMuted, textPrimary),

                    // Library search tab
                    _buildLibraryTab(cardBackground, textMuted, textPrimary),

                    // AI Picks tab (slow, loads on demand)
                    _buildAITab(textMuted, textPrimary),
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
    );
  }

  /// Similar Exercises tab - fast database queries (~500ms)
  Widget _buildSimilarTab(Color textMuted, Color textPrimary) {
    if (_isLoadingSimilar) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.cyan),
            const SizedBox(height: 16),
            Text(
              'Finding similar exercises...',
              style: TextStyle(color: textMuted),
            ),
          ],
        ),
      );
    }

    if (_similarExercises.isEmpty) {
      const accentColor = AppColors.cyan;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.swap_horiz_rounded, size: 40, color: accentColor),
            ),
            const SizedBox(height: 16),
            Text(
              'No similar exercises found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'No exercises match this muscle group',
              style: TextStyle(fontSize: 13, color: textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _loadSimilarExercises,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Try Again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: accentColor,
                side: BorderSide(color: accentColor.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _tabController.animateTo(3),
              child: const Text('Try AI Suggestions', style: TextStyle(color: accentColor)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _similarExercises.length,
      itemBuilder: (context, index) {
        final suggestion = _similarExercises[index];
        final name = suggestion['name'] ?? 'Exercise';
        final reason = suggestion['reason'] ?? '';
        final rank = suggestion['rank'] ?? (index + 1);
        final equipment = suggestion['equipment'] ?? '';
        final targetMuscle =
            suggestion['target_muscle'] ?? suggestion['body_part'] ?? '';

        // Create subtitle from reason or equipment/muscle info
        final subtitle = reason.isNotEmpty
            ? reason
            : [targetMuscle, equipment].where((s) => s.isNotEmpty).join(' • ');

        final isCustom = suggestion['is_custom'] == true;
        final source =
            suggestion['source'] as String? ?? 'similar_exercise';

        // Badge text based on rank / source. Custom exercises get their own
        // "YOURS" badge so the user knows it's their own gear, independent of
        // rank heuristics.
        String badge;
        Color badgeColor;
        if (isCustom) {
          badge = 'YOURS';
          badgeColor = AppColors.orange;
        } else if (rank == 1) {
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
          onTap: () => _swapExercise(name, source: source),
          textPrimary: textPrimary,
          textMuted: textMuted,
        );
      },
    );
  }

  Widget _buildRecentTab(Color textMuted, Color textPrimary) {
    if (_isLoadingRecent) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.cyan),
            const SizedBox(height: 16),
            Text(
              'Loading recent exercises...',
              style: TextStyle(color: textMuted),
            ),
          ],
        ),
      );
    }

    if (_recentExercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 48, color: textMuted),
            const SizedBox(height: 16),
            Text(
              'No recent swaps',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your swap history will appear here',
              style: TextStyle(
                fontSize: 12,
                color: textMuted.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recentExercises.length,
      itemBuilder: (context, index) {
        final exercise = _recentExercises[index];
        final name = exercise['name'] ?? 'Exercise';
        final targetMuscle = exercise['target_muscle'] ?? '';
        final equipment = exercise['equipment'] ?? '';
        final swapCount = exercise['swap_count'] ?? 1;

        // Create subtitle from target muscle and equipment
        final subtitle =
            [targetMuscle, equipment].where((s) => s.isNotEmpty).join(' • ');

        // Badge showing swap count
        String badge;
        Color badgeColor;
        if (swapCount > 3) {
          badge = 'Frequently Used';
          badgeColor = AppColors.success;
        } else if (swapCount > 1) {
          badge = 'Used $swapCount times';
          badgeColor = AppColors.orange;
        } else {
          badge = 'Recently Used';
          badgeColor = AppColors.orange;
        }

        return _ExerciseOptionCard(
          name: name,
          subtitle: subtitle,
          badge: badge,
          badgeColor: badgeColor,
          onTap: () => _swapExercise(name, source: 'recent_exercise'),
          textPrimary: textPrimary,
          textMuted: textMuted,
        );
      },
    );
  }

  /// Library tab list body — splits into two sections:
  /// 1. "Your custom exercises" (if any custom items are in the current
  ///    result set) — with a header.
  /// 2. "Exercise library" (everything else).
  ///
  /// This is a behaviour-preserving extraction of the old inline
  /// `ListView.builder` in [_buildLibraryTab], with an added section header.
  Widget _buildLibraryList({
    required Color textPrimary,
    required Color textMuted,
  }) {
    final customItems = _libraryExercises
        .where((e) => e.id.startsWith('custom_'))
        .toList();
    final libraryItems = _libraryExercises
        .where((e) => !e.id.startsWith('custom_'))
        .toList();

    final children = <Widget>[];
    if (customItems.isNotEmpty) {
      children.add(_sectionHeader(
        'Your custom exercises',
        textMuted,
        icon: Icons.auto_awesome_outlined,
      ));
      for (final exercise in customItems) {
        children.add(_buildLibraryCard(
          exercise: exercise,
          isCustom: true,
          textPrimary: textPrimary,
          textMuted: textMuted,
        ));
      }
    }
    if (libraryItems.isNotEmpty) {
      if (customItems.isNotEmpty) {
        children.add(_sectionHeader(
          'Exercise library',
          textMuted,
          icon: Icons.fitness_center_outlined,
        ));
      }
      for (final exercise in libraryItems) {
        children.add(_buildLibraryCard(
          exercise: exercise,
          isCustom: false,
          textPrimary: textPrimary,
          textMuted: textMuted,
        ));
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: children,
    );
  }

  Widget _sectionHeader(String title, Color textMuted, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textMuted),
            const SizedBox(width: 6),
          ],
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: textMuted,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryCard({
    required LibraryExerciseItem exercise,
    required bool isCustom,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return _ExerciseOptionCard(
      name: exercise.name,
      imageUrl: exercise.imageUrl,
      subtitle: exercise.targetMuscle ?? exercise.bodyPart ?? '',
      badge: isCustom ? 'CUSTOM' : (exercise.equipment ?? 'Bodyweight'),
      badgeColor: isCustom ? AppColors.orange : AppColors.purple,
      onTap: () => _showExercisePreviewAndSwap(
        name: exercise.name,
        targetMuscle: exercise.targetMuscle,
        equipment: exercise.equipment,
        instructions: exercise.instructions,
        source: isCustom ? 'custom_exercise' : 'library_search',
      ),
      onSwap: () => _swapExercise(
        exercise.name,
        source: isCustom ? 'custom_exercise' : 'library_search',
      ),
      textPrimary: textPrimary,
      textMuted: textMuted,
    );
  }

  Widget _buildLibraryTab(
      Color cardBackground, Color textMuted, Color textPrimary) {
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
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.cyan))
              : _libraryExercises.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'Search for exercises'
                            : 'No exercises found',
                        style: TextStyle(color: textMuted),
                      ),
                    )
                  : _buildLibraryList(
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),
        ),
      ],
    );
  }
}

