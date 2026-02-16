import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/providers/window_mode_provider.dart';
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
import 'widgets/components/components.dart';
import 'widgets/cards/cards.dart';
import 'widgets/daily_activity_card.dart';
import 'widgets/renewal_reminder_banner.dart';
import 'widgets/missed_workout_banner.dart';
import 'widgets/contextual_banner.dart';
import 'widgets/watch_install_banner.dart';
import 'widgets/tile_factory.dart';
import 'widgets/my_program_summary_card.dart';
import 'widgets/hero_workout_card.dart';
import 'widgets/hero_workout_carousel.dart';
import 'widgets/habits_section.dart';
import 'widgets/body_metrics_section.dart';
import 'widgets/achievements_section.dart';
import '../../data/providers/consistency_provider.dart';
import '../../data/providers/xp_provider.dart' as xp_provider;
import '../../data/providers/xp_provider.dart' show xpProvider, xpCurrentStreakProvider, levelUpEventProvider, streakMilestoneProvider, xpEarnedEventProvider, XPEarnedAnimationEvent;
import '../../data/models/user_xp.dart';
import '../../widgets/double_xp_banner.dart';
import '../../widgets/xp_level_bar.dart';
import '../../widgets/level_up_dialog.dart';
import '../../widgets/streak_milestone_dialog.dart';
import '../../widgets/xp_earned_animation.dart';
import '../../data/models/level_reward.dart';
import 'widgets/gym_profile_switcher.dart';
import 'widgets/daily_crate_banner.dart';
import 'widgets/minimal_header.dart';
import 'widgets/collapsed_banner_strip.dart';
import '../../widgets/health_connect_sheet.dart';
import '../../data/providers/health_import_provider.dart';

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
  String? _generationStartDate;
  int _generationWeeks = 0;
  int _totalExpected = 0;
  int _totalGenerated = 0;
  String _generationMessage = '';
  String? _generationDetail;

  // Auto-refresh tracking
  DateTime? _lastRefreshTime;

  // Deprecated: Edit mode state (no longer used but kept for backwards compatibility with dead code)
  @Deprecated('Edit mode has been removed')
  bool _isEditMode = false;
  @Deprecated('Edit mode has been removed')
  List<dynamic> _editingTiles = [];
  @Deprecated('Edit mode has been removed')
  static const String _editModeTooltipKey = 'has_shown_edit_mode_tooltip';
  @Deprecated('Edit mode has been removed')
  late final _wiggleController = _DummyAnimationController();
  // M13: Increased from 30 seconds to 5 minutes to reduce unnecessary refreshes
  static const Duration _minRefreshInterval = Duration(minutes: 5);

  /// Ensures the Health Connect popup auto-shows at most once per app session.
  static bool _healthPopupShownThisSession = false;

  @override
  void initState() {
    super.initState();
    // Register for app lifecycle events
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Reset nav bar labels to expanded when on Home screen
      ref.read(navBarLabelsExpandedProvider.notifier).state = true;
      // M4: Run initialization tasks in parallel so one doesn't block another
      Future.wait([
        _initializeWorkouts().catchError((e) {
          debugPrint('❌ [Home] _initializeWorkouts error: $e');
        }),
        Future(() => _checkPendingWidgetAction()).catchError((e) {
          debugPrint('❌ [Home] _checkPendingWidgetAction error: $e');
        }),
        Future(() => _initializeCurrentProgram()).catchError((e) {
          debugPrint('❌ [Home] _initializeCurrentProgram error: $e');
        }),
        Future(() => _initializeWindowModeTracking()).catchError((e) {
          debugPrint('❌ [Home] _initializeWindowModeTracking error: $e');
        }),
        _maybeShowHealthConnectPopup().catchError((e) {
          debugPrint('❌ [Home] _maybeShowHealthConnectPopup error: $e');
        }),
        _checkForWorkoutImports().catchError((e) {
          debugPrint('❌ [Home] _checkForWorkoutImports error: $e');
        }),
      ]);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Called when app lifecycle state changes (resume, pause, etc.)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Auto-refresh when returning to app (with rate limiting)
      _autoRefreshIfNeeded();
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
      final workoutsNotifier = ref.read(workoutsProvider.notifier);
      await workoutsNotifier.refresh();

      // Check mounted after async operation
      if (!mounted) return;

      // L9: The refresh() call above already updates provider state internally,
      // so we avoid a redundant ref.invalidate(workoutsProvider) which would
      // trigger an unnecessary full re-fetch.

      // Refresh Health Connect status - user may have granted permissions externally
      ref.read(healthSyncProvider.notifier).refreshConnectionStatus();

      // Check for new workout imports from Health Connect on resume
      _checkForWorkoutImports();
    }
  }

  /// Auto-show Health Connect popup if not connected and not recently dismissed.
  Future<void> _maybeShowHealthConnectPopup() async {
    if (_healthPopupShownThisSession) return;

    // Small delay so the home screen renders first
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

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

  /// Displays the edit mode coach mark/tooltip dialog
  void _showEditModeCoachMark() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: elevatedColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.purple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.edit_rounded, color: AppColors.purple, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Customize Your Dashboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTooltipItem(
              icon: Icons.touch_app_rounded,
              text: 'Tap tiles to resize them',
              color: AppColors.orange,
              textColor: textSecondary,
            ),
            const SizedBox(height: 12),
            _buildTooltipItem(
              icon: Icons.drag_handle_rounded,
              text: 'Drag handles to reorder tiles',
              color: AppColors.purple,
              textColor: textSecondary,
            ),
            const SizedBox(height: 12),
            _buildTooltipItem(
              icon: Icons.visibility_rounded,
              text: 'Tap the eye icon to show/hide tiles',
              color: AppColors.cyan,
              textColor: textSecondary,
            ),
            const SizedBox(height: 12),
            _buildTooltipItem(
              icon: Icons.add_circle_outline,
              text: 'Use + Add Tile to add new tiles',
              color: AppColors.success,
              textColor: textSecondary,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Got it!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper widget for tooltip items
  Widget _buildTooltipItem({
    required IconData icon,
    required String text,
    required Color color,
    required Color textColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
            ),
          ),
        ),
      ],
    );
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

  void _showAddTileSheet(bool isDark) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    // Get tile types that are not already added
    final existingTypes = _editingTiles.map((t) => t.type).toSet();
    final availableTiles = TileType.values.where((t) => !existingTypes.contains(t)).toList();

    // Group by category
    final tilesByCategory = <TileCategory, List<TileType>>{};
    for (final tile in availableTiles) {
      final category = tile.category;
      tilesByCategory[category] ??= [];
      tilesByCategory[category]!.add(tile);
    }

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        showHandle: false,
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: AppColors.cyan),
                    const SizedBox(width: 8),
                    Text(
                      'Add Tile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            // Tiles list
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final category in TileCategory.values)
                    if (tilesByCategory[category]?.isNotEmpty == true) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 8),
                        child: Text(
                          '${category.emoji} ${category.displayName}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                      ),
                      ...tilesByCategory[category]!.map((tileType) => _buildAddTileItem(
                        tileType,
                        isDark,
                        textPrimary,
                        textSecondary,
                      )),
                    ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildAddTileItem(
    TileType tileType,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final cardBg = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            _addTile(tileType);
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getIconForTileType(tileType),
                    color: AppColors.purple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            tileType.displayName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          if (tileType.isNew) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.cyan.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.cyan,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tileType.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.add_circle_outline,
                  color: AppColors.cyan,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForTileType(TileType type) {
    switch (type) {
      case TileType.quickStart:
        return Icons.play_circle_filled;
      case TileType.nextWorkout:
        return Icons.fitness_center;
      case TileType.fitnessScore:
        return Icons.insights;
      case TileType.moodPicker:
        return Icons.wb_sunny_outlined;
      case TileType.dailyActivity:
        return Icons.watch;
      case TileType.quickActions:
        return Icons.apps;
      case TileType.weeklyProgress:
        return Icons.donut_large;
      case TileType.weeklyGoals:
        return Icons.flag_outlined;
      case TileType.weekChanges:
        return Icons.swap_horiz;
      case TileType.upcomingFeatures:
        return Icons.new_releases_outlined;
      case TileType.upcomingWorkouts:
        return Icons.calendar_today;
      case TileType.streakCounter:
        return Icons.local_fire_department;
      case TileType.personalRecords:
        return Icons.emoji_events;
      case TileType.aiCoachTip:
        return Icons.tips_and_updates;
      case TileType.challengeProgress:
        return Icons.military_tech;
      case TileType.caloriesSummary:
        return Icons.restaurant;
      case TileType.macroRings:
        return Icons.pie_chart;
      case TileType.bodyWeight:
        return Icons.monitor_weight;
      case TileType.progressPhoto:
        return Icons.compare;
      case TileType.socialFeed:
        return Icons.people;
      case TileType.leaderboardRank:
        return Icons.leaderboard;
      case TileType.fasting:
        return Icons.timer;
      case TileType.weeklyCalendar:
        return Icons.calendar_month;
      case TileType.muscleHeatmap:
        return Icons.accessibility_new;
      case TileType.sleepScore:
        return Icons.bedtime;
      case TileType.restDayTip:
        return Icons.spa;
      case TileType.myJourney:
        return Icons.route;
      case TileType.progressCharts:
        return Icons.show_chart;
      case TileType.roiSummary:
        return Icons.trending_up;
      case TileType.weeklyPlan:
        return Icons.calendar_view_week;
      // New fat loss UX tiles
      case TileType.weightTrend:
        return Icons.trending_down;
      case TileType.dailyStats:
        return Icons.insights;
      case TileType.achievements:
        return Icons.emoji_events;
      case TileType.heroSection:
        return Icons.home;
      case TileType.quickLogWeight:
        return Icons.monitor_weight_outlined;
      case TileType.quickLogMeasurements:
        return Icons.straighten;
      case TileType.habits:
        return Icons.check_circle_outline;
      case TileType.xpProgress:
        return Icons.bolt;
      case TileType.upNext:
        return Icons.schedule;
      case TileType.todayStats:
        return Icons.bar_chart;
    }
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

  void _showDiscoverSheet(bool isDark) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        showHandle: false,
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.explore, color: AppColors.purple),
                  const SizedBox(width: 8),
                  Text(
                    'Discover Layouts',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Choose a preset layout tailored to your focus. You can customize it further after applying.',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Reset to Default button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => _resetToDefaultLayout(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.orange.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.restart_alt_rounded,
                            color: AppColors.orange,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reset to Default',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Restore the original FitWiz layout',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: AppColors.orange,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Preset layouts list
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: layoutPresets.length,
                itemBuilder: (context, index) {
                  final preset = layoutPresets[index];
                  return _buildPresetCard(preset, isDark, textPrimary, textSecondary);
                },
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildPresetCard(
    LayoutPreset preset,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final cardBg = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _applyPreset(preset),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.purple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        preset.icon,
                        color: preset.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            preset.name,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            preset.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: textSecondary,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Tile preview chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: preset.tiles.take(6).map((tileType) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: tileType.category.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getIconForTileType(tileType),
                            size: 12,
                            color: tileType.category.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tileType.displayName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: tileType.category.color,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                if (preset.tiles.length > 6) ...[
                  const SizedBox(height: 4),
                  Text(
                    '+${preset.tiles.length - 6} more tiles',
                    style: TextStyle(
                      fontSize: 11,
                      color: textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
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
              // Apply preset to local layout (tiles + SharedPreferences for header/banners)
              await ref.read(localLayoutProvider.notifier).applyPreset(preset);
              // Reload header style and collapse banners from SharedPreferences
              await ref.read(headerStyleProvider.notifier).reload();
              await ref.read(collapseBannersProvider.notifier).reload();
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
              await ref.read(headerStyleProvider.notifier).reload();
              await ref.read(collapseBannersProvider.notifier).reload();
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

    // Process daily login for XP rewards (runs in background)
    _processDailyLogin();
  }

  /// Process daily login to award XP bonuses
  Future<void> _processDailyLogin() async {
    try {
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;
      if (userId == null) return;

      final xpNotifier = ref.read(xpProvider.notifier);

      // First load user XP data so we have it available
      await xpNotifier.loadAll(userId: userId);

      // Then process daily login to award XP
      final result = await xpNotifier.processDailyLogin();

      if (result != null && mounted) {
        // Load active XP events (Double XP, etc.)
        await xpNotifier.loadActiveEvents();

        // Initialize streak tracking for milestone detection
        xpNotifier.initializeStreakTracking();

        // Check for streak milestones (7, 30, 100, 365 days)
        // This triggers celebration UI when user hits a milestone
        xpNotifier.checkStreakMilestone(result.currentStreak);

        // Initialize daily goals with login status
        // This sets dailyGoals.loggedIn = true based on loginStreak.hasLoggedInToday
        xpNotifier.initializeDailyGoals();

        // Show celebration if significant XP was awarded
        if (result.isSignificant && !result.alreadyClaimed) {
          _showDailyLoginCelebration(result);
        }
      }
    } catch (e) {
      debugPrint('❌ [Home] Error processing daily login: $e');
    }
  }

  /// Show a celebration for daily login rewards
  void _showDailyLoginCelebration(dynamic result) {
    if (!mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    // Build message based on what was earned
    String title = '🎉 Welcome Back!';
    String message = '+${result.totalXpAwarded} XP';

    if (result.isFirstLogin) {
      title = '🎉 Welcome to FitWiz!';
      message = 'You earned +${result.firstLoginXp} XP bonus!';
    } else if (result.streakMilestoneXp > 0) {
      title = '🔥 Streak Milestone!';
      message = '${result.currentStreak} days! +${result.totalXpAwarded} XP';
    } else if (result.hasDoubleXP) {
      title = '⚡ Double XP Active!';
      message = '+${result.totalXpAwarded} XP (2x bonus!)';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: Colors.amber,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    message,
                    style: TextStyle(
                      color: textPrimary.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (result.currentStreak > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${result.currentStreak}',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        backgroundColor: elevatedColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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

  /// Build a section header for the home screen
  Widget _buildHomeSectionHeader(String title, bool isDark, {IconData? icon}) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentColor = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: accentColor.withValues(alpha: 0.7)),
            const SizedBox(width: 8),
          ],
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textMuted,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Build all visible layout tiles as slivers for dynamic rendering
  /// Tiles are organized into logical sections with headers
  List<Widget> _buildLayoutTilesAsSlivers(
    BuildContext context,
    HomeLayout? layout,
    bool isDark,
    AsyncValue<TodayWorkoutResponse?> todayWorkoutState,
    bool isAIGenerating,
  ) {
    if (layout == null) {
      return _buildFallbackTilesAsSlivers(context, isDark, todayWorkoutState, isAIGenerating);
    }

    // Tiles to skip (deprecated or return empty)
    const deprecatedTiles = {
      TileType.heroSection,
      TileType.weightTrend,
      TileType.sleepScore,
      TileType.streakCounter,
      TileType.upcomingFeatures,
      TileType.weeklyProgress, // Deprecated
    };

    // Get visible tiles, sorted by order
    final visibleTiles = layout.tiles
        .where((t) => t.isVisible && !deprecatedTiles.contains(t.type))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    if (visibleTiles.isEmpty) {
      return _buildFallbackTilesAsSlivers(context, isDark, todayWorkoutState, isAIGenerating);
    }

    // Define section groups and their tile types
    const insightsTiles = {TileType.aiCoachTip, TileType.personalRecords, TileType.fitnessScore};
    const goalsTiles = {TileType.weeklyGoals, TileType.weekChanges};
    const trackingTiles = {TileType.habits, TileType.bodyWeight, TileType.achievements, TileType.dailyStats, TileType.quickLogWeight, TileType.quickLogMeasurements, TileType.todayStats};

    // Group tiles by section
    final workoutTiles = <HomeTile>[];  // nextWorkout, quickStart, quickActions
    final insightTilesList = <HomeTile>[];
    final goalsTilesList = <HomeTile>[];
    final trackingTilesList = <HomeTile>[];
    final otherTiles = <HomeTile>[];

    for (final tile in visibleTiles) {
      if (tile.type == TileType.nextWorkout || tile.type == TileType.quickStart || tile.type == TileType.quickActions) {
        workoutTiles.add(tile);
      } else if (insightsTiles.contains(tile.type)) {
        insightTilesList.add(tile);
      } else if (goalsTiles.contains(tile.type)) {
        goalsTilesList.add(tile);
      } else if (trackingTiles.contains(tile.type)) {
        trackingTilesList.add(tile);
      } else {
        otherTiles.add(tile);
      }
    }

    final slivers = <Widget>[];

    // Helper to render a group of tiles
    void renderTileGroup(List<HomeTile> tiles) {
      final halfWidthTiles = <HomeTile>[];

      for (final tile in tiles) {
        // Special handling for nextWorkout - use hero section logic
        if (tile.type == TileType.nextWorkout) {
          if (halfWidthTiles.isNotEmpty) {
            slivers.add(SliverToBoxAdapter(
              child: TileFactory.buildHalfWidthRow(context, ref, halfWidthTiles.toList(), isDark),
            ));
            halfWidthTiles.clear();
          }
          slivers.add(SliverToBoxAdapter(
            child: _buildHeroSectionFixed(context, todayWorkoutState, isAIGenerating, isDark),
          ));
          continue;
        }

        // Tiles that have their own padding (don't wrap with extra padding)
        const tilesWithOwnPadding = {
          TileType.habits,
          TileType.bodyWeight,
          TileType.achievements,
          TileType.weeklyGoals,
          TileType.weekChanges,
          TileType.aiCoachTip,
          TileType.personalRecords,
          TileType.fitnessScore,
          TileType.todayStats,
        };

        if (tilesWithOwnPadding.contains(tile.type)) {
          if (halfWidthTiles.isNotEmpty) {
            slivers.add(SliverToBoxAdapter(
              child: TileFactory.buildHalfWidthRow(context, ref, halfWidthTiles.toList(), isDark),
            ));
            halfWidthTiles.clear();
          }
          slivers.add(SliverToBoxAdapter(
            child: TileFactory.buildTile(context, ref, tile, isDark: isDark),
          ));
          continue;
        }

        // Half-width tiles - group in pairs
        if (tile.size == TileSize.half) {
          halfWidthTiles.add(tile);
          if (halfWidthTiles.length == 2) {
            slivers.add(SliverToBoxAdapter(
              child: TileFactory.buildHalfWidthRow(context, ref, halfWidthTiles.toList(), isDark),
            ));
            halfWidthTiles.clear();
          }
          continue;
        }

        // Flush pending half-width tiles
        if (halfWidthTiles.isNotEmpty) {
          slivers.add(SliverToBoxAdapter(
            child: TileFactory.buildHalfWidthRow(context, ref, halfWidthTiles.toList(), isDark),
          ));
          halfWidthTiles.clear();
        }

        // Full-width tile
        slivers.add(SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TileFactory.buildTile(context, ref, tile, isDark: isDark),
          ),
        ));
      }

      // Flush remaining half-width tiles
      if (halfWidthTiles.isNotEmpty) {
        slivers.add(SliverToBoxAdapter(
          child: TileFactory.buildHalfWidthRow(context, ref, halfWidthTiles, isDark),
        ));
      }
    }

    // Render workout section (no header - it's the main focus)
    if (workoutTiles.isNotEmpty) {
      renderTileGroup(workoutTiles);
    }

    // Render insights section
    if (insightTilesList.isNotEmpty) {
      slivers.add(SliverToBoxAdapter(
        child: _buildHomeSectionHeader('Insights', isDark, icon: Icons.lightbulb_outline),
      ));
      renderTileGroup(insightTilesList);
    }

    // Render goals section
    if (goalsTilesList.isNotEmpty) {
      slivers.add(SliverToBoxAdapter(
        child: _buildHomeSectionHeader('Goals & Progress', isDark, icon: Icons.flag_outlined),
      ));
      renderTileGroup(goalsTilesList);
    }

    // Render tracking section
    if (trackingTilesList.isNotEmpty) {
      slivers.add(SliverToBoxAdapter(
        child: _buildHomeSectionHeader('Tracking', isDark, icon: Icons.timeline),
      ));
      renderTileGroup(trackingTilesList);
    }

    // Render other tiles if any
    if (otherTiles.isNotEmpty) {
      slivers.add(SliverToBoxAdapter(
        child: _buildHomeSectionHeader('More', isDark),
      ));
      renderTileGroup(otherTiles);
    }

    return slivers;
  }

  /// Fallback tiles when layout fails to load
  List<Widget> _buildFallbackTilesAsSlivers(
    BuildContext context,
    bool isDark,
    AsyncValue<TodayWorkoutResponse?> todayWorkoutState,
    bool isAIGenerating,
  ) {
    return [
      // Hero workout section
      SliverToBoxAdapter(
        child: _buildHeroSectionFixed(context, todayWorkoutState, isAIGenerating, isDark),
      ),
      // Quick actions row
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: QuickActionsRow(),
        ),
      ),
      // Habits section
      const SliverToBoxAdapter(child: HabitsSection()),
      // Body metrics section
      const SliverToBoxAdapter(child: BodyMetricsSection()),
      // Achievements section
      const SliverToBoxAdapter(child: AchievementsSection()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    // Use todayWorkoutProvider for lazy loading (only fetches today's/next workout)
    final todayWorkoutState = ref.watch(todayWorkoutProvider);
    final user = authState.user;
    final isAIGenerating = ref.watch(aiGeneratingWorkoutProvider);
    final activeLayoutState = ref.watch(activeLayoutProvider);
    // Watch local layout for tile visibility settings
    final localLayoutState = ref.watch(localLayoutProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    // Watch the current streak from XP provider (login streak)
    final currentStreak = ref.watch(xpCurrentStreakProvider);

    // Watch header style and banner collapse preferences
    final headerStyle = ref.watch(headerStyleProvider);
    final collapseBanners = ref.watch(collapseBannersProvider);

    // Get responsive padding based on window mode
    final horizontalPadding = responsiveHorizontalPadding;
    final verticalPadding = responsiveVerticalPadding;

    // Listen for level-up events and show celebration dialog
    ref.listen<LevelUpEvent?>(levelUpEventProvider, (previous, next) {
      if (next != null && previous == null) {
        // Level up occurred - show celebration dialog
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            showLevelUpDialog(
              context,
              next,
              () {
                // Clear the level-up event after dialog is dismissed
                ref.read(xpProvider.notifier).clearLevelUp();
              },
            );
          }
        });
      }
    });

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

    return Scaffold(
      backgroundColor: backgroundColor,
      body: RefreshIndicator(
          onRefresh: () async {
            debugPrint('🔄 [Home] Pull-to-refresh triggered');
            _lastRefreshTime = DateTime.now();
            // Invalidate todayWorkoutProvider to refetch
            ref.invalidate(todayWorkoutProvider);
            // Also refresh layout in case it changed
            ref.invalidate(activeLayoutProvider);
            debugPrint('✅ [Home] Pull-to-refresh complete');
          },
          color: AppColors.cyan,
          backgroundColor: elevatedColor,
          child: SafeArea(
            child: CustomScrollView(
            slivers: [
              // Header: Minimal or Classic based on preset
              if (headerStyle == HeaderStyle.minimal)
                SliverToBoxAdapter(
                  child: MinimalHeader(),
                )
              else
                SliverToBoxAdapter(
                  child: _buildCombinedHeader(
                    context,
                    currentStreak,
                    isDark,
                    isCompact: isInSplitScreen || isNarrowLayout,
                  ),
                ),

              // Banners: Collapsed strip or full individual banners
              if (collapseBanners)
                const SliverToBoxAdapter(
                  child: CollapsedBannerStrip(),
                )
              else ...[
                // Daily XP Strip - Shows daily goals progress
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 8),
                    child: DailyXPStrip(),
                  ),
                ),
                // Contextual Banner - Personalized, dismissible tips
                SliverToBoxAdapter(
                  child: ContextualBanner(isDark: isDark),
                ),
                // Double XP Banner - Shows when Double XP event is active
                const SliverToBoxAdapter(
                  child: DoubleXPBanner(),
                ),
                // Daily Crate Banner - Shows when user has unclaimed daily crates
                const SliverToBoxAdapter(
                  child: DailyCrateBanner(),
                ),
              ],

              // Dynamic tiles from local layout
              ...localLayoutState.when(
                loading: () => [const SliverToBoxAdapter(child: SizedBox.shrink())],
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

  /// Build tiles dynamically based on the active layout
  List<Widget> _buildDynamicTiles(
    BuildContext context,
    AsyncValue<HomeLayout?> activeLayoutState,
    bool isDark,
    AsyncValue workoutsState,
    WorkoutsNotifier workoutsNotifier,
    dynamic nextWorkout,
    bool isAIGenerating,
    (int, int) weeklyProgress,
    List upcomingWorkouts,
  ) {
    return activeLayoutState.when(
      loading: () => [
        const SliverToBoxAdapter(
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      error: (error, _) => [
        // Fallback to default layout on error
        ..._buildDefaultTiles(
          context,
          isDark,
          workoutsState,
          workoutsNotifier,
          nextWorkout,
          isAIGenerating,
          weeklyProgress,
          upcomingWorkouts,
        ),
      ],
      data: (layout) {
        // Fallback to default layout if layout is null or has no tiles
        if (layout == null || layout.tiles.isEmpty) {
          return _buildDefaultTiles(
            context,
            isDark,
            workoutsState,
            workoutsNotifier,
            nextWorkout,
            isAIGenerating,
            weeklyProgress,
            upcomingWorkouts,
          );
        }

        // Tile types that have been removed/deprecated and return empty widgets
        const deprecatedTileTypes = {
          TileType.weeklyProgress,
          TileType.upcomingFeatures,
          TileType.upcomingWorkouts,
          TileType.heroSection,
          TileType.weightTrend,
          TileType.sleepScore,
          TileType.streakCounter,
        };

        final visibleTiles = layout.tiles
            .where((t) => t.isVisible && !deprecatedTileTypes.contains(t.type))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

        if (visibleTiles.isEmpty) {
          return _buildDefaultTiles(
            context,
            isDark,
            workoutsState,
            workoutsNotifier,
            nextWorkout,
            isAIGenerating,
            weeklyProgress,
            upcomingWorkouts,
          );
        }

        final slivers = <Widget>[];
        var i = 0;

        // Group YOUR WEEK tiles together
        final weekTileTypes = {
          TileType.weekChanges,
          TileType.weeklyGoals,
        };
        bool hasAddedWeekHeader = false;

        while (i < visibleTiles.length) {
          final tile = visibleTiles[i];

          // Add YOUR WEEK section header before first week-related tile
          if (weekTileTypes.contains(tile.type) && !hasAddedWeekHeader) {
            slivers.add(
              const SliverToBoxAdapter(
                child: SectionHeader(title: 'YOUR WEEK'),
              ),
            );
            hasAddedWeekHeader = true;
          }

          // Handle special tiles that need custom rendering
          if (tile.type == TileType.nextWorkout) {
            slivers.add(
              SliverToBoxAdapter(
                child: _buildNextWorkoutSection(
                  context,
                  workoutsState,
                  workoutsNotifier,
                  nextWorkout,
                  isAIGenerating,
                ),
              ),
            );
            i++;
            continue;
          }

          if (tile.type == TileType.upcomingWorkouts) {
            if (upcomingWorkouts.isNotEmpty) {
              slivers.add(
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'UPCOMING',
                    subtitle: '${upcomingWorkouts.length} workouts',
                    actionText: 'View All',
                    onAction: () {
                      HapticService.light();
                      context.push('/schedule');
                    },
                  ),
                ),
              );
              slivers.add(
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= upcomingWorkouts.length) return null;
                      final workout = upcomingWorkouts[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: AppAnimations.listItem,
                        child: SlideAnimation(
                          verticalOffset: 20,
                          curve: AppAnimations.fastOut,
                          child: FadeInAnimation(
                            curve: AppAnimations.fastOut,
                            child: UpcomingWorkoutCard(
                              workout: workout,
                              onTap: () => context.push('/workout/${workout.id}'),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: upcomingWorkouts.length.clamp(0, 1),
                  ),
                ),
              );
            }
            i++;
            continue;
          }

          // Handle half-width tiles - group them in pairs
          // In split screen or narrow layouts, render half-width tiles as full width
          if (tile.size == TileSize.half) {
            // Check if we're in a narrow layout where side-by-side doesn't work well
            final forceFullWidth = isInSplitScreen || windowWidth < 400;

            if (forceFullWidth) {
              // Render as full-width tile in narrow layouts
              slivers.add(
                SliverToBoxAdapter(
                  child: TileFactory.buildTile(
                    context,
                    ref,
                    tile.copyWith(size: TileSize.full),
                    isDark: isDark,
                  ),
                ),
              );
              i++;
              continue;
            }

            final halfTiles = <HomeTile>[tile];
            if (i + 1 < visibleTiles.length &&
                visibleTiles[i + 1].size == TileSize.half &&
                visibleTiles[i + 1].isVisible) {
              halfTiles.add(visibleTiles[i + 1]);
              i++;
            }

            slivers.add(
              SliverToBoxAdapter(
                child: TileFactory.buildHalfWidthRow(
                  context,
                  ref,
                  halfTiles,
                  isDark,
                ),
              ),
            );
            i++;
            continue;
          }

          // Full-width tile
          slivers.add(
            SliverToBoxAdapter(
              child: TileFactory.buildTile(context, ref, tile, isDark: isDark),
            ),
          );
          i++;
        }

        return slivers;
      },
    );
  }

  /// Build tiles dynamically based on active layout using lazy loading (todayWorkoutProvider)
  /// This version only shows the next workout card - no UPCOMING or YOUR WEEK sections
  List<Widget> _buildDynamicTilesLazy(
    BuildContext context,
    AsyncValue<HomeLayout?> activeLayoutState,
    bool isDark,
    AsyncValue<TodayWorkoutResponse?> todayWorkoutState,
    bool isAIGenerating,
  ) {
    return activeLayoutState.when(
      loading: () => [
        const SliverToBoxAdapter(
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      error: (error, _) => [
        ..._buildDefaultTilesLazy(context, isDark, todayWorkoutState, isAIGenerating),
      ],
      data: (layout) {
        // If no layout or no tiles, use default tiles
        if (layout == null || layout.tiles.isEmpty) {
          return _buildDefaultTilesLazy(context, isDark, todayWorkoutState, isAIGenerating);
        }

        // Tile types that have been removed/deprecated and return empty widgets
        const deprecatedTileTypes = {
          TileType.weeklyProgress,
          TileType.upcomingFeatures,
          TileType.upcomingWorkouts,
          TileType.heroSection,
          TileType.weightTrend,
          TileType.sleepScore,
          TileType.streakCounter,
        };

        // Get visible tiles sorted by order, filtering out deprecated types
        final visibleTiles = layout.tiles
            .where((t) => t.isVisible && !deprecatedTileTypes.contains(t.type))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

        if (visibleTiles.isEmpty) {
          return _buildDefaultTilesLazy(context, isDark, todayWorkoutState, isAIGenerating);
        }

        // Build tiles from layout configuration
        return _buildLayoutTilesLazy(context, visibleTiles, isDark, todayWorkoutState, isAIGenerating);
      },
    );
  }

  /// Build tiles based on the saved layout configuration
  List<Widget> _buildLayoutTilesLazy(
    BuildContext context,
    List<HomeTile> visibleTiles,
    bool isDark,
    AsyncValue<TodayWorkoutResponse?> todayWorkoutState,
    bool isAIGenerating,
  ) {
    final slivers = <Widget>[];
    var i = 0;

    // Get the workout for hero section if needed
    final todayWorkout = _getTodayWorkoutFromState(todayWorkoutState);
    final isGenerating = _isGeneratingFromState(todayWorkoutState);

    while (i < visibleTiles.length) {
      final tile = visibleTiles[i];

      // Skip hero section tiles (removed)
      if (tile.type == TileType.heroSection) {
        i++;
        continue;
      }

      // Handle half-size tiles (pair them in a row)
      if (tile.size == TileSize.half) {
        final halfTiles = <HomeTile>[tile];
        // Check if next tile is also half-size
        if (i + 1 < visibleTiles.length &&
            visibleTiles[i + 1].size == TileSize.half &&
            visibleTiles[i + 1].isVisible) {
          halfTiles.add(visibleTiles[i + 1]);
          i++;
        }

        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: halfTiles.map((t) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: halfTiles.length > 1 && t == halfTiles.first ? 8 : 0,
                        left: halfTiles.length > 1 && t == halfTiles.last ? 8 : 0,
                      ),
                      child: TileFactory.buildTile(context, ref, t, isDark: isDark),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
        i++;
        continue;
      }

      // Full or compact tiles
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
            child: TileFactory.buildTile(context, ref, tile, isDark: isDark),
          ),
        ),
      );
      i++;
    }

    return slivers;
  }

  /// Build default tiles using lazy loading (todayWorkoutProvider)
  /// Action-focused layout: Quick actions, Week progress, My Program
  List<Widget> _buildDefaultTilesLazy(
    BuildContext context,
    bool isDark,
    AsyncValue<TodayWorkoutResponse?> todayWorkoutState,
    bool isAIGenerating,
  ) {
    return [
      // Quick Actions Row - Food, Water, Fasting, Stats
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 8, bottom: 8),
          child: QuickActionsRow(),
        ),
      ),

      // My Program Summary - visible access to workout preferences
      const SliverToBoxAdapter(
        child: MyProgramSummaryCard(),
      ),
    ];
  }

  /// Extract workout from todayWorkoutProvider state
  Workout? _getTodayWorkoutFromState(AsyncValue<TodayWorkoutResponse?> state) {
    return state.whenOrNull(
      data: (response) {
        if (response == null) return null;
        if (response.isGenerating) return null;
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

  /// Build hero workout section using the new HeroWorkoutCard
  Widget _buildHeroWorkoutSection(
    BuildContext context,
    AsyncValue<TodayWorkoutResponse?> todayWorkoutState,
    bool isAIGenerating,
  ) {
    // Show loading during initial app load
    if (_isInitializing) {
      return const GeneratingHeroCard(
        message: 'Loading your workout...',
      );
    }

    return todayWorkoutState.when(
      loading: () => const GeneratingHeroCard(
        message: 'Loading workout...',
      ),
      error: (e, _) {
        debugPrint('⚠️ [Home] todayWorkoutProvider error: $e');
        return _buildFallbackHeroCard(context);
      },
      data: (response) {
        if (response == null) {
          return _buildFallbackHeroCard(context);
        }

        // Show generating card if workout is being generated
        if (response.isGenerating) {
          return GeneratingHeroCard(
            message: response.generationMessage ?? 'Generating your workout...',
          );
        }

        // Get the workout to display (today's or next upcoming)
        final workoutSummary = response.todayWorkout ?? response.nextWorkout;

        if (workoutSummary != null) {
          final workout = workoutSummary.toWorkout();
          return HeroWorkoutCard(
            workout: workout,
          );
        }

        // This should rarely happen since backend auto-generates
        return const GeneratingHeroCard(
          message: 'Loading your workout...',
        );
      },
    );
  }

  /// Fallback hero card when todayWorkoutProvider fails
  Widget _buildFallbackHeroCard(BuildContext context) {
    final workoutsAsync = ref.watch(workoutsProvider);

    return workoutsAsync.when(
      loading: () => const GeneratingHeroCard(message: 'Loading...'),
      error: (e, _) => const GeneratingHeroCard(message: 'Could not load workout'),
      data: (workouts) {
        final upcoming = workouts.where((w) => w.isCompleted != true).toList()
          ..sort((a, b) {
            if (a.scheduledDate == null) return 1;
            if (b.scheduledDate == null) return -1;
            return a.scheduledDate!.compareTo(b.scheduledDate!);
          });

        if (upcoming.isNotEmpty) {
          return HeroWorkoutCard(workout: upcoming.first);
        }

        return const GeneratingHeroCard(message: 'No workouts scheduled');
      },
    );
  }

  /// Build hero section with weekly carousel
  /// Shows carousel of workout cards for the current week
  Widget _buildHeroSectionFixed(
    BuildContext context,
    AsyncValue<TodayWorkoutResponse?> todayWorkoutState,
    bool isAIGenerating,
    bool isDark,
  ) {
    debugPrint('🏠 [HeroSection] Building hero section with carousel...');

    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    // During initial app load, show loading card
    Widget workoutContent;

    if (_isInitializing) {
      debugPrint('🏠 [HeroSection] Showing: GeneratingHeroCard (initializing)');
      workoutContent = const GeneratingHeroCard(
        message: 'Loading your workout...',
      );
    }
    // During AI generation, show generating card
    else if (isAIGenerating || todayWorkoutState.valueOrNull?.isGenerating == true) {
      debugPrint('🏠 [HeroSection] Showing: GeneratingHeroCard (generating)');
      workoutContent = GeneratingHeroCard(
        message: todayWorkoutState.valueOrNull?.generationMessage ?? 'Generating your workout...',
      );
    }
    // Otherwise show the carousel
    else {
      debugPrint('🏠 [HeroSection] Showing: HeroWorkoutCarousel');
      workoutContent = const HeroWorkoutCarousel();
    }

    // Return the section with header and workout content
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top spacing before WORKOUT header
        const SizedBox(height: 16),
        // Section header with "WORKOUT" and "View Programs" button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WORKOUT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Programs',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Coming Soon',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Workout carousel or loading card
        workoutContent,
      ],
    );
  }

  /// Check if a workout is scheduled for today
  bool _isWorkoutScheduledForToday(Workout workout) {
    return workout.isToday;
  }

  /// Build fixed trends section with progress cards
  /// Shows DailyStats and QuickLogWeight
  Widget _buildTrendsSection(bool isDark) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header - larger font for readability
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Your Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
          ),

          // Two half-width cards in a row - IntrinsicHeight ensures matching heights
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: DailyStatsCard(size: TileSize.half, isDark: isDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: QuickLogWeightCard(size: TileSize.half, isDark: isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build the next workout section using lazy loading (todayWorkoutProvider)
  Widget _buildNextWorkoutSectionLazy(
    BuildContext context,
    AsyncValue<TodayWorkoutResponse?> todayWorkoutState,
    bool isAIGenerating,
  ) {
    // Show loading card during initial app load
    if (_isInitializing) {
      return const GeneratingWorkoutsCard(
        message: 'Loading your workout...',
        subtitle: 'Preparing your personalized fitness plan',
      );
    }

    return todayWorkoutState.when(
      loading: () => const GeneratingWorkoutsCard(
        message: 'Loading workout...',
        subtitle: 'Please wait a moment',
      ),
      error: (e, _) {
        // Fallback to workoutsProvider on error
        debugPrint('⚠️ [Home] todayWorkoutProvider error, falling back to workoutsProvider: $e');
        return _buildFallbackWorkoutCard(context);
      },
      data: (response) {
        // If no response (endpoint might not be deployed), fallback to workoutsProvider
        if (response == null) {
          debugPrint('⚠️ [Home] todayWorkoutProvider returned null, falling back to workoutsProvider');
          return _buildFallbackWorkoutCard(context);
        }

        // If workout is being auto-generated, show generating card
        if (response.isGenerating) {
          return GeneratingWorkoutsCard(
            message: response.generationMessage ?? 'Generating your workout...',
            subtitle: 'This usually takes a few seconds',
          );
        }

        // Get the workout to display (today's or next upcoming)
        // Hero card should ALWAYS show a workout
        final workoutSummary = response.todayWorkout ?? response.nextWorkout;

        if (workoutSummary != null) {
          // Convert summary to Workout for NextWorkoutCard
          final workout = workoutSummary.toWorkout();
          return NextWorkoutCard(
            workout: workout,
            onStart: () => context.push('/workout/${workout.id}'),
          );
        }

        // This should rarely happen since backend auto-generates
        // But as a fallback, show generating card
        return const GeneratingWorkoutsCard(
          message: 'Loading your workout...',
          subtitle: 'Please wait a moment',
        );
      },
    );
  }

  /// Fallback to workoutsProvider when todayWorkoutProvider fails
  /// This ensures the home screen still works even if the /workouts/today endpoint isn't deployed
  Widget _buildFallbackWorkoutCard(BuildContext context) {
    final workoutsState = ref.watch(workoutsProvider);

    return workoutsState.when(
      loading: () => const GeneratingWorkoutsCard(
        message: 'Loading workout...',
        subtitle: 'Please wait a moment',
      ),
      error: (e, _) => ErrorCard(
        message: 'Failed to load workout',
        onRetry: () => ref.invalidate(workoutsProvider),
      ),
      data: (workouts) {
        if (workouts.isEmpty) {
          return _isCheckingWorkouts || _isStreamingGeneration
              ? const GeneratingWorkoutsCard(
                  message: 'Generating your personalized workout...',
                )
              : EmptyWorkoutCard(
                  onGenerate: () {
                    context.push('/workouts');
                  },
                );
        }

        // Find today's or next workout
        final today = DateTime.now();
        final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

        // Find today's incomplete workout
        final todayWorkout = workouts.where((w) =>
            (w.scheduledDate?.startsWith(todayStr) ?? false) && !(w.isCompleted ?? false)
        ).firstOrNull;

        if (todayWorkout != null) {
          return NextWorkoutCard(
            workout: todayWorkout,
            onStart: () => context.push('/workout/${todayWorkout.id}'),
          );
        }

        // Find next upcoming workout (future, not completed)
        final nextWorkout = workouts.where((w) {
          if (w.isCompleted ?? false) return false;
          final dateStr = w.scheduledDate;
          if (dateStr == null) return false;
          try {
            final date = DateTime.parse(dateStr.split('T')[0]);
            return date.isAfter(today);
          } catch (_) {
            return false;
          }
        }).firstOrNull;

        if (nextWorkout != null) {
          return NextWorkoutCard(
            workout: nextWorkout,
            onStart: () => context.push('/workout/${nextWorkout.id}'),
          );
        }

        return EmptyWorkoutCard(
          onGenerate: () {
            context.push('/workouts');
          },
        );
      },
    );
  }


  /// Build tiles for edit mode with drag-to-reorder and visibility toggles
  List<Widget> _buildEditModeTiles(
    BuildContext context,
    bool isDark,
    AsyncValue workoutsState,
    WorkoutsNotifier workoutsNotifier,
    dynamic nextWorkout,
    bool isAIGenerating,
  ) {
    // Sort tiles by order for display
    final sortedTiles = List<HomeTile>.from(_editingTiles)
      ..sort((a, b) => a.order.compareTo(b.order));

    return [
      // Add Tile and Discover buttons row - at the top
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              // Add Tile button
              Expanded(
                child: Material(
                  color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => _showAddTileSheet(isDark),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.cyan.withValues(alpha: 0.3),
                          width: 2,
                          strokeAlign: BorderSide.strokeAlignInside,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            color: AppColors.cyan,
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Add Tile',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cyan,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Discover button
              Expanded(
                child: Material(
                  color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => _showDiscoverSheet(isDark),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.purple.withValues(alpha: 0.3),
                          width: 2,
                          strokeAlign: BorderSide.strokeAlignInside,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.explore,
                            color: AppColors.purple,
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Discover',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.purple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Drag to reorder • Tap size to resize • Tap eye to hide',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      SliverReorderableList(
        itemBuilder: (context, index) {
          final tile = sortedTiles[index];
          return _buildEditableTile(
            context,
            tile,
            index,
            isDark,
            workoutsState,
            workoutsNotifier,
            nextWorkout,
            isAIGenerating,
          );
        },
        itemCount: sortedTiles.length,
        onReorder: _onReorderTiles,
      ),
    ];
  }

  /// Build edit mode tiles for lazy loading version
  List<Widget> _buildEditModeTilesLazy(
    BuildContext context,
    bool isDark,
    AsyncValue<TodayWorkoutResponse?> todayWorkoutState,
    bool isAIGenerating,
  ) {
    // Sort tiles by order for display
    final sortedTiles = List<HomeTile>.from(_editingTiles)
      ..sort((a, b) => a.order.compareTo(b.order));

    return [
      // Add Tile and Discover buttons row - at the top
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              // Add Tile button
              Expanded(
                child: Material(
                  color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => _showAddTileSheet(isDark),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.cyan.withValues(alpha: 0.3),
                          width: 2,
                          strokeAlign: BorderSide.strokeAlignInside,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            color: AppColors.cyan,
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Add Tile',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cyan,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Discover button
              Expanded(
                child: Material(
                  color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => _showDiscoverSheet(isDark),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.purple.withValues(alpha: 0.3),
                          width: 2,
                          strokeAlign: BorderSide.strokeAlignInside,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.explore,
                            color: AppColors.purple,
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Discover',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.purple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Drag to reorder • Tap size to resize • Tap eye to hide',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      SliverReorderableList(
        itemBuilder: (context, index) {
          final tile = sortedTiles[index];
          return _buildEditableTileLazy(
            context,
            tile,
            index,
            isDark,
            todayWorkoutState,
            isAIGenerating,
          );
        },
        itemCount: sortedTiles.length,
        onReorder: _onReorderTiles,
      ),
    ];
  }

  /// Build a single tile in edit mode for lazy loading version
  Widget _buildEditableTileLazy(
    BuildContext context,
    HomeTile tile,
    int index,
    bool isDark,
    AsyncValue<TodayWorkoutResponse?> todayWorkoutState,
    bool isAIGenerating,
  ) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    // Build the actual tile content
    Widget tileContent;
    if (tile.type == TileType.heroSection) {
      // Hero section removed - return empty container
      tileContent = const SizedBox.shrink();
    } else {
      tileContent = TileFactory.buildTile(context, ref, tile, isDark: isDark);
    }

    return ReorderableDelayedDragStartListener(
      key: ValueKey(tile.id),
      index: index,
      child: AnimatedBuilder(
        animation: _wiggleController,
        builder: (context, child) {
          // Subtle wiggle animation
          final wiggle = _wiggleController.value * 2 - 1;
          final angle = wiggle * 0.006;

          return Transform.rotate(
            angle: angle,
            child: child,
          );
        },
        child: Stack(
          children: [
            // The tile content with opacity for hidden tiles
            Opacity(
              opacity: tile.isVisible ? 1.0 : 0.4,
              child: IgnorePointer(
                ignoring: true,
                child: tileContent,
              ),
            ),
            // Overlay with drag handle and visibility toggle
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.purple.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    // Drag handle
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: elevatedColor.withValues(alpha: 0.95),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          bottomLeft: Radius.circular(14),
                        ),
                      ),
                      child: Icon(
                        Icons.drag_handle_rounded,
                        color: AppColors.purple,
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    // Resize button (only if tile supports multiple sizes)
                    if (tile.type.supportedSizes.length > 1)
                      Listener(
                        onPointerDown: (_) {
                          _cycleTileSize(tile.id);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: elevatedColor.withValues(alpha: 0.95),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.aspect_ratio_rounded,
                                color: AppColors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                tile.size.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    // Visibility toggle
                    Listener(
                      onPointerDown: (_) {
                        _toggleTileVisibility(tile.id);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: elevatedColor.withValues(alpha: 0.95),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(14),
                            bottomRight: Radius.circular(14),
                          ),
                        ),
                        child: Icon(
                          tile.isVisible
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: tile.isVisible ? AppColors.cyan : AppColors.textMuted,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a single tile in edit mode with wiggle, drag handle, and visibility toggle
  Widget _buildEditableTile(
    BuildContext context,
    HomeTile tile,
    int index,
    bool isDark,
    AsyncValue workoutsState,
    WorkoutsNotifier workoutsNotifier,
    dynamic nextWorkout,
    bool isAIGenerating,
  ) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    // Build the actual tile content
    Widget tileContent;
    if (tile.type == TileType.nextWorkout) {
      tileContent = _buildNextWorkoutSection(
        context,
        workoutsState,
        workoutsNotifier,
        nextWorkout,
        isAIGenerating,
      );
    } else {
      tileContent = TileFactory.buildTile(context, ref, tile, isDark: isDark);
    }

    return ReorderableDelayedDragStartListener(
      key: ValueKey(tile.id),
      index: index,
      child: AnimatedBuilder(
        animation: _wiggleController,
        builder: (context, child) {
          // Subtle wiggle animation - reduced from 0.02 to 0.006 radians
          final wiggle = _wiggleController.value * 2 - 1; // -1 to 1
          final angle = wiggle * 0.006; // Very subtle rotation (~0.3 degrees)

          return Transform.rotate(
            angle: angle,
            child: child,
          );
        },
        child: Stack(
          children: [
            // The tile content with opacity for hidden tiles
            Opacity(
              opacity: tile.isVisible ? 1.0 : 0.4,
              child: IgnorePointer(
                // Disable interactions in edit mode
                ignoring: true,
                child: tileContent,
              ),
            ),
            // Overlay with drag handle and visibility toggle
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.purple.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    // Drag handle
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: elevatedColor.withValues(alpha: 0.95),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          bottomLeft: Radius.circular(14),
                        ),
                      ),
                      child: Icon(
                        Icons.drag_handle_rounded,
                        color: AppColors.purple,
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    // Resize button (only if tile supports multiple sizes)
                    // Wrapped in Listener to capture taps before ReorderableDelayedDragStartListener
                    if (tile.type.supportedSizes.length > 1)
                      Listener(
                        onPointerDown: (_) {
                          _cycleTileSize(tile.id);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: elevatedColor.withValues(alpha: 0.95),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.aspect_ratio_rounded,
                                color: AppColors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                tile.size.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Visibility toggle button
                    // Wrapped in Listener to capture taps before ReorderableDelayedDragStartListener
                    Listener(
                      onPointerDown: (_) {
                        _toggleTileVisibility(tile.id);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: elevatedColor.withValues(alpha: 0.95),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(14),
                            bottomRight: Radius.circular(14),
                          ),
                        ),
                        child: Icon(
                          tile.isVisible
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: tile.isVisible ? AppColors.cyan : AppColors.textMuted,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Tile type label
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tile.type.displayName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build default tiles when no layout is available
  List<Widget> _buildDefaultTiles(
    BuildContext context,
    bool isDark,
    AsyncValue workoutsState,
    WorkoutsNotifier workoutsNotifier,
    dynamic nextWorkout,
    bool isAIGenerating,
    (int, int) weeklyProgress,
    List upcomingWorkouts,
  ) {
    return [
      // Fitness Score Card
      const SliverToBoxAdapter(child: FitnessScoreCard()),

      // Mood Picker Card
      const SliverToBoxAdapter(child: MoodPickerCard()),

      // Daily Activity Card
      const SliverToBoxAdapter(child: DailyActivityCard()),

      // Next Workout Card
      SliverToBoxAdapter(
        child: _buildNextWorkoutSection(
          context,
          workoutsState,
          workoutsNotifier,
          nextWorkout,
          isAIGenerating,
        ),
      ),

      // Quick Actions Row
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 8, bottom: 8),
          child: QuickActionsRow(),
        ),
      ),

      // Section: YOUR WEEK
      const SliverToBoxAdapter(
        child: SectionHeader(title: 'YOUR WEEK'),
      ),

      // Week Changes Card
      const SliverToBoxAdapter(child: WeekChangesCard()),

      // Weekly Progress
      SliverToBoxAdapter(
        child: WeeklyProgressCard(
          completed: weeklyProgress.$1,
          total: weeklyProgress.$2,
          isDark: isDark,
        ).animateSlideRotate(delay: const Duration(milliseconds: 50)),
      ),

      // Weekly Goals Card
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: WeeklyGoalsCard(isDark: isDark)
              .animateSlideRotate(delay: const Duration(milliseconds: 100)),
        ),
      ),

      // Section: UPCOMING
      if (upcomingWorkouts.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: SectionHeader(
            title: 'UPCOMING',
            subtitle: '${upcomingWorkouts.length} workouts',
            actionText: 'View Schedule',
            onAction: () {
              HapticService.light();
              context.push('/schedule');
            },
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= upcomingWorkouts.length) return null;
              final workout = upcomingWorkouts[index];
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: AppAnimations.listItem,
                child: SlideAnimation(
                  verticalOffset: 20,
                  curve: AppAnimations.fastOut,
                  child: FadeInAnimation(
                    curve: AppAnimations.fastOut,
                    child: UpcomingWorkoutCard(
                      workout: workout,
                      onTap: () => context.push('/workout/${workout.id}'),
                    ),
                  ),
                ),
              );
            },
            childCount: upcomingWorkouts.length.clamp(0, 3),
          ),
        ),
      ],
    ];
  }

  /// Combined header with Gym Profile Switcher and icons on same row
  Widget _buildCombinedHeader(
    BuildContext context,
    int currentStreak,
    bool isDark, {
    bool isCompact = false,
  }) {
    final padding = isCompact ? 10.0 : 16.0;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 8),
      child: Row(
        children: [
          // Gym Profile Switcher - takes remaining space
          const Expanded(
            child: GymProfileSwitcher(collapsed: true),
          ),
          // Edit Home Screen button
          GestureDetector(
            onTap: () {
              HapticService.selection();
              context.push('/settings/homescreen');
            },
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.glassSurface
                    : AppColorsLight.glassSurface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.edit_outlined,
                size: 18,
                color: textSecondary,
              ),
            ),
          ),
          // Calendar Button
          CalendarIconButton(isDark: isDark),
          // Notification Bell
          NotificationBellButton(isDark: isDark),
          const SizedBox(width: 4),
          // Streak Badge - Consolidated metric
          _StreakBadge(streak: currentStreak, isDark: isDark, isCompact: isCompact),
          // XP Level Progress - Compact version in header (after streak)
          if (!isCompact) ...[
            const SizedBox(width: 8),
            const XPLevelBarCompact(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String userName,
    int currentStreak,
    bool isDark, {
    bool isCompact = false,
  }) {
    // Reduce padding and spacing in compact/split-screen mode
    final padding = isCompact ? 10.0 : 16.0;
    final spacing = isCompact ? 4.0 : 8.0;

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Row(
        children: [
          // Greeting and name - takes remaining space
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hide greeting in very compact mode to save space
                if (!isCompact)
                  Text(
                    _getGreeting(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                Text(
                  userName,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                        // Slightly smaller in compact mode
                        fontSize: isCompact ? 20 : null,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: spacing),
          // Calendar Button
          CalendarIconButton(isDark: isDark),
          // Notification Bell
          NotificationBellButton(isDark: isDark),
          const SizedBox(width: 4),
          // Streak Badge - Consolidated metric
          _StreakBadge(streak: currentStreak, isDark: isDark, isCompact: isCompact),
          // XP Level Progress - Compact version in header (after streak)
          if (!isCompact) ...[
            const SizedBox(width: 8),
            const XPLevelBarCompact(),
          ],
        ],
      ),
    );
  }

  Widget _buildNextWorkoutSection(
    BuildContext context,
    AsyncValue workoutsState,
    WorkoutsNotifier workoutsNotifier,
    dynamic nextWorkout,
    bool isAIGenerating,
  ) {
    // Show loading card during initial app load
    if (_isInitializing) {
      return const GeneratingWorkoutsCard(
        message: 'Loading your workouts...',
        subtitle: 'Preparing your personalized fitness plan',
      );
    }

    return workoutsState.when(
      loading: () => const GeneratingWorkoutsCard(
        message: 'Loading workouts...',
        subtitle: 'Please wait a moment',
      ),
      error: (e, _) => ErrorCard(
        message: 'Failed to load workouts',
        onRetry: () => workoutsNotifier.refresh(),
      ),
      data: (_) => (isAIGenerating && nextWorkout == null)
          ? const GeneratingWorkoutsCard(
              message: 'AI is generating your workout...',
            )
          : nextWorkout != null
              ? NextWorkoutCard(
                  workout: nextWorkout,
                  onStart: () => context.push('/workout/${nextWorkout.id}'),
                )
              : (_isCheckingWorkouts || _isStreamingGeneration)
                  ? const GeneratingWorkoutsCard(
                      message: 'Generating your personalized workouts...',
                    )
                  : EmptyWorkoutCard(
                      onGenerate: () {
                        // Navigate to Workouts tab where user can generate more
                        context.go('/workouts');
                      },
                    ),
    );
  }

  Widget _buildTodaySectionHeader(bool isDark) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Text(
            'TODAY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textMuted,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          CustomizeProgramButton(isDark: isDark),
        ],
      ),
    );
  }
}

/// Consolidated profile menu button with notification badge
class _ProfileMenuButton extends StatelessWidget {
  final bool isDark;
  final bool isCompact;

  const _ProfileMenuButton({
    required this.isDark,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = isCompact ? 20.0 : 24.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () {
            HapticService.light();
            _showProfileMenu(context);
          },
          icon: Icon(
            Icons.person_outline,
            color: AppColors.purple,
            size: iconSize,
          ),
          tooltip: 'Menu',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        // Notification indicator
        // Positioned(
        //   top: -2,
        //   right: -2,
        //   child: Container(
        //     width: 8,
        //     height: 8,
        //     decoration: BoxDecoration(
        //       color: AppColors.orange,
        //       shape: BoxShape.circle,
        //       border: Border.all(
        //         color: isDark ? AppColors.background : AppColorsLight.background,
        //         width: 1.5,
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }

  void _showProfileMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 24),

              // Profile option
              _MenuOption(
                icon: Icons.person_outline,
                label: 'Profile',
                onTap: () {
                  Navigator.pop(context);
                  context.push('/profile');
                },
                isDark: isDark,
              ),

              // Notifications option
              _MenuOption(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                badge: 0, // TODO: Connect to actual notification count
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to notifications
                },
                isDark: isDark,
              ),

              // Settings option
              _MenuOption(
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () {
                  Navigator.pop(context);
                  context.push('/settings');
                },
                isDark: isDark,
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final int? badge;

  const _MenuOption({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticService.light();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: glassSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.purple),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                ),
                if (badge != null && badge! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge! > 99 ? '99+' : '$badge',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                Icon(Icons.chevron_right, color: textSecondary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A badge showing the current workout streak with fire icon
class _StreakBadge extends StatelessWidget {
  final int streak;
  final bool isDark;
  final bool isCompact;

  const _StreakBadge({
    required this.streak,
    required this.isDark,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    // Reduce size in compact mode
    final horizontalPadding = isCompact ? 6.0 : 10.0;
    final verticalPadding = isCompact ? 4.0 : 6.0;
    final iconSize = isCompact ? 14.0 : 16.0;
    final fontSize = isCompact ? 12.0 : 14.0;

    return Tooltip(
      message: streak > 0 ? '$streak day streak!' : 'Start your streak!',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: streak > 0
                ? AppColors.orange.withOpacity(0.5)
                : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department,
              size: iconSize,
              color: streak > 0 ? AppColors.orange : (isDark ? AppColors.textMuted : AppColorsLight.textMuted),
            ),
            SizedBox(width: isCompact ? 2 : 4),
            Text(
              '$streak',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: streak > 0 ? AppColors.orange : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Dummy animation controller for backwards compatibility with deprecated edit mode code
class _DummyAnimationController extends ChangeNotifier {
  void repeat({bool reverse = false}) {}
  void stop() {}
  void reset() {}
  double get value => 0.0;
}

/// Focus pills for navigating between For You (Home), Workouts, Nutrition, and Fasting
class WorkoutCategoryPills extends ConsumerStatefulWidget {
  final bool isDark;

  const WorkoutCategoryPills({super.key, required this.isDark});

  @override
  ConsumerState<WorkoutCategoryPills> createState() => _WorkoutCategoryPillsState();
}

class _WorkoutCategoryPillsState extends ConsumerState<WorkoutCategoryPills> {
  late ScrollController _scrollController;
  bool _hasAnimated = false;

  static final List<Map<String, dynamic>> _focusOptions = [
    {'label': 'For You', 'icon': Icons.star_rounded, 'route': null, 'color': AppColors.textPrimary},
    {'label': 'Workout', 'icon': Icons.fitness_center, 'route': '/workouts', 'color': AppColors.textPrimary},
    {'label': 'Nutrition', 'icon': Icons.restaurant, 'route': '/nutrition', 'color': AppColors.textPrimary},
    {'label': 'Fasting', 'icon': Icons.timer, 'route': '/fasting', 'color': AppColors.textPrimary},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Trigger scroll hint animation after widget builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animateScrollHint();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _animateScrollHint() async {
    if (_hasAnimated || !mounted) return;
    _hasAnimated = true;

    // Wait for initial stagger animations to complete
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted || !_scrollController.hasClients) return;

    // Scroll right to show hidden pills (Fasting)
    await _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );

    // Brief pause at the end
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted || !_scrollController.hasClients) return;

    // Scroll back to start
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    // Determine which pill is active based on current route
    final location = GoRouterState.of(context).matchedLocation;
    int activeIndex = 0; // Default to "For You"
    if (location.startsWith('/workouts')) {
      activeIndex = 1;
    } else if (location.startsWith('/nutrition')) {
      activeIndex = 2;
    } else if (location.startsWith('/fasting')) {
      activeIndex = 3;
    }

    // Get dynamic accent color from provider
    final colors = ref.colors(context);

    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return AnimationLimiter(
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Edit/Pencil icon button before pills
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  HapticService.selection();
                  context.push('/settings/homescreen');
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.glassSurface
                        : AppColorsLight.glassSurface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: textSecondary,
                  ),
                ),
              ),
            ),
            // Category pills
            ...AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 400),
              childAnimationBuilder: (widget) => SlideAnimation(
                horizontalOffset: 50.0,
                child: FadeInAnimation(child: widget),
              ),
              children: _focusOptions.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final isActive = index == activeIndex;
              // Use dynamic accent color from provider
              final activeColor = colors.accent;
              final route = option['route'] as String?;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _CategoryPill(
                  label: option['label'] as String,
                  icon: option['icon'] as IconData,
                  isActive: isActive,
                  isDark: isDark,
                  activeColor: activeColor,
                  onTap: () {
                    HapticService.selection();
                    if (route != null) {
                      // Navigate to the respective page
                      context.push(route);
                    }
                    // "For You" stays on Home - no navigation needed
                  },
                ),
              );
            }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isDark;
  final Color activeColor;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.isDark,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg = activeColor;
    final inactiveBg = isDark
        ? AppColors.glassSurface
        : AppColorsLight.glassSurface;
    // In dark mode (white bg), text is black. In light mode (black bg), text is white.
    final activeText = isDark ? Colors.black : Colors.white;
    final inactiveText = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: Material(
        color: isActive ? activeBg : inactiveBg,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isActive ? 16 : 14,
              vertical: isActive ? 10 : 8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive
                    ? activeBg
                    : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
                width: isActive ? 0 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isActive ? activeText : inactiveText,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? activeText : inactiveText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
