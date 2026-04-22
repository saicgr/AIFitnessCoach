part of 'chat_screen.dart';

/// Methods extracted from _ChatScreenState
extension __ChatScreenStateExt on _ChatScreenState {

  /// Callback for _InputBar to send single media message
  Future<void> _sendMessageWithMedia(PickedMedia media) async {
    final message = _textController.text.trim();
    if (_isLoading) return;

    // Determine which feature gate applies based on media type
    final usageNotifier = ref.read(usageTrackingProvider.notifier);
    final isVideo = media.type == ChatMediaType.video;
    final gateKey = isVideo ? _kFormVideoAnalysis : _kFoodScanning;
    final gateName = isVideo ? 'Form Video Analysis' : 'Food Scans';

    if (!usageNotifier.hasAccess(gateKey)) {
      ref.read(posthogServiceProvider).capture(
        eventName: 'chat_feature_gated',
        properties: {'feature_key': gateKey, 'feature_name': gateName},
      );
      showUpgradePromptSheet(context,
          featureKey: gateKey, featureName: gateName);
      return;
    }

    // Check if this is the last free use
    final remaining = usageNotifier.remainingUses(gateKey);
    final isLastUse = remaining != null && remaining == 1;

    HapticService.medium();
    _textController.clear();
    _startSendStatus(_MediaSendStatus.uploading);

    try {
      // Transition to analyzing after a short delay (upload is fast for images)
      if (!isVideo) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_sendStatus == _MediaSendStatus.uploading) {
            _updateSendStatus(_MediaSendStatus.analyzing);
          }
        });
      }
      await ref.read(chatMessagesProvider.notifier).sendMessageWithMedia(message, media);
      // Send completed — but the user may have backgrounded or popped the
      // chat screen during the upload/analysis. Guard every ref.read after
      // the await so we don't crash a disposed Riverpod scope.
      if (!mounted) return;
      ref.read(posthogServiceProvider).capture(
        eventName: 'chat_media_sent',
        properties: {'media_type': isVideo ? 'video' : 'image', 'message_length': message.length},
      );
      _scrollToBottom();
      ref.read(xpProvider.notifier).checkFirstChatBonus();

      // Optimistically decrement and show last-use snackbar
      usageNotifier.decrementLocal(gateKey);
      if (isLastUse && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('That was your last free ${gateName.toLowerCase()} for this period.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send media: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      _stopSendStatus();
      _scrollToBottom();
    }
  }


  /// Callback for _InputBar to send multiple media messages
  Future<void> _sendMessageWithMultiMedia(List<PickedMedia> mediaList) async {
    final message = _textController.text.trim();
    if (_isLoading) return;

    // Gate check: determine if video or image media
    final usageNotifier = ref.read(usageTrackingProvider.notifier);
    final hasVideo = mediaList.any((m) => m.type == ChatMediaType.video);
    final gateKey = hasVideo ? _kFormVideoAnalysis : _kFoodScanning;
    final gateName = hasVideo ? 'Form Video Analysis' : 'Food Scans';

    if (!usageNotifier.hasAccess(gateKey)) {
      ref.read(posthogServiceProvider).capture(
        eventName: 'chat_feature_gated',
        properties: {'feature_key': gateKey, 'feature_name': gateName},
      );
      showUpgradePromptSheet(context,
          featureKey: gateKey, featureName: gateName);
      return;
    }

    final remaining = usageNotifier.remainingUses(gateKey);
    final isLastUse = remaining != null && remaining == 1;

    HapticService.medium();
    _textController.clear();
    _startSendStatus(_MediaSendStatus.uploading);

    try {
      Future.delayed(const Duration(seconds: 2), () {
        if (_sendStatus == _MediaSendStatus.uploading) {
          _updateSendStatus(_MediaSendStatus.analyzing);
        }
      });
      await ref.read(chatMessagesProvider.notifier).sendMessageWithMultiMedia(message, mediaList);
      // Same guard pattern as single-media path above — the multi-upload can
      // take many seconds and the user may navigate away during it.
      if (!mounted) return;
      ref.read(posthogServiceProvider).capture(
        eventName: 'chat_multi_media_sent',
        properties: {'media_count': mediaList.length, 'message_length': message.length},
      );
      _scrollToBottom();
      ref.read(xpProvider.notifier).checkFirstChatBonus();

      usageNotifier.decrementLocal(gateKey);
      if (isLastUse && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('That was your last free ${gateName.toLowerCase()} for this period.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send media: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      _stopSendStatus();
      _scrollToBottom();
    }
  }


  /// Log selected dishes from a FoodAnalysisResultCard (buffet/menu analysis).
  Future<void> _logAnalysisItems(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // Determine meal type from time of day
    final hour = DateTime.now().hour;
    final mealType = hour < 10
        ? 'breakfast'
        : hour < 14
            ? 'lunch'
            : hour < 17
                ? 'snack'
                : 'dinner';

    try {
      final repo = ref.read(nutritionRepositoryProvider);

      // Build food_items list and sum macros
      final foodItems = <Map<String, dynamic>>[];
      int totalCal = 0;
      int totalProtein = 0;
      int totalCarbs = 0;
      int totalFat = 0;

      for (final item in items) {
        final cal = (item['calories'] as num? ?? 0).toInt();
        final protein = (item['protein_g'] as num? ?? item['protein'] as num? ?? 0).toInt();
        final carbs = (item['carbs_g'] as num? ?? item['carbs'] as num? ?? 0).toInt();
        final fat = (item['fat_g'] as num? ?? item['fat'] as num? ?? 0).toInt();

        totalCal += cal;
        totalProtein += protein;
        totalCarbs += carbs;
        totalFat += fat;

        foodItems.add({
          'name': item['name'] ?? 'Unknown',
          'calories': cal,
          'protein_g': protein,
          'carbs_g': carbs,
          'fat_g': fat,
          if (item['portion_multiplier'] != null) 'portion_multiplier': item['portion_multiplier'],
        });
      }

      await repo.logAdjustedFood(
        userId: userId,
        mealType: mealType,
        foodItems: foodItems,
        totalCalories: totalCal,
        totalProtein: totalProtein,
        totalCarbs: totalCarbs,
        totalFat: totalFat,
        sourceType: 'image',
      );

      // Bail out if the chat screen unmounted while logging — touching ref
      // after dispose throws "Cannot use ref after the widget was disposed".
      if (!mounted) return;

      // Refresh nutrition tab
      if (userId.isNotEmpty) {
        ref.read(nutritionProvider.notifier).loadTodaySummary(userId, forceRefresh: true);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged ${items.length} item${items.length == 1 ? '' : 's'} as $mealType'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to log food items'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }


  Future<void> _sendMessage() async {
    final message = _textController.text.trim();
    if (message.isEmpty || _isLoading) return;

    // Gate check for chat messages
    final usageNotifier = ref.read(usageTrackingProvider.notifier);
    if (!usageNotifier.hasAccess(_kAiChatMessages)) {
      ref.read(posthogServiceProvider).capture(
        eventName: 'chat_feature_gated',
        properties: {'feature_key': _kAiChatMessages, 'feature_name': 'AI Coach Messages'},
      );
      showUpgradePromptSheet(context,
          featureKey: _kAiChatMessages, featureName: 'AI Coach Messages');
      return;
    }

    HapticService.medium();
    _textController.clear();
    _startSendStatus(_MediaSendStatus.generating);

    try {
      await ref.read(chatMessagesProvider.notifier).sendMessage(message);
      // Send completed — the user may have navigated away while we were
      // waiting on the AI. Avoid touching ref after dispose.
      if (!mounted) return;
      ref.read(posthogServiceProvider).capture(
        eventName: 'chat_message_sent',
        properties: {'message_length': message.length},
      );
      _scrollToBottom();

      // Award first-time chat bonus (+50 XP)
      ref.read(xpProvider.notifier).checkFirstChatBonus();

      // Optimistically decrement chat message usage
      usageNotifier.decrementLocal(_kAiChatMessages);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      _stopSendStatus();
      _scrollToBottom();
    }
  }


  void _showUsageInfoSheet(BuildContext context) {
    // Refresh usage data before showing
    ref.read(usageTrackingProvider.notifier).fetchLimits();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        // Use Consumer so the sheet rebuilds when fetchLimits() completes
        return Consumer(
          builder: (ctx, sheetRef, _) {
            final usageState = sheetRef.watch(usageTrackingProvider);
            final features = usageState.limits.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key));

            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Today's Usage",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (usageState.isLoading && features.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (usageState.isPremium)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Unlimited access with Premium',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else ...[
                    ...features.map((entry) {
                      final feature = entry.value;
                      final used = feature.used;
                      final limit = feature.limit ?? 0;
                      if (limit == 0) return const SizedBox.shrink();
                      final remaining = feature.remaining ?? (limit - used);
                      final progress = limit > 0 ? (used / limit).clamp(0.0, 1.0) : 0.0;
                      final isLow = remaining <= (limit * 0.25).ceil() && remaining > 0;
                      final isExhausted = remaining <= 0;

                      const displayNames = {
                        'ai_chat_messages': 'Messages',
                        'food_scanning': 'Food Scans',
                        'form_video_analysis': 'Form Checks',
                        'text_to_calories': 'Text Logging',
                        'ai_workout_generation': 'Workout Gen',
                        'ai_meal_plan': 'Meal Plans',
                      };

                      Color barColor = AppColors.cyan;
                      if (isExhausted) barColor = AppColors.error;
                      else if (isLow) barColor = AppColors.warning;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  displayNames[entry.key] ?? entry.key.replaceAll('_', ' '),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                                Text(
                                  '$used/$limit',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isExhausted
                                        ? AppColors.error
                                        : isLow
                                            ? AppColors.warning
                                            : (isDark ? Colors.white : Colors.black),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(barColor),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    Text(
                      'Resets at midnight',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          showUpgradePromptSheet(context,
                              featureKey: _kAiChatMessages, featureName: 'AI Coach');
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.cyan),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Upgrade for Unlimited',
                          style: TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }


  void _showHelpSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondary : const Color(0xFF9E9E9E);

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.headset_mic, color: AppColors.cyan),
                title: const Text('Talk to Human'),
                subtitle: Text(
                  'Connect with a real support agent',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  HapticService.selection();
                  _showEscalateToHumanDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.bug_report, color: AppColors.orange),
                title: const Text('Report a Problem'),
                subtitle: Text(
                  'Email our support team',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  HapticService.selection();
                  launchUrl(Uri.parse('mailto:${AppLinks.supportEmail}?subject=FitWiz Bug Report'), mode: LaunchMode.externalApplication);
                },
              ),
              ListTile(
                leading: const Icon(Icons.lightbulb_outline, color: AppColors.purple),
                title: const Text('Chat Tips'),
                subtitle: Text(
                  'See what your AI coach can do',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  HapticService.selection();
                  _showFeaturesInfoSheet();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _showMiniMediaChoiceForAction(ChatQuickAction action) {
    final isVideo = action.mediaMode == ChatMediaMode.video;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colors = ThemeColors.of(ctx);
        final isDark = colors.isDark;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.elevated : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: action.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(action.icon, size: 18, color: action.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        action.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildMiniPickerOption(
                  ctx: ctx,
                  icon: isVideo ? Icons.videocam_outlined : Icons.camera_alt_outlined,
                  label: isVideo ? 'Record Video' : 'Take Photo',
                  color: action.color,
                  onTap: () {
                    Navigator.pop(ctx);
                    HapticService.selection();
                    _handleMediaFromPill(
                      isVideo ? ChatMediaMode.recordVideo : ChatMediaMode.camera,
                      action.examplePrompt ?? '',
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildMiniPickerOption(
                  ctx: ctx,
                  icon: isVideo ? Icons.video_library_outlined : Icons.photo_library_outlined,
                  label: isVideo ? 'Choose Video' : 'Choose Photo',
                  color: action.color,
                  onTap: () {
                    Navigator.pop(ctx);
                    HapticService.selection();
                    _handleMediaFromPill(
                      isVideo ? ChatMediaMode.video : ChatMediaMode.gallery,
                      action.examplePrompt ?? '',
                    );
                  },
                ),
                if (!isVideo) ...[
                  const SizedBox(height: 8),
                  _buildMiniPickerOption(
                    ctx: ctx,
                    icon: Icons.collections_outlined,
                    label: 'Choose Multiple Photos',
                    color: action.color,
                    onTap: () {
                      Navigator.pop(ctx);
                      HapticService.selection();
                      _handleMediaFromPill(
                        ChatMediaMode.multipleImages,
                        action.examplePrompt ?? '',
                      );
                    },
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }


  Future<void> _handleMediaFromPill(ChatMediaMode mode, String contextPrompt) async {
    if (_isLoading) return;

    // Set the context prompt before picking media
    if (contextPrompt.isNotEmpty) {
      _textController.text = contextPrompt;
    }

    try {
      // Multi-image path: Scan Food / Analyze Menu pills can accept multiple
      // photos so the nutrition agent runs analyze_multi_food_images.
      if (mode == ChatMediaMode.multipleImages) {
        final mediaList = await MediaPickerHelper.pickMultipleImages(context: context);
        if (mediaList.isEmpty) return;
        if (!mounted) return;
        if (mediaList.length == 1) {
          await _sendMessageWithMedia(mediaList.first);
        } else {
          await _sendMessageWithMultiMedia(mediaList);
        }
        return;
      }

      PickedMedia? media;
      switch (mode) {
        case ChatMediaMode.camera:
          media = await MediaPickerHelper.pickImage(ImageSource.camera);
          break;
        case ChatMediaMode.gallery:
          media = await MediaPickerHelper.pickImage(ImageSource.gallery);
          break;
        case ChatMediaMode.video:
          media = await MediaPickerHelper.pickVideo(ImageSource.gallery);
          break;
        case ChatMediaMode.recordVideo:
          media = await MediaPickerHelper.pickVideo(ImageSource.camera);
          break;
        case ChatMediaMode.multipleImages:
          // Already handled above.
          return;
      }

      if (media != null && mounted) {
        await _sendMessageWithMedia(media);
      }
    } on MediaValidationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }


  void _showOptionsMenu(BuildContext context) {
    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            ListTile(
              leading: const Icon(Icons.bug_report_outlined, color: AppColors.orange),
              title: const Text('Report a Problem'),
              subtitle: const Text(
                'Email our support team',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              onTap: () {
                Navigator.pop(context);
                HapticService.selection();
                launchUrl(Uri.parse('mailto:${AppLinks.supportEmail}?subject=FitWiz Bug Report'), mode: LaunchMode.externalApplication);
              },
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: AppColors.purple),
              title: const Text('Change Coach'),
              subtitle: const Text(
                'Switch to a different AI coach',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              onTap: () {
                Navigator.pop(context);
                HapticService.selection();
                context.push('/coach-selection?fromSettings=true');
              },
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Clear Chat History'),
              onTap: () {
                Navigator.pop(context);
                _showClearConfirmation();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About AI Coach'),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      ),
    );
  }

}
