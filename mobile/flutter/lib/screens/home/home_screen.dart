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
import '../../data/providers/multi_screen_tour_provider.dart';
import '../../widgets/multi_screen_tour_helper.dart';
import '../../data/services/haptic_service.dart';
import '../../data/providers/branded_program_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/providers/today_workout_provider.dart';
import '../../data/services/deep_link_service.dart';
import '../../data/services/health_service.dart';
import '../../widgets/responsive_layout.dart';
import '../nutrition/log_meal_sheet.dart';
import 'widgets/components/components.dart';
import 'widgets/cards/cards.dart';
import 'widgets/daily_activity_card.dart';
import 'widgets/renewal_reminder_banner.dart';
import 'widgets/missed_workout_banner.dart';
import 'widgets/tile_factory.dart';

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
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin, ResponsiveMixin, WidgetsBindingObserver {
  bool _isInitializing = true; // True until first workout check completes
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

  // Edit mode tooltip state
  final bool _hasShownEditModeTooltip = false;
  static const String _editModeTooltipKey = 'has_shown_edit_mode_tooltip';

  // Auto-refresh tracking
  DateTime? _lastRefreshTime;
  static const Duration _minRefreshInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    // Register for app lifecycle events
    WidgetsBinding.instance.addObserver(this);
    // Wiggle animation for edit mode (like iOS app icons)
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWorkouts();
      _checkPendingWidgetAction();
      _initializeCurrentProgram();
      _initializeWindowModeTracking();
      _checkAppTour();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _wiggleController.dispose();
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
      // Check if we should show tour step when returning to home
      _checkAndShowTourStep();
    });
  }

  /// Auto-refresh workouts if enough time has passed since last refresh
  Future<void> _autoRefreshIfNeeded() async {
    final now = DateTime.now();
    if (_lastRefreshTime == null ||
        now.difference(_lastRefreshTime!) > _minRefreshInterval) {
      debugPrint('🔄 [Home] Auto-refreshing workouts...');
      _lastRefreshTime = now;
      final workoutsNotifier = ref.read(workoutsProvider.notifier);
      await workoutsNotifier.refresh();
      // Force UI rebuild by invalidating the provider
      if (mounted) {
        ref.invalidate(workoutsProvider);
      }

      // Refresh Health Connect status - user may have granted permissions externally
      ref.read(healthSyncProvider.notifier).refreshConnectionStatus();
    }
  }

  void _enterEditMode() async {
    final layout = ref.read(activeLayoutProvider).value;
    if (layout != null) {
      setState(() {
        _isEditMode = true;
        _editingTiles = List.from(layout.tiles);
      });
      _wiggleController.repeat(reverse: true);
      HapticService.medium();

      // Show one-time tooltip/coach mark for edit mode
      await _showEditModeTooltipIfNeeded();
    }
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

  /// Check if multi-screen tour should be shown for new users
  Future<void> _checkAppTour() async {
    try {
      // Initialize the multi-screen tour provider
      await ref.read(multiScreenTourProvider.notifier).initialize();
      final tourState = ref.read(multiScreenTourProvider);

      if (tourState.shouldShowTour && tourState.isActive && mounted) {
        debugPrint('🎯 [Home] Multi-screen tour should be shown');
        // Wait a bit for the UI to fully build before showing tour
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          _checkAndShowTourStep();
        }
      }
    } catch (e) {
      debugPrint('❌ [Home] Error checking app tour: $e');
    }
  }

  /// Check and show the appropriate tour step for home screen
  void _checkAndShowTourStep() {
    final tourState = ref.read(multiScreenTourProvider);

    if (!tourState.isActive || tourState.isLoading) return;

    final currentStep = tourState.currentStep;
    if (currentStep == null) return;

    // Home screen handles step 1 (next_workout_card) and step 6 (chat_fab)
    if (currentStep.screenRoute != '/home') return;

    // Determine which key to use based on the step
    GlobalKey? targetKey;
    if (currentStep.targetKeyId == 'next_workout_card') {
      targetKey = HomeTourKeys.nextWorkoutKey;
    } else if (currentStep.targetKeyId == 'chat_fab') {
      targetKey = HomeTourKeys.chatFabKey;
    }

    if (targetKey == null) {
      debugPrint('[Home] No matching key for step: ${currentStep.id}');
      return;
    }

    // Use the helper to show the tour
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final helper = MultiScreenTourHelper(context: context, ref: ref);
      helper.checkAndShowTour('/home', targetKey!);
    });
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

              // Feature voting pill - compact access below header
              SliverToBoxAdapter(
                child: _FeatureVotingPill(isDark: isDark),
              ),

              // Renewal Reminder Banner (shows 5 days before subscription renewal)
              const SliverToBoxAdapter(
                child: RenewalReminderBanner(),
              ),

              // Missed Workout Banner (shows when user has missed workout(s) from past 3 days)
              const SliverToBoxAdapter(
                child: MissedWorkoutBanner(),
              ),

              // Section: TODAY with Customize button
              SliverToBoxAdapter(
                child: _buildTodaySectionHeader(isDark),
              ),

              // Dynamic Tile Rendering based on active layout
              ..._buildDynamicTilesLazy(
                context,
                activeLayoutState,
                isDark,
                todayWorkoutState,
                isAIGenerating,
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
        // Always use simplified default tiles for lazy loading
        return _buildDefaultTilesLazy(context, isDark, todayWorkoutState, isAIGenerating);
      },
    );
  }

  /// Build default tiles using lazy loading (todayWorkoutProvider)
  /// Simplified version without UPCOMING and YOUR WEEK sections
  List<Widget> _buildDefaultTilesLazy(
    BuildContext context,
    bool isDark,
    AsyncValue<TodayWorkoutResponse?> todayWorkoutState,
    bool isAIGenerating,
  ) {
    return [
      // View Upcoming link at the top right
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  HapticService.light();
                  context.push('/workouts');
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View Upcoming',
                      style: TextStyle(
                        color: AppColors.cyan,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.cyan,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Next Workout Card (hero card - using lazy loading)
      SliverToBoxAdapter(
        child: _buildNextWorkoutSectionLazy(
          context,
          todayWorkoutState,
          isAIGenerating,
        ),
      ),

      // Quick Actions Row
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Container(
            key: HomeTourKeys.quickActionsKey,
            child: const QuickActionsRow(),
          ),
        ),
      ),

      // Fitness Score Card
      const SliverToBoxAdapter(child: FitnessScoreCard()),

      // Mood Picker Card
      const SliverToBoxAdapter(child: MoodPickerCard()),

      // Daily Activity Card
      const SliverToBoxAdapter(child: DailyActivityCard()),

      // Note: YOUR WEEK and UPCOMING sections have been moved to Workouts tab
    ];
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

        // Get the workout to display (today's or next upcoming)
        final workoutSummary = response.todayWorkout ?? response.nextWorkout;

        if (workoutSummary != null) {
          // Convert summary to Workout for NextWorkoutCard
          final workout = workoutSummary.toWorkout();
          return Container(
            key: HomeTourKeys.nextWorkoutKey,
            child: NextWorkoutCard(
              workout: workout,
              onStart: () => context.push('/workout/${workout.id}'),
            ),
          );
        }

        // No workout available - show rest day or empty state
        if (response.restDayMessage != null) {
          return _buildRestDayCard(response.restDayMessage!, response.daysUntilNext);
        }

        return EmptyWorkoutCard(
          onGenerate: () {
            // Navigate to workouts tab which handles generation
            context.push('/workouts');
          },
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
          return Container(
            key: HomeTourKeys.nextWorkoutKey,
            child: NextWorkoutCard(
              workout: todayWorkout,
              onStart: () => context.push('/workout/${todayWorkout.id}'),
            ),
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
          return Container(
            key: HomeTourKeys.nextWorkoutKey,
            child: NextWorkoutCard(
              workout: nextWorkout,
              onStart: () => context.push('/workout/${nextWorkout.id}'),
            ),
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

  /// Build a rest day card
  Widget _buildRestDayCard(String message, int? daysUntilNext) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Icon(
              Icons.self_improvement,
              size: 48,
              color: AppColors.cyan.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Rest Day',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.push('/workouts'),
              child: Text(
                'View Schedule',
                style: TextStyle(
                  color: AppColors.cyan,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
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
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Container(
            key: HomeTourKeys.quickActionsKey,
            child: const QuickActionsRow(),
          ),
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
          // Streak Badge
          Container(
            key: HomeTourKeys.streakBadgeKey,
            child: _StreakBadge(streak: currentStreak, isDark: isDark, isCompact: isCompact),
          ),
          SizedBox(width: spacing),
          // Hide Profile button in very narrow split screen
          if (!isCompact) ...[
            Container(
              key: HomeTourKeys.libraryButtonKey, // Keep key for tour compatibility
              child: _ProfileButton(isDark: isDark),
            ),
            SizedBox(width: spacing / 2),
          ],
          NotificationBellButton(isDark: isDark),
          SizedBox(width: spacing / 2),
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
              ? Container(
                  key: HomeTourKeys.nextWorkoutKey,
                  child: NextWorkoutCard(
                    workout: nextWorkout,
                    onStart: () => context.push('/workout/${nextWorkout.id}'),
                  ),
                )
              : (_isCheckingWorkouts || _isStreamingGeneration)
                  ? const GeneratingWorkoutsCard(
                      message: 'Generating your personalized workouts...',
                    )
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
            Container(
              key: HomeTourKeys.editButtonKey,
              child: Material(
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
            ),
            const SizedBox(width: 8),
            CustomizeProgramButton(isDark: isDark),
          ],
        ],
      ),
    );
  }
}

/// A button that navigates to the profile screen
class _ProfileButton extends StatelessWidget {
  final bool isDark;

  const _ProfileButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        HapticService.light();
        context.push('/profile');
      },
      icon: Icon(
        Icons.person_outline,
        color: AppColors.purple,
        size: 24,
      ),
      tooltip: 'Profile',
    );
  }
}

