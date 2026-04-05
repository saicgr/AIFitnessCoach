part of 'food_browser_panel.dart';


// ─── Display Mode Toggle ──────────────────────────────────────────

class _DisplayModeToggle extends StatelessWidget {
  final _SearchDisplayMode mode;
  final ValueChanged<_SearchDisplayMode> onChanged;
  final bool isDark;

  const _DisplayModeToggle({
    required this.mode,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    Widget modeButton(_SearchDisplayMode m, IconData icon, String label) {
      final isActive = mode == m;
      return GestureDetector(
        onTap: () => onChanged(m),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isActive ? teal : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: isActive ? Colors.white : textMuted),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? Colors.white : textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          modeButton(_SearchDisplayMode.pages, Icons.view_carousel_outlined, 'Pages'),
          modeButton(_SearchDisplayMode.list, Icons.view_list_outlined, 'List'),
          modeButton(_SearchDisplayMode.carousel, Icons.view_column_outlined, 'Carousel'),
        ],
      ),
    );
  }
}

