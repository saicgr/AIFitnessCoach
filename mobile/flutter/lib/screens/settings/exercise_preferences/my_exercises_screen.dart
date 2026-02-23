import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/glass_back_button.dart';
import 'favorite_exercises_screen.dart';
import 'staple_exercises_screen.dart';
import 'exercise_queue_screen.dart';
import 'avoided_exercises_screen.dart';
import 'avoided_muscles_screen.dart';

/// Unified screen for all exercise preferences with a tab bar.
/// Consolidates: Favorites, Staples, Queue, Avoided Exercises, Avoided Muscles
class MyExercisesScreen extends ConsumerStatefulWidget {
  /// Initial tab index (0=Favorites, 1=Avoided, 2=Queue)
  final int initialTab;

  const MyExercisesScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<MyExercisesScreen> createState() => _MyExercisesScreenState();
}

class _MyExercisesScreenState extends ConsumerState<MyExercisesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
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
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const GlassBackButton(),
        title: Text(
          'My Exercises',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
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
          tabs: const [
            Tab(text: 'Favorites'),
            Tab(text: 'Avoided'),
            Tab(text: 'Queue'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FavoritesTab(),
          _AvoidedTab(),
          _QueueTab(),
        ],
      ),
    );
  }
}

/// Tab 1: Favorites - merges Favorite Exercises + Staple Exercises
class _FavoritesTab extends ConsumerStatefulWidget {
  const _FavoritesTab();

  @override
  ConsumerState<_FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends ConsumerState<_FavoritesTab>
    with AutomaticKeepAliveClientMixin {
  /// 0 = Favorite Exercises, 1 = Staple Exercises
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
                  label: 'Favorites',
                  icon: Icons.favorite,
                  isSelected: _selectedSegment == 0,
                  color: AppColors.error,
                  onTap: () => setState(() => _selectedSegment = 0),
                  isDark: isDark,
                ),
                const SizedBox(width: 4),
                _buildSegmentButton(
                  label: 'Staples',
                  icon: Icons.push_pin,
                  isSelected: _selectedSegment == 1,
                  color: AppColors.cyan,
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
              ? const FavoriteExercisesScreen(embedded: true)
              : const StapleExercisesScreen(embedded: true),
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

/// Tab 2: Avoided - merges Avoided Exercises + Avoided Muscles
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

/// Tab 3: Queue - exercise queue (wraps existing screen)
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
