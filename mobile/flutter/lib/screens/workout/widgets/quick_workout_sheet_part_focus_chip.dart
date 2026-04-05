part of 'quick_workout_sheet.dart';


class _FocusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final Color chipBorder;
  final VoidCallback onTap;
  final Color cardBackground;
  final Color textPrimary;
  final Color textMuted;

  const _FocusChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.chipBorder,
    required this.onTap,
    required this.cardBackground,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : chipBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? color : textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _ToggleChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final Color chipBorder;
  final VoidCallback onTap;
  final Color cardBackground;
  final Color textPrimary;
  final Color textMuted;

  const _ToggleChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.chipBorder,
    required this.onTap,
    required this.cardBackground,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : chipBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? color : textMuted,
          ),
        ),
      ),
    );
  }
}


/// Equipment chip with optional "tune" icon for weight detail.
class _EquipmentChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool hasDetails;
  final bool showTuneIcon;
  final Color color;
  final Color chipBorder;
  final VoidCallback onTap;
  final VoidCallback? onTuneTap;
  final Color cardBackground;
  final Color textPrimary;
  final Color textMuted;

  const _EquipmentChip({
    required this.label,
    required this.isSelected,
    required this.hasDetails,
    required this.showTuneIcon,
    required this.color,
    required this.chipBorder,
    required this.onTap,
    this.onTuneTap,
    required this.cardBackground,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : chipBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? color : textMuted,
              ),
            ),
            if (hasDetails) ...[
              const SizedBox(width: 4),
              Icon(Icons.check_circle, size: 12, color: color),
            ],
            if (showTuneIcon) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onTuneTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Icon(
                    Icons.tune,
                    size: 14,
                    color: isSelected ? color : textMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

