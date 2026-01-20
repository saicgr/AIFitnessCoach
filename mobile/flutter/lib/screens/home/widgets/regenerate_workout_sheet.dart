import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/workout.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../widgets/main_shell.dart';
import 'components/components.dart';
import 'workout_review_sheet.dart';

/// Shows a bottom sheet for regenerating workout with customization options
Future<Workout?> showRegenerateWorkoutSheet(
  BuildContext context,
  WidgetRef ref,
  Workout workout,
) async {
  final parentTheme = Theme.of(context);

  // Hide nav bar while sheet is open
  ref.read(floatingNavBarVisibleProvider.notifier).state = false;

  return showModalBottomSheet<Workout>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.2),
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (sheetContext) => Theme(
      data: parentTheme,
      child: _RegenerateWorkoutSheet(workout: workout),
    ),
  ).whenComplete(() {
    // Show nav bar when sheet is closed
    ref.read(floatingNavBarVisibleProvider.notifier).state = true;
  });
}

class _RegenerateWorkoutSheet extends ConsumerStatefulWidget {
  final Workout workout;

  const _RegenerateWorkoutSheet({required this.workout});

  @override
  ConsumerState<_RegenerateWorkoutSheet> createState() =>
      _RegenerateWorkoutSheetState();
}

class _RegenerateWorkoutSheetState
    extends ConsumerState<_RegenerateWorkoutSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isRegenerating = false;
  String _selectedDifficulty = 'medium';
  double _selectedDurationMin = 45;
  double _selectedDurationMax = 60;
  String? _selectedWorkoutType;
  final Set<String> _selectedFocusAreas = {};
  final Set<String> _selectedInjuries = {};
  final Set<String> _selectedEquipment = {};

  // Streaming progress state
  int _currentStep = 0;
  int _totalSteps = 4;
  String _progressMessage = '';
  String? _progressDetail;

  // Custom inputs
  String _customFocusArea = '';
  String _customInjury = '';
  String _customEquipment = '';
  String _customWorkoutType = '';
  bool _showFocusAreaInput = false;
  bool _showInjuryInput = false;
  bool _showEquipmentInput = false;
  bool _showWorkoutTypeInput = false;

  // Equipment quantities
  int _dumbbellCount = 2;
  int _kettlebellCount = 1;

  final TextEditingController _focusAreaController = TextEditingController();
  final TextEditingController _injuryController = TextEditingController();
  final TextEditingController _equipmentController = TextEditingController();
  final TextEditingController _workoutTypeController = TextEditingController();

  // AI Suggestions
  final TextEditingController _aiPromptController = TextEditingController();
  final FocusNode _aiPromptFocusNode = FocusNode();
  List<Map<String, dynamic>> _aiSuggestions = [];
  bool _isLoadingSuggestions = false;
  int? _selectedSuggestionIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeFromWorkout();
    _tabController.addListener(() {
      if (_tabController.index == 1 &&
          _aiSuggestions.isEmpty &&
          !_isLoadingSuggestions) {
        _loadAISuggestions();
      }
    });
  }

  void _initializeFromWorkout() {
    _selectedDifficulty = widget.workout.difficulty?.toLowerCase() ?? 'medium';
    final workoutDuration = (widget.workout.durationMinutes ?? 45).toDouble();
    _selectedDurationMin = workoutDuration;
    _selectedDurationMax = (workoutDuration + 15).clamp(15, 90);
    _selectedWorkoutType = widget.workout.type;

    final type = widget.workout.type?.toLowerCase() ?? '';
    if (type.contains('upper')) {
      _selectedFocusAreas.addAll(['Chest', 'Back', 'Shoulders', 'Arms']);
    } else if (type.contains('lower')) {
      _selectedFocusAreas.addAll(['Legs', 'Glutes']);
    } else if (type.contains('core')) {
      _selectedFocusAreas.add('Core');
    } else {
      _selectedFocusAreas.add('Full Body');
    }

    for (final eq in widget.workout.equipmentNeeded) {
      if (defaultEquipmentOptions.contains(eq)) {
        _selectedEquipment.add(eq);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _focusAreaController.dispose();
    _injuryController.dispose();
    _equipmentController.dispose();
    _workoutTypeController.dispose();
    _aiPromptController.dispose();
    _aiPromptFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadAISuggestions() async {
    setState(() => _isLoadingSuggestions = true);

    try {
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;
      if (userId == null) {
        setState(() => _isLoadingSuggestions = false);
        return;
      }

      final repo = ref.read(workoutRepositoryProvider);
      final suggestions = await repo.getWorkoutSuggestions(
        workoutId: widget.workout.id!,
        userId: userId,
        currentWorkoutType: widget.workout.type,
        prompt: _aiPromptController.text.trim().isEmpty
            ? null
            : _aiPromptController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _aiSuggestions = suggestions;
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading AI suggestions: $e');
      if (mounted) {
        setState(() => _isLoadingSuggestions = false);
      }
    }
  }

  Future<void> _regenerate() async {
    setState(() {
      _isRegenerating = true;
      _currentStep = 0;
      _progressMessage = 'Starting...';
      _progressDetail = null;
    });

    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      setState(() => _isRegenerating = false);
      return;
    }

    try {
      final allFocusAreas = _selectedFocusAreas.toList();
      if (_customFocusArea.isNotEmpty) {
        allFocusAreas.add(_customFocusArea);
      }

      final allInjuries = _selectedInjuries.toList();
      if (_customInjury.isNotEmpty) {
        allInjuries.add(_customInjury);
      }

      final allEquipment = _selectedEquipment.toList();
      if (_customEquipment.isNotEmpty) {
        allEquipment.add(_customEquipment);
      }

      final workoutType = _customWorkoutType.isNotEmpty
          ? _customWorkoutType
          : _selectedWorkoutType;

      final repo = ref.read(workoutRepositoryProvider);

      // Use streaming for real-time progress updates
      await for (final progress in repo.regenerateWorkoutStreaming(
        workoutId: widget.workout.id!,
        userId: userId,
        difficulty: _selectedDifficulty,
        durationMinutesMin: _selectedDurationMin.round(),
        durationMinutesMax: _selectedDurationMax.round(),
        focusAreas: allFocusAreas,
        injuries: allInjuries,
        equipment: allEquipment.isNotEmpty ? allEquipment : null,
        workoutType: workoutType,
        dumbbellCount:
            _selectedEquipment.contains('Dumbbells') ? _dumbbellCount : null,
        kettlebellCount:
            _selectedEquipment.contains('Kettlebell') ? _kettlebellCount : null,
      )) {
        if (!mounted) return;

        if (progress.hasError) {
          setState(() => _isRegenerating = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to regenerate: ${progress.message}'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }

        if (progress.isCompleted && progress.workout != null) {
          // Update progress to show we're loading the review
          setState(() {
            _progressMessage = 'Loading review...';
            _progressDetail = 'Preparing your workout';
          });

          // Show review sheet for user to approve
          final approvedWorkout = await showWorkoutReviewSheet(
            context,
            ref,
            progress.workout!,
          );

          if (approvedWorkout != null && mounted) {
            // User approved - close everything
            Navigator.pop(context, approvedWorkout);
          } else if (mounted) {
            // User pressed Back - return to customize with form preserved
            setState(() => _isRegenerating = false);
          }
          return;
        }

        // Update progress UI
        setState(() {
          _currentStep = progress.step;
          _totalSteps = progress.totalSteps;
          _progressMessage = progress.message;
          _progressDetail = progress.detail;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRegenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to regenerate: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _applyAISuggestion() async {
    if (_selectedSuggestionIndex == null ||
        _selectedSuggestionIndex! >= _aiSuggestions.length) {
      return;
    }

    setState(() {
      _isRegenerating = true;
      _currentStep = 0;
      _progressMessage = 'Applying suggestion...';
      _progressDetail = null;
    });

    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      setState(() => _isRegenerating = false);
      return;
    }

    try {
      final suggestion = _aiSuggestions[_selectedSuggestionIndex!];
      final repo = ref.read(workoutRepositoryProvider);

      // Use streaming for real-time progress updates
      await for (final progress in repo.regenerateWorkoutStreaming(
        workoutId: widget.workout.id!,
        userId: userId,
        difficulty: suggestion['difficulty'] ?? _selectedDifficulty,
        durationMinutesMin:
            suggestion['duration_minutes'] ?? _selectedDurationMin.round(),
        durationMinutesMax:
            suggestion['duration_minutes'] ?? _selectedDurationMax.round(),
        focusAreas:
            (suggestion['focus_areas'] as List?)?.cast<String>() ?? [],
        workoutType: suggestion['type'],
        aiPrompt: _aiPromptController.text.trim().isEmpty
            ? null
            : _aiPromptController.text.trim(),
        workoutName: suggestion['name'] as String?,
      )) {
        if (!mounted) return;

        if (progress.hasError) {
          setState(() => _isRegenerating = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to apply suggestion: ${progress.message}'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }

        if (progress.isCompleted && progress.workout != null) {
          // Update progress to show we're loading the review
          setState(() {
            _progressMessage = 'Loading review...';
            _progressDetail = 'Preparing your workout';
          });

          // Show review sheet for user to approve
          final approvedWorkout = await showWorkoutReviewSheet(
            context,
            ref,
            progress.workout!,
          );

          if (approvedWorkout != null && mounted) {
            // User approved - close everything
            Navigator.pop(context, approvedWorkout);
          } else if (mounted) {
            // User pressed Back - return to customize with form preserved
            setState(() => _isRegenerating = false);
          }
          return;
        }

        // Update progress UI
        setState(() {
          _currentStep = progress.step;
          _totalSteps = progress.totalSteps;
          _progressMessage = progress.message;
          _progressDetail = progress.detail;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRegenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to apply suggestion: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.sheetColors;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.6),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(colors),
                _buildTabBar(colors),
                const SizedBox(height: 8),
                Divider(height: 1, color: colors.cardBorder),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCustomizeTab(colors),
                      _buildAISuggestionsTab(colors),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(SheetColors colors) {
    return Column(
      children: [
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.textMuted.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: colors.purple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Regenerate Current Workout',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Customize or let AI suggest',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed:
                    _isRegenerating ? null : () => Navigator.pop(context),
                icon: Icon(Icons.close, color: colors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(SheetColors colors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: colors.glassSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: colors.purple,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: colors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(text: 'Customize'),
          Tab(text: 'AI Suggestions'),
        ],
      ),
    );
  }

  Widget _buildCustomizeTab(SheetColors colors) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WorkoutTypeSelector(
            selectedType: _selectedWorkoutType,
            onSelectionChanged: (type) {
              setState(() {
                _selectedWorkoutType = type;
                _customWorkoutType = '';
              });
            },
            customWorkoutType: _customWorkoutType,
            showCustomInput: _showWorkoutTypeInput,
            onToggleCustomInput: () =>
                setState(() => _showWorkoutTypeInput = !_showWorkoutTypeInput),
            onCustomTypeSaved: (value) {
              setState(() {
                _customWorkoutType = value;
                _selectedWorkoutType = null;
                _showWorkoutTypeInput = false;
              });
            },
            customInputController: _workoutTypeController,
            disabled: _isRegenerating,
          ),
          DifficultySelector(
            selectedDifficulty: _selectedDifficulty,
            onSelectionChanged: (d) =>
                setState(() => _selectedDifficulty = d),
            disabled: _isRegenerating,
            showIcons: false,
          ),
          DurationRangeSlider(
            durationMin: _selectedDurationMin,
            durationMax: _selectedDurationMax,
            onChanged: (range) => setState(() {
              _selectedDurationMin = range.start;
              _selectedDurationMax = range.end;
            }),
            disabled: _isRegenerating,
          ),
          const SizedBox(height: 20),
          EquipmentSelector(
            selectedEquipment: _selectedEquipment,
            onSelectionChanged: (eq) =>
                setState(() {
                  _selectedEquipment.clear();
                  _selectedEquipment.addAll(eq);
                }),
            customEquipment: _customEquipment,
            showCustomInput: _showEquipmentInput,
            onToggleCustomInput: () =>
                setState(() => _showEquipmentInput = !_showEquipmentInput),
            onCustomEquipmentSaved: (value) {
              setState(() {
                _customEquipment = value;
                _showEquipmentInput = false;
              });
            },
            dumbbellCount: _dumbbellCount,
            kettlebellCount: _kettlebellCount,
            onDumbbellCountChanged: (c) =>
                setState(() => _dumbbellCount = c),
            onKettlebellCountChanged: (c) =>
                setState(() => _kettlebellCount = c),
            customInputController: _equipmentController,
            disabled: _isRegenerating,
          ),
          const SizedBox(height: 20),
          FocusAreasSelector(
            selectedAreas: _selectedFocusAreas,
            onSelectionChanged: (areas) =>
                setState(() {
                  _selectedFocusAreas.clear();
                  _selectedFocusAreas.addAll(areas);
                }),
            customFocusArea: _customFocusArea,
            showCustomInput: _showFocusAreaInput,
            onToggleCustomInput: () =>
                setState(() => _showFocusAreaInput = !_showFocusAreaInput),
            onCustomFocusAreaSaved: (value) {
              setState(() {
                _customFocusArea = value;
                _showFocusAreaInput = false;
              });
            },
            customInputController: _focusAreaController,
            disabled: _isRegenerating,
          ),
          const SizedBox(height: 20),
          InjuriesSelector(
            selectedInjuries: _selectedInjuries,
            onSelectionChanged: (injuries) =>
                setState(() {
                  _selectedInjuries.clear();
                  _selectedInjuries.addAll(injuries);
                }),
            customInjury: _customInjury,
            showCustomInput: _showInjuryInput,
            onToggleCustomInput: () =>
                setState(() => _showInjuryInput = !_showInjuryInput),
            onCustomInjurySaved: (value) {
              setState(() {
                _customInjury = value;
                _showInjuryInput = false;
              });
            },
            customInputController: _injuryController,
            disabled: _isRegenerating,
          ),
          const SizedBox(height: 24),
          _buildRegenerateButton(colors),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAISuggestionsTab(SheetColors colors) {
    return Column(
      children: [
        _buildAIPromptInput(colors),
        Divider(height: 1, color: colors.cardBorder),
        Expanded(
          child: _isLoadingSuggestions
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: AppColors.cyan),
                      const SizedBox(height: 16),
                      Text(
                        'Generating suggestions...',
                        style: TextStyle(color: colors.textMuted),
                      ),
                    ],
                  ),
                )
              : _aiSuggestions.isEmpty
                  ? _buildEmptySuggestionsState(colors)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _aiSuggestions.length,
                      itemBuilder: (context, index) {
                        return AISuggestionCard(
                          suggestion: _aiSuggestions[index],
                          index: index,
                          isSelected: _selectedSuggestionIndex == index,
                          onTap: () {
                            setState(() {
                              _selectedSuggestionIndex =
                                  _selectedSuggestionIndex == index
                                      ? null
                                      : index;
                            });
                          },
                        );
                      },
                    ),
        ),
        if (_selectedSuggestionIndex != null) _buildApplyButton(colors),
      ],
    );
  }

  Widget _buildAIPromptInput(SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.chat_bubble_outline, size: 18, color: colors.cyan),
              const SizedBox(width: 8),
              Text(
                'Describe your ideal workout',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _aiPromptController,
            focusNode: _aiPromptFocusNode,
            maxLines: 2,
            enabled: !_isRegenerating,
            autofocus: false,
            textInputAction: TextInputAction.send,
            keyboardType: TextInputType.text,
            style: TextStyle(color: colors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText:
                  'e.g., "A quick upper body workout with no equipment"',
              hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
              filled: true,
              fillColor: colors.glassSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: colors.cardBorder.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.cyan, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: IconButton(
                icon: Icon(
                  Icons.send_rounded,
                  color: _aiPromptController.text.isEmpty
                      ? colors.textMuted
                      : colors.cyan,
                ),
                onPressed: _isLoadingSuggestions ? null : _loadAISuggestions,
              ),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _loadAISuggestions(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySuggestionsState(SheetColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 64,
              color: colors.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No suggestions yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter a prompt above or tap refresh to get AI-powered workout suggestions',
              style: TextStyle(fontSize: 14, color: colors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _isLoadingSuggestions ? null : _loadAISuggestions,
              icon: const Icon(Icons.refresh),
              label: const Text('Get Suggestions'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.cyan,
                side: BorderSide(color: colors.cyan),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegenerateButton(SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Progress indicator when regenerating
          if (_isRegenerating) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _totalSteps > 0 ? _currentStep / _totalSteps : null,
                backgroundColor: colors.glassSurface,
                valueColor: AlwaysStoppedAnimation<Color>(colors.purple),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _progressMessage,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            if (_progressDetail != null) ...[
              const SizedBox(height: 4),
              Text(
                _progressDetail!,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textMuted,
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isRegenerating ? null : _regenerate,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                disabledBackgroundColor: colors.purple.withOpacity(0.6),
              ),
              child: _isRegenerating
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Step $_currentStep of $_totalSteps',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Regenerate Workout',
                          style:
                              TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton(SheetColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.elevated,
        border: Border(top: BorderSide(color: colors.cardBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress indicator when applying
          if (_isRegenerating) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _totalSteps > 0 ? _currentStep / _totalSteps : null,
                backgroundColor: colors.glassSurface,
                valueColor: AlwaysStoppedAnimation<Color>(colors.cyan),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _progressMessage,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            if (_progressDetail != null) ...[
              const SizedBox(height: 4),
              Text(
                _progressDetail!,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textMuted,
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isRegenerating ? null : _applyAISuggestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.cyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                disabledBackgroundColor: colors.cyan.withOpacity(0.6),
              ),
              child: _isRegenerating
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Step $_currentStep of $_totalSteps',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Apply This Workout',
                          style:
                              TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// String extension for capitalize
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
