import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../live_chat_screen.dart';

/// Message bubble widget for live chat messages
/// Supports different styling for user vs agent messages
class LiveChatMessageBubble extends StatelessWidget {
  final LiveChatMessage message;
  final bool showAgentInfo;

  const LiveChatMessageBubble({
    super.key,
    required this.message,
    this.showAgentInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isFromUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Agent avatar (left side)
          if (!isUser && showAgentInfo) ...[
            _AgentAvatar(
              name: message.agentName ?? 'Agent',
              avatarUrl: message.agentAvatarUrl,
            ),
            const SizedBox(width: 8),
          ],

          // Message content
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Agent name (for agent messages)
                if (!isUser && showAgentInfo && message.agentName != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      message.agentName!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cyan,
                      ),
                    ),
                  ),

                // Message bubble
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.cyan
                        : (isDark ? AppColors.elevated : AppColorsLight.elevated),
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: isUser ? const Radius.circular(4) : null,
                      bottomLeft: !isUser ? const Radius.circular(4) : null,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Message text
                      Text(
                        message.content,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: isUser
                              ? Colors.white
                              : (isDark
                                  ? AppColors.textPrimary
                                  : AppColorsLight.textPrimary),
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Timestamp and read receipt
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(message.timestamp),
                            style: TextStyle(
                              fontSize: 10,
                              color: isUser
                                  ? Colors.white.withOpacity(0.7)
                                  : AppColors.textMuted,
                            ),
                          ),
                          if (isUser) ...[
                            const SizedBox(width: 4),
                            _ReadReceiptIndicator(isRead: message.isRead),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Spacer for user messages (right side)
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideX(
          begin: isUser ? 0.1 : -0.1,
          end: 0,
          duration: 200.ms,
          curve: Curves.easeOut,
        );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Agent avatar widget
class _AgentAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;

  const _AgentAvatar({
    required this.name,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.cyan, AppColors.teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: avatarUrl != null
          ? ClipOval(
              child: Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => _buildInitial(),
              ),
            )
          : _buildInitial(),
    );
  }

  Widget _buildInitial() {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'A',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

/// Read receipt indicator (checkmarks)
class _ReadReceiptIndicator extends StatelessWidget {
  final bool isRead;

  const _ReadReceiptIndicator({required this.isRead});

  @override
  Widget build(BuildContext context) {
    return Icon(
      isRead ? Icons.done_all : Icons.done,
      size: 14,
      color: isRead
          ? Colors.white.withOpacity(0.9)
          : Colors.white.withOpacity(0.6),
    );
  }
}

/// System message bubble (for chat events like "chat ended")
class SystemMessageBubble extends StatelessWidget {
  final String message;
  final DateTime timestamp;

  const SystemMessageBubble({
    super.key,
    required this.message,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.glassSurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
