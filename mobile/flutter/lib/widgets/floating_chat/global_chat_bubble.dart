import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/chat_message.dart';
import '../../data/repositories/chat_repository.dart';
import '../../navigation/app_router.dart' show currentRouteProvider;
import 'floating_chat_provider.dart';

/// Global chat bubble that appears on ALL screens
/// Works like Facebook Messenger - always visible and draggable
class GlobalChatBubble extends ConsumerStatefulWidget {
  final Widget child;

  const GlobalChatBubble({super.key, required this.child});

  @override
  ConsumerState<GlobalChatBubble> createState() => _GlobalChatBubbleState();
}

class _GlobalChatBubbleState extends ConsumerState<GlobalChatBubble> {
  // Routes where the bubble should be hidden
  static const _hiddenRoutes = [
    '/splash',
    '/onboarding',
    '/login',
    '/signup',
  ];

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(floatingChatProvider);
    final notifier = ref.read(floatingChatProvider.notifier);
    final currentPath = ref.watch(currentRouteProvider);

    debugPrint('🔍 [GlobalChatBubble] Building - currentPath: $currentPath, isExpanded: ${chatState.isExpanded}');

    // Check if bubble should be hidden on this route
    final shouldHide = _hiddenRoutes.any((route) => currentPath.startsWith(route));

    debugPrint('🔍 [GlobalChatBubble] shouldHide: $shouldHide');

    // Simple Stack - the child contains the Navigator which provides its own Overlay
    return Stack(
      fit: StackFit.expand,
      children: [
        // Main app content (MaterialApp.router provides Navigator with Overlay)
        widget.child,

        // Chat bubble and modal (only on appropriate routes)
        if (!shouldHide) ...[
          // Expanded chat modal with backdrop
          if (chatState.isExpanded) ...[
            // Semi-transparent backdrop - fast fade for snappy feel
            Positioned.fill(
              child: GestureDetector(
                onTap: () => notifier.collapse(),
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ).animate().fadeIn(duration: 150.ms, curve: Curves.easeOut),
              ),
            ),
            // Chat modal - smooth spring-like animation
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _ChatModal(
                onClose: () => notifier.collapse(),
              ).animate()
                .slideY(begin: 0.3, end: 0, duration: 250.ms, curve: Curves.easeOutQuart)
                .fadeIn(duration: 200.ms, curve: Curves.easeOut),
            ),
          ],

          // Floating bubble (always visible when not expanded)
          if (!chatState.isExpanded)
            _DraggableBubble(
              right: chatState.bubbleRight,
              bottom: chatState.bubbleBottom,
              isDragging: chatState.isDragging,
              onTap: () => notifier.expand(),
              onDragStart: () => notifier.setDragging(true),
              onDragUpdate: (right, bottom) => notifier.updateBubblePosition(right, bottom),
              onDragEnd: () => notifier.setDragging(false),
            ),
        ],
      ],
    );
  }
}

/// Draggable floating bubble widget
class _DraggableBubble extends StatelessWidget {
  final double right;
  final double bottom;
  final bool isDragging;
  final VoidCallback onTap;
  final VoidCallback onDragStart;
  final Function(double right, double bottom) onDragUpdate;
  final VoidCallback onDragEnd;

  const _DraggableBubble({
    required this.right,
    required this.bottom,
    required this.isDragging,
    required this.onTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      right: right,
      bottom: bottom + bottomPadding,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onPanStart: (_) => onDragStart(),
        onPanUpdate: (details) {
          final newRight = (right - details.delta.dx).clamp(16.0, screenSize.width - 72.0);
          final newBottom = (bottom - details.delta.dy).clamp(80.0, screenSize.height - 200.0);
          onDragUpdate(newRight, newBottom);
        },
        onPanEnd: (_) => onDragEnd(),
        child: AnimatedScale(
          scale: isDragging ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
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
                  color: AppColors.cyan.withOpacity(isDragging ? 0.7 : 0.4),
                  blurRadius: isDragging ? 24 : 16,
                  offset: const Offset(0, 4),
                  spreadRadius: isDragging ? 4 : 0,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

/// Chat modal widget
class _ChatModal extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const _ChatModal({required this.onClose});

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

    // Wrap in Material to provide the required ancestor for TextField and other Material widgets
    return Material(
      type: MaterialType.transparency,
      child: Container(
        height: screenHeight * 0.75,
        decoration: BoxDecoration(
          color: AppColors.pureBlack,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.cyan, AppColors.purple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.smart_toy, size: 22, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Coach',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _isLoading ? 'Typing...' : 'Online',
                        style: TextStyle(
                          fontSize: 13,
                          color: _isLoading ? AppColors.orange : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted, size: 24),
                  onPressed: widget.onClose,
                ),
              ],
            ),
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
                    const Text('Error loading messages', style: TextStyle(color: AppColors.textMuted)),
                    TextButton(
                      onPressed: () => ref.read(chatMessagesProvider.notifier).loadHistory(force: true),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length && _isLoading) {
                      return _buildTypingIndicator();
                    }
                    return _buildMessageBubble(messages[index]);
                  },
                );
              },
            ),
          ),

          // Input bar
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding + 12),
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
                    controller: _textController,
                    focusNode: _focusNode,
                    enabled: !_isLoading,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                    minLines: 1,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Ask your AI coach...',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.glassSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isLoading
                          ? [AppColors.textMuted, AppColors.textMuted]
                          : [AppColors.cyan, AppColors.purple],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final suggestions = [
      'What should I eat before a workout?',
      'How can I improve my form?',
      'Create a quick workout for me',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.cyan, AppColors.purple],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, size: 36, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text(
            'How can I help you today?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ask me anything about fitness',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          ...suggestions.map((suggestion) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () {
                _textController.text = suggestion;
                _sendMessage();
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.elevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.cyan),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.cyan : AppColors.elevated,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser ? AppColors.pureBlack : AppColors.textPrimary,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.elevated,
          borderRadius: BorderRadius.circular(18).copyWith(
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
