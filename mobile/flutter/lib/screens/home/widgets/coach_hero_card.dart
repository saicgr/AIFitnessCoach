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
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../data/providers/daily_coach_insight_provider.dart';
import 'home/unified_home_widgets.dart' show kHomeHPad;

import '../../../l10n/generated/app_localizations.dart';
class CoachHeroCard extends ConsumerStatefulWidget {
  const CoachHeroCard({super.key});

  @override
  ConsumerState<CoachHeroCard> createState() => _CoachHeroCardState();
}

class _CoachHeroCardState extends ConsumerState<CoachHeroCard> {
  // Client-side rate-limit on long-press regenerate (≤ once per 30 min).
  DateTime? _lastRegenAt;
  bool _regenerating = false;

  // ── Expand/collapse state (plan §1e) ──────────────────────────────
  // Auto-expanded during the morning bucket (5-10) and evening recap
  // (20-22); collapsed otherwise. Override per-day via the chevron, keyed
  // by `coach_hero_expanded_<localDate>` in SharedPreferences so a
  // chevron flip survives an app restart but rolls over at midnight.
  // Small-screen rule (height<700 || width<360): auto-rule is forced
  // collapsed even in morning/evening buckets — the user can still
  // manually expand. Decision is taken in build() because MediaQuery
  // isn't safe in initState.
  bool? _isExpandedToday;       // null = follow auto-rule.
  String? _hydratedForDate;     // local-date string the override was hydrated for.

