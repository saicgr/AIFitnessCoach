/// Favorites screen — grid of recipes the user has hearted.
///
/// Pushed from the "Favorites" quick-action tile in [RecipesTab]. Uses the
/// server-backed [favoriteRecipesProvider] and hydrates the app-wide
/// [recipeFavoritesProvider] set on load so heart icons elsewhere stay in
/// sync after the user toggles favorites here.
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

class FavoritesScreen extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;
  const FavoritesScreen({
    super.key,
    required this.userId,
    required this.isDark,
  });

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    _hideNavBar();
  }

  @override
  void reassemble() {
    super.reassemble();
    // Re-hide after hot reload (initState doesn't re-fire).
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

  @override
  Widget build(BuildContext context) {
    final accent = AccentColorScope.of(context).getColor(widget.isDark);
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final topPad = MediaQuery.of(context).padding.top;

    final favoritesAsync = ref.watch(favoriteRecipesProvider(widget.userId));

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(8, topPad + 8, 16, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GlassBackButton(onTap: () => Navigator.of(context).pop()),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Favorites',
                    style: TextStyle(
                      color: text,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: favoritesAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: accent),
              ),
              error: (err, _) => _ErrorView(
                message: 'Couldn\'t load favorites.',
                accent: accent,
                text: text,
                muted: muted,
                onRetry: () =>
                    ref.invalidate(favoriteRecipesProvider(widget.userId)),
              ),
              data: (resp) {
                // Hydrate the app-wide favorites set after build so heart icons
                // on other screens reflect the server's truth.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  ref
                      .read(recipeFavoritesProvider.notifier)
                      .hydrate(resp.items.map((r) => r.id));
                });

                if (resp.items.isEmpty) {
                  return _EmptyFavoritesView(
                    accent: accent,
                    text: text,
                    muted: muted,
                  );
                }

                return RefreshIndicator(
                  color: accent,
                  onRefresh: () async {
                    ref.invalidate(favoriteRecipesProvider(widget.userId));
                    // Allow the provider to settle before the RefreshIndicator
                    // dismisses — this keeps the spinner visible during refetch.
                    await ref.read(favoriteRecipesProvider(widget.userId).future);
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
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
// Empty + error states
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyFavoritesView extends StatelessWidget {
  final Color accent;
  final Color text;
  final Color muted;
  const _EmptyFavoritesView({
    required this.accent,
    required this.text,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    // Wrap in a scrollable so pull-to-refresh still works on the empty state.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      children: [
        Column(
          children: [
            Icon(
              Icons.favorite_border,
              size: 56,
              color: accent.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No favorites yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap \u2665 on any recipe in Discover or your library to save it here.',
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
  final String message;
  final Color accent;
  final Color text;
  final Color muted;
  final VoidCallback onRetry;
  const _ErrorView({
    required this.message,
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
              message,
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
