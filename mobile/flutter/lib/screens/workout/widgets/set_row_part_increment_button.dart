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
          color: AppColors.glassSurface,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onPressed != null ? AppColors.textSecondary : AppColors.textMuted,
        ),
      ),
    );
  }
}

