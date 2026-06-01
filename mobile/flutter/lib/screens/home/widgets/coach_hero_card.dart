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
import '../../../data/providers/ai_settings_provider.dart';
import '../../../data/providers/coach_card_visibility_provider.dart';
import '../../../data/providers/contextual_nudge_provider.dart';
import '../../../data/providers/daily_coach_insight_provider.dart';
import '../../../data/providers/sub_card_shown_today_provider.dart';
import '../../../widgets/coach/coach_contextual_nudge_row.dart';
import '../../../widgets/coach/sub_card_ranker.dart';
import '../../../widgets/glass_sheet.dart';
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

  // Visibility (expanded / minimized / dismissedToday) lives in
  // `coachCardVisibilityProvider` (Riverpod + SharedPreferences keyed by
  // local date). The notifier outlives this widget's State so the user's
  // explicit minimize / dismiss survives every tab switch + every cold
  // start within the same day.

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final visibility = ref.watch(coachCardVisibilityProvider);

    // Dismissed for today — collapse the card out of the home scroll
    // entirely. Returning SizedBox.shrink() over Padding() so the
    // surrounding kHomeGap spacers don't leave an orphan gap.
    if (visibility == CoachCardVisibility.dismissedToday) {
      return const SizedBox.shrink();
    }

    final insightAsync = ref.watch(dailyCoachInsightProvider);
    final isMinimized = visibility == CoachCardVisibility.minimized;

    return Padding(
      padding: kHomeHPad,
      child: GestureDetector(
        // Whole-card tap is suppressed while minimized — the only
        // interactive surface in that state is the chevron itself, so
        // tapping anywhere on the headline area shouldn't accidentally
        // open chat. Long-press regenerate also off in minimized mode.
        onTap: isMinimized
            ? null
            : () => _openChat(context, insightAsync.valueOrNull),
        onLongPress: isMinimized ? null : _onLongPressRegen,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.cardBorder),
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [
                c.accent.withValues(alpha: 0.10),
                c.accent.withValues(alpha: 0.03),
              ],
            ),
          ),
          padding: EdgeInsetsDirectional.fromSTEB(16, 14, 10, isMinimized ? 12 : 14),
          child: insightAsync.when(
            data: (insight) =>
                _content(c, insight, isMinimized: isMinimized),
            loading: () => _skeleton(c, isMinimized: isMinimized),
            error: (_, __) => _errorPlaceholder(c),
          ),
        ),
      ),
    );
  }

  Widget _content(
    ThemeColors c,
    dynamic insightDynamic, {
    required bool isMinimized,
  }) {
    final insight = insightDynamic as DailyCoachInsight;

    // When minimized, render only the eyebrow + headline so the card
    // shrinks to a compact summary row the user can re-expand via the
    // chevron. No body, no CTAs, no nudge stack.
    if (isMinimized) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _eyebrow(c, insight.isFallback, isMinimized: true),
          const SizedBox(height: 4),
          Text(
            insight.headline.isEmpty
                ? AppLocalizations.of(context).coachHeroCardYourCoachIsHere
                : insight.headline,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.15,
              color: c.textPrimary,
            ),
          ),
        ],
      );
    }

    // Expanded — full card. Body always renders bulleted when the server
    // returned multi-line text; otherwise as a 2-line summary. (The old
    // "auto-expand-in-morning-bucket" toggle was retired together with the
    // chevron's previous meaning; the chevron now controls minimize.)
    final bodyLines = _splitBodyLines(insight.body).take(5).toList();
    final hasBullets = bodyLines.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _eyebrow(c, insight.isFallback, isMinimized: false),
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
        if (hasBullets) ...[
          const SizedBox(height: 8),
          for (final line in bodyLines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _bodyLine(c, line),
            ),
        ] else if (insight.body.isNotEmpty) ...[
          const SizedBox(height: 4),
          // No maxLines / ellipsis — the Coach card is the headline surface
          // on Home; truncating the insight body to 2 lines made the daily
          // recommendation read as "Focus on hitting your 93.0g protein…"
          // which lost the actual recommendation. Server prompt already
          // bounds the body to ~3-5 sentences; let it wrap.
          Text(
            insight.body.replaceAll('\n', ' ').replaceAll('  ', ' '),
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
        // Tier 2 — stacked contextual nudges. Hidden in minimized mode
        // (the entire `_content` early-returns above when minimized).
        const _CoachNudgeStack(),
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
    bool isMinimized = false,
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
        // ⋮ — opens the coach options sheet (change persona / open AI
        // Settings / hide for today). Subtle, sits before the chevron so
        // the primary expand/minimize action keeps trailing emphasis.
        _CoachChromeIconButton(
          icon: Icons.more_vert,
          tooltip: 'Coach options',
          onTap: () => _showCoachOptionsSheet(context, ref),
        ),
        const SizedBox(width: 2),
        // Chevron — primary expand/minimize toggle, filled accent so the
        // common action reads as the affordance (NN/G "Dangerous UX"
        // inverted-emphasis: benign action gets the visual weight).
        _CoachChromeIconButton(
          icon: isMinimized ? Icons.expand_more : Icons.expand_less,
          tooltip: isMinimized ? 'Expand' : 'Minimize',
          emphasised: true,
          onTap: () => ref
              .read(coachCardVisibilityProvider.notifier)
              .toggleMinimized(),
        ),
        const SizedBox(width: 2),
        // X — destructive dismiss-for-today. Flat 14pt, no fill, muted
        // so a tap requires intent rather than reading like a primary
        // action sitting next to the chevron.
        // Dismisses the WHOLE coach card AND its entire nudge stack for the
        // day in one tap — the "dismiss all" affordance (issue 5). Tooltip
        // spells that out so users don't swipe each nudge individually.
        _CoachChromeIconButton(
          icon: Icons.close_rounded,
          tooltip: 'Hide coach + all nudges for today',
          onTap: () => ref
              .read(coachCardVisibilityProvider.notifier)
              .setDismissedToday(),
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
          padding: const EdgeInsetsDirectional.only(top: 6, end: 8, start: 2),
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

  Widget _skeleton(ThemeColors c, {bool isMinimized = false}) {
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: c.textMuted.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(6),
          ),
        );
    if (isMinimized) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _eyebrow(c, false, isMinimized: true),
          const SizedBox(height: 6),
          bar(220, 14),
        ],
      );
    }
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
        // Contextual nudges (morning hydration / breakfast / etc.) do NOT
        // depend on the daily coach insight — they read nutrition +
        // hydration + workout providers directly. Mounting the stack inside
        // the skeleton means sub-cards paint on the first frame after cold
        // start instead of waiting 1–3 s for the Gemini insight call.
        // Foreground-cycle workaround for the same bug is no longer needed.
        const _CoachNudgeStack(),
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
        // Same reasoning as the skeleton — nudges shouldn't disappear when
        // the Gemini insight fetch errors. Backend deterministic fallback
        // can populate the insight on its own retry; meanwhile the
        // user-actionable sub-cards stay visible.
        const _CoachNudgeStack(),
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

  // _CoachNudgeStack defined at file scope below.
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

  /// Bottom-sheet menu opened by the ⋮ button. Three actions:
  /// (1) open AI Settings, (2) change coach persona (deep-link into the
  /// persona section), (3) hide the card for the rest of today.
  void _showCoachOptionsSheet(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);
    showGlassSheet<void>(
      context: context,
      builder: (sheetCtx) {
        Widget row(IconData icon, String label, VoidCallback onTap) {
          return ListTile(
            leading: Icon(icon, size: 22, color: c.textPrimary),
            title: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            onTap: onTap,
          );
        }

        return GlassSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              row(Icons.tune, 'AI Settings', () {
                Navigator.of(sheetCtx).pop();
                context.push('/ai-settings');
              }),
              row(Icons.face_retouching_natural, 'Change coach personality',
                  () {
                Navigator.of(sheetCtx).pop();
                context.push('/ai-settings');
              }),
              row(Icons.visibility_off_outlined, 'Hide coach card today', () {
                Navigator.of(sheetCtx).pop();
                ref
                    .read(coachCardVisibilityProvider.notifier)
                    .setDismissedToday();
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

/// Tier-2 sub-card stack rendered inside [CoachHeroCard].
///
/// F4 layout: horizontal `PageView`, **2 sub-cards per page**, with dot
/// indicators below. Swipe to next pair. Capped at 8 eligible per day via
/// [SubCardRanker]; de-duplicated against the per-day `shownTodayDedupKeys`
/// set so a card the user has dismissed or acted on doesn't resurface
/// later the same day.
class _CoachNudgeStack extends ConsumerStatefulWidget {
  const _CoachNudgeStack();

  /// One page = up to this many stacked sub-cards.
  static const int _kCardsPerPage = 2;

  /// Approx height of ONE nudge row (emoji/2-line text + padding + border +
  /// CTA pill). Both title and body are single-line (ellipsis), so a row's
  /// height is deterministic; this is the per-row budget the PageView is sized
  /// from. Measured at ~68px on a 2-card page (the 58px first guess overflowed
  /// by 20px), so 74 leaves comfortable headroom while still cutting the dead
  /// space the old flat 184px left below short pages (issue 3).
  static const double _kRowHeight = 74;

  @override
  ConsumerState<_CoachNudgeStack> createState() => _CoachNudgeStackState();
}

class _CoachNudgeStackState extends ConsumerState<_CoachNudgeStack> {
  late final PageController _controller;
  int _activePage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (!_controller.hasClients || _controller.page == null) return;
    final p = _controller.page!.round();
    if (p != _activePage) setState(() => _activePage = p);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final raw = ref.watch(contextualNudgeProvider);
    if (raw.isEmpty) return const SizedBox.shrink();

    final settings = ref.watch(coachUiSettingsProvider);
    final shownToday = ref.watch(subCardShownTodayProvider);

    // #18: cap the home action cards to the top 4 (already priority-ranked) so
    // the stack never becomes an endless swipe of nudges.
    final ranked = rankWithCoachUiSettings(
      candidates: raw,
      settings: settings,
      shownTodayDedupKeys: shownToday,
    ).take(4).toList();
    if (ranked.isEmpty) return const SizedBox.shrink();

    final pageCount =
        (ranked.length / _CoachNudgeStack._kCardsPerPage).ceil();

    // The ranked list can shrink mid-view (a nudge is snoozed / hidden /
    // muted / expires). Clamp the active index for display, and if the
    // controller is now parked past the last page, snap it back next frame.
    final activeIndex = _activePage.clamp(0, pageCount - 1);
    if (_controller.hasClients &&
        (_controller.page ?? 0) > pageCount - 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) {
          _controller.jumpToPage(pageCount - 1);
        }
      });
    }

    // Size the PageView to the ACTIVE page's actual card count (1 or 2) rather
    // than a fixed 2-row budget, scaled with the user's text size. This kills
    // the dead space below a short page (issue 3) and resizes smoothly via the
    // AnimatedSize when a swipe lands on a page with a different card count.
    final cardsOnActivePage =
        (ranked.length - activeIndex * _CoachNudgeStack._kCardsPerPage)
            .clamp(1, _CoachNudgeStack._kCardsPerPage);
    final textScale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.6);
    final pageHeight = _CoachNudgeStack._kRowHeight * textScale * cardsOnActivePage +
        (cardsOnActivePage - 1) * 8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Divider(height: 1, color: c.cardBorder),
        const SizedBox(height: 10),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: SizedBox(
          height: pageHeight,
          child: PageView.builder(
            controller: _controller,
            itemCount: pageCount,
            physics: const PageScrollPhysics(),
            itemBuilder: (ctx, page) {
              final start = page * _CoachNudgeStack._kCardsPerPage;
              final end = (start + _CoachNudgeStack._kCardsPerPage)
                  .clamp(0, ranked.length);
              final slice = ranked.sublist(start, end);
              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  for (var i = 0; i < slice.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    CoachContextualNudgeRow(
                      key: ValueKey(
                          'nudge_${slice[i].effectiveDedupKey}'),
                      nudge: slice[i],
                      ctaColor: ctaColorForNudge(slice[i].id),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        ),
        if (pageCount > 1) ...[
          const SizedBox(height: 8),
          Semantics(
            label: 'Page ${activeIndex + 1} of $pageCount',
            child: _PageDots(
              pageCount: pageCount,
              activeIndex: activeIndex,
              color: c.textMuted,
              activeColor: c.accent,
            ),
          ),
        ],
      ],
    );
  }
}

/// Page-dot indicator that highlights the current page. The active dot is a
/// wider accent-coloured pill; inactive dots are small muted circles. The
/// parent drives [activeIndex] from its `PageController` listener.
class _PageDots extends StatelessWidget {
  final int pageCount;
  final int activeIndex;
  final Color color;
  final Color activeColor;
  const _PageDots({
    required this.pageCount,
    required this.activeIndex,
    required this.color,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < pageCount; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: i == activeIndex ? 16 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == activeIndex
                  ? activeColor
                  : color.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ],
    );
  }
}

/// Tiny icon button used in the coach card's eyebrow (chevron + X).
/// Centralised so both controls share the same tooltip + hit area
/// treatment. Set [emphasised] to render with a faint red-tinted circular
/// background — used for the X dismiss button so it reads as a distinct
/// destructive action rather than fading into another grey icon.
class _CoachChromeIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool emphasised;

  const _CoachChromeIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.emphasised = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    // Emphasised variant — filled accent circle. Used for the primary
    // chevron toggle so the common (benign) action reads as the
    // affordance. Per AccentColorScope: never hardcode a hue here, the
    // user's accent recolors this in step with the rest of the chrome.
    if (emphasised) {
      return Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.accent,
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: c.accentContrast,
                ),
              ),
            ),
          ),
        ),
      );
    }
    // Default variant — flat 14pt destructive/secondary icon, no fill.
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 18,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Icon(icon, size: 14, color: c.textMuted),
        ),
      ),
    );
  }
}
