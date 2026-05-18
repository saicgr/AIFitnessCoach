import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/providers/fasting_provider.dart';
import '../../../data/services/haptic_service.dart';

/// AI-generated fasting insight card (Section D).
///
/// Watches [fastingInsightProvider] — a Gemini-backed, server-cached analysis
/// of the user's fasting patterns. Renders:
///  - a shimmer skeleton while loading,
///  - a fade-in of the real insight on arrival,
///  - an error state with a retry affordance,
///  - an honest empty state when there is no fasting history yet.
class FastingAiInsightCard extends ConsumerWidget {
  const FastingAiInsightCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.colors(context);
    final insight = ref.watch(fastingInsightProvider);
    final fasting = ref.watch(fastingProvider);

    // Honest empty state: nothing to analyze before the first completed fast.
    final hasHistory = fasting.history.isNotEmpty || fasting.activeFast != null;
    if (!hasHistory) {
      return _InsightShell(
        colors: colors,
        child: _EmptyState(colors: colors),
      );
    }

    return insight.when(
      loading: () => _InsightShell(
        colors: colors,
        child: _ShimmerSkeleton(colors: colors),
      ),
      error: (err, _) => _InsightShell(
        colors: colors,
        child: _ErrorState(
          colors: colors,
          onRetry: () {
            HapticService.light();
            ref.invalidate(fastingInsightProvider);
          },
        ),
      ),
      data: (text) {
        if (text.trim().isEmpty) {
          return _InsightShell(
            colors: colors,
            child: _EmptyState(colors: colors),
          );
        }
        return _InsightShell(
          colors: colors,
          child: _LoadedState(colors: colors, text: text)
              .animate()
              .fadeIn(duration: 320.ms)
              .slideY(begin: 0.06, end: 0, duration: 320.ms),
        );
      },
    );
  }
}

/// Shared card chrome — gradient surface + "AI Insight" header.
class _InsightShell extends StatelessWidget {
  final ThemeColors colors;
  final Widget child;

  const _InsightShell({required this.colors, required this.child});

  @override
  Widget build(BuildContext context) {
    final accent = colors.accent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: colors.isDark ? 0.18 : 0.11),
            accent.withValues(alpha: colors.isDark ? 0.06 : 0.04),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(
                'AI Insight',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LoadedState extends StatelessWidget {
  final ThemeColors colors;
  final String text;

  const _LoadedState({required this.colors, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13.5,
        height: 1.5,
        color: colors.textSecondary,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ThemeColors colors;

  const _EmptyState({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.lightbulb_outline_rounded,
            size: 20, color: colors.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Complete a fast to unlock a personalized AI analysis of your '
            'fasting patterns.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: colors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final ThemeColors colors;
  final VoidCallback onRetry;

  const _ErrorState({required this.colors, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.cloud_off_rounded, size: 20, color: colors.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            "Couldn't load your insight. Check your connection.",
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: colors.textMuted,
            ),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onRetry,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Retry',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.accent,
            ),
          ),
        ),
      ],
    );
  }
}

/// Three shimmering placeholder lines while the insight loads.
class _ShimmerSkeleton extends StatelessWidget {
  final ThemeColors colors;

  const _ShimmerSkeleton({required this.colors});

  @override
  Widget build(BuildContext context) {
    final base = colors.textMuted.withValues(alpha: 0.18);
    Widget bar(double widthFactor) => FractionallySizedBox(
          widthFactor: widthFactor,
          child: Container(
            height: 12,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        bar(1.0),
        const SizedBox(height: 9),
        bar(0.92),
        const SizedBox(height: 9),
        bar(0.6),
      ],
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1100.ms,
          color: colors.accent.withValues(alpha: 0.25),
        );
  }
}
