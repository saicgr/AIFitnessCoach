import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/animations/app_animations.dart';
import '../core/constants/app_colors.dart';
import '../core/models/quick_action.dart';
import '../data/providers/fasting_provider.dart';
import '../data/providers/quick_action_provider.dart';
import '../data/repositories/hydration_repository.dart';
import '../data/services/api_client.dart';
import '../screens/fasting/widgets/log_weight_sheet.dart';
import '../screens/nutrition/log_meal_sheet.dart';
import '../screens/workout/widgets/quick_workout_sheet.dart';
import 'mood_picker_sheet.dart';
import 'main_shell.dart';
import 'glass_sheet.dart';
import 'quick_action_tile.dart';

part 'quick_actions_sheet_part_hero_action_card.dart';


/// Shows the quick actions bottom sheet when + button is tapped
void showQuickActionsSheet(BuildContext context, WidgetRef ref, {bool editMode = false}) {
  HapticFeedback.mediumImpact();

  // Hide nav bar while sheet is open
  ref.read(floatingNavBarVisibleProvider.notifier).state = false;

  showGlassSheet(
    context: context,
    useRootNavigator: true,
    builder: (context) => _QuickActionsSheet(ref: ref, startInEditMode: editMode),
  ).then((_) {
    // Show nav bar when sheet is closed
    ref.read(floatingNavBarVisibleProvider.notifier).state = true;
  });
}

class _QuickActionsSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final bool startInEditMode;

  const _QuickActionsSheet({required this.ref, this.startInEditMode = false});

  @override
  ConsumerState<_QuickActionsSheet> createState() => _QuickActionsSheetState();
}

// Three high-level groups (was 5). The previous 5-category breakdown made
// the More sheet feel overwhelming — Issue 6. Each group now consolidates
// related actions so the user scans 3 headers, not 5.
const _categories = <String, List<String>>{
  // LOG: every "I just did X" entry-point — food logging variants, weight,
  // water, mood, photo, measurements.
  'Log': [
    'food', 'photo_food', 'scan_food', 'scan_menu', 'barcode_food',
    'weight', 'water', 'photo', 'mood', 'measure',
  ],
  // PLAN: workout flows + review/progress surfaces.
  'Plan': [
    'quick_workout', 'workout', 'steps', 'library',
    'schedule', 'habits', 'history', 'progress', 'stats', 'summaries', 'achievements',
  ],
  // TOOLS: chat, hydration, settings.
  'Tools': ['chat', 'hydration', 'settings'],
};

