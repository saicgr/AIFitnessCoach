part of 'social_service.dart';

/// Methods extracted from SocialService
extension _SocialServiceExt2 on SocialService {

  // ============================================================
  // DIRECT MESSAGES
  // ============================================================

  /// Get list of conversations for user
  Future<List<Map<String, dynamic>>> getConversations({
    required String userId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/social/messages/conversations',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> conversations = [];

        if (data is Map && data['conversations'] != null) {
          conversations = data['conversations'] as List<dynamic>;
        } else if (data is List) {
          conversations = data;
        }

        // Transform API response to UI-friendly format
        return conversations.map<Map<String, dynamic>>((conv) {
          // Get other participant (first participant that isn't current user)
          final participants = conv['participants'] as List<dynamic>? ?? [];
          Map<String, dynamic>? otherUser;
          for (final p in participants) {
            if (p['user_id'] != userId) {
              otherUser = p as Map<String, dynamic>;
              break;
            }
          }

          // Get last message info
          final lastMessage = conv['last_message'] as Map<String, dynamic>?;

          return {
            'id': conv['id'],
            'other_user_id': otherUser?['user_id'],
            'other_user_name': otherUser?['user_name'] ?? 'User',
            'other_user_avatar': otherUser?['user_avatar'],
            'is_support_user': otherUser?['is_support_user'] ?? false,
            'last_message': (lastMessage?['encryption_version'] ?? 0) > 0
                ? 'Encrypted message'
                : (lastMessage?['content'] ?? ''),
            'last_message_encryption_version': lastMessage?['encryption_version'] ?? 0,
            'last_message_time': conv['last_message_at'] ?? lastMessage?['created_at'],
            'unread_count': conv['unread_count'] ?? 0,
          };
        }).toList();
      } else {
        throw Exception('Failed to get conversations: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error getting conversations: $e');
      rethrow;
    }
  }


  /// Get messages in a conversation
  Future<List<Map<String, dynamic>>> getMessages({
    required String userId,
    required String conversationId,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _apiClient.get(
        '/social/messages/conversations/$conversationId',
        queryParameters: {
          'user_id': userId,
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['messages'] != null) {
          return List<Map<String, dynamic>>.from(data['messages']);
        }
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } else {
        throw Exception('Failed to get messages: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error getting messages: $e');
      rethrow;
    }
  }


  /// Send a message
  Future<Map<String, dynamic>> sendMessage({
    required String userId,
    required String recipientId,
    String? content,
    String? conversationId,
    String? encryptedContent,
    String? encryptionNonce,
    int? encryptionVersion,
  }) async {
    try {
      final response = await _apiClient.post(
        '/social/messages/send',
        queryParameters: {'user_id': userId},
        data: {
          'recipient_id': recipientId,
          if (content != null) 'content': content,
          if (conversationId != null) 'conversation_id': conversationId,
          if (encryptedContent != null) 'encrypted_content': encryptedContent,
          if (encryptionNonce != null) 'encryption_nonce': encryptionNonce,
          if (encryptionVersion != null) 'encryption_version': encryptionVersion,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Social] Message sent');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Social] Error sending message: $e');
      rethrow;
    }
  }

}
