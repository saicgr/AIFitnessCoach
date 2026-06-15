part of 'measurement_detail_screen.dart';


class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Signature v2 stat cell: Anton numeral (color-tinted for min/avg/max),
    // Barlow uppercase kicker beneath. Split value + unit so the unit reads as
    // a small Barlow tail.
    final parts = value.split(' ');
    final numeral = parts.first;
    final unit = parts.length > 1 ? parts.sublist(1).join(' ') : null;
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(numeral, style: ZType.disp(22, color: color)),
            if (unit != null) ...[
              const SizedBox(width: 3),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit.toUpperCase(),
                  style: ZType.lbl(9,
                      color: color.withValues(alpha: 0.7), letterSpacing: 1),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label.toUpperCase(),
          style: ZType.lbl(10, color: AppColors.textMuted, letterSpacing: 1.5),
        ),
      ],
    );
  }
}

