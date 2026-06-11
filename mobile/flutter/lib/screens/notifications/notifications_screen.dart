import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers/unified_notifications_provider.dart';
import '../../core/services/posthog_service.dart';
import '../../widgets/pill_app_bar.dart';

import '../../l10n/generated/app_localizations.dart';
part 'notifications_screen_part_empty_notifications_view.dart';


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

  /// Add notification from push message data.
  ///
  /// Id resolution: when the push payload carries a `notif_id` (a shared
  /// deterministic id such as `<type>_<localdate>`), it is used verbatim so
  /// the push and the in-app banner / home card for the same event dedupe to
  /// ONE bell entry (Phase C3 — [addNotification] ignores a duplicate id).
  /// Otherwise a unique timestamp id is used, as before.
  void addFromPushMessage({
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
  }) {
    final sharedId = data?['notif_id']?.toString();
    final notification = NotificationItem(
      id: (sharedId != null && sharedId.isNotEmpty)
          ? sharedId
          : DateTime.now().millisecondsSinceEpoch.toString(),
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

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedFilter = 'All';

  // Filter taxonomy. Every notification `type` produced anywhere in the app —
  // including every banner type via [BannerNotificationMapper] — must appear
  // in exactly one bucket here so the filter pills never silently drop an
  // entry. `rank_percentile` (the leaderboard banner) lives under Workouts;
  // `health_coaching` (Phase C3 proactive coaching) lives under Coach.
  static const _filterCategories = <String, Set<String>>{
    'All': {},
    'Workouts': {'missed_workout', 'workout_reminder', 'rank_percentile'},
    'Coach': {'ai_coach', 'ai_coach_accountability', 'week1_tip', 'contextual',
              'health_coaching', 'nutrition_reminder', 'hydration_reminder',
              'weekly_summary'},
    'Rewards': {'daily_crate', 'double_xp', 'streak_alert', 'achievement', 'wrapped'},
    'Social': {'friend_request', 'friend_accepted', 'reaction', 'comment', 'mention',
               'challenge_received', 'challenge_accepted', 'challenge_completed', 'challenge_beaten'},
    'System': {'renewal', 'billing', 'test'},
  };

  void _navigateForNotificationType(BuildContext context, String type, {String? challengeId}) {
    switch (type) {
      case 'ai_coach':
      case 'ai_coach_accountability':
        context.push('/chat');
        break;
      case 'workout_reminder':
        context.go('/home');
        break;
      case 'nutrition_reminder':
        context.go('/nutrition');
        break;
      case 'hydration_reminder':
        context.go('/nutrition?tab=2');
        break;
      case 'health_coaching':
        // Phase C3 proactive coaching (readiness briefing / anomaly /
        // activity nudge). The Sleep detail screen carries the expanded
        // readiness view that all four coaching surfaces deep-link into.
        context.push('/health/sleep');
        break;
      case 'streak_alert':
      case 'achievement':
        context.push('/achievements');
        break;
      case 'weekly_summary':
        context.push('/summaries');
        break;
      case 'challenge_received':
        context.push('/challenges');
        break;
      case 'challenge_accepted':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).notificationsYourFriendIsDoing),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case 'challenge_completed':
      case 'challenge_beaten':
        if (challengeId != null) {
          context.push('/challenge-compare', extra: challengeId);
        } else {
          context.push('/challenges');
        }
        break;
      case 'friend_request':
      case 'friend_accepted':
        // Actions handled via inline Accept/Ignore buttons
        break;
      case 'reaction':
      case 'comment':
      case 'mention':
        // Navigate to social feed
        context.go('/social');
        break;
      case 'test':
        // Test notifications stay on this screen
        break;
      // Banner-originated notification types — every BannerType mapped by
      // [BannerNotificationMapper] routes here so a bell tap lands somewhere
      // sensible.
      case 'missed_workout':
      case 'daily_crate':
      case 'double_xp':
      case 'week1_tip':
      case 'contextual':
        context.go('/home');
        break;
      case 'wrapped':
        context.go('/home');
        break;
      case 'rank_percentile':
        // The leaderboard percentile banner — its tap target is Discover.
        context.push('/leaderboard');
        break;
      case 'renewal':
        context.push('/settings/subscription');
        break;
      default:
        // Unknown type - stay on notifications screen
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.read(posthogServiceProvider).capture(eventName: 'notifications_viewed');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentColor = isDark ? AppColors.cyan : AppColorsLight.accent;

    final unifiedState = ref.watch(unifiedNotificationsProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PillAppBar(
        title: AppLocalizations.of(context).permissionsPrimerNotifications,
        actions: [
          PillAppBarAction(
            icon: Icons.more_vert,
            onTap: () {
              showMenu<String>(
                context: context,
                position: const RelativeRect.fromLTRB(100, 100, 0, 0),
                items: [
                  PopupMenuItem(
                    value: 'mark_all_read',
                    child: Row(
                      children: [
                        Icon(Icons.done_all, size: 20, color: AppColors.cyan),
                        const SizedBox(width: 12),
                        Text(AppLocalizations.of(context).notificationsMarkAllAsRead),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all, size: 20, color: AppColors.error),
                        const SizedBox(width: 12),
                        Text(AppLocalizations.of(context).settingsCardPartClearAll),
                      ],
                    ),
                  ),
                ],
              ).then((value) {
                if (value == 'mark_all_read') {
                  ref.read(unifiedNotificationsProvider.notifier).markAllAsRead();
                } else if (value == 'clear_all') {
                  ref.read(unifiedNotificationsProvider.notifier).clearAll();
                }
              });
            },
          ),
        ],
      ),
      body: unifiedState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: textMuted),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context).notificationsFailedToLoadNotifications, style: TextStyle(color: textMuted)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.read(unifiedNotificationsProvider.notifier).refresh(),
                child: Text(AppLocalizations.of(context).buttonRetry),
              ),
            ],
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return _EmptyNotificationsView(isDark: isDark);
          }

          // Apply filter
          final filteredNotifications = _selectedFilter == 'All'
              ? notifications
              : notifications.where((n) =>
                  _filterCategories[_selectedFilter]!.contains(n.type)
                ).toList();

          return Column(
            children: [
              // Filter pills
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filterCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final label = _filterCategories.keys.elementAt(index);
                    final isSelected = _selectedFilter == label;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFilter = label),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? accentColor.withValues(alpha: 0.15)
                              : elevatedColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? accentColor : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
                          ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? accentColor : textMuted,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              // Notification list
              Expanded(
                child: filteredNotifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.filter_list, size: 40, color: textMuted),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context).notificationsNoNotificationsInThis,
                              style: TextStyle(color: textMuted, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
            onRefresh: () => ref.read(unifiedNotificationsProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredNotifications.length,
              itemBuilder: (context, index) {
                final notification = filteredNotifications[index];
                final isChallengeNotification = notification.id.startsWith('challenge_');
                final isSocialNotification = notification.id.startsWith('social_');
                final isFriendRequest = notification.type == 'friend_request';

                return Dismissible(
                  key: Key(notification.id),
                  direction: (isChallengeNotification || isFriendRequest || isSocialNotification)
                      ? DismissDirection.none
                      : DismissDirection.endToStart,
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
                  child: _UnifiedNotificationCard(
                    notification: notification,
                    isDark: isDark,
                    onAccept: isFriendRequest && notification.requestId != null
                        ? () async {
                            try {
                              await ref.read(unifiedNotificationsProvider.notifier)
                                  .acceptFriendRequest(notification.id, notification.requestId!);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('You and ${notification.fromUserName} are now friends!'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(AppLocalizations.of(context).notificationsFailedToAcceptRequest),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          }
                        : null,
                    onDecline: isFriendRequest && notification.requestId != null
                        ? () async {
                            try {
                              await ref.read(unifiedNotificationsProvider.notifier)
                                  .declineFriendRequest(notification.id, notification.requestId!);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(AppLocalizations.of(context).notificationsFriendRequestIgnored),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(AppLocalizations.of(context).notificationsFailedToIgnoreRequest),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          }
                        : null,
                    onTap: () {
                      // Mark as read
                      if (isChallengeNotification) {
                        ref.read(unifiedNotificationsProvider.notifier)
                            .markChallengeNotificationRead(notification.id);
                      } else if (isSocialNotification) {
                        ref.read(unifiedNotificationsProvider.notifier)
                            .markSocialNotificationRead(notification.id);
                      } else if (!isFriendRequest) {
                        ref.read(notificationsProvider.notifier).markAsRead(notification.id);
                      }
                      _navigateForNotificationType(
                        context,
                        notification.type,
                        challengeId: notification.challengeId,
                      );
                    },
                  ),
                );
              },
            ),
          ),
              ),
            ],
          );
        },
      ),
    );
  }
}
