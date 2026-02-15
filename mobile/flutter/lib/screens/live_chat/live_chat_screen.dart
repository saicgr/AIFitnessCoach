import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../data/services/haptic_service.dart';
import 'widgets/agent_info_header.dart';
import 'widgets/live_chat_input_bar.dart';
import '../../widgets/glass_back_button.dart';
import '../../widgets/glass_sheet.dart';
import 'widgets/live_chat_message_bubble.dart';
import 'widgets/queue_position_card.dart';
import 'widgets/typing_indicator.dart';

/// Connection status for the live chat
enum LiveChatStatus {
  disconnected,
  connecting,
  queued,
  connected,
  ended,
}

/// Model for a live chat message
class LiveChatMessage {
  final String id;
  final String content;
  final bool isFromUser;
  final DateTime timestamp;
  final bool isRead;
  final String? agentName;
  final String? agentAvatarUrl;

  const LiveChatMessage({
    required this.id,
    required this.content,
    required this.isFromUser,
    required this.timestamp,
    this.isRead = false,
    this.agentName,
    this.agentAvatarUrl,
  });
}

/// Model for agent info
class AgentInfo {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isOnline;

  const AgentInfo({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isOnline = true,
  });
}

/// Live chat state notifier
class LiveChatNotifier extends StateNotifier<LiveChatState> {
  LiveChatNotifier() : super(LiveChatState.initial());

  Timer? _typingTimer;

  void connect() {
    state = state.copyWith(status: LiveChatStatus.connecting);

    // Simulate connection delay then queue
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        state = state.copyWith(
          status: LiveChatStatus.queued,
          queuePosition: 3,
          estimatedWaitMinutes: 5,
        );
      }
    });
  }

  void simulateAgentConnect() {
    state = state.copyWith(
      status: LiveChatStatus.connected,
      agent: const AgentInfo(
        id: 'agent_1',
        name: 'Sarah',
        isOnline: true,
      ),
      queuePosition: null,
      estimatedWaitMinutes: null,
    );

    // Add welcome message from agent
    _addMessage(LiveChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      content: 'Hi! I\'m Sarah from the FitWiz support team. How can I help you today?',
      isFromUser: false,
      timestamp: DateTime.now(),
      agentName: 'Sarah',
    ));
  }

  void sendMessage(String content) {
    if (content.trim().isEmpty) return;

    final message = LiveChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      content: content.trim(),
      isFromUser: true,
      timestamp: DateTime.now(),
      isRead: false,
    );

    _addMessage(message);

    // Simulate agent typing
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        state = state.copyWith(isAgentTyping: true);
      }
    });

    // Simulate agent response
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        state = state.copyWith(isAgentTyping: false);
        _addMessage(LiveChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          content: 'Thank you for your message. Let me look into that for you.',
          isFromUser: false,
          timestamp: DateTime.now(),
          agentName: state.agent?.name,
        ));
      }
    });
  }

  void _addMessage(LiveChatMessage message) {
    state = state.copyWith(
      messages: [...state.messages, message],
    );
  }

  void setUserTyping(bool isTyping) {
    _typingTimer?.cancel();
    if (isTyping) {
      _typingTimer = Timer(const Duration(seconds: 3), () {
        // Typing timeout - user stopped typing
      });
    }
  }

  void markMessagesAsRead() {
    final updatedMessages = state.messages.map((msg) {
      if (!msg.isFromUser && !msg.isRead) {
        return LiveChatMessage(
          id: msg.id,
          content: msg.content,
          isFromUser: msg.isFromUser,
          timestamp: msg.timestamp,
          isRead: true,
          agentName: msg.agentName,
          agentAvatarUrl: msg.agentAvatarUrl,
        );
      }
      return msg;
    }).toList();

    state = state.copyWith(messages: updatedMessages);
  }

  void endChat() {
    state = state.copyWith(
      status: LiveChatStatus.ended,
      isAgentTyping: false,
    );

    _addMessage(LiveChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      content: 'Chat ended. Thank you for contacting FitWiz support!',
      isFromUser: false,
      timestamp: DateTime.now(),
      agentName: 'System',
    ));
  }

  void cancelQueue() {
    state = LiveChatState.initial();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }
}

/// Live chat state
class LiveChatState {
  final LiveChatStatus status;
  final List<LiveChatMessage> messages;
  final AgentInfo? agent;
  final int? queuePosition;
  final int? estimatedWaitMinutes;
  final bool isAgentTyping;

