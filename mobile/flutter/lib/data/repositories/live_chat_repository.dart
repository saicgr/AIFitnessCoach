import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/live_chat_session.dart';
import '../services/api_client.dart';

/// Live chat repository provider
final liveChatRepositoryProvider = Provider<LiveChatRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LiveChatRepository(apiClient);
});

/// Live chat repository for real-time customer support API calls
class LiveChatRepository {
  final ApiClient _apiClient;

  LiveChatRepository(this._apiClient);

  /// Start a new live chat session
  ///
  /// [category] - The category of the support request
  /// [initialMessage] - The user's first message
  /// [escalatedFromAi] - Whether this chat was escalated from AI
  /// [aiContext] - Context from the AI conversation if escalated
  Future<LiveChatSession> startLiveChat({
    required String category,
    required String initialMessage,
    bool escalatedFromAi = false,
    String? aiContext,
  }) async {
    try {
      debugPrint('🔍 [LiveChat] Starting live chat session...');
      debugPrint('🔍 [LiveChat] Category: $category, Escalated: $escalatedFromAi');

      final response = await _apiClient.post(
        '/support/live-chat/start',
        data: {
          'category': category,
          'initial_message': initialMessage,
          'escalated_from_ai': escalatedFromAi,
          if (aiContext != null) 'ai_context': aiContext,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final session =
            LiveChatSession.fromJson(response.data as Map<String, dynamic>);
        debugPrint('✅ [LiveChat] Session started: ${session.ticketId}');
        debugPrint('✅ [LiveChat] Status: ${session.status}, Queue position: ${session.queuePosition}');
        return session;
      }

      throw Exception('Failed to start live chat session');
    } on DioException catch (e) {
      debugPrint('❌ [LiveChat] DioException starting chat: ${e.message}');
      if (e.response?.statusCode == 503) {
        throw Exception('Live chat is currently unavailable. Please try again later.');
      }
      if (e.response?.statusCode == 429) {
        throw Exception('Too many requests. Please wait before starting a new chat.');
      }
      rethrow;
    } catch (e) {
      debugPrint('❌ [LiveChat] Error starting chat: $e');
      rethrow;
    }
  }

  /// Send a message in an active chat session
  ///
  /// [ticketId] - The ID of the chat session
  /// [message] - The message content to send
  Future<void> sendMessage({
    required String ticketId,
    required String message,
  }) async {
    try {
      debugPrint('🔍 [LiveChat] Sending message to ticket: $ticketId');

      final response = await _apiClient.post(
        '/support/live-chat/$ticketId/message',
        data: {
          'message': message,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ [LiveChat] Message sent successfully');
        return;
      }

      throw Exception('Failed to send message');
    } on DioException catch (e) {
      debugPrint('❌ [LiveChat] DioException sending message: ${e.message}');
      if (e.response?.statusCode == 404) {
        throw Exception('Chat session not found or has ended.');
      }
      if (e.response?.statusCode == 400) {
        throw Exception('Cannot send message. Chat may have ended.');
      }
      rethrow;
    } catch (e) {
      debugPrint('❌ [LiveChat] Error sending message: $e');
      rethrow;
    }
  }

  /// Send typing indicator to the agent
  ///
  /// [ticketId] - The ID of the chat session
  /// [isTyping] - Whether the user is currently typing
  Future<void> sendTypingIndicator({
    required String ticketId,
    required bool isTyping,
  }) async {
    try {
      // Don't log every typing indicator to reduce noise
      await _apiClient.post(
        '/support/live-chat/$ticketId/typing',
        data: {
          'is_typing': isTyping,
        },
      );
    } catch (e) {
      // Typing indicators are non-critical, don't throw
      debugPrint('⚠️ [LiveChat] Failed to send typing indicator: $e');
    }
  }

  /// Mark messages as read
  ///
  /// [ticketId] - The ID of the chat session
  /// [messageIds] - List of message IDs to mark as read
  Future<void> markMessagesRead({
    required String ticketId,
    required List<String> messageIds,
  }) async {
    if (messageIds.isEmpty) return;

    try {
      debugPrint('🔍 [LiveChat] Marking ${messageIds.length} messages as read');

      await _apiClient.post(
        '/support/live-chat/$ticketId/read',
        data: {
          'message_ids': messageIds,
        },
      );

      debugPrint('✅ [LiveChat] Messages marked as read');
    } catch (e) {
      // Non-critical operation, log but don't throw
      debugPrint('⚠️ [LiveChat] Failed to mark messages as read: $e');
    }
  }

  /// End the chat session
  ///
  /// [ticketId] - The ID of the chat session
  /// [resolutionNote] - Optional note about how the issue was resolved
  Future<void> endChat({
    required String ticketId,
    String? resolutionNote,
  }) async {
    try {
      debugPrint('🔍 [LiveChat] Ending chat session: $ticketId');

      final response = await _apiClient.post(
        '/support/live-chat/$ticketId/end',
        data: {
          if (resolutionNote != null) 'resolution_note': resolutionNote,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [LiveChat] Chat session ended');
        return;
      }

      throw Exception('Failed to end chat session');
    } catch (e) {
      debugPrint('❌ [LiveChat] Error ending chat: $e');
      rethrow;
    }
  }

  /// Get current queue position
  ///
  /// [ticketId] - The ID of the chat session
  Future<QueuePosition> getQueuePosition(String ticketId) async {
    try {
      debugPrint('🔍 [LiveChat] Getting queue position for: $ticketId');

      final response = await _apiClient.get(
        '/support/live-chat/$ticketId/queue-position',
      );

      if (response.statusCode == 200) {
        final position =
            QueuePosition.fromJson(response.data as Map<String, dynamic>);
        debugPrint('✅ [LiveChat] Queue position: ${position.position}');
        return position;
      }

      throw Exception('Failed to get queue position');
    } catch (e) {
      debugPrint('❌ [LiveChat] Error getting queue position: $e');
      rethrow;
    }
  }

  /// Check live chat availability
  Future<Availability> checkAvailability() async {
    try {
      debugPrint('🔍 [LiveChat] Checking availability...');

      final response = await _apiClient.get(
        '/support/live-chat/availability',
      );

      if (response.statusCode == 200) {
        final availability =
            Availability.fromJson(response.data as Map<String, dynamic>);
        debugPrint('✅ [LiveChat] Available: ${availability.isAvailable}, Agents: ${availability.agentsOnline}');
        return availability;
      }

      throw Exception('Failed to check availability');
    } catch (e) {
      debugPrint('❌ [LiveChat] Error checking availability: $e');
      // Return unavailable on error
      return const Availability(
        isAvailable: false,
        agentsOnline: 0,
        currentQueueSize: 0,
        estimatedWaitMinutes: 0,
      );
    }
  }

  /// Get current session state
  ///
  /// [ticketId] - The ID of the chat session
  Future<LiveChatSession?> getSession(String ticketId) async {
    try {
      debugPrint('🔍 [LiveChat] Fetching session: $ticketId');

      final response = await _apiClient.get(
        '/support/live-chat/$ticketId',
      );

      if (response.statusCode == 200) {
        final session =
            LiveChatSession.fromJson(response.data as Map<String, dynamic>);
        debugPrint('✅ [LiveChat] Session fetched: ${session.status}');
        return session;
      }

      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        debugPrint('⚠️ [LiveChat] Session not found: $ticketId');
        return null;
      }
      debugPrint('❌ [LiveChat] Error fetching session: $e');
      rethrow;
    } catch (e) {
      debugPrint('❌ [LiveChat] Error fetching session: $e');
      rethrow;
    }
  }

  /// Get chat history for a session
  ///
  /// [ticketId] - The ID of the chat session
  /// [limit] - Maximum number of messages to fetch
  /// [beforeId] - Fetch messages before this message ID (for pagination)
  Future<List<LiveChatMessage>> getChatHistory({
    required String ticketId,
    int limit = 50,
    String? beforeId,
  }) async {
    try {
      debugPrint('🔍 [LiveChat] Fetching chat history for: $ticketId');

      final response = await _apiClient.get(
        '/support/live-chat/$ticketId/messages',
        queryParameters: {
          'limit': limit,
          if (beforeId != null) 'before_id': beforeId,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        final messages = data
            .map((json) => LiveChatMessage.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('✅ [LiveChat] Fetched ${messages.length} messages');
        return messages;
      }

      return [];
    } catch (e) {
      debugPrint('❌ [LiveChat] Error fetching chat history: $e');
      rethrow;
    }
  }

  /// Submit chat rating and feedback
  ///
  /// [ticketId] - The ID of the chat session
  /// [rating] - Rating from 1-5
  /// [feedback] - Optional feedback text
  Future<void> submitRating({
    required String ticketId,
    required int rating,
    String? feedback,
  }) async {
    try {
      debugPrint('🔍 [LiveChat] Submitting rating for: $ticketId');

      final response = await _apiClient.post(
        '/support/live-chat/$ticketId/rating',
        data: {
          'rating': rating,
          if (feedback != null) 'feedback': feedback,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ [LiveChat] Rating submitted: $rating');
        return;
      }

      throw Exception('Failed to submit rating');
    } catch (e) {
      debugPrint('❌ [LiveChat] Error submitting rating: $e');
      // Non-critical, don't rethrow
    }
  }

  /// Request to escalate to a supervisor
  ///
  /// [ticketId] - The ID of the chat session
  /// [reason] - Reason for escalation
  Future<void> requestEscalation({
    required String ticketId,
    required String reason,
  }) async {
    try {
      debugPrint('🔍 [LiveChat] Requesting escalation for: $ticketId');

      final response = await _apiClient.post(
        '/support/live-chat/$ticketId/escalate',
        data: {
          'reason': reason,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [LiveChat] Escalation requested');
        return;
      }

      throw Exception('Failed to request escalation');
    } catch (e) {
      debugPrint('❌ [LiveChat] Error requesting escalation: $e');
      rethrow;
    }
  }
}
