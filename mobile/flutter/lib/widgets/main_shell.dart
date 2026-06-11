import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/chrome_constants.dart';
import '../core/constants/motion_tokens.dart';
import '../core/constants/type_scale.dart';
import '../core/providers/serious_mode_provider.dart';
import '../core/providers/subscription_provider.dart';
import '../data/services/recipe_notification_router.dart';
import '../core/theme/theme_colors.dart';
import '../data/models/coach_persona.dart';
import '../data/providers/coach_refresh_coordinator.dart';
import '../data/providers/discover_provider.dart';
import '../data/providers/fasting_provider.dart';
import '../data/providers/guest_mode_provider.dart';
import '../data/providers/recipe_providers.dart';
import '../screens/nutrition/saved_hub_screen.dart' show savedFoodsHubProvider, savedMenusHubProvider;
import '../data/providers/guest_usage_limits_provider.dart';
import '../data/services/deep_link_service.dart';
import '../data/services/widget_action_service.dart';
import '../screens/ai_settings/ai_settings_screen.dart';
import '../screens/onboarding/founder_note_sheet.dart';
import '../data/repositories/auth_repository.dart' show authStateProvider;
import '../screens/nutrition/quick_log_overlay.dart';
import 'coach_avatar.dart';
import 'app_tour/app_tour_controller.dart';
import 'floating_chat/floating_chat_bubble.dart';
import 'level_up_dialog.dart';
import 'streak_saved_dialog.dart';
import 'offline_banner.dart';
import 'email_verification_banner.dart';
import '../data/providers/xp_provider.dart'
    show
        xpProvider,
        levelUpEventProvider,
        dailyLoginResultProvider,
        unclaimedCratesCountProvider;
import '../data/providers/pending_celebrations_provider.dart';
import 'trophy_ceremony_overlay.dart';
import '../data/models/gym_profile.dart';
import '../data/providers/gym_profile_provider.dart';
import '../data/providers/weekly_recap_provider.dart';
import '../data/models/xp_event.dart' show DailyLoginResult;
import '../data/models/user_xp.dart';
import '../data/models/weekly_recap.dart';
import 'weekly_recap_dialog.dart';
import '../core/accessibility/accessibility_provider.dart';
import '../l10n/generated/app_localizations.dart';
// Tab-prewarm provider imports — warmed in build() so each tab paints from
// cache instead of a cold network skeleton on first open.
import '../data/providers/today_workout_provider.dart' show todayWorkoutProvider;
import '../data/repositories/workout_repository.dart'
    show workoutsProvider, workoutScreenSummaryProvider;
import '../data/repositories/nutrition_repository.dart'
    show dailyNutritionProvider, nutritionMetaProvider, todayNutritionKey;
import '../data/services/health_service.dart' show dailyActivityProvider;
import '../data/repositories/hydration_repository.dart' show hydrationProvider;
import '../data/providers/timeline_provider.dart' show timelineProvider;
import '../data/providers/habit_provider.dart' show habitsProvider;
import '../data/providers/consistency_provider.dart' show consistencyProvider;
import '../data/providers/synced_workouts_provider.dart'
    show syncedWorkoutsProvider;
import '../data/providers/nutrition_preferences_provider.dart'
    show nutritionPreferencesProvider;
import '../data/providers/food_patterns_provider.dart'
    show foodPatternsMoodProvider, patternsSettingsProvider;
import '../data/providers/daily_coach_insight_provider.dart'
    show dailyCoachInsightProvider;
import '../data/providers/contextual_nudge_provider.dart'
    show contextualNudgeProvider;

part 'main_shell_part_edge_panel_handle.dart';
part 'main_shell_part_guest_mode_banner.dart';


/// Provider to control floating nav bar visibility
final floatingNavBarVisibleProvider = StateProvider<bool>((ref) => true);

/// Provider to control whether nav bar labels are expanded
/// Set to false when on secondary pages (Workouts, Nutrition, Fasting)

/// Provider to control edge handle visibility (can be toggled in settings)
/// Persisted to SharedPreferences
final edgeHandleEnabledProvider =
    StateNotifierProvider<EdgeHandleEnabledNotifier, bool>((ref) {
  return EdgeHandleEnabledNotifier();
});

/// Provider to store edge handle vertical position (0.0 = top, 1.0 = bottom)
/// Persisted to SharedPreferences
final edgeHandlePositionProvider =
    StateNotifierProvider<EdgeHandlePositionNotifier, double>((ref) {
  return EdgeHandlePositionNotifier();
});

