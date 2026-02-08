import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/models/home_layout.dart';
import '../../data/providers/local_layout_provider.dart';
import '../../data/services/haptic_service.dart';

/// Screen for editing home screen layout with tabs for Toggles and Discover
class LayoutEditorScreen extends ConsumerStatefulWidget {
  const LayoutEditorScreen({super.key});

  @override
  ConsumerState<LayoutEditorScreen> createState() => _LayoutEditorScreenState();
}

class _LayoutEditorScreenState extends ConsumerState<LayoutEditorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _hasUserDefault = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkUserDefault();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkUserDefault() async {
    final hasDefault =
        await ref.read(localLayoutProvider.notifier).hasUserDefault();
    if (mounted) {
      setState(() => _hasUserDefault = hasDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.background : AppColorsLight.background;
    final textColor =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final layoutState = ref.watch(localLayoutProvider);
    final accentColor = ref.colors(context).accent;
    final isAtDefault = ref.watch(localLayoutProvider.notifier).matchesAppDefault();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'My Space',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Reset button - only show when layout is modified from default
          if (!isAtDefault)
            IconButton(
              icon: Icon(Icons.refresh, color: accentColor),
              tooltip: 'Reset to Original',
              onPressed: _showResetDialog,
            ),
          // More options menu
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: textMuted),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'set_default',
                child: Row(
                  children: [
                    Icon(Icons.bookmark_outline, size: 20, color: textColor),
                    const SizedBox(width: 12),
                    Text('Set as My Default',
                        style: TextStyle(color: textColor)),
                  ],
                ),
              ),
              if (_hasUserDefault)
                PopupMenuItem(
                  value: 'apply_default',
                  child: Row(
                    children: [
                      Icon(Icons.bookmark, size: 20, color: AppColors.purple),
                      const SizedBox(width: 12),
                      Text('Apply My Default',
                          style: TextStyle(color: textColor)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Styled TabBar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: elevatedColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: isDark ? Colors.black : Colors.white,
              unselectedLabelColor: textMuted,
              labelStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 14),
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(4),
              tabs: const [
                Tab(text: 'Toggles'),
                Tab(text: 'Discover'),
              ],
            ),
          ),
          // Content
          Expanded(
            child: layoutState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load layout',
                      style: TextStyle(color: textColor, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () =>
                          ref.read(localLayoutProvider.notifier).refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (layout) {
                if (layout == null) {
                  return Center(
                    child: Text(
                      'No layout found',
                      style: TextStyle(color: textMuted),
                    ),
                  );
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _TogglesTab(
                      layout: layout,
                      isDark: isDark,
                      elevatedColor: elevatedColor,
                      textColor: textColor,
                      textMuted: textMuted,
                    ),
                    _DiscoverTab(
                      isDark: isDark,
                      elevatedColor: elevatedColor,
                      textColor: textColor,
                      textMuted: textMuted,
                      hasUserDefault: _hasUserDefault,
                      onUserDefaultApplied: _checkUserDefault,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'set_default':
        _saveAsDefault();
        break;
      case 'apply_default':
        _applyUserDefault();
        break;
    }
  }

  void _showResetDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        title: Text('Reset Layout', style: TextStyle(color: textColor)),
        content: Text(
          'Reset to the app\'s original layout? This will undo all your customizations.',
          style: TextStyle(
              color: isDark ? AppColors.textMuted : AppColorsLight.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(
                    color: isDark
                        ? AppColors.textMuted
                        : AppColorsLight.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(localLayoutProvider.notifier).resetToAppDefault();
              HapticService.success();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Layout reset to original'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text('Reset',
                style: TextStyle(
                    color: isDark
                        ? AppColors.cyan
                        : _darkenColor(AppColors.cyan))),
          ),
        ],
      ),
    );
  }

  void _saveAsDefault() async {
    await ref.read(localLayoutProvider.notifier).saveAsUserDefault();
    HapticService.success();
    setState(() => _hasUserDefault = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved as your default layout'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _applyUserDefault() async {
    await ref.read(localLayoutProvider.notifier).applyUserDefault();
    HapticService.success();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Applied your default layout'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color _darkenColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness * 0.7).clamp(0.0, 1.0)).toColor();
  }
}

/// Toggles tab - List of all tiles with on/off switches and drag-to-reorder
class _TogglesTab extends ConsumerStatefulWidget {
  final HomeLayout layout;
  final bool isDark;
  final Color elevatedColor;
  final Color textColor;
  final Color textMuted;

  const _TogglesTab({
    required this.layout,
    required this.isDark,
    required this.elevatedColor,
    required this.textColor,
    required this.textMuted,
  });

  @override
  ConsumerState<_TogglesTab> createState() => _TogglesTabState();
}

class _TogglesTabState extends ConsumerState<_TogglesTab> {
  List<HomeTile> _orderedTiles = [];

  @override
  void initState() {
    super.initState();
    _updateOrderedTiles();
  }

  @override
  void didUpdateWidget(covariant _TogglesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.layout != widget.layout) {
      _updateOrderedTiles();
    }
  }

  void _updateOrderedTiles() {
    // Combine visible and hidden tiles, sorted by order
    final allTiles = List<HomeTile>.from(widget.layout.tiles);
    allTiles.sort((a, b) {
      // Visible tiles first, then hidden tiles
      if (a.isVisible && !b.isVisible) return -1;
      if (!a.isVisible && b.isVisible) return 1;
      return a.order.compareTo(b.order);
    });
    _orderedTiles = allTiles;
  }

  Color _darkenColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness * 0.7).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final visibleTiles = _orderedTiles.where((t) => t.isVisible).toList();
    final hiddenTiles = _orderedTiles.where((t) => !t.isVisible).toList();

