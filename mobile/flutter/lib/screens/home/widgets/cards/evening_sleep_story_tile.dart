/// F3.44 — Evening sleep-story tile. Shows only after 20:00 local time.
/// Today's pick comes from `GET /api/v1/sleep-stories/today` via
/// `sleepStoryTodayProvider`. Routes to chat with `source=sleep_story`
/// until the audio player ships.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/content_catalogs_provider.dart';
import '../../../../data/services/haptic_service.dart';

class EveningSleepStoryTile extends ConsumerWidget {
  const EveningSleepStoryTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);
    final now = DateTime.now();
    if (now.hour < 20) return const SizedBox.shrink();

    final async = ref.watch(sleepStoryTodayProvider);
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (pick) => _card(context, c, pick),
    );
  }

  Widget _card(BuildContext context, ThemeColors c, SleepStoryApi pick) {
    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push(
            '/chat?source=sleep_story&pick=${Uri.encodeComponent(pick.slug)}');
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.cardBorder.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Text('🌌', style: TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    pick.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${pick.durationMin} min · sleep story',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.bedtime_outlined, color: c.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
