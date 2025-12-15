import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/models/chat_message.dart';
import '../../data/repositories/chat_repository.dart';
import 'floating_chat_provider.dart';

/// Floating chat overlay - Facebook Messenger style
///
/// This widget wraps the entire app and provides:
/// 1. A floating chat bubble that can be tapped to expand
/// 2. An expandable chat modal that's keyboard-aware
/// 3. Draggable bubble position
class FloatingChatOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const FloatingChatOverlay({super.key, required this.child});

  @override
  ConsumerState<FloatingChatOverlay> createState() => _FloatingChatOverlayState();
}

class _FloatingChatOverlayState extends ConsumerState<FloatingChatOverlay>
    with WidgetsBindingObserver {
  // Keyboard height tracking
  double _keyboardHeight = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // This is called when keyboard appears/disappears
    final bottomInset = WidgetsBinding.instance.platformDispatcher.views.first.viewInsets.bottom /
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

    if (mounted) {
      setState(() {
        _keyboardHeight = bottomInset;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(floatingChatProvider);

    return Stack(
      children: [
        // Main app content
        widget.child,

        // Show chat modal when expanded (triggered by nav bar AI button)
        if (chatState.isExpanded) ...[
          // Semi-transparent backdrop
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(floatingChatProvider.notifier).collapse();
              },
              child: Container(
                color: Colors.black.withOpacity(0.6),
              ).animate().fadeIn(duration: 200.ms),
            ),
          ),

          // Chat modal - keyboard aware positioning
          Positioned(
            left: 0,
            right: 0,
            bottom: _keyboardHeight, // Moves up when keyboard appears
            child: _KeyboardAwareChatModal(
              keyboardHeight: _keyboardHeight,
              onClose: () {
                HapticFeedback.lightImpact();
                ref.read(floatingChatProvider.notifier).collapse();
              },
            ).animate().slideY(
              begin: 0.3,
              end: 0,
              duration: 300.ms,
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ],
    );
  }
}

/// Keyboard-aware chat modal
class _KeyboardAwareChatModal extends ConsumerStatefulWidget {
  final double keyboardHeight;
  final VoidCallback onClose;

  const _KeyboardAwareChatModal({
    required this.keyboardHeight,
    required this.onClose,
  });

  @override
  ConsumerState<_KeyboardAwareChatModal> createState() => _KeyboardAwareChatModalState();
}

class _KeyboardAwareChatModalState extends ConsumerState<_KeyboardAwareChatModal> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
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

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (animate) {
          _scrollController.animateTo(maxScroll, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
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
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final keyboardVisible = widget.keyboardHeight > 0;

    // Theme-aware colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final nearBackgroundColor = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

    // Calculate modal height - shrink when keyboard is visible
    final baseHeight = screenHeight * 0.7;
    final maxAvailableHeight = screenHeight - widget.keyboardHeight - 40; // 40 for top margin
    final modalHeight = keyboardVisible
        ? maxAvailableHeight.clamp(300.0, baseHeight)
        : baseHeight;

    return Material(
      type: MaterialType.transparency,
      child: Container(
        height: modalHeight,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
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
              color: textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cyan, purple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.smart_toy, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Coach',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        _isLoading ? 'Typing...' : 'Online',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isLoading
                              ? (isDark ? AppColors.orange : AppColorsLight.orange)
                              : (isDark ? AppColors.success : AppColorsLight.success),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: widget.onClose,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.close, color: textMuted),
                  ),
                ),
              ],
            ),
          ),

          Divider(color: cardBorder, height: 1),

          // Messages
          Expanded(
            child: messagesState.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: cyan),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        color: isDark ? AppColors.error : AppColorsLight.error,
                        size: 40),
                    const SizedBox(height: 12),
                    Text('Error loading messages', style: TextStyle(color: textMuted)),
                    TextButton(
                      onPressed: () => ref.read(chatMessagesProvider.notifier).loadHistory(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return _buildEmptyState(context, cyan, purple, textPrimary, textMuted, cardBorder);
                }

                // Scroll to bottom when messages change
                if (messages.length != _lastMessageCount) {
                  _lastMessageCount = messages.length;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom(animate: false);
                  });
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length && _isLoading) {
                      return _buildTypingIndicator(context);
                    }
                    return _buildMessageBubble(context, messages[index]);
                  },
                );
              },
            ),
          ),

          // Input bar - no extra bottom padding when keyboard is visible
          Container(
            padding: EdgeInsets.fromLTRB(
              12,
              10,
              12,
              keyboardVisible ? 12 : (bottomPadding + 12),
            ),
            decoration: BoxDecoration(
              color: nearBackgroundColor,
              border: Border(
                top: BorderSide(color: cardBorder.withOpacity(0.5)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    enabled: !_isLoading,
                    autofocus: false,
                    textInputAction: TextInputAction.send,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                    minLines: 1,
                    style: TextStyle(fontSize: 14, color: textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Ask your AI coach...',
                      hintStyle: TextStyle(color: textMuted, fontSize: 14),
                      filled: true,
                      fillColor: glassSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: cardBorder.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: cyan),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isLoading
                          ? [textMuted, textMuted]
                          : [cyan, purple],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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

  Widget _buildEmptyState(BuildContext context, Color cyan, Color purple, Color textPrimary, Color textMuted, Color cardBorder) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

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
              gradient: LinearGradient(colors: [cyan, purple]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, size: 30, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            'How can I help you today?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me anything about fitness',
            style: TextStyle(fontSize: 14, color: textSecondary),
          ),
          const SizedBox(height: 24),
          ...suggestions.map((suggestion) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                _textController.text = suggestion;
                _sendMessage();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: elevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 16, color: cyan),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(suggestion, style: TextStyle(color: textPrimary)),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 12, color: textMuted),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage message) {
    final isUser = message.role == 'user';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final userTextColor = isDark ? AppColors.pureBlack : Colors.white;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? cyan : elevated,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser ? userTextColor : textPrimary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: elevated,
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
              decoration: BoxDecoration(
                color: textMuted,
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
