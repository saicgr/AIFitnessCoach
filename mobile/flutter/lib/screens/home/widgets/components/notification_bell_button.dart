import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/services/haptic_service.dart';
import '../../../notifications/notifications_screen.dart';

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
    final unreadCount = ref.watch(unreadNotificationCountProvider);

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
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
                  width: 2,
                ),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
