import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// WhatsApp-style message bubble for conversational onboarding
/// Displays user and AI messages with proper styling and animations
/// AI messages show a typing animation before revealing the text
class MessageBubble extends StatefulWidget {
  final bool isUser;
  final String content;
  final DateTime? timestamp;
  final bool animate;

  const MessageBubble({
    super.key,
    required this.isUser,
    required this.content,
    this.timestamp,
    this.animate = true,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  bool _showTyping = false;
  bool _showContent = false;
  late AnimationController _typingController;

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();

    // For AI messages, show typing animation first
    if (!widget.isUser && widget.animate) {
      _showTyping = true;
      // Show typing for a brief period, then reveal content
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _showTyping = false;
            _showContent = true;
          });
        }
      });
    } else {
      // User messages show immediately
      _showContent = true;
    }
  }

  @override
  void dispose() {
    _typingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            widget.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Avatar
          if (!widget.isUser) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppColors.cyanGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyan.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Message Bubble
          Flexible(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _showTyping
                  ? _buildTypingBubble()
                  : _showContent
                      ? _buildMessageBubble()
                      : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Container(
      key: const ValueKey('typing'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(20),
        ),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAnimatedDot(0),
          const SizedBox(width: 4),
          _buildAnimatedDot(200),
          const SizedBox(width: 4),
          _buildAnimatedDot(400),
        ],
      ),
    );
  }

  Widget _buildAnimatedDot(int delayMs) {
    return AnimatedBuilder(
      animation: _typingController,
      builder: (context, child) {
        // Calculate bouncing animation with delay
        final progress = (_typingController.value + delayMs / 600) % 1.0;
        final bounce = (progress < 0.5)
            ? progress * 2
            : 2 - progress * 2;

        return Transform.translate(
          offset: Offset(0, -4 * bounce),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.cyan.withOpacity(0.6 + 0.4 * bounce),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble() {
    return Container(
      key: const ValueKey('message'),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: widget.isUser ? AppColors.cyanGradient : null,
        color: widget.isUser ? null : AppColors.glassSurface,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(widget.isUser ? 20 : 4),
          bottomRight: Radius.circular(widget.isUser ? 4 : 20),
        ),
        border: widget.isUser ? null : Border.all(color: AppColors.cardBorder),
        boxShadow: widget.isUser
            ? [
                BoxShadow(
                  color: AppColors.cyan.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: widget.isUser ? Colors.white : AppColors.textPrimary,
            ),
          ),
          if (widget.timestamp != null) ...[
            const SizedBox(height: 4),
            Text(
              _formatTime(widget.timestamp!),
              style: TextStyle(
                fontSize: 10,
                color: widget.isUser
                    ? Colors.white.withOpacity(0.7)
                    : AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
