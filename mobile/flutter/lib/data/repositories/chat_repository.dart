import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/theme_provider.dart';
import '../../navigation/app_router.dart';
import '../../screens/ai_settings/ai_settings_screen.dart';
import '../../screens/chat/widgets/media_picker_helper.dart';
import '../../core/providers/sound_preferences_provider.dart';
import '../services/haptic_service.dart';
import '../../services/offline_coach_service.dart';
import '../models/chat_message.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/connectivity_service.dart';
import '../services/data_cache_service.dart';
import '../providers/audio_preferences_provider.dart';
import '../providers/unified_state_provider.dart';
import 'workout_repository.dart';
import 'auth_repository.dart';
import 'hydration_repository.dart';
import 'nutrition_repository.dart';

part 'chat_repository_part_chat_messages_notifier.dart';
part 'chat_repository_part_chat_messages_notifier_ext.dart';


/// Chat repository provider
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ChatRepository(apiClient);
});

/// Chat messages provider - now includes workout context, settings control, navigation, hydration, AI settings, and unified fasting/nutrition context
final chatMessagesProvider =
    StateNotifierProvider<ChatMessagesNotifier, AsyncValue<List<ChatMessage>>>(
        (ref) {
  final repository = ref.watch(chatRepositoryProvider);
  final apiClient = ref.watch(apiClientProvider);
  final workoutsNotifier = ref.watch(workoutsProvider.notifier);
  final workoutRepository = ref.watch(workoutRepositoryProvider);
  // Only rebuild when user identity changes (login/logout), not on data refresh
  ref.watch(authStateProvider.select((s) => s.user?.id));
  final user = ref.read(authStateProvider).user;
  final themeNotifier = ref.watch(themeModeProvider.notifier);
  final router = ref.watch(routerProvider);
  final hydrationNotifier = ref.watch(hydrationProvider.notifier);
  final nutritionNotifier = ref.watch(nutritionProvider.notifier);
  // Pass a callback to get fresh AI settings on each message instead of caching stale settings
  AISettings getAISettings() => ref.read(aiSettingsProvider);
  // Pass a callback to set AI generating state (triggers home screen rebuild)
  void setAIGenerating(bool value) => ref.read(aiGeneratingWorkoutProvider.notifier).state = value;
  // Pass a callback to get the unified fasting/nutrition/workout context
  String getUnifiedContext() => ref.read(aiCoachContextProvider);
  // Offline coach dependencies
  final offlineCoach = ref.watch(offlineCoachServiceProvider);
  bool isOnline() => ref.read(isOnlineProvider);
  // Sound + audio control callbacks for AI setting changes
  SoundPreferencesNotifier getSoundPrefs() => ref.read(soundPreferencesProvider.notifier);
  AudioPreferencesNotifier getAudioPrefs() => ref.read(audioPreferencesProvider.notifier);
  return ChatMessagesNotifier(repository, apiClient, workoutsNotifier, workoutRepository, user, themeNotifier, router, hydrationNotifier, nutritionNotifier, getAISettings, setAIGenerating, getUnifiedContext, offlineCoach, isOnline, getSoundPrefs, getAudioPrefs);
});

/// Chat repository for API calls
class ChatRepository {
  final ApiClient _apiClient;

  ChatRepository(this._apiClient);

