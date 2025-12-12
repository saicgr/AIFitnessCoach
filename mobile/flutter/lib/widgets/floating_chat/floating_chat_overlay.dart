import 'package:flutter/material.dart';
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

            // Chat modal
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _ChatModal(
                onClose: () => ref.read(floatingChatProvider.notifier).collapse(),
                onMinimize: () => ref.read(floatingChatProvider.notifier).minimize(),
              ).animate().slideY(begin: 1, end: 0, duration: 300.ms, curve: Curves.easeOutCubic),
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.7,
      decoration: BoxDecoration(
        color: AppColors.pureBlack,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, -5),
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

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length && _isLoading) {
                      return const _TypingIndicator();
                    }
                    return _MessageBubble(message: messages[index]);
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
            bottomPadding: bottomPadding,
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

/// Message bubble
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.cyan : AppColors.elevated,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser ? AppColors.pureBlack : AppColors.textPrimary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
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

/// Input bar
class _InputBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding + 12),
      decoration: BoxDecoration(
        color: AppColors.nearBlack,
        border: Border(
          top: BorderSide(color: AppColors.cardBorder.withValues(alpha: 0.5)),
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
              maxLines: 3,
              minLines: 1,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Ask your AI coach...',
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
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