/// Notifier for the optional draggable floating chat-head bubble. Default
/// OFF — the primary coach surface is now the `CoachFloatingButton`
/// "Ask coach" pill at bottom-right. The draggable head remains available
/// via Settings → AI Coach for users who want the chat-head pattern.
class EdgeHandleEnabledNotifier extends StateNotifier<bool> {
  static const _key = 'edge_handle_enabled';

  EdgeHandleEnabledNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getBool(_key);
      if (value != null) {
        state = value;
      }
    } catch (e) {
      debugPrint('Error loading edge handle enabled: $e');
    }
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, value);
    } catch (e) {
      debugPrint('Error saving edge handle enabled: $e');
    }
  }
}

/// Notifier for edge handle vertical position with persistence
class EdgeHandlePositionNotifier extends StateNotifier<double> {
  static const _key = 'edge_handle_position';

  EdgeHandlePositionNotifier() : super(0.3) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getDouble(_key);
      if (value != null) {
        state = value.clamp(0.0, 1.0);
      }
    } catch (e) {
      debugPrint('Error loading edge handle position: $e');
    }
  }

  Future<void> setPosition(double value) async {
    state = value.clamp(0.0, 1.0);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_key, state);
    } catch (e) {
      debugPrint('Error saving edge handle position: $e');
    }
  }
}

/// Main shell with floating bottom navigation bar
/// Tracks whether the weekly-recap dialog has already fired in this app
/// session. Module-level (not instance) because MainShell is a
/// ConsumerWidget and rebuilds lose instance state. Provider-level ack
/// (SharedPreferences) handles the cross-session "already seen this week".
bool _weeklyRecapFired = false;

class MainShell extends ConsumerWidget {
  /// StatefulNavigationShell for the main tab navigation (keeps tabs alive).
  final StatefulNavigationShell? navigationShell;

  /// Fallback child widget for non-tab usages (e.g. progress_screen wrapping).
  final Widget? child;

  const MainShell({super.key, this.navigationShell, this.child});

  /// The widget to display as the main content area. Falls back to an empty
  /// SizedBox during router teardown when both args briefly resolve to null —
  /// release builds strip the prior assert, so we'd otherwise hit
  /// `child!` and crash with NoSuchMethodError.
  Widget get _child => navigationShell ?? child ?? const SizedBox.shrink();

