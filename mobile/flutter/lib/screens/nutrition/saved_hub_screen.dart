/// Saved hub — the user's bookmarked nutrition items across three sub-tabs:
/// **Recipes · Foods · Menus**.
///
/// Replaces the old `_SavedCard → FavoritesScreen` jump (a recipes-only grid)
/// with a dedicated hub that surfaces every saved type, each row stamped with
/// *when* it was saved. All three tabs load from the database:
///  - Recipes → `favoriteRecipesProvider` (`/nutrition/recipes/favorites`).
///  - Foods   → `NutritionRepository.getSavedFoods` (`/nutrition/saved-foods`).
///  - Menus   → `/nutrition/menu-analyses` (saved menu/buffet scans).
///
/// The screen carries its OWN floating bottom bar (styled like the
/// workout-detail / workout-completed screens), so it hides the global
/// `floatingNavBarVisibleProvider` while open and restores it reliably on
/// dispose — fixing the nav-bar race the old FavoritesScreen had.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_colors.dart';
import '../../data/models/nutrition.dart';
import '../../data/models/recipe.dart';
import '../../data/providers/recipe_favorites_provider.dart';
import '../../data/providers/recipe_providers.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../data/services/api_client.dart';
import '../../widgets/glass_back_button.dart';
import '../../widgets/nav_bar_hider_mixin.dart';
import 'menu_analysis_sheet.dart';
import 'recipes/recipe_detail_screen.dart';

import '../../l10n/generated/app_localizations.dart';
// ─────────────────────────────────────────────────────────────────────────────
// Data: saved foods (DB-backed, newest first)
// ─────────────────────────────────────────────────────────────────────────────

/// Saved foods for a user, ordered newest-first by `created_at`. Backed by
/// `/nutrition/saved-foods` — `SavedFood.createdAt` is the real saved-at
/// timestamp (the row is created the moment the user saves the food).
final savedFoodsHubProvider = FutureProvider.autoDispose
    .family<List<SavedFood>, String>((ref, userId) async {
  ref.keepAlive();
  final repo = ref.watch(nutritionRepositoryProvider);
  final resp = await repo.getSavedFoods(
    userId: userId,
    limit: 100,
    sortBy: 'created_at',
    sortOrder: 'desc',
  );
  final items = [...resp.items]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return items;
});

/// A saved menu/buffet analysis row. The backend `menu_analyses` table
/// exposes `created_at` (the scan/save time) — used as the saved-at stamp.
class SavedMenu {
  final String id;
  final String? title;
  final String? restaurantName;
  final String? thumbnailUrl;
  final int itemCount;
  final String analysisType;
  final DateTime? createdAt;

  const SavedMenu({
    required this.id,
    this.title,
    this.restaurantName,
    this.thumbnailUrl,
    this.itemCount = 0,
    this.analysisType = 'menu',
    this.createdAt,
  });

