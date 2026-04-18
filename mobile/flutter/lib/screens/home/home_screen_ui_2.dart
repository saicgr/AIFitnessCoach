part of 'home_screen.dart';

/// UI builder methods extracted from _HomeScreenState
extension _HomeScreenStateUI2 on _HomeScreenState {

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
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: const QuickActionsRow(),
        ),
      ),

      // Free-tier usage counters (hidden for premium)
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: UsageCounterStrip(),
        ),
      ),

      // My Program Summary - visible access to workout preferences
      const SliverToBoxAdapter(
        child: MyProgramSummaryCard(),
      ),
    ];
  }


  /// Build hero workout section using the new HeroWorkoutCard
  Widget _buildHeroWorkoutSection(
    BuildContext context,
    AsyncValue<TodayWorkoutResponse?> todayWorkoutState,
    bool isAIGenerating,
  ) {
    // Show loading during initial app load, but only if provider has no data yet.
    // Skip this gate when provider has cached data (prevents flash on back-navigation).
    if (_isInitializing && !todayWorkoutState.hasValue) {
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

        // Get the workout to display (today's or next upcoming)
        final workoutSummary = response.todayWorkout ?? response.nextWorkout;

        // Only show generating card when no workout exists at all
        if (response.isGenerating && workoutSummary == null) {
          return GeneratingHeroCard(
            message: response.generationMessage ?? 'Generating your workout...',
          );
        }

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
            onStart: () => context.push('/workout/${workout.id}', extra: workout),
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
        onRetry: () => ref.read(workoutsProvider.notifier).silentRefresh(),
      ),
      data: (workouts) {
        if (workouts.isEmpty) {
          return _isCheckingWorkouts || _isStreamingGeneration
              ? const GeneratingWorkoutsCard(
                  message: 'Generating your personalized workout...',
                )
              : EmptyWorkoutCard(
                  onGenerate: () {
                    context.go('/workouts');
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
            onStart: () => context.push('/workout/${todayWorkout.id}', extra: todayWorkout),
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
            onStart: () => context.push('/workout/${nextWorkout.id}', extra: nextWorkout),
          );
        }

        return EmptyWorkoutCard(
          onGenerate: () {
            context.go('/workouts');
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

}
