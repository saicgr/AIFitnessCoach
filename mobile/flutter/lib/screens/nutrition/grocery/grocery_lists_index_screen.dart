/// Index of all grocery lists the user has built.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/providers/recipe_providers.dart';
import '../../../widgets/glass_back_button.dart';
import '../../../widgets/main_shell.dart' show floatingNavBarVisibleProvider;
import 'grocery_list_screen.dart';

class GroceryListsIndexScreen extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;
  const GroceryListsIndexScreen({super.key, required this.userId, required this.isDark});
  @override
  ConsumerState<GroceryListsIndexScreen> createState() => _GroceryListsIndexScreenState();
}

class _GroceryListsIndexScreenState extends ConsumerState<GroceryListsIndexScreen> {
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
    // Belt-and-suspenders restore — primary restore happens at the push site
    // in recipes_tab._pushAndRestoreNavBar, which survives swipe-back/race.
    try {
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
    } catch (_) {}
    super.dispose();
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
            child: asyncLists.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error: $e', style: TextStyle(color: muted), textAlign: TextAlign.center),
                ),
              ),
              data: (lists) {
                if (lists.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 64, color: accent.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text('No lists yet', style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text('Create one from a meal plan or a single recipe.',
                              textAlign: TextAlign.center, style: TextStyle(color: muted)),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: lists.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final l = lists[i];
                    return Container(
                      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: accent.withValues(alpha: 0.18),
                          child: Icon(Icons.shopping_cart, color: accent, size: 18),
                        ),
                        title: Text(l.name ?? 'Untitled', style: TextStyle(color: text, fontWeight: FontWeight.w700)),
                        subtitle: Text('${l.checkedCount} of ${l.itemCount} checked',
                            style: TextStyle(color: muted, fontSize: 11)),
                        trailing: Icon(Icons.chevron_right, color: muted),
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) =>
                              GroceryListScreen(listId: l.id, userId: userId, isDark: isDark)));
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
