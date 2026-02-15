import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise.dart';
import '../../../widgets/glass_sheet.dart';
import 'superset_exercise_picker.dart';

/// Superset type definitions
enum SupersetType {
  antagonist,
  compound,
  preExhaust,
  custom,
}

extension SupersetTypeExtension on SupersetType {
  String get label {
    switch (this) {
      case SupersetType.antagonist:
        return 'Antagonist';
      case SupersetType.compound:
        return 'Compound';
      case SupersetType.preExhaust:
        return 'Pre-exhaust';
      case SupersetType.custom:
        return 'Custom';
    }
  }

  String get description {
    switch (this) {
      case SupersetType.antagonist:
        return 'Different muscle groups';
      case SupersetType.compound:
        return 'Same muscle group';
      case SupersetType.preExhaust:
        return 'Isolation then compound';
      case SupersetType.custom:
        return 'Any combination';
    }
  }

  IconData get icon {
    switch (this) {
      case SupersetType.antagonist:
        return Icons.swap_horiz;
      case SupersetType.compound:
        return Icons.layers;
      case SupersetType.preExhaust:
        return Icons.trending_up;
      case SupersetType.custom:
        return Icons.tune;
    }
  }

  Color get color {
    switch (this) {
      case SupersetType.antagonist:
        return AppColors.cyan;
      case SupersetType.compound:
        return AppColors.purple;
      case SupersetType.preExhaust:
        return AppColors.orange;
      case SupersetType.custom:
        return AppColors.teal;
    }
  }
}

/// AI-suggested superset pair
class SupersetSuggestion {
  final WorkoutExercise exercise1;
  final WorkoutExercise exercise2;
  final SupersetType type;
  final String reason;

  const SupersetSuggestion({
    required this.exercise1,
    required this.exercise2,
    required this.type,
    required this.reason,
  });
}

/// Result from the superset pair sheet
class SupersetPairResult {
  final WorkoutExercise exercise1;
  final WorkoutExercise exercise2;
  final SupersetType type;
  final int restBetweenExercises;
  final int restAfterSuperset;
  final bool saveToFavorites;

  const SupersetPairResult({
    required this.exercise1,
    required this.exercise2,
    required this.type,
    required this.restBetweenExercises,
    required this.restAfterSuperset,
    required this.saveToFavorites,
  });
}

/// Shows the superset pair creation sheet
Future<SupersetPairResult?> showSupersetPairSheet(
  BuildContext context,
  WidgetRef ref, {
  required List<WorkoutExercise> workoutExercises,
  WorkoutExercise? preselectedExercise,
}) async {
  return await showGlassSheet<SupersetPairResult>(
    context: context,
    builder: (context) => GlassSheet(
      showHandle: false,
      child: _SupersetPairSheet(
        workoutExercises: workoutExercises,
        preselectedExercise: preselectedExercise,
      ),
    ),
  );
}

class _SupersetPairSheet extends ConsumerStatefulWidget {
  final List<WorkoutExercise> workoutExercises;
  final WorkoutExercise? preselectedExercise;

  const _SupersetPairSheet({
    required this.workoutExercises,
    this.preselectedExercise,
  });

  @override
  ConsumerState<_SupersetPairSheet> createState() => _SupersetPairSheetState();
}

class _SupersetPairSheetState extends ConsumerState<_SupersetPairSheet> {
  WorkoutExercise? _exercise1;
  WorkoutExercise? _exercise2;
  SupersetType _selectedType = SupersetType.antagonist;
  double _restBetweenExercises = 0;
  double _restAfterSuperset = 90;
  bool _saveToFavorites = false;
  bool _showSuggestions = true;

