/// Coach Briefing Card — the RICH daily briefing rendered at the top of an
/// open/empty Ask Coach chat (morning_brief / evening_recap source).
///
/// Distinct from a normal chat bubble: a sparkle + time-of-day header, the
/// headline in bold, the multi-line body (with "• " bullets, an optional
/// "Watch:" line, and a trailing check-in question highlighted), then the
/// quick-reply chips as a Wrap of tappable pills.
///
/// Chip dispatch follows the backend contract (see [InsightChip]):
///   * route  → [onRouteTap]
///   * action → [onActionTap] (dispatched via dispatchWorkoutCardAction)
///   * neither (label-only) → [onMessageTap] (sent as a user chat message)
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/coach_persona.dart';
import '../../../data/providers/daily_coach_insight_provider.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/coach_avatar.dart';
import 'generic_blocks_renderer.dart';

class CoachBriefingCard extends StatelessWidget {
  final DailyCoachInsight insight;
  final CoachPersona coach;

  /// Label-only chip tapped → send [label] as a user chat message.
  final void Function(String label) onMessageTap;

  /// Action chip tapped → dispatch the workout-card action [kind].
  final void Function(String kind, Map<String, dynamic> payload) onActionTap;

  /// Route chip tapped → deep-link to [route].
  final void Function(String route) onRouteTap;

  /// ✨ tapped → force-regenerate the insight (`?refresh=true`). Null hides
  /// the affordance (e.g. render sites that can't reseed the thread).
  final VoidCallback? onRegenerate;

  /// True while a forced regeneration is in flight — the ✨ swaps for a
  /// small spinner so the tap visibly did something.
  final bool regenerating;

  const CoachBriefingCard({
    super.key,
    required this.insight,
    required this.coach,
    required this.onMessageTap,
    required this.onActionTap,
    required this.onRouteTap,
    this.onRegenerate,
    this.regenerating = false,
  });

  bool get _isEvening => insight.source == 'evening_recap';

