import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/serious_mode_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../data/providers/xp_provider.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/app_tour/app_tour_controller.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      key: AppTourKeys.topBarKey,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const _HomeAvatarButton(),
          const SizedBox(width: 12),
          const Expanded(child: _Greeting()),
          NotificationBellButton(isDark: isDark),
          _SettingsButton(isDark: isDark),
        ],
      ),
    );
  }
}

/// 36pt circular avatar at the left of the header. Tap → `/profile` (the
/// You hub). The avatar is the canonical "go to me" affordance — matches
/// Google Health / Strava / Instagram header patterns. Falls back to a
/// neutral person glyph when the user has no photo URL or the network
/// image fails to load.
class _HomeAvatarButton extends ConsumerWidget {
  const _HomeAvatarButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider).valueOrNull;
    final photoUrl = user?.photoUrl;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final muted = fg.withValues(alpha: 0.55);

    return GestureDetector(
      onTap: () {
        HapticService.light();
        // ?tab=profile lands on the Profile sub-tab inside the You hub
        // instead of the default Overview tab. Route handler parses this
        // query param in `app_router_main_shell_routes.dart` and passes
        // `initialTabIndex: 1` to YouHubScreen.
        context.go('/profile?tab=profile');
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fg.withValues(alpha: 0.08),
        ),
        clipBehavior: Clip.antiAlias,
        child: photoUrl != null && photoUrl.isNotEmpty
            ? Image.network(
                photoUrl,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.person, color: muted, size: 20),
              )
            : Icon(Icons.person, color: muted, size: 20),
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
    final greeting = hour < 12
        ? 'Good morning,'
        : hour < 17
            ? 'Good afternoon,'
            : 'Good evening,';
    final name = ref.watch(currentUserProvider).valueOrNull?.name;
    final firstName = (name != null && name.trim().isNotEmpty)
        ? name.trim().split(' ').first
        : 'there';

    final serious = ref.watch(seriousModeProvider);
    final streakDays = ref.watch(xpCurrentStreakProvider);
    final showStreak = !serious && streakDays > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          greeting,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        const SizedBox(height: 1),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                firstName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: isDark ? Colors.white : const Color(0xFF0A0A0A),
                ),
              ),
            ),
            if (showStreak) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  HapticService.light();
                  showStreakExplainerSheet(context);
                },
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '· ${streakDays}d',
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
            ],
          ],
        ),
      ],
    );
  }
}

