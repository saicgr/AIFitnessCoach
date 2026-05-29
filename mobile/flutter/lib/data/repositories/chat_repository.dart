import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/exercise_tip_service.dart';
import '../../core/theme/theme_provider.dart';
import '../../navigation/app_router.dart';
import '../../screens/ai_settings/ai_settings_screen.dart';
import '../../screens/chat/widgets/media_picker_helper.dart';
import '../../core/providers/sound_preferences_provider.dart';
import '../services/haptic_service.dart';
import '../../services/offline_coach_service.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../../core/models/meal_context.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/connectivity_service.dart';
import '../services/health_service.dart';
import '../services/data_cache_service.dart';
import '../services/recipe_notification_router.dart';
import '../providers/audio_preferences_provider.dart';
import '../providers/hormonal_health_provider.dart';
import '../providers/today_workout_provider.dart';
import '../providers/unified_state_provider.dart';
import 'workout_repository.dart';
import 'auth_repository.dart';
import 'hydration_repository.dart';
import 'nutrition_repository.dart';

part 'chat_repository_part_chat_messages_notifier.dart';
part 'chat_repository_part_chat_messages_notifier_ext.dart';
part 'chat_repository_part_chat_sessions_notifier.dart';


/// Chat repository provider
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ChatRepository(apiClient);
});

/// The active chat-session id for the "Ask Coach" screen.
///
/// `null` = a brand-new, not-yet-sent chat (the session is created
/// server-side on the first /send and ADOPTED here from the response). The
/// chat notifier reads this to scope its disk cache key + loadHistory, and
/// writes it on adoption / switchToSession / startNewChat.
///
/// NB: the [ChatMessagesNotifier] is NOT rebuilt when this changes — the
/// notifier mutates its own `_currentSessionId` field in lockstep so the
/// message list state survives a session switch.
final currentChatSessionProvider = StateProvider<String?>((ref) => null);

/// Lists the user's chat sessions for the history screen. Instant from
/// DataCacheService cache, then silently refreshed (feedback_instant_data).
final chatSessionsProvider =
    StateNotifierProvider<ChatSessionsNotifier, AsyncValue<List<ChatSession>>>(
        (ref) {
  final repository = ref.watch(chatRepositoryProvider);
  final apiClient = ref.watch(apiClientProvider);
  ref.watch(authStateProvider.select((s) => s.user?.id));
  return ChatSessionsNotifier(repository, apiClient);
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
  // Same callback pattern as the others — captures `ref` so the AI completion
  // handler can flip /today's cache without holding a notifier reference that
  // would break the dispose lifecycle.
  void refreshTodayWorkout() {
    ref.read(todayWorkoutProvider.notifier).invalidateAndRefresh();
    // Phase 6 — a chat-logged activity / sauna changes today's burned
    // calories; invalidate so the home flame icon re-fetches immediately.
    final uid = ref.read(authStateProvider).user?.id;
    if (uid != null) {
      ref.invalidate(aiBurnedCaloriesProvider(uid));
    }
  }
  // Phase F — the cycle agent's action tools mutate the backend; this
  // callback invalidates the cycle providers so a live Cycle screen / home
  // card repaints. Captures `ref` instead of holding notifier references.
  void refreshCycleData() {
    ref.invalidate(cyclePredictionProvider);
    ref.invalidate(cyclePeriodsProvider);
    ref.invalidate(cycleRawLogsProvider);
    ref.invalidate(cycleAiInsightProvider);
    ref.invalidate(hormonalProfileProvider);
    ref.invalidate(todayHormoneLogProvider);
  }
  final notifier = ChatMessagesNotifier(repository, apiClient, workoutsNotifier, workoutRepository, user, themeNotifier, router, hydrationNotifier, nutritionNotifier, getAISettings, setAIGenerating, getUnifiedContext, offlineCoach, isOnline, getSoundPrefs, getAudioPrefs, refreshTodayWorkout, refreshCycleData);
  // Session wiring — let the notifier publish an adopted/switched session id
  // to currentChatSessionProvider and refresh the sessions list when a new
  // session is created on first send.
  notifier.bindSessionHooks(
    onSessionChanged: (sessionId) =>
        ref.read(currentChatSessionProvider.notifier).state = sessionId,
    refreshSessions: () => ref.read(chatSessionsProvider.notifier).refresh(),
  );
  // Seed the notifier with whatever session is currently selected (e.g. the
  // history screen set it before popping back to chat).
  notifier.primeSessionId(ref.read(currentChatSessionProvider));
  return notifier;
});

