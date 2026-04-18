/// Recipes Tab — the hub for recipes, planning, scheduling, sharing.
///
/// Layout (top to bottom):
///   1. Sticky search bar (recents when empty; live results when typing).
///      The search bar is library-only — Discover is the gateway to curated /
///      community content.
///   2. "Coming up today" carousel (scheduled meal reminders + leftovers).
///   3. Quick-action tiles: Fridge · Import · Plan day · Lists · Favorites ·
///      Discover (6 tiles, each stretched to an equal fraction of the row).
///   4. Meal-type filter row (single-select: All / Breakfast / Lunch / …).
///   5. Filter modifier row + "Sort ▾" pill (multi-select + opens sheet).
///   6. My Recipes grid (respects search, category, modifier chips, and
///      whatever advanced filters / sort the user picked in the sheet).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/recipe.dart';
import '../../../data/providers/recipe_providers.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../recipes/recipe_create_screen.dart';
import '../recipes/recipe_detail_screen.dart';
import '../recipes/recipe_from_fridge_screen.dart';
import '../recipes/recipe_import_screen.dart';
import '../recipes/discover_screen.dart';
import '../recipes/favorites_screen.dart';
import '../recipes/widgets/recipe_card.dart';
import '../recipes/widgets/recipe_filter_sort_sheet.dart';
import '../grocery/grocery_lists_index_screen.dart';
import '../meal_planner/meal_planner_screen.dart';
import '../../../widgets/main_shell.dart' show floatingNavBarVisibleProvider;
import 'recipe_search_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Inline-chip source groupings
// ─────────────────────────────────────────────────────────────────────────────
//
// The in-place "Imported" / "Improvized" filter chips map to multiple backend
// `source_type` values. Keep these lists in one place so the sheet and the
// inline chips produce identical query params for the same semantic filter.
const List<String> _kImportedSources = [
  'imported',
  'imported_url',
  'imported_text',
  'imported_handwritten',
];
const List<String> _kImprovizedSources = ['improvized'];

class RecipesTab extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;
  const RecipesTab({super.key, required this.userId, required this.isDark});

  @override
  ConsumerState<RecipesTab> createState() => _RecipesTabState();
}

