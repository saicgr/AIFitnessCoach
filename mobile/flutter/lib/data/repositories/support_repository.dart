import 'dart:io';

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

      final path = userId != null ? '/support/tickets/$userId' : '/support/tickets';
      final response = await _apiClient.get(path);

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

  /// Get a presigned URL for uploading a ticket attachment to S3
  Future<Map<String, dynamic>> getAttachmentPresignedUrl({
    required String filename,
    required String contentType,
    required int fileSize,
  }) async {
    try {
      debugPrint('🔍 [Support] Getting presigned URL for attachment: $filename');
      final response = await _apiClient.post(
        '/support/attachments/presign',
        data: {
          'filename': filename,
          'content_type': contentType,
          'file_size': fileSize,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('✅ [Support] Got presigned URL, s3_key: ${data['s3_key']}');
        return data;
      }
      throw Exception('Failed to get presigned URL: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [Support] Error getting presigned URL: $e');
      rethrow;
    }
  }

  /// Upload a file to S3 using a presigned POST URL
  Future<void> uploadToS3({
    required String presignedUrl,
    required Map<String, dynamic>? fields,
    required File file,
    required String contentType,
  }) async {
    try {
      debugPrint('🔍 [Support] Uploading attachment to S3...');
      final fileBytes = await file.readAsBytes();
      final s3Dio = Dio();

      if (fields != null && fields.isNotEmpty) {
        final formData = FormData.fromMap({
          ...fields.map((k, v) => MapEntry(k, v.toString())),
          'file': MultipartFile.fromBytes(
            fileBytes,
            filename: file.path.split('/').last,
          ),
        });
        final response = await s3Dio.post(
          presignedUrl,
          data: formData,
          options: Options(
            receiveTimeout: const Duration(minutes: 2),
            sendTimeout: const Duration(minutes: 2),
          ),
        );
        debugPrint('✅ [Support] S3 upload complete: ${response.statusCode}');
        if (response.statusCode != 200 && response.statusCode != 204) {
          throw Exception('Upload failed with status ${response.statusCode}');
        }
      }
    } catch (e) {
      debugPrint('❌ [Support] Error uploading to S3: $e');
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
    String? stepsToReproduce,
    String? screenContext,
  }) async {
    try {
      debugPrint('🔍 [Support] Creating ticket: $subject');

      final data = <String, dynamic>{
        'user_id': userId,
        'subject': subject,
        'category': category,
        'priority': priority,
        'initial_message': description,
      };
      if (attachments != null && attachments.isNotEmpty) {
        data['attachments'] = attachments;
      }
      if (stepsToReproduce != null && stepsToReproduce.isNotEmpty) {
        data['steps_to_reproduce'] = stepsToReproduce;
      }
      if (screenContext != null && screenContext.isNotEmpty) {
        data['screen_context'] = screenContext;
      }

      final response = await _apiClient.post(
        '/support/tickets',
        data: data,
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
