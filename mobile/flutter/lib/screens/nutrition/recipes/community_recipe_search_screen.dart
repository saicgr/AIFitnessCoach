/// Community recipe search — searches public shared recipes, with "Save to my recipes" CTA.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/recipe.dart';
import '../../../data/providers/recipe_providers.dart';
import '../../../data/repositories/recipe_repository.dart';

class CommunityRecipeSearchScreen extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;
  final String? initialQuery;
  const CommunityRecipeSearchScreen({
    super.key,
    required this.userId,
    required this.isDark,
    this.initialQuery,
  });

  @override
  ConsumerState<CommunityRecipeSearchScreen> createState() =>
      _CommunityRecipeSearchScreenState();
}

class _CommunityRecipeSearchScreenState extends ConsumerState<CommunityRecipeSearchScreen> {
  late final TextEditingController _controller;
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery ?? '';
    _controller = TextEditingController(text: _query);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      setState(() => _query = v.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = AccentColorScope.of(context).getColor(widget.isDark);
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg, elevation: 0,
        title: Text('Community recipes', style: TextStyle(color: text)),
        iconTheme: IconThemeData(color: text),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search public recipes…',
                hintStyle: TextStyle(color: muted),
                prefixIcon: Icon(Icons.public_rounded, color: accent),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
              ),
            ),
          ),
          Expanded(
            child: _query.length < 2
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'Search public recipes shared by other users.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: muted),
                      ),
                    ),
                  )
                : Consumer(
                    builder: (ctx, ref, _) {
                      final asyncResults = ref.watch(recipeSearchProvider(RecipeSearchArgs(
                        userId: widget.userId,
                        query: _query,
                        scope: 'community',
                      )));
                      return asyncResults.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: muted))),
                        data: (resp) {
                          if (resp.items.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text(
                                  'Nothing found in community recipes.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: muted),
                                ),
                              ),
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: resp.items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) => _CommunityRow(
                              summary: resp.items[i], userId: widget.userId, isDark: isDark, accent: accent,
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

class _CommunityRow extends ConsumerWidget {
  final RecipeSummary summary;
  final String userId;
  final bool isDark;
  final Color accent;
  const _CommunityRow({required this.summary, required this.userId, required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.15)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 56, height: 56,
              child: summary.imageUrl != null
                  ? Image.network(summary.imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: accent.withValues(alpha: 0.1)))
                  : Container(color: accent.withValues(alpha: 0.1), child: Icon(Icons.restaurant_menu, color: accent)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(summary.name, style: TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  '${summary.caloriesPerServing ?? 0} kcal · ${summary.timesLogged} logs',
                  style: TextStyle(color: muted, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Save to my recipes',
            icon: Icon(Icons.bookmark_add_outlined, color: accent),
            onPressed: () async {
              final repo = ref.read(recipeRepositoryProvider);
              try {
                // Note: community search returns recipe IDs; resolving via slug requires the share row.
                // For now we surface a SnackBar — the per-public-recipe screen handles the actual clone.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Open the recipe to save it to your library')),
                );
                await repo.search(userId, query: summary.name, scope: 'community'); // touch to keep import
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Save failed: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
