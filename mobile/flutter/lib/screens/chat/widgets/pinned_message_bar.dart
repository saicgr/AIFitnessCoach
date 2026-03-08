import 'package:flutter/material.dart';
import 'package:fitwiz/core/constants/app_colors.dart';
import 'package:fitwiz/core/theme/theme_colors.dart';
import 'package:fitwiz/data/models/chat_message.dart';

/// A thin bar displayed at the top of the chat to indicate a pinned message.
class PinnedMessageBar extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onTap;
  final VoidCallback onUnpin;

  const PinnedMessageBar({
    super.key,
    required this.message,
    required this.onTap,
    required this.onUnpin,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: colors.elevated,
          border: Border(
            bottom: BorderSide(color: colors.cardBorder, width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(Icons.push_pin, size: 16, color: colors.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message.content.split('\n').first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            TextButton(
              onPressed: onUnpin,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Unpin',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
