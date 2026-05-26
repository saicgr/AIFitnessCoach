import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_colors.dart';
import '../core/providers/serious_mode_provider.dart';
import '../core/providers/subscription_provider.dart';
import '../data/services/recipe_notification_router.dart';
import '../core/theme/theme_colors.dart';
import '../data/models/coach_persona.dart';
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
import 'coach_floating_button.dart';
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
import '../data/repositories/nutrition_repository.dart' show nutritionProvider;
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

part 'main_shell_part_edge_panel_handle.dart';
part 'main_shell_part_guest_mode_banner.dart';


/// Provider to control floating nav bar visibility
final floatingNavBarVisibleProvider = StateProvider<bool>((ref) => true);

/// Provider to control whether nav bar labels are expanded
/// Set to false when on secondary pages (Workouts, Nutrition, Fasting)
final navBarLabelsExpandedProvider = StateProvider<bool>((ref) => true);

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

  const MainShell({super.key, this.navigationShell, this.child})
      : assert(navigationShell != null || child != null,
            'Either navigationShell or child must be provided');

  /// The widget to display as the main content area.
  Widget get _child => navigationShell ?? child!;

  int _calculateSelectedIndex(BuildContext context) {
    if (navigationShell != null) return navigationShell!.currentIndex;
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/workouts')) return 1;
    if (location.startsWith('/nutrition')) return 2;
    if (location.startsWith('/profile')) return 3;
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
    // Surface 1.8 — FAB defaults to collapsed; the idle-at-top expansion
    // timer in `_CoachFabScrollListener` re-extends after 800ms when the
    // user lands on Home at scroll position 0. Reset to collapsed on every
    // tab switch so the previous tab's expanded state doesn't leak.
    final fab = ref.read(coachFabExpandedProvider.notifier);
    if (fab.state) fab.state = false;
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
        context.go('/nutrition');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final isNavBarVisible = ref.watch(floatingNavBarVisibleProvider);
    final isGuestMode = ref.watch(isGuestModeProvider);

    // ── Tab prewarm ──────────────────────────────────────────────────
    // Warm every tab's first-paint data providers in the background so
    // switching tabs (and landing on Home) paints from cache instead of a
    // cold network skeleton. Each provider below is a StateNotifier / a
    // derived Provider / an autoDispose provider that calls keepAlive(), so
    // a bare `ref.read` constructs it, kicks off its fetch, and the result
    // is retained for when the tab actually opens. `ref.read` is idempotent
    // — re-running this block on every rebuild is a cheap no-op (no second
    // notifier, no refetch), so no one-time guard is needed and a re-login
    // (fresh MainShell) re-warms correctly.

    // Home tab — hero workout, full workout list, daily nutrition, health
    // activity, hydration, today's timeline, weekly consistency.
    ref.read(todayWorkoutProvider);
    ref.read(workoutsProvider);
    ref.read(nutritionProvider);
    ref.read(dailyActivityProvider);
    ref.read(hydrationProvider);
    ref.read(timelineProvider);
    ref.read(consistencyProvider);
    // Workouts tab — screen summary header + synced-workout history.
    ref.read(workoutScreenSummaryProvider);
    ref.read(syncedWorkoutsProvider);
    // Nutrition tab — preferences gate the daily tab's first paint.
    ref.read(nutritionPreferencesProvider);
    // Discover tab — kept-alive leaderboard snapshot; its notifier load()s
    // on creation.
    ref.read(discoverSnapshotProvider);
    // You tab — XP / rewards state + unclaimed-crates badge count.
    ref.read(xpProvider);
    ref.read(unclaimedCratesCountProvider);

    // Providers keyed by (or initialized with) the signed-in user id.
    final prewarmUserId = ref.read(authStateProvider).user?.id;
    if (prewarmUserId != null && prewarmUserId.isNotEmpty) {
      // fastingProvider's notifier needs an explicit initialize() — a bare
      // read just constructs an empty notifier.
      unawaited(ref.read(fastingProvider.notifier).initialize(prewarmUserId));
      // Home habits section — userId-family StateNotifier.
      ref.read(habitsProvider(prewarmUserId));
      // Nutrition · Daily tab — batch-cook events.
      ref.read(activeCookEventsProvider(prewarmUserId));
      // Nutrition · Recipes sub-tab — upcoming meal schedules.
      ref.read(upcomingSchedulesProvider(prewarmUserId));
      // Nutrition · Patterns sub-tab — the two single-entry (userId-keyed)
      // providers. The range/date-keyed ones (macros/topFoods/history)
      // re-key as the user scrubs, so they load on first tab open.
      ref.read(foodPatternsMoodProvider(prewarmUserId));
      ref.read(patternsSettingsProvider(prewarmUserId));
      // Nutrition · Saved hub — recipes/foods/menus. All keepAlive(), so
      // warming them here makes the first open of the Saved hub instant.
      ref.read(favoriteRecipesProvider(prewarmUserId));
      ref.read(savedFoodsHubProvider(prewarmUserId));
      ref.read(savedMenusHubProvider);
    }

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
                // NotificationListener that drives the Coach FAB's
                // expand/collapse: when the active tab's scroll view
                // is at the top, the FAB stays extended; once it
                // scrolls past 24pt the FAB collapses to icon-only.
                // Drives the Coach FAB's pill-vs-icon morph on the Home
                // tab — extended at scroll top, collapses to icon past
                // 24pt. Other tabs ignore this state (always icon).
                // setState only on threshold-cross, not per frame.
                Expanded(
                  // Surface 1.8 — scroll-aware FAB driver. Any scroll
                  // collapses the FAB immediately; the FAB re-expands to
                  // the "Ask coach" pill only after the user has been
                  // idle at scroll position 0 for 800ms.
                  child: _CoachFabScrollListener(child: _child),
                ),
              ],
            ),
          ),
          // "Ask coach" FAB above the nav — Home tab only. On Home
          // there's no sub-tab strip, so the pill+icon morph lives
          // standalone above the nav. On every other tab, the AI sparkle
          // action is integrated INTO that tab's `FloatingTabBar` strip
          // (see `_FloatingTabBarCoachSlot`), so the standalone FAB
          // would just double up. Hides when the nav hides
          // (e.g. `/fasting`).
          if (isNavBarVisible && selectedIndex == 0)
            const CoachFloatingButton(isHomeTab: true),
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

