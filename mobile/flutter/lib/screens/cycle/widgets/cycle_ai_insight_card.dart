/// Inline AI insight card for the Cycle screen (Phase F).
///
/// Fed by `GET /hormonal-health/ai-insight/{user_id}` via
/// [cycleAiInsightProvider]. Renders a one-paragraph proactive insight
/// generated from the user's own logged data with a "Tell me more" affordance
/// that expands into the full coach chat. Silently hides when no insight is
/// available so it never blocks the screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers/hormonal_health_provider.dart';
import '../cycle_chat.dart';

import '../../../l10n/generated/app_localizations.dart';
class CycleAiInsightCard extends ConsumerWidget {
  /// Pink feature accent.
  final Color accent;

  const CycleAiInsightCard({super.key, required this.accent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightAsync = ref.watch(cycleAiInsightProvider);

    return insightAsync.when(
      loading: () => const _InsightSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
      data: (insight) {
        if (insight == null) return const SizedBox.shrink();
        final text = (insight['insight'] ??
                insight['text'] ??
                insight['message'])
            ?.toString();
        if (text == null || text.trim().isEmpty) {
          return const SizedBox.shrink();
        }
        final title =
            (insight['title'] ?? 'From your coach').toString();
        return _InsightBody(
          title: title,
          text: text.trim(),
          accent: accent,
        ).animate().fadeIn(duration: 360.ms).slideY(
              begin: 0.06,
              end: 0,
              duration: 360.ms,
              curve: Curves.easeOutCubic,
            );
      },
    );
  }
}

class _InsightBody extends StatelessWidget {
  final String title;
  final String text;
  final Color accent;

  const _InsightBody({
    required this.title,
    required this.text,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: isDark ? 0.16 : 0.12),
            accent.withValues(alpha: isDark ? 0.06 : 0.04),
          ],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.auto_awesome_rounded,
                    size: 14, color: accent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: fg,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              color: fg.withValues(alpha: 0.78),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: GestureDetector(
              onTap: () => openCycleChat(
                context,
                cycleDatumSeed(text),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context).cycleAiInsightTellMeMore,
                    style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded,
                      size: 16, color: accent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightSkeleton extends StatelessWidget {
  const _InsightSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(16),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(duration: 700.ms)
        .then()
        .fade(begin: 1, end: 0.5, duration: 700.ms);
  }
}
