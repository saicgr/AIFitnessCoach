import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';

/// Recipe detail screen reachable from the AI chat's "View recipe" button via
/// `context.push('/recipe-detail', extra: recipeMap)`.
///
/// The recipe is passed as a loosely-typed `Map<String, dynamic>` because the
/// AI chat emits recipes in several shapes (flat vs nested macros, string vs
/// object ingredients, `name` vs `recipe_name`, etc.). Every accessor here is
/// defensive — a null, missing, or unexpectedly-typed field never crashes the
/// screen; it is simply omitted from the layout. If the map carries no usable
/// content at all we render a friendly empty state.
class RecipeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  // ---------------------------------------------------------------------------
  // Defensive field extraction helpers
  // ---------------------------------------------------------------------------

  /// Returns the first non-empty string value found under any of [keys].
  String? _str(List<String> keys) {
    for (final key in keys) {
      final value = recipe[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      if (value is num) return value.toString();
    }
    return null;
  }

  /// Returns the first numeric value found under any of [keys]. Strings that
  /// parse as numbers (e.g. "320" or "12.5 g") are also accepted.
  double? _num(List<String> keys) {
    for (final key in keys) {
      final value = recipe[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final match = RegExp(r'-?\d+(\.\d+)?').firstMatch(value);
        if (match != null) {
          final parsed = double.tryParse(match.group(0)!);
          if (parsed != null) return parsed;
        }
      }
    }
    return null;
  }

  /// Returns a nested map under any of [keys] (used for `macros`/`nutrition`).
  Map<String, dynamic>? _map(List<String> keys) {
    for (final key in keys) {
      final value = recipe[key];
      if (value is Map) {
        return value.map((k, v) => MapEntry(k.toString(), v));
      }
    }
    return null;
  }

  /// Reads a macro that may live flat on the recipe OR nested inside a
  /// `macros` / `nutrition` / `nutrition_info` sub-map.
  double? _macro(List<String> flatKeys, List<String> nestedKeys) {
    final flat = _num(flatKeys);
    if (flat != null) return flat;
    final nested = _map(['macros', 'nutrition', 'nutrition_info', 'macro']);
    if (nested != null) {
      for (final key in nestedKeys) {
        final value = nested[key];
        if (value is num) return value.toDouble();
        if (value is String) {
          final parsed = double.tryParse(
            RegExp(r'-?\d+(\.\d+)?').firstMatch(value)?.group(0) ?? '',
          );
          if (parsed != null) return parsed;
        }
      }
    }
    return null;
  }

  /// Returns a list of display strings from a recipe field that may be a
  /// `List<String>`, a `List<Map>` (with `name`/`text`/`step` keys), or a
  /// single newline-delimited string.
  List<String> _list(List<String> keys) {
    for (final key in keys) {
      final value = recipe[key];
      if (value is List) {
        final out = <String>[];
        for (final item in value) {
          final s = _stringifyListItem(item);
          if (s != null && s.isNotEmpty) out.add(s);
        }
        if (out.isNotEmpty) return out;
      }
      if (value is String && value.trim().isNotEmpty) {
        final parts = value
            .split(RegExp(r'\r?\n'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (parts.isNotEmpty) return parts;
      }
    }
    return const [];
  }

  String? _stringifyListItem(dynamic item) {
    if (item == null) return null;
    if (item is String) return item.trim();
    if (item is num) return item.toString();
    if (item is Map) {
      // Ingredient/step objects: prefer a descriptive text field, then try to
      // assemble "amount unit name" for ingredient-shaped maps.
      for (final key in ['text', 'step', 'instruction', 'description']) {
        final v = item[key];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      final name = item['name'] ?? item['food_name'] ?? item['ingredient'];
      if (name != null) {
        final amount = item['amount'] ?? item['quantity'] ?? item['qty'];
        final unit = item['unit'] ?? item['units'] ?? item['measure'];
        final buf = StringBuffer();
        if (amount != null && '$amount'.trim().isNotEmpty) {
          buf.write('${_trimNumber(amount)} ');
        }
        if (unit != null && '$unit'.trim().isNotEmpty) buf.write('$unit ');
        buf.write('$name');
        return buf.toString().trim();
      }
    }
    return item.toString().trim();
  }

  /// Renders 2.0 → "2" but keeps 1.5 → "1.5".
  String _trimNumber(dynamic value) {
    if (value is num) {
      if (value == value.roundToDouble()) return value.toInt().toString();
      return value.toString();
    }
    return '$value';
  }

  String? _formatMinutes(double? minutes) {
    if (minutes == null || minutes <= 0) return null;
    final total = minutes.round();
    if (total < 60) return '$total min';
    final hours = total ~/ 60;
    final mins = total % 60;
    return mins == 0 ? '${hours}h' : '${hours}h ${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    final title = _str(['name', 'title', 'recipe_name', 'recipeName']);
    final imageUrl =
        _str(['image_url', 'imageUrl', 'image', 'photo_url', 'thumbnail']);
    final description =
        _str(['description', 'recipe_description', 'summary', 'reason']);

    final calories = _macro(
      ['calories', 'calories_per_serving', 'caloriesPerServing', 'kcal'],
      ['calories', 'kcal'],
    );
    final protein = _macro(
      ['protein', 'protein_g', 'proteinG', 'protein_per_serving_g'],
      ['protein', 'protein_g', 'proteinG'],
    );
    final carbs = _macro(
      ['carbs', 'carbs_g', 'carbsG', 'carbohydrates', 'carbs_per_serving_g'],
      ['carbs', 'carbs_g', 'carbsG', 'carbohydrates'],
    );
    final fat = _macro(
      ['fat', 'fat_g', 'fatG', 'fat_per_serving_g'],
      ['fat', 'fat_g', 'fatG'],
    );

    final ingredients = _list(['ingredients', 'ingredient_list', 'items']);
    final steps =
        _list(['instructions', 'steps', 'directions', 'method', 'preparation']);

    final prepTime = _formatMinutes(
      _num(['prep_time', 'prep_time_minutes', 'prepTimeMinutes', 'prepTime']),
    );
    final cookTime = _formatMinutes(
      _num(['cook_time', 'cook_time_minutes', 'cookTimeMinutes', 'cookTime']),
    );
    final servings = _num(['servings', 'serving_size', 'serves', 'yield']);

    // If there's essentially nothing to show, present an empty state instead
    // of a bare scaffold.
    final hasContent = title != null ||
        description != null ||
        imageUrl != null ||
        calories != null ||
        protein != null ||
        carbs != null ||
        fat != null ||
        ingredients.isNotEmpty ||
        steps.isNotEmpty;

    if (!hasContent) {
      return _buildEmptyState(context);
    }

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, title, imageUrl),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (title != null) ...[
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _buildMetaRow(prepTime, cookTime, servings),
                _buildMacroRow(calories, protein, carbs, fat),
                if (description != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
                if (ingredients.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  _SectionHeader(
                    icon: Icons.shopping_basket_outlined,
                    label: 'Ingredients',
                  ),
                  const SizedBox(height: 12),
                  ...ingredients.map((line) => _BulletItem(text: line)),
                ],
                if (steps.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  _SectionHeader(
                    icon: Icons.format_list_numbered,
                    label: 'Instructions',
                  ),
                  const SizedBox(height: 12),
                  ...steps.asMap().entries.map(
                        (e) => _NumberedItem(index: e.key + 1, text: e.value),
                      ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/recipe-suggestions'),
                    icon: const Icon(Icons.restaurant_menu),
                    label: const Text('Browse more recipes'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.green,
                      side: const BorderSide(color: AppColors.green),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sub-builders
  // ---------------------------------------------------------------------------

  Widget _buildAppBar(
    BuildContext context,
    String? title,
    String? imageUrl,
  ) {
    final hasImage = imageUrl != null;
    return SliverAppBar(
      pinned: true,
      expandedHeight: hasImage ? 260 : kToolbarHeight,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back',
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/nutrition');
          }
        },
      ),
      flexibleSpace: hasImage
          ? FlexibleSpaceBar(
              background: _RecipeHeroImage(imageUrl: imageUrl),
            )
          : null,
    );
  }

  Widget _buildMacroRow(
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
  ) {
    final chips = <Widget>[];
    if (calories != null) {
      chips.add(_MacroChip(
        label: 'Calories',
        value: '${calories.round()}',
        color: AppColors.orange,
      ));
    }
    if (protein != null) {
      chips.add(_MacroChip(
        label: 'Protein',
        value: '${_trimNumber(protein)}g',
        color: AppColors.macroProtein,
      ));
    }
    if (carbs != null) {
      chips.add(_MacroChip(
        label: 'Carbs',
        value: '${_trimNumber(carbs)}g',
        color: AppColors.macroCarbs,
      ));
    }
    if (fat != null) {
      chips.add(_MacroChip(
        label: 'Fat',
        value: '${_trimNumber(fat)}g',
        color: AppColors.macroFat,
      ));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: chips,
    );
  }

  Widget _buildMetaRow(String? prepTime, String? cookTime, double? servings) {
    final items = <Widget>[];
    if (prepTime != null) {
      items.add(_MetaItem(icon: Icons.timer_outlined, label: 'Prep', value: prepTime));
    }
    if (cookTime != null) {
      items.add(_MetaItem(
          icon: Icons.local_fire_department_outlined,
          label: 'Cook',
          value: cookTime));
    }
    if (servings != null && servings > 0) {
      items.add(_MetaItem(
        icon: Icons.people_outline,
        label: 'Serves',
        value: _trimNumber(servings),
      ));
    }
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(spacing: 20, runSpacing: 10, children: items),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/nutrition');
            }
          },
        ),
        title: const Text('Recipe'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.no_meals_outlined,
                size: 64,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 16),
              const Text(
                "We couldn't load this recipe",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The recipe details are missing or could not be read. Try browsing fresh suggestions instead.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => context.push('/recipe-suggestions'),
                icon: const Icon(Icons.restaurant_menu),
                label: const Text('Browse more recipes'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.green,
                  side: const BorderSide(color: AppColors.green),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Private widgets
// =============================================================================

class _RecipeHeroImage extends StatelessWidget {
  final String imageUrl;

  const _RecipeHeroImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => const _HeroPlaceholder(),
          errorWidget: (context, url, error) => const _HeroPlaceholder(),
        ),
        // Bottom gradient so the back button / future title stays legible.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.35),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.glassSurface,
      alignment: Alignment.center,
      child: Icon(
        Icons.restaurant_outlined,
        size: 56,
        color: AppColors.textMuted,
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          '$label ',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.green),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;

  const _BulletItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7, right: 10),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.green,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberedItem extends StatelessWidget {
  final int index;
  final String text;

  const _NumberedItem({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
