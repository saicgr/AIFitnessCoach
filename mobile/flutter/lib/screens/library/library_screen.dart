import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/glass_back_button.dart';
import '../../widgets/segmented_tab_bar.dart';
import 'tabs/netflix_exercises_tab.dart';
import 'tabs/programs_tab.dart';
import 'tabs/skills_tab.dart';

// Export providers and models for external use
export 'providers/library_providers.dart';
export 'models/filter_option.dart';
export 'models/exercises_state.dart';

/// Main Library Screen with tabs for Exercises, Programs, and My Stats
class LibraryScreen extends ConsumerStatefulWidget {
  /// Initial tab index: 0 = Exercises, 1 = Programs, 2 = Skills
  final int initialTab;

  const LibraryScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
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
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                // Header with title only
                _buildHeader(context, isDark),

                // Tab Bar - full width
                _buildTabBar(context, elevated, cyan, textMuted, isDark),

                const SizedBox(height: 8),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      NetflixExercisesTab(),
                      ProgramsTab(),
                      SkillsTab(),
                    ],
                  ),
                ),
              ],
            ),

            // Floating back button
            Positioned(
              top: 8,
              left: 8,
              child: GlassBackButton(
                onTap: () {
                  HapticService.light();
                  context.pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(56, 12, 16, 16),
      child: Row(
        children: [
          // Title (offset to account for floating back button)
          Text(
            'Library',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(
    BuildContext context,
    Color elevated,
    Color cyan,
    Color textMuted,
    bool isDark,
  ) {
    return SegmentedTabBar(
      controller: _tabController,
      showIcons: false,
      tabs: const [
        SegmentedTabItem(label: 'Exercises'),
        SegmentedTabItem(label: 'Programs'),
        SegmentedTabItem(label: 'Skills'),
      ],
    );
  }
}
