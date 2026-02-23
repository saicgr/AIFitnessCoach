import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/dup_rotation.dart';
import '../../../services/hrv_recovery_service.dart';
import '../../../services/mesocycle_planner.dart';
import '../../../services/muscle_recovery_tracker.dart';
import '../../../services/quick_workout_preset_service.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/utils/difficulty_utils.dart';
import '../../../data/local/database_provider.dart';
import '../../../data/models/workout.dart';
import '../../../data/providers/quick_workout_provider.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/haptic_service.dart';
import '../../../models/equipment_item.dart';
import '../../../models/quick_workout_preset.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/main_shell.dart';

/// Actions for quick workout conflict resolution
enum _ConflictAction { noConflict, replace, addAnyway, changeDate, cancelled }

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
  bool _showAdvanced = false;
  String _weightUnit = 'kg';
  Set<String> _selectedEquipment = {'Bodyweight'};
  Set<String> _selectedInjuries = {};
  final Map<String, EquipmentItem> _equipmentDetails = {};
  String? _expandedEquipment; // which equipment's weight picker is open

  // Preset state
  List<QuickWorkoutPreset> _presets = [];
  List<QuickWorkoutPreset> _discoverPool = [];
  bool _presetsLoaded = false;

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

  /// Primary equipment shown as chips directly.
  static const List<String> _primaryEquipment = [
    'Bodyweight', 'Dumbbells', 'Barbell', 'Cable Machine',
    'Kettlebell',
  ];

  /// Full list of all equipment options (shown in "More" dialog).
  static const List<String> _allEquipmentOptions = [
    'Bodyweight', 'Dumbbells', 'Barbell', 'Cable Machine', 'Kettlebell',
    'Smith Machine', 'EZ Bar', 'Resistance Bands', 'Pull-up Bar',
    'Machines', 'Suspension Trainer', 'Exercise Ball', 'Sandbag',
    'Battle Ropes', 'Yoga Mat', 'Dip Station',
  ];

  /// Equipment types that get auto-selected when "Full Gym" is tapped.
  static const Set<String> _fullGymEquipment = {
    'Bodyweight', 'Dumbbells', 'Barbell', 'Cable Machine', 'Machines',
    'Smith Machine', 'Kettlebell', 'EZ Bar', 'Pull-up Bar',
  };

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
    _loadPresets();
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

  Future<void> _loadPresets() async {
    try {
      final db = ref.read(appDatabaseProvider);
      final userAsync = ref.read(currentUserProvider);
      final user = userAsync.valueOrNull;
      if (user == null) return;

      final userId = user.id;
      final presets = await QuickWorkoutPresetService.loadPresets(db, userId, user);
      final discover = QuickWorkoutPresetService.generateDiscoverPool(user);

      if (mounted) {
        setState(() {
          _presets = presets;
          _discoverPool = discover;
          _presetsLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('[QuickPresets] Failed to load presets: $e');
      if (mounted) setState(() => _presetsLoaded = true);
    }
  }

  void _initFromUserProfile() {
    final userAsync = ref.read(currentUserProvider);
    final user = userAsync.valueOrNull;
    if (user == null) return;

    // Read weight unit preference
    _weightUnit = user.preferredWeightUnit;

    // Pre-fill difficulty from fitness level
    final level = user.fitnessLevel?.toLowerCase();
    if (level != null && DifficultyUtils.internalValues.contains(level)) {
      _selectedDifficulty = level;
    }

    // Pre-fill equipment from profile (always include Bodyweight)
    final profileEquipment = user.equipmentList;
    if (profileEquipment.isNotEmpty) {
      _selectedEquipment = profileEquipment
          .where((e) => _allEquipmentOptions.any((o) => o.toLowerCase() == e.toLowerCase()))
          .map((e) => _allEquipmentOptions.firstWhere((o) => o.toLowerCase() == e.toLowerCase()))
          .toSet();
      _selectedEquipment.add('Bodyweight');
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

        // ── Preset row ──
        if (_presetsLoaded && _presets.isNotEmpty)
          SizedBox(
            height: 92,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _presets.length + 1, // +1 for Discover card
              itemBuilder: (context, index) {
                if (index == _presets.length) {
                  return _buildDiscoverCard(
                    accentColor: accentColor,
                    cardBackground: cardBackground,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  );
                }
                final preset = _presets[index];
                return _buildPresetCard(
                  preset: preset,
                  accentColor: accentColor,
                  cardBackground: cardBackground,
                  chipBorder: chipBorder,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                );
              },
            ),
          ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Duration slider
                Row(
                  children: [
                    Text(
                      'Duration',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$_selectedDuration min',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: accentColor,
                    inactiveTrackColor: chipBorder,
                    thumbColor: accentColor,
                    overlayColor: accentColor.withValues(alpha: 0.12),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  ),
                  child: Slider(
                    value: _selectedDuration.toDouble(),
                    min: 5,
                    max: 30,
                    divisions: 5,
                    onChanged: (v) {
                      HapticService.light();
                      setState(() => _selectedDuration = v.round());
                    },
                  ),
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
                  children: [
                    // Show first 5 options (2 rows)
                    ..._focusOptions.take(5).map((option) {
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
                    }),
                    // Show selected option from hidden set (if any)
                    ..._focusOptions.skip(5).where((option) =>
                        _selectedFocus == option['value']).map((option) {
                      final chipColor = (option['color'] as Color?) ?? accentColor;
                      return _FocusChip(
                        label: option['label'] as String,
                        icon: option['icon'] as IconData,
                        color: chipColor,
                        isSelected: true,
                        chipBorder: chipBorder,
                        onTap: () {
                          HapticService.light();
                          setState(() => _selectedFocus = null);
                        },
                        cardBackground: cardBackground,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                      );
                    }),
                    // "More" chip
                    GestureDetector(
                      onTap: () => _showMoreFocusDialog(
                        accentColor: accentColor,
                        cardBackground: cardBackground,
                        chipBorder: chipBorder,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: cardBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: chipBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.more_horiz, size: 18, color: textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              'More',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // "Customize more" toggle between Focus and advanced content
                TextButton.icon(
                  onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
                  icon: Icon(_showAdvanced ? Icons.expand_less : Icons.tune, size: 18),
                  label: Text(_showAdvanced ? 'Show less' : 'Customize more'),
                  style: TextButton.styleFrom(foregroundColor: textSecondary),
                ),

                // ── Advanced section (collapsed by default) ──
                if (_showAdvanced) ...[
                  const SizedBox(height: 8),

                  // Equipment selector (chips only — weight pickers further below)
                  Row(
                    children: [
                      Text(
                        'Equipment',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          HapticService.light();
                          setState(() {
                            final isFullGym = _fullGymEquipment.every(
                              (e) => _selectedEquipment.contains(e),
                            );
                            if (isFullGym) {
                              _selectedEquipment = {'Bodyweight'};
                              _equipmentDetails.clear();
                              _expandedEquipment = null;
                            } else {
                              _selectedEquipment = Set.from(_fullGymEquipment);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _fullGymEquipment.every(
                              (e) => _selectedEquipment.contains(e),
                            )
                                ? accentColor.withValues(alpha: 0.15)
                                : cardBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _fullGymEquipment.every(
                                (e) => _selectedEquipment.contains(e),
                              )
                                  ? accentColor
                                  : chipBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.fitness_center,
                                size: 14,
                                color: _fullGymEquipment.every(
                                  (e) => _selectedEquipment.contains(e),
                                )
                                    ? accentColor
                                    : textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Full Gym',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _fullGymEquipment.every(
                                    (e) => _selectedEquipment.contains(e),
                                  )
                                      ? accentColor
                                      : textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._primaryEquipment.map((equip) {
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
                      }),
                      if (!_fullGymEquipment.every((e) => _selectedEquipment.contains(e)))
                      ..._selectedEquipment
                          .where((e) => !_primaryEquipment.contains(e))
                          .map((equip) {
                        final hasDetails = _equipmentDetails.containsKey(equip);
                        final supportsDetail = _supportsWeightDetail(equip);
                        return _EquipmentChip(
                          label: equip,
                          isSelected: true,
                          hasDetails: hasDetails,
                          showTuneIcon: supportsDetail,
                          color: accentColor,
                          chipBorder: chipBorder,
                          onTap: () {
                            HapticService.light();
                            setState(() {
                              _selectedEquipment.remove(equip);
                              _equipmentDetails.remove(equip);
                              if (_expandedEquipment == equip) {
                                _expandedEquipment = null;
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
                      }),
                      GestureDetector(
                        onTap: () => _showMoreEquipmentDialog(
                          accentColor: accentColor,
                          cardBackground: cardBackground,
                          chipBorder: chipBorder,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          textMuted: textMuted,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: cardBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: chipBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, size: 14, color: textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                'More',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

                  // Difficulty selector
                  Text(
                    'Difficulty',
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
                                color: isSelected ? color.withValues(alpha: 0.15) : cardBackground,
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
                  Row(
                    children: [
                      {'value': 'strength', 'label': 'Strength', 'icon': Icons.fitness_center, 'color': Colors.red},
                      {'value': 'hypertrophy', 'label': 'Hypertrophy', 'icon': Icons.accessibility_new, 'color': Colors.blue},
                      {'value': 'endurance', 'label': 'Endurance', 'icon': Icons.directions_run, 'color': Colors.green},
                      {'value': 'power', 'label': 'Power', 'icon': Icons.bolt, 'color': Colors.orange},
                    ].asMap().entries.map((entry) {
                      final option = entry.value;
                      final isSelected = _selectedGoal == option['value'];
                      final chipColor = option['color'] as Color;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: entry.key < 3 ? 8 : 0,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              HapticService.light();
                              setState(() {
                                _selectedGoal = isSelected ? null : option['value'] as String;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? chipColor.withValues(alpha: 0.15) : cardBackground,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? chipColor : chipBorder,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    option['icon'] as IconData,
                                    size: 18,
                                    color: isSelected ? chipColor : textMuted,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    option['label'] as String,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? chipColor : textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
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

                  // Equipment Details (weight pickers — only for selected equipment)
                  if (_selectedEquipment.any(_supportsWeightDetail)) ...[
                    Text(
                      'Equipment Details',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._selectedEquipment.where(_supportsWeightDetail).map((equip) {
                      final isExpanded = _expandedEquipment == equip;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                HapticService.light();
                                setState(() {
                                  _expandedEquipment = isExpanded ? null : equip;
                                });
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                children: [
                                  Icon(Icons.tune, size: 16, color: accentColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    equip,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                  if (_equipmentDetails.containsKey(equip)) ...[
                                    const SizedBox(width: 4),
                                    Icon(Icons.check_circle, size: 14, color: accentColor),
                                  ],
                                  const Spacer(),
                                  AnimatedRotation(
                                    turns: isExpanded ? 0.5 : 0.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(Icons.expand_more, size: 20, color: textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            if (isExpanded)
                              _buildWeightPicker(
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
                      );
                    }),
                    const SizedBox(height: 8),
                  ],

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
                ], // end _showAdvanced
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
        lower == 'barbell' ||
        lower == 'ez bar';
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
                const SizedBox(width: 8),
                // Inline kg / lbs toggle
                Container(
                  decoration: BoxDecoration(
                    color: chipBorder,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final unit in ['kg', 'lbs'])
                        GestureDetector(
                          onTap: () {
                            if (_weightUnit == unit) return;
                            HapticService.light();
                            setState(() {
                              _weightUnit = unit;
                              // Clear stale weight selections since values differ per unit
                              _equipmentDetails.clear();
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _weightUnit == unit ? accentColor : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              unit,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _weightUnit == unit
                                    ? (Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white)
                                    : textMuted,
                              ),
                            ),
                          ),
                        ),
                    ],
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
    final weights = _weightUnit == 'lbs'
        ? [5.0, 10.0, 15.0, 20.0, 25.0, 30.0, 35.0, 40.0, 45.0, 50.0, 55.0, 60.0, 65.0, 70.0, 75.0, 80.0]
        : [5.0, 8.0, 10.0, 12.0, 15.0, 20.0, 25.0, 30.0, 35.0, 40.0, 45.0, 50.0];
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
                    weightUnit: _weightUnit,
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
          _weightUnit,
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
    final isLbs = _weightUnit == 'lbs';
    final barWeight = isLbs ? 45.0 : 20.0;
    final barLabel = isLbs ? 'Bar only (45 lbs)' : 'Bar only (20kg)';
    final barTempoLabel = isLbs ? 'High-rep tempo work at 45 lbs' : 'High-rep tempo work at 20kg';
    final plateInventory = isLbs
        ? {45.0: 1, 95.0: 1, 135.0: 1, 185.0: 1, 225.0: 1}
        : {20.0: 1, 40.0: 1, 60.0: 1, 80.0: 1, 100.0: 1};

    final existing = _equipmentDetails[equip];
    final isBarOnly = existing != null &&
        existing.weightInventory.length == 1 &&
        existing.weightInventory.containsKey(barWeight);
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
                      weightInventory: {barWeight: 1},
                      weightUnit: _weightUnit,
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
                      barLabel,
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
                    _equipmentDetails[equip] = EquipmentItem(
                      name: 'barbell',
                      displayName: 'Barbell',
                      quantity: 1,
                      weightInventory: plateInventory,
                      weightUnit: _weightUnit,
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
              barTempoLabel,
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

  void _showMoreFocusDialog({
    required Color accentColor,
    required Color cardBackground,
    required Color chipBorder,
    required Color textPrimary,
    required Color textMuted,
  }) {
    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Workout Focus',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 16),
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
                      Navigator.pop(ctx);
                    },
                    cardBackground: cardBackground,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                  );
                }).toList(),
              ),
              SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreEquipmentDialog({
    required Color accentColor,
    required Color cardBackground,
    required Color chipBorder,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
  }) {
    // Copy current selection so dialog can preview changes
    var tempSelection = Set<String>.from(_selectedEquipment);

    showGlassSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.8,
            expand: false,
            builder: (ctx, scrollController) => GlassSheet(
              showHandle: true,
              child: Column(
                children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        'All Equipment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() => _selectedEquipment = tempSelection);
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          'Done',
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _allEquipmentOptions.length,
                    itemBuilder: (ctx, index) {
                      final equip = _allEquipmentOptions[index];
                      final isSelected = tempSelection.contains(equip);
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          _getEquipmentIcon(equip),
                          color: isSelected ? accentColor : textMuted,
                          size: 22,
                        ),
                        title: Text(
                          equip,
                          style: TextStyle(
                            color: isSelected ? accentColor : textPrimary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: accentColor, size: 22)
                            : Icon(Icons.circle_outlined, color: chipBorder, size: 22),
                        onTap: () {
                          HapticService.light();
                          setModalState(() {
                            if (isSelected) {
                              tempSelection.remove(equip);
                            } else {
                              tempSelection.add(equip);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getEquipmentIcon(String equip) {
    switch (equip) {
      case 'Bodyweight':
        return Icons.accessibility_new;
      case 'Dumbbells':
        return Icons.fitness_center;
      case 'Barbell':
        return Icons.sports_gymnastics;
      case 'Cable Machine':
        return Icons.cable;
      case 'Kettlebell':
        return Icons.sports_mma;
      case 'Smith Machine':
        return Icons.view_column_outlined;
      case 'EZ Bar':
        return Icons.straighten;
      case 'Resistance Bands':
        return Icons.waves;
      case 'Pull-up Bar':
        return Icons.horizontal_rule;
      case 'Machines':
        return Icons.precision_manufacturing;
      case 'Suspension Trainer':
        return Icons.link;
      case 'Exercise Ball':
        return Icons.sports_baseball;
      case 'Sandbag':
        return Icons.inventory_2_outlined;
      case 'Battle Ropes':
        return Icons.gesture;
      case 'Yoga Mat':
        return Icons.self_improvement;
      case 'Dip Station':
        return Icons.expand;
      default:
        return Icons.fitness_center;
    }
  }

  Widget _buildPresetCard({
    required QuickWorkoutPreset preset,
    required Color accentColor,
    required Color cardBackground,
    required Color chipBorder,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final presetColor = preset.color;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _generateFromPreset(preset),
        onLongPress: () => _showPresetOptions(preset),
        child: Container(
          width: 100,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: presetColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: presetColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(preset.icon, size: 16, color: presetColor),
                  const SizedBox(width: 4),
                  Text(
                    '${preset.duration}m',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: presetColor,
                    ),
                  ),
                  const Spacer(),
                  if (preset.isFavorite)
                    Icon(Icons.favorite, size: 12, color: Colors.red.shade300),
                  if (preset.isAiGenerated && !preset.isFavorite)
                    Icon(Icons.auto_awesome, size: 12, color: presetColor.withOpacity(0.7)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _focusLabel(preset.focus),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                preset.subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoverCard({
    required Color accentColor,
    required Color cardBackground,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: _showDiscoverSheet,
        child: Container(
          width: 100,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentColor.withOpacity(0.2),
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, size: 24, color: accentColor),
              const SizedBox(height: 8),
              Text(
                'Discover',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _focusLabel(String? focus) {
    switch (focus) {
      case 'cardio': return 'Cardio';
      case 'strength': return 'Strength';
      case 'stretch': return 'Stretch';
      case 'full_body': return 'Full Body';
      case 'upper_body': return 'Upper Body';
      case 'lower_body': return 'Lower Body';
      case 'core': return 'Core';
      case 'emom': return 'EMOM';
      case 'amrap': return 'AMRAP';
      default: return 'Quick';
    }
  }

  void _generateFromPreset(QuickWorkoutPreset preset) {
    // Apply preset values to the sheet state, then generate
    setState(() {
      _selectedDuration = preset.duration;
      _selectedFocus = preset.focus;
      _selectedDifficulty = preset.difficulty;
      _selectedGoal = preset.goal;
      _selectedMood = preset.mood;
      _useSupersets = preset.useSupersets;
      _selectedEquipment = preset.equipment.toSet();
      _selectedInjuries = preset.injuries.toSet();
      _equipmentDetails.clear();
      if (preset.equipmentDetails != null) {
        _equipmentDetails.addAll(preset.equipmentDetails!);
      }
    });
    _generateQuickWorkout();
  }

  void _showPresetOptions(QuickWorkoutPreset preset) {
    HapticService.medium();
    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text(
                preset.label,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(
                  preset.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: preset.isFavorite ? Colors.red : null,
                ),
                title: Text(preset.isFavorite ? 'Unfavorite' : 'Favorite'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final db = ref.read(appDatabaseProvider);
                  await QuickWorkoutPresetService.toggleFavorite(db, preset.id);
                  await _loadPresets();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final db = ref.read(appDatabaseProvider);
                  await QuickWorkoutPresetService.deletePreset(db, preset.id);
                  await _loadPresets();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showDiscoverSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final accentColor = isDark ? AppColors.cyan : AppColorsLight.cyan;

    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                children: [
                  Icon(Icons.auto_awesome, color: accentColor, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Discover Workouts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Personalized suggestions based on your profile',
                  style: TextStyle(fontSize: 13, color: textSecondary),
                ),
              ),
              const SizedBox(height: 16),
              if (_discoverPool.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No additional suggestions available.',
                    style: TextStyle(color: textSecondary),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _discoverPool.map((preset) {
                    final presetColor = preset.color;
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _generateFromPreset(preset);
                      },
                      child: Container(
                        width: (MediaQuery.of(ctx).size.width - 56) / 2,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: presetColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: presetColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(preset.icon, size: 20, color: presetColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    preset.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    preset.subtitle,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Future<void> _generateQuickWorkout() async {
    HapticService.medium();

    // Check for conflict with existing workout on today's date
    final conflictResult = await _checkConflict();
    if (conflictResult == _ConflictAction.cancelled) return;

    // If user chose "Change Date", use the override date
    DateTime? scheduledDateOverride;
    if (conflictResult == _ConflictAction.changeDate) {
      final pickedDate = await _pickAlternateDate();
      if (pickedDate == null || !mounted) return;
      scheduledDateOverride = pickedDate;
    }

    // If user chose "Replace", delete the existing workout first
    if (conflictResult == _ConflictAction.replace && _conflictWorkoutId != null) {
      try {
        final apiClient = ref.read(apiClientProvider);
        await apiClient.delete(
          '${ApiConstants.workouts}/$_conflictWorkoutId',
        );
      } catch (e) {
        debugPrint('[QuickWorkout] Failed to delete existing workout: $e');
        // Continue anyway — the new workout will still be created
      }
    }

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
      scheduledDate: scheduledDateOverride,
    );

    if (workout != null && mounted) {
      // Auto-capture preset
      _autoCapturePreset();

      // Refresh today workout provider so carousel picks up the new workout
      ref.read(todayWorkoutProvider.notifier).refresh();
      // Also invalidate workoutsProvider to refresh the full list
      ref.invalidate(workoutsProvider);

      Navigator.pop(context, workout);
      // Navigate to active workout screen
      context.push('/workout/${workout.id}');
    }
  }

  /// Stored conflict workout ID for the "Replace" action
  String? _conflictWorkoutId;

  /// Check if there's a workout conflict on today's date.
  /// Returns the action the user chose (or noConflict if no existing workout).
  Future<_ConflictAction> _checkConflict() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final response = await apiClient.get(
        '${ApiConstants.workouts}/quick/conflict-check',
        queryParameters: {'date': dateStr},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['has_conflict'] == true && data['existing_workout'] != null) {
          final existing = data['existing_workout'] as Map<String, dynamic>;
          _conflictWorkoutId = existing['id'] as String?;
          final existingName = existing['name'] as String? ?? 'Workout';

          if (!mounted) return _ConflictAction.cancelled;
          return await _showConflictDialog(existingName);
        }
      }
    } catch (e) {
      debugPrint('[QuickWorkout] Conflict check failed: $e');
      // Graceful degradation: proceed without dialog
    }
    return _ConflictAction.noConflict;
  }

  /// Show the conflict resolution dialog.
  Future<_ConflictAction> _showConflictDialog(String existingWorkoutName) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showDialog<_ConflictAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Workout Already Scheduled',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          'You already have "$existingWorkoutName" scheduled for today. What would you like to do?',
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _ConflictAction.changeDate),
            child: const Text('Change Date'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _ConflictAction.addAnyway),
            child: const Text('Add Anyway'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _ConflictAction.replace),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
    return result ?? _ConflictAction.cancelled;
  }

  /// Show a date picker for the "Change Date" option.
  Future<DateTime?> _pickAlternateDate() async {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      helpText: 'Schedule quick workout for...',
    );
  }

  Future<void> _autoCapturePreset() async {
    try {
      final db = ref.read(appDatabaseProvider);
      final userAsync = ref.read(currentUserProvider);
      final user = userAsync.valueOrNull;
      if (user == null) return;

      await QuickWorkoutPresetService.autoCapture(
        db,
        user.id,
        duration: _selectedDuration,
        focus: _selectedFocus,
        difficulty: _selectedDifficulty,
        goal: _selectedGoal,
        mood: _selectedMood,
        useSupersets: _useSupersets,
        equipment: _selectedEquipment.toList(),
        injuries: _selectedInjuries.toList(),
        equipmentDetails: _equipmentDetails.isNotEmpty ? _equipmentDetails : null,
      );
    } catch (e) {
      debugPrint('[QuickPresets] Auto-capture failed: $e');
    }
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
