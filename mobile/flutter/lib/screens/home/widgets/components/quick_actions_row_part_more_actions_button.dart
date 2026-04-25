part of 'quick_actions_row.dart';


/// "+" button that opens a bottom sheet with all quick actions.
/// Uses the same `_GridActionTile` chrome as every other slot, with a
/// muted chip so it reads as "system" rather than competing with the
/// colored shortcuts.
class _MoreActionsButton extends ConsumerWidget {
  final bool isDark;

  const _MoreActionsButton({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _GridActionTile(
      isDark: isDark,
      onTap: () {
        HapticService.light();
        showQuickActionsSheet(context, ref);
      },
      onLongPress: () {
        HapticService.medium();
        showQuickActionsSheet(context, ref, editMode: true);
      },
      label: 'More',
      icon: Icons.more_horiz,
      iconColor: isDark
          ? AppColors.textPrimary
          : AppColorsLight.textPrimary,
      muteChip: true,
    );
  }
}

