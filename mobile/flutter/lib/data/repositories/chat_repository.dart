import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/theme_provider.dart';
import '../../navigation/app_router.dart';
import '../../screens/ai_settings/ai_settings_screen.dart';
import '../../screens/chat/widgets/media_picker_helper.dart';
import '../../services/offline_coach_service.dart';
import '../models/chat_message.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/connectivity_service.dart';
import '../services/data_cache_service.dart';
import '../providers/unified_state_provider.dart';
import 'workout_repository.dart';
import 'auth_repository.dart';
import 'hydration_repository.dart';
import 'nutrition_repository.dart';

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
  final authState = ref.watch(authStateProvider);
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
  return ChatMessagesNotifier(repository, apiClient, workoutsNotifier, workoutRepository, authState.user, themeNotifier, router, hydrationNotifier, nutritionNotifier, getAISettings, setAIGenerating, getUnifiedContext, offlineCoach, isOnline);
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
    } catch (e) {
      debugPrint('❌ [Chat] Error getting batch presigned URLs: $e');
      rethrow;
    }
  }

  /// Upload a file directly to S3 using the presigned URL
  /// Uses a standalone Dio instance (not the API client) for direct S3 PUT
  Future<bool> uploadToS3({
    required String presignedUrl,
    required Map<String, dynamic>? fields,
    required File file,
    required String contentType,
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
        );
        debugPrint('✅ [Chat] S3 upload complete: ${response.statusCode}');
        return response.statusCode == 200 || response.statusCode == 204;
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
        );
        debugPrint('✅ [Chat] S3 upload complete: ${response.statusCode}');
        return response.statusCode == 200 || response.statusCode == 204;
      }
    } catch (e) {
      debugPrint('❌ [Chat] Error uploading to S3: $e');
      return false;
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
  }) async {
    try {
      debugPrint('🔍 [Chat] Sending message: ${message.substring(0, message.length.clamp(0, 50))}...');
      if (aiSettings != null) {
        debugPrint('🤖 [Chat] AI settings: ${aiSettings['coaching_style']}, ${aiSettings['communication_tone']}');
      }
      if (unifiedContext != null) {
        debugPrint('🎯 [Chat] Including unified fasting/nutrition/workout context');
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
        ).toJson(),
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
      rethrow;
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
}

/// Chat messages state notifier
class ChatMessagesNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final ChatRepository _repository;
  final ApiClient _apiClient;
  final WorkoutsNotifier _workoutsNotifier;
  final WorkoutRepository _workoutRepository;
  final User? _user;
  final ThemeModeNotifier _themeNotifier;
  final GoRouter _router;
  final HydrationNotifier _hydrationNotifier;
  final NutritionNotifier _nutritionNotifier;
  final AISettings Function() _getAISettings; // Callback to get fresh settings
  final void Function(bool) _setAIGenerating; // Callback to set AI generating state
  final String Function() _getUnifiedContext; // Callback to get unified fasting/nutrition/workout context
  final OfflineCoachService _offlineCoach;
  final bool Function() _isOnline;
  bool _isLoading = false;

  /// Keywords that indicate user wants a quick workout (mirrors backend)
  static const _quickWorkoutKeywords = [
    'quick workout', 'short workout', 'fast workout',
    'quick exercise', 'something quick', 'something fast',
    '15 minute', '10 minute', '20 minute', '5 minute', '30 minute',
    'give me a quick', 'create a quick', 'need a quick', 'want a quick',
    'no time', 'short on time', 'in a hurry',
    'generate a workout', 'create a workout', 'make me a workout',
    'new workout', 'different workout',
    'cardio workout', 'hiit workout', 'bodyweight workout',
    'upper body workout', 'lower body workout', 'core workout',
    'leg workout', 'arm workout', 'chest workout', 'back workout',
    // Sport-specific workout types
    'boxing workout', 'boxing training', 'boxer workout',
    'hyrox workout', 'hyrox training', 'train for hyrox',
    'crossfit workout', 'crossfit wod', 'wod',
    'mma workout', 'mma training', 'martial arts workout', 'fighter workout',
    'tabata workout', 'interval workout', 'circuit workout',
    'strength workout', 'strength training',
    'endurance workout', 'endurance training',
    'flexibility workout', 'stretching workout', 'yoga workout',
    'mobility workout', 'mobility training',
    // Sport mentions
    'want to box', 'want to be a boxer', 'train like a boxer',
    'want to do hyrox', 'hyrox athlete',
    'want to do crossfit', 'train like crossfit',
    'train like a fighter', 'want to fight',
  ];

  ChatMessagesNotifier(this._repository, this._apiClient, this._workoutsNotifier, this._workoutRepository, this._user, this._themeNotifier, this._router, this._hydrationNotifier, this._nutritionNotifier, this._getAISettings, this._setAIGenerating, this._getUnifiedContext, this._offlineCoach, this._isOnline)
      : super(const AsyncValue.data([]));

  bool get isLoading => _isLoading;

  /// Build the cache key for chat history for a given user
  static String _cacheKey(String userId) => 'cache_chat_history_$userId';

  /// Load cached chat messages from DataCacheService
  Future<List<ChatMessage>> _loadFromCache(String userId) async {
    try {
      final cached = await DataCacheService.instance.getCachedList(_cacheKey(userId));
      if (cached != null && cached.isNotEmpty) {
        final messages = cached.map((json) => ChatMessage.fromJson(json)).toList();
        debugPrint('💾 [Chat] Loaded ${messages.length} messages from cache');
        return messages;
      }
    } catch (e) {
      debugPrint('❌ [Chat] Error loading from cache: $e');
    }
    return [];
  }

  /// Save chat messages to DataCacheService
  Future<void> _saveToCache(String userId, List<ChatMessage> messages) async {
    try {
      final jsonList = messages.map((m) => m.toJson()).toList();
      await DataCacheService.instance.cacheList(_cacheKey(userId), jsonList);
      debugPrint('💾 [Chat] Saved ${messages.length} messages to cache');
    } catch (e) {
      debugPrint('❌ [Chat] Error saving to cache: $e');
    }
  }

  /// Load chat history with cache-first pattern
  /// If force is false, only loads if there are no messages yet
  Future<void> loadHistory({bool force = false}) async {
    // Skip loading if we already have messages and not forcing
    final currentMessages = state.valueOrNull;
    if (!force && currentMessages != null && currentMessages.isNotEmpty) {
      debugPrint('🔍 [Chat] Skipping history load - already have ${currentMessages.length} messages');
      return;
    }

    final userId = await _apiClient.getUserId();
    if (userId == null) return;

    // 1. Load from cache first and show immediately
    final cachedMessages = await _loadFromCache(userId);
    if (cachedMessages.isNotEmpty) {
      state = AsyncValue.data(cachedMessages);
      debugPrint('🔍 [Chat] Showing ${cachedMessages.length} cached messages while fetching fresh data');
    } else {
      state = const AsyncValue.loading();
    }

    // 2. Fetch fresh data from API in background
    try {
      final messages = await _repository.getChatHistory(userId);
      state = AsyncValue.data(messages);
      // 3. Update cache with fresh data
      await _saveToCache(userId, messages);
    } catch (e, st) {
      // If we have cached data, keep showing it instead of error
      if (cachedMessages.isNotEmpty) {
        debugPrint('⚠️ [Chat] API fetch failed, keeping cached data: $e');
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  /// Send a message
  Future<void> sendMessage(String message) async {
    if (_isLoading) {
      debugPrint('⚠️ [Chat] Already loading, ignoring message');
      return;
    }

    final userId = await _apiClient.getUserId();
    if (userId == null) {
      debugPrint('❌ [Chat] No user ID - user not authenticated');
      // Add error message so user sees something
      final errorMessage = ChatMessage(
        role: 'assistant',
        content: 'Please sign in to chat with your AI Coach.',
        createdAt: DateTime.now().toIso8601String(),
      );
      final currentMessages = state.valueOrNull ?? [];
      state = AsyncValue.data([...currentMessages, errorMessage]);
      return;
    }

    final currentMessages = state.valueOrNull ?? [];

    // Add user message immediately
    final userMessage = ChatMessage(
      role: 'user',
      content: message,
      createdAt: DateTime.now().toIso8601String(),
    );
    final messagesWithUser = [...currentMessages, userMessage];
    state = AsyncValue.data(messagesWithUser);

    // Incrementally append user message to cache
    _saveToCache(userId, messagesWithUser);

    // --- OFFLINE ROUTING ---
    if (!_isOnline()) {
      if (_offlineCoach.isAvailable) {
        // Inject system notification on first offline message
        final hasOfflineNotification = currentMessages.any((m) =>
            m.role == 'system' && m.content.contains('Offline Mode'));
        if (!hasOfflineNotification) {
          final offlineNotification = ChatMessage(
            role: 'system',
            content: 'Offline Mode — Using local AI. Features like workout generation, nutrition logging, and exercise library lookup are not available. Send a message to get started.',
            createdAt: DateTime.now().toIso8601String(),
          );
          final withNotification = [...messagesWithUser, offlineNotification];
          state = AsyncValue.data(withNotification);
        }
        await _sendOfflineMessage(message, userId);
        return;
      } else {
        // No model loaded, show error
        final errorMessage = ChatMessage(
          role: 'assistant',
          content: 'AI Coach needs an internet connection or a downloaded AI model to respond. Go to Settings \u2192 Offline Mode to download a model.',
          createdAt: DateTime.now().toIso8601String(),
        );
        state = AsyncValue.data([...messagesWithUser, errorMessage]);
        return;
      }
    }
    // --- END OFFLINE ROUTING ---

    _isLoading = true;

    // Check if this looks like a quick workout request
    final messageLower = message.toLowerCase();
    final isQuickWorkoutRequest = _quickWorkoutKeywords.any((kw) => messageLower.contains(kw));
    if (isQuickWorkoutRequest) {
      _setAIGenerating(true);
      debugPrint('🏋️ [Chat] Quick workout request detected - setting loading state');
    }

    try {
      // Build conversation history for context
      final history = currentMessages.map((m) => {
        'role': m.role,
        'content': m.content,
      }).toList();

      // Build user profile context (matches backend UserProfile model)
      Map<String, dynamic>? userProfile;
      if (_user != null) {
        final user = _user;
        userProfile = {
          'id': user.id,  // Required by backend
          'fitness_level': user.fitnessLevel ?? 'beginner',
          'goals': user.goalsList,
          'equipment': user.equipmentList,
          'active_injuries': user.injuriesList,
        };
        debugPrint('🤖 [Chat] Sending user profile context: $userProfile');
      }

      // Build current workout context (matches backend WorkoutContext model)
      Map<String, dynamic>? currentWorkout;
      final nextWorkout = _workoutsNotifier.nextWorkout;
      if (nextWorkout != null) {
        final exercisesList = nextWorkout.exercises.map((e) {
          return <String, dynamic>{
            'name': e.name,
            'sets': e.sets,
            'reps': e.reps,
            'duration_seconds': e.durationSeconds,
            'muscle_group': e.muscleGroup,
            'equipment': e.equipment,
          };
        }).toList();

        currentWorkout = {
          'id': nextWorkout.id is int ? nextWorkout.id : int.tryParse(nextWorkout.id.toString()) ?? 0,
          'name': nextWorkout.name ?? 'Workout',
          'type': nextWorkout.type ?? 'strength',
          'difficulty': nextWorkout.difficulty ?? 'intermediate',
          'scheduled_date': nextWorkout.scheduledDate,
          'is_completed': nextWorkout.isCompleted ?? false,
          'exercises': exercisesList,
        };
        debugPrint('🤖 [Chat] Sending current workout context: ${nextWorkout.name} with ${exercisesList.length} exercises');
      }

      // Build workout schedule context (matches backend WorkoutScheduleContext)
      Map<String, dynamic>? workoutSchedule;
      final upcoming = _workoutsNotifier.upcomingWorkouts;
      // Only send schedule if we have today's workout
      if (nextWorkout != null) {
        final thisWeekWorkouts = upcoming.take(5).map((w) {
          return <String, dynamic>{
            'id': w.id is int ? w.id : int.tryParse(w.id.toString()) ?? 0,
            'name': w.name ?? 'Workout',
            'type': w.type ?? 'strength',
            'difficulty': w.difficulty ?? 'intermediate',
            'scheduled_date': w.scheduledDate,
            'is_completed': w.isCompleted ?? false,
            'exercises': <Map<String, dynamic>>[],
          };
        }).toList();

        workoutSchedule = {
          'today': currentWorkout,
          'thisWeek': thisWeekWorkouts,
          'recentCompleted': <Map<String, dynamic>>[],
        };
      }

      // Get fresh AI settings on each message (not stale cached settings)
      final currentAISettings = _getAISettings();
      debugPrint('🤖 [Chat] Using fresh AI settings: ${currentAISettings.coachingStyle}, ${currentAISettings.communicationTone}');

      // Get unified fasting/nutrition/workout context
      final unifiedContext = _getUnifiedContext();
      debugPrint('🎯 [Chat] Unified context length: ${unifiedContext.length} chars');

      final response = await _repository.sendMessage(
        message: message,
        userId: userId,
        userProfile: userProfile,
        currentWorkout: currentWorkout,
        workoutSchedule: workoutSchedule,
        conversationHistory: history,
        aiSettings: currentAISettings.toJson(),
        unifiedContext: unifiedContext,
      );

      // Process action_data if present (await to ensure refresh completes)
      await _processActionData(response.actionData);

      // Debug logging for action_data (helps trace "Go to Workout" button issues)
      if (response.actionData != null) {
        debugPrint('🎯 [Chat] Response has action_data: ${response.actionData}');
        debugPrint('🎯 [Chat] action_data[action]: ${response.actionData!['action']}');
        debugPrint('🎯 [Chat] action_data[workout_id]: ${response.actionData!['workout_id']}');
      } else {
        debugPrint('🔍 [Chat] Response has no action_data');
      }

      // Add assistant response with agent type AND action_data (for "Go to Workout" button)
      final assistantMessage = ChatMessage(
        role: 'assistant',
        content: response.message,
        intent: response.intent,
        agentType: response.agentType,
        createdAt: DateTime.now().toIso8601String(),
        actionData: response.actionData, // Include action_data for UI buttons
      );

      // Debug: Check if hasGeneratedWorkout will be true
      debugPrint('🎯 [Chat] assistantMessage.hasGeneratedWorkout: ${assistantMessage.hasGeneratedWorkout}');
      if (assistantMessage.hasGeneratedWorkout) {
        debugPrint('✅ [Chat] "Go to Workout" button should appear! workoutId: ${assistantMessage.workoutId}');
      }

      final updatedMessages = state.valueOrNull ?? [];
      final newMessages = [...updatedMessages, assistantMessage];
      state = AsyncValue.data(newMessages);

      // Incrementally update cache with new messages (append, don't re-fetch)
      await _saveToCache(userId, newMessages);
    } catch (e, stackTrace) {
      debugPrint('❌ [Chat] Error sending message: $e');
      debugPrint('❌ [Chat] Stack trace: $stackTrace');

      // Surface the real error - don't mask it as an AI response
      final errorMessage = ChatMessage(
        role: 'error',
        content: e.toString(),
        createdAt: DateTime.now().toIso8601String(),
      );
      final updatedMessages = state.valueOrNull ?? [];
      state = AsyncValue.data([...updatedMessages, errorMessage]);
    } finally {
      _isLoading = false;
      // Reset AI generating state if it was set for quick workout request
      if (isQuickWorkoutRequest) {
        _setAIGenerating(false);
      }
    }
  }

  /// Send a message with media attachment (image or video).
  /// Orchestrates: compress -> presign -> upload to S3 -> send message with media_ref.
  Future<void> sendMessageWithMedia(String message, PickedMedia media) async {
    if (_isLoading) {
      debugPrint('⚠️ [Chat] Already loading, ignoring message');
      return;
    }

    final userId = await _apiClient.getUserId();
    if (userId == null) {
      debugPrint('❌ [Chat] No user ID - user not authenticated');
      return;
    }

    final currentMessages = state.valueOrNull ?? [];

    // Add user message immediately (with placeholder for media)
    final userMessage = ChatMessage(
      role: 'user',
      content: message.isNotEmpty ? message : (media.type == ChatMediaType.video ? 'Check my form' : 'What do you see?'),
      createdAt: DateTime.now().toIso8601String(),
      mediaType: media.type == ChatMediaType.video ? 'video' : 'image',
    );
    final messagesWithUser = [...currentMessages, userMessage];
    state = AsyncValue.data(messagesWithUser);

    _isLoading = true;

    try {
      // Step 1: Show upload progress system message
      final uploadMsg = ChatMessage(
        role: 'system',
        content: media.type == ChatMediaType.video
            ? 'Uploading video (${media.formattedSize})...'
            : 'Uploading image (${media.formattedSize})...',
        createdAt: DateTime.now().toIso8601String(),
      );
      state = AsyncValue.data([...messagesWithUser, uploadMsg]);

      // Step 2: Get presigned URL
      final filename = media.file.path.split('/').last;
      final presignData = await _repository.getPresignedUrl(
        filename: filename,
        contentType: media.mimeType,
        mediaType: media.type == ChatMediaType.video ? 'video' : 'image',
        expectedSizeBytes: media.sizeBytes,
      );

      final presignedUrl = presignData['presigned_url'] as String? ?? presignData['url'] as String;
      final s3Key = presignData['s3_key'] as String;
      final fields = presignData['fields'] as Map<String, dynamic>?;

      // Step 3: Upload to S3
      final uploadSuccess = await _repository.uploadToS3(
        presignedUrl: presignedUrl,
        fields: fields,
        file: media.file,
        contentType: media.mimeType,
      );

      if (!uploadSuccess) {
        throw Exception('Failed to upload media to storage');
      }

      // Step 4: Show analyzing system message
      final analyzingMsg = ChatMessage(
        role: 'system',
        content: media.type == ChatMediaType.video
            ? 'Analyzing your form...'
            : 'Analyzing image...',
        createdAt: DateTime.now().toIso8601String(),
      );
      // Remove upload msg, add analyzing msg
      final msgsAfterUpload = state.valueOrNull ?? [];
      final filteredMsgs = msgsAfterUpload.where((m) =>
          !(m.role == 'system' && (m.content.contains('Uploading') || m.content.contains('Analyzing')))).toList();
      state = AsyncValue.data([...filteredMsgs, analyzingMsg]);

      // Step 5: Build media_ref and send message
      final mediaRef = {
        's3_key': s3Key,
        'media_type': media.type == ChatMediaType.video ? 'video' : 'image',
        'content_type': media.mimeType,
        'filename': filename,
      };

      // Build conversation history
      final history = currentMessages.map((m) => {
        'role': m.role,
        'content': m.content,
      }).toList();

      // Build user profile
      Map<String, dynamic>? userProfile;
      if (_user != null) {
        userProfile = {
          'id': _user.id,
          'fitness_level': _user.fitnessLevel ?? 'beginner',
          'goals': _user.goalsList,
          'equipment': _user.equipmentList,
          'active_injuries': _user.injuriesList,
        };
      }

      final currentAISettings = _getAISettings();
      final unifiedContext = _getUnifiedContext();

      final response = await _repository.sendMessage(
        message: message.isNotEmpty ? message : (media.type == ChatMediaType.video ? 'Check my form' : 'What do you see?'),
        userId: userId,
        userProfile: userProfile,
        conversationHistory: history,
        aiSettings: currentAISettings.toJson(),
        unifiedContext: unifiedContext,
        mediaRef: mediaRef,
      );

      // Process action_data
      await _processActionData(response.actionData);

      // Remove system messages (upload/analyzing) and add the assistant response
      final finalMsgs = (state.valueOrNull ?? []).where((m) =>
          !(m.role == 'system' && (m.content.contains('Uploading') || m.content.contains('Analyzing')))).toList();

      final assistantMessage = ChatMessage(
        role: 'assistant',
        content: response.message,
        intent: response.intent,
        agentType: response.agentType,
        createdAt: DateTime.now().toIso8601String(),
        actionData: response.actionData,
      );

      final newMessages = [...finalMsgs, assistantMessage];
      state = AsyncValue.data(newMessages);

      await _saveToCache(userId, newMessages);
    } catch (e, stackTrace) {
      debugPrint('❌ [Chat] Error sending message with media: $e');
      debugPrint('❌ [Chat] Stack trace: $stackTrace');

      // Remove system messages, add error
      final errorMsgs = (state.valueOrNull ?? []).where((m) =>
          !(m.role == 'system' && (m.content.contains('Uploading') || m.content.contains('Analyzing')))).toList();

      final errorMessage = ChatMessage(
        role: 'error',
        content: 'Failed to send media: ${e.toString().replaceAll('Exception: ', '')}',
        createdAt: DateTime.now().toIso8601String(),
      );
      state = AsyncValue.data([...errorMsgs, errorMessage]);
    } finally {
      _isLoading = false;
    }
  }

  /// Send a message with multiple media attachments (images/videos).
  /// Orchestrates: batch presign -> parallel S3 upload -> send message with media_refs.
  Future<void> sendMessageWithMultiMedia(String message, List<PickedMedia> mediaList) async {
    if (_isLoading || mediaList.isEmpty) return;

    final userId = await _apiClient.getUserId();
    if (userId == null) {
      debugPrint('❌ [Chat] No user ID - user not authenticated');
      return;
    }

    final currentMessages = state.valueOrNull ?? [];

    // Determine default message based on media mix
    final hasVideo = mediaList.any((m) => m.type == ChatMediaType.video);
    final imageCount = mediaList.where((m) => m.type == ChatMediaType.image).length;
    String defaultMessage;
    if (hasVideo && mediaList.length > 1) {
      defaultMessage = 'Compare my form across these videos';
    } else if (hasVideo) {
      defaultMessage = 'Check my form';
    } else if (imageCount > 1) {
      defaultMessage = 'What do you see in these photos?';
    } else {
      defaultMessage = 'What do you see?';
    }
    final actualMessage = message.isNotEmpty ? message : defaultMessage;

    // Add user message immediately
    final userMessage = ChatMessage(
      role: 'user',
      content: actualMessage,
      createdAt: DateTime.now().toIso8601String(),
      mediaType: hasVideo ? 'video' : 'image',
    );
    final messagesWithUser = [...currentMessages, userMessage];
    state = AsyncValue.data(messagesWithUser);
    _saveToCache(userId, messagesWithUser);

    _isLoading = true;

    try {
      // Step 1: Upload progress message
      final uploadMsg = ChatMessage(
        role: 'system',
        content: 'Uploading ${mediaList.length} files...',
        createdAt: DateTime.now().toIso8601String(),
      );
      state = AsyncValue.data([...messagesWithUser, uploadMsg]);

      // Step 2: Get batch presigned URLs
      final fileSpecs = mediaList.map((m) => <String, dynamic>{
        'filename': m.file.path.split('/').last,
        'content_type': m.mimeType,
        'media_type': m.type == ChatMediaType.video ? 'video' : 'image',
        'expected_size_bytes': m.sizeBytes,
      }).toList();

      final presignedItems = await _repository.getBatchPresignedUrls(files: fileSpecs);

      // Step 3: Upload all to S3 in parallel
      final uploadFutures = <Future<bool>>[];
      for (int i = 0; i < mediaList.length; i++) {
        final media = mediaList[i];
        final presigned = presignedItems[i];
        uploadFutures.add(_repository.uploadToS3(
          presignedUrl: presigned['presigned_url'] as String,
          fields: presigned['presigned_fields'] as Map<String, dynamic>?,
          file: media.file,
          contentType: media.mimeType,
        ));
      }

      final uploadResults = await Future.wait(uploadFutures);
      if (uploadResults.any((success) => !success)) {
        throw Exception('Some files failed to upload');
      }

      // Step 4: Show analyzing message
      final analyzingMsg = ChatMessage(
        role: 'system',
        content: hasVideo ? 'Analyzing your form...' : 'Analyzing ${mediaList.length} images...',
        createdAt: DateTime.now().toIso8601String(),
      );
      final msgsAfterUpload = state.valueOrNull ?? [];
      final filteredMsgs = msgsAfterUpload.where((m) =>
          !(m.role == 'system' && (m.content.contains('Uploading') || m.content.contains('Analyzing')))).toList();
      state = AsyncValue.data([...filteredMsgs, analyzingMsg]);

      // Step 5: Build media_refs and send
      final mediaRefs = <Map<String, dynamic>>[];
      for (int i = 0; i < mediaList.length; i++) {
        final media = mediaList[i];
        mediaRefs.add({
          's3_key': presignedItems[i]['s3_key'] as String,
          'media_type': media.type == ChatMediaType.video ? 'video' : 'image',
          'mime_type': media.mimeType,
          if (media.duration != null) 'duration_seconds': media.duration!.inSeconds.toDouble(),
        });
      }

      // Build context
      final history = currentMessages.map((m) => {
        'role': m.role,
        'content': m.content,
      }).toList();

      Map<String, dynamic>? userProfile;
      if (_user != null) {
        userProfile = {
          'id': _user.id,
          'fitness_level': _user.fitnessLevel ?? 'beginner',
          'goals': _user.goalsList,
          'equipment': _user.equipmentList,
          'active_injuries': _user.injuriesList,
        };
      }

      final currentAISettings = _getAISettings();
      final unifiedContext = _getUnifiedContext();

      final response = await _repository.sendMessage(
        message: actualMessage,
        userId: userId,
        userProfile: userProfile,
        conversationHistory: history,
        aiSettings: currentAISettings.toJson(),
        unifiedContext: unifiedContext,
        mediaRefs: mediaRefs,
      );

      await _processActionData(response.actionData);

      // Remove system messages and add response
      final finalMsgs = (state.valueOrNull ?? []).where((m) =>
          !(m.role == 'system' && (m.content.contains('Uploading') || m.content.contains('Analyzing')))).toList();

      final assistantMessage = ChatMessage(
        role: 'assistant',
        content: response.message,
        intent: response.intent,
        agentType: response.agentType,
        createdAt: DateTime.now().toIso8601String(),
        actionData: response.actionData,
      );

      final newMessages = [...finalMsgs, assistantMessage];
      state = AsyncValue.data(newMessages);
      await _saveToCache(userId, newMessages);
    } catch (e, stackTrace) {
      debugPrint('❌ [Chat] Error sending multi-media message: $e');
      debugPrint('❌ [Chat] Stack trace: $stackTrace');

      final errorMsgs = (state.valueOrNull ?? []).where((m) =>
          !(m.role == 'system' && (m.content.contains('Uploading') || m.content.contains('Analyzing')))).toList();

      final errorMessage = ChatMessage(
        role: 'error',
        content: 'Failed to analyze media: ${e.toString().replaceAll('Exception: ', '')}',
        createdAt: DateTime.now().toIso8601String(),
      );
      state = AsyncValue.data([...errorMsgs, errorMessage]);
    } finally {
      _isLoading = false;
    }
  }

  /// Clear messages and invalidate cache
  Future<void> clear() async {
    state = const AsyncValue.data([]);
    final userId = await _apiClient.getUserId();
    if (userId != null) {
      await DataCacheService.instance.invalidate(_cacheKey(userId));
    }
  }

  /// Clear history (alias for clear)
  Future<void> clearHistory() async {
    await clear();
  }

  /// Add a system notification message (e.g., coach changed)
  void addSystemNotification(String message) {
    final notificationMessage = ChatMessage(
      role: 'system',
      content: message,
      createdAt: DateTime.now().toIso8601String(),
    );
    final currentMessages = state.valueOrNull ?? [];
    state = AsyncValue.data([...currentMessages, notificationMessage]);
    debugPrint('📢 [Chat] System notification added: $message');
  }

  /// Send a message through the offline AI coach (local Gemma model).
  Future<void> _sendOfflineMessage(String message, String userId) async {
    _isLoading = true;

    try {
      // Build conversation history from existing messages
      final currentMessages = state.valueOrNull ?? [];
      final history = currentMessages
          .where((m) => m.role == 'user' || m.role == 'assistant')
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      // Build user profile context
      Map<String, dynamic>? userProfile;
      if (_user != null) {
        userProfile = {
          'fitness_level': _user.fitnessLevel ?? 'beginner',
          'goals': _user.goalsList,
          'active_injuries': _user.injuriesList,
        };
      }

      // Get current workout context string
      String? workoutContext;
      final nextWorkout = _workoutsNotifier.nextWorkout;
      if (nextWorkout != null) {
        workoutContext = 'Today\'s workout: ${nextWorkout.name ?? "Workout"} '
            'with ${nextWorkout.exercises.length} exercises';
      }

      final response = await _offlineCoach.sendMessage(
        userMessage: message,
        conversationHistory: history,
        userProfile: userProfile,
        currentWorkoutContext: workoutContext,
      );

      final updatedMessages = state.valueOrNull ?? [];
      final newMessages = [...updatedMessages, response];
      state = AsyncValue.data(newMessages);

      // Cache offline messages too
      await _saveToCache(userId, newMessages);
    } catch (e) {
      debugPrint('❌ [Chat] Offline error: $e');
      final errorMessage = ChatMessage(
        role: 'assistant',
        content: 'The offline AI encountered an error: ${e.toString().replaceAll('Exception: ', '')}',
        createdAt: DateTime.now().toIso8601String(),
      );
      final updatedMessages = state.valueOrNull ?? [];
      state = AsyncValue.data([...updatedMessages, errorMessage]);
    } finally {
      _isLoading = false;
    }
  }

  /// Process action_data from AI response
  Future<void> _processActionData(Map<String, dynamic>? actionData) async {
    if (actionData == null) {
      debugPrint('🤖 [Chat] No action_data to process (null)');
      return;
    }

    final action = actionData['action'] as String?;
    debugPrint('🤖 [Chat] Processing action_data: $action');
    debugPrint('🤖 [Chat] Full action_data: $actionData');

    switch (action) {
      case 'change_setting':
        _handleSettingChange(actionData);
        break;
      case 'navigate':
        _handleNavigation(actionData);
        break;
      case 'start_workout':
        _handleStartWorkout(actionData);
        break;
      case 'complete_workout':
        _handleCompleteWorkout(actionData);
        break;
      case 'log_hydration':
        _handleLogHydration(actionData);
        break;
      case 'generate_quick_workout':
        await _handleQuickWorkoutGenerated(actionData);
        break;
      case 'add_exercise':
      case 'remove_exercise':
      case 'replace_all_exercises':
      case 'modify_intensity':
      case 'reschedule':
      case 'delete_workout':
        await _handleWorkoutModified(actionData);
        break;
      case 'food_logged':
        debugPrint('🍽️ [Chat] Food logged via chat - refreshing nutrition data');
        try {
          final userId = await _apiClient.getUserId();
          if (userId != null) {
            await _nutritionNotifier.refreshAll(userId);
          }
        } catch (e) {
          debugPrint('🍽️ [Chat] Failed to refresh nutrition: $e');
        }
        break;
      default:
        debugPrint('🤖 [Chat] Unknown action: $action');
    }
  }

  /// Handle app setting changes from AI
  void _handleSettingChange(Map<String, dynamic> actionData) {
    final settingName = actionData['setting_name'] as String?;
    final settingValue = actionData['setting_value'] as bool?;

    debugPrint('🤖 [Chat] Changing setting: $settingName = $settingValue');

    switch (settingName) {
      case 'dark_mode':
        if (settingValue == true) {
          _themeNotifier.setTheme(ThemeMode.dark);
          debugPrint('🌙 [Chat] Dark mode enabled via AI');
        } else if (settingValue == false) {
          _themeNotifier.setTheme(ThemeMode.light);
          debugPrint('☀️ [Chat] Light mode enabled via AI');
        }
        break;
      case 'notifications':
        // TODO: Implement notification toggle when needed
        debugPrint('🔔 [Chat] Notifications setting change requested: $settingValue');
        break;
      default:
        debugPrint('🤖 [Chat] Unknown setting: $settingName');
    }
  }

  /// Handle navigation from AI
  void _handleNavigation(Map<String, dynamic> actionData) {
    final destination = actionData['destination'] as String?;
    debugPrint('🧭 [Chat] Navigating to: $destination');

    // Map destination names to routes
    final routes = {
      // Main tabs
      'home': '/home',
      'nutrition': '/nutrition',
      'profile': '/profile',
      // Feature screens
      'library': '/library',
      'chat': '/chat',
      'settings': '/settings',
      'achievements': '/achievements',
      'hydration': '/hydration',
      'summaries': '/summaries',
      'stats': '/stats',
      'progress': '/stats',
      'schedule': '/schedule',
      'fasting': '/nutrition',
      'neat': '/neat',
      'metrics': '/metrics',
      'support': '/help',
      // Settings sub-pages
      'workout_settings': '/settings/workout-settings',
      'ai_coach': '/settings/ai-coach',
      'appearance': '/settings/appearance',
    };

    final route = routes[destination];
    if (route != null) {
      // Use go for main tabs, push for nested screens
      if ({'home', 'nutrition', 'profile'}.contains(destination)) {
        _router.go(route);
      } else {
        _router.push(route);
      }
      debugPrint('🧭 [Chat] Navigated to $route');
    } else {
      debugPrint('🧭 [Chat] Unknown destination: $destination');
    }
  }

  /// Handle start workout from AI
  void _handleStartWorkout(Map<String, dynamic> actionData) {
    final workoutId = actionData['workout_id'];
    debugPrint('🏋️ [Chat] Starting workout: $workoutId');

    // Navigate to home (where the workout is) and trigger workout start
    // The workout will auto-start when the user sees the workout screen
    _router.go('/home');

    // Navigate to workout detail with start flag
    if (workoutId != null) {
      _router.push('/workout/$workoutId?autoStart=true');
      debugPrint('🏋️ [Chat] Navigated to workout detail with auto-start');
    }
  }

  /// Handle complete workout from AI
  Future<void> _handleCompleteWorkout(Map<String, dynamic> actionData) async {
    final workoutId = actionData['workout_id'];
    debugPrint('✅ [Chat] Completing workout: $workoutId');

    if (workoutId != null) {
      // Mark the workout as complete
      await _workoutRepository.completeWorkout(workoutId.toString());
      // Refresh workouts list
      await _workoutsNotifier.refresh();
      debugPrint('✅ [Chat] Workout marked as complete');
    }
  }

  /// Handle hydration logging from AI
  Future<void> _handleLogHydration(Map<String, dynamic> actionData) async {
    final amount = actionData['amount'] as int? ?? 1;
    debugPrint('💧 [Chat] Logging hydration: $amount glasses');

    final userId = await _apiClient.getUserId();
    if (userId == null) {
      debugPrint('❌ [Chat] No user ID for hydration logging');
      return;
    }

    // Log water - 1 glass = 250ml
    final amountMl = amount * 250;
    final success = await _hydrationNotifier.quickLog(
      userId: userId,
      drinkType: 'water',
      amountMl: amountMl,
    );

    if (success) {
      debugPrint('💧 [Chat] Successfully logged $amount glasses ($amountMl ml)');
    } else {
      debugPrint('❌ [Chat] Failed to log hydration');
    }
  }

  /// Handle quick workout generation from AI
  Future<void> _handleQuickWorkoutGenerated(Map<String, dynamic> actionData) async {
    final workoutId = actionData['workout_id'];
    final workoutName = actionData['workout_name'] as String?;
    final exerciseCount = actionData['exercise_count'] as int?;
    final durationMinutes = actionData['duration_minutes'];
    final workoutType = actionData['workout_type'] as String?;

    debugPrint('🏋️ [Chat] ═══════════════════════════════════════════');
    debugPrint('🏋️ [Chat] QUICK WORKOUT GENERATED SUCCESSFULLY!');
    debugPrint('🏋️ [Chat] workout_id: $workoutId');
    debugPrint('🏋️ [Chat] workout_name: $workoutName');
    debugPrint('🏋️ [Chat] exercise_count: $exerciseCount');
    debugPrint('🏋️ [Chat] duration_minutes: $durationMinutes');
    debugPrint('🏋️ [Chat] workout_type: $workoutType');
    debugPrint('🏋️ [Chat] ═══════════════════════════════════════════');

    // Refresh workouts to show the new quick workout
    debugPrint('🏋️ [Chat] Calling _workoutsNotifier.refresh()...');
    await _workoutsNotifier.refresh();
    debugPrint('🏋️ [Chat] Workouts refreshed successfully after quick workout generation');
    debugPrint('🏋️ [Chat] NOTE: The "Go to Workout" button should now appear in chat UI');
  }

  /// Handle general workout modifications from AI
  Future<void> _handleWorkoutModified(Map<String, dynamic> actionData) async {
    final action = actionData['action'] as String?;
    final workoutId = actionData['workout_id'];
    debugPrint('🏋️ [Chat] Workout modified: $action on workout $workoutId');

    // Refresh workouts to show the changes
    await _workoutsNotifier.refresh();
    debugPrint('🏋️ [Chat] Workouts refreshed after modification');
  }
}
