import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

/// Bottom sheet for selecting workout days.
///
/// Allows users to select which days of the week they want to work out.
/// All 7 days are shown as toggleable buttons (Mon-Sun).
/// At least 1 day must be selected.
class WorkoutDaysSheet extends StatefulWidget {
  /// The currently selected days (0=Monday, 6=Sunday).
  final Set<int> initialSelectedDays;

  /// Callback when the save button is pressed.
  final Future<void> Function(List<int> selectedDays) onSave;

  const WorkoutDaysSheet({
    super.key,
    required this.initialSelectedDays,
    required this.onSave,
  });

  @override
  State<WorkoutDaysSheet> createState() => _WorkoutDaysSheetState();
}

class _WorkoutDaysSheetState extends State<WorkoutDaysSheet> {
  late Set<int> _selectedDays;
  bool _isSaving = false;

  static const List<String> _dayNames = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _fullDayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDays = Set<int>.from(widget.initialSelectedDays);
  }

  void _toggleDay(int dayIndex) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedDays.contains(dayIndex)) {
        // Only allow removing if more than 1 day is selected
        if (_selectedDays.length > 1) {
          _selectedDays.remove(dayIndex);
        }
      } else {
        _selectedDays.add(dayIndex);
      }
    });
  }

  Future<void> _handleSave() async {
    if (_selectedDays.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      await widget.onSave(_selectedDays.toList()..sort());
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update workout days: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _getSelectedDaysSummary() {
    if (_selectedDays.isEmpty) return 'None selected';
    final sorted = _selectedDays.toList()..sort();
    if (sorted.length == 7) return 'Every day';
    if (sorted.length == 5 &&
        sorted.contains(0) &&
        sorted.contains(1) &&
        sorted.contains(2) &&
        sorted.contains(3) &&
        sorted.contains(4)) {
      return 'Weekdays';
    }
    if (sorted.length == 2 && sorted.contains(5) && sorted.contains(6)) {
      return 'Weekends';
    }
    return sorted.map((i) => _fullDayNames[i]).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Workout Days',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              'Select which days you want to work out',
              style: TextStyle(
                fontSize: 14,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 24),

            // Day selection row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                final isSelected = _selectedDays.contains(index);
                return GestureDetector(
                  onTap: () => _toggleDay(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.cyanGradient : null,
                      color: isSelected
                          ? null
                          : (isDark
                              ? AppColors.glassSurface
                              : AppColorsLight.glassSurface),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.cyan : cardBorder,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.cyan.withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _dayNames[index],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : textPrimary,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            // Selection counter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.cyan.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.cyan,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedDays.length} day${_selectedDays.length == 1 ? '' : 's'} / week',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Summary text
            Text(
              _getSelectedDaysSummary(),
              style: TextStyle(
                fontSize: 13,
                color: textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Info banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.cyan.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.cyan,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Changing workout days will update your schedule. Future workouts will be regenerated.',
                      style: TextStyle(
                        fontSize: 12,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor:
                      AppColors.cyan.withValues(alpha: 0.5),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
