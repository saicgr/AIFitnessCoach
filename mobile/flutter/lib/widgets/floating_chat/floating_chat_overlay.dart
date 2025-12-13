import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/chat_message.dart';
import '../../data/repositories/chat_repository.dart';
import '../../navigation/app_router.dart' show currentRouteProvider;
import 'floating_chat_provider.dart';

/// Floating chat overlay - Facebook Messenger style
///
/// This widget wraps the entire app and provides:
/// 1. A floating chat bubble that can be tapped to expand
/// 2. An expandable chat modal at the bottom of the screen
/// 3. Draggable bubble position
class FloatingChatOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const FloatingChatOverlay({super.key, required this.child});

  @override
  ConsumerState<FloatingChatOverlay> createState() => _FloatingChatOverlayState();
}

class _FloatingChatOverlayState extends ConsumerState<FloatingChatOverlay> {
  // Bubble position
  double _bubbleRight = 16;
  double _bubbleBottom = 100;

  // For drag animation
  bool _isDragging = false;

  /// Routes where the bubble should NOT be shown
  static const _hiddenRoutes = {
    '/splash',
    '/login',
    '/onboarding',
    '/active-workout',
    '/chat',
    '/workout-complete',
  };

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(floatingChatProvider);
    final screenSize = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Watch current route to rebuild when navigation happens
    final currentPath = ref.watch(currentRouteProvider);
    debugPrint('FloatingChatOverlay: currentPath = $currentPath');

    // Check if we're on a route where the bubble should be shown
    final shouldShowBubble = !_hiddenRoutes.any((route) => currentPath.startsWith(route));
    debugPrint('FloatingChatOverlay: shouldShowBubble = $shouldShowBubble');

    return Stack(
      children: [
        // Main app content
        widget.child,

        // Only show chat elements on appropriate screens
        if (shouldShowBubble) ...[
          // Chat modal (when expanded)
          if (chatState.isExpanded) ...[
            // Semi-transparent backdrop
            Positioned.fill(
              child: GestureDetector(
                onTap: () => ref.read(floatingChatProvider.notifier).collapse(),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ).animate().fadeIn(duration: 200.ms),
            ),

            // Floating chat window - centered with margins
            Center(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 80,
                  bottom: bottomPadding + 120,
                ),
                child: _ChatModal(
                  onClose: () => ref.read(floatingChatProvider.notifier).collapse(),
                  onMinimize: () => ref.read(floatingChatProvider.notifier).collapse(),
                ).animate().scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), duration: 250.ms, curve: Curves.easeOutBack)
                 .fadeIn(duration: 200.ms),
              ),
            ),
          ],

          // Floating bubble (when collapsed)
          if (!chatState.isExpanded)
            Positioned(
              right: _bubbleRight,
              bottom: _bubbleBottom + bottomPadding,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  debugPrint('FloatingChatOverlay: Bubble tapped!');
                  ref.read(floatingChatProvider.notifier).expand();
                },
                onPanStart: (_) => setState(() => _isDragging = true),
                onPanUpdate: (details) {
                  setState(() {
                    _bubbleRight -= details.delta.dx;
                    _bubbleBottom -= details.delta.dy;

                    // Keep within screen bounds
                    _bubbleRight = _bubbleRight.clamp(16, screenSize.width - 72);
                    _bubbleBottom = _bubbleBottom.clamp(100, screenSize.height - 200);
                  });
                },
                onPanEnd: (_) => setState(() => _isDragging = false),
                child: _FloatingBubble(isDragging: _isDragging),
              ),
            ),
        ],
      ],
    );
  }
}

/// Floating chat bubble
class _FloatingBubble extends StatelessWidget {
  final bool isDragging;

  const _FloatingBubble({this.isDragging = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isDragging ? 1.1 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.purple, AppColors.cyan],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.cyan.withValues(alpha: isDragging ? 0.6 : 0.4),
              blurRadius: isDragging ? 20 : 16,
              offset: const Offset(0, 4),
              spreadRadius: isDragging ? 2 : 0,
            ),
          ],
        ),
        child: const Icon(
          Icons.auto_awesome,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

/// Expandable chat modal
class _ChatModal extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onMinimize;

  const _ChatModal({
    required this.onClose,
    required this.onMinimize,
  });

  @override
  ConsumerState<_ChatModal> createState() => _ChatModalState();
}

