import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/providers/user_provider.dart';
import '../data/providers/gym_profile_provider.dart';
import '../data/providers/today_workout_provider.dart';
import '../data/services/haptic_service.dart';
import 'glass_sheet.dart';


part 'staple_choice_sheet_part_staple_choice_result.dart';
part 'staple_choice_sheet_part_day_target_mode.dart';

part 'staple_choice_sheet_ui.dart';


/// Shows the staple choice sheet and returns the user's selection.
Future<StapleChoiceResult?> showStapleChoiceSheet(
  BuildContext context, {
  required String exerciseName,
  String? equipmentValue,
  String? category,
  String? initialSection,
}) async {
  return showGlassSheet<StapleChoiceResult>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    builder: (sheetContext) => GlassSheet(
      child: StapleChoiceSheet(
        exerciseName: exerciseName,
        equipmentValue: equipmentValue,
        category: category,
        initialSection: initialSection,
        onCancel: () async {
          final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
          final discard = await showDialog<bool>(
            context: sheetContext,
            builder: (dialogContext) {
              return AlertDialog(
                backgroundColor:
                    isDark ? AppColors.elevated : AppColorsLight.elevated,
                title: const Text('Discard selection?'),
                content: const Text(
                  'Your exercise won\'t be saved as a staple.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text(
                      'Go Back',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textMuted
                            : AppColorsLight.textMuted,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: Text(
                      'Discard',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              );
            },
          );
          if (discard == true && sheetContext.mounted) {
            Navigator.pop(sheetContext);
          }
        },
      ),
    ),
  );
}

/// Bottom sheet for choosing when a staple exercise should apply,
/// with optional cardio parameter inputs and swap-with-exercise option.
class StapleChoiceSheet extends ConsumerStatefulWidget {
  final String exerciseName;
  final String? equipmentValue;
  final String? category;
  final String? initialSection;
  final VoidCallback onCancel;

  const StapleChoiceSheet({
    super.key,
    required this.exerciseName,
    this.equipmentValue,
    this.category,
    this.initialSection,
    required this.onCancel,
  });

  @override
  ConsumerState<StapleChoiceSheet> createState() => _StapleChoiceSheetState();
}

class _StapleChoiceSheetState extends ConsumerState<StapleChoiceSheet> {
  late String _selectedSection = widget.initialSection ?? 'main';
  bool _addToday = true; // true = today, false = next workout
  String? _selectedProfileId;
  bool _profileIdInitialized = false;
  bool _showSwapList = false;

  // Strength/timed controllers
  final _setsController = TextEditingController(text: '3');
  final _repsController = TextEditingController(text: '10');
  final _restController = TextEditingController(text: '60');
  final _weightController = TextEditingController();
  bool _showStrengthParams = true;

  // Day-of-week targeting
  _DayTargetMode _dayTargetMode = _DayTargetMode.workoutDays;
  final Set<int> _selectedDays = {}; // 0=Mon, 6=Sun

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // Cardio controllers
  final _durationController = TextEditingController(text: '10');
  final _speedController = TextEditingController(text: '3.5');
  final _inclineController = TextEditingController(text: '5');
  final _rpmController = TextEditingController(text: '70');
  final _resistanceController = TextEditingController(text: '5');
  final _strokeRateController = TextEditingController(text: '25');
  final _distanceController = TextEditingController();
  final _paceController = TextEditingController();

  // Advanced (universal) controllers — apply to any exercise type
  final _rpeController = TextEditingController();
  final _tempoController = TextEditingController();
  final _notesController = TextEditingController();
  final _romController = TextEditingController();
  String? _selectedBandColor;
  bool _showAdvanced = false;

  static const _bandColors = [
    ('yellow', 'Yellow (light)'),
    ('red', 'Red (medium)'),
    ('green', 'Green (heavy)'),
    ('blue', 'Blue (extra heavy)'),
    ('black', 'Black (max)'),
    ('purple', 'Purple'),
  ];

  static const _sections = [
    ('main', 'Main'),
    ('warmup', 'Warmup'),
    ('stretches', 'Stretch'),
  ];

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _restController.dispose();
    _weightController.dispose();
    _durationController.dispose();
    _speedController.dispose();
    _inclineController.dispose();
    _rpmController.dispose();
    _resistanceController.dispose();
    _strokeRateController.dispose();
    _distanceController.dispose();
    _paceController.dispose();
    _rpeController.dispose();
    _tempoController.dispose();
    _notesController.dispose();
    _romController.dispose();
    super.dispose();
  }

  bool get _isCardio {
    final eq = widget.equipmentValue?.toLowerCase() ?? '';
    final cat = widget.category?.toLowerCase() ?? '';
    final name = widget.exerciseName.toLowerCase();
    return cat == 'cardio' ||
        eq.contains('treadmill') ||
        eq.contains('bike') ||
        eq.contains('rower') ||
        eq.contains('elliptical') ||
        name.contains('walk') ||
        name.contains('run') ||
        name.contains('jog') ||
        name.contains('hike') ||
        name.contains('cycle') ||
        name.contains('cycling') ||
        name.contains('swim') ||
        name.contains('row') ||
        name.contains('sprint');
  }

  bool get _isTimed {
    final name = widget.exerciseName.toLowerCase();
    final cat = widget.category?.toLowerCase() ?? '';
    return name.contains('hold') || name.contains('plank') || name.contains('hang') ||
           name.contains('isometric') || name.contains('static') || name.contains('wall sit') ||
           cat == 'isometric' || cat == 'static' || cat == 'stretching';
  }

  bool get _isStrength => !_isCardio && !_isTimed;

  bool get _isStretching {
    final name = widget.exerciseName.toLowerCase();
    final cat = widget.category?.toLowerCase() ?? '';
    return cat == 'stretching' || cat == 'flexibility' || cat == 'mobility' ||
        name.contains('stretch') || name.contains('yoga') || name.contains('mobility');
  }

  bool get _usesBand {
    final eq = widget.equipmentValue?.toLowerCase() ?? '';
    return eq.contains('band') || eq.contains('resistance');
  }

  bool get _supportsIncline {
    final name = widget.exerciseName.toLowerCase();
    final eq = widget.equipmentValue?.toLowerCase() ?? '';
    return eq.contains('treadmill') ||
        name.contains('incline') ||
        name.contains('walk') ||
        name.contains('run') ||
        name.contains('hike') ||
        name.contains('bench');
  }

  String get _cardioType {
    final eq = widget.equipmentValue?.toLowerCase() ?? '';
    final name = widget.exerciseName.toLowerCase();
    if (eq.contains('treadmill')) return 'treadmill';
    if (eq.contains('bike') || name.contains('cycle') || name.contains('cycling')) return 'bike';
    if (eq.contains('rower') || name.contains('row')) return 'rower';
    if (eq.contains('elliptical')) return 'elliptical';
    if (name.contains('walk') || name.contains('hike')) return 'walking';
    if (name.contains('run') || name.contains('jog') || name.contains('sprint')) return 'running';
    if (name.contains('swim')) return 'swimming';
    return 'generic';
  }


  Map<String, double>? _buildCardioParams() {
    final params = <String, double>{};

    if (_isCardio) {
      final duration = double.tryParse(_durationController.text);
      if (duration != null) params['duration_seconds'] = duration * 60;

      final type = _cardioType;
      if (type == 'treadmill' || type == 'walking' || type == 'running') {
        final speed = double.tryParse(_speedController.text);
        if (speed != null) params['speed_mph'] = speed;
        final incline = double.tryParse(_inclineController.text);
        if (incline != null) params['incline_percent'] = incline;
        final distance = double.tryParse(_distanceController.text);
        if (distance != null) params['distance_miles'] = distance;
      } else if (type == 'bike') {
        final rpm = double.tryParse(_rpmController.text);
        if (rpm != null) params['rpm'] = rpm;
        final resistance = double.tryParse(_resistanceController.text);
        if (resistance != null) params['resistance_level'] = resistance;
      } else if (type == 'rower') {
        final strokeRate = double.tryParse(_strokeRateController.text);
        if (strokeRate != null) params['stroke_rate_spm'] = strokeRate;
      } else if (type == 'elliptical') {
        final resistance = double.tryParse(_resistanceController.text);
        if (resistance != null) params['resistance_level'] = resistance;
      } else if (type == 'swimming') {
        final distance = double.tryParse(_distanceController.text);
        if (distance != null) params['distance_miles'] = distance;
      }
    }

    // Universal advanced fields — apply regardless of exercise type.
    if (_showAdvanced) {
      if (!_isCardio && _supportsIncline) {
        final incline = double.tryParse(_inclineController.text);
        if (incline != null) params['incline_percent'] = incline;
      }
      final rpe = double.tryParse(_rpeController.text);
      if (rpe != null) params['rpe'] = rpe;
    }

    // Non-cardio "More (optional)" fields — only emitted when the user
    // actually typed a value AND it differs from the controller's pre-filled
    // default. Lets custom exercises like "Cat Nap" capture distance / incline
    // / duration / speed without forcing all strength rows to inherit cardio
    // defaults they never asked for.
    if (!_isCardio && _showStrengthParams) {
      const _defaults = {
        'duration': '10',
        'incline': '5',
        'speed': '3.5',
      };
      double? _readIfEdited(TextEditingController c, String defaultKey) {
        final text = c.text.trim();
        if (text.isEmpty) return null;
        if (text == _defaults[defaultKey]) return null;
        return double.tryParse(text);
      }

      final duration = _readIfEdited(_durationController, 'duration');
      if (duration != null) params['duration_seconds'] = duration * 60;
      final distance = double.tryParse(_distanceController.text.trim());
      if (distance != null) params['distance_miles'] = distance;
      final incline = _readIfEdited(_inclineController, 'incline');
      if (incline != null) params['incline_percent'] = incline;
      final speed = _readIfEdited(_speedController, 'speed');
      if (speed != null) params['speed_mph'] = speed;
    }

    return params.isEmpty ? null : params;
  }

  Color _parseChipColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.cyan;
    }
  }

  StapleChoiceResult _makeResult({
    required bool addToday,
    String? swapExerciseId,
    bool goBack = false,
  }) {
    final tempo = _showAdvanced ? _tempoController.text.trim() : '';
    final notes = _showAdvanced ? _notesController.text.trim() : '';
    final rom = _showAdvanced ? _romController.text.trim() : '';

    return (
      addToday: addToday,
      section: _selectedSection,
      gymProfileId: _selectedProfileId,
      swapExerciseId: swapExerciseId,
      cardioParams: _buildCardioParams(),
      userSets: _isStrength && _showStrengthParams ? int.tryParse(_setsController.text) : null,
      userReps: _isStrength && _showStrengthParams ? _repsController.text : null,
      userRestSeconds: _isStrength && _showStrengthParams ? int.tryParse(_restController.text) : null,
      userWeightLbs: _isStrength && _showStrengthParams ? double.tryParse(_weightController.text) : null,
      targetDays: _dayTargetMode == _DayTargetMode.everyDay
          ? [0, 1, 2, 3, 4, 5, 6]
          : _dayTargetMode == _DayTargetMode.custom && _selectedDays.isNotEmpty
              ? (_selectedDays.toList()..sort())
              : null,
      userTempo: tempo.isEmpty ? null : tempo,
      userNotes: notes.isEmpty ? null : notes,
      userBandColor: _showAdvanced ? _selectedBandColor : null,
      userRangeOfMotion: rom.isEmpty ? null : rom,
      goBack: goBack,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);

    final profiles = ref.watch(gymProfilesProvider).valueOrNull ?? [];
    final activeProfile = ref.watch(activeGymProfileProvider);

    if (!_profileIdInitialized && activeProfile != null) {
      _selectedProfileId = activeProfile.id;
      _profileIdInitialized = true;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),

            // Header with exercise name and close button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.exerciseName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.onCancel,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: textMuted.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Gym profile picker (only show if 2+ profiles)
            if (profiles.length >= 2) ...[
              Text(
                'Which gym profile?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildProfileChip(
                      label: 'All Profiles',
                      isSelected: _selectedProfileId == null,
                      color: textMuted,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      onTap: () =>
                          setState(() => _selectedProfileId = null),
                    ),
                    ...profiles.map((profile) {
                      final chipColor = _parseChipColor(profile.color);
                      return _buildProfileChip(
                        label: profile.name,
                        isSelected: _selectedProfileId == profile.id,
                        color: chipColor,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                        onTap: () => setState(
                            () => _selectedProfileId = profile.id),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Cardio settings (if applicable)
            if (_isCardio) ...[
              _buildCardioSection(textPrimary, textMuted, cardColor, cardBorder),
              const SizedBox(height: 16),
            ],

            // Strength/Timed settings (non-cardio)
            if (_isStrength || _isTimed) ...[
              _buildStrengthSection(textPrimary, textMuted, cardColor, cardBorder),
              const SizedBox(height: 16),
            ],

            // Universal Advanced section (RPE, tempo, band, notes, incline, etc.)
            _buildAdvancedSection(textPrimary, textMuted, cardColor, cardBorder),
            const SizedBox(height: 16),

            // Day-of-week targeting
            _buildDayPickerSection(textPrimary, textMuted, cardColor, cardBorder),
            const SizedBox(height: 16),

            // When to apply
            Text(
              'When to apply',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Timing toggle: Today vs Next workout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildToggleOption(
                      icon: Icons.bolt,
                      label: "Today's workout",
                      isSelected: _addToday,
                      color: AppColors.cyan,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      onTap: () => setState(() => _addToday = true),
                    ),
                    const SizedBox(width: 4),
                    _buildToggleOption(
                      icon: Icons.skip_next,
                      label: 'Next workout',
                      isSelected: !_addToday,
                      color: AppColors.cyan,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      onTap: () => setState(() => _addToday = false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Add as section
            Text(
              'Add as',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Section chips: Main / Warmup / Stretch
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _sections.map((entry) {
                  final (value, label) = entry;
                  final isSelected = _selectedSection == value;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: value != 'stretches' ? 8 : 0),
                      child: GestureDetector(
                        onTap: () {
                          HapticService.light();
                          setState(() => _selectedSection = value);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.cyan : cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.cyan : cardBorder,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected ? Colors.white : textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Swap option (alternative to Save)
            _buildSwapOption(
                textPrimary, textMuted, cardColor, cardBorder),
            const SizedBox(height: 16),

            // Save button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticService.medium();
                    Navigator.pop(context, _makeResult(addToday: _addToday));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthSection(
    Color textPrimary,
    Color textMuted,
    Color cardColor,
    Color cardBorder,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          HapticService.light();
          setState(() => _showStrengthParams = !_showStrengthParams);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.tune, color: AppColors.cyan, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Customize (optional)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    _showStrengthParams ? Icons.expand_less : Icons.expand_more,
                    color: textMuted,
                    size: 20,
                  ),
                ],
              ),
              if (_showStrengthParams) ...[
                const SizedBox(height: 12),
                if (_isStrength) ...[
                  _buildCardioField(
                    label: 'Weight',
                    controller: _weightController,
                    suffix: 'lbs',
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                  ),
                  const SizedBox(height: 8),
                ],
                _buildCardioField(
                  label: 'Sets',
                  controller: _setsController,
                  suffix: '',
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
                const SizedBox(height: 8),
                if (_isStrength)
                  _buildCardioField(
                    label: 'Reps',
                    controller: _repsController,
                    suffix: '',
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                  ),
                const SizedBox(height: 8),
                _buildCardioField(
                  label: 'Rest',
                  controller: _restController,
                  suffix: 'sec',
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
                // Optional extra fields — exposed for any non-cardio exercise
                // so custom exercises (e.g. "Cat Nap") and walks/incline work
                // can capture distance/duration/incline alongside sets/reps.
                // All optional; empty values are dropped in _buildCardioParams.
                const SizedBox(height: 12),
                Text(
                  'More (optional)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textMuted,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 8),
                _buildCardioField(
                  label: 'Duration',
                  controller: _durationController,
                  suffix: 'min',
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
                const SizedBox(height: 8),
                _buildCardioField(
                  label: 'Distance',
                  controller: _distanceController,
                  suffix: 'mi',
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
                const SizedBox(height: 8),
                _buildCardioField(
                  label: 'Incline',
                  controller: _inclineController,
                  suffix: '%',
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
                const SizedBox(height: 8),
                _buildCardioField(
                  label: 'Speed',
                  controller: _speedController,
                  suffix: 'mph',
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayPickerSection(
    Color textPrimary,
    Color textMuted,
    Color cardColor,
    Color cardBorder,
  ) {
    final userAsync = ref.watch(currentUserProvider);
    final workoutDays = userAsync.valueOrNull?.workoutDays ?? [];

    String subtitle;
    switch (_dayTargetMode) {
      case _DayTargetMode.workoutDays:
        subtitle = workoutDays.isNotEmpty
            ? workoutDays.map((d) => _dayLabels[d]).join(', ')
            : 'Your scheduled workout days';
      case _DayTargetMode.everyDay:
        subtitle = 'Sun - Sat';
      case _DayTargetMode.custom:
        subtitle = _selectedDays.isNotEmpty
            ? (_selectedDays.toList()..sort()).map((d) => _dayLabels[d]).join(', ')
            : 'Select days below';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Target Days',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: textMuted),
          ),
          const SizedBox(height: 12),
          // 3-option segmented control
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildDayModeOption(
                  label: 'Workout Days',
                  mode: _DayTargetMode.workoutDays,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
                const SizedBox(width: 4),
                _buildDayModeOption(
                  label: 'Every Day',
                  mode: _DayTargetMode.everyDay,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
                const SizedBox(width: 4),
                _buildDayModeOption(
                  label: 'Custom',
                  mode: _DayTargetMode.custom,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ],
            ),
          ),
          // Custom day picker (only visible when Custom is selected)
          if (_dayTargetMode == _DayTargetMode.custom) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (i) {
                final isSelected = _selectedDays.contains(i);
                final isWorkoutDay = workoutDays.contains(i);
                return GestureDetector(
                  onTap: () {
                    HapticService.light();
                    setState(() {
                      if (isSelected) {
                        _selectedDays.remove(i);
                      } else {
                        _selectedDays.add(i);
                      }
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.cyan
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.cyan
                                : isWorkoutDay
                                    ? AppColors.cyan.withValues(alpha: 0.4)
                                    : textMuted.withValues(alpha: 0.3),
                            width: isWorkoutDay && !isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _dayLabels[i].substring(0, 1),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isSelected ? Colors.white : textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isWorkoutDay
                              ? AppColors.cyan.withValues(alpha: 0.6)
                              : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            if (workoutDays.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Dots = your workout days',
                style: TextStyle(
                  fontSize: 11,
                  color: textMuted.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDayModeOption({
    required String label,
    required _DayTargetMode mode,
    required Color textPrimary,
    required Color textMuted,
  }) {
    final isSelected = _dayTargetMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticService.light();
          setState(() => _dayTargetMode = mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.cyan.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: AppColors.cyan.withValues(alpha: 0.3))
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? textPrimary : textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwapOption(
    Color textPrimary,
    Color textMuted,
    Color cardColor,
    Color cardBorder,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          HapticService.light();
          setState(() => _showSwapList = !_showSwapList);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.swap_horiz, color: AppColors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Swap with exercise',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Replace an exercise in today's workout",
                          style: TextStyle(
                            fontSize: 12,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _showSwapList
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: textMuted,
                    size: 20,
                  ),
                ],
              ),
              if (_showSwapList) ...[
                const SizedBox(height: 12),
                _buildWorkoutExerciseList(textPrimary, textMuted),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Universal advanced options — shows for every exercise type, collapsed by default.
  /// Contains: incline (if supported), RPE, tempo, band color (if bands), ROM, free-form notes.
  Widget _buildAdvancedSection(
    Color textPrimary,
    Color textMuted,
    Color cardColor,
    Color cardBorder,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                HapticService.light();
                setState(() => _showAdvanced = !_showAdvanced);
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.science_outlined, color: AppColors.cyan, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Advanced (optional)',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _advancedSubtitle(),
                            style: TextStyle(fontSize: 12, color: textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _showAdvanced ? Icons.expand_less : Icons.expand_more,
                      color: textMuted,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (_showAdvanced) ...[
              Divider(height: 1, color: cardBorder),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Incline — shown for exercises that support it and aren't already showing it in cardio
                    if (_supportsIncline && !_isCardio) ...[
                      _buildCardioField(
                        label: 'Incline',
                        controller: _inclineController,
                        suffix: '%',
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Hold duration — shown for timed exercises if cardio section isn't already handling it
                    if (_isTimed && !_isCardio) ...[
                      _buildCardioField(
                        label: 'Hold duration',
                        controller: _durationController,
                        suffix: 'sec',
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                      ),
                      const SizedBox(height: 8),
                    ],

                    // RPE — universal 1-10 scale
                    _buildCardioField(
                      label: 'RPE (effort)',
                      controller: _rpeController,
                      suffix: '/10',
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),
                    const SizedBox(height: 8),

                    // Tempo — only meaningful for strength work
                    if (_isStrength) ...[
                      _buildCardioField(
                        label: 'Tempo',
                        controller: _tempoController,
                        suffix: 'e.g. 3-0-1-0',
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Range of motion
                    if (_isStrength || _isStretching) ...[
                      _buildCardioField(
                        label: 'ROM',
                        controller: _romController,
                        suffix: 'e.g. full',
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Band color chips
                    if (_usesBand) ...[
                      Text(
                        'Band',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _bandColors.map((entry) {
                          final (value, label) = entry;
                          final isSelected = _selectedBandColor == value;
                          return GestureDetector(
                            onTap: () {
                              HapticService.light();
                              setState(() {
                                _selectedBandColor = isSelected ? null : value;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.cyan.withValues(alpha: 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.cyan
                                      : textMuted.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: isSelected ? AppColors.cyan : textMuted,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Free-form notes
                    Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      maxLength: 300,
                      style: TextStyle(fontSize: 14, color: textPrimary),
                      decoration: InputDecoration(
                        hintText: 'e.g. Focus on squeeze at top, slow eccentric',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: textMuted.withValues(alpha: 0.6),
                        ),
                        filled: true,
                        fillColor: textMuted.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: textMuted.withValues(alpha: 0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: textMuted.withValues(alpha: 0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.cyan),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                        isDense: true,
                      ),
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

  String _advancedSubtitle() {
    final parts = <String>[];
    if (_supportsIncline) parts.add('incline');
    parts.add('RPE');
    if (_isStrength) parts.add('tempo');
    if (_usesBand) parts.add('band');
    parts.add('notes');
    return parts.join(', ');
  }
}