  /// "as of 6:36 PM" freshness caption — local time the AI text was generated.
  String? get _asOfLabel {
    final ts = insight.generatedAt;
    if (ts == null) return null;
    final local = ts.toLocal();
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    return 'as of $hour12:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final accent = c.accent;
    final lines = _parseBody(insight.body);

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: c.isDark ? 0.14 : 0.10),
            accent.withValues(alpha: c.isDark ? 0.04 : 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: avatar + sparkle + time-of-day label ───────────────
          Row(
            children: [
              CoachAvatar(
                coach: coach,
                size: 32,
                showBorder: true,
                showShadow: false,
                enableTapToView: false,
              ),
              const SizedBox(width: 10),
              Icon(
                _isEvening
                    ? Icons.nightlight_round
                    : Icons.wb_sunny_rounded,
                size: 16,
                color: accent,
              ),
              const SizedBox(width: 6),
              Text(
                _isEvening ? 'EVENING RECAP' : 'MORNING BRIEFING',
                style: ZType.lbl(11, color: accent, weight: FontWeight.w800,
                    letterSpacing: 1.1),
              ),
              const Spacer(),
              // Freshness caption — makes staleness visible instead of the
              // numbers silently claiming to be "now".
              if (_asOfLabel != null) ...[
                Text(
                  _asOfLabel!,
                  style: ZType.lbl(10, color: c.textMuted, letterSpacing: 0.4),
                ),
                const SizedBox(width: 8),
              ],
              // ✨ = regenerate. The endpoint supports refresh=true, so a
              // user staring at stale numbers can fix it in one tap.
              if (onRegenerate != null)
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: regenerating
                      ? null
                      : () {
                          HapticService.selection();
                          onRegenerate!();
                        },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: regenerating
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.8,
                              valueColor: AlwaysStoppedAnimation(accent),
                            ),
                          )
                        : Icon(Icons.auto_awesome,
                            size: 14, color: accent.withValues(alpha: 0.7)),
                  ),
                )
              else
                Icon(Icons.auto_awesome,
                    size: 14, color: accent.withValues(alpha: 0.7)),
            ],
          ),
          const SizedBox(height: 12),

          // ── Headline ────────────────────────────────────────────────────
          if (insight.headline.trim().isNotEmpty)
            Text(
              insight.headline.trim(),
              style: ZType.ser(20, color: c.textPrimary,
                  weight: FontWeight.w600, height: 1.25),
            ),
          if (insight.headline.trim().isNotEmpty && lines.isNotEmpty)
            const SizedBox(height: 10),

          // ── Body: recap line, bullets, watch line, check-in question ─────
          for (int i = 0; i < lines.length; i++) ...[
            _BodyLine(
              line: lines[i],
              colors: c,
              accent: accent,
              onRouteTap: onRouteTap,
            ),
            if (i != lines.length - 1) const SizedBox(height: 6),
          ],

          // ── Grounded health graphs (sleep ring + recovery signals + steps)
          // — the Google-Health "here's how you slept" panel. Tappable into
          // the full metric screens via each block's tap_route.
          if (insight.blocks.isNotEmpty) ...[
            const SizedBox(height: 14),
            GenericBlocksRenderer(blocks: insight.blocks),
          ],

          // ── Quick-reply chips ────────────────────────────────────────────
          if (insight.chips.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final chip in insight.chips)
                  _BriefingChip(
                    chip: chip,
                    accent: accent,
                    onTap: () => _dispatch(chip),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _dispatch(InsightChip chip) {
    HapticService.selection();
    if (chip.route != null && chip.route!.isNotEmpty) {
      onRouteTap(chip.route!);
      return;
    }
    if (chip.action != null && chip.action!.isNotEmpty) {
      onActionTap(chip.action!, {
        if (insight.insightId != null) 'insight_id': insight.insightId,
        'source_surface': insight.source,
        // Forward any chip-attached action context (e.g. the injury recovery
        // check-in's body_part / injury_id) so the handler can act on it.
        ...chip.actionContext,
      });
      return;
    }
    onMessageTap(chip.label);
  }

  /// Split the multi-line body into trimmed, non-empty lines so we can style
  /// bullets ("• ") and the trailing check-in question distinctly.
  static List<String> _parseBody(String body) {
    return body
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }
}

/// One body line — bullets, "Watch:" callouts, and the trailing check-in
/// question are styled distinctly from the plain recap line.
class _BodyLine extends StatelessWidget {
  final String line;
  final ThemeColors colors;
  final Color accent;

  /// Deep-link handler for tappable stat phrases in the recap prose.
  final void Function(String route)? onRouteTap;

  const _BodyLine({
    required this.line,
    required this.colors,
    required this.accent,
    this.onRouteTap,
  });

  /// Stat phrases the recap regularly cites, mapped to their home surface —
  /// "489 calories" → Nutrition, "6 workouts" → Workouts, "8.0 hours of
  /// sleep" → Sleep. The card states facts; tapping one should GO there.
  static final List<(RegExp, String)> _statRoutes = [
    (
      RegExp(
        r'\d+(?:[.,]\d+)?\s*(?:calories|kcal|cal\b|grams? of protein|g of protein|g protein|grams? of carbs|grams? of fat)',
        caseSensitive: false,
      ),
      '/nutrition',
    ),
    (
      RegExp(r'\d+\s*(?:workouts?|sessions?)\b', caseSensitive: false),
      '/workouts',
    ),
    (
      RegExp(r'\d+(?:[.,]\d+)?\s*(?:hours?|hrs?)\s+of\s+sleep', caseSensitive: false),
      '/health/sleep',
    ),
  ];

