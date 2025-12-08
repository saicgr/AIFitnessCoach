import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/workout.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/repositories/auth_repository.dart';

/// Shows a bottom sheet for regenerating workout with customization options
Future<Workout?> showRegenerateWorkoutSheet(
  BuildContext context,
  WidgetRef ref,
  Workout workout,
) async {
  return showModalBottomSheet<Workout>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _RegenerateWorkoutSheet(workout: workout),
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
    extends ConsumerState<_RegenerateWorkoutSheet> {
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
  bool _showFocusAreaInput = false;
  bool _showInjuryInput = false;

  final TextEditingController _focusAreaController = TextEditingController();
  final TextEditingController _injuryController = TextEditingController();

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
  }

  @override
  void dispose() {
    _focusAreaController.dispose();
    _injuryController.dispose();
    super.dispose();
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

      final repo = ref.read(workoutRepositoryProvider);
      final newWorkout = await repo.regenerateWorkout(
        workoutId: widget.workout.id!,
        userId: userId,
        difficulty: _selectedDifficulty,
        durationMinutes: _selectedDuration.round(),
        focusAreas: allFocusAreas,
        injuries: allInjuries,
        equipment: _selectedEquipment.isNotEmpty ? _selectedEquipment.toList() : null,
        workoutType: _selectedWorkoutType,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.nearBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: AppColors.textMuted.withOpacity(0.3),
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
                      color: AppColors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: AppColors.purple,
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
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Customize your new workout',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed:
                        _isRegenerating ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Workout Type Selection
                    _buildWorkoutTypeSection(),

                    // Difficulty Selection
                    _buildDifficultySection(),

                    // Duration Selection (Slider)
                    _buildDurationSection(),

                    const SizedBox(height: 20),

                    // Equipment Selection
                    _buildEquipmentSection(),

                    const SizedBox(height: 20),

                    // Focus Areas Selection
                    _buildFocusAreasSection(),

                    const SizedBox(height: 20),

                    // Injuries Section (Optional)
                    _buildInjuriesSection(),

                    const SizedBox(height: 24),

                    // Regenerate Button
                    _buildRegenerateButton(),

                    // Extra padding to account for FAB overlap
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutTypeSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.category, size: 20, color: AppColors.cyan),
              const SizedBox(width: 8),
              Text(
                'Workout Type',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _workoutTypes.map((type) {
              final isSelected = _selectedWorkoutType?.toLowerCase() == type.toLowerCase();
              return GestureDetector(
                onTap: _isRegenerating
                    ? null
                    : () {
                        setState(() {
                          _selectedWorkoutType = isSelected ? null : type;
                        });
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.cyan.withOpacity(0.2)
                        : AppColors.elevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.cyan
                          : AppColors.cardBorder.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      color: isSelected ? AppColors.cyan : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
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

  Widget _buildDifficultySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.speed, size: 20, color: AppColors.cyan),
              const SizedBox(width: 8),
              Text(
                'Difficulty',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
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
                        color: isSelected ? color.withOpacity(0.2) : AppColors.elevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? color : AppColors.cardBorder.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          difficulty[0].toUpperCase() + difficulty.substring(1),
                          style: TextStyle(
                            color: isSelected ? color : AppColors.textSecondary,
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

  Widget _buildDurationSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 20, color: AppColors.orange),
              const SizedBox(width: 8),
              Text(
                'Duration',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_selectedDuration.round()} min',
                  style: const TextStyle(
                    color: AppColors.orange,
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
              activeTrackColor: AppColors.orange,
              inactiveTrackColor: AppColors.elevated,
              thumbColor: AppColors.orange,
              overlayColor: AppColors.orange.withOpacity(0.2),
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
                Text('15 min', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                Text('90 min', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fitness_center, size: 20, color: AppColors.success),
              const SizedBox(width: 8),
              Text(
                'Equipment Available',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              if (_selectedEquipment.isNotEmpty)
                Text(
                  '${_selectedEquipment.length} selected',
                  style: const TextStyle(color: AppColors.success, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Only generate exercises with selected equipment',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _equipmentOptions.map((equipment) {
              final isSelected = _selectedEquipment.contains(equipment);
              return GestureDetector(
                onTap: _isRegenerating
                    ? null
                    : () {
                        setState(() {
                          if (isSelected) {
                            _selectedEquipment.remove(equipment);
                          } else {
                            _selectedEquipment.add(equipment);
                          }
                        });
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.success.withOpacity(0.2) : AppColors.elevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.success : AppColors.cardBorder.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        const Icon(Icons.check, size: 14, color: AppColors.success),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        equipment,
                        style: TextStyle(
                          color: isSelected ? AppColors.success : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusAreasSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.track_changes, size: 20, color: AppColors.purple),
              const SizedBox(width: 8),
              Text(
                'Focus Areas',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              if (_selectedFocusAreas.isNotEmpty || _customFocusArea.isNotEmpty)
                Text(
                  '${_selectedFocusAreas.length + (_customFocusArea.isNotEmpty ? 1 : 0)} selected',
                  style: const TextStyle(color: AppColors.purple, fontSize: 12),
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
                      color: isSelected ? AppColors.purple.withOpacity(0.2) : AppColors.elevated,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.purple : AppColors.cardBorder.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          const Icon(Icons.check, size: 14, color: AppColors.purple),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          area,
                          style: TextStyle(
                            color: isSelected ? AppColors.purple : AppColors.textSecondary,
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
                        ? AppColors.purple.withOpacity(0.2)
                        : AppColors.elevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _customFocusArea.isNotEmpty
                          ? AppColors.purple
                          : AppColors.cardBorder.withOpacity(0.3),
                      width: _customFocusArea.isNotEmpty ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showFocusAreaInput ? Icons.close : Icons.add,
                        size: 14,
                        color: _customFocusArea.isNotEmpty ? AppColors.purple : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _customFocusArea.isNotEmpty ? _customFocusArea : 'Other',
                        style: TextStyle(
                          color: _customFocusArea.isNotEmpty ? AppColors.purple : AppColors.textSecondary,
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
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                filled: true,
                fillColor: AppColors.elevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.purple),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check, color: AppColors.purple),
                  onPressed: () {
                    setState(() {
                      _customFocusArea = _focusAreaController.text.trim();
                      _showFocusAreaInput = false;
                    });
                  },
                ),
              ),
              style: const TextStyle(color: AppColors.textPrimary),
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

  Widget _buildInjuriesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.healing, size: 20, color: AppColors.error),
              const SizedBox(width: 8),
              Text(
                'Injuries to Consider',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              if (_selectedInjuries.isNotEmpty || _customInjury.isNotEmpty)
                Text(
                  '${_selectedInjuries.length + (_customInjury.isNotEmpty ? 1 : 0)} selected',
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'AI will avoid exercises that may aggravate these areas',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
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
                      color: isSelected ? AppColors.error.withOpacity(0.2) : AppColors.elevated,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.error : AppColors.cardBorder.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          const Icon(Icons.check, size: 14, color: AppColors.error),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          injury,
                          style: TextStyle(
                            color: isSelected ? AppColors.error : AppColors.textSecondary,
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
                        ? AppColors.error.withOpacity(0.2)
                        : AppColors.elevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _customInjury.isNotEmpty
                          ? AppColors.error
                          : AppColors.cardBorder.withOpacity(0.3),
                      width: _customInjury.isNotEmpty ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showInjuryInput ? Icons.close : Icons.add,
                        size: 14,
                        color: _customInjury.isNotEmpty ? AppColors.error : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _customInjury.isNotEmpty ? _customInjury : 'Other',
                        style: TextStyle(
                          color: _customInjury.isNotEmpty ? AppColors.error : AppColors.textSecondary,
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
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                filled: true,
                fillColor: AppColors.elevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check, color: AppColors.error),
                  onPressed: () {
                    setState(() {
                      _customInjury = _injuryController.text.trim();
                      _showInjuryInput = false;
                    });
                  },
                ),
              ),
              style: const TextStyle(color: AppColors.textPrimary),
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

  Widget _buildRegenerateButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isRegenerating ? null : _regenerate,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.purple,
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
