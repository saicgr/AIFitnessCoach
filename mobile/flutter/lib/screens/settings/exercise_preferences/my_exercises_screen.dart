import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/custom_exercises_provider.dart';
import '../../../data/models/custom_exercise.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../core/services/posthog_service.dart';
import '../../../widgets/pill_app_bar.dart';
import '../../custom_exercises/widgets/create_exercise_sheet.dart';
import '../../custom_exercises/widgets/custom_exercise_card.dart';
import 'favorite_exercises_screen.dart';
import 'staple_exercises_screen.dart';
import 'exercise_queue_screen.dart';
import 'avoided_exercises_screen.dart';
import 'avoided_muscles_screen.dart';

/// Unified screen for all exercise preferences with a flat tab bar.
/// Tabs: Favorites (0), Staples (1), Avoided (2), Queue (3), Custom (4)
class MyExercisesScreen extends ConsumerStatefulWidget {
  /// Initial tab index — see class doc for mapping.
  final int initialTab;

  const MyExercisesScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<MyExercisesScreen> createState() => _MyExercisesScreenState();
}

class _MyExercisesScreenState extends ConsumerState<MyExercisesScreen>
    with SingleTickerProviderStateMixin {
  static const int _tabCount = 5;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabCount,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, _tabCount - 1),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(posthogServiceProvider).capture(eventName: 'my_exercises_viewed');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const PillAppBar(title: 'Exercise Preferences'),
      body: Stack(
        children: [
          // The full-screen tab body fills behind the floating pill bar so
          // content can scroll under it (matches the main shell pattern).
          // Add bottom padding so list ends remain reachable above the bar.
          Padding(
            padding: const EdgeInsets.only(bottom: 76),
            child: TabBarView(
              controller: _tabController,
              children: const [
                _FavoritesTab(),
                _StaplesTab(),
                _AvoidedTab(),
                _QueueTab(),
                _CustomTab(),
              ],
            ),
          ),
          // Floating pill bar — icon + label below, mirrors the app's main
          // bottom nav style. All five tabs are always visible (no expand-
          // on-select trick) per the user's request.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  return _FloatingPillTabs(
                    selectedIndex: _tabController.index,
                    onTap: (i) {
                      HapticFeedback.selectionClick();
                      _tabController.animateTo(i);
                    },
                    isDark: isDark,
                    textMuted: textMuted,
                    textPrimary: textPrimary,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating pill-shaped tab bar with icon-over-label tiles. Visually
/// identical in feel to the main shell's bottom nav so users get a
/// consistent navigation language across the app.
class _FloatingPillTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final bool isDark;
  final Color textMuted;
  final Color textPrimary;

  const _FloatingPillTabs({
    required this.selectedIndex,
    required this.onTap,
    required this.isDark,
    required this.textMuted,
    required this.textPrimary,
  });

  static const _items = <_PillItem>[
    _PillItem(icon: Icons.favorite_border, selectedIcon: Icons.favorite, label: 'Favorites', accent: AppColors.error),
    _PillItem(icon: Icons.push_pin_outlined, selectedIcon: Icons.push_pin, label: 'Staples', accent: AppColors.cyan),
    _PillItem(icon: Icons.block_outlined, selectedIcon: Icons.block, label: 'Avoided', accent: AppColors.orange),
    _PillItem(icon: Icons.bookmark_border, selectedIcon: Icons.bookmark, label: 'Queue', accent: AppColors.cyan),
    _PillItem(icon: Icons.tune, selectedIcon: Icons.tune, label: 'Custom', accent: AppColors.cyan),
  ];

  @override
  Widget build(BuildContext context) {
    final pillBarColor = isDark
        ? Colors.grey.shade900.withValues(alpha: 0.92)
        : Colors.grey.shade100.withValues(alpha: 0.95);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Material(
        elevation: 8,
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: pillBarColor,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final isSelected = i == selectedIndex;
              return Expanded(
                child: Semantics(
                  label: '${item.label} tab, ${i + 1} of ${_items.length}',
                  selected: isSelected,
                  button: true,
                  child: InkWell(
                    onTap: () => onTap(i),
                    borderRadius: BorderRadius.circular(18),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? item.accent.withValues(alpha: isDark ? 0.18 : 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected ? item.selectedIcon : item.icon,
                            size: 20,
                            color: isSelected ? item.accent : textMuted,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected ? item.accent : textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _PillItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Color accent;
  const _PillItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.accent,
  });
}

/// Tab 1: Favorite Exercises — AI prioritizes these when generating workouts.
class _FavoritesTab extends ConsumerStatefulWidget {
  const _FavoritesTab();

  @override
  ConsumerState<_FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends ConsumerState<_FavoritesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const FavoriteExercisesScreen(embedded: true);
  }
}

/// Tab 2: Staple Exercises — core lifts that never rotate out.
class _StaplesTab extends ConsumerStatefulWidget {
  const _StaplesTab();

  @override
  ConsumerState<_StaplesTab> createState() => _StaplesTabState();
}

class _StaplesTabState extends ConsumerState<_StaplesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const StapleExercisesScreen(embedded: true);
  }
}

/// Tab 3: Avoided — merges Avoided Exercises + Avoided Muscles (inner segment).
class _AvoidedTab extends ConsumerStatefulWidget {
  const _AvoidedTab();

  @override
  ConsumerState<_AvoidedTab> createState() => _AvoidedTabState();
}

class _AvoidedTabState extends ConsumerState<_AvoidedTab>
    with AutomaticKeepAliveClientMixin {
  /// 0 = Avoided Exercises, 1 = Avoided Muscles
  int _selectedSegment = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Column(
      children: [
        // Segment selector
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildSegmentButton(
                  label: 'Exercises',
                  icon: Icons.block,
                  isSelected: _selectedSegment == 0,
                  color: AppColors.error,
                  onTap: () => setState(() => _selectedSegment = 0),
                  isDark: isDark,
                ),
                const SizedBox(width: 4),
                _buildSegmentButton(
                  label: 'Muscles',
                  icon: Icons.accessibility_new,
                  isSelected: _selectedSegment == 1,
                  color: AppColors.orange,
                  onTap: () => setState(() => _selectedSegment = 1),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
        // Content
        Expanded(
          child: _selectedSegment == 0
              ? const AvoidedExercisesScreen(embedded: true)
              : const AvoidedMusclesScreen(embedded: true),
        ),
      ],
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: color.withValues(alpha: 0.3))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? color : textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? textPrimary : textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tab 4: Queue — exercise queue (wraps existing screen).
class _QueueTab extends StatefulWidget {
  const _QueueTab();

  @override
  State<_QueueTab> createState() => _QueueTabState();
}

class _QueueTabState extends State<_QueueTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const ExerciseQueueScreen(embedded: true);
  }
}

/// Tab 5: Custom — user-created custom exercises.
class _CustomTab extends ConsumerStatefulWidget {
  const _CustomTab();

  @override
  ConsumerState<_CustomTab> createState() => _CustomTabState();
}

class _CustomTabState extends ConsumerState<_CustomTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customExercisesProvider.notifier).initialize();
    });
  }

  void _showCreateSheet() {
    HapticService.light();
    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => const GlassSheet(
        child: CreateExerciseSheet(),
      ),
    );
  }

  void _confirmDelete(CustomExercise exercise) {
    HapticService.medium();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exercise'),
        content: Text(
            'Are you sure you want to delete "${exercise.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(customExercisesProvider.notifier)
                  .deleteExercise(exercise.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(customExercisesProvider);
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    // Listen for success/error messages
    ref.listen<CustomExercisesState>(customExercisesProvider, (previous, next) {
      if (next.successMessage != null &&
          previous?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        ref.read(customExercisesProvider.notifier).clearSuccess();
      }
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        ref.read(customExercisesProvider.notifier).clearError();
      }
    });

    if (state.isLoading && state.exercises.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_circle_outline,
                size: 48, color: textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'No custom exercises yet',
              style: TextStyle(fontSize: 16, color: textMuted),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your own exercises to use in workouts',
              style: TextStyle(
                  fontSize: 13, color: textMuted.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _showCreateSheet,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Exercise'),
              style: FilledButton.styleFrom(
                backgroundColor: cyan,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () =>
              ref.read(customExercisesProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.exercises.length,
            itemBuilder: (context, index) {
              final exercise = state.exercises[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CustomExerciseCard(
                  exercise: exercise,
                  onTap: () {},
                  onDelete: () => _confirmDelete(exercise),
                ),
              );
            },
          ),
        ),
        // Sit above the floating tab bar (~76pt) so it stays visible.
        Positioned(
          right: 16,
          bottom: 96,
          child: FloatingActionButton.extended(
            onPressed: _showCreateSheet,
            backgroundColor: cyan,
            icon: const Icon(Icons.add, color: Colors.black),
            label: const Text(
              'Create',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
