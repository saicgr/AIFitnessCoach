import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/models/coach_persona.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/coach_avatar.dart';
import 'food_analysis_inline_card.dart';
import 'food_analysis_result_card.dart';
import 'form_check_result_card.dart';
import 'form_comparison_result_card.dart';
import 'fullscreen_image_viewer.dart';
import 'report_message_sheet.dart';
import 'voice_message_widget.dart';
import 'chat_media_widgets.dart';

/// A single chat message bubble (user, assistant, system, or error)
class ChatMessageBubble extends ConsumerWidget {
  final ChatMessage message;
  final String? previousUserMessage;
  final CoachPersona coach;
  final void Function(List<Map<String, dynamic>>)? onLogAnalysisItems;
  final VoidCallback? onRetry;
  final VoidCallback? onRegenerate;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.coach,
    this.previousUserMessage,
    this.onLogAnalysisItems,
    this.onRetry,
    this.onRegenerate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUser = message.role == 'user';
    final isSystem = message.role == 'system';
    final isError = message.role == 'error';

    final messageCoach = (message.coachPersonaId != null
        ? CoachPersona.findById(message.coachPersonaId)
        : null) ?? coach;

    if (isSystem) {
      return _buildSystemMessage(context);
    }

    if (isError) {
      return _buildErrorMessage(context);
    }

