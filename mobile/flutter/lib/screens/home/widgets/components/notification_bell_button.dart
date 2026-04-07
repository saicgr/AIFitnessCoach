import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/providers/unified_notifications_provider.dart';
import '../../../../data/services/haptic_service.dart';

/// Notification bell button with unread count badge
/// Used in the home screen header
class NotificationBellButton extends ConsumerWidget {
  /// Whether the current theme is dark
  final bool isDark;

  const NotificationBellButton({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final unreadCount = ref.watch(unifiedUnreadCountProvider);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(
            unreadCount > 0 ? Icons.notifications : Icons.notifications_outlined,
            color: unreadCount > 0 ? AppColors.cyan : textMuted,
            size: 24,
          ),
          tooltip: 'Notifications',
          onPressed: () {
            HapticService.light();
            context.push('/notifications');
          },
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
