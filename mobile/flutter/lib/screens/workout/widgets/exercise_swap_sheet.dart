import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/workout.dart';
import '../../../data/models/exercise.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/repositories/library_repository.dart';
import '../../../data/repositories/exercise_preferences_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../widgets/exercise_image.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/segmented_tab_bar.dart';

/// Shows exercise swap sheet with fast DB suggestions and optional AI picks
Future<Workout?> showExerciseSwapSheet(
  BuildContext context,
  WidgetRef ref, {
  required String workoutId,
  required WorkoutExercise exercise,
}) async {
  return await showGlassSheet<Workout>(
    context: context,
    builder: (context) => GlassSheet(
      showHandle: false,
      child: _ExerciseSwapSheet(
        workoutId: workoutId,
        exercise: exercise,
      ),
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

  // Similar tab (fast DB queries)
  bool _isLoadingSimilar = true;
  List<Map<String, dynamic>> _similarExercises = [];

  // AI Picks tab (slow AI suggestions)
  bool _isLoadingAI = false;
  bool _aiLoaded = false;
  List<Map<String, dynamic>> _aiSuggestions = [];

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
    setState(() => _isLoadingSimilar = true);

    try {
      final userId = await ref.read(apiClientProvider).getUserId();
      final repo = ref.read(workoutRepositoryProvider);

      final suggestions = await repo.getExerciseSuggestionsFast(
        exerciseName: widget.exercise.name,
        userId: userId!,
        avoidedExercises: _avoidedExerciseNames,
      );

      if (mounted) {
        setState(() {
          _similarExercises = suggestions;
          _isLoadingSimilar = false;
        });
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

  /// Load slow AI-powered suggestions (~10s) - only called when AI tab is selected
  /// Uses user's text/voice input if provided, otherwise uses selected reason chip
  Future<void> _loadAISuggestions() async {
    setState(() => _isLoadingAI = true);

    try {
      final userId = await ref.read(apiClientProvider).getUserId();
      final repo = ref.read(workoutRepositoryProvider);

      // Build message for AI: prefer user input, then reason chip, then default
      String? message;
      final userInput = _aiInputController.text.trim();
      if (userInput.isNotEmpty) {
        message = userInput;
      } else if (_selectedReason != null) {
        message = _selectedReason;
      }
      // If no message, AI will use default behavior

      final suggestions = await repo.getExerciseSuggestions(
        workoutId: widget.workoutId,
        exercise: widget.exercise,
        userId: userId!,
        reason: message,
        avoidedExercises: _avoidedExerciseNames,
      );

      if (mounted) {
        setState(() {
          _aiSuggestions = suggestions;
          _isLoadingAI = false;
          _aiLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading AI suggestions: $e');
      if (mounted) {
        setState(() {
          _aiSuggestions = [];
          _isLoadingAI = false;
          _aiLoaded = true;
        });
      }
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
    final updatedWorkout = await repo.swapExercise(
      workoutId: widget.workoutId,
      oldExerciseName: widget.exercise.name,
      newExerciseName: newExerciseName,
      reason: _selectedReason,
      swapSource: source,
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
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fitness_center, size: 48, color: textMuted),
            const SizedBox(height: 16),
            Text(
              'No similar exercises found',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadSimilarExercises,
              child: const Text('Try Again'),
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

        // Badge text based on rank
        String badge;
        Color badgeColor;
        if (rank == 1) {
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
          onTap: () => _swapExercise(name, source: 'similar_exercise'),
          textPrimary: textPrimary,
          textMuted: textMuted,
        );
      },
    );
  }

  /// AI Picks tab - slow AI-powered suggestions (~10s)
  /// Now includes text + voice input for custom requests
  Widget _buildAITab(Color textMuted, Color textPrimary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackground =
        isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Column(
      children: [
        // Input field with mic and search buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _aiInputController,
                  decoration: InputDecoration(
                    hintText: 'e.g., "I only have dumbbells"',
                    hintStyle: TextStyle(color: textMuted, fontSize: 14),
                    filled: true,
                    fillColor: cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: TextStyle(color: textPrimary),
                  onSubmitted: (_) {
                    setState(() => _aiLoaded = false);
                    _loadAISuggestions();
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Mic button
              GestureDetector(
                onTap: _isSpeechAvailable || !_isListening
                    ? _toggleListening
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isListening
                        ? AppColors.cyan
                        : (_isSpeechAvailable
                            ? cardBackground
                            : cardBackground.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _isListening
                        ? [
                            BoxShadow(
                              color: AppColors.cyan.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening
                        ? Colors.white
                        : (_isSpeechAvailable ? textMuted : textMuted.withOpacity(0.5)),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Search button
              GestureDetector(
                onTap: _isLoadingAI
                    ? null
                    : () {
                        setState(() => _aiLoaded = false);
                        _loadAISuggestions();
                      },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isLoadingAI
                        ? AppColors.cyan.withOpacity(0.5)
                        : AppColors.cyan,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isLoadingAI ? Icons.hourglass_empty : Icons.search,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Listening indicator
        if (_isListening)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.cyan,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cyan.withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Listening... speak now',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.cyan,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        // Loading state
        if (_isLoadingAI)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.cyan),
                  const SizedBox(height: 16),
                  Text(
                    'Getting AI suggestions...',
                    style: TextStyle(color: textMuted),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This may take 10-15 seconds',
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          )
        // Not loaded yet - show prompt
        else if (!_aiLoaded)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 48,
                      color: AppColors.cyan.withOpacity(0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ask AI for suggestions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Describe your equipment or preferences\ne.g., "I have a bad shoulder" or "bodyweight only"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: textMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        _loadAISuggestions();
                      },
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: const Text('Get AI Suggestions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyan,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        // Empty state
        else if (_aiSuggestions.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 48, color: textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'No AI suggestions available',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() => _aiLoaded = false);
                      _loadAISuggestions();
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          )
        // Results list
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _aiSuggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _aiSuggestions[index];
                final name = suggestion['name'] ?? 'Exercise';
                final reason = suggestion['reason'] ?? '';
                final rank = suggestion['rank'] ?? (index + 1);
                final equipment = suggestion['equipment'] ?? '';
                final targetMuscle =
                    suggestion['target_muscle'] ?? suggestion['body_part'] ?? '';

                // Create subtitle from reason or equipment/muscle info
                final subtitle = reason.isNotEmpty
                    ? reason
                    : [targetMuscle, equipment]
                        .where((s) => s.isNotEmpty)
                        .join(' • ');

                // Badge text based on rank
                String badge;
                Color badgeColor;
                if (rank == 1) {
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
                  onTap: () => _swapExercise(name, source: 'ai_suggestion'),
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                );
              },
            ),
          ),
      ],
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
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _libraryExercises.length,
                      itemBuilder: (context, index) {
                        final exercise = _libraryExercises[index];
                        return _ExerciseOptionCard(
                          name: exercise.name,
                          subtitle:
                              exercise.targetMuscle ?? exercise.bodyPart ?? '',
                          badge: exercise.equipment ?? 'Bodyweight',
                          badgeColor: AppColors.purple,
                          onTap: () => _swapExercise(exercise.name,
                              source: 'library_search'),
                          textPrimary: textPrimary,
                          textMuted: textMuted,
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _ExerciseOptionCard extends ConsumerWidget {
  final String name;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final VoidCallback onTap;
  final Color textPrimary;
  final Color textMuted;

  const _ExerciseOptionCard({
    required this.name,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.onTap,
    required this.textPrimary,
    required this.textMuted,
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
                // Exercise image (fetches presigned URL from API)
                ExerciseImage(
                  exerciseName: name,
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
