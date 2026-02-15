/// Pre-workout check-in widget
///
/// Quick mood/energy check-in before starting a workout.
/// Designed to be fast (< 5 seconds) and skippable.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/subjective_feedback.dart';
import '../../../data/providers/subjective_feedback_provider.dart';
import '../../../widgets/glass_sheet.dart';

/// Pre-workout check-in widget displayed before the workout begins.
/// Quick, skippable - designed to take less than 5 seconds.
class PreWorkoutCheckin extends ConsumerStatefulWidget {
  /// Optional workout ID to associate with the check-in
  final String? workoutId;

  /// Callback when check-in is completed or skipped
  final VoidCallback onComplete;

  /// Callback when skip is pressed
  final VoidCallback? onSkip;

  /// Whether to show the extended fields (energy, sleep)
  final bool showExtendedFields;

  const PreWorkoutCheckin({
    super.key,
    this.workoutId,
    required this.onComplete,
    this.onSkip,
    this.showExtendedFields = false,
  });

  @override
  ConsumerState<PreWorkoutCheckin> createState() => _PreWorkoutCheckinState();
}

class _PreWorkoutCheckinState extends ConsumerState<PreWorkoutCheckin> {
  int? _selectedMood;
  int? _selectedEnergy;
  int? _selectedSleep;
  bool _isSubmitting = false;
  bool _showExtended = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header
              Text(
                'How are you feeling?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2),

              const SizedBox(height: 8),

              Text(
                'Quick check before your workout',
                style: TextStyle(
                  fontSize: 16,
                  color: textSecondary,
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 40),

              // Mood selection - emoji buttons
              _buildMoodSelector(textPrimary, elevated),

              // Extended fields (optional)
              if (widget.showExtendedFields || _showExtended) ...[
                const SizedBox(height: 32),
                _buildEnergySelector(textPrimary, textSecondary, elevated),
                const SizedBox(height: 24),
                _buildSleepSelector(textPrimary, textSecondary, elevated),
              ],

              const SizedBox(height: 40),

              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedMood != null && !_isSubmitting
                      ? _submitCheckin
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.cyan,
                    disabledBackgroundColor: isDark
                        ? Colors.grey[800]
                        : Colors.grey[300],
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Start Workout',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

              const SizedBox(height: 16),

              // Skip button
              TextButton(
                onPressed: _isSubmitting ? null : _handleSkip,
                child: Text(
                  'Skip check-in',
                  style: TextStyle(
                    fontSize: 16,
                    color: textSecondary,
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms),

              // Toggle extended fields
              if (!widget.showExtendedFields && !_showExtended) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showExtended = true;
                    });
                  },
                  icon: Icon(
                    Icons.add_circle_outline,
                    size: 18,
                    color: textSecondary,
                  ),
                  label: Text(
                    'Add more details',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodSelector(Color textPrimary, Color elevated) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMoodButton(1, elevated),
            _buildMoodButton(2, elevated),
            _buildMoodButton(3, elevated),
            _buildMoodButton(4, elevated),
            _buildMoodButton(5, elevated),
          ],
        ).animate().fadeIn(delay: 200.ms).scale(
          begin: const Offset(0.8, 0.8),
          duration: 300.ms,
          curve: Curves.easeOut,
        ),
        const SizedBox(height: 16),
        if (_selectedMood != null)
          Text(
            _selectedMood!.moodLabel,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _selectedMood!.moodColor,
            ),
          ).animate().fadeIn().scale(),
      ],
    );
  }

  Widget _buildMoodButton(int level, Color elevated) {
    final isSelected = _selectedMood == level;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedMood = level;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? level.moodColor.withValues(alpha: 0.2) : elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? level.moodColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: level.moodColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: AnimatedScale(
            scale: isSelected ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Text(
              level.moodEmoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnergySelector(Color textPrimary, Color textSecondary, Color elevated) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Energy level',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const Spacer(),
            if (_selectedEnergy != null)
              Text(
                _selectedEnergy!.energyLabel,
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            final level = index + 1;
            final isSelected = _selectedEnergy == level;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedEnergy = level;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.orange.withValues(alpha: 0.2)
                      : elevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.orange : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    level.energyEmoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildSleepSelector(Color textPrimary, Color textSecondary, Color elevated) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'How was your sleep?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const Spacer(),
            if (_selectedSleep != null)
              Text(
                _selectedSleep!.sleepLabel,
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            final level = index + 1;
            final isSelected = _selectedSleep == level;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedSleep = level;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.purple.withValues(alpha: 0.2)
                      : elevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.purple : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    level.sleepEmoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Future<void> _submitCheckin() async {
    if (_selectedMood == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final notifier = ref.read(subjectiveFeedbackProvider.notifier);
      await notifier.createPreCheckin(
        moodBefore: _selectedMood!,
        energyBefore: _selectedEnergy,
        sleepQuality: _selectedSleep,
        workoutId: widget.workoutId,
      );

      if (mounted) {
        widget.onComplete();
      }
    } catch (e) {
      debugPrint('Error submitting pre-checkin: $e');
      // Still proceed even if the API call fails
      if (mounted) {
        widget.onComplete();
      }
    }
  }

  void _handleSkip() {
    if (widget.onSkip != null) {
      widget.onSkip!();
    } else {
      widget.onComplete();
    }
  }
}

/// Compact pre-workout check-in as a bottom sheet
class PreWorkoutCheckinSheet extends ConsumerStatefulWidget {
  final String? workoutId;

  const PreWorkoutCheckinSheet({
    super.key,
    this.workoutId,
  });

  @override
  ConsumerState<PreWorkoutCheckinSheet> createState() => _PreWorkoutCheckinSheetState();
}

class _PreWorkoutCheckinSheetState extends ConsumerState<PreWorkoutCheckinSheet> {
  int? _selectedMood;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Text(
                'How are you feeling?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),

              const SizedBox(height: 24),

              // Mood buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  final level = index + 1;
                  final isSelected = _selectedMood == level;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _selectedMood = level;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? level.moodColor.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? level.moodColor : textSecondary.withValues(alpha: 0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: AnimatedScale(
                          scale: isSelected ? 1.1 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            level.moodEmoji,
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),

              // Selected mood label
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _selectedMood != null
                    ? Text(
                        _selectedMood!.moodLabel,
                        key: ValueKey(_selectedMood),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _selectedMood!.moodColor,
                        ),
                      )
                    : const SizedBox(height: 24),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: textSecondary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'Skip',
                        style: TextStyle(color: textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _selectedMood != null && !_isSubmitting
                          ? _submitAndClose
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppColors.cyan,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Start Workout',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
    );
  }

  Future<void> _submitAndClose() async {
    if (_selectedMood == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final notifier = ref.read(subjectiveFeedbackProvider.notifier);
      await notifier.createPreCheckin(
        moodBefore: _selectedMood!,
        workoutId: widget.workoutId,
      );
    } catch (e) {
      debugPrint('Error submitting pre-checkin: $e');
    }

    if (mounted) {
      Navigator.pop(context, true); // Return true to indicate submission
    }
  }
}

/// Helper function to show pre-workout check-in sheet
Future<bool> showPreWorkoutCheckin(BuildContext context, {String? workoutId}) async {
  final result = await showGlassSheet<bool>(
    context: context,
    builder: (context) => GlassSheet(
      child: PreWorkoutCheckinSheet(workoutId: workoutId),
    ),
  );

  return result ?? false;
}
