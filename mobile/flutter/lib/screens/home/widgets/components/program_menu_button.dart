import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/workout_repository.dart';
import '../edit_program_sheet.dart';

/// Three-dot menu button for program options
/// Used in the home screen header
class ProgramMenuButton extends ConsumerWidget {
  /// Whether the current theme is dark
  final bool isDark;

  const ProgramMenuButton({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: textMuted,
        size: 24,
      ),
      color: elevatedColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      offset: const Offset(0, 40),
      onSelected: (value) {
        if (value == 'edit_program') {
          _showEditProgramSheet(context, ref);
        } else if (value == 'settings') {
          context.push('/settings');
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'edit_program',
          child: Row(
            children: [
              Icon(
                Icons.tune,
                size: 20,
                color: AppColors.cyan,
              ),
              const SizedBox(width: 12),
              Text(
                'Customize Program',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColorsLight.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(
                Icons.settings_outlined,
                size: 20,
                color: textMuted,
              ),
              const SizedBox(width: 12),
              Text(
                'Settings',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColorsLight.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showEditProgramSheet(BuildContext context, WidgetRef ref) async {
    final result = await showEditProgramSheet(context, ref);

    if (result == true && context.mounted) {
      // Refresh workouts after program update - new workouts should be ready
      await ref.read(workoutsProvider.notifier).refresh();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Program updated! Your new workouts are ready.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }
}
