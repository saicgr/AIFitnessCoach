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
import '../screens/nutrition/log_meal_sheet.dart';
import '../screens/workout/widgets/quick_workout_sheet.dart';
import 'main_shell.dart';
import 'glass_sheet.dart';

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

const _categories = <String, List<String>>{
  'Track': ['weight', 'food', 'water', 'photo', 'mood', 'measure'],
  'Workout': ['quick_workout', 'workout', 'steps', 'library'],
  'Plan & Review': ['schedule', 'habits', 'fasting', 'history', 'progress', 'summaries', 'achievements'],
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
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final chipBg = isDark
        ? Colors.white.withValues(alpha: isPinned ? 0.12 : 0.08)
        : Colors.black.withValues(alpha: isPinned ? 0.07 : 0.04);
    final borderColor = isPinned
        ? action.color.withValues(alpha: 0.4)
        : (isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.06));

    void handleTap() {
      HapticFeedback.lightImpact();
      switch (action.id) {
        case 'water':
          _quickAddWater();
          return;
        case 'food':
          Navigator.pop(context);
          showLogMealSheet(context, widget.ref);
          return;
        case 'quick_workout':
          Navigator.pop(context);
          showQuickWorkoutSheet(context, widget.ref);
          return;
        case 'fasting':
          Navigator.pop(context);
          context.push('/fasting');
          return;
        default:
          Navigator.pop(context);
          if (action.route != null) {
            context.push(action.route!);
          }
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: handleTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isPinned ? 12 : 10,
            vertical: isPinned ? 10 : 8,
          ),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: isPinned ? 1.5 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                action.icon,
                size: isPinned ? 18 : 16,
                color: action.color,
              ),
              const SizedBox(width: 6),
              Text(
                action.label,
                style: TextStyle(
                  fontSize: isPinned ? 13 : 12,
                  fontWeight: isPinned ? FontWeight.w600 : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNormalMode(BuildContext context, bool isDark) {
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
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
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: filteredActions.map((id) {
                            final action = quickActionRegistry[id]!;
                            return _buildActionChip(action, isDark, context);
                          }).toList(),
                        ),
                ),
              ] else ...[
                // Pinned section
                _buildSectionHeader('Pinned', textMuted),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: pinnedActions.map((action) {
                      return _buildActionChip(action, isDark, context, isPinned: true);
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                // Category sections
                for (final entry in _categories.entries) ...[
                  _buildSectionHeader(entry.key, textMuted),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: entry.value.map((id) {
                        final action = quickActionRegistry[id];
                        if (action == null) return const SizedBox.shrink();
                        return _buildActionChip(action, isDark, context);
                      }).toList(),
                    ),
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'Drag to reorder. Top 4 appear in your shortcut bar.',
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
                  final isTop4 = index < 4;

                  return Container(
                    key: ValueKey(actionId),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: isTop4
                          ? action.color.withValues(alpha: isDark ? 0.12 : 0.08)
                          : elevatedColor,
                      borderRadius: BorderRadius.circular(12),
                      border: isTop4
                          ? Border.all(color: action.color.withValues(alpha: 0.3))
                          : null,
                    ),
                    child: Row(
                      children: [
                        // Drag handle
                        ReorderableDragStartListener(
                          index: index,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(Icons.drag_handle, color: textMuted, size: 20),
                          ),
                        ),
                        // Icon
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
                        // Label
                        Expanded(
                          child: Text(
                            action.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                        // Badge for top 3
                        if (isTop4)
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

/// Hero card that shows contextual content based on fasting state
class _HeroActionCard extends ConsumerWidget {
  final VoidCallback onClose;

  const _HeroActionCard({required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fastingState = ref.watch(fastingProvider);
    final hasFast = fastingState.hasFast;

    if (hasFast) {
      return _FastingHeroCard(
        fastingState: fastingState,
        onClose: onClose,
        isDark: isDark,
      );
    } else {
      return _PhotoHeroCard(
        onClose: onClose,
        isDark: isDark,
      );
    }
  }
}

/// Hero card showing fasting progress
class _FastingHeroCard extends ConsumerWidget {
  final FastingState fastingState;
  final VoidCallback onClose;
  final bool isDark;

  const _FastingHeroCard({
    required this.fastingState,
    required this.onClose,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final activeFast = fastingState.activeFast;

    // Semi-transparent colors for glassmorphic effect
    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);
    final iconBg = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.06);

    // Calculate progress
    final elapsedMinutes = activeFast?.elapsedMinutes ?? 0;
    final goalMinutes = activeFast?.goalDurationMinutes ?? 960; // Default 16h
    final progress = (elapsedMinutes / goalMinutes).clamp(0.0, 1.0);
    final hours = elapsedMinutes ~/ 60;
    final mins = elapsedMinutes % 60;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            onClose();
            context.push('/fasting');
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
            ),
            child: Row(
            children: [
              // Timer icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.timer,
                  size: 28,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Fasting',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${hours}h ${mins}m',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? Colors.white : Colors.black,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // End Fast button
              _EndFastButton(onClose: onClose, isDark: isDark),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

/// End fast button with loading state
class _EndFastButton extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final bool isDark;

  const _EndFastButton({required this.onClose, required this.isDark});

  @override
  ConsumerState<_EndFastButton> createState() => _EndFastButtonState();
}

class _EndFastButtonState extends ConsumerState<_EndFastButton> {
  bool _isEnding = false;

  Future<void> _endFast() async {
    if (_isEnding) return;

    setState(() => _isEnding = true);
    HapticFeedback.mediumImpact();

    try {
      final userId = await ref.read(apiClientProvider).getUserId();
      if (userId == null) return;

      await ref.read(fastingProvider.notifier).endFast(userId: userId);

      if (mounted) {
        HapticFeedback.lightImpact();
        widget.onClose();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Fast ended successfully'),
              ],
            ),
            backgroundColor: const Color(0xFF2D2D2D),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to end fast: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isEnding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.isDark ? Colors.white : Colors.black;
    final textOnButton = widget.isDark ? Colors.black : Colors.white;

    return GestureDetector(
      onTap: _endFast,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: _isEnding
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: textOnButton,
                ),
              )
            : Text(
                'End',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textOnButton,
                ),
              ),
      ),
    );
  }
}

/// Hero card prompting to take progress photo
class _PhotoHeroCard extends StatelessWidget {
  final VoidCallback onClose;
  final bool isDark;

  const _PhotoHeroCard({
    required this.onClose,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Semi-transparent colors for glassmorphic effect
    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);
    final iconBg = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.06);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onClose();
            context.push('/stats');
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
            ),
            child: Row(
            children: [
              // Camera icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: 28,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Track Your Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Take a progress photo to see your transformation',
                      style: TextStyle(
                        fontSize: 13,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: textMuted,
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

