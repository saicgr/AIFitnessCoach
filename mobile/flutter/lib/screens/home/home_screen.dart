import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/fasting_ongoing_notification_service.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../core/accessibility/accessibility_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/chrome_constants.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/providers/window_mode_provider.dart';
import '../../core/providers/workout_mini_player_provider.dart';
import '../../data/models/home_layout.dart';
import '../../data/providers/home_layout_provider.dart';
import '../../data/services/home_prewarmer.dart';
import 'refresh_home.dart';
import '../../data/providers/local_layout_provider.dart';
import '../../data/providers/coach_refresh_coordinator.dart';
import '../../data/providers/secondary_tile_providers.dart';
import '../../data/services/haptic_service.dart';
import '../../data/providers/branded_program_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/first_run/first_run_gate.dart';
import '../../data/models/workout.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/providers/today_workout_provider.dart';
import '../../data/providers/home_sections_provider.dart';
import '../../data/providers/contextual_nudge_provider.dart';
import '../../data/models/contextual_nudge.dart' show NudgePriorityTier;
import '../../data/providers/hormonal_health_provider.dart';
import '../../data/providers/fasting_provider.dart';
import 'widgets/cycle_setup_home_prompt.dart';
import '../../data/services/deep_link_service.dart';
import '../../data/services/health_service.dart';
import '../../widgets/glass_sheet.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/main_shell.dart';
import '../../widgets/pill_swipe_navigation.dart';
import '../nutrition/log_meal_sheet.dart';
import '../onboarding/notification_prime_screen.dart';
import '../onboarding/permissions_primer_screen.dart';
import 'widgets/components/components.dart';
import 'widgets/cards/cards.dart';
import 'widgets/daily_activity_card.dart';
import 'widgets/edit_tracking_sheet.dart';
import 'widgets/stacked_banner_panel.dart';
import 'widgets/calibration_banner.dart';
import 'widgets/cards/setup_checklist_card.dart';
import 'widgets/my_programs_card.dart';
import 'widgets/today_addons_row.dart';
import 'widgets/extended_home_cards_stack.dart';
import '../../widgets/rating_prompt_banner.dart';
import 'widgets/tile_factory.dart';
import 'widgets/today_score_card.dart';
import 'widgets/coach_hero_card.dart';
import 'widgets/readiness_tile.dart';
// StrainCoachCard was folded into the workout-hero meta line as a tier chip
// (see `_WorkoutHeroIntensityLine` in unified_home_widgets.dart). The widget
// itself stays in `widgets/strain_coach_card.dart` for the rationale detail
// screen, but the home screen no longer renders it.
import 'widgets/score_change_announcement_sheet.dart';
import 'widgets/my_program_summary_card.dart';
import 'widgets/hero_workout_card.dart';
import 'widgets/hero_fasting_card.dart';
import '../../core/providers/week_start_provider.dart';
import 'widgets/hero_workout_carousel.dart';
import 'widgets/home/unified_home_widgets.dart';
import 'widgets/home/metric_summary_deck.dart';
import 'widgets/home/home_metrics_strip.dart';
import 'widgets/home/home_timeline.dart';
import 'widgets/home/reports_recap_row.dart';
import 'widgets/swipeable_hero_section.dart' show HomeFocus, homeFocusProvider;
import 'widgets/workout_category_pills.dart';
import 'widgets/habits_section.dart';
import 'widgets/cards/cycle_summary_card.dart';
import 'widgets/body_metrics_section.dart';
import 'widgets/achievements_section.dart';
import '../../data/providers/consistency_provider.dart';
import '../../data/providers/xp_provider.dart' as xp_provider;
import '../../data/providers/xp_provider.dart'
    show
        xpProvider,
        xpCurrentStreakProvider,
        streakMilestoneProvider,
        xpEarnedEventProvider,
        XPEarnedAnimationEvent,
        coachBannerEventProvider,
        CoachBannerEvent,
        CoachBannerKind;
import '../ai_settings/ai_settings_screen.dart' show aiSettingsProvider;
import '../../data/models/coach_persona.dart';
import '../../widgets/coach_banner_overlay.dart';
import '../../data/models/user_xp.dart';
import '../../widgets/level_up_dialog.dart';
import '../../widgets/streak_milestone_dialog.dart';
import '../../widgets/xp_earned_animation.dart';
import '../../data/models/level_reward.dart';
import 'widgets/minimal_header.dart';
import '../../widgets/health_connect_sheet.dart';
import '../../data/providers/health_import_provider.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../data/repositories/hydration_repository.dart';
import '../../data/providers/nutrition_preferences_provider.dart';
import '../../data/providers/quick_action_provider.dart';
import '../settings/sections/nutrition_fasting_section.dart';
import '../../widgets/usage_counter_strip.dart';
import '../../widgets/app_tour/app_tour_controller.dart';
import '../../core/services/posthog_service.dart';
import '../../core/services/fitness_snapshot_service.dart';
import '../../core/perf/perf_trace.dart';
import 'package:fitwiz/core/constants/branding.dart';
import '../../l10n/generated/app_localizations.dart';

part 'home_screen_part_dummy_animation_controller.dart';

part 'home_screen_ui_1.dart';
part 'home_screen_ui_2.dart';
part 'home_screen_ui_3.dart';

part 'home_screen_ui.dart';

/// The main home screen displaying workouts, progress, and quick actions
class HomeScreen extends ConsumerStatefulWidget {
  final bool startEditMode;

