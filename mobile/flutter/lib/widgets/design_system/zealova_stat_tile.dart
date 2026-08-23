import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';

/// Big-numeral + label tile used across the redesign (strip metrics, stat
/// grids, workout-complete ledger). Anton numeral carries the hierarchy.
class ZealovaStatTile extends StatelessWidget {
  final String value;
  final String label;
  final String? unit;
  final double valueSize;
  final bool accentValue;
  final CrossAxisAlignment align;
  /// Optional long-press/hover explanation shown next to the label. Use this
  /// when two similarly-named tiles on the same screen measure different
  /// things (e.g. a strict day-by-day streak next to a schedule-aware one —
  /// finding #453) so the difference is discoverable instead of looking like
  /// a data-integrity bug.
  final String? tooltip;

  const ZealovaStatTile({
    super.key,
    required this.value,
    required this.label,
    this.unit,
    this.valueSize = 20,
    this.accentValue = false,
    this.align = CrossAxisAlignment.start,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final labelRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(),
            style: ZType.lbl(9, color: tc.textMuted, letterSpacing: 1.3)),
        if (tooltip != null) ...[
          const SizedBox(width: 3),
          Icon(Icons.info_outline, size: 10, color: tc.textMuted),
        ],
      ],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: align,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value,
                style: ZType.disp(valueSize,
                    color: accentValue ? tc.accent : tc.textPrimary)),
            if (unit != null) ...[
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(unit!.toUpperCase(),
                    style: ZType.lbl(9, color: tc.textMuted, letterSpacing: 1)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 3),
        if (tooltip != null)
          Tooltip(message: tooltip, triggerMode: TooltipTriggerMode.tap, child: labelRow)
        else
          labelRow,
      ],
    );
  }
}
