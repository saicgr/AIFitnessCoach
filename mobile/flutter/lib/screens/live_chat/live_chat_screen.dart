import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/live_chat_session.dart';
import '../../data/providers/live_chat_provider.dart';
import '../../data/services/haptic_service.dart';
import 'widgets/agent_info_header.dart';
import 'widgets/live_chat_input_bar.dart';
import '../../widgets/glass_back_button.dart';
import '../../widgets/glass_sheet.dart';
import 'widgets/live_chat_message_bubble.dart';
import 'widgets/queue_position_card.dart';
import 'widgets/typing_indicator.dart';

/// Live Chat Screen - wired to real backend API via LiveChatNotifier
class LiveChatScreen extends ConsumerStatefulWidget {
  const LiveChatScreen({super.key});

  @override
  ConsumerState<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends ConsumerState<LiveChatScreen> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Start a new chat session when the screen opens
      final session = ref.read(liveChatProvider).valueOrNull;
      if (session == null || session.hasEnded) {
        ref.read(liveChatProvider.notifier).startChat(
              category: 'general',
              initialMessage: 'I need help',
            );
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

  void _sendMessage() {
    final message = _textController.text.trim();
    if (message.isEmpty) return;

    HapticService.medium();
    ref.read(liveChatProvider.notifier).sendMessage(message);
    _textController.clear();
    _scrollToBottom();
  }

  void _onTextChanged(String text) {
    if (text.isNotEmpty) {
      ref.read(liveChatProvider.notifier).onUserTyping();
    }
  }

  void _showEndChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('End Chat?'),
        content: const Text(
          'Are you sure you want to end this conversation? You can start a new chat later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              HapticService.medium();
              ref.read(liveChatProvider.notifier).endChat();
            },
            child: const Text(
              'End Chat',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu() {
    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.call_end, color: AppColors.error),
                title: const Text('End Chat'),
                onTap: () {
                  Navigator.pop(context);
                  _showEndChatDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline, color: AppColors.cyan),
                title: const Text('About Live Chat'),
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

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.cyan,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Live Chat'),
          ],
        ),
        content: const Text(
          'Connect with our support team for real-time assistance. Our agents are available during business hours to help with any questions or issues.',
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

  /// Determine the effective status from the session state
  _ScreenStatus _getScreenStatus(AsyncValue<LiveChatSession?> sessionAsync) {
    return sessionAsync.when(
      loading: () => _ScreenStatus.connecting,
      error: (_, __) => _ScreenStatus.error,
      data: (session) {
        if (session == null) return _ScreenStatus.disconnected;
        if (session.isQueued) return _ScreenStatus.queued;
        if (session.isActive) return _ScreenStatus.connected;
        if (session.hasEnded) return _ScreenStatus.ended;
        return _ScreenStatus.disconnected;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(liveChatProvider);
    final session = sessionAsync.valueOrNull;
    final screenStatus = _getScreenStatus(sessionAsync);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    // Scroll to bottom when messages change
    ref.listen(liveChatProvider, (previous, next) {
      final prevCount = previous?.valueOrNull?.messages.length ?? 0;
      final nextCount = next.valueOrNull?.messages.length ?? 0;
      if (prevCount != nextCount) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(session, screenStatus),
      body: Column(
        children: [
          // Connection status indicator
          _buildConnectionStatus(screenStatus),

          // Error state
          if (screenStatus == _ScreenStatus.error)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: AppColors.error, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to connect to support',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sessionAsync.error?.toString() ?? 'Unknown error',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(liveChatProvider.notifier).startChat(
                                category: 'general',
                                initialMessage: 'I need help',
                              );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cyan,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          // Queue position card (when waiting)
          else if (screenStatus == _ScreenStatus.queued)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: QueuePositionCard(
                    position: session?.queuePosition ?? 1,
                    estimatedWaitMinutes: session?.estimatedWaitMinutes ?? 5,
                    onCancel: () {
                      HapticService.medium();
                      ref.read(liveChatProvider.notifier).endChat();
                      context.pop();
                    },
                  ),
                ),
              ),
            )
          else if (screenStatus == _ScreenStatus.connecting)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.cyan),
                    SizedBox(height: 16),
                    Text(
                      'Connecting to support...',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Messages list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: (session?.messages.length ?? 0) +
                    ((session?.isAgentTyping ?? false) ? 1 : 0),
                itemBuilder: (context, index) {
                  final messages = session?.messages ?? [];
                  if (index == messages.length &&
                      (session?.isAgentTyping ?? false)) {
                    return AgentTypingIndicator(
                      agentName: session?.agentName ?? 'Agent',
                    );
                  }
                  if (index >= messages.length) {
                    return const SizedBox.shrink();
                  }
                  final message = messages[index];
                  return LiveChatMessageBubble(
                    message: message,
                    showAgentInfo: !message.isFromUser,
                  );
                },
              ),
            ),

            // Input bar
            LiveChatInputBar(
              controller: _textController,
              focusNode: _focusNode,
              enabled: screenStatus == _ScreenStatus.connected,
              onSend: _sendMessage,
              onTextChanged: _onTextChanged,
            ),
          ],
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      LiveChatSession? session, _ScreenStatus screenStatus) {
    return AppBar(
      backgroundColor: AppColors.pureBlack,
      automaticallyImplyLeading: false,
      leading: GlassBackButton(
        onTap: () {
          HapticService.light();
          if (screenStatus == _ScreenStatus.connected) {
            _showEndChatDialog();
          } else {
            context.pop();
          }
        },
      ),
      title: screenStatus == _ScreenStatus.connected && session?.agentName != null
          ? AgentInfoHeader(
              agentName: session!.agentName!,
              isTyping: session.isAgentTyping,
              isOnline: true,
            )
          : const Text('Live Chat'),
      actions: [
        if (screenStatus == _ScreenStatus.connected)
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              HapticService.light();
              _showOptionsMenu();
            },
          ),
      ],
    );
  }

  Widget _buildConnectionStatus(_ScreenStatus status) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case _ScreenStatus.disconnected:
        statusColor = AppColors.textMuted;
        statusText = 'Disconnected';
        statusIcon = Icons.cloud_off;
        break;
      case _ScreenStatus.connecting:
        statusColor = AppColors.orange;
        statusText = 'Connecting...';
        statusIcon = Icons.sync;
        break;
      case _ScreenStatus.queued:
        statusColor = AppColors.warning;
        statusText = 'In Queue';
        statusIcon = Icons.hourglass_empty;
        break;
      case _ScreenStatus.connected:
        statusColor = AppColors.success;
        statusText = 'Connected';
        statusIcon = Icons.check_circle;
        break;
      case _ScreenStatus.ended:
        statusColor = AppColors.textMuted;
        statusText = 'Chat Ended';
        statusIcon = Icons.chat_bubble_outline;
        break;
      case _ScreenStatus.error:
        statusColor = AppColors.error;
        statusText = 'Connection Error';
        statusIcon = Icons.error_outline;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: statusColor.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(statusIcon, size: 14, color: statusColor),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Internal screen status enum
enum _ScreenStatus {
  disconnected,
  connecting,
  queued,
  connected,
  ended,
  error,
}
