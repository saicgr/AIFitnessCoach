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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter/rendering.dart' show RenderProxyBox;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../core/theme/app_typography.dart';
import '../../../widgets/design_system/zealova_stat_tile.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/services/api_client.dart';
import '../../../data/providers/sleep_score_provider.dart';
import '../../../data/providers/nutrition_preferences_provider.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../data/repositories/hydration_repository.dart';
import '../../nutrition/log_meal_sheet.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/providers/ai_settings_provider.dart';
import '../../../data/providers/coach_card_visibility_provider.dart';
import '../../../data/providers/contextual_nudge_provider.dart';
import '../../../data/providers/daily_coach_insight_provider.dart';
import '../../../data/providers/sub_card_shown_today_provider.dart';
import '../../../data/services/health_service.dart' show healthSyncProvider;
import '../../../widgets/coach/coach_contextual_nudge_row.dart';
import '../../../widgets/coach/sub_card_ranker.dart';
import '../../../core/widgets/skeleton/skeleton_box.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/health_connect_sheet.dart';
import '../../chat/widgets/generic_blocks_renderer.dart';
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

  // Inline "Show more / Show less" state for the message body. Collapsed by
  // default so the action items below sit at first glance.
  bool _bodyExpanded = false;

  // Which to-do row is expanded (tap a task to reveal its detail + action,
  // the way the previous coach tasks opened up). null = all collapsed.

  // Trend graphs are collapsed by default (the user found the always-on chart
  // made the card too tall) — tap the "TRENDS" header to reveal the carousel.
  bool _graphsExpanded = false;

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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              Container(
          // Signature hero surface — matte fill + a 3px accent left edge,
          // painted as a clipped overlay (below) so we never combine a
          // borderRadius with a NON-uniform border (Flutter crashes on that —
          // this was the blank-Home fatal).
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.cardBorder),
          ),
          padding: EdgeInsetsDirectional.fromSTEB(16, 10, 10, isMinimized ? 12 : 14),
          // Render the previous insight in place during a SILENT refresh.
          // Riverpod keeps the last `AsyncData` value through `AsyncLoading`
          // (auto refresh) and `AsyncError` (failed refresh), so an auto-update
          // never flashes the skeleton or blanks the card — it swaps the new
          // headline/body/graphs in once they land, and keeps the last-good
          // insight if the refresh fails. The skeleton shows only on the very
          // first cold load (no value yet); the error placeholder only when the
          // first load failed AND produced no value (rare — the provider falls
          // back to a deterministic insight).
          child: Builder(
            builder: (_) {
              final insight = insightAsync.valueOrNull;
              if (insight != null) {
                return _content(c, insight, isMinimized: isMinimized);
              }
              if (insightAsync.hasError) return _errorPlaceholder(c);
              return _skeleton(c, isMinimized: isMinimized);
            },
          ),
              ),
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 3, color: c.accent),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The single-paragraph message body, collapsed to 3 lines with an inline
  /// "Show more" / "Show less" toggle. The toggle only appears when the text
  /// actually exceeds 3 lines (measured), so short tips show no link. The full
  /// tip is always reachable inline — nothing is truncated away.
  /// A 2-cell stat band — "Protein left" / "Calories left" — promoting the
  /// values that were previously buried inside the to-do detail text into a
  /// glanceable row. Reads the SAME nutrition providers the to-do section uses
  /// (no new data path): protein left = currentProteinTarget − eatenProtein,
  /// calories left = currentCalorieTarget − eatenCal, both 0-floor clamped.
  /// Built from [ZealovaStatTile] + [ZType] + [ThemeColors] so it inherits the
  /// signature-v2 typography rather than inventing a bespoke surface. Hidden
  /// when no calorie target exists yet (e.g. a fresh install pre-onboarding).
  Widget _statBand(ThemeColors c) {
    final prefs = ref.watch(nutritionPreferencesProvider);
    final nut = ref.watch(dailyNutritionProvider(todayNutritionKey()));
    final calTarget = prefs.currentCalorieTarget;
    final pTarget = prefs.currentProteinTarget;
    if (calTarget <= 0) return const SizedBox.shrink();

    final eatenCal = (nut.summary?.totalCalories ?? 0).round();
    final eatenP = (nut.summary?.totalProteinG ?? 0).round();
    final calLeft = (calTarget - eatenCal).clamp(0, calTarget);
    final pLeft = pTarget > 0 ? (pTarget - eatenP).clamp(0, pTarget) : 0;
    final nf = NumberFormat.decimalPattern();

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: c.glassSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.cardBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: ZealovaStatTile(
                value: pTarget > 0 ? '$pLeft' : '—',
                unit: pTarget > 0 ? 'g' : null,
                label: 'Protein left',
                valueSize: 24,
                accentValue: true,
              ),
            ),
            Container(width: 1, height: 30, color: c.cardBorder),
            const SizedBox(width: 14),
            Expanded(
              child: ZealovaStatTile(
                value: nf.format(calLeft),
                unit: 'kcal',
                label: 'Calories left',
                valueSize: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The "TO DO TODAY" checklist — the day's coach tasks, each wired to real
  /// provider data (protein intake vs target, today's workout completion, last
  /// night's sleep). Self-hides if there's nothing actionable to show.
  Widget _todoSection(ThemeColors c) {
    final tasks = <_TodoTask>[];

    // 1) Protein target progress (nutrition) → tap opens the log-meal sheet,
    //    the same surface the "Fuel before you train" nudge used.
    final prefs = ref.watch(nutritionPreferencesProvider);
    final nut = ref.watch(dailyNutritionProvider(todayNutritionKey()));
    final pTarget = prefs.currentProteinTarget;
    final pCur = (nut.summary?.totalProteinG ?? 0).round();
    if (pTarget > 0) {
      final remaining = (pTarget - pCur).clamp(0, pTarget);
      tasks.add(_TodoTask(
        icon: Icons.restaurant_rounded,
        done: pCur >= pTarget,
        label: 'Hit ${pTarget}g protein',
        trailing: '$pCur / $pTarget',
        detail: pCur >= pTarget
            ? "Target met — nice. Anything else you log still counts."
            : "${remaining}g to go. Log a high-protein meal or snack to close the gap.",
        actionLabel: 'Log a meal',
        onTap: () => showLogMealSheet(context, ref),
      ));
    }

    // 2) Today's workout (start/open it) → push the active workout screen,
    //    reusing the `todayWorkoutProvider` value read here.
    final tw = ref.watch(todayWorkoutProvider).valueOrNull?.todayWorkout;
    final twName = tw?.name ?? '';
    if (twName.isNotEmpty && twName != 'Generating...') {
      final done = tw?.isCompleted == true;
      final exCount = tw?.exerciseCount ?? 0;
      tasks.add(_TodoTask(
        icon: Icons.fitness_center_rounded,
        done: done,
        label: twName,
        trailing: done ? 'done' : '$exCount ex',
        detail: done
            ? "Logged — recovery starts now. Hydrate and refuel."
            : "$exCount exercises queued for today. Start when you're ready.",
        actionLabel: done ? 'View workout' : 'Start workout',
        onTap: () {
          if (tw != null) {
            context.push('/workout/${tw.id}', extra: tw);
          } else {
            context.go('/workouts');
          }
        },
      ));
    }

    // 3) Hydration (log a drink) → jump to the Nutrition water card.
    final water = ref.watch(hydrationProvider).todaySummary;
    final waterMl = water?.totalMl ?? 0;
    tasks.add(_TodoTask(
      icon: Icons.local_drink_rounded,
      done: waterMl >= 2000,
      label: 'Stay hydrated',
      trailing: '${(waterMl / 1000).toStringAsFixed(1)}L',
      detail: waterMl >= 2000
          ? "You're well hydrated today. Keep sipping."
          : "${(waterMl / 1000).toStringAsFixed(1)}L logged so far — top up toward ~2L.",
      actionLabel: 'Log water',
      onTap: () => context.go('/nutrition?fuelSection=water'),
    ));

    // 4) Last night's sleep (log it) → open the sleep detail screen.
    final sleep = ref.watch(sleepScoreProvider).valueOrNull;
    final logged = sleep?.hasData ?? false;
    final mins = sleep?.summary.totalMinutes ?? 0;
    tasks.add(_TodoTask(
      icon: Icons.bedtime_rounded,
      done: logged,
      label: "Log last night's sleep",
      trailing: logged ? '${mins ~/ 60}h ${mins % 60}m' : 'tonight',
      detail: logged
          ? "${mins ~/ 60}h ${mins % 60}m recorded. Your recovery score uses this."
          : "Add last night's sleep so your readiness + recovery stay accurate.",
      actionLabel: 'Log sleep',
      onTap: () => context.push('/health/sleep'),
    ));

    if (tasks.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 13),
        Text('TO DO TODAY',
            style: ZType.lbl(10.5, color: c.textMuted, letterSpacing: 2)),
        const SizedBox(height: 8),
        // Same swipeable, adaptive-height carousel as the coach action cards
        // above (2 cards per page, page dots, height fits the active page).
        _TodoCarousel(tasks: tasks),
      ],
    );
  }


  /// Collapsible "TRENDS" section wrapping the grounded-graph carousel.
  /// Collapsed by default; the header toggles the reveal.
  Widget _graphsSection(ThemeColors c, List<Map<String, dynamic>> blocks) {
    final n = blocks.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _graphsExpanded = !_graphsExpanded),
          child: Row(
            children: [
              Text('TRENDS',
                  style: ZType.lbl(10.5, color: c.textMuted, letterSpacing: 2)),
              const SizedBox(width: 6),
              Text('· $n ${n == 1 ? "chart" : "charts"}',
                  style: ZType.lbl(10, color: c.textMuted)),
              const Spacer(),
              AnimatedRotation(
                turns: _graphsExpanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 180),
                child:
                    Icon(Icons.expand_more, size: 18, color: c.textMuted),
              ),
            ],
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _BlocksCarousel(blocks: blocks),
          ),
          crossFadeState: _graphsExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _expandableBody(ThemeColors c, String text) {
    final style = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 1.35,
      color: c.textSecondary,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final tp = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 3,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = tp.didExceedMaxLines;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: style,
              maxLines: _bodyExpanded ? null : 3,
              overflow:
                  _bodyExpanded ? TextOverflow.clip : TextOverflow.ellipsis,
            ),
            if (overflows) ...[
              const SizedBox(height: 2),
              // Inner tap target wins the gesture arena, so toggling does not
              // also fire the whole-card open-chat tap.
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _bodyExpanded = !_bodyExpanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    _bodyExpanded ? 'Show less' : 'Show more',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: c.accent,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _content(
    ThemeColors c,
    dynamic insightDynamic, {
    required bool isMinimized,
  }) {
    final insight = insightDynamic as DailyCoachInsight;

    // When minimized, render the eyebrow + headline + a one-line preview of
    // the insight body so the collapsed card still carries the actual
    // recommendation (not just a bare headline). Re-expand via the chevron for
    // the full body, CTAs, and nudge stack.
    if (isMinimized) {
      final preview = insight.body.replaceAll('\n', ' ').replaceAll('  ', ' ').trim();
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
          if (preview.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              preview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.25,
                color: c.textSecondary,
              ),
            ),
          ],
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
          // The coach message reads as plain text (spec), not the italic serif
          // — Fraunces is reserved for the masthead greeting only.
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            height: 1.3,
            letterSpacing: -0.1,
            color: c.textPrimary,
          ),
        ),
        // Proactive "Coach noticed" card (Dr-Yaad audit #2) — a concrete
        // injury-aware observation + the adjustment the engine made, with an
        // Accept action. Self-hides when the backend surfaced nothing.
        if (insight.coachNoticed != null) ...[
          const SizedBox(height: 10),
          _coachNoticedBanner(c, insight, insight.coachNoticed!),
        ],
        if (hasBullets) ...[
          const SizedBox(height: 8),
          for (final line in bodyLines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _bodyLine(c, line),
            ),
        ] else if (insight.body.isNotEmpty) ...[
          const SizedBox(height: 4),
          // Collapsed to 3 lines by default with an inline Show more / Show less
          // so the CTAs + nudge chips below sit at first glance, while the FULL
          // tip is one tap away inline (no truncation/loss). The toggle only
          // appears when the body actually exceeds 3 lines.
          _expandableBody(
            c, insight.body.replaceAll('\n', ' ').replaceAll('  ', ' '),
          ),
        ],
        // Stat band — promotes the buried "left" values (protein + calories
        // remaining) into a glanceable 2-cell row above the to-dos. Built from
        // the signature-v2 ZealovaStatTile so it conforms to the design system
        // (Anton numeral + Barlow label), sourced from the same nutrition
        // providers the to-do section reads. Self-hides when no calorie target
        // is configured (fresh install before onboarding sets one).
        _statBand(c),
        // TO DO TODAY — the day's coach tasks (protein / workout / sleep),
        // each wired to real data with live progress + a checkbox (spec).
        _todoSection(c),
        // Up to 3 compact grounded graphs — COLLAPSED by default behind a
        // "TRENDS" header (the user found the always-on chart made the card too
        // tall). Tap to reveal the swipeable carousel. Only topics the user has
        // data for appear (the server never fabricates).
        if (insight.blocks.isNotEmpty)
          _graphsSection(c, insight.blocks.take(3).toList()),
        // Spec footer: a hairline rule, then "Adjust today" (muted) · "Ask
        // coach ›" (accent) — replaces the Log/View CTA buttons.
        const SizedBox(height: 13),
        Container(height: 1, color: c.cardBorder),
        const SizedBox(height: 11),
        Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _openChat(context, insight),
              child: Text('ADJUST TODAY',
                  style: ZType.lbl(11, color: c.textMuted, letterSpacing: 1.5)),
            ),
            const Spacer(),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _openChat(context, insight),
              child: Text('ASK COACH ›',
                  style: ZType.lbl(11, color: c.accent, letterSpacing: 1.5)),
            ),
          ],
        ),
        // (Tier-2 stacked contextual nudges removed from the expanded card —
        // the day's actions now live in the tappable TO DO TODAY carousel
        // above. `_CoachNudgeStack` is still mounted in the skeleton/error
        // pre-load states so first-frame nudges aren't lost.)
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
    //
    // SIGNATURE V2 `.chd` header — a framed ✦ avatar, then "COACH" in Barlow
    // with a muted "· TODAY'S FOCUS" qualifier, then the existing chrome
    // controls. The avatar + qualifier give the card the coach-as-author
    // identity from the v2 mockup.
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.elevated,
            border: Border.all(color: c.cardBorder),
          ),
          child: Icon(Icons.auto_awesome, size: 11, color: c.accent),
        ),
        const SizedBox(width: 8),
        Text(
          AppLocalizations.of(context).coachHeroCardYourCoach.toUpperCase(),
          style: ZType.lbl(11, color: c.textPrimary, letterSpacing: 1.8),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '· TODAY’S FOCUS',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ZType.lbl(10, color: c.textMuted, letterSpacing: 1.4),
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

  Widget _skeleton(ThemeColors c, {bool isMinimized = false}) {
    // Branded "coach is thinking" state — shown ONLY on a genuine cold load
    // (no disk-cached insight yet, e.g. the first sign-in of a fresh account
    // where the server is still generating the briefing). The previous loading
    // state was a bare shimmer skeleton, which read as a stuck/empty card
    // rather than "your coach is preparing". This keeps the REAL eyebrow header
    // (instant) and below it a pulsing ✦ + a rotating status line + one soft
    // shimmer bar, so it unmistakably reads as deliberate, branded loading.
    // The disk cache (see dailyCoachInsightProvider) usually paints the last
    // briefing instantly, so this is only ever seen on a true first cold load.
    return _CoachThinkingCard(
      header: _eyebrow(c, false, isMinimized: isMinimized),
      isMinimized: isMinimized,
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

  /// Proactive "Coach noticed" banner (Dr-Yaad audit #2). The Accept button
  /// is a surface-half stub today — it opens chat seeded with the coach's
  /// concrete proposal; Phase 2 (#2 apply-action) swaps it for a live
  /// pre-session reshape via the `action` field.
  Widget _coachNoticedBanner(
    ThemeColors c,
    DailyCoachInsight insight,
    CoachNoticed cn,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: c.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.accent.withOpacity(0.30), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 15, color: c.accent),
              const SizedBox(width: 6),
              Text(
                cn.title.toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: c.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            cn.body,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  // #2 apply-action: reshape today's session for the flagged
                  // body part via the reshape endpoint. Falls back to chat when
                  // there's no today workout to adjust.
                  if (cn.action == 'adjust_today_workout' &&
                      cn.bodyPart != null) {
                    _applyCoachAdjustment(cn, insight);
                  } else {
                    _openChat(context, insight);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: c.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    cn.acceptLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: c.accentContrast,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _openChat(context, insight),
                child: Text(
                  cn.dismissLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.textMuted,
                  ),
                ),
              ),
            ],
          ),
          // Trust framing (Dr-Yaad audit #12) — the engine drafts, you decide.
          const SizedBox(height: 8),
          Text(
            'The engine drafts the change — nothing happens until you accept.',
            style: TextStyle(
              fontSize: 10.5,
              fontStyle: FontStyle.italic,
              color: c.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  /// #2 apply-action — the user tapped Accept on the "Coach noticed" card. Pull
  /// today's workout and reshape it for the flagged body part via the reshape
  /// endpoint (apply=true), then surface the concrete change. Falls back to
  /// chat when there's no today workout to adjust.
  Future<void> _applyCoachAdjustment(
    CoachNoticed cn,
    DailyCoachInsight? insight,
  ) async {
    final today = ref.read(todayWorkoutProvider).valueOrNull?.todayWorkout;
    final wid = today?.id;
    if (wid == null || wid.isEmpty || cn.bodyPart == null) {
      _openChat(context, insight);
      return;
    }
    HapticFeedback.mediumImpact();
    try {
      final client = ref.read(apiClientProvider);
      final resp = await client.post(
        '/workouts/$wid/reshape-for-readiness',
        // pain_level 5 ≥ the 4/10 swap threshold so aggravators get swapped.
        data: {'pain_part': cn.bodyPart, 'pain_level': 5, 'apply': true},
      );
      final data = Map<String, dynamic>.from(resp.data as Map);
      final reshaped = data['reshaped'] == true;
      final reasons = (data['reasons'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList();
      if (!mounted) return;
      // Refresh today's workout so the swap shows immediately.
      ref.read(todayWorkoutProvider.notifier).refresh();
      final bp = cn.bodyPart!.replaceAll('_', ' ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.green,
          duration: const Duration(seconds: 4),
          content: Text(
            reshaped && reasons.isNotEmpty
                ? reasons.first
                : "Today's session already protects your $bp.",
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _openChat(context, insight);
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
    // Guard against a second trigger while one is already in flight — the
    // refresh now has two entry points (long-press AND the ⋮ menu), so they
    // must not stack concurrent force-refreshes.
    if (_regenerating) return;
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
        // Surface the failure instead of failing silently — the card keeps
        // showing the prior insight, so this degrades gracefully.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 2),
            content: Text("Couldn't refresh, try again"),
          ),
        );
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
              row(Icons.refresh, 'Refresh insight', () {
                Navigator.of(sheetCtx).pop();
                _onLongPressRegen();
              }),
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

/// One actionable task in the "TO DO TODAY" carousel. Pure data — the
/// [onTap] closure carries the real navigation/sheet action so the card
/// widget stays dumb.
class _TodoTask {
  final IconData icon;
  final bool done;
  final String label;
  final String trailing;
  final String detail;
  final String actionLabel;
  final VoidCallback onTap;

  const _TodoTask({
    required this.icon,
    required this.done,
    required this.label,
    required this.trailing,
    required this.detail,
    required this.actionLabel,
    required this.onTap,
  });
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
              // The PageView gives every page the ACTIVE page's height. When the
              // active page holds fewer cards than a neighbour (e.g. a 1-card
              // tail page next to a full 2-card page), the taller neighbour
              // would overflow the shorter viewport. A non-scrolling
              // SingleChildScrollView (the remedy the overflow error itself
              // suggests) lets the off-screen neighbour clip silently instead of
              // throwing — the active page is always sized to fit, so it never
              // clips. mainAxisSize.min is required inside the unbounded scroll.
              return SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                ),
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

/// "TO DO TODAY" carousel — same swipeable, adaptive-height format as the
/// coach action cards above: up to 2 task cards per page, page dots, and a
/// height that fits the active page's card count (no dead space on a short
/// last page). Mirrors [_CoachNudgeStack].
class _TodoCarousel extends StatefulWidget {
  final List<_TodoTask> tasks;
  const _TodoCarousel({required this.tasks});

  static const int _kCardsPerPage = 2;
  // Per-card budget the PageView viewport is sized from. A _TodoCard is a
  // single icon-tile row with two 1-line texts (label + detail) and 10px
  // vertical padding + border — it measures ~58px, so the old 80 left ~22px of
  // dead space PER CARD below the stack (the visible gap under the tasks). 62
  // tracks the real height with a few px of headroom; the non-scrolling
  // SingleChildScrollView in the page builder absorbs any sub-pixel overshoot.
  static const double _kRowHeight = 62;

  @override
  State<_TodoCarousel> createState() => _TodoCarouselState();
}

class _TodoCarouselState extends State<_TodoCarousel> {
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
    final tasks = widget.tasks;
    if (tasks.isEmpty) return const SizedBox.shrink();

    final pageCount = (tasks.length / _TodoCarousel._kCardsPerPage).ceil();
    final activeIndex = _activePage.clamp(0, pageCount - 1);

    final cardsOnActivePage =
        (tasks.length - activeIndex * _TodoCarousel._kCardsPerPage)
            .clamp(1, _TodoCarousel._kCardsPerPage);
    final textScale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.6);
    final pageHeight =
        _TodoCarousel._kRowHeight * textScale * cardsOnActivePage +
            (cardsOnActivePage - 1) * 8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                final start = page * _TodoCarousel._kCardsPerPage;
                final end = (start + _TodoCarousel._kCardsPerPage)
                    .clamp(0, tasks.length);
                final slice = tasks.sublist(start, end);
                // See _CoachNudgeStack: the non-scrolling SingleChildScrollView
                // lets a taller off-screen page clip silently rather than
                // overflow the active page's (shorter) viewport.
                return SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      for (var i = 0; i < slice.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        _TodoCard(task: slice[i]),
                      ],
                    ],
                  ),
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

/// A single TO-DO card matching the signature-v2 checklist row (proof line
/// 537): a leading CHECKBOX (empty rounded square / filled accent ✓ when the
/// target is met), the task label + detail line (struck through when done),
/// and a trailing CTA pill (or the progress value once done).
///
/// Interactions (A2 — user chose "checkbox + open detail sheet"):
///   * Tapping the row BODY opens a task-detail [GlassSheet] (title, fuller
///     why, live progress, and a button that fires the deep-link action).
///   * The trailing CTA pill fires the quick action directly (unchanged).
///   * The checkbox toggles done for user-completable tasks (`onToggle` set);
///     for derived-progress tasks it is a read-only indicator that fills when
///     the target is met.
class _TodoCard extends StatelessWidget {
  final _TodoTask task;
  const _TodoCard({required this.task});

  /// Leading checkbox (signature-v2 proof line 537) — an empty rounded square
  /// when the target isn't met, a filled accent square with a ✓ when it is.
  /// The current coach tasks (protein / water / workout / sleep) are all
  /// DERIVED-progress, so this is a read-only indicator that fills when the
  /// target is met (per A2); user-completable tasks would make it interactive.
  Widget _checkbox(ThemeColors c) {
    final done = task.done;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: done ? c.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: done ? c.accent : c.textMuted.withValues(alpha: 0.55),
          width: 1.6,
        ),
      ),
      child: done
          ? Icon(Icons.check_rounded, size: 15, color: c.accentContrast)
          : null,
    );
  }

  void _openDetailSheet(BuildContext context) {
    final c = ThemeColors.of(context);
    showGlassSheet<void>(
      context: context,
      builder: (sheetCtx) => GlassSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: task.done
                        ? AppColors.green.withValues(alpha: 0.16)
                        : c.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(task.icon,
                      size: 20,
                      color: task.done ? AppColors.green : c.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.label,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                Text(task.trailing,
                    style: ZType.data(13, color: c.textMuted)),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              task.detail,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  task.onTap();
                },
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: c.accent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    task.actionLabel.toUpperCase(),
                    style: ZType.lbl(13,
                        color: c.accentContrast, letterSpacing: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final done = task.done;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // Row body opens the detail sheet (A2); the trailing CTA pill below
      // wins the gesture arena for the direct action.
      onTap: () => _openDetailSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.glassSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.cardBorder),
        ),
        child: Row(
          children: [
            _checkbox(c),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    task.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: done ? c.textMuted : c.textPrimary,
                      decoration: done ? TextDecoration.lineThrough : null,
                      decorationColor: c.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    task.detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.2,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (!done)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: task.onTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: c.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: c.accent.withValues(alpha: 0.34)),
                  ),
                  child: Text(
                    task.actionLabel,
                    style: ZType.lbl(11, color: c.accent, letterSpacing: 0.5),
                  ),
                ),
              )
            else
              Text(task.trailing, style: ZType.data(11, color: c.textMuted)),
          ],
        ),
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

