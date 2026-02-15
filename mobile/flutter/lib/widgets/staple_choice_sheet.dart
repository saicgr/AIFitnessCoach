import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../data/providers/gym_profile_provider.dart';
import '../data/providers/today_workout_provider.dart';
import '../data/services/haptic_service.dart';
import 'glass_sheet.dart';

/// Result type from the staple choice sheet
typedef StapleChoiceResult = ({
  bool addToday,
  String section,
  String? gymProfileId,
  String? swapExerciseId,
  Map<String, double>? cardioParams,
});

/// Shows the staple choice sheet and returns the user's selection.
Future<StapleChoiceResult?> showStapleChoiceSheet(
  BuildContext context, {
  required String exerciseName,
  String? equipmentValue,
  String? category,
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
  final VoidCallback onCancel;

  const StapleChoiceSheet({
    super.key,
    required this.exerciseName,
    this.equipmentValue,
    this.category,
    required this.onCancel,
  });

  @override
  ConsumerState<StapleChoiceSheet> createState() => _StapleChoiceSheetState();
}

class _StapleChoiceSheetState extends ConsumerState<StapleChoiceSheet> {
  String _selectedSection = 'main';
  String? _selectedProfileId;
  bool _profileIdInitialized = false;
  bool _showSwapList = false;

  // Cardio controllers
  final _durationController = TextEditingController(text: '10');
  final _speedController = TextEditingController(text: '3.5');
  final _inclineController = TextEditingController(text: '5');
  final _rpmController = TextEditingController(text: '70');
  final _resistanceController = TextEditingController(text: '5');
  final _strokeRateController = TextEditingController(text: '25');

  static const _sections = [
    ('main', 'Main'),
    ('warmup', 'Warmup'),
    ('stretches', 'Stretch'),
  ];

  @override
  void dispose() {
    _durationController.dispose();
    _speedController.dispose();
    _inclineController.dispose();
    _rpmController.dispose();
    _resistanceController.dispose();
    _strokeRateController.dispose();
    super.dispose();
  }

  bool get _isCardio {
    final eq = widget.equipmentValue?.toLowerCase() ?? '';
    final cat = widget.category?.toLowerCase() ?? '';
    return cat == 'cardio' ||
        eq.contains('treadmill') ||
        eq.contains('bike') ||
        eq.contains('rower') ||
        eq.contains('elliptical');
  }

  String get _cardioType {
    final eq = widget.equipmentValue?.toLowerCase() ?? '';
    if (eq.contains('treadmill')) return 'treadmill';
    if (eq.contains('bike')) return 'bike';
    if (eq.contains('rower')) return 'rower';
    if (eq.contains('elliptical')) return 'elliptical';
    return 'generic';
  }

  Map<String, double>? _buildCardioParams() {
    if (!_isCardio) return null;
    final params = <String, double>{};

    final duration = double.tryParse(_durationController.text);
    if (duration != null) params['duration_seconds'] = duration * 60;

    final type = _cardioType;
    if (type == 'treadmill') {
      final speed = double.tryParse(_speedController.text);
      if (speed != null) params['speed_mph'] = speed;
      final incline = double.tryParse(_inclineController.text);
      if (incline != null) params['incline_percent'] = incline;
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
  }) {
    return (
      addToday: addToday,
      section: _selectedSection,
      gymProfileId: _selectedProfileId,
      swapExerciseId: swapExerciseId,
      cardioParams: _buildCardioParams(),
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
            const SizedBox(height: 20),

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

            // Title
            Text(
              'When should this apply?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            // Option 1: Add to today's workout
            _buildTimingOption(
              icon: Icons.bolt,
              iconColor: AppColors.cyan,
              title: "Add to today's workout",
              subtitle: null,
              showSectionChips: true,
              textPrimary: textPrimary,
              textMuted: textMuted,
              cardColor: cardColor,
              cardBorder: cardBorder,
              onTap: () {
                HapticService.light();
                Navigator.pop(context, _makeResult(addToday: true));
              },
            ),
            const SizedBox(height: 12),

            // Option 2: Start from next workout
            _buildTimingOption(
              icon: Icons.skip_next,
              iconColor: textMuted,
              title: 'Start from next workout',
              subtitle: 'Current workout unchanged',
              showSectionChips: false,
              textPrimary: textPrimary,
              textMuted: textMuted,
              cardColor: cardColor,
              cardBorder: cardBorder,
              onTap: () {
                HapticService.light();
                Navigator.pop(context, _makeResult(addToday: false));
              },
            ),
            const SizedBox(height: 12),

            // Option 3: Swap with exercise
            _buildSwapOption(
                textPrimary, textMuted, cardColor, cardBorder),
            const SizedBox(height: 16),

            // Cancel button
            TextButton(
              onPressed: widget.onCancel,
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 15,
                  color: textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileChip({
    required String label,
    required bool isSelected,
    required Color color,
    required Color textPrimary,
    required Color textMuted,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticService.light();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.5)
                : textMuted.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? textPrimary : textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildCardioSection(
    Color textPrimary,
    Color textMuted,
    Color cardColor,
    Color cardBorder,
  ) {
    final type = _cardioType;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                Icon(Icons.timer, color: AppColors.cyan, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Cardio Settings',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCardioField(
              label: 'Duration',
              controller: _durationController,
              suffix: 'min',
              textPrimary: textPrimary,
              textMuted: textMuted,
            ),
            if (type == 'treadmill') ...[
              const SizedBox(height: 8),
              _buildCardioField(
                label: 'Speed',
                controller: _speedController,
                suffix: 'mph',
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
            ],
            if (type == 'bike') ...[
              const SizedBox(height: 8),
              _buildCardioField(
                label: 'RPM',
                controller: _rpmController,
                suffix: '',
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              const SizedBox(height: 8),
              _buildCardioField(
                label: 'Resistance',
                controller: _resistanceController,
                suffix: '',
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
            ],
            if (type == 'rower') ...[
              const SizedBox(height: 8),
              _buildCardioField(
                label: 'Stroke Rate',
                controller: _strokeRateController,
                suffix: 'spm',
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
            ],
            if (type == 'elliptical') ...[
              const SizedBox(height: 8),
              _buildCardioField(
                label: 'Resistance',
                controller: _resistanceController,
                suffix: '',
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCardioField({
    required String label,
    required TextEditingController controller,
    required String suffix,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: textMuted),
          ),
        ),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(fontSize: 14, color: textPrimary),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              suffixText: suffix,
              suffixStyle: TextStyle(fontSize: 12, color: textMuted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: textMuted.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: textMuted.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.cyan),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimingOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String? subtitle,
    required bool showSectionChips,
    required Color textPrimary,
    required Color textMuted,
    required Color cardColor,
    required Color cardBorder,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: onTap,
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
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (showSectionChips) ...[
                const SizedBox(height: 12),
                Row(
                  children: _sections.map((entry) {
                    final (value, label) = entry;
                    final isSelected = _selectedSection == value;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          HapticService.light();
                          setState(() => _selectedSection = value);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.cyan
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
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected ? Colors.white : textMuted,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
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

  Widget _buildWorkoutExerciseList(Color textPrimary, Color textMuted) {
    final todayWorkout = ref.watch(todayWorkoutProvider);
    return todayWorkout.when(
      data: (response) {
        final workout = response?.todayWorkout ?? response?.nextWorkout;
        if (workout == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No workout available',
              style: TextStyle(fontSize: 13, color: textMuted),
            ),
          );
        }
        final exercises = workout.exercises;
        if (exercises.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No exercises in workout',
              style: TextStyle(fontSize: 13, color: textMuted),
            ),
          );
        }
        return Column(
          children: exercises.map((ex) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.fitness_center, size: 18, color: textMuted),
              title: Text(
                ex.name,
                style: TextStyle(
                  fontSize: 14,
                  color: textPrimary,
                ),
              ),
              subtitle: ex.muscleGroup != null
                  ? Text(
                      ex.muscleGroup!,
                      style: TextStyle(fontSize: 12, color: textMuted),
                    )
                  : null,
              dense: true,
              onTap: () {
                HapticService.light();
                Navigator.pop(
                  context,
                  _makeResult(addToday: true, swapExerciseId: ex.name),
                );
              },
            );
          }).toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Could not load workout',
          style: TextStyle(fontSize: 13, color: textMuted),
        ),
      ),
    );
  }
}
