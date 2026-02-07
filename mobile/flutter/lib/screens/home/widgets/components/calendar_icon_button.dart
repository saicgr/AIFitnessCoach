import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/services/haptic_service.dart';

/// Calendar icon button for navigating to the schedule screen
/// Used in the home screen header
class CalendarIconButton extends ConsumerWidget {
  /// Whether the current theme is dark
  final bool isDark;

  const CalendarIconButton({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return IconButton(
      icon: Icon(
        Icons.calendar_month_outlined,
        color: textMuted,
        size: 24,
      ),
      tooltip: 'Schedule',
      onPressed: () {
        HapticService.light();
        context.push('/schedule');
      },
    );
  }
}