  int _calculateSelectedIndex(BuildContext context) {
    if (navigationShell != null) return navigationShell!.currentIndex;
    final location = GoRouterState.of(context).matchedLocation;
    // Branch order (2026-06 redesign): Home · Workout · Coach · Nutrition · You.
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/workouts')) return 1;
    if (location.startsWith('/coach')) return 2;
    if (location.startsWith('/nutrition')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  bool _isSecondaryPage(BuildContext context) {
    final fullPath = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    return fullPath.startsWith('/fasting');
  }

  void _onItemTapped(WidgetRef ref, BuildContext context, int index) {
    // Abort any in-flight AppTour on tab switch — the tour's anchor
    // GlobalKeys belong to the outgoing tab. IndexedStack keeps that
    // tab alive offscreen, so the renderbox still reports a screen
    // rect; without aborting, the spotlight would draw over whatever
    // happens to occupy those coordinates on the incoming tab. Silent
    // abort (no "seen" flag) so the tour stays eligible to fire when
    // the user returns to its host tab.
    final tourState = ref.read(appTourControllerProvider);
    if (tourState.isVisible) {
      ref.read(appTourControllerProvider.notifier).abort();
    }
    if (navigationShell != null) {
      navigationShell!.goBranch(index, initialLocation: index == navigationShell!.currentIndex);
      return;
    }
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/workouts');
        break;
      case 2:
        context.go('/coach');
        break;
      case 3:
        context.go('/nutrition');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep the coach-card auto-refresh coordinator alive app-wide: it listens
    // to meal/workout/fast/sleep changes and silently refreshes the Home coach
    // card so it reflects freshly-logged data even when the log happened on
    // another tab. `watch` returns the same instance (a Provider), so this adds
    // no rebuild churn.
    ref.watch(coachRefreshCoordinatorProvider);
    final selectedIndex = _calculateSelectedIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    // Path-based hide for fasting full screens. The fasting screens live
    // inside the Nutrition StatefulShellBranch — switching branches via
    // context.go('/home') keeps them alive in the IndexedStack, so any
    // provider state they set in initState() would never be restored on
    // dispose. Decide nav-bar visibility from the current path directly.
    final currentPath = GoRouter.of(context)
        .routerDelegate.currentConfiguration.uri.path;
    final pathWantsHidden = currentPath.startsWith('/fasting');
    final providerWantsHidden = !ref.watch(floatingNavBarVisibleProvider);
    // Coach tab: hide the nav while the keyboard is up so the chat composer
    // (which sits above the nav clearance — see CoachTabScreen) docks to the
    // keyboard like a normal chat app instead of floating above two bars.
    final keyboardWantsHidden = _calculateSelectedIndex(context) == 2 &&
        MediaQuery.viewInsetsOf(context).bottom > 0;
    final isNavBarVisible =
        !(pathWantsHidden || providerWantsHidden || keyboardWantsHidden);
    final isGuestMode = ref.watch(isGuestModeProvider);

    // ── Tab prewarm (staggered, active-tab-first) ─────────────────────
    // Warm each tab's first-paint providers so silent network refreshes are
    // in flight by the time a tab opens. Every first-paint provider is now
    // disk-cache-first (it paints last-known content instantly regardless),
    // so the prewarm's only job is to kick the *refresh* — which means we can
    // safely STAGGER it.
    //
    // Previously all ~23 providers were `ref.read` synchronously in build(),
    // constructing ~23 notifiers that each fired a network call into Dio's
    // 6-socket pool at once. The tab the user was actually looking at then
    // queued its own /today, /nutrition, /timeline calls BEHIND 19 other
    // tabs' background fetches — the dominant "every tab feels laggy on open"
    // cause. Now: warm the ACTIVE tab immediately (post-frame), then release
    // the other tabs' refreshes in two later waves so they never starve the
    // visible tab's sockets. Guarded so it schedules once per signed-in user
    // (re-arms on a fresh login).
    final prewarmUserId = ref.read(authStateProvider).user?.id;
    _schedulePrewarm(ref, selectedIndex, prewarmUserId);

    // Initialize widget action service (MethodChannel listener)
    // This allows Android widgets to trigger UI actions without navigation
    final widgetActionService = ref.read(widgetActionServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        widgetActionService.initialize(context, ref);
      }
    });

    // Founder welcome sheet — shown ONCE, only for brand-new accounts
    // (backend marks `is_new_user=true` on the row-creation response).
    // Returning users with existing accounts skip this entirely. Lives in
    // MainShell (not on auth screens) so the GoRouter redirect can't tear
    // the modal down mid-display.
    final authUser = ref.read(authStateProvider).user;
    if (authUser != null && authUser.isFirstLogin) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!context.mounted) return;
        await FounderNoteSheet.showIfFirstTime(context);
      });
    }

    // Consume any pending meal-reminder notification action (set by the FCM
    // handler in notification_service_ext._handleMessageOpenedApp). No-op if
    // nothing pending; clears itself after first consumption.
    if (RecipeNotificationRouter.pending != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          RecipeNotificationRouter.consume(context, ref);
        }
      });
    }

    // Listen for pending widget actions (from home screen widget deep links)
    ref.listen<PendingWidgetAction>(pendingWidgetActionProvider, (previous, next) {
      debugPrint('MainShell: Pending action changed from $previous to $next');
      if (next == PendingWidgetAction.showLogMealSheet) {
        // Clear the action immediately
        ref.read(pendingWidgetActionProvider.notifier).state = PendingWidgetAction.none;
        // Show the quick log overlay after screen is fully built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (context.mounted) {
              debugPrint('MainShell: Showing quick log overlay');
              showQuickLogOverlay(context, ref);
            }
          });
        });
      }
    });

    // Hard-lock paywall: redirect to /hard-paywall when subscription lapses
    ref.listen(
      subscriptionProvider.select((s) => s.tier),
      (previous, currentTier) {
        if (currentTier == SubscriptionTier.free && context.mounted) {
          // Check if user previously completed paywall (had a trial/sub that lapsed)
          ref.read(subscriptionProvider.notifier).checkIsHardLocked().then((isLocked) {
            if (isLocked && context.mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  context.go('/hard-paywall');
                }
              });
            }
          });
        }
      },
    );

    // Celebration ceremony — replay any trophies earned since the user's
    // last ack cursor. Fires on login (user becomes non-null) + on
    // explicit refresh triggers. Ack advances the cursor so the same
    // trophy never plays twice. Runs after frame so it never fights with
    // the shell's initial layout.
    ref.listen<PendingCelebrationsState>(pendingCelebrationsProvider, (prev, next) {
      if (next.pending.isEmpty) return;
      final wasEmpty = prev == null || prev.pending.isEmpty;
      if (!wasEmpty) return; // Already showing
      if (ref.read(seriousModeProvider)) {
        // Serious Mode suppresses celebrations — silently ack so they
        // don't stack up forever.
        ref.read(pendingCelebrationsProvider.notifier).ack();
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!context.mounted) return;
        await showTrophyCeremony(
          context: context,
          trophies: next.pending,
        );
        await ref.read(pendingCelebrationsProvider.notifier).ack();
      });
    });

    // Kick off an initial pending-celebrations refresh once per shell
    // mount. Later refreshes should be triggered by whatever awards a
    // trophy (trophy_triggers.py invokes FCM / websocket), but the
    // app-open case is the important retention moment here.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        ref.read(pendingCelebrationsProvider.notifier).refresh();
      }
    });

    // Listen for level-up events from ANY screen (moved from home_screen.dart)
    ref.listen<LevelUpEvent?>(levelUpEventProvider, (previous, next) {
      if (next != null && previous == null) {
        // Serious Mode suppresses celebration dialogs; XP is still awarded
        // and the level state advances, we just skip the confetti pop-in.
        if (ref.read(seriousModeProvider)) {
          ref.read(xpProvider.notifier).clearLevelUp();
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            final showProg = ref.read(accessibilityProvider).showLevelUpProgression;
            showLevelUpDialog(
              context,
              next,
              () {
                ref.read(xpProvider.notifier).clearLevelUp();
              },
              showProgression: showProg,
            );
          }
        });
      }
    });

    // Listen for Weekly Recap gate — fires on first foreground after
    // Monday 06:00 local time when the user has meaningful recap content
    // from last week. Provider handles ack persistence (SharedPreferences)
    // so the dialog can't re-fire the same ISO week. Suppressed when
    // another modal is currently visible (level-up) — we retry next frame.
    //
    // Defensive try/catch around the whole flow: if the dialog throws for
    // any reason we must not crash the entire main shell. Worst case, the
    // user sees no recap modal that week.
    // Weekly recap firing flow — two gates:
    //   1. `weeklyRecapGateProvider` resolves to a meaningful recap
    //   2. `gymProfilesProvider` has resolved (i.e. home chrome has
    //      finished painting "Loading gym…"). Without (2), the 0.72-alpha
    //      barrier lands on top of a still-loading header, so the user
    //      sees a dimmed screen + a floating recap card and thinks the
    //      app is broken.
    //
    // Both gates live behind the same `_weeklyRecapFired` guard so we
    // fire exactly once per listener arm.
    Future<void> tryFireWeeklyRecap() async {
      if (_weeklyRecapFired) return;
      final recap = ref.read(weeklyRecapGateProvider);
      if (recap == null) return;
      final gymState = ref.read(gymProfilesProvider);
      if (gymState.isLoading) return; // wait for gym to resolve
      if (!context.mounted) return;
      final route = ModalRoute.of(context);
      if (route == null || route.isCurrent != true) return;
      _weeklyRecapFired = true;
      try {
        await showWeeklyRecapDialog(
          context: context,
          recap: recap,
          ref: ref,
        );
      } catch (e, st) {
        debugPrint('weeklyRecapDialog error: $e\n$st');
      }
    }

    ref.listen<WeeklyRecap?>(weeklyRecapGateProvider, (previous, next) {
      if (next == null || previous != null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) => tryFireWeeklyRecap());
    });

    // Re-arm when gym profiles transition from loading → data. Covers the
    // common case: recap arrives BEFORE gym loads, first attempt bails out,
    // then gym finishes and we fire.
    ref.listen<AsyncValue<List<GymProfile>>>(gymProfilesProvider, (prev, next) {
      if (prev?.isLoading == true && !next.isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) => tryFireWeeklyRecap());
      }
    });

    // Listen for streak-saved events (migration 1938 / W3).
    // Fires once when daily-login response flags that a Streak Shield was
    // auto-consumed to protect the streak. Celebrates the save instead of
    // silently swallowing it.
    ref.listen<DailyLoginResult?>(dailyLoginResultProvider, (previous, next) {
      if (next == null) return;
      final wasAlreadyShown = previous?.streakSavedByShield == true;
      if (next.streakSavedByShield && !wasAlreadyShown) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            showStreakSavedDialog(
              context,
              savedStreakCount: next.savedStreakCount > 0
                  ? next.savedStreakCount
                  : next.currentStreak,
              shieldsRemaining: next.shieldsRemaining,
            );
          }
        });
      }
    });

    // Use ValueKey to avoid GlobalKey conflicts when theme changes
    return Material(
      key: const ValueKey('main_shell_material'),
      color: backgroundColor,
      child: Stack(
        children: [
          // Main content with guest/offline banners
          Positioned.fill(
            child: Column(
              children: [
                // Guest mode banner at top
                if (isGuestMode)
                  _GuestModeBanner(isDark: isDark),
                // Offline banner (auto-shows/hides based on connectivity)
                const OfflineBanner(),
                // Verify-your-email nudge (auto-shows/hides; non-blocking)
                const EmailVerificationBanner(),
                // Main content fills remaining space. Wrapped in a
                Expanded(child: _child),
              ],
            ),
          ),
          // "Ask coach" FAB retired (2026-06 redesign, Change 1): the Coach
          // bottom-nav tab supersedes it — always reachable, never collapses
          // on scroll. Contextual chat deep links (coach hero card, active
          // workout, food tips) still push the /chat overlay unchanged.
          // Nav bar at bottom — wrapped in Material so it participates in
          // Flutter's elevation/z-index system. This ensures OS-level
          // Tooltips (which use the root overlay) render UNDER the nav,
          // and that any Stack child rendered above content can't visually
          // cover the nav by accident. ✅
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              elevation: 8,
              type: MaterialType.transparency,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                offset: isNavBarVisible ? Offset.zero : const Offset(0, 1.5),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isNavBarVisible ? 1.0 : 0.0,
                  child: _FloatingNavBarWithAI(
                    selectedIndex: selectedIndex,
                    isSecondaryPage: _isSecondaryPage(context),
                    onItemTapped: (index) => _onItemTapped(ref, context, index),
                  ),
                ),
              ),
            ),
          ),
          // Optional draggable chat-head bubble (Settings → AI Coach
          // opt-in). Default off — most users get the "Ask coach" FAB
          // above. Rendered AFTER the nav so its drag-dismiss-zone
          // overlay paints on top of the nav when active.
          if (isNavBarVisible && ref.watch(edgeHandleEnabledProvider))
            const FloatingChatBubble(),
          // Note: Workout mini player is now handled globally in app.dart.
          // App tour overlay is ALSO mounted globally now (in app.dart's
          // MaterialApp.router builder Stack) — covering top-level routes
          // outside the shell (active workout, workout complete, /chat,
          // /stats, fasting body-status / guide). Removed from here to
          // avoid double-rendering the same controller state.
        ],
      ),
    );
  }

}

