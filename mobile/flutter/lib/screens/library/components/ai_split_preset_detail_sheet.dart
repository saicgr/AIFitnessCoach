import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/training_preferences_provider.dart';
import '../../../data/models/ai_split_preset.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/schedule_mismatch_dialog.dart';

/// Bottom sheet showing AI Split Preset details
class AISplitPresetDetailSheet extends ConsumerStatefulWidget {
  final AISplitPreset preset;

  const AISplitPresetDetailSheet({
    super.key,
    required this.preset,
  });

  @override
  ConsumerState<AISplitPresetDetailSheet> createState() => _AISplitPresetDetailSheetState();
}

class _AISplitPresetDetailSheetState extends ConsumerState<AISplitPresetDetailSheet> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;
    final green = isDark ? AppColors.green : AppColorsLight.green;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with name and badge
                  Row(
                    children: [
                      if (widget.preset.isAIPowered) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [orange, orange.withValues(alpha: 0.7)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 12,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'AI',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          widget.preset.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Stats row
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.calendar_today,
                        label: widget.preset.daysPerWeek == 0
                            ? 'Flexible'
                            : '${widget.preset.daysPerWeek} days/week',
                        color: orange,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Icons.timer_outlined,
                        label: widget.preset.duration,
                        color: purple,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Icons.trending_up,
                        label: '${widget.preset.hypertrophyScore}/10',
                        color: green,
                        isDark: isDark,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Difficulty badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.preset.difficulty.map((diff) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: elevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: textMuted.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          diff,
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Description
                  Text(
                    widget.preset.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: textSecondary,
                      height: 1.5,
                    ),
                  ),

                  // Warning if present
                  if (widget.preset.warning != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.coral.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.coral.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 18,
                            color: AppColors.coral,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.preset.warning!,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.coral,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Schedule section
                  _SectionHeader(title: 'Schedule', isDark: isDark),
                  const SizedBox(height: 12),
                  ...widget.preset.schedule.map((day) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: green,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                day,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),

                  const SizedBox(height: 24),

                  // Benefits section
                  _SectionHeader(title: 'Benefits', isDark: isDark),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.preset.benefits.map((benefit) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: green.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          benefit,
                          style: TextStyle(
                            fontSize: 13,
                            color: green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),

                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _handleStartSplit(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  widget.preset.isAIPowered
                                      ? Icons.auto_awesome
                                      : Icons.play_arrow_rounded,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.preset.isAIPowered
                                      ? 'Generate AI Program'
                                      : 'Start This Split',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle the "Start This Split" button press
  void _handleStartSplit(BuildContext context) {
    HapticService.medium();

    // Get current workout days from auth state
    final authState = ref.read(authStateProvider);
    final currentWorkoutDays = authState.user?.workoutDays ?? [];

    // Close the bottom sheet first
    Navigator.of(context).pop();

    // Check for mismatch (flexible splits like AI modes with 0 days skip check)
    if (widget.preset.daysPerWeek > 0 && currentWorkoutDays.length != widget.preset.daysPerWeek) {
      // Show mismatch dialog
      _showScheduleMismatchDialog(context, currentWorkoutDays);
    } else {
      // No mismatch - save directly
      _savePresetAsActiveSplit(context);
    }
  }

  /// Show the schedule mismatch dialog
  void _showScheduleMismatchDialog(
    BuildContext context,
    List<int> currentWorkoutDays,
  ) {
    final currentDayNames = ScheduleMismatchHelper.formatDayNames(currentWorkoutDays);
    final newDays = ScheduleMismatchHelper.getDefaultDaysForCount(widget.preset.daysPerWeek);
    final newDayNames = ScheduleMismatchHelper.formatDayNames(newDays);
    final compatibleSplit = ScheduleMismatchHelper.getCompatibleSplitForDays(currentWorkoutDays.length);
    final compatibleSplitName = ScheduleMismatchHelper.getSplitDisplayName(compatibleSplit);

    showDialog(
      context: context,
      builder: (dialogContext) => ScheduleMismatchDialog(
        splitName: widget.preset.name,
        requiredDays: widget.preset.daysPerWeek,
        currentDayCount: currentWorkoutDays.length,
        currentDayNames: currentDayNames,
        newDays: newDays,
        newDayNames: newDayNames,
        compatibleSplitName: compatibleSplitName,
        onKeepDays: () {
          Navigator.pop(dialogContext);
          // Save compatible split for current days
          _saveCompatibleSplit(context, compatibleSplit, compatibleSplitName);
        },
        onUpdateDays: () async {
          Navigator.pop(dialogContext);
          // Save the preset and update workout days
          await _savePresetAndUpdateDays(context, newDays);
        },
      ),
    );
  }

  /// Save the preset as the active training split
  void _savePresetAsActiveSplit(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    // Update training split via provider
    ref.read(trainingPreferencesProvider.notifier)
       .setTrainingSplit(widget.preset.trainingSplitValue);

    // Show success snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Switched to ${widget.preset.name}. Regenerate workouts to apply.',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: cyan,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Save a compatible split when user keeps their current days
  void _saveCompatibleSplit(
    BuildContext context,
    String compatibleSplit,
    String compatibleSplitName,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    // Update training split via provider
    ref.read(trainingPreferencesProvider.notifier)
       .setTrainingSplit(compatibleSplit);

    // Show success snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Switched to $compatibleSplitName to match your schedule. Regenerate workouts to apply.',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: cyan,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Save the preset and update workout days
  Future<void> _savePresetAndUpdateDays(
    BuildContext context,
    List<int> newDays,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    setState(() => _isLoading = true);

    try {
      // Update training split via provider
      ref.read(trainingPreferencesProvider.notifier)
         .setTrainingSplit(widget.preset.trainingSplitValue);

      // Update workout days via API
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;
      if (userId != null) {
        final repo = ref.read(workoutRepositoryProvider);
        final dayNamesList = newDays.map((idx) {
          const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          return days[idx];
        }).toList();

        await repo.quickDayChange(userId, dayNamesList);
        await ref.read(authStateProvider.notifier).refreshUser();
      }

      // Show success snackbar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Switched to ${widget.preset.name} with ${newDays.length}-day schedule. Regenerate workouts to apply.',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: cyan,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
