import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/current_day_provider.dart';
import '../../../core/providers/serious_mode_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../data/providers/xp_provider.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/app_tour/app_tour_controller.dart';
import '../../../widgets/word_bounce.dart';
import 'components/components.dart';
import 'streak_explainer_sheet.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Clean, minimal header for the "Minimalist" home screen preset.
///
/// Layout (2026-08 redesign — collapses the prior two-line greeting + big
/// Anton date block into a single line so the sections below start higher):
/// ```
/// Morning, Casey · Wed, Aug 5      [bell] [gear]
/// ```
///
/// - Greeting + date share one line (was: greeting line, then a large
///   two-line "WEDNESDAY · AUGUST 5" editorial date block below it). The
///   reclaimed vertical space goes to the banner stack and coach card, not a
///   phantom gap — this widget's own padding shrank to match.
/// - Level ring removed from Home; lives on `/you/overview` next to the
///   XP hero tile (gamification belongs in the gamification surface).
/// - Bell stays (notifications are universal).
/// - Settings gear replaces the kebab `⋮` and goes straight to `/settings`.
///   The kebab's prior items (change gym, toggle week strip, edit home
///   layout) all live inside Settings already; one tap to reach them is
///   acceptable for weekly-frequency actions.
class MinimalHeader extends ConsumerWidget {
  const MinimalHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Single-line masthead — greeting + date on the left, bell/settings
    // cluster on the right. The sparkle "Ask coach" button was removed
    // (2026-08): Coach is a bottom tab and already owns most of Home, so a
    // third unlabelled route into chat earned nothing.
    return Padding(
      key: AppTourKeys.topBarKey,
      // Tight bottom inset: the icon cluster below is 40pt tall (see
      // NotificationBellButton / _SettingsButton), and the banner panel that
      // follows adds its own 2pt. 8pt here stacked into a ~26pt dead band
      // between the masthead and the first banner (reported).
      padding: const EdgeInsets.fromLTRB(20, 4, 8, 2),
      child: Row(
        children: [
          const Expanded(child: _Greeting()),
          NotificationBellButton(isDark: isDark),
          _SettingsButton(isDark: isDark),
        ],
      ),
    );
  }
}

/// Inline streak chip ("23 🔥") for the masthead cluster. Hidden in Serious
/// Mode and when the streak is zero. Tap opens the streak explainer.
class _StreakChip extends ConsumerWidget {
  const _StreakChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final serious = ref.watch(seriousModeProvider);
    final streakDays = ref.watch(xpCurrentStreakProvider);
    if (serious || streakDays <= 0) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () {
        HapticService.light();
        showStreakExplainerSheet(context);
      },
      behavior: HitTestBehavior.opaque,
      child: WordBounce(
        trigger: streakDays,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$streakDays',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.70)
                    : Colors.black.withValues(alpha: 0.55),
                height: 1.0,
              ),
            ),
            const SizedBox(width: 3),
            const Text('🔥', style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

/// Settings gear button. Replaces the prior overflow kebab — every item
/// the kebab used to host (change gym, toggle week strip, edit home
/// layout) is reachable from `/settings` in one extra tap, and the user
/// confirmed they want a global gear on Home alongside the per-tab gears
/// that other tabs already render.
class _SettingsButton extends StatelessWidget {
  final bool isDark;
  const _SettingsButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final iconColor = isDark ? Colors.white70 : Colors.black54;
    return IconButton(
      icon: Icon(Icons.settings_outlined, size: 22, color: iconColor),
      tooltip: AppLocalizations.of(context).settingsTitle,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      onPressed: () {
        HapticService.light();
        context.push('/settings');
      },
    );
  }
}

/// Time-of-day greeting + the user's first name, folded onto one line with
/// the short date ("Morning, Casey · Wed, Aug 5"). Real name personalization
/// only — no "there"-style placeholder. When the name isn't available yet
/// (still loading, or genuinely unset) the line degrades to the date alone
/// rather than showing a fake-personalized greeting.
class _Greeting extends ConsumerWidget {
  const _Greeting();

  static const _weekdaysShort = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];
  static const _monthsShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Watched (not read) so this line rebuilds the instant the local day
    // rolls over — otherwise a session left open across midnight keeps
    // showing yesterday's greeting/date from the last paint (register #123).
    ref.watch(currentLocalDayProvider);
    // Watched so the greeting word itself ("Morning"/"Afternoon"/"Evening")
    // rebuilds the instant its bucket boundary is crossed — otherwise a
    // session left open across e.g. 5pm keeps showing "Afternoon" (#295).
    ref.watch(currentGreetingBucketProvider);
    final now = DateTime.now();
    final hour = now.hour;
    final name = ref.watch(currentUserProvider).valueOrNull?.name;
    final firstName = (name != null && name.trim().isNotEmpty)
        ? name.trim().split(' ').first
        : null;
    final shortDate =
        '${_weekdaysShort[now.weekday - 1]}, ${_monthsShort[now.month - 1]} ${now.day}';

    // v2 greeting — short, human, Archivo. "Evening, Chetan · Wed, Aug 5."
    final l10n = AppLocalizations.of(context);
    final shortGreeting = hour < 12
        ? l10n.minimalHeaderMorning
        : hour < 17
            ? l10n.minimalHeaderAfternoon
            : l10n.minimalHeaderEvening;

    final line =
        firstName != null ? '$shortGreeting, $firstName · $shortDate' : shortDate;

    return Text(
      line,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: ZType.ser(
        15,
        weight: FontWeight.w600,
        color: isDark
            ? Colors.white.withValues(alpha: 0.82)
            : const Color(0xFF2A2A2A),
      ),
    );
  }
}

