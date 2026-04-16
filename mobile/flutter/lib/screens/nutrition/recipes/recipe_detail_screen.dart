/// Recipe detail — polished layout with hero image, favorite heart,
/// Improvize for curated / others' recipes, and the full set of
/// existing actions (Log, Schedule, Add to plan, Coach review, Share,
/// History, Delete).
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/coach_review.dart';
import '../../../data/models/recipe.dart';
import '../../../data/providers/recipe_favorites_provider.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../data/repositories/recipe_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_back_button.dart';
import '../../../widgets/main_shell.dart' show floatingNavBarVisibleProvider;
import '../meal_planner/meal_planner_screen.dart';
import 'recipe_create_screen.dart';
import 'recipe_history_screen.dart';
import 'recipe_schedule_screen.dart';
import 'recipe_share_sheet.dart';
import 'widgets/coach_review_sheet.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final String recipeId;
  final String userId;
  final bool isDark;
  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
    required this.userId,
    required this.isDark,
  });

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  Recipe? _recipe;
  bool _loading = true;
  String? _error;
  bool _improvizing = false;

  @override
  void initState() {
    super.initState();
    _hideNavBar();
    _load();
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
    // Restore the floating nav bar when leaving detail.
    try {
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
    } catch (_) {}
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await ref
          .read(nutritionRepositoryProvider)
          .getRecipe(userId: widget.userId, recipeId: widget.recipeId);
      if (!mounted) return;
      // Hydrate the favorites provider from the server projection so the
      // heart renders correctly instantly on other screens too.
      if (r.isFavorited) {
        ref.read(recipeFavoritesProvider.notifier).hydrate([r.id]);
      }
      setState(() {
        _recipe = r;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = AccentColorScope.of(context).getColor(widget.isDark);
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Scaffold(
      backgroundColor: bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(error: _error!, muted: muted, onRetry: _load)
              : _buildContent(_recipe!, accent, text, muted, surface, isDark),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Main content
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildContent(
    Recipe r,
    Color accent,
    Color text,
    Color muted,
    Color surface,
    bool isDark,
  ) {
    final topPad = MediaQuery.of(context).padding.top;
    final hasImage = (r.imageUrl ?? '').isNotEmpty;
    final isOwnRecipe = r.userId != null && r.userId == widget.userId;
    final canImprovize =
        r.isCurated || (r.userId != null && r.userId != widget.userId);
    final canDelete = isOwnRecipe && !r.isCurated;

    // Heart state: prefer live provider, fall back to server projection.
    final favSet = ref.watch(recipeFavoritesProvider).ids;
    final isFav = favSet.contains(r.id) || r.isFavorited;

    return CustomScrollView(
      slivers: [
        // Hero header sliver
        SliverToBoxAdapter(
          child: _buildHero(
            r: r,
            accent: accent,
            surface: surface,
            topPad: topPad,
            hasImage: hasImage,
            isFav: isFav,
            isDark: isDark,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Title
              Text(
                r.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: text,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              _buildMetaRow(r, muted, accent),
              // Forked-from badge
              if (r.sourceRecipeName != null) ...[
                const SizedBox(height: 8),
                _forkedFromBadge(r.sourceRecipeName!, accent),
              ],
              // Curated badge
              if (r.isCurated) ...[
                const SizedBox(height: 8),
                _curatedBadge(),
              ],
              if ((r.description ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  r.description!,
                  style: TextStyle(color: muted, fontSize: 13, height: 1.45),
                ),
              ],
              const SizedBox(height: 16),
              _macroHeroCard(r, accent, text, muted, surface),
              const SizedBox(height: 16),
              _buildActionRow(
                r: r,
                accent: accent,
                surface: surface,
                canImprovize: canImprovize,
                canDelete: canDelete,
                isDark: isDark,
              ),
              const SizedBox(height: 24),
              Text(
                'Ingredients',
                style: TextStyle(
                  color: text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              if (r.ingredients.isEmpty)
                Text(
                  'No ingredients',
                  style: TextStyle(color: muted, fontSize: 13),
                )
              else
                ...r.ingredients.map(
                  (i) => _ingRow(i, text, muted, surface, accent),
                ),
              if ((r.instructions ?? '').isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Instructions',
                  style: TextStyle(
                    color: text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  r.instructions!,
                  style: TextStyle(color: text, fontSize: 14, height: 1.5),
                ),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Hero image block
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHero({
    required Recipe r,
    required Color accent,
    required Color surface,
    required double topPad,
    required bool hasImage,
    required bool isFav,
    required bool isDark,
  }) {
    const imageHeight = 240.0;
    const stripHeight = 120.0;
    final height = hasImage ? imageHeight : stripHeight;

    return SizedBox(
      height: height + topPad,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image or accent strip
          if (hasImage)
            Positioned.fill(
              child: Image.network(
                r.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imagePlaceholder(accent),
              ),
            )
          else
            Positioned.fill(
              child: Container(
                color: accent.withValues(alpha: 0.08),
                child: Center(
                  child: Icon(
                    Icons.restaurant_menu,
                    color: accent.withValues(alpha: 0.6),
                    size: 48,
                  ),
                ),
              ),
            ),
          // Dark gradient overlay at the bottom for readability
          if (hasImage)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.4),
                    ],
                  ),
                ),
              ),
            ),
          // Back button (top-left)
          Positioned(
            left: 12,
            top: topPad + 8,
            child: GlassBackButton(onTap: () => Navigator.of(context).pop()),
          ),
          // Favorite heart (top-right)
          Positioned(
            right: 12,
            top: topPad + 8,
            child: _HeartToggle(
              isFav: isFav,
              isDark: isDark,
              onTap: () => _toggleFavorite(r.id),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder(Color accent) {
    return Container(
      color: accent.withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          Icons.restaurant_menu,
          color: accent.withValues(alpha: 0.6),
          size: 48,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Meta row (servings · time · category/cuisine)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildMetaRow(Recipe r, Color muted, Color accent) {
    final total = r.totalTimeMinutes;
    final parts = <Widget>[
      _metaText('\ud83d\udc64 ${r.servings} serves', muted),
    ];
    if (total > 0) {
      parts
        ..add(_metaSep(muted))
        ..add(_metaText('\u23f1 $total min', muted));
    }
    final category = r.categoryEnum;
    parts
      ..add(_metaSep(muted))
      ..add(_metaPill('${category.emoji} ${category.label}', accent));
    if ((r.cuisine ?? '').isNotEmpty) {
      parts.add(const SizedBox(width: 6));
      parts.add(_metaPill(r.cuisine!, accent));
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 6,
      children: parts,
    );
  }

  Widget _metaText(String s, Color muted) => Text(
        s,
        style: TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w600),
      );

  Widget _metaSep(Color muted) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text('·', style: TextStyle(color: muted, fontSize: 12)),
      );

  Widget _metaPill(String label, Color accent) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: accent,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Badges
  // ─────────────────────────────────────────────────────────────────────────

  Widget _forkedFromBadge(String sourceName, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '\u2728 Forked from $sourceName',
        style: TextStyle(
          color: accent,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _curatedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.yellow.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '\ud83c\udf1f Curated recipe',
        style: TextStyle(
          color: AppColors.yellow,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Macro hero card
  // ─────────────────────────────────────────────────────────────────────────

  Widget _macroHeroCard(
    Recipe r,
    Color accent,
    Color text,
    Color muted,
    Color surface,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Per serving (\u00d7${r.servings} servings)',
            style: TextStyle(
              color: muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _macroTile('${r.caloriesPerServing ?? 0}', 'kcal', text, muted),
              _macroTile(
                (r.proteinPerServingG ?? 0).toStringAsFixed(0),
                'P g',
                text,
                muted,
              ),
              _macroTile(
                (r.carbsPerServingG ?? 0).toStringAsFixed(0),
                'C g',
                text,
                muted,
              ),
              _macroTile(
                (r.fatPerServingG ?? 0).toStringAsFixed(0),
                'F g',
                text,
                muted,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macroTile(String value, String label, Color text, Color muted) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: text,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(label, style: TextStyle(color: muted, fontSize: 11)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Action row (pill chips)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildActionRow({
    required Recipe r,
    required Color accent,
    required Color surface,
    required bool canImprovize,
    required bool canDelete,
    required bool isDark,
  }) {
    final improvizeColor = const Color(0xFF9B59FF); // distinct purple accent
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (canImprovize)
          _ActionChip(
            label: _improvizing ? 'Improvizing…' : 'Improvize',
            icon: Icons.auto_awesome,
            color: improvizeColor,
            onTap: _improvizing ? null : () => _improvize(r),
          ),
        _ActionChip(
          label: 'Log',
          icon: Icons.add_circle_outline,
          color: accent,
          onTap: () => _logRecipe(r),
        ),
        _ActionChip(
          label: 'Schedule',
          icon: Icons.alarm_add_outlined,
          color: accent,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RecipeScheduleScreen(
                  recipe: r,
                  userId: widget.userId,
                  isDark: widget.isDark,
                ),
              ),
            );
          },
        ),
        _ActionChip(
          label: 'Add to plan',
          icon: Icons.calendar_today,
          color: accent,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MealPlannerScreen(
                  userId: widget.userId,
                  isDark: widget.isDark,
                  date: DateTime.now(),
                  addRecipeId: r.id,
                ),
              ),
            );
          },
        ),
        _ActionChip(
          label: 'Coach review',
          icon: Icons.psychology_outlined,
          color: accent,
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: surface,
              builder: (_) => CoachReviewSheet(
                subjectType: CoachReviewSubject.recipe,
                subjectId: r.id,
                userId: widget.userId,
                isDark: widget.isDark,
              ),
            );
          },
        ),
        _ActionChip(
          label: 'Share',
          icon: Icons.share_rounded,
          color: accent,
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: surface,
              builder: (_) => RecipeShareSheet(
                recipeId: widget.recipeId,
                userId: widget.userId,
                isDark: widget.isDark,
              ),
            );
          },
        ),
        _ActionChip(
          label: 'History',
          icon: Icons.history,
          color: accent,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RecipeHistoryScreen(
                  recipeId: widget.recipeId,
                  userId: widget.userId,
                  isDark: widget.isDark,
                ),
              ),
            );
          },
        ),
        if (canDelete)
          _ActionChip(
            label: 'Delete',
            icon: Icons.delete_outline,
            color: AppColors.error,
            onTap: () => _confirmDelete(r),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Ingredient row
  // ─────────────────────────────────────────────────────────────────────────

  Widget _ingRow(
    RecipeIngredient i,
    Color text,
    Color muted,
    Color surface,
    Color accent,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${i.amount.toStringAsFixed(i.amount == i.amount.toInt() ? 0 : 1)} ${i.unit} '
              '${i.brand != null ? "${i.brand} " : ""}${i.foodName}',
              style: TextStyle(color: text, fontSize: 13),
            ),
          ),
          if (i.calories != null)
            Text(
              '${i.calories!.toStringAsFixed(0)} kcal',
              style: TextStyle(
                color: muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _toggleFavorite(String recipeId) async {
    HapticService.light();
    final notifier = ref.read(recipeFavoritesProvider.notifier);
    final wasFav = notifier.isFavorited(recipeId) || (_recipe?.isFavorited ?? false);
    try {
      await notifier.toggle(recipeId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 1),
          content: Text(wasFav ? 'Removed from favorites' : 'Added to favorites'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't update favorite: $e")),
      );
    }
  }

  Future<void> _improvize(Recipe r) async {
    HapticService.light();
    setState(() => _improvizing = true);
    try {
      final forked = await ref.read(recipeRepositoryProvider).improvize(r.id);
      if (!mounted) return;
      setState(() => _improvizing = false);

      // Convert the fresh Recipe → RecipeCreate so the user can edit and
      // save a truly personalized variation.
      final prefill = _recipeToCreate(forked);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 2),
          content: Text('Improvized! Edit and save your version.'),
        ),
      );

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RecipeCreateScreen(
            userId: widget.userId,
            isDark: widget.isDark,
            prefill: prefill,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _improvizing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Improvize failed: $e')),
      );
    }
  }

  RecipeCreate _recipeToCreate(Recipe r) {
    return RecipeCreate(
      name: r.name,
      description: r.description,
      servings: r.servings,
      prepTimeMinutes: r.prepTimeMinutes,
      cookTimeMinutes: r.cookTimeMinutes,
      instructions: r.instructions,
      imageUrl: r.imageUrl,
      category: r.category,
      cuisine: r.cuisine,
      tags: r.tags,
      sourceUrl: r.sourceUrl,
      sourceType: r.sourceType,
      isPublic: r.isPublic,
      ingredients: r.ingredients
          .map(
            (i) => RecipeIngredientCreate(
              foodName: i.foodName,
              brand: i.brand,
              amount: i.amount,
              unit: i.unit,
              amountGrams: i.amountGrams,
              barcode: i.barcode,
              calories: i.calories,
              proteinG: i.proteinG,
              carbsG: i.carbsG,
              fatG: i.fatG,
              fiberG: i.fiberG,
              sugarG: i.sugarG,
              vitaminDIu: i.vitaminDIu,
              calciumMg: i.calciumMg,
              ironMg: i.ironMg,
              sodiumMg: i.sodiumMg,
              omega3G: i.omega3G,
              micronutrients: i.micronutrients,
              notes: i.notes,
              isOptional: i.isOptional,
              ingredientOrder: i.ingredientOrder,
            ),
          )
          .toList(),
    );
  }

  Future<void> _logRecipe(Recipe r) async {
    try {
      await ref.read(nutritionRepositoryProvider).logRecipe(
            userId: widget.userId,
            recipeId: r.id,
            mealType: 'lunch',
            servings: 1.0,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged 1 serving as lunch')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Log failed: $e')),
        );
      }
    }
  }

  Future<void> _confirmDelete(Recipe r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete recipe?'),
        content: Text('"${r.name}" will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(nutritionRepositoryProvider).deleteRecipe(
            userId: widget.userId,
            recipeId: r.id,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe deleted')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Heart toggle widget (glass style, mirrors GlassBackButton sizing)
// ─────────────────────────────────────────────────────────────────────────

class _HeartToggle extends StatelessWidget {
  final bool isFav;
  final bool isDark;
  final VoidCallback onTap;
  const _HeartToggle({
    required this.isFav,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav
                  ? Colors.redAccent
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.9)
                      : AppColorsLight.textSecondary),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String error;
  final Color muted;
  final VoidCallback onRetry;
  const _ErrorState({
    required this.error,
    required this.muted,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: muted, size: 32),
            const SizedBox(height: 8),
            Text('Error: $error', style: TextStyle(color: muted)),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Reusable action chip
// ─────────────────────────────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.6,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
