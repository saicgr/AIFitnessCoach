import 'package:flutter/material.dart';
import '../../../../data/models/progress_charts.dart';

/// Horizontal selector for choosing time range
class TimeRangeSelector extends StatelessWidget {
  final ProgressTimeRange selectedRange;
  final ValueChanged<ProgressTimeRange> onRangeSelected;

  const TimeRangeSelector({
    super.key,
    required this.selectedRange,
    required this.onRangeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ProgressTimeRange.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final range = ProgressTimeRange.values[index];
          final isSelected = range == selectedRange;

          return ChoiceChip(
            label: Text(range.displayName),
            selected: isSelected,
            onSelected: (_) => onRangeSelected(range),
            selectedColor: colorScheme.primary,
            labelStyle: TextStyle(
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            backgroundColor: colorScheme.surfaceContainerHighest,
            side: BorderSide(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withOpacity(0.3),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          );
        },
      ),
    );
  }
}