  String _todayKey(DateTime now) =>
      'coach_hero_expanded_${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  Future<void> _hydrateExpansion(DateTime now) async {
    final key = _todayKey(now);
    if (_hydratedForDate == key) return;
    _hydratedForDate = key;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getBool(key);
      if (!mounted) return;
      setState(() {
        _isExpandedToday = stored; // null = no override, follow auto rule.
      });
    } catch (_) {
      // SharedPreferences failure is non-fatal — fall back to auto-rule.
      if (mounted) setState(() => _isExpandedToday = null);
    }
  }

  bool _autoExpanded(DateTime now, Size viewport) {
    // Small-screen override — never auto-expand on iPhone SE class screens.
    if (viewport.height < 700 || viewport.width < 360) return false;
    final h = now.hour;
    final morning = h >= 5 && h <= 10;
    final evening = h >= 20 && h <= 21;
    return morning || evening;
  }

  Future<void> _toggleExpanded(DateTime now) async {
    final viewport = MediaQuery.of(context).size;
    final autoExp = _autoExpanded(now, viewport);
    final currentVisible = _isExpandedToday ?? autoExp;
    final next = !currentVisible;
    setState(() => _isExpandedToday = next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_todayKey(now), next);
    } catch (_) {
      // Persist failure is non-fatal — the in-memory toggle still wins for
      // the session.
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final insightAsync = ref.watch(dailyCoachInsightProvider);
    final now = DateTime.now();
    final viewport = MediaQuery.of(context).size;

    // Hydrate the per-day expansion override on first paint (and after
    // midnight rollover). Cheap fire-and-forget — never blocks UI.
    if (_hydratedForDate != _todayKey(now)) {
      // ignore: discarded_futures
      _hydrateExpansion(now);
    }

    final autoExp = _autoExpanded(now, viewport);
    final isExpanded = _isExpandedToday ?? autoExp;

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
          // Slightly amplified top padding when expanded so the brief gets
          // breathing room without redesigning the collapsed footprint.
          padding: EdgeInsets.fromLTRB(16, isExpanded ? 18 : 14, 14, 14),
          child: insightAsync.when(
            data: (insight) =>
                _content(c, insight, isExpanded: isExpanded, now: now),
            loading: () => _skeleton(c),
            error: (_, __) => _errorPlaceholder(c),
          ),
        ),
      ),
    );
  }

  Widget _content(
    ThemeColors c,
    dynamic insightDynamic, {
    required bool isExpanded,
    required DateTime now,
  }) {
    final insight = insightDynamic as DailyCoachInsight;

    // Expanded body: split on \n into rows; rows beginning with "• " or
    // "- " render as bullet rows. Otherwise as paragraph lines. Cap at 5
    // rows to honour the size budget on small screens.
    final bodyLines = isExpanded
        ? _splitBodyLines(insight.body).take(5).toList()
        : const <String>[];

    // Action chips in expanded mode — primary + secondary + up to 2 extras.
    // We currently only have ctaPrimary + ctaSecondary on the payload;
    // additional chips arrive when Agent B wires the rich `chips` array
    // through `DailyCoachInsight`. Until then expanded reuses the two CTAs
    // we already have, which is a clean visual upgrade vs collapsed mode.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _eyebrow(c, insight.isFallback, isExpanded: isExpanded, now: now),
        const SizedBox(height: 6),
        Text(
          insight.headline.isEmpty
              ? AppLocalizations.of(context).coachHeroCardYourCoachIsHere
              : insight.headline,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            height: 1.2,
            letterSpacing: -0.2,
            color: c.textPrimary,
          ),
        ),
        if (isExpanded && bodyLines.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final line in bodyLines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _bodyLine(c, line),
            ),
        ] else if (insight.body.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            // Collapsed mode strips any embedded newlines so the same
            // server payload doesn't break the 2-line layout when the
            // user manually collapses an expanded brief.
            insight.body.replaceAll('\n', ' ').replaceAll('  ', ' '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.35,
              color: c.textSecondary,
            ),
          ),
        ],
        if (insight.ctaPrimary != null || insight.ctaSecondary != null) ...[
          SizedBox(height: isExpanded ? 14 : 12),
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
                  AppLocalizations.of(context).coachHeroCardRethinking,
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

  Widget _eyebrow(
    ThemeColors c,
    bool _, {
    bool isExpanded = false,
    DateTime? now,
  }) {
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
          AppLocalizations.of(context).coachHeroCardYourCoach,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: c.accent,
          ),
        ),
        const Spacer(),
        // Chevron — toggles per-day expansion override. Hit area enlarged
        // beyond the icon for fat-finger tapability without changing the
        // visual size of the chevron itself.
        if (now != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _toggleExpanded(now),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
                color: c.textMuted,
              ),
            ),
          ),
      ],
    );
  }

  /// Split a multi-line server-emitted body into rows. Server contract
  /// (plan §1e) — rows separated by `\n`; bullet rows start with "• " or
  /// "- ". Empty lines are dropped so layout doesn't double-space.
  List<String> _splitBodyLines(String body) {
    if (body.isEmpty) return const [];
    return body
        .split('\n')
        .map((l) => l.trimRight())
        .where((l) => l.trim().isNotEmpty)
        .toList();
  }

  Widget _bodyLine(ThemeColors c, String line) {
    final trimmed = line.trimLeft();
    final isBullet = trimmed.startsWith('• ') || trimmed.startsWith('- ');
    final text = isBullet ? trimmed.substring(2).trim() : trimmed;

    if (!isBullet) {
      return Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.4,
          color: c.textSecondary,
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6, right: 8, left: 2),
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: c.accent,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.4,
              color: c.textSecondary,
            ),
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
          AppLocalizations.of(context).coachHeroCardYourCoachIsGathering,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppLocalizations.of(context).coachHeroCardTapToOpenChat,
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
    // Plan §1c.5 — the card insight is the SAME content that should appear
    // as the first coach turn in chat (keyed by insight_id for dedup).
    // We no longer pass the headline+body as a `prefill` query string;
    // chat reads the insight via the daily_insight provider and seeds the
    // synthetic turn from there. Avoids "card said X, chat says Y" drift.
    final params = <String, String>{'source': 'coach_hero'};
    final id = insight?.insightId;
    if (id != null && id.isNotEmpty) params['insight_id'] = id;
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    final route = '/chat?$query';
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
        SnackBar(
          duration: Duration(seconds: 2),
          content: Text(AppLocalizations.of(context).coachHeroCardAlreadyRefreshedInThe),
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
