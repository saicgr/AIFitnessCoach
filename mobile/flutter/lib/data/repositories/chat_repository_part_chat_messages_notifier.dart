part of 'chat_repository.dart';


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
  final SoundPreferencesNotifier Function() _getSoundPrefs;
  final AudioPreferencesNotifier Function() _getAudioPrefs;
  bool _isLoading = false;
  Future<void>? _loadHistoryFuture;

  // Pagination state (#16)
  int _currentOffset = 0;
  bool _hasMoreMessages = true;

  // Offline message queue (#31)
  final List<String> _pendingOfflineMessages = [];

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

  ChatMessagesNotifier(this._repository, this._apiClient, this._workoutsNotifier, this._workoutRepository, this._user, this._themeNotifier, this._router, this._hydrationNotifier, this._nutritionNotifier, this._getAISettings, this._setAIGenerating, this._getUnifiedContext, this._offlineCoach, this._isOnline, this._getSoundPrefs, this._getAudioPrefs)
      : super(const AsyncValue.data([])) {
    _restoreFromCache();
  }

  /// Restore messages from cache on notifier recreation to prevent empty flash
  Future<void> _restoreFromCache() async {
    final userId = await _apiClient.getUserId();
    if (userId == null || !mounted) return;
    final cached = await _loadFromCache(userId);
    if (mounted && cached.isNotEmpty && (state.valueOrNull?.isEmpty ?? true)) {
      state = AsyncValue.data(cached);
    }
  }

  bool get isLoading => _isLoading;

  /// Whether more messages are available for pagination (#16)
  bool get hasMoreMessages => _hasMoreMessages;

  /// Update the status of a specific message in the current state (#14)
  void _updateMessageStatus(ChatMessage target, MessageStatus newStatus) {
    final messages = state.valueOrNull;
    if (messages == null) return;
    final updated = messages.map((m) {
      if (m.createdAt == target.createdAt && m.role == target.role && m.content == target.content) {
        return m.copyWith(status: newStatus);
      }
      return m;
    }).toList();
    state = AsyncValue.data(updated);
  }

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

  /// Save chat messages to DataCacheService (capped at 200 messages)
  Future<void> _saveToCache(String userId, List<ChatMessage> messages) async {
    try {
      // Limit cache to last 200 messages (#32)
      final trimmed = messages.length > 200
          ? messages.sublist(messages.length - 200)
          : messages;
      final jsonList = trimmed.map((m) => m.toJson()).toList();
      await DataCacheService.instance.cacheList(_cacheKey(userId), jsonList);
      debugPrint('💾 [Chat] Saved ${trimmed.length} messages to cache');
    } catch (e) {
      debugPrint('❌ [Chat] Error saving to cache: $e');
    }
  }

  /// Load chat history with cache-first pattern
  /// If force is false, only loads if there are no messages yet
  /// Concurrent calls are deduplicated — callers await the same in-flight request.
  Future<void> loadHistory({bool force = false}) {
    // Skip loading if we already have messages and not forcing
    final currentMessages = state.valueOrNull;
    if (!force && currentMessages != null && currentMessages.isNotEmpty) {
      debugPrint('🔍 [Chat] Skipping history load - already have ${currentMessages.length} messages');
      return Future.value();
    }

    // Dedup: if a load is already in-flight, piggyback on it
    if (_loadHistoryFuture != null && !force) {
      debugPrint('🔍 [Chat] Dedup - reusing in-flight history load');
      return _loadHistoryFuture!;
    }

    _loadHistoryFuture = _doLoadHistory(force: force);
    return _loadHistoryFuture!;
  }

  Future<void> _doLoadHistory({bool force = false}) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null || !mounted) return;

      // 1. Load from cache first and show immediately
      final cachedMessages = await _loadFromCache(userId);
      if (!mounted) return;
      if (cachedMessages.isNotEmpty) {
        state = AsyncValue.data(cachedMessages);
        debugPrint('🔍 [Chat] Showing ${cachedMessages.length} cached messages while fetching fresh data');
      } else {
        state = const AsyncValue.loading();
      }

      // 2. Fetch fresh data from API in background
      try {
        final messages = await _repository.getChatHistory(userId);
        if (!mounted) return;

        // If sendMessage is in-flight, don't replace state — the send
        // owns state and will produce the authoritative version when done.
        if (_isLoading) {
          debugPrint('⚠️ [Chat] Skipping history state replacement — sendMessage in-flight');
          await _saveToCache(userId, messages);
          return;
        }

        state = AsyncValue.data(messages);
        _currentOffset = messages.length;
        // 3. Update cache with fresh data
        await _saveToCache(userId, messages);
      } catch (e, st) {
        if (!mounted) return;
        // If we have cached data, keep showing it instead of error
        if (cachedMessages.isNotEmpty) {
          debugPrint('⚠️ [Chat] API fetch failed, keeping cached data: $e');
        } else {
          state = AsyncValue.error(e, st);
        }
      }
    } finally {
      _loadHistoryFuture = null;
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

    // Add user message immediately (with local file for thumbnail)
    final userMessage = ChatMessage(
      role: 'user',
      content: actualMessage,
      createdAt: DateTime.now().toIso8601String(),
      mediaType: hasVideo ? 'video' : 'image',
      localFilePath: mediaList.first.file.path,
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
      if (!mounted) return;

      // Step 3: Upload all to S3 in parallel with individual error handling
      final uploadResults = <bool>[];
      final uploadErrors = <int>[];
      await Future.wait(
        List.generate(mediaList.length, (i) async {
          try {
            final media = mediaList[i];
            final presigned = presignedItems[i];
            await _repository.uploadToS3(
              presignedUrl: presigned['presigned_url'] as String,
              fields: presigned['presigned_fields'] as Map<String, dynamic>?,
              file: media.file,
              contentType: media.mimeType,
            );
            uploadResults.add(true);
          } catch (e) {
            debugPrint('❌ [Chat] Upload failed for file $i: $e');
            uploadResults.add(false);
            uploadErrors.add(i);
          }
        }),
      );

      if (!mounted) return;
      final successCount = uploadResults.where((r) => r).length;
      final failCount = uploadErrors.length;

      // If all uploads failed, throw to trigger error handling
      if (successCount == 0) {
        throw Exception('All $failCount uploads failed. Please try again.');
      }

      // Show warning if some uploads failed
      if (failCount > 0) {
        final warningMsg = ChatMessage(
          role: 'system',
          content: '$successCount of ${mediaList.length} files uploaded. $failCount failed.',
          createdAt: DateTime.now().toIso8601String(),
        );
        final currentMsgs = state.valueOrNull ?? [];
        final withWarning = currentMsgs.where((m) =>
            !(m.role == 'system' && m.content.contains('Uploading'))).toList();
        state = AsyncValue.data([...withWarning, warningMsg]);
      }

      // Step 4: Show analyzing message
      final analyzingMsg = ChatMessage(
        role: 'system',
        content: hasVideo ? 'Analyzing your form...' : 'Analyzing $successCount images...',
        createdAt: DateTime.now().toIso8601String(),
      );
      final msgsAfterUpload = state.valueOrNull ?? [];
      final filteredMsgs = msgsAfterUpload.where((m) =>
          !(m.role == 'system' && (m.content.contains('Uploading') || m.content.contains('Analyzing') || m.content.contains('uploaded')))).toList();
      state = AsyncValue.data([...filteredMsgs, analyzingMsg]);

      // Step 5: Build media_refs only for successful uploads
      final mediaRefs = <Map<String, dynamic>>[];
      for (int i = 0; i < mediaList.length; i++) {
        if (uploadErrors.contains(i)) continue; // Skip failed uploads
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
      if (!mounted) return;

      await _processActionData(response.actionData);
      if (!mounted) return;

      // Remove system messages and add response
      final finalMsgs = (state.valueOrNull ?? []).where((m) =>
          !(m.role == 'system' && (m.content.contains('Uploading') || m.content.contains('Analyzing')))).toList();

      final assistantMessage = ChatMessage(
        role: 'assistant',
        content: _stripActionDataFromMessage(response.message),
        intent: response.intent,
        agentType: response.agentType,
        createdAt: DateTime.now().toIso8601String(),
        actionData: response.actionData,
        coachPersonaId: currentAISettings.coachPersonaId,
      );

      final newMessages = [...finalMsgs, assistantMessage];
      state = AsyncValue.data(newMessages);
      await _saveToCache(userId, newMessages);
    } catch (e, stackTrace) {
      debugPrint('❌ [Chat] Error sending multi-media message: $e');
      debugPrint('❌ [Chat] Stack trace: $stackTrace');
      if (!mounted) return;

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

  /// Clear history and notify server
  Future<void> clearHistory() async {
    state = const AsyncValue.data([]);
    final userId = await _apiClient.getUserId();
    if (userId != null) {
      await DataCacheService.instance.invalidate(_cacheKey(userId));
      // Clear on server too
      try {
        await _repository.clearChatHistory(userId);
      } catch (e) {
        debugPrint('❌ [Chat] Failed to clear history on server: $e');
      }
    }
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

      // Queue for server sync when back online
      queueOfflineMessage(message);
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

  /// Delete a message from state and server (#15)
  Future<void> deleteMessage(String messageId) async {
    // Remove from local state immediately
    final messages = state.valueOrNull;
    if (messages == null) return;
    final updated = messages.where((m) => m.id != messageId).toList();
    state = AsyncValue.data(updated);

    // Delete from server
    try {
      await _repository.deleteMessage(messageId);
    } catch (e) {
      debugPrint('❌ [Chat] Failed to delete message from server: $e');
    }

    // Update cache
    final userId = await _apiClient.getUserId();
    if (userId != null) {
      await _saveToCache(userId, updated);
    }
  }

  /// Load older messages for infinite scroll (#16)
  Future<void> loadOlderMessages() async {
    if (!_hasMoreMessages || _isLoading) return;

    final userId = await _apiClient.getUserId();
    if (userId == null || !mounted) return;

    try {
      final olderMessages = await _repository.getChatHistory(
        userId,
        limit: 50,
        offset: _currentOffset,
      );
      if (!mounted) return;

      if (olderMessages.length < 50) {
        _hasMoreMessages = false;
      }
      _currentOffset += olderMessages.length;

      // Prepend older messages to existing list, deduplicating by id
      final current = state.valueOrNull ?? [];
      final existingIds = current.map((m) => m.id).whereType<String>().toSet();
      final newOlder = olderMessages.where((m) => m.id != null && !existingIds.contains(m.id)).toList();

      if (newOlder.isNotEmpty) {
        state = AsyncValue.data([...newOlder, ...current]);
      }
    } catch (e) {
      debugPrint('❌ [Chat] Error loading older messages: $e');
    }
  }

  /// Toggle pin on a message (#27)
  Future<void> togglePin(String messageId) async {
    final messages = state.valueOrNull;
    if (messages == null) return;

    final targetMsg = messages.firstWhere((m) => m.id == messageId, orElse: () => messages.first);
    final newPinned = !targetMsg.isPinned;

    final updated = messages.map((m) {
      if (m.id == messageId) {
        return m.copyWith(isPinned: newPinned);
      }
      return m;
    }).toList();
    state = AsyncValue.data(updated);

    // Save updated state to cache
    final userId = await _apiClient.getUserId();
    if (userId != null) {
      await _saveToCache(userId, updated);
    }

    // Persist to backend (fire and forget)
    try {
      await _repository.toggleMessagePin(messageId, newPinned);
    } catch (e) {
      debugPrint('❌ [Chat] Failed to persist pin to server: $e');
    }
  }

  /// Send a voice message (#28)
  Future<void> sendVoiceMessage(File audioFile, int durationMs) async {
    if (_isLoading) return;

    final userId = await _apiClient.getUserId();
    if (userId == null) return;

    final currentMessages = state.valueOrNull ?? [];

    // Add user message immediately with pending status
    final userMessage = ChatMessage(
      role: 'user',
      content: 'Voice message',
      createdAt: DateTime.now().toIso8601String(),
      status: MessageStatus.pending,
      audioDurationMs: durationMs,
    );
    final messagesWithUser = [...currentMessages, userMessage];
    state = AsyncValue.data(messagesWithUser);

    _isLoading = true;

    try {
      // Step 1: Get presigned URL for audio upload
      final filename = audioFile.path.split('/').last;
      final presignData = await _repository.getPresignedUrl(
        filename: filename,
        contentType: 'audio/m4a',
        mediaType: 'audio',
        expectedSizeBytes: await audioFile.length(),
      );

      final presignedUrl = presignData['presigned_url'] as String? ?? presignData['url'] as String;
      final s3Key = presignData['s3_key'] as String;
      final fields = presignData['presigned_fields'] as Map<String, dynamic>?;
      final publicUrl = presignData['public_url'] as String?;

      // Step 2: Upload to S3
      await _repository.uploadToS3(
        presignedUrl: presignedUrl,
        fields: fields,
        file: audioFile,
        contentType: 'audio/m4a',
      );
      if (!mounted) return;

      // Update user message with audio URL and sent status
      final updatedUserMessage = userMessage.copyWith(
        audioUrl: publicUrl ?? presignedUrl,
        status: MessageStatus.sent,
      );
      final msgsAfterUpload = (state.valueOrNull ?? []).map((m) {
        if (m.createdAt == userMessage.createdAt && m.role == 'user' && m.content == 'Voice message') {
          return updatedUserMessage;
        }
        return m;
      }).toList();
      state = AsyncValue.data(msgsAfterUpload);

      // Step 3: Send message with media_ref
      final mediaRef = {
        's3_key': s3Key,
        'media_type': 'audio',
        'mime_type': 'audio/m4a',
        'filename': filename,
        'duration_ms': durationMs,
      };

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
        message: 'Voice message (${(durationMs / 1000).toStringAsFixed(1)}s)',
        userId: userId,
        userProfile: userProfile,
        conversationHistory: history,
        aiSettings: currentAISettings.toJson(),
        unifiedContext: unifiedContext,
        mediaRef: mediaRef,
      );
      if (!mounted) return;

      // Mark user message as delivered
      _updateMessageStatus(updatedUserMessage, MessageStatus.delivered);

      await _processActionData(response.actionData);
      if (!mounted) return;

      final assistantMessage = ChatMessage(
        role: 'assistant',
        content: _stripActionDataFromMessage(response.message),
        intent: response.intent,
        agentType: response.agentType,
        createdAt: DateTime.now().toIso8601String(),
        actionData: response.actionData,
        coachPersonaId: currentAISettings.coachPersonaId,
      );

      final updatedMessages = state.valueOrNull ?? [];
      final newMessages = [...updatedMessages, assistantMessage];
      state = AsyncValue.data(newMessages);
      await _saveToCache(userId, newMessages);
    } catch (e, stackTrace) {
      debugPrint('❌ [Chat] Error sending voice message: $e');
      debugPrint('❌ [Chat] Stack trace: $stackTrace');
      if (!mounted) return;

      _updateMessageStatus(userMessage, MessageStatus.error);

      final errorMessage = ChatMessage(
        role: 'error',
        content: 'Failed to send voice message: ${e.toString().replaceAll('Exception: ', '')}',
        createdAt: DateTime.now().toIso8601String(),
      );
      final updatedMessages = state.valueOrNull ?? [];
      state = AsyncValue.data([...updatedMessages, errorMessage]);
    } finally {
      _isLoading = false;
    }
  }

  /// Sync pending offline messages when connectivity is restored (#31)
  Future<void> syncPendingMessages() async {
    if (_pendingOfflineMessages.isEmpty || !_isOnline()) return;

    final userId = await _apiClient.getUserId();
    if (userId == null) return;

    debugPrint('🔄 [Chat] Syncing ${_pendingOfflineMessages.length} pending offline messages');

    final toSync = List<String>.from(_pendingOfflineMessages);
    for (final message in toSync) {
      try {
        await _repository.sendMessage(
          message: message,
          userId: userId,
        );
        _pendingOfflineMessages.remove(message);
        debugPrint('✅ [Chat] Synced offline message: ${message.substring(0, message.length.clamp(0, 50))}...');
      } catch (e) {
        debugPrint('❌ [Chat] Failed to sync offline message: $e');
        break; // Stop on first failure, retry later
      }
    }
  }

  /// Queue a message for offline sync (#31)
  void queueOfflineMessage(String message) {
    _pendingOfflineMessages.add(message);
    debugPrint('📝 [Chat] Queued message for offline sync (${_pendingOfflineMessages.length} pending)');
  }

  /// Clean AI message text for display:
  /// 1. Strip raw action_data JSON blobs the AI sometimes embeds in message text
  /// 2. Convert basic markdown bold (**text**) to plain text since chat has no markdown renderer
  String _stripActionDataFromMessage(String message) {
    // Strip JSON objects containing "action" key at the end of the message
    // e.g. {"action": "navigate", "destination": "nutrition"}
    final actionPattern = RegExp(
      r'\s*\{["\s]*"?action"?\s*:\s*"[^"]*"[^}]*\}\s*$',
      multiLine: true,
    );
    var cleaned = message.replaceAll(actionPattern, '').trimRight();

    // Convert markdown bold **text** to plain text
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\*\*(.+?)\*\*'),
      (m) => m.group(1)!,
    );

    return cleaned.isEmpty ? message : cleaned;
  }