class _QuickActionsSheetState extends ConsumerState<_QuickActionsSheet> {
  bool _isLoggingWater = false;
  bool _isEditMode = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.startInEditMode;
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _quickAddWater() async {
    if (_isLoggingWater) return;

    setState(() => _isLoggingWater = true);
    HapticFeedback.mediumImpact();

    try {
      final userId = await ref.read(apiClientProvider).getUserId();
      if (userId == null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to track hydration'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final success = await ref.read(hydrationProvider.notifier).quickLog(
            userId: userId,
            drinkType: 'water',
            amountMl: 500,
          );

      if (mounted) {
        Navigator.pop(context);
        if (success) {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text('+500ml water logged'),
                ],
              ),
              backgroundColor: const Color(0xFF2D2D2D),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to log water. Please try again.'),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(bottom: 80, left: 16, right: 16),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to log water. Please try again.'),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 80, left: 16, right: 16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoggingWater = false);
      }
    }
  }

  Widget _buildActionChip(QuickAction action, bool isDark, BuildContext context, {bool isPinned = false}) {
    Future<void> handleTap() async {
      HapticFeedback.lightImpact();

      // Capture the root navigator's context BEFORE popping this sheet —
      // after pop, the local `context` is defunct and showing a follow-up
      // sheet silently no-ops (that's what made "Scan Menu" look broken).
      final rootCtx = Navigator.of(context, rootNavigator: true).context;
      final ref = widget.ref;

      void runAfterPop(VoidCallback fn) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (rootCtx.mounted) fn();
        });
      }

      switch (action.id) {
        case 'water':
          _quickAddWater();
          return;
        case 'food':
          Navigator.pop(context);
          runAfterPop(() => showLogMealSheet(rootCtx, ref));
          return;
        case 'scan_food':
          Navigator.pop(context);
          runAfterPop(() => showLogMealSheet(rootCtx, ref, autoOpenMultiImage: true));
          return;
        case 'scan_menu':
          Navigator.pop(context);
          runAfterPop(() => showLogMealSheet(rootCtx, ref, autoOpenMenuScan: true));
          return;
        case 'photo_food':
          Navigator.pop(context);
          runAfterPop(() => showLogMealSheet(rootCtx, ref, autoOpenCamera: true));
          return;
        case 'barcode_food':
          Navigator.pop(context);
          runAfterPop(() => showLogMealSheet(rootCtx, ref, autoOpenBarcode: true));
          return;
        case 'quick_workout':
          final workout = await showQuickWorkoutSheet(context, widget.ref);
          if (!mounted) return;
          Navigator.pop(context);
          if (workout != null) {
            runAfterPop(() => rootCtx.push('/workout/${workout.id}', extra: workout));
          }
          return;
        case 'fasting':
          Navigator.pop(context);
          runAfterPop(() => rootCtx.go('/fasting'));
          return;
        case 'weight':
          Navigator.pop(context);
          runAfterPop(() => showLogWeightSheet(rootCtx, ref));
          return;
        case 'mood':
          Navigator.pop(context);
          runAfterPop(() => showMoodPickerSheet(rootCtx, ref));
          return;
        case 'chat':
          Navigator.pop(context);
          runAfterPop(() => rootCtx.push('/chat'));
          return;
        default:
          Navigator.pop(context);
          if (action.route != null) {
            runAfterPop(() => rootCtx.push(action.route!));
          }
      }
    }

    return QuickActionTile(
      isDark: isDark,
      onTap: handleTap,
      icon: action.icon,
      label: action.label,
      iconColor: action.color,
      isPinned: isPinned,
    );
  }

  Widget _buildNormalMode(BuildContext context, bool isDark) {
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentColor = isDark ? AppColors.teal : AppColorsLight.teal;
    final pinnedActions = ref.watch(pinnedQuickActionsProvider);
    final isSearching = _searchQuery.isNotEmpty;

    // Filter all actions by search query
    final allActionIds = _categories.values.expand((ids) => ids).toSet();
    final filteredActions = isSearching
        ? allActionIds
            .where((id) {
              final action = quickActionRegistry[id];
              return action != null &&
                  action.label.toLowerCase().contains(_searchQuery);
            })
            .toList()
        : <String>[];

    return GlassSheet(
      // Cap the More sheet at 75% so it reads as a focused picker rather than
      // a near-fullscreen wall of options (Issue 6 — felt overwhelming).
      maxHeightFraction: 0.75,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Card (contextual)
              _HeroActionCard(
                onClose: () => Navigator.pop(context),
              ).animateHeroEntrance(),

              const SizedBox(height: 12),

              // Search bar + edit icon
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(fontSize: 14, color: textColor),
                          decoration: InputDecoration(
                            hintText: 'Search actions...',
                            hintStyle: TextStyle(fontSize: 14, color: textMuted),
                            prefixIcon: Icon(Icons.search, size: 18, color: textMuted),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? GestureDetector(
                                    onTap: () => _searchController.clear(),
                                    child: Icon(Icons.close, size: 16, color: textMuted),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _isEditMode = true);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Two-row toggle for home screen shortcut bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref.read(quickActionsExpandedProvider.notifier).toggle();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          ref.watch(quickActionsExpandedProvider)
                              ? Icons.view_column_rounded
                              : Icons.view_stream_rounded,
                          size: 18,
                          color: ref.watch(quickActionsExpandedProvider)
                              ? accentColor
                              : textMuted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Show two rows',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                'Display extra shortcuts on home',
                                style: TextStyle(fontSize: 11, color: textMuted),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: ref.watch(quickActionsExpandedProvider),
                          onChanged: (_) {
                            HapticFeedback.lightImpact();
                            ref.read(quickActionsExpandedProvider.notifier).toggle();
                          },
                          // Material 3 on Android renders an unstyled
                          // `activeColor` thumb on a gray track. Force the
                          // accent across thumb + track so the toggle visibly
                          // announces "ON" instead of looking disabled.
                          activeThumbColor: Colors.white,
                          activeTrackColor: accentColor,
                          inactiveThumbColor: isDark
                              ? Colors.white.withValues(alpha: 0.6)
                              : Colors.black.withValues(alpha: 0.4),
                          inactiveTrackColor: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.08),
                          trackOutlineColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.selected)
                                ? accentColor
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : Colors.black.withValues(alpha: 0.15)),
                          ),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Show search results or categorized view
              if (isSearching) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: filteredActions.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No actions found',
                              style: TextStyle(fontSize: 14, color: textMuted),
                            ),
                          ),
                        )
                      : _buildTileGrid(
                          filteredActions
                              .map((id) => quickActionRegistry[id])
                              .whereType<QuickAction>()
                              .toList(),
                          isDark,
                          context,
                        ),
                ),
              ] else ...[
                // Pinned section
                _buildSectionHeader('Pinned', textMuted),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildTileGrid(
                    pinnedActions,
                    isDark,
                    context,
                    pinned: true,
                  ),
                ),

                const SizedBox(height: 16),

                // Category sections
                for (final entry in _categories.entries) ...[
                  _buildSectionHeader(entry.key, textMuted),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Builder(builder: (context) {
                      final actions = entry.value
                          .map((id) => quickActionRegistry[id])
                          .whereType<QuickAction>()
                          .toList();
                      return _buildTileGrid(actions, isDark, context);
                    }),
                  ),
                  const SizedBox(height: 16),
                ],
              ],

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Lay out a list of actions in the same 5-column grid the home shortcut
  /// bar uses. Tiles wrap onto a new row every 5 — short sections (4
  /// items) leave a trailing gap, full sections (5+) wrap cleanly.
  Widget _buildTileGrid(
    List<QuickAction> actions,
    bool isDark,
    BuildContext context, {
    bool pinned = false,
  }) {
    if (actions.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 5;
        const spacing = 8.0;
        final tileWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: actions.map((action) {
            return SizedBox(
              width: tileWidth,
              child: _buildActionChip(action, isDark, context, isPinned: pinned),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textMuted,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildEditMode(BuildContext context, bool isDark) {
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final order = ref.watch(quickActionOrderProvider);

    return GlassSheet(
      // Cap the More sheet at 75% so it reads as a focused picker rather than
      // a near-fullscreen wall of options (Issue 6 — felt overwhelming).
      maxHeightFraction: 0.75,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Customize Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _isEditMode = false),
                    child: Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.cyan : const Color(0xFF0891B2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Drag to reorder. Top 9 appear in your shortcut bar (slots 1–5 row 1, 6–9 row 2, slot 10 is More).',
                style: TextStyle(fontSize: 13, color: textMuted),
              ),
            ),
            // Reorderable list in a constrained height container
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              child: ReorderableListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 12),
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
                onReorderStart: (_) => HapticFeedback.mediumImpact(),
                onReorder: (oldIndex, newIndex) {
                  HapticFeedback.lightImpact();
                  ref.read(quickActionOrderProvider.notifier).reorder(oldIndex, newIndex);
                },
                itemCount: order.length,
                itemBuilder: (context, index) {
                  final actionId = order[index];
                  final action = quickActionRegistry[actionId]!;
                  // First 5 = row 1, next 4 = row 2 (slot 10 is the fixed More tile, not in this list).
                  final isRow1 = index < 5;
                  final isRow2 = index >= 5 && index < 9;
                  final isVisibleInBar = isRow1 || isRow2;

                  return Container(
                    key: ValueKey(actionId),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: isVisibleInBar
                          ? action.color.withValues(alpha: isDark ? 0.12 : 0.08)
                          : elevatedColor,
                      borderRadius: BorderRadius.circular(12),
                      border: isVisibleInBar
                          ? Border.all(color: action.color.withValues(alpha: 0.3))
                          : null,
                    ),
                    child: Row(
                      children: [
                        ReorderableDragStartListener(
                          index: index,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(Icons.drag_handle, color: textMuted, size: 20),
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: action.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(action.icon, color: action.color, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                action.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              if (isVisibleInBar)
                                Text(
                                  isRow1 ? 'Row 1' : 'Row 2',
                                  style: TextStyle(fontSize: 11, color: textMuted),
                                ),
                            ],
                          ),
                        ),
                        if (isVisibleInBar)
                          Container(
                            width: 24,
                            height: 24,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: action.color,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 12),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Reset button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  ref.read(quickActionOrderProvider.notifier).resetToDefault();
                },
                child: Text(
                  'Reset to Default',
                  style: TextStyle(
                    fontSize: 14,
                    color: textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isEditMode) {
      return _buildEditMode(context, isDark);
    }
    return _buildNormalMode(context, isDark);
  }
}

