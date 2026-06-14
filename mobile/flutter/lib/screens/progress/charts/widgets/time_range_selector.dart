import 'package:flutter/material.dart';
import '../../../../data/models/progress_charts.dart';
import '../../../../widgets/design_system/zealova.dart';

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
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ProgressTimeRange.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final range = ProgressTimeRange.values[index];
          final isSelected = range == selectedRange;

          return Center(
            child: ZealovaChip(
              label: range.displayName,
              selected: isSelected,
              onTap: () => onRangeSelected(range),
            ),
          );
        },
      ),
    );
  }
}
