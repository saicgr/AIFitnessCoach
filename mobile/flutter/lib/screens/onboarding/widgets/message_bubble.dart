import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';

/// Simple markdown text widget that supports **bold**, *italic*, and emojis
class _MarkdownText extends StatelessWidget {
  final String text;
  final TextStyle baseStyle;

  const _MarkdownText({
    required this.text,
    required this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: _parseMarkdown(text, baseStyle),
      ),
    );
  }

  List<InlineSpan> _parseMarkdown(String text, TextStyle baseStyle) {
    final List<InlineSpan> spans = [];

    // Regex patterns for markdown
    // Order matters: check bold (**) before italic (*)
    final pattern = RegExp(
      r'\*\*(.+?)\*\*'  // **bold**
      r'|'
      r'\*(.+?)\*'      // *italic*
      r'|'
      r'~~(.+?)~~'      // ~~strikethrough~~
      r'|'
      r'`(.+?)`',       // `code`
    );

    int lastEnd = 0;

    for (final match in pattern.allMatches(text)) {
      // Add text before this match
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }

      // Determine which group matched and apply style
      if (match.group(1) != null) {
        // **bold**
        spans.add(TextSpan(
          text: match.group(1),
          style: baseStyle.copyWith(fontWeight: FontWeight.bold),
        ));
      } else if (match.group(2) != null) {
        // *italic*
        spans.add(TextSpan(
          text: match.group(2),
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (match.group(3) != null) {
        // ~~strikethrough~~
        spans.add(TextSpan(
          text: match.group(3),
          style: baseStyle.copyWith(decoration: TextDecoration.lineThrough),
        ));
      } else if (match.group(4) != null) {
        // `code`
        spans.add(TextSpan(
          text: match.group(4),
          style: baseStyle.copyWith(
            fontFamily: 'monospace',
            backgroundColor: baseStyle.color?.withOpacity(0.1),
          ),
        ));
      }

      lastEnd = match.end;
    }

    // Add remaining text after last match
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    // If no matches, return original text
    if (spans.isEmpty) {
      spans.add(TextSpan(text: text));
    }

    return spans;
  }
}

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
                  // Use markdown rendering for AI messages, plain text for user
                  if (isUser)
                    Text(
                      content,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.white,
                      ),
                    )
                  else
                    _MarkdownText(
                      text: content,
                      baseStyle: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: colors.textPrimary,
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
