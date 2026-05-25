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

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/widgets/skeleton/skeleton.dart';
import '../../../data/models/recipe.dart';
import '../../../data/services/data_cache_service.dart';
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
import '../../../widgets/liquid_glass_action_bar.dart';
import '../../../widgets/glass_sheet.dart';
import 'recipe_search_bar.dart';

import '../../../l10n/generated/app_localizations.dart';
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
            // Now that the list provider is keep-alive, pull-to-refresh is
            // the explicit "give me fresh data" gesture — invalidate it too.
            ref.invalidate(myRecipesListProvider);
            ref.invalidate(recipeSearchProvider);
          },
          child: CustomScrollView(
            slivers: [
              // Quick action chips + carousel + combined search/filter/sort
              // toolbar + grid. No sticky header — search is inline with
              // filter + sort so every control that affects results lives in
              // a single bar.
              // Header section — carousel + quick actions + search/filter
              // toolbar. Stays a SliverList: these are a fixed handful of
              // widgets, not a long lazy list.
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                  ],
                ),
              ),
              // My Recipes grid — its own sliver so the recipe tiles are built
              // lazily by a SliverGrid (only on-screen tiles are constructed)
              // instead of a shrinkWrap GridView that builds every tile up
              // front. Clearance for the floating tab bar + nav + FAB is
              // applied as bottom padding here.
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  MediaQuery.of(context).viewPadding.bottom +
                      76 +
                      kLiquidGlassActionBarHeight +
                      16,
                ),
                sliver: _MyRecipesGrid(
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
              ),
            ],
          ),
        ),

        // Floating Build FAB — sits above BOTH the root floating nav bar
        // AND the Nutrition glass tab bar (Daily/Recipes/Patterns/Fuel),
        // which adds ~64px of vertical space above the nav. Without this
        // extra inset, the FAB overlaps the right end of the tab bar.
        Positioned(
          right: 20,
          bottom: 160,
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
                    colors: [accent, accent.withValues(alpha: 0.85)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  // Neutral shadow — the previous accent-tinted shadow
                  // (alpha 0.35 blur 16 offset 0,6) painted a soft red
                  // halo around the FAB that read as a pink rectangle on
                  // light backgrounds and tinted the glass tab bar
                  // through the BackdropFilter. Black at low alpha gives
                  // depth without the red bleed.
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context).recipesBuild,
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
            AppLocalizations.of(context).recipesComingUpToday,
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
                  item.recipeName ?? AppLocalizations.of(context).recipesScheduledMeal,
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
                  item.isExpired ? AppLocalizations.of(context).recipesExpired : AppLocalizations.of(context).recipesLeftovers,
                  style: TextStyle(
                      fontSize: 10,
                      color: warningColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  item.recipeName ?? AppLocalizations.of(context).recipesCookedDish,
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

  /// Bottom-sheet picker that asks Camera vs Gallery (multi-pick) before
  /// pushing the fridge scan screen. Mirrors the Scan Menu pattern so the
  /// two paths feel consistent. Cancelling the sheet (tap outside) is a
  /// no-op — the user stays on Recipes. Up to 5 photos per scan.
  Future<void> _openFridgePicker(
      BuildContext context, WidgetRef ref, String userId, bool isDark) async {
    final accent = ref.read(accentColorProvider).getColor(isDark);
    final source = await showGlassSheet<ImageSource>(
      context: context,
      builder: (ctx) {
        final text = isDark
            ? AppColors.textPrimary
            : AppColorsLight.textPrimary;
        final muted =
            isDark ? AppColors.textMuted : AppColorsLight.textMuted;
        return GlassSheet(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).recipesScanYourFridge,
                    style: TextStyle(
                        color: text,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(AppLocalizations.of(context).recipesUpTo5Photos,
                    style: TextStyle(color: muted, fontSize: 13)),
                const SizedBox(height: 16),
                _SheetAction(
                  icon: Icons.camera_alt_rounded,
                  label: AppLocalizations.of(context).recipesTakePhoto,
                  accent: accent,
                  onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
                ),
                const SizedBox(height: 10),
                _SheetAction(
                  icon: Icons.photo_library_outlined,
                  label: AppLocalizations.of(context).recipesChooseFromGallery,
                  subtitle: AppLocalizations.of(context).recipesMultiSelectSupported,
                  accent: accent,
                  onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (source == null || !context.mounted) return;

    // Acquire bytes for whichever source the user picked.
    final pickedPaths = <String>[];
    final pickedB64 = <String>[];
    try {
      if (source == ImageSource.gallery) {
        final files = await ImagePicker()
            .pickMultiImage(imageQuality: 75);
        if (files.isEmpty) return;
        final accepted = files.take(5).toList();
        for (final f in accepted) {
          final bytes = await File(f.path).readAsBytes();
          pickedPaths.add(f.path);
          pickedB64.add(base64Encode(bytes));
        }
      } else {
        final f = await ImagePicker()
            .pickImage(source: ImageSource.camera, imageQuality: 75);
        if (f == null) return;
        final bytes = await File(f.path).readAsBytes();
        pickedPaths.add(f.path);
        pickedB64.add(base64Encode(bytes));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load photo: $e')),
      );
      return;
    }
    if (!context.mounted || pickedB64.isEmpty) return;
    await _pushAndRestoreNavBar(
      context,
      ref,
      RecipeFromFridgeScreen(
        userId: userId,
        isDark: isDark,
        initialImagesB64: pickedB64,
        initialImagePaths: pickedPaths,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Build is now a FloatingActionButton at the root of RecipesTab.
    final actions = <_QuickAction>[
      _QuickAction(
        icon: Icons.kitchen_outlined,
        label: AppLocalizations.of(context).recipesFridge,
        // Open the photo picker first (matches Scan Menu) so the user
        // lands on the scan screen with their photos already attached
        // and detection in flight, instead of an empty input.
        onTap: () => _openFridgePicker(context, ref, userId, isDark),
      ),
      _QuickAction(
        icon: Icons.download_rounded,
        label: AppLocalizations.of(context).recipesImport,
        onTap: () => _pushAndRestoreNavBar(
            context, ref, RecipeImportScreen(userId: userId, isDark: isDark)),
      ),
      _QuickAction(
        icon: Icons.calendar_today_rounded,
        label: AppLocalizations.of(context).recipesPlanDay,
        onTap: () => _pushAndRestoreNavBar(
            context,
            ref,
            MealPlannerScreen(
                userId: userId, isDark: isDark, date: DateTime.now())),
      ),
      _QuickAction(
        icon: Icons.shopping_cart_outlined,
        label: AppLocalizations.of(context).recipesLists,
        onTap: () => _pushAndRestoreNavBar(context, ref,
            GroceryListsIndexScreen(userId: userId, isDark: isDark)),
      ),
      _QuickAction(
        icon: Icons.favorite_outline,
        label: AppLocalizations.of(context).workoutsFavorites,
        onTap: () => _pushAndRestoreNavBar(
            context, ref, FavoritesScreen(userId: userId, isDark: isDark)),
      ),
      _QuickAction(
        icon: Icons.public_outlined,
        label: AppLocalizations.of(context).navDiscover,
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
        label: AppLocalizations.of(context).recipesFavorites2,
        accent: accent,
        onRemove: () =>
            widget.onStateChanged(state.copyWith(favoritesOnly: false)),
      ));
    }
    if (state.hasLeftoversOnly) {
      pills.add(_ActivePill(
        label: AppLocalizations.of(context).recipesHasLeftovers,
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
      tooltip: AppLocalizations.of(context).recipesSortRecipes,
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
              AppLocalizations.of(context).recipesFilters,
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

/// Disk-cache key for the default-path My Recipes list. The category facet is
/// folded in so each meal-type filter bucket is isolated. 24-hour TTL — the
/// library changes only on explicit user edits, which invalidate the slot.
const String _kMyRecipesCacheKey = 'cache_my_recipes_list';

/// Build the faceted disk-cache key for [myRecipesListProvider].
String _myRecipesCacheKey(String? category) =>
    category == null ? _kMyRecipesCacheKey : '${_kMyRecipesCacheKey}_$category';

/// The fixed-column grid layout for both the real recipe tiles and the
/// loading skeleton — kept in one place so the skeleton → content swap is
/// reflow-free.
const SliverGridDelegateWithFixedCrossAxisCount _kRecipeGridDelegate =
    SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 2,
  mainAxisSpacing: 12,
  crossAxisSpacing: 12,
  childAspectRatio: 0.78,
);

/// Renders the My Recipes grid as a SLIVER (the parent CustomScrollView hosts
/// it directly), so tiles are built lazily by a [SliverGrid] — only on-screen
/// cards are constructed, unlike the old `shrinkWrap` GridView that built every
/// tile up front.
///
/// Instant-load: on the default fast path (no search / advanced filter) the
/// last-known recipe list is disk-cached via [DataCacheService]. A cold start
/// reads that slot and renders the grid instantly; a true first-ever open with
/// nothing cached shows a layout-matched shimmer grid instead of a spinner.
class _MyRecipesGrid extends ConsumerStatefulWidget {
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

  @override
  ConsumerState<_MyRecipesGrid> createState() => _MyRecipesGridState();
}

class _MyRecipesGridState extends ConsumerState<_MyRecipesGrid> {
  /// Disk-cached recipe list for the current category bucket (default path
  /// only). Rendered instantly on cold start while the provider re-fetches.
  List<RecipeSummary>? _cached;
  bool _cacheChecked = false;
  String? _cachedKey;

  String get _cacheKey => _myRecipesCacheKey(widget.category);

  /// True when any non-default filter is active — used to decide whether the
  /// recipeSearchProvider should be used even when there's no search text.
  /// (The search provider is the one that understands the richer filter set.)
  bool get _hasAdvancedFilters =>
      widget.hasLeftovers ||
      widget.favoritesOnly ||
      widget.sourceTypeIn.isNotEmpty ||
      widget.sortBy != 'created_desc';

  @override
  void initState() {
    super.initState();
    _loadCache();
  }

  @override
  void didUpdateWidget(covariant _MyRecipesGrid old) {
    super.didUpdateWidget(old);
    // Category changed → re-read the new bucket's cached list.
    if (old.category != widget.category) {
      _cached = null;
      _cacheChecked = false;
      _loadCache();
    }
  }

  Future<void> _loadCache() async {
    final key = _cacheKey;
    List<RecipeSummary>? items;
    try {
      final raw = await DataCacheService.instance
          .getCachedList(key, userId: widget.userId);
      if (raw != null) {
        items = raw.map(RecipeSummary.fromJson).toList();
      }
    } catch (e) {
      debugPrint('💾 [Recipes] my-recipes cache read failed: $e');
    }
    if (!mounted) return;
    setState(() {
      if (key == _cacheKey) {
        _cached = items;
        _cachedKey = key;
      }
      _cacheChecked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = widget.searchQuery.trim().length >= 2;

    // Search provider is used when the user is typing OR any advanced filter
    // / non-default sort is active — the search endpoint is the one that
    // knows how to apply sourceTypeIn / isFavorite / sortBy.
    if (hasQuery || _hasAdvancedFilters) {
      final searchAsync = ref.watch(recipeSearchProvider(RecipeSearchArgs(
        userId: widget.userId,
        query: hasQuery ? widget.searchQuery : '',
        scope: 'mine',
        category: widget.category,
        hasLeftovers: widget.hasLeftovers,
        sourceTypeIn: widget.sourceTypeIn,
        isFavorite: widget.favoritesOnly ? true : null,
        sortBy: widget.sortBy,
      )));
      // Stale-while-refresh: render cached items the moment we have them,
      // even if Riverpod is still re-fetching after an invalidation. The
      // search path is not disk-cached (the filter space is unbounded) — but
      // Riverpod's keepAlive still avoids a spinner on tab re-entry.
      final cached = searchAsync.valueOrNull;
      if (cached != null) {
        return _renderGrid(
          context,
          cached.items,
          isEmptyHint: hasQuery
              ? 'No matches in your recipes'
              : 'No recipes match these filters',
        );
      }
      if (searchAsync.hasError) {
        return _ErrorSliver(
            message: searchAsync.error.toString(), isDark: widget.isDark);
      }
      // No cached search result yet — layout-matched shimmer grid.
      return const _RecipeGridSkeleton();
    }

    // Default fast path — cheap /recipes endpoint, cached via Riverpod so
    // tab re-entry / filter-chip toggles don't re-fetch. Disk-cache the
    // payload too so a cold app start renders the grid instantly.
    final listAsync = ref.watch(myRecipesListProvider(
      MyRecipesListArgs(userId: widget.userId, category: widget.category),
    ));
    final fresh = listAsync.valueOrNull;
    if (fresh != null) {
      // Write-through: persist the list so the next cold start is instant.
      _cached = fresh.items;
      _cachedKey = _cacheKey;
      DataCacheService.instance.cacheList(
        _cacheKey,
        fresh.items.map((s) => s.toJson()).toList(),
        userId: widget.userId,
      );
    }
    // Cache-first: prefer fresh network data, fall back to the disk-cached
    // list (only if it belongs to the current category bucket).
    final items = fresh?.items ?? (_cachedKey == _cacheKey ? _cached : null);
    if (items != null) {
      return _renderGrid(context, items);
    }
    if (_cacheChecked && listAsync.hasError) {
      return _ErrorSliver(
          message: listAsync.error.toString(), isDark: widget.isDark);
    }
    // True first-ever open with nothing cached — shimmer grid skeleton.
    return const _RecipeGridSkeleton();
  }

  /// Render the recipe tiles as a lazy [SliverGrid]; empty list → empty-state
  /// sliver. The grid delegate is shared with the skeleton so swaps don't
  /// reflow.
  Widget _renderGrid(BuildContext context, List<RecipeSummary> items,
      {String? isEmptyHint}) {
    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: _EmptyState(
            isDark: widget.isDark, accent: widget.accent, hint: isEmptyHint),
      );
    }
    return SliverGrid(
      gridDelegate: _kRecipeGridDelegate,
      delegate: SliverChildBuilderDelegate(
        (_, i) {
          final s = items[i];
          return RecipeCard(
            summary: s,
            isDark: widget.isDark,
            accent: widget.accent,
            // Surface the source pill whenever a recipe is anything other
            // than plain "manual" — helps the user distinguish imported /
            // cloned / improvized items at a glance inside their library.
            showSourceBadge: _shouldShowSourceBadge(s),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => RecipeDetailScreen(
                    recipeId: s.id,
                    userId: widget.userId,
                    isDark: widget.isDark),
              ));
            },
            onLongPress: () => _showRecipeContextMenu(context, ref, s),
          );
        },
        childCount: items.length,
      ),
    );
  }

  bool _shouldShowSourceBadge(RecipeSummary s) {
    if (s.isCurated) return true;
    final t = (s.sourceType ?? '').toLowerCase();
    if (t.isEmpty || t == 'manual') return false;
    return true;
  }

  void _showRecipeContextMenu(BuildContext context, WidgetRef ref, RecipeSummary s) {
    showGlassSheet<void>(
      context: context,
      builder: (ctx) => GlassSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new, size: 20),
              title: Text(AppLocalizations.of(context).recipesOpen),
              onTap: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => RecipeDetailScreen(
                      recipeId: s.id,
                      userId: widget.userId,
                      isDark: widget.isDark),
                ));
              },
            ),
            if (!s.isCurated)
              ListTile(
                leading: Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                title: Text(AppLocalizations.of(context).buttonDelete, style: TextStyle(color: AppColors.error)),
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
        title: Text(AppLocalizations.of(context).recipesDeleteRecipe),
        content: Text('Are you sure you want to delete "${s.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(AppLocalizations.of(context).buttonCancel)),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppLocalizations.of(context).buttonDelete, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final repo = ref.read(nutritionRepositoryProvider);
      await repo.deleteRecipe(userId: widget.userId, recipeId: s.id);
      if (!context.mounted) return;
      // Invalidate both the keep-alive list cache AND the search cache so
      // the deleted row disappears from the grid immediately.
      ref.invalidate(myRecipesListProvider);
      ref.invalidate(recipeSearchProvider);
      // Drop the disk-cached list for this bucket so a cold restart doesn't
      // resurrect the just-deleted recipe; the provider re-fetch above will
      // write a fresh slot.
      DataCacheService.instance
          .invalidate(_cacheKey, userId: widget.userId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).recipesRecipeDeleted), duration: Duration(seconds: 2)),
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
            hint ?? AppLocalizations.of(context).recipesNoRecipesYet,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: text),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).recipesTapBuildToCreate,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: muted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// Error affordance rendered as a sliver — the My Recipes grid is hosted
/// directly inside the parent CustomScrollView, so its error / empty states
/// must also be sliver-shaped.
class _ErrorSliver extends StatelessWidget {
  final String message;
  final bool isDark;
  const _ErrorSliver({required this.message, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Couldn\'t load recipes: $message',
          style: TextStyle(
              color: isDark ? AppColors.error : AppColorsLight.error),
        ),
      ),
    );
  }
}

/// Layout-matched shimmer grid shown on a true first-ever open of the Recipes
/// tab (nothing disk-cached, provider still loading). Uses the SAME grid
/// delegate as the real [SliverGrid] so the skeleton → content swap never
/// reflows the layout. Six tiles is enough to fill the first viewport.
class _RecipeGridSkeleton extends StatelessWidget {
  const _RecipeGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: _kRecipeGridDelegate,
      delegate: SliverChildBuilderDelegate(
        (_, __) => const _RecipeCardSkeleton(),
        childCount: 6,
      ),
    );
  }
}

/// A single recipe-card placeholder — image block on top, title + meta lines
/// below — mirroring the real [RecipeCard] geometry inside the 0.78-ratio
/// grid tile.
class _RecipeCardSkeleton extends StatelessWidget {
  const _RecipeCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          // Hero image placeholder — fills the upper portion of the tile.
          Expanded(
            flex: 3,
            child: SkeletonBox(radius: 0, height: double.infinity),
          ),
          // Title + meta placeholder.
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SkeletonBox(width: double.infinity, height: 13),
                  SizedBox(height: 8),
                  SkeletonBox(width: 70, height: 11),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Single row inside the Fridge picker bottom sheet — icon + label
/// (+ optional subtitle) with an accent-tinted background. Kept private
/// to this file since the sheet is a one-off entry-point UI.
class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color accent;
  final VoidCallback onTap;
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: text,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: TextStyle(color: muted, fontSize: 12)),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: muted),
          ],
        ),
      ),
    );
  }
}
