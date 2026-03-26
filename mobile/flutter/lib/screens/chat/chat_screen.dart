import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_links.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../widgets/glass_sheet.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/coach_persona.dart';
import '../../data/models/live_chat_session.dart';
import '../../data/providers/live_chat_provider.dart';
import '../../data/providers/xp_provider.dart';
import '../../data/providers/offline_coach_provider.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/coach_avatar.dart';
import '../../widgets/floating_chat/floating_chat_overlay.dart';
import '../../widgets/medical_disclaimer_banner.dart';
import '../ai_settings/ai_settings_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/nutrition_repository.dart';
import 'widgets/food_analysis_inline_card.dart';
import '../../screens/nutrition/menu_analysis_sheet.dart';
import 'widgets/food_analysis_result_card.dart';
import 'widgets/form_check_result_card.dart';
import 'widgets/form_comparison_result_card.dart';
import 'widgets/fullscreen_image_viewer.dart';
import 'widgets/chat_search_overlay.dart';
import 'widgets/pinned_message_bar.dart';
import 'widgets/media_picker_helper.dart';
import 'widgets/media_preview_strip.dart';
import 'widgets/report_message_sheet.dart';
import 'widgets/chat_quick_pills.dart';
import 'widgets/chat_features_info_sheet.dart';
import 'widgets/enhanced_empty_state.dart';
import 'widgets/voice_message_widget.dart';
import '../../core/models/chat_quick_action.dart';
import '../../core/providers/usage_tracking_provider.dart';
import '../../core/services/posthog_service.dart';
import '../../widgets/upgrade_prompt_sheet.dart';

/// Media send status for progressive loading states
enum _MediaSendStatus {
  idle,
  uploading,     // "Uploading image..." / "Uploading video..."
  analyzing,     // "Analyzing nutrition..." / "Checking exercise form..." / "Reading menu..."
  generating,    // "Generating response..." / "Thinking..."
}

/// Feature keys for premium gating
const _kFoodScanning = 'food_scanning';
const _kFormVideoAnalysis = 'form_video_analysis';
const _kAiChatMessages = 'ai_chat_messages';

/// Quick action IDs that require food_scanning gate
const _foodScanActions = {'scan_food', 'analyze_menu', 'calorie_check'};

/// Quick action IDs that require form_video_analysis gate
const _formVideoActions = {'check_form', 'compare_form'};

class ChatScreen extends ConsumerStatefulWidget {
  final String? initialMessage;

