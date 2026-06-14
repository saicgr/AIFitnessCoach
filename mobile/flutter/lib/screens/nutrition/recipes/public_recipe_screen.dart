/// Public recipe view (deep-linked /r/{slug}). Read-only; "Save to my recipes" CTA.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/recipe_share.dart';
import '../../../data/providers/recipe_providers.dart';
import '../../../data/repositories/recipe_repository.dart';
import '../../../widgets/design_system/zealova.dart';

import '../../../l10n/generated/app_localizations.dart';
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
      appBar: const ZealovaAppBar(
        title: 'Recipe',
        kicker: 'SHARED',
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
                Text(AppLocalizations.of(context).publicRecipeRecipeNotAvailable, style: ZType.disp(22, color: text)),
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
            borderRadius: BorderRadius.circular(14),
            child: Image.network(v.imageUrl!, height: 180, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          ),
        const SizedBox(height: 16),
        Text(v.name, style: ZType.disp(26, color: text)),
        if (v.authorDisplayName != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('BY ${v.authorDisplayName} · ${v.viewCount} VIEWS · ${v.saveCount} SAVES'.toUpperCase(),
                style: ZType.lbl(11, color: muted, letterSpacing: 1.3)),
          ),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: [
          if (v.caloriesPerServing != null)
            _statChip('${v.caloriesPerServing} KCAL/SERV', text),
          if (v.proteinPerServingG != null)
            _statChip('${v.proteinPerServingG!.toStringAsFixed(0)}G P', AppColors.macroProtein),
        ]),
        const SizedBox(height: 24),
        ZealovaSectionKicker(AppLocalizations.of(context).recipeSuggestionCardIngredients),
        const SizedBox(height: 8),
        ...v.ingredients.map((i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('${i["amount"] ?? ""} ${i["unit"] ?? ""} ${i["food_name"] ?? ""}',
                        style: TextStyle(color: text, fontSize: 14)),
                  ),
                ],
              ),
            )),
        if ((v.instructions ?? '').isNotEmpty) ...[
          const SizedBox(height: 16),
          ZealovaSectionKicker(AppLocalizations.of(context).workoutShowcaseInstructions),
          const SizedBox(height: 8),
          Text(v.instructions!, style: TextStyle(color: text, fontSize: 14, height: 1.5)),
        ],
        const SizedBox(height: 32),
        ZealovaButton(
          label: AppLocalizations.of(context).publicRecipeSaveToMyRecipes,
          trailingIcon: Icons.bookmark_add,
          onTap: () async {
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
        ),
      ],
    );
  }

  Widget _statChip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label.toUpperCase(), style: ZType.lbl(11, color: color, letterSpacing: 1.3)),
      );
}
