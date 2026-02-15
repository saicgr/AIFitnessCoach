import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/scheduling_provider.dart';
import '../../../data/repositories/scheduling_repository.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';

/// Shows the reschedule sheet for a missed workout
///
/// Returns true if successfully rescheduled, false/null otherwise
Future<bool?> showRescheduleSheet(
  BuildContext context,
  WidgetRef ref, {
  required MissedWorkout workout,
}) async {
  return await showGlassSheet<bool>(
    context: context,
    builder: (context) => GlassSheet(
      showHandle: false,
      child: _RescheduleSheet(workout: workout),
    ),
  );
}

class _RescheduleSheet extends ConsumerStatefulWidget {
  final MissedWorkout workout;

  const _RescheduleSheet({required this.workout});

  @override
  ConsumerState<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends ConsumerState<_RescheduleSheet> {
  bool _isLoading = false;
  String? _selectedOption;
  DateTime? _selectedDate;
  String? _swapWorkoutId;
  String? _swapWorkoutName;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.nearBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final suggestionsAsync = ref.watch(schedulingSuggestionsProvider(widget.workout.id));

    return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.calendar_today_rounded,
                        color: AppColors.cyan,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reschedule Workout',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.workout.name,
                            style: TextStyle(
                              fontSize: 14,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(
            color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
            height: 1,
          ),

          // Suggestions list
          Flexible(
            child: suggestionsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Failed to load suggestions',
                    style: TextStyle(color: textSecondary),
                  ),
                ),
              ),
              data: (suggestions) {
                // Filter out skip suggestion for this sheet
                final rescheduleOptions = suggestions
                    .where((s) => s.suggestionType != 'skip')
                    .toList();

                return ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Suggested options
                    ...rescheduleOptions.map((suggestion) => _buildSuggestionCard(
                      context,
                      suggestion,
                      cardBg,
                      textPrimary,
                      textSecondary,
                      isDark,
                    )),

                    const SizedBox(height: 16),

                    // Custom date picker option
                    _buildCustomDateOption(
                      context,
                      cardBg,
                      textPrimary,
                      textSecondary,
                      isDark,
                    ),

                    const SizedBox(height: 24),

                    // Confirm button
                    if (_selectedOption != null)
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cyan,
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
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _getConfirmButtonText(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                  ],
                );
              },
            ),
          ),

          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
    );
  }

  Widget _buildSuggestionCard(
    BuildContext context,
    SchedulingSuggestion suggestion,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    final isSelected = _selectedOption == suggestion.suggestionType;
    final borderColor = isSelected ? AppColors.cyan : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder);

    IconData icon;
    Color iconColor;

    switch (suggestion.suggestionType) {
      case 'reschedule_today':
        icon = Icons.today_rounded;
        iconColor = AppColors.success;
        break;
      case 'reschedule_tomorrow':
        icon = Icons.event_rounded;
        iconColor = AppColors.purple;
        break;
      case 'swap':
        icon = Icons.swap_horiz_rounded;
        iconColor = AppColors.orange;
        break;
      default:
        icon = Icons.calendar_today_rounded;
        iconColor = AppColors.cyan;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            HapticService.light();
            setState(() {
              _selectedOption = suggestion.suggestionType;
              _selectedDate = suggestion.recommendedDate != null
                  ? DateTime.parse(suggestion.recommendedDate!)
                  : DateTime.now();
              _swapWorkoutId = suggestion.swapWorkoutId;
              _swapWorkoutName = suggestion.swapWorkoutName;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        suggestion.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                      if (suggestion.isSwap && suggestion.swapWorkoutName != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Swaps with: ${suggestion.swapWorkoutName}',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Selection indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.cyan : textSecondary.withOpacity(0.3),
                      width: 2,
                    ),
                    color: isSelected ? AppColors.cyan : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDateOption(
    BuildContext context,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    final isSelected = _selectedOption == 'custom';
    final borderColor = isSelected ? AppColors.cyan : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder);

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () async {
          HapticService.light();

          final pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now().add(const Duration(days: 1)),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 14)),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: AppColors.cyan,
                    onPrimary: Colors.white,
                  ),
                ),
                child: child!,
              );
            },
          );

          if (pickedDate != null) {
            setState(() {
              _selectedOption = 'custom';
              _selectedDate = pickedDate;
              _swapWorkoutId = null;
              _swapWorkoutName = null;
            });
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.date_range_rounded,
                  color: AppColors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pick a different day',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isSelected && _selectedDate != null
                          ? DateFormat('EEEE, MMM d').format(_selectedDate!)
                          : 'Choose from calendar',
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected ? AppColors.cyan : textSecondary,
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getConfirmButtonText() {
    if (_selectedDate == null) return 'Confirm';

    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());
    if (isToday) {
      return 'Do It Today';
    }

    final formattedDate = DateFormat('EEEE, MMM d').format(_selectedDate!);

    if (_swapWorkoutName != null) {
      return 'Swap to $formattedDate';
    }

    return 'Reschedule to $formattedDate';
  }

  Future<void> _handleConfirm() async {
    if (_selectedDate == null) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(schedulingActionProvider.notifier);
      final success = await notifier.rescheduleToDate(
        widget.workout.id,
        _selectedDate!,
        swapWithWorkoutId: _swapWorkoutId,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          // Also refresh workouts
          ref.invalidate(workoutsProvider);

          Navigator.pop(context, true);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_swapWorkoutName != null
                  ? 'Workout swapped successfully'
                  : 'Workout rescheduled'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to reschedule workout'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
