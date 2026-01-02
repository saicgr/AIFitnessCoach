import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/live_chat_session.dart';
import '../../data/providers/live_chat_provider.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/floating_chat/floating_chat_overlay.dart';
import 'widgets/report_message_sheet.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load chat history on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatMessagesProvider.notifier).loadHistory();
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
    // Pop the full screen with reverse animation
    Navigator.of(context).pop();
    // Show floating chat immediately after shrink animation - no delay for seamless feel
    Future.delayed(const Duration(milliseconds: 280), () {
      if (context.mounted) {
        // Use the no-animation version for seamless transition
        showChatBottomSheetNoAnimation(context, ref);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(chatMessagesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.pureBlack,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticService.light();
            context.pop();
          },
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.cyan, AppColors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Coach',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _isLoading ? 'Typing...' : 'Online',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isLoading ? AppColors.orange : AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Minimize button - animate back to floating chat overlay
          IconButton(
            icon: const Icon(Icons.close_fullscreen, size: 22),
            tooltip: 'Minimize',
            onPressed: () => _minimizeToFloatingChat(),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
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
            child: messagesState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.cyan),
              ),
              error: (e, _) => Center(
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
                  return _EmptyChat(onSuggestionTap: (suggestion) {
                    _textController.text = suggestion;
                    _sendMessage();
                  });
                }

                return ListView.builder(
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
                      message: message,
                      previousUserMessage: previousUserMessage,
                    ).animate().fadeIn(duration: 200.ms);
                  },
                );
              },
            ),
          ),

          // Input bar
          _InputBar(
            controller: _textController,
            focusNode: _focusNode,
            isLoading: _isLoading,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
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
    );
  }

  void _showEscalateToHumanDialog() {
    // Track selected category
    LiveChatCategory selectedCategory = LiveChatCategory.general;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
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
                  const Text('Talk to Human Support'),
                ],
              ),
              content: SingleChildScrollView(
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
                    // Category selection
                    ...LiveChatCategory.values.map((category) {
                      return RadioListTile<LiveChatCategory>(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          category.displayName,
                          style: const TextStyle(fontSize: 14),
                        ),
                        value: category,
                        groupValue: selectedCategory,
                        activeColor: AppColors.cyan,
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedCategory = value;
                            });
                          }
                        },
                      );
                    }),
                    const SizedBox(height: 16),
                    // Show availability/wait time
                    Consumer(
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
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setDialogState(() => isLoading = true);

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
                                  category: selectedCategory.value,
                                  initialMessage:
                                      'Escalated from AI chat for ${selectedCategory.displayName.toLowerCase()} help.',
                                  escalatedFromAi: true,
                                  aiContext: aiContext.isNotEmpty ? aiContext : null,
                                );

                            // Get the session to retrieve ticket ID
                            final session = ref.read(liveChatProvider).valueOrNull;

                            if (mounted) {
                              Navigator.pop(context);
                              HapticService.success();

                              // Navigate to live chat screen
                              context.push('/live-chat');
                            }
                          } catch (e) {
                            setDialogState(() => isLoading = false);

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to connect: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
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
              ],
            );
          },
        );
      },
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevated,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.cyan, AppColors.purple],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('AI Coach'),
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

// ─────────────────────────────────────────────────────────────────
// Empty Chat State
// ─────────────────────────────────────────────────────────────────

class _EmptyChat extends StatelessWidget {
  final Function(String) onSuggestionTap;

  const _EmptyChat({required this.onSuggestionTap});

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      'What should I eat before a workout?',
      'How can I improve my squat form?',
      'I feel tired today, should I still work out?',
      'Create a quick 15-minute workout',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.cyan, AppColors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'AI Coach',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your personal fitness assistant',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 32),
          Text(
            'Try asking...',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: 16),
          ...suggestions.map((suggestion) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  HapticService.selection();
                  onSuggestionTap(suggestion);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.elevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 18,
                        color: AppColors.cyan,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Message Bubble
// ─────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String? previousUserMessage;

  const _MessageBubble({
    required this.message,
    this.previousUserMessage,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

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
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.cyan, AppColors.purple],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.smart_toy,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'AI Coach',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cyan,
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

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.nearBlack,
        border: Border(
          top: BorderSide(color: AppColors.cardBorder.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: !isLoading,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Ask your AI coach...',
                filled: true,
                fillColor: AppColors.glassSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isLoading
                    ? [AppColors.textMuted, AppColors.textMuted]
                    : [AppColors.cyan, AppColors.purple],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: isLoading ? null : onSend,
              icon: isLoading
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
