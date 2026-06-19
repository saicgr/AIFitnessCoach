import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/glass_back_button.dart';
import '../../core/services/posthog_service.dart';
import '../../widgets/coach_floating_button.dart';
import 'providers/library_providers.dart';
import 'tabs/discover_tab.dart';
import 'tabs/exercises_tab.dart';
import 'tabs/my_library_tab.dart';
import 'tabs/my_workouts_tab.dart';
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

  static const _tabLabels = ['Discover', 'Exercises', 'Workouts', 'Custom', 'You'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
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
        _openSaved(); // Saved workouts now live behind the header ☆ icon.
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

  /// Open the user's saved/bookmarked workouts (the `saved_workouts` table) as a
  /// pushed screen — surfaced via the header ☆ icon rather than a top-level pill.
  void _openSaved() {
    HapticService.light();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _SavedWorkoutsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tc = ThemeColors.of(context);
    final backgroundColor = tc.background;
    final elevated = tc.surface;
    final textMuted = tc.textMuted;
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
                        AppLocalizations.of(context).workoutsLibrary.toUpperCase(),
                        style: ZType.disp(30, color: tc.textPrimary),
                      ),
                      const Spacer(),
                      // Saved/bookmarked workouts — surfaced as a header icon
                      // (not a top-level pill) so the pill row stays at five.
                      IconButton(
                        onPressed: _openSaved,
                        tooltip: 'Saved workouts',
                        icon: Icon(Icons.bookmark_border_rounded,
                            color: tc.textPrimary, size: 24),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Search bar — updates exerciseSearchProvider and auto-switches to Exercises tab
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: elevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
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

                const SizedBox(height: 10),

                // Tab selector pills (signature-v2 `.nl-ltab`). Flex each pill
                // so the four share the row width evenly — fixed-width pills
                // overflowed narrow screens by ~4.5px (issue 9). Equal Expanded
                // cells adapt SE..Pro Max. Active pill = solid accent fill +
                // dark text; inactive = hairline border + muted label.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: List.generate(_tabLabels.length, (index) {
                      final isSelected = _tabController.index == index;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(
                            end: index < _tabLabels.length - 1 ? 6 : 0,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              HapticService.light();
                              _tabController.animateTo(index);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 30,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? accentColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color: isSelected
                                      ? accentColor
                                      : AppColors.cardBorder,
                                ),
                              ),
                              child: Text(
                                _tabLabels[index].toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ZType.lbl(
                                  11,
                                  // Active pill rides the accent fill, so the
                                  // label flips to the dark-on-orange tone.
                                  color: isSelected
                                      ? const Color(0xFF160B03)
                                      : textMuted,
                                  letterSpacing: 1.3,
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
                      const MyWorkoutsTab(mode: MyWorkoutsMode.generated),
                      const MyWorkoutsTab(mode: MyWorkoutsMode.custom),
                      const MyLibraryTab(),
                    ],
                  ),
                ),

              ],
            ),

            // Coach access on Library. The screen uses its own top pill row (not
            // a bottom FloatingTabBar), so it never inherits a coach-sparkle
            // slot — mount the CoachFloatingButton in collapsed (icon-only)
            // form. liftAboveNav:false drops it to the real bottom edge. The
            // "Build a workout" CTA now lives on the Custom pill, so there's no
            // docked button to clear anymore.
            const CoachFloatingButton(liftAboveNav: false),
          ],
        ),
      ),
    );
  }
}

/// Pushed screen for the user's saved/bookmarked workouts (header ☆ icon).
class _SavedWorkoutsScreen extends StatelessWidget {
  const _SavedWorkoutsScreen();

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Scaffold(
      backgroundColor: tc.background,
      appBar: AppBar(
        backgroundColor: tc.background,
        elevation: 0,
        iconTheme: IconThemeData(color: tc.textPrimary),
        title: Text(
          'SAVED',
          style: ZType.disp(22, color: tc.textPrimary),
        ),
      ),
      body: const SafeArea(top: false, child: SavedWorkoutsTab()),
    );
  }
}
