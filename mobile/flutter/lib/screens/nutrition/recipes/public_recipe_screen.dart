/// Public recipe view (deep-linked /r/{slug}). Read-only; "Save to my recipes" CTA.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/recipe_share.dart';
import '../../../data/providers/recipe_providers.dart';
import '../../../data/repositories/recipe_repository.dart';

class PublicRecipeScreen extends ConsumerWidget {
  final String slug;
  final bool isDark;
  const PublicRecipeScreen({super.key, required this.slug, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = AccentColorScope.of(context).getColor(isDark);
    final bg = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final asyncView = ref.watch(publicRecipeProvider(slug));

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg, elevation: 0,
        iconTheme: IconThemeData(color: text),
      ),
      body: asyncView.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.link_off, size: 64, color: muted),
                const SizedBox(height: 12),
                Text('Recipe not available', style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(e.toString(), style: TextStyle(color: muted), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
        data: (view) => _buildView(context, ref, view, accent, text, muted),
      ),
    );
  }

  Widget _buildView(BuildContext context, WidgetRef ref, PublicRecipeView v, Color accent, Color text, Color muted) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        if (v.imageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(v.imageUrl!, height: 180, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          ),
        const SizedBox(height: 16),
        Text(v.name, style: TextStyle(color: text, fontSize: 24, fontWeight: FontWeight.w800)),
        if (v.authorDisplayName != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('by ${v.authorDisplayName} · ${v.viewCount} views · ${v.saveCount} saves',
                style: TextStyle(color: muted, fontSize: 12)),
          ),
        const SizedBox(height: 16),
        Wrap(spacing: 12, children: [
          if (v.caloriesPerServing != null)
            _statChip('${v.caloriesPerServing} kcal/serv', accent),
          if (v.proteinPerServingG != null)
            _statChip('${v.proteinPerServingG!.toStringAsFixed(0)}g P', accent),
        ]),
        const SizedBox(height: 24),
        Text('Ingredients', style: TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.w700)),
        ...v.ingredients.map((i) => ListTile(
              dense: true,
              leading: Icon(Icons.circle, size: 6, color: accent),
              title: Text('${i["amount"] ?? ""} ${i["unit"] ?? ""} ${i["food_name"] ?? ""}',
                  style: TextStyle(color: text)),
            )),
        if ((v.instructions ?? '').isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Instructions', style: TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.w700)),
          Text(v.instructions!, style: TextStyle(color: text, height: 1.5)),
        ],
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () async {
            try {
              final res = await ref.read(recipeRepositoryProvider).cloneShared(v.slug);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
              }
            }
          },
          icon: const Icon(Icons.bookmark_add),
          label: const Text('Save to my recipes'),
          style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white),
        ),
      ],
    );
  }

  Widget _statChip(String label, Color accent) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w700)),
      );
}
