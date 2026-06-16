import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
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
/// Layout (May 2026 redesign — replaces the prior 5-element chrome row):
/// ```
/// [Avatar] Good evening,        [bell] [gear]
///          Sai · 2d 🔥
/// ```
///
/// - Avatar (36pt) → `/profile` (You hub).
/// - Greeting + inline streak chip under name (gamification stays glanceable
///   without competing with primary CTAs).
/// - Level ring removed from Home; lives on `/you/overview` next to the
///   XP hero tile (gamification belongs in the gamification surface).
/// - Bell stays (notifications are universal).
/// - Settings gear replaces the kebab `⋮` and goes straight to `/settings`.
///   The kebab's prior items (change gym, toggle week strip, edit home
///   layout) all live inside Settings already; one tap to reach them is
///   acceptable for weekly-frequency actions.
class MinimalHeader extends ConsumerWidget {
  const MinimalHeader({super.key});

  static const _weekdays = [
    'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY',
  ];
  static const _months = [
    'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
    'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = ThemeColors.of(context);
    final now = DateTime.now();
    final weekday = _weekdays[now.weekday - 1];
    final monthDay = '${_months[now.month - 1]} ${now.day}';

    // SIGNATURE V2 masthead — brand + streak/bell/coach cluster, then the big
    // Anton editorial date, then the Fraunces greeting. Replaces the prior
    // avatar + inline-greeting row. Profile is reached via the You tab; the
    // settings gear stays in the cluster so it's still one tap from Home.
    return Padding(
      key: AppTourKeys.topBarKey,
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Wordmark removed (the user sees "Zealova" on every screen) — the
          // action cluster sits right-aligned on its own row.
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const _StreakChip(),
              const SizedBox(width: 2),
              NotificationBellButton(isDark: isDark),
              _CoachGlyphButton(isDark: isDark),
              _SettingsButton(isDark: isDark),
            ],
          ),
          const SizedBox(height: 2),
          // Big editorial date — Anton display, gym-aware accent on the month.
          RichText(
            text: TextSpan(
              text: weekday,
              style: ZType.disp(30, color: c.textPrimary),
              children: [
                TextSpan(
                  text: '  ·  $monthDay',
                  style: ZType.disp(30, color: c.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const _Greeting(),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// The ✦ ask-coach glyph in the home masthead — opens the coach chat.
class _CoachGlyphButton extends StatelessWidget {
  final bool isDark;
  const _CoachGlyphButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final iconColor = isDark ? Colors.white70 : Colors.black54;
    return IconButton(
      icon: Icon(Icons.auto_awesome, size: 20, color: iconColor),
      tooltip: 'Ask coach',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      onPressed: () {
        HapticService.light();
        try {
          context.push('/chat?source=home_masthead');
        } catch (_) {
          context.push('/chat');
        }
      },
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
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      onPressed: () {
        HapticService.light();
        context.push('/settings');
      },
    );
  }
}

/// Time-of-day greeting + the user's first name + inline streak chip.
/// The streak chip moved here from the right side of the header so the
/// streak's daily-motivation hook stays glanceable without occupying its
/// own chrome slot. Hidden in Serious Mode (where gamification chrome is
/// suppressed) and when the streak is zero.
class _Greeting extends ConsumerWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hour = DateTime.now().hour;
    final name = ref.watch(currentUserProvider).valueOrNull?.name;
    final firstName = (name != null && name.trim().isNotEmpty)
        ? name.trim().split(' ').first
        : 'there';

    // v2 greeting — short, human, Fraunces italic. "Evening, Chetan."
    final shortGreeting = hour < 12
        ? 'Morning'
        : hour < 17
            ? 'Afternoon'
            : 'Evening';

    return Text(
      '$shortGreeting, $firstName.',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: ZType.ser(
        12.5,
        color: isDark
            ? Colors.white.withValues(alpha: 0.82)
            : const Color(0xFF2A2A2A),
      ),
    );
  }
}

