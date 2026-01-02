import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';

/// Model for a notification item
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime timestamp;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'type': type,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
  };

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
    id: json['id'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    type: json['type'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    isRead: json['isRead'] as bool? ?? false,
  );

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
    id: id,
    title: title,
    body: body,
    type: type,
    timestamp: timestamp,
    isRead: isRead ?? this.isRead,
  );
}

/// Storage key for notifications
const _notificationsStorageKey = 'app_notifications';

/// Provider for notifications with persistence
final notificationsProvider = StateNotifierProvider<NotificationsNotifier, List<NotificationItem>>((ref) {
  return NotificationsNotifier();
});

/// Provider for unread notification count
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.where((n) => !n.isRead).length;
});

class NotificationsNotifier extends StateNotifier<List<NotificationItem>> {
  NotificationsNotifier() : super([]) {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_notificationsStorageKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        state = jsonList.map((json) => NotificationItem.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('🔔 [Notifications] Error loading notifications: $e');
    }
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(state.map((n) => n.toJson()).toList());
      await prefs.setString(_notificationsStorageKey, jsonString);
    } catch (e) {
      debugPrint('🔔 [Notifications] Error saving notifications: $e');
    }
  }

  void addNotification(NotificationItem notification) {
    // Don't add duplicates
    if (state.any((n) => n.id == notification.id)) return;

    state = [notification, ...state];
    // Keep only last 100 notifications
    if (state.length > 100) {
      state = state.sublist(0, 100);
    }
    _saveNotifications();
  }

  /// Add notification from push message data
  void addFromPushMessage({
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
  }) {
    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      type: type ?? data?['type'] ?? 'ai_coach',
      timestamp: DateTime.now(),
      isRead: false,
    );
    addNotification(notification);
  }

  void markAsRead(String id) {
    state = state.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    _saveNotifications();
  }

  void markAllAsRead() {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
    _saveNotifications();
  }

  void clearAll() {
    state = [];
    _saveNotifications();
  }

  void deleteNotification(String id) {
    state = state.where((n) => n.id != id).toList();
    _saveNotifications();
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  void _navigateForNotificationType(BuildContext context, String type) {
    switch (type) {
      case 'ai_coach':
        context.push('/chat');
        break;
      case 'workout_reminder':
        context.push('/home');
        break;
      case 'nutrition_reminder':
        context.push('/nutrition');
        break;
      case 'hydration_reminder':
        context.push('/hydration');
        break;
      case 'streak_alert':
      case 'achievement':
        context.push('/achievements');
        break;
      case 'weekly_summary':
        context.push('/summaries');
        break;
      case 'test':
        // Test notifications stay on this screen
        break;
      default:
        // Unknown type - stay on notifications screen
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use actual brightness to support ThemeMode.system
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final notifications = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: textMuted),
              color: elevatedColor,
              onSelected: (value) {
                if (value == 'mark_all_read') {
                  ref.read(notificationsProvider.notifier).markAllAsRead();
                } else if (value == 'clear_all') {
                  ref.read(notificationsProvider.notifier).clearAll();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, size: 20, color: AppColors.cyan),
                      const SizedBox(width: 12),
                      const Text('Mark all as read'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all, size: 20, color: AppColors.error),
                      const SizedBox(width: 12),
                      const Text('Clear all'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: notifications.isEmpty
          ? _EmptyNotificationsView(isDark: isDark)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Dismissible(
                  key: Key(notification.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    ref.read(notificationsProvider.notifier).deleteNotification(notification.id);
                  },
                  child: _NotificationCard(
                    notification: notification,
                    isDark: isDark,
                    onTap: () {
                      ref.read(notificationsProvider.notifier).markAsRead(notification.id);
                      // Navigate based on notification type
                      _navigateForNotificationType(context, notification.type);
                    },
                  ),
                );
              },
            ),
    );
  }
}

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