class _ChatModalState extends ConsumerState<_ChatModal> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _isLoading = false;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    // Load chat history when modal opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatMessagesProvider.notifier).loadHistory();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (animate) {
          _scrollController.animateTo(
            maxScroll,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(maxScroll);
        }
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _textController.text.trim();
    if (message.isEmpty || _isLoading) return;

    _textController.clear();
    setState(() => _isLoading = true);

    try {
      await ref.read(chatMessagesProvider.notifier).sendMessage(message);
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error sending message: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(chatMessagesProvider);

    return Container(
      constraints: const BoxConstraints(maxWidth: 400), // Max width for larger screens
      decoration: BoxDecoration(
        color: AppColors.pureBlack,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 30,
            offset: const Offset(0, 10),
            spreadRadius: 5,
          ),
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          _ChatHeader(
            onClose: widget.onClose,
            onMinimize: widget.onMinimize,
            isLoading: _isLoading,
          ),

          const Divider(color: AppColors.cardBorder, height: 1),

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
                    const Icon(Icons.error_outline, color: AppColors.error, size: 40),
                    const SizedBox(height: 12),
                    Text('Error loading messages', style: TextStyle(color: AppColors.textMuted)),
                    TextButton(
                      onPressed: () => ref.read(chatMessagesProvider.notifier).loadHistory(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return _EmptyChatState(onSuggestionTap: (suggestion) {
                    _textController.text = suggestion;
                    _sendMessage();
                  });
                }

                // Scroll to bottom when messages first load or when new messages arrive
                if (messages.length != _lastMessageCount) {
                  _lastMessageCount = messages.length;
                  // Use multiple frames to ensure ListView has fully rendered
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                          _scrollController.jumpTo(
                            _scrollController.position.maxScrollExtent,
                          );
                        }
                      });
                    });
                  });
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Typing indicator at the end
                    if (index == messages.length && _isLoading) {
                      return const _TypingIndicator();
                    }
                    return _MessageBubble(message: messages[index]);
                  },
                );
              },
            ),
          ),

          // Input bar - no bottom padding since floating
          _InputBar(
            controller: _textController,
            focusNode: _focusNode,
            isLoading: _isLoading,
            onSend: _sendMessage,
            bottomPadding: 0,
          ),
        ],
      ),
    );
  }
}

/// Chat header with title and actions
class _ChatHeader extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onMinimize;
  final bool isLoading;

  const _ChatHeader({
    required this.onClose,
    required this.onMinimize,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // AI avatar
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
            child: const Icon(Icons.smart_toy, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          // Title and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Coach',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  isLoading ? 'Typing...' : 'Online',
                  style: TextStyle(
                    fontSize: 12,
                    color: isLoading ? AppColors.orange : AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          // Minimize button
          IconButton(
            icon: const Icon(Icons.remove, color: AppColors.textMuted),
            onPressed: onMinimize,
            tooltip: 'Minimize',
          ),
          // Close button
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textMuted),
            onPressed: onClose,
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }
}

/// Empty chat state with suggestions
class _EmptyChatState extends StatelessWidget {
  final Function(String) onSuggestionTap;

  const _EmptyChatState({required this.onSuggestionTap});

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      'What should I eat before a workout?',
      'How can I improve my form?',
      'Create a quick workout',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.cyan, AppColors.purple],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, size: 30, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            'How can I help you today?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me anything about fitness',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ...suggestions.map((suggestion) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => onSuggestionTap(suggestion),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.elevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.cyan),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}

/// Message bubble with long-press to copy, agent colors, and timestamps
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  void _copyMessage(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.content));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Message copied'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final isToday = time.year == now.year && time.month == now.month && time.day == now.day;
    final isYesterday = time.year == now.year && time.month == now.month && time.day == now.day - 1;

    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minuteStr = time.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minuteStr $period';

    if (isToday) {
      return timeStr;
    } else if (isYesterday) {
      return 'Yesterday $timeStr';
    } else {
      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${monthNames[time.month - 1]} ${time.day} $timeStr';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final agentConfig = message.agentConfig;
    final timestamp = message.timestamp;

    if (!isUser) {
      debugPrint('🎨 [MessageBubble] message.agentType: ${message.agentType}, agentConfig: ${agentConfig.name} (${agentConfig.displayName})');
    }

    if (isUser) {
      // User message - simple cyan bubble
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onLongPress: () => _copyMessage(context),
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cyan,
                  borderRadius: BorderRadius.circular(16).copyWith(
                    bottomRight: const Radius.circular(4),
                  ),
                ),
                child: Text(
                  message.content,
                  style: const TextStyle(
                    color: AppColors.pureBlack,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
          // Timestamp for user message
          if (timestamp != null)
            Padding(
              padding: const EdgeInsets.only(right: 4, bottom: 8),
              child: Text(
                _formatTime(timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ),
        ],
      );
    }

    // Assistant message with agent color and icon
    final brightness = Theme.of(context).brightness;
    final agentBgColor = agentConfig.getBackgroundColor(brightness);
    final textColor = brightness == Brightness.dark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Agent avatar
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8, top: 2),
              decoration: BoxDecoration(
                color: agentConfig.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                agentConfig.icon,
                size: 16,
                color: agentConfig.primaryColor,
              ),
            ),
            // Message bubble
            Flexible(
              child: GestureDetector(
                onLongPress: () => _copyMessage(context),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: agentBgColor,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomLeft: const Radius.circular(4),
                    ),
                    border: Border.all(
                      color: agentConfig.primaryColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Agent name
                      Text(
                        agentConfig.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: agentConfig.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Message content
                      Text(
                        message.content,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        // Timestamp for assistant message
        if (timestamp != null)
          Padding(
            padding: const EdgeInsets.only(left: 36, bottom: 8),
            child: Text(
              _formatTime(timestamp),
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ),
      ],
    );
  }
}

/// Typing indicator
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                .animate(onPlay: (controller) => controller.repeat())
                .fadeIn(delay: Duration(milliseconds: index * 200))
                .then()
                .fadeOut(delay: const Duration(milliseconds: 400));
          }),
        ),
      ),
    );
  }
}