    Widget bubbleContent = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
      ),
      decoration: BoxDecoration(
        color: isUser ? AppColors.cyan : AppColors.elevated,
        borderRadius: BorderRadius.circular(16).copyWith(
          bottomRight: isUser ? const Radius.circular(4) : null,
          bottomLeft: !isUser ? const Radius.circular(4) : null,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CoachAvatar(
                    coach: messageCoach,
                    size: 20,
                    showBorder: true,
                    borderWidth: 1,
                    showShadow: false,
                    enableTapToView: false,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    messageCoach.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: messageCoach.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          // Media thumbnail for user messages
          if (isUser && message.hasMedia)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: message.mediaType != 'video'
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FullscreenImageViewer(
                              imageUrl: message.mediaUrl,
                              localFilePath: message.localFilePath,
                              heroTag: 'chat_media_${message.id}',
                            ),
                          ),
                        )
                    : null,
                child: Hero(
                  tag: 'chat_media_${message.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      height: 150,
                      child: Stack(
                        children: [
                          if (message.localFilePath != null)
                            Image.file(
                              File(message.localFilePath!),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 150,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.black12,
                                child: Center(
                                  child: Icon(
                                    message.mediaType == 'video' ? Icons.videocam : Icons.image,
                                    size: 32,
                                    color: Colors.white54,
                                  ),
                                ),
                              ),
                            )
                          else if (message.mediaUrl != null)
                            CachedNetworkImage(
                              imageUrl: message.mediaUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 150,
                              placeholder: (_, __) => Container(
                                color: Colors.black12,
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: Colors.black12,
                                child: Center(
                                  child: Icon(
                                    message.mediaType == 'video' ? Icons.videocam : Icons.image,
                                    size: 32,
                                    color: Colors.white54,
                                  ),
                                ),
                              ),
                            ),
                          if (message.uploadPhase != null)
                            Positioned.fill(
                              child: MediaUploadOverlay(
                                phase: message.uploadPhase!,
                                progress: message.uploadProgress,
                              ),
                            )
                          else if (message.mediaType == 'video')
                            const Positioned.fill(
                              child: Center(
                                child: Icon(Icons.play_circle_outline, color: Colors.white70, size: 40),
                              ),
                            ),
                          if (isUser && message.mediaRefs != null && message.mediaRefs!.length > 1)
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '+${message.mediaRefs!.length - 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Upload progress indicator
          if (isUser && !message.hasMedia && message.mediaType != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 48,
                  width: 140,
                  decoration: BoxDecoration(
                    color: AppColors.pureBlack.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.pureBlack.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Uploading...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.pureBlack.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (message.isVoiceMessage)
            VoiceMessageBubble(
              audioUrl: message.audioUrl!,
              durationMs: message.audioDurationMs ?? 0,
            )
          else
            Text(
              message.content,
              style: TextStyle(
                color: isUser ? AppColors.pureBlack : AppColors.textPrimary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          if (!isUser && message.hasFormCheckResult)
            FormCheckResultCard(result: message.formCheckResult!),
          if (!isUser && message.hasFoodAnalysis &&
              (message.actionData!['food_items'] as List).length <= 5)
            FoodAnalysisInlineCard(
              foodItems: (message.actionData!['food_items'] as List)
                  .cast<Map<String, dynamic>>(),
              onLogItems: onLogAnalysisItems != null
                  ? (items) => onLogAnalysisItems!(items)
                  : (_) {},
            ),
          if (!isUser && message.hasFoodAnalysis &&
              (message.actionData!['food_items'] as List).length > 5)
            FoodAnalysisSummaryCard(
              foodItems: (message.actionData!['food_items'] as List)
                  .cast<Map<String, dynamic>>(),
              onViewAll: onLogAnalysisItems,
            ),
          if (!isUser && (message.hasBuffetAnalysis || message.hasMenuAnalysis ||
              (message.actionData?['action'] == 'analyze_multi_food_images')))
            FoodAnalysisResultCard(
              data: message.actionData!,
              onLogItems: onLogAnalysisItems != null ? (items) => onLogAnalysisItems!(items) : null,
            ),
          if (!isUser && message.hasFormComparison)
            FormComparisonResultCard(data: message.actionData!),
          if (!isUser && message.hasGeneratedWorkout)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: GoToWorkoutButton(
                workoutId: message.workoutId!,
                workoutName: message.workoutName,
              ),
            ),
          // Timestamp + delivery status
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp ?? DateTime.now()),
                  style: TextStyle(
                    fontSize: 10,
                    color: isUser
                        ? AppColors.pureBlack.withOpacity(0.6)
                        : AppColors.textMuted,
                  ),
                ),
                if (isUser) ...[
                  const SizedBox(width: 4),
                  _buildStatusIcon(message.status),
                ],
              ],
            ),
          ),
          if (!isUser && message.actionData?['offline'] == true)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Generated offline by ${message.actionData?['model'] ?? 'Local AI'}',
                style: TextStyle(
                  fontSize: 9,
                  fontStyle: FontStyle.italic,
                  color: isUser
                      ? AppColors.pureBlack.withOpacity(0.4)
                      : AppColors.textMuted.withOpacity(0.6),
                ),
              ),
            ),
        ],
      ),
    );

    bubbleContent = GestureDetector(
      onLongPress: () {
        HapticService.medium();
        _showMessageContextMenu(context, ref, isUser);
      },
      child: bubbleContent,
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: bubbleContent,
    );
  }

  Widget _buildStatusIcon(MessageStatus status) {
    final statusColor = AppColors.pureBlack.withOpacity(0.5);
    switch (status) {
      case MessageStatus.pending:
        return Icon(Icons.access_time, size: 10, color: statusColor);
      case MessageStatus.sent:
        return Icon(Icons.check, size: 10, color: statusColor);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 10, color: AppColors.cyan);
      case MessageStatus.error:
        return const Icon(Icons.close, size: 10, color: AppColors.error);
    }
  }

  void _showMessageContextMenu(BuildContext context, WidgetRef ref, bool isUser) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.elevated : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.copy, size: 20),
                  title: const Text('Copy'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Clipboard.setData(ClipboardData(text: message.content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                if (!isUser && onRegenerate != null)
                  ListTile(
                    leading: const Icon(Icons.refresh, size: 20),
                    title: const Text('Regenerate'),
                    onTap: () {
                      Navigator.pop(ctx);
                      onRegenerate!();
                    },
                  ),
                if (message.id != null)
                  ListTile(
                    leading: Icon(
                      message.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      size: 20,
                    ),
                    title: Text(message.isPinned ? 'Unpin' : 'Pin'),
                    onTap: () {
                      Navigator.pop(ctx);
                      ref.read(chatMessagesProvider.notifier).togglePin(message.id!);
                    },
                  ),
                if (isUser)
                  ListTile(
                    leading: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                    title: const Text('Delete', style: TextStyle(color: AppColors.error)),
                    onTap: () {
                      Navigator.pop(ctx);
                      showDialog(
                        context: context,
                        builder: (dlgCtx) => AlertDialog(
                          title: const Text('Delete this message?'),
                          content: const Text('This action cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dlgCtx),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(dlgCtx);
                                if (message.id != null) {
                                  ref.read(chatMessagesProvider.notifier).deleteMessage(message.id!);
                                } else {
                                  final current = ref.read(chatMessagesProvider).valueOrNull ?? [];
                                  final updated = current.where((m) => m != message).toList();
                                  ref.read(chatMessagesProvider.notifier).state = AsyncValue.data(updated);
                                }
                              },
                              child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                if (!isUser)
                  ListTile(
                    leading: const Icon(Icons.flag_outlined, size: 20, color: AppColors.orange),
                    title: const Text('Report'),
                    onTap: () {
                      Navigator.pop(ctx);
                      showReportMessageSheet(
                        context,
                        messageId: message.id,
                        originalUserMessage: previousUserMessage ?? '',
                        aiResponse: message.content,
                      );
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorMessage(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.red.withOpacity(0.1)
              : Colors.red.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, size: 18,
                    color: isDark ? Colors.red[300] : Colors.red[600]),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    message.content,
                    style: TextStyle(fontSize: 13,
                        color: isDark ? Colors.red[300] : Colors.red[700]),
                  ),
                ),
              ],
            ),
            if (onRetry != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  onPressed: onRetry,
                  icon: Icon(Icons.refresh, size: 14,
                      color: isDark ? Colors.red[300] : Colors.red[600]),
                  label: Text('Retry',
                      style: TextStyle(fontSize: 12,
                          color: isDark ? Colors.red[300] : Colors.red[600])),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemMessage(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? AppColors.cardBorder.withOpacity(0.5)
                : AppColorsLight.cardBorder.withOpacity(0.5),
          ),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);

    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute';

    if (messageDate == today) {
      return timeStr;
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, $timeStr';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[time.month - 1]} ${time.day}, $timeStr';
    }
  }
}
