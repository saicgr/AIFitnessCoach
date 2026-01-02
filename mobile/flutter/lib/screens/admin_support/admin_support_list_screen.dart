import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers/admin_provider.dart';
import '../../data/services/haptic_service.dart';
import 'admin_support_provider.dart';

/// Admin support chat list screen - shows all active support chats
class AdminSupportListScreen extends ConsumerStatefulWidget {
  const AdminSupportListScreen({super.key});

  @override
  ConsumerState<AdminSupportListScreen> createState() => _AdminSupportListScreenState();
}

class _AdminSupportListScreenState extends ConsumerState<AdminSupportListScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh chats on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminSupportChatsProvider.notifier).refreshChats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);

    // If not admin, show access denied
    if (!isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.pureBlack,
        appBar: AppBar(
          backgroundColor: AppColors.pureBlack,
          title: const Text('Admin Support'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: AppColors.textMuted),
              SizedBox(height: 16),
              Text(
                'Admin Access Required',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'You do not have permission to access this area.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final chatsAsync = ref.watch(adminSupportChatsProvider);

    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      appBar: AppBar(
        backgroundColor: AppColors.pureBlack,
        title: const Text('Support Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              HapticService.light();
              ref.read(adminSupportChatsProvider.notifier).refreshChats();
            },
          ),
        ],
      ),
      body: chatsAsync.when(
        data: (chats) {
          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: AppColors.textMuted.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No active support chats',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'When users request support, their chats will appear here.',
                    style: TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(adminSupportChatsProvider.notifier).refreshChats();
            },
            color: AppColors.cyan,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                return _ChatCard(
                  chat: chat,
                  onTap: () {
                    HapticService.light();
                    context.push('/admin-support/chat/${chat.ticketId}');
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.cyan),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load chats',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(adminSupportChatsProvider.notifier).refreshChats();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatCard extends StatelessWidget {
  final AdminSupportChat chat;
  final VoidCallback onTap;

  const _ChatCard({
    required this.chat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(chat.status);
    final timeAgo = _formatTimeAgo(chat.lastMessageAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(12),
        border: chat.hasUnread
            ? Border.all(color: AppColors.cyan.withOpacity(0.5), width: 1.5)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // User avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          chat.userName.isNotEmpty ? chat.userName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cyan,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // User info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  chat.userName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (chat.hasUnread)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.cyan,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${chat.unreadCount}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  chat.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                chat.category,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Time
                    Text(
                      timeAgo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                // Last message preview
                if (chat.lastMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.pureBlack.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          chat.lastMessageIsFromUser ? Icons.person : Icons.support_agent,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            chat.lastMessage!,
                            style: TextStyle(
                              fontSize: 13,
                              color: chat.hasUnread ? AppColors.textPrimary : AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Escalated from AI indicator
                if (chat.escalatedFromAi) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.smart_toy,
                        size: 14,
                        color: AppColors.purple.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Escalated from AI Coach',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.purple.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'waiting':
        return AppColors.warning;
      case 'active':
        return AppColors.success;
      case 'closed':
        return AppColors.textMuted;
      default:
        return AppColors.cyan;
    }
  }

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}
