import 'package:flutter/material.dart';
import '../../../../core/theme/theme_colors.dart';

/// Data class holding all wellness check-in values.
class WellnessCheckinData {
  /// Sleep quality on Hooper scale (1-7).
  final int sleepQuality;

  /// Energy level on Hooper scale (1-7).
  final int energyLevel;

  /// Muscle soreness on Hooper scale (1-7).
  final int muscleSoreness;

  /// Stress level on Hooper scale (1-7).
  final int stressLevel;

  /// Selected mood emoji string.
  final String mood;

  /// Optional free-text notes.
  final String? notes;

  const WellnessCheckinData({
    required this.sleepQuality,
    required this.energyLevel,
    required this.muscleSoreness,
    required this.stressLevel,
    required this.mood,
    this.notes,
  });
}

/// Unified daily wellness check-in card that replaces both
/// [HomeReadinessCard] and [MoodPickerCard] with a single 3-step flow.
///
/// Steps:
///   1. Sleep quality + Energy level (1-5 display, mapped to Hooper 1-7)
///   2. Muscle soreness + Stress level (1-5 display, mapped to Hooper 1-7)
///   3. Mood emoji picker + optional notes
class WellnessCheckinCard extends StatefulWidget {
  /// Called with all collected values when the user taps Submit.
  final ValueChanged<WellnessCheckinData> onSubmit;

  /// When true, the card shows the compact "Checked in" summary instead of
  /// the multi-step form.
  final bool hasCheckedIn;

  /// Summary values to display in the completed state. Only used when
  /// [hasCheckedIn] is true.
  final WellnessCheckinData? completedData;

  const WellnessCheckinCard({
    super.key,
    required this.onSubmit,
    this.hasCheckedIn = false,
    this.completedData,
  });

  @override
  State<WellnessCheckinCard> createState() => _WellnessCheckinCardState();
}

class _WellnessCheckinCardState extends State<WellnessCheckinCard> {
  int _currentStep = 0;

  // Display values 1-5 (mapped to Hooper on submit)
  double _sleepQuality = 3;
  double _energyLevel = 3;
  double _muscleSoreness = 3;
  double _stressLevel = 3;

  int _selectedMoodIndex = 0;
  final TextEditingController _notesController = TextEditingController();

  static const _totalSteps = 3;

  static const List<String> _moodEmojis = [
    '\u{1F60A}', // smiling face
    '\u{1F610}', // neutral face
    '\u{1F614}', // pensive face
    '\u{1F624}', // angry face
    '\u{1F634}', // sleeping face
  ];

  static const List<String> _moodLabels = [
    'Happy',
    'Neutral',
    'Sad',
    'Frustrated',
    'Tired',
  ];

  static const List<String> _sliderLabels = [
    'Great',
    'Good',
    'OK',
    'Poor',
    'Bad',
  ];

  /// Maps a display value (1-5) to Hooper scale (1-7).
  /// 1->1, 2->2, 3->4, 4->5, 5->7
  static int _toHooper(double displayValue) {
    const mapping = <int, int>{1: 1, 2: 2, 3: 4, 4: 5, 5: 7};
    return mapping[displayValue.round()] ?? 4;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
      ),
      child: widget.hasCheckedIn
          ? _buildCompletedState(colors)
          : _buildFormState(colors),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Completed / summary state
  // ─────────────────────────────────────────────────────────────────

