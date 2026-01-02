import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/support_provider.dart';
import '../../../models/support_ticket.dart';

/// Screen showing all user's support tickets
class SupportTicketsScreen extends ConsumerStatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  ConsumerState<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends ConsumerState<SupportTicketsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref.read(supportTicketsProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final ticketsAsync = ref.watch(supportTicketsProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Support Tickets',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.cyan,
          unselectedLabelColor: textSecondary,
          indicatorColor: AppColors.cyan,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Closed'),
          ],
        ),
      ),
      body: ticketsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.cyan),
        ),
        error: (error, _) => _buildErrorState(error, isDark),
        data: (tickets) {
          final openTickets = tickets.where((t) => !t.isClosed && !t.isResolved).toList();
          final closedTickets = tickets.where((t) => t.isClosed || t.isResolved).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTicketsList(
                tickets: openTickets,
                emptyMessage: 'No active tickets',
                emptySubtitle: 'Create a new ticket to get help from our support team',
                isDark: isDark,
              ),
              _buildTicketsList(
                tickets: closedTickets,
                emptyMessage: 'No closed tickets',
                emptySubtitle: 'Your resolved tickets will appear here',
                isDark: isDark,
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/support-tickets/create'),
        backgroundColor: AppColors.cyan,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Ticket',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTicketsList({
    required List<SupportTicket> tickets,
    required String emptyMessage,
    required String emptySubtitle,
    required bool isDark,
  }) {
    if (tickets.isEmpty) {
      return _buildEmptyState(emptyMessage, emptySubtitle, isDark);
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.cyan,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          final ticket = tickets[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _TicketCard(
              ticket: ticket,
              onTap: () => context.push('/support-tickets/${ticket.id}'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message, String subtitle, bool isDark) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.cyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.support_agent,
                size: 40,
                color: AppColors.cyan.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
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

  Widget _buildErrorState(Object error, bool isDark) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load tickets',
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
              onPressed: _refresh,
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
}

/// Ticket card widget
class _TicketCard extends StatelessWidget {
  final SupportTicket ticket;
  final VoidCallback onTap;

  const _TicketCard({
    required this.ticket,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ticket.hasUnreadUpdates ? AppColors.cyan.withOpacity(0.5) : cardBorder,
          width: ticket.hasUnreadUpdates ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with ticket number and status
                Row(
                  children: [
                    Text(
                      ticket.ticketNumber,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cyan,
                      ),
                    ),
                    const Spacer(),
                    _StatusBadge(status: ticket.status),
                    if (ticket.hasUnreadUpdates) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.cyan,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Subject
                Text(
                  ticket.subject,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Category and priority
                Row(
                  children: [
                    _CategoryChip(category: ticket.category),
                    const SizedBox(width: 8),
                    _PriorityChip(priority: ticket.priority),
                  ],
                ),
                const SizedBox(height: 12),

                // Last update time
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Updated ${_formatTimeAgo(ticket.updatedAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Status badge widget
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case 'open':
        backgroundColor = AppColors.cyan.withOpacity(0.15);
        textColor = AppColors.cyan;
        text = 'Open';
        break;
      case 'in_progress':
        backgroundColor = AppColors.orange.withOpacity(0.15);
        textColor = AppColors.orange;
        text = 'In Progress';
        break;
      case 'awaiting_response':
        backgroundColor = AppColors.purple.withOpacity(0.15);
        textColor = AppColors.purple;
        text = 'Awaiting Response';
        break;
      case 'resolved':
        backgroundColor = AppColors.success.withOpacity(0.15);
        textColor = AppColors.success;
        text = 'Resolved';
        break;
      case 'closed':
        backgroundColor = AppColors.textSecondary.withOpacity(0.15);
        textColor = AppColors.textSecondary;
        text = 'Closed';
        break;
      default:
        backgroundColor = AppColors.textSecondary.withOpacity(0.15);
        textColor = AppColors.textSecondary;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

/// Category chip widget
class _CategoryChip extends StatelessWidget {
  final String category;

  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    String text;
    IconData icon;

    switch (category) {
      case 'billing':
        text = 'Billing';
        icon = Icons.receipt_long;
        break;
      case 'technical':
        text = 'Technical';
        icon = Icons.build;
        break;
      case 'feature_request':
        text = 'Feature';
        icon = Icons.lightbulb_outline;
        break;
      case 'bug_report':
        text = 'Bug';
        icon = Icons.bug_report;
        break;
      case 'account':
        text = 'Account';
        icon = Icons.person_outline;
        break;
      default:
        text = 'Other';
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Priority chip widget
class _PriorityChip extends StatelessWidget {
  final String priority;

  const _PriorityChip({required this.priority});

  @override
  Widget build(BuildContext context) {
    Color dotColor;

    switch (priority) {
      case 'urgent':
        dotColor = AppColors.error;
        break;
      case 'high':
        dotColor = AppColors.orange;
        break;
      case 'medium':
        dotColor = AppColors.warning;
        break;
      case 'low':
        dotColor = AppColors.success;
        break;
      default:
        dotColor = AppColors.textSecondary;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            priority.substring(0, 1).toUpperCase() + priority.substring(1),
            style: TextStyle(
              fontSize: 11,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