  factory SavedMenu.fromJson(Map<String, dynamic> json) {
    final photos = List<String>.from(json['menu_photo_urls'] ?? const []);
    final items = List<dynamic>.from(json['food_items'] ?? const []);
    return SavedMenu(
      id: json['id']?.toString() ?? '',
      title: (json['title'] as String?)?.trim(),
      restaurantName: (json['restaurant_name'] as String?)?.trim(),
      thumbnailUrl: photos.isNotEmpty ? photos.first : null,
      itemCount: items.length,
      analysisType: json['analysis_type'] as String? ?? 'menu',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}

/// Saved menus, ordered newest-first. Backed by `/nutrition/menu-analyses`.
final savedMenusHubProvider =
    FutureProvider.autoDispose<List<SavedMenu>>((ref) async {
  ref.keepAlive();
  final api = ref.watch(apiClientProvider);
  final resp = await api.get('/nutrition/menu-analyses');
  final rows = List<Map<String, dynamic>>.from(resp.data ?? const []);
  final menus = rows.map(SavedMenu.fromJson).toList()
    ..sort((a, b) {
      final ad = a.createdAt, bd = b.createdAt;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });
  return menus;
});

// ─────────────────────────────────────────────────────────────────────────────
// Relative-date formatting
// ─────────────────────────────────────────────────────────────────────────────

const _kMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "Saved just now / 2h ago / 3d ago / Saved May 14 / Saved May 14, 2025".
String formatSavedAt(DateTime? when) {
  if (when == null) return '';
  final now = DateTime.now();
  final local = when.toLocal();
  final diff = now.difference(local);
  if (diff.inSeconds < 60) return 'Saved just now';
  if (diff.inMinutes < 60) return 'Saved ${diff.inMinutes}m ago';
  if (diff.inHours < 24) return 'Saved ${diff.inHours}h ago';
  if (diff.inDays < 7) return 'Saved ${diff.inDays}d ago';
  final month = _kMonths[local.month - 1];
  if (local.year == now.year) return 'Saved $month ${local.day}';
  return 'Saved $month ${local.day}, ${local.year}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class SavedHubScreen extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;

  const SavedHubScreen({
    super.key,
    required this.userId,
    required this.isDark,
  });

  @override
  ConsumerState<SavedHubScreen> createState() => _SavedHubScreenState();
}

class _SavedHubScreenState extends ConsumerState<SavedHubScreen>
    with SingleTickerProviderStateMixin, NavBarHiderMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.colors(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(
              8,
              MediaQuery.of(context).padding.top + 8,
              16,
              4,
            ),
            child: Row(
              children: [
                GlassBackButton(onTap: () => Navigator.of(context).pop()),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).savedHubSaved,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Sub-tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.cardBorder),
              ),
              padding: const EdgeInsets.all(4),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: colors.accent,
                  borderRadius: BorderRadius.circular(9),
                ),
                labelColor: colors.accentContrast,
                unselectedLabelColor: colors.textSecondary,
                labelStyle: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Recipes'),
                  Tab(text: 'Foods'),
                  Tab(text: 'Menus'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _RecipesTab(userId: widget.userId, isDark: widget.isDark),
                _FoodsTab(userId: widget.userId, colors: colors),
                _MenusTab(colors: colors),
              ],
            ),
          ),
        ],
      ),
      // Own floating bottom bar — styled like the workout-detail /
      // workout-completed screens (gradient pill in a SafeArea bar).
      bottomNavigationBar: _SavedHubBottomBar(colors: colors),
    );
  }
}

