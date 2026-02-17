import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/utils/difficulty_utils.dart';
import '../../../data/models/workout.dart';
import '../../../data/providers/quick_workout_provider.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/main_shell.dart';

/// Shows the Quick Workout bottom sheet for busy users
/// who want 5-30 minute workouts.
Future<Workout?> showQuickWorkoutSheet(BuildContext context, WidgetRef ref) async {
  // Hide nav bar while sheet is open
  ref.read(floatingNavBarVisibleProvider.notifier).state = false;

  final result = await showGlassSheet<Workout>(
    context: context,
    builder: (context) => const GlassSheet(
      showHandle: false,
      child: _QuickWorkoutSheet(),
    ),
  );

  // Show nav bar when sheet is closed
  ref.read(floatingNavBarVisibleProvider.notifier).state = true;

  return result;
}

class _QuickWorkoutSheet extends ConsumerStatefulWidget {
  const _QuickWorkoutSheet();

  @override
  ConsumerState<_QuickWorkoutSheet> createState() => _QuickWorkoutSheetState();
}

class _QuickWorkoutSheetState extends ConsumerState<_QuickWorkoutSheet> {
  int _selectedDuration = 15;
  String? _selectedFocus;
  String? _selectedDifficulty;
  Set<String> _selectedEquipment = {};
  Set<String> _selectedInjuries = {};

  final List<int> _durations = [15, 20, 25, 30];
  final List<Map<String, dynamic>> _focusOptions = [
    {'value': 'cardio', 'label': 'Cardio', 'icon': Icons.directions_run, 'color': AppColors.cardio},
    {'value': 'strength', 'label': 'Strength', 'icon': Icons.fitness_center, 'color': AppColors.strength},
    {'value': 'stretch', 'label': 'Stretch', 'icon': Icons.self_improvement, 'color': AppColors.flexibility},
    {'value': 'full_body', 'label': 'Full Body', 'icon': Icons.accessibility_new, 'color': AppColors.cyan},
  ];

  static const List<String> _equipmentOptions = [
    'Bodyweight', 'Dumbbells', 'Barbell', 'Resistance Bands', 'Pull-up Bar', 'Kettlebell',
  ];

  static const List<String> _injuryOptions = [
    'Shoulder', 'Lower Back', 'Knee', 'Ankle', 'Hip', 'Neck', 'Elbow', 'Wrist',
  ];

  @override
  void initState() {
    super.initState();
    _initFromUserProfile();
  }