class _RecipesTabState extends ConsumerState<RecipesTab>
    with AutomaticKeepAliveClientMixin {
  String _searchQuery = '';

  /// Single source of truth for meal type + source + toggles + sort. Owned
  /// entirely by the filter sheet — the inline toolbar just reads from it and
  /// can remove individual facets (e.g. dismiss a chip).
  RecipeFilterSortState _filterSort = const RecipeFilterSortState();

  @override
  bool get wantKeepAlive => true;

  Future<void> _openFilterSortSheet() async {
    final accent = AccentColorScope.of(context).getColor(widget.isDark);
    final next = await showRecipeFilterSortSheet(
      context: context,
      ref: ref,
      current: _filterSort,
      isDark: widget.isDark,
      accent: accent,
    );
    if (next != null && mounted) {
      setState(() => _filterSort = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final accent = AccentColorScope.of(context).getColor(widget.isDark);
    final upcomingAsync = ref.watch(upcomingSchedulesProvider(widget.userId));
    final leftoversAsync = ref.watch(activeCookEventsProvider(widget.userId));

    return Stack(
      children: [
        RefreshIndicator(
          color: accent,
          onRefresh: () async {
            ref.invalidate(upcomingSchedulesProvider(widget.userId));
            ref.invalidate(activeCookEventsProvider(widget.userId));
          },
          child: CustomScrollView(
            slivers: [
              // Quick action chips + carousel + combined search/filter/sort
              // toolbar + grid. No sticky header — search is inline with
              // filter + sort so every control that affects results lives in
              // a single bar.
              SliverPadding(
                // Extra bottom padding to keep FAB from covering last recipe
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
                sliver: SliverList.list(
                  children: [
                    _ComingUpCarousel(
                      upcoming: upcomingAsync,
                      leftovers: leftoversAsync,
                      isDark: widget.isDark,
                      accent: accent,
                      userId: widget.userId,
                    ),
                    const SizedBox(height: 16),
                    _QuickActions(
                      isDark: widget.isDark,
                      accent: accent,
                      userId: widget.userId,
                    ),
                    const SizedBox(height: 20),
                    _RecipeSearchFilterSortBar(
                      userId: widget.userId,
                      isDark: widget.isDark,
                      accent: accent,
                      state: _filterSort,
                      onOpenFilters: _openFilterSortSheet,
                      onStateChanged: (next) =>
                          setState(() => _filterSort = next),
                      onQueryChanged: (q) =>
                          setState(() => _searchQuery = q),
                    ),
                    const SizedBox(height: 16),
                    _MyRecipesGrid(
                      userId: widget.userId,
                      isDark: widget.isDark,
                      accent: accent,
                      category: _filterSort.mealType,
                      searchQuery: _searchQuery,
                      hasLeftovers: _filterSort.hasLeftoversOnly,
                      favoritesOnly: _filterSort.favoritesOnly,
                      sourceTypeIn: _filterSort.sourceTypeIn,
                      sortBy: _filterSort.sortBy,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Floating Build FAB — sits above the root floating nav bar.
        // Styled as a pill with a gradient + sparkle icon to signal AI creation
        // rather than a random crossed-spoon glyph.
        Positioned(
          right: 20,
          bottom: 96,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => RecipeCreateScreen(
                        userId: widget.userId, isDark: widget.isDark)));
                if (!mounted) return;
                ref.read(floatingNavBarVisibleProvider.notifier).state = true;
              },
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent, accent.withValues(alpha: 0.75)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Build',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// Coming Up carousel — upcoming reminders + leftovers
// ============================================================

class _ComingUpCarousel extends StatelessWidget {
  final AsyncValue upcoming;
  final AsyncValue leftovers;
  final bool isDark;
  final Color accent;
  final String userId;
  const _ComingUpCarousel({
    required this.upcoming,
    required this.leftovers,
    required this.isDark,
    required this.accent,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final hasContent = upcoming.maybeWhen(
          data: (d) => (d as List).isNotEmpty,
          orElse: () => false,
        ) ||
        leftovers.maybeWhen(
          data: (d) => (d as List).isNotEmpty,
          orElse: () => false,
        );
    if (!hasContent) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Coming up today',
            style:
                TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: muted),
          ),
        ),
        SizedBox(
          height: 88,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...upcoming.maybeWhen(
                data: (d) => (d as List).map<Widget>(
                  (e) => _UpcomingCard(item: e, isDark: isDark, accent: accent),
                ),
                orElse: () => const Iterable<Widget>.empty(),
              ),
              ...leftovers.maybeWhen(
                data: (d) => (d as List).map<Widget>(
                  (e) => _LeftoverCard(item: e, isDark: isDark, accent: accent),
                ),
                orElse: () => const Iterable<Widget>.empty(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  final dynamic item;
  final bool isDark;
  final Color accent;
  const _UpcomingCard(
      {required this.item, required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context) {
    final fireAt = item.fireAt as DateTime;
    final timeLabel =
        '${fireAt.hour.toString().padLeft(2, '0')}:${fireAt.minute.toString().padLeft(2, '0')}';
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 56,
            decoration: BoxDecoration(
                color: accent, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$timeLabel · ${item.mealType.value}',
                  style: TextStyle(
                      fontSize: 11,
                      color: accent,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  item.recipeName ?? 'Scheduled meal',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: text),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.servings.toStringAsFixed(item.servings == item.servings.toInt() ? 0 : 1)} serving',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeftoverCard extends StatelessWidget {
  final dynamic item;
  final bool isDark;
  final Color accent;
  const _LeftoverCard(
      {required this.item, required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context) {
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final warningColor = item.isExpired
        ? (isDark ? AppColors.error : AppColorsLight.error)
        : item.isExpiringSoon
            ? AppColors.yellow
            : accent;
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: warningColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.kitchen_rounded, size: 30, color: warningColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.isExpired ? 'EXPIRED' : 'LEFTOVERS',
                  style: TextStyle(
                      fontSize: 10,
                      color: warningColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  item.recipeName ?? 'Cooked dish',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: text),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.portionsRemaining.toStringAsFixed(item.portionsRemaining == item.portionsRemaining.toInt() ? 0 : 1)} of ${item.portionsMade.toStringAsFixed(0)} left',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Quick Action Tiles — 6 stretched-to-width tiles
// ============================================================
//
// Fridge · Import · Plan day · Lists · Favorites · Discover
//
// Horizontally scrollable: tile widths are computed so that exactly 5 tiles
// fit in the viewport and the 6th peeks from the right edge as a scroll
// affordance. Avoids the old ellipsized labels ("Plan d...", "Favori...").

class _QuickActions extends ConsumerWidget {
  final bool isDark;
  final Color accent;
  final String userId;
  const _QuickActions({
    required this.isDark,
    required this.accent,
    required this.userId,
  });

  /// Push a sub-screen and guarantee the floating nav bar is restored once
  /// the user returns — works for back-button, swipe-back, AND unexpected pops.
  Future<void> _pushAndRestoreNavBar(
      BuildContext context, WidgetRef ref, Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (!context.mounted) return;
    ref.read(floatingNavBarVisibleProvider.notifier).state = true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Build is now a FloatingActionButton at the root of RecipesTab.
    final actions = <_QuickAction>[
      _QuickAction(
        icon: Icons.kitchen_outlined,
        label: 'Fridge',
        onTap: () => _pushAndRestoreNavBar(context, ref,
            RecipeFromFridgeScreen(userId: userId, isDark: isDark)),
      ),
      _QuickAction(
        icon: Icons.download_rounded,
        label: 'Import',
        onTap: () => _pushAndRestoreNavBar(
            context, ref, RecipeImportScreen(userId: userId, isDark: isDark)),
      ),
      _QuickAction(
        icon: Icons.calendar_today_rounded,
        label: 'Plan day',
        onTap: () => _pushAndRestoreNavBar(
            context,
            ref,
            MealPlannerScreen(
                userId: userId, isDark: isDark, date: DateTime.now())),
      ),
      _QuickAction(
        icon: Icons.shopping_cart_outlined,
        label: 'Lists',
        onTap: () => _pushAndRestoreNavBar(context, ref,
            GroceryListsIndexScreen(userId: userId, isDark: isDark)),
      ),
      _QuickAction(
        icon: Icons.favorite_outline,
        label: 'Favorites',
        onTap: () => _pushAndRestoreNavBar(
            context, ref, FavoritesScreen(userId: userId, isDark: isDark)),
      ),
      _QuickAction(
        icon: Icons.public_outlined,
        label: 'Discover',
        onTap: () => _pushAndRestoreNavBar(
            context, ref, DiscoverScreen(userId: userId, isDark: isDark)),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Show 5 tiles in the viewport with the 6th peeking from the right
        // edge to telegraph that the row is scrollable.
        const gap = 8.0;
        const tilesVisible = 5;
        const peekWidth = 28.0;
        final tileWidth =
            (constraints.maxWidth - gap * tilesVisible - peekWidth) /
                tilesVisible;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          // Negative end padding would clip the peek; the parent already
          // provides the 16-dp outer gutter.
          child: Row(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                SizedBox(
                  width: tileWidth,
                  child: _QuickActionChip(
                      action: actions[i], isDark: isDark, accent: accent),
                ),
                if (i != actions.length - 1) const SizedBox(width: gap),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _QuickAction({required this.icon, required this.label, required this.onTap});
}

class _QuickActionChip extends StatelessWidget {
  final _QuickAction action;
  final bool isDark;
  final Color accent;
  const _QuickActionChip(
      {required this.action, required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context) {
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, size: 20, color: accent),
            const SizedBox(height: 6),
            Text(
              action.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: text),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Combined search + filter + sort bar.
// Row 1: [Filters] [Sort ▼] [🔍 Search]
// Row 2: Active-filter dismissible pills (only when any filter is applied)
// ============================================================

/// Sort options mirror the ones defined in the filter sheet. Kept in sync
/// manually (there are only 4 and they rarely change) so the inline sort
/// dropdown doesn't need to reach into the sheet's private constants.
const List<(String value, String label, IconData icon)> _kSortOptions = [
  ('created_desc', 'Recent', Icons.schedule_rounded),
  ('name_asc', 'Name A→Z', Icons.sort_by_alpha_rounded),
  ('most_logged', 'Most logged', Icons.local_fire_department_rounded),
  ('last_cooked', 'Last cooked', Icons.restaurant_rounded),
];

String _sortLabelFor(String value) => _kSortOptions
    .firstWhere((o) => o.$1 == value, orElse: () => _kSortOptions.first)
    .$2;

/// The combined toolbar. Collapsed state: `[Filters] [Sort ▾] … [🔍]` with
/// search as a compact icon on the right. Tapping the icon animates the bar
/// into its expanded state — a single full-width search field (with a back-
/// chevron to return). This avoids the cramped-search problem when all three
/// controls compete for width on narrow phones.
///
/// Active filter facets render as dismissible pills on a second row — that
/// row is omitted when no filter is active so the empty-library view stays
/// uncluttered. The pill row stays put in BOTH toolbar states so users can
/// still see what's filtered while typing a search.
class _RecipeSearchFilterSortBar extends StatefulWidget {
  final String userId;
  final bool isDark;
  final Color accent;
  final RecipeFilterSortState state;
  final VoidCallback onOpenFilters;
  final ValueChanged<RecipeFilterSortState> onStateChanged;
  final ValueChanged<String> onQueryChanged;

  const _RecipeSearchFilterSortBar({
    required this.userId,
    required this.isDark,
    required this.accent,
    required this.state,
    required this.onOpenFilters,
    required this.onStateChanged,
    required this.onQueryChanged,
  });

  @override
  State<_RecipeSearchFilterSortBar> createState() =>
      _RecipeSearchFilterSortBarState();
}

class _RecipeSearchFilterSortBarState
    extends State<_RecipeSearchFilterSortBar> {
  /// When true the search bar occupies the full toolbar row. When false the
  /// bar shows [Filters]+[Sort]+search icon. The active query itself is kept
  /// in the parent via `onQueryChanged` so collapsing the UI doesn't wipe it.
  bool _searchExpanded = false;

  /// Preserved across expand/collapse cycles so the user can reopen search
  /// and see their previous query still in the input.
  String _preservedQuery = '';

  void _openSearch() => setState(() => _searchExpanded = true);

  void _closeSearch() {
    setState(() => _searchExpanded = false);
    // Don't clear the query here — user may just want to check filters then
    // reopen search. To explicitly clear, they use the × inside the input.
  }

  @override
  Widget build(BuildContext context) {
    final muted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final text =
        widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final activePills = _buildActivePills();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1 — switches between collapsed and expanded search layouts.
        SizedBox(
          height: 44,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              // Gentle horizontal slide that reads as a reveal.
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: _searchExpanded
                ? _buildExpandedSearch(muted, text)
                : _buildCollapsedBar(muted, text),
          ),
        ),

        // Row 2 — only shown when the user has applied any filter.
        if (activePills.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 32,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: activePills),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCollapsedBar(Color muted, Color text) {
    final hasQuery = _preservedQuery.trim().isNotEmpty;
    return Row(
      key: const ValueKey('collapsed'),
      children: [
        _FiltersButton(
          accent: widget.accent,
          muted: muted,
          text: text,
          count: widget.state.activeFilterCount,
          onTap: widget.onOpenFilters,
        ),
        const SizedBox(width: 8),
        _SortDropdown(
          accent: widget.accent,
          muted: muted,
          text: text,
          currentSort: widget.state.sortBy,
          onChanged: (v) =>
              widget.onStateChanged(widget.state.copyWith(sortBy: v)),
        ),
        const Spacer(),
        _SearchIconButton(
          accent: widget.accent,
          muted: muted,
          text: text,
          // Show accent fill + dot badge if a query is currently applied so
          // the user can tell search is "on" even when the field is hidden.
          active: hasQuery,
          onTap: _openSearch,
        ),
      ],
    );
  }

  Widget _buildExpandedSearch(Color muted, Color text) {
    return Row(
      key: const ValueKey('expanded'),
      children: [
        // Back chevron collapses the search UI. We deliberately don't clear
        // the query — see _closeSearch.
        InkWell(
          onTap: _closeSearch,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(Icons.arrow_back_rounded, size: 22, color: text),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: RecipeSearchBar(
            userId: widget.userId,
            isDark: widget.isDark,
            autoFocus: true,
            initialQuery: _preservedQuery,
            onQueryChanged: (q) {
              _preservedQuery = q;
              widget.onQueryChanged(q);
            },
          ),
        ),
      ],
    );
  }

  /// Produce one dismissible pill per active filter facet. Source chips are
  /// grouped (e.g. all imported_* types collapse into a single "Imported" pill)
  /// so the toolbar stays readable even with multi-value backend fields.
  List<Widget> _buildActivePills() {
    final pills = <Widget>[];
    final state = widget.state;
    final accent = widget.accent;

    if (state.mealType != null) {
      final match = kRecipeMealTypes.firstWhere(
        (m) => m.$1 == state.mealType,
        orElse: () => (state.mealType, state.mealType!),
      );
      pills.add(_ActivePill(
        label: match.$2,
        accent: accent,
        onRemove: () =>
            widget.onStateChanged(state.copyWith(mealType: null)),
      ));
    }
    if (state.favoritesOnly) {
      pills.add(_ActivePill(
        label: '⭐ Favorites',
        accent: accent,
        onRemove: () =>
            widget.onStateChanged(state.copyWith(favoritesOnly: false)),
      ));
    }
    if (state.hasLeftoversOnly) {
      pills.add(_ActivePill(
        label: '🍱 Has leftovers',
        accent: accent,
        onRemove: () =>
            widget.onStateChanged(state.copyWith(hasLeftoversOnly: false)),
      ));
    }

    final sources = state.sourceTypeIn;
    void addSourcePill(String label, List<String> members) {
      if (members.any(sources.contains)) {
        final next = sources.where((s) => !members.contains(s)).toList();
        pills.add(_ActivePill(
          label: label,
          accent: accent,
          onRemove: () =>
              widget.onStateChanged(state.copyWith(sourceTypeIn: next)),
        ));
      }
    }

    addSourcePill('Mine', const ['manual']);
    addSourcePill('📥 Imported', _kImportedSources);
    addSourcePill('✨ Improvized', _kImprovizedSources);
    addSourcePill('Cloned', const ['from_share']);
    addSourcePill('AI-generated', const ['ai_generated']);

    return [
      for (final p in pills)
        Padding(padding: const EdgeInsets.only(right: 8), child: p),
    ];
  }
}

/// Compact search-icon button used in the collapsed toolbar state. Fills with
/// accent + shows a dot badge when a search query is currently active so the
/// user can tell search is applied even when the input itself is hidden.
class _SearchIconButton extends StatelessWidget {
  final Color accent;
  final Color muted;
  final Color text;
  final bool active;
  final VoidCallback onTap;

  const _SearchIconButton({
    required this.accent,
    required this.muted,
    required this.text,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: active ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: active ? accent : muted.withValues(alpha: 0.35),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 20,
              color: active ? Colors.white : text,
            ),
            if (active)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Inline sort dropdown — shows the current sort label + chevron. Tapping opens
/// a PopupMenuButton with the same 4 options that used to live inside the
/// filter sheet's "Sort by" section.
class _SortDropdown extends StatelessWidget {
  final Color accent;
  final Color muted;
  final Color text;
  final String currentSort;
  final ValueChanged<String> onChanged;

  const _SortDropdown({
    required this.accent,
    required this.muted,
    required this.text,
    required this.currentSort,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Sort recipes',
      onSelected: onChanged,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      itemBuilder: (_) => [
        for (final opt in _kSortOptions)
          PopupMenuItem<String>(
            value: opt.$1,
            child: Row(
              children: [
                Icon(opt.$3,
                    size: 18,
                    color: currentSort == opt.$1 ? accent : muted),
                const SizedBox(width: 10),
                Text(
                  opt.$2,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: currentSort == opt.$1
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: currentSort == opt.$1 ? accent : text,
                  ),
                ),
                if (currentSort == opt.$1) ...[
                  const Spacer(),
                  Icon(Icons.check_rounded, size: 16, color: accent),
                ],
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: muted.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_vert_rounded, size: 16, color: text),
            const SizedBox(width: 4),
            Text(
              _sortLabelFor(currentSort),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: text,
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded, size: 18, color: text),
          ],
        ),
      ),
    );
  }
}

/// "Filters" button — fills with accent + shows a count badge when any filter
/// is active. Opens the full filter+sort bottom sheet on tap.
class _FiltersButton extends StatelessWidget {
  final Color accent;
  final Color muted;
  final Color text;
  final int count;
  final VoidCallback onTap;

  const _FiltersButton({
    required this.accent,
    required this.muted,
    required this.text,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? accent : muted.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 16,
              color: active ? Colors.white : text,
            ),
            const SizedBox(width: 6),
            Text(
              'Filters',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : text,
              ),
            ),
            if (active) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A dismissible "active filter" pill. Filled with a low-alpha accent tint so
/// it reads as a current selection (vs. the hollow inactive chips elsewhere).
class _ActivePill extends StatelessWidget {
  final String label;
  final Color accent;
  final VoidCallback onRemove;

  const _ActivePill({
    required this.label,
    required this.accent,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onRemove,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.only(left: 12, right: 6, top: 7, bottom: 7),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.close_rounded, size: 14, color: accent),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// My Recipes Grid
// ============================================================

class _MyRecipesGrid extends ConsumerWidget {
  final String userId;
  final bool isDark;
  final Color accent;
  final String? category;
  final String searchQuery;
  final bool hasLeftovers;
  final bool favoritesOnly;
  final List<String> sourceTypeIn;
  final String sortBy;
  const _MyRecipesGrid({
    required this.userId,
    required this.isDark,
    required this.accent,
    required this.category,
    required this.searchQuery,
    required this.hasLeftovers,
    required this.favoritesOnly,
    required this.sourceTypeIn,
    required this.sortBy,
  });

  /// True when any non-default filter is active — used to decide whether the
  /// recipeSearchProvider should be used even when there's no search text.
  /// (The search provider is the one that understands the richer filter set.)
  bool get _hasAdvancedFilters =>
      hasLeftovers ||
      favoritesOnly ||
      sourceTypeIn.isNotEmpty ||
      sortBy != 'created_desc';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasQuery = searchQuery.trim().length >= 2;

    // Search provider is used when the user is typing OR any advanced filter
    // / non-default sort is active — the search endpoint is the one that
    // knows how to apply sourceTypeIn / isFavorite / sortBy.
    if (hasQuery || _hasAdvancedFilters) {
      final searchAsync = ref.watch(recipeSearchProvider(RecipeSearchArgs(
        userId: userId,
        query: hasQuery ? searchQuery : '',
        scope: 'mine',
        category: category,
        hasLeftovers: hasLeftovers,
        sourceTypeIn: sourceTypeIn,
        isFavorite: favoritesOnly ? true : null,
        sortBy: sortBy,
      )));
      return searchAsync.when(
        loading: () => const Center(
            child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator())),
        error: (e, _) => _ErrorView(message: e.toString(), isDark: isDark),
        data: (resp) => _renderGrid(
          context,
          resp.items,
          isEmptyHint:
              hasQuery ? 'No matches in your recipes' : 'No recipes match these filters',
          widgetRef: ref,
        ),
      );
    }

    // Default fast path — simple category filter, uses the cheap list endpoint.
    final repo = ref.watch(nutritionRepositoryProvider);
    return FutureBuilder<RecipesResponse>(
      future: repo.getRecipes(userId: userId, category: category, limit: 100),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return _ErrorView(message: snap.error.toString(), isDark: isDark);
        }
        final items = snap.data?.items ?? const <RecipeSummary>[];
        return _renderGrid(context, items, widgetRef: ref);
      },
    );
  }

  Widget _renderGrid(BuildContext context, List<RecipeSummary> items,
      {String? isEmptyHint, WidgetRef? widgetRef}) {
    if (items.isEmpty) {
      return _EmptyState(isDark: isDark, accent: accent, hint: isEmptyHint);
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (_, i) {
        final s = items[i];
        return RecipeCard(
          summary: s,
          isDark: isDark,
          accent: accent,
          // Surface the source pill whenever a recipe is anything other than
          // plain "manual" — helps the user distinguish imported / cloned /
          // improvized items at a glance inside their own library.
          showSourceBadge: _shouldShowSourceBadge(s),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => RecipeDetailScreen(
                  recipeId: s.id, userId: userId, isDark: isDark),
            ));
          },
          onLongPress: widgetRef != null ? () => _showRecipeContextMenu(context, widgetRef, s) : null,
        );
      },
    );
  }

  bool _shouldShowSourceBadge(RecipeSummary s) {
    if (s.isCurated) return true;
    final t = (s.sourceType ?? '').toLowerCase();
    if (t.isEmpty || t == 'manual') return false;
    return true;
  }

  void _showRecipeContextMenu(BuildContext context, WidgetRef ref, RecipeSummary s) {
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: muted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.open_in_new, size: 20),
              title: const Text('Open'),
              onTap: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => RecipeDetailScreen(
                    recipeId: s.id, userId: userId, isDark: isDark),
                ));
              },
            ),
            if (!s.isCurated)
              ListTile(
                leading: Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                title: Text('Delete', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _confirmDeleteRecipe(context, ref, s);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteRecipe(BuildContext context, WidgetRef ref, RecipeSummary s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete recipe?'),
        content: Text('Are you sure you want to delete "${s.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final repo = ref.read(nutritionRepositoryProvider);
      await repo.deleteRecipe(userId: userId, recipeId: s.id);
      if (!context.mounted) return;
      // Invalidate the search/list providers to refresh the grid
      ref.invalidate(recipeSearchProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe deleted'), duration: Duration(seconds: 2)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final Color accent;
  final String? hint;
  const _EmptyState({required this.isDark, required this.accent, this.hint});

  @override
  Widget build(BuildContext context) {
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.menu_book_rounded,
              size: 64, color: accent.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            hint ?? 'No recipes yet',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: text),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap Build to create your first one, or try a fridge / import path above.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: muted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final bool isDark;
  const _ErrorView({required this.message, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'Couldn\'t load recipes: $message',
        style: TextStyle(
            color: isDark ? AppColors.error : AppColorsLight.error),
      ),
    );
  }
}
