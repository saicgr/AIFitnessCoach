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

  const ZealovaStatTile({
    super.key,
    required this.value,
    required this.label,
    this.unit,
    this.valueSize = 20,
    this.accentValue = false,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
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
        Text(label.toUpperCase(),
            style: ZType.lbl(9, color: tc.textMuted, letterSpacing: 1.3)),
      ],
    );
  }
}
