import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
// Prefixed: `empty_state.dart` also exports a `SkeletonCard`, so the shared
// instant-load skeleton kit is namespaced to disambiguate.
import '../../../core/widgets/skeleton/skeleton.dart' as skel;
import '../../../widgets/design_system/zealova.dart';
import '../../../widgets/empty_state.dart';
import '../models/filter_option.dart';
import '../providers/library_providers.dart';
import '../providers/muscle_group_images_provider.dart';
import '../widgets/exercise_search_bar.dart';
import '../widgets/filter_button.dart';
import '../widgets/active_filter_chips.dart';
import '../widgets/exercise_card.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../data/services/haptic_service.dart';
import '../../custom_exercises/widgets/create_exercise_sheet.dart';
import '../../exercises/import_exercise_screen.dart';
import '../components/exercise_filter_sheet.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Exercises tab content with search, filters, and paginated list
class ExercisesTab extends ConsumerStatefulWidget {
  const ExercisesTab({super.key});

  @override
  ConsumerState<ExercisesTab> createState() => _ExercisesTabState();
}

class _ExercisesTabState extends ConsumerState<ExercisesTab> {
  final ScrollController _scrollController = ScrollController();
  Set<String> _prevMuscles = {};
  Set<String> _prevEquipments = {};
  Set<String> _prevTypes = {};
  Set<String> _prevGoals = {};
  Set<String> _prevSuitableFor = {};
  Set<String> _prevAvoid = {};
  String _prevSearch = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when near bottom
      ref.read(exercisesNotifierProvider.notifier).loadExercises();
    }
  }

  void _showFilterSheet(BuildContext context) {
    showGlassSheet(
      context: context,
      builder: (context) => const ExerciseFilterSheet(),
    );
  }

  /// Open the manual "create custom exercise" form. Mirrors the entry point in
  /// `custom_exercises_screen.dart` so behavior stays consistent.
  void _showCreateExercise(BuildContext context) {
    HapticService.light();
    // `CreateExerciseSheet` is fully self-chromed (its own blur, border, drag
    // handle, and close button), so it is NOT wrapped in a `GlassSheet` here —
    // wrapping would render a SECOND drag handle and a double blur/border.
    // (Mirrors the entry point in `custom_exercises_screen.dart`.)
    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (_) => const CreateExerciseSheet(),
    );
  }

  /// The muscle-group labels shown in the inline quick-filter chip row.
  ///
  /// Prefer the authoritative body-part list from `filterOptionsProvider` (kept
  /// in the order the backend returns) so the chips always reflect the real
  /// catalog. Falls back to a curated ordered set only while filter options are
  /// still loading or if the API hasn't returned any body parts.
  List<String> _muscleChipOptions(
    AsyncValue<ExerciseFilterOptions> filterOptions,
  ) {
    const fallback = ['Chest', 'Back', 'Legs', 'Shoulders', 'Core', 'Arms'];
    final bodyParts = filterOptions.valueOrNull?.bodyParts;
    if (bodyParts == null || bodyParts.isEmpty) return fallback;
    return bodyParts.map((o) => o.name).toList();
  }

  @override
  Widget build(BuildContext context) {
    final exercisesState = ref.watch(exercisesNotifierProvider);
    final filterOptions = ref.watch(filterOptionsProvider);
    final searchQuery = ref.watch(exerciseSearchProvider);
    final selectedMuscles = ref.watch(selectedMuscleGroupsProvider);
    final selectedEquipments = ref.watch(selectedEquipmentsProvider);
    final selectedTypes = ref.watch(selectedExerciseTypesProvider);
    final selectedGoals = ref.watch(selectedGoalsProvider);
    final selectedSuitableFor = ref.watch(selectedSuitableForSetProvider);
    final selectedAvoid = ref.watch(selectedAvoidSetProvider);
    final searchSuggestion = ref.watch(searchSuggestionProvider);

    final performedOnly = ref.watch(performedOnlyProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tc = ThemeColors.of(context);
    final cyan = tc.accent;
    final textMuted = tc.textMuted;
    final activeFilters = getActiveFilterCount(ref);

    // Get total exercise count from filter options (when no filters applied)
    final totalExercises = filterOptions.valueOrNull?.totalExercises;

    // Check if filters or search changed and refresh exercises
    if (selectedMuscles != _prevMuscles ||
        selectedEquipments != _prevEquipments ||
        selectedTypes != _prevTypes ||
        selectedGoals != _prevGoals ||
        selectedSuitableFor != _prevSuitableFor ||
        selectedAvoid != _prevAvoid ||
        searchQuery != _prevSearch) {
      _prevMuscles = selectedMuscles;
      _prevEquipments = selectedEquipments;
      _prevTypes = selectedTypes;
      _prevGoals = selectedGoals;
      _prevSuitableFor = selectedSuitableFor;
      _prevAvoid = selectedAvoid;
      _prevSearch = searchQuery;
      // Schedule refresh after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(exercisesNotifierProvider.notifier).loadExercises(refresh: true);
      });
    }

    // Display label for the count widget. Avoids the "0 exercises found"
    // mirage during cold load — show "Loading…" until results arrive, and
    // prefer the authoritative total from filter-options when no filters are
    // active so the user sees real progress instead of a zero placeholder.
    final bool isInitialLoading =
        exercisesState.isLoading && exercisesState.exercises.isEmpty;
    final int activeFilterCount = activeFilters;
    final String countLabel;
    if (isInitialLoading) {
      countLabel = totalExercises != null
          ? 'Loading $totalExercises exercises…'
          : 'Loading exercises…';
    } else if (activeFilterCount == 0 &&
        searchQuery.isEmpty &&
        totalExercises != null) {
      countLabel = '$totalExercises exercises';
    } else {
      countLabel = '${exercisesState.exercises.length} exercises found';
    }

    return Column(
      children: [
        // Filter button row (search is handled by the top-level Library search bar)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                countLabel.toUpperCase(),
                style: ZType.lbl(11, color: textMuted, letterSpacing: 1.4),
              ),
              const Spacer(),
              // Create a custom exercise (manual form).
              _MiniIconButton(
                icon: Icons.add_rounded,
                tooltip: 'Create exercise',
                onTap: () => _showCreateExercise(context),
              ),
              const SizedBox(width: 6),
              // AI-import a custom exercise (photo / video / describe). Styled
              // distinctly from the plain "+" so the smart action stands out.
              _AiMiniButton(
                tooltip: 'Import with AI',
                onTap: () => showImportExerciseScreen(context),
              ),
              const SizedBox(width: 8),
              // "History" (performed-only) toggle chip — filters the catalog to
              // exercises the user has actually logged.
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: ZealovaChip(
                  label: AppLocalizations.of(context).exercisesTabHistoryToggle,
                  icon: performedOnly ? Icons.check_circle : Icons.history,
                  selected: performedOnly,
                  onTap: () {
                    ref.read(performedOnlyProvider.notifier).state =
                        !performedOnly;
                  },
                ),
              ),
              FilterButton(
                activeFilterCount: activeFilters,
                onTap: () => _showFilterSheet(context),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Inline muscle-group chip row (signature-v2 `.nl-chips`). Quick-toggle
        // the most-used body parts without opening the advanced filter sheet —
        // selecting/deselecting mutates `selectedMuscleGroupsProvider`, which
        // the build above watches and refreshes the list against (lines ~91).
        _MuscleChipRow(
          options: _muscleChipOptions(filterOptions),
          selected: selectedMuscles,
        ),

        const SizedBox(height: 4),

        // "Did you mean?" suggestion banner
        if (searchSuggestion != null && searchSuggestion.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () {
                ref.read(exerciseSearchProvider.notifier).state = searchSuggestion;
                ref.read(searchSuggestionProvider.notifier).state = null;
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: tc.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 16, color: cyan),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(fontSize: 14, color: textMuted),
                          children: [
                            const TextSpan(text: 'Did you mean: '),
                            TextSpan(
                              text: searchSuggestion,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: cyan,
                              ),
                            ),
                            const TextSpan(text: '?'),
                          ],
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 16, color: textMuted),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.1, end: 0),
          const SizedBox(height: 8),
        ],

        // Active filter chips. Muscle selections are already represented as
        // highlighted pills in the row above, so only surface this second row
        // when a NON-muscle filter (equipment/type/goal/suitable/avoid) is
        // active — otherwise it's redundant chrome that just adds a gap.
        if (selectedEquipments.isNotEmpty ||
            selectedTypes.isNotEmpty ||
            selectedGoals.isNotEmpty ||
            selectedSuitableFor.isNotEmpty ||
            selectedAvoid.isNotEmpty) ...[
          const ActiveFilterChipsList(),
          const SizedBox(height: 8),
        ],

        // Exercise list
        Expanded(
          child: _buildExerciseList(
            context,
            exercisesState,
            searchQuery,
            activeFilters,
            totalExercises,
            cyan,
            textMuted,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseList(
    BuildContext context,
    exercisesState,
    String searchQuery,
    int activeFilters,
    int? totalExercises,
    Color cyan,
    Color textMuted,
    bool isDark,
  ) {
    // Handle loading state — show a layout-matched shimmer list instead of a
    // blocking spinner. Each skeleton row mirrors an ExerciseCard (leading
    // square thumbnail + two text lines) so the skeleton → content swap is
    // reflow-free. A returning user is seeded from the disk cache and skips
    // this entirely; this is purely the cold-install affordance.
    if (exercisesState.isLoading && exercisesState.exercises.isEmpty) {
      return skel.SkeletonList(
        scrollable: true,
        itemCount: 8,
        spacing: 10,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemBuilder: (context, _) => const skel.SkeletonCard(
          showLeading: true,
          leadingSize: 56,
          lines: 2,
          height: 84,
        ),
      );
    }

    // Handle error state
    if (exercisesState.error != null && exercisesState.exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: isDark ? AppColors.error : AppColorsLight.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.exercisesTabFailedToLoadExercises(exercisesState.error)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref
                  .read(exercisesNotifierProvider.notifier)
                  .loadExercises(refresh: true),
              child: Text(AppLocalizations.of(context).buttonRetry),
            ),
          ],
        ),
      );
    }

    // Show exercises (backend handles both filters AND search now)
    // Client-side "performed only" filter
    final performedOnlyActive = ref.watch(performedOnlyProvider);
    var filtered = exercisesState.exercises;
    if (performedOnlyActive) {
      final historyAsync = ref.watch(exerciseHistoryProvider);
      final performedNames = historyAsync.valueOrNull
              ?.map((e) => e.exerciseName.toLowerCase())
              .toSet() ??
          <String>{};
      if (performedNames.isNotEmpty) {
        filtered = filtered
            .where((e) => performedNames.contains(e.name.toLowerCase()))
            .toList();
      }
    }

    if (filtered.isEmpty && !exercisesState.isLoading) {
      return EmptyState.noExercises(
        context,
        onAction: searchQuery.isNotEmpty || activeFilters > 0
            ? () => clearSearchAndFilters(ref)
            : null,
      );
    }

    // Calculate display count - show loading indicator if more available
    final hasMoreToLoad = exercisesState.hasMore;
    final itemCount = filtered.length + (hasMoreToLoad ? 1 : 0);

    // Determine count to display:
    // - If no filters/search and we have total from filter options: use that
    // - Otherwise use the current filtered count (which is accurate since backend now filters properly)
    final displayCount = (activeFilters == 0 &&
            searchQuery.isEmpty &&
            totalExercises != null)
        ? totalExercises
        : filtered.length;
    // Show "+" only if there might be more to load
    final showPlus = exercisesState.hasMore &&
        (activeFilters > 0 || searchQuery.isNotEmpty);

    return Column(
      children: [
        // Exercise list with infinite scroll
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              // Loading indicator at the end
              if (index >= filtered.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: exercisesState.isLoading
                        ? CircularProgressIndicator(color: cyan)
                        : TextButton(
                            onPressed: () => ref
                                .read(exercisesNotifierProvider.notifier)
                                .loadExercises(),
                            child: Text(
                              AppLocalizations.of(context).exercisesLoadMore,
                              style: TextStyle(color: cyan),
                            ),
                          ),
                  ),
                );
              }

              final exercise = filtered[index];
              // Only animate the first 10 items to avoid performance issues
              if (index < 10) {
                return ExerciseCard(exercise: exercise)
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: index * 30));
              }
              return ExerciseCard(exercise: exercise);
            },
          ),
        ),
      ],
    );
  }
}

