import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../../widgets/glass_back_button.dart';
import '../../widgets/floating_chat/floating_chat_overlay.dart';
import '../../widgets/medical_disclaimer_banner.dart';
import '../ai_settings/ai_settings_screen.dart';
import 'widgets/food_analysis_result_card.dart';
import 'widgets/form_check_result_card.dart';
import 'widgets/form_comparison_result_card.dart';
import 'widgets/media_picker_helper.dart';
import 'widgets/media_preview_strip.dart';
import 'widgets/report_message_sheet.dart';
import 'widgets/chat_quick_pills.dart';
import 'widgets/chat_features_info_sheet.dart';
import 'widgets/enhanced_empty_state.dart';
import '../../core/models/chat_quick_action.dart';
import '../../core/providers/usage_tracking_provider.dart';
import '../../widgets/upgrade_prompt_sheet.dart';

/// Feature keys for premium gating
const _kFoodScanning = 'food_scanning';
const _kFormVideoAnalysis = 'form_video_analysis';

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
  bool _isLoading = false;
  bool _initialMessageSent = false;

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
      showUpgradePromptSheet(context,
          featureKey: gateKey, featureName: gateName);
      return;
    }

    // Check if this is the last free use
    final remaining = usageNotifier.remainingUses(gateKey);
    final isLastUse = remaining != null && remaining == 1;

    HapticService.medium();
    _textController.clear();
    setState(() => _isLoading = true);

    try {
      await ref.read(chatMessagesProvider.notifier).sendMessageWithMedia(message, media);
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
      setState(() => _isLoading = false);
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
      showUpgradePromptSheet(context,
          featureKey: gateKey, featureName: gateName);
      return;
    }

    final remaining = usageNotifier.remainingUses(gateKey);
    final isLastUse = remaining != null && remaining == 1;

    HapticService.medium();
    _textController.clear();
    setState(() => _isLoading = true);

    try {
      await ref.read(chatMessagesProvider.notifier).sendMessageWithMultiMedia(message, mediaList);
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
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  @override
  void initState() {
    super.initState();
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
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _textController.text.trim();
    if (message.isEmpty || _isLoading) return;

    HapticService.medium();
    _textController.clear();
    setState(() => _isLoading = true);

    try {
      await ref.read(chatMessagesProvider.notifier).sendMessage(message);
      _scrollToBottom();

      // Award first-time chat bonus (+50 XP)
      ref.read(xpProvider.notifier).checkFirstChatBonus();
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
      setState(() => _isLoading = false);
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

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        leading: GlassBackButton(
          onTap: () {
            HapticService.light();
            context.pop();
          },
        ),
        title: Row(
          children: [
            CoachAvatar(
              coach: coach,
              size: 36,
              showBorder: true,
              showShadow: false,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coachName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: _isLoading
                            ? AppColors.orange
                            : offlineChatState.isAvailable
                                ? Colors.amber
                                : AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        _isLoading
                            ? 'Typing...'
                            : offlineChatState.isAvailable
                                ? 'Offline (${offlineChatState.modelName ?? "Local AI"})'
                                : 'Online',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isLoading
                              ? AppColors.orange
                              : offlineChatState.isAvailable
                                  ? Colors.amber
                                  : AppColors.success,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ),
          ],
        ),
        actions: [
          // Info icon - shows features help sheet
          IconButton(
            icon: const Icon(Icons.info_outline, size: 20),
            tooltip: 'Features',
            visualDensity: VisualDensity.compact,
            onPressed: () {
              HapticService.light();
              _showFeaturesInfoSheet();
            },
          ),
          // Swap coach button
          IconButton(
            icon: const Icon(Icons.swap_horiz, size: 20),
            tooltip: 'Change coach',
            visualDensity: VisualDensity.compact,
            onPressed: () {
              HapticService.light();
              context.push('/coach-selection?fromSettings=true');
            },
          ),
          // Minimize button - animate back to floating chat overlay
          IconButton(
            icon: const Icon(Icons.close_fullscreen, size: 20),
            tooltip: 'Minimize',
            visualDensity: VisualDensity.compact,
            onPressed: () => _minimizeToFloatingChat(),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 20),
            visualDensity: VisualDensity.compact,
            onPressed: () {
              HapticService.light();
              _showOptionsMenu(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: AnimatedSwitcher(
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

                  return ListView.builder(
                    key: const ValueKey('content'),
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length && _isLoading) {
                        return const _TypingIndicator();
                      }
                      final message = messages[index];
                      // Find the previous user message for context when reporting
                      String? previousUserMessage;
                      if (message.role == 'assistant') {
                        for (int i = index - 1; i >= 0; i--) {
                          if (messages[i].role == 'user') {
                            previousUserMessage = messages[i].content;
                            break;
                          }
                        }
                      }
                      return _MessageBubble(
                        key: ValueKey(message.id ?? 'msg_$index'),
                        message: message,
                        previousUserMessage: previousUserMessage,
                        coach: coach,
                      ).animate().fadeIn(duration: 200.ms);
                    },
                  );
                },
              ),
            ),
          ),

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
            isOffline: offlineChatState.isAvailable,
            modelName: offlineChatState.modelName,
          ),
        ],
      ),
    );
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
              leading: const Icon(Icons.support_agent, color: AppColors.cyan),
              title: const Text('Talk to Human Support'),
              subtitle: const Text(
                'Connect with a real person',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              onTap: () {
                Navigator.pop(context);
                HapticService.selection();
                _showEscalateToHumanDialog();
              },
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.bug_report_outlined, color: AppColors.orange),
              title: const Text('Report a Problem'),
              subtitle: const Text(
                'Submit a support ticket',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              onTap: () {
                Navigator.pop(context);
                HapticService.selection();
                context.push('/support-tickets');
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

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String? previousUserMessage;
  final CoachPersona coach;

  const _MessageBubble({
    super.key,
    required this.message,
    required this.coach,
    this.previousUserMessage,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final isSystem = message.role == 'system';

    // System messages (like coach change notifications) are displayed centered
    if (isSystem) {
      return _buildSystemMessage(context);
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
                    coach: coach,
                    size: 20,
                    showBorder: true,
                    borderWidth: 1,
                    showShadow: false,
                    enableTapToView: false, // Too small, don't interrupt chat
                  ),
                  const SizedBox(width: 6),
                  Text(
                    coach.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: coach.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          // Show media thumbnail for user messages with media
          if (isUser && message.hasMedia)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 150,
                  child: Stack(
                    children: [
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
                      if (message.mediaType == 'video')
                        const Positioned.fill(
                          child: Center(
                            child: Icon(Icons.play_circle_outline, color: Colors.white70, size: 40),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          // Show media indicator for user messages without URL (uploading)
          if (isUser && !message.hasMedia && message.mediaType != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    message.mediaType == 'video' ? Icons.videocam : Icons.image,
                    size: 14,
                    color: AppColors.pureBlack.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    message.mediaType == 'video' ? 'Video attached' : 'Image attached',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.pureBlack.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
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
          // Show multi-food/buffet/menu analysis result card
          if (!isUser && (message.hasBuffetAnalysis || message.hasMenuAnalysis ||
              (message.actionData?['action'] == 'analyze_multi_food_images')))
            FoodAnalysisResultCard(data: message.actionData!),
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
          // Always show timestamp - use "now" if not available
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _formatTime(message.timestamp ?? DateTime.now()),
              style: TextStyle(
                fontSize: 10,
                color: isUser
                    ? AppColors.pureBlack.withOpacity(0.6)
                    : AppColors.textMuted,
              ),
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

    // For AI messages, wrap with GestureDetector for long-press to report
    if (!isUser) {
      bubbleContent = GestureDetector(
        onLongPress: () {
          HapticService.medium();
          showReportMessageSheet(
            context,
            messageId: message.id,
            originalUserMessage: previousUserMessage ?? '',
            aiResponse: message.content,
          );
        },
        child: bubbleContent,
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: bubbleContent,
    );
  }

  /// Build a system notification message (centered, subtle styling)
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
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.elevated,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: const Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: const BoxDecoration(
                color: AppColors.textMuted,
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
  final bool isOffline;
  final String? modelName;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
    required this.onSendWithMedia,
    required this.onSendWithMultiMedia,
    this.isOffline = false,
    this.modelName,
  });

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  List<PickedMedia> _selectedMedia = [];

  void _pickMedia() async {
    try {
      final result = await MediaPickerHelper.showMediaPickerSheet(context);
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
    }
  }

  void _pickImageFromCamera() async {
    try {
      final media = await MediaPickerHelper.pickImage(ImageSource.camera);
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
                        maxLines: 1,
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

                    // Send button
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
          activeColor: AppColors.cyan,
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
