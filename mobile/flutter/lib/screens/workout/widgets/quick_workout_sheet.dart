import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/dup_rotation.dart';
import '../../../services/hrv_recovery_service.dart';
import '../../../services/mesocycle_planner.dart';
import '../../../services/muscle_recovery_tracker.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/utils/difficulty_utils.dart';
import '../../../data/models/workout.dart';
import '../../../data/providers/quick_workout_provider.dart';
import '../../../data/services/haptic_service.dart';
import '../../../models/equipment_item.dart';
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
  String? _selectedMood;
  String? _selectedGoal;
  String? _dupSuggestion;
  MesocyclePlan? _activeMesocycle;
  MesocycleContext? _mesocycleContext;
  HrvRecoveryModifiers? _hrvModifiers;
  bool _useSupersets = true;
  Set<String> _selectedEquipment = {};
  Set<String> _selectedInjuries = {};
  final Map<String, EquipmentItem> _equipmentDetails = {};
  String? _expandedEquipment; // which equipment's weight picker is open

  final List<int> _durations = [5, 10, 15, 20, 25, 30];
  final List<Map<String, dynamic>> _focusOptions = [
    {'value': 'cardio', 'label': 'Cardio / HIIT', 'icon': Icons.local_fire_department, 'color': AppColors.cardio},
    {'value': 'strength', 'label': 'Strength', 'icon': Icons.fitness_center, 'color': AppColors.strength},
    {'value': 'stretch', 'label': 'Stretch', 'icon': Icons.self_improvement, 'color': AppColors.flexibility},
    {'value': 'full_body', 'label': 'Full Body', 'icon': Icons.accessibility_new, 'color': null},
    {'value': 'upper_body', 'label': 'Upper Body', 'icon': Icons.sports_martial_arts, 'color': null},
    {'value': 'lower_body', 'label': 'Lower Body', 'icon': Icons.directions_walk, 'color': null},
    {'value': 'core', 'label': 'Core', 'icon': Icons.circle_outlined, 'color': null},
    {'value': 'emom', 'label': 'EMOM', 'icon': Icons.timer, 'color': Colors.purple},
    {'value': 'amrap', 'label': 'AMRAP', 'icon': Icons.repeat, 'color': Colors.teal},
  ];

  final List<Map<String, dynamic>> _moodOptions = [
    {'value': 'energized', 'label': 'Energized', 'icon': Icons.bolt, 'color': Colors.orange},
    {'value': 'tired', 'label': 'Tired', 'icon': Icons.bedtime_outlined, 'color': Colors.indigo},
    {'value': 'stressed', 'label': 'Stressed', 'icon': Icons.psychology_outlined, 'color': Colors.red},
    {'value': 'chill', 'label': 'Chill', 'icon': Icons.spa_outlined, 'color': Colors.teal},
    {'value': 'motivated', 'label': 'Fired Up', 'icon': Icons.local_fire_department, 'color': Colors.deepOrange},
    {'value': 'low_energy', 'label': 'Low Energy', 'icon': Icons.battery_2_bar, 'color': Colors.blueGrey},
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
    _loadDupSuggestion();
    _loadMesocycleStatus();
    _loadHrvModifiers();
  }

  Future<void> _loadHrvModifiers() async {
    try {
      final modifiers = await HrvRecoveryService.getModifiers();
      if (mounted && modifiers.hasData) {
        setState(() => _hrvModifiers = modifiers);
      }
    } catch (_) {
      // Non-critical: continue without HRV data
    }
  }

  Future<void> _loadMesocycleStatus() async {
    try {
      final plan = await MesocyclePlanner.getActivePlan();
      final context = await MesocyclePlanner.getCurrentContext();
      if (mounted) {
        setState(() {
          _activeMesocycle = plan;
          _mesocycleContext = context;
        });
      }
    } catch (_) {
      // Silently fail -- mesocycle display is non-critical
    }
  }

  Future<void> _loadDupSuggestion() async {
    try {
      final recoveryScores = await MuscleRecoveryTracker.getAllRecoveryScores();
      final avgRecovery = recoveryScores.isEmpty
          ? null
          : recoveryScores.values.reduce((a, b) => a + b) / recoveryScores.length;
      final suggestion = await DupRotation.getNextGoal(avgRecoveryPercent: avgRecovery);
      if (mounted) {
        setState(() => _dupSuggestion = suggestion);
      }
    } catch (_) {
      // Silently fail -- DUP suggestion is non-critical
    }
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
    // Theme-aware accent color (AppColors.cyan is light gray for dark theme — invisible in light mode)
    final accentColor = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final chipBorder = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08);

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
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.flash_on,
                  color: accentColor,
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _durations.map((duration) {
                    final isSelected = _selectedDuration == duration;
                    return SizedBox(
                      width: 56,
                      child: _DurationCard(
                        duration: duration,
                        isSelected: isSelected,
                        accentColor: accentColor,
                        chipBorder: chipBorder,
                        onTap: () {
                          HapticService.light();
                          setState(() => _selectedDuration = duration);
                        },
                        cardBackground: cardBackground,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
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
                    final chipColor = (option['color'] as Color?) ?? accentColor;
                    return _FocusChip(
                      label: option['label'] as String,
                      icon: option['icon'] as IconData,
                      color: chipColor,
                      isSelected: isSelected,
                      chipBorder: chipBorder,
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

                // Goal selector
                Text(
                  'Goal (Optional)',
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
                  children: [
                    {'value': 'strength', 'label': 'Strength', 'icon': Icons.fitness_center, 'color': Colors.red},
                    {'value': 'hypertrophy', 'label': 'Hypertrophy', 'icon': Icons.accessibility_new, 'color': Colors.blue},
                    {'value': 'endurance', 'label': 'Endurance', 'icon': Icons.directions_run, 'color': Colors.green},
                    {'value': 'power', 'label': 'Power', 'icon': Icons.bolt, 'color': Colors.orange},
                  ].map((option) {
                    final isSelected = _selectedGoal == option['value'];
                    final chipColor = option['color'] as Color;
                    return _FocusChip(
                      label: option['label'] as String,
                      icon: option['icon'] as IconData,
                      color: chipColor,
                      isSelected: isSelected,
                      chipBorder: chipBorder,
                      onTap: () {
                        HapticService.light();
                        setState(() {
                          _selectedGoal = isSelected ? null : option['value'] as String;
                        });
                      },
                      cardBackground: cardBackground,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    );
                  }).toList(),
                ),
                // DUP suggestion
                if (_dupSuggestion != null && _selectedGoal == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 14, color: textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Suggested: ${_dupSuggestion![0].toUpperCase()}${_dupSuggestion!.substring(1)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Mood selector
                Text(
                  'Mood (Optional)',
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
                  children: _moodOptions.map((option) {
                    final isSelected = _selectedMood == option['value'];
                    final chipColor = option['color'] as Color;
                    return _FocusChip(
                      label: option['label'] as String,
                      icon: option['icon'] as IconData,
                      color: chipColor,
                      isSelected: isSelected,
                      chipBorder: chipBorder,
                      onTap: () {
                        HapticService.light();
                        setState(() {
                          _selectedMood = isSelected ? null : option['value'] as String;
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
                                color: isSelected ? color : chipBorder,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (diff == 'hell') Icon(Icons.local_fire_department, size: 14, color: isSelected ? color : textPrimary),
                                  if (diff == 'hell') const SizedBox(width: 4),
                                  Text(
                                    DifficultyUtils.getDisplayName(diff),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? color : textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Format section
                Text('Format', style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary, fontSize: 16)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: cardBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: chipBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.compare_arrows_rounded, color: accentColor, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Supersets', style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary, fontSize: 14)),
                            Text('Pair opposing muscles to save time', style: TextStyle(color: textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _useSupersets,
                        activeColor: accentColor,
                        onChanged: (_selectedFocus == 'cardio' || _selectedFocus == 'stretch')
                            ? null
                            : (v) => setState(() => _useSupersets = v),
                      ),
                    ],
                  ),
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
                    final hasDetails = _equipmentDetails.containsKey(equip);
                    final supportsDetail = _supportsWeightDetail(equip);
                    return _EquipmentChip(
                      label: equip,
                      isSelected: isSelected,
                      hasDetails: hasDetails,
                      showTuneIcon: isSelected && supportsDetail,
                      color: accentColor,
                      chipBorder: chipBorder,
                      onTap: () {
                        HapticService.light();
                        setState(() {
                          if (isSelected) {
                            _selectedEquipment.remove(equip);
                            _equipmentDetails.remove(equip);
                            if (_expandedEquipment == equip) {
                              _expandedEquipment = null;
                            }
                          } else {
                            _selectedEquipment.add(equip);
                          }
                        });
                      },
                      onTuneTap: supportsDetail
                          ? () {
                              HapticService.light();
                              setState(() {
                                _expandedEquipment =
                                    _expandedEquipment == equip ? null : equip;
                              });
                            }
                          : null,
                      cardBackground: cardBackground,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    );
                  }).toList(),
                ),

                // Inline weight picker (expands below equipment chips)
                if (_expandedEquipment != null)
                  _buildWeightPicker(
                    _expandedEquipment!,
                    accentColor: accentColor,
                    cardBackground: cardBackground,
                    chipBorder: chipBorder,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    textMuted: textMuted,
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
                      chipBorder: chipBorder,
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

                // Mesocycle status chip
                if (_mesocycleContext != null && _activeMesocycle != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _mesocycleContext!.isDeload
                            ? Colors.green.withOpacity(0.1)
                            : accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _mesocycleContext!.isDeload
                              ? Colors.green.withOpacity(0.3)
                              : accentColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _mesocycleContext!.isDeload
                                ? Icons.spa_outlined
                                : Icons.trending_up,
                            size: 18,
                            color: _mesocycleContext!.isDeload
                                ? Colors.green
                                : accentColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mesocycle: ${_mesocycleContext!.phaseDisplayName}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  'Week ${_mesocycleContext!.weekNumber}/${_mesocycleContext!.totalWeeks}'
                                  '${_mesocycleContext!.isDeload ? " - Recovery week" : ""}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // HRV readiness indicator
                if (_hrvModifiers != null && _hrvModifiers!.hasData)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _getReadinessColor(_hrvModifiers!.readinessLevel).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _getReadinessColor(_hrvModifiers!.readinessLevel).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getReadinessIcon(_hrvModifiers!.readinessLevel),
                            size: 18,
                            color: _getReadinessColor(_hrvModifiers!.readinessLevel),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recovery: ${_hrvModifiers!.readinessDisplayName}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                                if (_hrvModifiers!.explanation != null)
                                  Text(
                                    _hrvModifiers!.explanation!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Info text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accentColor.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates_outlined,
                        color: accentColor,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Instant generation powered by exercise science research.',
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
                backgroundColor: accentColor,
                foregroundColor: isDark ? Colors.black : Colors.white,
                disabledBackgroundColor: accentColor.withOpacity(0.5),
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

  /// Whether this equipment type supports inline weight detail picker.
  bool _supportsWeightDetail(String equip) {
    final lower = equip.toLowerCase();
    return lower == 'dumbbells' ||
        lower == 'kettlebell' ||
        lower == 'barbell';
  }

  /// Build inline weight picker for the given equipment type.
  Widget _buildWeightPicker(
    String equip, {
    required Color accentColor,
    required Color cardBackground,
    required Color chipBorder,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
  }) {
    final lower = equip.toLowerCase();
    final existing = _equipmentDetails[equip];

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accentColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, size: 16, color: accentColor),
                const SizedBox(width: 6),
                Text(
                  'Available weights',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                if (existing != null && existing.weightInventory.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      HapticService.light();
                      setState(() => _equipmentDetails.remove(equip));
                    },
                    child: Text(
                      'Clear',
                      style: TextStyle(fontSize: 12, color: accentColor),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (lower == 'dumbbells' || lower == 'kettlebell')
              _buildDumbbellKettlebellPicker(
                equip,
                accentColor: accentColor,
                cardBackground: cardBackground,
                chipBorder: chipBorder,
                textPrimary: textPrimary,
                textMuted: textMuted,
              )
            else if (lower == 'barbell')
              _buildBarbellPicker(
                equip,
                accentColor: accentColor,
                cardBackground: cardBackground,
                chipBorder: chipBorder,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                textMuted: textMuted,
              ),
          ],
        ),
      ),
    );
  }

  /// Weight chips for dumbbells/kettlebells.
  /// Tap cycles: 0 -> 1 -> 2 -> 0. Shows "1x" or "2x" badge.
  Widget _buildDumbbellKettlebellPicker(
    String equip, {
    required Color accentColor,
    required Color cardBackground,
    required Color chipBorder,
    required Color textPrimary,
    required Color textMuted,
  }) {
    const weights = [5.0, 8.0, 10.0, 12.0, 15.0, 20.0, 25.0, 30.0, 35.0, 40.0];
    final existing = _equipmentDetails[equip];
    final currentInventory =
        existing?.weightInventory ?? <double, int>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tap to add (tap again for pairs)',
          style: TextStyle(fontSize: 11, color: textMuted),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: weights.map((w) {
            final qty = currentInventory[w] ?? 0;
            final isActive = qty > 0;
            return GestureDetector(
              onTap: () {
                HapticService.light();
                setState(() {
                  final newQty = (qty + 1) % 3; // 0 -> 1 -> 2 -> 0
                  final newInventory =
                      Map<double, int>.from(currentInventory);
                  if (newQty == 0) {
                    newInventory.remove(w);
                  } else {
                    newInventory[w] = newQty;
                  }
                  _equipmentDetails[equip] = EquipmentItem(
                    name: equip.toLowerCase() == 'dumbbells'
                        ? 'dumbbells'
                        : 'kettlebells',
                    displayName: equip,
                    quantity: newInventory.values.isEmpty
                        ? 1
                        : newInventory.values.reduce((a, b) => a > b ? a : b),
                    weightInventory: newInventory,
                    weightUnit: 'kg',
                  );
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 52,
                height: 36,
                decoration: BoxDecoration(
                  color: isActive
                      ? accentColor.withOpacity(0.15)
                      : cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive ? accentColor : chipBorder,
                    width: isActive ? 1.5 : 1,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '${w.toInt()}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isActive ? accentColor : textMuted,
                      ),
                    ),
                    if (qty > 0)
                      Positioned(
                        top: 2,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 3, vertical: 1),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${qty}x',
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        Text(
          'kg',
          style: TextStyle(fontSize: 11, color: textMuted),
        ),
      ],
    );
  }

  /// Barbell picker: "Bar only (20kg)" toggle vs "With plates".
  Widget _buildBarbellPicker(
    String equip, {
    required Color accentColor,
    required Color cardBackground,
    required Color chipBorder,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
  }) {
    final existing = _equipmentDetails[equip];
    final isBarOnly = existing != null &&
        existing.weightInventory.length == 1 &&
        existing.weightInventory.containsKey(20.0);
    final hasPlates = existing != null &&
        existing.weightInventory.isNotEmpty &&
        !isBarOnly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticService.light();
                  setState(() {
                    _equipmentDetails[equip] = EquipmentItem(
                      name: 'barbell',
                      displayName: 'Barbell',
                      quantity: 1,
                      weightInventory: {20.0: 1},
                      weightUnit: 'kg',
                      notes: 'bar only',
                    );
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isBarOnly
                        ? accentColor.withOpacity(0.15)
                        : cardBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isBarOnly ? accentColor : chipBorder,
                      width: isBarOnly ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Bar only (20kg)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isBarOnly ? accentColor : textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticService.light();
                  setState(() {
                    // Pre-fill with common plate weights (each side)
                    _equipmentDetails[equip] = EquipmentItem(
                      name: 'barbell',
                      displayName: 'Barbell',
                      quantity: 1,
                      weightInventory: {
                        20.0: 1, // bar
                        40.0: 1, // bar + 2x10
                        60.0: 1, // bar + 2x20
                        80.0: 1,
                        100.0: 1,
                      },
                      weightUnit: 'kg',
                    );
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: hasPlates
                        ? accentColor.withOpacity(0.15)
                        : cardBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasPlates ? accentColor : chipBorder,
                      width: hasPlates ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'With plates',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: hasPlates ? accentColor : textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (isBarOnly)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'High-rep tempo work at 20kg',
              style: TextStyle(fontSize: 11, color: textSecondary),
            ),
          ),
      ],
    );
  }

  Color _getReadinessColor(ReadinessLevel level) {
    switch (level) {
      case ReadinessLevel.low:
        return Colors.red;
      case ReadinessLevel.moderate:
        return Colors.orange;
      case ReadinessLevel.high:
        return Colors.green;
      case ReadinessLevel.peak:
        return Colors.blue;
    }
  }

  IconData _getReadinessIcon(ReadinessLevel level) {
    switch (level) {
      case ReadinessLevel.low:
        return Icons.battery_1_bar;
      case ReadinessLevel.moderate:
        return Icons.battery_3_bar;
      case ReadinessLevel.high:
        return Icons.battery_full;
      case ReadinessLevel.peak:
        return Icons.bolt;
    }
  }

  Future<void> _generateQuickWorkout() async {
    HapticService.medium();

    final workout = await ref.read(quickWorkoutProvider.notifier).generateQuickWorkout(
      duration: _selectedDuration,
      focus: _selectedFocus,
      difficulty: _selectedDifficulty,
      mood: _selectedMood,
      goal: _selectedGoal,
      useSupersets: _useSupersets,
      equipment: _selectedEquipment.isNotEmpty ? _selectedEquipment.toList() : null,
      injuries: _selectedInjuries.isNotEmpty ? _selectedInjuries.toList() : null,
      equipmentDetails: _equipmentDetails.isNotEmpty ? _equipmentDetails : null,
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
  final Color accentColor;
  final Color chipBorder;
  final VoidCallback onTap;
  final Color cardBackground;
  final Color textPrimary;
  final Color textMuted;

  const _DurationCard({
    required this.duration,
    required this.isSelected,
    required this.accentColor,
    required this.chipBorder,
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
          color: isSelected ? accentColor.withOpacity(0.15) : cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : chipBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              '$duration',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isSelected ? accentColor : textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'min',
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? accentColor : textMuted,
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
  final Color chipBorder;
  final VoidCallback onTap;
  final Color cardBackground;
  final Color textPrimary;
  final Color textMuted;

  const _FocusChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.chipBorder,
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
            color: isSelected ? color : chipBorder,
            width: isSelected ? 2 : 1,
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
  final Color chipBorder;
  final VoidCallback onTap;
  final Color cardBackground;
  final Color textPrimary;
  final Color textMuted;

  const _ToggleChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.chipBorder,
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
            color: isSelected ? color : chipBorder,
            width: isSelected ? 1.5 : 1,
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

/// Equipment chip with optional "tune" icon for weight detail.
class _EquipmentChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool hasDetails;
  final bool showTuneIcon;
  final Color color;
  final Color chipBorder;
  final VoidCallback onTap;
  final VoidCallback? onTuneTap;
  final Color cardBackground;
  final Color textPrimary;
  final Color textMuted;

  const _EquipmentChip({
    required this.label,
    required this.isSelected,
    required this.hasDetails,
    required this.showTuneIcon,
    required this.color,
    required this.chipBorder,
    required this.onTap,
    this.onTuneTap,
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
            color: isSelected ? color : chipBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? color : textMuted,
              ),
            ),
            if (hasDetails) ...[
              const SizedBox(width: 4),
              Icon(Icons.check_circle, size: 12, color: color),
            ],
            if (showTuneIcon) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onTuneTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Icon(
                    Icons.tune,
                    size: 14,
                    color: isSelected ? color : textMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
