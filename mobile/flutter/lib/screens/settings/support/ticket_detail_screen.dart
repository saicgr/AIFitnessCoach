import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/support_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../models/support_ticket.dart';
import '../../../widgets/glass_back_button.dart';

/// Screen showing ticket details and message thread
class TicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;

  const TicketDetailScreen({
    super.key,
    required this.ticketId,
  });

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final _replyController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Load ticket details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedTicketProvider.notifier).loadTicket(widget.ticketId);
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendReply() async {
    final content = _replyController.text.trim();
    if (content.isEmpty) return;

    final authState = ref.read(authStateProvider);
    if (authState.user == null) return;

    setState(() => _isSending = true);

    try {
      await ref.read(selectedTicketProvider.notifier).addReply(
        userId: authState.user!.id,
        content: content,
      );

      _replyController.clear();
      _scrollToBottom();

      // Also refresh the tickets list
      ref.read(supportTicketsProvider.notifier).refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reply: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _closeTicket() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
        final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
        final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

        return AlertDialog(
          backgroundColor: elevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Close Ticket?',
            style: TextStyle(color: textPrimary),
          ),
          content: Text(
            'Are you sure you want to close this ticket? You won\'t be able to send more messages.',
            style: TextStyle(color: textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Close Ticket'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await ref.read(selectedTicketProvider.notifier).closeTicket();
        ref.read(supportTicketsProvider.notifier).refresh();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ticket closed successfully'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to close ticket: ${e.toString()}'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final ticketAsync = ref.watch(selectedTicketProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const GlassBackButton(),
        title: ticketAsync.when(
          data: (ticket) => Text(
            ticket?.ticketNumber ?? 'Ticket',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          loading: () => Text(
            'Loading...',
            style: TextStyle(color: textPrimary),
          ),
          error: (_, __) => Text(
            'Error',
            style: TextStyle(color: textPrimary),
          ),
        ),
        centerTitle: true,
        actions: [
          ticketAsync.when(
            data: (ticket) {
              if (ticket != null && ticket.canReply) {
                return PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: textPrimary),
                  color: elevated,
                  onSelected: (value) {
                    if (value == 'close') {
                      _closeTicket();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'close',
                      child: Row(
                        children: [
                          const Icon(Icons.close, color: AppColors.error, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'Close Ticket',
                            style: TextStyle(color: textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: ticketAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.cyan),
        ),
        error: (error, _) => _buildErrorState(error, isDark),
        data: (ticket) {
          if (ticket == null) {
            return _buildNotFoundState(isDark);
          }

          return Column(
            children: [
              // Ticket info header
              _TicketInfoHeader(ticket: ticket),

              // Messages list
              Expanded(
                child: ticket.messages.isEmpty
                    ? _buildNoMessagesState(isDark)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: ticket.messages.length,
                        itemBuilder: (context, index) {
                          final message = ticket.messages[index];
                          return _MessageBubble(message: message);
                        },
                      ),
              ),

              // Reply input (if ticket is open)
              if (ticket.canReply)
                _ReplyInput(
                  controller: _replyController,
                  isSending: _isSending,
                  onSend: _sendReply,
                )
              else
                _ClosedTicketBanner(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorState(Object error, bool isDark) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load ticket',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(selectedTicketProvider.notifier).loadTicket(widget.ticketId);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState(bool isDark) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Ticket not found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This ticket may have been deleted or doesn\'t exist',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMessagesState(bool isDark) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 48,
            color: textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ticket info header widget
class _TicketInfoHeader extends StatelessWidget {
  final SupportTicket ticket;

  const _TicketInfoHeader({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    Color statusColor;
    switch (ticket.status) {
      case 'open':
        statusColor = AppColors.cyan;
        break;
      case 'in_progress':
        statusColor = AppColors.orange;
        break;
      case 'awaiting_response':
        statusColor = AppColors.purple;
        break;
      case 'resolved':
        statusColor = AppColors.success;
        break;
      case 'closed':
        statusColor = AppColors.textSecondary;
        break;
      default:
        statusColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        border: Border(
          bottom: BorderSide(color: cardBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject
          Text(
            ticket.subject,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Status and category row
          Row(
            children: [
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ticket.statusDisplayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Category
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.nearBlack : AppColorsLight.nearWhite,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ticket.categoryDisplayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ),
              const Spacer(),

              // Created date
              Text(
                'Created ${_formatDate(ticket.createdAt)}',
                style: TextStyle(
                  fontSize: 11,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return 'Just now';
    }
  }
}

/// Message bubble widget
class _MessageBubble extends StatelessWidget {
  final TicketMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = message.isFromUser;

    final userBubbleColor = AppColors.cyan;
    final supportBubbleColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // Support avatar
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.purple, AppColors.cyan],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Message bubble
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Sender name
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    isUser ? 'You' : message.senderName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                ),

                // Message content
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? userBubbleColor : supportBubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: isUser
                        ? null
                        : Border.all(
                            color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                          ),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUser ? Colors.white : textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),

                // Time
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    message.formattedTime,
                    style: TextStyle(
                      fontSize: 10,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (isUser) ...[
            const SizedBox(width: 8),
            // User avatar
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.cyan.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: AppColors.cyan,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Reply input widget
class _ReplyInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _ReplyInput({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: elevated,
        border: Border(
          top: BorderSide(color: cardBorder),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(color: textPrimary),
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Type your reply...',
                hintStyle: TextStyle(color: textSecondary),
                filled: true,
                fillColor: isDark ? AppColors.nearBlack : AppColorsLight.nearWhite,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: isSending ? null : onSend,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSending ? AppColors.cyan.withOpacity(0.5) : AppColors.cyan,
                shape: BoxShape.circle,
              ),
              child: isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 22,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Closed ticket banner widget
class _ClosedTicketBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: elevated,
        border: Border(
          top: BorderSide(color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 18,
            color: textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            'This ticket is closed',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
