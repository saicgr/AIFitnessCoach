/// Index of all grocery lists the user has built.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/widgets/skeleton/skeleton.dart';
import '../../../data/models/grocery_list.dart';
import '../../../data/providers/recipe_providers.dart';
import '../../../data/repositories/recipe_repository.dart';
import '../../../data/services/data_cache_service.dart';
import '../../../widgets/glass_back_button.dart';
import '../../../widgets/nav_bar_hider_mixin.dart';
import 'grocery_list_screen.dart';

class GroceryListsIndexScreen extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;
  const GroceryListsIndexScreen({super.key, required this.userId, required this.isDark});
  @override
  ConsumerState<GroceryListsIndexScreen> createState() => _GroceryListsIndexScreenState();
}

class _GroceryListsIndexScreenState extends ConsumerState<GroceryListsIndexScreen>
    with NavBarHiderMixin {
  /// Disk-cached list summaries, hydrated in [initState] so a cold start
  /// renders the user's real grocery lists on first frame instead of a
  /// spinner. The keep-alive `groceryListsProvider` then revalidates (SWR).
  List<GroceryListSummary>? _cachedLists;

  /// SharedPreferences slot for the cached list-index payload.
  static const _cacheKey = 'cache_grocery_lists';

  @override
  void initState() {
    super.initState();
    _hydrateFromCache();
  }

  /// Read the persisted list summaries off disk (instant, no network).
  Future<void> _hydrateFromCache() async {
    try {
      final cached = await DataCacheService.instance
          .getCachedList(_cacheKey, userId: widget.userId);
      if (cached != null && mounted) {
        setState(() {
          _cachedLists = cached.map(GroceryListSummary.fromJson).toList();
        });
      }
    } catch (e) {
      debugPrint('🛒 [GroceryLists] cache read failed: $e');
    }
  }

  /// Write fresh summaries through to disk so the next cold start is instant.
  /// `GroceryListSummary` has no `toJson`, so we re-emit the exact snake_case
  /// shape `GroceryListSummary.fromJson` expects.
  Future<void> _persistToCache(List<GroceryListSummary> lists) async {
    try {
      await DataCacheService.instance.cacheList(
        _cacheKey,
        lists
            .map((l) => <String, dynamic>{
                  'id': l.id,
                  'name': l.name,
                  'item_count': l.itemCount,
                  'checked_count': l.checkedCount,
                  'meal_plan_id': l.mealPlanId,
                  'source_recipe_id': l.sourceRecipeId,
                  'created_at': l.createdAt.toIso8601String(),
                })
            .toList(),
        userId: widget.userId,
      );
    } catch (e) {
      debugPrint('🛒 [GroceryLists] cache write failed: $e');
    }
  }

  Future<void> _createManualList(String userId, bool isDark) async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New grocery list'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'List name (optional)'),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(nameController.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name == null || !mounted) return;

    try {
      final list = await ref.read(recipeRepositoryProvider).buildGroceryList(
        userId,
        GroceryListCreate(name: name.isNotEmpty ? name : null),
      );
      if (!mounted) return;
      // Refresh the lists
      ref.invalidate(groceryListsProvider(userId));
      // Navigate to the new list
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GroceryListScreen(listId: list.id, userId: userId, isDark: isDark),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create list: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final userId = widget.userId;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final bg = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final asyncLists = ref.watch(groceryListsProvider(userId));
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: accent,
        foregroundColor: isDark ? Colors.black : Colors.white,
        onPressed: () => _createManualList(userId, isDark),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          SizedBox(height: topPad + 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 16, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GlassBackButton(onTap: () => Navigator.of(context).pop()),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Grocery lists',
                    style: TextStyle(color: text, fontSize: 22, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            // Cache-first SWR: fresh network data wins; otherwise the
            // disk-cached lists render instantly on cold start; the skeleton
            // shows only when neither exists (genuine first-ever open).
            child: Builder(builder: (_) {
              final fresh = asyncLists.valueOrNull;
              if (fresh != null) {
                // Persist fresh data for the next cold start.
                _persistToCache(fresh);
                return _buildListsBody(context, fresh, text, muted, surface, accent);
              }
              if (_cachedLists != null) {
                return _buildListsBody(
                    context, _cachedLists!, text, muted, surface, accent);
              }
              if (asyncLists.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Error: ${asyncLists.error}',
                        style: TextStyle(color: muted),
                        textAlign: TextAlign.center),
                  ),
                );
              }
              return const _GroceryListsSkeleton();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildListsBody(
    BuildContext context,
    List<GroceryListSummary> lists,
    Color text,
    Color muted,
    Color surface,
    Color accent,
  ) {
    if (lists.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shopping_cart_outlined,
                  size: 64, color: accent.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              Text('No lists yet',
                  style: TextStyle(
                      color: text,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Tap + to create a list, or add one from a recipe.',
                  textAlign: TextAlign.center, style: TextStyle(color: muted)),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      itemCount: lists.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final l = lists[i];
        return Container(
          decoration: BoxDecoration(
              color: surface, borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: accent.withValues(alpha: 0.18),
              child: Icon(Icons.shopping_cart, color: accent, size: 18),
            ),
            title: Text(l.name ?? 'Untitled',
                style: TextStyle(color: text, fontWeight: FontWeight.w700)),
            subtitle: Text('${l.checkedCount} of ${l.itemCount} checked',
                style: TextStyle(color: muted, fontSize: 11)),
            trailing: Icon(Icons.chevron_right, color: muted),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => GroceryListScreen(
                      listId: l.id, userId: widget.userId, isDark: widget.isDark)));
            },
          ),
        );
      },
    );
  }
}

/// Layout-matched loading placeholder for the grocery-list index. Mirrors the
/// ListTile row shape so the skeleton → content cross-fade doesn't reflow.
/// Shown only on a genuine first-ever open (no cache, no network yet).
class _GroceryListsSkeleton extends StatelessWidget {
  const _GroceryListsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkeletonList(
      itemCount: 6,
      spacing: 8,
      padding: EdgeInsets.fromLTRB(16, 0, 16, 80),
    );
  }
}
