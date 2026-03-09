import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/conversation_realtime_service.dart';

/// Provider for the conversation realtime service (F13)
/// Manages Supabase Realtime broadcast channels for typing indicators.
/// Auto-disposed when no longer referenced.
final conversationRealtimeServiceProvider =
    Provider.autoDispose<ConversationRealtimeService>((ref) {
  final service = ConversationRealtimeService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider that tracks which users are currently typing in a conversation (F13)
/// Key: conversationId, Value: list of user names currently typing
final typingUsersProvider =
    StateProvider.autoDispose.family<List<String>, String>(
  (ref, conversationId) => [],
);
