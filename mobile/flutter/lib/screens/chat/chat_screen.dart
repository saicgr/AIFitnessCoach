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
import 'widgets/chat_message_bubble.dart';
import 'widgets/chat_media_widgets.dart';
import '../../core/models/chat_quick_action.dart';
import '../../core/providers/usage_tracking_provider.dart';
import '../../core/services/posthog_service.dart';
import '../../widgets/upgrade_prompt_sheet.dart';
import 'package:fitwiz/core/constants/branding.dart';

part 'chat_screen_part_media_send_status.dart';

part 'chat_screen_ui.dart';

part 'chat_screen_ext.dart';


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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.initialMessage != null &&
          widget.initialMessage!.isNotEmpty &&
          !_initialMessageSent) {
        _initialMessageSent = true;
        // Await history so state is settled before sending — prevents race
        // condition where loadHistory's server fetch overwrites sendMessage state
        await ref.read(chatMessagesProvider.notifier).loadHistory();
        if (mounted) {
          _textController.text = widget.initialMessage!;
          _sendMessage();
        }
      } else {
        ref.read(chatMessagesProvider.notifier).loadHistory();
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

  /// Minimize - shrink back to floating chat overlay with seamless animation
  void _minimizeToFloatingChat() {
    HapticService.light();
    // Capture the navigator + provider container BEFORE popping. Once the
    // widget unmounts, our `ref` becomes invalid (Riverpod throws "Cannot use
    // ref after the widget was disposed" if accessed). The container survives
    // the pop because it's owned by the ProviderScope above us, so we can
    // safely use it from the delayed callback.
    final navigator = Navigator.of(context);
    final rootContext = navigator.context;
    final container = ProviderScope.containerOf(context);

    navigator.pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (rootContext.mounted) {
          showChatBottomSheetWithContainer(rootContext, container);
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
                error: (e, _) {
                  // Collapse noisy transport errors (DioException [connection
                  // timeout / connection error / receive timeout]) into a
                  // single user-readable line. Show the raw error only as a
                  // muted subtitle so we don't lose debug signal.
                  final errStr = e.toString();
                  final isTransport = errStr.contains('DioException') ||
                      errStr.contains('connection') ||
                      errStr.contains('timeout') ||
                      errStr.contains('SocketException');
                  final headline = isTransport
                      ? "Couldn't reach the coach."
                      : 'Something went wrong loading your chat.';
                  return Center(
                    key: const ValueKey('error'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            headline,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Check your connection and try again.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
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
                  );
                },
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

                      final bubble = ChatMessageBubble(
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

  bool _isSameDay(DateTime a, DateTime b) {
    // Convert to local time so UTC timestamps compare correctly with local dates
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
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
    if (userMessage == null || userMessage.isEmpty) return;

    // Remove the error bubble from local state unconditionally. Client-side
    // error bubbles typically have no server id, so the old id-guarded
    // deleteMessage path left the error bubble visible even after a successful
    // retry — confusing because the chat then showed [user][error][user][reply].
    final errorMsg = messages[errorIndex];
    final notifier = ref.read(chatMessagesProvider.notifier);
    final current = ref.read(chatMessagesProvider).valueOrNull ?? [];
    final cleaned = current.where((m) => !identical(m, errorMsg) && !(
        m.role == errorMsg.role &&
        m.content == errorMsg.content &&
        m.createdAt == errorMsg.createdAt)).toList();
    if (cleaned.length != current.length) {
      notifier.state = AsyncValue.data(cleaned);
    }
    if (errorMsg.id != null) {
      notifier.deleteMessage(errorMsg.id!); // Fire-and-forget server cleanup
    }

    _textController.text = userMessage;
    _sendMessage();
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
      // deleteMessage round-trips to the server. If the user popped the chat
      // during that hop we must NOT touch ref or trigger _sendMessage again.
      if (!mounted) return;
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

// _MediaUploadOverlay and _FoodAnalysisSummaryCard extracted to widgets/chat_media_widgets.dart