/// A single decoded event off the `POST /chat/send-stream` SSE stream.
///
/// The backend emits four event shapes (see BACKEND CONTRACT):
///   - `token`    → incremental text chunk in [delta] (append live)
///   - `action`   → an action card payload in [actionData]
///   - `done`     → final reconciliation: [messageId] + full [content] + [metadata]
///   - `error`    → fatal stream error with a human-readable [message]
///
/// `progress` is also tolerated (uploading/analyzing/generating [phase] hints)
/// so the existing typing-state UI can surface backend-side progress (C5).
class ChatStreamEvent {
  /// Event kind: token / action / done / error / progress.
  final String type;

  /// Incremental text chunk — present on `token` events.
  final String? delta;

  /// Action card payload — present on `action` events.
  final Map<String, dynamic>? actionData;

  /// Server-issued stable assistant-message UUID — present on `done`.
  final String? messageId;

  /// Full reconciled reply text — present on `done`.
  final String? content;

  /// Optional metadata bag (intent, agent_type, …) — present on `done`.
  final Map<String, dynamic>? metadata;

  /// Human-readable failure message — present on `error`.
  final String? message;

  /// Typing-phase hint (uploading/analyzing/generating) — present on `progress`.
  final String? phase;

  /// Server-issued session id — present on the terminal `done` event. On a
  /// brand-new chat (sent with null session_id) this is the id the client
  /// must ADOPT for all subsequent turns in the conversation.
  final String? sessionId;

