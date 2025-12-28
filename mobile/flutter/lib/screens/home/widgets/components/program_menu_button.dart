import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/workout_repository.dart';
import '../../../../data/services/haptic_service.dart';
import '../edit_program_sheet.dart';

/// Settings icon button for the home screen header
/// Navigates directly to settings screen
class SettingsButton extends StatelessWidget {
  /// Whether the current theme is dark
  final bool isDark;

  const SettingsButton({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return IconButton(
      onPressed: () {
        HapticService.light();
        context.push('/settings');
      },
      icon: Icon(
        Icons.settings_outlined,
        color: textMuted,
        size: 24,
      ),
      tooltip: 'Settings',
    );
  }
}

/// Customize Program button for the TODAY section
/// Opens the edit program sheet
class CustomizeProgramButton extends ConsumerWidget {
  /// Whether the current theme is dark
  final bool isDark;

  const CustomizeProgramButton({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Material(
      color: elevatedColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          HapticService.light();
          _showEditProgramSheet(context, ref);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.cyan.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune,
                size: 14,
                color: AppColors.cyan,
              ),
              const SizedBox(width: 6),
              Text(
                'Customize',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cyan,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditProgramSheet(BuildContext context, WidgetRef ref) async {
    final result = await showEditProgramSheet(context, ref);

    if (result == true && context.mounted) {
      // Small delay to ensure database transaction completes
      await Future.delayed(const Duration(milliseconds: 500));

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

/// @deprecated Use [SettingsButton] and [CustomizeProgramButton] instead
/// Kept for backwards compatibility
typedef ProgramMenuButton = SettingsButton;