  /// Get chat history
  Future<List<ChatMessage>> getChatHistory(String userId, {int limit = 100, int offset = 0}) async {
    try {
      debugPrint('🔍 [Chat] Fetching chat history for user: $userId (limit=$limit, offset=$offset)');
      final response = await _apiClient.get(
        '${ApiConstants.chat}/history/$userId',
        queryParameters: {'limit': limit, 'offset': offset},
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

  /// Get a presigned URL for S3 media upload
  Future<Map<String, dynamic>> getPresignedUrl({
    required String filename,
    required String contentType,
    required String mediaType,
    required int expectedSizeBytes,
  }) async {
    try {
      debugPrint('🔍 [Chat] Getting presigned URL for $filename ($contentType, $expectedSizeBytes bytes)');
      final response = await _apiClient.post(
        '${ApiConstants.chat}/media/presign',
        data: {
          'filename': filename,
          'content_type': contentType,
          'media_type': mediaType,
          'expected_size_bytes': expectedSizeBytes,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('✅ [Chat] Got presigned URL, s3_key: ${data['s3_key']}');
        return data;
      }
      throw Exception('Failed to get presigned URL: ${response.statusCode}');
    } on DioException catch (e) {
      debugPrint('❌ [Chat] Error getting presigned URL: $e');
      if (e.response?.statusCode == 503) {
        throw Exception('Media upload is temporarily unavailable. Please try again later.');
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Request timed out. Please check your connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Unable to connect. Please check your internet connection.');
      }
      throw Exception('Failed to prepare upload. Please try again.');
    } catch (e) {
      debugPrint('❌ [Chat] Error getting presigned URL: $e');
      rethrow;
    }
  }

  /// Get batch presigned URLs for multiple media uploads
  Future<List<Map<String, dynamic>>> getBatchPresignedUrls({
    required List<Map<String, dynamic>> files,
  }) async {
    try {
      debugPrint('🔍 [Chat] Getting batch presigned URLs for ${files.length} files');
      final response = await _apiClient.post(
        '${ApiConstants.chat}/media/presign-batch',
        data: {'files': files},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = (data['items'] as List).cast<Map<String, dynamic>>();
        debugPrint('✅ [Chat] Got ${items.length} presigned URLs');
        return items;
      }
      throw Exception('Failed to get batch presigned URLs: ${response.statusCode}');
    } on DioException catch (e) {
      debugPrint('❌ [Chat] Error getting batch presigned URLs: $e');
      if (e.response?.statusCode == 503) {
        throw Exception('Media upload is temporarily unavailable. Please try again later.');
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Request timed out. Please check your connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Unable to connect. Please check your internet connection.');
      }
      throw Exception('Failed to prepare upload. Please try again.');
    } catch (e) {
      debugPrint('❌ [Chat] Error getting batch presigned URLs: $e');
      rethrow;
    }
  }

  /// Upload a file directly to S3 using the presigned URL
  /// Uses a standalone Dio instance (not the API client) for direct S3 PUT
  Future<void> uploadToS3({
    required String presignedUrl,
    required Map<String, dynamic>? fields,
    required File file,
    required String contentType,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      debugPrint('🔍 [Chat] Uploading to S3...');
      final fileBytes = await file.readAsBytes();

      // Use a standalone Dio for S3 upload (no auth interceptor)
      final s3Dio = Dio();

      if (fields != null && fields.isNotEmpty) {
        // POST with multipart form data (for presigned POST)
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
            receiveTimeout: const Duration(minutes: 5),
            sendTimeout: const Duration(minutes: 5),
          ),
          onSendProgress: onProgress,
        );
        debugPrint('✅ [Chat] S3 upload complete: ${response.statusCode}');
        if (response.statusCode != 200 && response.statusCode != 204) {
          throw Exception('Upload failed with status ${response.statusCode}. Please try again.');
        }
      } else {
        // PUT with raw bytes (for presigned PUT URL)
        final response = await s3Dio.put(
          presignedUrl,
          data: Stream.fromIterable(fileBytes.map((e) => [e])),
          options: Options(
            headers: {
              'Content-Type': contentType,
              'Content-Length': fileBytes.length,
            },
            receiveTimeout: const Duration(minutes: 5),
            sendTimeout: const Duration(minutes: 5),
          ),
          onSendProgress: onProgress,
        );
        debugPrint('✅ [Chat] S3 upload complete: ${response.statusCode}');
        if (response.statusCode != 200 && response.statusCode != 204) {
          throw Exception('Upload failed with status ${response.statusCode}. Please try again.');
        }
      }
    } on DioException catch (e) {
      debugPrint('❌ [Chat] Error uploading to S3: $e');
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('Upload timed out. The file may be too large or your connection is slow.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Upload failed. Please check your internet connection.');
      }
      throw Exception('Failed to upload file. Please try again.');
    } catch (e) {
      debugPrint('❌ [Chat] Error uploading to S3: $e');
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
    Map<String, dynamic>? aiSettings,
    String? unifiedContext,
    Map<String, dynamic>? mediaRef,
    List<Map<String, dynamic>>? mediaRefs,
    String? imageBase64,
    List<String>? videoFrames,
    String? mediaUrl,
  }) async {
    try {
      debugPrint('🔍 [Chat] Sending message: ${message.substring(0, message.length.clamp(0, 50))}...');
      if (aiSettings != null) {
        debugPrint('🤖 [Chat] AI settings: ${aiSettings['coaching_style']}, ${aiSettings['communication_tone']}');
      }
      if (unifiedContext != null) {
        debugPrint('🎯 [Chat] Including unified fasting/nutrition/workout context');
      }
      if (videoFrames != null) {
        debugPrint('🎬 [Chat] Sending ${videoFrames.length} pre-extracted video frames');
      }

      final hasMedia = imageBase64 != null || videoFrames != null || mediaRef != null || (mediaRefs != null && mediaRefs.isNotEmpty);
      final response = await _apiClient.post(
        '${ApiConstants.chat}/send',
        data: ChatRequest(
          message: message,
          userId: userId,
          userProfile: userProfile,
          currentWorkout: currentWorkout,
          workoutSchedule: workoutSchedule,
          conversationHistory: conversationHistory,
          aiSettings: aiSettings,
          unifiedContext: unifiedContext,
          mediaRef: mediaRef,
          mediaRefs: mediaRefs,
          imageBase64: imageBase64,
          videoFrames: videoFrames,
          mediaUrl: mediaUrl,
        ).toJson(),
        // Media requests go through Gemini Vision — allow up to 3 minutes
        options: hasMedia ? Options(receiveTimeout: const Duration(minutes: 3)) : null,
      );

      if (response.statusCode == 200) {
        final jsonData = response.data as Map<String, dynamic>;
        debugPrint('🔍 [Chat] Raw response JSON: $jsonData');
        debugPrint('🔍 [Chat] agent_type in JSON: ${jsonData['agent_type']}');
        debugPrint('🔍 [Chat] action_data in JSON: ${jsonData['action_data']}');
        final chatResponse = ChatResponse.fromJson(jsonData);
        debugPrint('✅ [Chat] Got response with intent: ${chatResponse.intent}, agentType: ${chatResponse.agentType}, actionData: ${chatResponse.actionData}');
        return chatResponse;
      }
      throw Exception('Failed to send message');
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final detail = e.response?.data;
        debugPrint('❌ [Chat] 422 Validation error: $detail');
        final validationMsg = _extractValidationMessage(detail);
        throw Exception('Validation error: $validationMsg');
      }
      debugPrint('❌ [Chat] Error sending message: $e');
      if (e.response?.statusCode == 503) {
        throw Exception('The AI coach is temporarily unavailable. Please try again in a moment.');
      } else if (e.response?.statusCode == 429) {
        throw Exception('Too many messages. Please wait a moment before trying again.');
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout) {
        throw Exception('The request timed out. Please check your connection and try again.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Unable to connect to the server. Please check your internet connection.');
      }
      throw Exception('Something went wrong. Please try again.');
    } catch (e) {
      debugPrint('❌ [Chat] Error sending message: $e');
      rethrow;
    }
  }

