import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../data/models/progress_charts.dart';

/// Range chips for the chart archetype (v2 MEASUREMENT DETAIL `.pg-rng`):
/// slim hairline-outlined pills (7D / 1M / 3M / 1Y / All), the active one
/// accent-tinted. Restyled from the old ZealovaChip selector — wiring
/// (selectedRange / onRangeSelected) is unchanged.
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
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ProgressTimeRange.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final range = ProgressTimeRange.values[index];
          final isSelected = range == selectedRange;
          return Center(
            child: _RangePill(
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

/// Slim hairline pill — matches v2 `.pg-rng .c` (26px tall, hairline border,
/// active = accent text + tinted fill).
class _RangePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RangePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final fg = selected ? tc.accent : tc.textMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? tc.accent.withValues(alpha: 0.08)
              : Colors.transparent,
          border: Border.all(
            color: selected
                ? tc.accent.withValues(alpha: 0.5)
                : AppColors.hairlineStrong,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label.toUpperCase(),
          style: ZType.lbl(10.5, color: fg, letterSpacing: 1.0),
        ),
      ),
    );
  }
}