/// Swipeable carousel of the coach card's grounded graphs — one visible at a
/// time with page dots. When health is NOT connected the user only has one real
/// graph (nutrition), so we append "connect" prompt pages for the health topics
/// they're missing (Sleep / Steps / Recovery) — the carousel is then always
/// multi-page, shows what connecting unlocks, and drives the connection. Once
/// data exists the backend sends real graphs and the prompts drop off.
class _BlocksCarousel extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> blocks;
  const _BlocksCarousel({required this.blocks});

  @override
  ConsumerState<_BlocksCarousel> createState() => _BlocksCarouselState();
}

class _BlocksCarouselState extends ConsumerState<_BlocksCarousel> {
  // Floor height — fits the typical compact chart (~96 chart + title + padding)
  // and gives every page a consistent minimum. Pages that render TALLER (a
  // server-sent `metric` / `stat_grid` block ignores `compact`, or a chart with
  // a 2-line title) grow the viewport via measurement below instead of
  // overflowing the old hard-capped box (the 49px RenderFlex overflow).
  static const double _kHeight = 134;
  // Hard cap so the carousel can't sprawl (real graphs + prompts).
  static const int _kMaxPages = 4;
  final PageController _controller = PageController();
  int _page = 0;

  // Measured natural height per page index. The viewport sizes to the ACTIVE
  // page's measured height (floored at [_kHeight]) so no block is ever clipped,
  // while short pages don't leave dead space.
  final Map<int, double> _pageHeights = {};