    return Column(
      children: [
        // Info banner
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (widget.isDark ? AppColors.cyan : _darkenColor(AppColors.cyan))
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (widget.isDark
                      ? AppColors.cyan
                      : _darkenColor(AppColors.cyan))
                  .withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color:
                    widget.isDark ? AppColors.cyan : _darkenColor(AppColors.cyan),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Drag to reorder • Toggle to show/hide',
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.isDark
                        ? AppColors.cyan
                        : _darkenColor(AppColors.cyan),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Tile list
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final elevation =
                      Tween<double>(begin: 0, end: 8).evaluate(animation);
                  return Material(
                    elevation: elevation,
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.transparent,
                    child: child,
                  );
                },
                child: child,
              );
            },
            onReorderStart: (index) {
              HapticFeedback.mediumImpact();
            },
            onReorder: (oldIndex, newIndex) {
              if (oldIndex < visibleTiles.length &&
                  newIndex <= visibleTiles.length) {
                HapticFeedback.lightImpact();
                ref.read(localLayoutProvider.notifier).reorderTiles(
                      oldIndex,
                      newIndex > oldIndex ? newIndex - 1 : newIndex,
                    );
              }
            },
            itemCount: visibleTiles.length +
                (hiddenTiles.isNotEmpty ? 1 + hiddenTiles.length : 0),
            itemBuilder: (context, index) {
              // Visible tiles
              if (index < visibleTiles.length) {
                final tile = visibleTiles[index];
                return _buildTileRow(
                  key: ValueKey(tile.id),
                  tile: tile,
                  index: index,
                  isVisible: true,
                );
              }

              // Hidden section header
              if (index == visibleTiles.length && hiddenTiles.isNotEmpty) {
                return Container(
                  key: const ValueKey('hidden_header'),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'HIDDEN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: widget.textMuted,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                );
              }

              // Hidden tiles
              final hiddenIndex = index - visibleTiles.length - 1;
              if (hiddenIndex >= 0 && hiddenIndex < hiddenTiles.length) {
                final tile = hiddenTiles[hiddenIndex];
                return _buildTileRow(
                  key: ValueKey(tile.id),
                  tile: tile,
                  index: index,
                  isVisible: false,
                );
              }

              return const SizedBox.shrink(key: ValueKey('empty'));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTileRow({
    required Key key,
    required HomeTile tile,
    required int index,
    required bool isVisible,
  }) {
    final iconColor = _getIconColorForType(tile.type, widget.isDark);
    final accent = ref.colors(context).accent;

    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: widget.elevatedColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isVisible ? iconColor.withOpacity(0.3) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            // Drag handle (only for visible tiles)
            if (isVisible)
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.drag_handle,
                    color: widget.textMuted,
                    size: 20,
                  ),
                ),
              )
            else
              const SizedBox(width: 44),

            // Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(isVisible ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIconForType(tile.type),
                color: isVisible ? iconColor : iconColor.withOpacity(0.5),
                size: 18,
              ),
            ),

            const SizedBox(width: 12),

            // Title and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tile.type.displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isVisible ? widget.textColor : widget.textMuted,
                    ),
                  ),
                  Text(
                    tile.type.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Toggle switch
            Switch(
              value: isVisible,
              onChanged: (value) {
                HapticFeedback.lightImpact();
                ref
                    .read(localLayoutProvider.notifier)
                    .toggleTileVisibility(tile.id);
              },
              activeThumbColor: accent,
              activeTrackColor: accent.withValues(alpha: 0.3),
              inactiveThumbColor: widget.textMuted,
              inactiveTrackColor: widget.textMuted.withValues(alpha: 0.3),
            ),

            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Color _getIconColorForType(TileType type, bool isDark) {
    Color baseColor;
    switch (type.category) {
      case TileCategory.workout:
        baseColor = AppColors.cyan;
      case TileCategory.progress:
        baseColor = AppColors.green;
      case TileCategory.nutrition:
        baseColor = AppColors.orange;
      case TileCategory.social:
        baseColor = AppColors.purple;
      case TileCategory.wellness:
        baseColor = AppColors.yellow;
      case TileCategory.tools:
        baseColor = AppColors.cyan;
    }
    return isDark ? baseColor : _darkenColor(baseColor);
  }

  IconData _getIconForType(TileType type) {
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
      case TileType.weightTrend:
        return Icons.trending_down;
      case TileType.dailyStats:
        return Icons.directions_walk;
      case TileType.achievements:
        return Icons.emoji_events;
      case TileType.heroSection:
        return Icons.view_carousel;
      case TileType.quickLogWeight:
        return Icons.scale;
      case TileType.quickLogMeasurements:
        return Icons.straighten;
      case TileType.habits:
        return Icons.checklist;
      case TileType.xpProgress:
        return Icons.bolt;
      case TileType.upNext:
        return Icons.schedule;
    }
  }
}

