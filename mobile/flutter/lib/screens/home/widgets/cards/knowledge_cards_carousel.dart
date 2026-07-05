/// F3.59 — Knowledge cards carousel.
///
/// Horizontal scroller of 3 short evergreen learning cards (form tips,
/// nutrition primers, recovery basics). Tap routes to the discover screen
/// with the card id. Cards may be passed in (ranker-cached path) or
/// fetched from `GET /api/v1/discover/knowledge-cards` via
/// `knowledgeCardsProvider`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/content_catalogs_provider.dart';
import '../../../../data/services/haptic_service.dart';

class KnowledgeCard {
  final String id;
  final String emoji;
  final String title;
  final String tagline;

  const KnowledgeCard({
    required this.id,
    required this.emoji,
    required this.title,
    required this.tagline,
  });
}

class KnowledgeCardsCarousel extends ConsumerWidget {
  final bool show;
  // Optional ranker-supplied override. When null we fetch from the API.
  final List<KnowledgeCard>? cards;

  const KnowledgeCardsCarousel({
    super.key,
    this.show = true,
    this.cards,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!show) return const SizedBox.shrink();
    final c = ThemeColors.of(context);

    final injected = cards;
    if (injected != null) {
      if (injected.isEmpty) return const SizedBox.shrink();
      return _frame(c, injected);
    }

    final async = ref.watch(knowledgeCardsProvider);
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (rows) {
        if (rows.isEmpty) return const SizedBox.shrink();
        final mapped = rows
            .map((r) => KnowledgeCard(
                  id: r.slug,
                  emoji: r.emoji,
                  title: r.title,
                  tagline: r.tagline,
                ))
            .toList(growable: false);
        return _frame(c, mapped);
      },
    );
  }

  Widget _frame(ThemeColors c, List<KnowledgeCard> cards) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Learn',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                  letterSpacing: 0.3),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (ctx, i) {
                final card = cards[i];
                return _KnowledgeTile(card: card, c: c);
              },
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemCount: cards.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _KnowledgeTile extends StatelessWidget {
  final KnowledgeCard card;
  final ThemeColors c;
  const _KnowledgeTile({required this.card, required this.c});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        HapticService.light();
        context.push('/leaderboard?card=${card.id}');
      },
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(card.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            // Flexible so the title yields at large font scale rather than
            // forcing the Expanded tagline below into negative height.
            Flexible(
              child: Text(
                card.title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Text(
                card.tagline,
                style: TextStyle(
                    fontSize: 11.5,
                    color: c.textSecondary,
                    height: 1.3),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