// ── Staggered tab prewarm ───────────────────────────────────────────────────
// Module-level guard so the prewarm schedules exactly once per signed-in user.
// MainShell is a ConsumerWidget and rebuilds frequently; re-scheduling the
// delayed waves on every rebuild would re-flood the network. Re-arms on a real
// user change (logout → login / account switch) so a fresh session re-warms.
String? _prewarmOwnerUserId;
bool _prewarmScheduled = false;

void _schedulePrewarm(WidgetRef ref, int activeIndex, String? userId) {
  if (userId != _prewarmOwnerUserId) {
    _prewarmOwnerUserId = userId;
    _prewarmScheduled = false; // fresh login → re-warm
  }
  if (_prewarmScheduled) return;
  _prewarmScheduled = true;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Wave 0 — the tab the user is actually on. Fired post-frame (off the
    // synchronous build path) so it gets the Dio sockets first.
    _warmTab(() => _warmActiveTab(ref, activeIndex, userId));
    // Wave 1 — the OTHER primary tabs' first-paint providers (~700ms later).
    Future.delayed(const Duration(milliseconds: 700), () {
      _warmTab(() => _warmOtherTabs(ref, userId));
    });
    // Wave 2 — heavier / below-the-fold surfaces: coach insight + nudges,
    // discover leaderboard, fasting, patterns extras, saved hub (~1.6s later).
    Future.delayed(const Duration(milliseconds: 1600), () {
      _warmTab(() => _warmSecondary(ref, userId));
    });
  });
}

