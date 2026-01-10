import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/chat_message.dart';
import '../../data/repositories/chat_repository.dart';
import '../../screens/ai_settings/ai_settings_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'floating_chat_provider.dart';

/// Floating AI Coach chat bubble widget
/// This is a self-contained widget that can be added to any Stack
/// Uses floatingChatProvider for persistent state across navigation
class FloatingChatBubble extends ConsumerWidget {
  const FloatingChatBubble({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(floatingChatProvider);
    final notifier = ref.read(floatingChatProvider.notifier);
    final screenSize = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Show the bubble as a Positioned widget - tap navigates to full chat screen
    return Positioned(
      right: chatState.bubbleRight,
      bottom: chatState.bubbleBottom + bottomPadding,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          debugPrint('FloatingChatBubble: Tapped - navigating to /chat');
          // Navigate to full chat screen for proper keyboard handling
          context.push('/chat');
        },
        onPanStart: (_) => notifier.setDragging(true),
        onPanUpdate: (details) {
          final newRight = (chatState.bubbleRight - details.delta.dx).clamp(16.0, screenSize.width - 72);
          final newBottom = (chatState.bubbleBottom - details.delta.dy).clamp(100.0, screenSize.height - 200);
          notifier.updateBubblePosition(newRight, newBottom);
        },
        onPanEnd: (_) => notifier.setDragging(false),
        child: AnimatedScale(
          scale: chatState.isDragging ? 1.1 : 1.0,
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
                  color: AppColors.cyan.withValues(alpha: chatState.isDragging ? 0.6 : 0.4),
                  blurRadius: chatState.isDragging ? 20 : 16,
                  offset: const Offset(0, 4),
                  spreadRadius: chatState.isDragging ? 2 : 0,
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

/// Expandable chat modal
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

    // Get coach name from AI settings
    final aiSettings = ref.watch(aiSettingsProvider);
    final coachName = aiSettings.coachName ?? 'AI Coach';

    return Container(
      height: screenHeight * 0.7,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
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
                        coachName,
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
                IconButton(
                  icon: Icon(Icons.close, color: textMuted),
                  onPressed: widget.onClose,
                  tooltip: 'Close',
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
              color: nearBackgroundColor,
              border: Border(
                top: BorderSide(color: cardBorder.withValues(alpha: 0.5)),
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
                    style: TextStyle(fontSize: 14, color: textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Ask your AI coach...',
                      hintStyle: TextStyle(color: textMuted),
                      filled: true,
                      fillColor: glassSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

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
                colors: [cyan, purple],
              ),
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
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
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
                      child: Text(
                        suggestion,
                        style: TextStyle(color: textPrimary),
                      ),
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

  Widget _buildMessageBubble(ChatMessage message) {
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

  Widget _buildTypingIndicator() {
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
