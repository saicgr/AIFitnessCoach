import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/live_chat_session.dart';
import '../repositories/auth_repository.dart';
import '../repositories/live_chat_repository.dart';

/// Live chat session provider
final liveChatProvider =
    StateNotifierProvider<LiveChatNotifier, AsyncValue<LiveChatSession?>>(
  (ref) {
    final repository = ref.watch(liveChatRepositoryProvider);
    final authState = ref.watch(authStateProvider);
    final userId = authState.user?.id;
    return LiveChatNotifier(repository, userId);
  },
);

/// Live chat availability provider
final liveChatAvailabilityProvider = FutureProvider<Availability>((ref) async {
  final repository = ref.watch(liveChatRepositoryProvider);
  return await repository.checkAvailability();
});

/// Provider for tracking if user is typing (debounced)
final userTypingProvider = StateProvider<bool>((ref) => false);

/// Live chat state notifier with real-time support
class LiveChatNotifier extends StateNotifier<AsyncValue<LiveChatSession?>> {
  final LiveChatRepository _repository;
  final String? _userId;

  /// Supabase client for real-time subscriptions
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Real-time channel for session updates
  RealtimeChannel? _sessionChannel;

  /// Real-time channel for messages
  RealtimeChannel? _messagesChannel;

  /// Timer for debouncing typing indicator
  Timer? _typingDebounceTimer;

  /// Timer for polling queue position
  Timer? _queuePositionTimer;

  /// Current ticket ID for active session
  String? _currentTicketId;

  /// Last sent typing state to avoid redundant API calls
  bool _lastTypingState = false;

  LiveChatNotifier(this._repository, this._userId)
      : super(const AsyncValue.data(null));