  /// Split [text] into plain + tappable spans. Returns null when nothing
  /// matched (caller renders the cheap plain Text instead).
  List<InlineSpan>? _linkifiedSpans(TextStyle base) {
    if (onRouteTap == null) return null;
    // Collect all matches across patterns, earliest-first, non-overlapping.
    final hits = <(int, int, String)>[];
    for (final (re, route) in _statRoutes) {
      for (final m in re.allMatches(line)) {
        final overlaps =
            hits.any((h) => m.start < h.$2 && m.end > h.$1);
        if (!overlaps) hits.add((m.start, m.end, route));
      }
    }
    if (hits.isEmpty) return null;
    hits.sort((a, b) => a.$1.compareTo(b.$1));

    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final (start, end, route) in hits) {
      if (start > cursor) {
        spans.add(TextSpan(text: line.substring(cursor, start), style: base));
      }
      final phrase = line.substring(start, end);
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: GestureDetector(
          onTap: () {
            HapticService.selection();
            onRouteTap!(route);
          },
          child: Text(
            phrase,
            style: base.copyWith(
              color: accent,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationStyle: TextDecorationStyle.dotted,
              decorationColor: accent.withValues(alpha: 0.6),
            ),
          ),
        ),
      ));
      cursor = end;
    }
    if (cursor < line.length) {
      spans.add(TextSpan(text: line.substring(cursor), style: base));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final isBullet = line.startsWith('• ') || line.startsWith('•');
    final isWatch = line.toLowerCase().startsWith('watch:');
    final isQuestion = line.endsWith('?');

    if (isBullet) {
      final text = line.replaceFirst(RegExp(r'^•\s*'), '');
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.circle, size: 6, color: accent),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: ZType.ser(14,
                  color: colors.textPrimary.withValues(alpha: 0.92),
                  height: 1.35),
            ),
          ),
        ],
      );
    }

    if (isWatch) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.visibility_outlined, size: 15, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                line,
                style: ZType.ser(13.5, color: colors.textPrimary,
                    weight: FontWeight.w600, height: 1.35),
              ),
            ),
          ],
        ),
      );
    }

    // Trailing check-in question → emphasised so the open memory loop reads
    // as a prompt the user can answer.
    if (isQuestion) {
      return Text(
        line,
        style: ZType.ser(14.5, color: accent, weight: FontWeight.w700,
            height: 1.35),
      );
    }

    // Plain recap line (first line, with real numbers). Stat phrases become
    // tappable deep-links into their home surface.
    final base = ZType.ser(14, color: colors.textSecondary, height: 1.4);
    final spans = _linkifiedSpans(base);
    if (spans != null) {
      return Text.rich(TextSpan(children: spans));
    }
    return Text(line, style: base);
  }
}

/// A single briefing chip pill. Action / route / label-only all render the
/// same pill; an action chip shows a small leading glyph so it reads as a
/// one-tap shortcut vs a conversation starter.
class _BriefingChip extends StatelessWidget {
  final InsightChip chip;
  final Color accent;
  final VoidCallback onTap;

  const _BriefingChip({
    required this.chip,
    required this.accent,
    required this.onTap,
  });

  IconData? get _glyph {
    if (chip.action == null) return null;
    switch (chip.action) {
      case 'log_water_now':
        return Icons.water_drop_outlined;
      case 'log_breakfast':
        return Icons.restaurant_outlined;
      case 'plan_tomorrow_meals':
        return Icons.event_note_outlined;
      case 'start_wind_down':
        return Icons.bedtime_outlined;
      case 'start_workout_now':
        return Icons.fitness_center_outlined;
      case 'injury_resolved':
        return Icons.check_circle_outline;
      case 'injury_extend':
        return Icons.healing_outlined;
      case 'start_rehab':
        return Icons.self_improvement_outlined;
      default:
        return Icons.bolt_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final glyph = _glyph;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        // Compact pill — was vertical: 8, which read tall next to 13sp text.
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: accent.withValues(alpha: 0.32)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (glyph != null) ...[
              Icon(glyph, size: 14, color: accent),
              const SizedBox(width: 6),
            ],
            Text(
              chip.label,
              style: ZType.lbl(13, color: accent, letterSpacing: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
