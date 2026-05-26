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
import '../../../data/providers/coach_card_visibility_provider.dart';
import '../../../data/providers/contextual_nudge_provider.dart';
import '../../../data/providers/daily_coach_insight_provider.dart';
import '../../../widgets/coach/coach_contextual_nudge_row.dart';
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
          Text(
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
        _CoachChromeIconButton(
          icon: Icons.close_rounded,
          tooltip: 'Dismiss for today',
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
}

/// Tier-2 nudge stack rendered inside [CoachHeroCard]. Shows up to 2 rows
/// by default; when there are 3+ eligible nudges a `+N more ⌄` chip
/// appears that AnimatedSize-expands the card to reveal the rest.
///
/// Expansion state is held in [nudgeStackExpandedProvider] (Riverpod) so
/// it survives tab-switch rebuilds — local State here would reset when
/// the home tab unmounts, which the user noticed as "tasks reset on
/// tab change".
class _CoachNudgeStack extends ConsumerWidget {
  const _CoachNudgeStack();

  static const int _kVisibleClamp = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);
    final nudges = ref.watch(contextualNudgeProvider);
    if (nudges.isEmpty) return const SizedBox.shrink();

    final expanded = ref.watch(nudgeStackExpandedProvider);
    final overflow = nudges.length > _kVisibleClamp;
    final visible = expanded || !overflow
        ? nudges
        : nudges.take(_kVisibleClamp).toList(growable: false);

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Divider(height: 1, color: c.cardBorder),
          const SizedBox(height: 10),
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            CoachContextualNudgeRow(
              key: ValueKey('nudge_${visible[i].id.name}'),
              nudge: visible[i],
              ctaColor: ctaColorForNudge(visible[i].id),
            ),
          ],
          if (overflow) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.center,
              child: TextButton.icon(
                onPressed: () => ref
                    .read(nudgeStackExpandedProvider.notifier)
                    .state = !expanded,
                icon: Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                ),
                label: Text(
                  expanded
                      ? 'Show less'
                      : '+${nudges.length - _kVisibleClamp} more',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: c.textMuted,
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  textStyle: const TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
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
