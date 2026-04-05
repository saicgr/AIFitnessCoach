part of 'home_screen.dart';

/// UI builder methods extracted from _HomeScreenState
extension _HomeScreenStateUI1 on _HomeScreenState {

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


  /// Build a section header for the home screen
  Widget _buildHomeSectionHeader(String title, bool isDark, {IconData? icon, bool showEdit = false}) {
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
          if (showEdit) ...[
            const Spacer(),
            GestureDetector(
              onTap: () {
                HapticService.light();
                showEditTrackingSheet(context);
              },
              child: Icon(
                Icons.edit_outlined,
                size: 16,
                color: textMuted,
              ),
            ),
          ],
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
      TileType.fasting, // COMING SOON: hidden pre-launch — remove from this set to re-enable
    };

    // Get visible tiles, sorted by order
    final visibleTiles = layout.tiles
        .where((t) => t.isVisible && !deprecatedTiles.contains(t.type))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    // Migration: ensure dailyActivity tile exists in layout (for users who saved before it was added)
    if (!layout.tiles.any((t) => t.type == TileType.dailyActivity)) {
      final dailyActivityTile = HomeTile(
        id: 'tile_daily_activity_migrated',
        type: TileType.dailyActivity,
        size: TileType.dailyActivity.defaultSize,
        order: visibleTiles.isEmpty ? 0 : visibleTiles.last.order + 1,
        isVisible: true,
      );
      visibleTiles.add(dailyActivityTile);
    }

    if (visibleTiles.isEmpty) {
      return _buildFallbackTilesAsSlivers(context, isDark, todayWorkoutState, isAIGenerating);
    }

    // Define section groups and their tile types
    // COMING SOON: TileType.fasting removed — re-add when fasting feature launches
    const nutritionTileTypes = {TileType.caloriesSummary, TileType.macroRings};
    const insightsTiles = {TileType.aiCoachTip, TileType.personalRecords, TileType.fitnessScore};
    const goalsTiles = {TileType.weeklyGoals, TileType.weekChanges};
    const trackingTiles = {TileType.habits, TileType.bodyWeight, TileType.achievements, TileType.dailyStats, TileType.quickLogWeight, TileType.quickLogMeasurements, TileType.todayStats};
    const wellnessTiles = {TileType.moodPicker};

    // Group tiles by section
    final workoutTiles = <HomeTile>[];  // nextWorkout, quickStart, quickActions
    final nutritionTilesList = <HomeTile>[];
    final insightTilesList = <HomeTile>[];
    final goalsTilesList = <HomeTile>[];
    final trackingTilesList = <HomeTile>[];
    final wellnessTilesList = <HomeTile>[];
    final otherTiles = <HomeTile>[];

    for (final tile in visibleTiles) {
      if (tile.type == TileType.nextWorkout || tile.type == TileType.quickStart || tile.type == TileType.quickActions) {
        workoutTiles.add(tile);
      } else if (nutritionTileTypes.contains(tile.type)) {
        nutritionTilesList.add(tile);
      } else if (insightsTiles.contains(tile.type)) {
        insightTilesList.add(tile);
      } else if (goalsTiles.contains(tile.type)) {
        goalsTilesList.add(tile);
      } else if (trackingTiles.contains(tile.type)) {
        trackingTilesList.add(tile);
      } else if (wellnessTiles.contains(tile.type)) {
        wellnessTilesList.add(tile);
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

    // Render nutrition section (right after workout for prominence)
    if (nutritionTilesList.isNotEmpty) {
      slivers.add(SliverToBoxAdapter(
        child: _buildHomeSectionHeader('Nutrition', isDark, icon: Icons.restaurant),
      ));
      renderTileGroup(nutritionTilesList);
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
        child: _buildHomeSectionHeader('Tracking', isDark, icon: Icons.timeline, showEdit: true),
      ));
      renderTileGroup(trackingTilesList);
    }

    // Render wellness section
    if (wellnessTilesList.isNotEmpty) {
      slivers.add(SliverToBoxAdapter(
        child: _buildHomeSectionHeader('Wellness', isDark, icon: Icons.spa),
      ));
      renderTileGroup(wellnessTilesList);
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
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
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
      // Habits section
      const SliverToBoxAdapter(child: HabitsSection()),
      // Body metrics section
      const SliverToBoxAdapter(child: BodyMetricsSection()),
      // Achievements section
      const SliverToBoxAdapter(child: AchievementsSection()),
    ];
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
          TileType.fasting, // COMING SOON: hidden pre-launch — remove from this set to re-enable
        };

        final visibleTiles = layout.tiles
            .where((t) => t.isVisible && !deprecatedTileTypes.contains(t.type))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

        // Migration: ensure dailyActivity tile exists in layout (for users who saved before it was added)
        if (!layout.tiles.any((t) => t.type == TileType.dailyActivity)) {
          final dailyActivityTile = HomeTile(
            id: 'tile_daily_activity_migrated',
            type: TileType.dailyActivity,
            size: TileType.dailyActivity.defaultSize,
            order: visibleTiles.isEmpty ? 0 : visibleTiles.last.order + 1,
            isVisible: true,
          );
          visibleTiles.add(dailyActivityTile);
        }

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
                              onTap: () => context.push('/workout/${workout.id}', extra: workout),
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
          TileType.fasting, // COMING SOON: hidden pre-launch — remove from this set to re-enable
        };

        // Get visible tiles sorted by order, filtering out deprecated types
        final visibleTiles = layout.tiles
            .where((t) => t.isVisible && !deprecatedTileTypes.contains(t.type))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

        // Migration: ensure dailyActivity tile exists in layout (for users who saved before it was added)
        if (!layout.tiles.any((t) => t.type == TileType.dailyActivity)) {
          final dailyActivityTile = HomeTile(
            id: 'tile_daily_activity_migrated',
            type: TileType.dailyActivity,
            size: TileType.dailyActivity.defaultSize,
            order: visibleTiles.isEmpty ? 0 : visibleTiles.last.order + 1,
            isVisible: true,
          );
          visibleTiles.add(dailyActivityTile);
        }

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

}
