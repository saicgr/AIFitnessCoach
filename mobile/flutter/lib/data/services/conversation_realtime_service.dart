import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service that manages Supabase Realtime broadcast for typing indicators (F13)
///
/// Uses Supabase Realtime broadcast channels to send/receive typing events
/// in conversations. Each conversation gets its own channel.
class ConversationRealtimeService {
  final _supabase = Supabase.instance.client;
  RealtimeChannel? _channel;
  Timer? _typingTimer;
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of typing events from other users
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;

  /// Join a conversation's realtime channel for typing indicators
  void joinConversation(String conversationId) {
    // Clean up any existing channel
    leaveConversation();

    _channel = _supabase.channel('conversation:$conversationId');
    _channel!
        .onBroadcast(
          event: 'typing',
          callback: (payload) {
            _typingController.add(payload);
          },
        )
        .subscribe();
  }

  /// Send a typing indicator event
  void sendTyping(
    String conversationId,
    String userId,
    String userName,
    bool isTyping,
  ) {
    _typingTimer?.cancel();
    _channel?.sendBroadcastMessage(
      event: 'typing',
      payload: {
        'user_id': userId,
        'user_name': userName,
        'is_typing': isTyping,
      },
    );

    if (isTyping) {
      // Auto-clear after 3 seconds of no activity
      _typingTimer = Timer(const Duration(seconds: 3), () {
        sendTyping(conversationId, userId, userName, false);
      });
    }
  }

  /// Leave the current conversation's realtime channel
  void leaveConversation() {
    _typingTimer?.cancel();
    _channel?.unsubscribe();
    _channel = null;
  }

  /// Dispose of all resources
  void dispose() {
    leaveConversation();
    _typingController.close();
  }
}