/// Floating bottom bar — a single full-width "Done" gradient action,
/// matching the workout-completed screen's bottom bar treatment.
class _SavedHubBottomBar extends StatelessWidget {
  final ThemeColors colors;
  const _SavedHubBottomBar({required this.colors});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Container(
          decoration: BoxDecoration(
            gradient: colors.accentGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: colors.accent.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.check_rounded,
                size: 20, color: colors.accentContrast),
            label: Text(
              AppLocalizations.of(context).commonDone,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: colors.accentContrast,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recipes tab
// ─────────────────────────────────────────────────────────────────────────────

class _RecipesTab extends ConsumerWidget {
  final String userId;
  final bool isDark;
  const _RecipesTab({required this.userId, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.colors(context);
    if (userId.isEmpty) {
      return _EmptyState(
        colors: colors,
        icon: Icons.bookmark_border_rounded,
        title: AppLocalizations.of(context).savedHubNothingSavedYet,
        hint: AppLocalizations.of(context).savedHubSignInToSee,
      );
    }
    final async = ref.watch(favoriteRecipesProvider(userId));
    return async.when(
      loading: () => Center(child: CircularProgressIndicator(color: colors.accent)),
      error: (e, _) => _ErrorState(
        colors: colors,
        onRetry: () => ref.invalidate(favoriteRecipesProvider(userId)),
      ),
      data: (resp) {
        // Keep the app-wide heart state in sync, like FavoritesScreen did.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(recipeFavoritesProvider.notifier)
              .hydrate(resp.items.map((r) => r.id));
        });
        if (resp.items.isEmpty) {
          return _EmptyState(
            colors: colors,
            icon: Icons.restaurant_menu_rounded,
            title: AppLocalizations.of(context).savedHubNothingSavedYet,
            hint: AppLocalizations.of(context).savedHubTapOnAnyRecipe,
          );
        }
        // RecipeSummary has no per-favorite saved-at field on the backend;
        // `created_at` is the recipe's own creation date. Sort newest-first
        // by that and stamp each row with it.
        final items = [...resp.items]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return RefreshIndicator(
          color: colors.accent,
          onRefresh: () async {
            ref.invalidate(favoriteRecipesProvider(userId));
            await ref.read(favoriteRecipesProvider(userId).future);
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final r = items[i];
              return _SavedRow(
                colors: colors,
                imageUrl: r.imageUrl,
                fallbackIcon: Icons.restaurant_menu_rounded,
                name: r.name,
                subtitle: _recipeMacros(r),
                stamp: formatSavedAt(r.createdAt),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RecipeDetailScreen(
                        userId: userId,
                        recipeId: r.id,
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
    );
  }

  static String _recipeMacros(RecipeSummary r) {
    final parts = <String>[];
    if (r.caloriesPerServing != null) {
      parts.add('${r.caloriesPerServing} cal');
    }
    if (r.proteinPerServingG != null) {
      parts.add('${r.proteinPerServingG!.round()}g protein');
    }
    if (parts.isEmpty && r.category != null) parts.add(r.category!);
    return parts.join('  ·  ');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Foods tab
// ─────────────────────────────────────────────────────────────────────────────

class _FoodsTab extends ConsumerWidget {
  final String userId;
  final ThemeColors colors;
  const _FoodsTab({required this.userId, required this.colors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId.isEmpty) {
      return _EmptyState(
        colors: colors,
        icon: Icons.bookmark_border_rounded,
        title: AppLocalizations.of(context).savedHubNothingSavedYet,
        hint: AppLocalizations.of(context).savedHubSignInToSee2,
      );
    }
    final async = ref.watch(savedFoodsHubProvider(userId));
    return async.when(
      loading: () => Center(child: CircularProgressIndicator(color: colors.accent)),
      error: (e, _) => _ErrorState(
        colors: colors,
        onRetry: () => ref.invalidate(savedFoodsHubProvider(userId)),
      ),
      data: (foods) {
        if (foods.isEmpty) {
          return _EmptyState(
            colors: colors,
            icon: Icons.lunch_dining_rounded,
            title: AppLocalizations.of(context).savedHubNothingSavedYet,
            hint: AppLocalizations.of(context).savedHubSaveAMealOr,
          );
        }
        return RefreshIndicator(
          color: colors.accent,
          onRefresh: () async {
            ref.invalidate(savedFoodsHubProvider(userId));
            await ref.read(savedFoodsHubProvider(userId).future);
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: foods.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final f = foods[i];
              return _SavedRow(
                colors: colors,
                imageUrl: f.imageUrl,
                emoji: f.emoji,
                fallbackIcon: Icons.lunch_dining_rounded,
                name: f.brand != null && f.brand!.isNotEmpty
                    ? '${f.name}  ·  ${f.brand}'
                    : f.name,
                subtitle: _foodMacros(f),
                stamp: formatSavedAt(f.createdAt),
                onTap: null,
              );
            },
          ),
        );
      },
    );
  }

  static String _foodMacros(SavedFood f) {
    final parts = <String>[];
    if (f.totalCalories != null) parts.add('${f.totalCalories} cal');
    if (f.totalProteinG != null) {
      parts.add('${f.totalProteinG!.round()}g protein');
    }
    if (f.totalCarbsG != null) parts.add('${f.totalCarbsG!.round()}g carbs');
    return parts.join('  ·  ');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Menus tab
// ─────────────────────────────────────────────────────────────────────────────

class _MenusTab extends ConsumerWidget {
  final ThemeColors colors;
  const _MenusTab({required this.colors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(savedMenusHubProvider);
    return async.when(
      loading: () => Center(child: CircularProgressIndicator(color: colors.accent)),
      error: (e, _) => _ErrorState(
        colors: colors,
        onRetry: () => ref.invalidate(savedMenusHubProvider),
      ),
      data: (menus) {
        if (menus.isEmpty) {
          return _EmptyState(
            colors: colors,
            icon: Icons.menu_book_rounded,
            title: AppLocalizations.of(context).savedHubNothingSavedYet,
            hint: AppLocalizations.of(context).savedHubScanARestaurantMenu,
          );
        }
        return RefreshIndicator(
          color: colors.accent,
          onRefresh: () async {
            ref.invalidate(savedMenusHubProvider);
            await ref.read(savedMenusHubProvider.future);
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: menus.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final m = menus[i];
              final name = m.title?.isNotEmpty == true
                  ? m.title!
                  : (m.restaurantName?.isNotEmpty == true
                      ? m.restaurantName!
                      : (m.analysisType == 'buffet'
                          ? 'Buffet scan'
                          : 'Menu scan'));
              final sub = <String>[];
              if (m.restaurantName?.isNotEmpty == true &&
                  m.title?.isNotEmpty == true) {
                sub.add(m.restaurantName!);
              }
              if (m.itemCount > 0) {
                sub.add('${m.itemCount} item${m.itemCount == 1 ? '' : 's'}');
              }
              return _SavedRow(
                colors: colors,
                imageUrl: m.thumbnailUrl,
                fallbackIcon: Icons.menu_book_rounded,
                name: name,
                subtitle: sub.join('  ·  '),
                stamp: formatSavedAt(m.createdAt),
                onTap: () => _openMenu(context, ref, m),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openMenu(
      BuildContext context, WidgetRef ref, SavedMenu m) async {
    final api = ref.read(apiClientProvider);
    try {
      final resp = await api.get('/nutrition/menu-analyses/${m.id}');
      final data = Map<String, dynamic>.from(resp.data ?? {});
      final items =
          List<Map<String, dynamic>>.from(data['food_items'] ?? const []);
      final photos = List<String>.from(data['menu_photo_urls'] ?? const []);
      final elapsed = (data['elapsed_seconds'] as num?)?.toDouble();
      if (!context.mounted) return;
      MenuAnalysisSheet.show(
        context,
        foodItems: items,
        analysisType: data['analysis_type'] as String? ?? 'menu',
        isDark: Theme.of(context).brightness == Brightness.dark,
        onLogItems: (_) {/* reopen-only — logging handled by the sheet */},
        menuPhotoUrls: photos,
        elapsedSeconds: elapsed,
        restaurantName: data['restaurant_name'] as String?,
        restaurantAddress: data['address'] as String?,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open menu: $e')),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared row
// ─────────────────────────────────────────────────────────────────────────────

class _SavedRow extends StatelessWidget {
  final ThemeColors colors;
  final String? imageUrl;
  final String? emoji;
  final IconData fallbackIcon;
  final String name;
  final String subtitle;
  final String stamp;
  final VoidCallback? onTap;

  const _SavedRow({
    required this.colors,
    this.imageUrl,
    this.emoji,
    required this.fallbackIcon,
    required this.name,
    required this.subtitle,
    required this.stamp,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.cardBorder),
          ),
          child: Row(
            children: [
              _thumbnail(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                    if (stamp.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded,
                              size: 11, color: colors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            stamp,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbnail() {
    const size = 56.0;
    Widget fallback() => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: colors.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: emoji != null && emoji!.isNotEmpty
              ? Text(emoji!, style: const TextStyle(fontSize: 24))
              : Icon(fallbackIcon, size: 24, color: colors.accent),
        );

    if (imageUrl == null || imageUrl!.isEmpty) return fallback();
    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: size,
          height: size,
          color: colors.elevated,
        ),
        errorWidget: (_, __, ___) => fallback(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty + error states
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final ThemeColors colors;
  final IconData icon;
  final String title;
  final String hint;
  const _EmptyState({
    required this.colors,
    required this.icon,
    required this.title,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 28),
      children: [
        Column(
          children: [
            Icon(icon, size: 54, color: colors.accent.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: colors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final ThemeColors colors;
  final VoidCallback onRetry;
  const _ErrorState({required this.colors, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 46, color: colors.accent.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).savedHubCouldnTLoadYour,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).savedHubCheckYourConnectionAnd,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: colors.accent),
              child: Text(AppLocalizations.of(context).workoutReviewTryAgain),
            ),
          ],
        ),
      ),
    );
  }
}
