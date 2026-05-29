import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/glass_back_button.dart';
import '../../core/services/posthog_service.dart';
import '../../widgets/coach_floating_button.dart';
import 'providers/library_providers.dart';
import 'tabs/discover_tab.dart';
import 'tabs/exercises_tab.dart';
import 'tabs/my_library_tab.dart';
import 'tabs/workouts_tab.dart';

import '../../l10n/generated/app_localizations.dart';
// Export providers and models for external use
export 'providers/library_providers.dart';
export 'models/filter_option.dart';
export 'models/exercises_state.dart';

/// Main Library Screen with 3-tab layout: Discover, Exercises, Mine.
class LibraryScreen extends ConsumerStatefulWidget {
  final int? initialTab;

  /// Optional category tile key from the Plan-tab library grid
  /// (strength | cardio | mobility | hiit | yoga | saved). When present we
  /// map it to a concrete Exercises-tab DB-category filter (or the Saved tab
  /// for `saved`) on first frame so the screen opens pre-filtered.
  final String? initialCategory;

  const LibraryScreen({super.key, this.initialTab, this.initialCategory});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabLabels = ['Discover', 'Exercises', 'Workouts', 'Saved'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab ?? 0,
    );
    ref.read(posthogServiceProvider).capture(
      eventName: 'library_viewed',
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(posthogServiceProvider).capture(
          eventName: 'library_tab_changed',
          properties: {'tab_name': _tabLabels[_tabController.index]},
        );
        setState(() {});
      }
    });

    // Apply a category tile's pre-filter on first frame (deep-link from the
    // Plan-tab library grid). Done post-frame so the TabController + filter
    // providers are fully built before we mutate state / animate tabs.
    final category = widget.initialCategory;
    if (category != null && category.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _applyCategoryDeepLink(category);
      });
    }
  }

  /// Map a Plan-tab library tile key to a concrete Library action.
  ///
  /// Tile keys come from `workout_library_grid.dart`:
  /// strength | cardio | mobility | hiit | yoga | saved.
  ///
  /// The Exercises tab filters on the DB `category` column (verified live
  /// against `exercise_library_cleaned`, May 2026):
  ///   strength=1330, cardio=253, stretching=208, core=190, yoga=78,
  ///   plyometric=60, power=37, conditioning=22, functional=10, balance=4.
  /// So each tile key is mapped to a category value that actually returns
  /// rows (no empty lists):
  ///   strength → 'strength'   (1330 rows, exact match)
  ///   cardio   → 'cardio'     (253 rows, exact match)
  ///   mobility → 'stretching' (208 rows — DB has no 'mobility' category)
  ///   hiit     → 'plyometric' (60 rows — DB has no 'hiit'; plyometric is the
  ///                            closest high-intensity category. Note the DB
  ///                            value is singular 'plyometric', NOT 'plyometrics')
  ///   yoga     → 'yoga'       (78 rows, exact match)
  ///   saved    → Saved tab    (no category filter)
  void _applyCategoryDeepLink(String tileKey) {
    switch (tileKey) {
      case 'saved':
        _tabController.animateTo(3); // Saved tab — no category filter applied.
        return;
      case 'strength':
        _switchToExercises('strength', 'category');
        return;
      case 'cardio':
        _switchToExercises('cardio', 'category');
        return;
      case 'mobility':
        // DB has no 'mobility' category; 'stretching' is the mobility corpus.
        _switchToExercises('stretching', 'category');
        return;
      case 'hiit':
        // DB has no 'hiit' category; 'plyometric' (singular) is the closest
        // high-intensity match that returns rows.
        _switchToExercises('plyometric', 'category');
        return;
      case 'yoga':
        _switchToExercises('yoga', 'category');
        return;
      default:
        // Unknown key — leave the screen on its default tab, no filter.
        return;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// [axis] lets the Discover tab disambiguate label collisions across
  /// Browse sections (e.g. "Cardio" exists as both equipment and category).
  /// Accepted values: 'muscle', 'equipment', 'category'. Null = auto-detect.
  void _switchToExercises([String? filter, String? axis]) {
    HapticService.light();
    if (filter != null) {
      const muscles = {'Chest', 'Back', 'Shoulders', 'Arms', 'Legs', 'Core', 'Glutes'};
      const equipment = {'Weights', 'Bodyweight', 'Machines', 'Cardio'};
      // Clear all three filter axes before applying the new one so the
      // Exercises tab reflects exactly one selection.
      ref.read(selectedMuscleGroupsProvider.notifier).state = {};
      ref.read(selectedEquipmentsProvider.notifier).state = {};
      ref.read(selectedCategoriesProvider.notifier).state = {};

      final resolvedAxis = axis ??
          (muscles.contains(filter)
              ? 'muscle'
              : equipment.contains(filter)
                  ? 'equipment'
                  : 'category');

      switch (resolvedAxis) {
        case 'muscle':
          ref.read(selectedMuscleGroupsProvider.notifier).state = {filter};
          break;
        case 'equipment':
          ref.read(selectedEquipmentsProvider.notifier).state = {filter};
          break;
        case 'category':
          // DB category values are lowercase.
          ref.read(selectedCategoriesProvider.notifier).state = {filter.toLowerCase()};
          break;
      }
    }
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
                // Header — back button is inline with the title so spacing
                // between the header row and the search bar is deterministic
                // across iOS and Android (no overlap with a floating button).
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      GlassBackButton(
                        onTap: () {
                          HapticService.light();
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context).workoutsLibrary,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Search bar — updates exerciseSearchProvider and auto-switches to Exercises tab
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          child: TextField(
                            onChanged: (value) {
                              ref.read(exerciseSearchProvider.notifier).state = value;
                              if (value.isNotEmpty && _tabController.index != 1) {
                                ref.read(posthogServiceProvider).capture(
                                  eventName: 'library_search_initiated',
                                );
                                _tabController.animateTo(1);
                              }
                            },
                            style: TextStyle(
                              color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context).supersetExercisePickerSearchExercises,
                              hintStyle: TextStyle(
                                color: textMuted,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Tab selector pills. Flex each pill so the four share the row
                // width evenly — fixed-width pills overflowed narrow screens by
                // ~4.5px (issue 9). Equal Expanded cells adapt SE..Pro Max.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: List.generate(_tabLabels.length, (index) {
                      final isSelected = _tabController.index == index;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(
                            end: index < _tabLabels.length - 1 ? 8 : 0,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              HapticService.light();
                              _tabController.animateTo(index);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                      const WorkoutsTab(),
                      const MyLibraryTab(),
                    ],
                  ),
                ),
              ],
            ),

            // Coach access on Library. The screen sits under the Workout tab
            // but uses its own Material TabBar (4 tabs at the top of the
            // screen), not a bottom FloatingTabBar — so it never inherits a
            // coach-sparkle slot. Per the redesign plan's "coach access
            // universal" directive, mount the CoachFloatingButton in
            // collapsed (icon-only) form. liftAboveNav:false drops it to the
            // real bottom edge — Library has no bottom nav to clear, so the
            // default +100pt lift left it floating over content (issue 10).
            const CoachFloatingButton(liftAboveNav: false),
          ],
        ),
      ),
    );
  }
}