  const ChatScreen({
    super.key,
    this.initialMessage,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  _MediaSendStatus _sendStatus = _MediaSendStatus.idle;
  DateTime? _sendStartTime;
  Timer? _elapsedTimer;
  bool _initialMessageSent = false;
  bool _showScrollFAB = false;
  String? _highlightedMessageId;

  bool get _isLoading => _sendStatus != _MediaSendStatus.idle;

  String get _statusLabel {
    switch (_sendStatus) {
      case _MediaSendStatus.idle:
        return '';
      case _MediaSendStatus.uploading:
        return 'Uploading...';
      case _MediaSendStatus.analyzing:
        return 'Analyzing...';
      case _MediaSendStatus.generating:
        return 'Thinking...';
    }
  }

  String get _elapsedLabel {
    if (_sendStartTime == null) return '';
    final elapsed = DateTime.now().difference(_sendStartTime!).inSeconds;
    return '(${elapsed}s)';
  }

  void _startSendStatus(_MediaSendStatus status) {
    setState(() {
      _sendStatus = status;
      _sendStartTime = DateTime.now();
    });
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _isLoading) setState(() {});
    });
  }

  void _updateSendStatus(_MediaSendStatus status) {
    if (mounted) setState(() => _sendStatus = status);
  }

  void _stopSendStatus() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    if (mounted) {
      setState(() {
        _sendStatus = _MediaSendStatus.idle;
        _sendStartTime = null;
      });
    }
  }

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

  /// Callback for _InputBar to send a voice message
  Future<void> _sendVoiceMessage(File audioFile, int durationMs) async {
    _startSendStatus(_MediaSendStatus.generating);
    try {
      await ref.read(chatMessagesProvider.notifier).sendVoiceMessage(audioFile, durationMs);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send voice message: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      _stopSendStatus();
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final show = _scrollController.offset > 200;
      if (show != _showScrollFAB) setState(() => _showScrollFAB = show);

      // Load older messages when scrolling near the top (max extent in reversed list)
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        ref.read(chatMessagesProvider.notifier).loadOlderMessages();
      }
    });
    // Load chat history on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatMessagesProvider.notifier).loadHistory();

      // If initial message provided, send it automatically after history loads
      if (widget.initialMessage != null &&
          widget.initialMessage!.isNotEmpty &&
          !_initialMessageSent) {
        _initialMessageSent = true;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _textController.text = widget.initialMessage!;
            _sendMessage();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
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

      // Refresh nutrition tab
      if (userId.isNotEmpty) {
        ref.read(nutritionProvider.notifier).loadTodaySummary(userId, forceRefresh: true);
      }

      if (!mounted) return;
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _scrollController.offset > 0) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scrollToMessage(String messageId) {
    final messages = ref.read(chatMessagesProvider).valueOrNull ?? [];
    final idx = messages.indexWhere((m) => m.id == messageId);
    if (idx >= 0 && _scrollController.hasClients) {
      final reversedIndex = messages.length - 1 - idx;
      final estimatedOffset = reversedIndex * 80.0;
      _scrollController.animateTo(
        estimatedOffset.clamp(0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
      setState(() => _highlightedMessageId = messageId);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _highlightedMessageId = null);
      });
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

  /// Minimize - shrink back to floating chat overlay with seamless animation
  void _minimizeToFloatingChat() {
    HapticService.light();
    // Capture ref before pop since widget may unmount
    final currentRef = ref;
    final currentContext = context;
    // Pop the full screen, then show floating chat after animation completes
    Navigator.of(context).pop();
    // Use WidgetsBinding to ensure the pop frame is fully processed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (currentContext.mounted) {
          showChatBottomSheetNoAnimation(currentContext, currentRef);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(chatMessagesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final offlineChatState = ref.watch(offlineChatStateProvider);

    // Get coach persona from AI settings
    final aiSettings = ref.watch(aiSettingsProvider);
    final coach = CoachPersona.findById(aiSettings.coachPersonaId) ?? CoachPersona.defaultCoach;
    final coachName = coach.name;

    final topBarColor = isDark ? const Color(0xFF1C1C1E) : AppColorsLight.elevated;
    final topBarBorder = isDark
        ? null
        : Border.all(color: (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder).withValues(alpha: 0.3));
    final topBarShadow = BoxShadow(
      color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.1),
      blurRadius: 12,
      offset: const Offset(0, 4),
    );
    final statusColor = _isLoading
        ? AppColors.orange
        : offlineChatState.isAvailable
            ? Colors.amber
            : AppColors.success;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Main chat content — padded below the top bar
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + 60),
          // Pinned message bar
          if (messagesState.valueOrNull != null)
            Builder(builder: (context) {
              final pinnedMsg = messagesState.valueOrNull!
                  .cast<ChatMessage?>()
                  .firstWhere((m) => m!.isPinned, orElse: () => null);
              if (pinnedMsg == null) return const SizedBox.shrink();
              return PinnedMessageBar(
                message: pinnedMsg,
                onTap: () => _scrollToMessage(pinnedMsg.id ?? ''),
                onUnpin: () => ref.read(chatMessagesProvider.notifier).togglePin(pinnedMsg.id!),
              );
            }),
          // Messages
          Expanded(
            child: Stack(
              children: [
                AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: messagesState.when(
                loading: () => const Center(
                  key: ValueKey('loading'),
                  child: CircularProgressIndicator(color: AppColors.cyan),
                ),
                error: (e, _) => Center(
                  key: const ValueKey('error'),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text('Failed to load messages: $e'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          HapticService.medium();
                          ref.read(chatMessagesProvider.notifier).loadHistory();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (messages) {
                  if (messages.isEmpty) {
                    return EnhancedEmptyState(
                      key: const ValueKey('empty'),
                      coach: coach,
                      onSuggestionTap: (suggestion) {
                        _textController.text = suggestion;
                        _sendMessage();
                      },
                    );
                  }

                  final hasMore = ref.read(chatMessagesProvider.notifier).hasMoreMessages;
                  final extraItems = (_isLoading ? 1 : 0) + (hasMore ? 1 : 0);

                  return ListView.builder(
                    key: const ValueKey('content'),
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length + extraItems,
                    itemBuilder: (context, index) {
                      // With reverse: true, index 0 = bottom (newest).
                      // Typing indicator is the newest item (index 0).
                      if (index == 0 && _isLoading) {
                        return _TypingIndicator(
                          statusText: _statusLabel,
                          elapsed: _elapsedLabel,
                        );
                      }

                      // Loading-more indicator at the END (visually at top in reversed list)
                      final lastIndex = messages.length + extraItems - 1;
                      if (hasMore && index == lastIndex) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                        );
                      }

                      // Offset by 1 if loading indicator is shown
                      final msgIndex = messages.length - 1 - (index - (_isLoading ? 1 : 0));
                      if (msgIndex < 0 || msgIndex >= messages.length) {
                        return const SizedBox.shrink();
                      }
                      final message = messages[msgIndex];
                      // Find the previous user message for context when reporting
                      String? previousUserMessage;
                      if (message.role == 'assistant') {
                        for (int i = msgIndex - 1; i >= 0; i--) {
                          if (messages[i].role == 'user') {
                            previousUserMessage = messages[i].content;
                            break;
                          }
                        }
                      }

                      // Date separator: In a reversed list, index 0 = newest (bottom).
                      // Show a date header above the FIRST message of each day group.
                      // In reversed order, check if the NEWER message (index-1, visually
                      // below) belongs to a different day. If so, this message is the
                      // last of its day group (visually topmost), so place the header here.
                      Widget? dateSeparator;
                      final newerIndex = msgIndex - 1;
                      if (newerIndex >= 0) {
                        final currentDate = message.timestamp ?? DateTime.now();
                        final newerDate = messages[newerIndex].timestamp ?? DateTime.now();
                        if (!_isSameDay(currentDate, newerDate)) {
                          dateSeparator = _buildDateSeparator(currentDate);
                        }
                      }
                      // Always show header for the newest message group (index 0)
                      if (msgIndex == 0) {
                        dateSeparator = _buildDateSeparator(message.timestamp ?? DateTime.now());
                      }

                      final bubble = _MessageBubble(
                        key: ValueKey(message.id ?? 'msg_$msgIndex'),
                        message: message,
                        previousUserMessage: previousUserMessage,
                        coach: coach,
                        onLogAnalysisItems: _logAnalysisItems,
                        onRetry: (message.role == 'error' || message.status == MessageStatus.error)
                            ? () => _retryMessage(messages, msgIndex)
                            : null,
                        onRegenerate: message.role == 'assistant' ? () => _regenerateResponse(messages, msgIndex) : null,
                      ).animate().fadeIn(duration: 200.ms);

                      // Highlight animation for scroll-to-message
                      final isHighlighted = _highlightedMessageId != null && message.id == _highlightedMessageId;
                      final wrappedBubble = isHighlighted
                          ? Container(
                              decoration: BoxDecoration(
                                color: AppColors.cyan.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: bubble,
                            )
                          : bubble;

                      if (dateSeparator != null) {
                        // Column renders top-to-bottom even inside a reversed ListView.
                        // Separator above, bubble below.
                        return Column(
                          children: [dateSeparator, wrappedBubble],
                        );
                      }
                      return wrappedBubble;
                    },
                  );
                },
              ),
            ),
              // Scroll-to-bottom FAB
              Positioned(
                right: 16,
                bottom: 16,
                child: AnimatedScale(
                  scale: _showScrollFAB ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: FloatingActionButton.small(
                    heroTag: 'scroll_to_bottom',
                    backgroundColor: AppColors.elevated,
                    onPressed: _scrollToBottom,
                    child: const Icon(Icons.keyboard_arrow_down, color: AppColors.textPrimary),
                  ),
                ),
              ),
            ],
          ),
          ),

          // Low usage warning strip
          Builder(builder: (context) {
            final usageState = ref.watch(usageTrackingProvider);
            if (usageState.isPremium) return const SizedBox.shrink();
            final feature = usageState.limits[_kAiChatMessages];
            if (feature == null) return const SizedBox.shrink();
            final remaining = feature.remaining ?? ((feature.limit ?? 0) - feature.used);
            final limit = feature.limit ?? 0;
            if (remaining > 5 || remaining <= 0 || limit == 0) return const SizedBox.shrink();
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: AppColors.warning.withOpacity(isDark ? 0.15 : 0.1),
              child: Text(
                '$remaining message${remaining == 1 ? '' : 's'} left today',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.warning : Colors.orange.shade800,
                ),
              ),
            );
          }),

          // Medical disclaimer
          const MedicalDisclaimerBanner(),

          // Quick action pills
          ChatQuickPills(
            onSendPrompt: (prompt) {
              _textController.text = prompt;
              _sendMessage();
            },
            onOpenMediaPicker: (mode, contextPrompt) =>
                _handleMediaFromPill(mode, contextPrompt),
            isLoading: _isLoading,
          ),

          // Input bar
          _InputBar(
            controller: _textController,
            focusNode: _focusNode,
            isLoading: _isLoading,
            onSend: _sendMessage,
            onSendWithMedia: _sendMessageWithMedia,
            onSendWithMultiMedia: _sendMessageWithMultiMedia,
            onSendVoiceMessage: _sendVoiceMessage,
            isOffline: offlineChatState.isAvailable,
            modelName: offlineChatState.modelName,
          ),
        ],
      ),

      // Floating pill top bar — matches workout detail screen style
      Positioned(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        child: Row(
          children: [
            // Back button circle
            GestureDetector(
              onTap: () {
                HapticService.light();
                context.pop();
              },
              child: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: topBarColor,
                  borderRadius: BorderRadius.circular(22),
                  border: topBarBorder,
                  boxShadow: [topBarShadow],
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? Colors.white : AppColorsLight.textPrimary,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Coach name + status — expanded pill
            Expanded(
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: topBarColor,
                  borderRadius: BorderRadius.circular(22),
                  border: topBarBorder,
                  boxShadow: [topBarShadow],
                ),
                child: Row(
                  children: [
                    CoachAvatar(
                      coach: coach,
                      size: 30,
                      showBorder: true,
                      showShadow: false,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            coachName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppColorsLight.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(right: 4),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  _isLoading
                                      ? 'Typing...'
                                      : offlineChatState.isAvailable
                                          ? 'Offline'
                                          : 'Online',
                                  style: TextStyle(fontSize: 11, color: statusColor),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Usage info button circle
            GestureDetector(
              onTap: () {
                HapticService.light();
                _showUsageInfoSheet(context);
              },
              child: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: topBarColor,
                  borderRadius: BorderRadius.circular(22),
                  border: topBarBorder,
                  boxShadow: [topBarShadow],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: isDark ? Colors.white70 : AppColorsLight.textSecondary,
                      size: 20,
                    ),
                    // Warning dot when messages are running low
                    Builder(builder: (context) {
                      final remaining = ref.watch(usageTrackingProvider).limits[_kAiChatMessages];
                      final left = remaining?.remaining ?? remaining?.limit;
                      if (left != null && left <= 5 && left > 0) {
                        return Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Search + More pill
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: topBarColor,
                borderRadius: BorderRadius.circular(22),
                border: topBarBorder,
                boxShadow: [topBarShadow],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticService.light();
                      final messagesData = ref.read(chatMessagesProvider).valueOrNull ?? [];
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ChatSearchOverlay(
                          messages: messagesData,
                          onScrollToMessage: (messageId) {
                            Navigator.of(context).pop();
                            _scrollToMessage(messageId);
                          },
                        ),
                      ));
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(
                        Icons.search_rounded,
                        color: isDark ? Colors.white70 : AppColorsLight.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 20,
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticService.light();
                      _showOptionsMenu(context);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(
                        Icons.more_vert_rounded,
                        color: isDark ? Colors.white70 : AppColorsLight.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  ),
);
  }

  void _showUsageInfoSheet(BuildContext context) {
    final usageState = ref.read(usageTrackingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
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
              if (usageState.isPremium)
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
  }

  bool _isSameDay(DateTime a, DateTime b) {
    // Convert to local time so UTC timestamps compare correctly with local dates
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final local = date.toLocal();
    final messageDate = DateTime(local.year, local.month, local.day);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String label;
    if (messageDate == today) {
      label = 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      label = 'Yesterday';
    } else {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      label = '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.elevated.withOpacity(0.7)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textMuted : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _retryMessage(List<ChatMessage> messages, int errorIndex) {
    // Find the user message that preceded this error
    String? userMessage;
    for (int i = errorIndex - 1; i >= 0; i--) {
      if (messages[i].role == 'user') {
        userMessage = messages[i].content;
        break;
      }
    }
    if (userMessage != null && userMessage.isNotEmpty) {
      // Remove the error message and resend
      final errorMsg = messages[errorIndex];
      if (errorMsg.id != null) {
        ref.read(chatMessagesProvider.notifier).deleteMessage(errorMsg.id!);
      }
      _textController.text = userMessage;
      _sendMessage();
    }
  }

  /// Regenerate an AI response by removing it and resending the previous user message
  Future<void> _regenerateResponse(List<ChatMessage> messages, int aiMsgIndex) async {
    // Find the previous user message
    String? userMessage;
    for (int i = aiMsgIndex - 1; i >= 0; i--) {
      if (messages[i].role == 'user') {
        userMessage = messages[i].content;
        break;
      }
    }
    if (userMessage == null || userMessage.isEmpty) return;

    // Remove the AI response and await completion before resending
    final aiMsg = messages[aiMsgIndex];
    if (aiMsg.id != null) {
      await ref.read(chatMessagesProvider.notifier).deleteMessage(aiMsg.id!);
    } else {
      final current = ref.read(chatMessagesProvider).valueOrNull ?? [];
      final updated = current.where((m) => m != aiMsg).toList();
      ref.read(chatMessagesProvider.notifier).state = AsyncValue.data(updated);
    }

    // Resend the user message
    _textController.text = userMessage;
    _sendMessage();
  }

  void _showFeaturesInfoSheet() {
    showGlassSheet(
      context: context,
      builder: (context) => ChatFeaturesInfoSheet(
        onAction: (action) => _handleQuickAction(action),
      ),
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

  void _handleQuickAction(ChatQuickAction action) {
    if (_isLoading) return;

    // Premium gate: check form video analysis actions
    if (_formVideoActions.contains(action.id)) {
      final notifier = ref.read(usageTrackingProvider.notifier);
      if (!notifier.hasAccess(_kFormVideoAnalysis)) {
        showUpgradePromptSheet(context,
            featureKey: _kFormVideoAnalysis,
            featureName: 'Form Video Analysis');
        return;
      }
    }

    // Premium gate: check food scanning actions
    if (_foodScanActions.contains(action.id)) {
      final notifier = ref.read(usageTrackingProvider.notifier);
      if (!notifier.hasAccess(_kFoodScanning)) {
        showUpgradePromptSheet(context,
            featureKey: _kFoodScanning, featureName: 'Food Scans');
        return;
      }
    }

    if (action.behavior == ChatActionBehavior.sendPrompt && action.prompt != null) {
      _textController.text = action.prompt!;
      _sendMessage();
    } else if (action.behavior == ChatActionBehavior.openMediaPicker) {
      _showMiniMediaChoiceForAction(action);
    }
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
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniPickerOption({
    required BuildContext ctx,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colors = ThemeColors.of(ctx);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: colors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _handleMediaFromPill(ChatMediaMode mode, String contextPrompt) async {
    if (_isLoading) return;

    // Set the context prompt before picking media
    if (contextPrompt.isNotEmpty) {
      _textController.text = contextPrompt;
    }

    try {
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

  void _showEscalateToHumanDialog() {
    showDialog(
      context: context,
      builder: (_) => const _EscalateToHumanDialog(),
    );
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevated,
        title: const Text('Clear Chat History?'),
        content: const Text(
          'This will delete all your conversation history with the AI coach. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(chatMessagesProvider.notifier).clearHistory();
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    final aiSettings = ref.read(aiSettingsProvider);
    final coach = CoachPersona.findById(aiSettings.coachPersonaId) ?? CoachPersona.defaultCoach;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevated,
        title: Row(
          children: [
            CoachAvatar(
              coach: coach,
              size: 40,
              showBorder: true,
              showShadow: false,
              enableTapToView: false, // Already in a dialog
            ),
            const SizedBox(width: 12),
            Text(coach.name),
          ],
        ),
        content: const Text(
          'Your personal AI-powered fitness coach. Ask about workouts, nutrition, recovery, or any fitness-related questions. The AI learns from your progress to give personalized advice.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

// _EmptyChat replaced by EnhancedEmptyState widget

// ─────────────────────────────────────────────────────────────────
// Message Bubble
// ─────────────────────────────────────────────────────────────────

class _MessageBubble extends ConsumerWidget {
  final ChatMessage message;
  final String? previousUserMessage;
  final CoachPersona coach;
  final void Function(List<Map<String, dynamic>>)? onLogAnalysisItems;
  final VoidCallback? onRetry;
  final VoidCallback? onRegenerate;

  const _MessageBubble({
    super.key,
    required this.message,
    required this.coach,
    this.previousUserMessage,
    this.onLogAnalysisItems,
    this.onRetry,
    this.onRegenerate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUser = message.role == 'user';
    final isSystem = message.role == 'system';
    final isError = message.role == 'error';

    // Resolve the coach for this specific message: use stored persona if available,
    // otherwise fall back to the current global coach (for old messages without stored persona)
    final messageCoach = (message.coachPersonaId != null
        ? CoachPersona.findById(message.coachPersonaId)
        : null) ?? coach;

    // System messages (like coach change notifications) are displayed centered
    if (isSystem) {
      return _buildSystemMessage(context);
    }

    // Error messages are displayed with distinct warning styling
    if (isError) {
      return _buildErrorMessage(context);
    }

    // Wrap AI messages with GestureDetector for long-press to report
    Widget bubbleContent = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
      ),
      decoration: BoxDecoration(
        color: isUser ? AppColors.cyan : AppColors.elevated,
        borderRadius: BorderRadius.circular(16).copyWith(
          bottomRight: isUser ? const Radius.circular(4) : null,
          bottomLeft: !isUser ? const Radius.circular(4) : null,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CoachAvatar(
                    coach: messageCoach,
                    size: 20,
                    showBorder: true,
                    borderWidth: 1,
                    showShadow: false,
                    enableTapToView: false, // Too small, don't interrupt chat
                  ),
                  const SizedBox(width: 6),
                  Text(
                    messageCoach.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: messageCoach.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          // Show media thumbnail for user messages with media
          if (isUser && message.hasMedia)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: message.mediaType != 'video'
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FullscreenImageViewer(
                              imageUrl: message.mediaUrl,
                              localFilePath: message.localFilePath,
                              heroTag: 'chat_media_${message.id}',
                            ),
                          ),
                        )
                    : null,
                child: Hero(
                  tag: 'chat_media_${message.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      height: 150,
                      child: Stack(
                        children: [
                          if (message.localFilePath != null)
                            Image.file(
                              File(message.localFilePath!),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 150,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.black12,
                                child: Center(
                                  child: Icon(
                                    message.mediaType == 'video' ? Icons.videocam : Icons.image,
                                    size: 32,
                                    color: Colors.white54,
                                  ),
                                ),
                              ),
                            )
                          else if (message.mediaUrl != null)
                            CachedNetworkImage(
                              imageUrl: message.mediaUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 150,
                              placeholder: (_, __) => Container(
                                color: Colors.black12,
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: Colors.black12,
                                child: Center(
                                  child: Icon(
                                    message.mediaType == 'video' ? Icons.videocam : Icons.image,
                                    size: 32,
                                    color: Colors.white54,
                                  ),
                                ),
                              ),
                            ),
                          // Upload/analyze progress overlay — shown while video is processing
                          if (message.uploadPhase != null)
                            Positioned.fill(
                              child: _MediaUploadOverlay(
                                phase: message.uploadPhase!,
                                progress: message.uploadProgress,
                              ),
                            )
                          else if (message.mediaType == 'video')
                            const Positioned.fill(
                              child: Center(
                                child: Icon(Icons.play_circle_outline, color: Colors.white70, size: 40),
                              ),
                            ),
                          if (isUser && message.mediaRefs != null && message.mediaRefs!.length > 1)
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '+${message.mediaRefs!.length - 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Show upload progress indicator for user messages without URL (uploading)
          if (isUser && !message.hasMedia && message.mediaType != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 48,
                  width: 140,
                  decoration: BoxDecoration(
                    color: AppColors.pureBlack.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.pureBlack.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Uploading...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.pureBlack.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (message.isVoiceMessage)
            VoiceMessageBubble(
              audioUrl: message.audioUrl!,
              durationMs: message.audioDurationMs ?? 0,
            )
          else
            Text(
              message.content,
              style: TextStyle(
                color: isUser ? AppColors.pureBlack : AppColors.textPrimary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          // Show form check result card for assistant messages
          if (!isUser && message.hasFormCheckResult)
            FormCheckResultCard(result: message.formCheckResult!),
          // Show inline food analysis card for plate scans (1-5 items)
          if (!isUser && message.hasFoodAnalysis &&
              (message.actionData!['food_items'] as List).length <= 5)
            FoodAnalysisInlineCard(
              foodItems: (message.actionData!['food_items'] as List)
                  .cast<Map<String, dynamic>>(),
              onLogItems: onLogAnalysisItems != null
                  ? (items) => onLogAnalysisItems!(items)
                  : (_) {},
            ),
          // Show compact summary for plate scans with 6+ items (opens MenuAnalysisSheet)
          if (!isUser && message.hasFoodAnalysis &&
              (message.actionData!['food_items'] as List).length > 5)
            _FoodAnalysisSummaryCard(
              foodItems: (message.actionData!['food_items'] as List)
                  .cast<Map<String, dynamic>>(),
              onViewAll: onLogAnalysisItems,
            ),
          // Show multi-food/buffet/menu analysis result card
          if (!isUser && (message.hasBuffetAnalysis || message.hasMenuAnalysis ||
              (message.actionData?['action'] == 'analyze_multi_food_images')))
            FoodAnalysisResultCard(
              data: message.actionData!,
              onLogItems: onLogAnalysisItems != null ? (items) => onLogAnalysisItems!(items) : null,
            ),
          // Show form comparison result card
          if (!isUser && message.hasFormComparison)
            FormComparisonResultCard(data: message.actionData!),
          // Show "Go to workout" button if AI generated a workout
          if (!isUser && message.hasGeneratedWorkout)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _GoToWorkoutButton(
                workoutId: message.workoutId!,
                workoutName: message.workoutName,
              ),
            ),
          // Always show timestamp + delivery status
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp ?? DateTime.now()),
                  style: TextStyle(
                    fontSize: 10,
                    color: isUser
                        ? AppColors.pureBlack.withOpacity(0.6)
                        : AppColors.textMuted,
                  ),
                ),
                if (isUser) ...[
                  const SizedBox(width: 4),
                  _buildStatusIcon(message.status),
                ],
              ],
            ),
          ),
          // Show offline model badge if message was generated offline
          if (!isUser && message.actionData?['offline'] == true)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Generated offline by ${message.actionData?['model'] ?? 'Local AI'}',
                style: TextStyle(
                  fontSize: 9,
                  fontStyle: FontStyle.italic,
                  color: isUser
                      ? AppColors.pureBlack.withOpacity(0.4)
                      : AppColors.textMuted.withOpacity(0.6),
                ),
              ),
            ),
        ],
      ),
    );

    // Long-press context menu for all messages
    bubbleContent = GestureDetector(
      onLongPress: () {
        HapticService.medium();
        _showMessageContextMenu(context, ref, isUser);
      },
      child: bubbleContent,
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: bubbleContent,
    );
  }

  Widget _buildStatusIcon(MessageStatus status) {
    final statusColor = AppColors.pureBlack.withOpacity(0.5);
    switch (status) {
      case MessageStatus.pending:
        return Icon(Icons.access_time, size: 10, color: statusColor);
      case MessageStatus.sent:
        return Icon(Icons.check, size: 10, color: statusColor);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 10, color: AppColors.cyan);
      case MessageStatus.error:
        return const Icon(Icons.close, size: 10, color: AppColors.error);
    }
  }

  void _showMessageContextMenu(BuildContext context, WidgetRef ref, bool isUser) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.elevated : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Copy
                ListTile(
                  leading: const Icon(Icons.copy, size: 20),
                  title: const Text('Copy'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Clipboard.setData(ClipboardData(text: message.content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                // Regenerate (AI messages only)
                if (!isUser && onRegenerate != null)
                  ListTile(
                    leading: const Icon(Icons.refresh, size: 20),
                    title: const Text('Regenerate'),
                    onTap: () {
                      Navigator.pop(ctx);
                      onRegenerate!();
                    },
                  ),
                // Pin / Unpin
                if (message.id != null)
                  ListTile(
                    leading: Icon(
                      message.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      size: 20,
                    ),
                    title: Text(message.isPinned ? 'Unpin' : 'Pin'),
                    onTap: () {
                      Navigator.pop(ctx);
                      ref.read(chatMessagesProvider.notifier).togglePin(message.id!);
                    },
                  ),
                // Delete (user messages only)
                if (isUser)
                  ListTile(
                    leading: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                    title: const Text('Delete', style: TextStyle(color: AppColors.error)),
                    onTap: () {
                      Navigator.pop(ctx);
                      showDialog(
                        context: context,
                        builder: (dlgCtx) => AlertDialog(
                          title: const Text('Delete this message?'),
                          content: const Text('This action cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dlgCtx),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(dlgCtx);
                                if (message.id != null) {
                                  ref.read(chatMessagesProvider.notifier).deleteMessage(message.id!);
                                } else {
                                  final current = ref.read(chatMessagesProvider).valueOrNull ?? [];
                                  final updated = current.where((m) => m != message).toList();
                                  ref.read(chatMessagesProvider.notifier).state = AsyncValue.data(updated);
                                }
                              },
                              child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                // Report (AI messages only)
                if (!isUser)
                  ListTile(
                    leading: const Icon(Icons.flag_outlined, size: 20, color: AppColors.orange),
                    title: const Text('Report'),
                    onTap: () {
                      Navigator.pop(ctx);
                      showReportMessageSheet(
                        context,
                        messageId: message.id,
                        originalUserMessage: previousUserMessage ?? '',
                        aiResponse: message.content,
                      );
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build a system notification message (centered, subtle styling)
  Widget _buildErrorMessage(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.red.withOpacity(0.1)
              : Colors.red.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: isDark ? Colors.red[300] : Colors.red[600],
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.red[300] : Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
            if (onRetry != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  onPressed: onRetry,
                  icon: Icon(Icons.refresh, size: 14, color: isDark ? Colors.red[300] : Colors.red[600]),
                  label: Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.red[300] : Colors.red[600],
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemMessage(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.glassSurface
              : AppColorsLight.glassSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? AppColors.cardBorder.withOpacity(0.5)
                : AppColorsLight.cardBorder.withOpacity(0.5),
          ),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);

    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute';

    if (messageDate == today) {
      return timeStr;
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, $timeStr';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[time.month - 1]} ${time.day}, $timeStr';
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// Typing Indicator
// ─────────────────────────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  final String? statusText;
  final String? elapsed;

  const _TypingIndicator({this.statusText, this.elapsed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.elevated : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: const Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...List.generate(3, (index) {
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.textMuted : Colors.grey.shade400,
                  shape: BoxShape.circle,
                ),
              )
                  .animate(
                    onPlay: (controller) => controller.repeat(),
                  )
                  .fadeIn(delay: Duration(milliseconds: index * 200))
                  .then()
                  .fadeOut(delay: const Duration(milliseconds: 400));
            }),
            if (statusText != null && statusText!.isNotEmpty) ...[
              const SizedBox(width: 10),
              Text(
                '$statusText${elapsed != null && elapsed!.isNotEmpty ? ' $elapsed' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textMuted : Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Input Bar
// ─────────────────────────────────────────────────────────────────

class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onSend;
  final Future<void> Function(PickedMedia media) onSendWithMedia;
  final Future<void> Function(List<PickedMedia> mediaList) onSendWithMultiMedia;
  final Future<void> Function(File, int) onSendVoiceMessage;
  final bool isOffline;
  final String? modelName;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
    required this.onSendWithMedia,
    required this.onSendWithMultiMedia,
    required this.onSendVoiceMessage,
    this.isOffline = false,
    this.modelName,
  });

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  List<PickedMedia> _selectedMedia = [];
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _pickMedia() async {
    debugPrint('🔍 [_InputBar] _pickMedia called');
    try {
      final result = await MediaPickerHelper.showMediaPickerSheet(context);
      debugPrint('🔍 [_InputBar] _pickMedia result: ${result?.media.length ?? 'null'}');
      if (result != null && result.isNotEmpty && mounted) {
        setState(() {
          // Append picked media, enforce max 5
          final combined = [..._selectedMedia, ...result.media];
          _selectedMedia = combined.take(5).toList();
        });
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
    } catch (e, stackTrace) {
      debugPrint('❌ [_InputBar] _pickMedia unexpected error: $e');
      debugPrint('❌ [_InputBar] Stack trace: $stackTrace');
    }
  }

  void _pickImageFromCamera() async {
    debugPrint('🔍 [_InputBar] _pickImageFromCamera called');
    try {
      final media = await MediaPickerHelper.pickImage(ImageSource.camera, context: context);
      if (media != null && mounted) {
        setState(() {
          final combined = [..._selectedMedia, media];
          _selectedMedia = combined.take(5).toList();
        });
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

  void _pickVideo() {
    debugPrint('🔍 [_InputBar] _pickVideo called');
    final colors = ThemeColors.of(context);
    final isDark = colors.isDark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
              Text(
                'Add Video',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _VideoPickerOption(
                icon: Icons.videocam_outlined,
                label: 'Record Video',
                subtitle: 'Use camera (max 60s)',
                color: const Color(0xFFF97316),
                onTap: () async {
                  Navigator.pop(ctx);
                  HapticService.selection();
                  try {
                    final media = await MediaPickerHelper.pickVideo(ImageSource.camera);
                    if (media != null && mounted) {
                      setState(() {
                        final combined = [..._selectedMedia, media];
                        _selectedMedia = combined.take(5).toList();
                      });
                    }
                  } on MediaValidationException catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 8),
              _VideoPickerOption(
                icon: Icons.video_library_outlined,
                label: 'Choose Video',
                subtitle: 'From gallery (max 60s)',
                color: const Color(0xFFA855F7),
                onTap: () async {
                  Navigator.pop(ctx);
                  HapticService.selection();
                  try {
                    final media = await MediaPickerHelper.pickVideo(ImageSource.gallery);
                    if (media != null && mounted) {
                      setState(() {
                        final combined = [..._selectedMedia, media];
                        _selectedMedia = combined.take(5).toList();
                      });
                    }
                  } on MediaValidationException catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSend() {
    if (_selectedMedia.isNotEmpty) {
      final mediaList = List<PickedMedia>.from(_selectedMedia);
      setState(() => _selectedMedia = []);
      if (mediaList.length == 1) {
        widget.onSendWithMedia(mediaList.first);
      } else {
        widget.onSendWithMultiMedia(mediaList);
      }
    } else {
      widget.onSend();
    }
    // Dismiss keyboard after send
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final isDark = colors.isDark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.nearBlack : Colors.white,
        border: Border(
          top: BorderSide(color: colors.cardBorder.withOpacity(0.5)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Media preview strip
          if (_selectedMedia.isNotEmpty)
            MediaPreviewStrip(
              mediaList: _selectedMedia,
              onRemoveAt: (index) => setState(() => _selectedMedia.removeAt(index)),
              onInsertAt: (index, media) => setState(() => _selectedMedia.insert(index, media)),
              onAddMore: _pickMedia,
            ),

          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isOffline)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.phone_android, size: 12, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          'Offline AI${widget.modelName != null ? ' \u00b7 ${widget.modelName}' : ''}',
                          style: const TextStyle(fontSize: 11, color: Colors.amber),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    // Camera button (quick image)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.isLoading ? null : _pickImageFromCamera,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.camera_alt_outlined,
                          size: 18,
                          color: widget.isLoading
                              ? colors.textMuted
                              : colors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Video button
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.isLoading ? null : _pickVideo,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.videocam_outlined,
                          size: 18,
                          color: widget.isLoading
                              ? colors.textMuted
                              : const Color(0xFFF97316),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Media picker button (gallery + video)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.isLoading ? null : _pickMedia,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.attach_file_outlined,
                          size: 18,
                          color: widget.isLoading
                              ? colors.textMuted
                              : colors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Text field
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        focusNode: widget.focusNode,
                        enabled: true,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 4,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: _selectedMedia.isNotEmpty
                              ? 'Add a message (optional)...'
                              : (widget.isLoading ? 'Type your next message...' : 'Ask your AI coach...'),
                          filled: true,
                          fillColor: colors.glassSurface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Send or Voice button
                    if (_hasText || _selectedMedia.isNotEmpty || widget.isLoading)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.isLoading
                                ? [colors.textMuted, colors.textMuted]
                                : [AppColors.cyan, AppColors.purple],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: widget.isLoading ? null : _handleSend,
                          icon: widget.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                ),
                        ),
                      )
                    else
                      VoiceRecorderButton(
                        onRecordingComplete: (audioFile, durationMs) {
                          widget.onSendVoiceMessage(audioFile, durationMs);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Video Picker Option (for _InputBar video button)
// ─────────────────────────────────────────────────────────────────

class _VideoPickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _VideoPickerOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Go to Workout Button
// ─────────────────────────────────────────────────────────────────

class _GoToWorkoutButton extends StatelessWidget {
  final String workoutId;
  final String? workoutName;

  const _GoToWorkoutButton({
    required this.workoutId,
    this.workoutName,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticService.selection();
        context.push('/workout/$workoutId');
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.cyan, AppColors.purple],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.fitness_center,
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                workoutName != null ? 'Go to $workoutName' : 'Go to Workout',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_forward,
              size: 16,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Escalate to Human Dialog
// ─────────────────────────────────────────────────────────────────

class _EscalateToHumanDialog extends ConsumerStatefulWidget {
  const _EscalateToHumanDialog();

  @override
  ConsumerState<_EscalateToHumanDialog> createState() => _EscalateToHumanDialogState();
}

class _EscalateToHumanDialogState extends ConsumerState<_EscalateToHumanDialog> {
  LiveChatCategory _selectedCategory = LiveChatCategory.general;
  bool _isLoading = false;

  Widget _buildTitle() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.cyan,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.support_agent, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        const Flexible(child: Text('Talk to Human Support')),
      ],
    );
  }

  Widget _buildCategoryList() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: LiveChatCategory.values.map((category) {
        return RadioListTile<LiveChatCategory>(
          contentPadding: EdgeInsets.zero,
          title: Text(
            category.displayName,
            style: const TextStyle(fontSize: 14),
          ),
          value: category,
          groupValue: _selectedCategory,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedCategory = value;
              });
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildAvailabilityInfo() {
    return Consumer(
      builder: (context, ref, child) {
        final availabilityAsync = ref.watch(liveChatAvailabilityProvider);
        return availabilityAsync.when(
          data: (availability) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: availability.isAvailable
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: availability.isAvailable
                      ? AppColors.success.withOpacity(0.3)
                      : AppColors.warning.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    availability.isAvailable
                        ? Icons.check_circle_outline
                        : Icons.schedule,
                    size: 20,
                    color: availability.isAvailable
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          availability.formattedWaitTime,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: availability.isAvailable
                                ? AppColors.success
                                : AppColors.warning,
                            fontSize: 13,
                          ),
                        ),
                        if (availability.currentQueueSize > 0)
                          Text(
                            '${availability.currentQueueSize} people in queue',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.cyan,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Checking availability...',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          error: (_, __) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.textMuted.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                SizedBox(width: 8),
                Text(
                  'Wait time unavailable',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'You will be connected with a real support agent who can help with your questions.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          const Text(
            'Select a category:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          _buildCategoryList(),
          const SizedBox(height: 16),
          _buildAvailabilityInfo(),
        ],
      ),
    );
  }

  Future<void> _handleConnect() async {
    setState(() => _isLoading = true);

    try {
      // Get last 10 messages from current AI chat as context
      final messagesState = ref.read(chatMessagesProvider);
      String aiContext = '';

      messagesState.whenData((messages) {
        final recentMessages = messages.length > 10
            ? messages.sublist(messages.length - 10)
            : messages;

        aiContext = recentMessages.map((m) {
          final role = m.role == 'user' ? 'User' : 'AI Coach';
          return '$role: ${m.content}';
        }).join('\n\n');
      });

      // Start live chat with escalation
      await ref.read(liveChatProvider.notifier).startChat(
            category: _selectedCategory.value,
            initialMessage:
                'Escalated from AI chat for ${_selectedCategory.displayName.toLowerCase()} help.',
            escalatedFromAi: true,
            aiContext: aiContext.isNotEmpty ? aiContext : null,
          );

      if (mounted) {
        Navigator.pop(context);
        HapticService.success();

        // Navigate to live chat screen
        context.push('/live-chat');
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  List<Widget> _buildActions() {
    return [
      TextButton(
        onPressed: _isLoading ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: _isLoading ? null : _handleConnect,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cyan,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Connect'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.elevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: _buildTitle(),
      content: _buildContent(),
      actions: _buildActions(),
    );
  }
}

/// Overlay shown on top of a video thumbnail while it is uploading or being analyzed.
///
/// - 'uploading': shows a real progress bar (0–100%) with upload icon
/// - 'analyzing': shows a pulsing shimmer bar with AI icon (indeterminate)
class _MediaUploadOverlay extends StatefulWidget {
  final String phase; // 'uploading' | 'analyzing'
  final double? progress; // 0.0–1.0 for uploading; null for analyzing

  const _MediaUploadOverlay({required this.phase, this.progress});

  @override
  State<_MediaUploadOverlay> createState() => _MediaUploadOverlayState();
}

class _MediaUploadOverlayState extends State<_MediaUploadOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUploading = widget.phase == 'uploading';
    final label = isUploading
        ? 'Uploading ${widget.progress != null ? '${(widget.progress! * 100).toInt()}%' : ''}'
        : 'Analyzing...';
    final icon = isUploading ? Icons.cloud_upload_outlined : Icons.auto_awesome;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 100,
                child: isUploading
                    ? LinearProgressIndicator(
                        value: widget.progress,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 3,
                      )
                    : AnimatedBuilder(
                        animation: _shimmer,
                        builder: (_, __) => LinearProgressIndicator(
                          value: null, // indeterminate
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          borderRadius: BorderRadius.circular(4),
                          minHeight: 3,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact summary card for food analysis with 6+ items.
/// Shows total count + macros and a "View All & Log" button that opens
/// the MenuAnalysisSheet.
class _FoodAnalysisSummaryCard extends StatelessWidget {
  final List<Map<String, dynamic>> foodItems;
  final void Function(List<Map<String, dynamic>>)? onViewAll;

  const _FoodAnalysisSummaryCard({
    required this.foodItems,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final isDark = colors.isDark;

    int totalCal = 0;
    int totalProtein = 0;
    for (final item in foodItems) {
      totalCal += (item['calories'] as num? ?? 0).toInt();
      totalProtein += (item['protein_g'] as num? ?? item['protein'] as num? ?? 0).toInt();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.glassSurface : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.restaurant_rounded, size: 16, color: AppColors.green),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${foodItems.length} items found',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '$totalCal cal total',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.coral,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${totalProtein}g protein',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.macroProtein,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _openMenuSheet(context, isDark);
              },
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: const Text('View All & Log'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openMenuSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MenuAnalysisSheet(
        foodItems: foodItems,
        analysisType: 'plate',
        isDark: isDark,
        onLogItems: (selected) => onViewAll?.call(selected),
      ),
    );
  }
}
