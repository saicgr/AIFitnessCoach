part of 'chat_repository.dart';

/// Methods extracted from ChatMessagesNotifier
extension ChatMessagesNotifierExt on ChatMessagesNotifier {

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

    // Add user message immediately with pending status
    final userMessage = ChatMessage(
      role: 'user',
      content: message,
      createdAt: DateTime.now().toIso8601String(),
      status: MessageStatus.pending,
    );
    final messagesWithUser = [...currentMessages, userMessage];
    state = AsyncValue.data(messagesWithUser);

    // Incrementally append user message to cache
    _saveToCache(userId, messagesWithUser);

    // Set loading flag early to prevent concurrent sends and block
    // loadHistory from replacing state while a send is in-flight.
    _isLoading = true;

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
        _isLoading = false;
        return;
      } else {
        // No model loaded, show error
        final errorMessage = ChatMessage(
          role: 'assistant',
          content: 'AI Coach needs an internet connection or a downloaded AI model to respond. Go to Settings \u2192 Offline Mode to download a model.',
          createdAt: DateTime.now().toIso8601String(),
        );
        state = AsyncValue.data([...messagesWithUser, errorMessage]);
        _isLoading = false;
        return;
      }
    }
    // --- END OFFLINE ROUTING ---

    // Try to sync any pending offline messages first
    if (_pendingOfflineMessages.isNotEmpty && _isOnline()) {
      syncPendingMessages(); // Fire and forget, don't await
    }

    // Check if this looks like a quick workout request
    final messageLower = message.toLowerCase();
    final isQuickWorkoutRequest = ChatMessagesNotifier._quickWorkoutKeywords.any((kw) => messageLower.contains(kw));
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
      if (!mounted) return;

      // Mark user message as sent after successful API call
      _updateMessageStatus(userMessage, MessageStatus.sent);

      // Process action_data if present (await to ensure refresh completes)
      await _processActionData(response.actionData);
      if (!mounted) return;

      // Debug logging for action_data (helps trace "Go to Workout" button issues)
      if (response.actionData != null) {
        debugPrint('🎯 [Chat] Response has action_data: ${response.actionData}');
        debugPrint('🎯 [Chat] action_data[action]: ${response.actionData!['action']}');
        debugPrint('🎯 [Chat] action_data[workout_id]: ${response.actionData!['workout_id']}');
      } else {
        debugPrint('🔍 [Chat] Response has no action_data');
      }

      // Add assistant response with agent type AND action_data (for "Go to Workout" button)
      // Strip any raw action_data JSON that the AI accidentally included in the message text
      final cleanedMessage = _stripActionDataFromMessage(response.message);
      final assistantMessage = ChatMessage(
        role: 'assistant',
        content: cleanedMessage,
        intent: response.intent,
        agentType: response.agentType,
        createdAt: DateTime.now().toIso8601String(),
        actionData: response.actionData, // Include action_data for UI buttons
        coachPersonaId: currentAISettings.coachPersonaId,
      );

      // Debug: Check if hasGeneratedWorkout will be true
      debugPrint('🎯 [Chat] assistantMessage.hasGeneratedWorkout: ${assistantMessage.hasGeneratedWorkout}');
      if (assistantMessage.hasGeneratedWorkout) {
        debugPrint('✅ [Chat] "Go to Workout" button should appear! workoutId: ${assistantMessage.workoutId}');
      }

      // Mark user message as delivered (assistant responded)
      _updateMessageStatus(userMessage, MessageStatus.delivered);

      final updatedMessages = state.valueOrNull ?? [];

      // Guard against duplicate assistant messages (e.g., if loadHistory
      // already injected this response from the server before we got here)
      final isDuplicate = updatedMessages.any((m) =>
          m.role == 'assistant' && m.content == cleanedMessage);
      if (isDuplicate) {
        debugPrint('⚠️ [Chat] Skipping duplicate assistant message');
      } else {
        final newMessages = [...updatedMessages, assistantMessage];
        state = AsyncValue.data(newMessages);
        // Incrementally update cache with new messages (append, don't re-fetch)
        await _saveToCache(userId, newMessages);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [Chat] Error sending message: $e');
      debugPrint('❌ [Chat] Stack trace: $stackTrace');
      if (!mounted) return;

      // Mark user message as error
      _updateMessageStatus(userMessage, MessageStatus.error);

      // Surface the real error - don't mask it as an AI response
      final errorText = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      final errorMessage = ChatMessage(
        role: 'error',
        content: errorText,
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
  /// Images: presign -> upload to S3 in parallel with AI call.
  /// Videos: upload to backend (parallel S3 + Gemini Files API) -> send message with gemini_file_name.
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

    // Add user message immediately (with local file for thumbnail)
    var userMessage = ChatMessage(
      role: 'user',
      content: message.isNotEmpty ? message : (media.type == ChatMediaType.video ? 'Check my form' : 'What do you see?'),
      createdAt: DateTime.now().toIso8601String(),
      mediaType: media.type == ChatMediaType.video ? 'video' : 'image',
      localFilePath: media.file.path,
    );
    final messagesWithUser = [...currentMessages, userMessage];
    state = AsyncValue.data(messagesWithUser);

    _isLoading = true;

    // Helper: update the upload overlay on the user's video message
    void setOverlay(String? phase, double? progress) {
      final msgs = state.valueOrNull ?? [];
      state = AsyncValue.data(msgs.map((m) =>
        m.role == 'user' && m.localFilePath == media.file.path
            ? m.withUploadState(phase, progress)
            : m,
      ).toList());
    }

    try {
      // Build shared context
      final history = currentMessages.map((m) => {'role': m.role, 'content': m.content}).toList();
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
      final effectiveMessage = message.isNotEmpty
          ? message
          : (media.type == ChatMediaType.video ? 'Check my form' : 'What do you see?');

      ChatResponse response;

      if (media.type == ChatMediaType.image) {
        // Image: get presigned URL, update message with public URL, then upload to S3
        // in parallel with the AI call (using base64 inline)
        final filename = media.file.path.split('/').last;
        final presignData = await _repository.getPresignedUrl(
          filename: filename,
          contentType: media.mimeType,
          mediaType: 'image',
          expectedSizeBytes: media.sizeBytes,
        );

        final presignedUrl = presignData['presigned_url'] as String? ?? presignData['url'] as String;
        final s3Key = presignData['s3_key'] as String;
        final fields = presignData['presigned_fields'] as Map<String, dynamic>?;
        final publicUrl = presignData['public_url'] as String?;

        // Update user message with public URL immediately (URL is known before upload)
        if (publicUrl != null) {
          userMessage = userMessage.copyWith(mediaUrl: publicUrl);
          final updatedMsgs = (state.valueOrNull ?? []).map((m) =>
              m.role == 'user' && m.localFilePath == media.file.path
                  ? userMessage
                  : m).toList();
          state = AsyncValue.data(updatedMsgs);
        }

        setOverlay('analyzing', null);
        final imageBytes = await media.file.readAsBytes();
        final imageBase64 = base64Encode(imageBytes);
        // Send both imageBase64 (for immediate analysis) and mediaRef with s3_key
        // (for menu/buffet/multi-image tools that need S3 keys)
        final imageMediaRef = {
          's3_key': s3Key,
          'media_type': 'image',
          'mime_type': media.mimeType,
        };
        final results = await Future.wait([
          _repository.uploadToS3(presignedUrl: presignedUrl, fields: fields, file: media.file, contentType: media.mimeType),
          _repository.sendMessage(
            message: effectiveMessage, userId: userId, userProfile: userProfile,
            conversationHistory: history, aiSettings: currentAISettings.toJson(),
            unifiedContext: unifiedContext, imageBase64: imageBase64,
            mediaRef: imageMediaRef, mediaUrl: publicUrl,
          ),
        ]);
        response = results[1] as ChatResponse;

      } else {
        // Video: upload to backend which handles S3 + Gemini in parallel
        debugPrint('🎬 [Chat] Uploading video (${(media.sizeBytes / 1024 / 1024).toStringAsFixed(1)}MB) to backend for parallel S3+Gemini processing');
        setOverlay('uploading', 0.0);

        final uploadResult = await _repository.uploadVideoForAnalysis(
          file: media.file,
          mimeType: media.mimeType,
          duration: media.duration,
          onProgress: (sent, total) {
            if (total > 0) setOverlay('uploading', sent / total);
          },
        );

        if (!mounted) return;
        setOverlay('analyzing', null);

        final s3Key = uploadResult['s3_key'] as String;
        final publicUrl = uploadResult['public_url'] as String?;
        final geminiFileName = uploadResult['gemini_file_name'] as String;

        // Update video message with public URL from upload response
        if (publicUrl != null) {
          userMessage = userMessage.copyWith(mediaUrl: publicUrl);
          final updatedMsgs = (state.valueOrNull ?? []).map((m) =>
              m.role == 'user' && m.localFilePath == media.file.path
                  ? userMessage
                  : m).toList();
          state = AsyncValue.data(updatedMsgs);
        }

        final mediaRef = {
          's3_key': s3Key,
          'media_type': 'video',
          'mime_type': media.mimeType,
          'gemini_file_name': geminiFileName,  // backend uses this directly, skips S3 download
          if (media.duration != null) 'duration_seconds': media.duration!.inSeconds.toDouble(),
        };
        response = await _repository.sendMessage(
          message: effectiveMessage, userId: userId, userProfile: userProfile,
          conversationHistory: history, aiSettings: currentAISettings.toJson(),
          unifiedContext: unifiedContext, mediaRef: mediaRef,
          mediaUrl: publicUrl,
        );
      }

      if (!mounted) return;

      // Clear upload overlay before showing result
      setOverlay(null, null);

      // Process action_data
      await _processActionData(response.actionData);
      if (!mounted) return;

      final finalMsgs = state.valueOrNull ?? [];

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
      debugPrint('❌ [Chat] Error sending message with media: $e');
      debugPrint('❌ [Chat] Stack trace: $stackTrace');
      if (!mounted) return;

      // Clear upload overlay on the user's media message
      setOverlay(null, null);

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

}