/// Input bar - Stateful to properly manage TextField and agent picker
class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onSend;
  final double bottomPadding;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
    required this.bottomPadding,
  });

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _showAgentPicker = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _hideAgentPicker();
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final cursorPos = widget.controller.selection.baseOffset;

    // Check if user just typed '@' at the start or after a space
    if (cursorPos > 0 && cursorPos <= text.length) {
      final charBefore = cursorPos > 1 ? text[cursorPos - 2] : ' ';
      final currentChar = text[cursorPos - 1];

      if (currentChar == '@' && (charBefore == ' ' || cursorPos == 1)) {
        _showAgentPickerOverlay();
        return;
      }
    }

    // Hide picker if text changed without @
    if (_showAgentPicker && !text.contains('@')) {
      _hideAgentPicker();
    }
  }

  void _showAgentPickerOverlay() {
    if (_showAgentPicker) return;

    setState(() => _showAgentPicker = true);

    _overlayEntry = OverlayEntry(
      builder: (context) => _AgentPickerOverlay(
        onAgentSelected: _onAgentSelected,
        onDismiss: _hideAgentPicker,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideAgentPicker() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (_showAgentPicker) {
      setState(() => _showAgentPicker = false);
    }
  }

  void _onAgentSelected(AgentConfig agent) {
    final text = widget.controller.text;
    final cursorPos = widget.controller.selection.baseOffset;

    // Find the @ symbol to replace
    int atIndex = text.lastIndexOf('@', cursorPos - 1);
    if (atIndex >= 0) {
      final newText = text.replaceRange(atIndex, cursorPos, '@${agent.name} ');
      widget.controller.text = newText;
      widget.controller.selection = TextSelection.fromPosition(
        TextPosition(offset: atIndex + agent.name.length + 2),
      );
    }

    _hideAgentPicker();
    widget.focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, widget.bottomPadding + 12),
      decoration: BoxDecoration(
        color: AppColors.nearBlack,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: AppColors.cardBorder.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              enabled: !widget.isLoading,
              textCapitalization: TextCapitalization.sentences,
              autocorrect: true,
              enableSuggestions: true,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.send,
              maxLines: 3,
              minLines: 1,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Ask your AI coach... (@ to pick agent)',
                hintStyle: TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.glassSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_) => widget.onSend(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.isLoading
                    ? [AppColors.textMuted, AppColors.textMuted]
                    : [AppColors.cyan, AppColors.purple],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: widget.isLoading ? null : widget.onSend,
              icon: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

/// Agent picker overlay that appears when user types @
class _AgentPickerOverlay extends StatelessWidget {
  final Function(AgentConfig) onAgentSelected;
  final VoidCallback onDismiss;

  const _AgentPickerOverlay({
    required this.onAgentSelected,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onDismiss,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.transparent,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 80,
              ),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 350),
                  decoration: BoxDecoration(
                    color: AppColors.elevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Text(
                          'Ask a specialist',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      ...AgentConfig.allAgents.map((agent) => _AgentOption(
                        agent: agent,
                        onTap: () => onAgentSelected(agent),
                      )),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ).animate().slideY(begin: 0.3, end: 0, duration: 200.ms, curve: Curves.easeOut)
               .fadeIn(duration: 150.ms),
            ),
          ),
        ),
      ),
    );
  }
}

/// Single agent option in the picker
class _AgentOption extends StatelessWidget {
  final AgentConfig agent;
  final VoidCallback onTap;

  const _AgentOption({
    required this.agent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: agent.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                agent.icon,
                size: 20,
                color: agent.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@${agent.name}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: agent.primaryColor,
                    ),
                  ),
                  Text(
                    agent.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
