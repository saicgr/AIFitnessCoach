import 'dart:io';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/nutrition.dart';
import '../../../widgets/design_system/zealova.dart';
import '../../../widgets/fullscreen_image_viewer.dart';

/// The "magazine catalog" day view — a grid of the day's logged foods, each
/// shown via the photo the user actually uploaded (no AI generation). Foods
/// logged without a photo (text / barcode) get a clean Signature placeholder
/// tile so the grid stays complete. Tapping a photo opens the fullscreen viewer.
void showNutritionCatalog(
  BuildContext context, {
  required List<FoodLog> meals,
  required String dateLabel,
  required int totalCalories,
}) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => _NutritionCatalogScreen(
        meals: meals,
        dateLabel: dateLabel,
        totalCalories: totalCalories,
      ),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: child,
      ),
    ),
  );
}

class _NutritionCatalogScreen extends StatelessWidget {
  final List<FoodLog> meals;
  final String dateLabel;
  final int totalCalories;

  const _NutritionCatalogScreen({
    required this.meals,
    required this.dateLabel,
    required this.totalCalories,
  });

  String _label(FoodLog m) {
    if (m.foodItems.isNotEmpty) {
      final first = m.foodItems.first.name;
      final extra = m.foodItems.length - 1;
      return extra > 0 ? '$first  +$extra' : first;
    }
    return m.mealType.isEmpty
        ? 'Meal'
        : m.mealType[0].toUpperCase() + m.mealType.substring(1);
  }

  String _emoji(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return '🍳';
      case 'lunch':
        return '🥗';
      case 'dinner':
        return '🍝';
      case 'snack':
      case 'snacks':
        return '🍎';
      default:
        return '🍽️';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Scaffold(
      backgroundColor: tc.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dateLabel.toUpperCase(),
                              style: ZType.lbl(11,
                                  color: tc.textMuted, letterSpacing: 2)),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('$totalCalories',
                                  style: ZType.disp(40, color: tc.textPrimary)),
                              const SizedBox(width: 6),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text('KCAL',
                                    style: ZType.lbl(10,
                                        color: tc.textMuted, letterSpacing: 1.5)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: Icon(Icons.close, color: tc.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
            if (meals.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text('NOTHING LOGGED YET',
                      style: ZType.lbl(12, color: tc.textMuted)),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.82,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _CatalogTile(
                      meal: meals[i],
                      label: _label(meals[i]),
                      emoji: _emoji(meals[i].mealType),
                    ),
                    childCount: meals.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CatalogTile extends StatelessWidget {
  final FoodLog meal;
  final String label;
  final String emoji;
  const _CatalogTile(
      {required this.meal, required this.label, required this.emoji});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final url = meal.imageUrl;
    final hasPhoto = url != null && url.isNotEmpty;
    final isLocal = hasPhoto &&
        (url.startsWith('file://') ||
            (!url.startsWith('http') && url.startsWith('/')));

    Widget image;
    if (hasPhoto) {
      final img = isLocal
          ? Image.file(File(url.replaceFirst('file://', '')),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(tc))
          : Image.network(url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(tc),
              loadingBuilder: (ctx, child, progress) =>
                  progress == null ? child : _placeholder(tc));
      image = GestureDetector(
        onTap: isLocal
            ? null
            : () => showFullscreenImage(context,
                networkUrl: url, heroTag: 'catalog_${meal.id}'),
        child: Hero(tag: 'catalog_${meal.id}', child: img),
      );
    } else {
      image = _placeholder(tc);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: hasPhoto
                  ? [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 10)),
                    ]
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: image,
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: tc.textPrimary)),
        const SizedBox(height: 2),
        Text('${meal.totalCalories} CAL',
            style: ZType.lbl(9.5, color: tc.textMuted, letterSpacing: 1.2)),
      ],
    );
  }

  Widget _placeholder(ThemeColors tc) => Container(
        color: tc.surface,
        alignment: Alignment.center,
        child: Text(emoji, style: const TextStyle(fontSize: 34)),
      );
}