  Widget _buildCompletedState(ThemeColors colors) {
    final data = widget.completedData;

    return Row(
      children: [
        Icon(Icons.check_circle, color: colors.success, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Checked in \u2713',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              if (data != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Sleep ${data.sleepQuality}  '
                  'Energy ${data.energyLevel}  '
                  'Soreness ${data.muscleSoreness}  '
                  'Stress ${data.stressLevel}  '
                  '${_moodEmojis.isNotEmpty ? data.mood : ""}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Multi-step form state
  // ─────────────────────────────────────────────────────────────────

  Widget _buildFormState(ThemeColors colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row + step dots
        _buildHeader(colors),
        const SizedBox(height: 16),

        // Step content
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _buildCurrentStep(colors),
        ),

        const SizedBox(height: 16),

        // Navigation button
        _buildNavigationButton(colors),
      ],
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Row(
      children: [
        const Text(
          '\u{1F9D8}', // yoga emoji
          style: TextStyle(fontSize: 20),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Daily Wellness Check-in',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ),
        // Step dots
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_totalSteps, (i) {
            final isActive = i == _currentStep;
            return Container(
              width: isActive ? 10 : 6,
              height: 6,
              margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
              decoration: BoxDecoration(
                color: isActive
                    ? colors.accent
                    : colors.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCurrentStep(ThemeColors colors) {
    switch (_currentStep) {
      case 0:
        return _StepContent(
          key: const ValueKey(0),
          children: [
            _buildSliderRow(
              colors: colors,
              label: 'Sleep Quality',
              icon: Icons.bedtime_outlined,
              value: _sleepQuality,
              onChanged: (v) => setState(() => _sleepQuality = v),
            ),
            const SizedBox(height: 8),
            _buildSliderRow(
              colors: colors,
              label: 'Energy Level',
              icon: Icons.bolt_outlined,
              value: _energyLevel,
              onChanged: (v) => setState(() => _energyLevel = v),
            ),
          ],
        );
      case 1:
        return _StepContent(
          key: const ValueKey(1),
          children: [
            _buildSliderRow(
              colors: colors,
              label: 'Muscle Soreness',
              icon: Icons.fitness_center,
              value: _muscleSoreness,
              onChanged: (v) => setState(() => _muscleSoreness = v),
            ),
            const SizedBox(height: 8),
            _buildSliderRow(
              colors: colors,
              label: 'Stress Level',
              icon: Icons.psychology_outlined,
              value: _stressLevel,
              onChanged: (v) => setState(() => _stressLevel = v),
            ),
          ],
        );
      case 2:
        return _StepContent(
          key: const ValueKey(2),
          children: [
            // Mood emoji picker
            Text(
              'How\'s your mood?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_moodEmojis.length, (i) {
                final isSelected = i == _selectedMoodIndex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMoodIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.accent.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? colors.accent
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _moodEmojis[i],
                          style: TextStyle(
                            fontSize: isSelected ? 28 : 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _moodLabels[i],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? colors.accent
                                : colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            // Optional notes
            TextField(
              controller: _notesController,
              maxLines: 1,
              style: TextStyle(
                fontSize: 14,
                color: colors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Add a note (optional)',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: colors.textMuted,
                ),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.accent),
                ),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Slider row builder
  // ─────────────────────────────────────────────────────────────────

  Widget _buildSliderRow({
    required ThemeColors colors,
    required String label,
    required IconData icon,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    final labelText = _sliderLabels[value.round() - 1];

    // Color gradient from green (1=Great) to red (5=Bad)
    final sliderColor = Color.lerp(
      Colors.green,
      Colors.red,
      (value - 1) / 4,
    )!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: colors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: sliderColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                labelText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: sliderColor,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: sliderColor,
            thumbColor: sliderColor,
            overlayColor: sliderColor.withOpacity(0.15),
            inactiveTrackColor: colors.textMuted.withOpacity(0.15),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: value,
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Navigation button
  // ─────────────────────────────────────────────────────────────────

  Widget _buildNavigationButton(ThemeColors colors) {
    final isLastStep = _currentStep == _totalSteps - 1;
    final buttonLabel = isLastStep ? 'Submit' : 'Next';

    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          // Back button (hidden on first step)
          if (_currentStep > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: () => setState(() => _currentStep--),
                child: Text(
                  'Back',
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
            ),
          Expanded(
            child: FilledButton(
              onPressed: _onNextOrSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: colors.isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onNextOrSubmit() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      // Submit
      final data = WellnessCheckinData(
        sleepQuality: _toHooper(_sleepQuality),
        energyLevel: _toHooper(_energyLevel),
        muscleSoreness: _toHooper(_muscleSoreness),
        stressLevel: _toHooper(_stressLevel),
        mood: _moodEmojis[_selectedMoodIndex],
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      widget.onSubmit(data);
    }
  }
}

/// Simple wrapper that lays out children in a column with constrained height
/// so each step stays within ~220px.
class _StepContent extends StatelessWidget {
  final List<Widget> children;

  const _StepContent({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 220),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
