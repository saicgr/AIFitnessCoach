import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/models/workout.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/repositories/auth_repository.dart';

/// Shows a bottom sheet for regenerating workout with customization options
Future<Workout?> showRegenerateWorkoutSheet(
  BuildContext context,
  WidgetRef ref,
  Workout workout,
) async {
  // Capture the parent theme to ensure proper inheritance in the modal
  final parentTheme = Theme.of(context);

  return showModalBottomSheet<Workout>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true, // Ensures sheet renders above floating overlays
    builder: (sheetContext) => Theme(
      data: parentTheme,
      child: _RegenerateWorkoutSheet(workout: workout),
    ),
  );
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
  double _selectedDuration = 45;
  String? _selectedWorkoutType;
  final Set<String> _selectedFocusAreas = {};
  final Set<String> _selectedInjuries = {};
  final Set<String> _selectedEquipment = {};

  // Custom "Other" inputs
  String _customFocusArea = '';
  String _customInjury = '';
  String _customEquipment = '';
  String _customWorkoutType = '';
  bool _showFocusAreaInput = false;
  bool _showInjuryInput = false;
  bool _showEquipmentInput = false;
  bool _showWorkoutTypeInput = false;

  // Equipment quantity selectors (1 or 2)
  int _dumbbellCount = 2;
  int _kettlebellCount = 1;

  final TextEditingController _focusAreaController = TextEditingController();
  final TextEditingController _injuryController = TextEditingController();
  final TextEditingController _equipmentController = TextEditingController();
  final TextEditingController _workoutTypeController = TextEditingController();

  // AI Suggestions tab state
  final TextEditingController _aiPromptController = TextEditingController();
  final FocusNode _aiPromptFocusNode = FocusNode();
  List<Map<String, dynamic>> _aiSuggestions = [];
  bool _isLoadingSuggestions = false;
  int? _selectedSuggestionIndex;

  final List<String> _difficulties = ['easy', 'medium', 'hard'];
  final List<String> _workoutTypes = [
    'Strength',
    'HIIT',
    'Cardio',
    'Flexibility',
    'Full Body',
    'Upper Body',
    'Lower Body',
    'Core',
  ];
  final List<String> _focusAreas = [
    'Chest',
    'Back',
    'Shoulders',
    'Arms',
    'Core',
    'Legs',
    'Glutes',
    'Full Body',
  ];
  final List<String> _injuries = [
    'Shoulder',
    'Lower Back',
    'Knee',
    'Elbow',
    'Wrist',
    'Ankle',
    'Hip',
    'Neck',
  ];
  final List<String> _equipmentOptions = [
    'Full Gym',
    'Dumbbells',
    'Barbell',
    'Kettlebell',
    'Resistance Bands',
    'Pull-up Bar',
    'Bench',
    'Cable Machine',
    'Bodyweight Only',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize with current workout values
    _selectedDifficulty = widget.workout.difficulty?.toLowerCase() ?? 'medium';
    _selectedDuration = (widget.workout.durationMinutes ?? 45).toDouble();
    _selectedWorkoutType = widget.workout.type;

    // Pre-select focus areas based on workout type
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

    // Pre-select equipment from workout
    if (widget.workout.equipmentNeeded.isNotEmpty) {
      for (final eq in widget.workout.equipmentNeeded) {
        if (_equipmentOptions.contains(eq)) {
          _selectedEquipment.add(eq);
        }
      }
    }

    // Load AI suggestions when switching to AI tab
    _tabController.addListener(() {
      if (_tabController.index == 1 && _aiSuggestions.isEmpty && !_isLoadingSuggestions) {
        _loadAISuggestions();
      }
    });
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
        prompt: _aiPromptController.text.trim().isEmpty ? null : _aiPromptController.text.trim(),
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
    setState(() => _isRegenerating = true);

    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      setState(() => _isRegenerating = false);
      return;
    }

    try {
      // Combine selected focus areas with custom one
      final allFocusAreas = _selectedFocusAreas.toList();
      if (_customFocusArea.isNotEmpty) {
        allFocusAreas.add(_customFocusArea);
      }

      // Combine selected injuries with custom one
      final allInjuries = _selectedInjuries.toList();
      if (_customInjury.isNotEmpty) {
        allInjuries.add(_customInjury);
      }

      // Combine selected equipment with custom one
      final allEquipment = _selectedEquipment.toList();
      if (_customEquipment.isNotEmpty) {
        allEquipment.add(_customEquipment);
      }

      // Use custom workout type if entered, otherwise selected
      final workoutType = _customWorkoutType.isNotEmpty
          ? _customWorkoutType
          : _selectedWorkoutType;

      final repo = ref.read(workoutRepositoryProvider);
      final newWorkout = await repo.regenerateWorkout(
        workoutId: widget.workout.id!,
        userId: userId,
        difficulty: _selectedDifficulty,
        durationMinutes: _selectedDuration.round(),
        focusAreas: allFocusAreas,
        injuries: allInjuries,
        equipment: allEquipment.isNotEmpty ? allEquipment : null,
        workoutType: workoutType,
      );

      if (mounted) {
        Navigator.pop(context, newWorkout);
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
    if (_selectedSuggestionIndex == null || _selectedSuggestionIndex! >= _aiSuggestions.length) {
      return;
    }

    setState(() => _isRegenerating = true);

    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      setState(() => _isRegenerating = false);
      return;
    }

    try {
      final suggestion = _aiSuggestions[_selectedSuggestionIndex!];
      final repo = ref.read(workoutRepositoryProvider);

      // Regenerate with the AI suggestion parameters, including the workout name
      final newWorkout = await repo.regenerateWorkout(
        workoutId: widget.workout.id!,
        userId: userId,
        difficulty: suggestion['difficulty'] ?? _selectedDifficulty,
        durationMinutes: suggestion['duration_minutes'] ?? _selectedDuration.round(),
        focusAreas: (suggestion['focus_areas'] as List?)?.cast<String>() ?? [],
        workoutType: suggestion['type'],
        aiPrompt: _aiPromptController.text.trim().isEmpty ? null : _aiPromptController.text.trim(),
        workoutName: suggestion['name'] as String?,  // Pass the suggestion name
      );

      if (mounted) {
        Navigator.pop(context, newWorkout);
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
    // Use actual brightness to support ThemeMode.system
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final _SheetColors colors = isDark ? _DarkColors() : _LightColors();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? colors.elevated.withOpacity(0.85)
                : colors.elevated.withOpacity(0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
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

            // Header
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
                          'Regenerate Workout',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Customize or let AI suggest',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
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

            // Tab bar
            Container(
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
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                dividerColor: Colors.transparent,
                padding: const EdgeInsets.all(4),
                tabs: const [
                  Tab(text: 'Customize'),
                  Tab(text: 'AI Suggestions'),
                ],
              ),
            ),

            const SizedBox(height: 8),
            Divider(height: 1, color: colors.cardBorder),

            // Tab content
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

  Widget _buildCustomizeTab(_SheetColors colors) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Workout Type Selection
          _buildWorkoutTypeSection(colors),

          // Difficulty Selection
          _buildDifficultySection(colors),

          // Duration Selection (Slider)
          _buildDurationSection(colors),

          const SizedBox(height: 20),

          // Equipment Selection
          _buildEquipmentSection(colors),

          const SizedBox(height: 20),

          // Focus Areas Selection
          _buildFocusAreasSection(colors),

          const SizedBox(height: 20),

          // Injuries Section (Optional)
          _buildInjuriesSection(colors),

          const SizedBox(height: 24),

          // Regenerate Button
          _buildRegenerateButton(colors),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAISuggestionsTab(_SheetColors colors) {
    return Column(
      children: [
        // Prompt input at the top
        Padding(
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
                  hintText: 'e.g., "A quick upper body workout with no equipment"',
                  hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: colors.glassSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.cardBorder.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.cyan, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.send_rounded,
                      color: _aiPromptController.text.isEmpty ? colors.textMuted : colors.cyan,
                    ),
                    onPressed: _isLoadingSuggestions ? null : _loadAISuggestions,
                  ),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _loadAISuggestions(),
              ),
            ],
          ),
        ),

        Divider(height: 1, color: colors.cardBorder),

        // Suggestions list
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
                        return _buildSuggestionCard(colors, index);
                      },
                    ),
        ),

        // Apply button at bottom
        if (_selectedSuggestionIndex != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.elevated,
              border: Border(top: BorderSide(color: colors.cardBorder)),
            ),
            child: SizedBox(
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
                ),
                child: _isRegenerating
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Applying...',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptySuggestionsState(_SheetColors colors) {
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
              style: TextStyle(
                fontSize: 14,
                color: colors.textMuted,
              ),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(_SheetColors colors, int index) {
    final suggestion = _aiSuggestions[index];
    final isSelected = _selectedSuggestionIndex == index;
    final name = suggestion['name'] as String? ?? 'Workout ${index + 1}';
    final type = suggestion['type'] as String? ?? 'Strength';
    final difficulty = suggestion['difficulty'] as String? ?? 'medium';
    final duration = suggestion['duration_minutes'] as int? ?? 45;
    final description = suggestion['description'] as String? ?? '';
    final focusAreas = (suggestion['focus_areas'] as List?)?.cast<String>() ?? [];
    final sampleExercises = (suggestion['sample_exercises'] as List?)?.cast<String>() ?? [];

    final difficultyColor = _getDifficultyColor(difficulty);
    final typeColor = _getTypeColor(type);

    // Ranking label based on position
    String rankLabel;
    Color rankColor;
    IconData rankIcon;
    if (index == 0) {
      rankLabel = 'Best Match';
      rankColor = colors.success;
      rankIcon = Icons.star;
    } else if (index == 1) {
      rankLabel = '2nd Choice';
      rankColor = colors.cyan;
      rankIcon = Icons.thumb_up_outlined;
    } else if (index == 2) {
      rankLabel = '3rd Choice';
      rankColor = colors.orange;
      rankIcon = Icons.recommend_outlined;
    } else {
      rankLabel = '#${index + 1}';
      rankColor = colors.textMuted;
      rankIcon = Icons.tag;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSuggestionIndex = isSelected ? null : index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? colors.cyan.withOpacity(0.1) : colors.glassSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colors.cyan : colors.cardBorder.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ranking badge at the top
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: rankColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: index == 0 ? Border.all(color: rankColor.withOpacity(0.5), width: 1) : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(rankIcon, size: 14, color: rankColor),
                      const SizedBox(width: 4),
                      Text(
                        rankLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: rankColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colors.cyan,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 16, color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // Header with name
            Text(
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Tags row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTag(type, typeColor),
                _buildTag(difficulty.capitalize(), difficultyColor),
                _buildTag('$duration min', colors.orange),
              ],
            ),

            if (description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            if (focusAreas.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: focusAreas.map((area) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.purple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    area,
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.purple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )).toList(),
              ),
            ],

            // Sample exercises preview
            if (sampleExercises.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.glassSurface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.cardBorder.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.fitness_center, size: 14, color: colors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          'Exercises Preview',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: sampleExercises.map((exercise) => Text(
                        '• $exercise',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'hiit':
        return AppColors.error;
      case 'cardio':
        return AppColors.orange;
      case 'flexibility':
        return AppColors.purple;
      case 'strength':
      default:
        return AppColors.cyan;
    }
  }

  Widget _buildWorkoutTypeSection(_SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category, size: 20, color: colors.cyan),
              const SizedBox(width: 8),
              Text(
                'Workout Type',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._workoutTypes.map((type) {
                final isSelected = _selectedWorkoutType?.toLowerCase() == type.toLowerCase() &&
                    _customWorkoutType.isEmpty;
                return GestureDetector(
                  onTap: _isRegenerating
                      ? null
                      : () {
                          setState(() {
                            _selectedWorkoutType = isSelected ? null : type;
                            _customWorkoutType = ''; // Clear custom when selecting preset
                          });
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.cyan.withOpacity(0.2)
                          : colors.glassSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? colors.cyan
                            : colors.cardBorder.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        color: isSelected ? colors.cyan : colors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }),
              // "Other" chip
              GestureDetector(
                onTap: _isRegenerating
                    ? null
                    : () => setState(() => _showWorkoutTypeInput = !_showWorkoutTypeInput),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _customWorkoutType.isNotEmpty
                        ? colors.cyan.withOpacity(0.2)
                        : colors.glassSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _customWorkoutType.isNotEmpty
                          ? colors.cyan
                          : colors.cardBorder.withOpacity(0.3),
                      width: _customWorkoutType.isNotEmpty ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showWorkoutTypeInput ? Icons.close : Icons.add,
                        size: 14,
                        color: _customWorkoutType.isNotEmpty ? colors.cyan : colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _customWorkoutType.isNotEmpty ? _customWorkoutType : 'Other',
                        style: TextStyle(
                          color: _customWorkoutType.isNotEmpty ? colors.cyan : colors.textSecondary,
                          fontWeight: _customWorkoutType.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Custom input field
          if (_showWorkoutTypeInput) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _workoutTypeController,
              decoration: InputDecoration(
                hintText: 'Enter custom workout type (e.g., "Mobility")',
                hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
                filled: true,
                fillColor: colors.glassSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.cyan),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: IconButton(
                  icon: Icon(Icons.check, color: colors.cyan),
                  onPressed: () {
                    setState(() {
                      _customWorkoutType = _workoutTypeController.text.trim();
                      _selectedWorkoutType = null; // Clear preset selection
                      _showWorkoutTypeInput = false;
                    });
                  },
                ),
              ),
              style: TextStyle(color: colors.textPrimary),
              onSubmitted: (value) {
                setState(() {
                  _customWorkoutType = value.trim();
                  _selectedWorkoutType = null; // Clear preset selection
                  _showWorkoutTypeInput = false;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDifficultySection(_SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed, size: 20, color: colors.cyan),
              const SizedBox(width: 8),
              Text(
                'Difficulty',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: _difficulties.map((difficulty) {
              final isSelected = _selectedDifficulty == difficulty;
              final color = _getDifficultyColor(difficulty);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: difficulty != _difficulties.last ? 8 : 0,
                  ),
                  child: GestureDetector(
                    onTap: _isRegenerating
                        ? null
                        : () => setState(() => _selectedDifficulty = difficulty),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withOpacity(0.2) : colors.glassSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? color : colors.cardBorder.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          difficulty[0].toUpperCase() + difficulty.substring(1),
                          style: TextStyle(
                            color: isSelected ? color : colors.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationSection(_SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 20, color: colors.orange),
              const SizedBox(width: 8),
              Text(
                'Duration',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_selectedDuration.round()} min',
                  style: TextStyle(
                    color: colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colors.orange,
              inactiveTrackColor: colors.glassSurface,
              thumbColor: colors.orange,
              overlayColor: colors.orange.withOpacity(0.2),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: _selectedDuration,
              min: 15,
              max: 90,
              divisions: 15,
              onChanged: _isRegenerating
                  ? null
                  : (value) => setState(() => _selectedDuration = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('15 min', style: TextStyle(fontSize: 12, color: colors.textMuted)),
                Text('90 min', style: TextStyle(fontSize: 12, color: colors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentSection(_SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center, size: 20, color: colors.success),
              const SizedBox(width: 8),
              Text(
                'Equipment Available',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
              ),
              const Spacer(),
              if (_selectedEquipment.isNotEmpty || _customEquipment.isNotEmpty)
                Text(
                  '${_selectedEquipment.length + (_customEquipment.isNotEmpty ? 1 : 0)} selected',
                  style: TextStyle(color: colors.success, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Only generate exercises with selected equipment',
            style: TextStyle(fontSize: 12, color: colors.textMuted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._equipmentOptions.map((equipment) {
                final isSelected = _selectedEquipment.contains(equipment);
                final bool hasQuantitySelector = equipment == 'Dumbbells' || equipment == 'Kettlebell';

                return GestureDetector(
                  onTap: _isRegenerating
                      ? null
                      : () {
                          setState(() {
                            if (equipment == 'Full Gym') {
                              // Full Gym selects all equipment except Bodyweight Only
                              if (isSelected) {
                                _selectedEquipment.remove('Full Gym');
                              } else {
                                _selectedEquipment.add('Full Gym');
                                _selectedEquipment.addAll(_equipmentOptions.where((e) =>
                                  e != 'Bodyweight Only' && e != 'Full Gym'));
                              }
                            } else if (isSelected) {
                              _selectedEquipment.remove(equipment);
                              // Also remove Full Gym if any equipment is deselected
                              _selectedEquipment.remove('Full Gym');
                            } else {
                              _selectedEquipment.add(equipment);
                              // Check if all equipment selected (except Bodyweight Only and Full Gym)
                              final allEquipment = _equipmentOptions.where((e) =>
                                e != 'Bodyweight Only' && e != 'Full Gym');
                              if (allEquipment.every((e) => _selectedEquipment.contains(e))) {
                                _selectedEquipment.add('Full Gym');
                              }
                            }
                          });
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? colors.success.withOpacity(0.2) : colors.glassSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? colors.success : colors.cardBorder.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          Icon(Icons.check, size: 14, color: colors.success),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          equipment,
                          style: TextStyle(
                            color: isSelected ? colors.success : colors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                        // Quantity selector for Dumbbells and Kettlebell
                        if (hasQuantitySelector && isSelected) ...[
                          const SizedBox(width: 8),
                          _buildQuantitySelector(
                            equipment == 'Dumbbells' ? _dumbbellCount : _kettlebellCount,
                            (newValue) {
                              setState(() {
                                if (equipment == 'Dumbbells') {
                                  _dumbbellCount = newValue;
                                } else {
                                  _kettlebellCount = newValue;
                                }
                              });
                            },
                            colors,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              // "Other" chip
              GestureDetector(
                onTap: _isRegenerating
                    ? null
                    : () => setState(() => _showEquipmentInput = !_showEquipmentInput),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _customEquipment.isNotEmpty
                        ? colors.success.withOpacity(0.2)
                        : colors.glassSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _customEquipment.isNotEmpty
                          ? colors.success
                          : colors.cardBorder.withOpacity(0.3),
                      width: _customEquipment.isNotEmpty ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showEquipmentInput ? Icons.close : Icons.add,
                        size: 14,
                        color: _customEquipment.isNotEmpty ? colors.success : colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _customEquipment.isNotEmpty ? _customEquipment : 'Other',
                        style: TextStyle(
                          color: _customEquipment.isNotEmpty ? colors.success : colors.textSecondary,
                          fontWeight: _customEquipment.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Custom input field
          if (_showEquipmentInput) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _equipmentController,
              decoration: InputDecoration(
                hintText: 'Enter custom equipment (e.g., "TRX Bands")',
                hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
                filled: true,
                fillColor: colors.glassSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.success),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: IconButton(
                  icon: Icon(Icons.check, color: colors.success),
                  onPressed: () {
                    setState(() {
                      _customEquipment = _equipmentController.text.trim();
                      _showEquipmentInput = false;
                    });
                  },
                ),
              ),
              style: TextStyle(color: colors.textPrimary),
              onSubmitted: (value) {
                setState(() {
                  _customEquipment = value.trim();
                  _showEquipmentInput = false;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuantitySelector(int currentValue, Function(int) onChanged, _SheetColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.glassSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _isRegenerating || currentValue <= 1
                ? null
                : () => onChanged(currentValue - 1),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.remove,
                size: 14,
                color: currentValue <= 1 ? colors.textMuted : colors.success,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$currentValue',
              style: TextStyle(
                color: colors.success,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          GestureDetector(
            onTap: _isRegenerating || currentValue >= 2
                ? null
                : () => onChanged(currentValue + 1),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.add,
                size: 14,
                color: currentValue >= 2 ? colors.textMuted : colors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusAreasSection(_SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.track_changes, size: 20, color: colors.purple),
              const SizedBox(width: 8),
              Text(
                'Focus Areas',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
              ),
              const Spacer(),
              if (_selectedFocusAreas.isNotEmpty || _customFocusArea.isNotEmpty)
                Text(
                  '${_selectedFocusAreas.length + (_customFocusArea.isNotEmpty ? 1 : 0)} selected',
                  style: TextStyle(color: colors.purple, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._focusAreas.map((area) {
                final isSelected = _selectedFocusAreas.contains(area);
                return GestureDetector(
                  onTap: _isRegenerating
                      ? null
                      : () {
                          setState(() {
                            if (isSelected) {
                              _selectedFocusAreas.remove(area);
                            } else {
                              _selectedFocusAreas.add(area);
                            }
                          });
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? colors.purple.withOpacity(0.2) : colors.glassSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? colors.purple : colors.cardBorder.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          Icon(Icons.check, size: 14, color: colors.purple),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          area,
                          style: TextStyle(
                            color: isSelected ? colors.purple : colors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              // "Other" chip
              GestureDetector(
                onTap: _isRegenerating
                    ? null
                    : () => setState(() => _showFocusAreaInput = !_showFocusAreaInput),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _customFocusArea.isNotEmpty
                        ? colors.purple.withOpacity(0.2)
                        : colors.glassSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _customFocusArea.isNotEmpty
                          ? colors.purple
                          : colors.cardBorder.withOpacity(0.3),
                      width: _customFocusArea.isNotEmpty ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showFocusAreaInput ? Icons.close : Icons.add,
                        size: 14,
                        color: _customFocusArea.isNotEmpty ? colors.purple : colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _customFocusArea.isNotEmpty ? _customFocusArea : 'Other',
                        style: TextStyle(
                          color: _customFocusArea.isNotEmpty ? colors.purple : colors.textSecondary,
                          fontWeight: _customFocusArea.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Custom input field
          if (_showFocusAreaInput) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _focusAreaController,
              decoration: InputDecoration(
                hintText: 'Enter custom focus area (e.g., "Rotator cuff")',
                hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
                filled: true,
                fillColor: colors.glassSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.purple),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: IconButton(
                  icon: Icon(Icons.check, color: colors.purple),
                  onPressed: () {
                    setState(() {
                      _customFocusArea = _focusAreaController.text.trim();
                      _showFocusAreaInput = false;
                    });
                  },
                ),
              ),
              style: TextStyle(color: colors.textPrimary),
              onSubmitted: (value) {
                setState(() {
                  _customFocusArea = value.trim();
                  _showFocusAreaInput = false;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInjuriesSection(_SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.healing, size: 20, color: colors.error),
              const SizedBox(width: 8),
              Text(
                'Injuries to Consider',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
              ),
              const Spacer(),
              if (_selectedInjuries.isNotEmpty || _customInjury.isNotEmpty)
                Text(
                  '${_selectedInjuries.length + (_customInjury.isNotEmpty ? 1 : 0)} selected',
                  style: TextStyle(color: colors.error, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'AI will avoid exercises that may aggravate these areas',
            style: TextStyle(fontSize: 12, color: colors.textMuted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._injuries.map((injury) {
                final isSelected = _selectedInjuries.contains(injury);
                return GestureDetector(
                  onTap: _isRegenerating
                      ? null
                      : () {
                          setState(() {
                            if (isSelected) {
                              _selectedInjuries.remove(injury);
                            } else {
                              _selectedInjuries.add(injury);
                            }
                          });
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? colors.error.withOpacity(0.2) : colors.glassSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? colors.error : colors.cardBorder.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          Icon(Icons.check, size: 14, color: colors.error),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          injury,
                          style: TextStyle(
                            color: isSelected ? colors.error : colors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              // "Other" chip
              GestureDetector(
                onTap: _isRegenerating
                    ? null
                    : () => setState(() => _showInjuryInput = !_showInjuryInput),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _customInjury.isNotEmpty
                        ? colors.error.withOpacity(0.2)
                        : colors.glassSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _customInjury.isNotEmpty
                          ? colors.error
                          : colors.cardBorder.withOpacity(0.3),
                      width: _customInjury.isNotEmpty ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showInjuryInput ? Icons.close : Icons.add,
                        size: 14,
                        color: _customInjury.isNotEmpty ? colors.error : colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _customInjury.isNotEmpty ? _customInjury : 'Other',
                        style: TextStyle(
                          color: _customInjury.isNotEmpty ? colors.error : colors.textSecondary,
                          fontWeight: _customInjury.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Custom input field
          if (_showInjuryInput) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _injuryController,
              decoration: InputDecoration(
                hintText: 'Enter custom injury (e.g., "Tennis elbow")',
                hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
                filled: true,
                fillColor: colors.glassSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.error),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: IconButton(
                  icon: Icon(Icons.check, color: colors.error),
                  onPressed: () {
                    setState(() {
                      _customInjury = _injuryController.text.trim();
                      _showInjuryInput = false;
                    });
                  },
                ),
              ),
              style: TextStyle(color: colors.textPrimary),
              onSubmitted: (value) {
                setState(() {
                  _customInjury = value.trim();
                  _showInjuryInput = false;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRegenerateButton(_SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
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
          ),
          child: _isRegenerating
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Generating...',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppColors.success;
      case 'medium':
        return AppColors.orange;
      case 'hard':
        return AppColors.error;
      default:
        return AppColors.cyan;
    }
  }
}

/// Theme colors interface for the sheet
abstract class _SheetColors {
  Color get elevated;
  Color get textPrimary;
  Color get textSecondary;
  Color get textMuted;
  Color get cardBorder;
  Color get glassSurface;
  Color get cyan;
  Color get purple;
  Color get orange;
  Color get success;
  Color get error;
}

/// Dark theme colors for the sheet
class _DarkColors implements _SheetColors {
  @override Color get elevated => AppColors.elevated;
  @override Color get textPrimary => AppColors.textPrimary;
  @override Color get textSecondary => AppColors.textSecondary;
  @override Color get textMuted => AppColors.textMuted;
  @override Color get cardBorder => AppColors.cardBorder;
  @override Color get glassSurface => AppColors.glassSurface;
  @override Color get cyan => AppColors.cyan;
  @override Color get purple => AppColors.purple;
  @override Color get orange => AppColors.orange;
  @override Color get success => AppColors.success;
  @override Color get error => AppColors.error;
}

/// Light theme colors for the sheet
class _LightColors implements _SheetColors {
  @override Color get elevated => AppColorsLight.elevated;
  @override Color get textPrimary => AppColorsLight.textPrimary;
  @override Color get textSecondary => AppColorsLight.textSecondary;
  @override Color get textMuted => AppColorsLight.textMuted;
  @override Color get cardBorder => AppColorsLight.cardBorder;
  @override Color get glassSurface => AppColorsLight.glassSurface;
  @override Color get cyan => AppColorsLight.cyan;
  @override Color get purple => AppColors.purple;
  @override Color get orange => AppColors.orange;
  @override Color get success => AppColorsLight.success;
  @override Color get error => AppColorsLight.error;
}

/// String extension for capitalize
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
