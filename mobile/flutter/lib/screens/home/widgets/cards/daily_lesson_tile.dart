/// F3.60 — Daily lesson tile (long-form variant of the daily-lesson nudge).
///
/// Rendered as a sub-card in the PageView for users who prefer a richer
/// preview vs the in-coach nudge row. Self-collapses when [show] is false.
///
/// Wired to `GET /api/v1/discover/daily-lesson` via
/// `dailyLessonProvider`. If the ranker supplies content through the
/// constructor (title + preview), that wins and the provider isn't read —
/// useful for the cached ranker payload path. Otherwise the tile fetches
/// today's lesson directly.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/content_catalogs_provider.dart';
import '../../../../data/services/haptic_service.dart';

class DailyLessonTile extends ConsumerWidget {
  final bool show;
  // Optional ranker-supplied overrides. When [title] and [preview] are both
  // non-null the tile renders them directly; otherwise it reads the backend.
  final String? title;
  final String? readMinutes;
  final String? preview;

  const DailyLessonTile({
    super.key,
    this.show = true,
    this.title,
    this.readMinutes,
    this.preview,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!show) return const SizedBox.shrink();
    final c = ThemeColors.of(context);

    final t = title;
    final p = preview;
    if (t != null && p != null) {
      return _card(context, c, title: t, readMinutes: readMinutes ?? '', preview: p);
    }

    final async = ref.watch(dailyLessonProvider);
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (lesson) => _card(
        context,
        c,
        title: lesson.title,
        readMinutes: lesson.readMinutesLabel,
        preview: lesson.preview,
      ),
    );
  }

  Widget _card(
    BuildContext context,
    ThemeColors c, {
    required String title,
    required String readMinutes,
    required String preview,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticService.light();
          context.push('/leaderboard?source=daily_lesson');
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('📖', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    'TODAY\'S LESSON',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: c.textMuted,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    readMinutes,
                    style: TextStyle(fontSize: 11, color: c.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                    height: 1.25),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                preview,
                style: TextStyle(
                    fontSize: 12,
                    color: c.textSecondary,
                    height: 1.35),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