  List<SupersetSuggestion> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _exercise1 = widget.preselectedExercise;
    _generateSuggestions();
  }

  void _generateSuggestions() {
    // Generate AI suggestions based on available exercises
    final available = widget.workoutExercises
        .where((e) => !e.isInSuperset)
        .toList();

    if (available.length < 2) {
      _suggestions = [];
      return;
    }

    final suggestions = <SupersetSuggestion>[];

    // Find antagonist pairs (e.g., chest/back, biceps/triceps, quads/hamstrings)
    final antagonistPairs = <List<String>>[
      ['chest', 'back', 'lats', 'upper back'],
      ['biceps', 'triceps'],
      ['quadriceps', 'quads', 'hamstrings', 'glutes'],
      ['shoulders', 'rear delts', 'front delts'],
      ['abs', 'lower back', 'core'],
    ];

    for (int i = 0; i < available.length; i++) {
      for (int j = i + 1; j < available.length; j++) {
        final ex1 = available[i];
        final ex2 = available[j];

        final muscle1 = (ex1.muscleGroup ?? ex1.primaryMuscle ?? '').toLowerCase();
        final muscle2 = (ex2.muscleGroup ?? ex2.primaryMuscle ?? '').toLowerCase();

        // Check for antagonist pair
        for (final pairGroup in antagonistPairs) {
          final ex1InGroup = pairGroup.any((m) => muscle1.contains(m));
          final ex2InGroup = pairGroup.any((m) => muscle2.contains(m));

          if (ex1InGroup && ex2InGroup && muscle1 != muscle2) {
            suggestions.add(SupersetSuggestion(
              exercise1: ex1,
              exercise2: ex2,
              type: SupersetType.antagonist,
              reason: 'Works opposing muscles for efficient training',
            ));
            break;
          }
        }

        // Check for compound (same muscle group)
        if (muscle1 == muscle2 && muscle1.isNotEmpty) {
          suggestions.add(SupersetSuggestion(
            exercise1: ex1,
            exercise2: ex2,
            type: SupersetType.compound,
            reason: 'Intensifies ${_formatMuscle(muscle1)} workout',
          ));
        }
      }
    }

    // Limit to top 5 suggestions
    setState(() {
      _suggestions = suggestions.take(5).toList();
    });
  }

  String _formatMuscle(String muscle) {
    if (muscle.isEmpty) return muscle;
    return '${muscle[0].toUpperCase()}${muscle.substring(1)}';
  }

  Future<void> _selectExercise1() async {
    final selected = await showSupersetExercisePicker(
      context,
      exercises: widget.workoutExercises,
      excludeExercises: _exercise2 != null ? [_exercise2!] : [],
      title: 'Select Exercise 1',
    );

    if (selected != null) {
      setState(() {
        _exercise1 = selected;
        _showSuggestions = false;
      });
    }
  }

  Future<void> _selectExercise2() async {
    final selected = await showSupersetExercisePicker(
      context,
      exercises: widget.workoutExercises,
      excludeExercises: _exercise1 != null ? [_exercise1!] : [],
      title: 'Select Exercise 2',
    );

    if (selected != null) {
      setState(() {
        _exercise2 = selected;
        _showSuggestions = false;
      });
    }
  }

  void _selectSuggestion(SupersetSuggestion suggestion) {
    setState(() {
      _exercise1 = suggestion.exercise1;
      _exercise2 = suggestion.exercise2;
      _selectedType = suggestion.type;
      _showSuggestions = false;
    });
  }

  void _clearSelection() {
    setState(() {
      _exercise1 = null;
      _exercise2 = null;
      _showSuggestions = true;
    });
  }

  void _createSuperset() {
    if (_exercise1 == null || _exercise2 == null) return;

    Navigator.pop(
      context,
      SupersetPairResult(
        exercise1: _exercise1!,
        exercise2: _exercise2!,
        type: _selectedType,
        restBetweenExercises: _restBetweenExercises.toInt(),
        restAfterSuperset: _restAfterSuperset.toInt(),
        saveToFavorites: _saveToFavorites,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.nearBlack : AppColorsLight.pureWhite;
    final cardBackground = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    final canCreate = _exercise1 != null && _exercise2 != null;

    return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.link,
                    color: AppColors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Superset Pair',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                      ),
                      Text(
                        'Pair two exercises for efficient training',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: textMuted),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise Selection Cards
                  _buildExerciseSelectionCard(
                    index: 1,
                    exercise: _exercise1,
                    onTap: _selectExercise1,
                    cardBackground: cardBackground,
                    glassSurface: glassSurface,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    textMuted: textMuted,
                  ),

                  // Link indicator
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          Container(
                            width: 2,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _exercise1 != null && _exercise2 != null
                                  ? AppColors.purple
                                  : textMuted.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _exercise1 != null && _exercise2 != null
                                  ? AppColors.purple.withOpacity(0.15)
                                  : glassSurface,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.link,
                              size: 20,
                              color: _exercise1 != null && _exercise2 != null
                                  ? AppColors.purple
                                  : textMuted,
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _exercise1 != null && _exercise2 != null
                                  ? AppColors.purple
                                  : textMuted.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  _buildExerciseSelectionCard(
                    index: 2,
                    exercise: _exercise2,
                    onTap: _selectExercise2,
                    cardBackground: cardBackground,
                    glassSurface: glassSurface,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    textMuted: textMuted,
                  ),

                  const SizedBox(height: 24),

                  // Superset Type Selector
                  Text(
                    'Superset Type',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSupersetTypeSelector(
                    cardBackground: cardBackground,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    textMuted: textMuted,
                  ),

                  const SizedBox(height: 24),

                  // AI Suggestions Section
                  if (_showSuggestions && _suggestions.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 18,
                          color: AppColors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Suggested Pairs',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._suggestions.map((suggestion) => _buildSuggestionCard(
                          suggestion: suggestion,
                          cardBackground: cardBackground,
                          glassSurface: glassSurface,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          textMuted: textMuted,
                        )),
                    const SizedBox(height: 16),
                  ],

                  // Rest Settings
                  Text(
                    'Rest Settings',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Rest between exercises
                  _buildRestSlider(
                    label: 'Rest between exercises',
                    value: _restBetweenExercises,
                    min: 0,
                    max: 30,
                    divisions: 6,
                    onChanged: (value) => setState(() => _restBetweenExercises = value),
                    cardBackground: cardBackground,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    textMuted: textMuted,
                  ),

                  const SizedBox(height: 16),

                  // Rest after superset
                  _buildRestSlider(
                    label: 'Rest after superset',
                    value: _restAfterSuperset,
                    min: 60,
                    max: 180,
                    divisions: 8,
                    onChanged: (value) => setState(() => _restAfterSuperset = value),
                    cardBackground: cardBackground,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    textMuted: textMuted,
                  ),

                  const SizedBox(height: 24),

                  // Save to favorites toggle
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _saveToFavorites ? Icons.favorite : Icons.favorite_border,
                          color: _saveToFavorites ? AppColors.coral : textMuted,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Save to Favorites',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                'Reuse this pair in future workouts',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _saveToFavorites,
                          onChanged: (value) => setState(() => _saveToFavorites = value),
                          activeThumbColor: AppColors.coral,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Create Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  if (_exercise1 != null || _exercise2 != null) ...[
                    TextButton(
                      onPressed: _clearSelection,
                      child: Text(
                        'Clear',
                        style: TextStyle(color: textMuted),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: canCreate ? _createSuperset : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        disabledBackgroundColor: glassSurface,
                        foregroundColor: Colors.white,
                        disabledForegroundColor: textMuted,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.link,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Create Superset',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
    );
  }

  Widget _buildExerciseSelectionCard({
    required int index,
    required WorkoutExercise? exercise,
    required VoidCallback onTap,
    required Color cardBackground,
    required Color glassSurface,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
  }) {
    return Material(
      color: cardBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Exercise number badge
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: exercise != null
                      ? AppColors.purple.withOpacity(0.15)
                      : glassSurface,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: exercise != null ? AppColors.purple : textMuted,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Exercise info or placeholder
              if (exercise != null) ...[
                // Exercise GIF
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: glassSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: exercise.gifUrl != null && exercise.gifUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: exercise.gifUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Icon(
                            Icons.fitness_center,
                            color: textMuted,
                            size: 20,
                          ),
                          errorWidget: (_, __, ___) => Icon(
                            Icons.fitness_center,
                            color: textMuted,
                            size: 20,
                          ),
                        )
                      : Icon(
                          Icons.fitness_center,
                          color: textMuted,
                          size: 20,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        exercise.muscleGroup ?? exercise.primaryMuscle ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 24,
                ),
              ] else ...[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exercise $index',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap to select',
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.add_circle_outline,
                  color: textMuted,
                  size: 24,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupersetTypeSelector({
    required Color cardBackground,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: SupersetType.values.map((type) {
        final isSelected = _selectedType == type;
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                type.icon,
                size: 16,
                color: isSelected ? Colors.white : type.color,
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    type.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : textPrimary,
                    ),
                  ),
                  Text(
                    type.description,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected
                          ? Colors.white.withOpacity(0.8)
                          : textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          selected: isSelected,
          selectedColor: type.color,
          backgroundColor: cardBackground,
          onSelected: (selected) {
            if (selected) {
              setState(() => _selectedType = type);
            }
          },
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }

  Widget _buildSuggestionCard({
    required SupersetSuggestion suggestion,
    required Color cardBackground,
    required Color glassSurface,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _selectSuggestion(suggestion),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Exercise 1 thumbnail
                    _buildMiniExerciseThumb(
                      suggestion.exercise1,
                      glassSurface,
                      textMuted,
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.add,
                      size: 16,
                      color: suggestion.type.color,
                    ),
                    const SizedBox(width: 8),
                    // Exercise 2 thumbnail
                    _buildMiniExerciseThumb(
                      suggestion.exercise2,
                      glassSurface,
                      textMuted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${suggestion.exercise1.name} + ${suggestion.exercise2.name}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: suggestion.type.color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  suggestion.type.label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: suggestion.type.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: textMuted,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  suggestion.reason,
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniExerciseThumb(
    WorkoutExercise exercise,
    Color glassSurface,
    Color textMuted,
  ) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: glassSurface,
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.hardEdge,
      child: exercise.gifUrl != null && exercise.gifUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: exercise.gifUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => Icon(
                Icons.fitness_center,
                color: textMuted,
                size: 16,
              ),
              errorWidget: (_, __, ___) => Icon(
                Icons.fitness_center,
                color: textMuted,
                size: 16,
              ),
            )
          : Icon(
              Icons.fitness_center,
              color: textMuted,
              size: 16,
            ),
    );
  }

  Widget _buildRestSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required Color cardBackground,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
  }) {
    final displayValue = value.toInt();
    String valueText;
    if (displayValue == 0) {
      valueText = 'No rest';
    } else if (displayValue >= 60) {
      final minutes = displayValue ~/ 60;
      final seconds = displayValue % 60;
      if (seconds > 0) {
        valueText = '${minutes}m ${seconds}s';
      } else {
        valueText = '${minutes}m';
      }
    } else {
      valueText = '${displayValue}s';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  valueText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.purple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.purple,
              inactiveTrackColor: textMuted.withOpacity(0.2),
              thumbColor: AppColors.purple,
              overlayColor: AppColors.purple.withOpacity(0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