/// Discover tab - Preset layouts and user's saved default
class _DiscoverTab extends ConsumerWidget {
  final bool isDark;
  final Color elevatedColor;
  final Color textColor;
  final Color textMuted;
  final bool hasUserDefault;
  final VoidCallback onUserDefaultApplied;

  const _DiscoverTab({
    required this.isDark,
    required this.elevatedColor,
    required this.textColor,
    required this.textMuted,
    required this.hasUserDefault,
    required this.onUserDefaultApplied,
  });

  Color _darkenColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness * 0.7).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purple = isDark ? AppColors.purple : _darkenColor(AppColors.purple);
    final cyan = isDark ? AppColors.cyan : _darkenColor(AppColors.cyan);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User's default card (if exists)
          if (hasUserDefault) ...[
            _buildSectionHeader('MY DEFAULT', purple),
            const SizedBox(height: 8),
            _buildMyDefaultCard(context, ref, purple),
            const SizedBox(height: 24),
          ],

          // Presets section
          _buildSectionHeader('PRESETS', cyan),
          const SizedBox(height: 8),
          Text(
            'Choose a preset to quickly customize your home screen',
            style: TextStyle(fontSize: 13, color: textMuted),
          ),
          const SizedBox(height: 16),

          // Preset cards grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: LayoutPreset.values
                .map((preset) => _buildPresetCard(context, ref, preset))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildMyDefaultCard(
      BuildContext context, WidgetRef ref, Color purple) {
    return GestureDetector(
      onTap: () {
        HapticService.medium();
        ref.read(localLayoutProvider.notifier).applyUserDefault();
        onUserDefaultApplied();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Applied your default layout'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: purple.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: purple.withOpacity(0.1),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: purple.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.bookmark,
                color: purple,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Default',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Your saved custom layout',
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: purple,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Apply',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetCard(
      BuildContext context, WidgetRef ref, LayoutPreset preset) {
    final presetColor = _getPresetColor(preset);
    final color = isDark ? presetColor : _darkenColor(presetColor);

    return GestureDetector(
      onTap: () {
        HapticService.medium();
        ref.read(localLayoutProvider.notifier).applyPreset(preset);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Applied ${preset.displayName}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getPresetIcon(preset),
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              preset.displayName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Text(
                preset.description,
                style: TextStyle(
                  fontSize: 11,
                  color: textMuted,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Apply',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPresetIcon(LayoutPreset preset) {
    switch (preset) {
      case LayoutPreset.fatLossFocus:
        return Icons.trending_down;
      case LayoutPreset.gymFocused:
        return Icons.fitness_center;
      case LayoutPreset.nutritionFocused:
        return Icons.restaurant;
      case LayoutPreset.trackerOnly:
        return Icons.insights;
      case LayoutPreset.fastingFocused:
        return Icons.timer;
      case LayoutPreset.minimal:
        return Icons.view_agenda;
    }
  }

  Color _getPresetColor(LayoutPreset preset) {
    switch (preset) {
      case LayoutPreset.fatLossFocus:
        return AppColors.orange;
      case LayoutPreset.gymFocused:
        return AppColors.cyan;
      case LayoutPreset.nutritionFocused:
        return AppColors.green;
      case LayoutPreset.trackerOnly:
        return AppColors.purple;
      case LayoutPreset.fastingFocused:
        return AppColors.yellow;
      case LayoutPreset.minimal:
        return AppColors.cyan;
    }
  }
}
