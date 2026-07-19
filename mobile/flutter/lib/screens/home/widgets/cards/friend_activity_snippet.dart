/// F3.52 — Friend activity snippet. Surfaces the most recent friend event
/// from the social feed (workout completed, milestone, etc.). Collapses
/// gracefully if the feed is empty or unavailable.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/user_provider.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/social_provider.dart';
import '../../../../data/services/haptic_service.dart';

class FriendActivitySnippet extends ConsumerWidget {
  const FriendActivitySnippet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);

    String? userId;
    try {
      userId = ref.watch(currentUserProvider.select((u) => u.valueOrNull?.id));
    } catch (_) {}
    if (userId == null) return const SizedBox.shrink();

    Map<String, dynamic>? feed;
    try {
      feed = ref.watch(activityFeedProvider(userId)).valueOrNull;
    } catch (_) {}
    if (feed == null) return const SizedBox.shrink();

    List items = const [];
    final raw = feed['items'] ?? feed['activities'] ?? feed['feed'];
    if (raw is List) items = raw;
    if (items.isEmpty) return const SizedBox.shrink();

    final first = items.first;
    if (first is! Map) return const SizedBox.shrink();

    final name = (first['user_name'] ?? first['username'] ?? 'A friend').toString();
    final action = (first['action'] ?? first['type'] ?? first['title'] ?? '')
        .toString();
    final summary = (first['summary'] ?? first['body'] ?? first['description'] ?? '')
        .toString();

    final headline = action.isNotEmpty ? '$name $action' : '$name just logged something';

    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('/social');
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c.cardBorder.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('👥', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    headline,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (summary.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      summary,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: c.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: c.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
