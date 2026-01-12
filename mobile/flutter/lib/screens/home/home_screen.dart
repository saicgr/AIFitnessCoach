import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/window_mode_provider.dart';
import '../../data/models/home_layout.dart';
import '../../data/providers/home_layout_provider.dart';
import '../../data/services/haptic_service.dart';
import '../../data/providers/branded_program_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/workout.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/providers/today_workout_provider.dart';
import '../../data/services/deep_link_service.dart';
import '../../data/services/health_service.dart';
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
import 'widgets/week_progress_strip.dart';

/// Preset layout templates for quick customization
class LayoutPreset {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final List<TileType> tiles;

  const LayoutPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.tiles,
  });

  /// Convert to HomeTile list
  List<HomeTile> toHomeTiles() {
    return tiles.asMap().entries.map((entry) {
      return HomeTile(
        id: 'tile_${DateTime.now().millisecondsSinceEpoch}_${entry.key}',
        type: entry.value,
        size: entry.value.defaultSize,
        order: entry.key,
        isVisible: true,
      );
    }).toList();
  }
}

/// Available preset layouts
const List<LayoutPreset> layoutPresets = [
  LayoutPreset(
    id: 'gym_focused',
    name: 'Gym Focused',
    description: 'Workout-first layout for gym enthusiasts',
    emoji: '🏋️',
    tiles: [
      TileType.nextWorkout,
      TileType.streakCounter,
      TileType.personalRecords,
      TileType.weeklyProgress,
      TileType.muscleHeatmap,
      TileType.weekChanges,
      TileType.challengeProgress,
      TileType.upcomingWorkouts,
      TileType.quickActions,
      TileType.aiCoachTip,
    ],
  ),
  LayoutPreset(
    id: 'nutrition_focused',
    name: 'Nutrition Focused',
    description: 'Diet-first layout for tracking macros & meals',
    emoji: '🥗',
    tiles: [
      TileType.caloriesSummary,
      TileType.macroRings,
      TileType.quickActions,
      TileType.bodyWeight,
      TileType.fasting,
      TileType.nextWorkout,
      TileType.weeklyProgress,
      TileType.moodPicker,
      TileType.sleepScore,
      TileType.aiCoachTip,
    ],
  ),
  LayoutPreset(
    id: 'balanced',
    name: 'Balanced',
    description: 'Best of both worlds - workouts & nutrition',
    emoji: '⚖️',
    tiles: [
      TileType.nextWorkout,
      TileType.fitnessScore,
      TileType.caloriesSummary,
      TileType.macroRings,
      TileType.weeklyProgress,
      TileType.streakCounter,
      TileType.bodyWeight,
      TileType.quickActions,
      TileType.weeklyGoals,
      TileType.upcomingWorkouts,
    ],
  ),
  LayoutPreset(
    id: 'minimal',
    name: 'Minimal',
    description: 'Clean, distraction-free essentials only',
    emoji: '✨',
    tiles: [
      TileType.nextWorkout,
      TileType.weeklyProgress,
      TileType.streakCounter,
      TileType.quickActions,
      TileType.aiCoachTip,
    ],
  ),
  LayoutPreset(
    id: 'wellness',
    name: 'Wellness',
    description: 'Focus on recovery, mood, and overall health',
    emoji: '🧘',
    tiles: [
      TileType.moodPicker,
      TileType.sleepScore,
      TileType.dailyActivity,
      TileType.restDayTip,
      TileType.nextWorkout,
      TileType.streakCounter,
      TileType.bodyWeight,
      TileType.weeklyGoals,
      TileType.aiCoachTip,
      TileType.quickActions,
    ],
  ),
  LayoutPreset(
    id: 'social',
    name: 'Social',
    description: 'Stay motivated with community features',
    emoji: '👥',
    tiles: [
      TileType.nextWorkout,
      TileType.leaderboardRank,
      TileType.socialFeed,
      TileType.challengeProgress,
      TileType.streakCounter,
      TileType.personalRecords,
      TileType.weeklyProgress,
      TileType.quickActions,
    ],
  ),
];

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
  static const Duration _minRefreshInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    // Register for app lifecycle events
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Reset nav bar labels to expanded when on Home screen
      ref.read(navBarLabelsExpandedProvider.notifier).state = true;
      _initializeWorkouts();
      _checkPendingWidgetAction();
      _initializeCurrentProgram();
      _initializeWindowModeTracking();
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
  Future<void> _autoRefreshIfNeeded() async {
    if (!mounted) return;

    final now = DateTime.now();
    if (_lastRefreshTime == null ||
        now.difference(_lastRefreshTime!) > _minRefreshInterval) {
      debugPrint('🔄 [Home] Auto-refreshing workouts...');
      _lastRefreshTime = now;
      final workoutsNotifier = ref.read(workoutsProvider.notifier);
      await workoutsNotifier.refresh();

      // Check mounted after async operation
      if (!mounted) return;

      // Force UI rebuild by invalidating the provider
      ref.invalidate(workoutsProvider);

      // Refresh Health Connect status - user may have granted permissions externally
      ref.read(healthSyncProvider.notifier).refreshConnectionStatus();
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
        TileType.quickActions,
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

    showModalBottomSheet(
      context: context,
      backgroundColor: elevatedColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
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

    showModalBottomSheet(
      context: context,
      backgroundColor: elevatedColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
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
                      child: Center(
                        child: Text(
                          preset.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
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
            Text(preset.emoji, style: const TextStyle(fontSize: 24)),
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
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _editingTiles = preset.toHomeTiles();
              });
              HapticService.success();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${preset.emoji} ${preset.name} layout applied!'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
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

    // Default tiles that match the original FitWiz layout
    final defaultTileTypes = [
      TileType.fitnessScore,
      TileType.moodPicker,
      TileType.dailyActivity,
      TileType.nextWorkout,
      TileType.quickActions,
      TileType.weekChanges,
      TileType.weeklyProgress,
      TileType.weeklyGoals,
      TileType.upcomingWorkouts,
      TileType.aiCoachTip,
    ];

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
          'This will restore the original FitWiz layout. Your current customizations will be replaced.',
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
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _editingTiles = defaultTileTypes.asMap().entries.map((entry) {
                  return HomeTile(
                    id: 'tile_${entry.key}',
                    type: entry.value,
                    order: entry.key,
                    isVisible: true,
                    size: TileSize.full,
                  );
                }).toList();
              });
              HapticService.success();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('🔄 Default layout restored!'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
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
    // Use todayWorkoutProvider for lazy loading (only fetches today's/next workout)
    final todayWorkoutState = ref.watch(todayWorkoutProvider);
    final user = authState.user;
    final isAIGenerating = ref.watch(aiGeneratingWorkoutProvider);
    final activeLayoutState = ref.watch(activeLayoutProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    // Get responsive padding based on window mode
    final horizontalPadding = responsiveHorizontalPadding;
    final verticalPadding = responsiveVerticalPadding;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: wrapWithSwipeDetector(
        child: RefreshIndicator(
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
              // Header - compact in split screen
              SliverToBoxAdapter(
                child: _buildHeader(
                  context,
                  user?.displayName ?? 'User',
                  0, // Streak is now shown elsewhere, not fetched here
                  isDark,
                  isCompact: isInSplitScreen || isNarrowLayout,
                ),
              ),

              // Category Pills - Workout Filtering
              SliverToBoxAdapter(
                child: WorkoutCategoryPills(isDark: isDark),
              ),

              // Contextual Banner - Personalized, dismissible tips
              SliverToBoxAdapter(
                child: ContextualBanner(isDark: isDark),
              ),

              // Watch Install Banner - One-time prompt for WearOS (Android only)
              // COMING SOON: Uncomment when WearOS app is ready for release
              // SliverToBoxAdapter(
              //   child: WatchInstallBanner(isDark: isDark),
              // ),

              // Hero Section - Today's Workout or Rest Day Card
              SliverToBoxAdapter(
                child: _buildHeroSectionFixed(
                  context,
                  todayWorkoutState,
                  isAIGenerating,
                  isDark,
                ),
              ),

              // Quick Actions Row
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: QuickActionsRow(),
                ),
              ),

              // Trends Section - Fixed progress cards
              SliverToBoxAdapter(
                child: _buildTrendsSection(isDark),
              ),

              // Bottom padding for nav bar
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
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

      // Week Progress Strip - day circles with completion count
      const SliverToBoxAdapter(
        child: WeekProgressStrip(),
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

  /// Build hero section - always shows today's workout or next upcoming workout
  /// Matches what is displayed in the Workouts tab
  Widget _buildHeroSectionFixed(
    BuildContext context,
    AsyncValue<TodayWorkoutResponse?> todayWorkoutState,
    bool isAIGenerating,
    bool isDark,
  ) {
    // Show loading during initial app load
    if (_isInitializing) {
      return const GeneratingHeroCard(
        message: 'Loading your workout...',
      );
    }

    // Handle loading state
    if (todayWorkoutState.isLoading) {
      return const GeneratingHeroCard(
        message: 'Loading workout...',
      );
    }

    // Handle error state - show empty card with retry
    if (todayWorkoutState.hasError) {
      debugPrint('⚠️ [Home] todayWorkoutProvider error: ${todayWorkoutState.error}');
      return EmptyWorkoutCard(
        onGenerate: () {
          HapticService.light();
          context.go('/workouts');
        },
      );
    }

    final response = todayWorkoutState.valueOrNull;

    // Check if generating
    if (response?.isGenerating == true || isAIGenerating) {
      return GeneratingHeroCard(
        message: response?.generationMessage ?? 'Generating your workout...',
      );
    }

    // No response - show empty state
    if (response == null) {
      return EmptyWorkoutCard(
        onGenerate: () {
          HapticService.light();
          context.go('/workouts');
        },
      );
    }

    // Get today's workout or next upcoming workout (same logic as Workouts tab)
    final workoutSummary = response.todayWorkout ?? response.nextWorkout;

    if (workoutSummary != null) {
      final workout = workoutSummary.toWorkout();
      // Always show the HeroWorkoutCard - whether it's today or upcoming
      return HeroWorkoutCard(workout: workout);
    }

    // No workouts available - show empty state to generate
    return EmptyWorkoutCard(
      onGenerate: () {
        HapticService.light();
        context.go('/workouts');
      },
    );
  }

  /// Check if a workout is scheduled for today
  bool _isWorkoutScheduledForToday(Workout workout) {
    final scheduledDate = workout.scheduledDate;
    if (scheduledDate == null) return false;

    try {
      final date = DateTime.parse(scheduledDate);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final workoutDate = DateTime(date.year, date.month, date.day);

      return workoutDate == today;
    } catch (_) {
      return false;
    }
  }

  /// Build fixed trends section with progress cards
  /// Shows DailyStats, QuickLogWeight, and WeekProgressStrip
  Widget _buildTrendsSection(bool isDark) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'YOUR PROGRESS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textMuted,
                letterSpacing: 1.5,
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

          const SizedBox(height: 16),

          // Week progress strip
          const WeekProgressStrip(),
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
          const Spacer(),
          // Streak Badge - Consolidated metric
          _StreakBadge(streak: currentStreak, isDark: isDark, isCompact: isCompact),
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

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
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
class WorkoutCategoryPills extends ConsumerWidget {
  final bool isDark;

  const WorkoutCategoryPills({super.key, required this.isDark});

  static final List<Map<String, dynamic>> _focusOptions = [
    {'label': 'For You', 'icon': Icons.star_rounded, 'route': null, 'color': AppColors.teal},
    {'label': 'Workout', 'icon': Icons.fitness_center, 'route': '/workouts', 'color': AppColors.cyan},
    {'label': 'Nutrition', 'icon': Icons.restaurant, 'route': '/nutrition', 'color': const Color(0xFF34C759)},
    {'label': 'Fasting', 'icon': Icons.timer, 'route': '/fasting', 'color': AppColors.orange},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return AnimationLimiter(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 400),
            childAnimationBuilder: (widget) => SlideAnimation(
              horizontalOffset: 50.0,
              child: FadeInAnimation(child: widget),
            ),
            children: _focusOptions.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final isActive = index == activeIndex;
              final activeColor = option['color'] as Color;
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
    const activeText = Colors.white;
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
