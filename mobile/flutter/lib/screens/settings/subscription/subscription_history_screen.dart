import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/subscription_repository.dart';
import '../../../data/services/api_client.dart';

/// Subscription History Screen
/// Shows a timeline of all subscription events with color-coded badges
class SubscriptionHistoryScreen extends ConsumerStatefulWidget {
  const SubscriptionHistoryScreen({super.key});

  @override
  ConsumerState<SubscriptionHistoryScreen> createState() => _SubscriptionHistoryScreenState();
}

class _SubscriptionHistoryScreenState extends ConsumerState<SubscriptionHistoryScreen> {
  bool _isLoading = true;
  String? _error;
  List<SubscriptionEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId != null) {
        final repository = ref.read(subscriptionRepositoryProvider);
        final events = await repository.getSubscriptionHistory(userId);

        if (mounted) {
          setState(() {
            _events = events;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'User not authenticated';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.background : AppColorsLight.background;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'Subscription History',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        color: AppColors.cyan,
        child: _buildBody(isDark, textPrimary, textSecondary),
      ),
    );
  }

  Widget _buildBody(bool isDark, Color textPrimary, Color textSecondary) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.cyan,
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState(isDark, textPrimary);
    }

    if (_events.isEmpty) {
      return _buildEmptyState(isDark, textPrimary, textSecondary);
    }

    return _buildEventsList(isDark, textPrimary, textSecondary);
  }

  Widget _buildErrorState(bool isDark, Color textPrimary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load history',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadHistory,
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

  Widget _buildEmptyState(bool isDark, Color textPrimary, Color textSecondary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Subscription History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your subscription events will appear here',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList(bool isDark, Color textPrimary, Color textSecondary) {
    // Sort events by date, newest first
    final sortedEvents = List<SubscriptionEvent>.from(_events)
      ..sort((a, b) => b.eventDate.compareTo(a.eventDate));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedEvents.length,
      itemBuilder: (context, index) {
        final event = sortedEvents[index];
        final isFirst = index == 0;
        final isLast = index == sortedEvents.length - 1;

        return _SubscriptionEventTile(
          event: event,
          isFirst: isFirst,
          isLast: isLast,
          isDark: isDark,
        );
      },
    );
  }
}

/// Individual subscription event tile with timeline
class _SubscriptionEventTile extends StatelessWidget {
  final SubscriptionEvent event;
  final bool isFirst;
  final bool isLast;
  final bool isDark;

  const _SubscriptionEventTile({
    required this.event,
    required this.isFirst,
    required this.isLast,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator
          SizedBox(
            width: 32,
            child: Column(
              children: [
                // Top line (hidden for first item)
                Container(
                  width: 2,
                  height: 12,
                  color: isFirst ? Colors.transparent : textMuted.withValues(alpha: 0.3),
                ),
                // Dot
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getEventColor(event.eventType),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getEventColor(event.eventType).withValues(alpha: 0.3),
                      width: 3,
                    ),
                  ),
                ),
                // Bottom line (hidden for last item)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : textMuted.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Event card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event type badge and date row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _EventTypeBadge(eventType: event.eventType),
                      Text(
                        DateFormat('MMM d, yyyy').format(event.eventDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Plan name
                  Text(
                    event.planName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Price
                  if (event.pricePaid != null)
                    Row(
                      children: [
                        Icon(
                          Icons.payment,
                          size: 14,
                          color: textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '\$${event.pricePaid!.toStringAsFixed(2)} ${event.currency}',
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  // Details
                  if (event.details != null && event.details!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      event.details!,
                      style: TextStyle(
                        fontSize: 13,
                        color: textMuted,
                        fontStyle: FontStyle.italic,
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
  }

  Color _getEventColor(SubscriptionEventType type) {
    switch (type) {
      case SubscriptionEventType.purchased:
        return AppColors.green;
      case SubscriptionEventType.renewed:
        return AppColors.cyan;
      case SubscriptionEventType.upgraded:
        return AppColors.purple;
      case SubscriptionEventType.downgraded:
        return AppColors.orange;
      case SubscriptionEventType.canceled:
        return Colors.red.shade400;
      case SubscriptionEventType.expired:
        return Colors.grey;
      case SubscriptionEventType.refunded:
        return Colors.amber;
    }
  }
}

/// Event type badge with color coding
class _EventTypeBadge extends StatelessWidget {
  final SubscriptionEventType eventType;

  const _EventTypeBadge({required this.eventType});

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(),
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            eventType.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    switch (eventType) {
      case SubscriptionEventType.purchased:
        return AppColors.green;
      case SubscriptionEventType.renewed:
        return AppColors.cyan;
      case SubscriptionEventType.upgraded:
        return AppColors.purple;
      case SubscriptionEventType.downgraded:
        return AppColors.orange;
      case SubscriptionEventType.canceled:
        return Colors.red.shade400;
      case SubscriptionEventType.expired:
        return Colors.grey;
      case SubscriptionEventType.refunded:
        return Colors.amber;
    }
  }

  IconData _getIcon() {
    switch (eventType) {
      case SubscriptionEventType.purchased:
        return Icons.shopping_cart;
      case SubscriptionEventType.renewed:
        return Icons.refresh;
      case SubscriptionEventType.upgraded:
        return Icons.arrow_upward;
      case SubscriptionEventType.downgraded:
        return Icons.arrow_downward;
      case SubscriptionEventType.canceled:
        return Icons.cancel;
      case SubscriptionEventType.expired:
        return Icons.schedule;
      case SubscriptionEventType.refunded:
        return Icons.money_off;
    }
  }
}
