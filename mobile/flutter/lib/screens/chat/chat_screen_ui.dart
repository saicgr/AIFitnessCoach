part of 'chat_screen.dart';

/// Live assistant bubble that types out token-by-token (Part 5 — C4).
///
/// This widget is bound directly to [ChatMessagesNotifier.streamingBubble] via
/// a [ValueListenableBuilder], so each arriving token repaints ONLY this
/// bubble — the surrounding `ListView` and every other bubble stay still.
///
/// On a mid-stream drop the bound [StreamingBubbleState.dropped] flips true:
/// the partial text is KEPT (C2) and a "Connection dropped" + Retry row is
/// shown beneath it instead of the bubble vanishing.
class _StreamingBubble extends StatelessWidget {
  /// The notifier whose `streamingBubble` listenable drives this widget.
  final ChatMessagesNotifier notifier;

  /// The active coach persona — used for the avatar next to the bubble.
  final CoachPersona coach;

  /// Retry callback fired when a dropped stream's "Retry" chip is tapped.
  final VoidCallback onRetry;

  const _StreamingBubble({
    required this.notifier,
    required this.coach,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ValueListenableBuilder<StreamingBubbleState?>(
      valueListenable: notifier.streamingBubble,
      builder: (context, streaming, _) {
        // No active stream — render nothing; the list shows the typing
        // indicator or committed bubbles instead.
        if (streaming == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CoachAvatar(
                    coach: coach,
                    size: 28,
                    showBorder: true,
                    showShadow: false,
                    enableTapToView: false,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            isDark ? AppColors.elevated : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16).copyWith(
                          bottomLeft: const Radius.circular(4),
                        ),
                      ),
                      child: Text(
                        // While tokens arrive the text grows; an empty string
                        // is impossible here (the bubble is only created on
                        // the first non-empty token).
                        streaming.content,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color:
                              isDark ? Colors.white : AppColorsLight.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // C2 — mid-stream drop: keep the partial text above, surface a
              // resume/retry affordance here.
              if (streaming.dropped)
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 6, start: 36),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off_rounded,
                          size: 14, color: AppColors.warning),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context).chatScreenUiConnectionDropped,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.warning,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          HapticService.light();
                          onRetry();
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.refresh_rounded,
                                size: 14, color: AppColors.cyan),
                            const SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(context).buttonRetry,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.cyan,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Still streaming — a subtle "typing" caret cue under the
                // bubble so the user knows more text is coming.
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 4, start: 36),
                  child: Text(
                    AppLocalizations.of(context).chatScreenUiTyping,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textMuted
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// UI builder methods extracted from _ChatScreenState
extension _ChatScreenStateUI on _ChatScreenState {

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final local = date.toLocal();
    final messageDate = DateTime(local.year, local.month, local.day);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String label;
    if (messageDate == today) {
      label = 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      label = 'Yesterday';
    } else {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      label = '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.elevated.withOpacity(0.7)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textMuted : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildMiniPickerOption({
    required BuildContext ctx,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colors = ThemeColors.of(ctx);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: colors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

}
