import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/home_layout.dart';
import '../../data/providers/home_layout_provider.dart';
import '../../data/services/haptic_service.dart';
import '../../data/services/layout_share_service.dart';
import 'widgets/tile_picker_sheet.dart';
import 'widgets/template_picker_sheet.dart';

/// Screen for editing home screen layout with drag-and-drop
class LayoutEditorScreen extends ConsumerStatefulWidget {
  const LayoutEditorScreen({super.key});

  @override
  ConsumerState<LayoutEditorScreen> createState() => _LayoutEditorScreenState();
}

class _LayoutEditorScreenState extends ConsumerState<LayoutEditorScreen> {
  bool _isReordering = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.background : AppColorsLight.background;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final layoutState = ref.watch(activeLayoutProvider);
    final allLayoutsState = ref.watch(allLayoutsProvider);

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
          // Templates button
          IconButton(
            icon: Icon(Icons.style_outlined, color: AppColors.purple),
            onPressed: () => _showTemplatesSheet(context),
            tooltip: 'Templates',
          ),
          // More options menu
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: textMuted),
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'new_layout',
                child: Row(
                  children: [
                    Icon(Icons.add, size: 20),
                    SizedBox(width: 12),
                    Text('New Layout'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Rename Layout'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Share Layout'),
                  ],
                ),
              ),
              if ((allLayoutsState.value?.length ?? 0) > 1)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Delete Layout', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: layoutState.when(
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
                onPressed: () => ref.read(activeLayoutProvider.notifier).refresh(),
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

          return Column(
            children: [
              // Layout selector dropdown
              _buildLayoutSelector(
                context,
                layout,
                allLayoutsState.value ?? [],
                isDark,
                elevatedColor,
                textColor,
                textMuted,
              ),

              // Main content - tile list
              Expanded(
                child: _buildTileList(
                  context,
                  layout,
                  isDark,
                  elevatedColor,
                  textColor,
                  textMuted,
                ),
              ),

              // Bottom action bar
              _buildBottomBar(
                context,
                layout,
                isDark,
                elevatedColor,
                textColor,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLayoutSelector(
    BuildContext context,
    HomeLayout currentLayout,
    List<HomeLayout> allLayouts,
    bool isDark,
    Color elevatedColor,
    Color textColor,
    Color textMuted,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
        ),
        child: PopupMenuButton<String>(
          onSelected: (layoutId) {
            HapticService.light();
            ref.read(activeLayoutProvider.notifier).activateLayout(layoutId);
          },
          offset: const Offset(0, 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.dashboard_customize, color: AppColors.cyan, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Layout',
                        style: TextStyle(
                          fontSize: 11,
                          color: textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        currentLayout.name,
                        style: TextStyle(
                          fontSize: 15,
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: textMuted),
              ],
            ),
          ),
          itemBuilder: (context) {
            return allLayouts.map((layout) {
              return PopupMenuItem<String>(
                value: layout.id,
                child: Row(
                  children: [
                    Icon(
                      layout.isActive
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: layout.isActive ? AppColors.cyan : textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(layout.name),
                  ],
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildTileList(
    BuildContext context,
    HomeLayout layout,
    bool isDark,
    Color elevatedColor,
    Color textColor,
    Color textMuted,
  ) {
    final visibleTiles = layout.visibleTiles;
    final hiddenTiles = layout.hiddenTiles;

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final elevation = Tween<double>(begin: 0, end: 8).evaluate(animation);
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
        HapticService.medium();
        setState(() => _isReordering = true);
      },
      onReorderEnd: (index) {
        setState(() => _isReordering = false);
      },
      onReorder: (oldIndex, newIndex) {
        HapticService.light();
        if (oldIndex < visibleTiles.length && newIndex <= visibleTiles.length) {
          ref.read(activeLayoutProvider.notifier).reorderTiles(
                oldIndex,
                newIndex > oldIndex ? newIndex - 1 : newIndex,
              );
        }
      },
      itemCount: visibleTiles.length + (hiddenTiles.isNotEmpty ? 1 + hiddenTiles.length : 0),
      itemBuilder: (context, index) {
        // Visible tiles
        if (index < visibleTiles.length) {
          final tile = visibleTiles[index];
          return _buildTileItem(
            key: ValueKey(tile.id),
            tile: tile,
            isDark: isDark,
            elevatedColor: elevatedColor,
            textColor: textColor,
            textMuted: textMuted,
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
                      color: textMuted,
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
          return _buildTileItem(
            key: ValueKey(tile.id),
            tile: tile,
            isDark: isDark,
            elevatedColor: elevatedColor,
            textColor: textColor,
            textMuted: textMuted,
            isVisible: false,
          );
        }

        return const SizedBox.shrink(key: ValueKey('empty'));
      },
    );
  }

  Widget _buildTileItem({
    required Key key,
    required HomeTile tile,
    required bool isDark,
    required Color elevatedColor,
    required Color textColor,
    required Color textMuted,
    required bool isVisible,
  }) {
    final iconColor = _getIconColorForType(tile.type);

    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isVisible ? iconColor.withOpacity(0.3) : Colors.transparent,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.only(left: 8, right: 12),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isVisible)
                ReorderableDragStartListener(
                  index: tile.order,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.drag_handle,
                      color: textMuted,
                      size: 20,
                    ),
                  ),
                )
              else
                const SizedBox(width: 36),
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
            ],
          ),
          title: Text(
            tile.type.displayName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isVisible ? textColor : textMuted,
            ),
          ),
          subtitle: Text(
            tile.type.description,
            style: TextStyle(
              fontSize: 11,
              color: textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Size selector (only for tiles with multiple size options)
              if (isVisible && tile.type.supportedSizes.length > 1)
                _buildSizeDropdown(tile, textMuted),
              const SizedBox(width: 8),
              // Visibility toggle
              IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility : Icons.visibility_off,
                  color: isVisible ? AppColors.cyan : textMuted,
                  size: 20,
                ),
                onPressed: () {
                  HapticService.light();
                  ref
                      .read(activeLayoutProvider.notifier)
                      .toggleTileVisibility(tile.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSizeDropdown(HomeTile tile, Color textMuted) {
    return PopupMenuButton<TileSize>(
      onSelected: (size) {
        HapticService.light();
        ref.read(activeLayoutProvider.notifier).changeTileSize(tile.id, size);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.cyan.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tile.size.displayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.cyan,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 16, color: AppColors.cyan),
          ],
        ),
      ),
      itemBuilder: (context) {
        return tile.type.supportedSizes.map((size) {
          return PopupMenuItem<TileSize>(
            value: size,
            child: Row(
              children: [
                Icon(
                  tile.size == size
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 18,
                  color: tile.size == size ? AppColors.cyan : textMuted,
                ),
                const SizedBox(width: 8),
                Text(size.displayName),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    HomeLayout layout,
    bool isDark,
    Color elevatedColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Add Tile button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showTilePickerSheet(context, layout),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Tile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Share button
            Container(
              decoration: BoxDecoration(
                color: AppColors.purple.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () => _shareLayout(layout),
                icon: Icon(Icons.share_outlined, color: AppColors.purple),
                tooltip: 'Share Layout',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTilePickerSheet(BuildContext context, HomeLayout layout) {
    HapticService.light();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TilePickerSheet(
        currentTiles: layout.tiles,
        onTileSelected: (type, size) {
          ref.read(activeLayoutProvider.notifier).addTile(type, size: size);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showTemplatesSheet(BuildContext context) {
    HapticService.light();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TemplatePickerSheet(
        onTemplateSelected: (template) async {
          // Create new layout from template
          final notifier = ref.read(allLayoutsProvider.notifier);
          final newLayout = await notifier.createFromTemplate(
            templateId: template.id,
          );
          // Activate it
          ref.read(activeLayoutProvider.notifier).activateLayout(newLayout.id);
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'new_layout':
        _createNewLayout();
        break;
      case 'rename':
        _renameLayout();
        break;
      case 'share':
        final layout = ref.read(activeLayoutProvider).value;
        if (layout != null) _shareLayout(layout);
        break;
      case 'delete':
        _deleteLayout();
        break;
    }
  }

  void _createNewLayout() async {
    final name = await _showTextInputDialog(
      title: 'New Layout',
      hint: 'Enter layout name',
      defaultValue: 'My Layout',
    );
    if (name != null && name.isNotEmpty) {
      final notifier = ref.read(allLayoutsProvider.notifier);
      final newLayout = await notifier.createLayout(
        name: name,
        tiles: createDefaultTiles(),
      );
      ref.read(activeLayoutProvider.notifier).activateLayout(newLayout.id);
    }
  }

  void _renameLayout() async {
    final currentLayout = ref.read(activeLayoutProvider).value;
    if (currentLayout == null) return;

    final name = await _showTextInputDialog(
      title: 'Rename Layout',
      hint: 'Enter new name',
      defaultValue: currentLayout.name,
    );
    if (name != null && name.isNotEmpty) {
      await ref
          .read(allLayoutsProvider.notifier)
          .renameLayout(currentLayout.id, name);
      ref.read(activeLayoutProvider.notifier).refresh();
    }
  }

  void _deleteLayout() async {
    final currentLayout = ref.read(activeLayoutProvider).value;
    if (currentLayout == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Layout'),
        content: Text(
            'Are you sure you want to delete "${currentLayout.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(allLayoutsProvider.notifier)
          .deleteLayout(currentLayout.id);
      // Active layout will auto-update since we refresh
    }
  }

  void _shareLayout(HomeLayout layout) {
    HapticService.light();
    showShareLayoutSheet(context, layout);
  }

  Future<String?> _showTextInputDialog({
    required String title,
    required String hint,
    String? defaultValue,
  }) async {
    final controller = TextEditingController(text: defaultValue);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(TileType type) {
    switch (type) {
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
    }
  }

  Color _getIconColorForType(TileType type) {
    switch (type.category) {
      case TileCategory.workout:
        return AppColors.cyan;
      case TileCategory.progress:
        return AppColors.green;
      case TileCategory.nutrition:
        return AppColors.orange;
      case TileCategory.social:
        return AppColors.purple;
      case TileCategory.wellness:
        return AppColors.yellow;
      case TileCategory.tools:
        return AppColors.cyan;
    }
  }
}