  double _viewportHeight(int pageCount) {
    final active = _page.clamp(0, pageCount - 1);
    final measured = _pageHeights[active];
    if (measured == null || measured < _kHeight) return _kHeight;
    return measured;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final connected = ref.watch(healthSyncProvider).isConnected;

    // Real graph pages (one per backend block).
    final pages = <Widget>[
      for (final b in widget.blocks)
        Align(
          alignment: Alignment.topCenter,
          child: GenericBlocksRenderer(blocks: [b], compact: true),
        ),
    ];

    // When health isn't connected there are no sleep/steps/recovery graphs to
    // show — append a prompt page per missing topic so the carousel is useful.
    if (!connected) {
      for (final t in const [
        ('🌙', 'Sleep trend'),
        ('👟', 'Steps trend'),
        ('❤️', 'Recovery'),
      ]) {
        if (pages.length >= _kMaxPages) break;
        pages.add(_connectPromptPage(c, t.$1, t.$2));
      }
    }

    if (pages.length <= 1) {
      // Single real graph, nothing to swipe — render it inline (no dots).
      return widget.blocks.isEmpty
          ? const SizedBox.shrink()
          : GenericBlocksRenderer(blocks: widget.blocks, compact: true);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: SizedBox(
            height: _viewportHeight(pages.length),
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (i) => setState(() => _page = i),
              itemCount: pages.length,
              itemBuilder: (_, i) => SingleChildScrollView(
                // NeverScrollable: the page itself never scrolls — the scroll
                // view only exists so a page taller than the (not-yet-measured)
                // viewport is absorbed for a single frame instead of throwing a
                // RenderFlex overflow. Once `_MeasureSize` reports the real
                // height, the viewport grows to fit it (see [_viewportHeight]).
                physics: const NeverScrollableScrollPhysics(),
                child: _MeasureSize(
                  onChange: (size) {
                    if (size.height <= 0) return;
                    if (_pageHeights[i] == size.height) return;
                    // Defer the rebuild out of layout.
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() => _pageHeights[i] = size.height);
                    });
                  },
                  child: pages[i],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _PageDots(
          pageCount: pages.length,
          activeIndex: _page,
          color: c.textMuted,
          activeColor: c.accent,
        ),
      ],
    );
  }

  Widget _connectPromptPage(ThemeColors c, String icon, String topic) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$icon  $topic',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect Apple Health or Google Fit to see your $topic here.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.3,
                color: c.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => showHealthConnectSheet(context, ref),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: c.accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Connect health',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef _SizeChanged = void Function(Size size);

