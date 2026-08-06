import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Row 53 (E2E) — shown instead of the "TRY ASKING…" new-chat landing when
/// the user explicitly opened a saved session from HISTORY and it resolved
/// to zero messages (its `chat_history` rows are gone even though the
/// session shell — and anything derived from it, like `coach_memory` —
/// survived). Before this existed, an orphaned session rendered PIXEL
/// IDENTICAL to a genuinely brand-new chat, so the tap read as a no-op with
/// no way to tell the conversation the user came to read was actually lost.
///
/// Deliberately distinct from that landing: this IS a conversation the user
/// expected to see, not an invitation to start one.
class EmptySessionState extends StatelessWidget {
  const EmptySessionState({super.key, required this.onBackToChats});

  final VoidCallback onBackToChats;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      key: const ValueKey('empty_session'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 48,
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'This conversation has no messages',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Its messages didn't save. This chat is empty — it isn't a "
              'new one.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: onBackToChats,
              child: const Text('Back to Chats'),
            ),
          ],
        ),
      ),
    );
  }
}