  const HomeScreen({super.key, this.startEditMode = false});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with
        SingleTickerProviderStateMixin,
        ResponsiveMixin,
        WidgetsBindingObserver,
        PillSwipeNavigationMixin {
  // PillSwipeNavigationMixin: Home is index 0 (For You)
  @override
  int get currentPillIndex => 0;

  bool _isInitializing = true; // True until first workout check completes
  bool _isCheckingWorkouts = false;
  bool _isStreamingGeneration = false;

  final Completer<void> _initCompleter = Completer<void>();
  String? _generationStartDate;
  int _generationWeeks = 0;
  int _totalExpected = 0;
  int _totalGenerated = 0;
  String _generationMessage = '';
  String? _generationDetail;

  // Week calendar strip state
  late PageController _carouselPageController;
  int _selectedWeekDay = DateTime.now().weekday - 1; // 0=Mon
  List<CarouselItem> _carouselItems = [];

  // Auto-refresh tracking
  DateTime? _lastRefreshTime;

  @Deprecated('Edit mode has been removed')
  bool _isEditMode = false;
  @Deprecated('Edit mode has been removed')
  List<dynamic> _editingTiles = [];
  @Deprecated('Edit mode has been removed')
  static const String _editModeTooltipKey = 'has_shown_edit_mode_tooltip';
  @Deprecated('Edit mode has been removed')
  late final _wiggleController = _DummyAnimationController();
  static const Duration _minRefreshInterval = Duration(minutes: 5);

  /// Ensures the Health Connect popup auto-shows at most once per app session.
  static bool _healthPopupShownThisSession = false;

  /// Ensures the "What's New" spotlight is checked at most once per app session
  /// (the persistent seen-once flag lives in AppTourController).
  static bool _whatsNewCheckedThisSession = false;

  /// Perf markers (Phase B hook): guards so each PerfTrace mark fires exactly
  /// once. `_markedFirstContent` flips the first time `build()` runs with real
  /// (non-skeleton) content; `_markedInteractive` flips once init completes.
  bool _markedFirstContent = false;
  bool _markedInteractive = false;

  void _triggerNavTour() {
    final l10n = AppLocalizations.of(context)!;
    final steps = [
      // NOTE: the former 'nav_step_topbar' ("Your Profile") step was removed —
      // it ringed the whole masthead, which no longer holds a profile element
      // (the avatar moved to the You tab, covered by 'nav_step_profile' below).
      // It read as a wrong/mis-targeted tooltip, so the tour now starts on the
      // workout carousel. Step count is derived from this list → cards show N/5.
      AppTourStep(
        id: 'nav_step_carousel',
        targetKey: AppTourKeys.heroCarouselKey,
        title: l10n.homeScreenTourCarouselTitle,
        description: l10n.homeScreenTourCarouselDesc,
        position: TooltipPosition.below,
      ),
      AppTourStep(
        id: 'nav_step_quicklog',
        targetKey: AppTourKeys.quickLogKey,
        title: l10n.homeScreenTourQuicklogTitle,
        description: l10n.homeScreenTourQuicklogDesc,
        position: TooltipPosition.above,
        // Animated glow ring (instead of the flat solid ring) so the small "+"
        // FAB clearly reads as the highlighted target. Warm hues match the
        // FAB's orange accent border.
        highlightColors: const [
          AppColors.orange,
          AppColors.orangeLight,
          AppColors.yellow,
        ],
      ),
      AppTourStep(
        id: 'nav_step_workout',
        targetKey: AppTourKeys.workoutNavKey,
        title: l10n.homeScreenTourWorkoutTitle,
        description: l10n.homeScreenTourWorkoutDesc,
        position: TooltipPosition.above,
      ),
      AppTourStep(
        id: 'nav_step_nutrition',
        targetKey: AppTourKeys.nutritionNavKey,
        title: l10n.homeScreenTourNutritionTitle,
        description: l10n.homeScreenTourNutritionDesc,
        position: TooltipPosition.above,
      ),
      AppTourStep(
        id: 'nav_step_profile',
        targetKey: AppTourKeys.profileNavKey,
        title: l10n.homeScreenTourProfileTitle,
        description: l10n.homeScreenTourProfileDesc,
        position: TooltipPosition.above,
      ),
    ];
    ref
        .read(appTourControllerProvider.notifier)
        .checkAndShow('nav_tour', steps);
  }

  @override
  void initState() {
    super.initState();
    _extInitState();
  }

  @override
  void dispose() {
    _carouselPageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Called when app lifecycle state changes (resume, pause, etc.)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // The lifecycle observer can fire AFTER the State is disposed (the OS
    // delivers a final `paused`/`resumed` event during teardown, while
    // `removeObserver` is processed in dispose). `mounted` alone isn't
    // sufficient — Riverpod's ProviderScope can be torn down independently
    // of the State lifecycle, throwing "Bad state: No ProviderScope found".
    // Wrap the entire body in try/catch so the lifecycle event is silently
    // dropped if scope is gone.
    if (!mounted) return;
    if (state != AppLifecycleState.resumed) return;
    try {
      // Replay any fasting notification action (Pause/Resume, End Fast) that
      // fired in the background isolate while the app was not foregrounded.
      FastingOngoingNotificationService.instance.drainPendingBackgroundAction();
      // Auto-refresh when returning to app (with rate limiting). It has its
      // own internal guards but a defensive try here means any escape from
      // those guards still doesn't crash the app.
      _autoRefreshIfNeeded();
      // Pull latest CustomerInfo from RevenueCat so subscription state
      // reflects any out-of-app changes the user made (e.g. cancelling
      // from Google Play's Subscriptions page while the app was
      // backgrounded). Internally 30s-debounced — safe to fire often.
      unawaited(
        ref.read(subscriptionProvider.notifier).refreshFromRevenueCat(),
      );
      // Re-fetch XP on resume so the level ring updates when a workout the
      // user completed on another device (or via a background process)
      // bumped their total — without forcing them to pull-to-refresh.
      unawaited(ref.read(xpProvider.notifier).loadUserXP(showLoading: false));
    } catch (e) {
      debugPrint('⚠️ [Home] lifecycle resume skipped post-dispose: $e');
    }
  }

  /// Called when this widget becomes visible again (e.g., navigating back)
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Auto-refresh when screen becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _autoRefreshIfNeeded();
      if (!mounted) return;

      // First-run popup-storm guard. A brand-new (just-onboarded) account has no
      // prior app version, so "What's New" / score-change announcements are
      // meaningless to them — pre-mark them seen and show NOTHING here. Only a
      // returning user sees version-update modals, and they run one-at-a-time
      // through FirstRunModalQueue so they never stack.
      final user = ref.read(authStateProvider).user;
      if (FirstRunGate.isFreshAccount(user)) {
        await FirstRunGate.markVersionAnnouncementsSeenForFreshUser();
        return;
      }

      // One-shot: explain the v2 score redesign (Sleep added as 4th
      // contributor). No-op after the first show.
      if (mounted) {
        FirstRunModalQueue.enqueue(
          () => maybeShowScoreChangeAnnouncement(context),
        );
      }
      // One-shot: the Gravl-parity redesign "What's New" spotlight.
      if (mounted) {
        FirstRunModalQueue.enqueue(() => _maybeShowWhatsNew());
      }
    });
  }

  /// Show the "What's New" spotlight carousel once after the redesign ships.
  /// Session-guarded (avoids re-hitting prefs on every nav back to home) and
  /// persistently gated via [AppTourController]. No-op once seen.
  Future<void> _maybeShowWhatsNew() async {
    if (_whatsNewCheckedThisSession) return;
    _whatsNewCheckedThisSession = true;
    try {
      final controller = ref.read(appTourControllerProvider.notifier);
      if (await controller.hasSeenWhatsNew()) return;
      if (!mounted) return;
      // Don't stack over an active coach-mark tour.
      if (ref.read(appTourControllerProvider).isVisible) return;
      await controller.markWhatsNewSeen();
      if (!mounted) return;
      // Await the push so the FirstRunModalQueue only advances once the
      // What's New carousel is dismissed (no stacking with the next modal).
      await context.push('/whats-new');
    } catch (e) {
      debugPrint('⚠️ [Home] What\'s New spotlight skipped: $e');
    }
  }

  /// Auto-refresh workouts if enough time has passed since last refresh
  /// M13: Uses 5-minute interval and sets _lastRefreshTime at start to prevent double-refreshes
  /// L9: Only invalidates workoutsProvider after a successful refresh (staleness check)
  Future<void> _autoRefreshIfNeeded() async {
    if (!mounted) return;

    final now = DateTime.now();
    if (_lastRefreshTime == null ||
        now.difference(_lastRefreshTime!) > _minRefreshInterval) {
      // M13: Set time at start to prevent concurrent/double-refreshes
      _lastRefreshTime = now;
      debugPrint('🔄 [Home] Auto-refreshing workouts...');

      // Wrap every `ref.read` so a teardown that races with this lifecycle
      // path (Riverpod scope already gone) doesn't crash the app — the
      // refresh just no-ops, the next foreground will pick it up. This
      // mirrors the guard added to didChangeAppLifecycleState above.
      try {
        // User refresh + workouts refresh + health-connect refresh are
        // independent — fire them in parallel so the resume path is
        // bounded by the slowest single call instead of summing all three.
        // refreshUser() and refreshConnectionStatus() return Futures that
        // we await alongside the workouts refresh; nutrition stays
        // fire-and-forget because it has its own silent-refresh contract.
        final workoutsNotifier = ref.read(workoutsProvider.notifier);
        final futures = <Future<dynamic>>[
          Future.sync(() => ref.read(authStateProvider.notifier).refreshUser()),
          workoutsNotifier.refresh(),
          Future.sync(
            () =>
                ref.read(healthSyncProvider.notifier).refreshConnectionStatus(),
          ),
        ];
        await Future.wait(futures, eagerError: false);

        // Check mounted after async operation
        if (!mounted) return;

        // Refresh the kept-alive secondary tiles (metric deck, home insights/
        // patterns, achievement + content rows) on resume. They don't refetch
        // on their own because they're keepAlive'd, so a long background gap
        // (incl. crossing midnight) would otherwise leave them stale. The
        // tz-sensitive combinedHealth disk key returns a date-miss on rollover,
        // so the refetch picks up "today" rather than re-serving yesterday.
        for (final p in secondaryTileProviders) {
          ref.invalidate(p);
        }

        // Refresh the coach card's graph numbers on resume (cheap, no Gemini)
        // so a return-from-background reflects anything logged elsewhere — and,
        // importantly, the overnight Health-Connect sleep import that runs just
        // below in `_checkForWorkoutImports()`. The sleep-value change also
        // trips the coordinator's sleep listener, which regenerates the text.
        ref.read(coachRefreshCoordinatorProvider).bumpNumbers();

        // L9: The refresh() call above already updates provider state internally,
        // so we avoid a redundant ref.invalidate(workoutsProvider) which would
        // trigger an unnecessary full re-fetch.

        // Refresh nutrition & hydration data silently (no loading flash) —
        // fire-and-forget so the resume path doesn't wait on it.
        _refreshNutritionSilent();

        // Check for new workout imports from Health Connect on resume
        _checkForWorkoutImports();
      } catch (e) {
        debugPrint('⚠️ [Home] auto-refresh skipped (scope unavailable): $e');
      }
    }
  }

  /// Auto-show Health Connect popup if not connected and not recently dismissed.
  /// Waits until the home screen has fully loaded (todayWorkoutProvider resolved)
  /// so it doesn't overlay the loading screen.
  Future<void> _maybeShowHealthConnectPopup() async {
    if (_healthPopupShownThisSession) return;

    // Wait until workout init finishes (Completer instead of polling)
    await _initCompleter.future;
    if (!mounted) return;

    // Wait until todayWorkoutProvider has resolved (data or error, not loading)
    // Uses a listener instead of polling for instant response
    if (ref.read(todayWorkoutProvider).isLoading) {
      final completer = Completer<void>();
      final sub = ref.listenManual(todayWorkoutProvider, (prev, next) {
        if (!next.isLoading && !completer.isCompleted) completer.complete();
      });
      await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {},
      );
      sub.close();
    }

    // Small delay so the home content renders after provider resolves
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    // Wait for the onboarding tour to finish if it's currently showing —
    // otherwise the modal-bottom-sheet barrier scrims the tooltip and the
    // two overlays collide visually (light-mode tooltip becomes unreadable).
    if (ref.read(appTourControllerProvider).isVisible) {
      final completer = Completer<void>();
      final sub = ref.listenManual(appTourControllerProvider, (prev, next) {
        if (!next.isVisible && !completer.isCompleted) completer.complete();
      });
      await completer.future;
      sub.close();
      if (!mounted) return;
      // Brief breathing room after the tour closes before opening the sheet.
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
    }

    // Check SharedPreferences directly to avoid race condition with
    // HealthSyncNotifier's async _loadSyncState() not completing yet
    final prefs = await SharedPreferences.getInstance();
    final storedConnected = prefs.getBool('health_connected') ?? false;
    if (storedConnected) return;

    // Also check provider state in case it was updated this session
    final syncState = ref.read(healthSyncProvider);
    if (syncState.isConnected) return;

    final suppressed = await isHealthConnectPopupSuppressed();
    if (suppressed || !mounted) return;

    _healthPopupShownThisSession = true;
    // Through the queue so it never stacks on a What's New / level-up modal.
    await FirstRunModalQueue.enqueue(
      () => showHealthConnectSheet(context, ref),
    );
  }

  /// Check Health Connect for unimported workout sessions and auto-import them.
  /// Delayed 800ms to let the UI render first. Skips if HC not connected.
  Future<void> _checkForWorkoutImports() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final syncState = ref.read(healthSyncProvider);
    if (!syncState.isConnected) return;

    await ref.read(healthImportProvider.notifier).checkForUnimportedWorkouts();
    if (!mounted) return;

    final importState = ref.read(healthImportProvider);
    if (importState.pendingImports.isEmpty) return;

    // Auto-import all detected workouts
    final count = await ref.read(healthImportProvider.notifier).autoImportAll();
    if (!mounted) return;

    if (count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.homeScreenImportedWorkouts(count),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          // Gap 4 — auto-detected workouts import frictionlessly, but the user
          // can still confirm/correct a misdetection (type/duration) from the
          // workouts list. Keeps the effortless default + an editable path.
          action: SnackBarAction(
            label: 'Review',
            onPressed: () {
              if (mounted)
                context.go(
                  '/workouts',
                ); // branch-root: go, not push (dup-GlobalKey)
            },
          ),
        ),
      );
    }
  }

  /// Map XPGoalType from provider to animation widget enum
  XPGoalType _mapXPGoalType(xp_provider.XPGoalType type) {
    switch (type) {
      case xp_provider.XPGoalType.dailyLogin:
        return XPGoalType.dailyLogin;
      case xp_provider.XPGoalType.weightLog:
        return XPGoalType.weightLog;
      case xp_provider.XPGoalType.mealLog:
        return XPGoalType.mealLog;
      case xp_provider.XPGoalType.workoutComplete:
        return XPGoalType.workoutComplete;
      case xp_provider.XPGoalType.proteinGoal:
        return XPGoalType.proteinGoal;
      case xp_provider.XPGoalType.bodyMeasurements:
        return XPGoalType.bodyMeasurements;
      case xp_provider.XPGoalType.stepsGoal:
        return XPGoalType.stepsGoal;
      case xp_provider.XPGoalType.hydrationGoal:
        return XPGoalType.hydrationGoal;
      case xp_provider.XPGoalType.calorieGoal:
        return XPGoalType.calorieGoal;
      case xp_provider.XPGoalType.cycleLogged:
        return XPGoalType.cycleLogged;
    }
  }

  void _enterEditMode() async {
    final layout = ref.read(activeLayoutProvider).value;

    // If layout is null or empty, create default tiles
    List<HomeTile> tilesToEdit;
    if (layout != null && layout.tiles.isNotEmpty) {
      tilesToEdit = List.from(layout.tiles);
    } else {
      // Create default tiles for editing
      final defaultTileTypes = [
        TileType.fitnessScore,
        TileType.moodPicker,
        TileType.dailyActivity,
        TileType.nextWorkout,
        // Quick actions removed - now accessible via + button in nav bar
        TileType.weekChanges,
        TileType.weeklyProgress,
        TileType.weeklyGoals,
        TileType.upcomingWorkouts,
        TileType.aiCoachTip,
      ];
      tilesToEdit = defaultTileTypes.asMap().entries.map((entry) {
        return HomeTile(
          id: 'tile_${entry.key}',
          type: entry.value,
          order: entry.key,
          isVisible: true,
          size: entry.value.defaultSize,
        );
      }).toList();
    }

    setState(() {
      _isEditMode = true;
      _editingTiles = tilesToEdit;
    });
    _wiggleController.repeat(reverse: true);
    HapticService.medium();

    // Show one-time tooltip/coach mark for edit mode
    await _showEditModeTooltipIfNeeded();
  }

  /// Shows a one-time tooltip explaining edit mode features
  Future<void> _showEditModeTooltipIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool(_editModeTooltipKey) ?? false;

    if (!hasShown && mounted) {
      // Mark as shown immediately to prevent multiple displays
      await prefs.setBool(_editModeTooltipKey, true);

      // Show the tooltip dialog
      _showEditModeCoachMark();
    }
  }

  void _exitEditMode({bool save = true}) async {
    _wiggleController.stop();
    _wiggleController.reset();

    if (save && _editingTiles.isNotEmpty) {
      // Save the updated tiles (casting is safe since this dead code is never executed)
      await ref
          .read(activeLayoutProvider.notifier)
          .updateTiles(_editingTiles.cast<HomeTile>());
      HapticService.success();
    }

    setState(() {
      _isEditMode = false;
      _editingTiles = [];
    });
  }

  void _onReorderTiles(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final tile = _editingTiles.removeAt(oldIndex);
      _editingTiles.insert(newIndex, tile);
      // Update order values
      for (int i = 0; i < _editingTiles.length; i++) {
        _editingTiles[i] = _editingTiles[i].copyWith(order: i);
      }
    });
    HapticService.light();
  }

  void _toggleTileVisibility(String tileId) {
    setState(() {
      final index = _editingTiles.indexWhere((t) => t.id == tileId);
      if (index != -1) {
        _editingTiles[index] = _editingTiles[index].copyWith(
          isVisible: !_editingTiles[index].isVisible,
        );
      }
    });
    HapticService.light();
  }

  void _cycleTileSize(String tileId) {
    setState(() {
      final index = _editingTiles.indexWhere((t) => t.id == tileId);
      if (index != -1) {
        final tile = _editingTiles[index];
        final supportedSizes = tile.type.supportedSizes;
        if (supportedSizes.length > 1) {
          final currentIndex = supportedSizes.indexOf(tile.size);
          final nextIndex = (currentIndex + 1) % supportedSizes.length;
          _editingTiles[index] = tile.copyWith(size: supportedSizes[nextIndex]);
        }
      }
    });
    HapticService.medium();
  }

  void _addTile(TileType type) {
    setState(() {
      final newTile = HomeTile(
        id: 'tile_${DateTime.now().millisecondsSinceEpoch}',
        type: type,
        size: type.defaultSize,
        order: _editingTiles.length,
        isVisible: true,
      );
      _editingTiles.add(newTile);
    });
    HapticService.success();
  }

  void _applyPreset(LayoutPreset preset) {
    Navigator.pop(context); // Close the sheet

    // Show confirmation dialog
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: elevatedColor,
        title: Row(
          children: [
            Icon(preset.icon, color: preset.color, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppLocalizations.of(
                  context,
                )!.homeScreenApplyPreset(preset.name),
                style: TextStyle(color: textPrimary, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          AppLocalizations.of(context)!.homeScreenApplyPresetBody(preset.name),
          style: TextStyle(
            color: isDark
                ? AppColors.textSecondary
                : AppColorsLight.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppLocalizations.of(context)!.homeScreenCancel,
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondary
                    : AppColorsLight.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Apply preset to local layout (tiles only, header is always minimal)
              await ref.read(localLayoutProvider.notifier).applyPreset(preset);
              // Match the hero carousel to the preset's focus so a user who
              // picks "Nutrition Focus" lands on the Nutrition hero, not the
              // workout one.
              if (preset.isNutritionFocused) {
                ref.read(homeFocusProvider.notifier).state =
                    HomeFocus.nutrition;
              } else {
                ref.read(homeFocusProvider.notifier).state = HomeFocus.workout;
              }
              HapticService.success();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(
                        context,
                      )!.homeScreenPresetApplied(preset.name),
                    ),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.homeScreenApply),
          ),
        ],
      ),
    );
  }

  void _resetToDefaultLayout() {
    Navigator.pop(context); // Close the sheet

    // Show confirmation dialog
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: elevatedColor,
        title: Row(
          children: [
            Icon(Icons.restart_alt_rounded, color: AppColors.orange, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.homeScreenResetToDefault,
                style: TextStyle(color: textPrimary, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          AppLocalizations.of(context)!.homeScreenResetToDefaultBody,
          style: TextStyle(
            color: isDark
                ? AppColors.textSecondary
                : AppColorsLight.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppLocalizations.of(context)!.homeScreenCancel,
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondary
                    : AppColorsLight.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Find and apply the Minimalist preset
              final minimalistPreset = layoutPresets.firstWhere(
                (p) => p.id == 'minimalist',
              );
              await ref
                  .read(localLayoutProvider.notifier)
                  .applyPreset(minimalistPreset);
              HapticService.success();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.homeScreenDefaultRestored,
                    ),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.homeScreenReset),
          ),
        ],
      ),
    );
  }

  void _checkPendingWidgetAction() {
    final pendingAction = ref.read(pendingWidgetActionProvider);
    debugPrint('HomeScreen: Checking pending action: $pendingAction');
    if (pendingAction == PendingWidgetAction.showLogMealSheet) {
      // Clear the pending action
      ref.read(pendingWidgetActionProvider.notifier).state =
          PendingWidgetAction.none;
      // Show the meal log sheet after a short delay to ensure screen is ready
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          debugPrint('HomeScreen: Showing log meal sheet');
          showLogMealSheet(context, ref);
        }
      });
    }
  }

  /// Initialize the current program provider with the user's ID
  void _initializeCurrentProgram() {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId != null) {
      ref.read(currentProgramProvider.notifier).setUserId(userId);
    }
  }

  /// Silent nutrition/hydration refresh for auto-refresh — no loading flash.
  Future<void> _refreshNutritionSilent() async {
    final userId = ref.read(authStateProvider).user?.id;
    if (userId == null) return;
    ref.read(dailyNutritionProvider(todayNutritionKey()).notifier).load(userId);
    ref
        .read(hydrationProvider.notifier)
        .loadTodaySummary(userId, showLoading: false);
  }

  /// Load nutrition & hydration data so TodayStatsRow shows on first launch.
  /// Also pre-warms nutrition preferences so Profile tab loads instantly.
  ///
  /// A6 — unblock init: this no longer `await`s the three loads. All three
  /// notifiers render cache-first (they emit their in-memory/SharedPrefs
  /// cache synchronously and refresh in the background), so awaiting only
  /// delayed Home's `_extInitState` postFrame `Future.wait` on a network
  /// round-trip with no UI benefit. The loads are fired fire-and-forget,
  /// mirroring `_refreshNutritionSilent()`, and this function returns
  /// immediately.
  Future<void> _initializeNutritionAndHydration() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId == null) return;
    // Pre-warm fasting provider (loads in constructor, no await needed)
    ref.read(fastingSettingsProvider);

    // Initialize the fasting STATE provider too — the home nutrition card's
    // fasting row and the timeline's active-fast row both read
    // `fastingProvider.activeFast`. Without this call the provider only ever
    // has its (usually empty) in-memory cache, so an in-progress fast never
    // surfaces on Home until the user opens the standalone Fasting screen.
    // Fire-and-forget: it's not blocking the first paint of nutrition/macros.
    unawaited(ref.read(fastingProvider.notifier).initialize(userId));

    // Fire-and-forget — providers are cache-first so the UI shows data
    // immediately and the network refresh resolves silently. Not awaited so
    // the postFrame init chain stays unblocked.
    unawaited(
      ref
          .read(dailyNutritionProvider(todayNutritionKey()).notifier)
          .load(userId),
    );
    unawaited(ref.read(hydrationProvider.notifier).loadTodaySummary(userId));
    unawaited(
      ref.read(nutritionPreferencesProvider.notifier).initialize(userId),
    );
  }

  /// A8 — predictive prefetch. Once Home is interactive and idle, warm the
  /// caches for the two screens a user is most likely to open next so those
  /// taps feel instant:
  ///   1. Today's workout detail — pre-fetch `getWorkout(id)` for today's
  ///      (or the next) workout so [WorkoutDetailScreen]'s `_loadWorkout`
  ///      hits a warm repository cache instead of a cold network call.
  ///   2. The Nutrition daily screen's data — `nutritionProvider` and
  ///      `hydrationProvider` today summaries (re-triggered cache-first;
  ///      a no-op if already warm from `_initializeNutritionAndHydration`).
  ///
  /// This NEVER navigates — it only triggers loads. It's fire-and-forget,
  /// fully `mounted`-guarded, and skipped entirely when the device is
  /// offline so we don't burn a slow/metered connection on speculative work.
  Future<void> _predictivePrefetch() async {
    if (!mounted) return;

    // Easy connectivity check: skip prefetch when fully offline. (We don't
    // gate on mobile-vs-wifi — mobile data isn't necessarily slow, and the
    // prefetch payload is tiny.)
    try {
      final conn = await Connectivity().checkConnectivity();
      if (conn.every((r) => r == ConnectivityResult.none)) return;
    } catch (_) {
      // If the connectivity probe itself fails, just skip prefetch quietly.
      return;
    }
    if (!mounted) return;

    // (1) Today's workout detail — warm the workout repository cache.
    final todayWorkout = _getTodayWorkoutFromState(
      ref.read(todayWorkoutProvider),
    );
    final workoutId = todayWorkout?.id;
    if (workoutId != null && workoutId.isNotEmpty) {
      // Fire-and-forget; getWorkout populates the repo's cache so the detail
      // screen's _loadWorkout resolves instantly.
      unawaited(
        ref.read(workoutRepositoryProvider).getWorkout(workoutId).catchError((
          e,
        ) {
          debugPrint('🔍 [Home] prefetch workout detail skipped: $e');
          return null;
        }),
      );
    }

    // (2) Nutrition daily screen data — ensure today's nutrition + hydration
    // summaries are warm. Cache-first notifiers, so this is a cheap no-op if
    // _initializeNutritionAndHydration already populated them.
    final userId = ref.read(authStateProvider).user?.id;
    if (userId != null) {
      unawaited(
        ref
            .read(dailyNutritionProvider(todayNutritionKey()).notifier)
            .load(userId),
      );
      unawaited(
        ref
            .read(hydrationProvider.notifier)
            .loadTodaySummary(userId, showLoading: false),
      );
    }
  }

  /// Initialize window mode tracking with the user's ID
  void _initializeWindowModeTracking() {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId != null) {
      ref.read(windowModeProvider.notifier).setUserId(userId);
    }
  }

  Future<void> _initializeWorkouts() async {
    // Home screen now uses todayWorkoutProvider (lazy loading)
    // No need to fetch all workouts or trigger regeneration here
    // Regeneration is handled by the Workouts tab when user navigates there
    if (mounted) {
      setState(() => _isInitializing = false);
    }
    if (!_initCompleter.isCompleted) {
      _initCompleter.complete();
    }

    // Process daily login for XP rewards (runs in background)
    _processDailyLogin();
  }

  /// Load XP data and initialize goals/streak tracking.
  /// Daily login XP is already processed by app_router.dart on startup.
  ///
  /// Guards every `ref` access that follows an `await` with a `mounted`
  /// check — if the user navigates away from Home mid-load, the State is
  /// disposed and any further `ref.read` would throw.
  Future<void> _processDailyLogin() async {
    try {
      if (!mounted) return;
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;
      if (userId == null) return;

      final xpNotifier = ref.read(xpProvider.notifier);

      // Load user XP data so we have it available
      await xpNotifier.loadAll(userId: userId);
      if (!mounted) return;

      // Load active XP events (Double XP, etc.)
      await xpNotifier.loadActiveEvents();
      if (!mounted) return;

      // Initialize streak tracking for milestone detection
      xpNotifier.initializeStreakTracking();

      // Initialize daily goals with login status
      xpNotifier.initializeDailyGoals();

      final loginStreak = ref.read(xpProvider).loginStreak;
      if (loginStreak != null) {
        // Check for streak milestones (7, 30, 100, 365 days)
        xpNotifier.checkStreakMilestone(loginStreak.currentStreak);
      }
    } catch (e) {
      debugPrint('❌ [Home] Error processing daily login: $e');
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  /// Check if a tile type is visible in the local layout
  bool _isTileVisible(AsyncValue<HomeLayout?> layoutState, TileType type) {
    final layout = layoutState.value;
    if (layout == null) return true; // Show by default if no layout loaded
    final tile = layout.tiles.where((t) => t.type == type).firstOrNull;
    return tile?.isVisible ?? true; // Show by default if tile not found
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.pureBlack
        : AppColorsLight.pureWhite;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    // Perf marker: 'home_first_content'. `_isInitializing` is true until the
    // first workout check completes — once false, Home is rendering real
    // (non-skeleton) content. Mark in a post-frame callback so it fires after
    // this frame is actually painted, and only once.
    if (!_markedFirstContent && !_isInitializing) {
      _markedFirstContent = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        PerfTrace.mark('home_first_content');
      });
    }

    // Level-up listener moved to MainShell (widgets/main_shell.dart) so it fires from any screen

    // Listen for streak milestone events and show celebration dialog
    ref.listen<StreakMilestone?>(streakMilestoneProvider, (previous, next) {
      if (next != null && previous == null) {
        // Streak milestone reached - show celebration dialog
        final currentStreak = ref.read(xpCurrentStreakProvider);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            showStreakMilestoneDialog(context, next, currentStreak, () {
              // Clear the streak milestone after dialog is dismissed
              ref.read(xpProvider.notifier).clearStreakMilestone();
            });
          }
        });
      }
    });

    // Listen for XP earned events and show animation
    ref.listen<XPEarnedAnimationEvent?>(xpEarnedEventProvider, (
      previous,
      next,
    ) {
      if (next != null && previous == null) {
        // XP earned - show floating toast animation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            XPEarnedOverlay.show(
              context,
              xpAmount: next.xpAmount,
              goalType: _mapXPGoalType(next.goalType),
            );
            // Clear the event after showing animation
            Future.delayed(const Duration(milliseconds: 2500), () {
              ref.read(xpProvider.notifier).clearXPEarnedEvent();
            });
          }
        });
      }
    });

    // Listen for persona-voiced milestone banners (e.g. 10k-steps congrats).
    // Fires in parallel with the XP earned overlay — the XP toast celebrates
    // the numeric reward, the coach banner delivers the AI-persona voice.
    ref.listen<CoachBannerEvent?>(coachBannerEventProvider, (previous, next) {
      if (next != null && previous == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final aiSettings = ref.read(aiSettingsProvider);
          final coach =
              CoachPersona.findById(aiSettings.coachPersonaId) ??
              CoachPersona.defaultCoach;
          switch (next.kind) {
            case CoachBannerKind.stepsGoal:
              CoachBannerOverlay.show(
                context,
                coach: coach,
                title: AppLocalizations.of(context)!.homeScreenDailyStepsGoal,
                message: buildStepsGoalMessage(coach, next.value),
                xpAwarded: next.xpAwarded,
                icon: Icons.directions_walk_rounded,
              );
              break;
          }
          // Clear after the banner has had time to animate in. The overlay
          // manages its own auto-dismiss timer.
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) ref.read(xpProvider.notifier).clearCoachBannerEvent();
          });
        });
      }
    });

    return Scaffold(
      backgroundColor: backgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          debugPrint('🔄 [Home] Pull-to-refresh triggered');
          _lastRefreshTime = DateTime.now();
          // Reset carousel auto-generation so it can re-evaluate
          HeroWorkoutCarousel.resetAutoGeneration();
          // Refresh user data (picks up workout days, preferences changes)
          await ref.read(authStateProvider.notifier).refreshUser();
          // Silently reload layout from SharedPreferences (not a provider)
          ref.read(localLayoutProvider.notifier).reload();
          // Single consolidated invalidation of every Home-tier provider
          // (today workout, gym profiles, workouts, discover, nutrition,
          // hydration, billing renewal, celebrations, xp, consistency,
          // weekly plan, habits) + prewarmer + bootstrap prefetch.
          await refreshAllHome(ref);
          debugPrint('✅ [Home] Pull-to-refresh complete');
        },
        color: AppColors.cyan,
        backgroundColor: elevatedColor,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header — greeting + streak + bell + overflow. Fixed chrome.
              const SliverToBoxAdapter(child: MinimalHeader()),

              // Stacked notification-panel banners + rating prompt — fixed
              // system chrome, always directly under the header. Both
              // self-collapse to zero height when there's nothing to show.
              const SliverToBoxAdapter(child: StackedBannerPanel()),
              const SliverToBoxAdapter(child: RatingPromptBanner()),

              // Calibration banner (first 30 days). Sets expectations so users
              // don't churn at Day 3 thinking the AI is dumb — it's learning.
              // Starts collapsed (slim pill w/ progress ring); self-collapses
              // to zero height past the 30-day window or after user dismisses.
              const SliverToBoxAdapter(
                child: RepaintBoundary(child: CalibrationBanner()),
              ),

              // Get Started Challenge (new-user onboarding checklist) is no
              // longer mounted here — it is spliced in directly BELOW the Next
              // Workout hero inside _homeSectionSlivers so it sits where the
              // reference design places it. It self-collapses when complete,
              // past the 14-day window, or dismissed.

              // One-time cycle-tracking setup invitation for existing
              // eligible users (Phase E). Self-collapses to zero height
              // when the user is ineligible, already set up, or has
              // dismissed it once.
              const SliverToBoxAdapter(child: CycleSetupHomePrompt()),

              // SIGNATURE V2 — glanceable metrics strip directly under the
              // masthead: STEPS · SLEEP · READY · SCORE, tappable, so the
              // day's key numbers are seen without scrolling. The full metric
              // deck (ring + tiles + trends) stays below the fold.
              const SliverToBoxAdapter(
                child: RepaintBoundary(child: HomeMetricsStrip()),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: kHomeGap)),

              // Fixed coach-first composition. Only the timeline-visibility flag
              // is read here (the section list itself is a fixed v2 order), so
              // narrow the watch to that bool — a change elsewhere in
              // homeSectionsProvider no longer rebuilds the whole home sliver list.
              ..._homeSectionSlivers(
                ref.watch(
                  homeSectionsProvider.select(
                    (s) => s.isVisible(HomeSection.timeline),
                  ),
                ),
              ),

              // Bottom padding for the floating nav. Derived from the
              // actual safe-area inset + the nav-bar intrinsic height
              // + breathing room (Surface 1.9: 32 so the last sliver
              // clears the nav-shadow margin on every tested device,
              // iPhone SE → 16 Pro Max). Heights now come from
              // chrome_constants.dart so the nav and its consumers can't
              // drift apart.
              SliverToBoxAdapter(
                child: SizedBox(
                  height:
                      MediaQuery.viewPaddingOf(context).bottom +
                      kMainNavBarHeight +
                      kHomeBottomBreathingRoom,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Number of leading sections that are kept eager (above-the-fold). These
  /// are visible without scrolling on virtually every device (quick actions,
  /// week strip, hero workout card, nutrition card), so building them lazily
  /// would only add a frame of jank on first paint with no scroll-cost win.
  static const int _eagerSectionCount = 4;

  /// Build the customizable home sections as slivers, in the user's chosen
  /// order, skipping any they've hidden in "My Space". Each section gets a
  /// uniform [kHomeGap] below it. If every section is hidden the list is
  /// simply empty — the header + banners still render, no crash.
  ///
  /// A4 — lazy below-the-fold sections: the first [_eagerSectionCount]
  /// sections render eagerly as [SliverToBoxAdapter]s (they're on-screen at
  /// rest). Every remaining section is emitted through a single [SliverList]
  /// with a [SliverChildBuilderDelegate] so it only builds when the user
  /// scrolls it into the viewport. Section order and content are unchanged;
  /// each below-the-fold section still gets its trailing [kHomeGap].
  List<Widget> _homeSectionSlivers(bool timelineVisible) {
    // Timeline is pulled OUT of the normal section flow — the user wants it to
    // always be the very last card on Home, so it is appended after the
    // contextual card stack regardless of where it sits in the saved order.
    // (Only its visibility flag is needed here; passed in as a narrowed watch.)

    // Drop sections that are GUARANTEED to render nothing today so they don't
    // leave a phantom kHomeGap (issue 6):
    //  • strainCoach  — folded into the workout hero, always SizedBox.shrink.
    //  • metricTrio   — folded into the MetricSummaryDeck, always shrink.
    //  • cycle        — self-hides unless menstrual tracking is enabled; the
    //    gate is cheap (hormonalProfileProvider), so filter it here too rather
    //    than leave a ~14px void between the nutrition card and Reports/Recap.
    final menstrualEnabled = ref.watch(
      hormonalProfileProvider.select(
        (v) => v.valueOrNull?.menstrualTrackingEnabled ?? false,
      ),
    );
    // SIGNATURE V2 — Home is a FIXED coach-first composition, not the old
    // user-customizable section stack. Order: coach to-do (hero) → workout
    // carousel → fuel → (below the fold) the metric deck, habits, reports.
    // The emoji quick-actions grid and the week strip are dropped from Home —
    // quick-actions live behind the "+" / quick-log sheet in v2.
    // Signature v2 below-the-fold = Strength → Habits → Readiness → Cycle →
    // Timeline (timeline appended separately). The weekly Report + "Your Week"
    // recap were RELOCATED off Home (Reports → Progress, Recap → You/Wrapped)
    // to keep Home lean per the spec.
    // The pinned quick-actions row is opt-in (default OFF). Only insert the
    // section when the user has turned on "Show on home screen" so the row
    // sits BETWEEN the coach card and the workout card, with no phantom gap
    // when it's hidden (mirrors the strainCoach/cycle filtering above).
    final quickActionsOnHome = ref.watch(quickActionsHomeVisibleProvider);
    final visible = <HomeSection>[
      HomeSection.coachHero,
      if (quickActionsOnHome) HomeSection.quickActions,
      HomeSection.workoutCard,
      HomeSection.nutritionCard,
      HomeSection.todayScore,
      HomeSection.habits,
      HomeSection.readiness,
      if (menstrualEnabled) HomeSection.cycle,
    ];

    // Coach card sits ABOVE the workout card (user request). We no longer
    // auto-swap their order by training-day intent — the coach frames the day,
    // the workout follows. The order comes straight from `visible` (the default
    // now lists coachHero before workoutCard; a user's My Space reorder is
    // preserved as-is).

    final slivers = <Widget>[];

    // Above-the-fold: eager adapters, preserving the per-section gap.
    final eagerCount = visible.length < _eagerSectionCount
        ? visible.length
        : _eagerSectionCount;
    for (var i = 0; i < eagerCount; i++) {
      // RepaintBoundary isolates each heavy card's raster so an animation or
      // state change in one (coach hero, workout carousel, fuel card) doesn't
      // repaint its neighbours while the list is scrolling.
      slivers.add(SliverToBoxAdapter(
          child: RepaintBoundary(child: _widgetForSection(visible[i]))));
      // Quick actions hugs the card below it (the coach card) — a tighter gap
      // so the coach action items sit closer to first glance.
      final gap = visible[i] == HomeSection.quickActions ? 6.0 : kHomeGap;
      slivers.add(SliverToBoxAdapter(child: SizedBox(height: gap)));
      // Get Started Challenge sits directly below the Next Workout hero
      // (matches the reference). Self-hides to zero height when not applicable,
      // and provides its own vertical margin — so no trailing gap sliver here,
      // else a hidden card would leave a phantom void.
      if (visible[i] == HomeSection.workoutCard) {
        // Program Library integration: today's program ADD-ONS sit as a slim
        // row directly under the hero, and the user's enrolled programs ("My
        // Programs") follow. Both self-hide when empty (My Programs shows its
        // discovery empty-state on home only).
        slivers.add(const SliverToBoxAdapter(child: TodayAddonsRow()));
        slivers.add(const SliverToBoxAdapter(child: SetupChecklistCard()));
        slivers.add(const SliverToBoxAdapter(child: MyProgramsCard()));
      }
    }

    // Below-the-fold: a single lazily-building SliverList. Each visible
    // section maps to one child = section widget + its trailing kHomeGap,
    // so inter-section spacing matches the eager path exactly.
    final lazySections = visible.sublist(eagerCount);
    if (lazySections.isNotEmpty) {
      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final section = lazySections[index];
              final gap = section == HomeSection.quickActions ? 6.0 : kHomeGap;
              // Stable per-section identity (key + findChildIndexCallback): when
              // the visible-section set reorders or a section self-hides (the
              // menstrual gate resolving async, a card dropping out, a My Space
              // reorder), the sliver MOVES the existing element — and any
              // keep-alive child it holds — to its new index by identity rather
              // than rebuilding position-blind. Without this, a kept-alive child
              // could land out of monotonic order, tripping
              // RenderSliverMultiBoxAdaptor._debugVerifyChildOrder's
              // `indexOf(child) > index` assert; and an InheritedElement could
              // deactivate while a stale dependent survived, tripping
              // InheritedElement.debugDeactivated's `_dependents.isEmpty`.
              return KeyedSubtree(
                key: ValueKey('home_section_${section.name}'),
                child: RepaintBoundary(
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _widgetForSection(section),
                    // If a My Space reorder pushed the workout card below the
                    // fold, keep the add-ons row, Get Started Challenge, and My
                    // Programs directly beneath it.
                    if (section == HomeSection.workoutCard) ...[
                      const TodayAddonsRow(),
                      const SetupChecklistCard(),
                      const MyProgramsCard(),
                    ],
                    SizedBox(height: gap),
                  ],
                ),
                ),
              );
            },
            childCount: lazySections.length,
            findChildIndexCallback: (Key key) {
              if (key is ValueKey<String>) {
                final idx = lazySections.indexWhere(
                  (s) => 'home_section_${s.name}' == key.value,
                );
                return idx >= 0 ? idx : null;
              }
              return null;
            },
          ),
        ),
      );
    }

    // Phase B–W expansion: 80 self-collapsing contextual cards. Each
    // returns SizedBox.shrink() unless its gate fires, so this Column
    // is cheap even with all 80 imports present.
    slivers.add(const SliverToBoxAdapter(child: ExtendedHomeCardsStack()));

    // Active fast → prominent live hero above the timeline. Hidden entirely
    // when not fasting so Home stays uncluttered (the timeline still shows an
    // at-a-glance fasting row).
    if (ref.watch(fastingProvider.select((s) => s.activeFast != null))) {
      slivers.add(const SliverToBoxAdapter(child: HeroFastingCard()));
    }

    // Timeline always renders LAST (issue 7) — after every section and the
    // contextual card stack — so it's the final card on the Home scroll.
    if (timelineVisible) {
      slivers.add(const SliverToBoxAdapter(child: HomeTimeline()));
      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: kHomeGap)));
    }

    return slivers;
  }

  /// Maps a [HomeSection] to its concrete home widget.
  Widget _widgetForSection(HomeSection section) {
    switch (section) {
      case HomeSection.quickActions:
        // NOTE: the nav-tour "Quick Log" anchor (AppTourKeys.quickLogKey) now
        // lives on the "+" FAB in main_shell.dart — this section is opt-in
        // (hidden by default), so anchoring here left the tour spotlight with
        // a zero rect for new users. GlobalKeys must be attached exactly once.
        return const QuickActionsRow();
      case HomeSection.weekStrip:
        return const HomeWeekStrip();
      case HomeSection.coachHero:
        return const CoachHeroCard();
      case HomeSection.strainCoach:
        // The standalone "TODAY'S INTENSITY" card was folded into the
        // Workout hero's meta line as a tier chip. Returning SizedBox
        // here removes the card from the home scroll without forcing a
        // migration on `HomeSection.strainCoach` enum values that may be
        // persisted in a user's section ordering. The chip itself lives
        // in `_WorkoutHeroBody._metaLine` (see unified_home_widgets.dart).
        return const SizedBox.shrink();
      case HomeSection.workoutCard:
        // Anchor for nav-tour step 2 ("Today's Workout"). Key lives on the
        // active section widget (the legacy heroCarousel/tile_factory anchor
        // never mounts in this layout → zero-rect → no spotlight).
        return KeyedSubtree(
          key: AppTourKeys.heroCarouselKey,
          child: const HomeWorkoutCard(),
        );
      case HomeSection.nutritionCard:
        // Signature v2: Home leads with the compact one-line FUEL strip above
        // the fold; the full nutrition card lives on the Nutrition tab.
        return const HomeFuelStrip();
      case HomeSection.metricTrio:
        // Folded into the MetricSummaryDeck (Direction C). Kept in the enum so
        // a user's persisted ordering doesn't break; renders nothing now.
        return const SizedBox.shrink();
      case HomeSection.weeklyReport:
        // Two-up "Reports · Recap" row (issue 7) — replaces the full-width
        // Weekly Report card; pairs reports with the week recap as two squares.
        return const ReportsRecapRow();
      case HomeSection.timeline:
        // Rendered out-of-band as the final sliver (see _homeSectionSlivers).
        // This case stays for completeness but isn't hit in the normal loop.
        return const HomeTimeline();
      case HomeSection.habits:
        return const HabitsSection();
      case HomeSection.todayScore:
        // Signature v2: the below-fold leads with a typographic STRENGTH
        // breakdown (Anton score + hairline PUSH/PULL/LEGS-style bars), NOT the
        // old segmented activity ring deck — the spec drops the ring here.
        return const HomeStrengthBreakdown();
      case HomeSection.cycle:
        // Self-hides unless menstrual tracking is enabled. Renders the merged
        // "Your Cycle" card (#12) — phase + day, next-period countdown, PMS-prep,
        // in-period symptom log, Log/View actions — replacing the old
        // CycleStatusCard + the separate extended-stack cycle tiles.
        return const CycleSummaryCard();
      case HomeSection.readiness:
        // SLICE_READINESS Recovery Readiness tile. Self-hides on
        // calibration window (<14d) and after a "Building baseline"
        // empty state period.
        return const ReadinessTile();
    }
  }

  /// Extract workout from todayWorkoutProvider state
  Workout? _getTodayWorkoutFromState(AsyncValue<TodayWorkoutResponse?> state) {
    return state.whenOrNull(
      data: (response) {
        if (response == null) return null;
        // Show existing workout even if background generation is in progress
        final summary = response.todayWorkout ?? response.nextWorkout;
        return summary?.toWorkout();
      },
    );
  }

  /// Check if workout is being generated from state
  bool _isGeneratingFromState(AsyncValue<TodayWorkoutResponse?> state) {
    return state.whenOrNull(
          loading: () => true,
          data: (response) => response?.isGenerating ?? false,
        ) ??
        false;
  }

  /// Handle day tap in week strip
  void _onWeekDaySelected(int dayIndex) {
    setState(() => _selectedWeekDay = dayIndex);

    final weekConfig = ref.read(weekDisplayConfigProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = weekConfig.weekStart(today);
    final tappedDate = weekConfig.dateForDataIndex(weekStart, dayIndex);
    final tappedKey =
        '${tappedDate.year}-${tappedDate.month.toString().padLeft(2, '0')}-${tappedDate.day.toString().padLeft(2, '0')}';

    // 1) Exact carousel match wins — animate the carousel to that card.
    int? exactIndex;
    int bestIndex = 0;
    int bestDiff = 999;
    for (int i = 0; i < _carouselItems.length; i++) {
      final itemDate = _carouselItems[i].date;
      if (itemDate == null) continue;
      if (itemDate.year == tappedDate.year &&
          itemDate.month == tappedDate.month &&
          itemDate.day == tappedDate.day) {
        exactIndex = i;
        break;
      }
      final diff = itemDate.difference(tappedDate).inDays.abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        bestIndex = i;
      }
    }

    if (exactIndex != null && _carouselPageController.hasClients) {
      _carouselPageController.animateToPage(
        exactIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    // 2) No card for that day — but a workout may still exist (e.g. a missed
    // session that was filtered out of the carousel). Open it directly so the
    // user can see what they missed.
    final allWorkouts = ref.read(workoutsProvider).valueOrNull ?? [];
    Workout? matchedWorkout;
    for (final w in allWorkouts) {
      final raw = w.scheduledDate;
      if (raw == null || raw.length < 10) continue;
      if (raw.substring(0, 10) == tappedKey) {
        matchedWorkout = w;
        break;
      }
    }
    if (matchedWorkout != null && matchedWorkout.id != null) {
      context.push('/workout/${matchedWorkout.id}', extra: matchedWorkout);
      return;
    }

    // 3) Fallback — animate to nearest card so the user gets *something*.
    if (_carouselItems.isNotEmpty && _carouselPageController.hasClients) {
      _carouselPageController.animateToPage(
        bestIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Handle carousel page change (sync strip highlight)
  void _onCarouselPageChanged(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= _carouselItems.length) return;

    final itemDate = _carouselItems[pageIndex].date;
    if (itemDate == null) return;

    final weekdayIndex = itemDate.weekday - 1; // 0=Mon
    if (weekdayIndex != _selectedWeekDay) {
      setState(() => _selectedWeekDay = weekdayIndex);
    }
  }

  /// Check if a workout is scheduled for today
  bool _isWorkoutScheduledForToday(Workout workout) {
    return workout.isToday;
  }
}

// WorkoutCategoryPills has been extracted to widgets/workout_category_pills.dart