  const LiveChatState({
    required this.status,
    required this.messages,
    this.agent,
    this.queuePosition,
    this.estimatedWaitMinutes,
    this.isAgentTyping = false,
  });

  factory LiveChatState.initial() => const LiveChatState(
        status: LiveChatStatus.disconnected,
        messages: [],
      );

  LiveChatState copyWith({
    LiveChatStatus? status,
    List<LiveChatMessage>? messages,
    AgentInfo? agent,
    int? queuePosition,
    int? estimatedWaitMinutes,
    bool? isAgentTyping,
  }) {
    return LiveChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      agent: agent ?? this.agent,
      queuePosition: queuePosition,
      estimatedWaitMinutes: estimatedWaitMinutes,
      isAgentTyping: isAgentTyping ?? this.isAgentTyping,
    );
  }
}

/// Provider for live chat
final liveChatProvider =
    StateNotifierProvider<LiveChatNotifier, LiveChatState>((ref) {
  return LiveChatNotifier();
});

/// Live Chat Screen
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
      // Start connection when screen opens
      ref.read(liveChatProvider.notifier).connect();
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
    ref.read(liveChatProvider.notifier).setUserTyping(text.isNotEmpty);
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
          'Connect with our support team for real-time assistance. Our agents are available 24/7 to help with any questions or issues.',
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

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(liveChatProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    // Scroll to bottom when messages change
    ref.listen(liveChatProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(chatState),
      body: Column(
        children: [
          // Connection status indicator
          _buildConnectionStatus(chatState),

          // Queue position card (when waiting)
          if (chatState.status == LiveChatStatus.queued)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: QueuePositionCard(
                    position: chatState.queuePosition ?? 1,
                    estimatedWaitMinutes: chatState.estimatedWaitMinutes ?? 5,
                    onCancel: () {
                      HapticService.medium();
                      ref.read(liveChatProvider.notifier).cancelQueue();
                      context.pop();
                    },
                    onSimulateConnect: () {
                      // For demo purposes - simulate agent connection
                      HapticService.success();
                      ref.read(liveChatProvider.notifier).simulateAgentConnect();
                    },
                  ),
                ),
              ),
            )
          else if (chatState.status == LiveChatStatus.connecting)
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
                itemCount: chatState.messages.length +
                    (chatState.isAgentTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == chatState.messages.length &&
                      chatState.isAgentTyping) {
                    return AgentTypingIndicator(
                      agentName: chatState.agent?.name ?? 'Agent',
                    );
                  }
                  final message = chatState.messages[index];
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
              enabled: chatState.status == LiveChatStatus.connected,
              onSend: _sendMessage,
              onTextChanged: _onTextChanged,
            ),
          ],
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(LiveChatState chatState) {
    return AppBar(
      backgroundColor: AppColors.pureBlack,
      automaticallyImplyLeading: false,
      leading: GlassBackButton(
        onTap: () {
          HapticService.light();
          if (chatState.status == LiveChatStatus.connected) {
            _showEndChatDialog();
          } else {
            context.pop();
          }
        },
      ),
      title: chatState.status == LiveChatStatus.connected && chatState.agent != null
          ? AgentInfoHeader(
              agent: chatState.agent!,
              isTyping: chatState.isAgentTyping,
            )
          : const Text('Live Chat'),
      actions: [
        if (chatState.status == LiveChatStatus.connected)
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

  Widget _buildConnectionStatus(LiveChatState chatState) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (chatState.status) {
      case LiveChatStatus.disconnected:
        statusColor = AppColors.textMuted;
        statusText = 'Disconnected';
        statusIcon = Icons.cloud_off;
        break;
      case LiveChatStatus.connecting:
        statusColor = AppColors.orange;
        statusText = 'Connecting...';
        statusIcon = Icons.sync;
        break;
      case LiveChatStatus.queued:
        statusColor = AppColors.warning;
        statusText = 'In Queue';
        statusIcon = Icons.hourglass_empty;
        break;
      case LiveChatStatus.connected:
        statusColor = AppColors.success;
        statusText = 'Connected';
        statusIcon = Icons.check_circle;
        break;
      case LiveChatStatus.ended:
        statusColor = AppColors.textMuted;
        statusText = 'Chat Ended';
        statusIcon = Icons.chat_bubble_outline;
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
