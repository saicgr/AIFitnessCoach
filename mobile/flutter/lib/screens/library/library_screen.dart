import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/glass_back_button.dart';
import 'tabs/discover_tab.dart';
import 'tabs/exercises_tab.dart';
import 'tabs/my_library_tab.dart';

// Export providers and models for external use
export 'providers/library_providers.dart';
export 'models/filter_option.dart';
export 'models/exercises_state.dart';

/// Main Library Screen with 3-tab layout: Discover, Exercises, Mine.
class LibraryScreen extends ConsumerStatefulWidget {
  final int? initialTab;

  const LibraryScreen({super.key, this.initialTab});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabLabels = ['Discover', 'Exercises', 'Mine'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab ?? 0,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _switchToExercises([String? muscleFilter]) {
    HapticService.light();
    _tabController.animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accent = ref.watch(accentColorProvider);
    final accentColor = accent.getColor(isDark);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header with title
                Padding(
                  padding: const EdgeInsets.fromLTRB(56, 12, 16, 0),
                  child: Row(
                    children: [
                      Text(
                        'Library',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: () => _switchToExercises(),
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: elevated,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: textMuted.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: textMuted,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Search exercises...',
                              style: TextStyle(
                                color: textMuted,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: accentColor.withValues(alpha: 0.6),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Tab selector pills
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: List.generate(_tabLabels.length, (index) {
                      final isSelected = _tabController.index == index;
                      return Padding(
                        padding: EdgeInsets.only(
                          right: index < _tabLabels.length - 1 ? 8 : 0,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            HapticService.light();
                            _tabController.animateTo(index);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? accentColor : elevated,
                              borderRadius: BorderRadius.circular(20),
                              border: isSelected
                                  ? null
                                  : Border.all(
                                      color:
                                          textMuted.withValues(alpha: 0.2),
                                    ),
                            ),
                            child: Text(
                              _tabLabels[index],
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 8),

                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      DiscoverTab(onSwitchToExercises: _switchToExercises),
                      const ExercisesTab(),
                      const MyLibraryTab(),
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
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
