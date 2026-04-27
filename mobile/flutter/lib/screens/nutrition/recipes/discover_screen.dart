/// Discover screen — curated recipes the community (and Zealova) has vetted.
///
/// Pushed from the "Discover" quick-action tile in [RecipesTab]. Shows a
/// single-select category chip row + a cycling sort pill (Popular / Recent /
/// A-Z), and renders a 2-column grid of [RecipeCard]s.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/providers/recipe_favorites_provider.dart';
import '../../../data/providers/recipe_providers.dart';
import '../../../widgets/glass_back_button.dart';
import '../../../widgets/main_shell.dart' show floatingNavBarVisibleProvider;
import 'recipe_detail_screen.dart';
import 'widgets/recipe_card.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;
  const DiscoverScreen({
    super.key,
    required this.userId,
    required this.isDark,
  });

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  String? _category; // null == All
  String _sort = 'most_logged';

  // Cycle order for the sort pill.
  static const _sortCycle = <String>[
    'most_logged',
    'created_desc',
    'name_asc',
  ];

  // Display label shown on the pill for each sort value.
  static const _sortLabels = <String, String>{
    'most_logged': 'Popular',
    'created_desc': 'Recent',
    'name_asc': 'A-Z',
  };

  // Human-readable category labels used in the "No curated X" empty string.
  static const _categoryLabels = <String, String>{
    'breakfast': 'breakfast',
    'lunch': 'lunch',
    'dinner': 'dinner',
    'snack': 'snack',
    'dessert': 'dessert',
    'drink': 'drink',
  };

  @override
  void initState() {
    super.initState();
    _hideNavBar();
  }

  @override
  void reassemble() {
    super.reassemble();
    _hideNavBar();
  }

  void _hideNavBar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(floatingNavBarVisibleProvider.notifier).state = false;
      }
    });
  }

  @override
  void dispose() {
    try {
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
    } catch (_) {}
    super.dispose();
  }

  void _cycleSort() {
    final idx = _sortCycle.indexOf(_sort);
    final next = _sortCycle[(idx + 1) % _sortCycle.length];
    setState(() => _sort = next);
  }

  @override
  Widget build(BuildContext context) {
    final accent = AccentColorScope.of(context).getColor(widget.isDark);
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final topPad = MediaQuery.of(context).padding.top;

    final args = DiscoverArgs(category: _category, sort: _sort);
    final discoverAsync = ref.watch(discoverRecipesProvider(args));

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row
          Padding(
            padding: EdgeInsets.fromLTRB(8, topPad + 8, 16, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GlassBackButton(onTap: () => Navigator.of(context).pop()),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discover',
                        style: TextStyle(
                          color: text,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Curated recipes to try or improvize',
                        style: TextStyle(
                          color: muted,
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Category chip row + sort pill
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _CategoryAndSortRow(
              isDark: isDark,
              accent: accent,
              text: text,
              muted: muted,
              selectedCategory: _category,
              sortLabel: _sortLabels[_sort] ?? 'Popular',
              onCategoryChanged: (c) => setState(() => _category = c),
              onSortTap: _cycleSort,
            ),
          ),

          Expanded(
            child: discoverAsync.when(
              loading: () =>
                  Center(child: CircularProgressIndicator(color: accent)),
              error: (err, _) => _ErrorView(
                accent: accent,
                text: text,
                muted: muted,
                onRetry: () =>
                    ref.invalidate(discoverRecipesProvider(args)),
              ),
              data: (resp) {
                // Keep heart states in sync for discover items.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  final favIds = resp.items
                      .where((r) => r.isFavorited)
                      .map((r) => r.id);
                  ref.read(recipeFavoritesProvider.notifier).hydrate(favIds);
                });

                if (resp.items.isEmpty) {
                  final catLabel =
                      _category == null ? null : _categoryLabels[_category!];
                  return _EmptyDiscoverView(
                    accent: accent,
                    text: text,
                    muted: muted,
                    categoryLabel: catLabel,
                  );
                }

                return RefreshIndicator(
                  color: accent,
                  onRefresh: () async {
                    ref.invalidate(discoverRecipesProvider(args));
                    await ref.read(discoverRecipesProvider(args).future);
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: resp.items.length,
                    itemBuilder: (ctx, i) {
                      final summary = resp.items[i];
                      return RecipeCard(
                        summary: summary,
                        isDark: isDark,
                        accent: accent,
                        showSourceBadge: true,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RecipeDetailScreen(
                                userId: widget.userId,
                                recipeId: summary.id,
                                isDark: isDark,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category chip row + sort pill
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryAndSortRow extends StatelessWidget {
  final bool isDark;
  final Color accent;
  final Color text;
  final Color muted;
  final String? selectedCategory;
  final String sortLabel;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onSortTap;

  const _CategoryAndSortRow({
    required this.isDark,
    required this.accent,
    required this.text,
    required this.muted,
    required this.selectedCategory,
    required this.sortLabel,
    required this.onCategoryChanged,
    required this.onSortTap,
  });

  @override
  Widget build(BuildContext context) {
    const cats = <(String?, String)>[
      (null, 'All'),
      ('breakfast', '🌅 Breakfast'),
      ('lunch', '☀️ Lunch'),
      ('dinner', '🌙 Dinner'),
      ('snack', '🍎 Snack'),
      ('dessert', '🍰 Dessert'),
      ('drink', '🥤 Drink'),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final c in cats)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _Chip(
                      label: c.$2,
                      selected: selectedCategory == c.$1,
                      accent: accent,
                      muted: muted,
                      text: text,
                      onTap: () => onCategoryChanged(c.$1),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _SortPill(
          label: sortLabel,
          accent: accent,
          muted: muted,
          text: text,
          onTap: onSortTap,
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final Color muted;
  final Color text;
  final VoidCallback onTap;
  const _Chip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.muted,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? accent : muted.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : text,
          ),
        ),
      ),
    );
  }
}

/// Cycling sort pill. Tap cycles Popular → Recent → A-Z → Popular.
class _SortPill extends StatelessWidget {
  final String label;
  final Color accent;
  final Color muted;
  final Color text;
  final VoidCallback onTap;
  const _SortPill({
    required this.label,
    required this.accent,
    required this.muted,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_vert_rounded, size: 14, color: accent),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty + error states
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyDiscoverView extends StatelessWidget {
  final Color accent;
  final Color text;
  final Color muted;
  final String? categoryLabel;
  const _EmptyDiscoverView({
    required this.accent,
    required this.text,
    required this.muted,
    this.categoryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final title = categoryLabel == null
        ? 'No curated recipes yet'
        : 'No curated $categoryLabel recipes yet';
    final subtitle = categoryLabel == null
        ? 'Check back soon \u2014 we\'re adding new recipes every week.'
        : 'Try a different category, or check back soon.';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      children: [
        Column(
          children: [
            Icon(
              Icons.restaurant_menu_rounded,
              size: 56,
              color: accent.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: muted, height: 1.5),
            ),
          ],
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Color accent;
  final Color text;
  final Color muted;
  final VoidCallback onRetry;
  const _ErrorView({
    required this.accent,
    required this.text,
    required this.muted,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: accent.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              "Couldn't load Discover.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: muted),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: accent),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