/// Run a prewarm wave, swallowing any error. The delayed waves can fire after
/// MainShell unmounts (e.g. logout navigated away), where `ref.read` would
/// throw — that's harmless, so we ignore it rather than crash.
void _warmTab(void Function() body) {
  try {
    body();
  } catch (_) {
    // Shell torn down before the wave fired — nothing to warm.
  }
}

void _warmActiveTab(WidgetRef ref, int index, String? userId) {
  final hasUser = userId != null && userId.isNotEmpty;
  switch (index) {
    case 0: // Home — hero workout, workout list, nutrition, activity,
      // hydration, timeline, consistency, + the coach hero (insight + nudges,
      // often the first card so warmed in wave 0 not wave 2).
      ref.read(todayWorkoutProvider);
      ref.read(workoutsProvider);
      ref.read(dailyNutritionProvider(todayNutritionKey()));
      ref.read(nutritionMetaProvider);
      ref.read(dailyActivityProvider);
      ref.read(hydrationProvider);
      ref.read(timelineProvider);
      ref.read(consistencyProvider);
      ref.read(dailyCoachInsightProvider);
      ref.read(contextualNudgeProvider);
      if (hasUser) ref.read(habitsProvider(userId));
      break;
    case 1: // Workouts — hero workout, list, screen summary, synced history.
      ref.read(todayWorkoutProvider);
      ref.read(workoutsProvider);
      ref.read(workoutScreenSummaryProvider);
      ref.read(syncedWorkoutsProvider);
      break;
    case 2: // Coach — the daily insight feeds the briefing/greeting open
      // ladder, so it's the chat tab's first-paint dependency.
      ref.read(dailyCoachInsightProvider);
      ref.read(contextualNudgeProvider);
      break;
    case 3: // Nutrition — daily summary + preferences gate the first paint;
      // batch-cook events + upcoming schedules feed the Daily tab.
      ref.read(dailyNutritionProvider(todayNutritionKey()));
      ref.read(nutritionMetaProvider);
      ref.read(nutritionPreferencesProvider);
      if (hasUser) {
        ref.read(activeCookEventsProvider(userId));
        ref.read(upcomingSchedulesProvider(userId));
      }
      break;
    case 4: // You / Profile — XP state + unclaimed-crates badge.
      ref.read(xpProvider);
      ref.read(unclaimedCratesCountProvider);
      break;
  }
}

