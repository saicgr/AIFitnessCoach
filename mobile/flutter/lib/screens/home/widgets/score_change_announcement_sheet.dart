/// One-shot announcement sheet shown the first time a user opens the home
/// screen after the v2 score redesign (2026-05-22).
///
/// Why this exists: adding Sleep as a 4th contributor (40/30/15/15) shifts
/// every existing user's day score the moment they update — without context
/// they'd see "67 yesterday → 58 today" and assume something's broken or
/// their behaviour regressed. The sheet explains the change in one tap.
///
/// CONSOLIDATION (Phase 6): the "Sleep now counts toward your score" message
/// is ALSO folded into the full-screen What's-New carousel as a slide. To stop
/// a returning user from seeing BOTH surfaces, this sheet now DEFERS to the
/// carousel: [maybeShowScoreChangeAnnouncement] skips itself whenever the
/// What's-New carousel still has to run (it's enqueued right after this sheet
/// on home mount and marks `score_change_v2_seen` true when it opens). The
/// sheet only ever fires as a legacy fallback — for a user who already saw the
/// carousel before this slide existed, so the carousel won't run again but the
/// score-change flag was never set.
///
/// One-shot: persisted under `score_change_v2_seen` in SharedPreferences.
/// First call to [maybeShowScoreChangeAnnouncement] after that returns
/// immediately without showing anything.
///
/// Uses the app's shared [GlassSheet] + [showGlassSheet] so it matches every
/// other bottom sheet — glassmorphic, covers the floating Liquid Glass nav
/// bar (which is itself an overlay), and respects the standard barrier.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../widgets/glass_sheet.dart';
import 'score_colors.dart';

import '../../../l10n/generated/app_localizations.dart';

const String _kSeenKey = 'score_change_v2_seen';

/// The What's-New carousel's "seen" flag (owned by
/// `app_tour_controller.dart` / `whats_new_screen.dart`). When this is still
/// false the carousel is about to run and will explain the score change there,
/// so this sheet stands down to avoid showing the same news twice.
const String _kWhatsNewSeenKey = 'whats_new_seen_gravl_v1';

/// Show the sheet if it hasn't been shown to this device yet. Call once from
/// the home screen's `didChangeDependencies` (post-frame so the sheet can
/// use context).
Future<void> maybeShowScoreChangeAnnouncement(BuildContext context) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kSeenKey) == true) return;
    // Defer to the What's-New carousel: if it hasn't run yet it will show the
    // folded-in score-change slide (and mark _kSeenKey true), so showing this
    // sheet too would be redundant. Only fall through when the carousel was
    // already seen but the score-change flag wasn't (legacy upgrade path).
    if (prefs.getBool(_kWhatsNewSeenKey) != true) return;
    if (!context.mounted) return;
    await showGlassSheet<void>(
      context: context,
      // Enable drag/dismiss — this is informational, not blocking.
      isDismissible: true,
      enableDrag: true,
      // Use our custom translucent panel rather than the shared GlassSheet
      // widget. The shared one uses Colors.white.withValues(alpha: 0.7) for
      // legibility on most prompt sheets, which reads as ~opaque. The
      // announcement is purely informational and benefits from a stronger
      // see-through effect (matches the iOS Control Center frosted look),
      // so we override the surface tint + crank up the blur for this sheet
      // only — no global GlassSheetStyle change.
      builder: (_) => const _TranslucentGlassPanel(child: _ScoreChangeBody()),
    );
    // Persist after the sheet returns so an interrupted first-show (e.g.
    // the user backgrounded the app mid-sheet) gets another chance.
    await prefs.setBool(_kSeenKey, true);
  } catch (_) {
    // Non-fatal — the sheet is a one-time courtesy, never block the home.
  }
}

/// Custom translucent panel — bigger blur + lower surface alpha than the
/// shared [GlassSheet] so background content actually reads through. Keeps
/// the standard rounded-top corners + drag handle so it still matches the
/// app's sheet shape.
class _TranslucentGlassPanel extends StatelessWidget {
  final Widget child;
  const _TranslucentGlassPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Heavier blur than the shared GlassSheet (24 vs 12) + lower alpha for
    // a real Control-Center-style frosted glass effect.
    final surface = isDark
        ? Colors.black.withValues(alpha: 0.32)
        : Colors.white.withValues(alpha: 0.42);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.55);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: border, width: 0.5)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Standard drag handle so dismiss is discoverable.
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.45,
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Flexible(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreChangeBody extends StatelessWidget {
  const _ScoreChangeBody();

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sparkle eyebrow
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [c.accent, c.accent.withValues(alpha: 0.70)],
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 13,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).scoreChangeAnnouncementWhatSNew,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: c.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(
              context,
            ).scoreChangeAnnouncementSleepNowCountsToward,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.3,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We added Sleep as a fourth pillar alongside Train, '
            'Nourish, and Move. Your day score now reflects all four, '
            'so a poor night shows up as a lower number and a solid '
            'night helps it climb. Tap any ring to dig in.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          // Pillar legend — four colored dots + labels so the user can match
          // what they're about to see on the score card.
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _LegendChip(
                label: AppLocalizations.of(
                  context,
                ).scoreChangeAnnouncementTrain,
                color: kTrainColor,
                weight: 40,
              ),
              _LegendChip(
                label: AppLocalizations.of(
                  context,
                ).scoreChangeAnnouncementNourish,
                color: kFuelColor,
                weight: 30,
              ),
              _LegendChip(
                label: AppLocalizations.of(context).scoreChangeAnnouncementMove,
                color: kMoveColor,
                weight: 15,
              ),
              _LegendChip(
                label: AppLocalizations.of(context).sleepDetailSleep,
                color: kSleepColor,
                weight: 15,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: FilledButton.styleFrom(
                  backgroundColor: c.accent,
                  foregroundColor: c.accentContrast,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context).weightIncrementsGotIt,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final String label;
  final Color color;
  final int weight; // % share for context — small under-label
  const _LegendChip({
    required this.label,
    required this.color,
    required this.weight,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          AppLocalizations.of(
            context,
          )!.scoreChangeAnnouncementSheetValue(label, weight),
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
      ],
    );
  }
}