/// Reports its child's laid-out size via [onChange] whenever it changes.
/// Used by [_BlocksCarousel] to size its PageView viewport to the active
/// page's real height (so server blocks of any height never overflow the
/// carousel) without a measurement package. The child is laid out with its
/// natural height (the carousel wraps it in a NeverScrollable
/// SingleChildScrollView) so the reported size is the intrinsic page height.
class _MeasureSize extends SingleChildRenderObjectWidget {
  final _SizeChanged onChange;

  const _MeasureSize({required this.onChange, required Widget super.child});

  @override
  _MeasureSizeRenderObject createRenderObject(BuildContext context) =>
      _MeasureSizeRenderObject(onChange);

  @override
  void updateRenderObject(
    BuildContext context,
    _MeasureSizeRenderObject renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class _MeasureSizeRenderObject extends RenderProxyBox {
  _MeasureSizeRenderObject(this.onChange);

  _SizeChanged onChange;
  Size? _previous;

  @override
  void performLayout() {
    super.performLayout();
    final newSize = child?.size ?? Size.zero;
    if (_previous == newSize) return;
    _previous = newSize;
    // Fire after this layout pass settles; the listener schedules its own
    // post-frame setState so we never mutate the tree mid-layout.
    onChange(newSize);
  }
}

/// The branded cold-load state for the coach hero — a pulsing ✦ paired with a
/// rotating status line ("Reading your day…" → "Pulling your numbers
/// together…" → …) and one soft shimmer bar. Self-contained (owns its own
/// ticker + rotation timer) so the parent's lifecycle is untouched, and it
/// reads as the coach actively preparing rather than a stuck, empty card.
///
/// [header] is the already-built eyebrow row (kept real + instant); the
/// animated content sits beneath it. In [isMinimized] only a single compact
/// line is shown to match the collapsed card height.
class _CoachThinkingCard extends StatefulWidget {
  final Widget header;
  final bool isMinimized;

  const _CoachThinkingCard({
    required this.header,
    this.isMinimized = false,
  });

  @override
  State<_CoachThinkingCard> createState() => _CoachThinkingCardState();
}

class _CoachThinkingCardState extends State<_CoachThinkingCard>
    with SingleTickerProviderStateMixin {
  // Rotating reassurance copy. Kept human + specific to the work the coach is
  // actually doing on first load (reading the day, pulling numbers, shaping the
  // focus) so it never reads as a generic spinner label.
  static const List<String> _phrases = <String>[
    'Reading your day…',
    'Pulling your numbers together…',
    'Checking last night’s sleep…',
    'Shaping today’s focus…',
  ];

  late final AnimationController _pulse;
  Timer? _rotateTimer;
  int _phraseIndex = 0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    // Advance the status line every ~1.9s; AnimatedSwitcher cross-fades it.
    _rotateTimer = Timer.periodic(const Duration(milliseconds: 1900), (_) {
      if (!mounted) return;
      setState(() => _phraseIndex = (_phraseIndex + 1) % _phrases.length);
    });
  }

  @override
  void dispose() {
    _rotateTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  Widget _spark(ThemeColors c, double size) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1.0).animate(
        CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
      ),
      child: Icon(Icons.auto_awesome, size: size, color: c.accent),
    );
  }

  Widget _rotatingLine(ThemeColors c, double fontSize) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: child,
      ),
      child: Text(
        _phrases[_phraseIndex],
        key: ValueKey<int>(_phraseIndex),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: c.textPrimary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);

    if (widget.isMinimized) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.header,
          const SizedBox(height: 8),
          Row(
            children: [
              _spark(c, 13),
              const SizedBox(width: 8),
              Flexible(child: _rotatingLine(c, 13)),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.header,
        const SizedBox(height: 14),
        Row(
          children: [
            _spark(c, 16),
            const SizedBox(width: 10),
            Expanded(child: _rotatingLine(c, 14)),
          ],
        ),
        const SizedBox(height: 12),
        // One soft shimmer bar keeps the "loading" read without faking content.
        const SkeletonBox(width: 180, height: 11, radius: 6),
        const SizedBox(height: 14),
        Text(
          'Your focus lands in a sec.',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: c.textSecondary,
          ),
        ),
      ],
    );
  }
}
