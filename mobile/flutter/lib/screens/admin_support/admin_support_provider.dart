import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_client.dart';
import '../../core/services/supabase_realtime_service.dart';

/// Model for admin support chat in list view
class AdminSupportChat {
  final String ticketId;
  final String userId;
  final String userName;
  final String userEmail;
  final String category;
  final String status;
  final String? lastMessage;
  final bool lastMessageIsFromUser;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool hasUnread;
  final bool escalatedFromAi;
  final String? aiHandoffContext;
  final DateTime createdAt;

  AdminSupportChat({
    required this.ticketId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.category,
    required this.status,
    this.lastMessage,
    this.lastMessageIsFromUser = true,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.hasUnread = false,
    this.escalatedFromAi = false,
    this.aiHandoffContext,
    required this.createdAt,
  });

  factory AdminSupportChat.fromJson(Map<String, dynamic> json) {
    return AdminSupportChat(
      ticketId: json['id']?.toString() ?? json['ticket_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? json['users']?['name']?.toString() ?? 'Unknown User',
      userEmail: json['user_email']?.toString() ?? json['users']?['email']?.toString() ?? '',
      category: json['category']?.toString() ?? 'general',
      status: json['status']?.toString() ?? 'waiting',
      lastMessage: json['last_message']?.toString(),
      lastMessageIsFromUser: json['last_message_is_from_user'] ?? true,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'].toString())
          : null,
      unreadCount: json['unread_count'] ?? 0,
      hasUnread: (json['unread_count'] ?? 0) > 0,
      escalatedFromAi: json['escalated_from_ai'] ?? false,
      aiHandoffContext: json['ai_handoff_context']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

/// Model for chat message in admin view
class AdminChatMessage {
  final String id;
  final String ticketId;
  final String senderId;
  final String senderRole; // 'user' or 'agent'
  final String content;
  final DateTime createdAt;
  final DateTime? readAt;

  AdminChatMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.senderRole,
    required this.content,
    required this.createdAt,
    this.readAt,
  });

  factory AdminChatMessage.fromJson(Map<String, dynamic> json) {
    return AdminChatMessage(
      id: json['id']?.toString() ?? '',
      ticketId: json['ticket_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      senderRole: json['sender_role']?.toString() ?? 'user',
      content: json['content']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'].toString()) : null,
    );
  }

  bool get isFromUser => senderRole == 'user';
  bool get isRead => readAt != null;
}

/// State for admin support chats list
class AdminSupportChatsNotifier extends StateNotifier<AsyncValue<List<AdminSupportChat>>> {
  final Ref ref;
  Timer? _refreshTimer;

  AdminSupportChatsNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadChats();
    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      refreshChats();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadChats() async {
    try {
      final chats = await _fetchChats();
      if (mounted) {
        state = AsyncValue.data(chats);
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> refreshChats() async {
    try {
      final chats = await _fetchChats();
      if (mounted) {
        state = AsyncValue.data(chats);
      }
    } catch (e) {
      // Keep existing data on refresh error
      print('Failed to refresh admin chats: $e');
    }
  }

  Future<List<AdminSupportChat>> _fetchChats() async {
    final authState = ref.read(authStateProvider);
    if (authState.user == null) return [];

    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.get(
      '${ApiConstants.baseUrl}/api/v1/admin/live-chats',
    );

    if (response.statusCode == 200) {
      final data = response.data;
      if (data is Map && data['chats'] != null) {
        final chatsList = data['chats'] as List;
        return chatsList.map((c) => AdminSupportChat.fromJson(c)).toList();
      }
      if (data is List) {
        return data.map((c) => AdminSupportChat.fromJson(c)).toList();
      }
    }
    return [];
  }
}

final adminSupportChatsProvider =
    StateNotifierProvider<AdminSupportChatsNotifier, AsyncValue<List<AdminSupportChat>>>((ref) {
  return AdminSupportChatsNotifier(ref);
});

/// State for a specific chat's messages
class AdminChatMessagesNotifier extends StateNotifier<AsyncValue<List<AdminChatMessage>>> {
  final Ref ref;
  final String ticketId;
  StreamSubscription? _subscription;

  AdminChatMessagesNotifier(this.ref, this.ticketId) : super(const AsyncValue.loading()) {
    _loadMessages();
    _subscribeToMessages();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _fetchMessages();
      if (mounted) {
        state = AsyncValue.data(messages);
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  void _subscribeToMessages() {
    final realtimeService = ref.read(supabaseRealtimeServiceProvider);
    realtimeService.subscribeToMessages(ticketId, (messageData) {
      final newMessage = AdminChatMessage.fromJson(messageData);
      state.whenData((messages) {
        // Check if message already exists
        if (!messages.any((m) => m.id == newMessage.id)) {
          state = AsyncValue.data([...messages, newMessage]);
        }
      });
    });
  }

  Future<List<AdminChatMessage>> _fetchMessages() async {
    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.get(
      '${ApiConstants.baseUrl}/api/v1/admin/live-chats/$ticketId',
    );

    if (response.statusCode == 200) {
      final data = response.data;
      if (data is Map && data['messages'] != null) {
        final messagesList = data['messages'] as List;
        return messagesList.map((m) => AdminChatMessage.fromJson(m)).toList();
      }
    }
    return [];
  }

  Future<void> sendMessage(String content) async {
    final apiClient = ref.read(apiClientProvider);
    await apiClient.post(
      '${ApiConstants.baseUrl}/api/v1/admin/live-chats/$ticketId/reply',
      data: {'content': content},
    );
    // Message will be added via realtime subscription
  }

  Future<void> markAsRead() async {
    final apiClient = ref.read(apiClientProvider);
    await apiClient.post(
      '${ApiConstants.baseUrl}/api/v1/admin/live-chats/$ticketId/read',
    );
  }

  Future<void> closeChat({String? resolutionNote}) async {
    final apiClient = ref.read(apiClientProvider);
    await apiClient.post(
      '${ApiConstants.baseUrl}/api/v1/admin/live-chats/$ticketId/close',
      data: {'resolution_note': resolutionNote ?? 'Issue resolved'},
    );
  }
}

final adminChatMessagesProvider = StateNotifierProvider.family<
    AdminChatMessagesNotifier, AsyncValue<List<AdminChatMessage>>, String>((ref, ticketId) {
  return AdminChatMessagesNotifier(ref, ticketId);
});

/// Provider to get chat details (user info, context, etc.)
final adminChatDetailProvider = FutureProvider.family<AdminSupportChat?, String>((ref, ticketId) async {
  final chats = ref.watch(adminSupportChatsProvider);
  return chats.valueOrNull?.firstWhere(
    (c) => c.ticketId == ticketId,
    orElse: () => throw Exception('Chat not found'),
  );
});

/// Provider for unread count badge
final adminUnreadCountProvider = Provider<int>((ref) {
  final chats = ref.watch(adminSupportChatsProvider);
  return chats.valueOrNull?.fold<int>(0, (sum, chat) => sum + chat.unreadCount) ?? 0;
});
