part of 'nutrient_explorer.dart';


class _TierLabel extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isCenter;

  const _TierLabel({
    required this.label,
    required this.value,
    required this.color,
    this.isCenter = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: ZType.lbl(9, color: color, letterSpacing: 1),
        ),
        Text(
          value,
          style: ZType.data(11, color: color),
        ),
      ],
    );
  }
}