  /// Extract human-readable validation message from Pydantic 422 error detail
  String _extractValidationMessage(dynamic detail) {
    if (detail == null) return 'Unknown validation error';
    if (detail is Map<String, dynamic>) {
      final errors = detail['detail'];
      if (errors is List && errors.isNotEmpty) {
        return errors.map((e) {
          final loc = (e['loc'] as List?)?.join(' -> ') ?? '';
          final msg = e['msg'] ?? '';
          return '$loc: $msg';
        }).join('; ');
      }
      return detail.toString();
    }
    return detail.toString();
  }

  /// Search chat history on the server (#15)
  Future<List<ChatMessage>> searchChatHistory(String query, {int limit = 20}) async {
    try {
      debugPrint('🔍 [Chat] Searching chat history: $query');
      final response = await _apiClient.post(
        '${ApiConstants.chat}/search',
        data: {'query': query, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['results'] as List? ?? [];
        return data.map((json) {
          final item = ChatHistoryItem.fromJson(json as Map<String, dynamic>);
          return item.toChatMessage();
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ [Chat] Error searching chat history: $e');
      return [];
    }
  }

  /// Delete a chat message (#15)
  Future<void> deleteMessage(String messageId) async {
    try {
      debugPrint('🗑️ [Chat] Deleting message: $messageId');
      final response = await _apiClient.delete(
        '${ApiConstants.chat}/messages/$messageId',
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('✅ [Chat] Message deleted successfully');
      } else {
        throw Exception('Failed to delete message: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Chat] Error deleting message: $e');
      rethrow;
    }
  }

  /// Report an AI message for review
  Future<void> reportMessage({
    String? messageId,
    required String category,
    String? reason,
    required String originalUserMessage,
    required String aiResponse,
  }) async {
    try {
      debugPrint('🚩 [Chat] Reporting message: category=$category');
      final response = await _apiClient.post(
        '${ApiConstants.chat}/report',
        data: {
          'message_id': messageId,
          'category': category,
          'reason': reason,
          'original_user_message': originalUserMessage,
          'ai_response': aiResponse,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ [Chat] Message reported successfully');
      } else {
        throw Exception('Failed to report message: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Chat] Error reporting message: $e');
      rethrow;
    }
  }

  /// Clear all chat history for a user
  Future<void> clearChatHistory(String userId) async {
    try {
      debugPrint('🗑️ [Chat] Clearing chat history for user: $userId');
      await _apiClient.delete('${ApiConstants.chat}/history/$userId');
    } catch (e) {
      debugPrint('❌ [Chat] Error clearing chat history: $e');
      // Don't rethrow - local clear already succeeded
    }
  }

  /// Toggle pin state on the server
  Future<void> toggleMessagePin(String messageId, bool isPinned) async {
    try {
      await _apiClient.patch(
        '${ApiConstants.chat}/messages/$messageId/pin',
        data: {'is_pinned': isPinned},
      );
    } catch (e) {
      debugPrint('❌ [Chat] Error toggling pin: $e');
    }
  }

  /// Upload video directly to backend for parallel S3 + Gemini processing.
  /// Returns {s3_key, public_url, gemini_file_name, mime_type}.
  Future<Map<String, dynamic>> uploadVideoForAnalysis({
    required File file,
    required String mimeType,
    Duration? duration,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      debugPrint('🎬 [Chat] Uploading video to backend for parallel S3+Gemini processing');
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
          contentType: DioMediaType.parse(mimeType),
        ),
        'media_type': 'video',
        if (duration != null) 'duration_seconds': duration.inSeconds.toString(),
      });

      final response = await _apiClient.post(
        '${ApiConstants.chat}/media/upload',
        data: formData,
        options: Options(
          receiveTimeout: const Duration(minutes: 5),
          sendTimeout: const Duration(minutes: 5),
        ),
        onSendProgress: onProgress,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('✅ [Chat] Video upload complete: s3_key=${data['s3_key']}, gemini=${data['gemini_file_name']}');
        return data;
      }
      throw Exception('Video upload failed: ${response.statusCode}');
    } on DioException catch (e) {
      debugPrint('❌ [Chat] Error uploading video for analysis: $e');
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('Upload timed out. The file may be too large or your connection is slow.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Upload failed. Please check your internet connection.');
      }
      throw Exception('Failed to upload video. Please try again.');
    } catch (e) {
      debugPrint('❌ [Chat] Error uploading video for analysis: $e');
      rethrow;
    }
  }
}
