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
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: textPrimary,
            unselectedLabelColor: textMuted,
            indicatorColor: AppColors.cyan,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'Favorites'),
              Tab(text: 'Staples'),
              Tab(text: 'Avoided'),
              Tab(text: 'Queue'),
              Tab(text: 'Custom'),
            ],
          ),
          Expanded(
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
        ],
      ),
    );
  }
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
        Positioned(
          right: 16,
          bottom: 16,
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
