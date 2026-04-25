import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../core/accessibility/accessibility_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/providers/window_mode_provider.dart';
import '../../core/providers/workout_mini_player_provider.dart';
import '../../data/models/home_layout.dart';
import '../../data/providers/home_layout_provider.dart';
import '../../data/providers/local_layout_provider.dart';
import '../../data/services/haptic_service.dart';
import '../../data/providers/branded_program_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/workout.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/providers/today_workout_provider.dart';
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
import 'widgets/tile_factory.dart';
import 'widgets/my_program_summary_card.dart';
import 'widgets/hero_workout_card.dart';
import '../../core/providers/week_start_provider.dart';
import 'widgets/hero_workout_carousel.dart';
import 'widgets/sectioned_hero_area.dart';
import 'widgets/swipeable_hero_section.dart' show HomeFocus, homeFocusProvider;
import 'widgets/workout_category_pills.dart';
import 'widgets/habits_section.dart';
import 'widgets/body_metrics_section.dart';
import 'widgets/achievements_section.dart';
import '../../data/providers/consistency_provider.dart';
import '../../data/providers/xp_provider.dart' as xp_provider;
import '../../data/providers/xp_provider.dart' show xpProvider, xpCurrentStreakProvider, streakMilestoneProvider, xpEarnedEventProvider, XPEarnedAnimationEvent, coachBannerEventProvider, CoachBannerEvent, CoachBannerKind;
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
import '../settings/sections/nutrition_fasting_section.dart';
import '../../widgets/usage_counter_strip.dart';
import '../../widgets/app_tour/app_tour_controller.dart';
import '../../core/services/posthog_service.dart';
import '../../core/services/fitness_snapshot_service.dart';

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
    with SingleTickerProviderStateMixin, ResponsiveMixin, WidgetsBindingObserver, PillSwipeNavigationMixin {
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

  void _triggerNavTour() {
    final steps = [
      AppTourStep(
        id: 'nav_step_topbar',
        targetKey: AppTourKeys.topBarKey,
        title: 'Your Command Center',
        description: 'Switch between gyms, customize your home screen layout, access settings, and track your level.',
        position: TooltipPosition.below,
      ),
      AppTourStep(
        id: 'nav_step_carousel',
        targetKey: AppTourKeys.heroCarouselKey,
        title: 'Your AI Workout',
        description: 'Swipe to see this week\'s plan. Tap to start today\'s workout.',
        position: TooltipPosition.below,
      ),
      AppTourStep(
        id: 'nav_step_quicklog',
        targetKey: AppTourKeys.quickLogKey,
        title: 'Quick Actions',
        description: 'Quick workout generation, weight logging, food logging and more.',
        position: TooltipPosition.above,
      ),
      AppTourStep(
        id: 'nav_step_workout',
        targetKey: AppTourKeys.workoutNavKey,
        title: 'Workouts',
        description: 'View your workout history and browse the exercise library.',
        position: TooltipPosition.above,
      ),
      AppTourStep(
        id: 'nav_step_nutrition',
        targetKey: AppTourKeys.nutritionNavKey,
        title: 'Track Nutrition',
        description: 'Scan meals with your camera. Track macros easily.',
        position: TooltipPosition.above,
      ),
      AppTourStep(
        id: 'nav_step_profile',
        targetKey: AppTourKeys.profileNavKey,
        title: 'Your Progress',
        description: 'View strength charts, streaks, XP, and achievements.',
        position: TooltipPosition.above,
      ),
    ];
    ref.read(appTourControllerProvider.notifier).checkAndShow('nav_tour', steps);
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
    // `removeObserver` is processed in dispose). Guard against using `ref`
    // post-dispose — Riverpod throws `Bad state: No ProviderScope found`
    // otherwise, which Crashlytics flagged on this exact path.
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      // Auto-refresh when returning to app (with rate limiting)
      _autoRefreshIfNeeded();
      // Pull latest CustomerInfo from RevenueCat so subscription state
      // reflects any out-of-app changes the user made (e.g. cancelling
      // from Google Play's Subscriptions page while the app was
      // backgrounded). Internally 30s-debounced — safe to fire often.
      try {
        unawaited(
          ref.read(subscriptionProvider.notifier).refreshFromRevenueCat(),
        );
      } catch (e) {
        debugPrint('⚠️ [Home] subscription refresh skipped post-dispose: $e');
      }
    }
  }

  /// Called when this widget becomes visible again (e.g., navigating back)
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Auto-refresh when screen becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoRefreshIfNeeded();
    });
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
        // Refresh user data (picks up workout days, preferences changes)
        ref.read(authStateProvider.notifier).refreshUser();
        final workoutsNotifier = ref.read(workoutsProvider.notifier);
        await workoutsNotifier.refresh();

        // Check mounted after async operation
        if (!mounted) return;

        // L9: The refresh() call above already updates provider state internally,
        // so we avoid a redundant ref.invalidate(workoutsProvider) which would
        // trigger an unnecessary full re-fetch.

        // Refresh Health Connect status - user may have granted permissions externally
        ref.read(healthSyncProvider.notifier).refreshConnectionStatus();

        // Refresh nutrition & hydration data silently (no loading flash)
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
    showHealthConnectSheet(context, ref);
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
    final count =
        await ref.read(healthImportProvider.notifier).autoImportAll();
    if (!mounted) return;

    if (count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Imported $count workout${count > 1 ? 's' : ''} from Health Connect'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
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
      await ref.read(activeLayoutProvider.notifier).updateTiles(_editingTiles.cast<HomeTile>());
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
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
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
                'Apply ${preset.name}?',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'This will replace your current tiles with the ${preset.name} layout. You can still customize after applying.',
          style: TextStyle(
            color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
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
                ref.read(homeFocusProvider.notifier).state = HomeFocus.nutrition;
              } else {
                ref.read(homeFocusProvider.notifier).state = HomeFocus.workout;
              }
              HapticService.success();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${preset.name} layout applied!'),
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
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _resetToDefaultLayout() {
    Navigator.pop(context); // Close the sheet

    // Show confirmation dialog
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
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
                'Reset to Default?',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'This will restore the Minimalist layout (the app default). Your current customizations will be replaced.',
          style: TextStyle(
            color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
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
              await ref.read(localLayoutProvider.notifier).applyPreset(minimalistPreset);
              HapticService.success();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Default layout restored!'),
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
            child: const Text('Reset'),
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
      ref.read(pendingWidgetActionProvider.notifier).state = PendingWidgetAction.none;
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
    ref.read(nutritionProvider.notifier).loadTodaySummary(userId);
    ref.read(hydrationProvider.notifier).loadTodaySummary(userId, showLoading: false);
  }

  /// Load nutrition & hydration data so TodayStatsRow shows on first launch.
  /// Also pre-warms nutrition preferences so Profile tab loads instantly.
  Future<void> _initializeNutritionAndHydration() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId == null) return;
    // Pre-warm fasting provider (loads in constructor, no await needed)
    ref.read(fastingSettingsProvider);

    await Future.wait([
      ref.read(nutritionProvider.notifier).loadTodaySummary(userId),
      ref.read(hydrationProvider.notifier).loadTodaySummary(userId),
      ref.read(nutritionPreferencesProvider.notifier).initialize(userId),
    ]);
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
    // M12: Use .select() for granular rebuilds - only rebuild when the specific data changes
    final todayWorkoutState = ref.watch(todayWorkoutProvider);
    final isAIGenerating = ref.watch(aiGeneratingWorkoutProvider);
    // Watch local layout for tile visibility settings
    final localLayoutState = ref.watch(localLayoutProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    // Level-up listener moved to MainShell (widgets/main_shell.dart) so it fires from any screen

    // Listen for streak milestone events and show celebration dialog
    ref.listen<StreakMilestone?>(streakMilestoneProvider, (previous, next) {
      if (next != null && previous == null) {
        // Streak milestone reached - show celebration dialog
        final currentStreak = ref.read(xpCurrentStreakProvider);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            showStreakMilestoneDialog(
              context,
              next,
              currentStreak,
              () {
                // Clear the streak milestone after dialog is dismissed
                ref.read(xpProvider.notifier).clearStreakMilestone();
              },
            );
          }
        });
      }
    });

    // Listen for XP earned events and show animation
    ref.listen<XPEarnedAnimationEvent?>(xpEarnedEventProvider, (previous, next) {
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
          final coach = CoachPersona.findById(aiSettings.coachPersonaId) ??
              CoachPersona.defaultCoach;
          switch (next.kind) {
            case CoachBannerKind.stepsGoal:
              CoachBannerOverlay.show(
                context,
                coach: coach,
                title: 'Daily steps goal',
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
            // Silently refresh today's workout (stale-while-revalidate)
            ref.read(todayWorkoutProvider.notifier).invalidateAndRefresh();
            // Silently reload layout from SharedPreferences
            ref.read(localLayoutProvider.notifier).reload();
            debugPrint('✅ [Home] Pull-to-refresh complete');
          },
          color: AppColors.cyan,
          backgroundColor: elevatedColor,
          child: SafeArea(
            child: CustomScrollView(
            slivers: [
              // Header: Always minimal (level ring now pairs streak count inline)
              const SliverToBoxAdapter(
                child: MinimalHeader(),
              ),

              // Rank/percentile is now surfaced inside StackedBannerPanel as
              // a BannerType.rankPercentile entry (stacks with Daily Crate,
              // missed workouts, etc.) — no separate hero card.

              // Stacked notification-panel banners (all active, swipeable)
              const SliverToBoxAdapter(
                child: StackedBannerPanel(),
              ),

              // Dynamic tiles from local layout
              ...localLayoutState.when(
                loading: () => _buildFallbackTilesAsSlivers(context, isDark, todayWorkoutState, isAIGenerating),
                error: (_, __) => _buildFallbackTilesAsSlivers(context, isDark, todayWorkoutState, isAIGenerating),
                data: (layout) => _buildLayoutTilesAsSlivers(context, layout, isDark, todayWorkoutState, isAIGenerating),
              ),

              // Bottom padding for nav bar
              const SliverToBoxAdapter(
                child: SizedBox(height: 120),
              ),
            ],
          ),
        ),
      ),
    );
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
    ) ?? false;
  }

  /// Build hero section with tab pills (Workouts | Nutrition | Fasting)
  /// and weekly carousel for workouts
  Widget _buildHeroSectionFixed(
    BuildContext context,
    AsyncValue<TodayWorkoutResponse?> todayWorkoutState,
    bool isAIGenerating,
    bool isDark,
  ) {
    return SectionedHeroArea(
      carouselPageController: _carouselPageController,
      carouselKey: AppTourKeys.heroCarouselKey,
      onCarouselItemsChanged: (items) {
        if (mounted && items.length != _carouselItems.length ||
            (items.isNotEmpty && _carouselItems.isNotEmpty &&
             items.first.date != _carouselItems.first.date)) {
          setState(() => _carouselItems = items);
        }
      },
      onPageChanged: _onCarouselPageChanged,
      todayWorkoutState: todayWorkoutState,
      isAIGenerating: isAIGenerating,
      isInitializing: _isInitializing,
      selectedWeekDay: _selectedWeekDay,
      onWeekDaySelected: _onWeekDaySelected,
    );
  }

  /// Handle day tap in week strip
  void _onWeekDaySelected(int dayIndex) {
    setState(() => _selectedWeekDay = dayIndex);

    if (_carouselItems.isEmpty) return;
    if (!_carouselPageController.hasClients) return;

    // Find the carousel item whose date matches or is closest to the tapped day
    final weekConfig = ref.read(weekDisplayConfigProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = weekConfig.weekStart(today);
    final tappedDate = weekConfig.dateForDataIndex(weekStart, dayIndex);

    int bestIndex = 0;
    int bestDiff = 999;

    for (int i = 0; i < _carouselItems.length; i++) {
      final itemDate = _carouselItems[i].date;
      if (itemDate == null) continue;

      final diff = (itemDate.difference(tappedDate).inDays).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        bestIndex = i;
      }
    }

    _carouselPageController.animateToPage(
      bestIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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

