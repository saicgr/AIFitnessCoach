part of 'set_row.dart';


class _IncrementButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _IncrementButton({
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onPressed?.call();
        HapticFeedback.selectionClick();
      },
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: ThemeColors.of(context).glassSurface,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onPressed != null ? ThemeColors.of(context).textSecondary : ThemeColors.of(context).textMuted,
        ),
      ),
    );
  }
}

