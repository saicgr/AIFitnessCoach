import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../models/chat_message.dart';
import '../services/api_client.dart';

/// Chat repository provider
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ChatRepository(apiClient);
});

/// Chat messages provider
final chatMessagesProvider =
    StateNotifierProvider<ChatMessagesNotifier, AsyncValue<List<ChatMessage>>>(
        (ref) {
  final repository = ref.watch(chatRepositoryProvider);
  final apiClient = ref.watch(apiClientProvider);
  return ChatMessagesNotifier(repository, apiClient);
});

/// Chat repository for API calls
class ChatRepository {
  final ApiClient _apiClient;

  ChatRepository(this._apiClient);

  /// Get chat history
  Future<List<ChatMessage>> getChatHistory(String userId, {int limit = 100}) async {
    try {
      debugPrint('🔍 [Chat] Fetching chat history for user: $userId');
      final response = await _apiClient.get(
        '${ApiConstants.chat}/history/$userId',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        final messages = data.map((json) {
          final item = ChatHistoryItem.fromJson(json as Map<String, dynamic>);
          return item.toChatMessage();
        }).toList();
        debugPrint('✅ [Chat] Fetched ${messages.length} messages');
        return messages;
      }
      return [];
    } catch (e) {
      debugPrint('❌ [Chat] Error fetching chat history: $e');
      rethrow;
    }
  }

  /// Send a message to the AI coach
  Future<ChatResponse> sendMessage({
    required String message,
    required String userId,
    Map<String, dynamic>? userProfile,
    Map<String, dynamic>? currentWorkout,
    Map<String, dynamic>? workoutSchedule,
    List<Map<String, dynamic>>? conversationHistory,
  }) async {
    try {
      debugPrint('🔍 [Chat] Sending message: ${message.substring(0, message.length.clamp(0, 50))}...');

      final response = await _apiClient.post(
        '${ApiConstants.chat}/send',
        data: ChatRequest(
          message: message,
          userId: userId,
          userProfile: userProfile,
          currentWorkout: currentWorkout,
          workoutSchedule: workoutSchedule,
          conversationHistory: conversationHistory,
        ).toJson(),
      );

      if (response.statusCode == 200) {
        final chatResponse = ChatResponse.fromJson(response.data as Map<String, dynamic>);
        debugPrint('✅ [Chat] Got response with intent: ${chatResponse.intent}');
        return chatResponse;
      }
      throw Exception('Failed to send message');
    } catch (e) {
      debugPrint('❌ [Chat] Error sending message: $e');
      rethrow;
    }
  }
}

/// Chat messages state notifier
class ChatMessagesNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final ChatRepository _repository;
  final ApiClient _apiClient;
  bool _isLoading = false;

  ChatMessagesNotifier(this._repository, this._apiClient)
      : super(const AsyncValue.data([]));

  bool get isLoading => _isLoading;

  /// Load chat history
  Future<void> loadHistory() async {
    final userId = await _apiClient.getUserId();
    if (userId == null) return;

    state = const AsyncValue.loading();
    try {
      final messages = await _repository.getChatHistory(userId);
      state = AsyncValue.data(messages);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Send a message
  Future<void> sendMessage(String message) async {
    if (_isLoading) return;

    final userId = await _apiClient.getUserId();
    if (userId == null) return;

    final currentMessages = state.valueOrNull ?? [];

    // Add user message immediately
    final userMessage = ChatMessage(
      role: 'user',
      content: message,
      createdAt: DateTime.now().toIso8601String(),
    );
    state = AsyncValue.data([...currentMessages, userMessage]);

    _isLoading = true;

    try {
      // Build conversation history for context
      final history = currentMessages.map((m) => {
        'role': m.role,
        'content': m.content,
      }).toList();

      final response = await _repository.sendMessage(
        message: message,
        userId: userId,
        conversationHistory: history,
      );

      // Add assistant response
      final assistantMessage = ChatMessage(
        role: 'assistant',
        content: response.message,
        intent: response.intent,
        createdAt: DateTime.now().toIso8601String(),
      );

      final updatedMessages = state.valueOrNull ?? [];
      state = AsyncValue.data([...updatedMessages, assistantMessage]);
    } catch (e) {
      // Add error message
      final errorMessage = ChatMessage(
        role: 'assistant',
        content: 'Sorry, I encountered an error. Please try again.',
        createdAt: DateTime.now().toIso8601String(),
      );
      final updatedMessages = state.valueOrNull ?? [];
      state = AsyncValue.data([...updatedMessages, errorMessage]);
    } finally {
      _isLoading = false;
    }
  }

  /// Clear messages
  void clear() {
    state = const AsyncValue.data([]);
  }

  /// Clear history (alias for clear)
  void clearHistory() {
    clear();
  }
}
