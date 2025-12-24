import 'package:flutter/material.dart';
import 'sheet_theme_colors.dart';
import 'section_title.dart';

/// A widget for selecting program duration in weeks
class ProgramDurationSelector extends StatelessWidget {
  /// Selected number of weeks
  final int selectedWeeks;

  /// Callback when selection changes
  final ValueChanged<int> onSelectionChanged;

  /// Whether the selector is disabled
  final bool disabled;

  const ProgramDurationSelector({
    super.key,
    required this.selectedWeeks,
    required this.onSelectionChanged,
    this.disabled = false,
  });

  String _getProgramDurationLabel() {
    if (selectedWeeks <= 1) return '1 week';
    if (selectedWeeks <= 4) return '$selectedWeeks weeks';
    return '${(selectedWeeks / 4).round()} months';
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
              icon: Icons.date_range,
              title: 'Program Duration',
              iconColor: colors.purple,
              badge: _getProgramDurationLabel(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'How far ahead to schedule workouts',
          style: TextStyle(fontSize: 13, color: colors.textMuted),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildDurationOption(colors, 1, '1 Week'),
            _buildDurationOption(colors, 2, '2 Weeks'),
            _buildDurationOption(colors, 4, '1 Month'),
            _buildDurationOption(colors, 8, '2 Months'),
            _buildDurationOption(colors, 12, '3 Months'),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationOption(SheetColors colors, int weeks, String label) {
    final isSelected = selectedWeeks == weeks;
    return GestureDetector(
      onTap: disabled ? null : () => onSelectionChanged(weeks),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.purple.withOpacity(0.2)
              : colors.glassSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colors.purple
                : colors.cardBorder.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? colors.purple : colors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
