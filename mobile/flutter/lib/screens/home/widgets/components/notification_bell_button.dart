import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/providers/unified_notifications_provider.dart';
import '../../../../data/services/haptic_service.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/theme/accent_color_provider.dart';
import '../../../../core/theme/theme_colors.dart';
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
    final textMuted = ThemeColors.of(context).textMuted;
    final unreadCount = ref.watch(unifiedUnreadCountProvider);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(
            unreadCount > 0 ? Icons.notifications : Icons.notifications_outlined,
            color: unreadCount > 0 ? context.accentColor : textMuted,
            size: 24,
          ),
          // Matches _SettingsButton's compact box. The stock 48pt IconButton
          // made the masthead row 48pt tall against ~20pt of greeting text,
          // which is most of the dead band the user saw between the top bar
          // and the first banner.
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          tooltip: AppLocalizations.of(context).permissionsPrimerNotifications,
          onPressed: () {
            HapticService.light();
            context.push('/notifications');
          },
        ),
        if (unreadCount > 0)
          // Corner of the 24pt bell inside its 40pt box.
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.error,  // accent-allowlist: error/destructive -- must stay red
                shape: BoxShape.circle,
                border: Border.all(
                  color: ThemeColors.of(context).background,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