/// Compact pill for feature voting access - shown below header
class _FeatureVotingPill extends StatelessWidget {
  final bool isDark;

  const _FeatureVotingPill({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final pillBg = isDark
        ? AppColors.cyan.withValues(alpha: 0.12)
        : AppColors.cyan.withValues(alpha: 0.08);
    final borderColor = AppColors.cyan.withValues(alpha: 0.3);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GestureDetector(
        onTap: () {
          HapticService.light();
          context.push('/features');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: pillBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.how_to_vote_rounded,
                color: AppColors.cyan,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'What should we build next?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.cyan,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.cyan,
                size: 12,
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

/// Global keys for tour targets on home screen
class HomeTourKeys {
  static final GlobalKey nextWorkoutKey = GlobalKey();
  static final GlobalKey streakBadgeKey = GlobalKey();
  static final GlobalKey libraryButtonKey = GlobalKey();
  static final GlobalKey quickActionsKey = GlobalKey();
  static final GlobalKey editButtonKey = GlobalKey();
  static final GlobalKey chatFabKey = GlobalKey();

  /// Get all keys as a map
  static Map<String, GlobalKey> get all => {
    'nextWorkout': nextWorkoutKey,
    'streakBadge': streakBadgeKey,
    'libraryButton': libraryButtonKey,
    'quickActions': quickActionsKey,
    'editButton': editButtonKey,
    'chatFab': chatFabKey,
  };
}
