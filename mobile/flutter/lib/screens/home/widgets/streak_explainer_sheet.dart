/// Streak explainer sheet — what counts as a streak, how the freeze works,
/// and how many freezes the user has banked.
///
/// Surfaced from:
///  * The home header streak chip (`Nd 🔥`).
///  * Future: the XP/Goals screen detail row.
///
/// Reuses the app's shared `showGlassSheet` + `GlassSheet` styling so it
/// matches every other bottom sheet on the home (not a custom panel).
///
/// P5 §13 (2026-05-24) — wires the XP-side freeze (migration 2095) into
/// this sheet. `freezesAvailable` comes from `xpFreezesAvailableProvider`
/// and the "Use freeze" button calls `XPNotifier.useFreeze()` which POSTs
/// `/xp/use-freeze`. The "streak at risk" gate fires when the last XP
/// transaction is older than 18 hours AND freezes > 0.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../data/providers/xp_provider.dart';
import '../../../widgets/glass_sheet.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Open the streak explainer.
Future<void> showStreakExplainerSheet(BuildContext context) {
  return showGlassSheet<void>(
    context: context,
    isDismissible: true,
    enableDrag: true,
    builder: (_) => const GlassSheet(
      showHandle: true,
      child: _StreakExplainerBody(),
    ),
  );
}

class _StreakExplainerBody extends ConsumerWidget {
  const _StreakExplainerBody();

  /// Heuristic for "streak at risk": no XP-earning action in the last 18h.
  /// Reads the most recent xp_transaction timestamp from the loginStreak +
  /// `hasLoggedInToday` flag — if the user has NOT logged in today, the
  /// streak will roll over at local midnight, so we want to surface the
  /// freeze option proactively.
  bool _isStreakAtRisk(WidgetRef ref) {
    final st = ref.read(xpProvider);
    // If they've already logged in today, today is safe — no risk yet.
    if (st.hasLoggedInToday) return false;
    // Otherwise their next missing action will break the streak at local
    // midnight; treat that as "at risk" so the freeze CTA appears.
    return st.currentStreak > 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);
    final streakDays = ref.watch(xpCurrentStreakProvider);
    final freezes = ref.watch(xpFreezesAvailableProvider);
    final atRisk = _isStreakAtRisk(ref);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).streakExplainerYourStreak,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: c.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Big streak number
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$streakDays',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: -1.5,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  streakDays == 1 ? 'day' : 'days',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Rule
          Text(
            AppLocalizations.of(context).streakExplainerHowTheStreakWorks,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'You earn a streak day every day you log into Zealova and complete '
            'at least one tracked action — a workout, a meal, a weigh-in, or '
            'a chat with your coach. Miss a day and the streak resets to 0.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: 14),

          // Freeze section — real freeze count (P5 §13) + Use-freeze CTA
          // when the streak is at risk and the user has at least 1 banked.
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🧊', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                AppLocalizations.of(context).streakExplainerStreakFreezes,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: c.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: c.accent.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '$freezes',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: c.accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            freezes == 0
                                ? 'No freezes banked — your next freeze unlocks '
                                  'on the first of the month.'
                                : 'Protect your streak through travel or '
                                  'illness. Cap of 2 per month.',
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.4,
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // CTA only when the freeze actually does something useful:
                // freezes available AND the streak is at risk today.
                if (atRisk && freezes > 0) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        await ref.read(xpProvider.notifier).useFreeze();
                        if (context.mounted) {
                          Navigator.of(context).maybePop();
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: c.accent,
                        foregroundColor: c.accentContrast,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context).streakExplainerUseFreeze,
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),

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
