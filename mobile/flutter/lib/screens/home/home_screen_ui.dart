part of 'home_screen.dart';

/// Methods extracted from _HomeScreenState
extension __HomeScreenStateExt on _HomeScreenState {

  void _extInitState() {
    _carouselPageController = PageController(viewportFraction: 0.88);
    // Register for app lifecycle events
    WidgetsBinding.instance.addObserver(this);
    ref.read(posthogServiceProvider).capture(
      eventName: 'home_screen_viewed',
    );
    // Gate: route to the notification pre-permission screen once per install
    // before the user interacts with home. Runs async so it can read prefs.
    _maybeShowNotificationPrime();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Eagerly trigger todayWorkoutProvider so it starts loading before build()
      // If bootstrap already pre-seeded the cache, this returns instantly
      ref.read(todayWorkoutProvider);
      // Reset nav bar labels to expanded when on Home screen
      ref.read(navBarLabelsExpandedProvider.notifier).state = true;
      // M4: Run critical initialization tasks first, then non-critical ones
      // Nutrition/hydration loads in parallel with workouts so the Nutrition
      // tab has data ready before the user can tap it.
      await Future.wait([
        _initializeWorkouts().catchError((e) {
          debugPrint('❌ [Home] _initializeWorkouts error: $e');
        }),
        Future(() => _initializeCurrentProgram()).catchError((e) {
          debugPrint('❌ [Home] _initializeCurrentProgram error: $e');
        }),
        _initializeNutritionAndHydration().catchError((e) {
          debugPrint('❌ [Home] _initializeNutritionAndHydration error: $e');
        }),
      ]);
      // Non-critical tasks run after critical ones resolve
      if (!mounted) return;
      Future.wait([
        Future(() => _checkPendingWidgetAction()).catchError((e) {
          debugPrint('❌ [Home] _checkPendingWidgetAction error: $e');
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
      // Trigger nav tour after critical data has loaded so the home screen
      // is populated (workout card, calendar, etc.) before the spotlight appears.
      // The carouselKey is now always in the widget tree (even during loading),
      // so the spotlight will find it regardless of todayWorkoutProvider state.
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        // Don't trigger tour when returning from a minimized workout
        if (ref.read(isWorkoutMinimizedProvider)) return;
        _triggerNavTour();
      });
    });
  }

  /// Routes the user to the notification pre-permission screen once per
  /// install. The flag is flipped the moment that screen is shown (by the
  /// screen itself once the user picks Enable or Not now), so returning
  /// users skip this. Runs off the post-frame callback so navigation
  /// doesn't collide with this frame's build.
  Future<void> _maybeShowNotificationPrime() async {
    // Skip if we're coming back from a minimized workout — user is in-flow.
    if (ref.read(isWorkoutMinimizedProvider)) return;

    final prefs = await SharedPreferences.getInstance();
    final alreadyShown =
        prefs.getBool(NotificationPrimeScreen.prefsKey) ?? false;
    if (alreadyShown) return;
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Belt-and-suspenders: double-check we haven't been pushed somewhere else.
      final router = GoRouter.of(context);
      final current =
          router.routerDelegate.currentConfiguration.uri.toString();
      if (current != '/home' && current != '/senior-home') return;
      context.go('/notifications-prime');
    });
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
      case TileType.stepsCounter:
        return Icons.directions_walk;
      case TileType.nutritionPatterns:
        return Icons.restaurant_menu;
    }
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

}