/// Horizontally-scrolling quick-filter chip row for muscle groups
/// (signature-v2 `.nl-chips`). Each chip toggles its label in
/// `selectedMuscleGroupsProvider` — case-insensitively, mirroring the advanced
/// filter sheet's `_MuscleImageGrid.onToggle` so the two surfaces stay in sync.
class _MuscleChipRow extends ConsumerWidget {
  final List<String> options;
  final Set<String> selected;

  const _MuscleChipRow({
    required this.options,
    required this.selected,
  });

  /// Resolve a muscle/body-part label to its illustration asset, matching the
  /// `muscleGroupAssets` keys case-insensitively. Returns null for groups we
  /// don't have art for (e.g. "Cardio", "Abdominals") so the chip falls back to
  /// a clean text-only pill rather than a broken thumbnail.
  String? _assetFor(String name) {
    final lower = name.toLowerCase();
    for (final entry in muscleGroupAssets.entries) {
      if (entry.key.toLowerCase() == lower) return entry.value;
    }
    return null;
  }

  void _toggle(WidgetRef ref, String value) {
    final newSet = Set<String>.from(selected);
    // Match case-insensitively so a provider value seeded from a deep-link
    // (e.g. 'Chest') still toggles off against the chip's label.
    final existing = newSet.firstWhere(
      (v) => v.toLowerCase() == value.toLowerCase(),
      orElse: () => '',
    );
    if (existing.isNotEmpty) {
      newSet.remove(existing);
    } else {
      newSet.add(value);
    }
    ref.read(selectedMuscleGroupsProvider.notifier).state = newSet;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 28,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final name = options[index];
          final isSelected = selected.any(
            (v) => v.toLowerCase() == name.toLowerCase(),
          );
          return ZealovaChip(
            label: name,
            leadingAsset: _assetFor(name),
            selected: isSelected,
            onTap: () => _toggle(ref, name),
          );
        },
      ),
    );
  }
}

/// Compact 32pt icon button used in the Exercises header action row
/// (Create exercise / AI import).
class _MiniIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _MiniIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tc.elevated,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Icon(icon, size: 18, color: tc.textPrimary),
        ),
      ),
    );
  }
}

/// AI-import entry point in the Exercises header. Styled as a "smart" action —
/// an accent gradient fill with an accent-tinted glow — so it reads as distinct
/// from the plain neutral `_MiniIconButton` ("+") sitting beside it.
class _AiMiniButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback onTap;
  const _AiMiniButton({required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final accent = tc.accent;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.85),
                accent.withValues(alpha: 0.55),
              ],
            ),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: accent.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            size: 17,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