  void _initFromUserProfile() {
    final userAsync = ref.read(currentUserProvider);
    final user = userAsync.valueOrNull;
    if (user == null) return;

    // Pre-fill difficulty from fitness level
    final level = user.fitnessLevel?.toLowerCase();
    if (level != null && DifficultyUtils.internalValues.contains(level)) {
      _selectedDifficulty = level;
    }

    // Pre-fill equipment from profile
    final profileEquipment = user.equipmentList;
    if (profileEquipment.isNotEmpty) {
      _selectedEquipment = profileEquipment
          .where((e) => _equipmentOptions.any((o) => o.toLowerCase() == e.toLowerCase()))
          .map((e) => _equipmentOptions.firstWhere((o) => o.toLowerCase() == e.toLowerCase()))
          .toSet();
    }

    // Pre-fill injuries from profile
    final profileInjuries = user.injuriesList;
    if (profileInjuries.isNotEmpty) {
      _selectedInjuries = profileInjuries
          .where((e) => _injuryOptions.any((o) => o.toLowerCase() == e.toLowerCase()))
          .map((e) => _injuryOptions.firstWhere((o) => o.toLowerCase() == e.toLowerCase()))
          .toSet();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quickWorkoutProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackground = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.flash_on,
                  color: AppColors.cyan,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Workout',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Perfect for busy days',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 14,
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

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Duration selector
                Text(
                  'Duration',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: _durations.map((duration) {
                    final isSelected = _selectedDuration == duration;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: duration != _durations.last ? 8 : 0,
                        ),
                        child: _DurationCard(
                          duration: duration,
                          isSelected: isSelected,
                          onTap: () {
                            HapticService.light();
                            setState(() => _selectedDuration = duration);
                          },
                          cardBackground: cardBackground,
                          textPrimary: textPrimary,
                          textMuted: textMuted,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Focus selector
                Text(
                  'Focus (Optional)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _focusOptions.map((option) {
                    final isSelected = _selectedFocus == option['value'];
                    return _FocusChip(
                      label: option['label'] as String,
                      icon: option['icon'] as IconData,
                      color: option['color'] as Color,
                      isSelected: isSelected,
                      onTap: () {
                        HapticService.light();
                        setState(() {
                          _selectedFocus = isSelected ? null : option['value'] as String;
                        });
                      },
                      cardBackground: cardBackground,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Difficulty selector
                Text(
                  'Difficulty (Optional)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: DifficultyUtils.internalValues.map((diff) {
                    final isSelected = _selectedDifficulty == diff;
                    final color = DifficultyUtils.getColor(diff);
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: diff != DifficultyUtils.internalValues.last ? 8 : 0,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            HapticService.light();
                            setState(() {
                              _selectedDifficulty = isSelected ? null : diff;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? color.withOpacity(0.15) : cardBackground,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? color : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                DifficultyUtils.getDisplayName(diff),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? color : textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Equipment selector
                Text(
                  'Equipment (Optional)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _equipmentOptions.map((equip) {
                    final isSelected = _selectedEquipment.contains(equip);
                    return _ToggleChip(
                      label: equip,
                      isSelected: isSelected,
                      color: AppColors.cyan,
                      onTap: () {
                        HapticService.light();
                        setState(() {
                          if (isSelected) {
                            _selectedEquipment.remove(equip);
                          } else {
                            _selectedEquipment.add(equip);
                          }
                        });
                      },
                      cardBackground: cardBackground,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Injuries selector
                Text(
                  'Injuries (Optional)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _injuryOptions.map((injury) {
                    final isSelected = _selectedInjuries.contains(injury);
                    return _ToggleChip(
                      label: injury,
                      isSelected: isSelected,
                      color: AppColors.error,
                      onTap: () {
                        HapticService.light();
                        setState(() {
                          if (isSelected) {
                            _selectedInjuries.remove(injury);
                          } else {
                            _selectedInjuries.add(injury);
                          }
                        });
                      },
                      cardBackground: cardBackground,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Info text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.cyan.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates_outlined,
                        color: AppColors.cyan,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'AI will generate an efficient workout tailored to your selections.',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // Generate button
        Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(context).padding.bottom + 12,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: state.isGenerating
                  ? null
                  : () => _generateQuickWorkout(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.cyan.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: state.isGenerating
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          state.statusMessage ?? 'Generating...',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.flash_on, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Generate $_selectedDuration-min Workout',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),

        // Error message
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _generateQuickWorkout() async {
    HapticService.medium();

    final workout = await ref.read(quickWorkoutProvider.notifier).generateQuickWorkout(
      duration: _selectedDuration,
      focus: _selectedFocus,
      difficulty: _selectedDifficulty,
      equipment: _selectedEquipment.isNotEmpty ? _selectedEquipment.toList() : null,
      injuries: _selectedInjuries.isNotEmpty ? _selectedInjuries.toList() : null,
    );

    if (workout != null && mounted) {
      Navigator.pop(context, workout);
      // Navigate to active workout screen
      context.push('/workout/${workout.id}');
    }
  }
}

class _DurationCard extends StatelessWidget {
  final int duration;
  final bool isSelected;
  final VoidCallback onTap;
  final Color cardBackground;
  final Color textPrimary;
  final Color textMuted;

  const _DurationCard({
    required this.duration,
    required this.isSelected,
    required this.onTap,
    required this.cardBackground,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cyan.withOpacity(0.15) : cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.cyan : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              '$duration',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.cyan : textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'min',
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppColors.cyan : textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final Color cardBackground;
  final Color textPrimary;
  final Color textMuted;

  const _FocusChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
    required this.cardBackground,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? color : textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  final Color cardBackground;
  final Color textPrimary;
  final Color textMuted;

  const _ToggleChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
    required this.cardBackground,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? color : textMuted,
          ),
        ),
      ),
    );
  }
}
