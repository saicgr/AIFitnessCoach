/// Coach Hero Card — promoted from the score-card footer (was a single line)
/// to a full hero card between the date strip and the Today Score card.
///
/// Backed by [dailyCoachInsightProvider] which calls the Gemini-backed
/// `/api/v1/coach/daily-insight` endpoint with a 24h Supabase cache. When the
/// server is unreachable, the provider falls back to the deterministic
/// `coachHeadline()` + `coachBody()` from `score_coach_line.dart` so the card
/// always renders something coherent.
///
/// Per plan §4:
///   * Whole-card tap → `/chat` with insight prefilled as latest coach turn.
///   * Long-press → "Regenerate" (calls the refresh family with ?refresh=true).
///   * Primary + secondary CTA routes come from the API payload.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../data/providers/daily_coach_insight_provider.dart';
import 'home/unified_home_widgets.dart' show kHomeHPad;

class CoachHeroCard extends ConsumerStatefulWidget {
  const CoachHeroCard({super.key});

  @override
  ConsumerState<CoachHeroCard> createState() => _CoachHeroCardState();
}

class _CoachHeroCardState extends ConsumerState<CoachHeroCard> {
  // Client-side rate-limit on long-press regenerate (≤ once per 30 min).
  DateTime? _lastRegenAt;
  bool _regenerating = false;

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final insightAsync = ref.watch(dailyCoachInsightProvider);

    return Padding(
      padding: kHomeHPad,
      child: GestureDetector(
        onTap: () => _openChat(context, insightAsync.valueOrNull),
        onLongPress: _onLongPressRegen,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.cardBorder),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                c.accent.withValues(alpha: 0.10),
                c.accent.withValues(alpha: 0.03),
              ],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          child: insightAsync.when(
            data: (insight) => _content(c, insight),
            loading: () => _skeleton(c),
            error: (_, __) => _errorPlaceholder(c),
          ),
        ),
      ),
    );
  }

  Widget _content(ThemeColors c, dynamic insightDynamic) {
    final insight = insightDynamic as DailyCoachInsight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _eyebrow(c, insight.isFallback),
        const SizedBox(height: 6),
        Text(
          insight.headline.isEmpty
              ? 'Your coach is here.'
              : insight.headline,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            height: 1.2,
            letterSpacing: -0.2,
            color: c.textPrimary,
          ),
        ),
        if (insight.body.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            insight.body,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.35,
              color: c.textSecondary,
            ),
          ),
        ],
        if (insight.ctaPrimary != null || insight.ctaSecondary != null) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (insight.ctaPrimary != null)
                _primaryCta(c, insight.ctaPrimary!),
              if (insight.ctaSecondary != null)
                _secondaryCta(c, insight.ctaSecondary!),
            ],
          ),
        ],
        if (_regenerating)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.6,
                    valueColor: AlwaysStoppedAnimation<Color>(c.accent),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Rethinking…',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: c.textMuted,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _eyebrow(ThemeColors c, bool _) {
    // OFFLINE chip removed — was a dev-debug indicator visible to end users.
    // The deterministic fallback should read as a normal coach voice; no need
    // to surface "the server is down" to the user.
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [c.accent, c.accent.withValues(alpha: 0.70)],
            ),
          ),
          child: const Icon(Icons.auto_awesome, size: 12, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Text(
          'YOUR COACH',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: c.accent,
          ),
        ),
      ],
    );
  }

  Widget _primaryCta(ThemeColors c, CoachCta cta) {
    return ElevatedButton(
      onPressed: () => _navigate(context, cta.route),
      style: ElevatedButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.accentContrast,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      child: Text(cta.label),
    );
  }

  Widget _secondaryCta(ThemeColors c, CoachCta cta) {
    return OutlinedButton(
      onPressed: () => _navigate(context, cta.route),
      style: OutlinedButton.styleFrom(
        foregroundColor: c.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        side: BorderSide(color: c.cardBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      child: Text(cta.label),
    );
  }

  Widget _skeleton(ThemeColors c) {
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: c.textMuted.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(6),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow(c, false),
        const SizedBox(height: 8),
        bar(220, 16),
        const SizedBox(height: 6),
        bar(double.infinity, 12),
        const SizedBox(height: 4),
        bar(180, 12),
      ],
    );
  }

  Widget _errorPlaceholder(ThemeColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow(c, true),
        const SizedBox(height: 6),
        Text(
          'Your coach is gathering thoughts.',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap to open chat.',
          style: TextStyle(fontSize: 12, color: c.textSecondary),
        ),
      ],
    );
  }

  void _navigate(BuildContext context, String route) {
    if (route.isEmpty) return;
    try {
      context.push(route);
    } catch (_) {
      // Route not registered — open chat as a safe fallback.
      _openChat(context, ref.read(dailyCoachInsightProvider).valueOrNull);
    }
  }

  void _openChat(BuildContext context, DailyCoachInsight? insight) {
    final headline = insight?.headline ?? '';
    final body = insight?.body ?? '';
    final encoded =
        Uri.encodeQueryComponent('${headline.trim()}\n${body.trim()}'.trim());
    final route = encoded.isEmpty
        ? '/chat?source=coach_hero'
        : '/chat?source=coach_hero&prefill=$encoded';
    try {
      context.push(route);
    } catch (_) {
      context.push('/chat');
    }
  }

  void _onLongPressRegen() {
    final now = DateTime.now();
    if (_lastRegenAt != null &&
        now.difference(_lastRegenAt!) < const Duration(minutes: 30)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 2),
          content: Text('Already refreshed in the last 30 minutes.'),
        ),
      );
      return;
    }
    setState(() {
      _regenerating = true;
      _lastRegenAt = now;
    });
    // Trigger a force-refresh by reading the family with today's date —
    // it bypasses the cache server-side via ?refresh=true.
    ref.read(dailyCoachInsightRefreshProvider(DateTime.now()).future).then(
      (_) {
        if (!mounted) return;
        // Invalidate the main provider so the visible card picks up the
        // freshly-cached insight.
        ref.invalidate(dailyCoachInsightProvider);
        setState(() => _regenerating = false);
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _regenerating = false);
      },
    );
  }
}
