part of 'notifications_screen.dart';


class _EmptyNotificationsView extends StatelessWidget {
  final bool isDark;

  const _EmptyNotificationsView({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: elevatedColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none,
                size: 40,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your AI Coach will send you workout reminders, motivation, and progress updates here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: elevatedColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 18, color: AppColors.cyan),
                      const SizedBox(width: 8),
                      Text(
                        'What to expect',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.cyan,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ExpectationItem(
                    icon: Icons.fitness_center,
                    text: 'Workout reminders based on your schedule',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _ExpectationItem(
                    icon: Icons.emoji_events,
                    text: 'Achievement and streak alerts',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _ExpectationItem(
                    icon: Icons.auto_awesome,
                    text: 'Personalized tips from your AI Coach',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _ExpectationItem(
                    icon: Icons.insights,
                    text: 'Weekly progress summaries',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _ExpectationItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;

  const _ExpectationItem({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Row(
      children: [
        Icon(icon, size: 16, color: textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}


class _NotificationCard extends StatelessWidget {
  final NotificationItem notification;
  final bool isDark;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.isDark,
    required this.onTap,
  });

  IconData _getIconForType(String type) {
    switch (type) {
      case 'workout_reminder':
        return Icons.fitness_center;
      case 'ai_coach':
        return Icons.auto_awesome;
      case 'streak_alert':
        return Icons.local_fire_department;
      case 'achievement':
        return Icons.emoji_events;
      case 'weekly_summary':
        return Icons.insights;
      case 'nutrition_reminder':
        return Icons.restaurant;
      case 'hydration_reminder':
        return Icons.water_drop;
      case 'test':
        return Icons.science;
      case 'friend_request':
        return Icons.person_add;
      case 'challenge_received':
        return Icons.emoji_events;
      case 'challenge_accepted':
        return Icons.check_circle;
      case 'challenge_completed':
        return Icons.flag;
      case 'challenge_beaten':
        return Icons.military_tech;
      case 'reaction':
        return Icons.favorite;
      case 'comment':
        return Icons.chat_bubble;
      case 'mention':
        return Icons.alternate_email;
      case 'friend_accepted':
        return Icons.people;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'workout_reminder':
        return AppColors.cyan;
      case 'ai_coach':
        return AppColors.purple;
      case 'streak_alert':
        return AppColors.orange;
      case 'achievement':
        return AppColors.success;
      case 'weekly_summary':
        return AppColors.purple;
      case 'nutrition_reminder':
        return AppColors.success;
      case 'hydration_reminder':
        return Colors.blue;
      case 'test':
        return AppColors.cyan;
      case 'friend_request':
        return AppColors.purple;
      case 'challenge_received':
        return AppColors.orange;
      case 'challenge_accepted':
        return AppColors.cyan;
      case 'challenge_completed':
        return AppColors.success;
      case 'challenge_beaten':
        return const Color(0xFFFFD700);
      case 'reaction':
        return AppColors.pink;
      case 'comment':
        return AppColors.cyan;
      case 'mention':
        return AppColors.orange;
      case 'friend_accepted':
        return AppColors.success;
      default:
        return AppColors.cyan;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    final today = DateTime(now.year, now.month, now.day);
    final notifDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    // Format time as HH:MM AM/PM
    final hour = timestamp.hour > 12 ? timestamp.hour - 12 : (timestamp.hour == 0 ? 12 : timestamp.hour);
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final amPm = timestamp.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour:$minute $amPm';

    if (notifDate == today) {
      // Today - show relative time if recent, otherwise time
      if (diff.inMinutes < 1) {
        return 'Just now';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else {
        return 'Today at $timeStr';
      }
    } else if (notifDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday at $timeStr';
    } else if (diff.inDays < 7) {
      // Within a week - show day name
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${days[timestamp.weekday - 1]} at $timeStr';
    } else {
      // Older - show date
      return '${timestamp.month}/${timestamp.day} at $timeStr';
    }
  }

  @override
  Widget build(BuildContext context) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final typeColor = _getColorForType(notification.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: notification.isRead
                  ? null
                  : Border.all(color: typeColor.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getIconForType(notification.type),
                    size: 20,
                    color: typeColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 8, top: 4),
                              decoration: BoxDecoration(
                                color: typeColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatTimestamp(notification.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


/// Notification card that works with UnifiedNotification (challenge + local)
class _UnifiedNotificationCard extends StatelessWidget {
  final UnifiedNotification notification;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const _UnifiedNotificationCard({
    required this.notification,
    required this.isDark,
    required this.onTap,
    this.onAccept,
    this.onDecline,
  });

  IconData _getIconForType(String type) {
    switch (type) {
      case 'workout_reminder':
        return Icons.fitness_center;
      case 'ai_coach':
        return Icons.auto_awesome;
      case 'streak_alert':
        return Icons.local_fire_department;
      case 'achievement':
        return Icons.emoji_events;
      case 'weekly_summary':
        return Icons.insights;
      case 'nutrition_reminder':
        return Icons.restaurant;
      case 'hydration_reminder':
        return Icons.water_drop;
      case 'friend_request':
        return Icons.person_add;
      case 'challenge_received':
        return Icons.emoji_events;
      case 'challenge_accepted':
        return Icons.check_circle;
      case 'challenge_completed':
        return Icons.flag;
      case 'challenge_beaten':
        return Icons.military_tech;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'workout_reminder':
        return AppColors.cyan;
      case 'ai_coach':
        return AppColors.purple;
      case 'streak_alert':
        return AppColors.orange;
      case 'achievement':
        return AppColors.success;
      case 'weekly_summary':
        return AppColors.purple;
      case 'nutrition_reminder':
        return AppColors.success;
      case 'hydration_reminder':
        return Colors.blue;
      case 'friend_request':
        return AppColors.purple;
      case 'challenge_received':
        return AppColors.orange;
      case 'challenge_accepted':
        return AppColors.cyan;
      case 'challenge_completed':
        return AppColors.success;
      case 'challenge_beaten':
        return const Color(0xFFFFD700);
      default:
        return AppColors.cyan;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    final today = DateTime(now.year, now.month, now.day);
    final notifDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    final hour = timestamp.hour > 12 ? timestamp.hour - 12 : (timestamp.hour == 0 ? 12 : timestamp.hour);
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final amPm = timestamp.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour:$minute $amPm';

    if (notifDate == today) {
      if (diff.inMinutes < 1) {
        return 'Just now';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else {
        return 'Today at $timeStr';
      }
    } else if (notifDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday at $timeStr';
    } else if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${days[timestamp.weekday - 1]} at $timeStr';
    } else {
      return '${timestamp.month}/${timestamp.day} at $timeStr';
    }
  }

  @override
  Widget build(BuildContext context) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final typeColor = _getColorForType(notification.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: notification.isRead
                  ? null
                  : Border.all(color: typeColor.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar for challenge/friend notifications, icon for others
                if (notification.fromUserAvatar != null)
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: typeColor.withOpacity(0.2),
                    backgroundImage: NetworkImage(notification.fromUserAvatar!),
                  )
                else
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getIconForType(notification.type),
                      size: 20,
                      color: typeColor,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 8, top: 4),
                              decoration: BoxDecoration(
                                color: typeColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatTimestamp(notification.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: textMuted,
                        ),
                      ),
                      // Accept / Ignore buttons for friend requests
                      if (notification.type == 'friend_request' && (onAccept != null || onDecline != null)) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (onAccept != null)
                              Expanded(
                                child: SizedBox(
                                  height: 34,
                                  child: FilledButton(
                                    onPressed: onAccept,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.cyan,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Accept', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ),
                            if (onAccept != null && onDecline != null)
                              const SizedBox(width: 8),
                            if (onDecline != null)
                              Expanded(
                                child: SizedBox(
                                  height: 34,
                                  child: OutlinedButton(
                                    onPressed: onDecline,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: textSecondary,
                                      side: BorderSide(color: textMuted.withOpacity(0.3)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Ignore', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

