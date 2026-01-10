import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/support_ticket.dart';
import '../services/api_client.dart';

/// Support repository provider
final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SupportRepository(apiClient);
});

/// Support repository for API calls
class SupportRepository {
  final ApiClient _apiClient;

  SupportRepository(this._apiClient);

  /// Get all tickets for a user
  Future<List<SupportTicket>> getTickets({String? userId}) async {
    try {
      debugPrint('🔍 [Support] Fetching tickets for user: $userId');

      final queryParams = <String, dynamic>{};
      if (userId != null) queryParams['user_id'] = userId;

      final response = await _apiClient.get(
        '/support/tickets',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        final tickets = data
            .map((json) => SupportTicket.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('✅ [Support] Fetched ${tickets.length} tickets');
        return tickets;
      }
      return [];
    } catch (e) {
      debugPrint('❌ [Support] Error fetching tickets: $e');
      rethrow;
    }
  }

  /// Get a specific ticket by ID
  Future<SupportTicket?> getTicketById(String ticketId) async {
    try {
      debugPrint('🔍 [Support] Fetching ticket: $ticketId');

      final response = await _apiClient.get('/support/tickets/$ticketId');

      if (response.statusCode == 200) {
        final ticket =
            SupportTicket.fromJson(response.data as Map<String, dynamic>);
        debugPrint('✅ [Support] Fetched ticket: ${ticket.ticketNumber}');
        return ticket;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Support] Error fetching ticket: $e');
      rethrow;
    }
  }

  /// Create a new support ticket
  Future<SupportTicket> createTicket({
    required String userId,
    required String subject,
    required String category,
    required String priority,
    required String description,
    List<String>? attachments,
  }) async {
    try {
      debugPrint('🔍 [Support] Creating ticket: $subject');

      final response = await _apiClient.post(
        '/support/tickets',
        data: {
          'user_id': userId,
          'subject': subject,
          'category': category,
          'priority': priority,
          'description': description,
          'attachments': attachments,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final ticket =
            SupportTicket.fromJson(response.data as Map<String, dynamic>);
        debugPrint('✅ [Support] Ticket created: ${ticket.ticketNumber}');
        return ticket;
      }

      throw Exception('Failed to create support ticket');
    } on DioException catch (e) {
      debugPrint('❌ [Support] DioException creating ticket: ${e.message}');
      if (e.response?.statusCode == 429) {
        throw Exception('Too many tickets created. Please wait before creating another.');
      }
      rethrow;
    } catch (e) {
      debugPrint('❌ [Support] Error creating ticket: $e');
      rethrow;
    }
  }

  /// Add a reply to an existing ticket
  Future<TicketMessage> addReply({
    required String ticketId,
    required String userId,
    required String content,
    List<String>? attachments,
  }) async {
    try {
      debugPrint('🔍 [Support] Adding reply to ticket: $ticketId');

      final response = await _apiClient.post(
        '/support/tickets/$ticketId/reply',
        data: {
          'user_id': userId,
          'content': content,
          'attachments': attachments,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final message =
            TicketMessage.fromJson(response.data as Map<String, dynamic>);
        debugPrint('✅ [Support] Reply added successfully');
        return message;
      }

      throw Exception('Failed to add reply');
    } catch (e) {
      debugPrint('❌ [Support] Error adding reply: $e');
      rethrow;
    }
  }

  /// Close a ticket
  Future<SupportTicket> closeTicket(String ticketId) async {
    try {
      debugPrint('🔍 [Support] Closing ticket: $ticketId');

      final response = await _apiClient.post(
        '/support/tickets/$ticketId/close',
      );

      if (response.statusCode == 200) {
        final ticket =
            SupportTicket.fromJson(response.data as Map<String, dynamic>);
        debugPrint('✅ [Support] Ticket closed: ${ticket.ticketNumber}');
        return ticket;
      }

      throw Exception('Failed to close ticket');
    } catch (e) {
      debugPrint('❌ [Support] Error closing ticket: $e');
      rethrow;
    }
  }

  /// Mark ticket updates as read
  Future<void> markAsRead(String ticketId) async {
    try {
      debugPrint('🔍 [Support] Marking ticket as read: $ticketId');

      await _apiClient.post('/support/tickets/$ticketId/read');

      debugPrint('✅ [Support] Ticket marked as read');
    } catch (e) {
      debugPrint('❌ [Support] Error marking ticket as read: $e');
      // Don't rethrow - this is a non-critical operation
    }
  }

  /// Get count of tickets with unread updates
  Future<int> getUnreadCount(String userId) async {
    try {
      debugPrint('🔍 [Support] Getting unread count for user: $userId');

      final response = await _apiClient.get(
        '/support/tickets/unread-count',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        final count = response.data['count'] as int? ?? 0;
        debugPrint('✅ [Support] Unread count: $count');
        return count;
      }
      return 0;
    } catch (e) {
      debugPrint('❌ [Support] Error getting unread count: $e');
      return 0;
    }
  }
}