  const ChatStreamEvent({
    required this.type,
    this.delta,
    this.actionData,
    this.messageId,
    this.content,
    this.metadata,
    this.message,
    this.phase,
    this.sessionId,
  });
}

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
        // Presign uses media-tier timeouts so a slow connect during the
        // initial handshake doesn't surface as the user-visible "Request
        // timed out" error before we even reach S3.
        options: Options(
          receiveTimeout: ApiConstants.mediaUploadTimeout,
          sendTimeout: ApiConstants.mediaUploadConnectTimeout,
        ),
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
                 e.type == DioExceptionType.receiveTimeout ||
                 e.type == DioExceptionType.sendTimeout) {
        throw Exception('Upload taking longer than usual on this network. Try again on stronger Wi-Fi or LTE.');
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
        options: Options(
          receiveTimeout: ApiConstants.mediaUploadTimeout,
          sendTimeout: ApiConstants.mediaUploadConnectTimeout,
        ),
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
                 e.type == DioExceptionType.receiveTimeout ||
                 e.type == DioExceptionType.sendTimeout) {
        throw Exception('Upload taking longer than usual on this network. Try again on stronger Wi-Fi or LTE.');
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

  /// Fetch the lightweight meal-context summary used by the AI-Coach popup
  /// on the meal-log sheet. Returns remaining macros, today's workout,
  /// favorites preview, etc. A failure throws — callers should fall back
  /// to generic pills with a "partial context" banner.
  Future<MealContext> fetchMealContext({
    String? mealType,
    required String timezone,
  }) async {
    final response = await _apiClient.get(
      '${ApiConstants.chat}/meal-context',
      queryParameters: {
        if (mealType != null && mealType.isNotEmpty) 'meal_type': mealType,
        'tz': timezone,
      },
    );
    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      return MealContext.fromJson(response.data as Map<String, dynamic>);
    }
    throw Exception('Failed to load meal context (HTTP ${response.statusCode})');
  }

  /// Send a message to the AI coach
  ///
  /// [agentOverride] lets contextual widgets force a specific agent (e.g. the
  /// nutrition meal-log AI Coach card passes `'nutrition'` so every prompt is
  /// guaranteed to reach the Nutrition agent regardless of intent classifier
  /// output). Must be a valid `AgentType` value server-side.
  /// Send a chat message to the backend.
  ///
  /// Returns a record carrying:
  ///   - [response]: parsed [ChatResponse] (existing public contract).
  ///   - [messageId]: stable assistant-message UUID generated server-side.
  ///     Callers MUST use this as the local id of the assistant bubble so
  ///     a subsequent loadHistory/Realtime fetch can dedup by id (UPSERT)
  ///     instead of appending the same reply twice.
  ///
  /// `messageId` may be null if the backend is older than 2026-04-27 — in
  /// that case dedup falls back to content+timestamp matching at the call
  /// site (existing behavior).
  Future<({ChatResponse response, String? messageId, String? sessionId})> sendMessage({
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
    String? agentOverride,
    String? sessionId,
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
      if (agentOverride != null) {
        debugPrint('🎯 [Chat] agent_override=$agentOverride (bypassing classifier)');
      }
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
          agentOverride: agentOverride,
          sessionId: sessionId,
        ).toJson(),
        // Media requests go through Gemini Vision — allow up to 3 minutes
        options: Options(receiveTimeout: hasMedia ? const Duration(minutes: 3) : ApiConstants.aiReceiveTimeout),
      );

      if (response.statusCode == 200) {
        final jsonData = response.data as Map<String, dynamic>;
        debugPrint('🔍 [Chat] Raw response JSON: $jsonData');
        debugPrint('🔍 [Chat] agent_type in JSON: ${jsonData['agent_type']}');
        debugPrint('🔍 [Chat] action_data in JSON: ${jsonData['action_data']}');
        final chatResponse = ChatResponse.fromJson(jsonData);
        // Read message_id directly from the raw envelope — it isn't part of
        // the @JsonSerializable ChatResponse model (kept off the model so we
        // don't have to regenerate the .g.dart files; build_runner is
        // forbidden in this repo per project_codegen_gotcha.md).
        final messageId = jsonData['message_id'] as String?;
        // Session adoption — the server creates a session on a brand-new chat
        // (null session_id) and echoes its id here; callers must adopt it.
        final returnedSessionId = jsonData['session_id'] as String?;
        debugPrint('✅ [Chat] Got response with intent: ${chatResponse.intent}, agentType: ${chatResponse.agentType}, actionData: ${chatResponse.actionData}, messageId=$messageId, sessionId=$returnedSessionId');
        return (response: chatResponse, messageId: messageId, sessionId: returnedSessionId);
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

  /// Send a chat message and consume the AI reply as a token-by-token SSE
  /// stream from `POST /chat/send-stream`.
  ///
  /// Yields a [ChatStreamEvent] for each decoded `data:` line. The caller
  /// (ChatMessagesNotifier) is responsible for appending a placeholder
  /// assistant bubble on the first `token`, appending each `delta` to it so
  /// the reply types out live, and reconciling on `done`.
  ///
  /// This method NEVER falls back to the non-streaming path itself — if the
  /// stream fails the error surfaces to the caller, which decides whether to
  /// retry via the legacy [sendMessage]. Keeping the two paths separate means
  /// a mid-stream drop can preserve partial text (C2) instead of silently
  /// restarting a fresh blocking request.
  Stream<ChatStreamEvent> sendMessageStreaming({
    required String message,
    required String userId,
    Map<String, dynamic>? userProfile,
    Map<String, dynamic>? currentWorkout,
    Map<String, dynamic>? workoutSchedule,
    List<Map<String, dynamic>>? conversationHistory,
    Map<String, dynamic>? aiSettings,
    String? unifiedContext,
    String? agentOverride,
    String? sessionId,
  }) async* {
    debugPrint('🔌 [Chat] Opening streaming send: ${message.substring(0, message.length.clamp(0, 50))}...');

    // Dedicated Dio for the SSE stream — mirrors the workout-regeneration
    // streaming pattern. We cannot reuse the shared ApiClient instance because
    // it sets a JSON-decoding ResponseType; the stream needs raw bytes.
    final streamingDio = Dio(BaseOptions(
      baseUrl: _apiClient.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      // LangGraph multi-agent replies can run long; the per-token cadence
      // resets the receive timer, so 3 minutes is a generous ceiling.
      receiveTimeout: const Duration(minutes: 3),
      headers: {
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
      },
    ));

    // Carry over the auth headers from the shared client (Supabase JWT etc.).
    final authHeaders = await _apiClient.getAuthHeaders();
    streamingDio.options.headers.addAll(authHeaders);

    final response = await streamingDio.post(
      '${ApiConstants.chat}/send-stream',
      data: ChatRequest(
        message: message,
        userId: userId,
        userProfile: userProfile,
        currentWorkout: currentWorkout,
        workoutSchedule: workoutSchedule,
        conversationHistory: conversationHistory,
        aiSettings: aiSettings,
        unifiedContext: unifiedContext,
        agentOverride: agentOverride,
        sessionId: sessionId,
      ).toJson(),
      options: Options(responseType: ResponseType.stream),
    );

    final responseBody = response.data as ResponseBody;

    // SSE framing: events are separated by a blank line; each event is a set
    // of `field: value` lines. We only care about `data:` lines here (the
    // backend encodes the event kind inside the JSON `type` field, not the
    // SSE `event:` field), but we still buffer across chunk boundaries so a
    // `data:` line split mid-byte isn't dropped.
    String buffer = '';
    final dataLines = <String>[];

    ChatStreamEvent? _decode(String jsonText) {
      try {
        final obj = jsonDecode(jsonText) as Map<String, dynamic>;
        final type = obj['type'] as String? ?? 'unknown';
        return ChatStreamEvent(
          type: type,
          delta: obj['delta'] as String?,
          actionData: obj['action_data'] is Map
              ? (obj['action_data'] as Map).cast<String, dynamic>()
              : null,
          messageId: obj['message_id'] as String?,
          content: obj['content'] as String?,
          metadata: obj['metadata'] is Map
              ? (obj['metadata'] as Map).cast<String, dynamic>()
              : null,
          message: obj['message'] as String?,
          phase: obj['phase'] as String?,
          sessionId: obj['session_id'] as String?,
        );
      } catch (e) {
        debugPrint('⚠️ [Chat] Failed to decode SSE data line: $e');
        return null;
      }
    }

    await for (final bytes in responseBody.stream) {
      buffer += utf8.decode(bytes, allowMalformed: true);

      while (buffer.contains('\n')) {
        final newlineIndex = buffer.indexOf('\n');
        final line = buffer.substring(0, newlineIndex).replaceAll('\r', '');
        buffer = buffer.substring(newlineIndex + 1);

        if (line.isEmpty) {
          // Blank line — event boundary. Join multi-line `data:` payloads.
          if (dataLines.isNotEmpty) {
            final jsonText = dataLines.join('\n').trim();
            dataLines.clear();
            if (jsonText.isNotEmpty && jsonText != '[DONE]') {
              final ev = _decode(jsonText);
              if (ev != null) yield ev;
            }
          }
          continue;
        }

        if (line.startsWith('data:')) {
          dataLines.add(line.substring(5).trimLeft());
        }
        // `event:` / `id:` / `:` comment lines are intentionally ignored.
      }
    }

    // Flush any trailing event that arrived without a closing blank line.
    if (dataLines.isNotEmpty) {
      final jsonText = dataLines.join('\n').trim();
      if (jsonText.isNotEmpty && jsonText != '[DONE]') {
        final ev = _decode(jsonText);
        if (ev != null) yield ev;
      }
    }
    debugPrint('🔌 [Chat] Streaming send closed cleanly');
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

  /// Apply a workout change the AI has proposed in chat.
  ///
  /// Returns the raw response map from the backend so callers can react to
  /// the applied mutation (e.g. refresh providers). Throws on any non-2xx
  /// except the "soft failure" case where status==200 but success==false.
  Future<Map<String, dynamic>> applyProposal({
    required String proposalId,
    required String proposalToken,
  }) async {
    try {
      debugPrint('🎯 [Chat] Applying proposal $proposalId');
      final response = await _apiClient.post(
        '${ApiConstants.chat}/proposals/$proposalId/apply',
        data: {'proposal_token': proposalToken},
      );
      final data = (response.data as Map).cast<String, dynamic>();
      debugPrint('✅ [Chat] Proposal apply result: success=${data['success']}');
      return data;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      debugPrint('❌ [Chat] Apply proposal failed: HTTP $status - ${e.message}');
      // Re-throw so the card can map 409/410 to distinct UI states.
      rethrow;
    } catch (e) {
      debugPrint('❌ [Chat] Apply proposal error: $e');
      rethrow;
    }
  }

  /// Dismiss a pending proposal. Fire-and-forget from the UI — the user
  /// tapped "Not now" and we mark the row dismissed server-side.
  Future<void> dismissProposal({
    required String proposalId,
    required String proposalToken,
  }) async {
    try {
      debugPrint('👋 [Chat] Dismissing proposal $proposalId');
      await _apiClient.post(
        '${ApiConstants.chat}/proposals/$proposalId/dismiss',
        data: {'proposal_token': proposalToken},
      );
    } catch (e) {
      // Dismiss is best-effort — if it fails the row just sits pending until
      // it expires. Don't surface the error to the user.
      debugPrint('⚠️ [Chat] Dismiss proposal error (ignored): $e');
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

  // ── Chat sessions (conversation list, like ChatGPT/Gemini) ────────────

  /// List the user's chat sessions, newest activity first.
  ///
  /// [q] searches title + message content; [includeArchived] surfaces
  /// archived threads too. Rethrows on failure (no silent fallback).
  Future<List<ChatSession>> listSessions({
    String? q,
    bool includeArchived = false,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.coachSessions,
        queryParameters: {
          if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
          'include_archived': includeArchived,
          'limit': limit,
          'offset': offset,
        },
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = (data['items'] as List? ?? const [])
            .map((j) => ChatSession.fromJson(j as Map<String, dynamic>))
            .toList();
        debugPrint('✅ [Chat] Listed ${items.length} sessions (q=$q, archived=$includeArchived)');
        return items;
      }
      throw Exception('Failed to list sessions: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [Chat] Error listing sessions: $e');
      rethrow;
    }
  }

  /// Convenience: search sessions by query string.
  Future<List<ChatSession>> searchSessions(String q, {int limit = 50}) =>
      listSessions(q: q, limit: limit);

  /// Create a brand-new session up-front. NOTE: the normal flow does NOT
  /// call this — a session is created server-side on the first /send with a
  /// null session_id. Exposed for completeness / explicit "new chat" needs.
  Future<ChatSession> createSession({String? title}) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.coachSessions,
        data: {if (title != null) 'title': title},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ChatSession.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to create session: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [Chat] Error creating session: $e');
      rethrow;
    }
  }

  /// Fetch a single session item.
  Future<ChatSession> getSession(String sessionId) async {
    try {
      final response = await _apiClient.get(ApiConstants.coachSessionItem(sessionId));
      if (response.statusCode == 200) {
        return ChatSession.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to load session: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [Chat] Error loading session $sessionId: $e');
      rethrow;
    }
  }

  /// Load a single session's messages (oldest first).
  ///
  /// The endpoint returns raw `chat_history` rows where EACH row holds a
  /// `user_message` + an `ai_response`. We expand each row into two
  /// [ChatMessage]s (a user turn followed by the assistant turn) so the
  /// chat UI renders them exactly like a live conversation. Media / audio /
  /// pin / source metadata is preserved on the appropriate turn.
  Future<List<ChatMessage>> getSessionMessages(
    String sessionId, {
    int limit = 200,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.coachSessionMessages(sessionId),
        queryParameters: {'limit': limit, 'offset': offset},
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final rows = (data['messages'] as List? ?? const [])
            .cast<Map<String, dynamic>>();
        final messages = <ChatMessage>[];
        for (final row in rows) {
          final id = row['id']?.toString();
          final userId = row['user_id']?.toString();
          final ts = row['timestamp']?.toString();
          final userMsg = (row['user_message'] as String?)?.trim() ?? '';
          final aiMsg = (row['ai_response'] as String?)?.trim() ?? '';
          final isPinned = (row['is_pinned'] as bool?) ?? false;
          final audioUrl = row['audio_url'] as String?;
          final audioDurationMs = (row['audio_duration_ms'] as num?)?.toInt();
          final mediaUrl = row['media_url'] as String?;
          final mediaType = row['media_type'] as String?;
          final sourceSurface = row['source_surface'] as String?;
          final insightId = row['insight_id'] as String?;
          final contextJson = row['context_json'];
          final actionData = contextJson is Map
              ? contextJson.cast<String, dynamic>()
              : null;

          if (userMsg.isNotEmpty) {
            messages.add(ChatMessage(
              id: id != null ? '${id}_u' : null,
              userId: userId,
              role: 'user',
              content: userMsg,
              createdAt: ts,
              mediaUrl: mediaUrl,
              mediaType: mediaType,
              audioUrl: audioUrl,
              audioDurationMs: audioDurationMs,
              sourceSurface: sourceSurface,
              insightId: insightId,
            ));
          }
          if (aiMsg.isNotEmpty) {
            messages.add(ChatMessage(
              id: id,
              userId: userId,
              role: 'assistant',
              content: aiMsg,
              createdAt: ts,
              actionData: actionData,
              isPinned: isPinned,
              sourceSurface: sourceSurface,
              insightId: insightId,
            ));
          }
        }
        debugPrint('✅ [Chat] Loaded ${messages.length} messages for session $sessionId');
        return messages;
      }
      throw Exception('Failed to load session messages: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [Chat] Error loading session messages ($sessionId): $e');
      rethrow;
    }
  }

  /// Rename a session.
  Future<ChatSession> renameSession(String sessionId, String title) async {
    try {
      final response = await _apiClient.patch(
        ApiConstants.coachSessionItem(sessionId),
        data: {'title': title},
      );
      if (response.statusCode == 200) {
        return ChatSession.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to rename session: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [Chat] Error renaming session $sessionId: $e');
      rethrow;
    }
  }

  /// Archive / unarchive a session.
  Future<ChatSession> archiveSession(String sessionId, bool isArchived) async {
    try {
      final response = await _apiClient.patch(
        ApiConstants.coachSessionItem(sessionId),
        data: {'is_archived': isArchived},
      );
      if (response.statusCode == 200) {
        return ChatSession.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to archive session: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [Chat] Error archiving session $sessionId: $e');
      rethrow;
    }
  }

  /// Delete a session (cascades its messages server-side).
  Future<void> deleteSession(String sessionId) async {
    try {
      final response = await _apiClient.delete(ApiConstants.coachSessionItem(sessionId));
      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('🗑️ [Chat] Deleted session $sessionId');
        return;
      }
      throw Exception('Failed to delete session: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [Chat] Error deleting session $sessionId: $e');
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
