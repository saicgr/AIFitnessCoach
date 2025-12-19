import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';

/// WhatsApp-style message bubble for conversational onboarding
/// Displays user and AI messages with proper styling
class MessageBubble extends StatelessWidget {
  final bool isUser;
  final String content;
  final DateTime? timestamp;
  final bool animate;
  final int animationIndex;

  const MessageBubble({
    super.key,
    required this.isUser,
    required this.content,
    this.timestamp,
    this.animate = true,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Calculate animation delay based on index
    final baseDelay = Duration(milliseconds: 200 + (animationIndex * 100));

    Widget bubble = Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Avatar
          if (!isUser) ...[
            _buildAiAvatar(colors),
            const SizedBox(width: 12),
          ],

          // Message Bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser ? AppColors.cyanGradient : null,
                color: isUser ? null : colors.glassSurface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                border: isUser ? null : Border.all(color: colors.cardBorder),
                boxShadow: isUser
                    ? [
                        BoxShadow(
                          color: colors.cyan.withOpacity(0.3),
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
                    content,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isUser ? Colors.white : colors.textPrimary,
                    ),
                  ),
                  if (timestamp != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(timestamp!),
                      style: TextStyle(
                        fontSize: 10,
                        color: isUser
                            ? Colors.white.withOpacity(0.7)
                            : colors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );

    // Apply entrance animation if enabled
    if (animate) {
      bubble = bubble
          .animate()
          .fadeIn(duration: 400.ms, delay: baseDelay)
          .slideX(
            begin: isUser ? 0.15 : -0.15,
            end: 0,
            duration: 400.ms,
            delay: baseDelay,
            curve: Curves.easeOutCubic,
          )
          .scale(
            begin: const Offset(0.95, 0.95),
            end: const Offset(1, 1),
            duration: 300.ms,
            delay: baseDelay,
            curve: Curves.easeOutCubic,
          );
    }

    return bubble;
  }

  Widget _buildAiAvatar(ThemeColors colors) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: AppColors.cyanGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colors.cyan.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.auto_awesome, color: Colors.white, size: 20),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