  /// Start a new live chat session
  Future<void> startChat({
    required String category,
    required String initialMessage,
    bool escalatedFromAi = false,
    String? aiContext,
  }) async {
    if (_userId == null) {
      state = AsyncValue.error(
        Exception('User not authenticated'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();

    try {
      debugPrint('🔍 [LiveChatNotifier] Starting new chat session...');

      final session = await _repository.startLiveChat(
        category: category,
        initialMessage: initialMessage,
        escalatedFromAi: escalatedFromAi,
        aiContext: aiContext,
      );

      _currentTicketId = session.ticketId;
      state = AsyncValue.data(session);

      // Subscribe to real-time updates
      _subscribeToRealtimeUpdates(session.ticketId);

      // Start queue position polling if in queue
      if (session.isQueued) {
        _startQueuePositionPolling();
      }

      debugPrint('✅ [LiveChatNotifier] Chat session started: ${session.ticketId}');
    } catch (e, stackTrace) {
      debugPrint('❌ [LiveChatNotifier] Error starting chat: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Send a message in the current session
  Future<void> sendMessage(String message) async {
    final currentSession = state.valueOrNull;
    if (currentSession == null) {
      debugPrint('⚠️ [LiveChatNotifier] No active session to send message');
      return;
    }

    if (message.trim().isEmpty) return;

    try {
      debugPrint('🔍 [LiveChatNotifier] Sending message...');

      // Optimistically add message to UI
      final optimisticMessage = LiveChatMessage(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        ticketId: currentSession.ticketId,
        senderRole: SenderRole.user,
        message: message,
        createdAt: DateTime.now(),
      );

      final updatedMessages = [...currentSession.messages, optimisticMessage];
      state = AsyncValue.data(
        currentSession.copyWith(messages: updatedMessages),
      );

      // Send to API
      await _repository.sendMessage(
        ticketId: currentSession.ticketId,
        message: message,
      );

      // Clear typing state
      _sendTypingIndicator(false);

      debugPrint('✅ [LiveChatNotifier] Message sent');
    } catch (e) {
      debugPrint('❌ [LiveChatNotifier] Error sending message: $e');
      // Revert optimistic update on error
      await _refreshSession();
      rethrow;
    }
  }

  /// Handle user typing with debouncing
  void onUserTyping() {
    // Cancel existing timer
    _typingDebounceTimer?.cancel();

    // Send typing indicator if not already typing
    if (!_lastTypingState) {
      _sendTypingIndicator(true);
    }

    // Set timer to stop typing indicator after 2 seconds of inactivity
    _typingDebounceTimer = Timer(const Duration(seconds: 2), () {
      _sendTypingIndicator(false);
    });
  }

  /// Send typing indicator to server
  void _sendTypingIndicator(bool isTyping) {
    if (_currentTicketId == null) return;
    if (_lastTypingState == isTyping) return; // Avoid redundant calls

    _lastTypingState = isTyping;
    _repository.sendTypingIndicator(
      ticketId: _currentTicketId!,
      isTyping: isTyping,
    );
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead() async {
    final currentSession = state.valueOrNull;
    if (currentSession == null) return;

    final unreadMessageIds = currentSession.messages
        .where((m) => m.isFromAgent && !m.isRead)
        .map((m) => m.id)
        .toList();

    if (unreadMessageIds.isEmpty) return;

    try {
      await _repository.markMessagesRead(
        ticketId: currentSession.ticketId,
        messageIds: unreadMessageIds,
      );

      // Update local state
      final updatedMessages = currentSession.messages.map((m) {
        if (unreadMessageIds.contains(m.id)) {
          return m.copyWith(readAt: DateTime.now());
        }
        return m;
      }).toList();

      state = AsyncValue.data(
        currentSession.copyWith(messages: updatedMessages),
      );
    } catch (e) {
      debugPrint('⚠️ [LiveChatNotifier] Failed to mark messages as read: $e');
    }
  }

  /// End the current chat session
  Future<void> endChat({String? resolutionNote}) async {
    final currentSession = state.valueOrNull;
    if (currentSession == null) return;

    try {
      debugPrint('🔍 [LiveChatNotifier] Ending chat session...');

      await _repository.endChat(
        ticketId: currentSession.ticketId,
        resolutionNote: resolutionNote,
      );

      // Update local state
      state = AsyncValue.data(
        currentSession.copyWith(
          status: LiveChatStatus.ended,
          endedAt: DateTime.now(),
        ),
      );

      // Cleanup
      _cleanup();

      debugPrint('✅ [LiveChatNotifier] Chat session ended');
    } catch (e) {
      debugPrint('❌ [LiveChatNotifier] Error ending chat: $e');
      rethrow;
    }
  }

  /// Submit rating for the chat session
  Future<void> submitRating({required int rating, String? feedback}) async {
    final currentSession = state.valueOrNull;
    if (currentSession == null) return;

    try {
      await _repository.submitRating(
        ticketId: currentSession.ticketId,
        rating: rating,
        feedback: feedback,
      );
      debugPrint('✅ [LiveChatNotifier] Rating submitted');
    } catch (e) {
      debugPrint('⚠️ [LiveChatNotifier] Failed to submit rating: $e');
    }
  }

  /// Request escalation to supervisor
  Future<void> requestEscalation(String reason) async {
    final currentSession = state.valueOrNull;
    if (currentSession == null) return;

    try {
      await _repository.requestEscalation(
        ticketId: currentSession.ticketId,
        reason: reason,
      );
      debugPrint('✅ [LiveChatNotifier] Escalation requested');
    } catch (e) {
      debugPrint('❌ [LiveChatNotifier] Error requesting escalation: $e');
      rethrow;
    }
  }

  /// Resume an existing session
  Future<void> resumeSession(String ticketId) async {
    state = const AsyncValue.loading();

    try {
      debugPrint('🔍 [LiveChatNotifier] Resuming session: $ticketId');

      final session = await _repository.getSession(ticketId);

      if (session == null) {
        state = const AsyncValue.data(null);
        return;
      }

      _currentTicketId = ticketId;
      state = AsyncValue.data(session);

      // Subscribe to real-time updates
      _subscribeToRealtimeUpdates(ticketId);

      // Start queue position polling if in queue
      if (session.isQueued) {
        _startQueuePositionPolling();
      }

      debugPrint('✅ [LiveChatNotifier] Session resumed');
    } catch (e, stackTrace) {
      debugPrint('❌ [LiveChatNotifier] Error resuming session: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Clear the current session
  void clearSession() {
    _cleanup();
    state = const AsyncValue.data(null);
  }

  /// Subscribe to real-time updates via Supabase
  void _subscribeToRealtimeUpdates(String ticketId) {
    debugPrint('🔍 [LiveChatNotifier] Subscribing to real-time updates...');

    // Subscribe to session updates (status changes, agent assignment)
    _sessionChannel = _supabase
        .channel('live_chat_session:$ticketId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'live_chat_sessions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'ticket_id',
            value: ticketId,
          ),
          callback: (payload) {
            debugPrint('🔔 [LiveChatNotifier] Session update received');
            _handleSessionUpdate(payload.newRecord);
          },
        )
        .subscribe();

    // Subscribe to new messages
    _messagesChannel = _supabase
        .channel('live_chat_messages:$ticketId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'live_chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'ticket_id',
            value: ticketId,
          ),
          callback: (payload) {
            debugPrint('🔔 [LiveChatNotifier] New message received');
            _handleNewMessage(payload.newRecord);
          },
        )
        .subscribe();

    // Subscribe to typing indicator updates
    _supabase
        .channel('live_chat_typing:$ticketId')
        .onBroadcast(
          event: 'typing',
          callback: (payload) {
            final isAgentTyping = payload['is_agent_typing'] as bool? ?? false;
            _handleAgentTyping(isAgentTyping);
          },
        )
        .subscribe();

    debugPrint('✅ [LiveChatNotifier] Subscribed to real-time updates');
  }

  /// Handle session update from real-time
  void _handleSessionUpdate(Map<String, dynamic> data) {
    final currentSession = state.valueOrNull;
    if (currentSession == null) return;

    try {
      // Parse status
      final statusStr = data['status'] as String?;
      LiveChatStatus? newStatus;
      if (statusStr != null) {
        newStatus = LiveChatStatus.values.firstWhere(
          (s) => s.name == statusStr,
          orElse: () => currentSession.status,
        );
      }

      // Update session with new data
      final updatedSession = currentSession.copyWith(
        status: newStatus,
        agentName: data['agent_name'] as String? ?? currentSession.agentName,
        agentId: data['agent_id'] as String? ?? currentSession.agentId,
        queuePosition: data['queue_position'] as int? ?? currentSession.queuePosition,
      );

      state = AsyncValue.data(updatedSession);

      // Stop queue polling if no longer in queue
      if (updatedSession.isActive) {
        _stopQueuePositionPolling();
      }
    } catch (e) {
      debugPrint('⚠️ [LiveChatNotifier] Error handling session update: $e');
    }
  }

  /// Handle new message from real-time
  void _handleNewMessage(Map<String, dynamic> data) {
    final currentSession = state.valueOrNull;
    if (currentSession == null) return;

    try {
      final message = LiveChatMessage.fromJson(data);

      // Avoid duplicates
      if (currentSession.messages.any((m) => m.id == message.id)) {
        return;
      }

      // Add message to list
      final updatedMessages = [...currentSession.messages, message];
      state = AsyncValue.data(
        currentSession.copyWith(
          messages: updatedMessages,
          isAgentTyping: false, // Clear typing indicator on new message
        ),
      );
    } catch (e) {
      debugPrint('⚠️ [LiveChatNotifier] Error handling new message: $e');
    }
  }

  /// Handle agent typing indicator
  void _handleAgentTyping(bool isTyping) {
    final currentSession = state.valueOrNull;
    if (currentSession == null) return;

    if (currentSession.isAgentTyping != isTyping) {
      state = AsyncValue.data(
        currentSession.copyWith(isAgentTyping: isTyping),
      );
    }
  }

  /// Start polling for queue position
  void _startQueuePositionPolling() {
    _queuePositionTimer?.cancel();
    _queuePositionTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _pollQueuePosition(),
    );
  }

  /// Stop polling for queue position
  void _stopQueuePositionPolling() {
    _queuePositionTimer?.cancel();
    _queuePositionTimer = null;
  }

  /// Poll for current queue position
  Future<void> _pollQueuePosition() async {
    if (_currentTicketId == null) return;

    final currentSession = state.valueOrNull;
    if (currentSession == null || !currentSession.isQueued) {
      _stopQueuePositionPolling();
      return;
    }

    try {
      final position = await _repository.getQueuePosition(_currentTicketId!);

      state = AsyncValue.data(
        currentSession.copyWith(
          queuePosition: position.position,
          estimatedWaitMinutes: position.estimatedWaitMinutes,
        ),
      );
    } catch (e) {
      debugPrint('⚠️ [LiveChatNotifier] Failed to poll queue position: $e');
    }
  }

  /// Refresh session from server
  Future<void> _refreshSession() async {
    if (_currentTicketId == null) return;

    try {
      final session = await _repository.getSession(_currentTicketId!);
      if (session != null) {
        state = AsyncValue.data(session);
      }
    } catch (e) {
      debugPrint('⚠️ [LiveChatNotifier] Failed to refresh session: $e');
    }
  }

  /// Cleanup resources
  void _cleanup() {
    debugPrint('🔍 [LiveChatNotifier] Cleaning up resources...');

    _typingDebounceTimer?.cancel();
    _typingDebounceTimer = null;

    _queuePositionTimer?.cancel();
    _queuePositionTimer = null;

    _sessionChannel?.unsubscribe();
    _sessionChannel = null;

    _messagesChannel?.unsubscribe();
    _messagesChannel = null;

    _currentTicketId = null;
    _lastTypingState = false;
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }
}

/// Provider for active chat count badge
final activeChatBadgeProvider = Provider<int>((ref) {
  final session = ref.watch(liveChatProvider).valueOrNull;
  if (session == null) return 0;
  if (session.hasEnded) return 0;
  return session.unreadCount;
});

/// Provider to check if there's an active chat session
final hasActiveChatProvider = Provider<bool>((ref) {
  final session = ref.watch(liveChatProvider).valueOrNull;
  return session != null && !session.hasEnded;
});

/// Provider for chat status text
final chatStatusTextProvider = Provider<String>((ref) {
  final session = ref.watch(liveChatProvider).valueOrNull;
  if (session == null) return '';

  if (session.isQueued) {
    final position = session.queuePosition;
    if (position != null && position > 0) {
      return 'Queue position: $position';
    }
    return 'Waiting for agent...';
  }

  if (session.isActive) {
    if (session.isAgentTyping) {
      return '${session.agentName ?? 'Agent'} is typing...';
    }
    return 'Connected to ${session.agentName ?? 'Agent'}';
  }

  if (session.hasEnded) {
    return 'Chat ended';
  }

  return '';
});
