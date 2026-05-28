/// F3.42 — Daily meditation tile. Rotating short guided session pulled from
/// `GET /api/v1/meditation/today` (server-curated DOY rotation). Routes to
/// chat with `source=meditation` until a dedicated player ships.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/content_catalogs_provider.dart';
import '../../../../data/services/haptic_service.dart';

class DailyMeditationTile extends ConsumerWidget {
  const DailyMeditationTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);
    final async = ref.watch(dailyMeditationProvider);
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (pick) => _card(context, c, pick),
    );
  }

  Widget _card(BuildContext context, ThemeColors c, MeditationPickApi pick) {
    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push(
            '/chat?source=meditation&pick=${Uri.encodeComponent(pick.slug)}');
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
                color: c.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Text('🧘', style: TextStyle(fontSize: 22)),
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
                    '${pick.durationMin} min · guided',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            _PlayPill(color: c.accent),
          ],
        ),
      ),
    );
  }
}

class _PlayPill extends StatelessWidget {
  final Color color;
  const _PlayPill({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
          SizedBox(width: 2),
          Text(
            'Play',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
