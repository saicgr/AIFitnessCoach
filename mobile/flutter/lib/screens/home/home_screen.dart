import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/home_layout.dart';
import '../../data/providers/home_layout_provider.dart';
import '../../data/services/haptic_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/deep_link_service.dart';
import '../nutrition/log_meal_sheet.dart';
import 'widgets/components/components.dart';
import 'widgets/cards/cards.dart';
import 'widgets/daily_activity_card.dart';
import 'widgets/tile_factory.dart';

/// The main home screen displaying workouts, progress, and quick actions
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isCheckingWorkouts = false;
  bool _isStreamingGeneration = false;
  String? _generationStartDate;
  int _generationWeeks = 0;
  int _totalExpected = 0;
  int _totalGenerated = 0;
  String _generationMessage = '';
  String? _generationDetail;

  // Edit mode state
  bool _isEditMode = false;
  late AnimationController _wiggleController;
  List<HomeTile> _editingTiles = [];

  @override
  void initState() {
    super.initState();
    // Wiggle animation for edit mode (like iOS app icons)
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWorkouts();
      _checkPendingWidgetAction();
    });
  }

  @override
  void dispose() {
    _wiggleController.dispose();
    super.dispose();
  }

  void _enterEditMode() {
    final layout = ref.read(activeLayoutProvider).value;
    if (layout != null) {
      setState(() {
        _isEditMode = true;
        _editingTiles = List.from(layout.tiles);
      });
      _wiggleController.repeat(reverse: true);
      HapticService.medium();
    }
  }

  void _exitEditMode({bool save = true}) async {
    _wiggleController.stop();
    _wiggleController.reset();

    if (save && _editingTiles.isNotEmpty) {
      // Save the updated tiles
      await ref.read(activeLayoutProvider.notifier).updateTiles(_editingTiles);
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

  Future<void> _initializeWorkouts() async {
    final notifier = ref.read(workoutsProvider.notifier);

    // First refresh to get current workouts
    await notifier.refresh();

    // Clear banner state if workouts exist
    if (notifier.nextWorkout != null && mounted) {
      setState(() {
        _generationStartDate = null;
        _generationWeeks = 0;
        _totalExpected = 0;
        _totalGenerated = 0;
        _isStreamingGeneration = false;
      });
      return; // Don't check for generation if we already have workouts
    }

    // Check if we've already checked today (persisted across app restarts)
    final prefs = await SharedPreferences.getInstance();
    final lastCheckDate = prefs.getString('last_workout_check_date');
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Also check session-level flag (for tab switching within same session)
    final hasCheckedSession = ref.read(hasCheckedRegenerationProvider);

    if (lastCheckDate == today || hasCheckedSession) {
      debugPrint(
        'Debug: [HomeScreen] Skipping regeneration check - already done today ($lastCheckDate)',
      );
      return;
    }

    // Check if we need to generate workouts and use streaming for real-time progress
    if (!_isCheckingWorkouts && !_isStreamingGeneration) {
      setState(() => _isCheckingWorkouts = true);
      try {
        // If user has NO workouts at all, use streaming for immediate feedback
        final hasNoWorkouts = notifier.nextWorkout == null &&
            (notifier.state.valueOrNull?.isEmpty ?? true);

        if (hasNoWorkouts) {
          // Use streaming generation for first-time users
          await _generateWorkoutsWithStreaming();
        } else {
          // Use background check for users with existing workouts
          final result = await notifier.checkAndRegenerateIfNeeded();
          debugPrint(
            'Debug: [HomeScreen] Workout check result: ${result['message']}',
          );

          // If generation was triggered in background, show banner
          if (result['needs_generation'] == true && mounted) {
            setState(() {
              _generationStartDate = result['start_date'] as String?;
              _generationWeeks = (result['weeks'] as int?) ?? 4;
              _totalExpected = (result['total_expected'] as int?) ?? 0;
              _totalGenerated = (result['total_generated'] as int?) ?? 0;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Generating your upcoming workouts...'),
                backgroundColor: AppColors.elevated,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }

        // Mark as checked for this session AND persist today's date
        ref.read(hasCheckedRegenerationProvider.notifier).state = true;
        await prefs.setString('last_workout_check_date', today);
      } finally {
        if (mounted) {
          setState(() => _isCheckingWorkouts = false);
        }
      }
    }
  }

  /// Generate workouts with streaming progress for first-time users
  Future<void> _generateWorkoutsWithStreaming() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId == null) return;

    // Get user preferences for workout days
    final repo = ref.read(workoutRepositoryProvider);
    final prefs = await repo.getProgramPreferences(userId);

    // Convert day names to indices (0=Mon, 6=Sun)
    const dayNameToIndex = {
      'Monday': 0, 'Tuesday': 1, 'Wednesday': 2, 'Thursday': 3,
      'Friday': 4, 'Saturday': 5, 'Sunday': 6,
    };
    List<int> selectedDays;
    if (prefs?.workoutDays.isNotEmpty == true) {
      selectedDays = prefs!.workoutDays
          .map((name) => dayNameToIndex[name] ?? 0)
          .toList();
    } else {
      selectedDays = [0, 2, 4]; // Mon, Wed, Fri default
    }
    final durationMinutes = prefs?.durationMinutes ?? 45;

    setState(() {
      _isStreamingGeneration = true;
      _generationStartDate = DateTime.now().toIso8601String().split('T')[0];
      _totalExpected = 0;
      _totalGenerated = 0;
      _generationMessage = 'Starting workout generation...';
      _generationDetail = null;
    });

    try {
      await for (final progress in repo.generateMonthlyWorkoutsStreaming(
        userId: userId,
        selectedDays: selectedDays,
        durationMinutes: durationMinutes,
      )) {
        if (!mounted) return;

        if (progress.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${progress.message}'),
              backgroundColor: AppColors.error,
            ),
          );
          break;
        }

        if (progress.isCompleted) {
          // Generation complete - refresh workouts and clear generation state
          await ref.read(workoutsProvider.notifier).refresh();
          setState(() {
            _isStreamingGeneration = false;
            _generationStartDate = null;
            _totalExpected = 0;
            _totalGenerated = 0;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${progress.workouts.length} workouts ready!'),
              backgroundColor: AppColors.success,
            ),
          );
          break;
        }

        // Update progress UI
        setState(() {
          _totalExpected = progress.totalWorkouts;
          _totalGenerated = progress.currentWorkout;
          _generationMessage = progress.message;
          _generationDetail = progress.detail;
        });
      }
    } catch (e) {
      debugPrint('Error during streaming generation: $e');
      if (mounted) {
        setState(() => _isStreamingGeneration = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate workouts: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final workoutsState = ref.watch(workoutsProvider);
    final workoutsNotifier = ref.read(workoutsProvider.notifier);
    final user = authState.user;
    final isAIGenerating = ref.watch(aiGeneratingWorkoutProvider);
    final activeLayoutState = ref.watch(activeLayoutProvider);

    final nextWorkout = workoutsNotifier.nextWorkout;
    final upcomingWorkouts = workoutsNotifier.upcomingWorkouts;
    final weeklyProgress = workoutsNotifier.weeklyProgress;
    final currentStreak = workoutsNotifier.currentStreak;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await workoutsNotifier.refresh();
          ref.invalidate(activeLayoutProvider);
        },
        color: AppColors.cyan,
        backgroundColor: elevatedColor,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: _buildHeader(
                  context,
                  user?.displayName ?? 'User',
                  currentStreak,
                  isDark,
                ),
              ),

              // Streaming Generation Banner (for first-time users with real-time progress)
              if (_isStreamingGeneration && nextWorkout == null)
                SliverToBoxAdapter(
                  child: StreamingWorkoutGenerationCard(
                    isDark: isDark,
                    currentWorkout: _totalGenerated,
                    totalWorkouts: _totalExpected,
                    message: _generationMessage,
                    detail: _generationDetail,
                  ),
                ),

              // Legacy Generation Banner (for background generation)
              if (!_isStreamingGeneration &&
                  _generationStartDate != null &&
                  _generationWeeks > 0 &&
                  nextWorkout == null)
                SliverToBoxAdapter(
                  child: MoreWorkoutsLoadingBanner(
                    isDark: isDark,
                    startDate: _generationStartDate!,
                    weeks: _generationWeeks,
                    totalExpected: _totalExpected,
                    totalGenerated: _totalGenerated,
                  ),
                ),

              // Section: TODAY with Customize button
              SliverToBoxAdapter(
                child: _buildTodaySectionHeader(isDark),
              ),

              // Dynamic Tile Rendering based on active layout
              ..._buildDynamicTiles(
                context,
                activeLayoutState,
                isDark,
                workoutsState,
                workoutsNotifier,
                nextWorkout,
                isAIGenerating,
                weeklyProgress,
                upcomingWorkouts,
              ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
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
    // In edit mode, use the editing tiles list
    if (_isEditMode && _editingTiles.isNotEmpty) {
      return _buildEditModeTiles(context, isDark, workoutsState, workoutsNotifier, nextWorkout, isAIGenerating);
    }

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

        final visibleTiles = layout.tiles.where((t) => t.isVisible).toList()
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
          TileType.weeklyProgress,
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
                    childCount: upcomingWorkouts.length.clamp(0, 3),
                  ),
                ),
              );
            }
            i++;
            continue;
          }

          // Handle half-width tiles - group them in pairs
          if (tile.size == TileSize.half) {
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
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Drag cards to reorder • Tap eye to hide/show',
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
          // Wiggle animation like iOS icons
          final wiggle = _wiggleController.value * 2 - 1; // -1 to 1
          final angle = wiggle * 0.02; // Small rotation

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
                    // Visibility toggle button
                    GestureDetector(
                      onTap: () => _toggleTileVisibility(tile.id),
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

      // Upcoming Features Card
      const SliverToBoxAdapter(child: UpcomingFeaturesCard()),

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
            actionText: 'View All',
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

  Widget _buildHeader(
    BuildContext context,
    String userName,
    int currentStreak,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  userName,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // Streak Badge
          _StreakBadge(streak: currentStreak, isDark: isDark),
          const SizedBox(width: 8),
          _LibraryButton(isDark: isDark),
          const SizedBox(width: 4),
          NotificationBellButton(isDark: isDark),
          const SizedBox(width: 4),
          SettingsButton(isDark: isDark),
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
    return workoutsState.when(
      loading: () => const LoadingCard(),
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
              : _isCheckingWorkouts
                  ? const GeneratingWorkoutsCard()
                  : EmptyWorkoutCard(
                      onGenerate: () async {
                        setState(() => _isCheckingWorkouts = true);
                        final result = await workoutsNotifier
                            .checkAndRegenerateIfNeeded();
                        if (mounted) {
                          setState(() => _isCheckingWorkouts = false);
                          if (result['needs_generation'] != true) {
                            context.go('/onboarding');
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    const Text('Generating your workouts...'),
                                backgroundColor: AppColors.elevated,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
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
          if (_isEditMode) ...[
            // Done button in edit mode
            Material(
              color: AppColors.cyan,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () => _exitEditMode(save: true),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            // Edit button (replaces My Space)
            Material(
              color: elevatedColor,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: _enterEditMode,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.purple.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_rounded,
                        size: 16,
                        color: AppColors.purple,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CustomizeProgramButton(isDark: isDark),
          ],
        ],
      ),
    );
  }
}

/// A button that navigates to the library screen
class _LibraryButton extends StatelessWidget {
  final bool isDark;

  const _LibraryButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Material(
      color: elevatedColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          HapticService.light();
          context.push('/library');
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.purple.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fitness_center,
                size: 16,
                color: AppColors.purple,
              ),
              const SizedBox(width: 6),
              Text(
                'Library',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
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

  const _StreakBadge({
    required this.streak,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Tooltip(
      message: streak > 0 ? '$streak day streak!' : 'Start your streak!',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
              size: 16,
              color: streak > 0 ? AppColors.orange : (isDark ? AppColors.textMuted : AppColorsLight.textMuted),
            ),
            const SizedBox(width: 4),
            Text(
              '$streak',
              style: TextStyle(
                fontSize: 14,
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
