import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/providers/social_provider.dart';
import '../widgets/empty_state.dart';

/// Messages Tab - Shows direct messages between users
/// First message for new users is from support@fitwiz.us
class MessagesTab extends ConsumerStatefulWidget {
  const MessagesTab({super.key});

  @override
  ConsumerState<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends ConsumerState<MessagesTab> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authStateProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      return SocialEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Not Logged In',
        description: 'Please log in to see your messages',
        actionLabel: null,
        onAction: null,
      );
    }

    // Watch conversations provider
    final conversationsAsync = ref.watch(conversationsProvider(userId));

    return conversationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        debugPrint('Error loading conversations: $error');
        return SocialEmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Failed to Load Messages',
          description: 'Could not load your conversations.\nPlease try again later.',
          actionLabel: 'Retry',
          onAction: () {
            ref.invalidate(conversationsProvider(userId));
          },
        );
      },
      data: (conversations) {
        if (conversations.isEmpty) {
          return SocialEmptyState(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'No Messages Yet',
            description: 'Start a conversation with your friends!\nYour messages will appear here.',
            actionLabel: null,
            onAction: null,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            return _ConversationCard(
              conversation: conversation,
              currentUserId: userId,
              isDark: isDark,
            );
          },
        );
      },
    );
  }
}

class _ConversationCard extends StatelessWidget {
  final Map<String, dynamic> conversation;
  final String currentUserId;
  final bool isDark;

  const _ConversationCard({
    required this.conversation,
    required this.currentUserId,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final otherUserName = conversation['other_user_name'] as String? ?? 'User';
    final otherUserAvatar = conversation['other_user_avatar'] as String?;
    final lastMessage = conversation['last_message'] as String? ?? '';
    final lastMessageTime = conversation['last_message_time'] as String?;
    final unreadCount = conversation['unread_count'] as int? ?? 0;
    final isSupportUser = conversation['is_support_user'] as bool? ?? false;
    final conversationId = conversation['id'] as String? ?? '';

    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/social/messages/$conversationId');
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: isSupportUser ? AppColors.teal : AppColors.purple,
                      backgroundImage: otherUserAvatar != null
                          ? NetworkImage(otherUserAvatar)
                          : null,
                      child: otherUserAvatar == null
                          ? Icon(
                              isSupportUser ? Icons.support_agent : Icons.person,
                              color: Colors.white,
                              size: 24,
                            )
                          : null,
                    ),
                    // Support badge
                    if (isSupportUser)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.teal,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: cardBg,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.verified,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isSupportUser ? 'FitWiz Support' : otherUserName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (lastMessageTime != null)
                            Text(
                              _formatTime(lastMessageTime),
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMessage,
                              style: TextStyle(
                                fontSize: 13,
                                color: unreadCount > 0 ? textPrimary : textSecondary,
                                fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: context.colors.accent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                unreadCount > 99 ? '99+' : '$unreadCount',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: context.colors.accentContrast,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(String timeString) {
    try {
      final time = DateTime.parse(timeString);
      final now = DateTime.now();
      final diff = now.difference(time);

      if (diff.inMinutes < 1) {
        return 'Now';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h';
      } else if (diff.inDays < 7) {
        return '${diff.inDays}d';
      } else {
        return '${time.month}/${time.day}';
      }
    } catch (e) {
      return '';
    }
  }
}
