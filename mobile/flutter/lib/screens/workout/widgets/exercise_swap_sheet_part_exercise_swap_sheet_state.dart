part of 'exercise_swap_sheet.dart';


class _ExerciseSwapSheetState extends ConsumerState<_ExerciseSwapSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Similar tab (fast DB queries)
  bool _isLoadingSimilar = false;
  List<Map<String, dynamic>> _similarExercises = [];
  // Backend-provided typed reason when _similarExercises is empty:
  //   'exercise_not_found' | 'filtered_out' | 'no_match' | null (loaded ok)
  // Drives honest empty-state copy on the Similar tab.
  String? _similarEmptyReason;

  // AI Picks tab (slow AI suggestions)
  bool _isLoadingAI = false;
  bool _aiLoaded = false;
  List<Map<String, dynamic>> _aiSuggestions = [];
  String? _aiError;
  // Currently selected refinement chip in the AI Picks tab. Maps to a
  // canned message in WorkoutRepository.getExerciseSuggestions chipMessages.
  // Persists across re-renders so the user can see which angle they picked.
  String? _aiPickChip;
  static const List<String> _aiPickChipOptions = [
    'Similar muscles',
    'Easier',
    'Harder',
    'No machine needed',
    'Bodyweight only',
    'Different angle',
  ];

  // Recent tab
  bool _isLoadingRecent = true;
  List<Map<String, dynamic>> _recentExercises = [];

  // Library tab
  bool _isLoadingLibrary = false;
  List<LibraryExerciseItem> _libraryExercises = [];
  String _searchQuery = '';

  // Any Equipment tab — muscle-similar matches regardless of what the user
  // owns. Drives the "what if I went to a different gym?" exploration the
  // Similar tab can't surface because it filters to available equipment.
  bool _isLoadingAnyEquipment = false;
  bool _anyEquipmentLoaded = false;
  List<Map<String, dynamic>> _anyEquipmentSuggestions = [];
  String? _anyEquipmentEmptyReason;

  // Swap state
  bool _isSwapping = false;
  String? _selectedReason;

  // Persist the swap going forward: future AI generations replace the old
  // exercise with the new one, and progressive-overload history follows it.
  // Defaults ON — directly answers "I want to swap once, not every week."
  // Hidden on the preview-swap path (previews aren't committed).
  bool _applyToFuture = true;

  /// When non-null, the row whose name (case-insensitive) matches this
  /// gets a brief cyan pulse highlight on first paint after the targeted
  /// tab loads. Cleared by [_clearPreselectHighlight] after ~1.4s so a
  /// later rebuild (e.g. user keeps scrolling) doesn't keep glowing.
  String? _highlightedName;
  Timer? _highlightTimer;

  /// Case-insensitive match against [_highlightedName] — used by every
  /// option-card builder to decide whether to render the cyan glow.
  bool _isHighlighted(String name) {
    final h = _highlightedName;
    if (h == null || h.isEmpty) return false;
    return name.toLowerCase().trim() == h.toLowerCase().trim();
  }

  // AI input state (voice + text)
  final TextEditingController _aiInputController = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();
  bool _isSpeechAvailable = false;
  bool _isListening = false;
  // Speech is initialized LAZILY (point-of-use), not in initState — calling
  // _speechToText.initialize() fires the iOS Speech-Recognition + Microphone
  // permission prompts, and the user shouldn't see those just for opening the
  // Swap sheet. We init the first time they tap the mic. Guards a single init.
  bool _speechInitialized = false;

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
    _tabController = TabController(length: 6, vsync: this);
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
    // NOTE: _initSpeech() is intentionally NOT called here — it triggers the
    // iOS Speech/Mic permission prompts on call. We defer it to the first
    // mic tap (see _toggleListening) so opening the sheet asks for nothing.

    // Chat-deeplink preselect: jump to AI Picks tab (where the matched
    // exercise is most likely to surface — Similar tab is name-matched
    // against widget.exercise, NOT against the canonical match), seed
    // _highlightedName so the row glows, and auto-clear after ~1.4s.
    if (widget.preselectedExerciseName != null &&
        widget.preselectedExerciseName!.trim().isNotEmpty) {
      _highlightedName = widget.preselectedExerciseName!.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Switch to AI Picks (now index 5 after inserting Any Equipment at
        // index 4). AI Picks loads on demand; nudge it with a custom-message
        // hint so the matched exercise rises to the top of suggestions.
        _aiInputController.text = _highlightedName!;
        _tabController.animateTo(5);
        _loadAISuggestions();
      });
      _highlightTimer = Timer(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() => _highlightedName = null);
      });
    }
  }

  Future<void> _initSpeech() async {
    _speechInitialized = true;
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
    _highlightTimer?.cancel();
    if (_isListening) {
      _speechToText.stop();
    }
    super.dispose();
  }

  void _onTabChanged() {
    // Any Equipment tab (index 4): muscle-similar matches regardless of
    // the user's owned equipment. Lazy-load on first visit so we don't
    // pay the round trip for users who never open it.
    if (_tabController.index == 4 &&
        !_anyEquipmentLoaded &&
        !_isLoadingAnyEquipment) {
      _loadAnyEquipmentExercises();
    }

    // AI Picks tab (now index 5 after inserting Any Equipment at 4).
    // Auto-load only when the user hasn't typed a custom query yet —
    // the freeform input takes precedence when present.
    if (_tabController.index == 5 &&
        !_aiLoaded &&
        !_isLoadingAI &&
        _aiInputController.text.isEmpty) {
      _loadAISuggestions();
    }
  }

  /// Load muscle-similar exercises ignoring the user's equipment filter so
  /// they can see what targets the same muscles at any gym. Distinct from
  /// the Similar tab in exactly one way: we pass `ignoreEquipment: true`
  /// to the backend so the equipment-availability filter is bypassed.
  Future<void> _loadAnyEquipmentExercises() async {
    if (_isLoadingAnyEquipment) return;
    setState(() => _isLoadingAnyEquipment = true);

    try {
      final userId = await ref.read(apiClientProvider).getUserId();
      final repo = ref.read(workoutRepositoryProvider);

      final userEquipment = ref.read(environmentEquipmentProvider).equipment;
      final result = await repo.getExerciseSuggestionsFast(
        exerciseName: widget.exercise.name,
        userId: userId!,
        avoidedExercises: _avoidedExerciseNames,
        userEquipment: userEquipment,
        ignoreEquipment: true,
      );

      if (mounted) {
        setState(() {
          _anyEquipmentSuggestions = result.suggestions;
          _anyEquipmentEmptyReason =
              result.suggestions.isEmpty ? result.emptyReason : null;
          _isLoadingAnyEquipment = false;
          _anyEquipmentLoaded = true;
        });

        final names = result.suggestions
            .map((s) => s['name'] as String?)
            .whereType<String>()
            .toList();
        if (names.isNotEmpty) {
          final apiClient = ref.read(apiClientProvider);
          ImageUrlCache.batchPreFetch(names, apiClient);
        }
      }
    } catch (e) {
      debugPrint('Error loading Any Equipment suggestions: $e');
      if (mounted) {
        setState(() {
          _anyEquipmentSuggestions = [];
          _anyEquipmentEmptyReason = 'no_match';
          _isLoadingAnyEquipment = false;
          _anyEquipmentLoaded = true;
        });
      }
    }
  }

  Future<void> _toggleListening() async {
    // Point-of-use init: the first mic tap is when we ask for Speech/Mic
    // permission. _initSpeech() sets _isSpeechAvailable based on the user's
    // grant; if they deny (or the platform reports unavailable), we surface a
    // graceful message instead of crashing or silently doing nothing.
    if (!_speechInitialized) {
      await _initSpeech();
      if (!mounted) return;
    }

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

      // Pass user's configured equipment so the backend can drop
      // candidates that the user can't actually do. Without this, a
      // bodyweight-only user swapping a barbell row would get back lots
      // of non-bodyweight options (the bug we're fixing).
      final userEquipment = ref.read(environmentEquipmentProvider).equipment;
      final result = await repo.getExerciseSuggestionsFast(
        exerciseName: widget.exercise.name,
        userId: userId!,
        avoidedExercises: _avoidedExerciseNames,
        userEquipment: userEquipment,
      );
      final suggestions = result.suggestions;
      final emptyReason = result.emptyReason;

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
          // Only carry the emptyReason when we'd actually show an empty
          // state. If a custom-exercise merge populated the list, treat
          // it as a successful load (no empty state).
          _similarEmptyReason = merged.isEmpty ? emptyReason : null;
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
          // Network/parse failure — fall back to the generic message.
          _similarEmptyReason = 'no_match';
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
      // Read the user's currently-configured equipment from the env+equip
      // provider. This is the same source the workout-generation pipeline
      // uses, so AI Picks stays consistent with what the user actually has.
      // Backend will fall back to loading from the users row if we somehow
      // pass null (defensive, e.g. provider not yet hydrated).
      final userEquipment = ref.read(environmentEquipmentProvider).equipment;
      // Reason precedence: AI-tab chip > sheet-level reason chip. Falls
      // through to the repository's context-rich default when both null
      // (auto-load on first tab visit).
      final activeReason = _aiPickChip ?? _selectedReason;
      final suggestions = await repo.getExerciseSuggestions(
        workoutId: widget.workoutId,
        exercise: widget.exercise,
        userId: userId!,
        reason: activeReason,
        customMessage: userInput.isEmpty ? null : userInput,
        avoidedExercises: _avoidedExerciseNames,
        userEquipment: userEquipment,
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
      previewId: widget.previewId,
      applyToFuture: _applyToFuture,
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
            content: Text(AppLocalizations.of(context)!.exerciseSwapSheetPartExerciseSwapSheetStateSwappedTo(newExerciseName)),
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
    final l = AppLocalizations.of(context)!;
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

    return Stack(
      children: [
        _buildSheetBody(
          l: l,
          isDark: isDark,
          cardBackground: cardBackground,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          textMuted: textMuted,
          glassSurface: glassSurface,
        ),
        // Snap-equipment FAB (Issue #1, Task #6). Fixed bottom-right; doesn't
        // overlap content because the tab bodies have their own bottom padding.
        PositionedDirectional(
          end: 16,
          bottom: 16,
          child: Builder(builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final fg = isDark ? Colors.white : Colors.black;
            Future<void> onTap() async {
              final updated = await showEquipmentSnapFlow(
                context, ref,
                mode: SnapMode.swap,
                workoutId: widget.workoutId,
                replacingExerciseId: widget.exercise.exerciseId,
                replacingExerciseName: widget.exercise.name,
                previewId: widget.previewId,
              );
              if (updated != null && mounted) {
                Navigator.of(context).pop(updated);
              }
            }

            // Glassmorphic pill — translucent + blurred instead of the solid
            // cyan FAB, so it floats over the list without dominating it.
            return ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: fg.withValues(alpha: isDark ? 0.16 : 0.06),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: fg.withValues(alpha: isDark ? 0.28 : 0.14),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt, size: 18, color: fg),
                          const SizedBox(width: 8),
                          Text(
                            'Snap equipment',
                            style: TextStyle(
                              color: fg,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSheetBody({
    required AppLocalizations l,
    required bool isDark,
    required Color cardBackground,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
    required Color glassSurface,
  }) {
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
                            l.exerciseSwapSheetTitle,
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
                              if (_tabController.index == 5) {
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
                          label: Text(
                            l.exerciseSwapSheetImport,
                            style: const TextStyle(
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
                                  l.exerciseSwapSheetReplacing,
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
                                padding: const EdgeInsetsDirectional.only(end: 8),
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

                    // Apply-to-future toggle (the wedge): persist this swap so
                    // future AI plans honor it and progress follows the swap.
                    if (widget.previewId == null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.event_repeat, size: 18, color: textMuted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Apply to future workouts',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  'Future plans use this exercise and keep your progress',
                                  style: TextStyle(fontSize: 11, color: textMuted),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _applyToFuture,
                            activeThumbColor: AppColors.cyan,
                            onChanged: (v) =>
                                setState(() => _applyToFuture = v),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Tabs - 6 tabs (5th = Any Equipment for cross-gym discovery)
              SegmentedTabBar(
                controller: _tabController,
                showIcons: false,
                tabs: [
                  SegmentedTabItem(label: l.exerciseSwapSheetTabSimilar),
                  SegmentedTabItem(label: l.exerciseSwapSheetTabRecent),
                  SegmentedTabItem(label: l.exerciseSwapSheetTabSnapped),
                  SegmentedTabItem(label: l.exerciseAddSheetTabLibrary),
                  SegmentedTabItem(label: l.exerciseSwapSheetTabAnyEquipment),
                  SegmentedTabItem(label: l.exerciseAddSheetTabAiPicks),
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

                    // Snapped tab (Issue #1, Task #6) — re-rank prior snaps
                    SnappedEquipmentSection(
                      mode: SnapMode.swap,
                      workoutId: widget.workoutId,
                      replacingExerciseId: widget.exercise.id,
                      replacingExerciseName: widget.exercise.name,
                      previewId: widget.previewId,
                      onSwapOrAdd: (match) async {
                        final name = (match['name'] as String?) ?? '';
                        final oldName = widget.exercise.name;
                        if (name.isEmpty || oldName.isEmpty) return null;
                        final repo = ref.read(workoutRepositoryProvider);
                        final (workout, err) = await repo.swapExercise(
                          workoutId: widget.workoutId,
                          oldExerciseName: oldName,
                          newExerciseName: name,
                          swapSource: 'equipment_snap_history',
                          previewId: widget.previewId,
                          applyToFuture: _applyToFuture,
                        );
                        if (!mounted) return null;
                        if (err != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(err)),
                          );
                          return null;
                        }
                        if (workout != null) {
                          Navigator.of(context).pop(workout);
                        }
                        return workout;
                      },
                    ),

                    // Library search tab
                    _buildLibraryTab(cardBackground, textMuted, textPrimary),

                    // Any Equipment tab — muscle-similar, equipment filter
                    // bypassed (server-side flag). For "if I went somewhere
                    // else, what could I do?" exploration.
                    _buildAnyEquipmentTab(textMuted, textPrimary),

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
      // Branch on the typed reason from /suggest-fast so the user sees
      // what actually happened. The previous one-size-fits-all "No
      // exercises match this muscle group" was the wrong reason in two
      // of the three cases (it blamed the muscle when the real cause was
      // either an unresolved exercise name or an equipment-filter wipe).
      String title;
      String body;
      switch (_similarEmptyReason) {
        case 'exercise_not_found':
          title = "We couldn't find this exercise";
          body =
              "Try AI Picks for a creative substitute or browse the Library directly.";
          break;
        case 'filtered_out':
          title = 'No equipment-compatible alternatives';
          body =
              "Library has options for this muscle, but none match the equipment you have. Try AI Picks for a creative substitute.";
          break;
        default:
          title = 'No similar exercises yet';
          body =
              "We don't have a close match in our library. Try AI Picks for a creative alternative.";
      }
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
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                body,
                style: TextStyle(fontSize: 13, color: textMuted),
                textAlign: TextAlign.center,
              ),
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
              onPressed: () => _tabController.animateTo(5),
              child: const Text('Try AI Suggestions', style: TextStyle(color: accentColor)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        // Bottom safe-area inset matches the AI Picks tab (see ext file)
        // so the last result card never lands behind the home-indicator.
        MediaQuery.viewPaddingOf(context).bottom + 16,
      ),
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
          highlighted: _isHighlighted(name),
        );
      },
    );
  }

  /// "Any Equipment" tab — same muscle-similarity ranking as Similar, but the
  /// equipment-availability filter is bypassed server-side via
  /// `ignore_equipment=true`. This is the "what could I do at another gym?"
  /// view. Each row shows the equipment chip so the user can tell at a
  /// glance what they'd need.
  Widget _buildAnyEquipmentTab(Color textMuted, Color textPrimary) {
    if (_isLoadingAnyEquipment) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.cyan),
            const SizedBox(height: 16),
            Text(
              'Finding muscle-matched alternatives...',
              style: TextStyle(color: textMuted),
            ),
          ],
        ),
      );
    }

    if (_anyEquipmentSuggestions.isEmpty) {
      const accentColor = AppColors.cyan;
      final body = _anyEquipmentEmptyReason == 'exercise_not_found'
          ? "We couldn't find this exercise in our library. Try AI Picks for a creative substitute."
          : "No muscle-similar alternatives in our library yet. Try AI Picks for a creative suggestion.";
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
              child: const Icon(Icons.fitness_center_rounded,
                  size: 40, color: accentColor),
            ),
            const SizedBox(height: 16),
            Text(
              'No alternatives yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                body,
                style: TextStyle(fontSize: 13, color: textMuted),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _loadAnyEquipmentExercises,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Try Again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: accentColor,
                side: BorderSide(color: accentColor.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Compute which equipment the user actually owns so each row can show
    // an "In your gym" vs the equipment name. Cheap — runs once per build.
    final ownedEquipment = ref
        .read(environmentEquipmentProvider)
        .equipment
        .map((e) => e.toLowerCase())
        .toSet();

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.viewPaddingOf(context).bottom + 16,
      ),
      itemCount: _anyEquipmentSuggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _anyEquipmentSuggestions[index];
        final name = (suggestion['name'] as String?) ?? 'Exercise';
        final reason = (suggestion['reason'] as String?) ?? '';
        final equipment = (suggestion['equipment'] as String?) ?? '';
        final targetMuscle = (suggestion['target_muscle'] as String?) ??
            (suggestion['body_part'] as String?) ??
            '';

        final subtitle = reason.isNotEmpty
            ? reason
            : [targetMuscle, equipment]
                .where((s) => s.isNotEmpty)
                .join(' • ');

        // Badge: highlight rows whose equipment the user actually owns so
        // the cross-equipment list still surfaces "you can do this right
        // now" candidates near the top.
        final equipLower = equipment.toLowerCase();
        final owns = equipLower.isNotEmpty &&
            ownedEquipment.any((e) =>
                e == equipLower || equipLower.contains(e) || e.contains(equipLower));
        final badge = owns
            ? 'In your gym'
            : (equipment.isNotEmpty ? equipment : 'Alternative');
        final badgeColor = owns ? AppColors.success : AppColors.purple;

        return _ExerciseOptionCard(
          name: name,
          subtitle: subtitle,
          badge: badge,
          badgeColor: badgeColor,
          onTap: () =>
              _swapExercise(name, source: 'any_equipment_exercise'),
          textPrimary: textPrimary,
          textMuted: textMuted,
          highlighted: _isHighlighted(name),
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
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.viewPaddingOf(context).bottom + 16,
      ),
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
          highlighted: _isHighlighted(name),
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
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.viewPaddingOf(context).bottom + 16,
      ),
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
      highlighted: _isHighlighted(exercise.name),
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

