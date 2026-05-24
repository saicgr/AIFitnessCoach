/// One-shot announcement sheet shown the first time a user opens the home
/// screen after the v2 score redesign (2026-05-22).
///
/// Why this exists: adding Sleep as a 4th contributor (40/30/15/15) shifts
/// every existing user's day score the moment they update — without context
/// they'd see "67 yesterday → 58 today" and assume something's broken or
/// their behaviour regressed. The sheet explains the change in one tap.
///
/// One-shot: persisted under `score_change_v2_seen` in SharedPreferences.
/// First call to [maybeShowScoreChangeAnnouncement] after that returns
/// immediately without showing anything.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/theme_colors.dart';
import 'score_colors.dart';

const String _kSeenKey = 'score_change_v2_seen';

/// Show the sheet if it hasn't been shown to this device yet. Call once from
/// the home screen's `initState` (post-frame so the sheet can use context).
Future<void> maybeShowScoreChangeAnnouncement(BuildContext context) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kSeenKey) == true) return;
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ScoreChangeSheet(),
    );
    // Persist after the sheet returns so an interrupted first-show (e.g.
    // the user backgrounded the app mid-sheet) gets another chance.
    await prefs.setBool(_kSeenKey, true);
  } catch (_) {
    // Non-fatal — the sheet is a one-time courtesy, never block the home.
  }
}

class _ScoreChangeSheet extends StatelessWidget {
  const _ScoreChangeSheet();

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: c.elevated,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.cardBorder),
        ),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
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
                  child:
                      const Icon(Icons.auto_awesome, size: 13, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(
                  'WHAT\'S NEW',
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
              'Sleep now counts toward your daily score.',
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
              'Nourish, and Move. Your day score now reflects all four — '
              'so a poor night shows up as a lower number, and a solid '
              'night helps it climb. Tap any ring to dig in.',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            // Pillar legend — four colored dots + labels in one row so the
            // user can match what they're about to see on the score card.
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: const [
                _LegendChip(label: 'Train', color: kTrainColor, weight: 40),
                _LegendChip(label: 'Nourish', color: kFuelColor, weight: 30),
                _LegendChip(label: 'Move', color: kMoveColor, weight: 15),
                _LegendChip(label: 'Sleep', color: kSleepColor, weight: 15),
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
                        horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text(
                    'Got it',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label · $weight%',
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
