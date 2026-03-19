import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../services/challenges_service.dart';
import '../../core/providers/auth_provider.dart';
import '../../screens/notifications/notifications_screen.dart';
import 'social_provider.dart';

/// Unified notification model that merges local + challenge notifications
class UnifiedNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime timestamp;
  final bool isRead;
  final String? challengeId;
  final String? requestId;
  final String? fromUserName;
  final String? fromUserAvatar;
  final String? referenceId;

  const UnifiedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.challengeId,
    this.requestId,
    this.fromUserName,
    this.fromUserAvatar,
    this.referenceId,
  });

  /// Create from a local NotificationItem
  factory UnifiedNotification.fromLocal(NotificationItem item) {
    return UnifiedNotification(
      id: item.id,
      title: item.title,
      body: item.body,
      type: item.type,
      timestamp: item.timestamp,
      isRead: item.isRead,
    );
  }

  /// Create from a challenge notification API response
  factory UnifiedNotification.fromChallengeNotification(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'challenge_received';
    final fromName = json['from_user_name'] as String?;

    String title;
    String body;
    switch (type) {
      case 'challenge_received':
        title = 'New Challenge!';
        body = '${fromName ?? 'Someone'} challenged you to beat their workout';
        break;
      case 'challenge_accepted':
        title = 'Challenge Accepted';
        body = '${fromName ?? 'Someone'} accepted your challenge!';
        break;
      case 'challenge_completed':
        title = 'Challenge Completed';
        body = '${fromName ?? 'Someone'} completed your challenge!';
        break;
      case 'challenge_beaten':
        title = 'Challenge Beaten!';
        body = '${fromName ?? 'Someone'} beat your workout record!';
        break;
      default:
        title = 'Challenge Update';
        body = json['message'] as String? ?? 'You have a challenge update';
    }

    return UnifiedNotification(
      id: 'challenge_${json['id'] ?? DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: type,
      timestamp: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isRead: json['is_read'] as bool? ?? false,
      challengeId: json['challenge_id'] as String?,
      fromUserName: fromName,
      fromUserAvatar: json['from_user_avatar'] as String?,
    );
  }

  /// Create from a friend request API response
  factory UnifiedNotification.fromFriendRequest(Map<String, dynamic> json) {
    final fromName = json['from_user_name'] as String? ?? 'Someone';
    return UnifiedNotification(
      id: 'friend_request_${json['id']}',
      title: 'Friend Request',
      body: '$fromName wants to be your friend',
      type: 'friend_request',
      timestamp: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isRead: false,
      requestId: json['id'] as String?,
      fromUserName: fromName,
      fromUserAvatar: json['from_user_avatar'] as String?,
    );
  }

  /// Create from a social notification API response (reactions, comments, mentions)
  factory UnifiedNotification.fromSocialNotification(Map<String, dynamic> json) {
    return UnifiedNotification(
      id: 'social_${json['id']}',
      title: json['title'] as String? ?? 'Notification',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'social',
      timestamp: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isRead: json['is_read'] as bool? ?? false,
      fromUserName: json['from_user_name'] as String?,
      fromUserAvatar: json['from_user_avatar'] as String?,
      referenceId: json['reference_id'] as String?,
    );
  }
}

/// Provider for ChallengesService
final challengesServiceProvider = Provider<ChallengesService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ChallengesService(apiClient);
});

/// Unified notifications provider combining local + challenge notifications
final unifiedNotificationsProvider =
    StateNotifierProvider<UnifiedNotificationsNotifier, AsyncValue<List<UnifiedNotification>>>((ref) {
  return UnifiedNotificationsNotifier(ref);
});

/// Unread count across all unified notifications
final unifiedUnreadCountProvider = Provider<int>((ref) {
  final state = ref.watch(unifiedNotificationsProvider);
  return state.whenOrNull(
        data: (notifications) => notifications.where((n) => !n.isRead).length,
      ) ??
      0;
});

class UnifiedNotificationsNotifier extends StateNotifier<AsyncValue<List<UnifiedNotification>>> {
  final Ref _ref;
  Timer? _pollTimer;

  UnifiedNotificationsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadAll();
    // TODO: Re-enable when social features are launched
    // _startPolling();
    // Re-fetch when auth state changes (userId becomes available after login)
    _ref.listen<String?>(currentUserIdProvider, (prev, next) {
      if (prev != next && next != null) {
        _loadAll();
      }
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _silentRefresh();
    });
  }

  /// Refresh without showing loading state (background poll)
  Future<void> _silentRefresh() async {
    // Only poll if we have data (don't poll during initial load or error)
    if (state is! AsyncData) return;
    try {
      await _loadAll();
    } catch (e) {
      // Silent failure - don't update state on poll errors
      debugPrint('🔔 [UnifiedNotifications] Silent poll error: $e');
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAll() async {
    try {
      final localNotifications = _ref.read(notificationsProvider);
      final localUnified = localNotifications.map(UnifiedNotification.fromLocal).toList();

      // Try to fetch challenge notifications from API
      List<UnifiedNotification> challengeUnified = [];
      final userId = _ref.read(currentUserIdProvider);
      if (userId != null) {
        try {
          final service = _ref.read(challengesServiceProvider);
          final response = await service.getNotifications(userId: userId);
          final notifications = response['notifications'] as List<dynamic>? ?? [];
          challengeUnified = notifications
              .map((n) => UnifiedNotification.fromChallengeNotification(n as Map<String, dynamic>))
              .toList();
        } catch (e) {
          debugPrint('🔔 [UnifiedNotifications] Error fetching challenge notifications: $e');
          // Continue with just local notifications
        }
      }

      // TODO: Re-enable when social features are launched
      // Fetch pending friend requests
      // List<UnifiedNotification> friendRequestUnified = [];
      // if (userId != null) {
      //   try {
      //     final socialService = _ref.read(socialServiceProvider);
      //     final requests = await socialService.getReceivedFriendRequests(
      //       userId: userId,
      //       status: 'pending',
      //     );
      //     friendRequestUnified = requests
      //         .map((r) => UnifiedNotification.fromFriendRequest(r))
      //         .toList();
      //   } catch (e) {
      //     debugPrint('🔔 [UnifiedNotifications] Error fetching friend requests: $e');
      //   }
      // }

      // TODO: Re-enable when social features are launched
      // Fetch social notifications (reactions, comments, mentions)
      // List<UnifiedNotification> socialUnified = [];
      // if (userId != null) {
      //   try {
      //     final socialService = _ref.read(socialServiceProvider);
      //     final response = await socialService.getSocialNotifications(
      //       userId: userId,
      //       limit: 50,
      //     );
      //     final items = response['notifications'] as List<dynamic>? ?? [];
      //     socialUnified = items
      //         .map((n) => UnifiedNotification.fromSocialNotification(n as Map<String, dynamic>))
      //         .toList();
      //   } catch (e) {
      //     debugPrint('🔔 [UnifiedNotifications] Error fetching social notifications: $e');
      //   }
      // }

      // Merge and sort by timestamp (newest first)
      final all = [...challengeUnified, ...localUnified];
      all.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      state = AsyncValue.data(all);
    } catch (e, st) {
      debugPrint('🔔 [UnifiedNotifications] Error loading notifications: $e');
      state = AsyncValue.error(e, st);
    }
  }

  /// Refresh all notifications
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadAll();
  }

  /// Mark a challenge notification as read via API
  Future<void> markChallengeNotificationRead(String notificationId) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;

    // Strip the 'challenge_' prefix to get the real notification ID
    final realId = notificationId.startsWith('challenge_')
        ? notificationId.substring('challenge_'.length)
        : notificationId;

    try {
      final service = _ref.read(challengesServiceProvider);
      await service.markNotificationRead(userId: userId, notificationId: realId);

      // Update local state
      state = state.whenData((notifications) {
        return notifications.map((n) {
          if (n.id == notificationId) {
            return UnifiedNotification(
              id: n.id,
              title: n.title,
              body: n.body,
              type: n.type,
              timestamp: n.timestamp,
              isRead: true,
              challengeId: n.challengeId,
              requestId: n.requestId,
              fromUserName: n.fromUserName,
              fromUserAvatar: n.fromUserAvatar,
              referenceId: n.referenceId,
            );
          }
          return n;
        }).toList();
      });
    } catch (e) {
      debugPrint('🔔 [UnifiedNotifications] Error marking as read: $e');
    }
  }

  /// Mark a social notification as read via API
  Future<void> markSocialNotificationRead(String notificationId) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;

    // Strip the 'social_' prefix to get the real notification ID
    final realId = notificationId.startsWith('social_')
        ? notificationId.substring('social_'.length)
        : notificationId;

    try {
      final socialService = _ref.read(socialServiceProvider);
      await socialService.markNotificationRead(userId: userId, notificationId: realId);

      // Update local state
      state = state.whenData((notifications) {
        return notifications.map((n) {
          if (n.id == notificationId) {
            return UnifiedNotification(
              id: n.id,
              title: n.title,
              body: n.body,
              type: n.type,
              timestamp: n.timestamp,
              isRead: true,
              challengeId: n.challengeId,
              requestId: n.requestId,
              fromUserName: n.fromUserName,
              fromUserAvatar: n.fromUserAvatar,
              referenceId: n.referenceId,
            );
          }
          return n;
        }).toList();
      });
    } catch (e) {
      debugPrint('🔔 [UnifiedNotifications] Error marking social notification as read: $e');
    }
  }

  /// Accept a friend request and remove its notification
  Future<void> acceptFriendRequest(String notificationId, String requestId) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      final socialService = _ref.read(socialServiceProvider);
      await socialService.acceptFriendRequest(userId: userId, requestId: requestId);

      // Remove notification from state
      state = state.whenData(
        (notifications) => notifications.where((n) => n.id != notificationId).toList(),
      );

      // Invalidate friends list so it auto-refreshes
      _ref.invalidate(friendsListProvider(userId));
    } catch (e) {
      debugPrint('🔔 [UnifiedNotifications] Error accepting friend request: $e');
      rethrow;
    }
  }

  /// Decline a friend request and remove its notification
  Future<void> declineFriendRequest(String notificationId, String requestId) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      final socialService = _ref.read(socialServiceProvider);
      await socialService.declineFriendRequest(userId: userId, requestId: requestId);

      // Remove notification from state
      state = state.whenData(
        (notifications) => notifications.where((n) => n.id != notificationId).toList(),
      );
    } catch (e) {
      debugPrint('🔔 [UnifiedNotifications] Error declining friend request: $e');
      rethrow;
    }
  }
}
