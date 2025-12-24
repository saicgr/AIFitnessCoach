import 'package:flutter/material.dart';
import 'sheet_theme_colors.dart';
import 'section_title.dart';

/// Default list of day names
const List<String> defaultDayNames = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun'
];

/// A widget for selecting workout days of the week
class WorkoutDaysSelector extends StatelessWidget {
  /// Set of selected day indices (0 = Monday, 6 = Sunday)
  final Set<int> selectedDays;

  /// Callback when selection changes
  final ValueChanged<Set<int>> onSelectionChanged;

  /// Whether the selector is disabled
  final bool disabled;

  /// List of day names (defaults to Mon-Sun abbreviations)
  final List<String> dayNames;

  const WorkoutDaysSelector({
    super.key,
    required this.selectedDays,
    required this.onSelectionChanged,
    this.disabled = false,
    this.dayNames = defaultDayNames,
  });

  void _handleDayTap(int index) {
    if (disabled) return;

    final newSelection = Set<int>.from(selectedDays);
    if (newSelection.contains(index)) {
      newSelection.remove(index);
    } else {
      newSelection.add(index);
    }
    onSelectionChanged(newSelection);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sheetColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SectionTitle(
              icon: Icons.calendar_month,
              title: 'Workout Days',
              iconColor: colors.cyan,
              badge: '${selectedDays.length} days/week',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Select which days you want to work out',
          style: TextStyle(fontSize: 13, color: colors.textMuted),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) {
            final isSelected = selectedDays.contains(index);
            return GestureDetector(
              onTap: () => _handleDayTap(index),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.cyan.withOpacity(0.2)
                      : colors.glassSurface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? colors.cyan : colors.cardBorder,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    dayNames[index],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? colors.cyan : colors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