/// Helper to get contrast color for a given background
Color _getContrastColor(Color background) {
  // Calculate luminance - if > 0.5, use black text, otherwise white
  final luminance = background.computeLuminance();
  return luminance > 0.5 ? Colors.black : Colors.white;
}

/// Surface 1.8 — scroll-aware driver for the Coach FAB's pill ↔ icon morph.
///
/// Default state: collapsed (icon-only). The FAB expands to "Ask coach"
/// only after the user idles at scroll position 0 for 800ms; any scroll
/// motion collapses it instantly. Implements the
/// `coachFabExpandedProvider` writes on behalf of the parent shell.
class _CoachFabScrollListener extends ConsumerStatefulWidget {
  final Widget child;
  const _CoachFabScrollListener({required this.child});

  @override
  ConsumerState<_CoachFabScrollListener> createState() =>
      _CoachFabScrollListenerState();
}

class _CoachFabScrollListenerState
    extends ConsumerState<_CoachFabScrollListener> {
  Timer? _idleTimer;

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  void _scheduleExpand() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      final notifier = ref.read(coachFabExpandedProvider.notifier);
      if (!notifier.state) notifier.state = true;
    });
  }

  void _collapseImmediate() {
    _idleTimer?.cancel();
    final notifier = ref.read(coachFabExpandedProvider.notifier);
    if (notifier.state) notifier.state = false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.depth != 0) return false;
        final pixels = notification.metrics.pixels;
        final atTop = pixels < 24;
        if (notification is ScrollEndNotification) {
          if (atTop) {
            _scheduleExpand();
          } else {
            _collapseImmediate();
          }
        } else if (notification is ScrollUpdateNotification ||
            notification is ScrollStartNotification ||
            notification is UserScrollNotification) {
          // Any scroll motion: collapse immediately and cancel any
          // pending re-expand timer. The expand only fires after the
          // user has STOPPED scrolling at the top for 800ms.
          _collapseImmediate();
        }
        return false;
      },
      child: widget.child,
    );
  }
}