/// Wave 1 — the primary first-paint providers of every main tab. `ref.read` is
/// idempotent, so re-reading whatever the active tab already warmed is a cheap
/// no-op (no second notifier, no refetch).
void _warmOtherTabs(WidgetRef ref, String? userId) {
  ref.read(todayWorkoutProvider);
  ref.read(workoutsProvider);
  ref.read(dailyNutritionProvider(todayNutritionKey()));
  ref.read(nutritionMetaProvider);
  ref.read(dailyActivityProvider);
  ref.read(hydrationProvider);
  ref.read(timelineProvider);
  ref.read(consistencyProvider);
  ref.read(workoutScreenSummaryProvider);
  ref.read(syncedWorkoutsProvider);
  ref.read(nutritionPreferencesProvider);
  ref.read(xpProvider);
  ref.read(unclaimedCratesCountProvider);
  if (userId != null && userId.isNotEmpty) {
    ref.read(habitsProvider(userId));
    ref.read(activeCookEventsProvider(userId));
    ref.read(upcomingSchedulesProvider(userId));
  }
}

/// Wave 2 — heavier / below-the-fold surfaces that aren't needed for any
/// tab's above-the-fold first paint.
void _warmSecondary(WidgetRef ref, String? userId) {
  ref.read(dailyCoachInsightProvider);
  ref.read(contextualNudgeProvider);
  ref.read(discoverSnapshotProvider);
  if (userId != null && userId.isNotEmpty) {
    // fastingProvider needs an explicit initialize() — a bare read just
    // constructs an empty notifier.
    unawaited(ref.read(fastingProvider.notifier).initialize(userId));
    ref.read(foodPatternsMoodProvider(userId));
    ref.read(patternsSettingsProvider(userId));
    ref.read(favoriteRecipesProvider(userId));
    ref.read(savedFoodsHubProvider(userId));
    ref.read(savedMenusHubProvider);
  }
}

/// Helper to get contrast color for a given background
Color _getContrastColor(Color background) {
  // Calculate luminance - if > 0.5, use black text, otherwise white
  final luminance = background.computeLuminance();
  return luminance > 0.5 ? Colors.black : Colors.white;
}

// _CoachFabScrollListener removed with the Coach FAB (2026-06 redesign,
// Change 1) — the Coach bottom-nav tab replaced the scroll-aware FAB, so the
// pill↔icon morph driver had nothing left to drive.
